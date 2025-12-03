# Pet Garden PvP Simulator

A Roblox game combining pet collection, farming, tower defense PvE, and arena PvP.

## Tech Stack
- Roblox Studio + Luau
- Rojo for file sync
- Wally for package management

## Setup
1. Install Rokit: https://github.com/rojo-rbx/rokit
2. Run `rokit install` to install tools
3. Run `wally install` to install packages
4. Run `rojo serve` to start syncing
5. Connect Rojo plugin in Roblox Studio

## Project Structure
- `src/client/` - Client-side code (Controllers, UI)
- `src/server/` - Server-side code (Services, Modules)
- `src/shared/` - Shared code (Constants, Types, Utils, Data)
- `assets/` - Images, sounds, models
- `Packages/` - Wally packages (auto-generated)

## Commands
- `rojo serve` - Start live sync
- `rojo build -o game.rbxl` - Build place file
- `wally install` - Install packages
- `stylua src/` - Format code
- `selene src/` - Lint code
