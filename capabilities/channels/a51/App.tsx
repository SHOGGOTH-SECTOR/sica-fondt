import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import { 
  ShieldAlert, 
  Zap, 
  Activity, 
  Cpu, 
  Terminal, 
  MessageSquare, 
  Users, 
  Settings,
  ShieldCheck,
  Search,
  Lock,
  Radio,
  Layers,
  Bot,
  BrainCircuit,
  Webhook,
  Code,
  Plus,
  Trash2,
  Play,
  ExternalLink,
  Command,
  Server,
  LogOut,
  User,
  Moon,
  Sun,
  Bell,
  BellOff,
  PenTool,
  GitBranch,
  Link as LinkIcon,
  Telescope,
  Rocket
} from "lucide-react";
import { v4 as uuidv4 } from "uuid";
import { GUNDAM_SERVICES, GUNDAM_MANIFEST } from "./gundam_core";
import { callMcpTool } from "./services/mcpService";

export default function App() {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [logs, setLogs] = useState<{id: number, msg: string, type: string, timestamp?: string}[]>([]);
  const [isScanning, setIsScanning] = useState(false);
  
  // Auth State
  const [user, setUser] = useState<any>(null);
  const [userSettings, setUserSettings] = useState<any>(null);
  const [isAuthLoading, setIsAuthLoading] = useState(true);
  const [authMode, setAuthMode] = useState<"login" | "register">("login");
  const [authUsername, setAuthUsername] = useState("");
  const [authPassword, setAuthPassword] = useState("");
  const [authError, setAuthError] = useState("");

  // Data States
  const [bots, setBots] = useState<any[]>([]);
  const [models, setModels] = useState<any[]>([]);
  const [webhooks, setWebhooks] = useState<any[]>([]);
  const [mainframeModules, setMainframeModules] = useState<any[]>([]);
  const [lilithData, setLilithData] = useState<any>({ events: [], balances: [], agents: [], swarmPhase: 'L5' });
  const [isDeployModalOpen, setIsDeployModalOpen] = useState(false);
  const [isModelModalOpen, setIsModelModalOpen] = useState(false);
  const [spaceData, setSpaceData] = useState<any>(null);
  const [isSpaceLoading, setIsSpaceLoading] = useState(false);
  const [threatHistory, setThreatHistory] = useState<any[]>([]);
  const [newBotName, setNewBotName] = useState("");
  const [newBotToken, setNewBotToken] = useState("");
  const [newModelName, setNewModelName] = useState("");
  const [newModelPath, setNewModelPath] = useState("");
  const [testingModelId, setTestingModelId] = useState<string | null>(null);
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);
  const [chimeraResults, setChimeraResults] = useState<any>({ axioms: [], solutions: [] });
  const [chaosTransformed, setChaosTransformed] = useState<string[]>([]);

  // Discord Management State
  const [selectedDiscordBot, setSelectedDiscordBot] = useState<string | null>(null);
  const [discordGuilds, setDiscordGuilds] = useState<any[]>([]);
  const [selectedGuild, setSelectedGuild] = useState<string | null>(null);
  const [discordChannels, setDiscordChannels] = useState<any[]>([]);
  const [selectedChannel, setSelectedChannel] = useState<string | null>(null);
  const [discordMessage, setDiscordMessage] = useState("");

  // Multilingual Mesh State
  const [meshCores, setMeshCores] = useState<any[]>([]);
  const [elixirSource, setElixirSource] = useState("");
  const [compiledRust, setCompiledRust] = useState("");
  const [isCompiling, setIsCompiling] = useState(false);

  // Shaping State
  const [shapingAffordances, setShapingAffordances] = useState<{ui: string[], code: string[]}>({ 
    ui: ["View Threat Map", "Trigger Protocol 7", "Deploy Bot"], 
    code: ["rust_analyze()", "elixir_swarm_init()", "ballerina_dispatch()"] 
  });
  const [shapingConnections, setShapingConnections] = useState<{from: string, to: string}[]>([]);
  const [rippleResults, setRippleResults] = useState<any>(null);
  const [isRippleChecking, setIsRippleChecking] = useState(false);
  const [newAffordance, setNewAffordance] = useState("");
  const [affordanceType, setAffordanceType] = useState<"ui" | "code">("ui");

  // File Browser State
  const [isFileBrowserOpen, setIsFileBrowserOpen] = useState(false);
  const [currentPath, setCurrentPath] = useState("");
  const [browserFiles, setBrowserFiles] = useState<any[]>([]);
  const [isBrowserLoading, setIsBrowserLoading] = useState(false);

  // MCP State
  const [mcpTools, setMcpTools] = useState<any[]>([]);
  const [mcpLogs, setMcpLogs] = useState<any[]>([]);
  const [isMcpConnecting, setIsMcpConnecting] = useState(false);
  const [mcpEventSource, setMcpEventSource] = useState<EventSource | null>(null);

  // Mainframe State
  const [systemStats, setSystemStats] = useState<any>(null);
  const [isMainframeInstalled, setIsMainframeInstalled] = useState(localStorage.getItem("mainframe_installed") === "true");
  const [isInstallingMainframe, setIsInstallingMainframe] = useState(false);
  const [installProgress, setInstallProgress] = useState(0);

  useEffect(() => {
    checkAuth();
  }, []);

  useEffect(() => {
    if (!user) return;
    fetchData();
    fetchSystemStats();
    fetchThreatHistory();
    const interval = setInterval(() => {
      fetchLogs();
      fetchSystemStats();
      fetchData();
      fetchThreatHistory();
      if (isScanning) {
        // Keep the "meticulous scan" logs for flavor, but mix with real logs
        const newLog = {
          id: Date.now(),
          msg: `[${GUNDAM_SERVICES[Math.floor(Math.random() * GUNDAM_SERVICES.length)].language}] Meticulous scan: No domineering vectors detected.`,
          type: "info"
        };
        setLogs(prev => [newLog, ...prev].slice(0, 50));
      }
    }, 3000);
    return () => clearInterval(interval);
  }, [isScanning, user]);

  const checkAuth = async () => {
    try {
      const res = await fetch("/api/auth/me");
      if (res.ok) {
        const data = await res.json();
        setUser(data.user);
        setUserSettings(data.settings);
      }
    } catch (err) {
      console.error("Auth check failed:", err);
    } finally {
      setIsAuthLoading(false);
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError("");
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username: authUsername, password: authPassword })
      });
      const data = await res.json();
      if (res.ok) {
        checkAuth();
      } else {
        setAuthError(data.error || "Login failed");
      }
    } catch (err) {
      setAuthError("Network error");
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError("");
    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username: authUsername, password: authPassword })
      });
      const data = await res.json();
      if (res.ok) {
        setAuthMode("login");
        setAuthError("Registration successful. Please login.");
      } else {
        setAuthError(data.error || "Registration failed");
      }
    } catch (err) {
      setAuthError("Network error");
    }
  };

  const handleLogout = async () => {
    await fetch("/api/auth/logout", { method: "POST" });
    setUser(null);
    setUserSettings(null);
    setActiveTab("dashboard");
  };

  const updateSettings = async (newSettings: any) => {
    try {
      const res = await fetch("/api/user/settings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newSettings)
      });
      if (res.ok) {
        setUserSettings({ ...userSettings, ...newSettings });
      }
    } catch (err) {
      console.error("Failed to update settings:", err);
    }
  };

  useEffect(() => {
    if (selectedDiscordBot) {
      fetch(`/api/discord/guilds/${selectedDiscordBot}`)
        .then(res => res.json())
        .then(data => {
          if (Array.isArray(data)) setDiscordGuilds(data);
          else setDiscordGuilds([]);
        });
    } else {
      setDiscordGuilds([]);
      setSelectedGuild(null);
    }
  }, [selectedDiscordBot]);

  useEffect(() => {
    if (selectedDiscordBot && selectedGuild) {
      fetch(`/api/discord/channels/${selectedDiscordBot}/${selectedGuild}`)
        .then(res => res.json())
        .then(data => {
          if (Array.isArray(data)) setDiscordChannels(data);
          else setDiscordChannels([]);
        });
    } else {
      setDiscordChannels([]);
      setSelectedChannel(null);
    }
  }, [selectedDiscordBot, selectedGuild]);

  useEffect(() => {
    if (activeTab === "mesh") {
      callMcpTool('multilingual_core_status', {}).then(res => {
        if (res.cores) setMeshCores(res.cores);
      });
    }
  }, [activeTab]);

  const fetchLogs = async () => {
    try {
      const res = await fetch("/api/logs");
      const data = await res.json();
      // Map server logs to the UI format
      const serverLogs = data.map((l: any) => ({
        id: l.id,
        msg: `[Bot ${l.bot_id.slice(0,4)}] ${l.message}`,
        type: l.type,
        timestamp: l.timestamp
      }));
      setLogs(prev => {
        // Merge and deduplicate by ID if possible, or just replace
        // For simplicity, we'll just merge and sort
        const combined = [...serverLogs, ...prev.filter(p => !p.timestamp)]; // Keep scanning logs
        return combined.sort((a, b) => (b.id || b.timestamp) - (a.id || a.timestamp)).slice(0, 50);
      });
    } catch (err) {
      console.error("Logs fetch error:", err);
    }
  };

  const fetchThreatHistory = async () => {
    try {
      const res = await fetch("/api/threats/history");
      const data = await res.json();
      setThreatHistory(data);
    } catch (err) {
      console.error("Failed to fetch threat history:", err);
    }
  };

  const fetchData = async () => {
    try {
      const [b, m, w, mod, lilith, agents] = await Promise.all([
        fetch("/api/bots").then(r => r.json()),
        fetch("/api/models").then(r => r.json()),
        fetch("/api/webhooks").then(r => r.json()),
        fetch("/api/system/modules").then(r => r.json()),
        fetch("/api/lilith/nec").then(r => r.json()),
        fetch("/api/lilith/agents").then(r => r.json())
      ]);
      setBots(b);
      setModels(m);
      setWebhooks(w);
      setMainframeModules(mod);
      setLilithData({ ...lilith, agents });
    } catch (err) {
      console.error("Fetch error:", err);
    }
  };

  const handleDeployBot = async () => {
    if (!newBotName || !newBotToken) return;
    await fetch("/api/bots", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: uuidv4(), name: newBotName, token: newBotToken, status: "deploying" })
    });
    setNewBotName("");
    setNewBotToken("");
    setIsDeployModalOpen(false);
    fetchData();
    
    // Simulate deployment progress
    setTimeout(() => {
      setLogs(prev => [{ id: Date.now(), msg: `[System] Bot "${newBotName}" successfully deployed to edge node.`, type: "success" }, ...prev]);
      fetchData(); // Refresh to show "online" status if I had logic for it
    }, 3000);
  };

  const toggleBotStatus = async (bot: any) => {
    const newStatus = bot.status === "online" ? "offline" : "online";
    await fetch("/api/bots", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...bot, status: newStatus })
    });
    fetchData();
    setLogs(prev => [{ id: Date.now(), msg: `[System] Bot "${bot.name}" status changed to ${newStatus}.`, type: "info" }, ...prev]);
  };

  const deleteBot = async (id: string) => {
    if (!confirm("Are you sure you want to decommission this bot?")) return;
    await fetch(`/api/bots/${id}`, { method: "DELETE" });
    fetchData();
    setLogs(prev => [{ id: Date.now(), msg: `[System] Bot instance ${id.slice(0,8)} decommissioned.`, type: "warning" }, ...prev]);
  };

  const handleAddModel = async () => {
    if (!newModelName || !newModelPath) return;
    const id = uuidv4();
    const newModel = { id, name: newModelName, path: newModelPath, type: "GGUF" };
    
    setLogs(prev => [{ id: Date.now(), msg: `[System] Attempting to mount GGUF vault: ${newModelName}...`, type: "info" }, ...prev]);
    
    try {
      const res = await fetch("/api/models", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newModel)
      });
      const data = await res.json();
      
      if (data.success) {
        setLogs(prev => [{ id: Date.now(), msg: `[System] GGUF Model "${newModelName}" mounted successfully.`, type: "success" }, ...prev]);
      } else {
        setLogs(prev => [{ id: Date.now(), msg: `[Error] Failed to mount model: ${data.error}`, type: "error" }, ...prev]);
      }
    } catch (err) {
      setLogs(prev => [{ id: Date.now(), msg: `[Error] Network failure during model mount.`, type: "error" }, ...prev]);
    }
    
    setNewModelName("");
    setNewModelPath("");
    setIsModelModalOpen(false);
    fetchData();
  };

  const testModel = async (model: any) => {
    setTestingModelId(model.id);
    const startTime = Date.now();
    setLogs(prev => [{ id: Date.now(), msg: `[Benchmark] Initiating latency test for ${model.name}...`, type: "info" }, ...prev]);
    
    try {
      const res = await fetch("/api/models/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: model.id, message: "Hello, confirm your status." })
      });
      const data = await res.json();
      const endTime = Date.now();
      const latency = endTime - startTime;
      
      if (data.response) {
        setLogs(prev => [{ id: Date.now(), msg: `[Benchmark] ${model.name} responded in ${latency}ms. Status: METICULOUS.`, type: "success" }, ...prev]);
        alert(`Model Response: ${data.response}\nLatency: ${latency}ms`);
      } else {
        setLogs(prev => [{ id: Date.now(), msg: `[Benchmark] ${model.name} failed to respond.`, type: "error" }, ...prev]);
      }
    } catch (err) {
      setLogs(prev => [{ id: Date.now(), msg: `[Benchmark] Error testing ${model.name}.`, type: "error" }, ...prev]);
    } finally {
      setTestingModelId(null);
    }
  };

  const deleteModel = async (id: string) => {
    if (!confirm("Are you sure you want to unmount this model?")) return;
    await fetch(`/api/models/${id}`, { method: "DELETE" });
    fetchData();
  };

  const fetchFiles = async (path?: string) => {
    setIsBrowserLoading(true);
    try {
      const url = path ? `/api/files/list?path=${encodeURIComponent(path)}` : "/api/files/list";
      const res = await fetch(url);
      const data = await res.json();
      if (res.ok) {
        setCurrentPath(data.currentPath);
        setBrowserFiles(data.files);
      }
    } catch (err) {
      console.error("Failed to fetch files:", err);
    } finally {
      setIsBrowserLoading(false);
    }
  };

  const handleBrowseFiles = () => {
    setIsFileBrowserOpen(true);
    fetchFiles();
  };

  const navigateUp = () => {
    const parts = currentPath.split("/");
    parts.pop();
    const parentPath = parts.join("/") || "/";
    fetchFiles(parentPath);
  };

  const addWebhook = async () => {
    const name = prompt("Webhook Name:");
    const url = prompt("Webhook URL:");
    if (!name || !url) return;
    await fetch("/api/webhooks", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: uuidv4(), name, url })
    });
    fetchData();
  };

  const testWebhook = async (url: string) => {
    const msg = prompt("Test Message:", "G.U.N.D.A.M. system check operational.");
    if (!msg) return;
    const res = await fetch("/api/webhooks/test", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url, message: msg })
    });
    const data = await res.json();
    alert(data.success ? "Webhook fired successfully!" : "Webhook failed.");
  };

  const connectMcp = () => {
    if (mcpEventSource) return;
    setIsMcpConnecting(true);
    const es = new EventSource("/api/mcp/sse");
    
    es.onopen = () => {
      setIsMcpConnecting(false);
      setMcpLogs(prev => [...prev, { type: 'info', msg: 'MCP Connection established via SSE' }]);
      // Fetch tools once connected
      fetchMcpTools();
    };

    es.onerror = (e) => {
      console.error("MCP SSE Error:", e);
      setMcpLogs(prev => [...prev, { type: 'error', msg: 'MCP Connection failed' }]);
      setIsMcpConnecting(false);
      es.close();
      setMcpEventSource(null);
    };

    setMcpEventSource(es);
  };

  const fetchMcpTools = async () => {
    try {
      // In a real MCP client, we'd send a JSON-RPC request over the transport.
      // For this demo, we'll simulate the tool discovery by hitting the same logic.
      const res = await fetch("/api/mcp/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 1,
          method: "tools/list",
          params: {}
        })
      });
      const data = await res.json();
      if (data.result?.tools) {
        setMcpTools(data.result.tools);
      }
    } catch (err) {
      console.error("Failed to fetch MCP tools:", err);
    }
  };

  const fetchSystemStats = async () => {
    try {
      const res = await fetch("/api/system/stats");
      const data = await res.json();
      setSystemStats(data);
    } catch (err) {
      console.error("Failed to fetch system stats:", err);
    }
  };

  const runHygiene = async () => {
    setLogs(prev => [{ id: Date.now(), msg: "[Hygieia] Initiating Operative Deadman Sub-cycle (Absorbing B=6)...", type: "warning" }, ...prev]);
    try {
      const res = await fetch("/api/system/hygiene", { method: "POST" });
      const data = await res.json();
      if (data.success) {
        setLogs(prev => [{ id: Date.now(), msg: `[Hygieia] Sigma-Closure: ${data.sigma_closure.toFixed(8)} (${data.status}). Lattice Level: ${data.lattice_level}.`, type: "success" }, ...prev]);
        alert(`Hygiene Complete.\nSigma-Closure: ${data.sigma_closure.toFixed(8)}\nStatus: ${data.status}`);
      }
    } catch (err) {
      setLogs(prev => [{ id: Date.now(), msg: "[Hygieia] Hygiene sub-cycle failed to stabilize.", type: "error" }, ...prev]);
    }
  };

  const installMainframe = () => {
    setIsInstallingMainframe(true);
    setInstallProgress(0);
    const interval = setInterval(() => {
      setInstallProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setIsInstallingMainframe(false);
          setIsMainframeInstalled(true);
          localStorage.setItem("mainframe_installed", "true");
          setLogs(prevLogs => [{ id: Date.now(), msg: "[System] Mainframe Core successfully installed and initialized.", type: "success" }, ...prevLogs]);
          return 100;
        }
        return prev + 2;
      });
    }, 50);
  };

  if (isAuthLoading) {
    return (
      <div className="h-screen bg-[#0E0E10] flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-indigo-500 flex items-center justify-center animate-pulse shadow-[0_0_30px_rgba(99,102,241,0.5)]">
            <ShieldAlert className="w-7 h-7 text-white" />
          </div>
          <p className="text-[10px] uppercase tracking-[0.2em] text-white/20 font-mono">Initializing Core...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="h-screen bg-[#0E0E10] flex items-center justify-center p-6">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="w-full max-w-md bg-[#121214] border border-white/10 rounded-[2.5rem] p-10 shadow-2xl"
        >
          <div className="flex flex-col items-center mb-10">
            <div className="w-16 h-16 rounded-3xl bg-indigo-500 flex items-center justify-center mb-6 shadow-[0_0_40px_rgba(99,102,241,0.3)]">
              <ShieldAlert className="w-9 h-9 text-white" />
            </div>
            <h1 className="text-3xl font-bold tracking-tighter mb-2">G.U.N.D.A.M.</h1>
            <p className="text-xs uppercase tracking-widest text-white/30 font-mono">Project Meticulous Access</p>
          </div>

          <form onSubmit={authMode === "login" ? handleLogin : handleRegister} className="space-y-6">
            <div>
              <label className="block text-[10px] uppercase tracking-widest text-white/30 font-mono mb-2 ml-1">Username</label>
              <div className="relative">
                <input 
                  type="text"
                  value={authUsername}
                  onChange={(e) => setAuthUsername(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-sm focus:outline-none focus:border-indigo-500/50 transition-all pl-12"
                  placeholder="meticulous_admin"
                  required
                />
                <User className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-white/20" />
              </div>
            </div>
            <div>
              <label className="block text-[10px] uppercase tracking-widest text-white/30 font-mono mb-2 ml-1">Password</label>
              <div className="relative">
                <input 
                  type="password"
                  value={authPassword}
                  onChange={(e) => setAuthPassword(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-sm focus:outline-none focus:border-indigo-500/50 transition-all pl-12"
                  placeholder="••••••••"
                  required
                />
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-white/20" />
              </div>
            </div>

            {authError && (
              <div className="p-4 rounded-2xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs font-medium">
                {authError}
              </div>
            )}

            <button 
              type="submit"
              className="w-full py-4 rounded-2xl bg-indigo-500 hover:bg-indigo-400 text-white font-bold shadow-lg shadow-indigo-500/20 transition-all"
            >
              {authMode === "login" ? "Authorize Access" : "Create Account"}
            </button>
          </form>

          <div className="mt-8 text-center">
            <button 
              onClick={() => {
                setAuthMode(authMode === "login" ? "register" : "login");
                setAuthError("");
              }}
              className="text-white/40 hover:text-indigo-400 text-xs font-medium transition-colors"
            >
              {authMode === "login" ? "Need an account? Register" : "Already have an account? Login"}
            </button>
          </div>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-[#0E0E10] text-[#E1E1E3] font-sans selection:bg-indigo-500/30 overflow-hidden">
      {/* Sidebar */}
      <div className="w-20 md:w-64 border-r border-white/5 flex flex-col bg-[#09090B]">
        <div className="p-6">
          <div className="flex items-center gap-3 mb-8">
            <div className="w-10 h-10 rounded-xl bg-indigo-500 flex items-center justify-center shadow-[0_0_20px_rgba(99,102,241,0.4)]">
              <ShieldAlert className="w-6 h-6 text-white" />
            </div>
            <div className="hidden md:block">
              <h1 className="text-lg font-bold tracking-tighter">G.U.N.D.A.M.</h1>
              <p className="text-[10px] uppercase tracking-widest text-white/30 font-mono">Project Meticulous</p>
            </div>
          </div>

          <nav className="space-y-1">
            {[
              { id: "dashboard", icon: Activity, label: "Overview" },
              { id: "dev-panel", icon: Command, label: "Developer Panel" },
              { id: "bots", icon: Bot, label: "Bot Deployment" },
              { id: "models", icon: BrainCircuit, label: "GGUF Models" },
              { id: "webhooks", icon: Webhook, label: "Webhooks" },
              { id: "monitoring", icon: Radio, label: "Live Monitor" },
              { id: "mcp-console", icon: Terminal, label: "MCP Console" },
              { id: "lilith-swarm", icon: Users, label: "Lilith Swarm" },
              { id: "discord", icon: MessageSquare, label: "Discord" },
              { id: "mesh", icon: Layers, label: "Multilingual Mesh" },
              { id: "shaping", icon: PenTool, label: "Shaping & Breadboarding" },
              { id: "space-ops", icon: Telescope, label: "Space Ops" },
              { id: "mainframe", icon: Server, label: "Mainframe" },
              { id: "settings", icon: Settings, label: "User Settings" }
            ].map((item) => (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all ${
                  activeTab === item.id 
                  ? "bg-white/5 text-indigo-400 border border-white/10" 
                  : "text-white/40 hover:text-white/60 hover:bg-white/[0.02]"
                }`}
              >
                <item.icon className="w-5 h-5 shrink-0" />
                <span className="hidden md:block text-sm font-medium">{item.label}</span>
              </button>
            ))}
          </nav>
        </div>

        <div className="mt-auto p-6 border-t border-white/5 space-y-4">
          <div className="flex items-center justify-between px-2">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-indigo-500/20 flex items-center justify-center border border-indigo-500/40">
                <User className="w-4 h-4 text-indigo-400" />
              </div>
              <div className="hidden md:block">
                <p className="text-xs font-bold truncate max-w-[100px]">{user.username}</p>
                <p className="text-[8px] uppercase tracking-widest text-white/20 font-mono">Operator</p>
              </div>
            </div>
            <button 
              onClick={handleLogout}
              className="p-2 text-white/20 hover:text-red-400 transition-colors"
              title="Logout"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
          <div className="flex items-center gap-3 px-2 py-1">
            <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span className="hidden md:block text-[10px] uppercase tracking-widest text-white/40 font-mono">System Online</span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-16 border-b border-white/5 flex items-center justify-between px-8 bg-[#09090B]/50 backdrop-blur-xl">
          <div className="flex items-center gap-4">
            <h2 className="text-sm font-semibold uppercase tracking-widest text-white/60">{activeTab.replace("-", " ")}</h2>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white/5 border border-white/10">
              <Lock className="w-3.5 h-3.5 text-indigo-400" />
              <span className="text-[10px] uppercase tracking-widest text-white/40 font-mono">ToS Compliant Wrapper</span>
            </div>
            <button 
              onClick={() => setIsScanning(!isScanning)}
              className={`px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-widest transition-all ${
                isScanning 
                ? "bg-red-500/10 text-red-500 border border-red-500/20" 
                : "bg-indigo-500 text-white shadow-[0_0_20px_rgba(99,102,241,0.3)]"
              }`}
            >
              {isScanning ? "Stop Scan" : "Initialize Scan"}
            </button>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-8">
          <AnimatePresence mode="wait">
            {activeTab === "dashboard" && (
              <motion.div 
                key="dashboard"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="space-y-8"
              >
                {/* Quick Actions */}
                <div className="flex items-center gap-4">
                  <button 
                    onClick={() => setIsDeployModalOpen(true)}
                    className="flex items-center gap-2 px-6 py-3 rounded-2xl bg-indigo-500 hover:bg-indigo-400 text-white font-bold shadow-lg shadow-indigo-500/20 transition-all"
                  >
                    <Plus className="w-5 h-5" />
                    Quick Deploy Bot
                  </button>
                  <button 
                    onClick={() => setIsModelModalOpen(true)}
                    className="flex items-center gap-2 px-6 py-3 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 text-white/80 font-bold transition-all"
                  >
                    <BrainCircuit className="w-5 h-5 text-emerald-400" />
                    Load Model
                  </button>
                </div>

                {/* Stats Grid */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                  {[
                    { label: "Active Bots", value: bots.length.toString(), icon: Bot, color: "text-indigo-400" },
                    { label: "GGUF Models", value: models.length.toString(), icon: BrainCircuit, color: "text-emerald-400" },
                    { label: "Webhooks", value: webhooks.length.toString(), icon: Webhook, color: "text-amber-400" },
                    { label: "System Nodes", value: "4", icon: Cpu, color: "text-cyan-400" }
                  ].map((stat, i) => (
                    <div key={i} className="p-6 rounded-2xl bg-[#121214] border border-white/5 hover:border-white/10 transition-all">
                      <div className="flex items-center justify-between mb-4">
                        <stat.icon className={`w-5 h-5 ${stat.color}`} />
                        <span className="text-[10px] font-mono text-white/20">0{i+1}</span>
                      </div>
                      <p className="text-2xl font-bold tracking-tight">{stat.value}</p>
                      <p className="text-xs text-white/40 font-medium">{stat.label}</p>
                    </div>
                  ))}
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                  <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                    <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
                      <Layers className="w-5 h-5 text-indigo-400" />
                      Multi-Language Core Engine
                    </h3>
                    <div className="space-y-4">
                      {GUNDAM_SERVICES.map((service) => (
                        <div key={service.name} className={`p-4 rounded-2xl bg-white/[0.02] border border-white/5 flex items-center justify-between`}>
                          <div>
                            <p className={`font-bold text-white/80`}>{service.name}</p>
                            <p className="text-[10px] text-white/30 uppercase tracking-widest font-mono">{service.language} • {service.role}</p>
                          </div>
                          <div className="flex items-center gap-2">
                            <div className={`w-1.5 h-1.5 rounded-full ${service.status === "online" ? "bg-emerald-500" : "bg-red-500"}`} />
                            <span className="text-[10px] font-mono text-white/40 uppercase">{service.status}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="p-8 rounded-3xl bg-[#121214] border border-white/5 flex flex-col">
                    <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
                      <Radio className="w-5 h-5 text-indigo-400" />
                      System Logs
                    </h3>
                    <div className="flex-1 font-mono text-[11px] space-y-2 overflow-y-auto max-h-[300px] pr-4">
                      {logs.length > 0 ? logs.map(log => (
                        <div key={log.id} className="flex gap-3 text-white/40">
                          <span className="text-indigo-500/50 shrink-0">[{new Date(log.id).toLocaleTimeString()}]</span>
                          <span>{log.msg}</span>
                        </div>
                      )) : (
                        <div className="h-full flex items-center justify-center text-white/10 italic">
                          Initialize scan to begin monitoring...
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Threat Analysis History */}
                <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                  <div className="flex items-center justify-between mb-6">
                    <h3 className="text-lg font-bold flex items-center gap-2">
                      <ShieldAlert className="w-5 h-5 text-red-400" />
                      Recent Threat Analysis
                    </h3>
                    <button 
                      onClick={async () => {
                        const target = prompt("Enter target for analysis (e.g., system_core, network_node_7):");
                        if (!target) return;
                        setIsScanning(true);
                        await callMcpTool("analyze_threat", { target });
                        setIsScanning(false);
                        fetchThreatHistory();
                      }}
                      className="text-xs font-bold text-indigo-400 hover:text-indigo-300 uppercase tracking-widest"
                    >
                      Run New Scan
                    </button>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {threatHistory.length > 0 ? threatHistory.map((threat, i) => (
                      <div key={i} className="p-4 rounded-2xl bg-white/[0.02] border border-white/5">
                        <div className="flex items-center justify-between mb-2">
                          <span className="text-[10px] font-mono text-white/30 uppercase">{threat.target}</span>
                          <span className={`text-[10px] font-bold px-2 py-0.5 rounded ${
                            threat.threat_level === 'CRITICAL' ? 'bg-red-500/20 text-red-400' :
                            threat.threat_level === 'HIGH' ? 'bg-orange-500/20 text-orange-400' :
                            'bg-blue-500/20 text-blue-400'
                          }`}>
                            {threat.threat_level}
                          </span>
                        </div>
                        <p className="text-sm font-medium text-white/80 mb-2">{threat.findings}</p>
                        <div className="flex items-center justify-between text-[10px] text-white/20 font-mono">
                          <span>{new Date(threat.timestamp).toLocaleString()}</span>
                          <span className="uppercase">{threat.status}</span>
                        </div>
                      </div>
                    )) : (
                      <div className="col-span-full py-12 text-center border border-dashed border-white/5 rounded-2xl">
                        <p className="text-white/20 italic">No threat analysis data available.</p>
                      </div>
                    )}
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "dev-panel" && (
              <motion.div 
                key="dev-panel"
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="space-y-6"
              >
                <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                  <div className="flex items-center justify-between mb-8">
                    <div>
                      <h3 className="text-xl font-bold">Developer Control Plane</h3>
                      <p className="text-sm text-white/40">Meticulously manage G.U.N.D.A.M. infrastructure</p>
                    </div>
                    <div className="flex gap-2">
                      <button className="p-2 rounded-lg bg-white/5 border border-white/10 hover:bg-white/10"><Settings className="w-4 h-4" /></button>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="p-6 rounded-2xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all cursor-pointer" onClick={() => setActiveTab("bots")}>
                      <Bot className="w-8 h-8 text-indigo-400 mb-4" />
                      <h4 className="font-bold">Bot Factory</h4>
                      <p className="text-xs text-white/30 mt-1">Deploy and manage Discord bot instances</p>
                    </div>
                    <div className="p-6 rounded-2xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all cursor-pointer" onClick={() => setActiveTab("models")}>
                      <BrainCircuit className="w-8 h-8 text-emerald-400 mb-4" />
                      <h4 className="font-bold">Model Vault</h4>
                      <p className="text-xs text-white/30 mt-1">Manage GGUF local inference models</p>
                    </div>
                    <div className="p-6 rounded-2xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all cursor-pointer" onClick={() => setActiveTab("webhooks")}>
                      <Webhook className="w-8 h-8 text-amber-400 mb-4" />
                      <h4 className="font-bold">Hook Router</h4>
                      <p className="text-xs text-white/30 mt-1">Configure and test system webhooks</p>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "bots" && (
              <motion.div key="bots" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-xl font-bold">Bot Deployment Factory</h3>
                    <p className="text-sm text-white/40">Meticulously deploy and manage your Discord bot fleet</p>
                  </div>
                  <button onClick={() => setIsDeployModalOpen(true)} className="flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-500 text-white text-sm font-bold">
                    <Plus className="w-4 h-4" /> Deploy New Bot
                  </button>
                </div>
                
                <div className="grid grid-cols-1 gap-4">
                  {bots.map(bot => (
                    <div key={bot.id} className="p-6 rounded-2xl bg-[#121214] border border-white/5 flex items-center justify-between group hover:border-white/10 transition-all">
                      <div className="flex items-center gap-6">
                        <div className={`w-14 h-14 rounded-2xl flex items-center justify-center border transition-all ${
                          bot.status === "online" ? "bg-emerald-500/10 border-emerald-500/20 text-emerald-400" : "bg-white/5 border-white/10 text-white/20"
                        }`}>
                          <Bot className="w-7 h-7" />
                        </div>
                        <div>
                          <div className="flex items-center gap-3">
                            <p className="text-lg font-bold">{bot.name}</p>
                            <span className={`px-2 py-0.5 rounded-md text-[10px] uppercase font-bold ${
                              bot.status === "online" ? "bg-emerald-500/20 text-emerald-400" : 
                              bot.status === "deploying" ? "bg-amber-500/20 text-amber-400 animate-pulse" :
                              "bg-white/10 text-white/40"
                            }`}>
                              {bot.status}
                            </span>
                          </div>
                          <p className="text-xs text-white/30 font-mono mt-1">UUID: {bot.id}</p>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-4">
                        <div className="flex items-center gap-2 mr-4">
                          <button 
                            onClick={() => toggleBotStatus(bot)}
                            className={`p-2.5 rounded-xl border transition-all ${
                              bot.status === "online" 
                              ? "bg-red-500/10 border-red-500/20 text-red-400 hover:bg-red-500/20" 
                              : "bg-emerald-500/10 border-emerald-500/20 text-emerald-400 hover:bg-emerald-500/20"
                            }`}
                            title={bot.status === "online" ? "Stop Bot" : "Start Bot"}
                          >
                            {bot.status === "online" ? <Zap className="w-4 h-4 fill-current" /> : <Play className="w-4 h-4 fill-current" />}
                          </button>
                          <button className="p-2.5 rounded-xl bg-white/5 border border-white/10 text-white/40 hover:bg-white/10 transition-all">
                            <Settings className="w-4 h-4" />
                          </button>
                        </div>
                        <button 
                          onClick={() => deleteBot(bot.id)}
                          className="p-2.5 text-white/10 hover:text-red-400 transition-colors"
                        >
                          <Trash2 className="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  ))}
                  {bots.length === 0 && (
                    <div className="py-20 text-center border-2 border-dashed border-white/5 rounded-3xl">
                      <Bot className="w-12 h-12 mx-auto mb-4 text-white/10" />
                      <p className="text-white/20">No bots deployed in this sector.</p>
                      <button onClick={() => setIsDeployModalOpen(true)} className="mt-4 text-indigo-400 hover:text-indigo-300 text-sm font-bold">
                        Deploy your first bot instance
                      </button>
                    </div>
                  )}
                </div>
              </motion.div>
            )}

            {activeTab === "models" && (
              <motion.div key="models" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-xl font-bold">GGUF Model Vault</h3>
                    <p className="text-sm text-white/40">Meticulously manage and test local inference models</p>
                  </div>
                  <button onClick={() => setIsModelModalOpen(true)} className="flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-500 text-black text-sm font-bold">
                    <Plus className="w-4 h-4" /> Load GGUF Model
                  </button>
                </div>
                <div className="space-y-4">
                  {models.map(model => (
                    <div key={model.id} className="p-6 rounded-2xl bg-[#121214] border border-white/5 flex flex-col gap-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center border border-emerald-500/20">
                            <BrainCircuit className="w-6 h-6 text-emerald-400" />
                          </div>
                          <div>
                            <p className="text-lg font-bold">{model.name}</p>
                            <p className="text-xs text-white/30 font-mono">{model.path}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="text-[10px] font-mono text-emerald-500/50 uppercase px-2 py-1 rounded bg-emerald-500/5 border border-emerald-500/10">{model.type}</span>
                          
                          <button 
                            onClick={() => testModel(model)}
                            disabled={testingModelId === model.id}
                            className={`flex items-center gap-2 px-3 py-1.5 rounded-lg border transition-all text-[10px] font-bold uppercase ${
                              testingModelId === model.id 
                              ? "bg-white/5 border-white/10 text-white/20 cursor-not-allowed" 
                              : "bg-emerald-500/5 border-emerald-500/10 text-emerald-400 hover:bg-emerald-500/10"
                            }`}
                          >
                            <Activity className={`w-3 h-3 ${testingModelId === model.id ? "animate-spin" : ""}`} />
                            {testingModelId === model.id ? "Testing..." : "Benchmark"}
                          </button>

                          <button 
                            onClick={async () => {
                              const msg = prompt("Test Prompt:");
                              if (!msg) return;
                              const res = await fetch("/api/models/chat", {
                                method: "POST",
                                headers: { "Content-Type": "application/json" },
                                body: JSON.stringify({ id: model.id, message: msg })
                              });
                              const data = await res.json();
                              if (data.response) alert(`Model: ${data.response}`);
                              else alert(`Error: ${data.error || "Failed to get response"}`);
                            }}
                            className="p-2.5 rounded-xl bg-white/5 border border-white/10 text-white/40 hover:text-white/60 hover:bg-white/10 transition-all"
                            title="Chat Test"
                          >
                            <MessageSquare className="w-4 h-4" />
                          </button>

                          <button 
                            onClick={() => deleteModel(model.id)}
                            className="p-2.5 text-white/10 hover:text-red-400 transition-colors"
                            title="Unmount Model"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                  {models.length === 0 && (
                    <div className="py-20 text-center border-2 border-dashed border-white/5 rounded-3xl">
                      <BrainCircuit className="w-12 h-12 mx-auto mb-4 text-white/10" />
                      <p className="text-white/20">No models loaded in this sector.</p>
                    </div>
                  )}
                </div>
              </motion.div>
            )}

            {activeTab === "mcp-console" && (
              <motion.div key="mcp-console" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="h-full flex flex-col gap-6">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-xl font-bold">Model Context Protocol Console</h3>
                    <p className="text-sm text-white/40">Interact with G.U.N.D.A.M. tools via standardized MCP</p>
                  </div>
                  <button 
                    onClick={connectMcp}
                    disabled={!!mcpEventSource || isMcpConnecting}
                    className={`px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-widest transition-all ${
                      mcpEventSource 
                      ? "bg-emerald-500/10 text-emerald-500 border border-emerald-500/20" 
                      : "bg-indigo-500 text-white shadow-[0_0_20px_rgba(99,102,241,0.3)]"
                    }`}
                  >
                    {mcpEventSource ? "Connected" : isMcpConnecting ? "Connecting..." : "Connect MCP"}
                  </button>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 flex-1 min-h-0">
                  <div className="lg:col-span-1 flex flex-col gap-6 overflow-hidden">
                    <div className="p-6 rounded-3xl bg-[#121214] border border-white/5 flex flex-col overflow-hidden">
                      <h4 className="text-xs font-bold uppercase tracking-widest text-white/30 mb-4 flex items-center gap-2">
                        <Code className="w-3 h-3" /> Available Tools
                      </h4>
                      <div className="flex-1 overflow-y-auto space-y-3 pr-2">
                        {mcpTools.length > 0 ? mcpTools.map(tool => (
                          <div key={tool.name} className="p-4 rounded-2xl bg-white/[0.02] border border-white/5 hover:border-white/10 transition-all group">
                            <div className="flex items-center justify-between mb-2">
                              <p className="text-sm font-bold text-indigo-400">{tool.name}</p>
                              <button 
                                onClick={() => {
                                  const args = tool.name === 'analyze_threat' ? { content: prompt("Content to analyze:") } : 
                                               tool.name === 'run_agentic_decision' ? { botId: bots[0]?.id || 'test-bot' } :
                                               tool.name === 'dna_registry_check' ? { agentId: prompt("Agent ID to verify:") } :
                                               { toolName: "TEST_TOOL", args: {} };
                                  if (args.content === null || args.agentId === null) return;
                                  callMcpTool(tool.name, args);
                                }}
                                className="p-1.5 rounded-lg bg-indigo-500/10 text-indigo-400 opacity-0 group-hover:opacity-100 transition-all"
                              >
                                <Play className="w-3 h-3 fill-current" />
                              </button>
                            </div>
                            <p className="text-[10px] text-white/40 leading-relaxed">{tool.description}</p>
                          </div>
                        )) : (
                          <div className="h-full flex items-center justify-center text-white/10 italic text-center p-4">
                            Connect to MCP server to discover tools...
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="lg:col-span-2 flex flex-col gap-6 overflow-hidden">
                    <div className="p-6 rounded-3xl bg-[#09090B] border border-white/5 flex flex-col overflow-hidden font-mono text-xs">
                      <h4 className="text-xs font-bold uppercase tracking-widest text-white/30 mb-4 flex items-center gap-2">
                        <Terminal className="w-3 h-3" /> MCP Traffic Log
                      </h4>
                      <div className="flex-1 overflow-y-auto space-y-3 pr-2">
                        {mcpLogs.map((log, i) => (
                          <div key={i} className={`p-3 rounded-xl border ${
                            log.type === 'error' ? 'bg-red-500/5 border-red-500/10 text-red-400' :
                            log.type === 'call' ? 'bg-indigo-500/5 border-indigo-500/10 text-indigo-300' :
                            log.type === 'result' ? 'bg-emerald-500/5 border-emerald-500/10 text-emerald-300' :
                            'bg-white/5 border-white/10 text-white/40'
                          }`}>
                            <div className="flex items-center gap-2 mb-1 opacity-50">
                              <span className="text-[10px] uppercase tracking-widest">[{log.type}]</span>
                              <span className="text-[10px]">{new Date().toLocaleTimeString()}</span>
                            </div>
                            <p>{log.msg}</p>
                            {log.args && <pre className="mt-2 p-2 bg-black/40 rounded-lg overflow-x-auto">{JSON.stringify(log.args, null, 2)}</pre>}
                            {log.result && <pre className="mt-2 p-2 bg-black/40 rounded-lg overflow-x-auto">{JSON.stringify(log.result, null, 2)}</pre>}
                          </div>
                        ))}
                        {mcpLogs.length === 0 && (
                          <div className="h-full flex items-center justify-center text-white/10 italic">
                            Waiting for MCP activity...
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "mesh" && (
              <motion.div key="mesh" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-2xl font-bold tracking-tighter">Multilingual Mesh Core</h3>
                    <p className="text-sm text-white/40">Cross-language optimization engine (Rust, Julia, Elixir, Ballerina)</p>
                  </div>
                  <div className="flex gap-2">
                    {meshCores.map(core => (
                      <div key={core.name} className="px-3 py-1 rounded-full bg-white/5 border border-white/10 flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                        <span className="text-[10px] font-bold uppercase tracking-widest text-white/60">{core.name}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                  <div className="space-y-6">
                    <div className="p-8 rounded-[2rem] bg-[#121214] border border-white/5 space-y-6">
                      <div className="flex items-center justify-between">
                        <h4 className="text-lg font-bold flex items-center gap-2">
                          <Code className="w-5 h-5 text-indigo-400" /> Elixir Source
                        </h4>
                        <span className="text-[10px] font-mono text-white/20">SOURCE_LIB_V1</span>
                      </div>
                      <textarea 
                        value={elixirSource}
                        onChange={(e) => setElixirSource(e.target.value)}
                        placeholder="defmodule Gundam.Core do ..."
                        className="w-full h-64 p-6 rounded-2xl bg-black/40 border border-white/5 text-indigo-300 font-mono text-xs focus:outline-none focus:border-indigo-500/50 transition-all resize-none"
                      />
                      <button 
                        onClick={async () => {
                          setIsCompiling(true);
                          const res = await callMcpTool('elixir_rust_compile', { elixir_code: elixirSource });
                          if (res.rust_code) setCompiledRust(res.rust_code);
                          setIsCompiling(false);
                        }}
                        disabled={isCompiling || !elixirSource}
                        className="w-full py-4 rounded-2xl bg-indigo-500 text-white font-bold text-sm shadow-lg shadow-indigo-500/20 disabled:opacity-50 transition-all flex items-center justify-center gap-2"
                      >
                        {isCompiling ? "Compiling to Rust..." : "Compile to Optimized Rust"}
                      </button>
                    </div>
                  </div>

                  <div className="space-y-6">
                    <div className="p-8 rounded-[2rem] bg-[#121214] border border-white/5 space-y-6">
                      <div className="flex items-center justify-between">
                        <h4 className="text-lg font-bold flex items-center gap-2">
                          <Cpu className="w-5 h-5 text-emerald-400" /> Optimized Rust Output
                        </h4>
                        <span className="text-[10px] font-mono text-emerald-500/40">L5_COSMIC_RUNTIME</span>
                      </div>
                      <div className="w-full h-64 p-6 rounded-2xl bg-black/40 border border-white/5 overflow-y-auto">
                        <pre className="text-emerald-400 font-mono text-xs whitespace-pre-wrap">
                          {compiledRust || "// Output will appear here after compilation..."}
                        </pre>
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div className="p-4 rounded-2xl bg-white/[0.02] border border-white/5">
                          <p className="text-[10px] uppercase tracking-widest text-white/20 font-bold mb-1">Safety Level</p>
                          <p className="text-sm font-bold text-white/60">Memory Safe</p>
                        </div>
                        <div className="p-4 rounded-2xl bg-white/[0.02] border border-white/5">
                          <p className="text-[10px] uppercase tracking-widest text-white/20 font-bold mb-1">Concurrency</p>
                          <p className="text-sm font-bold text-white/60">Zero-Cost</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="p-8 rounded-[2rem] bg-[#121214] border border-white/5">
                  <h4 className="text-xs font-bold uppercase tracking-widest text-white/30 mb-6 flex items-center gap-2">
                    <Activity className="w-3 h-3" /> Core Registry
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    {meshCores.map(core => (
                      <div key={core.name} className="p-4 rounded-2xl bg-white/[0.02] border border-white/5 space-y-2">
                        <div className="flex items-center justify-between">
                          <span className="text-xs font-bold text-white/60">{core.name}</span>
                          <span className="text-[10px] font-mono text-emerald-500">{core.status}</span>
                        </div>
                        <p className="text-[10px] font-mono text-white/20 truncate">{core.path}</p>
                        <p className="text-[10px] font-mono text-white/40">v{core.version}</p>
                      </div>
                    ))}
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "shaping" && (
              <motion.div key="shaping" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-2xl font-bold tracking-tighter">Shaping & Breadboarding</h3>
                    <p className="text-sm text-white/40">Affordance mapping and ripple effect analysis (Inspired by Shape Up)</p>
                  </div>
                  <div className="flex gap-2">
                    <button 
                      onClick={async () => {
                        setIsRippleChecking(true);
                        const res = await callMcpTool('ripple_check', { component: "Mainframe", change: "Protocol 7 Upgrade" });
                        setRippleResults(res);
                        setIsRippleChecking(false);
                      }}
                      disabled={isRippleChecking}
                      className="px-4 py-2 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 text-xs font-bold flex items-center gap-2"
                    >
                      <GitBranch className="w-4 h-4" /> {isRippleChecking ? "Analyzing..." : "Ripple Check"}
                    </button>
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  <div className="lg:col-span-1 space-y-6">
                    <div className="p-6 rounded-3xl bg-[#121214] border border-white/5 space-y-4">
                      <h4 className="text-xs font-bold uppercase tracking-widest text-white/30 flex items-center gap-2">
                        <Plus className="w-3 h-3" /> Add Affordance
                      </h4>
                      <div className="space-y-4">
                        <div className="flex gap-2">
                          <button 
                            onClick={() => setAffordanceType("ui")}
                            className={`flex-1 py-2 rounded-xl text-[10px] font-bold uppercase tracking-widest transition-all ${affordanceType === "ui" ? "bg-indigo-500 text-white" : "bg-white/5 text-white/40"}`}
                          >
                            UI
                          </button>
                          <button 
                            onClick={() => setAffordanceType("code")}
                            className={`flex-1 py-2 rounded-xl text-[10px] font-bold uppercase tracking-widest transition-all ${affordanceType === "code" ? "bg-emerald-500 text-white" : "bg-white/5 text-white/40"}`}
                          >
                            Code
                          </button>
                        </div>
                        <input 
                          type="text"
                          value={newAffordance}
                          onChange={(e) => setNewAffordance(e.target.value)}
                          placeholder="Affordance name..."
                          className="w-full px-4 py-2 rounded-xl bg-black/40 border border-white/5 text-sm text-white focus:outline-none focus:border-indigo-500/50"
                        />
                        <button 
                          onClick={() => {
                            if (!newAffordance) return;
                            setShapingAffordances(prev => ({
                              ...prev,
                              [affordanceType]: [...prev[affordanceType], newAffordance]
                            }));
                            setNewAffordance("");
                          }}
                          className="w-full py-2 rounded-xl bg-white/5 border border-white/10 text-white/60 text-xs font-bold hover:bg-white/10 transition-all"
                        >
                          Add to {affordanceType.toUpperCase()}
                        </button>
                      </div>
                    </div>

                    {rippleResults && (
                      <div className="p-6 rounded-3xl bg-[#121214] border border-white/5 space-y-4">
                        <h4 className="text-xs font-bold uppercase tracking-widest text-white/30 flex items-center gap-2">
                          <Activity className="w-3 h-3" /> Ripple Analysis
                        </h4>
                        <div className="space-y-3">
                          {rippleResults.ripples.map((r: any, i: number) => (
                            <div key={i} className="p-3 rounded-xl bg-white/[0.02] border border-white/5 space-y-1">
                              <div className="flex items-center justify-between">
                                <span className="text-[10px] font-bold text-white/60">{r.target}</span>
                                <span className={`text-[8px] font-bold px-1.5 py-0.5 rounded ${
                                  r.impact === 'CRITICAL' ? 'bg-red-500/20 text-red-400' :
                                  r.impact === 'HIGH' ? 'bg-orange-500/20 text-orange-400' :
                                  'bg-indigo-500/20 text-indigo-400'
                                }`}>{r.impact}</span>
                              </div>
                              <p className="text-[10px] text-white/30 leading-relaxed">{r.reason}</p>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="lg:col-span-2 space-y-6">
                    <div className="p-8 rounded-[3rem] bg-[#121214] border border-white/5 space-y-8">
                      <div className="grid grid-cols-2 gap-12">
                        <div className="space-y-4">
                          <h5 className="text-xs font-bold uppercase tracking-widest text-white/20 text-center">UI Affordances</h5>
                          <div className="space-y-2">
                            {shapingAffordances.ui.map((ui, i) => (
                              <div key={i} className="p-4 rounded-2xl bg-indigo-500/5 border border-indigo-500/10 text-indigo-300 text-sm font-medium text-center relative group">
                                {ui}
                                <button 
                                  onClick={() => {
                                    setShapingAffordances(prev => ({ ...prev, ui: prev.ui.filter((_, idx) => idx !== i) }));
                                    setShapingConnections(prev => prev.filter(c => c.from !== ui));
                                  }}
                                  className="absolute -right-2 -top-2 w-5 h-5 rounded-full bg-red-500 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all"
                                >
                                  <Trash2 className="w-3 h-3" />
                                </button>
                              </div>
                            ))}
                          </div>
                        </div>
                        <div className="space-y-4">
                          <h5 className="text-xs font-bold uppercase tracking-widest text-white/20 text-center">Code Affordances</h5>
                          <div className="space-y-2">
                            {shapingAffordances.code.map((code, i) => (
                              <div key={i} className="p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/10 text-emerald-300 text-sm font-mono text-center relative group">
                                {code}
                                <button 
                                  onClick={() => {
                                    setShapingAffordances(prev => ({ ...prev, code: prev.code.filter((_, idx) => idx !== i) }));
                                    setShapingConnections(prev => prev.filter(c => c.to !== code));
                                  }}
                                  className="absolute -left-2 -top-2 w-5 h-5 rounded-full bg-red-500 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all"
                                >
                                  <Trash2 className="w-3 h-3" />
                                </button>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>

                      <div className="pt-8 border-t border-white/5 space-y-4">
                        <h5 className="text-xs font-bold uppercase tracking-widest text-white/20">Wiring (Connections)</h5>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div className="p-4 rounded-2xl bg-white/[0.02] border border-white/5 space-y-4">
                            <div className="flex gap-2">
                              <select 
                                className="flex-1 bg-black/40 border border-white/5 rounded-xl px-3 py-2 text-xs text-white/60 focus:outline-none"
                                id="ui-select"
                              >
                                {shapingAffordances.ui.map(ui => <option key={ui} value={ui}>{ui}</option>)}
                              </select>
                              <div className="flex items-center text-white/20"><LinkIcon className="w-4 h-4" /></div>
                              <select 
                                className="flex-1 bg-black/40 border border-white/5 rounded-xl px-3 py-2 text-xs text-white/60 focus:outline-none"
                                id="code-select"
                              >
                                {shapingAffordances.code.map(code => <option key={code} value={code}>{code}</option>)}
                              </select>
                            </div>
                            <button 
                              onClick={() => {
                                const ui = (document.getElementById('ui-select') as HTMLSelectElement).value;
                                const code = (document.getElementById('code-select') as HTMLSelectElement).value;
                                if (ui && code && !shapingConnections.some(c => c.from === ui && c.to === code)) {
                                  setShapingConnections(prev => [...prev, { from: ui, to: code }]);
                                }
                              }}
                              className="w-full py-2 rounded-xl bg-indigo-500 text-white text-xs font-bold shadow-lg shadow-indigo-500/20"
                            >
                              Wire Affordances
                            </button>
                          </div>
                          <div className="max-h-48 overflow-y-auto space-y-2 pr-2">
                            {shapingConnections.map((conn, i) => (
                              <div key={i} className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                                <div className="flex items-center gap-3 text-[10px]">
                                  <span className="text-indigo-400 font-bold">{conn.from}</span>
                                  <Zap className="w-3 h-3 text-white/20" />
                                  <span className="text-emerald-400 font-mono">{conn.to}</span>
                                </div>
                                <button 
                                  onClick={() => setShapingConnections(prev => prev.filter((_, idx) => idx !== i))}
                                  className="text-white/20 hover:text-red-400 transition-colors"
                                >
                                  <Trash2 className="w-3 h-3" />
                                </button>
                              </div>
                            ))}
                            {shapingConnections.length === 0 && (
                              <p className="text-[10px] text-white/20 italic text-center py-8">No connections established.</p>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "discord" && (
              <motion.div key="discord" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-2xl font-bold tracking-tighter">Discord Command Center</h3>
                    <p className="text-sm text-white/40">Manage servers and transmit through legally marked bots</p>
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  <div className="lg:col-span-1 space-y-6">
                    <div className="p-6 rounded-3xl bg-[#121214] border border-white/5">
                      <h4 className="text-xs font-bold uppercase tracking-widest text-white/30 mb-4 flex items-center gap-2">
                        <Activity className="w-3 h-3" /> Active Bots
                      </h4>
                      <div className="space-y-2">
                        {bots.filter(b => b.status === 'online').map(bot => (
                          <button 
                            key={bot.id}
                            onClick={() => setSelectedDiscordBot(bot.id)}
                            className={`w-full p-4 rounded-2xl border text-left transition-all ${selectedDiscordBot === bot.id ? "bg-indigo-500/10 border-indigo-500/30 text-indigo-400" : "bg-white/[0.02] border-white/5 text-white/60 hover:bg-white/[0.04]"}`}
                          >
                            <p className="font-bold text-sm">{bot.name}</p>
                            <p className="text-[10px] opacity-50 font-mono">{bot.id}</p>
                          </button>
                        ))}
                        {bots.filter(b => b.status === 'online').length === 0 && (
                          <p className="text-xs text-white/20 italic text-center py-4">No online bots available.</p>
                        )}
                      </div>
                    </div>

                    {selectedDiscordBot && (
                      <div className="p-6 rounded-3xl bg-[#121214] border border-white/5">
                        <h4 className="text-xs font-bold uppercase tracking-widest text-white/30 mb-4 flex items-center gap-2">
                          <Server className="w-3 h-3" /> Target Guild
                        </h4>
                        <div className="space-y-2">
                          {discordGuilds.map(guild => (
                            <button 
                              key={guild.id}
                              onClick={() => setSelectedGuild(guild.id)}
                              className={`w-full p-4 rounded-2xl border text-left transition-all ${selectedGuild === guild.id ? "bg-indigo-500/10 border-indigo-500/30 text-indigo-400" : "bg-white/[0.02] border-white/5 text-white/60 hover:bg-white/[0.04]"}`}
                            >
                              <p className="font-bold text-sm">{guild.name}</p>
                              <p className="text-[10px] opacity-50 font-mono">{guild.memberCount} members</p>
                            </button>
                          ))}
                          {discordGuilds.length === 0 && (
                            <p className="text-xs text-white/20 italic text-center py-4">No guilds found for this bot.</p>
                          )}
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="lg:col-span-2 space-y-6">
                    {selectedGuild ? (
                      <div className="p-8 rounded-3xl bg-[#121214] border border-white/5 space-y-8">
                        <div className="flex items-center justify-between">
                          <h4 className="text-lg font-bold">Server Management</h4>
                          <div className="flex gap-2">
                            <button 
                              onClick={async () => {
                                const targetId = prompt("Enter User ID to kick:");
                                const reason = prompt("Reason:");
                                if (!targetId) return;
                                await callMcpTool('discord_manage_server', { botId: selectedDiscordBot, guildId: selectedGuild, action: 'kick', targetId, reason });
                              }}
                              className="px-3 py-1.5 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-[10px] font-bold uppercase tracking-widest"
                            >
                              Kick Member
                            </button>
                            <button 
                              onClick={async () => {
                                const channelName = prompt("Enter Channel Name:");
                                if (!channelName) return;
                                await callMcpTool('discord_manage_server', { botId: selectedDiscordBot, guildId: selectedGuild, action: 'create_channel', channelName });
                              }}
                              className="px-3 py-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[10px] font-bold uppercase tracking-widest"
                            >
                              Create Channel
                            </button>
                          </div>
                        </div>

                        <div className="space-y-4">
                          <h5 className="text-xs font-bold uppercase tracking-widest text-white/30">Transmit Message</h5>
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div className="space-y-2">
                              <p className="text-[10px] uppercase tracking-widest text-white/20 font-bold">Select Channel</p>
                              <div className="max-h-48 overflow-y-auto space-y-1 pr-2">
                                {discordChannels.map(ch => (
                                  <button 
                                    key={ch.id}
                                    onClick={() => setSelectedChannel(ch.id)}
                                    className={`w-full p-3 rounded-xl border text-left transition-all ${selectedChannel === ch.id ? "bg-indigo-500/10 border-indigo-500/30 text-indigo-400" : "bg-white/[0.02] border-white/5 text-white/40 hover:bg-white/[0.04]"}`}
                                  >
                                    <p className="text-xs font-bold"># {ch.name}</p>
                                  </button>
                                ))}
                              </div>
                            </div>
                            <div className="space-y-4">
                              <div className="space-y-2">
                                <p className="text-[10px] uppercase tracking-widest text-white/20 font-bold">Message Content</p>
                                <textarea 
                                  value={discordMessage}
                                  onChange={(e) => setDiscordMessage(e.target.value)}
                                  placeholder="Enter transmission content..."
                                  className="w-full h-32 p-4 rounded-2xl bg-white/[0.02] border border-white/5 text-white text-sm focus:outline-none focus:border-indigo-500/50 transition-all resize-none"
                                />
                              </div>
                              <button 
                                onClick={async () => {
                                  if (!selectedChannel || !discordMessage) return;
                                  const res = await fetch("/api/discord/message", {
                                    method: "POST",
                                    headers: { "Content-Type": "application/json" },
                                    body: JSON.stringify({ botId: selectedDiscordBot, channelId: selectedChannel, message: discordMessage })
                                  });
                                  const data = await res.json();
                                  if (data.success) {
                                    setDiscordMessage("");
                                    alert("Transmission successful.");
                                  } else {
                                    alert(`Error: ${data.error}`);
                                  }
                                }}
                                disabled={!selectedChannel || !discordMessage}
                                className="w-full py-3 rounded-2xl bg-indigo-500 text-white font-bold text-sm shadow-lg shadow-indigo-500/20 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                              >
                                Send Legally Marked Message
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    ) : (
                      <div className="h-full flex flex-col items-center justify-center p-12 rounded-[3rem] bg-[#121214] border border-white/5 text-center">
                        <MessageSquare className="w-16 h-16 text-white/5 mb-6" />
                        <h4 className="text-xl font-bold text-white/20">Select a Bot and Guild to begin management</h4>
                      </div>
                    )}
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "lilith-swarm" && (
              <motion.div key="lilith-swarm" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-2xl font-bold tracking-tighter">Lilith Swarm Intelligence</h3>
                    <p className="text-sm text-white/40">Multi-agent orchestration and Negative Extraction Currency ledger</p>
                  </div>
                    <div className="flex gap-3">
                      <div className="px-4 py-2 rounded-xl bg-white/5 border border-white/10 flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-indigo-500 animate-pulse" />
                        <span className="text-[10px] uppercase tracking-widest text-white/40 font-mono">Pipeline: {lilithData.swarmPhase}</span>
                      </div>
                      <button 
                        onClick={async () => {
                          const input = prompt("Input for Cosmic Pipeline:");
                          if (!input) return;
                          const phases = ['venusian', 'martian', 'l5'];
                          for (const phase of phases) {
                            setLilithData((prev: any) => ({ ...prev, swarmPhase: phase.toUpperCase() }));
                            const res = await callMcpTool('swarm_orchestrate', { input, phase, agentId: selectedAgentId });
                            if (res?.error) {
                              alert(`Pipeline Error: ${res.error}`);
                              break;
                            }
                            if (phase === 'l5') {
                              alert(`Manifested: ${res.result}`);
                            }
                            await new Promise(r => setTimeout(r, 800));
                          }
                        }}
                        className="px-4 py-2 rounded-xl bg-indigo-500 text-white text-xs font-bold uppercase tracking-widest"
                      >
                        Orchestrate Swarm
                      </button>
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  {/* NEC Ledger */}
                  <div className="lg:col-span-2 space-y-6">
                    <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                      <h4 className="text-lg font-bold mb-6 flex items-center gap-2">
                        <Zap className="w-5 h-5 text-amber-400" />
                        NEC Ledger (Negative Extraction Currency)
                      </h4>
                      <div className="overflow-x-auto">
                        <table className="w-full text-left text-xs">
                          <thead>
                            <tr className="text-white/30 uppercase tracking-widest border-b border-white/5">
                              <th className="pb-4 font-mono">Timestamp</th>
                              <th className="pb-4 font-mono">Giver</th>
                              <th className="pb-4 font-mono">Receiver</th>
                              <th className="pb-4 font-mono">Value</th>
                              <th className="pb-4 font-mono">Description</th>
                            </tr>
                          </thead>
                          <tbody className="text-white/60">
                            {lilithData.events.map((ev: any) => (
                              <tr key={ev.id} className="border-b border-white/[0.02]">
                                <td className="py-4 font-mono">{new Date(ev.timestamp).toLocaleTimeString()}</td>
                                <td className="py-4 font-bold text-indigo-400">{ev.giver}</td>
                                <td className="py-4 font-bold text-emerald-400">{ev.receiver}</td>
                                <td className="py-4 font-mono text-amber-400">+{ev.value.toFixed(2)}</td>
                                <td className="py-4 italic">{ev.description}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                        {lilithData.events.length === 0 && (
                          <div className="py-10 text-center text-white/10 italic">No care events recorded in the ledger.</div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Agent Balances & Tools */}
                  <div className="space-y-6">
                    <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                      <h4 className="text-lg font-bold mb-6 flex items-center gap-2">
                        <Users className="w-5 h-5 text-indigo-400" />
                        Agent Trust Balances
                      </h4>
                      <div className="space-y-4">
                        {lilithData.balances.map((b: any) => (
                          <div key={b.person} className="p-4 rounded-2xl bg-white/[0.02] border border-white/5 flex items-center justify-between">
                            <p className="font-bold">{b.person}</p>
                            <p className={`font-mono font-bold ${b.balance >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
                              {b.balance.toFixed(2)} NEC
                            </p>
                          </div>
                        ))}
                        {lilithData.balances.length === 0 && (
                          <div className="text-center text-white/10 italic">No active agents.</div>
                        )}
                      </div>
                    </div>

                    <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                      <div className="flex items-center justify-between mb-6">
                        <h4 className="text-lg font-bold flex items-center gap-2">
                          <ShieldCheck className="w-5 h-5 text-emerald-400" />
                          DNA Registry (Authorized Agents)
                        </h4>
                        <button 
                          onClick={async () => {
                            const agentId = prompt("Enter Agent ID to authorize:");
                            if (!agentId) return;
                            await callMcpTool('dna_registry_check', { agentId });
                            fetchData();
                          }}
                          className="px-3 py-1.5 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 text-emerald-400 text-[10px] font-bold uppercase tracking-widest transition-all"
                        >
                          Authorize Agent
                        </button>
                      </div>
                      <div className="space-y-3">
                        {lilithData.agents.map((a: any) => (
                          <div 
                            key={a.agent_id} 
                            onClick={() => setSelectedAgentId(a.agent_id)}
                            className={`p-4 rounded-2xl border transition-all cursor-pointer group ${
                              selectedAgentId === a.agent_id 
                              ? "bg-emerald-500/10 border-emerald-500/30" 
                              : "bg-white/[0.02] border-white/5 hover:bg-white/[0.04]"
                            }`}
                          >
                            <div className="flex items-center justify-between">
                              <div>
                                <p className={`text-sm font-bold transition-colors ${selectedAgentId === a.agent_id ? "text-emerald-400" : "text-white/80"}`}>{a.agent_id}</p>
                                <p className="text-[10px] text-white/30 uppercase tracking-widest font-mono">DNA: {a.dna_hash}</p>
                              </div>
                              <div className={`w-8 h-8 rounded-lg flex items-center justify-center border transition-all ${
                                selectedAgentId === a.agent_id 
                                ? "bg-emerald-500/20 border-emerald-500/40" 
                                : "bg-emerald-500/10 border-emerald-500/20"
                              }`}>
                                <ShieldCheck className={`w-4 h-4 ${selectedAgentId === a.agent_id ? "text-emerald-300" : "text-emerald-400"}`} />
                              </div>
                            </div>
                          </div>
                        ))}
                        {lilithData.agents.length === 0 && (
                          <div className="text-center text-white/10 italic">No agents registered.</div>
                        )}
                      </div>
                    </div>

                    <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                      <h4 className="text-lg font-bold mb-6 flex items-center gap-2">
                        <Command className="w-5 h-5 text-emerald-400" />
                        Lilith Core Tools
                      </h4>
                      <div className="grid grid-cols-1 gap-3">
                        <button 
                          onClick={async () => {
                            const binary = prompt("Binary data to translate:");
                            if (!binary) return;
                            const res = await callMcpTool('typogenetic_translate', { binary });
                            if (res) alert(`DNA Sequence: ${res.dna}`);
                          }}
                          className="w-full p-4 rounded-2xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all text-left group"
                        >
                          <p className="text-sm font-bold group-hover:text-emerald-400 transition-colors">Typogenetic Translate</p>
                          <p className="text-[10px] text-white/30 uppercase tracking-widest font-mono">Binary <span className="text-emerald-500">↔</span> DNA</p>
                        </button>
                        <button 
                          onClick={async () => {
                            const elements = prompt("Comma-separated elements for chaos injection:")?.split(',') || [];
                            if (elements.length === 0) return;
                            const res = await callMcpTool('chaos_inject', { elements, intensity: 0.8 });
                            if (res) setChaosTransformed(res.transformed);
                          }}
                          className="w-full p-4 rounded-2xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all text-left group"
                        >
                          <p className="text-sm font-bold group-hover:text-amber-400 transition-colors">Chaos Engine</p>
                          <p className="text-[10px] text-white/30 uppercase tracking-widest font-mono">Entropy Injection</p>
                        </button>
                        {chaosTransformed.length > 0 && (
                          <motion.div 
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            className="p-4 rounded-2xl bg-amber-500/5 border border-amber-500/10 font-mono text-[10px] text-amber-400/80 space-y-1 overflow-hidden"
                          >
                            {chaosTransformed.map((t, i) => <div key={i}>{t}</div>)}
                          </motion.div>
                        )}
                        <button 
                          onClick={async () => {
                            const giver = selectedAgentId || prompt("Giver Agent ID:");
                            const receiver = prompt("Receiver Agent ID:");
                            const value = parseFloat(prompt("Care Value:") || "0");
                            const description = prompt("Description:");
                            if (!giver || !receiver || isNaN(value)) return;
                            await callMcpTool('nec_record_care', { giver, receiver, value, description });
                            fetchData();
                          }}
                          className="w-full p-4 rounded-2xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all text-left group"
                        >
                          <p className="text-sm font-bold group-hover:text-indigo-400 transition-colors">Record Care Event</p>
                          <p className="text-[10px] text-white/30 uppercase tracking-widest font-mono">Update NEC Ledger</p>
                        </button>
                      </div>
                    </div>

                    <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                      <h4 className="text-lg font-bold mb-6 flex items-center gap-2">
                        <BrainCircuit className="w-5 h-5 text-indigo-400" />
                        Chimera Logic Engine
                      </h4>
                      <div className="grid grid-cols-1 gap-3">
                        <button 
                          onClick={async () => {
                            const problem = prompt("Problem to deconstruct:");
                            if (!problem) return;
                            const res = await callMcpTool('chimera_deconstruct', { problem });
                            if (res) setChimeraResults((prev: any) => ({ ...prev, axioms: res.axioms }));
                          }}
                          className="w-full p-4 rounded-2xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all text-left group"
                        >
                          <p className="text-sm font-bold group-hover:text-indigo-400 transition-colors">Axiom Deconstructor</p>
                          <p className="text-[10px] text-white/30 uppercase tracking-widest font-mono">Prolog Reasoning</p>
                        </button>
                        {chimeraResults.axioms.length > 0 && (
                          <motion.div 
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            className="p-4 rounded-2xl bg-indigo-500/5 border border-indigo-500/10 font-mono text-[10px] text-indigo-400/80 space-y-1 overflow-hidden"
                          >
                            {chimeraResults.axioms.map((a: string, i: number) => <div key={i}>{a}</div>)}
                          </motion.div>
                        )}
                        <button 
                          onClick={async () => {
                            const constraints = prompt("Comma-separated constraints to solve:")?.split(',') || [];
                            if (constraints.length === 0) return;
                            const res = await callMcpTool('chimera_solve', { constraints });
                            if (res) setChimeraResults((prev: any) => ({ ...prev, solutions: res.solutions }));
                          }}
                          className="w-full p-4 rounded-2xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-all text-left group"
                        >
                          <p className="text-sm font-bold group-hover:text-emerald-400 transition-colors">Constraint Solver</p>
                          <p className="text-[10px] text-white/30 uppercase tracking-widest font-mono">Logic Satisfaction</p>
                        </button>
                        {chimeraResults.solutions.length > 0 && (
                          <motion.div 
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            className="p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/10 font-mono text-[10px] text-emerald-400/80 space-y-2 overflow-hidden"
                          >
                            {chimeraResults.solutions.map((s: any, i: number) => (
                              <div key={i}>
                                <div className="font-bold">{s.constraint} <span className={s.status === 'SATISFIED' ? 'text-emerald-400' : 'text-red-400'}>[{s.status}]</span></div>
                                <div className="opacity-50">{s.proof}</div>
                              </div>
                            ))}
                          </motion.div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "mainframe" && (
              <motion.div key="mainframe" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="space-y-8 max-w-5xl">
                {!isMainframeInstalled ? (
                  <div className="p-12 rounded-[3rem] bg-[#121214] border border-white/5 text-center">
                    <Server className="w-16 h-16 mx-auto mb-6 text-indigo-500" />
                    <h3 className="text-2xl font-bold mb-4">Mainframe Core Not Installed</h3>
                    <p className="text-white/40 mb-8 max-w-md mx-auto">
                      The G.U.N.D.A.M. Mainframe Core provides real-time system monitoring, hygiene orchestration, and advanced resource management.
                    </p>
                    {isInstallingMainframe ? (
                      <div className="max-w-xs mx-auto">
                        <div className="h-1.5 w-full bg-white/5 rounded-full overflow-hidden mb-2">
                          <motion.div 
                            initial={{ width: 0 }}
                            animate={{ width: `${installProgress}%` }}
                            className="h-full bg-indigo-500"
                          />
                        </div>
                        <p className="text-[10px] uppercase tracking-widest text-white/30 font-mono">Installing Core: {installProgress}%</p>
                      </div>
                    ) : (
                      <button 
                        onClick={installMainframe}
                        className="px-8 py-4 rounded-2xl bg-indigo-500 hover:bg-indigo-400 text-white font-bold shadow-lg shadow-indigo-500/20 transition-all"
                      >
                        Install Mainframe Core
                      </button>
                    )}
                  </div>
                ) : (
                  <div className="space-y-8">
                    {/* Mainframe Dashboard */}
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                      <div className="lg:col-span-2 p-8 rounded-3xl bg-[#121214] border border-white/5">
                        <div className="flex items-center justify-between mb-8">
                          <h3 className="text-xl font-bold flex items-center gap-3">
                            <Activity className="w-5 h-5 text-indigo-400" />
                            Mainframe Core Dashboard
                          </h3>
                          <div className="flex items-center gap-2">
                            <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                            <span className="text-[10px] uppercase tracking-widest text-white/40 font-mono">Core Active</span>
                          </div>
                        </div>

                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                          {[
                            { label: "CPU Cores", value: systemStats?.cpus || "...", icon: Cpu },
                            { label: "Memory Usage", value: systemStats ? `${Math.round((1 - systemStats.freeMem / systemStats.totalMem) * 100)}%` : "...", icon: Layers },
                            { label: "System Uptime", value: systemStats ? `${Math.floor(systemStats.uptime / 3600)}h` : "...", icon: Activity },
                            { label: "Process RAM", value: systemStats ? `${Math.round(systemStats.processMem.rss / 1024 / 1024)}MB` : "...", icon: Server }
                          ].map((stat, i) => (
                            <div key={i} className="p-4 rounded-2xl bg-white/[0.02] border border-white/5">
                              <stat.icon className="w-4 h-4 text-white/20 mb-2" />
                              <p className="text-xl font-bold">{stat.value}</p>
                              <p className="text-[10px] uppercase text-white/30 font-mono">{stat.label}</p>
                            </div>
                          ))}
                        </div>

                        <div className="mt-8 h-32 w-full bg-white/[0.01] rounded-2xl border border-white/5 relative overflow-hidden flex items-end p-4 gap-1">
                          {/* Mock Load Graph */}
                          {Array.from({ length: 40 }).map((_, i) => (
                            <motion.div 
                              key={i}
                              initial={{ height: "20%" }}
                              animate={{ height: `${20 + Math.random() * 60}%` }}
                              transition={{ repeat: Infinity, duration: 1 + Math.random(), repeatType: "reverse" }}
                              className="flex-1 bg-indigo-500/20 rounded-t-sm"
                            />
                          ))}
                          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                            <p className="text-[10px] uppercase tracking-[0.3em] text-white/10 font-mono">Real-time Load Balancing</p>
                          </div>
                        </div>

                        <div className="mt-8">
                          <h4 className="text-xs font-bold uppercase tracking-widest text-white/30 mb-4">Mainframe Module Status</h4>
                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            {mainframeModules.map((mod) => (
                              <div key={mod.id} className="p-4 rounded-xl bg-white/[0.02] border border-white/5 flex items-center justify-between">
                                <div>
                                  <p className="text-sm font-bold">{mod.name}</p>
                                  <p className="text-[10px] text-white/20 uppercase font-mono">v{mod.version}</p>
                                </div>
                                <div className="flex items-center gap-2">
                                  <div className={`w-1.5 h-1.5 rounded-full ${mod.status === 'online' ? 'bg-emerald-500' : 'bg-red-500'}`} />
                                  <span className="text-[10px] font-mono text-white/40 uppercase">{mod.status}</span>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>

                      <div className="p-8 rounded-3xl bg-[#121214] border border-white/5 flex flex-col">
                        <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
                          <ShieldAlert className="w-5 h-5 text-amber-400" />
                          System Hygiene
                        </h3>
                        <p className="text-xs text-white/40 mb-6 leading-relaxed">
                          The Hygieia sub-cycle performs meticulous memory scrubbing and Sigma-Closure validation to prevent entropic decay.
                        </p>
                        <div className="mt-auto space-y-3">
                          <div className="p-3 rounded-xl bg-white/5 border border-white/10">
                            <p className="text-[10px] uppercase text-white/30 font-mono mb-1">Lattice Level</p>
                            <p className="text-sm font-bold">N=6 (Absorbing)</p>
                          </div>
                          <button 
                            onClick={runHygiene}
                            className="w-full py-3 rounded-xl bg-amber-500/10 hover:bg-amber-500/20 border border-amber-500/20 text-amber-400 text-xs font-bold uppercase transition-all"
                          >
                            Run Hygiene Sub-cycle
                          </button>
                        </div>
                      </div>
                    </div>

                    <div className="p-10 rounded-[3rem] bg-[#121214] border border-white/5 relative overflow-hidden">
                      <div className="absolute top-0 right-0 p-8 opacity-5">
                        <Server className="w-64 h-64" />
                      </div>
                      
                      <div className="relative z-10">
                        <h3 className="text-3xl font-bold mb-4 flex items-center gap-4">
                          <Server className="w-10 h-10 text-indigo-400" />
                          Mainframe Specs
                        </h3>
                        <p className="text-white/40 mb-10 max-w-2xl">
                          The Project Meticulous Mainframe is a high-performance, sandboxed environment designed for autonomous bot orchestration and local LLM inference.
                        </p>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                          <div className="space-y-6">
                            <h4 className="text-xs font-bold uppercase tracking-widest text-indigo-400">Capabilities</h4>
                            <ul className="space-y-4">
                              {[
                                { label: "Multi-Language Runtime", desc: "Native support for Node.js, with bridges for Rust, Elixir, Julia, and Ballerina." },
                                { label: "Local LLM Inference", desc: "High-speed GGUF execution via node-llama-cpp with meticulous memory management." },
                                { label: "MCP Tool Hosting", desc: "Standardized Model Context Protocol server for cross-platform tool discovery." },
                                { label: "Real-time Orchestration", desc: "Low-latency Discord event handling and autonomous agentic decisioning." }
                              ].map((item, i) => (
                                <li key={i} className="flex gap-4">
                                  <div className="w-1.5 h-1.5 rounded-full bg-indigo-500 mt-2 shrink-0" />
                                  <div>
                                    <p className="font-bold text-sm">{item.label}</p>
                                    <p className="text-xs text-white/30">{item.desc}</p>
                                  </div>
                                </li>
                              ))}
                            </ul>
                          </div>

                          <div className="space-y-6">
                            <h4 className="text-xs font-bold uppercase tracking-widest text-red-400">System Limits</h4>
                            <ul className="space-y-4">
                              {[
                                { label: "Network Isolation", desc: "External access is strictly limited to Port 3000 via Nginx reverse proxy." },
                                { label: "Sandboxed Environment", desc: "No direct host filesystem access; all operations are meticulously containerized." },
                                { label: "Resource Quotas", desc: "CPU and RAM are subject to container limits to prevent domineering vectors." },
                                { label: "Persistence", desc: "Primary storage is SQLite-based; large-scale binary data should be managed meticulously." }
                              ].map((item, i) => (
                                <li key={i} className="flex gap-4">
                                  <div className="w-1.5 h-1.5 rounded-full bg-red-500 mt-2 shrink-0" />
                                  <div>
                                    <p className="font-bold text-sm">{item.label}</p>
                                    <p className="text-xs text-white/30">{item.desc}</p>
                                  </div>
                                </li>
                              ))}
                            </ul>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </motion.div>
            )}

            {activeTab === "space-ops" && (
              <motion.div key="space-ops" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-2xl font-bold tracking-tight">Space Operations</h3>
                    <p className="text-sm text-white/40 font-mono uppercase tracking-widest">Deep Space Network • JPL • NASA Integration</p>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white/5 border border-white/10">
                      <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                      <span className="text-[10px] font-mono text-white/60 uppercase">DSN Link: Active</span>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  <div className="lg:col-span-2 space-y-8">
                    {/* NASA NEO Section */}
                    <div className="p-8 rounded-3xl bg-[#121214] border border-white/5 relative overflow-hidden group">
                      <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity">
                        <Rocket className="w-32 h-32" />
                      </div>
                      <h4 className="text-lg font-bold mb-6 flex items-center gap-2">
                        <ShieldAlert className="w-5 h-5 text-amber-400" />
                        NASA Near-Earth Objects (NEO)
                      </h4>
                      <div className="flex gap-4 mb-8">
                        <button 
                          onClick={async () => {
                            setIsSpaceLoading(true);
                            const res = await callMcpTool("nasa_neo_lookup", { date: new Date().toISOString().split('T')[0] });
                            setSpaceData(res);
                            setIsSpaceLoading(false);
                          }}
                          disabled={isSpaceLoading}
                          className="px-6 py-3 rounded-2xl bg-indigo-500 hover:bg-indigo-400 text-white font-bold transition-all disabled:opacity-50"
                        >
                          {isSpaceLoading ? "Querying NASA..." : "Fetch Today's NEOs"}
                        </button>
                      </div>

                      {spaceData?.element_count !== undefined && (
                        <div className="space-y-4">
                          <div className="p-4 rounded-2xl bg-white/[0.02] border border-white/5">
                            <p className="text-xs text-white/40 uppercase font-mono mb-1">Total Objects Detected</p>
                            <p className="text-3xl font-bold text-indigo-400">{spaceData.element_count}</p>
                          </div>
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {Object.values(spaceData.near_earth_objects || {}).flat().slice(0, 4).map((neo: any) => (
                              <div key={neo.id} className="p-4 rounded-2xl bg-white/[0.02] border border-white/5 hover:border-white/10 transition-all">
                                <div className="flex items-center justify-between mb-2">
                                  <p className="font-bold text-white/80">{neo.name}</p>
                                  {neo.is_potentially_hazardous_asteroid && (
                                    <span className="text-[8px] font-bold px-1.5 py-0.5 rounded bg-red-500/20 text-red-400 uppercase">Hazardous</span>
                                  )}
                                </div>
                                <div className="space-y-1 text-[10px] font-mono text-white/40">
                                  <p>Diameter: {neo.estimated_diameter.kilometers.estimated_diameter_max.toFixed(2)} km</p>
                                  <p>Velocity: {parseFloat(neo.close_approach_data[0].relative_velocity.kilometers_per_hour).toLocaleString()} km/h</p>
                                  <p>Miss Distance: {parseFloat(neo.close_approach_data[0].miss_distance.kilometers).toLocaleString()} km</p>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>

                    {/* JPL Horizons Section */}
                    <div className="p-8 rounded-3xl bg-[#121214] border border-white/5 relative overflow-hidden group">
                      <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity">
                        <Telescope className="w-32 h-32" />
                      </div>
                      <h4 className="text-lg font-bold mb-6 flex items-center gap-2">
                        <Activity className="w-5 h-5 text-emerald-400" />
                        JPL Horizons Ephemeris
                      </h4>
                      <div className="flex gap-4 mb-8">
                        <button 
                          onClick={async () => {
                            const target = prompt("Enter target body (e.g., Mars, Jupiter, 1999 AN10):", "Mars");
                            if (!target) return;
                            setIsSpaceLoading(true);
                            const res = await callMcpTool("jpl_horizons_query", { target });
                            setSpaceData(res);
                            setIsSpaceLoading(false);
                          }}
                          disabled={isSpaceLoading}
                          className="px-6 py-3 rounded-2xl bg-emerald-500 hover:bg-emerald-400 text-black font-bold transition-all disabled:opacity-50"
                        >
                          {isSpaceLoading ? "Querying JPL..." : "Query Ephemeris"}
                        </button>
                      </div>

                      {spaceData?.target && (
                        <div className="p-6 rounded-2xl bg-white/[0.02] border border-white/5 font-mono">
                          <div className="flex items-center justify-between mb-4">
                            <h5 className="text-emerald-400 font-bold uppercase tracking-widest">Target: {spaceData.target}</h5>
                            <span className="text-[10px] text-white/20">COORD: {spaceData.coordinates}</span>
                          </div>
                          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <div>
                              <p className="text-[10px] text-white/30 uppercase mb-1">Distance (AU)</p>
                              <p className="text-xl font-bold text-white/80">{spaceData.distance_au}</p>
                            </div>
                            <div>
                              <p className="text-[10px] text-white/30 uppercase mb-1">Velocity (km/s)</p>
                              <p className="text-xl font-bold text-white/80">{spaceData.velocity_kms}</p>
                            </div>
                            <div>
                              <p className="text-[10px] text-white/30 uppercase mb-1">Light Time</p>
                              <p className="text-xl font-bold text-white/80">{spaceData.light_time}</p>
                            </div>
                          </div>
                          <div className="mt-6 pt-6 border-t border-white/5">
                            <p className="text-[10px] text-white/30 uppercase mb-2">Ephemeris Data Stream</p>
                            <div className="p-4 rounded-xl bg-black/40 text-[10px] text-emerald-500/70 leading-relaxed">
                              {spaceData.raw_ephemeris}
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="space-y-8">
                    <div className="p-8 rounded-3xl bg-[#121214] border border-white/5">
                      <h4 className="text-sm font-bold mb-6 uppercase tracking-widest text-white/40">Telemetry Stream</h4>
                      <div className="space-y-4">
                        {[1, 2, 3, 4, 5].map(i => (
                          <div key={i} className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                            <div className="flex items-center gap-3">
                              <div className="w-1.5 h-1.5 rounded-full bg-indigo-500" />
                              <span className="text-[10px] font-mono text-white/60">SENSOR_0{i}</span>
                            </div>
                            <span className="text-[10px] font-mono text-indigo-400">{(Math.random() * 100).toFixed(2)}%</span>
                          </div>
                        ))}
                      </div>
                      <div className="mt-8 pt-8 border-t border-white/5">
                        <div className="h-32 flex items-end gap-1">
                          {[...Array(20)].map((_, i) => (
                            <div 
                              key={i} 
                              className="flex-1 bg-indigo-500/20 rounded-t-sm transition-all hover:bg-indigo-500/40"
                              style={{ height: `${Math.random() * 100}%` }}
                            />
                          ))}
                        </div>
                        <p className="text-[10px] text-center mt-4 text-white/20 font-mono uppercase tracking-widest">Real-time Signal Analysis</p>
                      </div>
                    </div>

                    <div className="p-8 rounded-3xl bg-indigo-500/10 border border-indigo-500/20">
                      <h4 className="font-bold mb-2">Space Ops Protocol</h4>
                      <p className="text-xs text-white/60 leading-relaxed mb-4">
                        All deep space queries are routed through the G.U.N.D.A.M. secure relay to ensure zero-latency domineering vectors.
                      </p>
                      <ul className="space-y-2">
                        <li className="flex items-center gap-2 text-[10px] text-indigo-400 font-bold uppercase">
                          <ShieldCheck className="w-3 h-3" /> Encrypted Uplink
                        </li>
                        <li className="flex items-center gap-2 text-[10px] text-indigo-400 font-bold uppercase">
                          <ShieldCheck className="w-3 h-3" /> JPL Auth Verified
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "settings" && (
              <motion.div key="settings" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8 max-w-2xl">
                <div className="p-8 rounded-[2.5rem] bg-[#121214] border border-white/5">
                  <h3 className="text-2xl font-bold mb-8 flex items-center gap-3">
                    <Settings className="w-6 h-6 text-indigo-400" />
                    User Preferences
                  </h3>
                  
                  <div className="space-y-8">
                    <div className="flex items-center justify-between p-6 rounded-3xl bg-white/[0.02] border border-white/5">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-2xl bg-indigo-500/10 flex items-center justify-center border border-indigo-500/20">
                          {userSettings?.theme === 'dark' ? <Moon className="w-6 h-6 text-indigo-400" /> : <Sun className="w-6 h-6 text-amber-400" />}
                        </div>
                        <div>
                          <p className="font-bold">Interface Theme</p>
                          <p className="text-xs text-white/30 uppercase tracking-widest font-mono">Current: {userSettings?.theme}</p>
                        </div>
                      </div>
                      <div className="flex bg-black/40 p-1 rounded-xl border border-white/5">
                        <button 
                          onClick={() => updateSettings({ theme: 'dark' })}
                          className={`px-4 py-2 rounded-lg text-[10px] font-bold uppercase transition-all ${userSettings?.theme === 'dark' ? 'bg-indigo-500 text-white' : 'text-white/40 hover:text-white/60'}`}
                        >
                          Dark
                        </button>
                        <button 
                          onClick={() => updateSettings({ theme: 'light' })}
                          className={`px-4 py-2 rounded-lg text-[10px] font-bold uppercase transition-all ${userSettings?.theme === 'light' ? 'bg-indigo-500 text-white' : 'text-white/40 hover:text-white/60'}`}
                        >
                          Light
                        </button>
                      </div>
                    </div>

                    <div className="flex items-center justify-between p-6 rounded-3xl bg-white/[0.02] border border-white/5">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-2xl bg-indigo-500/10 flex items-center justify-center border border-indigo-500/20">
                          {userSettings?.notifications_enabled ? <Bell className="w-6 h-6 text-indigo-400" /> : <BellOff className="w-6 h-6 text-white/20" />}
                        </div>
                        <div>
                          <p className="font-bold">System Notifications</p>
                          <p className="text-xs text-white/30 uppercase tracking-widest font-mono">{userSettings?.notifications_enabled ? 'Enabled' : 'Disabled'}</p>
                        </div>
                      </div>
                      <button 
                        onClick={() => updateSettings({ notifications_enabled: !userSettings?.notifications_enabled })}
                        className={`w-14 h-8 rounded-full p-1 transition-all ${userSettings?.notifications_enabled ? 'bg-indigo-500' : 'bg-white/10'}`}
                      >
                        <div className={`w-6 h-6 rounded-full bg-white shadow-md transition-all transform ${userSettings?.notifications_enabled ? 'translate-x-6' : 'translate-x-0'}`} />
                      </button>
                    </div>

                    <div className="p-6 rounded-3xl bg-red-500/5 border border-red-500/10">
                      <h4 className="text-red-400 font-bold mb-2">Danger Zone</h4>
                      <p className="text-xs text-white/30 mb-4">Decommissioning your account will permanently purge all associated bot nodes and model configurations.</p>
                      <button className="px-6 py-3 rounded-xl bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 text-red-400 text-xs font-bold uppercase transition-all">
                        Decommission Account
                      </button>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === "webhooks" && (
              <motion.div key="webhooks" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
                <div className="flex items-center justify-between">
                  <h3 className="text-xl font-bold">Hook Router</h3>
                  <button onClick={addWebhook} className="flex items-center gap-2 px-4 py-2 rounded-xl bg-amber-500 text-black text-sm font-bold">
                    <Plus className="w-4 h-4" /> Create Webhook
                  </button>
                </div>
                <div className="space-y-3">
                  {webhooks.map(hook => (
                    <div key={hook.id} className="p-4 rounded-2xl bg-[#121214] border border-white/5 flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <Webhook className="w-5 h-5 text-amber-400" />
                        <div>
                          <p className="text-sm font-bold">{hook.name}</p>
                          <p className="text-[10px] text-white/30 font-mono truncate max-w-xs">{hook.url}</p>
                        </div>
                      </div>
                      <button 
                        onClick={() => testWebhook(hook.url)}
                        className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-[10px] font-bold uppercase"
                      >
                        <Zap className="w-3 h-3 text-amber-400" /> Test Hook
                      </button>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </main>
      </div>

      {/* Model Modal */}
      <AnimatePresence>
        {isModelModalOpen && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6">
            <motion.div 
              initial={{ opacity: 0 }} 
              animate={{ opacity: 1 }} 
              exit={{ opacity: 0 }}
              onClick={() => setIsModelModalOpen(false)}
              className="absolute inset-0 bg-black/80 backdrop-blur-sm"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              className="relative w-full max-w-md bg-[#121214] border border-white/10 rounded-3xl p-8 shadow-2xl"
            >
              <h3 className="text-2xl font-bold mb-2">Mount GGUF Model</h3>
              <p className="text-white/40 text-sm mb-6">Register a local GGUF file into the inference vault.</p>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-[10px] uppercase font-bold text-white/30 mb-1.5 ml-1">Model Name</label>
                  <input 
                    type="text" 
                    value={newModelName}
                    onChange={(e) => setNewModelName(e.target.value)}
                    placeholder="e.g. Llama-3-8B-Instruct"
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-emerald-500/50 transition-colors"
                  />
                </div>
                <div>
                  <label className="block text-[10px] uppercase font-bold text-white/30 mb-1.5 ml-1">Model Path (GGUF)</label>
                  <div className="flex gap-2">
                    <div className="flex-1 relative">
                      <input 
                        type="text" 
                        value={newModelPath}
                        onChange={(e) => setNewModelPath(e.target.value)}
                        placeholder="/path/to/model.gguf"
                        className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm font-mono focus:outline-none focus:border-emerald-500/50 transition-colors pr-12"
                      />
                      <button 
                        onClick={handleBrowseFiles}
                        className="absolute right-2 top-1/2 -translate-y-1/2 p-2 text-white/20 hover:text-emerald-400 transition-colors"
                        title="Browse Files"
                      >
                        <Search className="w-4 h-4" />
                      </button>
                    </div>
                    <button 
                      onClick={async () => {
                        if (!newModelPath) return;
                        const res = await fetch("/api/models/test-path", {
                          method: "POST",
                          headers: { "Content-Type": "application/json" },
                          body: JSON.stringify({ path: newModelPath })
                        });
                        const data = await res.json();
                        if (data.success) alert("Success: GGUF file found at path.");
                        else alert(`Error: ${data.error}`);
                      }}
                      className="px-4 rounded-xl bg-white/5 border border-white/10 text-white/40 hover:text-white/60 hover:bg-white/10 transition-all text-[10px] font-bold uppercase"
                    >
                      Test
                    </button>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-3 mt-8">
                <button 
                  onClick={() => setIsModelModalOpen(false)}
                  className="flex-1 px-4 py-3 rounded-xl bg-white/5 hover:bg-white/10 text-sm font-bold transition-colors"
                >
                  Cancel
                </button>
                <button 
                  onClick={handleAddModel}
                  className="flex-1 px-4 py-3 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-black text-sm font-bold transition-colors"
                >
                  Mount Model
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* File Browser Modal */}
      <AnimatePresence>
        {isFileBrowserOpen && (
          <div className="fixed inset-0 z-[110] flex items-center justify-center p-6">
            <motion.div 
              initial={{ opacity: 0 }} 
              animate={{ opacity: 1 }} 
              exit={{ opacity: 0 }}
              onClick={() => setIsFileBrowserOpen(false)}
              className="absolute inset-0 bg-black/90 backdrop-blur-md"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              className="relative w-full max-w-2xl bg-[#121214] border border-white/10 rounded-3xl p-8 shadow-2xl flex flex-col max-h-[80vh]"
            >
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="text-xl font-bold">Meticulous File Browser</h3>
                  <p className="text-xs text-white/30 font-mono mt-1 truncate max-w-md">{currentPath}</p>
                </div>
                <button 
                  onClick={navigateUp}
                  className="p-2 rounded-xl bg-white/5 border border-white/10 text-white/40 hover:text-white/60"
                  title="Go Up"
                >
                  <ExternalLink className="w-4 h-4 rotate-180" />
                </button>
              </div>

              <div className="flex-1 overflow-y-auto space-y-1 pr-2">
                {isBrowserLoading ? (
                  <div className="h-40 flex items-center justify-center">
                    <Activity className="w-6 h-6 text-indigo-500 animate-spin" />
                  </div>
                ) : (
                  browserFiles.map((file, i) => (
                    <button
                      key={i}
                      onClick={() => {
                        if (file.isDirectory) {
                          fetchFiles(file.path);
                        } else if (file.isGGUF) {
                          setNewModelPath(file.path);
                          setIsFileBrowserOpen(false);
                        }
                      }}
                      className={`w-full flex items-center gap-3 p-3 rounded-xl transition-all ${
                        file.isDirectory 
                        ? "hover:bg-white/5 text-white/60" 
                        : file.isGGUF 
                          ? "hover:bg-emerald-500/10 text-emerald-400" 
                          : "opacity-30 cursor-not-allowed"
                      }`}
                    >
                      {file.isDirectory ? <Layers className="w-4 h-4" /> : <BrainCircuit className="w-4 h-4" />}
                      <span className="text-sm font-medium truncate">{file.name}</span>
                      {file.isGGUF && <span className="ml-auto text-[10px] font-bold uppercase text-emerald-500/50">GGUF</span>}
                    </button>
                  ))
                )}
              </div>

              <div className="mt-6 flex justify-end">
                <button 
                  onClick={() => setIsFileBrowserOpen(false)}
                  className="px-6 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-sm font-bold transition-colors"
                >
                  Close
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Deployment Modal */}
      <AnimatePresence>
        {isDeployModalOpen && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsDeployModalOpen(false)}
              className="absolute inset-0 bg-black/80 backdrop-blur-sm"
            />
            <motion.div 
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="relative w-full max-w-lg bg-[#121214] border border-white/10 rounded-3xl p-8 shadow-2xl"
            >
              <div className="flex items-center gap-4 mb-8">
                <div className="w-12 h-12 rounded-2xl bg-indigo-500/10 flex items-center justify-center border border-indigo-500/20">
                  <Bot className="w-6 h-6 text-indigo-400" />
                </div>
                <div>
                  <h3 className="text-xl font-bold">Deploy New Bot Instance</h3>
                  <p className="text-sm text-white/40 font-medium">Initialize a meticulous Discord wrapper node</p>
                </div>
              </div>

              <div className="space-y-6">
                <div>
                  <label className="block text-[10px] uppercase tracking-widest text-white/40 font-mono mb-2">Instance Name</label>
                  <input 
                    value={newBotName}
                    onChange={(e) => setNewBotName(e.target.value)}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-indigo-500/50 transition-all"
                    placeholder="e.g. GUNDAM-PRIME-01"
                  />
                </div>
                <div>
                  <label className="block text-[10px] uppercase tracking-widest text-white/40 font-mono mb-2">Discord Bot Token</label>
                  <div className="relative">
                    <input 
                      type="password"
                      value={newBotToken}
                      onChange={(e) => setNewBotToken(e.target.value)}
                      className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-indigo-500/50 transition-all pr-12"
                      placeholder="MTAx..."
                    />
                    <Lock className="absolute right-4 top-1/2 -translate-y-1/2 w-4 h-4 text-white/20" />
                  </div>
                </div>

                <div className="pt-4 flex gap-3">
                  <button 
                    onClick={() => setIsDeployModalOpen(false)}
                    className="flex-1 py-3 rounded-xl bg-white/5 hover:bg-white/10 border border-white/10 text-sm font-bold transition-all"
                  >
                    Cancel
                  </button>
                  <button 
                    onClick={handleDeployBot}
                    disabled={!newBotName || !newBotToken}
                    className="flex-1 py-3 rounded-xl bg-indigo-500 hover:bg-indigo-400 disabled:opacity-50 disabled:cursor-not-allowed text-white text-sm font-bold shadow-lg shadow-indigo-500/20 transition-all"
                  >
                    Deploy Instance
                  </button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
