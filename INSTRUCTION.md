# INSTRUCTION.md

## Prerequisites
- docker
- kind
- kubectl
- helm

## 1. Deploy
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

## 2. Validate nodes and taints
```bash
kubectl get nodes --show-labels
kubectl describe nodes | grep -A2 Taints
```
The node labeled `app=mysql` must show taint `app=mysql:NoSchedule`.

## 3. Validate the helm release
```bash
helm list -A
helm status todoapp -n todoapp
```

## 4. Validate resources
```bash
kubectl get all,cm,secret,ing -A
```
Compare with `output.log`.

## 5. Validate pod scheduling
```bash
kubectl get pods -n mysql -o wide
kubectl get pods -n todoapp -o wide
```
MySQL pods must be scheduled only on the tainted `app=mysql` node; todoapp pods must not.

## 6. Tear down
```bash
kind delete cluster --name todoapp-cluster
```