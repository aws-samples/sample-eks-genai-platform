#!/bin/bash

echo "Setting up LiteLLM with secure secrets..."

# Generate secure secrets for LiteLLM
echo "Generating secure secrets..."
LITELLM_MASTER_KEY="sk-$(openssl rand -hex 32)"
LITELLM_SALT_KEY=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 16)
REDIS_PASSWORD=$(openssl rand -hex 16)

# Generate DATABASE_URL with the postgres password
DATABASE_URL="postgresql://myuser:${POSTGRES_PASSWORD}@postgres:5432/mydatabase"

echo "Generated secrets for secure deployment"

# Create namespace
kubectl create namespace genai --dry-run=client -o yaml | kubectl apply -f -

# Create LiteLLM secrets
echo "Creating Kubernetes secrets..."
kubectl create secret generic litellm-secrets \
  --from-literal=master-key="$LITELLM_MASTER_KEY" \
  --from-literal=salt-key="$LITELLM_SALT_KEY" \
  --from-literal=postgres-password="$POSTGRES_PASSWORD" \
  --from-literal=redis-password="$REDIS_PASSWORD" \
  --from-literal=database-url="$DATABASE_URL" \
  -n genai --dry-run=client -o yaml | kubectl apply -f -

# Check if required Langfuse keys are set as environment variables
echo "Checking for Langfuse API keys..."
if [ -z "${LANGFUSE_PUBLIC_KEY}" ]; then
  echo "Error: LANGFUSE_PUBLIC_KEY environment variable is not set"
  echo "Please follow the README instructions to:"
  echo "1. Access Langfuse web UI via ALB hostname"
  echo "2. Create organization 'test' and project 'demo'"
  echo "3. Generate API keys from the Tracing menu"
  echo "4. Export LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY"
  echo ""
  echo "Example:"
  echo "export LANGFUSE_PUBLIC_KEY=<your-langfuse-public-key>"
  echo "export LANGFUSE_SECRET_KEY=<your-langfuse-secret-key>"
  exit 1
fi

if [ -z "${LANGFUSE_SECRET_KEY}" ]; then
  echo "Error: LANGFUSE_SECRET_KEY environment variable is not set"
  echo "Please follow the README instructions to set up Langfuse API keys"
  exit 1
fi

echo "✅ Using provided Langfuse API keys from environment variables"

# Create Langfuse integration secret for LiteLLM
kubectl create secret generic litellm-langfuse-secrets \
  --from-literal=public-key="$LANGFUSE_PUBLIC_KEY" \
  --from-literal=secret-key="$LANGFUSE_SECRET_KEY" \
  -n genai --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Kubernetes secrets created successfully"

# Deploy LiteLLM with secure configuration
echo "Deploying LiteLLM..."
kubectl apply -f litellm-deployment.yaml

# Deploy ALB Ingress
echo "Deploying ALB Ingress for LiteLLM..."
kubectl apply -f litellm-ingress.yaml

echo "Waiting for ALB to be provisioned..."
sleep 30

URL=$(kubectl get ingress litellm-ingress-alb -n genai -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "ALB still provisioning...")

echo ""
echo "✅ LiteLLM deployment completed!"
echo ""
echo "To access LiteLLM:"
echo "1. Access LiteLLM API at: ${URL}"
echo ""
echo "2. Open your browser to the ALB hostname (may take 5-10 minutes for ALB to be ready)"
echo ""
