# sica-fondt
AI Mafia Bot Gen.02.6


```dir
mafiabot_core/
├── alire.toml               # The package manifest (Alire). No pip, no cargo. Pure discipline.
├── config/                  # Environment and secret handling.
├── src/                     # The Forge.
│   ├── mafiabot.adb         # The Main entry point.
│   ├── core/
│   │   ├── engine.ads       
│   │   └── engine.adb       
│   ├── daemons/
│   │   ├── economy.ads      
│   │   └── economy.adb
│   ├── network/
│   │   ├── sockets.ads      
│   │   └── sockets.adb
│   └── payloads/
│       ├── exploits.ads     
│       └── exploits.adb
├── tests/
│   └── engine_tests.adb     
└── .gitignore
```
