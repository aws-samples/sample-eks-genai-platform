#!/bin/bash

echo "Setting up Fruit Store Agentic API with MCP..."

# Check if required LiteLLM virtual keys are set
if [ -z "${QWEN_TEXT_MODEL_KEY}" ]; then
  echo "Error: QWEN_TEXT_MODEL_KEY environment variable is not set"
  echo "Please create virtual keys in LiteLLM admin panel and export them."
  echo "See the main README for detailed instructions."
  exit 1
fi

if [ -z "${QWEN_VISION_MODEL_KEY}" ]; then
  echo "Error: QWEN_VISION_MODEL_KEY environment variable is not set"
  echo "Please create virtual keys in LiteLLM admin panel and export them."
  echo "See the main README for detailed instructions."
  exit 1
fi

# Parse command line arguments
USE_VISION_MODEL=false
if [ "$1" = "--vision" ]; then
    USE_VISION_MODEL=true
    echo "🔍 Vision model enabled - using vllm-server-qwen-vision"
else
    echo "📝 Using default text model - qwen3-vllm"
    echo "💡 Tip: Use './setup.sh --vision' to enable vision capabilities"
fi

# Create namespace if it doesn't exist
kubectl create namespace genai --dry-run=client -o yaml | kubectl apply -f -

# Check if Langfuse is deployed and secrets exist
echo "Checking for existing Langfuse deployment..."
if ! kubectl get secret langfuse-secrets -n genai &>/dev/null; then
  echo "Warning: Langfuse secrets not found. Please ensure Langfuse is deployed first."
  echo "Run the model-observability setup script before this one."
  exit 1
fi

echo "✅ Langfuse secrets found - proceeding with deployment"

# Create LiteLLM model keys secret
echo "Creating LiteLLM model keys secret..."
kubectl create secret generic litellm-model-keys \
  --from-literal=qwen-text-key="$QWEN_TEXT_MODEL_KEY" \
  --from-literal=qwen-vision-key="$QWEN_VISION_MODEL_KEY" \
  -n genai --dry-run=client -o yaml | kubectl apply -f -

echo "✅ LiteLLM model keys secret created"

# Clean up existing deployments
echo "Cleaning up existing deployments..."
kubectl delete deployment mcp-fruit-services -n genai --ignore-not-found=true
kubectl delete deployment agentic-app -n genai --ignore-not-found=true

kubectl delete configmap mcp-fruit-prices-config -n genai --ignore-not-found=true
kubectl delete configmap agentic-app-config -n genai --ignore-not-found=true

echo "✅ Cleanup completed"

# Deploy MCP Fruit Services
echo "Deploying MCP Fruit Services..."
kubectl create configmap mcp-fruit-prices-config \
  --from-file=mcp-fruit-prices.py \
  -n genai \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f deployments/mcp-fruit-prices-deployment.yaml

echo "Waiting for MCP Fruit Services to be ready..."
kubectl rollout status deployment/mcp-fruit-services -n genai

echo "✅ MCP Fruit Services deployed successfully!"
echo "Service is accessible at: http://mcp-fruit-services.genai.svc.cluster.local:8000"

# Deploy Agentic Application
echo "Deploying Enhanced Fruit Store Agentic API..."
kubectl create configmap agentic-app-config \
  --from-file=langgraph-agent-react-agent.py \
  -n genai \
  --dry-run=client -o yaml | kubectl apply -f -

# Configure the model based on the flag
if [ "$USE_VISION_MODEL" = true ]; then
    echo "Configuring deployment to use vision model..."
    cp deployments/agentic-app.yaml /tmp/agentic-app.yaml
    sed -i 's|value: "qwen3-vllm"|value: "vllm-server-qwen-vision"|g' /tmp/agentic-app.yaml
    kubectl apply -f /tmp/agentic-app.yaml -n genai
    rm /tmp/agentic-app.yaml
else
    kubectl apply -f deployments/agentic-app.yaml -n genai
fi

echo "Waiting for Agentic API to be ready..."
kubectl rollout status deployment/agentic-app -n genai

echo ""
echo "✅ Enhanced Fruit Store Agentic API deployment completed!"
echo ""