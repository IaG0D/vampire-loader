# 🦇 Vampire Rig Scanner v14

> The most complete Roblox universal script. Made in Brazil by **VampireSonata**.

![License](https://img.shields.io/badge/license-private-red)
![Version](https://img.shields.io/badge/version-v14-purple)
![Status](https://img.shields.io/badge/status-active-brightgreen)

---

## How to Use

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/IaG0D/vampire-loader/main/loader.luau"))()
```

> **Whitelist required.** Contact VampireSonata on Discord to get access.

---

## Features

### 👁 ESP System
- Player & NPC ESP with multiple modes
- Health bars, box highlights, chams/fill
- Tracers, skeleton ESP, head dot
- Tool ESP with item icons
- Threat level indicators
- Sound ESP & footstep trails
- Player info cards
- Voice constellation (voice chat orbs)

### 🎯 Aimbot
- FOV-based target detection (10-360 radius)
- Adjustable smoothness (1-20)
- Team check toggle
- Visual FOV circle

### 👤 Player List
- Full online player list with search
- Server info (player count, ping, job ID)
- Spectate any player
- Shadow clone, troll panel, backpack viewer
- **Right-click radial menu** on any player in-game

### 🎯 Radial Menu (NEW)
- Right-click any player in the 3D world
- Quick actions: **Spectate, Teleport, Shadow, Troll, Close**
- Shadow/Troll/Spectate buttons show **Stop** when active
- Animated open/close with scale tween

### 🏃 Movement
- **Fly** — WASD + Space/Shift flight
- **Noclip** — Walk through walls
- **Infinite Jump** — Jump mid-air
- **ClickTP** — Teleport to mouse click
- **AntiVoid** — Prevent falling off map
- **Spin** — Rotate character (adjustable speed)
- **Flashback** — Save & recall position
- **feFlip** — Front flip animation
- **Speed & Jump** — Adjustable walk speed (1-500) and jump power (0-300)
- **Character Scale** — Adjust height, width, depth, head size, proportions

### 💃 Emote Player
- Play any animation by ID
- Pause / resume / stop
- **Sync Emotes** — Select other players and sync animations
- Favorites system with persistent storage
- Catalog search with thumbnails

### 🎞 Animation System (NEW)
- Browse trending animation bundles
- Apply full bundles (idle, walk, run, jump, climb, swim, fall)
- Apply individual animation slots
- Search animation catalog
- Favorites system
- Natural idle variation preserved

### 🎬 Cinema Mode (NEW)
- **6 camera modes:** Freecam, Orbit, Dolly, Follow, Static, Crane
- **Visual effects:** Letterbox, vignette, film grain, DOF, motion blur, sun rays
- **Color grading:** 9 presets + custom brightness/contrast/saturation
- **Waypoint system** with cubic easing, loop, ping-pong
- **Recording system** with timestamp interpolation
- **Quick actions:** Fade, zoom punch, shake, bird/worm eye, screenshot, mirror
- **Hotkeys:** WASD, F=Target, K=Keyframe, P=Play, R=Record, Backspace=Exit
- Auto-hides HUD, floating info bar with current mode

### 🎮 Game-Specific
- **Death Ball** — Auto-play, auto-dodge, ESP, prediction, kill feed
- **Piano Auto** — Paste sheets from playpianosheets.com, auto BPM detection, key sustain, speed control
- **Sound Player** — Play any AudioID, volume control, loop, list all map sounds

### 🖥 Graphics
- **Ultra Low / Low** — FPS boost presets
- **Ultra High (PC da NASA)** — Maximum quality settings
- **15+ Shader Presets** — RTX, Cinematic, Neon, VHS, Noir, Sunset, Aqua, Mirror, and more
- **Ambient Changer** — Custom RGB lighting
- **Atmosphere Control** — Density, haze, glow
- **Fog Remover** — Clear map fog instantly
- Restore to original at any time

### 🔧 Utilities
- **Server Hop** — Jump to another server
- **Rejoin** — Reconnect to same server
- **Copy Place ID / Job ID** — One-click clipboard
- **Anti-AFK** — Prevent idle kick
- **Waypoints** — Save positions, teleport back, manage list
- **Shift+F5** — Quick Save All hotkey

### ⚙ Configuration
- Spectate highlight toggle
- **Save Instance** — Full map, characters only, NPCs only, GUIs only, animations only
- Cosmetics (headless, invisible, ghost, hide nametags, hide game UI)
- Remote Spy panel
- Chat Spy panel
- Execute arbitrary Luau code
- **License info & online users** (VIP+ feature)

---

## Premium Experience

### 🦇 Animated Splash Screen
- Full-screen cinematic intro with animated logo
- Loading bar with real-time progress
- Role badge reveal after authentication
- Smooth fade-out transition

### 🔊 UI Sounds
- Click, hover, and menu sounds
- Notification sounds (success, error, warning)
- Tab switch feedback

### Visual Polish
- **Pulsing border glow** — MainFrame and MiniBar breathe between red and purple
- **Topbar avatar** — Player headshot with role-colored border + badge
- **Sliding tab indicator** — Animated underline that glides between tabs
- **Live nametags** — See other script users' role badges above their heads in-game

---

## Roles & Permissions

| Feature | 👀 Visitor | 🦇 User | 🔧 Contributor | ⭐ VIP | 👑 Admin |
|---------|-----------|---------|----------------|--------|----------|
| ESP | ✅ | ✅ | ✅ | ✅ | ✅ |
| Movement | ✅ | ✅ | ✅ | ✅ | ✅ |
| Emotes | ✅ | ✅ | ✅ | ✅ | ✅ |
| Games | ✅ | ✅ | ✅ | ✅ | ✅ |
| Animations | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cinema Mode | ✅ | ✅ | ✅ | ✅ | ✅ |
| Executor | ❌ | ❌ | ✅ | ✅ | ✅ |
| See Online Users | ❌ | ❌ | ✅ | ✅ | ✅ |
| Aimbot | ❌ | ❌ | ❌ | ✅ | ✅ |
| Remote Spy | ❌ | ❌ | ❌ | ✅ | ✅ |
| Save Instance | ❌ | ❌ | ❌ | ✅ | ✅ |
| Admin Panel | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Security

- **Whitelist system** with role-based access (👑 Admin, ⭐ VIP, 🔧 Contributor, 🦇 User, 👀 Visitor)
- **Public access mode** — Open to everyone as Visitor when enabled
- License expiration support
- Ban system with custom messages
- Maintenance mode
- Version control & forced updates
- XOR + Base64 obfuscated source code

---

## Hotkeys

| Key | Action |
|-----|--------|
| `Ctrl+G` | Toggle GUI |
| `N` | Toggle Freecam |
| `Shift+F5` | Save All (map) |
| `Right-Click` | Radial Menu (on player) |
| `Backspace` | Exit Cinema Mode |

---

## Screenshots

*Coming soon*

---

## Contact

- **Discord:** iag0d
- **Roblox:** VampireSonata

---

<p align="center">
  <b>🦇 Create By VampireSonata 🦇</b><br>
  <i>The ultimate Roblox experience.</i>
</p>
