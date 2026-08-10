# Companion (your chat agent)

This profile installs **Ollama + Open WebUI** and desk tools.  
A full “Aria-class” companion is **your** container or binary — not bundled here (keeps the pack free of private code/secrets).

## Suggested next steps on this machine

1. Pull a chat model: `docker exec -it si-ollama ollama pull qwen2.5:7b-instruct-q4_K_M`  
2. Open WebUI at `http://<this-host>:8080`  
3. Optional: run your own companion on port **8083** pointed at `http://127.0.0.1:11434`  
4. Screen record for agents: [HouseCap](https://github.com/teamrustyonmars-byte/housecap)

No passwords or house IPs are stored in this file.
