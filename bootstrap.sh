#!/bin/bash
set -euo pipefail

# 1. Spin up the kind cluster
kind create cluster --config cluster.yml

# 2. Inspect nodes for labels and taints
kubectl get nodes --show-labels
kubectl describe nodes | grep -E "Name:|Taints:"

# 3. Taint nodes labeled app=mysql
for node in $(kubectl get nodes -l app=mysql -o name); do
  kubectl taint node "${node#node/}" app=mysql:NoSchedule --overwrite
done

# 4. Deploy the todoapp helm chart (mysql sub-chart deployed together)
helm dependency build ./helm-chart/todoapp
helm upgrade --install todoapp ./helm-chart/todoapp \
  --namespace todoapp \
  --create-namespace

# Install Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 5. Wait for everything to become ready
kubectl wait --namespace todoapp --for=condition=Available deployment --all --timeout=180s
kubectl wait --namespace mysql --for=condition=Ready pod -l app=mysql --timeout=180s

# 6. Collect output.log
kubectl get all,cm,secret,ing -A > output.log