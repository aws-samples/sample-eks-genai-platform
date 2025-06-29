#!/bin/bash

echo "Setting up Langfuse using Helm chart..."

# Generate secure secrets
echo "Generating secure secrets..."
ENCRYPTION_KEY=$(openssl rand -hex 32)
SALT=$(openssl rand -hex 16)
NEXTAUTH_SECRET=$(openssl rand -hex 16)
POSTGRES_PASSWORD=$(openssl rand -hex 16)
CLICKHOUSE_PASSWORD=$(openssl rand -hex 16)
REDIS_PASSWORD=$(openssl rand -hex 16)
MINIO_ACCESS_KEY="minio"
MINIO_SECRET_KEY=$(openssl rand -hex 16)

echo "Generated secrets for secure deployment"

# Create namespace
kubectl create namespace genai --dry-run=client -o yaml | kubectl apply -f -

# Create secrets
echo "Creating Kubernetes secrets..."
kubectl create secret generic langfuse-secrets \
  --from-literal=encryption-key="$ENCRYPTION_KEY" \
  --from-literal=salt="$SALT" \
  --from-literal=nextauth-secret="$NEXTAUTH_SECRET" \
  -n genai --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgresql-secrets \
  --from-literal=db-pass="$POSTGRES_PASSWORD" \
  --from-literal=password="$POSTGRES_PASSWORD" \
  -n genai --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic clickhouse-secrets \
  --from-literal=clickhouse-pass="$CLICKHOUSE_PASSWORD" \
  -n genai --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic redis-secrets \
  --from-literal=redis-pass="$REDIS_PASSWORD" \
  -n genai --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic minio-secrets \
  --from-literal=access-key="$MINIO_ACCESS_KEY" \
  --from-literal=secret-key="$MINIO_SECRET_KEY" \
  --from-literal=root-user="$MINIO_ACCESS_KEY" \
  --from-literal=root-password="$MINIO_SECRET_KEY" \
  -n genai --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Kubernetes secrets created successfully"

# Add Langfuse Helm repository
echo "Adding Langfuse Helm repository..."
helm repo add langfuse https://langfuse.github.io/langfuse-k8s
helm repo update

# Install Langfuse using Helm
echo "Installing Langfuse..."
helm install langfuse langfuse/langfuse --create-namespace -n genai -f values.yaml

# Deploy ALB Ingress
echo "Deploying ALB Ingress for Langfuse..."
kubectl apply -f langfuse-ingress.yaml

echo "Waiting for ALB to be provisioned..."
sleep 30

URL=$(kubectl get ingress langfuse-web-ingress-alb -n genai -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo ""
echo "✅ Langfuse deployment completed!"
echo ""
echo "To access Langfuse:"
echo "1. Access Languse Webui at: ${URL}"
echo ""
echo "2. Open your browser to the ALB hostname (may take 5-10 minutes for ALB to be ready)"
echo ""
