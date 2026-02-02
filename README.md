# Ezles-X BSS

A comprehensive automation script for **Bee Swarm Simulator** on Roblox.

## Features

### Auto Farm
- **Auto Pollen Collection** - Automatically collects pollen from any field
- **Auto Convert** - Converts pollen to honey at your hive when backpack is full
- **Auto Token Collection** - Picks up nearby tokens while farming
- **Field Selection** - Choose from 17 different fields

### Quests & NPCs
- **Auto Quest** - Automatically accepts quests from quest givers
- **Auto Feed** - Feeds your bees with treats automatically
- **Quest Giver Selection** - Black Bear, Brown Bear, Mother Bear, and more

### Dispensers
- **Auto Dispenser** - Claims free items from all dispensers automatically
- Supports: Honey, Treat, Royal Jelly, Blueberry, Strawberry, Glue, Ticket dispensers

### Combat
- **Mob Killer** - Automatically attacks nearby mobs
- **Target Selection** - Choose which mobs to target
- **Quick Teleports** - Instant teleport to mob locations

### Teleports
- **Field Teleports** - Instant teleport to any field
- **Location Teleports** - Shops, HQ, shrines, and more

### Movement
- **Fly** - Fly around the map (WASD + Space/Ctrl)
- **Noclip** - Pass through walls
- **Speed Boost** - Increase walk speed

### Utilities
- **Anti-AFK** - Prevents disconnection
- **Server Hop** - Find a new server
- **Rejoin** - Quickly rejoin the current server

## Installation

1. Open **Bee Swarm Simulator** in Roblox
2. Open your executor (Delta, Seliware, etc.)
3. Execute the following script:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Ezles/ezles-x/main/loader.lua"))()
```

Or copy the contents of `EXECUTE_THIS.lua`

## Supported Executors

- Delta (Free)
- Seliware (Paid)
- Synapse X
- KRNL
- Fluxus
- And most other executors

## UI Library

This script uses **Rayfield** by Sirius for the user interface.

## File Structure

```
/
├── main.lua          # Main script with all features
├── loader.lua        # Loader that verifies game and loads main
├── EXECUTE_THIS.lua  # Simple execution script
└── README.md         # This file
```

## Controls

| Feature | Controls |
|---------|----------|
| Fly | WASD to move, Space to go up, Ctrl/Shift to go down |
| UI Toggle | Use Rayfield's built-in keybind |

## Disclaimer

This script is for educational purposes only. Use at your own risk.

## Credits

- **Ezles** - Script development
- **Sirius** - Rayfield UI Library
