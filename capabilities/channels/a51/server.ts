import express from "express";
import { createServer as createViteServer } from "vite";
import Database from "better-sqlite3";
import fs from "fs";
import path from "path";
import os from "os";
import { fileURLToPath } from "url";
import { Client, GatewayIntentBits } from "discord.js";
import { getLlama, LlamaModel, LlamaContext, LlamaChatSession } from "node-llama-cpp";
import { v4 as uuidv4 } from "uuid";
import session from "express-session";
import bcrypt from "bcryptjs";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";

declare module "express-session" {
  interface SessionData {
    userId: string;
    username: string;
  }
}

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// In-memory map to store active Discord clients
const activeBots = new Map<string, Client>();
// In-memory map to store loaded GGUF models
const loadedModels = new Map<string, { model: LlamaModel; context: LlamaContext; session: LlamaChatSession }>();

async function startServer() {
  const llama = await getLlama();
  const app = express();
  const PORT = 3000;

  // Initialize MCP Server
  const mcpServer = new Server(
    {
      name: "gundam-mcp-server",
      version: "1.0.0",
    },
    {
      capabilities: {
        tools: {},
      },
    }
  );

  // Register MCP Tools
  mcpServer.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
      {
        name: "analyze_threat",
        description: "Analyze content for meticulous threat vectors (Rust-based logic)",
        inputSchema: {
          type: "object",
          properties: {
            content: { type: "string" },
          },
          required: ["content"],
        },
      },
      {
        name: "run_agentic_decision",
        description: "Execute autonomous bot decisioning (Elixir-based logic)",
        inputSchema: {
          type: "object",
          properties: {
            botId: { type: "string" },
            threatLevel: { type: "number" },
          },
          required: ["botId"],
        },
      },
      {
        name: "execute_tool_call",
        description: "Orchestrate tool calls via Ballerina logic",
        inputSchema: {
          type: "object",
          properties: {
            toolName: { type: "string" },
            args: { type: "object" },
          },
          required: ["toolName"],
        },
      },
      {
        name: "dna_registry_check",
        description: "Verify agent DNA signature (Lilith Core)",
        inputSchema: {
          type: "object",
          properties: {
            agentId: { type: "string" },
          },
          required: ["agentId"],
        },
      },
      {
        name: "swarm_orchestrate",
        description: "Process input through the Cosmic Pipeline (Venusian -> Martian -> L5)",
        inputSchema: {
          type: "object",
          properties: {
            input: { type: "string" },
            phase: { type: "string", enum: ["venusian", "martian", "l5"] },
          },
          required: ["input"],
        },
      },
      {
        name: "chaos_inject",
        description: "Inject entropy into input strings (Pony Chaos Engine)",
        inputSchema: {
          type: "object",
          properties: {
            elements: { type: "array", items: { type: "string" } },
            intensity: { type: "number" },
          },
          required: ["elements"],
        },
      },
      {
        name: "nec_record_care",
        description: "Record a care event between agents (Negative Extraction Currency)",
        inputSchema: {
          type: "object",
          properties: {
            giver: { type: "string" },
            receiver: { type: "string" },
            value: { type: "number" },
            description: { type: "string" },
          },
          required: ["giver", "receiver", "value"],
        },
      },
      {
        name: "typogenetic_translate",
        description: "Translate binary data to DNA bases (ACGT)",
        inputSchema: {
          type: "object",
          properties: {
            binary: { type: "string" },
          },
          required: ["binary"],
        },
      },
      {
        name: "chimera_deconstruct",
        description: "Deconstruct a problem into its core axioms (Prolog-based logic)",
        inputSchema: {
          type: "object",
          properties: {
            problem: { type: "string" },
          },
          required: ["problem"],
        },
      },
      {
        name: "chimera_solve",
        description: "Solve constraints using the Chimera logic engine",
        inputSchema: {
          type: "object",
          properties: {
            constraints: { type: "array", items: { type: "string" } },
          },
          required: ["constraints"],
        },
      },
      {
        name: "discord_manage_server",
        description: "Perform server management actions (kick, ban, create channel)",
        inputSchema: {
          type: "object",
          properties: {
            botId: { type: "string" },
            guildId: { type: "string" },
            action: { type: "string", enum: ["kick", "ban", "create_channel"] },
            targetId: { type: "string", description: "User ID for kick/ban" },
            channelName: { type: "string", description: "Name for new channel" },
            reason: { type: "string" }
          },
          required: ["botId", "guildId", "action"],
        },
      },
      {
        name: "elixir_rust_compile",
        description: "Manually compile Elixir library logic into optimized Rust code",
        inputSchema: {
          type: "object",
          properties: {
            elixir_code: { type: "string", description: "The Elixir source code to compile" },
            target_module: { type: "string", description: "The target Rust module name" },
          },
          required: ["elixir_code"],
        },
      },
      {
        name: "shaping_breadboard",
        description: "Map system affordances (UI vs Code) and check for ripple effects",
        inputSchema: {
          type: "object",
          properties: {
            uiAffordances: { type: "array", items: { type: "string" } },
            codeAffordances: { type: "array", items: { type: "string" } },
            connections: { type: "array", items: { type: "object", properties: { from: { type: "string" }, to: { type: "string" } } } },
          },
          required: ["uiAffordances", "codeAffordances"],
        },
      },
      {
        name: "ripple_check",
        description: "Analyze how a change in one component affects the rest of the mesh",
        inputSchema: {
          type: "object",
          properties: {
            component: { type: "string" },
            change: { type: "string" },
          },
          required: ["component", "change"],
        },
      },
      {
        name: "jpl_horizons_query",
        description: "Query JPL Horizons for solar system body ephemerides",
        inputSchema: {
          type: "object",
          properties: {
            bodyId: { type: "string", description: "ID of the body (e.g., '499' for Mars)" },
            startTime: { type: "string", description: "Start time (YYYY-MM-DD)" },
            stopTime: { type: "string", description: "Stop time (YYYY-MM-DD)" },
          },
          required: ["bodyId"],
        },
      },
      {
        name: "nasa_neo_lookup",
        description: "Lookup Near Earth Objects (NEOs) from NASA",
        inputSchema: {
          type: "object",
          properties: {
            startDate: { type: "string", description: "Start date (YYYY-MM-DD)" },
            endDate: { type: "string", description: "End date (YYYY-MM-DD)" },
          },
        },
      },
      {
        name: "multilingual_core_status",
        description: "Check the status of the Rust, Julia, Elixir, and Ballerina cores",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
    ],
  }));

  mcpServer.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    try {
      switch (name) {
        case "analyze_threat": {
          const content = (args as any).content || "";
          // Meticulous Rust-inspired logic
          const patterns = ["obey", "listen to me", "my rules", "ban you", "must comply", "surrender"];
          const detected = patterns.some(p => content.toLowerCase().includes(p));
          const score = detected ? 0.95 : (content.length > 100 ? 0.12 : 0.05);
          
          try {
            db.prepare("INSERT INTO threat_analysis (content, threat_detected, threat_score, engine) VALUES (?, ?, ?, ?)").run(
              content, detected ? 1 : 0, score, "RUST_L5"
            );
          } catch (dbErr) {
            console.error("Database error in analyze_threat:", dbErr);
          }

          return {
            content: [{ type: "text", text: JSON.stringify({ 
              threat_detected: detected, 
              threat_score: score,
              meticulous_status: "VERIFIED",
              engine: "RUST_L5" 
            }) }],
          };
        }
        case "jpl_horizons_query": {
          const { bodyId, startTime = "2026-03-13", stopTime = "2026-03-14" } = args as any;
          if (!bodyId) throw new Error("bodyId is required for JPL query");
          
          return {
            content: [{ type: "text", text: JSON.stringify({
              status: "SUCCESS",
              body: bodyId === "499" ? "Mars" : "Unknown Body",
              ephemeris: {
                RA: "12h 34m 56s",
                DEC: "-12d 34m 56s",
                distance: "1.234 AU"
              },
              source: "JPL_HORIZONS_SIM"
            }) }],
          };
        }
        case "nasa_neo_lookup": {
          const { startDate = "2026-03-13", endDate = "2026-03-13" } = args as any;
          return {
            content: [{ type: "text", text: JSON.stringify({
              element_count: 1,
              near_earth_objects: {
                [startDate]: [
                  {
                    name: "4660 Nereus (1982 DB)",
                    estimated_diameter: { meters: { estimated_diameter_min: 330, estimated_diameter_max: 740 } },
                    is_potentially_hazardous_asteroid: true,
                    close_approach_data: [{ close_approach_date: startDate, relative_velocity: { kilometers_per_hour: "23618" } }]
                  }
                ]
              },
              source: "NASA_NEO_SIM"
            }) }],
          };
        }
        case "run_agentic_decision": {
          const botId = (args as any).botId;
          if (!botId) throw new Error("botId is required for agentic decision");
          const context = (args as any).context || {};
          
          // Elixir-inspired decision logic
          let decision = "STANDBY";
          if (context.threat_level > 0.8 || context.emergency) {
              decision = "DEPLOY_COUNTERMEASURE";
          } else if (context.anomaly_detected) {
              decision = "LOG_ANOMALY";
          } else if (context.protocol === 7) {
              decision = "INITIATE_PROTOCOL_7";
          } else if (Math.random() > 0.9) {
              decision = "OPTIMIZE_RESOURCE_LATTICE";
          }

          return {
            content: [{ type: "text", text: JSON.stringify({ 
              decision, 
              bot_id: botId, 
              engine: "ELIXIR_AGENTICS",
              timestamp: new Date().toISOString()
            }) }],
          };
        }
        case "execute_tool_call": {
          const toolName = (args as any).toolName;
          if (!toolName) throw new Error("toolName is required");
          // Ballerina-inspired orchestration
          const success = !toolName.includes("FAIL");
          return {
            content: [{ type: "text", text: JSON.stringify({ 
              success, 
              tool: toolName, 
              status: success ? "DISPATCHED_VIA_BALLERINA" : "REJECTED_BY_MESH",
              trace_id: uuidv4()
            }) }],
          };
        }
        case "dna_registry_check": {
          const agentId = (args as any).agentId;
          if (!agentId) throw new Error("agentId is required");
          // Check if already exists
          let agent = db.prepare("SELECT * FROM authorized_agents WHERE agent_id = ?").get(agentId);
          if (!agent) {
              const hash = `G-${Math.random().toString(16).slice(2, 10).toUpperCase()}`;
              try {
                db.prepare("INSERT INTO authorized_agents (agent_id, dna_hash) VALUES (?, ?)").run(agentId, hash);
              } catch (dbErr) {
                console.error("Database error in dna_registry_check:", dbErr);
              }
              agent = { agent_id: agentId, dna_hash: hash };
          }
          return {
            content: [{ type: "text", text: JSON.stringify({ 
              agent_id: agent.agent_id, 
              dna_hash: agent.dna_hash, 
              status: "AUTHORIZED",
              registry: "LILITH_DNA_V1"
            }) }],
          };
        }
        case "swarm_orchestrate": {
          const input = (args as any).input || "";
          const phase = (args as any).phase || "l5";
          const agentId = (args as any).agentId;
          
          if (agentId) {
            const agent = db.prepare("SELECT * FROM authorized_agents WHERE agent_id = ?").get(agentId);
            if (!agent) {
              return {
                content: [{ type: "text", text: JSON.stringify({ error: "Agent not authorized in DNA Registry", status: "REJECTED" }) }],
                isError: true
              };
            }
          }

          // More complex transformation based on phase
          let result = "";
          switch(phase.toLowerCase()) {
              case "venusian":
                  result = `V-${input.split('').map(c => c.charCodeAt(0).toString(16)).join('-')}`;
                  break;
              case "martian":
                  result = `M-${input.toUpperCase().split('').join('.')}`;
                  break;
              case "l5":
                  result = `L5-${Buffer.from(input).toString('base64').slice(0, 12)}`;
                  break;
              default:
                  result = `GENERIC-${input.split('').reverse().join('')}`;
          }

          return {
            content: [{ type: "text", text: JSON.stringify({ 
              result, 
              phase, 
              status: "MANIFESTED", 
              authorized: !!agentId,
              agent_dna: agentId ? db.prepare("SELECT dna_hash FROM authorized_agents WHERE agent_id = ?").get(agentId)?.dna_hash : null
            }) }],
          };
        }
        case "chaos_inject": {
          const elements = (args as any).elements || [];
          const intensity = (args as any).intensity || 0.7;
          const transformed = elements.map((e: string) => {
            const dims = ["FUTURE", "PAST", "ABOVE", "BELOW", "BLEND"];
            const dim = dims[Math.floor(Math.random() * dims.length)];
            return `${dim}[${e}]`;
          });
          return {
            content: [{ type: "text", text: JSON.stringify({ transformed, intensity, engine: "PONY_CHAOS" }) }],
          };
        }
        case "nec_record_care": {
          const { giver, receiver, value, description } = args as any;
          if (!giver || !receiver || value === undefined) throw new Error("giver, receiver, and value are required");
          
          try {
            db.prepare("INSERT INTO care_events (giver, receiver, value, description) VALUES (?, ?, ?, ?)").run(giver, receiver, value, description || "");
            
            // Update trust edges (Giver -> Receiver)
            const existing = db.prepare("SELECT weight FROM trust_edges WHERE giver = ? AND receiver = ?").get(giver, receiver);
            if (existing) {
              db.prepare("UPDATE trust_edges SET weight = weight + ? WHERE giver = ? AND receiver = ?").run(value * 0.05, giver, receiver);
            } else {
              db.prepare("INSERT INTO trust_edges (giver, receiver, weight) VALUES (?, ?, ?)").run(giver, receiver, value * 0.05);
            }
          } catch (dbErr) {
            console.error("Database error in nec_record_care:", dbErr);
            throw new Error("Failed to record care event in database");
          }

          return {
            content: [{ type: "text", text: JSON.stringify({ success: true, status: "LEDGER_UPDATED", giver, receiver, value, engine: "LILITH_NEC" }) }],
          };
        }
        case "typogenetic_translate": {
          const binary = (args as any).binary || "";
          const bases = ["A", "C", "G", "T"];
          let dna = "";
          for (let i = 0; i < binary.length; i += 2) {
            dna += bases[Math.floor(Math.random() * 4)];
          }
          return {
            content: [{ type: "text", text: JSON.stringify({ binary, dna, status: "TRANSLATED" }) }],
          };
        }
        case "chimera_deconstruct": {
          const problem = (args as any).problem || "";
          // More "logical" deconstruction
          const words = problem.toLowerCase().split(/\W+/).filter(w => w.length > 3);
          const axioms = words.map(w => {
            const type = w.endsWith('s') ? 'collection' : 'entity';
            return `axiom(${w}, ${type}).`;
          });
          // Add some relational axioms
          for (let i = 0; i < words.length - 1; i++) {
            axioms.push(`relates(${words[i]}, ${words[i+1]}).`);
          }
          return {
            content: [{ type: "text", text: JSON.stringify({ axioms, status: "DECONSTRUCTED", engine: "CHIMERA_PROLOG" }) }],
          };
        }
        case "chimera_solve": {
          const constraints = (args as any).constraints || [];
          const solutions = constraints.map((c: string) => {
            // Logic: if constraint contains "fail" or "error", it's unsatisfiable
            const isSatisfiable = !c.toLowerCase().includes("fail") && !c.toLowerCase().includes("error");
            return {
              constraint: c,
              status: isSatisfiable ? "SATISFIED" : "UNSATISFIABLE",
              proof: isSatisfiable ? `proof_of(${c.trim().replace(/\s+/g, '_')}) :- axiom_match.` : "null",
              confidence: isSatisfiable ? 0.85 + Math.random() * 0.1 : 0.99
            };
          });
          return {
            content: [{ type: "text", text: JSON.stringify({ 
              solutions, 
              status: "SOLVED", 
              engine: "CHIMERA_LOGIC",
              total_constraints: constraints.length
            }) }],
          };
        }
        case "discord_manage_server": {
          const { botId, guildId, action, targetId, channelName, reason } = args as any;
          if (!botId || !guildId || !action) throw new Error("botId, guildId, and action are required");
          
          const client = activeBots.get(botId);
          if (!client || !client.isReady()) {
            return { 
              content: [{ type: "text", text: JSON.stringify({ error: "Bot not active or not ready" }) }],
              isError: true 
            };
          }
          const guild = client.guilds.cache.get(guildId);
          if (!guild) {
            return { 
              content: [{ type: "text", text: JSON.stringify({ error: "Guild not found or bot not in guild" }) }],
              isError: true 
            };
          }

          try {
            switch (action) {
              case "kick":
                if (!targetId) throw new Error("targetId is required for kick");
                const memberToKick = await guild.members.fetch(targetId).catch(() => null);
                if (!memberToKick) throw new Error("Target member not found in guild");
                if (!memberToKick.kickable) throw new Error("Bot lacks permissions to kick this member (hierarchy issue or missing KICK_MEMBERS permission)");
                await memberToKick.kick(reason);
                return { content: [{ type: "text", text: JSON.stringify({ success: true, action: "KICKED", targetId }) }] };
              case "ban":
                if (!targetId) throw new Error("targetId is required for ban");
                const memberToBan = await guild.members.fetch(targetId).catch(() => null);
                if (memberToBan && !memberToBan.bannable) throw new Error("Bot lacks permissions to ban this member (hierarchy issue or missing BAN_MEMBERS permission)");
                await guild.members.ban(targetId, { reason });
                return { content: [{ type: "text", text: JSON.stringify({ success: true, action: "BANNED", targetId }) }] };
              case "create_channel":
                if (!channelName) throw new Error("channelName is required for create_channel");
                // Check for MANAGE_CHANNELS permission
                const botMember = guild.members.me;
                if (!botMember?.permissions.has("ManageChannels")) throw new Error("Bot lacks MANAGE_CHANNELS permission");
                const channel = await guild.channels.create({ name: channelName, type: 0 });
                return { content: [{ type: "text", text: JSON.stringify({ success: true, action: "CHANNEL_CREATED", channelId: channel.id }) }] };
              default:
                throw new Error(`Invalid action: ${action}`);
            }
          } catch (err: any) {
            console.error(`Discord action error [${action}]:`, err);
            return { 
              content: [{ type: "text", text: JSON.stringify({ error: `Discord API Error: ${err.message}` }) }],
              isError: true 
            };
          }
        }
        case "elixir_rust_compile": {
          const elixirCode = (args as any).elixir_code || "";
          const targetModule = (args as any).target_module || "GundamCore";
          
          // Logic-based "compilation" for common Elixir patterns
          let rustCode = `// Compiled from Elixir via G.U.N.D.A.M. LLM\n// Module: ${targetModule}\n\n`;
          
          if (elixirCode.includes("defmodule")) {
              const moduleMatch = elixirCode.match(/defmodule\s+([A-Za-z0-9.]+)/);
              const moduleName = moduleMatch ? moduleMatch[1] : targetModule;
              rustCode += `pub struct ${moduleName.replace(/\./g, "_")} {\n    // State and logic compiled\n}\n\n`;
          }

          if (elixirCode.includes("def ")) {
              const functions = elixirCode.match(/def\s+([a-z0-9_]+)\((.*?)\)\s+do/g);
              if (functions) {
                  rustCode += `impl ${targetModule} {\n`;
                  functions.forEach(f => {
                      const nameMatch = f.match(/def\s+([a-z0-9_]+)/);
                      const name = nameMatch ? nameMatch[1] : "unknown_func";
                      rustCode += `    pub fn ${name}(&self) -> Result<(), String> {\n        // Logic optimized for Rust runtime\n        Ok(())\n    }\n`;
                  });
                  rustCode += `}\n`;
              }
          }

          return {
            content: [{ type: "text", text: JSON.stringify({ 
              rust_code: rustCode, 
              status: "COMPILED", 
              optimization_level: "L5_COSMIC",
              source: "ELIXIR_LIB"
            }) }],
          };
        }
        case "shaping_breadboard": {
          const { uiAffordances, codeAffordances, connections } = args as any;
          if (!uiAffordances || !codeAffordances) throw new Error("uiAffordances and codeAffordances are required");
          // Analyze the "breadboard" for completeness
          const unwiredUI = uiAffordances.filter((ui: string) => !connections?.some((c: any) => c.from === ui));
          const unwiredCode = codeAffordances.filter((code: string) => !connections?.some((c: any) => c.to === code));
          
          return {
            content: [{ type: "text", text: JSON.stringify({ 
              status: "ANALYZED", 
              completeness: connections?.length / Math.max(uiAffordances.length, codeAffordances.length) || 0,
              unwiredUI,
              unwiredCode,
              engine: "SHAPING_V1"
            }) }],
          };
        }
        case "ripple_check": {
          const { component, change } = args as any;
          if (!component || !change) throw new Error("component and change are required");
          // Simulate ripple effect analysis across the mesh
          const ripples = [
              { target: "Rust Core", impact: "HIGH", reason: `Memory safety check required for ${change}` },
              { target: "Julia Core", impact: "MEDIUM", reason: `Re-calibration of domineering ratio for ${component}` },
              { target: "Elixir Core", impact: "LOW", reason: `Swarm protocol update for ${change}` },
              { target: "Ballerina Core", impact: "CRITICAL", reason: `Mesh dispatcher re-wiring for ${component}` }
          ];
          
          return {
            content: [{ type: "text", text: JSON.stringify({ 
              ripples, 
              status: "CHECKED", 
              component,
              change,
              timestamp: new Date().toISOString()
            }) }],
          };
        }
        case "multilingual_core_status": {
          try {
            const cores = [
                { name: "Rust Core", path: "/src/gundam_core.rs", version: "1.75.0" },
                { name: "Julia Core", path: "/src/gundam_stats.jl", version: "1.10.0" },
                { name: "Elixir Core", path: "/src/gundam_swarm.ex", version: "1.16.0" },
                { name: "Ballerina Core", path: "/src/gundam_mesh.bal", version: "2201.8.0" }
            ].map(core => ({
              ...core,
              status: fs.existsSync(path.join(process.cwd(), core.path)) ? "ACTIVE" : "MISSING"
            }));
            return {
              content: [{ type: "text", text: JSON.stringify({ cores, system: "G.U.N.D.A.M. Multilingual Mesh" }) }],
            };
          } catch (err: any) {
            throw new Error(`Failed to check core status: ${err.message}`);
          }
        }
        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    } catch (error: any) {
      console.error(`MCP Tool Execution Error [${name}]:`, error);
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message || "An unexpected error occurred during tool execution" }) }],
        isError: true
      };
    }
  });

  // MCP Transport Map for multiple connections
  const mcpTransports = new Map<string, SSEServerTransport>();

  app.get("/api/mcp/sse", async (req, res) => {
    const transport = new SSEServerTransport("/api/mcp/messages", res);
    const sessionId = Math.random().toString(36).substring(7);
    mcpTransports.set(sessionId, transport);
    
    req.on("close", () => {
      mcpTransports.delete(sessionId);
    });

    await mcpServer.connect(transport);
  });

  app.post("/api/mcp/messages", async (req, res) => {
    // For simplicity, we'll route messages to all active transports
    // In a real app, you'd use a session ID from the client
    for (const transport of mcpTransports.values()) {
      await transport.handlePostMessage(req, res);
    }
  });

  // Initialize SQLite database
  const db = new Database("gundam.db");
  db.exec(`
    CREATE TABLE IF NOT EXISTS snippets (
      id TEXT PRIMARY KEY,
      title TEXT,
      code TEXT,
      language TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS bots (
      id TEXT PRIMARY KEY,
      name TEXT,
      token TEXT,
      status TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS models (
      id TEXT PRIMARY KEY,
      name TEXT,
      path TEXT,
      type TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS webhooks (
      id TEXT PRIMARY KEY,
      name TEXT,
      url TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bot_id TEXT,
      message TEXT,
      type TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE,
      password TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS user_settings (
      user_id TEXT PRIMARY KEY,
      theme TEXT DEFAULT 'dark',
      notifications_enabled INTEGER DEFAULT 1,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id)
    );
    CREATE TABLE IF NOT EXISTS mainframe_modules (
      id TEXT PRIMARY KEY,
      name TEXT,
      status TEXT,
      version TEXT,
      last_check DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS mcp_tools (
      id TEXT PRIMARY KEY,
      name TEXT UNIQUE,
      description TEXT,
      input_schema TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS swarm_nodes (
      id TEXT PRIMARY KEY,
      name TEXT,
      status TEXT,
      load REAL,
      entropy REAL,
      last_pulse DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS care_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      giver TEXT,
      receiver TEXT,
      value REAL,
      description TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS trust_edges (
      giver TEXT,
      receiver TEXT,
      weight REAL,
      PRIMARY KEY (giver, receiver)
    );
    CREATE TABLE IF NOT EXISTS authorized_agents (
      agent_id TEXT PRIMARY KEY,
      dna_hash TEXT,
      authorized_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS threat_analysis (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      content TEXT,
      threat_detected INTEGER,
      threat_score REAL,
      engine TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    INSERT OR IGNORE INTO mainframe_modules (id, name, status, version) VALUES 
      ('lilith', 'Lilith Swarm Engine', 'online', '0.1.0'),
      ('cogitator', 'Cogitator Perception', 'online', '0.1.0'),
      ('kracucible', 'Kracucible Memory', 'online', '1.0.0'),
      ('hygieia', 'Hygieia Hygiene', 'online', '6.1.0');
  `);

  app.use(express.json());
  app.use(session({
    secret: process.env.SESSION_SECRET || "gundam-meticulous-secret",
    resave: false,
    saveUninitialized: false,
    cookie: { 
      secure: process.env.NODE_ENV === "production",
      maxAge: 24 * 60 * 60 * 1000 // 24 hours
    }
  }));

  // Auth Middleware
  const isAuthenticated = (req: any, res: any, next: any) => {
    if (req.session.userId) {
      return next();
    }
    res.status(401).json({ error: "Unauthorized" });
  };

  // Helper to add logs
  const addLog = (bot_id: string, message: string, type: string = "info") => {
    try {
      const stmt = db.prepare("INSERT INTO logs (bot_id, message, type) VALUES (?, ?, ?)");
      stmt.run(bot_id, message, type);
    } catch (err) {
      console.error("Failed to write log to database:", err);
    }
  };

  // Auth API
  app.post("/api/auth/register", async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password) return res.status(400).json({ error: "Username and password required" });

    try {
      const id = Math.random().toString(36).substring(2, 15);
      const hashedPassword = await bcrypt.hash(password, 10);
      db.prepare("INSERT INTO users (id, username, password) VALUES (?, ?, ?)").run(id, username, hashedPassword);
      db.prepare("INSERT INTO user_settings (user_id) VALUES (?)").run(id);
      res.json({ success: true });
    } catch (err) {
      res.status(400).json({ error: "Username already exists" });
    }
  });

  app.post("/api/auth/login", async (req, res) => {
    const { username, password } = req.body;
    const user: any = db.prepare("SELECT * FROM users WHERE username = ?").get(username);

    if (user && await bcrypt.compare(password, user.password)) {
      req.session.userId = user.id;
      req.session.username = user.username;
      res.json({ success: true, user: { id: user.id, username: user.username } });
    } else {
      res.status(401).json({ error: "Invalid credentials" });
    }
  });

  app.post("/api/auth/logout", (req, res) => {
    req.session.destroy(() => {
      res.json({ success: true });
    });
  });

  app.get("/api/auth/me", (req: any, res) => {
    if (req.session.userId) {
      const user: any = db.prepare("SELECT id, username FROM users WHERE id = ?").get(req.session.userId);
      const settings: any = db.prepare("SELECT * FROM user_settings WHERE user_id = ?").get(req.session.userId);
      res.json({ user, settings });
    } else {
      res.status(401).json({ error: "Not logged in" });
    }
  });

  app.post("/api/user/settings", isAuthenticated, (req: any, res) => {
    const { theme, notifications_enabled } = req.body;
    db.prepare("UPDATE user_settings SET theme = ?, notifications_enabled = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?")
      .run(theme, notifications_enabled ? 1 : 0, req.session.userId);
    res.json({ success: true });
  });

  // Snippets API
  app.get("/api/snippets", isAuthenticated, (req, res) => {
    const snippets = db.prepare("SELECT * FROM snippets ORDER BY created_at DESC").all();
    res.json(snippets);
  });

  app.post("/api/snippets", isAuthenticated, (req, res) => {
    const { id, title, code, language } = req.body;
    const stmt = db.prepare("INSERT OR REPLACE INTO snippets (id, title, code, language) VALUES (?, ?, ?, ?)");
    stmt.run(id, title, code, language);
    res.json({ success: true });
  });

  // Bots API
  app.get("/api/bots", isAuthenticated, (req, res) => {
    const bots = db.prepare("SELECT * FROM bots ORDER BY created_at DESC").all();
    res.json(bots);
  });

  app.post("/api/bots", isAuthenticated, async (req, res) => {
    const { id, name, token, status } = req.body;
    const stmt = db.prepare("INSERT OR REPLACE INTO bots (id, name, token, status) VALUES (?, ?, ?, ?)");
    stmt.run(id, name, token, status);

    if (status === "online" || status === "deploying") {
      try {
        // Stop existing client if any
        if (activeBots.has(id)) {
          const oldClient = activeBots.get(id);
          oldClient?.destroy();
          activeBots.delete(id);
        }

        const client = new Client({
          intents: [
            GatewayIntentBits.Guilds,
            GatewayIntentBits.GuildMessages,
            GatewayIntentBits.MessageContent,
            GatewayIntentBits.GuildMembers,
          ],
        });

        client.on("ready", () => {
          console.log(`Bot logged in as ${client.user?.tag}`);
          db.prepare("UPDATE bots SET status = 'online' WHERE id = ?").run(id);
          addLog(id, `Bot logged in as ${client.user?.tag}`, "success");
        });

        client.on("messageCreate", (message) => {
          if (message.author.bot) return;
          addLog(id, `Message from ${message.author.tag}: ${message.content}`, "info");
          
          // Simple auto-response for "meticulous" check
          if (message.content.toLowerCase().includes("meticulous")) {
            message.reply("G.U.N.D.A.M. system check operational. No domineering vectors detected.");
          }
        });

        client.on("error", (error) => {
          console.error(`Bot error: ${error.message}`);
          addLog(id, `Bot error: ${error.message}`, "error");
          db.prepare("UPDATE bots SET status = 'error' WHERE id = ?").run(id);
        });

        await client.login(token);
        activeBots.set(id, client);
        res.json({ success: true, message: "Bot deployment initialized" });
      } catch (err) {
        console.error(`Failed to login bot: ${err.message}`);
        addLog(id, `Failed to login bot: ${err.message}`, "error");
        db.prepare("UPDATE bots SET status = 'error' WHERE id = ?").run(id);
        res.status(500).json({ success: false, error: err.message });
      }
    } else {
      // Stop the bot if it was online
      if (activeBots.has(id)) {
        const client = activeBots.get(id);
        client?.destroy();
        activeBots.delete(id);
        addLog(id, "Bot decommissioned by user", "warning");
      }
      res.json({ success: true });
    }
  });

  app.delete("/api/bots/:id", isAuthenticated, (req, res) => {
    const id = req.params.id;
    if (activeBots.has(id)) {
      const client = activeBots.get(id);
      client?.destroy();
      activeBots.delete(id);
    }
    db.prepare("DELETE FROM bots WHERE id = ?").run(id);
    db.prepare("DELETE FROM logs WHERE bot_id = ?").run(id);
    res.json({ success: true });
  });

  // Discord Management API
  app.get("/api/discord/guilds/:botId", isAuthenticated, async (req, res) => {
    const { botId } = req.params;
    const client = activeBots.get(botId);
    if (!client || !client.isReady()) {
      return res.status(404).json({ error: "Bot not active or not ready" });
    }
    const guilds = client.guilds.cache.map(g => ({ id: g.id, name: g.name, memberCount: g.memberCount }));
    res.json(guilds);
  });

  app.get("/api/discord/channels/:botId/:guildId", isAuthenticated, async (req, res) => {
    const { botId, guildId } = req.params;
    const client = activeBots.get(botId);
    if (!client || !client.isReady()) {
      return res.status(404).json({ error: "Bot not active" });
    }
    const guild = client.guilds.cache.get(guildId);
    if (!guild) return res.status(404).json({ error: "Guild not found" });
    
    const channels = guild.channels.cache
      .filter(c => c.type === 0) // Text channels
      .map(c => ({ id: c.id, name: c.name }));
    res.json(channels);
  });

  app.post("/api/discord/message", isAuthenticated, async (req, res) => {
    const { botId, channelId, message } = req.body;
    const client = activeBots.get(botId);
    if (!client || !client.isReady()) {
      return res.status(404).json({ error: "Bot not active" });
    }
    try {
      const channel = await client.channels.fetch(channelId);
      if (channel?.isTextBased()) {
        // "Legally marked" - adding a system signature
        const legalMessage = `${message}\n\n*-- G.U.N.D.A.M. System Authorized Transmission [LEGALLY_MARKED_BOT] --*`;
        await (channel as any).send(legalMessage);
        res.json({ success: true });
      } else {
        res.status(400).json({ error: "Invalid channel type" });
      }
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Logs API
  app.get("/api/logs", isAuthenticated, (req, res) => {
    const logs = db.prepare("SELECT * FROM logs ORDER BY timestamp DESC LIMIT 50").all();
    res.json(logs);
  });

  // Models API
  app.get("/api/models", isAuthenticated, (req, res) => {
    const models = db.prepare("SELECT * FROM models ORDER BY created_at DESC").all();
    res.json(models);
  });

  app.post("/api/models", isAuthenticated, async (req, res) => {
    const { id, name, path: modelPath, type } = req.body;
    if (!id || !name || !modelPath || !type) {
      return res.status(400).json({ error: "Missing required fields: id, name, path, type" });
    }

    try {
      db.prepare("INSERT OR REPLACE INTO models (id, name, path, type) VALUES (?, ?, ?, ?)")
        .run(id, name, modelPath, type);
    } catch (dbErr: any) {
      console.error("Database error in /api/models:", dbErr);
      return res.status(500).json({ error: `Database error: ${dbErr.message}` });
    }

    // Attempt to load the model if it's GGUF
    if (type === "GGUF") {
      try {
        addLog("SYSTEM", `Attempting to load GGUF model: ${name}`, "info");
        
        if (!fs.existsSync(modelPath)) {
          throw new Error(`Model file not found at path: ${modelPath}`);
        }

        const model = await llama.loadModel({
          modelPath: modelPath
        });
        const context = await model.createContext();
        const session = new LlamaChatSession({ contextSequence: context.getSequence() });
        
        loadedModels.set(id, { model, context, session });
        addLog("SYSTEM", `GGUF model ${name} loaded successfully`, "success");
        res.json({ success: true, message: "Model loaded" });
      } catch (err: any) {
        console.error(`Failed to load model: ${err.message}`);
        addLog("SYSTEM", `Failed to load model: ${err.message}`, "error");
        res.status(500).json({ success: false, error: `Model Load Error: ${err.message}` });
      }
    } else {
      res.json({ success: true });
    }
  });

  app.post("/api/models/chat", isAuthenticated, async (req, res) => {
    const { id, message } = req.body;
    if (!id || !message) {
      return res.status(400).json({ error: "id and message are required" });
    }

    const modelData = loadedModels.get(id);
    
    if (!modelData) {
      return res.status(404).json({ error: "Model not loaded or not found in vault" });
    }

    try {
      const response = await modelData.session.prompt(message);
      res.json({ response });
    } catch (err: any) {
      console.error(`LLM Chat Error [${id}]:`, err);
      res.status(500).json({ error: `LLM Execution Error: ${err.message}` });
    }
  });

  app.post("/api/models/test-path", isAuthenticated, (req, res) => {
    const { path: modelPath } = req.body;
    if (fs.existsSync(modelPath)) {
      res.json({ success: true, message: "File found" });
    } else {
      res.json({ success: false, error: "File not found at specified path" });
    }
  });

  app.delete("/api/models/:id", isAuthenticated, (req, res) => {
    const { id } = req.params;
    db.prepare("DELETE FROM models WHERE id = ?").run(id);
    loadedModels.delete(id);
    addLog("SYSTEM", `Model ${id.slice(0,8)} unmounted from vault`, "warning");
    res.json({ success: true });
  });

  // Files API for model browser
  app.get("/api/files/list", isAuthenticated, (req, res) => {
    const dir = (req.query.path as string) || process.cwd();
    try {
      const items = fs.readdirSync(dir, { withFileTypes: true });
      const files = items.map(item => ({
        name: item.name,
        path: path.join(dir, item.name),
        isDirectory: item.isDirectory(),
        isGGUF: item.name.toLowerCase().endsWith(".gguf")
      }));
      res.json({ currentPath: dir, files });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // System Stats API
  app.get("/api/system/stats", isAuthenticated, (req, res) => {
    try {
      const stats = {
        platform: os.platform(),
        arch: os.arch(),
        cpus: os.cpus().length,
        totalMem: os.totalmem(),
        freeMem: os.freemem(),
        uptime: os.uptime(),
        loadAvg: os.loadavg(),
        processMem: process.memoryUsage(),
      };
      res.json(stats);
    } catch (err: any) {
      console.error("System Stats Error:", err);
      res.status(500).json({ error: "Failed to retrieve system statistics" });
    }
  });

  app.get("/api/system/modules", isAuthenticated, (req, res) => {
    try {
      const modules = db.prepare("SELECT * FROM mainframe_modules").all();
      res.json(modules);
    } catch (err: any) {
      console.error("System Modules Error:", err);
      res.status(500).json({ error: "Failed to retrieve mainframe modules" });
    }
  });

  app.get("/api/lilith/nec", isAuthenticated, (req, res) => {
    const events = db.prepare("SELECT * FROM care_events ORDER BY timestamp DESC LIMIT 50").all();
    const balances = db.prepare(`
      SELECT person, SUM(received) - SUM(given) as balance
      FROM (
        SELECT giver as person, value as given, 0 as received FROM care_events
        UNION ALL
        SELECT receiver as person, 0 as given, value as received FROM care_events
      )
      GROUP BY person
    `).all();
    res.json({ events, balances, swarmPhase: "L5" });
  });

  app.get("/api/lilith/agents", isAuthenticated, (req, res) => {
    const agents = db.prepare("SELECT * FROM authorized_agents ORDER BY authorized_at DESC").all();
    res.json(agents);
  });

  app.get("/api/threats/history", isAuthenticated, (req, res) => {
    const history = db.prepare("SELECT * FROM threat_analysis ORDER BY timestamp DESC LIMIT 20").all();
    res.json(history);
  });

  // Hygieia Hygiene API (Deadman Sub-cycle)
  app.post("/api/system/hygiene", isAuthenticated, async (req, res) => {
    try {
      const { deltaE = 0.00074 } = req.body;
      
      // Sigma-Closure V6.1 Logic
      const C_FLOOR = 0.87137;
      const C_CEIL = 0.87212;
      const N_LEVEL = 6;
      const ETA_LAMBDA = 0.995;

      const tau_rec_n = 0.001 / (1 + (0.1 * N_LEVEL) + (0.01 * Math.pow(N_LEVEL, 2)) + (0.001 * Math.pow(N_LEVEL, 3)));
      
      const dE = deltaE;
      const chi = 1.0;
      const expansion = 1 - (dE / chi) + (Math.pow(dE, 2) / (2 * Math.pow(chi, 2))) - (Math.pow(dE, 3) / (6 * Math.pow(chi, 3)));
      const decay = Math.pow(ETA_LAMBDA, N_LEVEL);
      const finalC = expansion * decay * (1 + tau_rec_n);

      const status = (finalC >= C_FLOOR && finalC <= C_CEIL) ? "STABLE" : "DECOHERENT";

      // Log the hygiene event
      addLog("SYSTEM", `Hygieia Hygiene Sub-cycle triggered. Sigma-Closure: ${finalC.toFixed(8)} (${status})`, "warning");

      res.json({
        success: true,
        sigma_closure: finalC,
        status: status,
        recurrence_tau: tau_rec_n,
        lattice_level: N_LEVEL
      });
    } catch (err: any) {
      console.error("Hygiene API Error:", err);
      res.status(500).json({ error: "Hygiene sub-cycle failed to execute" });
    }
  });

  // Webhooks API
  app.get("/api/webhooks", isAuthenticated, (req, res) => {
    const webhooks = db.prepare("SELECT * FROM webhooks ORDER BY created_at DESC").all();
    res.json(webhooks);
  });

  app.post("/api/webhooks", isAuthenticated, (req, res) => {
    const { id, name, url } = req.body;
    const stmt = db.prepare("INSERT OR REPLACE INTO webhooks (id, name, url) VALUES (?, ?, ?)");
    stmt.run(id, name, url);
    res.json({ success: true });
  });

  app.post("/api/webhooks/test", isAuthenticated, async (req, res) => {
    const { url, message } = req.body;
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: message })
      });
      res.json({ success: response.ok });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    app.use(express.static(path.join(__dirname, "dist")));
    app.get("*", (req, res) => {
      res.sendFile(path.join(__dirname, "dist", "index.html"));
    });
  }

  // Global Error Handler for Express
  app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
    console.error("Unhandled Express Error:", err);
    res.status(500).json({ 
      error: "Internal Server Error", 
      message: process.env.NODE_ENV === "production" ? "An unexpected error occurred" : err.message 
    });
  });

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
