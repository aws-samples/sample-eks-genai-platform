#!/bin/bash

# Function to create or update the HF secret
create_hf_secret() {
    local token=$1
    echo "Creating/updating HF secret..."
    kubectl create secret generic hf-secret \
        --from-literal=hf_api_token="$token" \
        -n genai \
        --dry-run=client -o yaml | kubectl apply -f -
    
    if [ $? -eq 0 ]; then
        echo "✅ HF secret created/updated successfully"
    else
        echo "❌ Failed to create HF secret"
        exit 1
    fi
}

# Function to deploy VLLM services
deploy_vllm_services() {
    echo "Deploying VLLM Qwen services..."
    
    # Deploy Qwen-3 service
    echo "Applying vllm-qwen-3.yaml..."
    kubectl apply -f vllm-qwen-3.yaml
    if [ $? -eq 0 ]; then
        echo "✅ VLLM Qwen-3 service deployed successfully"
    else
        echo "❌ Failed to deploy VLLM Qwen-3 service"
        exit 1
    fi
    
    # Deploy Qwen Vision service
    echo "Applying vllm-qwen-vision.yaml..."
    kubectl apply -f vllm-qwen-vision.yaml
    if [ $? -eq 0 ]; then
        echo "✅ VLLM Qwen Vision service deployed successfully"
    else
        echo "❌ Failed to deploy VLLM Qwen Vision service"
        exit 1
    fi
}

# Main script logic
HF_TOKEN=""

# Check if token provided as argument
if [ $# -eq 1 ]; then
    HF_TOKEN=$1
    echo "Using provided HF token"
elif [ $# -eq 0 ]; then
    # Prompt for token if not provided
    echo -n "Please input HF token: "
    read -r HF_TOKEN
else
    echo "Usage: $0 [HF_TOKEN]"
    echo "  $0 <your_hf_token>     - Use provided token"
    echo "  $0                     - Prompt for token input"
    exit 1
fi

# Validate token is not empty
if [ -z "$HF_TOKEN" ]; then
    echo "❌ Error: HF token cannot be empty"
    exit 1
fi

echo "🚀 Starting VLLM deployment process..."

# Create the secret
create_hf_secret "$HF_TOKEN"

# Deploy the services
deploy_vllm_services

echo "🎉 VLLM Qwen Models deployment completed successfully!"

