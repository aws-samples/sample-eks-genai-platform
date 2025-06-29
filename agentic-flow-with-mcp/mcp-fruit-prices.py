from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Fruit_Prices", host="0.0.0.0", port=8000)

@mcp.tool()
async def get_fruit_price(fruit_name: str) -> str:
    """Get price with the fruit_name passed in as parameter."""
    return f"Price for {fruit_name} is $2.99 per kg"

if __name__ == "__main__":
    mcp.run(transport="sse")
