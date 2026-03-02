# Buckshot Roulette Modding Guide

This guide explains how to create your own mods for the Buckshot Roulette Mod Loader.

## 📁 Mod Structure
Mods should be placed in the `mods-unpacked/` directory using the following naming convention: `AuthorName-ModName`.

Example: `mods-unpacked/mrpauk335-CoolMod/`

Inside your mod folder, you need at least two files:
1. `manifest.json`: Metadata about your mod.
2. `mod_main.gd`: The entry point script for your mod.

---

## 📄 manifest.json
This file defines your mod's identity and dependencies.

```json
{
    "name": "CoolMod",
    "namespace": "AuthorName",
    "version_number": "1.0.0",
    "description": "Adds awesome new features!",
    "dependencies": [],
    "extra": {
        "godot": {
            "authors": ["AuthorName"],
            "compatible_game_version": ["1.0.0"],
            "compatible_mod_loader_version": ["7.0.0"]
        }
    }
}
```

---

## 🛠 mod_main.gd
The `mod_main.gd` script is automatically loaded by the Mod Loader. Use it to initialize your mod and hook into the game.

### Standard Template
```gdscript
extends Node

const MOD_NAME = "AuthorName-CoolMod"

func _init():
    # Called when the mod is first loaded
    print("Initializing ", MOD_NAME)

func _ready():
    # Hook into game state managers
    var game_state = get_node_or_null("/root/ModLoader/MP_GameStateManager")
    if game_state:
        game_state.game_state_ready.connect(_on_game_state_ready)

func _on_game_state_ready(state_manager):
    print("Mod connected to game state!")
```

---

## 🔗 Hooking into Vanilla Logic
We have added manual hooks to critical multiplayer scripts to make modding easier. You can "hook" into these methods using the `ModLoader` API.

### Available Hook Points:
- `MP_RoundManager.gd`: `_ready`
- `MP_LobbyUI.gd`: `_ready`, `_process`, `UpdatePlayerList`
- `MP_GameStateManager.gd`: `_ready`
- `MP_PacketVerification.gd`: `VerifyPacket`

### How to use Hooks:
Use `ModLoaderMod.install_script_extension()` to extend vanilla scripts or use the dedicated hook system if you want to modify behavior without replacing the whole file.

---

## 🎨 Scene Extensions
If you want to modify a UI scene (like the main menu), you can use Scene Extensions:

```gdscript
# In your mod_main.gd
const MY_MENU_EXTENSION = "res://mods-unpacked/AuthorName-CoolMod/scenes/MenuExtension.tscn"

func _init():
    ModLoaderScene.add_scene_extension(MY_MENU_EXTENSION)
```

## 🚀 Testing your Mod
1. Place your mod in `mods-unpacked/`.
2. Run the game.
3. Check the Godot console and the in-game **MODS** menu to verify your mod is loaded.
