---
name: Agent Context Protocol ACP Skill
description: Using this skills to understand Agent Context Protocol when user mentioned or working with this.
license: MIT
---

# Agent Context Protocol (ACP)

ACP is a standard JSON-RPC based protocol that enables seamless communication between code editors (clients) and AI coding agents (servers). It operates over standard input/output (stdio), allowing the agent to run as a subprocess of the editor.

## Core Concepts

1.  **JSON-RPC Transport**: Communication uses JSON-RPC 2.0 messages (requests, responses, notifications) delimited by newlines.
2.  **Sessions**: Stateful conversation contexts.
3.  **Context**: Rich context is passed to the agent, including:
    *   User messages
    *   File contents (resources)
    *   Editor selections
    *   Terminal output
4.  **Tools & Delegation**: Agents can execute tools and delegate tasks to specialized sub-agents. The client handles tool execution requests and displays progress.

## Implementation in PDFScribe

PDFScribe implements ACP to power its research capabilities using the local `opencode` binary.

### Architecture

*   **Service Layer**: `AIService` manages the high-level application state and selects the `OpenCodeStrategy` when the "OpenCode" provider is chosen.
*   **Strategy Layer**: `OpenCodeStrategy` (in `Services/Strategies/OpenCodeStrategy.swift`) implements the specific ACP logic.
*   **Transport Layer**: `JSONRPCClient` (in `Services/Infrastructure/JSONRPCClient.swift`) handles encoding/decoding of JSON-RPC messages.
*   **Process Layer**: `ProcessManager` manages the `opencode` subprocess lifecycle.

### Key Workflows

#### 1. Initialization
The client launches `opencode acp` and sends an `initialize` request with client capabilities and info.
```swift
// OpenCodeStrategy.swift
let initParams = ["protocolVersion": 1, "capabilities": [...], "clientInfo": [...]]
client.createRequest(method: "initialize", params: initParams)
```

#### 2. Session Creation
A session is created via `session/new`, establishing the working directory (`cwd`).
```swift
client.createRequest(method: "session/new", params: ["cwd": workingDirectory])
```

#### 3. Sending Prompts
When a user sends a message, `OpenCodeStrategy` constructs a rich payload for `session/prompt`:
*   **Text**: The user's query.
*   **Resources**: The current file (Markdown/PDF) and any referenced files are attached as resource blocks (`uri`, `mimeType`, `text`).
*   **Selections**: Selected text from the editor or PDF viewer is formatted and appended.

#### 4. Streaming Responses
The client listens for `session/update` notifications to handle real-time feedback:
*   `agent_message_chunk`: Streaming text response.
*   `tool_call`: Notifications when the agent (or sub-agent) executes a tool.
*   `tool_call_update`: Status updates for tool execution.
*   `turn_complete`: Signals the end of the agent's turn.

#### 5. Delegation
The implementation explicitly handles sub-agent delegation. When a `task` tool is called, `activeDelegationId` is set to track the sub-agent's lifecycle. Output from the sub-agent is handled distinctly from the main agent's stream to ensure correct UI representation.
