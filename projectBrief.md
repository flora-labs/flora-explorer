# Flora Explorer Project Brief

## Project Overview

Flora Explorer is a blockchain explorer for the Flora Network, a decentralized blockchain platform. This web application provides users with a comprehensive interface to explore and interact with the Flora blockchain.

### Core Technologies
- **Frontend Framework**: Vue 3 with TypeScript
- **UI Components**: TailwindCSS with glassmorphic design patterns
- **Blockchain Integration**: CosmJS for Cosmos SDK interaction
- **Build Tool**: Vite
- **State Management**: Pinia stores

### Key Features
- Real-time blockchain data exploration
- Wallet integration and management
- Transaction viewing and tracking
- Validator information and staking interface
- IBC (Inter-Blockchain Communication) support
- Supply and distribution metrics
- Community pool tracking

## Architecture

### Project Structure
```
flora-explorer/
├── src/
│   ├── layouts/         # Layout components (DefaultLayout, ChainProfile, NavBar)
│   ├── modules/         # Feature modules ([chain]/, wallet/, staking/)
│   ├── stores/          # Pinia state management stores
│   ├── libs/            # Core libraries and API clients
│   └── components/      # Reusable Vue components
├── chains/              # Chain configuration files
│   ├── mainnet/         # Mainnet chain configs
│   └── testnet/         # Testnet chain configs (flora.json)
└── public/              # Static assets
```

### API Endpoints
- **Main API**: http://50.18.34.12:1317 (Cosmos REST API)
- **RPC**: http://52.9.17.25:26657 (Tendermint RPC)
- **EVM RPC**: http://52.9.17.25:8545 (Ethereum-compatible RPC)

### Current Network Configuration
- **Chain ID**: flora_7668378-1
- **Network**: Flora Devnet (Testnet)
- **Native Token**: FLORA (uflora with 18 decimals)

## ConPort Integration Instructions

### What is ConPort?

ConPort (Context Portal) is a memory bank MCP server that builds a project-specific knowledge graph. It enables AI assistants to understand your project better by storing important information like decisions, tasks, and architectural patterns in a structured database.

### Adding ConPort to Claude Code

To integrate ConPort with Claude Code for this project, add the following to your Claude Code configuration:

1. **Install ConPort MCP Server**:
   ```bash
   pip install context-portal-mcp
   ```

2. **Configure MCP in Claude Code**:
   Add to your `claude_code_config.json` or relevant MCP configuration:
   ```json
   {
     "mcpServers": {
       "conport": {
         "command": "uvx",
         "args": ["context-portal-mcp"],
         "env": {
           "WORKSPACE_ID": "/Users/alan/Projects/_FLORA/flora-workspace/flora-explorer"
         }
       }
     }
   }
   ```

3. **Initialize ConPort**:
   When starting a new Claude Code session, tell the assistant:
   ```
   Initialize according to ConPort custom instructions. The workspace_id is the current project directory.
   ```

### ConPort Usage Strategy

#### Core Principles
- Always provide the `workspace_id` with each ConPort tool call
- Proactively log decisions, progress, and important context
- Use semantic search for finding relevant project information
- Build relationships between different context items

#### Key ConPort Tools

1. **Product Context** (High-level project info):
   - `get_product_context()` - Retrieve project goals and architecture
   - `update_product_context()` - Update project description

2. **Decision Tracking**:
   - `log_decision()` - Record architectural/implementation decisions
   - `get_decisions()` - Retrieve logged decisions
   - `search_decisions_fts()` - Full-text search in decisions

3. **Progress Tracking**:
   - `log_progress()` - Track task status (TODO, IN_PROGRESS, DONE)
   - `get_progress()` - View progress entries
   - `update_progress()` - Update task status

4. **Custom Data**:
   - `log_custom_data()` - Store project-specific information
   - `get_custom_data()` - Retrieve custom data
   - `search_project_glossary_fts()` - Search in project glossary

5. **Knowledge Graph**:
   - `link_conport_items()` - Create relationships between items
   - `get_linked_items()` - Find related context items

### Best Practices

1. **Start Each Session**:
   - Check if ConPort is available with `get_conport_schema()`
   - Load product context with `get_product_context()`
   - Review recent activity with `get_recent_activity_summary()`

2. **During Development**:
   - Log important decisions immediately
   - Update progress status as tasks change
   - Link related items (e.g., link a bug fix to the original decision)

3. **Context Retrieval**:
   - Use semantic search for complex queries
   - Filter by tags and categories for precise results
   - Leverage the knowledge graph for understanding relationships

## Current Issues and Tasks

### Recently Fixed
- ✅ Fixed nginx proxy configuration - API was pointing to wrong port (26657 instead of 1317)
- ✅ Updated flora.json to prioritize working API endpoint
- ✅ Verified API endpoints are functioning correctly

### Known Issues
- Some components may need endpoint updates after the API fix
- Glassmorphic design implementation in progress
- Supply and distribution metrics need proper formatting

### Development Guidelines

1. **Code Style**:
   - Use TypeScript for type safety
   - Follow Vue 3 Composition API patterns
   - Maintain consistent glassmorphic design system

2. **Testing**:
   - Test all API endpoints before deployment
   - Verify wallet integrations work correctly
   - Check responsive design on mobile devices

3. **Performance**:
   - Optimize API calls with proper caching
   - Use lazy loading for heavy components
   - Implement proper error handling for network failures

## Contact and Resources

- **Flora Network Documentation**: [Pending]
- **ConPort Repository**: https://github.com/GreatScottyMac/context-portal
- **Project Repository**: [Current repository]

## Quick Start for AI Assistants

When working on this project with ConPort:

1. Initialize ConPort context:
   ```
   [CONPORT_ACTIVE] Initializing Flora Explorer project context...
   ```

2. Check recent changes:
   ```
   get_recent_activity_summary(workspace_id="/Users/alan/Projects/_FLORA/flora-workspace/flora-explorer")
   ```

3. Load project context:
   ```
   get_product_context(workspace_id="/Users/alan/Projects/_FLORA/flora-workspace/flora-explorer")
   ```

4. When making changes, log decisions:
   ```
   log_decision(
     workspace_id="/Users/alan/Projects/_FLORA/flora-workspace/flora-explorer",
     summary="Changed API endpoint priority",
     rationale="Direct IP endpoint more reliable than proxy"
   )
   ```

This project brief serves as the primary context document for AI assistants working on the Flora Explorer project with ConPort integration.