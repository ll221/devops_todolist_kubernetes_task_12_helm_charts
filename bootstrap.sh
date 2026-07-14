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
helm dependency build .infrastructure/helm-chart/todoapp
helm upgrade --install todoapp .infrastructure/helm-chart/todoapp \
  --namespace todoapp \
  --create-namespace

# 5. Apply the standalone todoapp pod manifest
kubectl apply -f .infrastructure/app/todoapp-pod.yaml

# Install Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 6. Wait for everything to become ready
kubectl wait --namespace todoapp --for=condition=Available deployment --all --timeout=180s
kubectl wait --namespace mysql --for=condition=Ready pod -l app=mysql --timeout=180s

# 7. Collect output.log
kubectl get all,cm,secret,ing -A > output.log
