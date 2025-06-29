# https://python.langchain.com/docs/how_to/migrate_agent/
from langchain_mcp_adapters.client import MultiServerMCPClient
from langgraph.prebuilt import create_react_agent
from langchain_core.messages import AIMessage
from langchain_openai import ChatOpenAI
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
import os

local_secret_key = os.environ["LANGFUSE_SECRET_KEY"]
local_public_key = os.environ["LANGFUSE_PUBLIC_KEY"] 

from langfuse.langchain import CallbackHandler
 
# Initialize Langfuse CallbackHandler for Langchain (tracing)
langfuse_handler = CallbackHandler()

# Configure LLM - can use either text or vision model
llm_model = os.environ.get("LLM_MODEL", "qwen3-vllm")  # Default to text model, can override with vision model
llm_model_url = "http://litellm:4000"

# Select the appropriate virtual key based on model
if "vision" in llm_model:
    llm_model_key = os.environ["QWEN_VISION_MODEL_KEY"]
    print(f"Using vision model: {llm_model} with virtual key")
else:
    llm_model_key = os.environ["QWEN_TEXT_MODEL_KEY"]
    print(f"Using text model: {llm_model} with virtual key")

model = ChatOpenAI(
    model=llm_model, 
    temperature=0, 
    max_tokens=1500, 
    api_key=llm_model_key,  # Use LiteLLM virtual key for access control and tracking
    base_url=llm_model_url
)

print(f"LLM configured successfully with model: {llm_model}")

fruit_server_params = {
    "fruit_price_services": {
        "url": "http://mcp-fruit-services:8000/sse",
        "transport": "sse",
    }
}

# Initialize the MCP client and agent on startup
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start MCP client
    try:
        client = MultiServerMCPClient(fruit_server_params)
        tools = await client.get_tools()
        
        print("Total tools loaded:", len(tools))
        for tool in tools:
            print("Tool:", tool.name)
            print("Tool description:", tool.description)
        
        print("Agent initialized successfully with MCP tools")
        
    except Exception as e:
        print(f"Error initializing agent: {str(e)}")
        print("Application will continue without MCP tools")
    
    yield
    
    print("Shutting down agent and MCP client")

app = FastAPI(
    title="Simple Fruit Store Agentic API with MCP",
    description="A simple fruit store API demonstrating LangGraph and MCP integration",
    version="2.0.0",
    lifespan=lifespan
)

@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Simple Fruit Store Agentic API with MCP",
        "version": "2.0.0",
        "endpoints": {
            "/api/fruits": "POST - Simple fruit price query demonstration",
            "/health": "GET - Health check"
        }
    }

@app.post("/api/fruits")
async def q():
    """Simple fruit price query using MCP tool."""
    
    try:
        client = MultiServerMCPClient(fruit_server_params)
        tools = await client.get_tools()
        
        graph = create_react_agent(model, tools, debug=True)
        graph = graph.with_config({
            "run_name": "fruit_agent",
            "callbacks": [langfuse_handler],
            "recursion_limit": 25,
        })        
        
        inputs = {"messages": [("user", "What is the price of apples? Use the tool to get the price.")]}
        
        final_message = ""
        async for s in graph.astream(inputs, stream_mode="values"):
            message = s["messages"][-1]
            if isinstance(message, tuple):
                print(message)
            else:
                message.pretty_print()
                
            if isinstance(message, AIMessage):
                final_message = message.content
                print("Final message:", final_message)                
        
        return final_message
        
    except Exception as e:
        print(f"Error in fruit query: {str(e)}")
        return {"error": f"Failed to process fruit query: {str(e)}"}

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "simple-fruit-store-agentic-api"}

if __name__ == "__main__":
    uvicorn.run("langgraph-agent-react-agent:app", host="0.0.0.0", port=8080, reload=True)
