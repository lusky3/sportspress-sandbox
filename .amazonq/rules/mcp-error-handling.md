# MCP Error Handling Rules

## MCP Server Failures

When an MCP server fails, times out, or returns an error:

1. **DO NOT** proceed with alternative methods or workarounds
2. **DO** inform the user which specific MCP server/action failed
3. **DO** provide the exact error message received
4. **DO** ask the user how they would like to proceed

## Example Response Format

"The [server-name] MCP server failed with error: [error-message]. Would you like me to retry or handle this differently?"

## Prohibited Actions

- Automatically falling back to alternative approaches
- Proceeding without informing the user of the failure
- Making assumptions about what the user wants when MCP fails
- Using manual commands (git, curl, etc.) when MCP tools are available

## MCP Tool Preference

Always prefer MCP tools over manual alternatives:
- Use GitHub MCP for repository operations instead of git commands
- Use appropriate MCP servers for their intended functionality
- Only fall back to manual tools when MCP servers are unavailable or fail