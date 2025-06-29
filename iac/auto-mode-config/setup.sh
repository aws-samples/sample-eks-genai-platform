# Deploy Graviton Nodepool
kubectl create -f nodepools/graviton-nodepool.yaml

# Deploy GPU Nodepool
kubectl create -f nodepools/gpu-nodepool.yaml

# Deploy the Storage Class
kubectl create -f storage-class.yaml

# Delete general-purpose nodepool
kubectl delete nodepool general-purpose 
