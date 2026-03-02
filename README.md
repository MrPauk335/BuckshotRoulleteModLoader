# Buckshot Roulette Mod Loader + AI Bot

Official Mod Loader for Buckshot Roulette, featuring a Neural Network AI integration.

## 🚀 Features
- **Mod Management**: Easily toggle and manage mods via the in-game "MODS" menu.
- **AI Bot**: Play against a Neural Network trained AI.
  - **Dual Logic**: Supports local MLP (Neural Network) and Llama 3 API (via OpenRouter).
  - **Dynamic Commands**: Add/Remove bots in the lobby with a single click.
- **Steam Integration**: Built with GodotSteam for seamless multiplayer.

## 🛠 Installation
1. Download the latest release.
2. Place the `ModLoader` files into your Buckshot Roulette directory.
3. Launch the game. You should see a "MODS" button in the main menu.

## 🤖 AI Setup
The AI can be configured in `ai_config.json`:
- **API Mode**: Set your OpenRouter API key to use Llama 3 8B.
- **Local Mode**: If no API key is provided, the bot falls back to the local `ai_weights.json` for prediction.

### Python Requirements
To run the AI bots, ensure you have Python installed with the following libraries:
```bash
pip install numpy requests
```

## 📂 Project Structure
- `/mods-unpacked`: Source for restored mods (AI Bot, Mod Menu, etc.).
- `/multiplayer`: Core multiplayer logic with ModLoader hooks injected.
- `ai_bridge.py`: Communication bridge between Godot and Python.
- `buckshot_ai.py`: Neural Network architecture and training environment.

## 🤝 Contribution
Restored and maintained by **MrPauk335**. Feel free to open issues or pull requests.

---
*Buckshot Roulette is a game by Mike Klubnika. This mod loader is an unofficial community project.*
