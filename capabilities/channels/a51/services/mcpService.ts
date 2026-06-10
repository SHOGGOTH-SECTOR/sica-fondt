// MCP Service for G.U.N.D.A.M.
// Handles communication with the Model Context Protocol server

export async function callMcpTool(toolName: string, args: any): Promise<any> {
  try {
    const response = await fetch("/api/mcp/messages", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: Math.random().toString(36).substring(7),
        method: "tools/call",
        params: {
          name: toolName,
          arguments: args,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`MCP Tool Call Failed: ${response.statusText}`);
    }

    const data = await response.json();
    
    // The SSE transport might return the response in a different way depending on implementation
    // But for our simplified server.ts implementation, we'll try to parse it
    if (data.result && data.result.content && data.result.content[0]) {
      return JSON.parse(data.result.content[0].text);
    }
    
    return data;
  } catch (error) {
    console.error(`Error calling MCP tool ${toolName}:`, error);
    return { error: error instanceof Error ? error.message : String(error) };
  }
}
