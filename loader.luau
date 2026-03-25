--==================================================
-- VAMPIRE RIG SCANNER v13 - TAB SYSTEM + FULL FEATURES
-- Create By VampireSonata
-- Tabs: Scanner, ESP, Players, Movement, Emote, Games, Settings
-- ⚡ Bundled automaticamente — NÃO edite este arquivo!
-- ⚡ Edite os modulos em vampire-rigs/src/
--==================================================


--[[ ═══════ MODULE: 00_auth.luau ═══════ ]]

--==================================================
-- AUTENTICAÇÃO & WHITELIST
--==================================================
-- Verifica se o jogador está autorizado antes de carregar o script.
-- Whitelist hospedada externamente (GitHub raw / Pastebin / API).
-- Suporta roles: admin, vip, contributor, user

-- ════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════

WHITELIST_URL = "https://raw.githubusercontent.com/IaG0D/vampire-loader/main/whitelist.json"
SCRIPT_VERSION = "v14"
SCRIPT_NAME = "Vampire Rig Scanner"

-- ════════════════════════════════════════════════
-- ROLES & PERMISSÕES
-- ════════════════════════════════════════════════
-- admin    → tudo + ver online + gerenciar
-- vip      → tudo + ver online
-- contributor → features básicas + ver online
-- user     → features básicas apenas

ROLE_HIERARCHY = {
	admin = 4,
	vip = 3,
	contributor = 2,
	user = 1,
}

-- Permissões por role mínimo
ROLE_PERMISSIONS = {
	see_online_users = "contributor",  -- ver quem tá usando
	esp_features = "user",
	movement_features = "user",
	emote_features = "user",
	games_features = "user",
	aimbot_feature = "vip",
	remote_spy = "vip",
	save_instance = "vip",
	executor = "contributor",
	admin_panel = "admin",
}

-- ════════════════════════════════════════════════
-- FETCH WHITELIST
-- ════════════════════════════════════════════════

authData = nil      -- dados do jogador autenticado
authRole = nil      -- role do jogador
authWhitelist = {}  -- whitelist completa (pra ver online)
authPassed = false  -- se passou na autenticação

local function fetchWhitelist()
	local success, result = pcall(function()
		return game:HttpGet(WHITELIST_URL, true)
	end)
	if not success then
		return nil, "Erro ao buscar whitelist: " .. tostring(result)
	end

	local decodeOk, data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(result)
	end)
	if not decodeOk then
		return nil, "Erro ao decodificar whitelist"
	end

	return data, nil
end

-- ════════════════════════════════════════════════
-- VERIFICAR AUTORIZAÇÃO
-- ════════════════════════════════════════════════

local function checkAuth()
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	if not LP then
		return false, "LocalPlayer não encontrado"
	end

	local userId = LP.UserId
	local data, err = fetchWhitelist()
	if not data then
		return false, err
	end

	-- Verificar se o script está ativo
	if data.enabled == false then
		return false, data.maintenance_msg or "Script desativado temporariamente."
	end

	-- Verificar versão mínima (se definida)
	if data.min_version and SCRIPT_VERSION ~= data.min_version then
		if data.force_update then
			return false, "Atualize o script! Versão atual: " .. SCRIPT_VERSION .. " | Necessária: " .. data.min_version
		end
	end

	-- Buscar jogador na whitelist
	local users = data.users or {}
	local found = nil
	for _, entry in ipairs(users) do
		if entry.id == userId then
			found = entry
			break
		end
	end

	if not found then
		return false, data.denied_msg or "Você não está na whitelist. Contate o administrador."
	end

	-- Verificar se está banido
	if found.banned then
		return false, found.ban_reason or "Você foi banido do script."
	end

	-- Verificar expiração (se tiver)
	if found.expires then
		local now = os.time()
		if now > found.expires then
			return false, "Sua licença expirou. Contate o administrador."
		end
	end

	-- Autenticado!
	authData = found
	authRole = found.role or "user"
	authWhitelist = users
	authPassed = true

	return true, nil
end

-- ════════════════════════════════════════════════
-- HELPERS DE PERMISSÃO
-- ════════════════════════════════════════════════

hasPermission = function(permName)
	if not authPassed then return false end
	local minRole = ROLE_PERMISSIONS[permName]
	if not minRole then return true end -- permissão não listada = liberada
	local myLevel = ROLE_HIERARCHY[authRole] or 0
	local reqLevel = ROLE_HIERARCHY[minRole] or 0
	return myLevel >= reqLevel
end

getRoleBadge = function(role)
	if role == "admin" then return "👑"
	elseif role == "vip" then return "⭐"
	elseif role == "contributor" then return "🔧"
	else return "🦇" end
end

getRoleColor = function(role)
	if role == "admin" then return Color3.fromRGB(255, 215, 0)      -- gold
	elseif role == "vip" then return Color3.fromRGB(180, 100, 255)  -- purple
	elseif role == "contributor" then return Color3.fromRGB(100, 200, 255) -- blue
	else return Color3.fromRGB(200, 200, 200) end -- gray
end

-- ════════════════════════════════════════════════
-- TELA DE AUTH DENIED (UI bonita de erro)
-- ════════════════════════════════════════════════

local function showDeniedScreen(reason)
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local pg = LP and LP:FindFirstChildOfClass("PlayerGui")
	if not pg then return end

	local sg = Instance.new("ScreenGui")
	sg.Name = "VampAuthDenied"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.3
	bg.BorderSizePixel = 0
	bg.Parent = sg

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 360, 0, 220)
	card.Position = UDim2.new(0.5, -180, 0.5, -110)
	card.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
	card.BorderSizePixel = 0
	card.Parent = sg
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", card)
	stroke.Color = Color3.fromRGB(200, 40, 40)
	stroke.Thickness = 1.5

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 50)
	icon.Position = UDim2.new(0, 0, 0, 15)
	icon.BackgroundTransparency = 1
	icon.Text = "🦇"
	icon.TextSize = 36
	icon.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 24)
	title.Position = UDim2.new(0, 10, 0, 65)
	title.BackgroundTransparency = 1
	title.Text = SCRIPT_NAME
	title.TextColor3 = Color3.fromRGB(200, 60, 60)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = card

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -30, 0, 60)
	msg.Position = UDim2.new(0, 15, 0, 100)
	msg.BackgroundTransparency = 1
	msg.Text = reason
	msg.TextColor3 = Color3.fromRGB(220, 220, 220)
	msg.TextSize = 12
	msg.Font = Enum.Font.Gotham
	msg.TextWrapped = true
	msg.TextXAlignment = Enum.TextXAlignment.Center
	msg.Parent = card

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 120, 0, 30)
	closeBtn.Position = UDim2.new(0.5, -60, 1, -45)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	closeBtn.Text = "FECHAR"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 12
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = card
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	closeBtn.MouseButton1Click:Connect(function()
		sg:Destroy()
	end)
end

-- ════════════════════════════════════════════════
-- EXECUTAR AUTENTICAÇÃO
-- ════════════════════════════════════════════════

do
	local ok, reason = checkAuth()
	if not ok then
		showDeniedScreen(reason)
		return -- PARA TUDO AQUI, não carrega o script
	end
end

-- Se chegou aqui, está autorizado! O resto do script carrega normalmente.


--[[ ═══════ MODULE: 01_core.luau ═══════ ]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local AvatarEditorService = game:GetService("AvatarEditorService")
AssetService = game:GetService("AssetService")
MarketplaceService = game:GetService("MarketplaceService")
local LP = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local HOTKEY = Enum.KeyCode.G
local REQUIRE_CTRL = true
local LOAD_DELAY = 0.1

--==================================================
-- DEBUG
--==================================================

local function log(...)
    print("[VampScanner]", ...)
end

--==================================================
-- CRIAR UI
--==================================================

if LP.PlayerGui:FindFirstChild("VampireRigScanner") then
    LP.PlayerGui:FindFirstChild("VampireRigScanner"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VampireRigScanner"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LP.PlayerGui

--==================================================
-- CORES
--==================================================

local Colors = {
    bg = Color3.fromRGB(12, 12, 14),
    topbar = Color3.fromRGB(22, 22, 26),
    content = Color3.fromRGB(8, 8, 10),
    card = Color3.fromRGB(18, 18, 22),
    cardLoaded = Color3.fromRGB(18, 28, 18),

    blood = Color3.fromRGB(139, 0, 0),
    bloodLight = Color3.fromRGB(180, 20, 20),
    bloodDark = Color3.fromRGB(100, 0, 0),

    green = Color3.fromRGB(40, 120, 40),
    greenLight = Color3.fromRGB(60, 150, 60),

    text = Color3.fromRGB(240, 240, 245),
    textDim = Color3.fromRGB(130, 130, 140),
    textBlood = Color3.fromRGB(200, 50, 50),
    textLoading = Color3.fromRGB(255, 200, 100),

    -- Premium palette
    accent = Color3.fromRGB(180, 20, 20),
    glowRed = Color3.fromRGB(220, 40, 40),
    glowPurple = Color3.fromRGB(120, 60, 180),
    surfaceLight = Color3.fromRGB(28, 28, 32),
    surfaceMid = Color3.fromRGB(22, 22, 26),
    separator = Color3.fromRGB(45, 20, 20),
    purple = Color3.fromRGB(80, 40, 120),
    purpleLight = Color3.fromRGB(110, 60, 160),
    warning = Color3.fromRGB(200, 150, 50),
    tabActive = Color3.fromRGB(139, 0, 0),
    tabInactive = Color3.fromRGB(28, 28, 32),
    inputBg = Color3.fromRGB(25, 25, 30),
    inputBorder = Color3.fromRGB(50, 50, 60),
}

--==================================================
-- VARIABLES
--==================================================

-- State variables (globals to stay under Lua's 200 local limit)
currentPreviewData = nil
previewConnection = nil
allScannedRigs = {}
isExporting = false

-- Tab system
activeTab = "scanner"
tabButtons = {}
tabContents = {}

-- Auto-scan
autoScanConfig = { enabled = true, interval = 5 }
autoScanConnection = nil
scannedPlayerSet = {}
scannedNPCSet = {}

-- Spectate state
spectatingInfo = nil
spectateHighlight = nil
savedCameraSubject = nil
spectateConfig = { showHighlight = true }

-- ESP state
espState = {
    players = false,
    npcs = false,
    cameras = false,
    healthBars = false,
    boxESP = false,
    chams = false,
    tracers = false,
    skeleton = false,
    headDot = false,
    threatLevel = false,
    toolESP = false,
    soundESP = false,
    footsteps = false,
}
espConnection = nil
espObjects = {}
tracerLines = {}
skeletonBeams = {}
headDotObjects = {}
footstepParts = {}
footstepConnection = nil
soundEspObjects = {}
soundEspConnection = nil

-- Movement state
movementState = {
    fly = false,
    noclip = false,
    infiniteJump = false,
    freecam = false,
    clickTP = false,
    antiVoid = false,
    spin = false,
    spinSpeed = 10,
    speed = 16,
    jumpPower = 50,
}
flyConnection = nil
flyBG = nil
flyBV = nil
noclipConnection = nil
jumpConnection = nil
freecamConnection = nil
savedCameraState = nil
speedConnection = nil
clickTPConnection = nil
antiVoidConnection = nil
antiVoidLastSafe = nil
spinConnection = nil
flashbackSavedCFrame = nil

-- Aimbot state
aimbotState = {
    enabled = false,
    fov = 90,
    teamCheck = true,
    smoothness = 5,
}
aimbotConnection = nil
aimbotFovCircle = nil

-- Piano auto state
pianoAutoPlaying = false
pianoAutoThread = nil
pianoAutoSpeed = 1.0
pianoBPMLocked = false
pianoDetectedBPM = nil
pianoManualBPM = nil

-- Utils state
antiAfkEnabled = false
antiAfkConnection = nil
savedWaypoints = {} -- { {name, cframe}, ... }
currentSound = nil
SoundVolumeValue = 50
soundLoopState = { loop = false }
savedFogEnd = nil
savedFogStart = nil
savedAmbient = nil
savedOutdoorAmbient = nil

-- Emote state
currentEmoteTrack = nil
emotePaused = false
emoteSpeed = 1
currentEmoteAnimId = nil  -- last played animation ID (for sync)

-- Sync players state
syncPlayers = {}          -- { [Player] = true } checked players
syncTracks = {}           -- { [Player] = AnimationTrack } active tracks per synced player

-- Shadow state
shadowState = {
    active = false,
    mode = "orbit",      -- "orbit" | "head"
    target = nil,
    delay = 0,
    distance = 4,
    angle = 0,           -- 0-360° (0=behind, 90=right, 180=front, 270=left)
    height = 0,          -- -5 to 10 studs vertical offset
    faceTarget = false,  -- look at target or match their rotation
    mirrorAnims = true,  -- mirror target animations (ON by default)
    autoOrbit = false,   -- slowly rotate around target
    orbitSpeed = 2,      -- degrees per frame (1-10)
    trail = false,       -- trail effect while shadowing
}
shadowConnection = nil
shadowHistory = {}
shadowRecordedPath = {}
shadowRecording = false
shadowReplaying = false
shadowReplayConnection = nil
shadowTrailInstance = nil

-- Notification state
notifContainer = nil
notifCount = 0

-- Settings state
saveConfigState = {
    DecompileMode = false,
    SavePlayers = false,
    RemovePlayerCharacters = true,
    NilInstances = false,
    SaveNonCreatable = false,
    IsolateLocalPlayer = false,
    SaveCameraInstances = false,
}

-- Emote catalog state
emoteCatalogPages = nil
emoteCatalogHasMore = false
emoteSearchVersion = 0
isLoadingMoreEmotes = false

-- Favorite emotes state
favoriteEmotes = {}         -- Array of { id, name, isBundle }
emoteTabPreloaded = false   -- Whether trending emotes have been loaded

-- Animation tab state
originalAnimations = {}     -- { idle = { {name, id, weight}, ... }, ... } snapshot
currentAnimations = {}      -- { idle = number, walk = number, ... } IDs numericos aplicados
animFavorites = {}           -- { { id = number, name = string }, ... }
animSpeed = 1                -- speed multiplier (0.2 — 5.0)
animDetailView = false       -- detail view vs catalog grid
animDetailBundleId = nil     -- bundleId do detalhe aberto
animDetailBundleData = nil   -- unpacked bundle data pro detail view
animDetailSelected = nil     -- { slotName = true/false } selecao no detail view
animPreviewTrack = nil       -- AnimationTrack ativo de preview
animCatalogPages = nil
animCatalogHasMore = false
animSearchVersion = 0
isLoadingMoreAnims = false
animTabPreloaded = false

ANIM_SLOTS = {"idle", "walk", "run", "jump", "climb", "swim", "fall"}
ANIM_SLOT_LABELS = { idle = "Idle", walk = "Walk", run = "Run", jump = "Jump", climb = "Climb", swim = "Swim", fall = "Fall" }
ASSET_TYPE_MAP = {
    [48] = "climb", [50] = "fall", [51] = "idle",
    [52] = "jump", [53] = "run", [54] = "swim", [55] = "walk"
}

-- Cosmetic state
cosmeticState = {
    headless = false,
    invisible = false,
    ghost = false,
    hideNametags = false,
    hideVampNametag = false,
    hideGameUI = false,
}

-- Active troll connection
trollConnection = nil
trollTarget = nil
trollSpeedMul = 1
trollSavedCFrame = nil
trollSitTrack = nil
trollJailParts = {}

-- Remote spy state
remoteSpyActive = false
remoteSpyLog = {}
remoteSpyHook = nil
scannedRemotes = {}
blockedRemotes = {}
remoteCallCounts = {}
autoRepeatActive = false

-- Anti-AFK state
antiAfkActive = false
antiAfkConnection = nil

-- Chat spy state
chatSpyActive = false
chatSpyLog = {}
chatSpyConnections = {}

-- Backpack viewer state
backpackTarget = nil
backpackItems = {}

-- Graphics state
graphicsOriginal = nil
graphicsMode = "default"
graphicsShader = "none"

-- Player info state
playerInfoState = { active = false }
playerInfoActive = false
playerInfoBillboards = {}
playerInfoConnection = nil

-- Forward-declared functions are assigned as globals by later modules
-- (removed local forward declarations to stay under Lua's 200 local limit)

--==================================================
-- UI HELPERS
--==================================================

local function addGradient(frame, c1, c2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1 or Colors.surfaceLight, c2 or Colors.bg)
    g.Rotation = rotation or 90
    g.Parent = frame
    return g
end

local function addAccentLine(parent, position, color, size)
    local line = Instance.new("Frame")
    line.Name = "AccentLine"
    line.Size = size or UDim2.new(1, 0, 0, 1)
    line.Position = position or UDim2.new(0, 0, 1, 0)
    line.BackgroundColor3 = color or Colors.accent
    line.BackgroundTransparency = 0.3
    line.BorderSizePixel = 0
    line.Parent = parent
    local lineGrad = Instance.new("UIGradient")
    lineGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color or Colors.accent),
        ColorSequenceKeypoint.new(0.5, color or Colors.accent),
        ColorSequenceKeypoint.new(1, Colors.bg),
    })
    lineGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.7, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    lineGrad.Parent = line
    return line
end

local function makeHoverable(btn, normalColor, hoverColor, pressColor)
    local hc = hoverColor or Color3.new(
        math.min(normalColor.R + 0.08, 1),
        math.min(normalColor.G + 0.08, 1),
        math.min(normalColor.B + 0.08, 1)
    )
    local pc = pressColor or Color3.new(
        math.max(normalColor.R - 0.05, 0),
        math.max(normalColor.G - 0.05, 0),
        math.max(normalColor.B - 0.05, 0)
    )
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = hc,
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = normalColor,
        }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.05), {
            BackgroundColor3 = pc,
        }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = hc,
        }):Play()
    end)
end

local function addBtnGradient(btn)
    local g = Instance.new("UIGradient")
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    g.Rotation = 0
    g.Parent = btn
    return g
end

--==================================================
-- REUSABLE UI COMPONENTS
--==================================================

local function createSectionHeader(parent, text, yPos)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.Position = UDim2.new(0, 0, 0, yPos)
    header.BackgroundTransparency = 1
    header.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.bloodLight
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header

    addAccentLine(header, UDim2.new(0, 0, 1, -1), Colors.blood, UDim2.new(1, 0, 0, 1))

    return header
end

local function createVampToggle(parent, label, key, stateTable, yPos, accentColor)
    local ac = accentColor or Colors.green

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.Position = UDim2.new(0, 0, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -55, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Colors.textDim
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -44, 0, 3)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local function refresh()
        local on = stateTable[key]
        btn.Text = on and "ON" or "OFF"
        local targetColor = on and ac or Color3.fromRGB(50, 25, 25)
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = targetColor,
        }):Play()
        btn.TextColor3 = Colors.text
    end

    local function getColor()
        return stateTable[key] and ac or Color3.fromRGB(50, 25, 25)
    end
    btn.MouseEnter:Connect(function()
        local base = getColor()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.new(
                math.min(base.R + 0.06, 1),
                math.min(base.G + 0.06, 1),
                math.min(base.B + 0.06, 1)
            ),
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = getColor(),
        }):Play()
    end)

    refresh()
    return { row = row, btn = btn, lbl = lbl, refresh = refresh }
end

local function createSliderRow(parent, label, min, max, default, yPos, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 32)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    -- Label (left)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65, 0, 0, 12)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Colors.textDim
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    -- Value label (right)
    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.35, 0, 0, 12)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = Colors.text
    valLabel.TextSize = 10
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = row

    -- Track bar
    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, 0, 0, 8)
    track.Position = UDim2.new(0, 0, 0, 18)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

    -- Fill bar
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((default - min) / math.max(max - min, 1), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = Colors.glowPurple
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new(Colors.blood, Colors.glowPurple)
    fillGrad.Parent = fill

    -- Thumb knob
    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(math.clamp((default - min) / math.max(max - min, 1), 0, 1), 0, 0.5, 0)
    thumb.BackgroundColor3 = Colors.text
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 2
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    local thumbStroke = Instance.new("UIStroke", thumb)
    thumbStroke.Color = Colors.glowPurple
    thumbStroke.Thickness = 1.5

    local currentVal = default
    local dragging = false

    local function updateVisual(pct)
        pct = math.clamp(pct, 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, 0, 0.5, 0)
    end

    local function setValue(v)
        currentVal = math.clamp(math.floor(v + 0.5), min, max)
        local pct = (currentVal - min) / math.max(max - min, 1)
        updateVisual(pct)
        valLabel.Text = tostring(currentVal)
        if callback then callback(currentVal) end
    end

    local function handleInput(inputPos)
        local absPos = track.AbsolutePosition.X
        local absSize = track.AbsoluteSize.X
        if absSize <= 0 then return end
        local pct = math.clamp((inputPos - absPos) / absSize, 0, 1)
        local rawVal = min + pct * (max - min)
        setValue(rawVal)
    end

    -- Click on track
    track.MouseButton1Down:Connect(function()
        dragging = true
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            handleInput(input.Position.X)
        end
    end)

    -- Drag anywhere while held
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            handleInput(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Thumb hover glow
    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            TweenService:Create(thumb, TweenInfo.new(0.15), { Size = UDim2.new(0, 16, 0, 16) }):Play()
            TweenService:Create(thumbStroke, TweenInfo.new(0.15), { Thickness = 2 }):Play()
        end
    end)
    thumb.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            TweenService:Create(thumb, TweenInfo.new(0.2), { Size = UDim2.new(0, 14, 0, 14) }):Play()
            TweenService:Create(thumbStroke, TweenInfo.new(0.2), { Thickness = 1.5 }):Play()
        end
    end)

    return { row = row, getValue = function() return currentVal end, setValue = setValue }
end


--[[ ═══════ MODULE: 02_notifications.luau ═══════ ]]

--==================================================
-- NOTIFICATION SYSTEM
--==================================================

notifContainer = Instance.new("Frame")
notifContainer.Name = "Notifications"
notifContainer.Size = UDim2.new(0, 280, 1, -20)
notifContainer.Position = UDim2.new(1, -290, 0, 10)
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = ScreenGui

local notifLayout = Instance.new("UIListLayout", notifContainer)
notifLayout.Padding = UDim.new(0, 6)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder

local notifTypeColors = {
    info = Colors.blood,
    success = Colors.green,
    warning = Colors.warning,
    error = Colors.glowRed,
}

local notifTypeIcons = {
    info = "🦇",
    success = "✅",
    warning = "⚠",
    error = "❌",
}

notify = function(text, notifType)
    notifType = notifType or "info"
    local color = notifTypeColors[notifType] or Colors.blood
    local icon = notifTypeIcons[notifType] or "🦇"

    notifCount = notifCount + 1

    -- Limita a 5 notificacoes visiveis
    local children = notifContainer:GetChildren()
    local frames = {}
    for _, c in ipairs(children) do
        if c:IsA("Frame") then table.insert(frames, c) end
    end
    if #frames >= 5 then
        frames[1]:Destroy()
    end

    local toast = Instance.new("Frame")
    toast.Name = "Notif_" .. notifCount
    toast.Size = UDim2.new(1, 0, 0, 40)
    toast.BackgroundColor3 = Colors.card
    toast.BorderSizePixel = 0
    toast.LayoutOrder = notifCount
    toast.BackgroundTransparency = 1
    toast.Parent = notifContainer
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)
    addGradient(toast, Colors.surfaceLight, Colors.card, 0)

    local toastStroke = Instance.new("UIStroke", toast)
    toastStroke.Color = color
    toastStroke.Thickness = 1
    toastStroke.Transparency = 0.5

    -- Left accent bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -8)
    bar.Position = UDim2.new(0, 0, 0, 4)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.Parent = toast
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 24, 0, 24)
    iconLabel.Position = UDim2.new(0, 8, 0, 8)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 14
    iconLabel.Parent = toast

    -- Text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -40, 1, 0)
    textLabel.Position = UDim2.new(0, 34, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Colors.text
    textLabel.TextSize = 11
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    textLabel.Parent = toast

    -- Slide in
    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
    }):Play()

    -- Auto dismiss
    task.delay(3, function()
        if toast and toast.Parent then
            local fadeOut = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
            })
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                if toast and toast.Parent then toast:Destroy() end
            end)
        end
    end)
end


--[[ ═══════ MODULE: 03_minibar.luau ═══════ ]]

--==================================================
-- MINI BAR (widget no canto)
--==================================================

local MiniBar = Instance.new("TextButton")
MiniBar.Name = "MiniBar"
MiniBar.Size = UDim2.new(0, 210, 0, 56)
MiniBar.Position = UDim2.new(1, 0, 1, -70) -- comeca fora da tela (direita)
MiniBar.BackgroundColor3 = Colors.bg
MiniBar.BorderSizePixel = 0
MiniBar.AutoButtonColor = false
MiniBar.Text = ""
MiniBar.Parent = ScreenGui
Instance.new("UICorner", MiniBar).CornerRadius = UDim.new(0, 12)
local miniStroke = Instance.new("UIStroke", MiniBar)
miniStroke.Color = Colors.blood
miniStroke.Thickness = 1.5
addGradient(MiniBar, Colors.surfaceLight, Colors.bg, 45)

-- Avatar thumbnail
local AvatarFrame = Instance.new("Frame")
AvatarFrame.Size = UDim2.new(0, 40, 0, 40)
AvatarFrame.Position = UDim2.new(0, 8, 0, 8)
AvatarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AvatarFrame.Parent = MiniBar
Instance.new("UICorner", AvatarFrame).CornerRadius = UDim.new(1, 0)
local avatarStroke = Instance.new("UIStroke", AvatarFrame)
avatarStroke.Color = Colors.blood
avatarStroke.Thickness = 1.5

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(1, 0, 1, 0)
AvatarImg.BackgroundTransparency = 1
AvatarImg.Image = ""
AvatarImg.Parent = AvatarFrame
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

-- Carrega avatar do LocalPlayer
task.spawn(function()
    local ok, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and thumb then
        AvatarImg.Image = thumb
    end
end)

-- Separador vertical
local miniSep = Instance.new("Frame")
miniSep.Size = UDim2.new(0, 1, 0, 36)
miniSep.Position = UDim2.new(0, 52, 0, 10)
miniSep.BackgroundColor3 = Colors.blood
miniSep.BackgroundTransparency = 0.5
miniSep.BorderSizePixel = 0
miniSep.Parent = MiniBar

-- Nome do usuario
local MiniName = Instance.new("TextLabel")
MiniName.Size = UDim2.new(0, 140, 0, 16)
MiniName.Position = UDim2.new(0, 55, 0, 6)
MiniName.BackgroundTransparency = 1
MiniName.Text = LP.DisplayName
MiniName.TextColor3 = Colors.bloodLight
MiniName.TextSize = 12
MiniName.Font = Enum.Font.GothamBold
MiniName.TextXAlignment = Enum.TextXAlignment.Left
MiniName.TextTruncate = Enum.TextTruncate.AtEnd
MiniName.Parent = MiniBar

-- Titulo
local MiniTitle = Instance.new("TextLabel")
MiniTitle.Size = UDim2.new(0, 140, 0, 14)
MiniTitle.Position = UDim2.new(0, 55, 0, 22)
MiniTitle.BackgroundTransparency = 1
MiniTitle.Text = "🦇 Vampire Rigs v13"
MiniTitle.TextColor3 = Colors.textDim
MiniTitle.TextSize = 10
MiniTitle.Font = Enum.Font.GothamBold
MiniTitle.TextXAlignment = Enum.TextXAlignment.Left
MiniTitle.Parent = MiniBar

-- Hint
local MiniHint = Instance.new("TextLabel")
MiniHint.Size = UDim2.new(0, 140, 0, 12)
MiniHint.Position = UDim2.new(0, 55, 0, 38)
MiniHint.BackgroundTransparency = 1
MiniHint.Text = "Ctrl+G to open"
MiniHint.TextColor3 = Color3.fromRGB(80, 80, 80)
MiniHint.TextSize = 9
MiniHint.Font = Enum.Font.Gotham
MiniHint.TextXAlignment = Enum.TextXAlignment.Left
MiniHint.Parent = MiniBar

-- Icone morcego pulsante
local MiniBat = Instance.new("TextLabel")
MiniBat.Size = UDim2.new(0, 20, 0, 20)
MiniBat.Position = UDim2.new(1, -26, 0, 18)
MiniBat.BackgroundTransparency = 1
MiniBat.Text = "🦇"
MiniBat.TextSize = 16
MiniBat.Parent = MiniBar


--[[ ═══════ MODULE: 04_mainframe.luau ═══════ ]]

--==================================================
-- MAIN FRAME + TAB SYSTEM
--==================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 420, 0, 560)
MainFrame.Position = UDim2.new(0.3, 0, 0.5, -280)
MainFrame.BackgroundColor3 = Colors.bg
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Colors.blood
mainStroke.Thickness = 1.2
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
addGradient(MainFrame, Colors.surfaceLight, Color3.fromRGB(8, 8, 10), 90)

--==================================================
-- TOP BAR
--==================================================

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Colors.topbar
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
addGradient(TopBar, Color3.fromRGB(40, 8, 8), Colors.topbar, 0)

local TopBarFix = Instance.new("Frame")
TopBarFix.Size = UDim2.new(1, 0, 0, 10)
TopBarFix.Position = UDim2.new(0, 0, 1, -10)
TopBarFix.BackgroundColor3 = Colors.topbar
TopBarFix.BorderSizePixel = 0
TopBarFix.Parent = TopBar

addAccentLine(TopBar, UDim2.new(0, 0, 1, -1), Colors.blood)

local VampIcon = Instance.new("TextLabel")
VampIcon.Size = UDim2.new(0, 30, 0, 30)
VampIcon.Position = UDim2.new(0, 8, 0, 5)
VampIcon.BackgroundTransparency = 1
VampIcon.Text = "🦇"
VampIcon.TextSize = 20
VampIcon.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 40, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Vampire Rig Scanner"
Title.TextColor3 = Colors.bloodLight
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -32, 0, 7)
CloseBtn.BackgroundColor3 = Colors.blood
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Colors.text
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(CloseBtn, Colors.blood, Colors.glowRed)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -62, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MinBtn.Text = "-"
MinBtn.TextColor3 = Colors.text
MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBold
MinBtn.AutoButtonColor = false
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(MinBtn, Color3.fromRGB(50, 50, 50), Color3.fromRGB(70, 70, 70))

--==================================================
-- TAB BAR
--==================================================

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, 34)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Colors.topbar
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame
addAccentLine(TabBar, UDim2.new(0, 0, 1, -1), Colors.blood)

local tabDefs = {
    { id = "scanner",  icon = "🔍", label = "Rigs" },
    { id = "esp",      icon = "👁",  label = "ESP" },
    { id = "player",   icon = "👤", label = "Players" },
    { id = "movement", icon = "🏃", label = "Move" },
    { id = "emote",    icon = "💃", label = "Emote" },
    { id = "games",    icon = "🎮", label = "Games" },
    { id = "graphics", icon = "🖥", label = "GFX" },
    { id = "utils",    icon = "🔧", label = "Utils" },
    { id = "anim",     icon = "🎞", label = "Anim" },
    { id = "settings", icon = "⚙",  label = "Config" },
}

-- Container para os botoes (UIListLayout aqui dentro, sem afetar o accent line)
local TabBtnContainer = Instance.new("Frame")
TabBtnContainer.Size = UDim2.new(1, 0, 1, 0)
TabBtnContainer.BackgroundTransparency = 1
TabBtnContainer.BorderSizePixel = 0
TabBtnContainer.Parent = TabBar

local tabBarLayout = Instance.new("UIListLayout", TabBtnContainer)
tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabBarLayout.Padding = UDim.new(0, 0)

for i, def in ipairs(tabDefs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. def.id
    tabBtn.Size = UDim2.new(1 / #tabDefs, 0, 1, 0)
    tabBtn.LayoutOrder = i
    tabBtn.BackgroundColor3 = Colors.tabInactive
    tabBtn.BackgroundTransparency = 0.5
    tabBtn.Text = def.icon
    tabBtn.TextColor3 = Colors.textDim
    tabBtn.TextSize = 16
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.AutoButtonColor = false
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = TabBtnContainer

    -- Tooltip label (aparece no hover)
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 50, 0, 16)
    tooltip.Position = UDim2.new(0.5, -25, 1, 2)
    tooltip.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
    tooltip.Text = def.label
    tooltip.TextColor3 = Colors.bloodLight
    tooltip.TextSize = 9
    tooltip.Font = Enum.Font.GothamBold
    tooltip.Visible = false
    tooltip.ZIndex = 10
    tooltip.Parent = tabBtn
    Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", tooltip).Color = Colors.blood

    tabBtn.MouseEnter:Connect(function() tooltip.Visible = true end)
    tabBtn.MouseLeave:Connect(function() tooltip.Visible = false end)

    -- Active indicator line (bottom of tab)
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0.7, 0, 0, 2)
    indicator.Position = UDim2.new(0.15, 0, 1, -3)
    indicator.BackgroundColor3 = Colors.blood
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = tabBtn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 1)

    tabButtons[def.id] = { btn = tabBtn, indicator = indicator, def = def }

    tabBtn.MouseButton1Click:Connect(function()
        switchTab(def.id)
    end)
end

--==================================================
-- TAB CONTENT CONTAINER
--==================================================

local TabContent = Instance.new("Frame")
TabContent.Name = "TabContent"
TabContent.Size = UDim2.new(1, -16, 1, -107) -- 40 topbar + 34 tabbar + 8 pad + 25 footer
TabContent.Position = UDim2.new(0, 8, 0, 78)
TabContent.BackgroundTransparency = 1
TabContent.BorderSizePixel = 0
TabContent.Parent = MainFrame

--==================================================
-- FOOTER
--==================================================

local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, 0, 0, 25)
Footer.Position = UDim2.new(0, 0, 1, -25)
Footer.BackgroundColor3 = Colors.topbar
Footer.BorderSizePixel = 0
Footer.Parent = MainFrame
Instance.new("UICorner", Footer).CornerRadius = UDim.new(0, 10)
addAccentLine(Footer, UDim2.new(0, 0, 0, 0), Colors.blood)

local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(1, 0, 1, 0)
Credits.BackgroundTransparency = 1
Credits.Text = "🦇 Create By VampireSonata 🦇"
Credits.TextColor3 = Colors.textBlood
Credits.TextSize = 11
Credits.Font = Enum.Font.GothamBold
Credits.Parent = Footer

--==================================================
-- SWITCH TAB
--==================================================

switchTab = function(tabId)
    activeTab = tabId

    -- Update tab buttons
    for id, data in pairs(tabButtons) do
        local isActive = (id == tabId)
        data.btn.BackgroundTransparency = isActive and 0 or 0.5
        data.btn.BackgroundColor3 = isActive and Colors.tabActive or Colors.tabInactive
        data.btn.TextColor3 = isActive and Colors.text or Colors.textDim
        data.indicator.Visible = isActive
    end

    -- Update tab content visibility
    for id, content in pairs(tabContents) do
        content.Visible = (id == tabId)
    end
end


--[[ ═══════ MODULE: 05_tab_scanner.luau ═══════ ]]

--==================================================
-- TAB: SCANNER
--==================================================

local ScannerContent = Instance.new("Frame")
ScannerContent.Name = "ScannerContent"
ScannerContent.Size = UDim2.new(1, 0, 1, 0)
ScannerContent.BackgroundTransparency = 1
ScannerContent.Parent = TabContent
tabContents["scanner"] = ScannerContent

-- Search bar
local SearchBar = Instance.new("TextBox")
SearchBar.Name = "SearchBar"
SearchBar.Size = UDim2.new(1, 0, 0, 28)
SearchBar.Position = UDim2.new(0, 0, 0, 0)
SearchBar.BackgroundColor3 = Colors.inputBg
SearchBar.Text = ""
SearchBar.PlaceholderText = "🔍 Search rigs..."
SearchBar.TextColor3 = Colors.text
SearchBar.PlaceholderColor3 = Colors.textDim
SearchBar.TextSize = 11
SearchBar.Font = Enum.Font.Gotham
SearchBar.ClearTextOnFocus = false
SearchBar.Parent = ScannerContent
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0, 6)
local searchStroke = Instance.new("UIStroke", SearchBar)
searchStroke.Color = Colors.inputBorder
searchStroke.Thickness = 1

SearchBar.Focused:Connect(function()
    TweenService:Create(searchStroke, TweenInfo.new(0.2), { Color = Colors.bloodLight, Thickness = 1.5 }):Play()
end)
SearchBar.FocusLost:Connect(function()
    TweenService:Create(searchStroke, TweenInfo.new(0.3), { Color = Colors.inputBorder, Thickness = 1 }):Play()
end)

-- Control row: Auto-scan toggle + Scan button
local ControlRow = Instance.new("Frame")
ControlRow.Size = UDim2.new(1, 0, 0, 30)
ControlRow.Position = UDim2.new(0, 0, 0, 32)
ControlRow.BackgroundTransparency = 1
ControlRow.Parent = ScannerContent

local AutoScanToggle = createVampToggle(ControlRow, "Auto-Scan", "enabled", autoScanConfig, 0, Colors.green)

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, 0, 0, 30)
ScanBtn.Position = UDim2.new(0, 0, 0, 64)
ScanBtn.BackgroundColor3 = Colors.blood
ScanBtn.Text = "🩸 SCAN"
ScanBtn.TextColor3 = Colors.text
ScanBtn.TextSize = 13
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.AutoButtonColor = false
ScanBtn.Parent = ScannerContent
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ScanBtn)
makeHoverable(ScanBtn, Colors.blood, Colors.glowRed)

-- Export + count row
local ExportBtn = Instance.new("TextButton")
ExportBtn.Size = UDim2.new(0.5, -3, 0, 26)
ExportBtn.Position = UDim2.new(0, 0, 0, 98)
ExportBtn.BackgroundColor3 = Colors.bloodDark
ExportBtn.Text = "🦇 EXPORT ALL"
ExportBtn.TextColor3 = Colors.text
ExportBtn.TextSize = 11
ExportBtn.Font = Enum.Font.GothamBold
ExportBtn.AutoButtonColor = false
ExportBtn.Parent = ScannerContent
Instance.new("UICorner", ExportBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ExportBtn)
makeHoverable(ExportBtn, Colors.bloodDark, Colors.blood)

local CountLabel = Instance.new("TextLabel")
CountLabel.Size = UDim2.new(0.5, -3, 0, 26)
CountLabel.Position = UDim2.new(0.5, 3, 0, 98)
CountLabel.BackgroundTransparency = 1
CountLabel.Text = "0P | 0N"
CountLabel.TextColor3 = Colors.textDim
CountLabel.TextSize = 11
CountLabel.Font = Enum.Font.GothamBold
CountLabel.TextXAlignment = Enum.TextXAlignment.Right
CountLabel.Parent = ScannerContent

-- Result scroll area
local ResultScroll = Instance.new("ScrollingFrame")
ResultScroll.Name = "ResultScroll"
ResultScroll.Size = UDim2.new(1, 0, 1, -162)
ResultScroll.Position = UDim2.new(0, 0, 0, 128)
ResultScroll.BackgroundColor3 = Colors.content
ResultScroll.BorderSizePixel = 0
ResultScroll.ScrollBarThickness = 4
ResultScroll.ScrollBarImageColor3 = Colors.blood
ResultScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ResultScroll.Parent = ScannerContent
Instance.new("UICorner", ResultScroll).CornerRadius = UDim.new(0, 6)
local resultStroke = Instance.new("UIStroke", ResultScroll)
resultStroke.Color = Colors.separator
resultStroke.Thickness = 0.5
resultStroke.Transparency = 0.5

local ResultLayout = Instance.new("UIListLayout")
ResultLayout.Padding = UDim.new(0, 5)
ResultLayout.Parent = ResultScroll
local resultPad = Instance.new("UIPadding", ResultScroll)
resultPad.PaddingTop = UDim.new(0, 4)
resultPad.PaddingLeft = UDim.new(0, 4)
resultPad.PaddingRight = UDim.new(0, 4)

-- Unspectate button (hidden by default)
local UnspectateBtn = Instance.new("TextButton")
UnspectateBtn.Size = UDim2.new(1, 0, 0, 26)
UnspectateBtn.Position = UDim2.new(0, 0, 1, -28)
UnspectateBtn.BackgroundColor3 = Colors.blood
UnspectateBtn.Text = "🦇 UNSPECTATE"
UnspectateBtn.TextColor3 = Colors.text
UnspectateBtn.TextSize = 11
UnspectateBtn.Font = Enum.Font.GothamBold
UnspectateBtn.AutoButtonColor = false
UnspectateBtn.Visible = false
UnspectateBtn.Parent = ScannerContent
Instance.new("UICorner", UnspectateBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(UnspectateBtn)
makeHoverable(UnspectateBtn, Colors.blood, Colors.glowRed)


--[[ ═══════ MODULE: 06_tab_esp.luau ═══════ ]]

--==================================================
-- TAB: ESP
--==================================================

local ESPContent = Instance.new("Frame")
ESPContent.Name = "ESPContent"
ESPContent.Size = UDim2.new(1, 0, 1, 0)
ESPContent.BackgroundTransparency = 1
ESPContent.Visible = false
ESPContent.Parent = TabContent
tabContents["esp"] = ESPContent

-- Scroll container
local ESPScroll = Instance.new("ScrollingFrame")
ESPScroll.Size = UDim2.new(1, 0, 1, 0)
ESPScroll.BackgroundTransparency = 1
ESPScroll.ScrollBarThickness = 3
ESPScroll.ScrollBarImageColor3 = Colors.blood
ESPScroll.CanvasSize = UDim2.new(0, 0, 0, 870)
ESPScroll.BorderSizePixel = 0
ESPScroll.Parent = ESPContent

--==================================================
-- SECTION: Players & NPCs
--==================================================

createSectionHeader(ESPScroll, "Players & NPCs", 0)

local espToggles = {}

espToggles.players = createVampToggle(ESPScroll, "Player ESP", "players", espState, 26, Colors.bloodLight)
espToggles.npcs = createVampToggle(ESPScroll, "NPC ESP", "npcs", espState, 56, Colors.green)
espToggles.cameras = createVampToggle(ESPScroll, "Camera ESP", "cameras", espState, 86, Colors.warning)

--==================================================
-- SECTION: Visual Modes
--==================================================

createSectionHeader(ESPScroll, "Visual Modes", 120)

espToggles.healthBars = createVampToggle(ESPScroll, "Health Bars", "healthBars", espState, 146, Colors.bloodLight)
espToggles.boxESP = createVampToggle(ESPScroll, "Box Highlight", "boxESP", espState, 176, Colors.glowPurple)
espToggles.chams = createVampToggle(ESPScroll, "Chams (Fill)", "chams", espState, 206, Colors.glowRed)

--==================================================
-- SECTION: Tracking
--==================================================

createSectionHeader(ESPScroll, "Tracking", 240)

espToggles.tracers = createVampToggle(ESPScroll, "Tracers (Lines)", "tracers", espState, 266, Color3.fromRGB(0, 180, 255))
espToggles.skeleton = createVampToggle(ESPScroll, "Skeleton ESP", "skeleton", espState, 296, Color3.fromRGB(200, 200, 200))
espToggles.headDot = createVampToggle(ESPScroll, "Head Dot", "headDot", espState, 326, Color3.fromRGB(255, 80, 80))
espToggles.threatLevel = createVampToggle(ESPScroll, "Threat Level", "threatLevel", espState, 356, Color3.fromRGB(255, 160, 0))
espToggles.toolESP = createVampToggle(ESPScroll, "Tool ESP", "toolESP", espState, 386, Color3.fromRGB(180, 120, 255))
espToggles.itemIcons = createVampToggle(ESPScroll, "Item Icons", "itemIcons", espState, 416, Color3.fromRGB(200, 140, 40))

--==================================================
-- SECTION: World
--==================================================

createSectionHeader(ESPScroll, "World", 450)

-- These toggles are NOT in espToggles — they have separate start/stop
FootstepsToggle = createVampToggle(ESPScroll, "Footsteps Trail", "footsteps", espState, 476, Color3.fromRGB(120, 200, 80))
SoundESPToggle = createVampToggle(ESPScroll, "Sound ESP", "soundESP", espState, 506, Color3.fromRGB(255, 200, 60))

--==================================================
-- SECTION: Player Details
--==================================================

createSectionHeader(ESPScroll, "Player Details", 540)

PlayerInfoToggle = createVampToggle(ESPScroll, "Player Info Cards", "active", playerInfoState, 566, Color3.fromRGB(40, 180, 60))

--==================================================
-- SECTION: Info
--==================================================

--==================================================
-- SECTION: Aimbot
--==================================================

createSectionHeader(ESPScroll, "Aimbot", 600)

AimbotToggle = createVampToggle(ESPScroll, "Aimbot (Right Click)", "enabled", aimbotState, 626, Colors.glowRed)

AimbotFovSlider = createSliderRow(ESPScroll, "FOV Radius", 10, 360, 90, 656, function(val)
    aimbotState.fov = val
    if aimbotFovCircle then
        pcall(function() aimbotFovCircle.Radius = val end)
    end
end)

AimbotSmoothnessSlider = createSliderRow(ESPScroll, "Smoothness", 1, 20, 5, 694, function(val)
    aimbotState.smoothness = val
end)

AimbotTeamCheckToggle = createVampToggle(ESPScroll, "Team Check (Skip Allies)", "teamCheck", aimbotState, 730, Colors.green)

--==================================================
-- SECTION: Info
--==================================================

createSectionHeader(ESPScroll, "Info", 764)

local ESPStatusLabel = Instance.new("TextLabel")
ESPStatusLabel.Size = UDim2.new(1, 0, 0, 20)
ESPStatusLabel.Position = UDim2.new(0, 0, 0, 790)
ESPStatusLabel.BackgroundTransparency = 1
ESPStatusLabel.Text = "ESP OFF — toggle features above"
ESPStatusLabel.TextColor3 = Colors.textDim
ESPStatusLabel.TextSize = 11
ESPStatusLabel.Font = Enum.Font.Gotham
ESPStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
ESPStatusLabel.Parent = ESPScroll

-- Master OFF button
local ESPOffBtn = Instance.new("TextButton")
ESPOffBtn.Size = UDim2.new(1, 0, 0, 28)
ESPOffBtn.Position = UDim2.new(0, 0, 0, 820)
ESPOffBtn.BackgroundColor3 = Colors.bloodDark
ESPOffBtn.Text = "🔴 DISABLE ALL ESP"
ESPOffBtn.TextColor3 = Colors.text
ESPOffBtn.TextSize = 11
ESPOffBtn.Font = Enum.Font.GothamBold
ESPOffBtn.AutoButtonColor = false
ESPOffBtn.Parent = ESPScroll
Instance.new("UICorner", ESPOffBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ESPOffBtn)
makeHoverable(ESPOffBtn, Colors.bloodDark, Colors.blood)


--[[ ═══════ MODULE: 07_tab_player.luau ═══════ ]]

--==================================================
-- TAB: PLAYERS
--==================================================

local PlayerContent = Instance.new("Frame")
PlayerContent.Name = "PlayerContent"
PlayerContent.Size = UDim2.new(1, 0, 1, 0)
PlayerContent.BackgroundTransparency = 1
PlayerContent.Visible = false
PlayerContent.Parent = TabContent
tabContents["player"] = PlayerContent

createSectionHeader(PlayerContent, "Online Players", 0)

-- Search bar
PlayerSearchBox = Instance.new("TextBox")
PlayerSearchBox.Size = UDim2.new(1, -8, 0, 22)
PlayerSearchBox.Position = UDim2.new(0, 4, 0, 24)
PlayerSearchBox.BackgroundColor3 = Colors.content
PlayerSearchBox.Text = ""
PlayerSearchBox.PlaceholderText = "Search players..."
PlayerSearchBox.PlaceholderColor3 = Colors.textDim
PlayerSearchBox.TextColor3 = Colors.text
PlayerSearchBox.TextSize = 10
PlayerSearchBox.Font = Enum.Font.Code
PlayerSearchBox.TextXAlignment = Enum.TextXAlignment.Left
PlayerSearchBox.ClearTextOnFocus = false
PlayerSearchBox.Parent = PlayerContent
Instance.new("UICorner", PlayerSearchBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", PlayerSearchBox).PaddingLeft = UDim.new(0, 6)
local psStroke = Instance.new("UIStroke", PlayerSearchBox)
psStroke.Color = Colors.separator
psStroke.Thickness = 0.5

-- Player list scroll
local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Name = "PlayerScroll"
PlayerScroll.Size = UDim2.new(1, 0, 1, -126)
PlayerScroll.Position = UDim2.new(0, 0, 0, 50)
PlayerScroll.BackgroundColor3 = Colors.content
PlayerScroll.BorderSizePixel = 0
PlayerScroll.ScrollBarThickness = 4
PlayerScroll.ScrollBarImageColor3 = Colors.blood
PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScroll.Parent = PlayerContent
Instance.new("UICorner", PlayerScroll).CornerRadius = UDim.new(0, 6)
local playerStroke = Instance.new("UIStroke", PlayerScroll)
playerStroke.Color = Colors.separator
playerStroke.Thickness = 0.5
playerStroke.Transparency = 0.5

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.Padding = UDim.new(0, 4)
PlayerLayout.Parent = PlayerScroll
local playerPad = Instance.new("UIPadding", PlayerScroll)
playerPad.PaddingTop = UDim.new(0, 4)
playerPad.PaddingLeft = UDim.new(0, 4)
playerPad.PaddingRight = UDim.new(0, 4)

-- Unspectate button (hidden by default)
local PlayerUnspectateBtn = Instance.new("TextButton")
PlayerUnspectateBtn.Size = UDim2.new(1, 0, 0, 26)
PlayerUnspectateBtn.Position = UDim2.new(0, 0, 1, -98)
PlayerUnspectateBtn.BackgroundColor3 = Colors.blood
PlayerUnspectateBtn.Text = "🦇 UNSPECTATE"
PlayerUnspectateBtn.TextColor3 = Colors.text
PlayerUnspectateBtn.TextSize = 11
PlayerUnspectateBtn.Font = Enum.Font.GothamBold
PlayerUnspectateBtn.AutoButtonColor = false
PlayerUnspectateBtn.Visible = false
PlayerUnspectateBtn.Parent = PlayerContent
Instance.new("UICorner", PlayerUnspectateBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(PlayerUnspectateBtn)
makeHoverable(PlayerUnspectateBtn, Colors.blood, Colors.glowRed)

-- Refresh button
local RefreshPlayersBtn = Instance.new("TextButton")
RefreshPlayersBtn.Size = UDim2.new(1, 0, 0, 26)
RefreshPlayersBtn.Position = UDim2.new(0, 0, 1, -70)
RefreshPlayersBtn.BackgroundColor3 = Colors.blood
RefreshPlayersBtn.Text = "🔄 REFRESH PLAYERS"
RefreshPlayersBtn.TextColor3 = Colors.text
RefreshPlayersBtn.TextSize = 11
RefreshPlayersBtn.Font = Enum.Font.GothamBold
RefreshPlayersBtn.AutoButtonColor = false
RefreshPlayersBtn.Parent = PlayerContent
Instance.new("UICorner", RefreshPlayersBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RefreshPlayersBtn)
makeHoverable(RefreshPlayersBtn, Colors.blood, Colors.glowRed)

--==================================================
-- SERVER INFO
--==================================================

createSectionHeader(PlayerContent, "Server Info", -42)
-- Reposition relative to bottom
local ServerInfo = Instance.new("Frame")
ServerInfo.Size = UDim2.new(1, 0, 0, 38)
ServerInfo.Position = UDim2.new(0, 0, 1, -38)
ServerInfo.BackgroundColor3 = Colors.card
ServerInfo.BorderSizePixel = 0
ServerInfo.Parent = PlayerContent
Instance.new("UICorner", ServerInfo).CornerRadius = UDim.new(0, 6)
addGradient(ServerInfo, Colors.surfaceLight, Colors.card, 0)

local ServerInfoLabel = Instance.new("TextLabel")
ServerInfoLabel.Name = "ServerInfoLabel"
ServerInfoLabel.Size = UDim2.new(1, -10, 1, 0)
ServerInfoLabel.Position = UDim2.new(0, 5, 0, 0)
ServerInfoLabel.BackgroundTransparency = 1
ServerInfoLabel.Text = "Loading server info..."
ServerInfoLabel.TextColor3 = Colors.textDim
ServerInfoLabel.TextSize = 9
ServerInfoLabel.Font = Enum.Font.Code
ServerInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerInfoLabel.TextWrapped = true
ServerInfoLabel.Parent = ServerInfo


--[[ ═══════ MODULE: 08_tab_movement.luau ═══════ ]]

--==================================================
-- TAB: MOVEMENT
--==================================================

local MovementContent = Instance.new("Frame")
MovementContent.Name = "MovementContent"
MovementContent.Size = UDim2.new(1, 0, 1, 0)
MovementContent.BackgroundTransparency = 1
MovementContent.Visible = false
MovementContent.Parent = TabContent
tabContents["movement"] = MovementContent

-- Scroll container
local MoveScroll = Instance.new("ScrollingFrame")
MoveScroll.Size = UDim2.new(1, 0, 1, 0)
MoveScroll.BackgroundTransparency = 1
MoveScroll.ScrollBarThickness = 3
MoveScroll.ScrollBarImageColor3 = Colors.blood
MoveScroll.CanvasSize = UDim2.new(0, 0, 0, 740)
MoveScroll.BorderSizePixel = 0
MoveScroll.Parent = MovementContent

createSectionHeader(MoveScroll, "Movement", 0)

local moveToggles = {}

moveToggles.fly = createVampToggle(MoveScroll, "Fly (WASD+Space/Shift)", "fly", movementState, 26, Colors.glowPurple)
moveToggles.noclip = createVampToggle(MoveScroll, "Noclip (Walk Through)", "noclip", movementState, 56, Colors.warning)
moveToggles.infiniteJump = createVampToggle(MoveScroll, "Infinite Jump", "infiniteJump", movementState, 86, Colors.green)

createSectionHeader(MoveScroll, "Speed", 120)

local speedSlider = createSliderRow(MoveScroll, "Walk Speed", 1, 500, 16, 146, function(val)
    movementState.speed = val
    if applySpeed then applySpeed() end
end)

local jumpSlider = createSliderRow(MoveScroll, "Jump Power", 0, 300, 50, 178, function(val)
    movementState.jumpPower = val
    if applySpeed then applySpeed() end
end)

createSectionHeader(MoveScroll, "Camera", 214)

moveToggles.freecam = createVampToggle(MoveScroll, "Freecam (Detach Camera)", "freecam", movementState, 240, Colors.bloodLight)

createSectionHeader(MoveScroll, "Extras", 274)

moveToggles.clickTP = createVampToggle(MoveScroll, "ClickTP (Teleport to Click)", "clickTP", movementState, 298, Colors.glowPurple)
moveToggles.antiVoid = createVampToggle(MoveScroll, "AntiVoid (Prevent Falling)", "antiVoid", movementState, 328, Colors.green)
moveToggles.spin = createVampToggle(MoveScroll, "Spin (Rotate Character)", "spin", movementState, 358, Colors.warning)

spinSpeedSlider = createSliderRow(MoveScroll, "Spin Speed", 1, 50, 10, 388, function(val)
    movementState.spinSpeed = val
end)

createSectionHeader(MoveScroll, "Flashback", 426)

FlashbackSaveBtn = Instance.new("TextButton")
FlashbackSaveBtn.Size = UDim2.new(0.5, -3, 0, 28)
FlashbackSaveBtn.Position = UDim2.new(0, 0, 0, 450)
FlashbackSaveBtn.BackgroundColor3 = Colors.green
FlashbackSaveBtn.Text = "💾 SAVE POS"
FlashbackSaveBtn.TextColor3 = Colors.text
FlashbackSaveBtn.TextSize = 11
FlashbackSaveBtn.Font = Enum.Font.GothamBold
FlashbackSaveBtn.AutoButtonColor = false
FlashbackSaveBtn.Parent = MoveScroll
Instance.new("UICorner", FlashbackSaveBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(FlashbackSaveBtn)
makeHoverable(FlashbackSaveBtn, Colors.green, Colors.glowPurple)

FlashbackRecallBtn = Instance.new("TextButton")
FlashbackRecallBtn.Size = UDim2.new(0.5, -3, 0, 28)
FlashbackRecallBtn.Position = UDim2.new(0.5, 3, 0, 450)
FlashbackRecallBtn.BackgroundColor3 = Colors.glowPurple
FlashbackRecallBtn.Text = "⚡ RECALL"
FlashbackRecallBtn.TextColor3 = Colors.text
FlashbackRecallBtn.TextSize = 11
FlashbackRecallBtn.Font = Enum.Font.GothamBold
FlashbackRecallBtn.AutoButtonColor = false
FlashbackRecallBtn.Parent = MoveScroll
Instance.new("UICorner", FlashbackRecallBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(FlashbackRecallBtn)
makeHoverable(FlashbackRecallBtn, Colors.glowPurple, Colors.blood)

FeFlipBtn = Instance.new("TextButton")
FeFlipBtn.Size = UDim2.new(1, 0, 0, 28)
FeFlipBtn.Position = UDim2.new(0, 0, 0, 484)
FeFlipBtn.BackgroundColor3 = Colors.bloodLight
FeFlipBtn.Text = "🦇 feFlip"
FeFlipBtn.TextColor3 = Colors.text
FeFlipBtn.TextSize = 11
FeFlipBtn.Font = Enum.Font.GothamBold
FeFlipBtn.AutoButtonColor = false
FeFlipBtn.Parent = MoveScroll
Instance.new("UICorner", FeFlipBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(FeFlipBtn)
makeHoverable(FeFlipBtn, Colors.bloodLight, Colors.blood)

-- Reset button
ResetMoveBtn = Instance.new("TextButton")
ResetMoveBtn.Size = UDim2.new(1, 0, 0, 28)
ResetMoveBtn.Position = UDim2.new(0, 0, 0, 524)
ResetMoveBtn.BackgroundColor3 = Colors.bloodDark
ResetMoveBtn.Text = "🔴 RESET ALL"
ResetMoveBtn.TextColor3 = Colors.text
ResetMoveBtn.TextSize = 11
ResetMoveBtn.Font = Enum.Font.GothamBold
ResetMoveBtn.AutoButtonColor = false
ResetMoveBtn.Parent = MoveScroll
Instance.new("UICorner", ResetMoveBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ResetMoveBtn)
makeHoverable(ResetMoveBtn, Colors.bloodDark, Colors.blood)

-- ════════════════════════════════════════════════
-- Seção: Escala do Personagem
-- ════════════════════════════════════════════════

createSectionHeader(MoveScroll, "Character Scale", 570)

CharHeightSlider = createSliderRow(MoveScroll, "Height", 0.5, 5.0, 1.0, 596, function(v)
    applyCharacterScale(v, CharWidthSlider.getValue and CharWidthSlider.getValue() or 1.0, CharHeadSlider.getValue and CharHeadSlider.getValue() or 1.0)
end)
CharWidthSlider = createSliderRow(MoveScroll, "Width", 0.5, 5.0, 1.0, 628, function(v)
    applyCharacterScale(CharHeightSlider.getValue and CharHeightSlider.getValue() or 1.0, v, CharHeadSlider.getValue and CharHeadSlider.getValue() or 1.0)
end)
CharHeadSlider = createSliderRow(MoveScroll, "Head Size", 0.5, 3.0, 1.0, 660, function(v)
    applyCharacterScale(CharHeightSlider.getValue and CharHeightSlider.getValue() or 1.0, CharWidthSlider.getValue and CharWidthSlider.getValue() or 1.0, v)
end)

CharScaleResetBtn = Instance.new("TextButton")
CharScaleResetBtn.Size = UDim2.new(1, -8, 0, 28)
CharScaleResetBtn.Position = UDim2.new(0, 4, 0, 694)
CharScaleResetBtn.BackgroundColor3 = Colors.warning
CharScaleResetBtn.Text = "↺ RESET SCALE"
CharScaleResetBtn.TextColor3 = Colors.text
CharScaleResetBtn.TextSize = 11
CharScaleResetBtn.Font = Enum.Font.GothamBold
CharScaleResetBtn.AutoButtonColor = false
CharScaleResetBtn.Parent = MoveScroll
Instance.new("UICorner", CharScaleResetBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(CharScaleResetBtn)
makeHoverable(CharScaleResetBtn, Colors.warning, Color3.fromRGB(255, 200, 80))


--[[ ═══════ MODULE: 09_tab_emote.luau ═══════ ]]

--==================================================
-- TAB: EMOTE (Favorites + Playback + Sync Players + Catalog Search)
--==================================================

EmoteContent = Instance.new("Frame")
EmoteContent.Name = "EmoteContent"
EmoteContent.Size = UDim2.new(1, 0, 1, 0)
EmoteContent.BackgroundTransparency = 1
EmoteContent.Visible = false
EmoteContent.Parent = TabContent
tabContents["emote"] = EmoteContent

EmoteScroll = Instance.new("ScrollingFrame")
EmoteScroll.Size = UDim2.new(1, 0, 1, 0)
EmoteScroll.BackgroundTransparency = 1
EmoteScroll.ScrollBarThickness = 3
EmoteScroll.ScrollBarImageColor3 = Colors.blood
EmoteScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
EmoteScroll.BorderSizePixel = 0
EmoteScroll.Parent = EmoteContent

--==================================================
-- FAVORITES SECTION
--==================================================

createSectionHeader(EmoteScroll, "Favorites", 0)

favSectionY = 24

-- Favorites grid container (global for cross-module access)
EmoteFavGrid = Instance.new("Frame")
EmoteFavGrid.Name = "FavGrid"
EmoteFavGrid.Size = UDim2.new(1, 0, 0, 0)
EmoteFavGrid.Position = UDim2.new(0, 0, 0, favSectionY)
EmoteFavGrid.BackgroundTransparency = 1
EmoteFavGrid.ClipsDescendants = true
EmoteFavGrid.Parent = EmoteScroll

EmoteFavGridLayout = Instance.new("UIGridLayout", EmoteFavGrid)
EmoteFavGridLayout.CellSize = UDim2.new(0, 60, 0, 82)
EmoteFavGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
EmoteFavGridLayout.FillDirection = Enum.FillDirection.Horizontal
EmoteFavGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Empty favorites label
EmoteFavEmpty = Instance.new("TextLabel")
EmoteFavEmpty.Size = UDim2.new(1, 0, 0, 24)
EmoteFavEmpty.Position = UDim2.new(0, 0, 0, favSectionY)
EmoteFavEmpty.BackgroundTransparency = 1
EmoteFavEmpty.Text = "No favorites yet — star emotes from catalog"
EmoteFavEmpty.TextColor3 = Colors.textDim
EmoteFavEmpty.TextSize = 9
EmoteFavEmpty.Font = Enum.Font.Gotham
EmoteFavEmpty.Visible = true
EmoteFavEmpty.Parent = EmoteScroll

--==================================================
-- PLAYBACK CONTROLS
-- (Y positions set by recalcEmoteLayout)
--==================================================

-- Pause/Resume button (left half)
PauseEmoteBtn = Instance.new("TextButton")
PauseEmoteBtn.Size = UDim2.new(0.5, -2, 0, 26)
PauseEmoteBtn.BackgroundColor3 = Colors.warning
PauseEmoteBtn.Text = "⏸ PAUSE"
PauseEmoteBtn.TextColor3 = Colors.text
PauseEmoteBtn.TextSize = 10
PauseEmoteBtn.Font = Enum.Font.GothamBold
PauseEmoteBtn.AutoButtonColor = false
PauseEmoteBtn.Parent = EmoteScroll
Instance.new("UICorner", PauseEmoteBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(PauseEmoteBtn, Colors.warning, Color3.fromRGB(230, 180, 60))

-- Stop emote button (right half)
StopEmoteBtn = Instance.new("TextButton")
StopEmoteBtn.Size = UDim2.new(0.5, -2, 0, 26)
StopEmoteBtn.BackgroundColor3 = Colors.bloodDark
StopEmoteBtn.Text = "⏹ STOP"
StopEmoteBtn.TextColor3 = Colors.text
StopEmoteBtn.TextSize = 10
StopEmoteBtn.Font = Enum.Font.GothamBold
StopEmoteBtn.AutoButtonColor = false
StopEmoteBtn.Parent = EmoteScroll
Instance.new("UICorner", StopEmoteBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(StopEmoteBtn, Colors.bloodDark, Colors.blood)

-- Speed slider (0.2x — 5.0x) usando range 2-50 ÷10
EmoteSpeedSlider = createSliderRow(EmoteScroll, "Speed", 2, 50, 10, 0, function(val)
    emoteSpeed = val / 10
    if currentEmoteTrack and not emotePaused then
        pcall(function()
            currentEmoteTrack:AdjustSpeed(emoteSpeed)
        end)
        -- Sync speed to other players
        if syncAdjustSpeed then
            syncAdjustSpeed(emotePaused and 0 or emoteSpeed)
        end
    end
end)
-- Override o label pra mostrar "1.0x" ao invés de "10"
do
    local origSetValue = EmoteSpeedSlider.setValue
    EmoteSpeedSlider.setValue = function(v)
        origSetValue(v)
        -- Atualiza label com formato "X.Xx"
        local valLabel = EmoteSpeedSlider.row:FindFirstChildWhichIsA("TextLabel")
        for _, child in ipairs(EmoteSpeedSlider.row:GetChildren()) do
            if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Right then
                child.Text = string.format("%.1fx", v / 10)
                break
            end
        end
    end
    EmoteSpeedSlider.setValue(10) -- inicializa com "1.0x"
end

--==================================================
-- SYNC PLAYERS SECTION
--==================================================

-- Header clicavel (toggle collapse)
SyncPlayersExpanded = false
SyncPlayersHeader = Instance.new("TextButton")
SyncPlayersHeader.Name = "SyncPlayersHeader"
SyncPlayersHeader.Size = UDim2.new(1, 0, 0, 22)
SyncPlayersHeader.BackgroundTransparency = 1
SyncPlayersHeader.Text = "▸ Sync Players (0 synced)"
SyncPlayersHeader.TextColor3 = Colors.text
SyncPlayersHeader.TextSize = 10
SyncPlayersHeader.Font = Enum.Font.GothamBold
SyncPlayersHeader.TextXAlignment = Enum.TextXAlignment.Left
SyncPlayersHeader.AutoButtonColor = false
SyncPlayersHeader.Parent = EmoteScroll
addAccentLine(SyncPlayersHeader)

-- Container que esconde/mostra todo conteudo do sync
SyncPlayersBody = Instance.new("Frame")
SyncPlayersBody.Name = "SyncPlayersBody"
SyncPlayersBody.Size = UDim2.new(1, 0, 0, 0)
SyncPlayersBody.BackgroundTransparency = 1
SyncPlayersBody.ClipsDescendants = true
SyncPlayersBody.Visible = false
SyncPlayersBody.Parent = EmoteScroll

-- Search + Refresh row
SyncSearchBox = Instance.new("TextBox")
SyncSearchBox.Size = UDim2.new(1, -68, 0, 24)
SyncSearchBox.Position = UDim2.new(0, 0, 0, 0)
SyncSearchBox.BackgroundColor3 = Colors.inputBg
SyncSearchBox.Text = ""
SyncSearchBox.PlaceholderText = "🔍 Search players..."
SyncSearchBox.PlaceholderColor3 = Colors.textDim
SyncSearchBox.TextColor3 = Colors.text
SyncSearchBox.TextSize = 10
SyncSearchBox.Font = Enum.Font.Code
SyncSearchBox.ClearTextOnFocus = false
SyncSearchBox.Parent = SyncPlayersBody
Instance.new("UICorner", SyncSearchBox).CornerRadius = UDim.new(0, 6)
do
    local syncSearchStroke = Instance.new("UIStroke", SyncSearchBox)
    syncSearchStroke.Color = Colors.inputBorder
    syncSearchStroke.Thickness = 1
    SyncSearchBox.Focused:Connect(function()
        TweenService:Create(syncSearchStroke, TweenInfo.new(0.2), { Color = Colors.purpleLight, Thickness = 1.5 }):Play()
    end)
    SyncSearchBox.FocusLost:Connect(function()
        TweenService:Create(syncSearchStroke, TweenInfo.new(0.3), { Color = Colors.inputBorder, Thickness = 1 }):Play()
    end)
end

SyncRefreshBtn = Instance.new("TextButton")
SyncRefreshBtn.Size = UDim2.new(0, 62, 0, 24)
SyncRefreshBtn.Position = UDim2.new(1, -62, 0, 0)
SyncRefreshBtn.BackgroundColor3 = Colors.purple
SyncRefreshBtn.Text = "⟳ Refresh"
SyncRefreshBtn.TextColor3 = Colors.text
SyncRefreshBtn.TextSize = 10
SyncRefreshBtn.Font = Enum.Font.GothamBold
SyncRefreshBtn.AutoButtonColor = false
SyncRefreshBtn.Parent = SyncPlayersBody
Instance.new("UICorner", SyncRefreshBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(SyncRefreshBtn, Colors.purple, Colors.purpleLight)

-- Select All / Deselect All
SyncSelectAllBtn = Instance.new("TextButton")
SyncSelectAllBtn.Size = UDim2.new(0.5, -2, 0, 22)
SyncSelectAllBtn.Position = UDim2.new(0, 0, 0, 28)
SyncSelectAllBtn.BackgroundColor3 = Colors.green
SyncSelectAllBtn.Text = "✓ Select All"
SyncSelectAllBtn.TextColor3 = Colors.text
SyncSelectAllBtn.TextSize = 9
SyncSelectAllBtn.Font = Enum.Font.GothamBold
SyncSelectAllBtn.AutoButtonColor = false
SyncSelectAllBtn.Parent = SyncPlayersBody
Instance.new("UICorner", SyncSelectAllBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(SyncSelectAllBtn, Colors.green, Colors.greenLight)

SyncDeselectAllBtn = Instance.new("TextButton")
SyncDeselectAllBtn.Size = UDim2.new(0.5, -2, 0, 22)
SyncDeselectAllBtn.Position = UDim2.new(0.5, 2, 0, 28)
SyncDeselectAllBtn.BackgroundColor3 = Color3.fromRGB(50, 25, 25)
SyncDeselectAllBtn.Text = "✗ Deselect All"
SyncDeselectAllBtn.TextColor3 = Colors.text
SyncDeselectAllBtn.TextSize = 9
SyncDeselectAllBtn.Font = Enum.Font.GothamBold
SyncDeselectAllBtn.AutoButtonColor = false
SyncDeselectAllBtn.Parent = SyncPlayersBody
Instance.new("UICorner", SyncDeselectAllBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(SyncDeselectAllBtn, Color3.fromRGB(50, 25, 25), Colors.bloodDark)

-- Player list container com scroll interno (max 160px)
SyncPlayerScroll = Instance.new("ScrollingFrame")
SyncPlayerScroll.Name = "SyncPlayerScroll"
SyncPlayerScroll.Size = UDim2.new(1, 0, 0, 0) -- altura atualizada dinamicamente, max 160
SyncPlayerScroll.Position = UDim2.new(0, 0, 0, 54)
SyncPlayerScroll.BackgroundTransparency = 1
SyncPlayerScroll.ScrollBarThickness = 2
SyncPlayerScroll.ScrollBarImageColor3 = Colors.blood
SyncPlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SyncPlayerScroll.BorderSizePixel = 0
SyncPlayerScroll.ClipsDescendants = true
SyncPlayerScroll.Parent = SyncPlayersBody

SyncPlayerList = Instance.new("Frame")
SyncPlayerList.Name = "SyncPlayerList"
SyncPlayerList.Size = UDim2.new(1, 0, 0, 0)
SyncPlayerList.BackgroundTransparency = 1
SyncPlayerList.Parent = SyncPlayerScroll

SyncPlayerListLayout = Instance.new("UIListLayout", SyncPlayerList)
SyncPlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
SyncPlayerListLayout.Padding = UDim.new(0, 2)

-- Sync count label (dentro do body)
SyncCountLabel = Instance.new("TextLabel")
SyncCountLabel.Size = UDim2.new(1, 0, 0, 14)
SyncCountLabel.BackgroundTransparency = 1
SyncCountLabel.Text = "0 players synced"
SyncCountLabel.TextColor3 = Colors.textDim
SyncCountLabel.TextSize = 9
SyncCountLabel.Font = Enum.Font.Gotham
SyncCountLabel.TextXAlignment = Enum.TextXAlignment.Center
SyncCountLabel.Parent = SyncPlayersBody

--==================================================
-- CATALOG SEARCH
--==================================================

EmoteCatalogHeader = createSectionHeader(EmoteScroll, "Catalog Search", 0)

-- Search input (global for event wiring in 22_events)
EmoteSearchBox = Instance.new("TextBox")
EmoteSearchBox.Size = UDim2.new(1, 0, 0, 26)
EmoteSearchBox.BackgroundColor3 = Colors.inputBg
EmoteSearchBox.Text = ""
EmoteSearchBox.PlaceholderText = "🔍 Search emotes or paste ID..."
EmoteSearchBox.PlaceholderColor3 = Colors.textDim
EmoteSearchBox.TextColor3 = Colors.text
EmoteSearchBox.TextSize = 11
EmoteSearchBox.Font = Enum.Font.Code
EmoteSearchBox.ClearTextOnFocus = false
EmoteSearchBox.Parent = EmoteScroll
Instance.new("UICorner", EmoteSearchBox).CornerRadius = UDim.new(0, 6)
do
    local emoteSearchStroke = Instance.new("UIStroke", EmoteSearchBox)
    emoteSearchStroke.Color = Colors.inputBorder
    emoteSearchStroke.Thickness = 1
    EmoteSearchBox.Focused:Connect(function()
        TweenService:Create(emoteSearchStroke, TweenInfo.new(0.2), { Color = Colors.purpleLight, Thickness = 1.5 }):Play()
    end)
    EmoteSearchBox.FocusLost:Connect(function()
        TweenService:Create(emoteSearchStroke, TweenInfo.new(0.3), { Color = Colors.inputBorder, Thickness = 1 }):Play()
    end)
end

-- Catalog grid container (global for cross-module access)
EmoteCatalogGrid = Instance.new("Frame")
EmoteCatalogGrid.Name = "CatalogGrid"
EmoteCatalogGrid.Size = UDim2.new(1, 0, 0, 300)
EmoteCatalogGrid.BackgroundTransparency = 1
EmoteCatalogGrid.ClipsDescendants = true
EmoteCatalogGrid.Parent = EmoteScroll

EmoteCatalogGridLayout = Instance.new("UIGridLayout", EmoteCatalogGrid)
EmoteCatalogGridLayout.CellSize = UDim2.new(0, 60, 0, 82)
EmoteCatalogGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
EmoteCatalogGridLayout.FillDirection = Enum.FillDirection.Horizontal
EmoteCatalogGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Empty/status label
EmoteCatalogEmpty = Instance.new("TextLabel")
EmoteCatalogEmpty.Size = UDim2.new(1, 0, 0, 30)
EmoteCatalogEmpty.BackgroundTransparency = 1
EmoteCatalogEmpty.Text = "Loading popular emotes..."
EmoteCatalogEmpty.TextColor3 = Colors.textDim
EmoteCatalogEmpty.TextSize = 10
EmoteCatalogEmpty.Font = Enum.Font.Gotham
EmoteCatalogEmpty.Visible = true
EmoteCatalogEmpty.Parent = EmoteScroll

--==================================================
-- LAYOUT FUNCTION (global — repositions everything based on favorites grid height)
--==================================================

recalcEmoteLayout = function()
    local favHeight = EmoteFavGrid.Size.Y.Offset
    if favHeight < 10 then favHeight = 24 end

    local baseY = favSectionY + favHeight + 8

    -- Playback controls (Pause/Stop/Speed)
    PauseEmoteBtn.Position = UDim2.new(0, 0, 0, baseY)
    StopEmoteBtn.Position = UDim2.new(0.5, 2, 0, baseY)
    EmoteSpeedSlider.row.Position = UDim2.new(0, 10, 0, baseY + 32)

    -- Sync Players section (colapsavel)
    local syncY = baseY + 70
    SyncPlayersHeader.Position = UDim2.new(0, 0, 0, syncY)

    local syncBodyHeight = 0
    if SyncPlayersExpanded then
        -- Calcula altura do scroll de players (max 160px)
        local listContentHeight = SyncPlayerList.Size.Y.Offset
        local scrollHeight = math.min(math.max(listContentHeight, 34), 160)
        SyncPlayerScroll.Size = UDim2.new(1, 0, 0, scrollHeight)
        SyncPlayerScroll.CanvasSize = UDim2.new(0, 0, 0, listContentHeight)

        -- Altura do count label
        local countY = 54 + scrollHeight + 2
        SyncCountLabel.Position = UDim2.new(0, 0, 0, countY)

        syncBodyHeight = countY + 16
        SyncPlayersBody.Size = UDim2.new(1, 0, 0, syncBodyHeight)
        SyncPlayersBody.Position = UDim2.new(0, 0, 0, syncY + 24)
        SyncPlayersBody.Visible = true
    else
        SyncPlayersBody.Visible = false
        syncBodyHeight = 0
    end

    local afterSyncY = syncY + 24 + (SyncPlayersExpanded and syncBodyHeight + 4 or 0)

    -- Catalog section
    local catalogY = afterSyncY + 4
    EmoteCatalogHeader.Position = UDim2.new(0, 0, 0, catalogY)
    EmoteSearchBox.Position = UDim2.new(0, 0, 0, catalogY + 26)
    EmoteCatalogGrid.Position = UDim2.new(0, 0, 0, catalogY + 58)
    EmoteCatalogEmpty.Position = UDim2.new(0, 0, 0, catalogY + 58)

    -- Update canvas
    EmoteScroll.CanvasSize = UDim2.new(0, 0, 0, catalogY + 58 + EmoteCatalogGrid.Size.Y.Offset + 20)
end

-- Initial layout (no favorites yet)
recalcEmoteLayout()


--[[ ═══════ MODULE: 09b_shadow_panel.luau ═══════ ]]

--==================================================
-- SHADOW PANEL — FLOATING (aberto via botao SHADOW em player cards)
-- Todas as variaveis sao GLOBALS para nao gastar locals
--==================================================

ShadowPanel = Instance.new("Frame")
ShadowPanel.Name = "ShadowPanel"
ShadowPanel.Size = UDim2.new(0, 240, 0, 540)
ShadowPanel.Position = UDim2.new(0.5, -120, 0.5, -270)
ShadowPanel.BackgroundColor3 = Colors.bg
ShadowPanel.BorderSizePixel = 0
ShadowPanel.Visible = false
ShadowPanel.Parent = ScreenGui

Instance.new("UICorner", ShadowPanel).CornerRadius = UDim.new(0, 10)
ShadowPanelStroke = Instance.new("UIStroke", ShadowPanel)
ShadowPanelStroke.Color = Colors.glowPurple
ShadowPanelStroke.Thickness = 1.5
addGradient(ShadowPanel, Colors.surfaceLight, Color3.fromRGB(8, 8, 10), 90)

--==================================================
-- TOP BAR
--==================================================

ShadowPanelTopBar = Instance.new("Frame")
ShadowPanelTopBar.Size = UDim2.new(1, 0, 0, 32)
ShadowPanelTopBar.BackgroundColor3 = Colors.topbar
ShadowPanelTopBar.BorderSizePixel = 0
ShadowPanelTopBar.Parent = ShadowPanel
Instance.new("UICorner", ShadowPanelTopBar).CornerRadius = UDim.new(0, 10)
addGradient(ShadowPanelTopBar, Color3.fromRGB(30, 10, 40), Colors.topbar, 0)

-- Fix bottom corners
ShadowPanelTopBarFix = Instance.new("Frame")
ShadowPanelTopBarFix.Size = UDim2.new(1, 0, 0, 10)
ShadowPanelTopBarFix.Position = UDim2.new(0, 0, 1, -10)
ShadowPanelTopBarFix.BackgroundColor3 = Colors.topbar
ShadowPanelTopBarFix.BorderSizePixel = 0
ShadowPanelTopBarFix.Parent = ShadowPanelTopBar

addAccentLine(ShadowPanelTopBar, UDim2.new(0, 0, 1, -1), Colors.glowPurple)

ShadowPanelTitle = Instance.new("TextLabel")
ShadowPanelTitle.Size = UDim2.new(1, -40, 1, 0)
ShadowPanelTitle.Position = UDim2.new(0, 10, 0, 0)
ShadowPanelTitle.BackgroundTransparency = 1
ShadowPanelTitle.Text = "👤 Shadow Mode"
ShadowPanelTitle.TextColor3 = Colors.purpleLight
ShadowPanelTitle.TextSize = 12
ShadowPanelTitle.Font = Enum.Font.GothamBold
ShadowPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
ShadowPanelTitle.Parent = ShadowPanelTopBar

ShadowPanelClose = Instance.new("TextButton")
ShadowPanelClose.Size = UDim2.new(0, 20, 0, 20)
ShadowPanelClose.Position = UDim2.new(1, -26, 0, 6)
ShadowPanelClose.BackgroundColor3 = Colors.blood
ShadowPanelClose.Text = "X"
ShadowPanelClose.TextColor3 = Colors.text
ShadowPanelClose.TextSize = 11
ShadowPanelClose.Font = Enum.Font.GothamBold
ShadowPanelClose.AutoButtonColor = false
ShadowPanelClose.Parent = ShadowPanelTopBar
Instance.new("UICorner", ShadowPanelClose).CornerRadius = UDim.new(0, 6)
makeHoverable(ShadowPanelClose, Colors.blood, Colors.glowRed)

--==================================================
-- PLAYER INFO
--==================================================

-- Player photo (large, circular)
ShadowPanelThumbFrame = Instance.new("Frame")
ShadowPanelThumbFrame.Size = UDim2.new(0, 64, 0, 64)
ShadowPanelThumbFrame.Position = UDim2.new(0.5, -32, 0, 40)
ShadowPanelThumbFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ShadowPanelThumbFrame.Parent = ShadowPanel
Instance.new("UICorner", ShadowPanelThumbFrame).CornerRadius = UDim.new(1, 0)
ShadowPanelThumbStroke = Instance.new("UIStroke", ShadowPanelThumbFrame)
ShadowPanelThumbStroke.Color = Colors.glowPurple
ShadowPanelThumbStroke.Thickness = 2

ShadowPanelThumb = Instance.new("ImageLabel")
ShadowPanelThumb.Size = UDim2.new(1, 0, 1, 0)
ShadowPanelThumb.BackgroundTransparency = 1
ShadowPanelThumb.Parent = ShadowPanelThumbFrame
Instance.new("UICorner", ShadowPanelThumb).CornerRadius = UDim.new(1, 0)

-- Player name
ShadowPanelPlayerName = Instance.new("TextLabel")
ShadowPanelPlayerName.Size = UDim2.new(1, 0, 0, 18)
ShadowPanelPlayerName.Position = UDim2.new(0, 0, 0, 110)
ShadowPanelPlayerName.BackgroundTransparency = 1
ShadowPanelPlayerName.Text = "Select a player"
ShadowPanelPlayerName.TextColor3 = Colors.purpleLight
ShadowPanelPlayerName.TextSize = 13
ShadowPanelPlayerName.Font = Enum.Font.GothamBold
ShadowPanelPlayerName.Parent = ShadowPanel

-- Target status label (same name as before — used by 21_emote_shadow)
ShadowTargetLabel = Instance.new("TextLabel")
ShadowTargetLabel.Size = UDim2.new(1, -20, 0, 14)
ShadowTargetLabel.Position = UDim2.new(0, 10, 0, 130)
ShadowTargetLabel.BackgroundTransparency = 1
ShadowTargetLabel.Text = "Target: none"
ShadowTargetLabel.TextColor3 = Colors.textDim
ShadowTargetLabel.TextSize = 10
ShadowTargetLabel.Font = Enum.Font.GothamBold
ShadowTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
ShadowTargetLabel.Parent = ShadowPanel

--==================================================
-- QUICK PRESETS (row of 5 buttons)
--==================================================

shadowPresetButtons = {}
shadowPresetDefs = {
    { name = "Behind", angle = 0,   height = 0, faceTarget = false, mode = "orbit" },
    { name = "Front",  angle = 180, height = 0, faceTarget = true,  mode = "orbit" },
    { name = "Left",   angle = 270, height = 0, faceTarget = false, mode = "orbit" },
    { name = "Right",  angle = 90,  height = 0, faceTarget = false, mode = "orbit" },
    { name = "Head",   angle = 0,   height = 0, faceTarget = false, mode = "head" },
}

do
    local btnWidth = 42
    local gap = 2
    local startX = 10
    for i, def in ipairs(shadowPresetDefs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, btnWidth, 0, 24)
        btn.Position = UDim2.new(0, startX + (i - 1) * (btnWidth + gap), 0, 152)
        btn.BackgroundColor3 = Color3.fromRGB(40, 20, 40)
        btn.Text = def.name
        btn.TextColor3 = Colors.textDim
        btn.TextSize = 9
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.Parent = ShadowPanel
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        makeHoverable(btn, Color3.fromRGB(40, 20, 40), Colors.glowPurple)
        shadowPresetButtons[i] = { btn = btn, def = def }
    end
end

--==================================================
-- REFRESH PRESET HIGHLIGHT
--==================================================

refreshShadowModeButtons = function()
    for _, data in ipairs(shadowPresetButtons) do
        local def = data.def
        local isActive = shadowState.active and shadowState.mode == def.mode
        if def.mode == "orbit" and isActive then
            isActive = (shadowState.angle == def.angle and shadowState.faceTarget == def.faceTarget)
        end
        data.btn.BackgroundColor3 = isActive and Colors.glowPurple or Color3.fromRGB(40, 20, 40)
        data.btn.TextColor3 = isActive and Colors.text or Colors.textDim
    end
end

--==================================================
-- SLIDERS
--==================================================

-- Angle slider (0-360)
ShadowPanelAngleSlider = createSliderRow(ShadowPanel, "Angle (0-360)", 0, 360, 0, 182, function(val)
    shadowState.angle = val
end)

-- Height slider (-5 to 10)
ShadowPanelHeightSlider = createSliderRow(ShadowPanel, "Height (studs)", -5, 10, 0, 216, function(val)
    shadowState.height = val
end)

-- Distance slider (1-15)
ShadowPanelDistSlider = createSliderRow(ShadowPanel, "Distance (studs)", 1, 15, 4, 250, function(val)
    shadowState.distance = val
end)

-- Delay slider (0-5)
ShadowPanelDelaySlider = createSliderRow(ShadowPanel, "Delay (sec)", 0, 5, 0, 284, function(val)
    shadowState.delay = val
end)

--==================================================
-- FACE TARGET TOGGLE
--==================================================

ShadowFaceTargetToggle = createVampToggle(
    ShadowPanel, "Face Target", "faceTarget", shadowState, 318, Colors.glowPurple
)

--==================================================
-- MIRROR ANIMS TOGGLE
--==================================================

ShadowMirrorAnimsToggle = createVampToggle(
    ShadowPanel, "Mirror Anims", "mirrorAnims", shadowState, 346, Colors.glowPurple
)

--==================================================
-- AUTO-ORBIT TOGGLE + SPEED SLIDER
--==================================================

ShadowAutoOrbitToggle = createVampToggle(
    ShadowPanel, "Auto-Orbit", "autoOrbit", shadowState, 374, Colors.glowPurple
)

ShadowOrbitSpeedSlider = createSliderRow(ShadowPanel, "Orbit Speed", 1, 10, 2, 404, function(val)
    shadowState.orbitSpeed = val
end)

--==================================================
-- SHADOW TRAIL TOGGLE
--==================================================

ShadowTrailToggle = createVampToggle(
    ShadowPanel, "Trail Effect", "trail", shadowState, 438, Colors.blood
)

--==================================================
-- RECORD & REPLAY BUTTONS (row of 2)
--==================================================

ShadowRecBtn = Instance.new("TextButton")
ShadowRecBtn.Size = UDim2.new(0.5, -12, 0, 24)
ShadowRecBtn.Position = UDim2.new(0, 10, 0, 470)
ShadowRecBtn.BackgroundColor3 = Colors.blood
ShadowRecBtn.Text = "⏺ REC"
ShadowRecBtn.TextColor3 = Colors.text
ShadowRecBtn.TextSize = 10
ShadowRecBtn.Font = Enum.Font.GothamBold
ShadowRecBtn.AutoButtonColor = false
ShadowRecBtn.Parent = ShadowPanel
Instance.new("UICorner", ShadowRecBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(ShadowRecBtn, Colors.blood, Colors.glowRed)

ShadowPlayReplayBtn = Instance.new("TextButton")
ShadowPlayReplayBtn.Size = UDim2.new(0.5, -12, 0, 24)
ShadowPlayReplayBtn.Position = UDim2.new(0.5, 2, 0, 470)
ShadowPlayReplayBtn.BackgroundColor3 = Colors.green
ShadowPlayReplayBtn.Text = "▶ REPLAY"
ShadowPlayReplayBtn.TextColor3 = Colors.text
ShadowPlayReplayBtn.TextSize = 10
ShadowPlayReplayBtn.Font = Enum.Font.GothamBold
ShadowPlayReplayBtn.AutoButtonColor = false
ShadowPlayReplayBtn.Parent = ShadowPanel
Instance.new("UICorner", ShadowPlayReplayBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(ShadowPlayReplayBtn, Colors.green, Colors.greenLight)

--==================================================
-- RESET + STOP BUTTONS (row of 2)
--==================================================

ShadowResetBtn = Instance.new("TextButton")
ShadowResetBtn.Size = UDim2.new(0.5, -12, 0, 24)
ShadowResetBtn.Position = UDim2.new(0, 10, 0, 500)
ShadowResetBtn.BackgroundColor3 = Colors.warning
ShadowResetBtn.Text = "↺ RESET"
ShadowResetBtn.TextColor3 = Colors.bg
ShadowResetBtn.TextSize = 10
ShadowResetBtn.Font = Enum.Font.GothamBold
ShadowResetBtn.AutoButtonColor = false
ShadowResetBtn.Parent = ShadowPanel
Instance.new("UICorner", ShadowResetBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(ShadowResetBtn, Colors.warning, Color3.fromRGB(230, 180, 60))

StopShadowBtn = Instance.new("TextButton")
StopShadowBtn.Size = UDim2.new(0.5, -12, 0, 24)
StopShadowBtn.Position = UDim2.new(0.5, 2, 0, 500)
StopShadowBtn.BackgroundColor3 = Colors.bloodDark
StopShadowBtn.Text = "🔴 STOP"
StopShadowBtn.TextColor3 = Colors.text
StopShadowBtn.TextSize = 10
StopShadowBtn.Font = Enum.Font.GothamBold
StopShadowBtn.AutoButtonColor = false
StopShadowBtn.Parent = ShadowPanel
Instance.new("UICorner", StopShadowBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(StopShadowBtn, Colors.bloodDark, Colors.blood)

--==================================================
-- OPEN SHADOW PANEL
--==================================================

openShadowPanel = function(player)
    shadowState.target = player
    ShadowTargetLabel.Text = "Target: " .. player.DisplayName
    ShadowTargetLabel.TextColor3 = Colors.purpleLight
    ShadowPanelPlayerName.Text = player.DisplayName
    ShadowPanelTitle.Text = "👤 " .. player.DisplayName

    -- Load thumbnail
    task.spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
        end)
        if ok and thumb then ShadowPanelThumb.Image = thumb end
    end)

    -- Sync sliders + toggles to current state
    ShadowPanelAngleSlider.setValue(shadowState.angle)
    ShadowPanelHeightSlider.setValue(shadowState.height)
    ShadowPanelDistSlider.setValue(shadowState.distance)
    ShadowPanelDelaySlider.setValue(shadowState.delay)
    ShadowOrbitSpeedSlider.setValue(shadowState.orbitSpeed)
    ShadowFaceTargetToggle.refresh()
    ShadowMirrorAnimsToggle.refresh()
    ShadowAutoOrbitToggle.refresh()
    ShadowTrailToggle.refresh()
    refreshShadowModeButtons()
    ShadowPanel.Visible = true
    notify("Shadow target: " .. player.DisplayName, "info")
end


--[[ ═══════ MODULE: 09c_troll_panel.luau ═══════ ]]

--==================================================
-- TROLL PANEL — FLOATING (aberto via botao TROLL em player cards)
-- Todas as variaveis sao GLOBALS para nao gastar locals
--==================================================

TrollPanel = Instance.new("Frame")
TrollPanel.Name = "TrollPanel"
TrollPanel.Size = UDim2.new(0, 240, 0, 710)
TrollPanel.Position = UDim2.new(0.5, 130, 0.5, -355)
TrollPanel.BackgroundColor3 = Colors.bg
TrollPanel.BorderSizePixel = 0
TrollPanel.Visible = false
TrollPanel.Parent = ScreenGui

Instance.new("UICorner", TrollPanel).CornerRadius = UDim.new(0, 10)
TrollPanelStroke = Instance.new("UIStroke", TrollPanel)
TrollPanelStroke.Color = Colors.glowRed
TrollPanelStroke.Thickness = 1.5
addGradient(TrollPanel, Colors.surfaceLight, Color3.fromRGB(10, 6, 6), 90)

--==================================================
-- TOP BAR
--==================================================

TrollPanelTopBar = Instance.new("Frame")
TrollPanelTopBar.Size = UDim2.new(1, 0, 0, 32)
TrollPanelTopBar.BackgroundColor3 = Colors.topbar
TrollPanelTopBar.BorderSizePixel = 0
TrollPanelTopBar.Parent = TrollPanel
Instance.new("UICorner", TrollPanelTopBar).CornerRadius = UDim.new(0, 10)
addGradient(TrollPanelTopBar, Color3.fromRGB(40, 8, 8), Colors.topbar, 0)

-- Fix bottom corners
TrollPanelTopBarFix = Instance.new("Frame")
TrollPanelTopBarFix.Size = UDim2.new(1, 0, 0, 10)
TrollPanelTopBarFix.Position = UDim2.new(0, 0, 1, -10)
TrollPanelTopBarFix.BackgroundColor3 = Colors.topbar
TrollPanelTopBarFix.BorderSizePixel = 0
TrollPanelTopBarFix.Parent = TrollPanelTopBar

addAccentLine(TrollPanelTopBar, UDim2.new(0, 0, 1, -1), Colors.blood)

TrollPanelTitle = Instance.new("TextLabel")
TrollPanelTitle.Size = UDim2.new(1, -40, 1, 0)
TrollPanelTitle.Position = UDim2.new(0, 10, 0, 0)
TrollPanelTitle.BackgroundTransparency = 1
TrollPanelTitle.Text = "💥 Troll Panel"
TrollPanelTitle.TextColor3 = Colors.bloodLight
TrollPanelTitle.TextSize = 12
TrollPanelTitle.Font = Enum.Font.GothamBold
TrollPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
TrollPanelTitle.Parent = TrollPanelTopBar

TrollPanelClose = Instance.new("TextButton")
TrollPanelClose.Size = UDim2.new(0, 20, 0, 20)
TrollPanelClose.Position = UDim2.new(1, -26, 0, 6)
TrollPanelClose.BackgroundColor3 = Colors.blood
TrollPanelClose.Text = "X"
TrollPanelClose.TextColor3 = Colors.text
TrollPanelClose.TextSize = 11
TrollPanelClose.Font = Enum.Font.GothamBold
TrollPanelClose.AutoButtonColor = false
TrollPanelClose.Parent = TrollPanelTopBar
Instance.new("UICorner", TrollPanelClose).CornerRadius = UDim.new(0, 6)
makeHoverable(TrollPanelClose, Colors.blood, Colors.glowRed)

--==================================================
-- PLAYER INFO
--==================================================

-- Player photo (large, circular)
TrollPanelThumbFrame = Instance.new("Frame")
TrollPanelThumbFrame.Size = UDim2.new(0, 64, 0, 64)
TrollPanelThumbFrame.Position = UDim2.new(0.5, -32, 0, 40)
TrollPanelThumbFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TrollPanelThumbFrame.Parent = TrollPanel
Instance.new("UICorner", TrollPanelThumbFrame).CornerRadius = UDim.new(1, 0)
TrollPanelThumbStroke = Instance.new("UIStroke", TrollPanelThumbFrame)
TrollPanelThumbStroke.Color = Colors.blood
TrollPanelThumbStroke.Thickness = 2

TrollPanelThumb = Instance.new("ImageLabel")
TrollPanelThumb.Size = UDim2.new(1, 0, 1, 0)
TrollPanelThumb.BackgroundTransparency = 1
TrollPanelThumb.Parent = TrollPanelThumbFrame
Instance.new("UICorner", TrollPanelThumb).CornerRadius = UDim.new(1, 0)

-- Player name
TrollPanelPlayerName = Instance.new("TextLabel")
TrollPanelPlayerName.Size = UDim2.new(1, 0, 0, 18)
TrollPanelPlayerName.Position = UDim2.new(0, 0, 0, 110)
TrollPanelPlayerName.BackgroundTransparency = 1
TrollPanelPlayerName.Text = "Select a player"
TrollPanelPlayerName.TextColor3 = Colors.bloodLight
TrollPanelPlayerName.TextSize = 13
TrollPanelPlayerName.Font = Enum.Font.GothamBold
TrollPanelPlayerName.Parent = TrollPanel

-- Target status label
TrollTargetLabel = Instance.new("TextLabel")
TrollTargetLabel.Size = UDim2.new(1, -20, 0, 14)
TrollTargetLabel.Position = UDim2.new(0, 10, 0, 130)
TrollTargetLabel.BackgroundTransparency = 1
TrollTargetLabel.Text = "Target: none"
TrollTargetLabel.TextColor3 = Colors.textDim
TrollTargetLabel.TextSize = 10
TrollTargetLabel.Font = Enum.Font.GothamBold
TrollTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TrollTargetLabel.Parent = TrollPanel

--==================================================
-- SECTION: ACTIONS (SCROLLABLE)
--==================================================

addAccentLine(TrollPanel, UDim2.new(0, 10, 0, 150), Colors.blood, UDim2.new(1, -20, 0, 1))

-- Scrollable button area
TrollBtnScroll = Instance.new("ScrollingFrame")
TrollBtnScroll.Size = UDim2.new(1, 0, 0, 400)
TrollBtnScroll.Position = UDim2.new(0, 0, 0, 155)
TrollBtnScroll.BackgroundTransparency = 1
TrollBtnScroll.BorderSizePixel = 0
TrollBtnScroll.ScrollBarThickness = 4
TrollBtnScroll.ScrollBarImageColor3 = Colors.blood
TrollBtnScroll.CanvasSize = UDim2.new(0, 0, 0, 844)
TrollBtnScroll.Parent = TrollPanel

--==================================================
-- TROLL BUTTON GRID (2 columns, scrollable)
--==================================================

-- Helper to create a troll action button (40px height, compact)
createTrollBtn = function(parent, text, yPos, xCol, color)
    local btnW = 105
    local xPos = xCol == 0 and 10 or 125
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, btnW, 0, 40)
    btn.Position = UDim2.new(0, xPos, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Colors.text
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    addBtnGradient(btn)

    -- Hover color
    local hc = Color3.new(
        math.min(color.R + 0.1, 1),
        math.min(color.G + 0.1, 1),
        math.min(color.B + 0.1, 1)
    )
    makeHoverable(btn, color, hc)
    return btn
end

-- Row 1 (y=4)
TrollFlingBtn = createTrollBtn(TrollBtnScroll, "💥 FLING", 4, 0, Colors.glowRed)
TrollHeadsitBtn = createTrollBtn(TrollBtnScroll, "🪑 HEADSIT", 4, 1, Colors.warning)

-- Row 2 (y=48)
TrollBangBtn = createTrollBtn(TrollBtnScroll, "😏 BANG", 48, 0, Colors.purple)
TrollBang2Btn = createTrollBtn(TrollBtnScroll, "🍑 BANG 2", 48, 1, Color3.fromRGB(180, 50, 100))

-- Row 3 (y=92)
TrollBackpackBtn = createTrollBtn(TrollBtnScroll, "🎒 BACKPACK", 92, 0, Color3.fromRGB(40, 100, 120))
TrollOrbitBtn = createTrollBtn(TrollBtnScroll, "🌀 ORBIT", 92, 1, Colors.green)

-- Row 4 (y=136)
TrollHelicopterBtn = createTrollBtn(TrollBtnScroll, "🚁 HELICOPTER", 136, 0, Color3.fromRGB(200, 80, 40))
TrollSpinTopBtn = createTrollBtn(TrollBtnScroll, "🌪 SPIN TOP", 136, 1, Color3.fromRGB(180, 50, 180))

-- Row 5 (y=180)
TrollTrampolineBtn = createTrollBtn(TrollBtnScroll, "🦘 TRAMPOLINE", 180, 0, Color3.fromRGB(50, 160, 80))
TrollCreepBtn = createTrollBtn(TrollBtnScroll, "👀 CREEP", 180, 1, Color3.fromRGB(60, 60, 60))

-- Row 6 (y=224)
TrollFlingAllBtn = createTrollBtn(TrollBtnScroll, "💣 FLING ALL", 224, 0, Colors.bloodDark)
TrollLaunchBtn = createTrollBtn(TrollBtnScroll, "🚀 LAUNCH", 224, 1, Color3.fromRGB(80, 40, 160))

-- Row 7 (y=268)
TrollCarpetBtn = createTrollBtn(TrollBtnScroll, "🧎 CARPET", 268, 0, Color3.fromRGB(140, 100, 40))
TrollDizzyBtn = createTrollBtn(TrollBtnScroll, "😵 DIZZY", 268, 1, Color3.fromRGB(220, 60, 180))

-- Row 8 (y=312)
TrollMagnetBtn = createTrollBtn(TrollBtnScroll, "🧲 MAGNET", 312, 0, Color3.fromRGB(40, 80, 160))
TrollCloneBtn = createTrollBtn(TrollBtnScroll, "👤 CLONE", 312, 1, Color3.fromRGB(60, 60, 60))

-- Row 9 (y=356)
TrollUpsideDownBtn = createTrollBtn(TrollBtnScroll, "🙃 UPSIDE DOWN", 356, 0, Color3.fromRGB(120, 60, 160))
TrollTornadoBtn = createTrollBtn(TrollBtnScroll, "🌪 TORNADO", 356, 1, Color3.fromRGB(30, 120, 140))

-- Row 10 (y=400)
TrollSnakeBtn = createTrollBtn(TrollBtnScroll, "🐍 SNAKE", 400, 0, Color3.fromRGB(60, 140, 40))
TrollMirrorBtn = createTrollBtn(TrollBtnScroll, "🪞 MIRROR", 400, 1, Color3.fromRGB(100, 140, 200))

-- Row 11 (y=444)
TrollStackBtn = createTrollBtn(TrollBtnScroll, "🏋 STACK", 444, 0, Color3.fromRGB(180, 120, 40))
TrollFigure8Btn = createTrollBtn(TrollBtnScroll, "🔄 FIGURE 8", 444, 1, Color3.fromRGB(60, 120, 180))

-- Row 12 (y=488)
TrollDogBtn = createTrollBtn(TrollBtnScroll, "🐶 DOG", 488, 0, Color3.fromRGB(140, 100, 60))
TrollFerrisBtn = createTrollBtn(TrollBtnScroll, "🎡 FERRIS", 488, 1, Color3.fromRGB(200, 60, 120))

-- Row 13 (y=532)
TrollSalsaBtn = createTrollBtn(TrollBtnScroll, "💃 SALSA", 532, 0, Color3.fromRGB(200, 40, 80))
TrollUfoBtn = createTrollBtn(TrollBtnScroll, "🛸 UFO", 532, 1, Color3.fromRGB(80, 180, 80))

-- Row 14 (y=576)
TrollBoomerangBtn = createTrollBtn(TrollBtnScroll, "🪃 BOOMERANG", 576, 0, Color3.fromRGB(200, 140, 40))
TrollRollerBtn = createTrollBtn(TrollBtnScroll, "🎢 ROLLER", 576, 1, Color3.fromRGB(40, 100, 200))

-- Row 15 (y=620)
TrollSpiralBtn = createTrollBtn(TrollBtnScroll, "🌀 SPIRAL", 620, 0, Color3.fromRGB(160, 40, 200))
TrollSurfBtn = createTrollBtn(TrollBtnScroll, "🏄 SURF", 620, 1, Color3.fromRGB(40, 160, 200))

-- Row 16 (y=664)
TrollBouncerBtn = createTrollBtn(TrollBtnScroll, "🎪 BOUNCER", 664, 0, Color3.fromRGB(200, 100, 40))
TrollLapSitBtn = createTrollBtn(TrollBtnScroll, "💺 LAP SIT", 664, 1, Color3.fromRGB(160, 60, 100))

-- Row 17 (y=708)
TrollWaveBtn = createTrollBtn(TrollBtnScroll, "🌊 WAVE", 708, 0, Color3.fromRGB(40, 120, 180))
TrollParasiteBtn = createTrollBtn(TrollBtnScroll, "🦠 PARASITE", 708, 1, Color3.fromRGB(100, 200, 60))

-- Row 18 (y=752)
TrollStalkBtn = createTrollBtn(TrollBtnScroll, "👁 STALK", 752, 0, Color3.fromRGB(60, 60, 80))
TrollPushBtn = createTrollBtn(TrollBtnScroll, "🤜 PUSH", 752, 1, Color3.fromRGB(200, 120, 40))

-- Row 19 (y=796)
TrollSwapBtn = createTrollBtn(TrollBtnScroll, "🔀 SWAP", 796, 0, Color3.fromRGB(40, 160, 160))
TrollJailBtn = createTrollBtn(TrollBtnScroll, "🔒 JAIL", 796, 1, Color3.fromRGB(180, 0, 0))

--==================================================
-- TROLL SPEED SLIDER
--==================================================

addAccentLine(TrollPanel, UDim2.new(0, 10, 0, 558), Colors.blood, UDim2.new(1, -20, 0, 1))

TrollSpeedSlider = createSliderRow(TrollPanel, "Troll Speed", 0.5, 5, 1, 564, function(val)
    trollSpeedMul = val
end)

--==================================================
-- STOP TROLL BUTTON
--==================================================

TrollStopBtn = Instance.new("TextButton")
TrollStopBtn.Size = UDim2.new(1, -20, 0, 30)
TrollStopBtn.Position = UDim2.new(0, 10, 0, 610)
TrollStopBtn.BackgroundColor3 = Colors.warning
TrollStopBtn.Text = "⛔ STOP TROLL"
TrollStopBtn.TextColor3 = Colors.bg
TrollStopBtn.TextSize = 11
TrollStopBtn.Font = Enum.Font.GothamBold
TrollStopBtn.AutoButtonColor = false
TrollStopBtn.Parent = TrollPanel
Instance.new("UICorner", TrollStopBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(TrollStopBtn, Colors.warning, Color3.fromRGB(230, 180, 60))

--==================================================
-- CLOSE BUTTON
--==================================================

TrollCloseBottomBtn = Instance.new("TextButton")
TrollCloseBottomBtn.Size = UDim2.new(1, -20, 0, 26)
TrollCloseBottomBtn.Position = UDim2.new(0, 10, 0, 646)
TrollCloseBottomBtn.BackgroundColor3 = Colors.bloodDark
TrollCloseBottomBtn.Text = "🔴 CLOSE"
TrollCloseBottomBtn.TextColor3 = Colors.text
TrollCloseBottomBtn.TextSize = 11
TrollCloseBottomBtn.Font = Enum.Font.GothamBold
TrollCloseBottomBtn.AutoButtonColor = false
TrollCloseBottomBtn.Parent = TrollPanel
Instance.new("UICorner", TrollCloseBottomBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(TrollCloseBottomBtn, Colors.bloodDark, Colors.blood)

--==================================================
-- OPEN TROLL PANEL
--==================================================

openTrollPanel = function(player)
    trollTarget = player
    TrollTargetLabel.Text = "Target: " .. player.DisplayName
    TrollTargetLabel.TextColor3 = Colors.bloodLight
    TrollPanelPlayerName.Text = player.DisplayName
    TrollPanelTitle.Text = "💥 " .. player.DisplayName

    -- Reset speed slider
    TrollSpeedSlider.setValue(trollSpeedMul)

    -- Load thumbnail
    task.spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
        end)
        if ok and thumb then TrollPanelThumb.Image = thumb end
    end)

    TrollPanel.Visible = true
    notify("Troll target: " .. player.DisplayName, "info")
end


--[[ ═══════ MODULE: 09d_remote_panel.luau ═══════ ]]

--==================================================
-- REMOTE SPY PANEL — FLOATING
-- Scanner + Spy + Custom Fire + Block + Repeat + Export
-- Todas as variaveis sao GLOBALS para nao gastar locals
--==================================================

selectedFireRemote = nil

RemoteSpyPanel = Instance.new("Frame")
RemoteSpyPanel.Name = "RemoteSpyPanel"
RemoteSpyPanel.Size = UDim2.new(0, 280, 0, 710)
RemoteSpyPanel.Position = UDim2.new(0.5, -400, 0.5, -360)
RemoteSpyPanel.BackgroundColor3 = Colors.bg
RemoteSpyPanel.BorderSizePixel = 0
RemoteSpyPanel.Visible = false
RemoteSpyPanel.Parent = ScreenGui

Instance.new("UICorner", RemoteSpyPanel).CornerRadius = UDim.new(0, 10)
RemoteSpyPanelStroke = Instance.new("UIStroke", RemoteSpyPanel)
RemoteSpyPanelStroke.Color = Color3.fromRGB(0, 180, 160)
RemoteSpyPanelStroke.Thickness = 1.5
addGradient(RemoteSpyPanel, Colors.surfaceLight, Color3.fromRGB(6, 10, 10), 90)

--==================================================
-- TOP BAR
--==================================================

RemoteSpyTopBar = Instance.new("Frame")
RemoteSpyTopBar.Size = UDim2.new(1, 0, 0, 32)
RemoteSpyTopBar.BackgroundColor3 = Colors.topbar
RemoteSpyTopBar.BorderSizePixel = 0
RemoteSpyTopBar.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyTopBar).CornerRadius = UDim.new(0, 10)
addGradient(RemoteSpyTopBar, Color3.fromRGB(8, 30, 28), Colors.topbar, 0)

RemoteSpyTopBarFix = Instance.new("Frame")
RemoteSpyTopBarFix.Size = UDim2.new(1, 0, 0, 10)
RemoteSpyTopBarFix.Position = UDim2.new(0, 0, 1, -10)
RemoteSpyTopBarFix.BackgroundColor3 = Colors.topbar
RemoteSpyTopBarFix.BorderSizePixel = 0
RemoteSpyTopBarFix.Parent = RemoteSpyTopBar

addAccentLine(RemoteSpyTopBar, UDim2.new(0, 0, 1, -1), Color3.fromRGB(0, 180, 160))

RemoteSpyTitle = Instance.new("TextLabel")
RemoteSpyTitle.Size = UDim2.new(1, -40, 1, 0)
RemoteSpyTitle.Position = UDim2.new(0, 10, 0, 0)
RemoteSpyTitle.BackgroundTransparency = 1
RemoteSpyTitle.Text = "🕵 Remote Spy"
RemoteSpyTitle.TextColor3 = Color3.fromRGB(100, 220, 200)
RemoteSpyTitle.TextSize = 12
RemoteSpyTitle.Font = Enum.Font.GothamBold
RemoteSpyTitle.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpyTitle.Parent = RemoteSpyTopBar

RemoteSpyCloseBtn = Instance.new("TextButton")
RemoteSpyCloseBtn.Size = UDim2.new(0, 20, 0, 20)
RemoteSpyCloseBtn.Position = UDim2.new(1, -26, 0, 6)
RemoteSpyCloseBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 120)
RemoteSpyCloseBtn.Text = "X"
RemoteSpyCloseBtn.TextColor3 = Colors.text
RemoteSpyCloseBtn.TextSize = 11
RemoteSpyCloseBtn.Font = Enum.Font.GothamBold
RemoteSpyCloseBtn.AutoButtonColor = false
RemoteSpyCloseBtn.Parent = RemoteSpyTopBar
Instance.new("UICorner", RemoteSpyCloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(RemoteSpyCloseBtn, Color3.fromRGB(0, 140, 120), Color3.fromRGB(0, 180, 160))

--==================================================
-- SCAN SECTION
--==================================================

RemoteSpyScanBtn = Instance.new("TextButton")
RemoteSpyScanBtn.Size = UDim2.new(0.5, -12, 0, 28)
RemoteSpyScanBtn.Position = UDim2.new(0, 10, 0, 40)
RemoteSpyScanBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 120)
RemoteSpyScanBtn.Text = "🔍 SCAN"
RemoteSpyScanBtn.TextColor3 = Colors.text
RemoteSpyScanBtn.TextSize = 10
RemoteSpyScanBtn.Font = Enum.Font.GothamBold
RemoteSpyScanBtn.AutoButtonColor = false
RemoteSpyScanBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyScanBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RemoteSpyScanBtn)
makeHoverable(RemoteSpyScanBtn, Color3.fromRGB(0, 140, 120), Color3.fromRGB(0, 180, 160))

RemoteSpyVulnScanBtn = Instance.new("TextButton")
RemoteSpyVulnScanBtn.Size = UDim2.new(0.5, -12, 0, 28)
RemoteSpyVulnScanBtn.Position = UDim2.new(0.5, 2, 0, 40)
RemoteSpyVulnScanBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
RemoteSpyVulnScanBtn.Text = "⚠ VULN SCAN"
RemoteSpyVulnScanBtn.TextColor3 = Colors.text
RemoteSpyVulnScanBtn.TextSize = 10
RemoteSpyVulnScanBtn.Font = Enum.Font.GothamBold
RemoteSpyVulnScanBtn.AutoButtonColor = false
RemoteSpyVulnScanBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyVulnScanBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RemoteSpyVulnScanBtn)
makeHoverable(RemoteSpyVulnScanBtn, Color3.fromRGB(180, 80, 20), Color3.fromRGB(220, 100, 30))

RemoteSpyStatsLabel = Instance.new("TextLabel")
RemoteSpyStatsLabel.Size = UDim2.new(1, -20, 0, 14)
RemoteSpyStatsLabel.Position = UDim2.new(0, 10, 0, 72)
RemoteSpyStatsLabel.BackgroundTransparency = 1
RemoteSpyStatsLabel.Text = "Found: 0 remotes"
RemoteSpyStatsLabel.TextColor3 = Colors.textDim
RemoteSpyStatsLabel.TextSize = 9
RemoteSpyStatsLabel.Font = Enum.Font.Code
RemoteSpyStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpyStatsLabel.Parent = RemoteSpyPanel

RemoteSpyFilterBox = Instance.new("TextBox")
RemoteSpyFilterBox.Size = UDim2.new(1, -20, 0, 22)
RemoteSpyFilterBox.Position = UDim2.new(0, 10, 0, 90)
RemoteSpyFilterBox.BackgroundColor3 = Colors.content
RemoteSpyFilterBox.Text = ""
RemoteSpyFilterBox.PlaceholderText = "Filter remotes..."
RemoteSpyFilterBox.PlaceholderColor3 = Colors.textDim
RemoteSpyFilterBox.TextColor3 = Colors.text
RemoteSpyFilterBox.TextSize = 10
RemoteSpyFilterBox.Font = Enum.Font.Code
RemoteSpyFilterBox.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpyFilterBox.ClearTextOnFocus = false
RemoteSpyFilterBox.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyFilterBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", RemoteSpyFilterBox).PaddingLeft = UDim.new(0, 6)

RemoteSpyListScroll = Instance.new("ScrollingFrame")
RemoteSpyListScroll.Size = UDim2.new(1, -20, 0, 120)
RemoteSpyListScroll.Position = UDim2.new(0, 10, 0, 116)
RemoteSpyListScroll.BackgroundColor3 = Colors.content
RemoteSpyListScroll.BorderSizePixel = 0
RemoteSpyListScroll.ScrollBarThickness = 3
RemoteSpyListScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 160)
RemoteSpyListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
RemoteSpyListScroll.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyListScroll).CornerRadius = UDim.new(0, 4)

RemoteSpyListLayout = Instance.new("UIListLayout")
RemoteSpyListLayout.Padding = UDim.new(0, 2)
RemoteSpyListLayout.Parent = RemoteSpyListScroll

RemoteSpyListPad = Instance.new("UIPadding", RemoteSpyListScroll)
RemoteSpyListPad.PaddingTop = UDim.new(0, 3)
RemoteSpyListPad.PaddingLeft = UDim.new(0, 3)
RemoteSpyListPad.PaddingRight = UDim.new(0, 3)

--==================================================
-- CUSTOM FIRE SECTION
--==================================================

RemoteSpySelectedLabel = Instance.new("TextLabel")
RemoteSpySelectedLabel.Size = UDim2.new(1, -20, 0, 14)
RemoteSpySelectedLabel.Position = UDim2.new(0, 10, 0, 240)
RemoteSpySelectedLabel.BackgroundTransparency = 1
RemoteSpySelectedLabel.Text = "Selected: (click 🎯 to select)"
RemoteSpySelectedLabel.TextColor3 = Colors.textDim
RemoteSpySelectedLabel.TextSize = 9
RemoteSpySelectedLabel.Font = Enum.Font.Code
RemoteSpySelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpySelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
RemoteSpySelectedLabel.Parent = RemoteSpyPanel

RemoteSpyArgsBox = Instance.new("TextBox")
RemoteSpyArgsBox.Size = UDim2.new(1, -20, 0, 28)
RemoteSpyArgsBox.Position = UDim2.new(0, 10, 0, 256)
RemoteSpyArgsBox.BackgroundColor3 = Colors.inputBg
RemoteSpyArgsBox.Text = ""
RemoteSpyArgsBox.PlaceholderText = "Args: \"hello\", 123, true"
RemoteSpyArgsBox.PlaceholderColor3 = Colors.textDim
RemoteSpyArgsBox.TextColor3 = Colors.text
RemoteSpyArgsBox.TextSize = 10
RemoteSpyArgsBox.Font = Enum.Font.Code
RemoteSpyArgsBox.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpyArgsBox.ClearTextOnFocus = false
RemoteSpyArgsBox.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyArgsBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", RemoteSpyArgsBox).PaddingLeft = UDim.new(0, 6)
RemoteSpyArgsStroke = Instance.new("UIStroke", RemoteSpyArgsBox)
RemoteSpyArgsStroke.Color = Colors.inputBorder
RemoteSpyArgsStroke.Thickness = 1

RemoteSpyArgsBox.Focused:Connect(function()
    TweenService:Create(RemoteSpyArgsStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(0, 200, 180), Thickness = 1.5 }):Play()
end)
RemoteSpyArgsBox.FocusLost:Connect(function()
    TweenService:Create(RemoteSpyArgsStroke, TweenInfo.new(0.3), { Color = Colors.inputBorder, Thickness = 1 }):Play()
end)

RemoteSpyFireCustomBtn = Instance.new("TextButton")
RemoteSpyFireCustomBtn.Size = UDim2.new(0.5, -12, 0, 26)
RemoteSpyFireCustomBtn.Position = UDim2.new(0, 10, 0, 288)
RemoteSpyFireCustomBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 30)
RemoteSpyFireCustomBtn.Text = "🔥 FIRE"
RemoteSpyFireCustomBtn.TextColor3 = Colors.text
RemoteSpyFireCustomBtn.TextSize = 10
RemoteSpyFireCustomBtn.Font = Enum.Font.GothamBold
RemoteSpyFireCustomBtn.AutoButtonColor = false
RemoteSpyFireCustomBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyFireCustomBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RemoteSpyFireCustomBtn)
makeHoverable(RemoteSpyFireCustomBtn, Color3.fromRGB(180, 60, 30), Color3.fromRGB(220, 80, 40))

RemoteSpyMassFireBtn = Instance.new("TextButton")
RemoteSpyMassFireBtn.Size = UDim2.new(0.5, -12, 0, 26)
RemoteSpyMassFireBtn.Position = UDim2.new(0.5, 2, 0, 288)
RemoteSpyMassFireBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
RemoteSpyMassFireBtn.Text = "💣 MASS FIRE"
RemoteSpyMassFireBtn.TextColor3 = Colors.text
RemoteSpyMassFireBtn.TextSize = 10
RemoteSpyMassFireBtn.Font = Enum.Font.GothamBold
RemoteSpyMassFireBtn.AutoButtonColor = false
RemoteSpyMassFireBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyMassFireBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RemoteSpyMassFireBtn)
makeHoverable(RemoteSpyMassFireBtn, Color3.fromRGB(160, 30, 30), Color3.fromRGB(200, 50, 50))

--==================================================
-- FUZZ + DECOMPILE ROW
--==================================================

RemoteSpyFuzzBtn = Instance.new("TextButton")
RemoteSpyFuzzBtn.Size = UDim2.new(0.5, -12, 0, 26)
RemoteSpyFuzzBtn.Position = UDim2.new(0, 10, 0, 318)
RemoteSpyFuzzBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 180)
RemoteSpyFuzzBtn.Text = "🧪 FUZZ"
RemoteSpyFuzzBtn.TextColor3 = Colors.text
RemoteSpyFuzzBtn.TextSize = 10
RemoteSpyFuzzBtn.Font = Enum.Font.GothamBold
RemoteSpyFuzzBtn.AutoButtonColor = false
RemoteSpyFuzzBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyFuzzBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RemoteSpyFuzzBtn)
makeHoverable(RemoteSpyFuzzBtn, Color3.fromRGB(120, 60, 180), Color3.fromRGB(160, 80, 220))

RemoteSpyDecompileBtn = Instance.new("TextButton")
RemoteSpyDecompileBtn.Size = UDim2.new(0.5, -12, 0, 26)
RemoteSpyDecompileBtn.Position = UDim2.new(0.5, 2, 0, 318)
RemoteSpyDecompileBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 160)
RemoteSpyDecompileBtn.Text = "📜 DECOMPILE"
RemoteSpyDecompileBtn.TextColor3 = Colors.text
RemoteSpyDecompileBtn.TextSize = 10
RemoteSpyDecompileBtn.Font = Enum.Font.GothamBold
RemoteSpyDecompileBtn.AutoButtonColor = false
RemoteSpyDecompileBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyDecompileBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RemoteSpyDecompileBtn)
makeHoverable(RemoteSpyDecompileBtn, Color3.fromRGB(40, 100, 160), Color3.fromRGB(60, 140, 200))

--==================================================
-- SPY SECTION
--==================================================

addAccentLine(RemoteSpyPanel, UDim2.new(0, 10, 0, 352), Color3.fromRGB(0, 180, 160), UDim2.new(1, -20, 0, 1))

RemoteSpyToggleBtn = Instance.new("TextButton")
RemoteSpyToggleBtn.Size = UDim2.new(1, -20, 0, 28)
RemoteSpyToggleBtn.Position = UDim2.new(0, 10, 0, 360)
RemoteSpyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 70)
RemoteSpyToggleBtn.Text = "🕵 START SPY"
RemoteSpyToggleBtn.TextColor3 = Colors.text
RemoteSpyToggleBtn.TextSize = 11
RemoteSpyToggleBtn.Font = Enum.Font.GothamBold
RemoteSpyToggleBtn.AutoButtonColor = false
RemoteSpyToggleBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyToggleBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RemoteSpyToggleBtn)
makeHoverable(RemoteSpyToggleBtn, Color3.fromRGB(40, 80, 70), Color3.fromRGB(0, 140, 120))

RemoteSpyStatusLabel = Instance.new("TextLabel")
RemoteSpyStatusLabel.Size = UDim2.new(1, -20, 0, 14)
RemoteSpyStatusLabel.Position = UDim2.new(0, 10, 0, 392)
RemoteSpyStatusLabel.BackgroundTransparency = 1
RemoteSpyStatusLabel.Text = "Spy: OFF"
RemoteSpyStatusLabel.TextColor3 = Colors.textDim
RemoteSpyStatusLabel.TextSize = 9
RemoteSpyStatusLabel.Font = Enum.Font.Code
RemoteSpyStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpyStatusLabel.Parent = RemoteSpyPanel

RemoteSpyLogFilterBox = Instance.new("TextBox")
RemoteSpyLogFilterBox.Size = UDim2.new(1, -20, 0, 22)
RemoteSpyLogFilterBox.Position = UDim2.new(0, 10, 0, 410)
RemoteSpyLogFilterBox.BackgroundColor3 = Colors.content
RemoteSpyLogFilterBox.Text = ""
RemoteSpyLogFilterBox.PlaceholderText = "Search spy log..."
RemoteSpyLogFilterBox.PlaceholderColor3 = Colors.textDim
RemoteSpyLogFilterBox.TextColor3 = Colors.text
RemoteSpyLogFilterBox.TextSize = 10
RemoteSpyLogFilterBox.Font = Enum.Font.Code
RemoteSpyLogFilterBox.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpyLogFilterBox.ClearTextOnFocus = false
RemoteSpyLogFilterBox.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyLogFilterBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", RemoteSpyLogFilterBox).PaddingLeft = UDim.new(0, 6)

-- Spy log scroll
RemoteSpyLogScroll = Instance.new("ScrollingFrame")
RemoteSpyLogScroll.Size = UDim2.new(1, -20, 0, 150)
RemoteSpyLogScroll.Position = UDim2.new(0, 10, 0, 436)
RemoteSpyLogScroll.BackgroundColor3 = Color3.fromRGB(10, 14, 14)
RemoteSpyLogScroll.BorderSizePixel = 0
RemoteSpyLogScroll.ScrollBarThickness = 3
RemoteSpyLogScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 160)
RemoteSpyLogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
RemoteSpyLogScroll.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyLogScroll).CornerRadius = UDim.new(0, 4)

RemoteSpyLogLayout = Instance.new("UIListLayout")
RemoteSpyLogLayout.Padding = UDim.new(0, 1)
RemoteSpyLogLayout.Parent = RemoteSpyLogScroll

RemoteSpyLogPad = Instance.new("UIPadding", RemoteSpyLogScroll)
RemoteSpyLogPad.PaddingTop = UDim.new(0, 2)
RemoteSpyLogPad.PaddingLeft = UDim.new(0, 3)
RemoteSpyLogPad.PaddingRight = UDim.new(0, 3)

-- Hint label
RemoteSpyLogHint = Instance.new("TextLabel")
RemoteSpyLogHint.Size = UDim2.new(1, -20, 0, 12)
RemoteSpyLogHint.Position = UDim2.new(0, 10, 0, 588)
RemoteSpyLogHint.BackgroundTransparency = 1
RemoteSpyLogHint.Text = "💡 Click entry → copy script + auto-fill args"
RemoteSpyLogHint.TextColor3 = Color3.fromRGB(80, 80, 90)
RemoteSpyLogHint.TextSize = 8
RemoteSpyLogHint.Font = Enum.Font.Gotham
RemoteSpyLogHint.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpyLogHint.Parent = RemoteSpyPanel

--==================================================
-- AUTO-REPEAT SECTION
--==================================================

addAccentLine(RemoteSpyPanel, UDim2.new(0, 10, 0, 604), Color3.fromRGB(120, 60, 180), UDim2.new(1, -20, 0, 1))

RemoteSpyRepeatLabel = Instance.new("TextLabel")
RemoteSpyRepeatLabel.Size = UDim2.new(0, 48, 0, 22)
RemoteSpyRepeatLabel.Position = UDim2.new(0, 10, 0, 612)
RemoteSpyRepeatLabel.BackgroundTransparency = 1
RemoteSpyRepeatLabel.Text = "Repeat:"
RemoteSpyRepeatLabel.TextColor3 = Colors.textDim
RemoteSpyRepeatLabel.TextSize = 9
RemoteSpyRepeatLabel.Font = Enum.Font.GothamBold
RemoteSpyRepeatLabel.TextXAlignment = Enum.TextXAlignment.Left
RemoteSpyRepeatLabel.Parent = RemoteSpyPanel

-- Interval box
RemoteSpyIntervalBox = Instance.new("TextBox")
RemoteSpyIntervalBox.Size = UDim2.new(0, 50, 0, 22)
RemoteSpyIntervalBox.Position = UDim2.new(0, 60, 0, 612)
RemoteSpyIntervalBox.BackgroundColor3 = Colors.inputBg
RemoteSpyIntervalBox.Text = "1"
RemoteSpyIntervalBox.PlaceholderText = "sec"
RemoteSpyIntervalBox.PlaceholderColor3 = Colors.textDim
RemoteSpyIntervalBox.TextColor3 = Colors.text
RemoteSpyIntervalBox.TextSize = 9
RemoteSpyIntervalBox.Font = Enum.Font.Code
RemoteSpyIntervalBox.ClearTextOnFocus = false
RemoteSpyIntervalBox.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyIntervalBox).CornerRadius = UDim.new(0, 4)

RemoteSpyRepeatXLabel = Instance.new("TextLabel")
RemoteSpyRepeatXLabel.Size = UDim2.new(0, 16, 0, 22)
RemoteSpyRepeatXLabel.Position = UDim2.new(0, 113, 0, 612)
RemoteSpyRepeatXLabel.BackgroundTransparency = 1
RemoteSpyRepeatXLabel.Text = "x"
RemoteSpyRepeatXLabel.TextColor3 = Colors.textDim
RemoteSpyRepeatXLabel.TextSize = 9
RemoteSpyRepeatXLabel.Font = Enum.Font.GothamBold
RemoteSpyRepeatXLabel.Parent = RemoteSpyPanel

-- Count box (0 = infinite)
RemoteSpyCountBox = Instance.new("TextBox")
RemoteSpyCountBox.Size = UDim2.new(0, 40, 0, 22)
RemoteSpyCountBox.Position = UDim2.new(0, 130, 0, 612)
RemoteSpyCountBox.BackgroundColor3 = Colors.inputBg
RemoteSpyCountBox.Text = "10"
RemoteSpyCountBox.PlaceholderText = "0=∞"
RemoteSpyCountBox.PlaceholderColor3 = Colors.textDim
RemoteSpyCountBox.TextColor3 = Colors.text
RemoteSpyCountBox.TextSize = 9
RemoteSpyCountBox.Font = Enum.Font.Code
RemoteSpyCountBox.ClearTextOnFocus = false
RemoteSpyCountBox.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyCountBox).CornerRadius = UDim.new(0, 4)

-- Repeat button
RemoteSpyRepeatBtn = Instance.new("TextButton")
RemoteSpyRepeatBtn.Size = UDim2.new(0, 90, 0, 22)
RemoteSpyRepeatBtn.Position = UDim2.new(1, -100, 0, 612)
RemoteSpyRepeatBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
RemoteSpyRepeatBtn.Text = "▶ REPEAT"
RemoteSpyRepeatBtn.TextColor3 = Colors.text
RemoteSpyRepeatBtn.TextSize = 9
RemoteSpyRepeatBtn.Font = Enum.Font.GothamBold
RemoteSpyRepeatBtn.AutoButtonColor = false
RemoteSpyRepeatBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyRepeatBtn).CornerRadius = UDim.new(0, 4)
makeHoverable(RemoteSpyRepeatBtn, Color3.fromRGB(80, 40, 120), Color3.fromRGB(110, 60, 160))

--==================================================
-- BOTTOM BUTTONS
--==================================================

-- Row: [EXPORT] [CLEAR]
RemoteSpyExportBtn = Instance.new("TextButton")
RemoteSpyExportBtn.Size = UDim2.new(0.5, -12, 0, 26)
RemoteSpyExportBtn.Position = UDim2.new(0, 10, 0, 644)
RemoteSpyExportBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 140)
RemoteSpyExportBtn.Text = "📋 EXPORT LOG"
RemoteSpyExportBtn.TextColor3 = Colors.text
RemoteSpyExportBtn.TextSize = 9
RemoteSpyExportBtn.Font = Enum.Font.GothamBold
RemoteSpyExportBtn.AutoButtonColor = false
RemoteSpyExportBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyExportBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(RemoteSpyExportBtn, Color3.fromRGB(0, 100, 140), Color3.fromRGB(0, 140, 180))

RemoteSpyClearBtn = Instance.new("TextButton")
RemoteSpyClearBtn.Size = UDim2.new(0.5, -12, 0, 26)
RemoteSpyClearBtn.Position = UDim2.new(0.5, 2, 0, 644)
RemoteSpyClearBtn.BackgroundColor3 = Colors.warning
RemoteSpyClearBtn.Text = "🗑 CLEAR"
RemoteSpyClearBtn.TextColor3 = Colors.bg
RemoteSpyClearBtn.TextSize = 10
RemoteSpyClearBtn.Font = Enum.Font.GothamBold
RemoteSpyClearBtn.AutoButtonColor = false
RemoteSpyClearBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyClearBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(RemoteSpyClearBtn, Colors.warning, Color3.fromRGB(230, 180, 60))

-- Row: [CLOSE]
RemoteSpyCloseBottomBtn = Instance.new("TextButton")
RemoteSpyCloseBottomBtn.Size = UDim2.new(1, -20, 0, 26)
RemoteSpyCloseBottomBtn.Position = UDim2.new(0, 10, 0, 674)
RemoteSpyCloseBottomBtn.BackgroundColor3 = Colors.bloodDark
RemoteSpyCloseBottomBtn.Text = "🔴 CLOSE"
RemoteSpyCloseBottomBtn.TextColor3 = Colors.text
RemoteSpyCloseBottomBtn.TextSize = 10
RemoteSpyCloseBottomBtn.Font = Enum.Font.GothamBold
RemoteSpyCloseBottomBtn.AutoButtonColor = false
RemoteSpyCloseBottomBtn.Parent = RemoteSpyPanel
Instance.new("UICorner", RemoteSpyCloseBottomBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(RemoteSpyCloseBottomBtn, Colors.bloodDark, Colors.blood)

--==================================================
-- REFRESH REMOTE LIST (cards com 🎯 select + 🚫 block + call count)
--==================================================

refreshRemoteList = function(filterText)
    for _, child in pairs(RemoteSpyListScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    filterText = filterText and filterText:lower() or ""

    local count = 0
    local vulnCount = 0
    for idx, data in ipairs(scannedRemotes) do
        local match = true
        if filterText ~= "" and not data.name:lower():find(filterText, 1, true) and not data.path:lower():find(filterText, 1, true) then
            match = false
        end

        if match then
        count = count + 1
        if data.vuln == "vuln" then vulnCount = vulnCount + 1 end

        local isBlocked = blockedRemotes[data.path] == true
        local callCount = remoteCallCounts[data.path] or 0

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, 36)
        card.BorderSizePixel = 0
        card.LayoutOrder = idx
        card.Parent = RemoteSpyListScroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 4)

        -- Card color
        if isBlocked then
            card.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
        elseif data.vuln == "vuln" then
            card.BackgroundColor3 = Color3.fromRGB(50, 15, 15)
        elseif data.vuln == "safe" then
            card.BackgroundColor3 = Color3.fromRGB(15, 40, 20)
        elseif data.vuln == "timeout" then
            card.BackgroundColor3 = Color3.fromRGB(40, 35, 10)
        else
            card.BackgroundColor3 = Colors.card
        end

        -- Type icon
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 18, 0, 18)
        icon.Position = UDim2.new(0, 3, 0, 2)
        icon.BackgroundTransparency = 1
        icon.Text = data.class == "RemoteEvent" and "📡" or "📞"
        icon.TextSize = 11
        icon.Parent = card

        -- Vuln/Block badge
        if isBlocked then
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 18, 0, 10)
            badge.Position = UDim2.new(0, 3, 0, 20)
            badge.BackgroundTransparency = 1
            badge.Text = "🚫"
            badge.TextSize = 7
            badge.Parent = card
        elseif data.vuln == "vuln" then
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 18, 0, 10)
            badge.Position = UDim2.new(0, 3, 0, 20)
            badge.BackgroundTransparency = 1
            badge.Text = "⚠"
            badge.TextSize = 8
            badge.TextColor3 = Color3.fromRGB(255, 80, 40)
            badge.Parent = card
        elseif data.vuln == "safe" then
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 18, 0, 10)
            badge.Position = UDim2.new(0, 3, 0, 20)
            badge.BackgroundTransparency = 1
            badge.Text = "✓"
            badge.TextSize = 8
            badge.TextColor3 = Color3.fromRGB(60, 200, 80)
            badge.Font = Enum.Font.GothamBold
            badge.Parent = card
        elseif data.vuln == "timeout" then
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 18, 0, 10)
            badge.Position = UDim2.new(0, 3, 0, 20)
            badge.BackgroundTransparency = 1
            badge.Text = "⏱"
            badge.TextSize = 8
            badge.TextColor3 = Color3.fromRGB(200, 180, 60)
            badge.Parent = card
        end

        -- Name (with blocked prefix)
        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(1, -68, 0, 14)
        nameL.Position = UDim2.new(0, 22, 0, 1)
        nameL.BackgroundTransparency = 1
        nameL.Text = (isBlocked and "[BLOCKED] " or "") .. data.name
        nameL.TextSize = 9
        nameL.Font = Enum.Font.GothamBold
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        nameL.TextTruncate = Enum.TextTruncate.AtEnd
        nameL.Parent = card

        if isBlocked then
            nameL.TextColor3 = Color3.fromRGB(180, 60, 60)
        elseif data.vuln == "vuln" then
            nameL.TextColor3 = Color3.fromRGB(255, 100, 60)
        elseif data.vuln == "safe" then
            nameL.TextColor3 = Color3.fromRGB(80, 220, 100)
        else
            nameL.TextColor3 = Color3.fromRGB(100, 220, 200)
        end

        -- Path + call count
        local pathText = data.path
        if callCount > 0 then
            pathText = pathText .. " [x" .. callCount .. "]"
        end
        local pathL = Instance.new("TextLabel")
        pathL.Size = UDim2.new(1, -68, 0, 12)
        pathL.Position = UDim2.new(0, 22, 0, 16)
        pathL.BackgroundTransparency = 1
        pathL.Text = pathText
        pathL.TextColor3 = Colors.textDim
        pathL.TextSize = 7
        pathL.Font = Enum.Font.Code
        pathL.TextXAlignment = Enum.TextXAlignment.Left
        pathL.TextTruncate = Enum.TextTruncate.AtEnd
        pathL.Parent = card

        -- 🎯 Select button (left)
        local selBtn = Instance.new("TextButton")
        selBtn.Size = UDim2.new(0, 18, 0, 18)
        selBtn.Position = UDim2.new(1, -40, 0, 9)
        selBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 100)
        selBtn.Text = "🎯"
        selBtn.TextSize = 9
        selBtn.TextColor3 = Colors.text
        selBtn.Font = Enum.Font.GothamBold
        selBtn.AutoButtonColor = false
        selBtn.Parent = card
        Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(selBtn, Color3.fromRGB(0, 120, 100), Color3.fromRGB(0, 160, 140))

        selBtn.MouseButton1Click:Connect(function()
            selectedFireRemote = data
            RemoteSpySelectedLabel.Text = "Selected: " .. data.class:sub(7, 7) .. " " .. data.name
            RemoteSpySelectedLabel.TextColor3 = Color3.fromRGB(100, 220, 200)
            notify("Selected: " .. data.name, "info")
        end)

        -- 🚫 Block button (right)
        local blockBtn = Instance.new("TextButton")
        blockBtn.Size = UDim2.new(0, 18, 0, 18)
        blockBtn.Position = UDim2.new(1, -20, 0, 9)
        blockBtn.BackgroundColor3 = isBlocked and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 30, 30)
        blockBtn.Text = isBlocked and "✅" or "🚫"
        blockBtn.TextSize = 9
        blockBtn.TextColor3 = Colors.text
        blockBtn.Font = Enum.Font.GothamBold
        blockBtn.AutoButtonColor = false
        blockBtn.Parent = card
        Instance.new("UICorner", blockBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(blockBtn,
            isBlocked and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 30, 30),
            isBlocked and Color3.fromRGB(60, 160, 60) or Color3.fromRGB(160, 50, 50)
        )

        blockBtn.MouseButton1Click:Connect(function()
            if blockedRemotes[data.path] then
                blockedRemotes[data.path] = nil
                notify("Unblocked: " .. data.name, "success")
            else
                blockedRemotes[data.path] = true
                notify("Blocked: " .. data.name, "warning")
            end
            refreshRemoteList(RemoteSpyFilterBox.Text)
        end)
        end -- if match
    end

    RemoteSpyListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 38)

    local statsText = "Found: " .. #scannedRemotes .. " remotes"
    if vulnCount > 0 then
        statsText = statsText .. " | ⚠ " .. vulnCount .. " vuln"
    end
    local blockedCount = 0
    for _ in pairs(blockedRemotes) do blockedCount = blockedCount + 1 end
    if blockedCount > 0 then
        statsText = statsText .. " | 🚫 " .. blockedCount .. " blocked"
    end
    if filterText ~= "" then
        statsText = statsText .. " (" .. count .. " shown)"
    end
    RemoteSpyStatsLabel.Text = statsText
end

--==================================================
-- REFRESH SPY LOG (clickable entries, filtro, caller, return)
--==================================================

refreshRemoteSpyLog = function()
    for _, child in pairs(RemoteSpyLogScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end

    local filterText = RemoteSpyLogFilterBox.Text:lower()
    local count = 0

    for idx, entry in ipairs(remoteSpyLog) do
        local secs = math.floor(entry.time % 60)
        local mins = math.floor((entry.time / 60) % 60)
        local hrs = math.floor((entry.time / 3600) % 24)
        local timeStr = string.format("%02d:%02d:%02d", hrs, mins, secs)

        local argStrs = {}
        for _, arg in ipairs(entry.args) do
            local s = tostring(arg)
            if #s > 30 then s = s:sub(1, 27) .. "..." end
            table.insert(argStrs, s)
        end
        local argsText = #argStrs > 0 and ("(" .. table.concat(argStrs, ", ") .. ")") or "()"

        local fullText = timeStr .. " " .. entry.name .. ":" .. entry.method .. argsText
        -- Add return value for InvokeServer
        if entry.returnValue then
            fullText = fullText .. " → " .. entry.returnValue
        end

        -- Apply filter
        local show = true
        if filterText ~= "" then
            if not fullText:lower():find(filterText, 1, true) and not entry.name:lower():find(filterText, 1, true) then
                show = false
            end
        end

        if show then
            count = count + 1

            -- TextButton for clickable (copy script)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 14)
            btn.BackgroundColor3 = count % 2 == 0 and Color3.fromRGB(14, 18, 18) or Color3.fromRGB(10, 14, 14)
            btn.BackgroundTransparency = 0
            btn.BorderSizePixel = 0
            btn.LayoutOrder = idx
            btn.AutoButtonColor = false

            btn.Text = fullText
            btn.TextColor3 = entry.method == "FireServer" and Color3.fromRGB(100, 220, 200) or Color3.fromRGB(220, 180, 100)
            btn.TextSize = 7
            btn.Font = Enum.Font.Code
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            btn.Parent = RemoteSpyLogScroll

            -- Click → copy generated script
            btn.MouseButton1Click:Connect(function()
                copyLogEntry(entry)
            end)

            -- Hover effect
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(20, 30, 30)
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = count % 2 == 0 and Color3.fromRGB(14, 18, 18) or Color3.fromRGB(10, 14, 14)
            end)
        end
    end

    RemoteSpyLogScroll.CanvasSize = UDim2.new(0, 0, 0, count * 15)
    RemoteSpyLogScroll.CanvasPosition = Vector2.new(0, math.max(0, count * 15 - 150))
end

--==================================================
-- OPEN REMOTE SPY PANEL
--==================================================

openRemoteSpyPanel = function()
    scanRemotes()
    refreshRemoteList("")
    RemoteSpyPanel.Visible = true
    notify("Remote Spy opened — " .. #scannedRemotes .. " remotes found", "info")
end

--==================================================
-- DECOMPILE RESULTS PANEL — FLOATING
--==================================================

DecompilePanel = Instance.new("Frame")
DecompilePanel.Name = "DecompilePanel"
DecompilePanel.Size = UDim2.new(0, 420, 0, 400)
DecompilePanel.Position = UDim2.new(0.5, 50, 0.5, -200)
DecompilePanel.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
DecompilePanel.BorderSizePixel = 0
DecompilePanel.Visible = false
DecompilePanel.Parent = ScreenGui
Instance.new("UICorner", DecompilePanel).CornerRadius = UDim.new(0, 10)

DecompilePanelStroke = Instance.new("UIStroke", DecompilePanel)
DecompilePanelStroke.Color = Color3.fromRGB(40, 100, 160)
DecompilePanelStroke.Thickness = 1.5
addGradient(DecompilePanel, Color3.fromRGB(12, 16, 22), Color3.fromRGB(6, 8, 12), 90)

-- Top Bar
DecompileTopBar = Instance.new("Frame")
DecompileTopBar.Size = UDim2.new(1, 0, 0, 32)
DecompileTopBar.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
DecompileTopBar.BorderSizePixel = 0
DecompileTopBar.Parent = DecompilePanel
Instance.new("UICorner", DecompileTopBar).CornerRadius = UDim.new(0, 10)
addGradient(DecompileTopBar, Color3.fromRGB(10, 18, 30), Color3.fromRGB(15, 20, 30), 0)

DecompileTopBarFix = Instance.new("Frame")
DecompileTopBarFix.Size = UDim2.new(1, 0, 0, 10)
DecompileTopBarFix.Position = UDim2.new(0, 0, 1, -10)
DecompileTopBarFix.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
DecompileTopBarFix.BorderSizePixel = 0
DecompileTopBarFix.Parent = DecompileTopBar

addAccentLine(DecompileTopBar, UDim2.new(0, 0, 1, -1), Color3.fromRGB(40, 100, 160))

DecompileTitle = Instance.new("TextLabel")
DecompileTitle.Size = UDim2.new(1, -80, 1, 0)
DecompileTitle.Position = UDim2.new(0, 10, 0, 0)
DecompileTitle.BackgroundTransparency = 1
DecompileTitle.Text = "📜 Decompile Results"
DecompileTitle.TextColor3 = Color3.fromRGB(80, 160, 220)
DecompileTitle.TextSize = 12
DecompileTitle.Font = Enum.Font.GothamBold
DecompileTitle.TextXAlignment = Enum.TextXAlignment.Left
DecompileTitle.Parent = DecompileTopBar

DecompileCloseBtn = Instance.new("TextButton")
DecompileCloseBtn.Size = UDim2.new(0, 20, 0, 20)
DecompileCloseBtn.Position = UDim2.new(1, -26, 0, 6)
DecompileCloseBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 160)
DecompileCloseBtn.Text = "X"
DecompileCloseBtn.TextColor3 = Colors.text
DecompileCloseBtn.TextSize = 11
DecompileCloseBtn.Font = Enum.Font.GothamBold
DecompileCloseBtn.AutoButtonColor = false
DecompileCloseBtn.Parent = DecompileTopBar
Instance.new("UICorner", DecompileCloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(DecompileCloseBtn, Color3.fromRGB(40, 100, 160), Color3.fromRGB(60, 140, 200))

-- Copy button
DecompileCopyBtn = Instance.new("TextButton")
DecompileCopyBtn.Size = UDim2.new(0, 20, 0, 20)
DecompileCopyBtn.Position = UDim2.new(1, -50, 0, 6)
DecompileCopyBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 60)
DecompileCopyBtn.Text = "📋"
DecompileCopyBtn.TextColor3 = Colors.text
DecompileCopyBtn.TextSize = 10
DecompileCopyBtn.Font = Enum.Font.GothamBold
DecompileCopyBtn.AutoButtonColor = false
DecompileCopyBtn.Parent = DecompileTopBar
Instance.new("UICorner", DecompileCopyBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(DecompileCopyBtn, Color3.fromRGB(30, 80, 60), Color3.fromRGB(40, 120, 90))

-- Status label
DecompileStatusLabel = Instance.new("TextLabel")
DecompileStatusLabel.Size = UDim2.new(1, -20, 0, 14)
DecompileStatusLabel.Position = UDim2.new(0, 10, 0, 36)
DecompileStatusLabel.BackgroundTransparency = 1
DecompileStatusLabel.Text = "Searching..."
DecompileStatusLabel.TextColor3 = Colors.textDim
DecompileStatusLabel.TextSize = 9
DecompileStatusLabel.Font = Enum.Font.Code
DecompileStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
DecompileStatusLabel.Parent = DecompilePanel

-- Code scroll area (fundo estilo terminal)
DecompileCodeScroll = Instance.new("ScrollingFrame")
DecompileCodeScroll.Size = UDim2.new(1, -20, 1, -58)
DecompileCodeScroll.Position = UDim2.new(0, 10, 0, 54)
DecompileCodeScroll.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
DecompileCodeScroll.BorderSizePixel = 0
DecompileCodeScroll.ScrollBarThickness = 4
DecompileCodeScroll.ScrollBarImageColor3 = Color3.fromRGB(40, 100, 160)
DecompileCodeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
DecompileCodeScroll.Parent = DecompilePanel
Instance.new("UICorner", DecompileCodeScroll).CornerRadius = UDim.new(0, 6)

DecompileCodeLayout = Instance.new("UIListLayout")
DecompileCodeLayout.Padding = UDim.new(0, 0)
DecompileCodeLayout.Parent = DecompileCodeScroll

DecompileCodePad = Instance.new("UIPadding", DecompileCodeScroll)
DecompileCodePad.PaddingTop = UDim.new(0, 4)
DecompileCodePad.PaddingLeft = UDim.new(0, 6)
DecompileCodePad.PaddingRight = UDim.new(0, 4)

-- Texto do decompile guardado aqui para copy
decompileResultText = ""

-- Função para popular o painel
showDecompileResults = function(remoteName, results, checked)
    -- Limpa
    for _, c in pairs(DecompileCodeScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end

    local lineCount = 0

    local function addLine(text, color, bold)
        lineCount = lineCount + 1
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -4, 0, 13)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or Color3.fromRGB(160, 170, 180)
        lbl.TextSize = 9
        lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.LayoutOrder = lineCount
        lbl.Parent = DecompileCodeScroll
    end

    if #results == 0 then
        addLine("No scripts reference '" .. remoteName .. "'", Color3.fromRGB(200, 100, 60), true)
        DecompileStatusLabel.Text = "No results — checked " .. checked .. " scripts"
        DecompileStatusLabel.TextColor3 = Color3.fromRGB(200, 100, 60)
    else
        DecompileStatusLabel.Text = "Found in " .. #results .. " scripts — " .. checked .. " checked"
        DecompileStatusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)

        -- Monta texto para copy
        local copyLines = {"-- Decompile: " .. remoteName, ""}
        for _, f in ipairs(results) do
            addLine("═══ " .. f.script .. " ═══", Color3.fromRGB(80, 160, 220), true)
            table.insert(copyLines, "-- ═══ " .. f.script .. " ═══")
            addLine("", nil, false)
            for _, l in ipairs(f.lines) do
                -- ▶ = linha do match (highlight amarelo), resto = contexto (cinza)
                local isMatch = l:sub(1, 3) == "▶" or l:find("▶") == 1
                local color = isMatch and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(140, 160, 140)
                addLine(l, color, isMatch)
                table.insert(copyLines, l)
            end
            addLine("", nil, false)
            table.insert(copyLines, "")
        end
        decompileResultText = table.concat(copyLines, "\n")
    end

    DecompileCodeScroll.CanvasSize = UDim2.new(0, 0, 0, lineCount * 13)
    DecompileTitle.Text = "📜 Decompile: " .. remoteName
    DecompilePanel.Visible = true
end


--[[ ═══════ MODULE: 09e_chatspy_panel.luau ═══════ ]]

--==================================================
-- CHAT SPY PANEL — FLOATING
-- Espiona mensagens do chat em tempo real
-- Todas as variaveis sao GLOBALS para nao gastar locals
--==================================================

ChatSpyPanel = Instance.new("Frame")
ChatSpyPanel.Name = "ChatSpyPanel"
ChatSpyPanel.Size = UDim2.new(0, 260, 0, 420)
ChatSpyPanel.Position = UDim2.new(0.5, 160, 0.5, -210)
ChatSpyPanel.BackgroundColor3 = Colors.bg
ChatSpyPanel.BorderSizePixel = 0
ChatSpyPanel.Visible = false
ChatSpyPanel.Parent = ScreenGui

Instance.new("UICorner", ChatSpyPanel).CornerRadius = UDim.new(0, 10)
ChatSpyPanelStroke = Instance.new("UIStroke", ChatSpyPanel)
ChatSpyPanelStroke.Color = Color3.fromRGB(40, 180, 60)
ChatSpyPanelStroke.Thickness = 1.5
addGradient(ChatSpyPanel, Colors.surfaceLight, Color3.fromRGB(6, 10, 6), 90)

--==================================================
-- TOP BAR
--==================================================

ChatSpyTopBar = Instance.new("Frame")
ChatSpyTopBar.Size = UDim2.new(1, 0, 0, 32)
ChatSpyTopBar.BackgroundColor3 = Colors.topbar
ChatSpyTopBar.BorderSizePixel = 0
ChatSpyTopBar.Parent = ChatSpyPanel
Instance.new("UICorner", ChatSpyTopBar).CornerRadius = UDim.new(0, 10)
addGradient(ChatSpyTopBar, Color3.fromRGB(8, 28, 8), Colors.topbar, 0)

-- Fix bottom corners
ChatSpyTopBarFix = Instance.new("Frame")
ChatSpyTopBarFix.Size = UDim2.new(1, 0, 0, 10)
ChatSpyTopBarFix.Position = UDim2.new(0, 0, 1, -10)
ChatSpyTopBarFix.BackgroundColor3 = Colors.topbar
ChatSpyTopBarFix.BorderSizePixel = 0
ChatSpyTopBarFix.Parent = ChatSpyTopBar

addAccentLine(ChatSpyTopBar, UDim2.new(0, 0, 1, -1), Color3.fromRGB(40, 180, 60))

ChatSpyTitle = Instance.new("TextLabel")
ChatSpyTitle.Size = UDim2.new(1, -40, 1, 0)
ChatSpyTitle.Position = UDim2.new(0, 10, 0, 0)
ChatSpyTitle.BackgroundTransparency = 1
ChatSpyTitle.Text = "💬 Chat Spy"
ChatSpyTitle.TextColor3 = Color3.fromRGB(80, 220, 100)
ChatSpyTitle.TextSize = 12
ChatSpyTitle.Font = Enum.Font.GothamBold
ChatSpyTitle.TextXAlignment = Enum.TextXAlignment.Left
ChatSpyTitle.Parent = ChatSpyTopBar

-- Close X
ChatSpyCloseX = Instance.new("TextButton")
ChatSpyCloseX.Size = UDim2.new(0, 20, 0, 20)
ChatSpyCloseX.Position = UDim2.new(1, -26, 0, 6)
ChatSpyCloseX.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
ChatSpyCloseX.Text = "X"
ChatSpyCloseX.TextColor3 = Colors.text
ChatSpyCloseX.TextSize = 11
ChatSpyCloseX.Font = Enum.Font.GothamBold
ChatSpyCloseX.AutoButtonColor = false
ChatSpyCloseX.Parent = ChatSpyTopBar
Instance.new("UICorner", ChatSpyCloseX).CornerRadius = UDim.new(0, 6)
makeHoverable(ChatSpyCloseX, Color3.fromRGB(40, 140, 40), Color3.fromRGB(60, 180, 60))

--==================================================
-- TOGGLE SPY BUTTON
--==================================================

ChatSpyToggleBtn = Instance.new("TextButton")
ChatSpyToggleBtn.Size = UDim2.new(1, -20, 0, 28)
ChatSpyToggleBtn.Position = UDim2.new(0, 10, 0, 40)
ChatSpyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
ChatSpyToggleBtn.Text = "🕵 START SPY"
ChatSpyToggleBtn.TextColor3 = Colors.text
ChatSpyToggleBtn.TextSize = 11
ChatSpyToggleBtn.Font = Enum.Font.GothamBold
ChatSpyToggleBtn.AutoButtonColor = false
ChatSpyToggleBtn.Parent = ChatSpyPanel
Instance.new("UICorner", ChatSpyToggleBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ChatSpyToggleBtn)
makeHoverable(ChatSpyToggleBtn, Color3.fromRGB(40, 140, 40), Color3.fromRGB(60, 180, 60))

--==================================================
-- STATUS + FILTER
--==================================================

ChatSpyStatusLabel = Instance.new("TextLabel")
ChatSpyStatusLabel.Size = UDim2.new(1, -20, 0, 14)
ChatSpyStatusLabel.Position = UDim2.new(0, 10, 0, 72)
ChatSpyStatusLabel.BackgroundTransparency = 1
ChatSpyStatusLabel.Text = "Spy: OFF"
ChatSpyStatusLabel.TextColor3 = Colors.textDim
ChatSpyStatusLabel.TextSize = 10
ChatSpyStatusLabel.Font = Enum.Font.GothamBold
ChatSpyStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
ChatSpyStatusLabel.Parent = ChatSpyPanel

ChatSpyFilterBox = Instance.new("TextBox")
ChatSpyFilterBox.Size = UDim2.new(1, -20, 0, 22)
ChatSpyFilterBox.Position = UDim2.new(0, 10, 0, 90)
ChatSpyFilterBox.BackgroundColor3 = Colors.inputBg
ChatSpyFilterBox.Text = ""
ChatSpyFilterBox.PlaceholderText = "Filter messages..."
ChatSpyFilterBox.PlaceholderColor3 = Colors.textDim
ChatSpyFilterBox.TextColor3 = Colors.text
ChatSpyFilterBox.TextSize = 10
ChatSpyFilterBox.Font = Enum.Font.Code
ChatSpyFilterBox.TextXAlignment = Enum.TextXAlignment.Left
ChatSpyFilterBox.ClearTextOnFocus = false
ChatSpyFilterBox.Parent = ChatSpyPanel
Instance.new("UICorner", ChatSpyFilterBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", ChatSpyFilterBox).PaddingLeft = UDim.new(0, 6)
ChatSpyFilterStroke = Instance.new("UIStroke", ChatSpyFilterBox)
ChatSpyFilterStroke.Color = Colors.separator
ChatSpyFilterStroke.Thickness = 0.5

--==================================================
-- LOG SCROLL
--==================================================

addAccentLine(ChatSpyPanel, UDim2.new(0, 10, 0, 116), Color3.fromRGB(40, 180, 60), UDim2.new(1, -20, 0, 1))

ChatSpyLogScroll = Instance.new("ScrollingFrame")
ChatSpyLogScroll.Size = UDim2.new(1, -20, 0, 236)
ChatSpyLogScroll.Position = UDim2.new(0, 10, 0, 120)
ChatSpyLogScroll.BackgroundColor3 = Colors.content
ChatSpyLogScroll.BorderSizePixel = 0
ChatSpyLogScroll.ScrollBarThickness = 3
ChatSpyLogScroll.ScrollBarImageColor3 = Color3.fromRGB(40, 180, 60)
ChatSpyLogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatSpyLogScroll.Parent = ChatSpyPanel
Instance.new("UICorner", ChatSpyLogScroll).CornerRadius = UDim.new(0, 6)
ChatSpyLogStroke = Instance.new("UIStroke", ChatSpyLogScroll)
ChatSpyLogStroke.Color = Colors.separator
ChatSpyLogStroke.Thickness = 0.5
ChatSpyLogStroke.Transparency = 0.5

ChatSpyLogLayout = Instance.new("UIListLayout")
ChatSpyLogLayout.Padding = UDim.new(0, 2)
ChatSpyLogLayout.Parent = ChatSpyLogScroll
ChatSpyLogPad = Instance.new("UIPadding", ChatSpyLogScroll)
ChatSpyLogPad.PaddingTop = UDim.new(0, 4)
ChatSpyLogPad.PaddingLeft = UDim.new(0, 4)

--==================================================
-- BOTTOM BUTTONS
--==================================================

ChatSpyClearBtn = Instance.new("TextButton")
ChatSpyClearBtn.Size = UDim2.new(1, -20, 0, 24)
ChatSpyClearBtn.Position = UDim2.new(0, 10, 0, 364)
ChatSpyClearBtn.BackgroundColor3 = Colors.warning
ChatSpyClearBtn.Text = "🗑 CLEAR LOG"
ChatSpyClearBtn.TextColor3 = Colors.bg
ChatSpyClearBtn.TextSize = 11
ChatSpyClearBtn.Font = Enum.Font.GothamBold
ChatSpyClearBtn.AutoButtonColor = false
ChatSpyClearBtn.Parent = ChatSpyPanel
Instance.new("UICorner", ChatSpyClearBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(ChatSpyClearBtn, Colors.warning, Color3.fromRGB(230, 180, 60))

ChatSpyCloseBtn = Instance.new("TextButton")
ChatSpyCloseBtn.Size = UDim2.new(1, -20, 0, 24)
ChatSpyCloseBtn.Position = UDim2.new(0, 10, 0, 392)
ChatSpyCloseBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
ChatSpyCloseBtn.Text = "🔴 CLOSE"
ChatSpyCloseBtn.TextColor3 = Colors.text
ChatSpyCloseBtn.TextSize = 11
ChatSpyCloseBtn.Font = Enum.Font.GothamBold
ChatSpyCloseBtn.AutoButtonColor = false
ChatSpyCloseBtn.Parent = ChatSpyPanel
Instance.new("UICorner", ChatSpyCloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(ChatSpyCloseBtn, Color3.fromRGB(40, 100, 40), Color3.fromRGB(60, 140, 60))

--==================================================
-- REFRESH LOG FUNCTION
--==================================================

refreshChatSpyLog = function(filterText)
    for _, child in ipairs(ChatSpyLogScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    local filter = filterText or ChatSpyFilterBox.Text
    filter = filter:lower()
    local count = 0

    for i = #chatSpyLog, 1, -1 do
        local entry = chatSpyLog[i]
        local text = entry.player .. ": " .. entry.message

        local match = true
        if filter ~= "" then
            if not text:lower():find(filter, 1, true) then
                match = false
            end
        end

        if match then
            local timeStr = os.date("%H:%M:%S", entry.time)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -8, 0, 16)
            lbl.BackgroundTransparency = 1
            lbl.Text = "[" .. timeStr .. "] " .. entry.player .. ": " .. entry.message
            lbl.TextColor3 = Colors.text
            lbl.TextSize = 9
            lbl.Font = Enum.Font.Code
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.Parent = ChatSpyLogScroll
            count = count + 1
        end
    end

    ChatSpyLogScroll.CanvasSize = UDim2.new(0, 0, 0, count * 18)
end

--==================================================
-- OPEN FUNCTION
--==================================================

openChatSpyPanel = function()
    ChatSpyPanel.Visible = true
    refreshChatSpyLog()
end


--[[ ═══════ MODULE: 09f_tab_games.luau ═══════ ]]

--==================================================
-- TAB: GAMES
--==================================================

GamesContent = Instance.new("Frame")
GamesContent.Name = "GamesContent"
GamesContent.Size = UDim2.new(1, 0, 1, 0)
GamesContent.BackgroundTransparency = 1
GamesContent.Visible = false
GamesContent.Parent = TabContent
tabContents["games"] = GamesContent

-- Scroll container
GamesScroll = Instance.new("ScrollingFrame")
GamesScroll.Size = UDim2.new(1, 0, 1, 0)
GamesScroll.BackgroundTransparency = 1
GamesScroll.ScrollBarThickness = 3
GamesScroll.ScrollBarImageColor3 = Colors.blood
GamesScroll.CanvasSize = UDim2.new(0, 0, 0, 360)
GamesScroll.BorderSizePixel = 0
GamesScroll.Parent = GamesContent

GamesScrollLayout = Instance.new("UIListLayout", GamesScroll)
GamesScrollLayout.Padding = UDim.new(0, 6)

GamesScrollPad = Instance.new("UIPadding", GamesScroll)
GamesScrollPad.PaddingTop = UDim.new(0, 8)
GamesScrollPad.PaddingLeft = UDim.new(0, 8)
GamesScrollPad.PaddingRight = UDim.new(0, 8)

-- Header
GamesHeaderLabel = Instance.new("TextLabel")
GamesHeaderLabel.Size = UDim2.new(1, 0, 0, 18)
GamesHeaderLabel.BackgroundTransparency = 1
GamesHeaderLabel.Text = "🎮 Game-Specific Exploits"
GamesHeaderLabel.TextColor3 = Colors.text
GamesHeaderLabel.TextSize = 13
GamesHeaderLabel.Font = Enum.Font.GothamBold
GamesHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
GamesHeaderLabel.Parent = GamesScroll

GamesDescLabel = Instance.new("TextLabel")
GamesDescLabel.Size = UDim2.new(1, 0, 0, 12)
GamesDescLabel.BackgroundTransparency = 1
GamesDescLabel.Text = "Select a game to open its exploit panel"
GamesDescLabel.TextColor3 = Colors.textDim
GamesDescLabel.TextSize = 9
GamesDescLabel.Font = Enum.Font.Gotham
GamesDescLabel.TextXAlignment = Enum.TextXAlignment.Left
GamesDescLabel.Parent = GamesScroll

-- ═══ GAME CARD: DEATH BALL ═══
DeathBallCard = Instance.new("TextButton")
DeathBallCard.Size = UDim2.new(1, 0, 0, 54)
DeathBallCard.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
DeathBallCard.Text = ""
DeathBallCard.AutoButtonColor = false
DeathBallCard.Parent = GamesScroll
Instance.new("UICorner", DeathBallCard).CornerRadius = UDim.new(0, 8)
addBtnGradient(DeathBallCard)

DeathBallCardStroke = Instance.new("UIStroke", DeathBallCard)
DeathBallCardStroke.Color = Color3.fromRGB(200, 60, 60)
DeathBallCardStroke.Thickness = 1

DeathBallCardIcon = Instance.new("TextLabel")
DeathBallCardIcon.Size = UDim2.new(0, 40, 0, 40)
DeathBallCardIcon.Position = UDim2.new(0, 8, 0, 7)
DeathBallCardIcon.BackgroundTransparency = 1
DeathBallCardIcon.Text = "⚽"
DeathBallCardIcon.TextSize = 24
DeathBallCardIcon.Parent = DeathBallCard

DeathBallCardTitle = Instance.new("TextLabel")
DeathBallCardTitle.Size = UDim2.new(1, -60, 0, 18)
DeathBallCardTitle.Position = UDim2.new(0, 52, 0, 6)
DeathBallCardTitle.BackgroundTransparency = 1
DeathBallCardTitle.Text = "Death Ball (Test)"
DeathBallCardTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
DeathBallCardTitle.TextSize = 13
DeathBallCardTitle.Font = Enum.Font.GothamBold
DeathBallCardTitle.TextXAlignment = Enum.TextXAlignment.Left
DeathBallCardTitle.Parent = DeathBallCard

DeathBallCardDesc = Instance.new("TextLabel")
DeathBallCardDesc.Size = UDim2.new(1, -60, 0, 12)
DeathBallCardDesc.Position = UDim2.new(0, 52, 0, 26)
DeathBallCardDesc.BackgroundTransparency = 1
DeathBallCardDesc.Text = "Auto-Rebater • ESP • Dodge • Prediction • Kill Feed"
DeathBallCardDesc.TextColor3 = Colors.textDim
DeathBallCardDesc.TextSize = 9
DeathBallCardDesc.Font = Enum.Font.Gotham
DeathBallCardDesc.TextXAlignment = Enum.TextXAlignment.Left
DeathBallCardDesc.Parent = DeathBallCard

DeathBallCardArrow = Instance.new("TextLabel")
DeathBallCardArrow.Size = UDim2.new(0, 20, 1, 0)
DeathBallCardArrow.Position = UDim2.new(1, -24, 0, 0)
DeathBallCardArrow.BackgroundTransparency = 1
DeathBallCardArrow.Text = "▸"
DeathBallCardArrow.TextColor3 = Color3.fromRGB(200, 60, 60)
DeathBallCardArrow.TextSize = 16
DeathBallCardArrow.Font = Enum.Font.GothamBold
DeathBallCardArrow.Parent = DeathBallCard

makeHoverable(DeathBallCard, Color3.fromRGB(20, 20, 30), Color3.fromRGB(35, 20, 25))

--==================================================
-- DEATH BALL PANEL — FLOATING (v2 FULL FEATURES)
--==================================================

DeathBallPanel = Instance.new("Frame")
DeathBallPanel.Name = "DeathBallPanel"
DeathBallPanel.Size = UDim2.new(0, 280, 0, 870)
DeathBallPanel.Position = UDim2.new(0.5, -140, 0.5, -420)
DeathBallPanel.BackgroundColor3 = Color3.fromRGB(14, 10, 14)
DeathBallPanel.BorderSizePixel = 0
DeathBallPanel.Visible = false
DeathBallPanel.Parent = ScreenGui
Instance.new("UICorner", DeathBallPanel).CornerRadius = UDim.new(0, 10)

DeathBallPanelStroke = Instance.new("UIStroke", DeathBallPanel)
DeathBallPanelStroke.Color = Color3.fromRGB(200, 60, 60)
DeathBallPanelStroke.Thickness = 1.5
addGradient(DeathBallPanel, Color3.fromRGB(18, 10, 14), Color3.fromRGB(8, 6, 10), 90)

-- Top Bar
DeathBallTopBar = Instance.new("Frame")
DeathBallTopBar.Size = UDim2.new(1, 0, 0, 32)
DeathBallTopBar.BackgroundColor3 = Color3.fromRGB(30, 12, 18)
DeathBallTopBar.BorderSizePixel = 0
DeathBallTopBar.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallTopBar).CornerRadius = UDim.new(0, 10)
addGradient(DeathBallTopBar, Color3.fromRGB(35, 12, 18), Color3.fromRGB(20, 8, 12), 0)

DeathBallTopBarFix = Instance.new("Frame")
DeathBallTopBarFix.Size = UDim2.new(1, 0, 0, 10)
DeathBallTopBarFix.Position = UDim2.new(0, 0, 1, -10)
DeathBallTopBarFix.BackgroundColor3 = Color3.fromRGB(30, 12, 18)
DeathBallTopBarFix.BorderSizePixel = 0
DeathBallTopBarFix.Parent = DeathBallTopBar

addAccentLine(DeathBallTopBar, UDim2.new(0, 0, 1, -1), Color3.fromRGB(200, 60, 60))

DeathBallTitleLabel = Instance.new("TextLabel")
DeathBallTitleLabel.Size = UDim2.new(1, -40, 1, 0)
DeathBallTitleLabel.Position = UDim2.new(0, 10, 0, 0)
DeathBallTitleLabel.BackgroundTransparency = 1
DeathBallTitleLabel.Text = "⚽ Death Ball v3 AUTO"
DeathBallTitleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
DeathBallTitleLabel.TextSize = 12
DeathBallTitleLabel.Font = Enum.Font.GothamBold
DeathBallTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallTitleLabel.Parent = DeathBallTopBar

DeathBallCloseBtn = Instance.new("TextButton")
DeathBallCloseBtn.Size = UDim2.new(0, 20, 0, 20)
DeathBallCloseBtn.Position = UDim2.new(1, -26, 0, 6)
DeathBallCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
DeathBallCloseBtn.Text = "X"
DeathBallCloseBtn.TextColor3 = Colors.text
DeathBallCloseBtn.TextSize = 11
DeathBallCloseBtn.Font = Enum.Font.GothamBold
DeathBallCloseBtn.AutoButtonColor = false
DeathBallCloseBtn.Parent = DeathBallTopBar
Instance.new("UICorner", DeathBallCloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(DeathBallCloseBtn, Color3.fromRGB(200, 60, 60), Color3.fromRGB(240, 80, 80))

-- ═══ AUTO-PLAY TOGGLE (botão principal) ═══
DeathBallAutoBtn = Instance.new("TextButton")
DeathBallAutoBtn.Size = UDim2.new(1, -20, 0, 38)
DeathBallAutoBtn.Position = UDim2.new(0, 10, 0, 40)
DeathBallAutoBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
DeathBallAutoBtn.Text = "⚡ AUTO-PLAY: OFF"
DeathBallAutoBtn.TextColor3 = Colors.text
DeathBallAutoBtn.TextSize = 13
DeathBallAutoBtn.Font = Enum.Font.GothamBold
DeathBallAutoBtn.AutoButtonColor = false
DeathBallAutoBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallAutoBtn).CornerRadius = UDim.new(0, 8)
addBtnGradient(DeathBallAutoBtn)
makeHoverable(DeathBallAutoBtn, Color3.fromRGB(40, 20, 20), Color3.fromRGB(60, 30, 30))

-- ═══ ROW 1: AUTO-DETECT + ESP ═══
DeathBallAutoDetectBtn = Instance.new("TextButton")
DeathBallAutoDetectBtn.Size = UDim2.new(0.48, -5, 0, 26)
DeathBallAutoDetectBtn.Position = UDim2.new(0, 10, 0, 84)
DeathBallAutoDetectBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
DeathBallAutoDetectBtn.Text = "AUTO-DETECT: ON"
DeathBallAutoDetectBtn.TextColor3 = Colors.text
DeathBallAutoDetectBtn.TextSize = 9
DeathBallAutoDetectBtn.Font = Enum.Font.GothamBold
DeathBallAutoDetectBtn.AutoButtonColor = false
DeathBallAutoDetectBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallAutoDetectBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(DeathBallAutoDetectBtn)
makeHoverable(DeathBallAutoDetectBtn, Color3.fromRGB(40, 140, 60), Color3.fromRGB(60, 180, 80))

DeathBallEspBtn = Instance.new("TextButton")
DeathBallEspBtn.Size = UDim2.new(0.48, -5, 0, 26)
DeathBallEspBtn.Position = UDim2.new(0.52, 0, 0, 84)
DeathBallEspBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
DeathBallEspBtn.Text = "ESP: OFF"
DeathBallEspBtn.TextColor3 = Colors.text
DeathBallEspBtn.TextSize = 9
DeathBallEspBtn.Font = Enum.Font.GothamBold
DeathBallEspBtn.AutoButtonColor = false
DeathBallEspBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallEspBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(DeathBallEspBtn)
makeHoverable(DeathBallEspBtn, Color3.fromRGB(30, 30, 50), Color3.fromRGB(50, 50, 80))

-- ═══ ROW 2: DODGE + DEBUG ═══
DeathBallDodgeBtn = Instance.new("TextButton")
DeathBallDodgeBtn.Size = UDim2.new(0.48, -5, 0, 26)
DeathBallDodgeBtn.Position = UDim2.new(0, 10, 0, 114)
DeathBallDodgeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
DeathBallDodgeBtn.Text = "DODGE: OFF"
DeathBallDodgeBtn.TextColor3 = Colors.text
DeathBallDodgeBtn.TextSize = 9
DeathBallDodgeBtn.Font = Enum.Font.GothamBold
DeathBallDodgeBtn.AutoButtonColor = false
DeathBallDodgeBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallDodgeBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(DeathBallDodgeBtn)
makeHoverable(DeathBallDodgeBtn, Color3.fromRGB(30, 30, 50), Color3.fromRGB(50, 50, 80))

DeathBallDebugBtn = Instance.new("TextButton")
DeathBallDebugBtn.Size = UDim2.new(0.48, -5, 0, 26)
DeathBallDebugBtn.Position = UDim2.new(0.52, 0, 0, 114)
DeathBallDebugBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
DeathBallDebugBtn.Text = "DEBUG: OFF"
DeathBallDebugBtn.TextColor3 = Colors.text
DeathBallDebugBtn.TextSize = 9
DeathBallDebugBtn.Font = Enum.Font.GothamBold
DeathBallDebugBtn.AutoButtonColor = false
DeathBallDebugBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallDebugBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(DeathBallDebugBtn)
makeHoverable(DeathBallDebugBtn, Color3.fromRGB(30, 30, 50), Color3.fromRGB(50, 50, 80))

-- ═══ SETTINGS ROW 1: RANGE + COOLDOWN ═══
DeathBallRangeLabel = Instance.new("TextLabel")
DeathBallRangeLabel.Size = UDim2.new(0, 50, 0, 20)
DeathBallRangeLabel.Position = UDim2.new(0, 10, 0, 148)
DeathBallRangeLabel.BackgroundTransparency = 1
DeathBallRangeLabel.Text = "Range:"
DeathBallRangeLabel.TextColor3 = Colors.textDim
DeathBallRangeLabel.TextSize = 9
DeathBallRangeLabel.Font = Enum.Font.GothamBold
DeathBallRangeLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallRangeLabel.Parent = DeathBallPanel

DeathBallRangeBox = Instance.new("TextBox")
DeathBallRangeBox.Size = UDim2.new(0, 40, 0, 20)
DeathBallRangeBox.Position = UDim2.new(0, 58, 0, 148)
DeathBallRangeBox.BackgroundColor3 = Colors.inputBg
DeathBallRangeBox.Text = "5"
DeathBallRangeBox.PlaceholderText = "studs"
DeathBallRangeBox.PlaceholderColor3 = Colors.textDim
DeathBallRangeBox.TextColor3 = Colors.text
DeathBallRangeBox.TextSize = 10
DeathBallRangeBox.Font = Enum.Font.Code
DeathBallRangeBox.ClearTextOnFocus = false
DeathBallRangeBox.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallRangeBox).CornerRadius = UDim.new(0, 4)

DeathBallCooldownLabel = Instance.new("TextLabel")
DeathBallCooldownLabel.Size = UDim2.new(0, 60, 0, 20)
DeathBallCooldownLabel.Position = UDim2.new(0.5, -20, 0, 148)
DeathBallCooldownLabel.BackgroundTransparency = 1
DeathBallCooldownLabel.Text = "Cooldown:"
DeathBallCooldownLabel.TextColor3 = Colors.textDim
DeathBallCooldownLabel.TextSize = 9
DeathBallCooldownLabel.Font = Enum.Font.GothamBold
DeathBallCooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallCooldownLabel.Parent = DeathBallPanel

DeathBallCooldownBox = Instance.new("TextBox")
DeathBallCooldownBox.Size = UDim2.new(0, 40, 0, 20)
DeathBallCooldownBox.Position = UDim2.new(0.5, 42, 0, 148)
DeathBallCooldownBox.BackgroundColor3 = Colors.inputBg
DeathBallCooldownBox.Text = "0.2"
DeathBallCooldownBox.PlaceholderText = "sec"
DeathBallCooldownBox.PlaceholderColor3 = Colors.textDim
DeathBallCooldownBox.TextColor3 = Colors.text
DeathBallCooldownBox.TextSize = 10
DeathBallCooldownBox.Font = Enum.Font.Code
DeathBallCooldownBox.ClearTextOnFocus = false
DeathBallCooldownBox.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallCooldownBox).CornerRadius = UDim.new(0, 4)

-- ═══ SETTINGS ROW 2: BALL NAME (usado quando auto-detect OFF) ═══
DeathBallNameLabel = Instance.new("TextLabel")
DeathBallNameLabel.Size = UDim2.new(0, 80, 0, 20)
DeathBallNameLabel.Position = UDim2.new(0, 10, 0, 174)
DeathBallNameLabel.BackgroundTransparency = 1
DeathBallNameLabel.Text = "Ball Name:"
DeathBallNameLabel.TextColor3 = Colors.textDim
DeathBallNameLabel.TextSize = 9
DeathBallNameLabel.Font = Enum.Font.GothamBold
DeathBallNameLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallNameLabel.Parent = DeathBallPanel

DeathBallNameBox = Instance.new("TextBox")
DeathBallNameBox.Size = UDim2.new(1, -100, 0, 20)
DeathBallNameBox.Position = UDim2.new(0, 90, 0, 174)
DeathBallNameBox.BackgroundColor3 = Colors.inputBg
DeathBallNameBox.Text = "Ball"
DeathBallNameBox.PlaceholderText = "only if auto-detect OFF"
DeathBallNameBox.PlaceholderColor3 = Colors.textDim
DeathBallNameBox.TextColor3 = Colors.text
DeathBallNameBox.TextSize = 10
DeathBallNameBox.Font = Enum.Font.Code
DeathBallNameBox.ClearTextOnFocus = false
DeathBallNameBox.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallNameBox).CornerRadius = UDim.new(0, 4)

-- ═══ SEPARATOR 1 ═══
addAccentLine(DeathBallPanel, UDim2.new(0, 10, 0, 200), Color3.fromRGB(200, 60, 60), UDim2.new(1, -20, 0, 1))

-- ═══ STATUS & INFO ═══
DeathBallStatusLabel = Instance.new("TextLabel")
DeathBallStatusLabel.Size = UDim2.new(1, -20, 0, 14)
DeathBallStatusLabel.Position = UDim2.new(0, 10, 0, 208)
DeathBallStatusLabel.BackgroundTransparency = 1
DeathBallStatusLabel.Text = "Status: Idle — press AUTO-PLAY to start"
DeathBallStatusLabel.TextColor3 = Colors.textDim
DeathBallStatusLabel.TextSize = 9
DeathBallStatusLabel.Font = Enum.Font.Code
DeathBallStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallStatusLabel.Parent = DeathBallPanel

DeathBallBallInfo = Instance.new("TextLabel")
DeathBallBallInfo.Size = UDim2.new(1, -20, 0, 14)
DeathBallBallInfo.Position = UDim2.new(0, 10, 0, 224)
DeathBallBallInfo.BackgroundTransparency = 1
DeathBallBallInfo.Text = "Balls: --"
DeathBallBallInfo.TextColor3 = Colors.textDim
DeathBallBallInfo.TextSize = 9
DeathBallBallInfo.Font = Enum.Font.Code
DeathBallBallInfo.TextXAlignment = Enum.TextXAlignment.Left
DeathBallBallInfo.Parent = DeathBallPanel

DeathBallDistInfo = Instance.new("TextLabel")
DeathBallDistInfo.Size = UDim2.new(1, -20, 0, 14)
DeathBallDistInfo.Position = UDim2.new(0, 10, 0, 240)
DeathBallDistInfo.BackgroundTransparency = 1
DeathBallDistInfo.Text = "Distance: --"
DeathBallDistInfo.TextColor3 = Colors.textDim
DeathBallDistInfo.TextSize = 9
DeathBallDistInfo.Font = Enum.Font.Code
DeathBallDistInfo.TextXAlignment = Enum.TextXAlignment.Left
DeathBallDistInfo.Parent = DeathBallPanel

DeathBallColorInfo = Instance.new("TextLabel")
DeathBallColorInfo.Size = UDim2.new(1, -20, 0, 14)
DeathBallColorInfo.Position = UDim2.new(0, 10, 0, 256)
DeathBallColorInfo.BackgroundTransparency = 1
DeathBallColorInfo.Text = "Method: none"
DeathBallColorInfo.TextColor3 = Colors.textDim
DeathBallColorInfo.TextSize = 9
DeathBallColorInfo.Font = Enum.Font.Code
DeathBallColorInfo.TextXAlignment = Enum.TextXAlignment.Left
DeathBallColorInfo.Parent = DeathBallPanel

DeathBallVelInfo = Instance.new("TextLabel")
DeathBallVelInfo.Size = UDim2.new(1, -20, 0, 14)
DeathBallVelInfo.Position = UDim2.new(0, 10, 0, 272)
DeathBallVelInfo.BackgroundTransparency = 1
DeathBallVelInfo.Text = "Velocity: --"
DeathBallVelInfo.TextColor3 = Colors.textDim
DeathBallVelInfo.TextSize = 9
DeathBallVelInfo.Font = Enum.Font.Code
DeathBallVelInfo.TextXAlignment = Enum.TextXAlignment.Left
DeathBallVelInfo.Parent = DeathBallPanel

-- ═══ SEPARATOR 2 ═══
addAccentLine(DeathBallPanel, UDim2.new(0, 10, 0, 292), Color3.fromRGB(200, 60, 60), UDim2.new(1, -20, 0, 1))

-- ═══ STATS ═══
DeathBallStatsLabel = Instance.new("TextLabel")
DeathBallStatsLabel.Size = UDim2.new(1, -20, 0, 14)
DeathBallStatsLabel.Position = UDim2.new(0, 10, 0, 298)
DeathBallStatsLabel.BackgroundTransparency = 1
DeathBallStatsLabel.Text = "Rebated: 0 | Missed: 0"
DeathBallStatsLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
DeathBallStatsLabel.TextSize = 10
DeathBallStatsLabel.Font = Enum.Font.GothamBold
DeathBallStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallStatsLabel.Parent = DeathBallPanel

-- ═══ SCAN BALL BUTTON ═══
DeathBallScanBtn = Instance.new("TextButton")
DeathBallScanBtn.Size = UDim2.new(1, -20, 0, 26)
DeathBallScanBtn.Position = UDim2.new(0, 10, 0, 318)
DeathBallScanBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
DeathBallScanBtn.Text = "SCAN FOR BALLS (manual)"
DeathBallScanBtn.TextColor3 = Colors.text
DeathBallScanBtn.TextSize = 10
DeathBallScanBtn.Font = Enum.Font.GothamBold
DeathBallScanBtn.AutoButtonColor = false
DeathBallScanBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallScanBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(DeathBallScanBtn)
makeHoverable(DeathBallScanBtn, Color3.fromRGB(40, 80, 120), Color3.fromRGB(60, 110, 160))

-- ═══ SEPARATOR 3: OBJECT SCANNER ═══
addAccentLine(DeathBallPanel, UDim2.new(0, 10, 0, 352), Color3.fromRGB(0, 200, 160), UDim2.new(1, -20, 0, 1))

DeathBallScanObjHeader = Instance.new("TextLabel")
DeathBallScanObjHeader.Size = UDim2.new(1, -20, 0, 14)
DeathBallScanObjHeader.Position = UDim2.new(0, 10, 0, 358)
DeathBallScanObjHeader.BackgroundTransparency = 1
DeathBallScanObjHeader.Text = "Object Scanner — find part names"
DeathBallScanObjHeader.TextColor3 = Color3.fromRGB(0, 220, 180)
DeathBallScanObjHeader.TextSize = 9
DeathBallScanObjHeader.Font = Enum.Font.GothamBold
DeathBallScanObjHeader.TextXAlignment = Enum.TextXAlignment.Left
DeathBallScanObjHeader.Parent = DeathBallPanel

-- Scan range + button row
DeathBallScanRangeLabel = Instance.new("TextLabel")
DeathBallScanRangeLabel.Size = UDim2.new(0, 46, 0, 22)
DeathBallScanRangeLabel.Position = UDim2.new(0, 10, 0, 376)
DeathBallScanRangeLabel.BackgroundTransparency = 1
DeathBallScanRangeLabel.Text = "Range:"
DeathBallScanRangeLabel.TextColor3 = Colors.textDim
DeathBallScanRangeLabel.TextSize = 9
DeathBallScanRangeLabel.Font = Enum.Font.GothamBold
DeathBallScanRangeLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallScanRangeLabel.Parent = DeathBallPanel

DeathBallScanRangeBox = Instance.new("TextBox")
DeathBallScanRangeBox.Size = UDim2.new(0, 36, 0, 22)
DeathBallScanRangeBox.Position = UDim2.new(0, 54, 0, 376)
DeathBallScanRangeBox.BackgroundColor3 = Colors.inputBg
DeathBallScanRangeBox.Text = "50"
DeathBallScanRangeBox.PlaceholderText = "studs"
DeathBallScanRangeBox.PlaceholderColor3 = Colors.textDim
DeathBallScanRangeBox.TextColor3 = Colors.text
DeathBallScanRangeBox.TextSize = 10
DeathBallScanRangeBox.Font = Enum.Font.Code
DeathBallScanRangeBox.ClearTextOnFocus = false
DeathBallScanRangeBox.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallScanRangeBox).CornerRadius = UDim.new(0, 4)

DeathBallScanObjBtn = Instance.new("TextButton")
DeathBallScanObjBtn.Size = UDim2.new(1, -110, 0, 22)
DeathBallScanObjBtn.Position = UDim2.new(0, 100, 0, 376)
DeathBallScanObjBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
DeathBallScanObjBtn.Text = "SCAN OBJECTS"
DeathBallScanObjBtn.TextColor3 = Colors.text
DeathBallScanObjBtn.TextSize = 9
DeathBallScanObjBtn.Font = Enum.Font.GothamBold
DeathBallScanObjBtn.AutoButtonColor = false
DeathBallScanObjBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallScanObjBtn).CornerRadius = UDim.new(0, 4)
addBtnGradient(DeathBallScanObjBtn)
makeHoverable(DeathBallScanObjBtn, Color3.fromRGB(40, 80, 120), Color3.fromRGB(60, 110, 160))

-- Results scroll
DeathBallScanResultLabel = Instance.new("TextLabel")
DeathBallScanResultLabel.Size = UDim2.new(1, -20, 0, 90)
DeathBallScanResultLabel.Position = UDim2.new(0, 10, 0, 404)
DeathBallScanResultLabel.BackgroundColor3 = Color3.fromRGB(8, 6, 10)
DeathBallScanResultLabel.BackgroundTransparency = 0.3
DeathBallScanResultLabel.Text = "Click SCAN OBJECTS to see nearby parts\nBillboards show name, class, dist, vel & color"
DeathBallScanResultLabel.TextColor3 = Colors.textDim
DeathBallScanResultLabel.TextSize = 8
DeathBallScanResultLabel.Font = Enum.Font.Code
DeathBallScanResultLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallScanResultLabel.TextYAlignment = Enum.TextYAlignment.Top
DeathBallScanResultLabel.TextWrapped = true
DeathBallScanResultLabel.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallScanResultLabel).CornerRadius = UDim.new(0, 4)

DeathBallScanResultPad = Instance.new("UIPadding", DeathBallScanResultLabel)
DeathBallScanResultPad.PaddingTop = UDim.new(0, 4)
DeathBallScanResultPad.PaddingLeft = UDim.new(0, 4)

-- ═══ SEPARATOR 4: KILL FEED ═══
addAccentLine(DeathBallPanel, UDim2.new(0, 10, 0, 502), Color3.fromRGB(200, 60, 60), UDim2.new(1, -20, 0, 1))

DeathBallKillHeader = Instance.new("TextLabel")
DeathBallKillHeader.Size = UDim2.new(1, -20, 0, 16)
DeathBallKillHeader.Position = UDim2.new(0, 10, 0, 508)
DeathBallKillHeader.BackgroundTransparency = 1
DeathBallKillHeader.Text = "Kill Feed"
DeathBallKillHeader.TextColor3 = Color3.fromRGB(255, 120, 120)
DeathBallKillHeader.TextSize = 10
DeathBallKillHeader.Font = Enum.Font.GothamBold
DeathBallKillHeader.TextXAlignment = Enum.TextXAlignment.Left
DeathBallKillHeader.Parent = DeathBallPanel

DeathBallKillScroll = Instance.new("ScrollingFrame")
DeathBallKillScroll.Size = UDim2.new(1, -20, 0, 70)
DeathBallKillScroll.Position = UDim2.new(0, 10, 0, 526)
DeathBallKillScroll.BackgroundColor3 = Color3.fromRGB(8, 6, 10)
DeathBallKillScroll.BackgroundTransparency = 0.3
DeathBallKillScroll.ScrollBarThickness = 3
DeathBallKillScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 60, 60)
DeathBallKillScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
DeathBallKillScroll.BorderSizePixel = 0
DeathBallKillScroll.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallKillScroll).CornerRadius = UDim.new(0, 4)

DeathBallKillScrollLayout = Instance.new("UIListLayout", DeathBallKillScroll)
DeathBallKillScrollLayout.Padding = UDim.new(0, 2)

DeathBallKillScrollPad = Instance.new("UIPadding", DeathBallKillScroll)
DeathBallKillScrollPad.PaddingTop = UDim.new(0, 4)
DeathBallKillScrollPad.PaddingLeft = UDim.new(0, 4)

DeathBallKillEmpty = Instance.new("TextLabel")
DeathBallKillEmpty.Size = UDim2.new(1, 0, 0, 14)
DeathBallKillEmpty.BackgroundTransparency = 1
DeathBallKillEmpty.Text = "No kills yet..."
DeathBallKillEmpty.TextColor3 = Colors.textDim
DeathBallKillEmpty.TextSize = 9
DeathBallKillEmpty.Font = Enum.Font.Code
DeathBallKillEmpty.TextXAlignment = Enum.TextXAlignment.Left
DeathBallKillEmpty.Parent = DeathBallKillScroll

-- ═══ SEPARATOR 5: AFK BOT SECTION ═══
addAccentLine(DeathBallPanel, UDim2.new(0, 10, 0, 604), Color3.fromRGB(60, 200, 100), UDim2.new(1, -20, 0, 2))

DeathBallBotHeader = Instance.new("TextLabel")
DeathBallBotHeader.Size = UDim2.new(1, -20, 0, 16)
DeathBallBotHeader.Position = UDim2.new(0, 10, 0, 612)
DeathBallBotHeader.BackgroundTransparency = 1
DeathBallBotHeader.Text = "AFK Bot Mode"
DeathBallBotHeader.TextColor3 = Color3.fromRGB(100, 255, 150)
DeathBallBotHeader.TextSize = 11
DeathBallBotHeader.Font = Enum.Font.GothamBold
DeathBallBotHeader.TextXAlignment = Enum.TextXAlignment.Left
DeathBallBotHeader.Parent = DeathBallPanel

-- AFK Bot toggle
DeathBallBotBtn = Instance.new("TextButton")
DeathBallBotBtn.Size = UDim2.new(1, -20, 0, 30)
DeathBallBotBtn.Position = UDim2.new(0, 10, 0, 632)
DeathBallBotBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
DeathBallBotBtn.Text = "AFK BOT: OFF"
DeathBallBotBtn.TextColor3 = Colors.text
DeathBallBotBtn.TextSize = 11
DeathBallBotBtn.Font = Enum.Font.GothamBold
DeathBallBotBtn.AutoButtonColor = false
DeathBallBotBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallBotBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(DeathBallBotBtn)
makeHoverable(DeathBallBotBtn, Color3.fromRGB(30, 30, 50), Color3.fromRGB(40, 80, 50))

-- Set Queue Position button
DeathBallSetQueueBtn = Instance.new("TextButton")
DeathBallSetQueueBtn.Size = UDim2.new(1, -20, 0, 24)
DeathBallSetQueueBtn.Position = UDim2.new(0, 10, 0, 668)
DeathBallSetQueueBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
DeathBallSetQueueBtn.Text = "SET QUEUE POSITION"
DeathBallSetQueueBtn.TextColor3 = Colors.text
DeathBallSetQueueBtn.TextSize = 9
DeathBallSetQueueBtn.Font = Enum.Font.GothamBold
DeathBallSetQueueBtn.AutoButtonColor = false
DeathBallSetQueueBtn.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallSetQueueBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(DeathBallSetQueueBtn)
makeHoverable(DeathBallSetQueueBtn, Color3.fromRGB(40, 80, 120), Color3.fromRGB(60, 110, 160))

-- Queue position label
DeathBallQueuePosLabel = Instance.new("TextLabel")
DeathBallQueuePosLabel.Size = UDim2.new(1, -20, 0, 14)
DeathBallQueuePosLabel.Position = UDim2.new(0, 10, 0, 696)
DeathBallQueuePosLabel.BackgroundTransparency = 1
DeathBallQueuePosLabel.Text = "Queue: not set"
DeathBallQueuePosLabel.TextColor3 = Color3.fromRGB(200, 100, 60)
DeathBallQueuePosLabel.TextSize = 9
DeathBallQueuePosLabel.Font = Enum.Font.Code
DeathBallQueuePosLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallQueuePosLabel.Parent = DeathBallPanel

-- Miss chance setting
DeathBallMissLabel = Instance.new("TextLabel")
DeathBallMissLabel.Size = UDim2.new(0, 80, 0, 18)
DeathBallMissLabel.Position = UDim2.new(0, 10, 0, 714)
DeathBallMissLabel.BackgroundTransparency = 1
DeathBallMissLabel.Text = "Miss chance:"
DeathBallMissLabel.TextColor3 = Colors.textDim
DeathBallMissLabel.TextSize = 9
DeathBallMissLabel.Font = Enum.Font.GothamBold
DeathBallMissLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallMissLabel.Parent = DeathBallPanel

DeathBallMissBox = Instance.new("TextBox")
DeathBallMissBox.Size = UDim2.new(0, 40, 0, 18)
DeathBallMissBox.Position = UDim2.new(0, 90, 0, 714)
DeathBallMissBox.BackgroundColor3 = Colors.inputBg
DeathBallMissBox.Text = "12"
DeathBallMissBox.PlaceholderText = "%"
DeathBallMissBox.PlaceholderColor3 = Colors.textDim
DeathBallMissBox.TextColor3 = Colors.text
DeathBallMissBox.TextSize = 10
DeathBallMissBox.Font = Enum.Font.Code
DeathBallMissBox.ClearTextOnFocus = false
DeathBallMissBox.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallMissBox).CornerRadius = UDim.new(0, 4)

DeathBallMissPercent = Instance.new("TextLabel")
DeathBallMissPercent.Size = UDim2.new(0, 12, 0, 18)
DeathBallMissPercent.Position = UDim2.new(0, 132, 0, 714)
DeathBallMissPercent.BackgroundTransparency = 1
DeathBallMissPercent.Text = "%"
DeathBallMissPercent.TextColor3 = Colors.textDim
DeathBallMissPercent.TextSize = 9
DeathBallMissPercent.Font = Enum.Font.GothamBold
DeathBallMissPercent.Parent = DeathBallPanel

-- Bot state label
DeathBallBotStateLabel = Instance.new("TextLabel")
DeathBallBotStateLabel.Size = UDim2.new(1, -20, 0, 14)
DeathBallBotStateLabel.Position = UDim2.new(0, 10, 0, 738)
DeathBallBotStateLabel.BackgroundTransparency = 1
DeathBallBotStateLabel.Text = "Bot: Idle"
DeathBallBotStateLabel.TextColor3 = Colors.textDim
DeathBallBotStateLabel.TextSize = 9
DeathBallBotStateLabel.Font = Enum.Font.Code
DeathBallBotStateLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallBotStateLabel.Parent = DeathBallPanel

-- Rounds counter
DeathBallBotRoundsLabel = Instance.new("TextLabel")
DeathBallBotRoundsLabel.Size = UDim2.new(1, -20, 0, 14)
DeathBallBotRoundsLabel.Position = UDim2.new(0, 10, 0, 754)
DeathBallBotRoundsLabel.BackgroundTransparency = 1
DeathBallBotRoundsLabel.Text = "Rounds: 0"
DeathBallBotRoundsLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
DeathBallBotRoundsLabel.TextSize = 9
DeathBallBotRoundsLabel.Font = Enum.Font.GothamBold
DeathBallBotRoundsLabel.TextXAlignment = Enum.TextXAlignment.Left
DeathBallBotRoundsLabel.Parent = DeathBallPanel

-- ═══ INFO TEXT ═══
DeathBallInfoText = Instance.new("TextLabel")
DeathBallInfoText.Size = UDim2.new(1, -20, 0, 50)
DeathBallInfoText.Position = UDim2.new(0, 10, 0, 774)
DeathBallInfoText.BackgroundTransparency = 1
DeathBallInfoText.Text = "v3 AUTO: just press AUTO-PLAY!\nAuto-detects balls, tries all click methods\nFor AFK: set queue pos + turn on bot"
DeathBallInfoText.TextColor3 = Colors.textDim
DeathBallInfoText.TextSize = 8
DeathBallInfoText.Font = Enum.Font.Code
DeathBallInfoText.TextXAlignment = Enum.TextXAlignment.Left
DeathBallInfoText.TextYAlignment = Enum.TextYAlignment.Top
DeathBallInfoText.TextWrapped = true
DeathBallInfoText.Parent = DeathBallPanel

-- ═══ CLOSE ═══
DeathBallCloseBtnBottom = Instance.new("TextButton")
DeathBallCloseBtnBottom.Size = UDim2.new(1, -20, 0, 26)
DeathBallCloseBtnBottom.Position = UDim2.new(0, 10, 0, 830)
DeathBallCloseBtnBottom.BackgroundColor3 = Colors.bloodDark
DeathBallCloseBtnBottom.Text = "CLOSE"
DeathBallCloseBtnBottom.TextColor3 = Colors.text
DeathBallCloseBtnBottom.TextSize = 10
DeathBallCloseBtnBottom.Font = Enum.Font.GothamBold
DeathBallCloseBtnBottom.AutoButtonColor = false
DeathBallCloseBtnBottom.Parent = DeathBallPanel
Instance.new("UICorner", DeathBallCloseBtnBottom).CornerRadius = UDim.new(0, 6)

--[[ PARKVOICE — DESABILITADO
-- ═══════════════════════════════════════════════════
-- GAME CARD: PARKVOICE
-- ═══════════════════════════════════════════════════

ParkVoiceCard = Instance.new("TextButton")
ParkVoiceCard.Size = UDim2.new(1, 0, 0, 54)
ParkVoiceCard.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
ParkVoiceCard.Text = ""
ParkVoiceCard.AutoButtonColor = false
ParkVoiceCard.Parent = GamesScroll
Instance.new("UICorner", ParkVoiceCard).CornerRadius = UDim.new(0, 8)
addBtnGradient(ParkVoiceCard)

ParkVoiceCardStroke = Instance.new("UIStroke", ParkVoiceCard)
ParkVoiceCardStroke.Color = Color3.fromRGB(200, 120, 255)
ParkVoiceCardStroke.Thickness = 1

ParkVoiceCardIcon = Instance.new("TextLabel")
ParkVoiceCardIcon.Size = UDim2.new(0, 40, 0, 40)
ParkVoiceCardIcon.Position = UDim2.new(0, 8, 0, 7)
ParkVoiceCardIcon.BackgroundTransparency = 1
ParkVoiceCardIcon.Text = "🌸"
ParkVoiceCardIcon.TextSize = 24
ParkVoiceCardIcon.Parent = ParkVoiceCard

ParkVoiceCardTitle = Instance.new("TextLabel")
ParkVoiceCardTitle.Size = UDim2.new(1, -60, 0, 18)
ParkVoiceCardTitle.Position = UDim2.new(0, 52, 0, 6)
ParkVoiceCardTitle.BackgroundTransparency = 1
ParkVoiceCardTitle.Text = "ParkVoice"
ParkVoiceCardTitle.TextColor3 = Color3.fromRGB(200, 120, 255)
ParkVoiceCardTitle.TextSize = 13
ParkVoiceCardTitle.Font = Enum.Font.GothamBold
ParkVoiceCardTitle.TextXAlignment = Enum.TextXAlignment.Left
ParkVoiceCardTitle.Parent = ParkVoiceCard

ParkVoiceCardDesc = Instance.new("TextLabel")
ParkVoiceCardDesc.Size = UDim2.new(1, -60, 0, 12)
ParkVoiceCardDesc.Position = UDim2.new(0, 52, 0, 26)
ParkVoiceCardDesc.BackgroundTransparency = 1
ParkVoiceCardDesc.Text = "Flower Event • Remote Fire"
ParkVoiceCardDesc.TextColor3 = Colors.textDim
ParkVoiceCardDesc.TextSize = 9
ParkVoiceCardDesc.Font = Enum.Font.Gotham
ParkVoiceCardDesc.TextXAlignment = Enum.TextXAlignment.Left
ParkVoiceCardDesc.Parent = ParkVoiceCard

ParkVoiceCardArrow = Instance.new("TextLabel")
ParkVoiceCardArrow.Size = UDim2.new(0, 20, 1, 0)
ParkVoiceCardArrow.Position = UDim2.new(1, -24, 0, 0)
ParkVoiceCardArrow.BackgroundTransparency = 1
ParkVoiceCardArrow.Text = "▸"
ParkVoiceCardArrow.TextColor3 = Color3.fromRGB(200, 120, 255)
ParkVoiceCardArrow.TextSize = 16
ParkVoiceCardArrow.Font = Enum.Font.GothamBold
ParkVoiceCardArrow.Parent = ParkVoiceCard

makeHoverable(ParkVoiceCard, Color3.fromRGB(20, 22, 30), Color3.fromRGB(30, 20, 40))

--==================================================
-- PARKVOICE PANEL — FLOATING
--==================================================

ParkVoicePanel = Instance.new("Frame")
ParkVoicePanel.Name = "ParkVoicePanel"
ParkVoicePanel.Size = UDim2.new(0, 260, 0, 180)
ParkVoicePanel.Position = UDim2.new(0.5, -130, 0.5, -90)
ParkVoicePanel.BackgroundColor3 = Colors.bg
ParkVoicePanel.BorderSizePixel = 0
ParkVoicePanel.Visible = false
ParkVoicePanel.Parent = ScreenGui

Instance.new("UICorner", ParkVoicePanel).CornerRadius = UDim.new(0, 10)
ParkVoicePanelStroke = Instance.new("UIStroke", ParkVoicePanel)
ParkVoicePanelStroke.Color = Color3.fromRGB(200, 120, 255)
ParkVoicePanelStroke.Thickness = 1.5
addGradient(ParkVoicePanel, Colors.surfaceLight, Color3.fromRGB(12, 6, 16), 90)

ParkVoiceTopBar = Instance.new("Frame")
ParkVoiceTopBar.Size = UDim2.new(1, 0, 0, 32)
ParkVoiceTopBar.BackgroundColor3 = Colors.topbar
ParkVoiceTopBar.BorderSizePixel = 0
ParkVoiceTopBar.Parent = ParkVoicePanel
Instance.new("UICorner", ParkVoiceTopBar).CornerRadius = UDim.new(0, 10)
addGradient(ParkVoiceTopBar, Color3.fromRGB(20, 8, 28), Colors.topbar, 0)

ParkVoiceTopBarFix = Instance.new("Frame")
ParkVoiceTopBarFix.Size = UDim2.new(1, 0, 0, 10)
ParkVoiceTopBarFix.Position = UDim2.new(0, 0, 1, -10)
ParkVoiceTopBarFix.BackgroundColor3 = Colors.topbar
ParkVoiceTopBarFix.BorderSizePixel = 0
ParkVoiceTopBarFix.Parent = ParkVoiceTopBar

addAccentLine(ParkVoiceTopBar, UDim2.new(0, 0, 1, -1), Color3.fromRGB(200, 120, 255))

ParkVoiceTitle = Instance.new("TextLabel")
ParkVoiceTitle.Size = UDim2.new(1, -40, 1, 0)
ParkVoiceTitle.Position = UDim2.new(0, 10, 0, 0)
ParkVoiceTitle.BackgroundTransparency = 1
ParkVoiceTitle.Text = "ParkVoice"
ParkVoiceTitle.TextColor3 = Color3.fromRGB(220, 150, 255)
ParkVoiceTitle.TextSize = 12
ParkVoiceTitle.Font = Enum.Font.GothamBold
ParkVoiceTitle.TextXAlignment = Enum.TextXAlignment.Left
ParkVoiceTitle.Parent = ParkVoiceTopBar

ParkVoiceCloseX = Instance.new("TextButton")
ParkVoiceCloseX.Size = UDim2.new(0, 20, 0, 20)
ParkVoiceCloseX.Position = UDim2.new(1, -26, 0, 6)
ParkVoiceCloseX.BackgroundColor3 = Color3.fromRGB(140, 60, 200)
ParkVoiceCloseX.Text = "X"
ParkVoiceCloseX.TextColor3 = Colors.text
ParkVoiceCloseX.TextSize = 11
ParkVoiceCloseX.Font = Enum.Font.GothamBold
ParkVoiceCloseX.AutoButtonColor = false
ParkVoiceCloseX.Parent = ParkVoiceTopBar
Instance.new("UICorner", ParkVoiceCloseX).CornerRadius = UDim.new(0, 6)
makeHoverable(ParkVoiceCloseX, Color3.fromRGB(140, 60, 200), Color3.fromRGB(180, 90, 255))

ParkVoiceFlowerBtn = Instance.new("TextButton")
ParkVoiceFlowerBtn.Size = UDim2.new(1, -20, 0, 54)
ParkVoiceFlowerBtn.Position = UDim2.new(0, 10, 0, 42)
ParkVoiceFlowerBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 220)
ParkVoiceFlowerBtn.Text = "FLOWER"
ParkVoiceFlowerBtn.TextColor3 = Colors.text
ParkVoiceFlowerBtn.TextSize = 18
ParkVoiceFlowerBtn.Font = Enum.Font.GothamBold
ParkVoiceFlowerBtn.AutoButtonColor = false
ParkVoiceFlowerBtn.Parent = ParkVoicePanel
Instance.new("UICorner", ParkVoiceFlowerBtn).CornerRadius = UDim.new(0, 8)
addBtnGradient(ParkVoiceFlowerBtn)
makeHoverable(ParkVoiceFlowerBtn, Color3.fromRGB(180, 60, 220), Color3.fromRGB(220, 100, 255))

ParkVoiceStatus = Instance.new("TextLabel")
ParkVoiceStatus.Size = UDim2.new(1, -20, 0, 28)
ParkVoiceStatus.Position = UDim2.new(0, 10, 0, 102)
ParkVoiceStatus.BackgroundColor3 = Color3.fromRGB(20, 15, 25)
ParkVoiceStatus.Text = "Click FLOWER to fire all remotes (vuln scan)"
ParkVoiceStatus.TextColor3 = Colors.textDim
ParkVoiceStatus.TextSize = 9
ParkVoiceStatus.Font = Enum.Font.Code
ParkVoiceStatus.TextXAlignment = Enum.TextXAlignment.Left
ParkVoiceStatus.TextWrapped = true
ParkVoiceStatus.Parent = ParkVoicePanel
Instance.new("UICorner", ParkVoiceStatus).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", ParkVoiceStatus).PaddingLeft = UDim.new(0, 6)

ParkVoiceCloseBtn = Instance.new("TextButton")
ParkVoiceCloseBtn.Size = UDim2.new(1, -20, 0, 26)
ParkVoiceCloseBtn.Position = UDim2.new(0, 10, 0, 140)
ParkVoiceCloseBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
ParkVoiceCloseBtn.Text = "CLOSE"
ParkVoiceCloseBtn.TextColor3 = Colors.text
ParkVoiceCloseBtn.TextSize = 10
ParkVoiceCloseBtn.Font = Enum.Font.GothamBold
ParkVoiceCloseBtn.AutoButtonColor = false
ParkVoiceCloseBtn.Parent = ParkVoicePanel
Instance.new("UICorner", ParkVoiceCloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(ParkVoiceCloseBtn, Color3.fromRGB(80, 40, 120), Color3.fromRGB(120, 60, 180))

openParkVoicePanel = function()
    ParkVoicePanel.Visible = true
end
--]] -- FIM PARKVOICE DESABILITADO
makeHoverable(DeathBallCloseBtnBottom, Colors.bloodDark, Colors.blood)

-- ═══ GAME CARD: PIANO AUTO ═══
PianoAutoCard = Instance.new("TextButton")
PianoAutoCard.Size = UDim2.new(1, 0, 0, 54)
PianoAutoCard.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
PianoAutoCard.Text = ""
PianoAutoCard.AutoButtonColor = false
PianoAutoCard.Parent = GamesScroll
Instance.new("UICorner", PianoAutoCard).CornerRadius = UDim.new(0, 8)
addBtnGradient(PianoAutoCard)

PianoAutoCardStroke = Instance.new("UIStroke", PianoAutoCard)
PianoAutoCardStroke.Color = Color3.fromRGB(100, 80, 200)
PianoAutoCardStroke.Thickness = 1

PianoAutoCardIcon = Instance.new("TextLabel")
PianoAutoCardIcon.Size = UDim2.new(0, 40, 0, 40)
PianoAutoCardIcon.Position = UDim2.new(0, 8, 0, 7)
PianoAutoCardIcon.BackgroundTransparency = 1
PianoAutoCardIcon.Text = "🎹"
PianoAutoCardIcon.TextSize = 24
PianoAutoCardIcon.Parent = PianoAutoCard

PianoAutoCardTitle = Instance.new("TextLabel")
PianoAutoCardTitle.Size = UDim2.new(1, -60, 0, 18)
PianoAutoCardTitle.Position = UDim2.new(0, 52, 0, 6)
PianoAutoCardTitle.BackgroundTransparency = 1
PianoAutoCardTitle.Text = "Piano Auto (Test)"
PianoAutoCardTitle.TextColor3 = Color3.fromRGB(140, 120, 255)
PianoAutoCardTitle.TextSize = 13
PianoAutoCardTitle.Font = Enum.Font.GothamBold
PianoAutoCardTitle.TextXAlignment = Enum.TextXAlignment.Left
PianoAutoCardTitle.Parent = PianoAutoCard

PianoAutoCardDesc = Instance.new("TextLabel")
PianoAutoCardDesc.Size = UDim2.new(1, -60, 0, 12)
PianoAutoCardDesc.Position = UDim2.new(0, 52, 0, 26)
PianoAutoCardDesc.BackgroundTransparency = 1
PianoAutoCardDesc.Text = "Auto Player • Sheet Paste • Speed Control"
PianoAutoCardDesc.TextColor3 = Colors.textDim
PianoAutoCardDesc.TextSize = 9
PianoAutoCardDesc.Font = Enum.Font.Gotham
PianoAutoCardDesc.TextXAlignment = Enum.TextXAlignment.Left
PianoAutoCardDesc.Parent = PianoAutoCard

PianoAutoCardArrow = Instance.new("TextLabel")
PianoAutoCardArrow.Size = UDim2.new(0, 20, 1, 0)
PianoAutoCardArrow.Position = UDim2.new(1, -24, 0, 0)
PianoAutoCardArrow.BackgroundTransparency = 1
PianoAutoCardArrow.Text = "▸"
PianoAutoCardArrow.TextColor3 = Color3.fromRGB(100, 80, 200)
PianoAutoCardArrow.TextSize = 16
PianoAutoCardArrow.Font = Enum.Font.GothamBold
PianoAutoCardArrow.Parent = PianoAutoCard

makeHoverable(PianoAutoCard, Color3.fromRGB(20, 20, 30), Color3.fromRGB(30, 25, 45))

-- ═══ GAME CARD: SOUND PLAYER ═══
SoundPlayerCard = Instance.new("TextButton")
SoundPlayerCard.Size = UDim2.new(1, -8, 0, 54)
SoundPlayerCard.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
SoundPlayerCard.Text = ""
SoundPlayerCard.AutoButtonColor = false
SoundPlayerCard.Parent = GamesScroll
Instance.new("UICorner", SoundPlayerCard).CornerRadius = UDim.new(0, 8)
addBtnGradient(SoundPlayerCard)

SoundPlayerCardStroke = Instance.new("UIStroke", SoundPlayerCard)
SoundPlayerCardStroke.Color = Color3.fromRGB(80, 200, 100)
SoundPlayerCardStroke.Thickness = 1

SoundPlayerCardIcon = Instance.new("TextLabel")
SoundPlayerCardIcon.Size = UDim2.new(0, 40, 0, 40)
SoundPlayerCardIcon.Position = UDim2.new(0, 8, 0, 7)
SoundPlayerCardIcon.BackgroundTransparency = 1
SoundPlayerCardIcon.Text = "🔊"
SoundPlayerCardIcon.TextSize = 24
SoundPlayerCardIcon.Parent = SoundPlayerCard

SoundPlayerCardTitle = Instance.new("TextLabel")
SoundPlayerCardTitle.Size = UDim2.new(1, -60, 0, 18)
SoundPlayerCardTitle.Position = UDim2.new(0, 52, 0, 6)
SoundPlayerCardTitle.BackgroundTransparency = 1
SoundPlayerCardTitle.Text = "Sound Player"
SoundPlayerCardTitle.TextColor3 = Color3.fromRGB(80, 200, 100)
SoundPlayerCardTitle.TextSize = 13
SoundPlayerCardTitle.Font = Enum.Font.GothamBold
SoundPlayerCardTitle.TextXAlignment = Enum.TextXAlignment.Left
SoundPlayerCardTitle.Parent = SoundPlayerCard

SoundPlayerCardDesc = Instance.new("TextLabel")
SoundPlayerCardDesc.Size = UDim2.new(1, -60, 0, 12)
SoundPlayerCardDesc.Position = UDim2.new(0, 52, 0, 26)
SoundPlayerCardDesc.BackgroundTransparency = 1
SoundPlayerCardDesc.Text = "Play any AudioID • Volume • Map Sounds"
SoundPlayerCardDesc.TextColor3 = Colors.textDim
SoundPlayerCardDesc.TextSize = 9
SoundPlayerCardDesc.Font = Enum.Font.Gotham
SoundPlayerCardDesc.TextXAlignment = Enum.TextXAlignment.Left
SoundPlayerCardDesc.Parent = SoundPlayerCard

SoundPlayerCardArrow = Instance.new("TextLabel")
SoundPlayerCardArrow.Size = UDim2.new(0, 20, 1, 0)
SoundPlayerCardArrow.Position = UDim2.new(1, -24, 0, 0)
SoundPlayerCardArrow.BackgroundTransparency = 1
SoundPlayerCardArrow.Text = "▸"
SoundPlayerCardArrow.TextColor3 = Color3.fromRGB(80, 200, 100)
SoundPlayerCardArrow.TextSize = 16
SoundPlayerCardArrow.Font = Enum.Font.GothamBold
SoundPlayerCardArrow.Parent = SoundPlayerCard

makeHoverable(SoundPlayerCard, Color3.fromRGB(20, 20, 30), Color3.fromRGB(25, 35, 28))

--==================================================
-- PIANO AUTO PANEL — FLOATING
--==================================================

PianoAutoPanel = Instance.new("Frame")
PianoAutoPanel.Name = "PianoAutoPanel"
PianoAutoPanel.Size = UDim2.new(0, 260, 0, 450)
PianoAutoPanel.Position = UDim2.new(0.5, -130, 0.5, -210)
PianoAutoPanel.BackgroundColor3 = Color3.fromRGB(14, 10, 14)
PianoAutoPanel.BorderSizePixel = 0
PianoAutoPanel.Visible = false
PianoAutoPanel.Parent = ScreenGui
Instance.new("UICorner", PianoAutoPanel).CornerRadius = UDim.new(0, 10)

PianoAutoPanelStroke = Instance.new("UIStroke", PianoAutoPanel)
PianoAutoPanelStroke.Color = Color3.fromRGB(100, 80, 200)
PianoAutoPanelStroke.Thickness = 1.5
addGradient(PianoAutoPanel, Color3.fromRGB(14, 10, 18), Color3.fromRGB(8, 6, 10), 90)

-- Top Bar
PianoAutoTopBar = Instance.new("Frame")
PianoAutoTopBar.Size = UDim2.new(1, 0, 0, 32)
PianoAutoTopBar.BackgroundColor3 = Color3.fromRGB(20, 14, 30)
PianoAutoTopBar.BorderSizePixel = 0
PianoAutoTopBar.Parent = PianoAutoPanel
Instance.new("UICorner", PianoAutoTopBar).CornerRadius = UDim.new(0, 10)
addGradient(PianoAutoTopBar, Color3.fromRGB(25, 14, 35), Color3.fromRGB(14, 8, 20), 0)

PianoAutoTopBarFix = Instance.new("Frame")
PianoAutoTopBarFix.Size = UDim2.new(1, 0, 0, 10)
PianoAutoTopBarFix.Position = UDim2.new(0, 0, 1, -10)
PianoAutoTopBarFix.BackgroundColor3 = Color3.fromRGB(20, 14, 30)
PianoAutoTopBarFix.BorderSizePixel = 0
PianoAutoTopBarFix.Parent = PianoAutoTopBar

addAccentLine(PianoAutoTopBar, UDim2.new(0, 0, 1, -1), Color3.fromRGB(100, 80, 200))

PianoAutoTitleLabel = Instance.new("TextLabel")
PianoAutoTitleLabel.Size = UDim2.new(1, -40, 1, 0)
PianoAutoTitleLabel.Position = UDim2.new(0, 10, 0, 0)
PianoAutoTitleLabel.BackgroundTransparency = 1
PianoAutoTitleLabel.Text = "🎹 Piano Auto Player"
PianoAutoTitleLabel.TextColor3 = Color3.fromRGB(140, 120, 255)
PianoAutoTitleLabel.TextSize = 12
PianoAutoTitleLabel.Font = Enum.Font.GothamBold
PianoAutoTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
PianoAutoTitleLabel.Parent = PianoAutoTopBar

PianoAutoCloseBtn = Instance.new("TextButton")
PianoAutoCloseBtn.Size = UDim2.new(0, 20, 0, 20)
PianoAutoCloseBtn.Position = UDim2.new(1, -26, 0, 6)
PianoAutoCloseBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
PianoAutoCloseBtn.Text = "X"
PianoAutoCloseBtn.TextColor3 = Colors.text
PianoAutoCloseBtn.TextSize = 11
PianoAutoCloseBtn.Font = Enum.Font.GothamBold
PianoAutoCloseBtn.AutoButtonColor = false
PianoAutoCloseBtn.Parent = PianoAutoTopBar
Instance.new("UICorner", PianoAutoCloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(PianoAutoCloseBtn, Color3.fromRGB(100, 80, 200), Color3.fromRGB(140, 110, 255))

-- ═══ SHEET INPUT (multi-line TextBox) ═══
PianoAutoSheetLabel = Instance.new("TextLabel")
PianoAutoSheetLabel.Size = UDim2.new(1, -20, 0, 16)
PianoAutoSheetLabel.Position = UDim2.new(0, 10, 0, 38)
PianoAutoSheetLabel.BackgroundTransparency = 1
PianoAutoSheetLabel.Text = "📋 Paste Sheet:"
PianoAutoSheetLabel.TextColor3 = Colors.textDim
PianoAutoSheetLabel.TextSize = 10
PianoAutoSheetLabel.Font = Enum.Font.GothamBold
PianoAutoSheetLabel.TextXAlignment = Enum.TextXAlignment.Left
PianoAutoSheetLabel.Parent = PianoAutoPanel

PianoAutoSheet = Instance.new("TextBox")
PianoAutoSheet.Size = UDim2.new(1, -20, 0, 120)
PianoAutoSheet.Position = UDim2.new(0, 10, 0, 56)
PianoAutoSheet.BackgroundColor3 = Color3.fromRGB(20, 16, 28)
PianoAutoSheet.Text = ""
PianoAutoSheet.PlaceholderText = "Paste piano sheet here..."
PianoAutoSheet.PlaceholderColor3 = Color3.fromRGB(80, 70, 100)
PianoAutoSheet.TextColor3 = Colors.text
PianoAutoSheet.TextSize = 10
PianoAutoSheet.Font = Enum.Font.Code
PianoAutoSheet.TextXAlignment = Enum.TextXAlignment.Left
PianoAutoSheet.TextYAlignment = Enum.TextYAlignment.Top
PianoAutoSheet.TextWrapped = true
PianoAutoSheet.ClearTextOnFocus = false
PianoAutoSheet.MultiLine = true
PianoAutoSheet.Parent = PianoAutoPanel
Instance.new("UICorner", PianoAutoSheet).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", PianoAutoSheet).PaddingLeft = UDim.new(0, 6)

PianoAutoSheetStroke = Instance.new("UIStroke", PianoAutoSheet)
PianoAutoSheetStroke.Color = Color3.fromRGB(60, 50, 100)
PianoAutoSheetStroke.Thickness = 1

-- ═══ SPEED SLIDER ═══
PianoAutoSpeedLabel = Instance.new("TextLabel")
PianoAutoSpeedLabel.Size = UDim2.new(1, -20, 0, 16)
PianoAutoSpeedLabel.Position = UDim2.new(0, 10, 0, 182)
PianoAutoSpeedLabel.BackgroundTransparency = 1
PianoAutoSpeedLabel.Text = "⚡ Speed: 1.0x"
PianoAutoSpeedLabel.TextColor3 = Colors.textDim
PianoAutoSpeedLabel.TextSize = 10
PianoAutoSpeedLabel.Font = Enum.Font.GothamBold
PianoAutoSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
PianoAutoSpeedLabel.Parent = PianoAutoPanel

PianoAutoSpeedSlider = Instance.new("Frame")
PianoAutoSpeedSlider.Name = "PianoAutoSpeedSlider"
PianoAutoSpeedSlider.Size = UDim2.new(1, -20, 0, 20)
PianoAutoSpeedSlider.Position = UDim2.new(0, 10, 0, 200)
PianoAutoSpeedSlider.BackgroundColor3 = Color3.fromRGB(30, 24, 40)
PianoAutoSpeedSlider.Parent = PianoAutoPanel
Instance.new("UICorner", PianoAutoSpeedSlider).CornerRadius = UDim.new(0, 6)

PianoAutoSpeedFill = Instance.new("Frame")
PianoAutoSpeedFill.Name = "Fill"
PianoAutoSpeedFill.Size = UDim2.new(0.11, 0, 1, 0)
PianoAutoSpeedFill.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
PianoAutoSpeedFill.Parent = PianoAutoSpeedSlider
Instance.new("UICorner", PianoAutoSpeedFill).CornerRadius = UDim.new(0, 6)

PianoAutoSpeedKnob = Instance.new("Frame")
PianoAutoSpeedKnob.Name = "Knob"
PianoAutoSpeedKnob.Size = UDim2.new(0, 12, 0, 12)
PianoAutoSpeedKnob.Position = UDim2.new(0.11, -6, 0.5, -6)
PianoAutoSpeedKnob.BackgroundColor3 = Colors.text
PianoAutoSpeedKnob.Parent = PianoAutoSpeedSlider
Instance.new("UICorner", PianoAutoSpeedKnob).CornerRadius = UDim.new(1, 0)

-- ═══ BPM INPUT ═══
PianoBPMLabel = Instance.new("TextLabel")
PianoBPMLabel.Size = UDim2.new(0.4, -10, 0, 16)
PianoBPMLabel.Position = UDim2.new(0, 10, 0, 228)
PianoBPMLabel.BackgroundTransparency = 1
PianoBPMLabel.Text = "♪ BPM (auto ou manual):"
PianoBPMLabel.TextColor3 = Colors.textDim
PianoBPMLabel.TextSize = 10
PianoBPMLabel.Font = Enum.Font.GothamBold
PianoBPMLabel.TextXAlignment = Enum.TextXAlignment.Left
PianoBPMLabel.Parent = PianoAutoPanel

PianoBPMInput = Instance.new("TextBox")
PianoBPMInput.Size = UDim2.new(0.55, -10, 0, 24)
PianoBPMInput.Position = UDim2.new(0.45, 0, 0, 225)
PianoBPMInput.BackgroundColor3 = Color3.fromRGB(30, 24, 40)
PianoBPMInput.Text = ""
PianoBPMInput.PlaceholderText = "auto"
PianoBPMInput.PlaceholderColor3 = Color3.fromRGB(80, 70, 120)
PianoBPMInput.TextColor3 = Color3.fromRGB(200, 160, 255)
PianoBPMInput.TextSize = 12
PianoBPMInput.Font = Enum.Font.Code
PianoBPMInput.ClearTextOnFocus = false
PianoBPMInput.Parent = PianoAutoPanel
Instance.new("UICorner", PianoBPMInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", PianoBPMInput).Color = Color3.fromRGB(60, 50, 100)

-- ═══ PLAY / STOP BUTTONS ═══
PianoAutoPlayBtn = Instance.new("TextButton")
PianoAutoPlayBtn.Size = UDim2.new(0.48, -5, 0, 34)
PianoAutoPlayBtn.Position = UDim2.new(0, 10, 0, 258)
PianoAutoPlayBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
PianoAutoPlayBtn.Text = "▶ PLAY"
PianoAutoPlayBtn.TextColor3 = Colors.text
PianoAutoPlayBtn.TextSize = 13
PianoAutoPlayBtn.Font = Enum.Font.GothamBold
PianoAutoPlayBtn.AutoButtonColor = false
PianoAutoPlayBtn.Parent = PianoAutoPanel
Instance.new("UICorner", PianoAutoPlayBtn).CornerRadius = UDim.new(0, 8)
addBtnGradient(PianoAutoPlayBtn)
makeHoverable(PianoAutoPlayBtn, Color3.fromRGB(40, 140, 60), Color3.fromRGB(60, 180, 80))

PianoAutoStopBtn = Instance.new("TextButton")
PianoAutoStopBtn.Size = UDim2.new(0.48, -5, 0, 34)
PianoAutoStopBtn.Position = UDim2.new(0.52, 5, 0, 258)
PianoAutoStopBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
PianoAutoStopBtn.Text = "⏹ STOP"
PianoAutoStopBtn.TextColor3 = Colors.text
PianoAutoStopBtn.TextSize = 13
PianoAutoStopBtn.Font = Enum.Font.GothamBold
PianoAutoStopBtn.AutoButtonColor = false
PianoAutoStopBtn.Parent = PianoAutoPanel
Instance.new("UICorner", PianoAutoStopBtn).CornerRadius = UDim.new(0, 8)
addBtnGradient(PianoAutoStopBtn)
makeHoverable(PianoAutoStopBtn, Color3.fromRGB(180, 40, 40), Color3.fromRGB(220, 60, 60))

-- ═══ STATUS LABEL ═══
PianoAutoStatus = Instance.new("TextLabel")
PianoAutoStatus.Size = UDim2.new(1, -20, 0, 24)
PianoAutoStatus.Position = UDim2.new(0, 10, 0, 300)
PianoAutoStatus.BackgroundColor3 = Color3.fromRGB(20, 16, 28)
PianoAutoStatus.Text = "Ready"
PianoAutoStatus.TextColor3 = Color3.fromRGB(140, 120, 255)
PianoAutoStatus.TextSize = 10
PianoAutoStatus.Font = Enum.Font.Code
PianoAutoStatus.TextXAlignment = Enum.TextXAlignment.Center
PianoAutoStatus.Parent = PianoAutoPanel
Instance.new("UICorner", PianoAutoStatus).CornerRadius = UDim.new(0, 4)

PianoAutoStatusStroke = Instance.new("UIStroke", PianoAutoStatus)
PianoAutoStatusStroke.Color = Color3.fromRGB(60, 50, 100)
PianoAutoStatusStroke.Thickness = 1

-- ═══ HELP TEXT ═══
PianoAutoHelpLabel = Instance.new("TextLabel")
PianoAutoHelpLabel.Size = UDim2.new(1, -20, 0, 50)
PianoAutoHelpLabel.Position = UDim2.new(0, 10, 0, 332)
PianoAutoHelpLabel.BackgroundColor3 = Color3.fromRGB(20, 16, 28)
PianoAutoHelpLabel.Text = "Letters = notes, [abc] = chord\nspace = pause | = long pause\nBPM: auto detect or type manually"
PianoAutoHelpLabel.TextColor3 = Colors.textDim
PianoAutoHelpLabel.TextSize = 9
PianoAutoHelpLabel.Font = Enum.Font.Code
PianoAutoHelpLabel.TextXAlignment = Enum.TextXAlignment.Left
PianoAutoHelpLabel.TextWrapped = true
PianoAutoHelpLabel.Parent = PianoAutoPanel
Instance.new("UICorner", PianoAutoHelpLabel).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", PianoAutoHelpLabel).PaddingLeft = UDim.new(0, 6)

PianoAutoHelpStroke = Instance.new("UIStroke", PianoAutoHelpLabel)
PianoAutoHelpStroke.Color = Color3.fromRGB(40, 35, 60)
PianoAutoHelpStroke.Thickness = 1

-- ═══ LINK TEXT ═══
PianoAutoLinkLabel = Instance.new("TextLabel")
PianoAutoLinkLabel.Size = UDim2.new(1, -20, 0, 20)
PianoAutoLinkLabel.Position = UDim2.new(0, 10, 0, 390)
PianoAutoLinkLabel.BackgroundTransparency = 1
PianoAutoLinkLabel.Text = "Sheets: vpsheet.com"
PianoAutoLinkLabel.TextColor3 = Color3.fromRGB(100, 80, 200)
PianoAutoLinkLabel.TextSize = 10
PianoAutoLinkLabel.Font = Enum.Font.GothamBold
PianoAutoLinkLabel.TextXAlignment = Enum.TextXAlignment.Center
PianoAutoLinkLabel.Parent = PianoAutoPanel

--==================================================
-- SOUND PLAYER PANEL — FLOATING
--==================================================

SoundPlayerPanel = Instance.new("Frame")
SoundPlayerPanel.Name = "SoundPlayerPanel"
SoundPlayerPanel.Size = UDim2.new(0, 260, 0, 380)
SoundPlayerPanel.Position = UDim2.new(0.5, -130, 0.5, -190)
SoundPlayerPanel.BackgroundColor3 = Color3.fromRGB(14, 10, 14)
SoundPlayerPanel.BorderSizePixel = 0
SoundPlayerPanel.Visible = false
SoundPlayerPanel.Parent = ScreenGui
Instance.new("UICorner", SoundPlayerPanel).CornerRadius = UDim.new(0, 10)

SoundPlayerPanelStroke = Instance.new("UIStroke", SoundPlayerPanel)
SoundPlayerPanelStroke.Color = Color3.fromRGB(80, 200, 100)
SoundPlayerPanelStroke.Thickness = 1.5
addGradient(SoundPlayerPanel, Color3.fromRGB(14, 16, 14), Color3.fromRGB(8, 10, 8), 90)

-- Top Bar
SoundPlayerTopBar = Instance.new("Frame")
SoundPlayerTopBar.Size = UDim2.new(1, 0, 0, 32)
SoundPlayerTopBar.BackgroundColor3 = Color3.fromRGB(16, 24, 18)
SoundPlayerTopBar.BorderSizePixel = 0
SoundPlayerTopBar.Parent = SoundPlayerPanel
Instance.new("UICorner", SoundPlayerTopBar).CornerRadius = UDim.new(0, 10)
addGradient(SoundPlayerTopBar, Color3.fromRGB(18, 28, 20), Color3.fromRGB(10, 16, 12), 0)

SoundPlayerTopBarFix = Instance.new("Frame")
SoundPlayerTopBarFix.Size = UDim2.new(1, 0, 0, 10)
SoundPlayerTopBarFix.Position = UDim2.new(0, 0, 1, -10)
SoundPlayerTopBarFix.BackgroundColor3 = Color3.fromRGB(16, 24, 18)
SoundPlayerTopBarFix.BorderSizePixel = 0
SoundPlayerTopBarFix.Parent = SoundPlayerTopBar

addAccentLine(SoundPlayerTopBar, UDim2.new(0, 0, 1, -1), Color3.fromRGB(80, 200, 100))

SoundPlayerTitleLabel = Instance.new("TextLabel")
SoundPlayerTitleLabel.Size = UDim2.new(1, -40, 1, 0)
SoundPlayerTitleLabel.Position = UDim2.new(0, 10, 0, 0)
SoundPlayerTitleLabel.BackgroundTransparency = 1
SoundPlayerTitleLabel.Text = "🔊 Sound Player"
SoundPlayerTitleLabel.TextColor3 = Color3.fromRGB(80, 200, 100)
SoundPlayerTitleLabel.TextSize = 12
SoundPlayerTitleLabel.Font = Enum.Font.GothamBold
SoundPlayerTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SoundPlayerTitleLabel.Parent = SoundPlayerTopBar

SoundPlayerCloseBtn = Instance.new("TextButton")
SoundPlayerCloseBtn.Size = UDim2.new(0, 20, 0, 20)
SoundPlayerCloseBtn.Position = UDim2.new(1, -26, 0, 6)
SoundPlayerCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
SoundPlayerCloseBtn.Text = "X"
SoundPlayerCloseBtn.TextColor3 = Colors.text
SoundPlayerCloseBtn.TextSize = 11
SoundPlayerCloseBtn.Font = Enum.Font.GothamBold
SoundPlayerCloseBtn.AutoButtonColor = false
SoundPlayerCloseBtn.Parent = SoundPlayerTopBar
Instance.new("UICorner", SoundPlayerCloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(SoundPlayerCloseBtn, Color3.fromRGB(200, 60, 60), Color3.fromRGB(240, 80, 80))

-- ═══ AUDIO ID INPUT ═══
SoundIdInput = Instance.new("TextBox")
SoundIdInput.Size = UDim2.new(1, -20, 0, 28)
SoundIdInput.Position = UDim2.new(0, 10, 0, 40)
SoundIdInput.BackgroundColor3 = Color3.fromRGB(20, 26, 22)
SoundIdInput.Text = ""
SoundIdInput.PlaceholderText = "Enter Audio ID..."
SoundIdInput.PlaceholderColor3 = Color3.fromRGB(70, 100, 80)
SoundIdInput.TextColor3 = Colors.text
SoundIdInput.TextSize = 11
SoundIdInput.Font = Enum.Font.Code
SoundIdInput.ClearTextOnFocus = false
SoundIdInput.Parent = SoundPlayerPanel
Instance.new("UICorner", SoundIdInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", SoundIdInput).PaddingLeft = UDim.new(0, 6)

SoundIdInputStroke = Instance.new("UIStroke", SoundIdInput)
SoundIdInputStroke.Color = Color3.fromRGB(60, 120, 70)
SoundIdInputStroke.Thickness = 1

-- ═══ PLAY / STOP BUTTONS ═══
SoundPlayBtn = Instance.new("TextButton")
SoundPlayBtn.Size = UDim2.new(0.48, -5, 0, 34)
SoundPlayBtn.Position = UDim2.new(0, 10, 0, 76)
SoundPlayBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
SoundPlayBtn.Text = "▶ PLAY"
SoundPlayBtn.TextColor3 = Colors.text
SoundPlayBtn.TextSize = 13
SoundPlayBtn.Font = Enum.Font.GothamBold
SoundPlayBtn.AutoButtonColor = false
SoundPlayBtn.Parent = SoundPlayerPanel
Instance.new("UICorner", SoundPlayBtn).CornerRadius = UDim.new(0, 8)
addBtnGradient(SoundPlayBtn)
makeHoverable(SoundPlayBtn, Color3.fromRGB(40, 140, 60), Color3.fromRGB(60, 180, 80))

SoundStopBtn = Instance.new("TextButton")
SoundStopBtn.Size = UDim2.new(0.48, -5, 0, 34)
SoundStopBtn.Position = UDim2.new(0.52, 5, 0, 76)
SoundStopBtn.BackgroundColor3 = Colors.bloodDark
SoundStopBtn.Text = "⏹ STOP"
SoundStopBtn.TextColor3 = Colors.text
SoundStopBtn.TextSize = 13
SoundStopBtn.Font = Enum.Font.GothamBold
SoundStopBtn.AutoButtonColor = false
SoundStopBtn.Parent = SoundPlayerPanel
Instance.new("UICorner", SoundStopBtn).CornerRadius = UDim.new(0, 8)
addBtnGradient(SoundStopBtn)
makeHoverable(SoundStopBtn, Colors.bloodDark, Colors.blood)

-- ═══ VOLUME SLIDER ═══
SoundVolumeLabel = Instance.new("TextLabel")
SoundVolumeLabel.Size = UDim2.new(1, -20, 0, 16)
SoundVolumeLabel.Position = UDim2.new(0, 10, 0, 118)
SoundVolumeLabel.BackgroundTransparency = 1
SoundVolumeLabel.Text = "🔊 Volume: 50%"
SoundVolumeLabel.TextColor3 = Colors.textDim
SoundVolumeLabel.TextSize = 10
SoundVolumeLabel.Font = Enum.Font.GothamBold
SoundVolumeLabel.TextXAlignment = Enum.TextXAlignment.Left
SoundVolumeLabel.Parent = SoundPlayerPanel

SoundVolumeSlider = Instance.new("Frame")
SoundVolumeSlider.Name = "SoundVolumeSlider"
SoundVolumeSlider.Size = UDim2.new(1, -20, 0, 20)
SoundVolumeSlider.Position = UDim2.new(0, 10, 0, 136)
SoundVolumeSlider.BackgroundColor3 = Color3.fromRGB(24, 30, 26)
SoundVolumeSlider.Parent = SoundPlayerPanel
Instance.new("UICorner", SoundVolumeSlider).CornerRadius = UDim.new(0, 6)

SoundVolumeFill = Instance.new("Frame")
SoundVolumeFill.Name = "Fill"
SoundVolumeFill.Size = UDim2.new(0.5, 0, 1, 0)
SoundVolumeFill.BackgroundColor3 = Color3.fromRGB(80, 200, 100)
SoundVolumeFill.Parent = SoundVolumeSlider
Instance.new("UICorner", SoundVolumeFill).CornerRadius = UDim.new(0, 6)

SoundVolumeKnob = Instance.new("Frame")
SoundVolumeKnob.Name = "Knob"
SoundVolumeKnob.Size = UDim2.new(0, 12, 0, 12)
SoundVolumeKnob.Position = UDim2.new(0.5, -6, 0.5, -6)
SoundVolumeKnob.BackgroundColor3 = Colors.text
SoundVolumeKnob.Parent = SoundVolumeSlider
Instance.new("UICorner", SoundVolumeKnob).CornerRadius = UDim.new(1, 0)

-- ═══ LOOP TOGGLE ═══
SoundLoopToggle = createVampToggle(SoundPlayerPanel, "Loop", "loop", {loop = false}, 164, Color3.fromRGB(80, 200, 100))

-- ═══ STATUS LABEL ═══
SoundStatusLabel = Instance.new("TextLabel")
SoundStatusLabel.Size = UDim2.new(1, -20, 0, 24)
SoundStatusLabel.Position = UDim2.new(0, 10, 0, 196)
SoundStatusLabel.BackgroundColor3 = Color3.fromRGB(20, 26, 22)
SoundStatusLabel.Text = "No sound playing"
SoundStatusLabel.TextColor3 = Color3.fromRGB(80, 200, 100)
SoundStatusLabel.TextSize = 10
SoundStatusLabel.Font = Enum.Font.Code
SoundStatusLabel.TextXAlignment = Enum.TextXAlignment.Center
SoundStatusLabel.Parent = SoundPlayerPanel
Instance.new("UICorner", SoundStatusLabel).CornerRadius = UDim.new(0, 4)

SoundStatusStroke = Instance.new("UIStroke", SoundStatusLabel)
SoundStatusStroke.Color = Color3.fromRGB(60, 120, 70)
SoundStatusStroke.Thickness = 1

-- ═══ MAP SOUNDS ═══
MapSoundsBtn = Instance.new("TextButton")
MapSoundsBtn.Size = UDim2.new(1, -20, 0, 30)
MapSoundsBtn.Position = UDim2.new(0, 10, 0, 228)
MapSoundsBtn.BackgroundColor3 = Colors.glowPurple
MapSoundsBtn.Text = "🗺 LIST MAP SOUNDS"
MapSoundsBtn.TextColor3 = Colors.text
MapSoundsBtn.TextSize = 11
MapSoundsBtn.Font = Enum.Font.GothamBold
MapSoundsBtn.AutoButtonColor = false
MapSoundsBtn.Parent = SoundPlayerPanel
Instance.new("UICorner", MapSoundsBtn).CornerRadius = UDim.new(0, 8)
addBtnGradient(MapSoundsBtn)
makeHoverable(MapSoundsBtn, Colors.glowPurple, Color3.fromRGB(140, 110, 255))

-- Lista de sons do mapa
MapSoundsScroll = Instance.new("ScrollingFrame")
MapSoundsScroll.Size = UDim2.new(1, -20, 0, 100)
MapSoundsScroll.Position = UDim2.new(0, 10, 0, 264)
MapSoundsScroll.BackgroundColor3 = Color3.fromRGB(16, 20, 18)
MapSoundsScroll.ScrollBarThickness = 2
MapSoundsScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 200, 100)
MapSoundsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MapSoundsScroll.BorderSizePixel = 0
MapSoundsScroll.Parent = SoundPlayerPanel
Instance.new("UICorner", MapSoundsScroll).CornerRadius = UDim.new(0, 6)

MapSoundsScrollStroke = Instance.new("UIStroke", MapSoundsScroll)
MapSoundsScrollStroke.Color = Color3.fromRGB(50, 100, 60)
MapSoundsScrollStroke.Thickness = 1

MapSoundsScrollLayout = Instance.new("UIListLayout", MapSoundsScroll)
MapSoundsScrollLayout.Padding = UDim.new(0, 2)

-- ═══ PLAY ALL / STOP ALL ═══
MapSoundsPlayAllBtn = Instance.new("TextButton")
MapSoundsPlayAllBtn.Size = UDim2.new(0.48, -5, 0, 28)
MapSoundsPlayAllBtn.Position = UDim2.new(0, 10, 0, 370)
MapSoundsPlayAllBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
MapSoundsPlayAllBtn.Text = "▶ PLAY ALL"
MapSoundsPlayAllBtn.TextColor3 = Colors.text
MapSoundsPlayAllBtn.TextSize = 10
MapSoundsPlayAllBtn.Font = Enum.Font.GothamBold
MapSoundsPlayAllBtn.AutoButtonColor = false
MapSoundsPlayAllBtn.Parent = SoundPlayerPanel
Instance.new("UICorner", MapSoundsPlayAllBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(MapSoundsPlayAllBtn)
makeHoverable(MapSoundsPlayAllBtn, Color3.fromRGB(40, 140, 60), Color3.fromRGB(60, 180, 80))

MapSoundsStopAllBtn = Instance.new("TextButton")
MapSoundsStopAllBtn.Size = UDim2.new(0.48, -5, 0, 28)
MapSoundsStopAllBtn.Position = UDim2.new(0.52, 5, 0, 370)
MapSoundsStopAllBtn.BackgroundColor3 = Colors.bloodDark
MapSoundsStopAllBtn.Text = "⏹ STOP ALL"
MapSoundsStopAllBtn.TextColor3 = Colors.text
MapSoundsStopAllBtn.TextSize = 10
MapSoundsStopAllBtn.Font = Enum.Font.GothamBold
MapSoundsStopAllBtn.AutoButtonColor = false
MapSoundsStopAllBtn.Parent = SoundPlayerPanel
Instance.new("UICorner", MapSoundsStopAllBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(MapSoundsStopAllBtn)
makeHoverable(MapSoundsStopAllBtn, Colors.bloodDark, Colors.blood)

-- Drag setup no 14_drag.luau


--[[ ═══════ MODULE: 09g_backpack_panel.luau ═══════ ]]

--==================================================
-- BACKPACK VIEWER PANEL — FLOATING
-- Visualiza tools/items de qualquer player
-- Todas as variaveis sao GLOBALS para nao gastar locals
--==================================================

BackpackPanel = Instance.new("Frame")
BackpackPanel.Name = "BackpackPanel"
BackpackPanel.Size = UDim2.new(0, 260, 0, 420)
BackpackPanel.Position = UDim2.new(0.5, 160, 0.5, -210)
BackpackPanel.BackgroundColor3 = Colors.bg
BackpackPanel.BorderSizePixel = 0
BackpackPanel.Visible = false
BackpackPanel.Parent = ScreenGui

Instance.new("UICorner", BackpackPanel).CornerRadius = UDim.new(0, 10)
BackpackPanelStroke = Instance.new("UIStroke", BackpackPanel)
BackpackPanelStroke.Color = Color3.fromRGB(200, 140, 40)
BackpackPanelStroke.Thickness = 1.5
addGradient(BackpackPanel, Colors.surfaceLight, Color3.fromRGB(12, 10, 6), 90)

--==================================================
-- TOP BAR
--==================================================

BackpackTopBar = Instance.new("Frame")
BackpackTopBar.Size = UDim2.new(1, 0, 0, 32)
BackpackTopBar.BackgroundColor3 = Colors.topbar
BackpackTopBar.BorderSizePixel = 0
BackpackTopBar.Parent = BackpackPanel
Instance.new("UICorner", BackpackTopBar).CornerRadius = UDim.new(0, 10)
addGradient(BackpackTopBar, Color3.fromRGB(28, 18, 6), Colors.topbar, 0)

BackpackTopBarFix = Instance.new("Frame")
BackpackTopBarFix.Size = UDim2.new(1, 0, 0, 10)
BackpackTopBarFix.Position = UDim2.new(0, 0, 1, -10)
BackpackTopBarFix.BackgroundColor3 = Colors.topbar
BackpackTopBarFix.BorderSizePixel = 0
BackpackTopBarFix.Parent = BackpackTopBar

addAccentLine(BackpackTopBar, UDim2.new(0, 0, 1, -1), Color3.fromRGB(200, 140, 40))

BackpackTitle = Instance.new("TextLabel")
BackpackTitle.Size = UDim2.new(1, -40, 1, 0)
BackpackTitle.Position = UDim2.new(0, 10, 0, 0)
BackpackTitle.BackgroundTransparency = 1
BackpackTitle.Text = "Backpack Viewer"
BackpackTitle.TextColor3 = Color3.fromRGB(240, 180, 60)
BackpackTitle.TextSize = 12
BackpackTitle.Font = Enum.Font.GothamBold
BackpackTitle.TextXAlignment = Enum.TextXAlignment.Left
BackpackTitle.Parent = BackpackTopBar

BackpackCloseX = Instance.new("TextButton")
BackpackCloseX.Size = UDim2.new(0, 20, 0, 20)
BackpackCloseX.Position = UDim2.new(1, -26, 0, 6)
BackpackCloseX.BackgroundColor3 = Color3.fromRGB(160, 110, 30)
BackpackCloseX.Text = "X"
BackpackCloseX.TextColor3 = Colors.text
BackpackCloseX.TextSize = 11
BackpackCloseX.Font = Enum.Font.GothamBold
BackpackCloseX.AutoButtonColor = false
BackpackCloseX.Parent = BackpackTopBar
Instance.new("UICorner", BackpackCloseX).CornerRadius = UDim.new(0, 6)
makeHoverable(BackpackCloseX, Color3.fromRGB(160, 110, 30), Color3.fromRGB(200, 140, 40))

--==================================================
-- PLAYER INFO ROW
--==================================================

BackpackThumb = Instance.new("ImageLabel")
BackpackThumb.Size = UDim2.new(0, 36, 0, 36)
BackpackThumb.Position = UDim2.new(0, 10, 0, 40)
BackpackThumb.BackgroundColor3 = Colors.content
BackpackThumb.Image = ""
BackpackThumb.Parent = BackpackPanel
Instance.new("UICorner", BackpackThumb).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", BackpackThumb).Color = Color3.fromRGB(200, 140, 40)

BackpackPlayerName = Instance.new("TextLabel")
BackpackPlayerName.Size = UDim2.new(0, 130, 0, 16)
BackpackPlayerName.Position = UDim2.new(0, 52, 0, 42)
BackpackPlayerName.BackgroundTransparency = 1
BackpackPlayerName.Text = "Player"
BackpackPlayerName.TextColor3 = Colors.text
BackpackPlayerName.TextSize = 11
BackpackPlayerName.Font = Enum.Font.GothamBold
BackpackPlayerName.TextXAlignment = Enum.TextXAlignment.Left
BackpackPlayerName.TextTruncate = Enum.TextTruncate.AtEnd
BackpackPlayerName.Parent = BackpackPanel

BackpackPlayerUser = Instance.new("TextLabel")
BackpackPlayerUser.Size = UDim2.new(0, 130, 0, 12)
BackpackPlayerUser.Position = UDim2.new(0, 52, 0, 58)
BackpackPlayerUser.BackgroundTransparency = 1
BackpackPlayerUser.Text = "@username"
BackpackPlayerUser.TextColor3 = Colors.textDim
BackpackPlayerUser.TextSize = 9
BackpackPlayerUser.Font = Enum.Font.Gotham
BackpackPlayerUser.TextXAlignment = Enum.TextXAlignment.Left
BackpackPlayerUser.TextTruncate = Enum.TextTruncate.AtEnd
BackpackPlayerUser.Parent = BackpackPanel

BackpackRefreshBtn = Instance.new("TextButton")
BackpackRefreshBtn.Size = UDim2.new(0, 60, 0, 22)
BackpackRefreshBtn.Position = UDim2.new(1, -70, 0, 47)
BackpackRefreshBtn.BackgroundColor3 = Color3.fromRGB(160, 110, 30)
BackpackRefreshBtn.Text = "REFRESH"
BackpackRefreshBtn.TextColor3 = Colors.text
BackpackRefreshBtn.TextSize = 9
BackpackRefreshBtn.Font = Enum.Font.GothamBold
BackpackRefreshBtn.AutoButtonColor = false
BackpackRefreshBtn.Parent = BackpackPanel
Instance.new("UICorner", BackpackRefreshBtn).CornerRadius = UDim.new(0, 4)
makeHoverable(BackpackRefreshBtn, Color3.fromRGB(160, 110, 30), Color3.fromRGB(200, 140, 40))

--==================================================
-- FILTER
--==================================================

BackpackFilterBox = Instance.new("TextBox")
BackpackFilterBox.Size = UDim2.new(1, -20, 0, 22)
BackpackFilterBox.Position = UDim2.new(0, 10, 0, 84)
BackpackFilterBox.BackgroundColor3 = Colors.inputBg
BackpackFilterBox.Text = ""
BackpackFilterBox.PlaceholderText = "Filter tools..."
BackpackFilterBox.PlaceholderColor3 = Colors.textDim
BackpackFilterBox.TextColor3 = Colors.text
BackpackFilterBox.TextSize = 10
BackpackFilterBox.Font = Enum.Font.Code
BackpackFilterBox.TextXAlignment = Enum.TextXAlignment.Left
BackpackFilterBox.ClearTextOnFocus = false
BackpackFilterBox.Parent = BackpackPanel
Instance.new("UICorner", BackpackFilterBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", BackpackFilterBox).PaddingLeft = UDim.new(0, 6)
BackpackFilterStroke = Instance.new("UIStroke", BackpackFilterBox)
BackpackFilterStroke.Color = Colors.separator
BackpackFilterStroke.Thickness = 0.5

--==================================================
-- TOOL LIST SCROLL
--==================================================

addAccentLine(BackpackPanel, UDim2.new(0, 10, 0, 112), Color3.fromRGB(200, 140, 40), UDim2.new(1, -20, 0, 1))

BackpackListScroll = Instance.new("ScrollingFrame")
BackpackListScroll.Size = UDim2.new(1, -20, 0, 250)
BackpackListScroll.Position = UDim2.new(0, 10, 0, 116)
BackpackListScroll.BackgroundColor3 = Colors.content
BackpackListScroll.BorderSizePixel = 0
BackpackListScroll.ScrollBarThickness = 3
BackpackListScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 140, 40)
BackpackListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
BackpackListScroll.Parent = BackpackPanel
Instance.new("UICorner", BackpackListScroll).CornerRadius = UDim.new(0, 6)
BackpackListStroke = Instance.new("UIStroke", BackpackListScroll)
BackpackListStroke.Color = Colors.separator
BackpackListStroke.Thickness = 0.5
BackpackListStroke.Transparency = 0.5

BackpackListLayout = Instance.new("UIListLayout")
BackpackListLayout.Padding = UDim.new(0, 3)
BackpackListLayout.Parent = BackpackListScroll
BackpackListPad = Instance.new("UIPadding", BackpackListScroll)
BackpackListPad.PaddingTop = UDim.new(0, 4)
BackpackListPad.PaddingLeft = UDim.new(0, 4)

--==================================================
-- STATS + BOTTOM BUTTONS
--==================================================

BackpackStatsLabel = Instance.new("TextLabel")
BackpackStatsLabel.Size = UDim2.new(1, -20, 0, 14)
BackpackStatsLabel.Position = UDim2.new(0, 10, 0, 372)
BackpackStatsLabel.BackgroundTransparency = 1
BackpackStatsLabel.Text = "Tools: 0"
BackpackStatsLabel.TextColor3 = Colors.textDim
BackpackStatsLabel.TextSize = 10
BackpackStatsLabel.Font = Enum.Font.GothamBold
BackpackStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
BackpackStatsLabel.Parent = BackpackPanel

BackpackCloseBtn = Instance.new("TextButton")
BackpackCloseBtn.Size = UDim2.new(1, -20, 0, 24)
BackpackCloseBtn.Position = UDim2.new(0, 10, 0, 390)
BackpackCloseBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 20)
BackpackCloseBtn.Text = "CLOSE"
BackpackCloseBtn.TextColor3 = Colors.text
BackpackCloseBtn.TextSize = 11
BackpackCloseBtn.Font = Enum.Font.GothamBold
BackpackCloseBtn.AutoButtonColor = false
BackpackCloseBtn.Parent = BackpackPanel
Instance.new("UICorner", BackpackCloseBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(BackpackCloseBtn, Color3.fromRGB(120, 80, 20), Color3.fromRGB(160, 110, 30))

--==================================================
-- SCAN + REFRESH FUNCTIONS
--==================================================

scanBackpack = function(player)
    backpackItems = {}
    pcall(function()
        -- 1. Backpack (tools nao equipadas)
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, tool in pairs(bp:GetChildren()) do
                table.insert(backpackItems, {
                    name = tool.Name,
                    class = tool.ClassName,
                    location = "Backpack",
                    texture = tool:IsA("Tool") and tool.TextureId or "",
                    instance = tool,
                })
            end
        end
        -- 2. Character (tool equipada na mao)
        local char = player.Character
        if char then
            for _, obj in pairs(char:GetChildren()) do
                if obj:IsA("Tool") or obj:IsA("HopperBin") then
                    table.insert(backpackItems, {
                        name = obj.Name,
                        class = obj.ClassName,
                        location = "Equipped",
                        texture = obj:IsA("Tool") and obj.TextureId or "",
                        instance = obj,
                    })
                end
            end
        end
        -- 3. StarterGear (persistente)
        local sg = player:FindFirstChild("StarterGear")
        if sg then
            for _, tool in pairs(sg:GetChildren()) do
                table.insert(backpackItems, {
                    name = tool.Name,
                    class = tool.ClassName,
                    location = "StarterGear",
                    texture = tool:IsA("Tool") and tool.TextureId or "",
                    instance = tool,
                })
            end
        end
    end)
    table.sort(backpackItems, function(a, b) return a.name < b.name end)
end

refreshBackpackList = function()
    for _, child in ipairs(BackpackListScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local filter = BackpackFilterBox.Text:lower()
    local count = 0

    for _, item in ipairs(backpackItems) do
        local match = true
        if filter ~= "" then
            if not item.name:lower():find(filter, 1, true) and not item.class:lower():find(filter, 1, true) then
                match = false
            end
        end

        if match then
            -- Card frame
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -8, 0, 38)
            card.BackgroundColor3 = Color3.fromRGB(25, 22, 18)
            card.BorderSizePixel = 0
            card.Parent = BackpackListScroll
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 4)

            -- Location color indicator (barra lateral)
            local locBar = Instance.new("Frame")
            locBar.Size = UDim2.new(0, 3, 1, -6)
            locBar.Position = UDim2.new(0, 2, 0, 3)
            locBar.BorderSizePixel = 0
            locBar.Parent = card
            Instance.new("UICorner", locBar).CornerRadius = UDim.new(0, 2)

            if item.location == "Equipped" then
                locBar.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
            elseif item.location == "StarterGear" then
                locBar.BackgroundColor3 = Color3.fromRGB(160, 100, 220)
            else
                locBar.BackgroundColor3 = Color3.fromRGB(80, 150, 220)
            end

            -- Tool name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -14, 0, 14)
            nameLabel.Position = UDim2.new(0, 10, 0, 3)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = item.name
            nameLabel.TextColor3 = Colors.text
            nameLabel.TextSize = 10
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = card

            -- Class + location
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, -14, 0, 12)
            infoLabel.Position = UDim2.new(0, 10, 0, 18)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = item.class .. " | " .. item.location
            infoLabel.TextColor3 = Colors.textDim
            infoLabel.TextSize = 9
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
            infoLabel.Parent = card

            count = count + 1
        end
    end

    BackpackListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 41 + 8)
    BackpackStatsLabel.Text = "Tools: " .. count .. (#backpackItems ~= count and (" / " .. #backpackItems .. " total") or "")
end

--==================================================
-- OPEN FUNCTION
--==================================================

openBackpackPanel = function(player)
    backpackTarget = player
    BackpackTitle.Text = "Backpack — " .. player.DisplayName
    BackpackPlayerName.Text = player.DisplayName
    BackpackPlayerUser.Text = "@" .. player.Name

    -- Thumbnail async
    task.spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
        end)
        if ok and thumb then BackpackThumb.Image = thumb end
    end)

    scanBackpack(player)
    refreshBackpackList()
    BackpackPanel.Visible = true
end


--[[ ═══════ MODULE: 09h_tab_graphics.luau ═══════ ]]

--==================================================
-- TAB: GRAPHICS (FPS Boost + Shaders + Environment)
--==================================================

GfxContent = Instance.new("Frame")
GfxContent.Name = "GfxContent"
GfxContent.Size = UDim2.new(1, 0, 1, 0)
GfxContent.BackgroundTransparency = 1
GfxContent.Visible = false
GfxContent.Parent = TabContent
tabContents["graphics"] = GfxContent

GfxScroll = Instance.new("ScrollingFrame")
GfxScroll.Size = UDim2.new(1, 0, 1, 0)
GfxScroll.BackgroundTransparency = 1
GfxScroll.ScrollBarThickness = 3
GfxScroll.ScrollBarImageColor3 = Colors.glowPurple
GfxScroll.CanvasSize = UDim2.new(0, 0, 0, 1380)
GfxScroll.BorderSizePixel = 0
GfxScroll.Parent = GfxContent

--==================================================
-- FPS BOOST SECTION
--==================================================

createSectionHeader(GfxScroll, "FPS Boost", 8)

GfxLowBtn = Instance.new("TextButton")
GfxLowBtn.Size = UDim2.new(1, -16, 0, 32)
GfxLowBtn.Position = UDim2.new(0, 8, 0, 34)
GfxLowBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
GfxLowBtn.Text = "LOW GFX"
GfxLowBtn.TextColor3 = Colors.text
GfxLowBtn.TextSize = 12
GfxLowBtn.Font = Enum.Font.GothamBold
GfxLowBtn.AutoButtonColor = false
GfxLowBtn.Parent = GfxScroll
Instance.new("UICorner", GfxLowBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxLowBtn)
makeHoverable(GfxLowBtn, Color3.fromRGB(40, 140, 60), Color3.fromRGB(60, 180, 80))

GfxUltraLowBtn = Instance.new("TextButton")
GfxUltraLowBtn.Size = UDim2.new(1, -16, 0, 32)
GfxUltraLowBtn.Position = UDim2.new(0, 8, 0, 72)
GfxUltraLowBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 40)
GfxUltraLowBtn.Text = "ULTRA LOW"
GfxUltraLowBtn.TextColor3 = Colors.text
GfxUltraLowBtn.TextSize = 12
GfxUltraLowBtn.Font = Enum.Font.GothamBold
GfxUltraLowBtn.AutoButtonColor = false
GfxUltraLowBtn.Parent = GfxScroll
Instance.new("UICorner", GfxUltraLowBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxUltraLowBtn)
makeHoverable(GfxUltraLowBtn, Color3.fromRGB(30, 100, 40), Color3.fromRGB(50, 130, 60))

GfxUltraHighBtn = Instance.new("TextButton")
GfxUltraHighBtn.Size = UDim2.new(1, -16, 0, 32)
GfxUltraHighBtn.Position = UDim2.new(0, 8, 0, 110)
GfxUltraHighBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 180)
GfxUltraHighBtn.Text = "ULTRA HIGH"
GfxUltraHighBtn.TextColor3 = Colors.text
GfxUltraHighBtn.TextSize = 12
GfxUltraHighBtn.Font = Enum.Font.GothamBold
GfxUltraHighBtn.AutoButtonColor = false
GfxUltraHighBtn.Parent = GfxScroll
Instance.new("UICorner", GfxUltraHighBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxUltraHighBtn)
makeHoverable(GfxUltraHighBtn, Color3.fromRGB(140, 40, 180), Color3.fromRGB(170, 60, 220))

GfxRestoreBtn = Instance.new("TextButton")
GfxRestoreBtn.Size = UDim2.new(1, -16, 0, 26)
GfxRestoreBtn.Position = UDim2.new(0, 8, 0, 148)
GfxRestoreBtn.BackgroundColor3 = Color3.fromRGB(180, 130, 30)
GfxRestoreBtn.Text = "RESTORE ORIGINAL"
GfxRestoreBtn.TextColor3 = Colors.text
GfxRestoreBtn.TextSize = 10
GfxRestoreBtn.Font = Enum.Font.GothamBold
GfxRestoreBtn.AutoButtonColor = false
GfxRestoreBtn.Parent = GfxScroll
Instance.new("UICorner", GfxRestoreBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(GfxRestoreBtn, Color3.fromRGB(180, 130, 30), Color3.fromRGB(220, 160, 40))

GfxFpsStatus = Instance.new("TextLabel")
GfxFpsStatus.Size = UDim2.new(1, -16, 0, 18)
GfxFpsStatus.Position = UDim2.new(0, 8, 0, 180)
GfxFpsStatus.BackgroundTransparency = 1
GfxFpsStatus.Text = "Mode: Default"
GfxFpsStatus.TextColor3 = Colors.textDim
GfxFpsStatus.TextSize = 9
GfxFpsStatus.Font = Enum.Font.Code
GfxFpsStatus.TextXAlignment = Enum.TextXAlignment.Left
GfxFpsStatus.Parent = GfxScroll

--==================================================
-- SHADERS SECTION
--==================================================

createSectionHeader(GfxScroll, "Shaders", 206)

-- ═══ Row 1: RTX, CINE, NEON, MIRROR ═══
GfxRtxBtn = Instance.new("TextButton")
GfxRtxBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxRtxBtn.Position = UDim2.new(0, 8, 0, 232)
GfxRtxBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 200)
GfxRtxBtn.Text = "RTX"
GfxRtxBtn.TextColor3 = Colors.text
GfxRtxBtn.TextSize = 11
GfxRtxBtn.Font = Enum.Font.GothamBold
GfxRtxBtn.AutoButtonColor = false
GfxRtxBtn.Parent = GfxScroll
Instance.new("UICorner", GfxRtxBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxRtxBtn)
makeHoverable(GfxRtxBtn, Color3.fromRGB(140, 60, 200), Color3.fromRGB(180, 90, 255))

GfxCineBtn = Instance.new("TextButton")
GfxCineBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxCineBtn.Position = UDim2.new(0.25, 5, 0, 232)
GfxCineBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
GfxCineBtn.Text = "CINE"
GfxCineBtn.TextColor3 = Colors.text
GfxCineBtn.TextSize = 11
GfxCineBtn.Font = Enum.Font.GothamBold
GfxCineBtn.AutoButtonColor = false
GfxCineBtn.Parent = GfxScroll
Instance.new("UICorner", GfxCineBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxCineBtn)
makeHoverable(GfxCineBtn, Color3.fromRGB(40, 80, 160), Color3.fromRGB(60, 110, 200))

GfxNeonBtn = Instance.new("TextButton")
GfxNeonBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxNeonBtn.Position = UDim2.new(0.5, 5, 0, 232)
GfxNeonBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 120)
GfxNeonBtn.Text = "NEON"
GfxNeonBtn.TextColor3 = Colors.text
GfxNeonBtn.TextSize = 11
GfxNeonBtn.Font = Enum.Font.GothamBold
GfxNeonBtn.AutoButtonColor = false
GfxNeonBtn.Parent = GfxScroll
Instance.new("UICorner", GfxNeonBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxNeonBtn)
makeHoverable(GfxNeonBtn, Color3.fromRGB(200, 40, 120), Color3.fromRGB(240, 80, 160))

GfxMirrorBtn = Instance.new("TextButton")
GfxMirrorBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxMirrorBtn.Position = UDim2.new(0.75, 5, 0, 232)
GfxMirrorBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 180)
GfxMirrorBtn.Text = "MIRROR"
GfxMirrorBtn.TextColor3 = Colors.text
GfxMirrorBtn.TextSize = 10
GfxMirrorBtn.Font = Enum.Font.GothamBold
GfxMirrorBtn.AutoButtonColor = false
GfxMirrorBtn.Parent = GfxScroll
Instance.new("UICorner", GfxMirrorBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxMirrorBtn)
makeHoverable(GfxMirrorBtn, Color3.fromRGB(40, 160, 180), Color3.fromRGB(60, 200, 220))

-- ═══ Row 2: VHS, NOIR, SUNSET, AQUA ═══
GfxVhsBtn = Instance.new("TextButton")
GfxVhsBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxVhsBtn.Position = UDim2.new(0, 8, 0, 276)
GfxVhsBtn.BackgroundColor3 = Color3.fromRGB(160, 120, 60)
GfxVhsBtn.Text = "VHS"
GfxVhsBtn.TextColor3 = Colors.text
GfxVhsBtn.TextSize = 11
GfxVhsBtn.Font = Enum.Font.GothamBold
GfxVhsBtn.AutoButtonColor = false
GfxVhsBtn.Parent = GfxScroll
Instance.new("UICorner", GfxVhsBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxVhsBtn)
makeHoverable(GfxVhsBtn, Color3.fromRGB(160, 120, 60), Color3.fromRGB(200, 160, 80))

GfxNoirBtn = Instance.new("TextButton")
GfxNoirBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxNoirBtn.Position = UDim2.new(0.25, 5, 0, 276)
GfxNoirBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GfxNoirBtn.Text = "NOIR"
GfxNoirBtn.TextColor3 = Colors.text
GfxNoirBtn.TextSize = 11
GfxNoirBtn.Font = Enum.Font.GothamBold
GfxNoirBtn.AutoButtonColor = false
GfxNoirBtn.Parent = GfxScroll
Instance.new("UICorner", GfxNoirBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxNoirBtn)
makeHoverable(GfxNoirBtn, Color3.fromRGB(60, 60, 60), Color3.fromRGB(100, 100, 100))

GfxSunsetBtn = Instance.new("TextButton")
GfxSunsetBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxSunsetBtn.Position = UDim2.new(0.5, 5, 0, 276)
GfxSunsetBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 40)
GfxSunsetBtn.Text = "SUNSET"
GfxSunsetBtn.TextColor3 = Colors.text
GfxSunsetBtn.TextSize = 10
GfxSunsetBtn.Font = Enum.Font.GothamBold
GfxSunsetBtn.AutoButtonColor = false
GfxSunsetBtn.Parent = GfxScroll
Instance.new("UICorner", GfxSunsetBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxSunsetBtn)
makeHoverable(GfxSunsetBtn, Color3.fromRGB(200, 120, 40), Color3.fromRGB(240, 160, 60))

GfxAquaBtn = Instance.new("TextButton")
GfxAquaBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxAquaBtn.Position = UDim2.new(0.75, 5, 0, 276)
GfxAquaBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 140)
GfxAquaBtn.Text = "AQUA"
GfxAquaBtn.TextColor3 = Colors.text
GfxAquaBtn.TextSize = 11
GfxAquaBtn.Font = Enum.Font.GothamBold
GfxAquaBtn.AutoButtonColor = false
GfxAquaBtn.Parent = GfxScroll
Instance.new("UICorner", GfxAquaBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxAquaBtn)
makeHoverable(GfxAquaBtn, Color3.fromRGB(30, 80, 140), Color3.fromRGB(50, 120, 180))

-- ═══ Row 3: DREAM, HORROR, ARCTIC, VAPOR ═══
GfxDreamBtn = Instance.new("TextButton")
GfxDreamBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxDreamBtn.Position = UDim2.new(0, 8, 0, 320)
GfxDreamBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 220)
GfxDreamBtn.Text = "DREAM"
GfxDreamBtn.TextColor3 = Color3.fromRGB(30, 30, 30)
GfxDreamBtn.TextSize = 10
GfxDreamBtn.Font = Enum.Font.GothamBold
GfxDreamBtn.AutoButtonColor = false
GfxDreamBtn.Parent = GfxScroll
Instance.new("UICorner", GfxDreamBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxDreamBtn)
makeHoverable(GfxDreamBtn, Color3.fromRGB(180, 140, 220), Color3.fromRGB(220, 180, 255))

GfxHorrorBtn = Instance.new("TextButton")
GfxHorrorBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxHorrorBtn.Position = UDim2.new(0.25, 5, 0, 320)
GfxHorrorBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
GfxHorrorBtn.Text = "HORROR"
GfxHorrorBtn.TextColor3 = Colors.text
GfxHorrorBtn.TextSize = 10
GfxHorrorBtn.Font = Enum.Font.GothamBold
GfxHorrorBtn.AutoButtonColor = false
GfxHorrorBtn.Parent = GfxScroll
Instance.new("UICorner", GfxHorrorBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxHorrorBtn)
makeHoverable(GfxHorrorBtn, Color3.fromRGB(140, 20, 20), Color3.fromRGB(200, 40, 40))

GfxArcticBtn = Instance.new("TextButton")
GfxArcticBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxArcticBtn.Position = UDim2.new(0.5, 5, 0, 320)
GfxArcticBtn.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
GfxArcticBtn.Text = "ARCTIC"
GfxArcticBtn.TextColor3 = Color3.fromRGB(20, 20, 40)
GfxArcticBtn.TextSize = 10
GfxArcticBtn.Font = Enum.Font.GothamBold
GfxArcticBtn.AutoButtonColor = false
GfxArcticBtn.Parent = GfxScroll
Instance.new("UICorner", GfxArcticBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxArcticBtn)
makeHoverable(GfxArcticBtn, Color3.fromRGB(180, 220, 255), Color3.fromRGB(220, 240, 255))

GfxVaporBtn = Instance.new("TextButton")
GfxVaporBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxVaporBtn.Position = UDim2.new(0.75, 5, 0, 320)
GfxVaporBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 200)
GfxVaporBtn.Text = "VAPOR"
GfxVaporBtn.TextColor3 = Colors.text
GfxVaporBtn.TextSize = 10
GfxVaporBtn.Font = Enum.Font.GothamBold
GfxVaporBtn.AutoButtonColor = false
GfxVaporBtn.Parent = GfxScroll
Instance.new("UICorner", GfxVaporBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxVaporBtn)
makeHoverable(GfxVaporBtn, Color3.fromRGB(200, 80, 200), Color3.fromRGB(240, 120, 240))

-- ═══ Row 4: CYBER, VINTAGE, GALAXY, TOXIC ═══
GfxCyberBtn = Instance.new("TextButton")
GfxCyberBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxCyberBtn.Position = UDim2.new(0, 8, 0, 364)
GfxCyberBtn.BackgroundColor3 = Color3.fromRGB(20, 180, 100)
GfxCyberBtn.Text = "CYBER"
GfxCyberBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
GfxCyberBtn.TextSize = 10
GfxCyberBtn.Font = Enum.Font.GothamBold
GfxCyberBtn.AutoButtonColor = false
GfxCyberBtn.Parent = GfxScroll
Instance.new("UICorner", GfxCyberBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxCyberBtn)
makeHoverable(GfxCyberBtn, Color3.fromRGB(20, 180, 100), Color3.fromRGB(40, 220, 130))

GfxVintageBtn = Instance.new("TextButton")
GfxVintageBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxVintageBtn.Position = UDim2.new(0.25, 5, 0, 364)
GfxVintageBtn.BackgroundColor3 = Color3.fromRGB(160, 140, 100)
GfxVintageBtn.Text = "VNTGE"
GfxVintageBtn.TextColor3 = Color3.fromRGB(30, 20, 10)
GfxVintageBtn.TextSize = 10
GfxVintageBtn.Font = Enum.Font.GothamBold
GfxVintageBtn.AutoButtonColor = false
GfxVintageBtn.Parent = GfxScroll
Instance.new("UICorner", GfxVintageBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxVintageBtn)
makeHoverable(GfxVintageBtn, Color3.fromRGB(160, 140, 100), Color3.fromRGB(200, 180, 130))

GfxGalaxyBtn = Instance.new("TextButton")
GfxGalaxyBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxGalaxyBtn.Position = UDim2.new(0.5, 5, 0, 364)
GfxGalaxyBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 100)
GfxGalaxyBtn.Text = "GALAXY"
GfxGalaxyBtn.TextColor3 = Colors.text
GfxGalaxyBtn.TextSize = 10
GfxGalaxyBtn.Font = Enum.Font.GothamBold
GfxGalaxyBtn.AutoButtonColor = false
GfxGalaxyBtn.Parent = GfxScroll
Instance.new("UICorner", GfxGalaxyBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxGalaxyBtn)
makeHoverable(GfxGalaxyBtn, Color3.fromRGB(40, 20, 100), Color3.fromRGB(80, 40, 160))

GfxToxicBtn = Instance.new("TextButton")
GfxToxicBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxToxicBtn.Position = UDim2.new(0.75, 5, 0, 364)
GfxToxicBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 20)
GfxToxicBtn.Text = "TOXIC"
GfxToxicBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
GfxToxicBtn.TextSize = 10
GfxToxicBtn.Font = Enum.Font.GothamBold
GfxToxicBtn.AutoButtonColor = false
GfxToxicBtn.Parent = GfxScroll
Instance.new("UICorner", GfxToxicBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxToxicBtn)
makeHoverable(GfxToxicBtn, Color3.fromRGB(80, 180, 20), Color3.fromRGB(120, 220, 40))

-- ═══ Row 5: AUTUMN, SAKURA, MATRIX, BLEACH ═══
GfxAutumnBtn = Instance.new("TextButton")
GfxAutumnBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxAutumnBtn.Position = UDim2.new(0, 8, 0, 408)
GfxAutumnBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 30)
GfxAutumnBtn.Text = "AUTMN"
GfxAutumnBtn.TextColor3 = Colors.text
GfxAutumnBtn.TextSize = 10
GfxAutumnBtn.Font = Enum.Font.GothamBold
GfxAutumnBtn.AutoButtonColor = false
GfxAutumnBtn.Parent = GfxScroll
Instance.new("UICorner", GfxAutumnBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxAutumnBtn)
makeHoverable(GfxAutumnBtn, Color3.fromRGB(180, 100, 30), Color3.fromRGB(220, 140, 50))

GfxSakuraBtn = Instance.new("TextButton")
GfxSakuraBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxSakuraBtn.Position = UDim2.new(0.25, 5, 0, 408)
GfxSakuraBtn.BackgroundColor3 = Color3.fromRGB(240, 140, 180)
GfxSakuraBtn.Text = "SAKRA"
GfxSakuraBtn.TextColor3 = Color3.fromRGB(30, 10, 20)
GfxSakuraBtn.TextSize = 10
GfxSakuraBtn.Font = Enum.Font.GothamBold
GfxSakuraBtn.AutoButtonColor = false
GfxSakuraBtn.Parent = GfxScroll
Instance.new("UICorner", GfxSakuraBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxSakuraBtn)
makeHoverable(GfxSakuraBtn, Color3.fromRGB(240, 140, 180), Color3.fromRGB(255, 180, 210))

GfxMatrixBtn = Instance.new("TextButton")
GfxMatrixBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxMatrixBtn.Position = UDim2.new(0.5, 5, 0, 408)
GfxMatrixBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
GfxMatrixBtn.Text = "MTRX"
GfxMatrixBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
GfxMatrixBtn.TextSize = 10
GfxMatrixBtn.Font = Enum.Font.GothamBold
GfxMatrixBtn.AutoButtonColor = false
GfxMatrixBtn.Parent = GfxScroll
Instance.new("UICorner", GfxMatrixBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxMatrixBtn)
makeHoverable(GfxMatrixBtn, Color3.fromRGB(0, 100, 0), Color3.fromRGB(0, 160, 0))

GfxBleachBtn = Instance.new("TextButton")
GfxBleachBtn.Size = UDim2.new(0.25, -6, 0, 38)
GfxBleachBtn.Position = UDim2.new(0.75, 5, 0, 408)
GfxBleachBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
GfxBleachBtn.Text = "BLCH"
GfxBleachBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
GfxBleachBtn.TextSize = 10
GfxBleachBtn.Font = Enum.Font.GothamBold
GfxBleachBtn.AutoButtonColor = false
GfxBleachBtn.Parent = GfxScroll
Instance.new("UICorner", GfxBleachBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxBleachBtn)
makeHoverable(GfxBleachBtn, Color3.fromRGB(200, 200, 210), Color3.fromRGB(240, 240, 250))

-- REMOVE SHADERS button
GfxRemoveShadersBtn = Instance.new("TextButton")
GfxRemoveShadersBtn.Size = UDim2.new(1, -16, 0, 24)
GfxRemoveShadersBtn.Position = UDim2.new(0, 8, 0, 452)
GfxRemoveShadersBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
GfxRemoveShadersBtn.Text = "REMOVE SHADERS"
GfxRemoveShadersBtn.TextColor3 = Colors.textDim
GfxRemoveShadersBtn.TextSize = 9
GfxRemoveShadersBtn.Font = Enum.Font.GothamBold
GfxRemoveShadersBtn.AutoButtonColor = false
GfxRemoveShadersBtn.Parent = GfxScroll
Instance.new("UICorner", GfxRemoveShadersBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(GfxRemoveShadersBtn, Color3.fromRGB(60, 60, 70), Color3.fromRGB(90, 90, 100))

-- Shader status
GfxShaderStatus = Instance.new("TextLabel")
GfxShaderStatus.Size = UDim2.new(1, -16, 0, 18)
GfxShaderStatus.Position = UDim2.new(0, 8, 0, 482)
GfxShaderStatus.BackgroundTransparency = 1
GfxShaderStatus.Text = "Shader: None"
GfxShaderStatus.TextColor3 = Colors.textDim
GfxShaderStatus.TextSize = 9
GfxShaderStatus.Font = Enum.Font.Code
GfxShaderStatus.TextXAlignment = Enum.TextXAlignment.Left
GfxShaderStatus.Parent = GfxScroll

--==================================================
-- MANUAL SLIDERS
--==================================================

createSectionHeader(GfxScroll, "Manual Controls", 508)

GfxBloomSlider = createSliderRow(GfxScroll, "Bloom Intensity", 0, 20, 5, 534, function(val)
    local bloom = game.Lighting:FindFirstChild("VampGFX_Bloom")
    if bloom then
        bloom.Intensity = val / 10
    end
end)

GfxBlurSlider = createSliderRow(GfxScroll, "Blur", 0, 10, 0, 572, function(val)
    local blur = game.Lighting:FindFirstChild("VampGFX_Blur")
    if not blur and val > 0 then
        blur = Instance.new("BlurEffect")
        blur.Name = "VampGFX_Blur"
        blur.Parent = game.Lighting
    end
    if blur then
        blur.Size = val
        if val == 0 then blur:Destroy() end
    end
end)

GfxBrightSlider = createSliderRow(GfxScroll, "Brightness", 1, 5, 2, 610, function(val)
    game.Lighting.Brightness = val
end)

--==================================================
-- ENVIRONMENT SECTION
--==================================================

createSectionHeader(GfxScroll, "Environment", 650)

-- Time of Day (0-24h)
GfxTimeSlider = createSliderRow(GfxScroll, "Time of Day", 0, 24, 14, 676, function(val)
    if saveOriginalLighting then saveOriginalLighting() end
    game.Lighting.ClockTime = val
end)
do
    local origSetVal = GfxTimeSlider.setValue
    GfxTimeSlider.setValue = function(v)
        origSetVal(v)
        for _, child in ipairs(GfxTimeSlider.row:GetChildren()) do
            if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Right then
                child.Text = string.format("%02d:00", v)
                break
            end
        end
    end
    GfxTimeSlider.setValue(14)
end

-- FOV (30-120)
GfxFovSlider = createSliderRow(GfxScroll, "FOV", 30, 120, 70, 714, function(val)
    if saveOriginalLighting then saveOriginalLighting() end
    pcall(function()
        workspace.CurrentCamera.FieldOfView = val
    end)
end)
do
    local origSetVal = GfxFovSlider.setValue
    GfxFovSlider.setValue = function(v)
        origSetVal(v)
        for _, child in ipairs(GfxFovSlider.row:GetChildren()) do
            if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Right then
                child.Text = v .. "\194\176"
                break
            end
        end
    end
    GfxFovSlider.setValue(70)
end

-- Fog Distance (1-100 = FogEnd * 100)
GfxFogSlider = createSliderRow(GfxScroll, "Fog Distance", 1, 100, 100, 752, function(val)
    if saveOriginalLighting then saveOriginalLighting() end
    game.Lighting.FogEnd = val * 100
end)
do
    local origSetVal = GfxFogSlider.setValue
    GfxFogSlider.setValue = function(v)
        origSetVal(v)
        for _, child in ipairs(GfxFogSlider.row:GetChildren()) do
            if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Right then
                child.Text = tostring(v * 100)
                break
            end
        end
    end
    GfxFogSlider.setValue(100)
end

-- Fog Color label
GfxFogColorLabel = Instance.new("TextLabel")
GfxFogColorLabel.Size = UDim2.new(1, -16, 0, 14)
GfxFogColorLabel.Position = UDim2.new(0, 8, 0, 790)
GfxFogColorLabel.BackgroundTransparency = 1
GfxFogColorLabel.Text = "Fog Color:"
GfxFogColorLabel.TextColor3 = Colors.textDim
GfxFogColorLabel.TextSize = 9
GfxFogColorLabel.Font = Enum.Font.GothamBold
GfxFogColorLabel.TextXAlignment = Enum.TextXAlignment.Left
GfxFogColorLabel.Parent = GfxScroll

-- Fog Color preset buttons
GfxFogWhite = Instance.new("TextButton")
GfxFogWhite.Size = UDim2.new(0.2, -6, 0, 26)
GfxFogWhite.Position = UDim2.new(0, 8, 0, 808)
GfxFogWhite.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
GfxFogWhite.Text = "White"
GfxFogWhite.TextColor3 = Color3.fromRGB(30, 30, 30)
GfxFogWhite.TextSize = 8
GfxFogWhite.Font = Enum.Font.GothamBold
GfxFogWhite.AutoButtonColor = false
GfxFogWhite.Parent = GfxScroll
Instance.new("UICorner", GfxFogWhite).CornerRadius = UDim.new(0, 4)

GfxFogGray = Instance.new("TextButton")
GfxFogGray.Size = UDim2.new(0.2, -6, 0, 26)
GfxFogGray.Position = UDim2.new(0.2, 5, 0, 808)
GfxFogGray.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
GfxFogGray.Text = "Gray"
GfxFogGray.TextColor3 = Colors.text
GfxFogGray.TextSize = 8
GfxFogGray.Font = Enum.Font.GothamBold
GfxFogGray.AutoButtonColor = false
GfxFogGray.Parent = GfxScroll
Instance.new("UICorner", GfxFogGray).CornerRadius = UDim.new(0, 4)

GfxFogBlue = Instance.new("TextButton")
GfxFogBlue.Size = UDim2.new(0.2, -6, 0, 26)
GfxFogBlue.Position = UDim2.new(0.4, 5, 0, 808)
GfxFogBlue.BackgroundColor3 = Color3.fromRGB(100, 150, 220)
GfxFogBlue.Text = "Blue"
GfxFogBlue.TextColor3 = Colors.text
GfxFogBlue.TextSize = 8
GfxFogBlue.Font = Enum.Font.GothamBold
GfxFogBlue.AutoButtonColor = false
GfxFogBlue.Parent = GfxScroll
Instance.new("UICorner", GfxFogBlue).CornerRadius = UDim.new(0, 4)

GfxFogWarm = Instance.new("TextButton")
GfxFogWarm.Size = UDim2.new(0.2, -6, 0, 26)
GfxFogWarm.Position = UDim2.new(0.6, 5, 0, 808)
GfxFogWarm.BackgroundColor3 = Color3.fromRGB(220, 180, 100)
GfxFogWarm.Text = "Warm"
GfxFogWarm.TextColor3 = Color3.fromRGB(30, 30, 30)
GfxFogWarm.TextSize = 8
GfxFogWarm.Font = Enum.Font.GothamBold
GfxFogWarm.AutoButtonColor = false
GfxFogWarm.Parent = GfxScroll
Instance.new("UICorner", GfxFogWarm).CornerRadius = UDim.new(0, 4)

GfxFogDark = Instance.new("TextButton")
GfxFogDark.Size = UDim2.new(0.2, -6, 0, 26)
GfxFogDark.Position = UDim2.new(0.8, 5, 0, 808)
GfxFogDark.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
GfxFogDark.Text = "Dark"
GfxFogDark.TextColor3 = Colors.text
GfxFogDark.TextSize = 8
GfxFogDark.Font = Enum.Font.GothamBold
GfxFogDark.AutoButtonColor = false
GfxFogDark.Parent = GfxScroll
Instance.new("UICorner", GfxFogDark).CornerRadius = UDim.new(0, 4)

--==================================================
-- RESET ALL BUTTON
--==================================================

GfxResetAllBtn = Instance.new("TextButton")
GfxResetAllBtn.Size = UDim2.new(1, -16, 0, 36)
GfxResetAllBtn.Position = UDim2.new(0, 8, 0, 850)
GfxResetAllBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
GfxResetAllBtn.Text = "RESET ALL (volta ao mapa original)"
GfxResetAllBtn.TextColor3 = Colors.text
GfxResetAllBtn.TextSize = 11
GfxResetAllBtn.Font = Enum.Font.GothamBold
GfxResetAllBtn.AutoButtonColor = false
GfxResetAllBtn.Parent = GfxScroll
Instance.new("UICorner", GfxResetAllBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(GfxResetAllBtn)
makeHoverable(GfxResetAllBtn, Color3.fromRGB(200, 50, 50), Color3.fromRGB(240, 80, 80))

--==================================================
-- SEÇÃO: AMBIENT & FOG
--==================================================

createSectionHeader(GfxScroll, "Ambient & Fog", 900)

-- Botão remover fog
FogRemoveBtn = Instance.new("TextButton")
FogRemoveBtn.Size = UDim2.new(1, -8, 0, 32)
FogRemoveBtn.Position = UDim2.new(0, 4, 0, 926)
FogRemoveBtn.BackgroundColor3 = Colors.glowPurple
FogRemoveBtn.Text = "🌫 REMOVE FOG"
FogRemoveBtn.TextColor3 = Colors.text
FogRemoveBtn.TextSize = 12
FogRemoveBtn.Font = Enum.Font.GothamBold
FogRemoveBtn.AutoButtonColor = false
FogRemoveBtn.Parent = GfxScroll
Instance.new("UICorner", FogRemoveBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(FogRemoveBtn)
makeHoverable(FogRemoveBtn, Colors.glowPurple, Color3.fromRGB(180, 120, 255))

-- Botão restaurar fog
FogRestoreBtn = Instance.new("TextButton")
FogRestoreBtn.Size = UDim2.new(1, -8, 0, 28)
FogRestoreBtn.Position = UDim2.new(0, 4, 0, 964)
FogRestoreBtn.BackgroundColor3 = Colors.warning
FogRestoreBtn.Text = "↺ RESTORE FOG"
FogRestoreBtn.TextColor3 = Colors.text
FogRestoreBtn.TextSize = 11
FogRestoreBtn.Font = Enum.Font.GothamBold
FogRestoreBtn.AutoButtonColor = false
FogRestoreBtn.Parent = GfxScroll
Instance.new("UICorner", FogRestoreBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(FogRestoreBtn)
makeHoverable(FogRestoreBtn, Colors.warning, Color3.fromRGB(230, 180, 60))

-- Label de cor ambiente
AmbientLabel = Instance.new("TextLabel")
AmbientLabel.Size = UDim2.new(1, -8, 0, 16)
AmbientLabel.Position = UDim2.new(0, 4, 0, 1000)
AmbientLabel.BackgroundTransparency = 1
AmbientLabel.Text = "Ambient Color:"
AmbientLabel.TextColor3 = Colors.textDim
AmbientLabel.TextSize = 10
AmbientLabel.Font = Enum.Font.GothamBold
AmbientLabel.TextXAlignment = Enum.TextXAlignment.Left
AmbientLabel.Parent = GfxScroll

-- Sliders de cor ambiente (R, G, B)
AmbientRSlider = createSliderRow(GfxScroll, "R", 0, 255, 128, 1020, function(v) end)
AmbientGSlider = createSliderRow(GfxScroll, "G", 0, 255, 128, 1058, function(v) end)
AmbientBSlider = createSliderRow(GfxScroll, "B", 0, 255, 128, 1096, function(v) end)

-- Botão aplicar ambient
AmbientApplyBtn = Instance.new("TextButton")
AmbientApplyBtn.Size = UDim2.new(1, -8, 0, 30)
AmbientApplyBtn.Position = UDim2.new(0, 4, 0, 1138)
AmbientApplyBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
AmbientApplyBtn.Text = "🎨 APPLY AMBIENT"
AmbientApplyBtn.TextColor3 = Colors.text
AmbientApplyBtn.TextSize = 11
AmbientApplyBtn.Font = Enum.Font.GothamBold
AmbientApplyBtn.AutoButtonColor = false
AmbientApplyBtn.Parent = GfxScroll
Instance.new("UICorner", AmbientApplyBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(AmbientApplyBtn)
makeHoverable(AmbientApplyBtn, Color3.fromRGB(100, 80, 200), Color3.fromRGB(130, 110, 240))

-- Sliders de atmosfera
AtmoDensitySlider = createSliderRow(GfxScroll, "Density", 0, 100, 30, 1176, function(v) end)
AtmoHazeSlider = createSliderRow(GfxScroll, "Haze", 0, 100, 0, 1214, function(v) end)
AtmoGlowSlider = createSliderRow(GfxScroll, "Glow", 0, 100, 0, 1252, function(v) end)

-- Botão aplicar atmosfera
AtmoApplyBtn = Instance.new("TextButton")
AtmoApplyBtn.Size = UDim2.new(1, -8, 0, 30)
AtmoApplyBtn.Position = UDim2.new(0, 4, 0, 1294)
AtmoApplyBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
AtmoApplyBtn.Text = "🌈 APPLY ATMOSPHERE"
AtmoApplyBtn.TextColor3 = Colors.text
AtmoApplyBtn.TextSize = 11
AtmoApplyBtn.Font = Enum.Font.GothamBold
AtmoApplyBtn.AutoButtonColor = false
AtmoApplyBtn.Parent = GfxScroll
Instance.new("UICorner", AtmoApplyBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(AtmoApplyBtn)
makeHoverable(AtmoApplyBtn, Color3.fromRGB(100, 80, 200), Color3.fromRGB(130, 110, 240))

-- Botão resetar tudo de ambient
AmbientResetBtn = Instance.new("TextButton")
AmbientResetBtn.Size = UDim2.new(1, -8, 0, 28)
AmbientResetBtn.Position = UDim2.new(0, 4, 0, 1332)
AmbientResetBtn.BackgroundColor3 = Colors.bloodDark
AmbientResetBtn.Text = "🔴 RESET ALL AMBIENT"
AmbientResetBtn.TextColor3 = Colors.text
AmbientResetBtn.TextSize = 11
AmbientResetBtn.Font = Enum.Font.GothamBold
AmbientResetBtn.AutoButtonColor = false
AmbientResetBtn.Parent = GfxScroll
Instance.new("UICorner", AmbientResetBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(AmbientResetBtn)
makeHoverable(AmbientResetBtn, Colors.bloodDark, Colors.blood)

--==================================================
-- LOGIC
--==================================================

saveOriginalLighting = function()
    if graphicsOriginal then return end
    local L = game.Lighting
    graphicsOriginal = {
        GlobalShadows = L.GlobalShadows,
        FogEnd = L.FogEnd,
        FogStart = L.FogStart,
        FogColor = L.FogColor,
        ClockTime = L.ClockTime,
        Brightness = L.Brightness,
        ExposureCompensation = L.ExposureCompensation,
        ShadowSoftness = L.ShadowSoftness,
        EnvironmentDiffuseScale = L.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = L.EnvironmentSpecularScale,
        Ambient = L.Ambient,
        OutdoorAmbient = L.OutdoorAmbient,
        ColorShift_Top = L.ColorShift_Top,
        GeographicLatitude = L.GeographicLatitude,
    }
    pcall(function()
        graphicsOriginal.FOV = workspace.CurrentCamera.FieldOfView
    end)
end

removeVampGfxEffects = function()
    for _, child in ipairs(game.Lighting:GetChildren()) do
        if child.Name:sub(1, 8) == "VampGFX_" then
            child:Destroy()
        end
    end
end

-- Restaurar TODAS as propriedades do mapa original
restoreLightingFromOriginal = function()
    if not graphicsOriginal then return end
    local L = game.Lighting
    for k, v in pairs(graphicsOriginal) do
        if k ~= "FOV" then
            pcall(function() L[k] = v end)
        end
    end
    pcall(function()
        if graphicsOriginal.FOV then
            workspace.CurrentCamera.FieldOfView = graphicsOriginal.FOV
        end
    end)
end

applyLowGfx = function()
    saveOriginalLighting()
    local L = game.Lighting
    L.GlobalShadows = false
    L.FogEnd = 99999

    for _, child in ipairs(L:GetChildren()) do
        if child:IsA("BloomEffect") or child:IsA("SunRaysEffect")
            or child:IsA("BlurEffect") or child:IsA("DepthOfFieldEffect")
            or child:IsA("ColorCorrectionEffect") then
            if child.Name:sub(1, 8) ~= "VampGFX_" then
                child.Enabled = false
            end
        end
    end

    pcall(function()
        if sethiddenproperty then
            local settings = game:GetService("RenderSettings") or settings().Rendering
            sethiddenproperty(settings, "QualityLevel", "Level01")
        end
    end)

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    graphicsMode = "low"
    GfxFpsStatus.Text = "Mode: LOW GFX"
    GfxFpsStatus.TextColor3 = Color3.fromRGB(80, 200, 100)
    GfxLowBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 100)
    GfxUltraLowBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 40)
    notify("Low GFX applied", "success")
end

applyUltraLowGfx = function()
    applyLowGfx()

    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
                count = count + 1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire")
                or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Trail") then
                obj.Enabled = false
            elseif obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            end
        end)
    end

    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterReflectance = 0
            terrain.Decoration = false
        end
    end)

    for _, child in ipairs(game.Lighting:GetChildren()) do
        pcall(function()
            if child:IsA("Atmosphere") and child.Name:sub(1, 8) ~= "VampGFX_" then
                child.Enabled = false
            end
        end)
    end

    graphicsMode = "ultralow"
    GfxFpsStatus.Text = "Mode: ULTRA LOW (" .. count .. " parts)"
    GfxFpsStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
    GfxUltraLowBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 100)
    notify("Ultra Low GFX applied (" .. count .. " parts)", "success")
end

applyUltraHighGfx = function()
    saveOriginalLighting()
    local L = game.Lighting

    -- Maximizar qualidade de rendering
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
    end)
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(settings().Rendering, "QualityLevel", "Level21")
        end
    end)

    -- Sombras globais ON
    L.GlobalShadows = true
    L.EnvironmentDiffuseScale = 1
    L.EnvironmentSpecularScale = 1

    -- Maximizar RenderFidelity em todas MeshParts
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("MeshPart") then
                obj.RenderFidelity = Enum.RenderFidelity.Precise
                count += 1
            elseif obj:IsA("BasePart") then
                obj.CastShadow = true
            end
        end)
    end

    -- Terrain max quality
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.Decoration = true
            terrain.WaterWaveSize = 0.5
            terrain.WaterReflectance = 1
        end
    end)

    -- Re-enable todos os efeitos visuais do Lighting
    for _, child in ipairs(L:GetChildren()) do
        pcall(function()
            if (child:IsA("BloomEffect") or child:IsA("SunRaysEffect")
                or child:IsA("BlurEffect") or child:IsA("DepthOfFieldEffect")
                or child:IsA("ColorCorrectionEffect") or child:IsA("Atmosphere"))
                and child.Name:sub(1, 8) ~= "VampGFX_" then
                child.Enabled = true
            end
        end)
    end

    graphicsMode = "ultrahigh"
    GfxFpsStatus.Text = "Mode: ULTRA HIGH (" .. count .. " meshes)"
    GfxFpsStatus.TextColor3 = Color3.fromRGB(200, 120, 255)
    GfxLowBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
    GfxUltraLowBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 40)
    GfxUltraHighBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 255)
    notify("Ultra High GFX applied (" .. count .. " meshes)", "success")
end

restoreGraphics = function()
    if not graphicsOriginal then
        notify("Nothing to restore", "warning")
        return
    end

    -- Restaurar TODAS propriedades do mapa original
    restoreLightingFromOriginal()

    -- Re-enable efeitos do jogo
    for _, child in ipairs(game.Lighting:GetChildren()) do
        pcall(function()
            if (child:IsA("BloomEffect") or child:IsA("SunRaysEffect")
                or child:IsA("BlurEffect") or child:IsA("DepthOfFieldEffect")
                or child:IsA("ColorCorrectionEffect") or child:IsA("Atmosphere"))
                and child.Name:sub(1, 8) ~= "VampGFX_" then
                child.Enabled = true
            end
        end)
    end

    removeVampGfxEffects()

    -- Restaurar reflectance (mirror)
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("BasePart") then
                local orig = obj:GetAttribute("VampGFX_OrigReflectance")
                if orig ~= nil then
                    obj.Reflectance = orig
                    obj:SetAttribute("VampGFX_OrigReflectance", nil)
                end
            end
        end)
    end

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)

    graphicsMode = "default"
    graphicsShader = "none"
    GfxFpsStatus.Text = "Mode: Default (restored)"
    GfxFpsStatus.TextColor3 = Colors.textDim
    GfxShaderStatus.Text = "Shader: None"
    GfxShaderStatus.TextColor3 = Colors.textDim
    GfxLowBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
    GfxUltraLowBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 40)
    GfxUltraHighBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 180)

    -- Atualizar sliders pro valor original
    pcall(function()
        GfxBrightSlider.setValue(math.floor(graphicsOriginal.Brightness + 0.5))
        GfxTimeSlider.setValue(math.floor(graphicsOriginal.ClockTime + 0.5))
        GfxFovSlider.setValue(math.floor((graphicsOriginal.FOV or 70) + 0.5))
        GfxFogSlider.setValue(math.max(1, math.floor(graphicsOriginal.FogEnd / 100 + 0.5)))
    end)
    GfxBloomSlider.setValue(0)
    GfxBlurSlider.setValue(0)

    notify("Graphics restored to map original!", "success")
end

resetAllGfx = function()
    saveOriginalLighting()
    restoreGraphics()
end

applyShader = function(preset)
    saveOriginalLighting()
    removeVampGfxEffects()

    -- Limpar reflectance se vinha de mirror
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("BasePart") then
                local orig = obj:GetAttribute("VampGFX_OrigReflectance")
                if orig ~= nil then
                    obj.Reflectance = orig
                    obj:SetAttribute("VampGFX_OrigReflectance", nil)
                end
            end
        end)
    end

    local L = game.Lighting

    if preset == "rtx" then
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.5
        bloom.Size = 22
        bloom.Threshold = 1.5
        bloom.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.117
        rays.Spread = 1
        rays.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.3
        cc.Saturation = 0.2
        cc.TintColor = Color3.fromRGB(255, 252, 224)
        cc.Parent = L

        local blur = Instance.new("BlurEffect")
        blur.Name = "VampGFX_Blur"
        blur.Size = 2
        blur.Parent = L

        L.ExposureCompensation = 0.34
        L.ShadowSoftness = 1
        L.EnvironmentDiffuseScale = 0.343
        L.EnvironmentSpecularScale = 1
        L.Brightness = 2
        L.ColorShift_Top = Color3.fromRGB(118, 117, 108)
        L.OutdoorAmbient = Color3.fromRGB(141, 141, 141)
        L.Ambient = Color3.fromRGB(112, 112, 112)
        L.GlobalShadows = true

        GfxShaderStatus.Text = "Shader: RTX Realistic"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(200, 140, 255)
        GfxBloomSlider.setValue(5)
        GfxBlurSlider.setValue(2)
        GfxBrightSlider.setValue(2)

    elseif preset == "cinematic" then
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.3
        bloom.Size = 15
        bloom.Threshold = 2
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.5
        cc.Saturation = 0.15
        cc.TintColor = Color3.fromRGB(220, 230, 255)
        cc.Parent = L

        local dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "VampGFX_DOF"
        dof.FarIntensity = 0.3
        dof.FocusDistance = 50
        dof.InFocusRadius = 30
        dof.NearIntensity = 0
        dof.Parent = L

        L.Brightness = 1.5
        L.ExposureCompensation = 0.2
        L.ShadowSoftness = 0.8
        L.GlobalShadows = true

        GfxShaderStatus.Text = "Shader: Cinematic"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(100, 160, 255)
        GfxBloomSlider.setValue(3)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(2)

    elseif preset == "neon" then
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 1
        bloom.Size = 40
        bloom.Threshold = 0.8
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.2
        cc.Saturation = 0.4
        cc.TintColor = Color3.fromRGB(255, 240, 255)
        cc.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.2
        rays.Spread = 0.8
        rays.Parent = L

        L.Brightness = 3
        L.ExposureCompensation = 0.5
        L.GlobalShadows = true

        GfxShaderStatus.Text = "Shader: Neon"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(255, 100, 200)
        GfxBloomSlider.setValue(10)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(3)

    elseif preset == "mirror" then
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.4
        bloom.Size = 18
        bloom.Threshold = 1.8
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.25
        cc.Saturation = 0.1
        cc.TintColor = Color3.fromRGB(230, 240, 255)
        cc.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.08
        rays.Spread = 0.6
        rays.Parent = L

        L.Brightness = 2
        L.ExposureCompensation = 0.3
        L.ShadowSoftness = 0.6
        L.EnvironmentDiffuseScale = 0.5
        L.EnvironmentSpecularScale = 1
        L.GlobalShadows = true

        local refCount = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") and obj.Reflectance < 0.1 then
                    obj:SetAttribute("VampGFX_OrigReflectance", obj.Reflectance)
                    obj.Reflectance = 0.35
                    refCount = refCount + 1
                end
            end)
        end

        GfxShaderStatus.Text = "Shader: Mirror (" .. refCount .. " parts)"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(80, 220, 240)
        GfxBloomSlider.setValue(4)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(2)

    elseif preset == "vhs" then
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.8
        bloom.Size = 30
        bloom.Threshold = 0.6
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.4
        cc.Saturation = -0.4
        cc.TintColor = Color3.fromRGB(255, 220, 160)
        cc.Parent = L

        local blur = Instance.new("BlurEffect")
        blur.Name = "VampGFX_Blur"
        blur.Size = 3
        blur.Parent = L

        L.Brightness = 1.8
        L.ExposureCompensation = 0.4
        L.Ambient = Color3.fromRGB(140, 120, 90)
        L.OutdoorAmbient = Color3.fromRGB(160, 140, 100)
        L.GlobalShadows = true

        GfxShaderStatus.Text = "Shader: VHS Retro"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(220, 180, 100)
        GfxBloomSlider.setValue(8)
        GfxBlurSlider.setValue(3)
        GfxBrightSlider.setValue(2)

    elseif preset == "noir" then
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.7
        cc.Saturation = -1
        cc.TintColor = Color3.fromRGB(240, 240, 255)
        cc.Parent = L

        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.3
        bloom.Size = 12
        bloom.Threshold = 2
        bloom.Parent = L

        local dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "VampGFX_DOF"
        dof.FarIntensity = 0.2
        dof.FocusDistance = 40
        dof.InFocusRadius = 25
        dof.NearIntensity = 0
        dof.Parent = L

        L.Brightness = 1.2
        L.ExposureCompensation = 0.1
        L.ShadowSoftness = 0.3
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(80, 80, 80)

        GfxShaderStatus.Text = "Shader: Film Noir"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
        GfxBloomSlider.setValue(3)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(1)

    elseif preset == "sunset" then
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.6
        bloom.Size = 25
        bloom.Threshold = 1.2
        bloom.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.25
        rays.Spread = 0.9
        rays.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.25
        cc.Saturation = 0.3
        cc.TintColor = Color3.fromRGB(255, 200, 140)
        cc.Parent = L

        L.ClockTime = 17.5
        L.Brightness = 2.5
        L.ExposureCompensation = 0.4
        L.ShadowSoftness = 0.9
        L.ColorShift_Top = Color3.fromRGB(255, 180, 100)
        L.OutdoorAmbient = Color3.fromRGB(200, 140, 80)
        L.Ambient = Color3.fromRGB(160, 100, 60)
        L.GlobalShadows = true

        GfxShaderStatus.Text = "Shader: Golden Sunset"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
        GfxBloomSlider.setValue(6)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(3)
        GfxTimeSlider.setValue(18)

    elseif preset == "aqua" then
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.15
        cc.Saturation = -0.1
        cc.TintColor = Color3.fromRGB(140, 200, 255)
        cc.Parent = L

        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.4
        bloom.Size = 20
        bloom.Threshold = 1.5
        bloom.Parent = L

        local blur = Instance.new("BlurEffect")
        blur.Name = "VampGFX_Blur"
        blur.Size = 4
        blur.Parent = L

        local dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "VampGFX_DOF"
        dof.FarIntensity = 0.5
        dof.FocusDistance = 30
        dof.InFocusRadius = 20
        dof.NearIntensity = 0.1
        dof.Parent = L

        L.Brightness = 1
        L.ExposureCompensation = -0.1
        L.FogEnd = 600
        L.FogColor = Color3.fromRGB(40, 80, 120)
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(60, 100, 140)

        GfxShaderStatus.Text = "Shader: Underwater"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(80, 180, 255)
        GfxBloomSlider.setValue(4)
        GfxBlurSlider.setValue(4)
        GfxBrightSlider.setValue(1)
        GfxFogSlider.setValue(6)

    elseif preset == "dream" then
        -- Sonho: pastel, bloom alto, suave, ethereal
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 1.2
        bloom.Size = 45
        bloom.Threshold = 0.5
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = -0.1
        cc.Saturation = -0.2
        cc.TintColor = Color3.fromRGB(240, 220, 255)
        cc.Parent = L

        local blur = Instance.new("BlurEffect")
        blur.Name = "VampGFX_Blur"
        blur.Size = 6
        blur.Parent = L

        L.Brightness = 2.5
        L.ExposureCompensation = 0.6
        L.ShadowSoftness = 1
        L.Ambient = Color3.fromRGB(180, 160, 200)
        L.OutdoorAmbient = Color3.fromRGB(200, 180, 220)
        L.GlobalShadows = true
        L.FogEnd = 2000
        L.FogColor = Color3.fromRGB(200, 180, 230)

        GfxShaderStatus.Text = "Shader: Dreamscape"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(200, 160, 255)
        GfxBloomSlider.setValue(12)
        GfxBlurSlider.setValue(6)
        GfxBrightSlider.setValue(3)
        GfxFogSlider.setValue(20)

    elseif preset == "horror" then
        -- Terror: escuro, vermelho, sombras pesadas
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.6
        cc.Saturation = -0.3
        cc.TintColor = Color3.fromRGB(255, 180, 180)
        cc.Parent = L

        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.2
        bloom.Size = 8
        bloom.Threshold = 3
        bloom.Parent = L

        L.Brightness = 0.5
        L.ExposureCompensation = -0.3
        L.ShadowSoftness = 0.1
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(30, 10, 10)
        L.OutdoorAmbient = Color3.fromRGB(40, 15, 15)
        L.FogEnd = 400
        L.FogColor = Color3.fromRGB(15, 5, 5)
        L.ClockTime = 0

        GfxShaderStatus.Text = "Shader: Horror"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(255, 60, 60)
        GfxBloomSlider.setValue(2)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(1)
        GfxTimeSlider.setValue(0)
        GfxFogSlider.setValue(4)

    elseif preset == "arctic" then
        -- Artico: frio, brilhante, branco/azul
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.5
        bloom.Size = 20
        bloom.Threshold = 1.2
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.2
        cc.Saturation = -0.15
        cc.TintColor = Color3.fromRGB(210, 230, 255)
        cc.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.15
        rays.Spread = 0.7
        rays.Parent = L

        L.Brightness = 3
        L.ExposureCompensation = 0.5
        L.ShadowSoftness = 0.7
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(160, 180, 200)
        L.OutdoorAmbient = Color3.fromRGB(180, 200, 220)
        L.FogEnd = 3000
        L.FogColor = Color3.fromRGB(200, 220, 240)

        GfxShaderStatus.Text = "Shader: Arctic"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(180, 220, 255)
        GfxBloomSlider.setValue(5)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(3)
        GfxFogSlider.setValue(30)

    elseif preset == "vapor" then
        -- Vaporwave: rosa/roxo/cyan, saturado, neon vibes
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.9
        bloom.Size = 35
        bloom.Threshold = 0.7
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.3
        cc.Saturation = 0.5
        cc.TintColor = Color3.fromRGB(255, 180, 255)
        cc.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.15
        rays.Spread = 0.5
        rays.Parent = L

        L.Brightness = 2.5
        L.ExposureCompensation = 0.4
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(120, 60, 160)
        L.OutdoorAmbient = Color3.fromRGB(160, 80, 200)
        L.ColorShift_Top = Color3.fromRGB(200, 100, 255)
        L.ClockTime = 20

        GfxShaderStatus.Text = "Shader: Vaporwave"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(255, 120, 255)
        GfxBloomSlider.setValue(9)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(3)
        GfxTimeSlider.setValue(20)

    elseif preset == "cyber" then
        -- Cyberpunk: neon azul/roxo, tech, alto contraste
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.7
        bloom.Size = 30
        bloom.Threshold = 0.8
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.5
        cc.Saturation = 0.4
        cc.TintColor = Color3.fromRGB(150, 180, 255)
        cc.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.1
        rays.Spread = 0.4
        rays.Parent = L

        L.Brightness = 1.5
        L.ExposureCompensation = 0.2
        L.ShadowSoftness = 0.3
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(30, 40, 100)
        L.OutdoorAmbient = Color3.fromRGB(40, 60, 140)
        L.ColorShift_Top = Color3.fromRGB(80, 120, 255)
        L.ClockTime = 22

        GfxShaderStatus.Text = "Shader: Cyberpunk"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(80, 160, 255)
        GfxBloomSlider.setValue(7)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(2)
        GfxTimeSlider.setValue(22)

    elseif preset == "vintage" then
        -- Vintage: sépia quente, baixa saturação, filme antigo
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.3
        cc.Saturation = -0.5
        cc.TintColor = Color3.fromRGB(240, 210, 170)
        cc.Parent = L

        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.35
        bloom.Size = 15
        bloom.Threshold = 1.8
        bloom.Parent = L

        local blur = Instance.new("BlurEffect")
        blur.Name = "VampGFX_Blur"
        blur.Size = 2
        blur.Parent = L

        L.Brightness = 2
        L.ExposureCompensation = 0.35
        L.ShadowSoftness = 0.8
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(150, 130, 100)
        L.OutdoorAmbient = Color3.fromRGB(180, 155, 120)

        GfxShaderStatus.Text = "Shader: Vintage Film"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(210, 180, 120)
        GfxBloomSlider.setValue(4)
        GfxBlurSlider.setValue(2)
        GfxBrightSlider.setValue(2)

    elseif preset == "galaxy" then
        -- Galáxia: escuro, roxo cósmico, bloom espacial
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.8
        bloom.Size = 40
        bloom.Threshold = 0.6
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.4
        cc.Saturation = 0.3
        cc.TintColor = Color3.fromRGB(180, 140, 255)
        cc.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.2
        rays.Spread = 1
        rays.Parent = L

        L.Brightness = 0.8
        L.ExposureCompensation = 0.1
        L.ShadowSoftness = 0.5
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(40, 20, 80)
        L.OutdoorAmbient = Color3.fromRGB(60, 30, 120)
        L.ColorShift_Top = Color3.fromRGB(120, 60, 200)
        L.ClockTime = 0
        L.FogEnd = 5000
        L.FogColor = Color3.fromRGB(10, 5, 25)

        GfxShaderStatus.Text = "Shader: Galaxy"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(160, 100, 255)
        GfxBloomSlider.setValue(8)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(1)
        GfxTimeSlider.setValue(0)

    elseif preset == "toxic" then
        -- Tóxico: verde radioativo, efeito nocivo
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.6
        bloom.Size = 25
        bloom.Threshold = 0.9
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.5
        cc.Saturation = 0.2
        cc.TintColor = Color3.fromRGB(160, 255, 100)
        cc.Parent = L

        L.Brightness = 1.5
        L.ExposureCompensation = 0.15
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(30, 80, 10)
        L.OutdoorAmbient = Color3.fromRGB(50, 120, 20)
        L.ColorShift_Top = Color3.fromRGB(80, 200, 40)
        L.FogEnd = 800
        L.FogColor = Color3.fromRGB(20, 50, 10)

        GfxShaderStatus.Text = "Shader: Toxic"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(100, 255, 60)
        GfxBloomSlider.setValue(6)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(2)
        GfxFogSlider.setValue(8)

    elseif preset == "autumn" then
        -- Outono: tons quentes, laranja/dourado, folhas
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.45
        bloom.Size = 18
        bloom.Threshold = 1.4
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.2
        cc.Saturation = 0.15
        cc.TintColor = Color3.fromRGB(255, 200, 150)
        cc.Parent = L

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "VampGFX_SunRays"
        rays.Intensity = 0.18
        rays.Spread = 0.8
        rays.Parent = L

        L.Brightness = 2.2
        L.ExposureCompensation = 0.3
        L.ShadowSoftness = 0.7
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(160, 110, 60)
        L.OutdoorAmbient = Color3.fromRGB(190, 140, 80)
        L.ColorShift_Top = Color3.fromRGB(220, 160, 80)
        L.ClockTime = 16

        GfxShaderStatus.Text = "Shader: Autumn"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(220, 160, 60)
        GfxBloomSlider.setValue(5)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(2)
        GfxTimeSlider.setValue(16)

    elseif preset == "sakura" then
        -- Sakura: rosa suave, cherry blossom, leve e aéreo
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.7
        bloom.Size = 30
        bloom.Threshold = 0.9
        bloom.Parent = L

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = -0.05
        cc.Saturation = 0.1
        cc.TintColor = Color3.fromRGB(255, 210, 230)
        cc.Parent = L

        local blur = Instance.new("BlurEffect")
        blur.Name = "VampGFX_Blur"
        blur.Size = 3
        blur.Parent = L

        L.Brightness = 2.8
        L.ExposureCompensation = 0.5
        L.ShadowSoftness = 0.9
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(200, 160, 180)
        L.OutdoorAmbient = Color3.fromRGB(220, 180, 200)
        L.ColorShift_Top = Color3.fromRGB(255, 190, 210)
        L.FogEnd = 3000
        L.FogColor = Color3.fromRGB(240, 200, 220)

        GfxShaderStatus.Text = "Shader: Sakura"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(255, 160, 200)
        GfxBloomSlider.setValue(7)
        GfxBlurSlider.setValue(3)
        GfxBrightSlider.setValue(3)
        GfxFogSlider.setValue(30)

    elseif preset == "matrix" then
        -- Matrix: verde digital, escuro, chuva de código
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.6
        cc.Saturation = -0.6
        cc.TintColor = Color3.fromRGB(100, 255, 100)
        cc.Parent = L

        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.4
        bloom.Size = 15
        bloom.Threshold = 1.5
        bloom.Parent = L

        L.Brightness = 0.8
        L.ExposureCompensation = -0.2
        L.ShadowSoftness = 0.2
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(10, 40, 10)
        L.OutdoorAmbient = Color3.fromRGB(15, 60, 15)
        L.ColorShift_Top = Color3.fromRGB(0, 180, 0)
        L.ClockTime = 2
        L.FogEnd = 600
        L.FogColor = Color3.fromRGB(0, 10, 0)

        GfxShaderStatus.Text = "Shader: Matrix"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(0, 255, 60)
        GfxBloomSlider.setValue(4)
        GfxBlurSlider.setValue(0)
        GfxBrightSlider.setValue(1)
        GfxTimeSlider.setValue(2)
        GfxFogSlider.setValue(6)

    elseif preset == "bleach" then
        -- Bleach Bypass: alta exposição, lavado, brancos estourados
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "VampGFX_CC"
        cc.Contrast = 0.5
        cc.Saturation = -0.35
        cc.TintColor = Color3.fromRGB(245, 240, 230)
        cc.Parent = L

        local bloom = Instance.new("BloomEffect")
        bloom.Name = "VampGFX_Bloom"
        bloom.Intensity = 0.9
        bloom.Size = 35
        bloom.Threshold = 0.5
        bloom.Parent = L

        local blur = Instance.new("BlurEffect")
        blur.Name = "VampGFX_Blur"
        blur.Size = 1
        blur.Parent = L

        L.Brightness = 3.5
        L.ExposureCompensation = 0.8
        L.ShadowSoftness = 0.5
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(180, 175, 165)
        L.OutdoorAmbient = Color3.fromRGB(200, 195, 185)

        GfxShaderStatus.Text = "Shader: Bleach Bypass"
        GfxShaderStatus.TextColor3 = Color3.fromRGB(220, 215, 200)
        GfxBloomSlider.setValue(9)
        GfxBlurSlider.setValue(1)
        GfxBrightSlider.setValue(4)
    end

    graphicsShader = preset
    notify("Shader: " .. preset:upper() .. " applied!", "success")
end

removeShaders = function()
    removeVampGfxEffects()

    -- Restaurar reflectance (mirror)
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("BasePart") then
                local orig = obj:GetAttribute("VampGFX_OrigReflectance")
                if orig ~= nil then
                    obj.Reflectance = orig
                    obj:SetAttribute("VampGFX_OrigReflectance", nil)
                end
            end
        end)
    end

    -- Restaurar TODAS propriedades do mapa original (fix: antes restaurava parcial)
    restoreLightingFromOriginal()

    graphicsShader = "none"
    GfxShaderStatus.Text = "Shader: None"
    GfxShaderStatus.TextColor3 = Colors.textDim
    GfxBloomSlider.setValue(0)
    GfxBlurSlider.setValue(0)
    pcall(function()
        if graphicsOriginal then
            GfxBrightSlider.setValue(math.floor(graphicsOriginal.Brightness + 0.5))
            GfxTimeSlider.setValue(math.floor(graphicsOriginal.ClockTime + 0.5))
            GfxFogSlider.setValue(math.max(1, math.floor(graphicsOriginal.FogEnd / 100 + 0.5)))
        end
    end)
    notify("Shaders removed", "info")
end

--==================================================
-- EVENTS (inline)
--==================================================

GfxLowBtn.MouseButton1Click:Connect(function()
    if graphicsMode == "low" then restoreGraphics() else applyLowGfx() end
end)

GfxUltraLowBtn.MouseButton1Click:Connect(function()
    if graphicsMode == "ultralow" then restoreGraphics() else applyUltraLowGfx() end
end)

GfxUltraHighBtn.MouseButton1Click:Connect(function()
    if graphicsMode == "ultrahigh" then restoreGraphics() else applyUltraHighGfx() end
end)

GfxRestoreBtn.MouseButton1Click:Connect(function()
    restoreGraphics()
end)

GfxRtxBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "rtx" then removeShaders() else applyShader("rtx") end
end)

GfxCineBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "cinematic" then removeShaders() else applyShader("cinematic") end
end)

GfxNeonBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "neon" then removeShaders() else applyShader("neon") end
end)

GfxMirrorBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "mirror" then removeShaders() else applyShader("mirror") end
end)

GfxVhsBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "vhs" then removeShaders() else applyShader("vhs") end
end)

GfxNoirBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "noir" then removeShaders() else applyShader("noir") end
end)

GfxSunsetBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "sunset" then removeShaders() else applyShader("sunset") end
end)

GfxAquaBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "aqua" then removeShaders() else applyShader("aqua") end
end)

GfxDreamBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "dream" then removeShaders() else applyShader("dream") end
end)

GfxHorrorBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "horror" then removeShaders() else applyShader("horror") end
end)

GfxArcticBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "arctic" then removeShaders() else applyShader("arctic") end
end)

GfxVaporBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "vapor" then removeShaders() else applyShader("vapor") end
end)

GfxCyberBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "cyber" then removeShaders() else applyShader("cyber") end
end)

GfxVintageBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "vintage" then removeShaders() else applyShader("vintage") end
end)

GfxGalaxyBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "galaxy" then removeShaders() else applyShader("galaxy") end
end)

GfxToxicBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "toxic" then removeShaders() else applyShader("toxic") end
end)

GfxAutumnBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "autumn" then removeShaders() else applyShader("autumn") end
end)

GfxSakuraBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "sakura" then removeShaders() else applyShader("sakura") end
end)

GfxMatrixBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "matrix" then removeShaders() else applyShader("matrix") end
end)

GfxBleachBtn.MouseButton1Click:Connect(function()
    if graphicsShader == "bleach" then removeShaders() else applyShader("bleach") end
end)

GfxRemoveShadersBtn.MouseButton1Click:Connect(function()
    removeShaders()
end)

GfxResetAllBtn.MouseButton1Click:Connect(function()
    resetAllGfx()
end)

-- Fog Color buttons (também ajusta FogEnd pra fog ficar visível)
GfxFogWhite.MouseButton1Click:Connect(function()
    if saveOriginalLighting then saveOriginalLighting() end
    local L = game.Lighting
    L.FogColor = Color3.fromRGB(220, 220, 220)
    if L.FogEnd > 5000 then L.FogEnd = 1500 end
    GfxFogSlider.setValue(math.max(1, math.floor(L.FogEnd / 100 + 0.5)))
end)

GfxFogGray.MouseButton1Click:Connect(function()
    if saveOriginalLighting then saveOriginalLighting() end
    local L = game.Lighting
    L.FogColor = Color3.fromRGB(140, 140, 140)
    if L.FogEnd > 5000 then L.FogEnd = 1500 end
    GfxFogSlider.setValue(math.max(1, math.floor(L.FogEnd / 100 + 0.5)))
end)

GfxFogBlue.MouseButton1Click:Connect(function()
    if saveOriginalLighting then saveOriginalLighting() end
    local L = game.Lighting
    L.FogColor = Color3.fromRGB(100, 150, 220)
    if L.FogEnd > 5000 then L.FogEnd = 1500 end
    GfxFogSlider.setValue(math.max(1, math.floor(L.FogEnd / 100 + 0.5)))
end)

GfxFogWarm.MouseButton1Click:Connect(function()
    if saveOriginalLighting then saveOriginalLighting() end
    local L = game.Lighting
    L.FogColor = Color3.fromRGB(220, 180, 100)
    if L.FogEnd > 5000 then L.FogEnd = 1500 end
    GfxFogSlider.setValue(math.max(1, math.floor(L.FogEnd / 100 + 0.5)))
end)

GfxFogDark.MouseButton1Click:Connect(function()
    if saveOriginalLighting then saveOriginalLighting() end
    local L = game.Lighting
    L.FogColor = Color3.fromRGB(30, 30, 45)
    if L.FogEnd > 5000 then L.FogEnd = 1500 end
    GfxFogSlider.setValue(math.max(1, math.floor(L.FogEnd / 100 + 0.5)))
end)


--[[ ═══════ MODULE: 09i_tab_utils.luau ═══════ ]]

--==================================================
-- TAB: UTILS
--==================================================

UtilsContent = Instance.new("Frame")
UtilsContent.Name = "UtilsContent"
UtilsContent.Size = UDim2.new(1, 0, 1, 0)
UtilsContent.BackgroundTransparency = 1
UtilsContent.Visible = false
UtilsContent.Parent = TabContent
tabContents["utils"] = UtilsContent

-- Container com scroll
UtilsScroll = Instance.new("ScrollingFrame")
UtilsScroll.Size = UDim2.new(1, 0, 1, 0)
UtilsScroll.BackgroundTransparency = 1
UtilsScroll.ScrollBarThickness = 3
UtilsScroll.ScrollBarImageColor3 = Colors.blood
UtilsScroll.CanvasSize = UDim2.new(0, 0, 0, 700)
UtilsScroll.BorderSizePixel = 0
UtilsScroll.Parent = UtilsContent

-- ════════════════════════════════════════════════
-- SEÇÃO 1: SERVER
-- ════════════════════════════════════════════════

createSectionHeader(UtilsScroll, "Server", 0)

-- Botão Server Hop
ServerHopBtn = Instance.new("TextButton")
ServerHopBtn.Size = UDim2.new(1, 0, 0, 32)
ServerHopBtn.Position = UDim2.new(0, 0, 0, 26)
ServerHopBtn.BackgroundColor3 = Colors.blood
ServerHopBtn.Text = "🔀 SERVER HOP"
ServerHopBtn.TextColor3 = Colors.text
ServerHopBtn.TextSize = 11
ServerHopBtn.Font = Enum.Font.GothamBold
ServerHopBtn.AutoButtonColor = false
ServerHopBtn.Parent = UtilsScroll
Instance.new("UICorner", ServerHopBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ServerHopBtn)
makeHoverable(ServerHopBtn, Colors.blood, Colors.bloodLight)

-- Botão Rejoin
RejoinBtn = Instance.new("TextButton")
RejoinBtn.Size = UDim2.new(1, 0, 0, 32)
RejoinBtn.Position = UDim2.new(0, 0, 0, 62)
RejoinBtn.BackgroundColor3 = Colors.glowPurple
RejoinBtn.Text = "🔄 REJOIN"
RejoinBtn.TextColor3 = Colors.text
RejoinBtn.TextSize = 11
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.AutoButtonColor = false
RejoinBtn.Parent = UtilsScroll
Instance.new("UICorner", RejoinBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RejoinBtn)
makeHoverable(RejoinBtn, Colors.glowPurple, Colors.blood)

-- Botão Copiar Place ID
CopyPlaceIdBtn = Instance.new("TextButton")
CopyPlaceIdBtn.Size = UDim2.new(0.48, 0, 0, 28)
CopyPlaceIdBtn.Position = UDim2.new(0, 0, 0, 100)
CopyPlaceIdBtn.BackgroundColor3 = Colors.bloodDark
CopyPlaceIdBtn.Text = "📋 Place ID"
CopyPlaceIdBtn.TextColor3 = Colors.text
CopyPlaceIdBtn.TextSize = 10
CopyPlaceIdBtn.Font = Enum.Font.GothamBold
CopyPlaceIdBtn.AutoButtonColor = false
CopyPlaceIdBtn.Parent = UtilsScroll
Instance.new("UICorner", CopyPlaceIdBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(CopyPlaceIdBtn)
makeHoverable(CopyPlaceIdBtn, Colors.bloodDark, Colors.blood)

-- Botão Copiar Job ID
CopyJobIdBtn = Instance.new("TextButton")
CopyJobIdBtn.Size = UDim2.new(0.48, 0, 0, 28)
CopyJobIdBtn.Position = UDim2.new(0.52, 0, 0, 100)
CopyJobIdBtn.BackgroundColor3 = Colors.bloodDark
CopyJobIdBtn.Text = "📋 Job ID"
CopyJobIdBtn.TextColor3 = Colors.text
CopyJobIdBtn.TextSize = 10
CopyJobIdBtn.Font = Enum.Font.GothamBold
CopyJobIdBtn.AutoButtonColor = false
CopyJobIdBtn.Parent = UtilsScroll
Instance.new("UICorner", CopyJobIdBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(CopyJobIdBtn)
makeHoverable(CopyJobIdBtn, Colors.bloodDark, Colors.blood)

-- ════════════════════════════════════════════════
-- SEÇÃO 2: UTILITIES
-- ════════════════════════════════════════════════

createSectionHeader(UtilsScroll, "Utilities", 140)

-- Botão Anti-AFK (toggle)
UtilsAntiAfkBtn = Instance.new("TextButton")
UtilsAntiAfkBtn.Size = UDim2.new(1, 0, 0, 32)
UtilsAntiAfkBtn.Position = UDim2.new(0, 0, 0, 166)
UtilsAntiAfkBtn.BackgroundColor3 = Colors.green
UtilsAntiAfkBtn.Text = "⚡ ANTI-AFK: OFF"
UtilsAntiAfkBtn.TextColor3 = Colors.text
UtilsAntiAfkBtn.TextSize = 11
UtilsAntiAfkBtn.Font = Enum.Font.GothamBold
UtilsAntiAfkBtn.AutoButtonColor = false
UtilsAntiAfkBtn.Parent = UtilsScroll
Instance.new("UICorner", UtilsAntiAfkBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(UtilsAntiAfkBtn)
makeHoverable(UtilsAntiAfkBtn, Colors.green, Colors.glowPurple)

-- ════════════════════════════════════════════════
-- SEÇÃO 3: SOUND PLAYER
-- ════════════════════════════════════════════════

createSectionHeader(UtilsScroll, "Sound Player", 210)

-- Input do ID de áudio
SoundIdInput = Instance.new("TextBox")
SoundIdInput.Size = UDim2.new(0.7, -4, 0, 28)
SoundIdInput.Position = UDim2.new(0, 0, 0, 236)
SoundIdInput.BackgroundColor3 = Colors.inputBg
SoundIdInput.Text = ""
SoundIdInput.PlaceholderText = "Audio ID..."
SoundIdInput.PlaceholderColor3 = Colors.textDim
SoundIdInput.TextColor3 = Colors.text
SoundIdInput.TextSize = 10
SoundIdInput.Font = Enum.Font.Code
SoundIdInput.TextXAlignment = Enum.TextXAlignment.Left
SoundIdInput.ClearTextOnFocus = false
SoundIdInput.Parent = UtilsScroll
Instance.new("UICorner", SoundIdInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", SoundIdInput).PaddingLeft = UDim.new(0, 6)
SoundIdInputStroke = Instance.new("UIStroke", SoundIdInput)
SoundIdInputStroke.Color = Colors.inputBorder
SoundIdInputStroke.Thickness = 0.5

-- Botão Play
SoundPlayBtn = Instance.new("TextButton")
SoundPlayBtn.Size = UDim2.new(0.28, 0, 0, 28)
SoundPlayBtn.Position = UDim2.new(0.72, 0, 0, 236)
SoundPlayBtn.BackgroundColor3 = Colors.green
SoundPlayBtn.Text = "▶"
SoundPlayBtn.TextColor3 = Colors.text
SoundPlayBtn.TextSize = 14
SoundPlayBtn.Font = Enum.Font.GothamBold
SoundPlayBtn.AutoButtonColor = false
SoundPlayBtn.Parent = UtilsScroll
Instance.new("UICorner", SoundPlayBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(SoundPlayBtn)
makeHoverable(SoundPlayBtn, Colors.green, Colors.glowPurple)

-- Botão Stop
SoundStopBtn = Instance.new("TextButton")
SoundStopBtn.Size = UDim2.new(1, 0, 0, 28)
SoundStopBtn.Position = UDim2.new(0, 0, 0, 270)
SoundStopBtn.BackgroundColor3 = Colors.bloodDark
SoundStopBtn.Text = "⏹ STOP ALL SOUNDS"
SoundStopBtn.TextColor3 = Colors.text
SoundStopBtn.TextSize = 10
SoundStopBtn.Font = Enum.Font.GothamBold
SoundStopBtn.AutoButtonColor = false
SoundStopBtn.Parent = UtilsScroll
Instance.new("UICorner", SoundStopBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(SoundStopBtn)
makeHoverable(SoundStopBtn, Colors.bloodDark, Colors.blood)

-- Slider de volume
SoundVolumeSlider = createSliderRow(UtilsScroll, "Volume", 0, 100, 50, 304, function(val)
	SoundVolumeValue = val
end)

-- Status do som
SoundStatusLabel = Instance.new("TextLabel")
SoundStatusLabel.Size = UDim2.new(1, 0, 0, 16)
SoundStatusLabel.Position = UDim2.new(0, 0, 0, 338)
SoundStatusLabel.BackgroundTransparency = 1
SoundStatusLabel.Text = "No sound playing"
SoundStatusLabel.TextColor3 = Colors.textDim
SoundStatusLabel.TextSize = 9
SoundStatusLabel.Font = Enum.Font.Gotham
SoundStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
SoundStatusLabel.Parent = UtilsScroll

-- ════════════════════════════════════════════════
-- SEÇÃO 4: WAYPOINTS
-- ════════════════════════════════════════════════

createSectionHeader(UtilsScroll, "Waypoints", 366)

-- Botão salvar posição atual
WaypointSaveBtn = Instance.new("TextButton")
WaypointSaveBtn.Size = UDim2.new(1, 0, 0, 30)
WaypointSaveBtn.Position = UDim2.new(0, 0, 0, 392)
WaypointSaveBtn.BackgroundColor3 = Colors.glowPurple
WaypointSaveBtn.Text = "💾 SAVE CURRENT POSITION"
WaypointSaveBtn.TextColor3 = Colors.text
WaypointSaveBtn.TextSize = 11
WaypointSaveBtn.Font = Enum.Font.GothamBold
WaypointSaveBtn.AutoButtonColor = false
WaypointSaveBtn.Parent = UtilsScroll
Instance.new("UICorner", WaypointSaveBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(WaypointSaveBtn)
makeHoverable(WaypointSaveBtn, Colors.glowPurple, Colors.blood)

-- Lista de waypoints com scroll
WaypointScroll = Instance.new("ScrollingFrame")
WaypointScroll.Size = UDim2.new(1, 0, 0, 140)
WaypointScroll.Position = UDim2.new(0, 0, 0, 428)
WaypointScroll.BackgroundColor3 = Colors.inputBg
WaypointScroll.BackgroundTransparency = 0.5
WaypointScroll.ScrollBarThickness = 2
WaypointScroll.ScrollBarImageColor3 = Colors.blood
WaypointScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
WaypointScroll.BorderSizePixel = 0
WaypointScroll.Parent = UtilsScroll
Instance.new("UICorner", WaypointScroll).CornerRadius = UDim.new(0, 6)

WaypointScrollLayout = Instance.new("UIListLayout", WaypointScroll)
WaypointScrollLayout.Padding = UDim.new(0, 3)

WaypointScrollPad = Instance.new("UIPadding", WaypointScroll)
WaypointScrollPad.PaddingTop = UDim.new(0, 4)
WaypointScrollPad.PaddingLeft = UDim.new(0, 4)
WaypointScrollPad.PaddingRight = UDim.new(0, 4)
WaypointScrollPad.PaddingBottom = UDim.new(0, 4)

WaypointScrollStroke = Instance.new("UIStroke", WaypointScroll)
WaypointScrollStroke.Color = Colors.separator
WaypointScrollStroke.Thickness = 0.5

-- Botão limpar todos os waypoints
WaypointClearBtn = Instance.new("TextButton")
WaypointClearBtn.Size = UDim2.new(1, 0, 0, 26)
WaypointClearBtn.Position = UDim2.new(0, 0, 0, 574)
WaypointClearBtn.BackgroundColor3 = Colors.bloodDark
WaypointClearBtn.Text = "🗑 CLEAR ALL"
WaypointClearBtn.TextColor3 = Colors.text
WaypointClearBtn.TextSize = 10
WaypointClearBtn.Font = Enum.Font.GothamBold
WaypointClearBtn.AutoButtonColor = false
WaypointClearBtn.Parent = UtilsScroll
Instance.new("UICorner", WaypointClearBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(WaypointClearBtn)
makeHoverable(WaypointClearBtn, Colors.bloodDark, Colors.blood)

-- Contador de waypoints
WaypointCountLabel = Instance.new("TextLabel")
WaypointCountLabel.Size = UDim2.new(1, 0, 0, 16)
WaypointCountLabel.Position = UDim2.new(0, 0, 0, 604)
WaypointCountLabel.BackgroundTransparency = 1
WaypointCountLabel.Text = "0 waypoints saved"
WaypointCountLabel.TextColor3 = Colors.textDim
WaypointCountLabel.TextSize = 9
WaypointCountLabel.Font = Enum.Font.Gotham
WaypointCountLabel.TextXAlignment = Enum.TextXAlignment.Left
WaypointCountLabel.Parent = UtilsScroll


--[[ ═══════ MODULE: 09j_tab_animations.luau ═══════ ]]

--==================================================
-- TAB: ANIMATIONS (Favorites + Current Slots + Catalog Search)
--==================================================

AnimContent = Instance.new("Frame")
AnimContent.Name = "AnimContent"
AnimContent.Size = UDim2.new(1, 0, 1, 0)
AnimContent.BackgroundTransparency = 1
AnimContent.Visible = false
AnimContent.Parent = TabContent
tabContents["anim"] = AnimContent

-- ════════════════════════════════════════════════
-- MAIN VIEW (favorites + slots + catalog)
-- ════════════════════════════════════════════════

AnimMainView = Instance.new("Frame")
AnimMainView.Name = "AnimMainView"
AnimMainView.Size = UDim2.new(1, 0, 1, 0)
AnimMainView.BackgroundTransparency = 1
AnimMainView.Parent = AnimContent

AnimScroll = Instance.new("ScrollingFrame")
AnimScroll.Size = UDim2.new(1, 0, 1, 0)
AnimScroll.BackgroundTransparency = 1
AnimScroll.ScrollBarThickness = 3
AnimScroll.ScrollBarImageColor3 = Colors.blood
AnimScroll.CanvasSize = UDim2.new(0, 0, 0, 800)
AnimScroll.BorderSizePixel = 0
AnimScroll.Parent = AnimMainView

--==================================================
-- FAVORITES SECTION
--==================================================

createSectionHeader(AnimScroll, "Favorites", 0)
animFavSectionY = 24

AnimFavGrid = Instance.new("Frame")
AnimFavGrid.Name = "AnimFavGrid"
AnimFavGrid.Size = UDim2.new(1, 0, 0, 0)
AnimFavGrid.Position = UDim2.new(0, 0, 0, animFavSectionY)
AnimFavGrid.BackgroundTransparency = 1
AnimFavGrid.ClipsDescendants = true
AnimFavGrid.Parent = AnimScroll

AnimFavGridLayout = Instance.new("UIGridLayout", AnimFavGrid)
AnimFavGridLayout.CellSize = UDim2.new(0, 60, 0, 82)
AnimFavGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
AnimFavGridLayout.FillDirection = Enum.FillDirection.Horizontal
AnimFavGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

AnimFavEmpty = Instance.new("TextLabel")
AnimFavEmpty.Size = UDim2.new(1, 0, 0, 24)
AnimFavEmpty.Position = UDim2.new(0, 0, 0, animFavSectionY)
AnimFavEmpty.BackgroundTransparency = 1
AnimFavEmpty.Text = "No favorites yet — star bundles from catalog"
AnimFavEmpty.TextColor3 = Colors.textDim
AnimFavEmpty.TextSize = 9
AnimFavEmpty.Font = Enum.Font.Gotham
AnimFavEmpty.Visible = true
AnimFavEmpty.Parent = AnimScroll

--==================================================
-- CURRENT ANIMATIONS SECTION
--==================================================

AnimSlotsHeader = createSectionHeader(AnimScroll, "Current Animations", 0)

AnimSlotsContainer = Instance.new("Frame")
AnimSlotsContainer.Name = "AnimSlots"
AnimSlotsContainer.Size = UDim2.new(1, 0, 0, 7 * 28)
AnimSlotsContainer.BackgroundTransparency = 1
AnimSlotsContainer.Parent = AnimScroll

AnimSlotRows = {}

for i, slotName in ipairs(ANIM_SLOTS) do
    do
        local row = Instance.new("Frame")
        row.Name = "SlotRow_" .. slotName
        row.Size = UDim2.new(1, 0, 0, 26)
        row.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
        row.BackgroundColor3 = Colors.card
        row.BorderSizePixel = 0
        row.Parent = AnimSlotsContainer
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local slotLabel = Instance.new("TextLabel")
        slotLabel.Size = UDim2.new(0, 40, 1, 0)
        slotLabel.Position = UDim2.new(0, 6, 0, 0)
        slotLabel.BackgroundTransparency = 1
        slotLabel.Text = ANIM_SLOT_LABELS[slotName]
        slotLabel.TextColor3 = Colors.text
        slotLabel.TextSize = 10
        slotLabel.Font = Enum.Font.GothamBold
        slotLabel.TextXAlignment = Enum.TextXAlignment.Left
        slotLabel.Parent = row

        local animLabel = Instance.new("TextLabel")
        animLabel.Name = "AnimLabel"
        animLabel.Size = UDim2.new(1, -86, 1, 0)
        animLabel.Position = UDim2.new(0, 48, 0, 0)
        animLabel.BackgroundTransparency = 1
        animLabel.Text = "Default"
        animLabel.TextColor3 = Colors.textDim
        animLabel.TextSize = 9
        animLabel.Font = Enum.Font.Gotham
        animLabel.TextXAlignment = Enum.TextXAlignment.Left
        animLabel.TextTruncate = Enum.TextTruncate.AtEnd
        animLabel.Parent = row

        local resetBtn = Instance.new("TextButton")
        resetBtn.Name = "ResetBtn"
        resetBtn.Size = UDim2.new(0, 26, 0, 20)
        resetBtn.Position = UDim2.new(1, -30, 0, 3)
        resetBtn.BackgroundColor3 = Colors.bloodDark
        resetBtn.Text = "↺"
        resetBtn.TextColor3 = Colors.text
        resetBtn.TextSize = 12
        resetBtn.Font = Enum.Font.GothamBold
        resetBtn.AutoButtonColor = false
        resetBtn.Visible = false
        resetBtn.Parent = row
        Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(resetBtn, Colors.bloodDark, Colors.blood)

        AnimSlotRows[slotName] = { row = row, label = animLabel, resetBtn = resetBtn }
    end
end

-- Funcao pra atualizar UI de um slot
updateAnimSlotUI = function(slotName)
    local slotUI = AnimSlotRows[slotName]
    if not slotUI then return end
    if currentAnimations[slotName] then
        slotUI.label.Text = "Custom (" .. tostring(currentAnimations[slotName]) .. ")"
        slotUI.label.TextColor3 = Colors.green
        slotUI.resetBtn.Visible = true
    else
        slotUI.label.Text = "Default"
        slotUI.label.TextColor3 = Colors.textDim
        slotUI.resetBtn.Visible = false
    end
end

-- Speed slider
AnimSpeedSlider = createSliderRow(AnimScroll, "Speed", 2, 50, 10, 0, function(val)
    animSpeed = val / 10
    -- Atualiza label com formato "X.Xx" durante drag
    for _, child in ipairs(AnimSpeedSlider.row:GetChildren()) do
        if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Right then
            child.Text = string.format("%.1fx", val / 10)
            break
        end
    end
end)
do
    local origSetValue = AnimSpeedSlider.setValue
    AnimSpeedSlider.setValue = function(v)
        origSetValue(v)
        for _, child in ipairs(AnimSpeedSlider.row:GetChildren()) do
            if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Right then
                child.Text = string.format("%.1fx", v / 10)
                break
            end
        end
    end
    AnimSpeedSlider.setValue(10)
end

-- Reset All button
AnimResetAllBtn = Instance.new("TextButton")
AnimResetAllBtn.Size = UDim2.new(1, 0, 0, 26)
AnimResetAllBtn.BackgroundColor3 = Colors.bloodDark
AnimResetAllBtn.Text = "↺ Reset All"
AnimResetAllBtn.TextColor3 = Colors.text
AnimResetAllBtn.TextSize = 10
AnimResetAllBtn.Font = Enum.Font.GothamBold
AnimResetAllBtn.AutoButtonColor = false
AnimResetAllBtn.Parent = AnimScroll
Instance.new("UICorner", AnimResetAllBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(AnimResetAllBtn, Colors.bloodDark, Colors.blood)

--==================================================
-- CATALOG SEARCH SECTION
--==================================================

AnimCatalogHeader = createSectionHeader(AnimScroll, "Catalog Search", 0)

AnimSearchBox = Instance.new("TextBox")
AnimSearchBox.Size = UDim2.new(1, 0, 0, 26)
AnimSearchBox.BackgroundColor3 = Colors.inputBg
AnimSearchBox.Text = ""
AnimSearchBox.PlaceholderText = "🔍 Search animations or paste bundle ID..."
AnimSearchBox.PlaceholderColor3 = Colors.textDim
AnimSearchBox.TextColor3 = Colors.text
AnimSearchBox.TextSize = 11
AnimSearchBox.Font = Enum.Font.Code
AnimSearchBox.ClearTextOnFocus = false
AnimSearchBox.Parent = AnimScroll
Instance.new("UICorner", AnimSearchBox).CornerRadius = UDim.new(0, 6)
do
    local animSearchStroke = Instance.new("UIStroke", AnimSearchBox)
    animSearchStroke.Color = Colors.inputBorder
    animSearchStroke.Thickness = 1
    AnimSearchBox.Focused:Connect(function()
        TweenService:Create(animSearchStroke, TweenInfo.new(0.2), { Color = Colors.purpleLight, Thickness = 1.5 }):Play()
    end)
    AnimSearchBox.FocusLost:Connect(function()
        TweenService:Create(animSearchStroke, TweenInfo.new(0.3), { Color = Colors.inputBorder, Thickness = 1 }):Play()
    end)
end

AnimCatalogGrid = Instance.new("Frame")
AnimCatalogGrid.Name = "AnimCatalogGrid"
AnimCatalogGrid.Size = UDim2.new(1, 0, 0, 300)
AnimCatalogGrid.BackgroundTransparency = 1
AnimCatalogGrid.ClipsDescendants = true
AnimCatalogGrid.Parent = AnimScroll

AnimCatalogGridLayout = Instance.new("UIGridLayout", AnimCatalogGrid)
AnimCatalogGridLayout.CellSize = UDim2.new(0, 60, 0, 82)
AnimCatalogGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
AnimCatalogGridLayout.FillDirection = Enum.FillDirection.Horizontal
AnimCatalogGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

AnimCatalogEmpty = Instance.new("TextLabel")
AnimCatalogEmpty.Size = UDim2.new(1, 0, 0, 30)
AnimCatalogEmpty.BackgroundTransparency = 1
AnimCatalogEmpty.Text = "Loading popular animations..."
AnimCatalogEmpty.TextColor3 = Colors.textDim
AnimCatalogEmpty.TextSize = 10
AnimCatalogEmpty.Font = Enum.Font.Gotham
AnimCatalogEmpty.Visible = true
AnimCatalogEmpty.Parent = AnimScroll

-- ════════════════════════════════════════════════
-- DETAIL VIEW (hidden by default)
-- ════════════════════════════════════════════════

AnimDetailFrame = Instance.new("Frame")
AnimDetailFrame.Name = "AnimDetailView"
AnimDetailFrame.Size = UDim2.new(1, 0, 1, 0)
AnimDetailFrame.BackgroundTransparency = 1
AnimDetailFrame.Visible = false
AnimDetailFrame.Parent = AnimContent

AnimDetailScroll = Instance.new("ScrollingFrame")
AnimDetailScroll.Size = UDim2.new(1, 0, 1, 0)
AnimDetailScroll.BackgroundTransparency = 1
AnimDetailScroll.ScrollBarThickness = 3
AnimDetailScroll.ScrollBarImageColor3 = Colors.blood
AnimDetailScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
AnimDetailScroll.BorderSizePixel = 0
AnimDetailScroll.Parent = AnimDetailFrame

AnimDetailBackBtn = Instance.new("TextButton")
AnimDetailBackBtn.Size = UDim2.new(1, 0, 0, 24)
AnimDetailBackBtn.Position = UDim2.new(0, 0, 0, 0)
AnimDetailBackBtn.BackgroundTransparency = 1
AnimDetailBackBtn.Text = "← Back"
AnimDetailBackBtn.TextColor3 = Colors.purpleLight
AnimDetailBackBtn.TextSize = 11
AnimDetailBackBtn.Font = Enum.Font.GothamBold
AnimDetailBackBtn.TextXAlignment = Enum.TextXAlignment.Left
AnimDetailBackBtn.AutoButtonColor = false
AnimDetailBackBtn.Parent = AnimDetailScroll

AnimDetailThumb = Instance.new("ImageLabel")
AnimDetailThumb.Size = UDim2.new(0, 60, 0, 60)
AnimDetailThumb.Position = UDim2.new(0, 0, 0, 30)
AnimDetailThumb.BackgroundColor3 = Colors.card
AnimDetailThumb.BorderSizePixel = 0
AnimDetailThumb.Parent = AnimDetailScroll
Instance.new("UICorner", AnimDetailThumb).CornerRadius = UDim.new(0, 8)

AnimDetailName = Instance.new("TextLabel")
AnimDetailName.Size = UDim2.new(1, -70, 0, 20)
AnimDetailName.Position = UDim2.new(0, 68, 0, 32)
AnimDetailName.BackgroundTransparency = 1
AnimDetailName.Text = ""
AnimDetailName.TextColor3 = Colors.text
AnimDetailName.TextSize = 12
AnimDetailName.Font = Enum.Font.GothamBold
AnimDetailName.TextXAlignment = Enum.TextXAlignment.Left
AnimDetailName.TextTruncate = Enum.TextTruncate.AtEnd
AnimDetailName.Parent = AnimDetailScroll

AnimDetailFavBtn = Instance.new("TextButton")
AnimDetailFavBtn.Size = UDim2.new(0.5, -2, 0, 26)
AnimDetailFavBtn.Position = UDim2.new(0, 0, 0, 98)
AnimDetailFavBtn.BackgroundColor3 = Colors.card
AnimDetailFavBtn.Text = "☆ Favorite"
AnimDetailFavBtn.TextColor3 = Colors.text
AnimDetailFavBtn.TextSize = 10
AnimDetailFavBtn.Font = Enum.Font.GothamBold
AnimDetailFavBtn.AutoButtonColor = false
AnimDetailFavBtn.Parent = AnimDetailScroll
Instance.new("UICorner", AnimDetailFavBtn).CornerRadius = UDim.new(0, 6)

AnimDetailApplyAllBtn = Instance.new("TextButton")
AnimDetailApplyAllBtn.Size = UDim2.new(0.5, -2, 0, 26)
AnimDetailApplyAllBtn.Position = UDim2.new(0.5, 2, 0, 98)
AnimDetailApplyAllBtn.BackgroundColor3 = Colors.green
AnimDetailApplyAllBtn.Text = "▶ Apply All"
AnimDetailApplyAllBtn.TextColor3 = Colors.text
AnimDetailApplyAllBtn.TextSize = 10
AnimDetailApplyAllBtn.Font = Enum.Font.GothamBold
AnimDetailApplyAllBtn.AutoButtonColor = false
AnimDetailApplyAllBtn.Visible = false
AnimDetailApplyAllBtn.Parent = AnimDetailScroll
Instance.new("UICorner", AnimDetailApplyAllBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(AnimDetailApplyAllBtn, Colors.green, Colors.greenLight)

AnimDetailStatus = Instance.new("TextLabel")
AnimDetailStatus.Size = UDim2.new(1, 0, 0, 20)
AnimDetailStatus.Position = UDim2.new(0, 0, 0, 130)
AnimDetailStatus.BackgroundTransparency = 1
AnimDetailStatus.Text = "Loading bundle..."
AnimDetailStatus.TextColor3 = Colors.textDim
AnimDetailStatus.TextSize = 10
AnimDetailStatus.Font = Enum.Font.Gotham
AnimDetailStatus.Visible = false
AnimDetailStatus.Parent = AnimDetailScroll

AnimDetailSlotList = Instance.new("Frame")
AnimDetailSlotList.Name = "SlotList"
AnimDetailSlotList.Size = UDim2.new(1, 0, 0, 0)
AnimDetailSlotList.Position = UDim2.new(0, 0, 0, 134)
AnimDetailSlotList.BackgroundTransparency = 1
AnimDetailSlotList.Parent = AnimDetailScroll

AnimDetailSlotListLayout = Instance.new("UIListLayout", AnimDetailSlotList)
AnimDetailSlotListLayout.SortOrder = Enum.SortOrder.LayoutOrder
AnimDetailSlotListLayout.Padding = UDim.new(0, 4)

AnimDetailApplySelBtn = Instance.new("TextButton")
AnimDetailApplySelBtn.Size = UDim2.new(1, 0, 0, 28)
AnimDetailApplySelBtn.BackgroundColor3 = Colors.purple
AnimDetailApplySelBtn.Text = "▶ Apply Selected"
AnimDetailApplySelBtn.TextColor3 = Colors.text
AnimDetailApplySelBtn.TextSize = 10
AnimDetailApplySelBtn.Font = Enum.Font.GothamBold
AnimDetailApplySelBtn.AutoButtonColor = false
AnimDetailApplySelBtn.Visible = false
AnimDetailApplySelBtn.Parent = AnimDetailScroll
Instance.new("UICorner", AnimDetailApplySelBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(AnimDetailApplySelBtn, Colors.purple, Colors.purpleLight)

-- ════════════════════════════════════════════════
-- LAYOUT FUNCTION
-- ════════════════════════════════════════════════

recalcAnimLayout = function()
    local favHeight = AnimFavGrid.Size.Y.Offset
    if favHeight < 10 then favHeight = 24 end

    local baseY = animFavSectionY + favHeight + 8

    AnimSlotsHeader.Position = UDim2.new(0, 0, 0, baseY)
    AnimSlotsContainer.Position = UDim2.new(0, 0, 0, baseY + 24)

    local slotsHeight = 7 * 28
    AnimSpeedSlider.row.Position = UDim2.new(0, 10, 0, baseY + 24 + slotsHeight + 4)
    AnimResetAllBtn.Position = UDim2.new(0, 0, 0, baseY + 24 + slotsHeight + 40)

    local catalogY = baseY + 24 + slotsHeight + 74
    AnimCatalogHeader.Position = UDim2.new(0, 0, 0, catalogY)
    AnimSearchBox.Position = UDim2.new(0, 0, 0, catalogY + 26)
    AnimCatalogGrid.Position = UDim2.new(0, 0, 0, catalogY + 58)
    AnimCatalogEmpty.Position = UDim2.new(0, 0, 0, catalogY + 58)

    AnimScroll.CanvasSize = UDim2.new(0, 0, 0, catalogY + 58 + AnimCatalogGrid.Size.Y.Offset + 20)
end

recalcAnimLayout()


--[[ ═══════ MODULE: 10_tab_settings.luau ═══════ ]]

--==================================================
-- TAB: SETTINGS
--==================================================

local SettingsContent = Instance.new("Frame")
SettingsContent.Name = "SettingsContent"
SettingsContent.Size = UDim2.new(1, 0, 1, 0)
SettingsContent.BackgroundTransparency = 1
SettingsContent.Visible = false
SettingsContent.Parent = TabContent
tabContents["settings"] = SettingsContent

-- Scroll container
local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, 0, 1, 0)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.ScrollBarThickness = 3
SettingsScroll.ScrollBarImageColor3 = Colors.blood
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
SettingsScroll.BorderSizePixel = 0
SettingsScroll.Parent = SettingsContent

--==================================================
-- AUTO-SCAN SETTINGS
--==================================================

createSectionHeader(SettingsScroll, "Auto-Scan", 0)

local autoScanSettingToggle = createVampToggle(SettingsScroll, "Auto-Scan Enabled", "enabled", autoScanConfig, 26, Colors.green)

local autoScanIntervalSlider = createSliderRow(SettingsScroll, "Interval (sec)", 3, 30, autoScanConfig.interval, 56, function(val)
    autoScanConfig.interval = val
end)

--==================================================
-- HOTKEY INFO
--==================================================

createSectionHeader(SettingsScroll, "Hotkey", 92)

local hotkeyLabel = Instance.new("TextLabel")
hotkeyLabel.Size = UDim2.new(1, 0, 0, 20)
hotkeyLabel.Position = UDim2.new(0, 0, 0, 118)
hotkeyLabel.BackgroundTransparency = 1
hotkeyLabel.Text = "Ctrl+G — Toggle Scanner"
hotkeyLabel.TextColor3 = Colors.textDim
hotkeyLabel.TextSize = 11
hotkeyLabel.Font = Enum.Font.Gotham
hotkeyLabel.TextXAlignment = Enum.TextXAlignment.Left
hotkeyLabel.Parent = SettingsScroll

--==================================================
-- SPECTATE SETTINGS
--==================================================

createSectionHeader(SettingsScroll, "Spectate", 144)

local spectateHLToggle = createVampToggle(SettingsScroll, "Spectate Highlight", "showHighlight", spectateConfig, 170, Colors.bloodLight)

--==================================================
-- SAVE INSTANCE
--==================================================

createSectionHeader(SettingsScroll, "Save Instance", 200)

local FileNameLabel = Instance.new("TextLabel")
FileNameLabel.Size = UDim2.new(1, 0, 0, 16)
FileNameLabel.Position = UDim2.new(0, 0, 0, 226)
FileNameLabel.BackgroundTransparency = 1
FileNameLabel.Text = "File name:"
FileNameLabel.TextColor3 = Colors.textDim
FileNameLabel.TextSize = 11
FileNameLabel.Font = Enum.Font.GothamBold
FileNameLabel.TextXAlignment = Enum.TextXAlignment.Left
FileNameLabel.Parent = SettingsScroll

local FileNameBox = Instance.new("TextBox")
FileNameBox.Size = UDim2.new(1, 0, 0, 28)
FileNameBox.Position = UDim2.new(0, 0, 0, 244)
FileNameBox.BackgroundColor3 = Colors.inputBg
FileNameBox.Text = ""
FileNameBox.PlaceholderText = "auto: PlaceId_Date"
FileNameBox.TextColor3 = Colors.text
FileNameBox.PlaceholderColor3 = Colors.textDim
FileNameBox.TextSize = 11
FileNameBox.Font = Enum.Font.Code
FileNameBox.ClearTextOnFocus = false
FileNameBox.Parent = SettingsScroll
Instance.new("UICorner", FileNameBox).CornerRadius = UDim.new(0, 6)
local fileBoxStroke = Instance.new("UIStroke", FileNameBox)
fileBoxStroke.Color = Colors.inputBorder
fileBoxStroke.Thickness = 1

FileNameBox.Focused:Connect(function()
    TweenService:Create(fileBoxStroke, TweenInfo.new(0.2), { Color = Colors.purpleLight, Thickness = 1.5 }):Play()
end)
FileNameBox.FocusLost:Connect(function()
    TweenService:Create(fileBoxStroke, TweenInfo.new(0.3), { Color = Colors.inputBorder, Thickness = 1 }):Play()
end)

-- Save toggles
local saveY = 280
local saveToggles = {}

local saveToggleDefs = {
    { label = "Decompile Scripts", key = "DecompileMode" },
    { label = "Save Players", key = "SavePlayers" },
    { label = "Remove Characters", key = "RemovePlayerCharacters" },
    { label = "Nil Instances", key = "NilInstances" },
    { label = "Non-Creatable", key = "SaveNonCreatable" },
    { label = "Isolate LocalPlayer", key = "IsolateLocalPlayer" },
    { label = "Camera Instances", key = "SaveCameraInstances" },
}

for i, def in ipairs(saveToggleDefs) do
    saveToggles[def.key] = createVampToggle(SettingsScroll, def.label, def.key, saveConfigState, saveY + (i - 1) * 30, Colors.purple)
end

-- Save buttons
local saveBtnY = saveY + #saveToggleDefs * 30 + 8

local ConfirmSaveBtn = Instance.new("TextButton")
ConfirmSaveBtn.Size = UDim2.new(0.5, -3, 0, 32)
ConfirmSaveBtn.Position = UDim2.new(0, 0, 0, saveBtnY)
ConfirmSaveBtn.BackgroundColor3 = Colors.purple
ConfirmSaveBtn.Text = "💾 SAVE"
ConfirmSaveBtn.TextColor3 = Colors.text
ConfirmSaveBtn.TextSize = 12
ConfirmSaveBtn.Font = Enum.Font.GothamBold
ConfirmSaveBtn.AutoButtonColor = false
ConfirmSaveBtn.Parent = SettingsScroll
Instance.new("UICorner", ConfirmSaveBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ConfirmSaveBtn)
makeHoverable(ConfirmSaveBtn, Colors.purple, Colors.purpleLight)

local SaveAllBtn = Instance.new("TextButton")
SaveAllBtn.Size = UDim2.new(0.5, -3, 0, 32)
SaveAllBtn.Position = UDim2.new(0.5, 3, 0, saveBtnY)
SaveAllBtn.BackgroundColor3 = Colors.green
SaveAllBtn.Text = "⚡ SAVE ALL"
SaveAllBtn.TextColor3 = Colors.text
SaveAllBtn.TextSize = 12
SaveAllBtn.Font = Enum.Font.GothamBold
SaveAllBtn.AutoButtonColor = false
SaveAllBtn.Parent = SettingsScroll
Instance.new("UICorner", SaveAllBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(SaveAllBtn)
makeHoverable(SaveAllBtn, Colors.green, Colors.greenLight)

SaveCharsBtn = Instance.new("TextButton")
SaveCharsBtn.Size = UDim2.new(0.5, -3, 0, 32)
SaveCharsBtn.Position = UDim2.new(0, 0, 0, saveBtnY + 38)
SaveCharsBtn.BackgroundColor3 = Colors.glowPurple
SaveCharsBtn.Text = "🧍 CHARACTERS"
SaveCharsBtn.TextColor3 = Colors.text
SaveCharsBtn.TextSize = 11
SaveCharsBtn.Font = Enum.Font.GothamBold
SaveCharsBtn.AutoButtonColor = false
SaveCharsBtn.Parent = SettingsScroll
Instance.new("UICorner", SaveCharsBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(SaveCharsBtn)
makeHoverable(SaveCharsBtn, Colors.glowPurple, Colors.purple)

SaveNPCsBtn = Instance.new("TextButton")
SaveNPCsBtn.Size = UDim2.new(0.5, -3, 0, 32)
SaveNPCsBtn.Position = UDim2.new(0.5, 3, 0, saveBtnY + 38)
SaveNPCsBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
SaveNPCsBtn.Text = "🤖 NPCs"
SaveNPCsBtn.TextColor3 = Colors.text
SaveNPCsBtn.TextSize = 11
SaveNPCsBtn.Font = Enum.Font.GothamBold
SaveNPCsBtn.AutoButtonColor = false
SaveNPCsBtn.Parent = SettingsScroll
Instance.new("UICorner", SaveNPCsBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(SaveNPCsBtn)
makeHoverable(SaveNPCsBtn, Color3.fromRGB(180, 120, 40), Color3.fromRGB(220, 150, 60))

--==================================================
-- ABOUT
--==================================================

createSectionHeader(SettingsScroll, "About", saveBtnY + 80)

local aboutLabel = Instance.new("TextLabel")
aboutLabel.Size = UDim2.new(1, 0, 0, 40)
aboutLabel.Position = UDim2.new(0, 0, 0, saveBtnY + 106)
aboutLabel.BackgroundTransparency = 1
aboutLabel.Text = "🦇 Vampire Rig Scanner v13\nCreate By VampireSonata"
aboutLabel.TextColor3 = Colors.textBlood
aboutLabel.TextSize = 11
aboutLabel.Font = Enum.Font.GothamBold
aboutLabel.TextXAlignment = Enum.TextXAlignment.Left
aboutLabel.TextWrapped = true
aboutLabel.Parent = SettingsScroll

--==================================================
-- COSMETICS
--==================================================

createSectionHeader(SettingsScroll, "Cosmetics", saveBtnY + 154)

cosmeticHeadlessToggle = createVampToggle(SettingsScroll, "Headless", "headless", cosmeticState, saveBtnY + 180, Colors.glowPurple)
cosmeticInvisibleToggle = createVampToggle(SettingsScroll, "Invisible", "invisible", cosmeticState, saveBtnY + 208, Colors.glowPurple)
cosmeticGhostToggle = createVampToggle(SettingsScroll, "Ghost (Semi-Transparent)", "ghost", cosmeticState, saveBtnY + 236, Colors.glowPurple)
cosmeticHideNametagsToggle = createVampToggle(SettingsScroll, "Hide All Nametags", "hideNametags", cosmeticState, saveBtnY + 264, Colors.glowPurple)
cosmeticHideVampTagToggle = createVampToggle(SettingsScroll, "Hide Script Nametag", "hideVampNametag", cosmeticState, saveBtnY + 292, Colors.glowPurple)
cosmeticHideGameUIToggle = createVampToggle(SettingsScroll, "Hide Game UI", "hideGameUI", cosmeticState, saveBtnY + 320, Colors.glowPurple)

CosmeticResetBtn = Instance.new("TextButton")
CosmeticResetBtn.Size = UDim2.new(1, 0, 0, 26)
CosmeticResetBtn.Position = UDim2.new(0, 0, 0, saveBtnY + 356)
CosmeticResetBtn.BackgroundColor3 = Colors.warning
CosmeticResetBtn.Text = "↺ RESET COSMETICS"
CosmeticResetBtn.TextColor3 = Colors.bg
CosmeticResetBtn.TextSize = 11
CosmeticResetBtn.Font = Enum.Font.GothamBold
CosmeticResetBtn.AutoButtonColor = false
CosmeticResetBtn.Parent = SettingsScroll
Instance.new("UICorner", CosmeticResetBtn).CornerRadius = UDim.new(0, 6)
makeHoverable(CosmeticResetBtn, Colors.warning, Color3.fromRGB(230, 180, 60))

--==================================================
-- SECURITY TOOLS
--==================================================

createSectionHeader(SettingsScroll, "Security Tools", saveBtnY + 392)

RemoteSpyOpenBtn = Instance.new("TextButton")
RemoteSpyOpenBtn.Size = UDim2.new(1, 0, 0, 28)
RemoteSpyOpenBtn.Position = UDim2.new(0, 0, 0, saveBtnY + 418)
RemoteSpyOpenBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 120)
RemoteSpyOpenBtn.Text = "🕵 OPEN REMOTE SPY"
RemoteSpyOpenBtn.TextColor3 = Colors.text
RemoteSpyOpenBtn.TextSize = 11
RemoteSpyOpenBtn.Font = Enum.Font.GothamBold
RemoteSpyOpenBtn.AutoButtonColor = false
RemoteSpyOpenBtn.Parent = SettingsScroll
Instance.new("UICorner", RemoteSpyOpenBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(RemoteSpyOpenBtn)
makeHoverable(RemoteSpyOpenBtn, Color3.fromRGB(0, 140, 120), Color3.fromRGB(0, 180, 160))

--==================================================
-- DEV TOOLS
--==================================================

createSectionHeader(SettingsScroll, "Dev Tools", saveBtnY + 458)

-- Anti-AFK toggle button
AntiAfkBtn = Instance.new("TextButton")
AntiAfkBtn.Size = UDim2.new(1, 0, 0, 28)
AntiAfkBtn.Position = UDim2.new(0, 0, 0, saveBtnY + 484)
AntiAfkBtn.BackgroundColor3 = Color3.fromRGB(50, 25, 25)
AntiAfkBtn.Text = "⚡ ANTI-AFK: OFF"
AntiAfkBtn.TextColor3 = Colors.text
AntiAfkBtn.TextSize = 11
AntiAfkBtn.Font = Enum.Font.GothamBold
AntiAfkBtn.AutoButtonColor = false
AntiAfkBtn.Parent = SettingsScroll
Instance.new("UICorner", AntiAfkBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(AntiAfkBtn)
makeHoverable(AntiAfkBtn, Color3.fromRGB(50, 25, 25), Color3.fromRGB(70, 40, 40))

-- Chat Spy open button
ChatSpyOpenBtn = Instance.new("TextButton")
ChatSpyOpenBtn.Size = UDim2.new(1, 0, 0, 28)
ChatSpyOpenBtn.Position = UDim2.new(0, 0, 0, saveBtnY + 518)
ChatSpyOpenBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
ChatSpyOpenBtn.Text = "💬 OPEN CHAT SPY"
ChatSpyOpenBtn.TextColor3 = Colors.text
ChatSpyOpenBtn.TextSize = 11
ChatSpyOpenBtn.Font = Enum.Font.GothamBold
ChatSpyOpenBtn.AutoButtonColor = false
ChatSpyOpenBtn.Parent = SettingsScroll
Instance.new("UICorner", ChatSpyOpenBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ChatSpyOpenBtn)
makeHoverable(ChatSpyOpenBtn, Color3.fromRGB(40, 140, 40), Color3.fromRGB(60, 180, 60))

-- Execute Script label
ExecLabel = Instance.new("TextLabel")
ExecLabel.Size = UDim2.new(1, 0, 0, 16)
ExecLabel.Position = UDim2.new(0, 0, 0, saveBtnY + 554)
ExecLabel.BackgroundTransparency = 1
ExecLabel.Text = "Execute Script:"
ExecLabel.TextColor3 = Colors.textDim
ExecLabel.TextSize = 11
ExecLabel.Font = Enum.Font.GothamBold
ExecLabel.TextXAlignment = Enum.TextXAlignment.Left
ExecLabel.Parent = SettingsScroll

-- Execute TextBox
ExecScriptBox = Instance.new("TextBox")
ExecScriptBox.Size = UDim2.new(1, 0, 0, 60)
ExecScriptBox.Position = UDim2.new(0, 0, 0, saveBtnY + 572)
ExecScriptBox.BackgroundColor3 = Colors.inputBg
ExecScriptBox.Text = ""
ExecScriptBox.PlaceholderText = "paste lua code here..."
ExecScriptBox.TextColor3 = Colors.text
ExecScriptBox.PlaceholderColor3 = Colors.textDim
ExecScriptBox.TextSize = 10
ExecScriptBox.Font = Enum.Font.Code
ExecScriptBox.TextXAlignment = Enum.TextXAlignment.Left
ExecScriptBox.TextYAlignment = Enum.TextYAlignment.Top
ExecScriptBox.ClearTextOnFocus = false
ExecScriptBox.TextWrapped = true
ExecScriptBox.MultiLine = true
ExecScriptBox.Parent = SettingsScroll
Instance.new("UICorner", ExecScriptBox).CornerRadius = UDim.new(0, 6)
ExecScriptBoxPad = Instance.new("UIPadding", ExecScriptBox)
ExecScriptBoxPad.PaddingLeft = UDim.new(0, 6)
ExecScriptBoxPad.PaddingTop = UDim.new(0, 4)
ExecScriptStroke = Instance.new("UIStroke", ExecScriptBox)
ExecScriptStroke.Color = Colors.inputBorder
ExecScriptStroke.Thickness = 1

ExecScriptBox.Focused:Connect(function()
    TweenService:Create(ExecScriptStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(80, 220, 100), Thickness = 1.5 }):Play()
end)
ExecScriptBox.FocusLost:Connect(function()
    TweenService:Create(ExecScriptStroke, TweenInfo.new(0.3), { Color = Colors.inputBorder, Thickness = 1 }):Play()
end)

-- Run button
ExecRunBtn = Instance.new("TextButton")
ExecRunBtn.Size = UDim2.new(1, 0, 0, 28)
ExecRunBtn.Position = UDim2.new(0, 0, 0, saveBtnY + 638)
ExecRunBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
ExecRunBtn.Text = "▶ RUN SCRIPT"
ExecRunBtn.TextColor3 = Colors.text
ExecRunBtn.TextSize = 11
ExecRunBtn.Font = Enum.Font.GothamBold
ExecRunBtn.AutoButtonColor = false
ExecRunBtn.Parent = SettingsScroll
Instance.new("UICorner", ExecRunBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(ExecRunBtn)
makeHoverable(ExecRunBtn, Color3.fromRGB(40, 140, 40), Color3.fromRGB(60, 180, 60))

-- ════════════════════════════════════════════════
-- SEÇÃO: Licença / Auth Info
-- ════════════════════════════════════════════════

AuthInfoY = saveBtnY + 690
createSectionHeader(SettingsScroll, "License", AuthInfoY)

AuthInfoLabel = Instance.new("TextLabel")
AuthInfoLabel.Size = UDim2.new(1, 0, 0, 40)
AuthInfoLabel.Position = UDim2.new(0, 0, 0, AuthInfoY + 26)
AuthInfoLabel.BackgroundColor3 = Colors.card
AuthInfoLabel.BackgroundTransparency = 0.3
AuthInfoLabel.TextColor3 = Colors.text
AuthInfoLabel.TextSize = 10
AuthInfoLabel.Font = Enum.Font.Code
AuthInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
AuthInfoLabel.TextWrapped = true
AuthInfoLabel.Parent = SettingsScroll
Instance.new("UICorner", AuthInfoLabel).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", AuthInfoLabel).PaddingLeft = UDim.new(0, 8)

-- Preencher info de auth
do
	local badge = getRoleBadge(authRole or "user")
	local name = (authData and authData.name) or LP.Name
	local role = authRole or "user"
	AuthInfoLabel.Text = badge .. " " .. name .. " | Role: " .. string.upper(role) .. "\n" .. SCRIPT_NAME .. " " .. SCRIPT_VERSION
	AuthInfoLabel.TextColor3 = getRoleColor(role)
end

-- ════════════════════════════════════════════════
-- SEÇÃO: Online Users (visível para contributor+)
-- ════════════════════════════════════════════════

OnlineUsersY = AuthInfoY + 80
createSectionHeader(SettingsScroll, "Online Users", OnlineUsersY)

OnlineUsersScroll = Instance.new("ScrollingFrame")
OnlineUsersScroll.Size = UDim2.new(1, 0, 0, 120)
OnlineUsersScroll.Position = UDim2.new(0, 0, 0, OnlineUsersY + 26)
OnlineUsersScroll.BackgroundColor3 = Colors.content
OnlineUsersScroll.BackgroundTransparency = 0.5
OnlineUsersScroll.ScrollBarThickness = 2
OnlineUsersScroll.ScrollBarImageColor3 = Colors.blood
OnlineUsersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
OnlineUsersScroll.BorderSizePixel = 0
OnlineUsersScroll.Parent = SettingsScroll
Instance.new("UICorner", OnlineUsersScroll).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", OnlineUsersScroll).Color = Colors.separator

OnlineUsersLayout = Instance.new("UIListLayout", OnlineUsersScroll)
OnlineUsersLayout.Padding = UDim.new(0, 2)
OnlineUsersPad = Instance.new("UIPadding", OnlineUsersScroll)
OnlineUsersPad.PaddingTop = UDim.new(0, 4)
OnlineUsersPad.PaddingLeft = UDim.new(0, 4)
OnlineUsersPad.PaddingRight = UDim.new(0, 4)

OnlineUsersCountLabel = Instance.new("TextLabel")
OnlineUsersCountLabel.Size = UDim2.new(1, 0, 0, 14)
OnlineUsersCountLabel.Position = UDim2.new(0, 0, 0, OnlineUsersY + 150)
OnlineUsersCountLabel.BackgroundTransparency = 1
OnlineUsersCountLabel.Text = "Checking..."
OnlineUsersCountLabel.TextColor3 = Colors.textDim
OnlineUsersCountLabel.TextSize = 9
OnlineUsersCountLabel.Font = Enum.Font.Gotham
OnlineUsersCountLabel.TextXAlignment = Enum.TextXAlignment.Left
OnlineUsersCountLabel.Parent = SettingsScroll

-- Esconder se não tem permissão
if not hasPermission("see_online_users") then
	OnlineUsersScroll.Visible = false
	OnlineUsersCountLabel.Text = "🔒 VIP+ feature"
end

SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, OnlineUsersY + 180)


--[[ ═══════ MODULE: 11_preview_ui.luau ═══════ ]]

--==================================================
-- PREVIEW WINDOW — BOLA DE CRISTAL
--==================================================

local PreviewFrame = Instance.new("Frame")
PreviewFrame.Name = "Preview"
PreviewFrame.Size = UDim2.new(0, 320, 0, 500)
PreviewFrame.Position = UDim2.new(0.3, 430, 0.5, -250)
PreviewFrame.BackgroundColor3 = Colors.bg
PreviewFrame.BorderSizePixel = 0
PreviewFrame.Visible = false
PreviewFrame.Parent = ScreenGui

local previewStroke = Instance.new("UIStroke", PreviewFrame)
previewStroke.Color = Colors.glowPurple
previewStroke.Thickness = 1.5
Instance.new("UICorner", PreviewFrame).CornerRadius = UDim.new(0, 10)
addGradient(PreviewFrame, Colors.surfaceLight, Color3.fromRGB(8, 8, 10), 90)

-- Top bar
local PreviewTopBar = Instance.new("Frame")
PreviewTopBar.Size = UDim2.new(1, 0, 0, 35)
PreviewTopBar.BackgroundColor3 = Colors.topbar
PreviewTopBar.BorderSizePixel = 0
PreviewTopBar.Parent = PreviewFrame
Instance.new("UICorner", PreviewTopBar).CornerRadius = UDim.new(0, 10)
addGradient(PreviewTopBar, Color3.fromRGB(30, 10, 40), Colors.topbar, 0)

local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 10)
topBarFix.Position = UDim2.new(0, 0, 1, -10)
topBarFix.BackgroundColor3 = Colors.topbar
topBarFix.BorderSizePixel = 0
topBarFix.Parent = PreviewTopBar

addAccentLine(PreviewTopBar, UDim2.new(0, 0, 1, -1), Colors.glowPurple)

local PreviewTitle = Instance.new("TextLabel")
PreviewTitle.Size = UDim2.new(1, -50, 1, 0)
PreviewTitle.Position = UDim2.new(0, 10, 0, 0)
PreviewTitle.BackgroundTransparency = 1
PreviewTitle.Text = "🔮 Crystal Ball"
PreviewTitle.TextColor3 = Colors.purpleLight
PreviewTitle.TextSize = 13
PreviewTitle.Font = Enum.Font.GothamBold
PreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
PreviewTitle.Parent = PreviewTopBar

local PreviewClose = Instance.new("TextButton")
PreviewClose.Size = UDim2.new(0, 22, 0, 22)
PreviewClose.Position = UDim2.new(1, -28, 0, 6)
PreviewClose.BackgroundColor3 = Colors.blood
PreviewClose.Text = "X"
PreviewClose.TextColor3 = Colors.text
PreviewClose.TextSize = 12
PreviewClose.Font = Enum.Font.GothamBold
PreviewClose.AutoButtonColor = false
PreviewClose.Parent = PreviewTopBar
Instance.new("UICorner", PreviewClose).CornerRadius = UDim.new(0, 6)
makeHoverable(PreviewClose, Colors.blood, Colors.glowRed)

--==================================================
-- VIEWPORT (Crystal Ball)
--==================================================

local Viewport = Instance.new("ViewportFrame")
Viewport.Size = UDim2.new(1, -20, 0, 220)
Viewport.Position = UDim2.new(0, 10, 0, 42)
Viewport.BackgroundColor3 = Color3.fromRGB(5, 3, 8)
Viewport.BorderSizePixel = 0
Viewport.Ambient = Color3.fromRGB(180, 160, 200)
Viewport.LightColor = Color3.fromRGB(255, 240, 255)
Viewport.LightDirection = Vector3.new(-1, -1, -1)
Viewport.Parent = PreviewFrame
Instance.new("UICorner", Viewport).CornerRadius = UDim.new(0, 12)
local vpStroke = Instance.new("UIStroke", Viewport)
vpStroke.Color = Colors.glowPurple
vpStroke.Thickness = 2
vpStroke.Transparency = 0.2

-- "LIVE" badge overlay
local LiveBadge = Instance.new("TextLabel")
LiveBadge.Size = UDim2.new(0, 48, 0, 16)
LiveBadge.Position = UDim2.new(0, 6, 0, 6)
LiveBadge.BackgroundColor3 = Color3.fromRGB(180, 15, 15)
LiveBadge.Text = "● LIVE"
LiveBadge.TextColor3 = Colors.text
LiveBadge.TextSize = 9
LiveBadge.Font = Enum.Font.GothamBold
LiveBadge.Visible = false
LiveBadge.ZIndex = 10
LiveBadge.Parent = Viewport
Instance.new("UICorner", LiveBadge).CornerRadius = UDim.new(0, 4)

-- Distance overlay (top-right)
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0, 60, 0, 16)
DistLabel.Position = UDim2.new(1, -66, 0, 6)
DistLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
DistLabel.BackgroundTransparency = 0.3
DistLabel.Text = ""
DistLabel.TextColor3 = Colors.textDim
DistLabel.TextSize = 9
DistLabel.Font = Enum.Font.Code
DistLabel.Visible = false
DistLabel.ZIndex = 10
DistLabel.Parent = Viewport
Instance.new("UICorner", DistLabel).CornerRadius = UDim.new(0, 4)

-- Status text (center, for loading/errors)
local ViewportStatus = Instance.new("TextLabel")
ViewportStatus.Size = UDim2.new(1, 0, 1, 0)
ViewportStatus.BackgroundTransparency = 1
ViewportStatus.Text = ""
ViewportStatus.TextColor3 = Colors.textLoading
ViewportStatus.TextSize = 12
ViewportStatus.Font = Enum.Font.GothamBold
ViewportStatus.TextWrapped = true
ViewportStatus.ZIndex = 5
ViewportStatus.Parent = Viewport

--==================================================
-- INFO BAR (name, type, HP)
--==================================================

local InfoBar = Instance.new("Frame")
InfoBar.Size = UDim2.new(1, -20, 0, 42)
InfoBar.Position = UDim2.new(0, 10, 0, 268)
InfoBar.BackgroundColor3 = Colors.card
InfoBar.BorderSizePixel = 0
InfoBar.Parent = PreviewFrame
Instance.new("UICorner", InfoBar).CornerRadius = UDim.new(0, 6)
addGradient(InfoBar, Colors.surfaceLight, Colors.card, 0)

local PreviewNameLabel = Instance.new("TextLabel")
PreviewNameLabel.Size = UDim2.new(1, -60, 0, 18)
PreviewNameLabel.Position = UDim2.new(0, 8, 0, 3)
PreviewNameLabel.BackgroundTransparency = 1
PreviewNameLabel.Text = ""
PreviewNameLabel.TextColor3 = Colors.purpleLight
PreviewNameLabel.TextSize = 12
PreviewNameLabel.Font = Enum.Font.GothamBold
PreviewNameLabel.TextXAlignment = Enum.TextXAlignment.Left
PreviewNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
PreviewNameLabel.Parent = InfoBar

local PreviewTypeBadge = Instance.new("Frame")
PreviewTypeBadge.Size = UDim2.new(0, 50, 0, 14)
PreviewTypeBadge.Position = UDim2.new(1, -56, 0, 5)
PreviewTypeBadge.BackgroundColor3 = Colors.blood
PreviewTypeBadge.Parent = InfoBar
Instance.new("UICorner", PreviewTypeBadge).CornerRadius = UDim.new(0, 4)

local PreviewTypeLabel = Instance.new("TextLabel")
PreviewTypeLabel.Size = UDim2.new(1, 0, 1, 0)
PreviewTypeLabel.BackgroundTransparency = 1
PreviewTypeLabel.Text = "PLAYER"
PreviewTypeLabel.TextColor3 = Colors.text
PreviewTypeLabel.TextSize = 8
PreviewTypeLabel.Font = Enum.Font.GothamBold
PreviewTypeLabel.Parent = PreviewTypeBadge

-- HP bar
local PreviewHPBg = Instance.new("Frame")
PreviewHPBg.Size = UDim2.new(1, -16, 0, 6)
PreviewHPBg.Position = UDim2.new(0, 8, 0, 26)
PreviewHPBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PreviewHPBg.BorderSizePixel = 0
PreviewHPBg.Parent = InfoBar
Instance.new("UICorner", PreviewHPBg).CornerRadius = UDim.new(0, 3)

local PreviewHPFill = Instance.new("Frame")
PreviewHPFill.Size = UDim2.new(1, 0, 1, 0)
PreviewHPFill.BackgroundColor3 = Colors.green
PreviewHPFill.BorderSizePixel = 0
PreviewHPFill.Parent = PreviewHPBg
Instance.new("UICorner", PreviewHPFill).CornerRadius = UDim.new(0, 3)

local PreviewHPLabel = Instance.new("TextLabel")
PreviewHPLabel.Size = UDim2.new(1, 0, 0, 8)
PreviewHPLabel.Position = UDim2.new(0, 0, 0, 34)
PreviewHPLabel.BackgroundTransparency = 1
PreviewHPLabel.Text = ""
PreviewHPLabel.TextColor3 = Colors.textDim
PreviewHPLabel.TextSize = 8
PreviewHPLabel.Font = Enum.Font.Code
PreviewHPLabel.Parent = InfoBar

--==================================================
-- INFO SCROLL (accessories, scales, etc)
--==================================================

local InfoScroll = Instance.new("ScrollingFrame")
InfoScroll.Size = UDim2.new(1, -20, 0, 115)
InfoScroll.Position = UDim2.new(0, 10, 0, 316)
InfoScroll.BackgroundColor3 = Colors.content
InfoScroll.BorderSizePixel = 0
InfoScroll.ScrollBarThickness = 3
InfoScroll.ScrollBarImageColor3 = Colors.glowPurple
InfoScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
InfoScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
InfoScroll.Parent = PreviewFrame
Instance.new("UICorner", InfoScroll).CornerRadius = UDim.new(0, 6)
local infoScrollStroke = Instance.new("UIStroke", InfoScroll)
infoScrollStroke.Color = Colors.separator
infoScrollStroke.Thickness = 0.5
infoScrollStroke.Transparency = 0.5

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -16, 0, 0)
InfoLabel.Position = UDim2.new(0, 8, 0, 4)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Colors.textDim
InfoLabel.TextSize = 9
InfoLabel.Font = Enum.Font.Code
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.TextWrapped = true
InfoLabel.AutomaticSize = Enum.AutomaticSize.Y
InfoLabel.Text = ""
InfoLabel.Parent = InfoScroll

--==================================================
-- COPY JSON BUTTON
--==================================================

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(1, -20, 0, 30)
CopyBtn.Position = UDim2.new(0, 10, 1, -60)
CopyBtn.BackgroundColor3 = Colors.purple
CopyBtn.Text = "🩸 COPY JSON"
CopyBtn.TextColor3 = Colors.text
CopyBtn.TextSize = 12
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.AutoButtonColor = false
CopyBtn.Parent = PreviewFrame
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)
addBtnGradient(CopyBtn)
makeHoverable(CopyBtn, Colors.purple, Colors.purpleLight)

--==================================================
-- FOOTER
--==================================================

local PreviewFooter = Instance.new("Frame")
PreviewFooter.Size = UDim2.new(1, 0, 0, 25)
PreviewFooter.Position = UDim2.new(0, 0, 1, -25)
PreviewFooter.BackgroundColor3 = Colors.topbar
PreviewFooter.BorderSizePixel = 0
PreviewFooter.Parent = PreviewFrame
Instance.new("UICorner", PreviewFooter).CornerRadius = UDim.new(0, 10)
addAccentLine(PreviewFooter, UDim2.new(0, 0, 0, 0), Colors.glowPurple)

local PreviewCredits = Instance.new("TextLabel")
PreviewCredits.Size = UDim2.new(1, 0, 1, 0)
PreviewCredits.BackgroundTransparency = 1
PreviewCredits.Text = "🔮 Crystal Ball — VampireSonata"
PreviewCredits.TextColor3 = Colors.textBlood
PreviewCredits.TextSize = 10
PreviewCredits.Font = Enum.Font.GothamBold
PreviewCredits.Parent = PreviewFooter


--[[ ═══════ MODULE: 12_helpers.luau ═══════ ]]

--==================================================
-- HELPERS
--==================================================

local function color3ToTable(c3)
    return { R = c3.R, G = c3.G, B = c3.B }
end

local function tableToColor3(t)
    if not t then return Color3.new(1, 1, 1) end
    return Color3.new(t.R or 1, t.G or 1, t.B or 1)
end

local AccessoryTypeMap = {
    [Enum.AccessoryType.Unknown] = "Unknown",
    [Enum.AccessoryType.Hat] = "Hat",
    [Enum.AccessoryType.Hair] = "Hair",
    [Enum.AccessoryType.Face] = "Face",
    [Enum.AccessoryType.Neck] = "Neck",
    [Enum.AccessoryType.Shoulder] = "Shoulder",
    [Enum.AccessoryType.Front] = "Front",
    [Enum.AccessoryType.Back] = "Back",
    [Enum.AccessoryType.Waist] = "Waist",
    [Enum.AccessoryType.TShirt] = "TShirt",
    [Enum.AccessoryType.Shirt] = "Shirt",
    [Enum.AccessoryType.Pants] = "Pants",
    [Enum.AccessoryType.Jacket] = "Jacket",
    [Enum.AccessoryType.Sweater] = "Sweater",
    [Enum.AccessoryType.Shorts] = "Shorts",
    [Enum.AccessoryType.LeftShoe] = "LeftShoe",
    [Enum.AccessoryType.RightShoe] = "RightShoe",
    [Enum.AccessoryType.DressSkirt] = "DressSkirt",
    [Enum.AccessoryType.Eyebrow] = "Eyebrow",
    [Enum.AccessoryType.Eyelash] = "Eyelash",
}

local function accessoryTypeToString(enumValue)
    return AccessoryTypeMap[enumValue] or tostring(enumValue):match("%.(%w+)$") or "Unknown"
end


--[[ ═══════ MODULE: 13_scanner_logic.luau ═══════ ]]

--==================================================
-- EXTRACT DESCRIPTION (pega o objeto HumanoidDescription)
--==================================================

local function getHumanoidDescription(humanoid)
    local success, desc = pcall(function()
        return humanoid:GetAppliedDescription()
    end)
    return success and desc or nil
end

-- Helper: tenta ler propriedade com pcall isolado
local function safeGet(obj, prop)
    local ok, val = pcall(function() return obj[prop] end)
    return ok and val or nil
end

-- Extrai dados para JSON (cada propriedade isolada pra nao derrubar as outras)
local function extractDescriptionData(desc, rigType)
    if not desc then return nil end

    local data = {}
    local capturado = {}
    local falhou = {}

    data.RigType = rigType or "R15"

    -- Roupas
    for _, prop in ipairs({"Shirt", "Pants", "GraphicTShirt", "Face"}) do
        local val = safeGet(desc, prop)
        if val ~= nil then
            data[prop] = val
            table.insert(capturado, prop)
        else
            table.insert(falhou, prop)
        end
    end

    -- Body parts
    for _, prop in ipairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
        local val = safeGet(desc, prop)
        if val ~= nil then
            data[prop] = val
            table.insert(capturado, prop)
        else
            table.insert(falhou, prop)
        end
    end

    -- Cores
    for _, prop in ipairs({"HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor"}) do
        local val = safeGet(desc, prop)
        if val ~= nil then
            data[prop] = color3ToTable(val)
            table.insert(capturado, prop)
        else
            table.insert(falhou, prop)
        end
    end

    -- Escalas
    for _, prop in ipairs({"BodyTypeScale", "DepthScale", "HeadScale", "HeightScale", "ProportionScale", "WidthScale"}) do
        local val = safeGet(desc, prop)
        if val ~= nil then
            data[prop] = val
            table.insert(capturado, prop)
        else
            table.insert(falhou, prop)
        end
    end

    -- Propriedades legacy de acessorios
    for _, prop in ipairs({
        "HatAccessory", "HairAccessory", "FaceAccessory",
        "NeckAccessory", "ShouldersAccessory", "FrontAccessory",
        "BackAccessory", "WaistAccessory",
    }) do
        local val = safeGet(desc, prop)
        if val ~= nil and val ~= "" then
            data[prop] = val
            table.insert(capturado, prop)
        end
    end

    -- Accessories via GetAccessories
    local accOk, accErr = pcall(function()
        local accessories = desc:GetAccessories(true)
        data.Accessories = {}
        for _, acc in ipairs(accessories) do
            table.insert(data.Accessories, {
                AssetId = acc.AssetId,
                AccessoryType = accessoryTypeToString(acc.AccessoryType),
                Order = acc.Order,
                Puffiness = acc.Puffiness,
                IsLayered = acc.IsLayered,
            })
        end
    end)
    if accOk then
        table.insert(capturado, "Accessories(" .. #(data.Accessories or {}) .. ")")
    else
        table.insert(falhou, "Accessories: " .. tostring(accErr))
    end

    -- AccessoryBlob
    if gethiddenproperty then
        local ok, blob = pcall(function()
            return gethiddenproperty(desc, "AccessoryBlob")
        end)
        if ok and blob and type(blob) == "string" and blob ~= "" then
            data.AccessoryBlob = blob
            table.insert(capturado, "AccessoryBlob(" .. #blob .. " chars)")
        else
            table.insert(falhou, "AccessoryBlob(gethiddenproperty: " .. tostring(blob) .. ")")
        end
    end

    -- AccessoryDescriptions
    local adjOk, adjErr = pcall(function()
        local accDescriptions = {}
        for _, child in ipairs(desc:GetChildren()) do
            if child:IsA("AccessoryDescription") and child.AssetId and child.AssetId > 0 then
                local pos = child.Position
                local rot = child.Rotation
                local scl = child.Scale

                local posChanged = pos.X ~= 0 or pos.Y ~= 0 or pos.Z ~= 0
                local rotChanged = rot.X ~= 0 or rot.Y ~= 0 or rot.Z ~= 0
                local sclChanged = scl.X ~= 1 or scl.Y ~= 1 or scl.Z ~= 1

                if posChanged or rotChanged or sclChanged then
                    local entry = { AssetId = child.AssetId }
                    if posChanged then entry.Position = { pos.X, pos.Y, pos.Z } end
                    if rotChanged then entry.Rotation = { rot.X, rot.Y, rot.Z } end
                    if sclChanged then entry.Scale = { scl.X, scl.Y, scl.Z } end
                    table.insert(accDescriptions, entry)
                end
            end
        end
        if #accDescriptions > 0 then
            data.AccessoryDescriptions = accDescriptions
        end
    end)
    if adjOk and data.AccessoryDescriptions then
        table.insert(capturado, "AccessoryDescriptions(" .. #data.AccessoryDescriptions .. ")")
    elseif not adjOk then
        table.insert(falhou, "AccessoryDescriptions: " .. tostring(adjErr))
    end

    log("  CAPTURADO:", table.concat(capturado, ", "))
    if #falhou > 0 then
        log("  FALHOU:", table.concat(falhou, ", "))
    end

    return data
end

--==================================================
-- LOAD RIG DATA
--==================================================

local function loadRigData(info)
    log("loadRigData:", info.name)

    if info.loaded then
        log("  Ja carregado")
        return true
    end

    local character = info.character

    if info.player and info.player.Character then
        character = info.player.Character
        info.character = character
    end

    if not character or not character.Parent then
        log("  ERRO: character invalido")
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        log("  ERRO: sem Humanoid")
        return false
    end

    log("  Pegando HumanoidDescription...")
    info.humanoidDescription = getHumanoidDescription(humanoid)

    if info.humanoidDescription then
        log("  HumanoidDescription: OK")
        info.rigType = humanoid.RigType
        info.fullDescription = extractDescriptionData(info.humanoidDescription, humanoid.RigType.Name)

        pcall(function()
            local ATT_TO_TYPE = {
                HatAttachment = "Hat",
                HairAttachment = "Hair",
                FaceFrontAttachment = "Face",
                FaceCenterAttachment = "Face",
                NeckAttachment = "Neck",
                BodyFrontAttachment = "Front",
                BodyBackAttachment = "Back",
                WaistCenterAttachment = "Waist",
                WaistBackAttachment = "Waist",
                RightCollarAttachment = "Shoulder",
                LeftCollarAttachment = "Shoulder",
            }

            local rigidByType = {}
            if info.fullDescription and info.fullDescription.Accessories then
                for _, acc in ipairs(info.fullDescription.Accessories) do
                    if not acc.IsLayered then
                        local t = acc.AccessoryType
                        if not rigidByType[t] then rigidByType[t] = {} end
                        table.insert(rigidByType[t], acc.AssetId)
                    end
                end
            end

            local typeCounters = {}
            local transforms = {}

            for _, child in ipairs(character:GetChildren()) do
                if child:IsA("Accessory") then
                    local handle = child:FindFirstChild("Handle")
                    if handle then
                        for _, att in ipairs(handle:GetChildren()) do
                            if att:IsA("Attachment") and not att.Name:match("^Rig") then
                                local accType = ATT_TO_TYPE[att.Name]
                                if accType then
                                    typeCounters[accType] = (typeCounters[accType] or 0) + 1
                                    local idx = typeCounters[accType]
                                    local assetId = rigidByType[accType] and rigidByType[accType][idx] or 0

                                    if assetId ~= 0 then
                                        local cf = att.CFrame
                                        local pos = cf.Position
                                        local rx, ry, rz = cf:ToOrientation()

                                        local scale = 1
                                        pcall(function()
                                            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
                                            if mesh then
                                                scale = mesh.Scale.Y
                                            end
                                        end)

                                        table.insert(transforms, {
                                            AssetId = assetId,
                                            Name = child.Name,
                                            AttName = att.Name,
                                            Pos = {X = pos.X, Y = pos.Y, Z = pos.Z},
                                            Rot = {RX = rx, RY = ry, RZ = rz},
                                            Scale = scale,
                                        })
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end

            if #transforms > 0 then
                info.fullDescription.AccessoryTransforms = transforms
                log("  AccessoryTransforms:", #transforms, "rigidos capturados")
            end
        end)
    else
        log("  HumanoidDescription: FALHOU")
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    info.savedPosition = hrp and hrp.CFrame or CFrame.new()

    info.loaded = true
    return info.humanoidDescription ~= nil
end

local function generateRigJSON(info)
    return {
        name = info.name,
        type = info.type,
        userId = info.userId,
        description = info.fullDescription
    }
end

--==================================================
-- GERAR RIG PARA PREVIEW
--==================================================

local function generatePreviewRig(info)
    log("generatePreviewRig:", info.name)

    if not info.humanoidDescription then
        log("  ERRO: sem humanoidDescription")
        return nil
    end

    local rigType = info.rigType or Enum.HumanoidRigType.R15

    log("  Gerando rig tipo:", tostring(rigType))

    local success, model = pcall(function()
        return Players:CreateHumanoidModelFromDescription(info.humanoidDescription, rigType)
    end)

    if success and model then
        log("  Rig gerado com sucesso!")

        model:PivotTo(CFrame.new(0, -500, 0))
        model.Parent = workspace

        for _, obj in pairs(model:GetDescendants()) do
            if obj:IsA("BaseScript") then
                obj:Destroy()
            end
        end

        task.wait()

        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
            end
        end

        model.Parent = nil

        return model
    else
        log("  ERRO ao gerar rig:", tostring(model))
        return nil
    end
end


--[[ ═══════ MODULE: 14_drag.luau ═══════ ]]

--==================================================
-- DRAG
--==================================================

local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MiniBar, MiniBar)
makeDraggable(MainFrame, TopBar)
makeDraggable(PreviewFrame, PreviewTopBar)
makeDraggable(ShadowPanel, ShadowPanelTopBar)
makeDraggable(TrollPanel, TrollPanelTopBar)
makeDraggable(RemoteSpyPanel, RemoteSpyTopBar)
makeDraggable(ChatSpyPanel, ChatSpyTopBar)
makeDraggable(DecompilePanel, DecompileTopBar)
makeDraggable(DeathBallPanel, DeathBallTopBar)
--makeDraggable(ParkVoicePanel, ParkVoiceTopBar) -- PARKVOICE DESABILITADO
makeDraggable(BackpackPanel, BackpackTopBar)
makeDraggable(PianoAutoPanel, PianoAutoTopBar)
makeDraggable(SoundPlayerPanel, SoundPlayerTopBar)


--[[ ═══════ MODULE: 15_animations.luau ═══════ ]]

--==================================================
-- ANIMACOES & TOGGLE
--==================================================

local scannerOpen = false
local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfoIn = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local miniBarTarget = UDim2.new(1, -220, 1, -70)
local lastMiniBarPos = miniBarTarget

-- Anima entrada da MiniBar (slide da direita)
task.delay(0.3, function()
    TweenService:Create(MiniBar, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = miniBarTarget
    }):Play()
end)

-- Pulso sutil no morcego da MiniBar
task.spawn(function()
    while MiniBar and MiniBar.Parent do
        local t1 = TweenService:Create(MiniBat, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextTransparency = 0.5,
            Rotation = -10,
        })
        t1:Play()
        t1.Completed:Wait()
        local t2 = TweenService:Create(MiniBat, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextTransparency = 0,
            Rotation = 10,
        })
        t2:Play()
        t2.Completed:Wait()
    end
end)

-- Pulso sutil na borda do avatar
task.spawn(function()
    while MiniBar and MiniBar.Parent do
        local t1 = TweenService:Create(avatarStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Color = Colors.glowRed,
            Thickness = 2,
        })
        t1:Play()
        t1.Completed:Wait()
        local t2 = TweenService:Create(avatarStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Color = Colors.blood,
            Thickness = 1.5,
        })
        t2:Play()
        t2.Completed:Wait()
    end
end)

-- Pulso sutil no stroke principal da MiniBar
task.spawn(function()
    while MiniBar and MiniBar.Parent do
        local t1 = TweenService:Create(miniStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Thickness = 2,
            Transparency = 0,
        })
        t1:Play()
        t1.Completed:Wait()
        local t2 = TweenService:Create(miniStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Thickness = 1.2,
            Transparency = 0.2,
        })
        t2:Play()
        t2.Completed:Wait()
    end
end)

local function openScanner()
    if scannerOpen then return end
    scannerOpen = true

    -- Release mouse if freecam is active
    if movementState.freecam then
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
    end

    lastMiniBarPos = MiniBar.Position
    MiniBar.Visible = false

    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 380, 0, 500)
    MainFrame.BackgroundTransparency = 0.3
    local openTween = TweenService:Create(MainFrame, tweenInfo, {
        Size = UDim2.new(0, 420, 0, 560),
        BackgroundTransparency = 0,
    })
    openTween:Play()

    -- Set default tab
    switchTab(activeTab)

    MiniHint.Text = "Ctrl+G to close"
end

local function closeScanner()
    if not scannerOpen then return end
    scannerOpen = false

    PreviewFrame.Visible = false

    -- Re-lock mouse if freecam is still active
    if movementState.freecam then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
        UIS.MouseIconEnabled = false
    end

    local closeTween = TweenService:Create(MainFrame, tweenInfoIn, {
        Size = UDim2.new(0, 380, 0, 500),
        BackgroundTransparency = 0.5,
    })
    closeTween:Play()
    closeTween.Completed:Connect(function()
        if not scannerOpen then
            MainFrame.Visible = false
            MainFrame.Size = UDim2.new(0, 420, 0, 560)
            MainFrame.BackgroundTransparency = 0
        end
    end)

    MiniBar.Position = lastMiniBarPos
    MiniBar.Visible = true

    MiniHint.Text = "Ctrl+G to open"
end

local function toggleScanner()
    if scannerOpen then
        closeScanner()
    else
        openScanner()
    end
end

-- MiniBar hover effect (premium)
MiniBar.MouseEnter:Connect(function()
    TweenService:Create(miniStroke, TweenInfo.new(0.2), {
        Color = Colors.glowRed,
        Thickness = 2.5,
        Transparency = 0,
    }):Play()
    TweenService:Create(MiniBar, TweenInfo.new(0.2), {
        BackgroundColor3 = Colors.surfaceLight,
    }):Play()
    TweenService:Create(miniSep, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.2,
        BackgroundColor3 = Colors.glowRed,
    }):Play()
end)
MiniBar.MouseLeave:Connect(function()
    TweenService:Create(miniStroke, TweenInfo.new(0.3), {
        Color = Colors.blood,
        Thickness = 1.5,
        Transparency = 0,
    }):Play()
    TweenService:Create(MiniBar, TweenInfo.new(0.3), {
        BackgroundColor3 = Colors.bg,
    }):Play()
    TweenService:Create(miniSep, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Colors.blood,
    }):Play()
end)

-- Click na MiniBar abre o scanner
MiniBar.MouseButton1Click:Connect(toggleScanner)


--[[ ═══════ MODULE: 16_preview.luau ═══════ ]]

--==================================================
-- PREVIEW — BOLA DE CRISTAL (Live CFrame Sync)
--==================================================

local function clearPreview()
    if previewConnection then
        previewConnection:Disconnect()
        previewConnection = nil
    end
    for _, child in pairs(Viewport:GetChildren()) do
        if not child:IsA("UICorner") and not child:IsA("UIStroke")
            and child ~= ViewportStatus and child ~= LiveBadge and child ~= DistLabel then
            child:Destroy()
        end
    end
    ViewportStatus.Text = ""
    LiveBadge.Visible = false
    DistLabel.Visible = false
    PreviewHPFill.Size = UDim2.new(1, 0, 1, 0)
    PreviewHPFill.BackgroundColor3 = Colors.green
    PreviewHPLabel.Text = ""
    currentPreviewData = nil
end

local function displayPreviewInfo(info)
    local desc = info.fullDescription
    if not desc then
        InfoLabel.Text = "No data available"
        return
    end

    local txt = ""
    txt = txt .. "RigType: " .. tostring(desc.RigType or "?") .. "\n\n"

    txt = txt .. "-- CLOTHES --\n"
    txt = txt .. "Shirt: " .. tostring(desc.Shirt or 0) .. "\n"
    txt = txt .. "Pants: " .. tostring(desc.Pants or 0) .. "\n"
    txt = txt .. "Face: " .. tostring(desc.Face or 0) .. "\n\n"

    local accCount = desc.Accessories and #desc.Accessories or 0
    txt = txt .. "-- ACCESSORIES (" .. accCount .. ") --\n"
    if desc.Accessories then
        for i, acc in ipairs(desc.Accessories) do
            txt = txt .. i .. ". " .. acc.AccessoryType
            if acc.IsLayered then txt = txt .. " [L]" end
            txt = txt .. " - " .. acc.AssetId .. "\n"
        end
    end

    txt = txt .. "\n-- SCALES --\n"
    txt = txt .. "Height: " .. string.format("%.2f", desc.HeightScale or 1) .. "\n"
    txt = txt .. "Width: " .. string.format("%.2f", desc.WidthScale or 1) .. "\n"
    txt = txt .. "BodyType: " .. string.format("%.2f", desc.BodyTypeScale or 0) .. "\n"

    InfoLabel.Text = txt
end

local function showPreview(info)
    log("showPreview START:", info.name)
    clearPreview()
    currentPreviewData = info
    PreviewTitle.Text = "🔮 " .. info.name
    PreviewFrame.Visible = true
    log("  PreviewFrame.Visible = true")
    ViewportStatus.Text = "Connecting..."

    -- Info bar
    PreviewNameLabel.Text = info.name
    PreviewTypeLabel.Text = info.type
    PreviewTypeBadge.BackgroundColor3 = info.type == "PLAYER" and Colors.blood or Colors.green

    -- Get real character
    local realChar = info.character
    if info.player and info.player.Character then
        realChar = info.player.Character
    end

    if not realChar or not realChar.Parent then
        log("  Character not found")
        ViewportStatus.Text = "Character not found"
        InfoLabel.Text = ""
        return
    end

    log("  Cloning character...")
    -- Clone character for viewport
    local cloneOk, cloneModel = pcall(function()
        return realChar:Clone()
    end)

    if not cloneOk or not cloneModel then
        log("  Clone FAILED:", tostring(cloneModel))
        ViewportStatus.Text = "Failed to clone"
        InfoLabel.Text = ""
        return
    end
    log("  Clone OK, setting up viewport")

    -- Build part mapping (Clone preserves descendant order)
    local partMap = {}
    local realDescs = realChar:GetDescendants()
    local cloneDescs = cloneModel:GetDescendants()
    for i = 1, math.min(#realDescs, #cloneDescs) do
        local realPart = realDescs[i]
        local clonePart = cloneDescs[i]
        if realPart:IsA("BasePart") and clonePart:IsA("BasePart") then
            partMap[realPart] = clonePart
        end
    end

    -- Camera
    local camera = Instance.new("Camera")
    camera.FieldOfView = 50
    camera.Parent = Viewport
    Viewport.CurrentCamera = camera

    -- WorldModel container
    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = Viewport

    -- Floor plane for visual grounding
    local floor = Instance.new("Part")
    floor.Size = Vector3.new(40, 0.1, 40)
    floor.Position = Vector3.new(0, -3.5, 0)
    floor.Color = Color3.fromRGB(12, 10, 18)
    floor.Material = Enum.Material.SmoothPlastic
    floor.Anchored = true
    floor.CanCollide = false
    floor.Parent = worldModel

    cloneModel.Parent = worldModel

    ViewportStatus.Text = ""
    LiveBadge.Visible = true
    DistLabel.Visible = true

    -- Live sync loop
    local angle = 0
    local livePulse = 0
    previewConnection = RunService.RenderStepped:Connect(function(dt)
        -- Check if real character still exists
        if not realChar or not realChar.Parent then
            ViewportStatus.Text = "Left the game"
            LiveBadge.Text = "● OFF"
            LiveBadge.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            return
        end

        local realHRP = realChar:FindFirstChild("HumanoidRootPart")
        if not realHRP then return end

        -- Sync all part CFrames (centered at origin)
        local rootCF = realHRP.CFrame
        for realPart, clonePart in pairs(partMap) do
            if realPart.Parent and clonePart.Parent then
                pcall(function()
                    clonePart.CFrame = rootCF:Inverse() * realPart.CFrame
                end)
            end
        end

        -- Camera orbit
        angle = angle + dt * 0.4
        local camDist = 10
        local camHeight = 2.5
        camera.CFrame = CFrame.new(
            Vector3.new(math.sin(angle) * camDist, camHeight, math.cos(angle) * camDist),
            Vector3.new(0, 0.5, 0)
        )

        -- Update distance from local player
        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local dist = math.floor((myHRP.Position - realHRP.Position).Magnitude)
            DistLabel.Text = dist .. "m"
        end

        -- Update HP bar
        local hum = realChar:FindFirstChildOfClass("Humanoid")
        if hum then
            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            PreviewHPFill.Size = UDim2.new(pct, 0, 1, 0)
            if pct > 0.5 then
                PreviewHPFill.BackgroundColor3 = Colors.green
            elseif pct > 0.25 then
                PreviewHPFill.BackgroundColor3 = Colors.warning
            else
                PreviewHPFill.BackgroundColor3 = Colors.glowRed
            end
            PreviewHPLabel.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
        end

        -- Pulse LIVE badge
        livePulse = livePulse + dt * 2
        local alpha = (math.sin(livePulse) + 1) / 2
        LiveBadge.BackgroundColor3 = Color3.fromRGB(
            math.floor(140 + alpha * 60),
            math.floor(10 + alpha * 10),
            math.floor(10 + alpha * 10)
        )
    end)

    -- Load rig data and display info
    if not info.loaded then
        InfoLabel.Text = "Loading data..."
        task.spawn(function()
            loadRigData(info)
            if info.cardFrame then
                info.cardFrame.BackgroundColor3 = Colors.cardLoaded
            end
            if info.statusLabel and info.fullDescription then
                local accCount = info.fullDescription.Accessories and #info.fullDescription.Accessories or 0
                info.statusLabel.Text = (info.fullDescription.RigType or "?") .. " | " .. accCount .. " acc"
                info.statusLabel.TextColor3 = Colors.greenLight
            end
            displayPreviewInfo(info)
        end)
    else
        displayPreviewInfo(info)
    end
end


--[[ ═══════ MODULE: 17_actions.luau ═══════ ]]

--==================================================
-- COPY JSON
--==================================================

copyToClipboard = function()
    if not currentPreviewData then return end

    if not currentPreviewData.loaded then
        CopyBtn.Text = "Carregando..."
        loadRigData(currentPreviewData)
    end

    if not currentPreviewData.fullDescription then
        CopyBtn.Text = "Sem dados"
        task.delay(1.5, function() CopyBtn.Text = "🩸 COPY JSON" end)
        return
    end

    local rigData = generateRigJSON(currentPreviewData)
    local ok, jsonStr = pcall(function()
        return HttpService:JSONEncode(rigData)
    end)

    if ok then
        if setclipboard then
            setclipboard(jsonStr)
            CopyBtn.Text = "COPIADO!"
        elseif toclipboard then
            toclipboard(jsonStr)
            CopyBtn.Text = "COPIADO!"
        else
            print(jsonStr)
            CopyBtn.Text = "VER F9"
        end
        notify("JSON copiado: " .. currentPreviewData.name, "success")
    else
        CopyBtn.Text = "ERRO"
        notify("Erro ao copiar JSON", "error")
    end

    task.delay(1.5, function() CopyBtn.Text = "🩸 COPY JSON" end)
end

--==================================================
-- EXPORT ALL
--==================================================

exportAllJSON = function()
    if #allScannedRigs == 0 then
        ExportBtn.Text = "SCAN FIRST"
        task.delay(1.5, function() ExportBtn.Text = "🦇 EXPORT ALL" end)
        return
    end

    if isExporting then return end
    isExporting = true

    local total = #allScannedRigs
    local loaded = 0

    for i, info in ipairs(allScannedRigs) do
        ExportBtn.Text = "🦇 " .. i .. "/" .. total

        if not info.loaded then
            loadRigData(info)
            if info.cardFrame then
                info.cardFrame.BackgroundColor3 = Colors.cardLoaded
            end
            if info.statusLabel and info.fullDescription then
                local accCount = info.fullDescription.Accessories and #info.fullDescription.Accessories or 0
                info.statusLabel.Text = (info.fullDescription.RigType or "?") .. " | " .. accCount .. " acc"
                info.statusLabel.TextColor3 = Colors.greenLight
            end
        end

        if info.fullDescription then
            loaded = loaded + 1
        end

        task.wait(LOAD_DELAY)
    end

    local allData = {
        exportVersion = "Vampire-v13",
        exportDate = os.date("%Y-%m-%d %H:%M:%S"),
        createdBy = "VampireSonata",
        totalRigs = total,
        loadedRigs = loaded,
        rigs = {}
    }

    for _, info in ipairs(allScannedRigs) do
        if info.fullDescription then
            table.insert(allData.rigs, generateRigJSON(info))
        end
    end

    local ok, jsonStr = pcall(function()
        return HttpService:JSONEncode(allData)
    end)

    isExporting = false

    if ok then
        if setclipboard then
            setclipboard(jsonStr)
            ExportBtn.Text = "🦇 " .. loaded .. " RIGS!"
        elseif toclipboard then
            toclipboard(jsonStr)
            ExportBtn.Text = "🦇 " .. loaded .. " RIGS!"
        else
            print(jsonStr)
            ExportBtn.Text = "VER F9"
        end
        notify("Exportados " .. loaded .. " rigs!", "success")
    else
        ExportBtn.Text = "ERRO"
        notify("Erro ao exportar", "error")
    end

    task.delay(2, function() ExportBtn.Text = "🦇 EXPORT ALL" end)
end

--==================================================
-- SCANNER
--==================================================

clearResults = function()
    for _, child in pairs(ResultScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    allScannedRigs = {}
    scannedPlayerSet = {}
    scannedNPCSet = {}
end

createResultCard = function(info)
    local accentColor = info.type == "PLAYER" and Colors.blood or Colors.green

    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -10, 0, 70)
    Card.BackgroundColor3 = Colors.card
    Card.BorderSizePixel = 0
    Card.Parent = ResultScroll
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)
    addGradient(Card, Colors.surfaceLight, Colors.card, 0)

    local cardStroke = Instance.new("UIStroke", Card)
    cardStroke.Color = accentColor
    cardStroke.Thickness = 1
    cardStroke.Transparency = 1

    -- Left accent bar
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 1, -8)
    accentBar.Position = UDim2.new(0, 0, 0, 4)
    accentBar.BackgroundColor3 = accentColor
    accentBar.BorderSizePixel = 0
    accentBar.Parent = Card
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)

    -- Card hover
    Card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            TweenService:Create(cardStroke, TweenInfo.new(0.15), { Transparency = 0.3 }):Play()
            TweenService:Create(Card, TweenInfo.new(0.15), { BackgroundColor3 = Colors.surfaceLight }):Play()
        end
    end)
    Card.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            TweenService:Create(cardStroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
            TweenService:Create(Card, TweenInfo.new(0.2), { BackgroundColor3 = Colors.card }):Play()
        end
    end)

    info.cardFrame = Card

    -- Thumbnail (players only)
    local contentOffsetX = 12
    if info.type == "PLAYER" and info.userId then
        contentOffsetX = 46

        local thumbFrame = Instance.new("Frame")
        thumbFrame.Size = UDim2.new(0, 30, 0, 30)
        thumbFrame.Position = UDim2.new(0, 8, 0, 6)
        thumbFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        thumbFrame.Parent = Card
        Instance.new("UICorner", thumbFrame).CornerRadius = UDim.new(1, 0)
        local tStroke = Instance.new("UIStroke", thumbFrame)
        tStroke.Color = Colors.blood
        tStroke.Thickness = 1

        local thumbImg = Instance.new("ImageLabel")
        thumbImg.Size = UDim2.new(1, 0, 1, 0)
        thumbImg.BackgroundTransparency = 1
        thumbImg.Parent = thumbFrame
        Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1, 0)

        task.spawn(function()
            local ok, thumb = pcall(function()
                return Players:GetUserThumbnailAsync(info.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and thumb then thumbImg.Image = thumb end
        end)
    end

    local TypeBadge = Instance.new("Frame")
    TypeBadge.Size = UDim2.new(0, 50, 0, 16)
    TypeBadge.Position = UDim2.new(1, -58, 0, 5)
    TypeBadge.BackgroundColor3 = accentColor
    TypeBadge.Parent = Card
    Instance.new("UICorner", TypeBadge).CornerRadius = UDim.new(0, 4)

    local TypeLabel = Instance.new("TextLabel")
    TypeLabel.Size = UDim2.new(1, 0, 1, 0)
    TypeLabel.BackgroundTransparency = 1
    TypeLabel.Text = info.type
    TypeLabel.TextColor3 = Colors.text
    TypeLabel.TextSize = 9
    TypeLabel.Font = Enum.Font.GothamBold
    TypeLabel.Parent = TypeBadge

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -65, 0, 18)
    NameLabel.Position = UDim2.new(0, contentOffsetX, 0, 5)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = info.displayName and (info.displayName .. " @" .. info.name) or info.name
    NameLabel.TextColor3 = Colors.bloodLight
    NameLabel.TextSize = 12
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = Card

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 0, 14)
    StatusLabel.Position = UDim2.new(0, contentOffsetX, 0, 22)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Click VIEW"
    StatusLabel.TextColor3 = Colors.textDim
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = Card

    info.statusLabel = StatusLabel

    -- Botoes
    local ViewBtn = Instance.new("TextButton")
    ViewBtn.Size = UDim2.new(0, 48, 0, 20)
    ViewBtn.Position = UDim2.new(0, 12, 1, -26)
    ViewBtn.BackgroundColor3 = Colors.blood
    ViewBtn.Text = "VIEW"
    ViewBtn.TextColor3 = Colors.text
    ViewBtn.TextSize = 10
    ViewBtn.Font = Enum.Font.GothamBold
    ViewBtn.AutoButtonColor = false
    ViewBtn.Parent = Card
    Instance.new("UICorner", ViewBtn).CornerRadius = UDim.new(0, 4)
    makeHoverable(ViewBtn, Colors.blood, Colors.glowRed)

    ViewBtn.MouseButton1Click:Connect(function()
        log("VIEW clicked:", info.name)
        local ok, err = pcall(showPreview, info)
        if not ok then
            log("showPreview ERROR:", tostring(err))
            notify("Preview error: " .. tostring(err):sub(1, 60), "error")
        end
    end)

    local TPBtn = Instance.new("TextButton")
    TPBtn.Size = UDim2.new(0, 32, 0, 20)
    TPBtn.Position = UDim2.new(0, 64, 1, -26)
    TPBtn.BackgroundColor3 = Colors.green
    TPBtn.Text = "TP"
    TPBtn.TextColor3 = Colors.text
    TPBtn.TextSize = 10
    TPBtn.Font = Enum.Font.GothamBold
    TPBtn.AutoButtonColor = false
    TPBtn.Parent = Card
    Instance.new("UICorner", TPBtn).CornerRadius = UDim.new(0, 4)
    makeHoverable(TPBtn, Colors.green, Colors.greenLight)

    TPBtn.MouseButton1Click:Connect(function()
        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local targetChar = info.character
        if info.player and info.player.Character then
            targetChar = info.player.Character
        end
        if myHRP and targetChar then
            local hrp = targetChar:FindFirstChild("HumanoidRootPart")
            if hrp then
                myHRP.CFrame = hrp.CFrame
                notify("TP to " .. info.name, "success")
            end
        end
    end)

    local JSONBtn = Instance.new("TextButton")
    JSONBtn.Size = UDim2.new(0, 38, 0, 20)
    JSONBtn.Position = UDim2.new(0, 100, 1, -26)
    JSONBtn.BackgroundColor3 = Colors.bloodDark
    JSONBtn.Text = "JSON"
    JSONBtn.TextColor3 = Colors.text
    JSONBtn.TextSize = 10
    JSONBtn.Font = Enum.Font.GothamBold
    JSONBtn.AutoButtonColor = false
    JSONBtn.Parent = Card
    Instance.new("UICorner", JSONBtn).CornerRadius = UDim.new(0, 4)
    makeHoverable(JSONBtn, Colors.bloodDark, Colors.blood)

    local SpecBtn = Instance.new("TextButton")
    SpecBtn.Size = UDim2.new(0, 38, 0, 20)
    SpecBtn.Position = UDim2.new(0, 142, 1, -26)
    SpecBtn.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
    SpecBtn.Text = "SPEC"
    SpecBtn.TextColor3 = Colors.text
    SpecBtn.TextSize = 10
    SpecBtn.Font = Enum.Font.GothamBold
    SpecBtn.AutoButtonColor = false
    SpecBtn.Parent = Card
    Instance.new("UICorner", SpecBtn).CornerRadius = UDim.new(0, 4)
    makeHoverable(SpecBtn, Color3.fromRGB(80, 25, 25), Color3.fromRGB(120, 35, 35))

    SpecBtn.MouseButton1Click:Connect(function()
        startSpectate(info)
    end)

    -- Shadow button (players only)
    if info.type == "PLAYER" and info.player then
        local ShadowResultBtn = Instance.new("TextButton")
        ShadowResultBtn.Size = UDim2.new(0, 52, 0, 20)
        ShadowResultBtn.Position = UDim2.new(0, 184, 1, -26)
        ShadowResultBtn.BackgroundColor3 = Colors.glowPurple
        ShadowResultBtn.Text = "SHADOW"
        ShadowResultBtn.TextColor3 = Colors.text
        ShadowResultBtn.TextSize = 9
        ShadowResultBtn.Font = Enum.Font.GothamBold
        ShadowResultBtn.AutoButtonColor = false
        ShadowResultBtn.Parent = Card
        Instance.new("UICorner", ShadowResultBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(ShadowResultBtn, Colors.glowPurple, Colors.purpleLight)

        ShadowResultBtn.MouseButton1Click:Connect(function()
            openShadowPanel(info.player)
        end)

        local BagResultBtn = Instance.new("TextButton")
        BagResultBtn.Size = UDim2.new(0, 32, 0, 20)
        BagResultBtn.Position = UDim2.new(0, 148, 1, -26)
        BagResultBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 40)
        BagResultBtn.Text = "BAG"
        BagResultBtn.TextColor3 = Colors.text
        BagResultBtn.TextSize = 9
        BagResultBtn.Font = Enum.Font.GothamBold
        BagResultBtn.AutoButtonColor = false
        BagResultBtn.Parent = Card
        Instance.new("UICorner", BagResultBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(BagResultBtn, Color3.fromRGB(200, 140, 40), Color3.fromRGB(240, 180, 60))

        BagResultBtn.MouseButton1Click:Connect(function()
            openBackpackPanel(info.player)
        end)
    end

    JSONBtn.MouseButton1Click:Connect(function()
        if not info.loaded then
            JSONBtn.Text = "..."
            loadRigData(info)
            Card.BackgroundColor3 = Colors.cardLoaded
            if info.fullDescription then
                StatusLabel.Text = (info.fullDescription.RigType or "?") .. " | " .. #(info.fullDescription.Accessories or {}) .. " acc"
                StatusLabel.TextColor3 = Colors.greenLight
            end
        end

        if info.fullDescription then
            local ok, json = pcall(function()
                return HttpService:JSONEncode(generateRigJSON(info))
            end)
            if ok then
                if setclipboard then setclipboard(json)
                elseif toclipboard then toclipboard(json)
                else print(json) end
                JSONBtn.Text = "OK!"
                notify("JSON: " .. info.name, "success")
            else
                JSONBtn.Text = "ERR"
            end
        else
            JSONBtn.Text = "ERR"
        end
        task.delay(1, function() JSONBtn.Text = "JSON" end)
    end)
end

runScan = function()
    log("=== SCAN INICIADO ===")
    clearResults()
    clearPreview()
    PreviewFrame.Visible = false

    local countP, countN = 0, 0
    local players = Players:GetPlayers()

    log("Players online:", #players)

    for _, player in pairs(players) do
        local char = player.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            log("  + PLAYER:", player.Name)
            local info = {
                name = player.Name,
                displayName = player.DisplayName,
                type = "PLAYER",
                character = char,
                player = player,
                userId = player.UserId,
                loaded = false,
            }
            table.insert(allScannedRigs, info)
            scannedPlayerSet[player] = info
            createResultCard(info)
            countP = countP + 1
        end
    end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local isPlayer = false
            for _, p in pairs(players) do
                if p.Character == obj then isPlayer = true break end
            end
            if not isPlayer then
                log("  + NPC:", obj.Name)
                local info = {
                    name = obj.Name,
                    type = "NPC",
                    character = obj,
                    loaded = false,
                }
                table.insert(allScannedRigs, info)
                scannedNPCSet[obj] = info
                createResultCard(info)
                countN = countN + 1
            end
        end
    end

    ResultScroll.CanvasSize = UDim2.new(0, 0, 0, ResultLayout.AbsoluteContentSize.Y + 10)
    CountLabel.Text = countP .. "P | " .. countN .. "N"
    Title.Text = "Vampire (" .. countP .. "P | " .. countN .. "N)"
    notify("Scan: " .. countP .. " players, " .. countN .. " NPCs", "info")
    log("=== SCAN COMPLETO ===")
end

--==================================================
-- SEARCH / FILTER
--==================================================

filterResults = function(searchText)
    local text = searchText:lower()
    for _, info in ipairs(allScannedRigs) do
        if info.cardFrame then
            if text == "" then
                info.cardFrame.Visible = true
            else
                local matchName = info.name:lower():find(text, 1, true) ~= nil
                local matchDisplay = info.displayName and info.displayName:lower():find(text, 1, true) ~= nil
                info.cardFrame.Visible = matchName or matchDisplay
            end
        end
    end
    task.defer(function()
        ResultScroll.CanvasSize = UDim2.new(0, 0, 0, ResultLayout.AbsoluteContentSize.Y + 10)
    end)
end

--==================================================
-- AUTO-SCAN
--==================================================

startAutoScan = function()
    if autoScanConnection then return end

    autoScanConnection = task.spawn(function()
        -- Do initial scan
        if #allScannedRigs == 0 then
            runScan()
        end

        while autoScanConfig.enabled do
            task.wait(autoScanConfig.interval)
            if not autoScanConfig.enabled then break end

            local players = Players:GetPlayers()

            -- Check for new players
            for _, player in pairs(players) do
                if not scannedPlayerSet[player] then
                    local char = player.Character
                    if char and char:FindFirstChildOfClass("Humanoid") then
                        local info = {
                            name = player.Name,
                            displayName = player.DisplayName,
                            type = "PLAYER",
                            character = char,
                            player = player,
                            userId = player.UserId,
                            loaded = false,
                        }
                        table.insert(allScannedRigs, info)
                        scannedPlayerSet[player] = info
                        createResultCard(info)
                        notify(player.DisplayName .. " joined", "info")
                    end
                end
            end

            -- Check for removed players (gray out card)
            for player, info in pairs(scannedPlayerSet) do
                if not player.Parent then
                    if info.cardFrame and info.cardFrame.Parent then
                        info.cardFrame.BackgroundTransparency = 0.6
                        if info.statusLabel then
                            info.statusLabel.Text = "LEFT"
                            info.statusLabel.TextColor3 = Colors.textDim
                        end
                    end
                    scannedPlayerSet[player] = nil
                end
            end

            -- Update counts
            local pCount, nCount = 0, 0
            for _, info in ipairs(allScannedRigs) do
                if info.type == "PLAYER" then pCount = pCount + 1
                else nCount = nCount + 1 end
            end
            CountLabel.Text = pCount .. "P | " .. nCount .. "N"
            ResultScroll.CanvasSize = UDim2.new(0, 0, 0, ResultLayout.AbsoluteContentSize.Y + 10)
        end
    end)
end

stopAutoScan = function()
    autoScanConfig.enabled = false
    if autoScanConnection then
        task.cancel(autoScanConnection)
        autoScanConnection = nil
    end
end

--==================================================
-- PLAYER LIST (for Player tab)
--==================================================

refreshPlayerList = function(filterText)
    -- Clear existing
    for _, child in pairs(PlayerScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    filterText = filterText and filterText:lower() or ""

    for _, player in pairs(Players:GetPlayers()) do
        -- Filter by name/displayname
        local match = true
        if filterText ~= "" then
            local dn = player.DisplayName:lower()
            local un = player.Name:lower()
            if not dn:find(filterText, 1, true) and not un:find(filterText, 1, true) then
                match = false
            end
        end

        if match then
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 54)
        card.BackgroundColor3 = Colors.card
        card.BorderSizePixel = 0
        card.Parent = PlayerScroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
        addGradient(card, Colors.surfaceLight, Colors.card, 0)

        -- Avatar thumbnail
        local thumbFrame = Instance.new("Frame")
        thumbFrame.Size = UDim2.new(0, 36, 0, 36)
        thumbFrame.Position = UDim2.new(0, 6, 0, 7)
        thumbFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        thumbFrame.Parent = card
        Instance.new("UICorner", thumbFrame).CornerRadius = UDim.new(1, 0)
        local thumbStroke = Instance.new("UIStroke", thumbFrame)
        thumbStroke.Color = Colors.blood
        thumbStroke.Thickness = 1

        local thumbImg = Instance.new("ImageLabel")
        thumbImg.Size = UDim2.new(1, 0, 1, 0)
        thumbImg.BackgroundTransparency = 1
        thumbImg.Parent = thumbFrame
        Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1, 0)

        task.spawn(function()
            local ok, thumb = pcall(function()
                return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and thumb then thumbImg.Image = thumb end
        end)

        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -120, 0, 16)
        nameLabel.Position = UDim2.new(0, 48, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
        nameLabel.TextColor3 = Colors.bloodLight
        nameLabel.TextSize = 11
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = card

        -- Account age
        local ageLabel = Instance.new("TextLabel")
        ageLabel.Size = UDim2.new(1, -120, 0, 12)
        ageLabel.Position = UDim2.new(0, 48, 0, 20)
        ageLabel.BackgroundTransparency = 1
        ageLabel.Text = "Age: " .. player.AccountAge .. "d | ID: " .. player.UserId
        ageLabel.TextColor3 = Colors.textDim
        ageLabel.TextSize = 9
        ageLabel.Font = Enum.Font.Gotham
        ageLabel.TextXAlignment = Enum.TextXAlignment.Left
        ageLabel.Parent = card

        -- Health bar
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local hpBg = Instance.new("Frame")
            hpBg.Size = UDim2.new(0, 80, 0, 6)
            hpBg.Position = UDim2.new(0, 48, 0, 35)
            hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            hpBg.BorderSizePixel = 0
            hpBg.Parent = card
            Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)

            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local hpFill = Instance.new("Frame")
            hpFill.Size = UDim2.new(pct, 0, 1, 0)
            hpFill.BackgroundColor3 = pct > 0.5 and Colors.green or (pct > 0.25 and Colors.warning or Colors.glowRed)
            hpFill.BorderSizePixel = 0
            hpFill.Parent = hpBg
            Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 3)
        end

        -- Buttons: SPEC | TP
        local specBtn = Instance.new("TextButton")
        specBtn.Size = UDim2.new(0, 36, 0, 18)
        specBtn.Position = UDim2.new(1, -80, 0, 6)
        specBtn.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
        specBtn.Text = "SPEC"
        specBtn.TextColor3 = Colors.text
        specBtn.TextSize = 9
        specBtn.Font = Enum.Font.GothamBold
        specBtn.AutoButtonColor = false
        specBtn.Parent = card
        Instance.new("UICorner", specBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(specBtn, Color3.fromRGB(80, 25, 25), Color3.fromRGB(120, 35, 35))

        specBtn.MouseButton1Click:Connect(function()
            local c = player.Character
            if c then
                startSpectate({
                    name = player.Name,
                    character = c,
                    player = player,
                })
            end
        end)

        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(0, 28, 0, 18)
        tpBtn.Position = UDim2.new(1, -40, 0, 6)
        tpBtn.BackgroundColor3 = Colors.green
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = Colors.text
        tpBtn.TextSize = 9
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.AutoButtonColor = false
        tpBtn.Parent = card
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(tpBtn, Colors.green, Colors.greenLight)

        tpBtn.MouseButton1Click:Connect(function()
            local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local c = player.Character
            if myHRP and c then
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    myHRP.CFrame = hrp.CFrame
                    notify("TP to " .. player.Name, "success")
                end
            end
        end)

        -- Shadow button
        local shadowBtn = Instance.new("TextButton")
        shadowBtn.Size = UDim2.new(0, 52, 0, 18)
        shadowBtn.Position = UDim2.new(1, -80, 0, 30)
        shadowBtn.BackgroundColor3 = Colors.glowPurple
        shadowBtn.Text = "SHADOW"
        shadowBtn.TextColor3 = Colors.text
        shadowBtn.TextSize = 8
        shadowBtn.Font = Enum.Font.GothamBold
        shadowBtn.AutoButtonColor = false
        shadowBtn.Parent = card
        Instance.new("UICorner", shadowBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(shadowBtn, Colors.glowPurple, Colors.purpleLight)

        shadowBtn.MouseButton1Click:Connect(function()
            openShadowPanel(player)
        end)

        -- Troll button (opens troll panel)
        local trollBtn = Instance.new("TextButton")
        trollBtn.Size = UDim2.new(0, 40, 0, 18)
        trollBtn.Position = UDim2.new(1, -24, 0, 30)
        trollBtn.BackgroundColor3 = Colors.glowRed
        trollBtn.Text = "TROLL"
        trollBtn.TextColor3 = Colors.text
        trollBtn.TextSize = 8
        trollBtn.Font = Enum.Font.GothamBold
        trollBtn.AutoButtonColor = false
        trollBtn.Parent = card
        Instance.new("UICorner", trollBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(trollBtn, Colors.glowRed, Color3.fromRGB(255, 80, 80))

        trollBtn.MouseButton1Click:Connect(function()
            openTrollPanel(player)
        end)

        -- Backpack button
        local bagBtn = Instance.new("TextButton")
        bagBtn.Size = UDim2.new(0, 30, 0, 18)
        bagBtn.Position = UDim2.new(1, -134, 0, 30)
        bagBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 40)
        bagBtn.Text = "BAG"
        bagBtn.TextColor3 = Colors.text
        bagBtn.TextSize = 8
        bagBtn.Font = Enum.Font.GothamBold
        bagBtn.AutoButtonColor = false
        bagBtn.Parent = card
        Instance.new("UICorner", bagBtn).CornerRadius = UDim.new(0, 4)
        makeHoverable(bagBtn, Color3.fromRGB(200, 140, 40), Color3.fromRGB(240, 180, 60))

        bagBtn.MouseButton1Click:Connect(function()
            openBackpackPanel(player)
        end)
        end -- if match
    end

    PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, PlayerLayout.AbsoluteContentSize.Y + 10)
end

--==================================================
-- SERVER INFO
--==================================================

updateServerInfo = function()
    task.spawn(function()
        local fps = 0
        local frameCount = 0
        local lastTime = tick()

        while ServerInfoLabel and ServerInfoLabel.Parent do
            frameCount = frameCount + 1
            local now = tick()
            if now - lastTime >= 1 then
                fps = frameCount
                frameCount = 0
                lastTime = now

                local placeId = game.PlaceId
                local jobId = game.JobId
                local shortJob = #jobId > 12 and jobId:sub(1, 12) .. "..." or jobId
                local playerCount = #Players:GetPlayers()
                local maxPlayers = Players.MaxPlayers

                ServerInfoLabel.Text = "Place: " .. placeId .. " | Job: " .. shortJob .. "\nPlayers: " .. playerCount .. "/" .. maxPlayers .. " | FPS: " .. fps
            end
            task.wait()
        end
    end)
end


--[[ ═══════ MODULE: 18_spectate.luau ═══════ ]]

--==================================================
-- SPECTATE MODE
--==================================================

startSpectate = function(info)
    local targetChar = info.character
    if info.player and info.player.Character then
        targetChar = info.player.Character
    end

    if not targetChar then
        log("Spectate: character not found")
        notify("Spectate: character not found", "error")
        return
    end

    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        log("Spectate: no Humanoid found")
        notify("Spectate: no Humanoid", "error")
        return
    end

    if spectatingInfo and spectatingInfo == info then
        stopSpectate()
        return
    end

    if spectatingInfo then
        stopSpectate()
    end

    local camera = workspace.CurrentCamera
    savedCameraSubject = camera.CameraSubject

    camera.CameraSubject = humanoid
    spectatingInfo = info

    -- Highlight (respects config)
    if spectateHighlight then
        spectateHighlight:Destroy()
        spectateHighlight = nil
    end
    if spectateConfig.showHighlight then
        spectateHighlight = Instance.new("Highlight")
        spectateHighlight.Name = "VampSpectateHL"
        spectateHighlight.FillColor = Colors.blood
        spectateHighlight.FillTransparency = 0.7
        spectateHighlight.OutlineColor = Colors.bloodLight
        spectateHighlight.OutlineTransparency = 0
        spectateHighlight.Adornee = targetChar
        spectateHighlight.Parent = targetChar
    end

    local specLabel = "🦇 UNSPECTATE (" .. info.name .. ")"
    UnspectateBtn.Visible = true
    UnspectateBtn.Text = specLabel
    PlayerUnspectateBtn.Visible = true
    PlayerUnspectateBtn.Text = specLabel

    notify("Spectating: " .. info.name, "info")
    log("Spectating:", info.name)
end

stopSpectate = function()
    if not spectatingInfo then return end

    local camera = workspace.CurrentCamera
    if savedCameraSubject then
        camera.CameraSubject = savedCameraSubject
        savedCameraSubject = nil
    else
        local localChar = LP.Character
        if localChar then
            local hum = localChar:FindFirstChildOfClass("Humanoid")
            if hum then
                camera.CameraSubject = hum
            end
        end
    end

    if spectateHighlight then
        spectateHighlight:Destroy()
        spectateHighlight = nil
    end

    spectatingInfo = nil
    UnspectateBtn.Visible = false
    PlayerUnspectateBtn.Visible = false

    notify("Spectate stopped", "info")
    log("Spectate stopped")
end


--[[ ═══════ MODULE: 19_esp_system.luau ═══════ ]]

--==================================================
-- ESP SYSTEM (Full) — 7 new features
-- Tracers, Skeleton, HeadDot, ThreatLevel, ToolESP,
-- Footsteps, SoundESP
--==================================================

--==================================================
-- TRACER CONTAINER (screen-space lines)
--==================================================

TracerContainer = Instance.new("Frame")
TracerContainer.Name = "TracerContainer"
TracerContainer.Size = UDim2.new(1, 0, 1, 0)
TracerContainer.BackgroundTransparency = 1
TracerContainer.Parent = ScreenGui

-- Item Icons cache
espBackpackCache = {}
espItemIconsTimer = 0

-- Screen-space line helper: draws a line between two Vector2 points
local function drawTracerLine(from, to, color)
    local dx = to.X - from.X
    local dy = to.Y - from.Y
    local dist = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dy, dx)

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, dist, 0, 1)
    line.Position = UDim2.new(0, from.X, 0, from.Y)
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.Rotation = math.deg(angle)
    line.BackgroundColor3 = color or Color3.fromRGB(0, 180, 255)
    line.BackgroundTransparency = 0.3
    line.BorderSizePixel = 0
    line.Parent = TracerContainer
    return line
end

--==================================================
-- SKELETON BONE DEFINITIONS
--==================================================

local skeletonBones = {
    -- Spine
    { "HumanoidRootPart", "UpperTorso" },
    { "UpperTorso", "Head" },
    { "HumanoidRootPart", "LowerTorso" },
    -- Left arm
    { "UpperTorso", "LeftUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    -- Right arm
    { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "RightLowerArm", "RightHand" },
    -- Left leg
    { "LowerTorso", "LeftUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    -- Right leg
    { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "RightLowerLeg", "RightFoot" },
}

-- R6 fallback bones
local skeletonBonesR6 = {
    { "Torso", "Head" },
    { "Torso", "Left Arm" },
    { "Torso", "Right Arm" },
    { "Torso", "Left Leg" },
    { "Torso", "Right Leg" },
}

--==================================================
-- CORE ESP FUNCTIONS
--==================================================

local function createESPObject(target, espName, espColor, isCamera, isNPC)
    local existing = target:FindFirstChild("VampESP_BG")
    if existing then return end

    local espData = {
        target = target,
        isCamera = isCamera,
        isNPC = isNPC,
    }

    -- Highlight (player/NPC/camera ESP)
    if espState.players or espState.npcs or espState.cameras then
        local hl = Instance.new("Highlight")
        hl.Name = "VampESP_HL"
        hl.Adornee = target
        hl.Parent = target

        if espState.chams then
            hl.FillColor = espColor
            hl.FillTransparency = 0.3
            hl.OutlineColor = espColor
            hl.OutlineTransparency = 0.2
        elseif espState.boxESP then
            hl.FillColor = espColor
            hl.FillTransparency = 1
            hl.OutlineColor = espColor
            hl.OutlineTransparency = 0
        else
            hl.FillColor = espColor
            hl.FillTransparency = 0.85
            hl.OutlineColor = espColor
            hl.OutlineTransparency = 0.2
        end

        espData.highlight = hl
    end

    -- BillboardGui com nome e distancia
    local bg = Instance.new("BillboardGui")
    bg.Name = "VampESP_BG"
    bg.Size = UDim2.new(0, 200, 0, 60)
    bg.StudsOffset = Vector3.new(0, isCamera and 2 or 4, 0)
    bg.AlwaysOnTop = true
    bg.Adornee = target
    bg.Parent = target

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ESPName"
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = espName
    nameLabel.TextColor3 = espColor
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = bg

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "ESPDist"
    distLabel.Size = UDim2.new(1, 0, 0, 14)
    distLabel.Position = UDim2.new(0, 0, 0, 16)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "? studs"
    distLabel.TextColor3 = Colors.textDim
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextSize = 11
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = bg

    espData.billboard = bg
    espData.nameLabel = nameLabel
    espData.distLabel = distLabel

    -- Tool ESP label (below distance)
    if espState.toolESP and not isCamera then
        local toolLabel = Instance.new("TextLabel")
        toolLabel.Name = "ESPTool"
        toolLabel.Size = UDim2.new(1, 0, 0, 12)
        toolLabel.Position = UDim2.new(0, 0, 0, 32)
        toolLabel.BackgroundTransparency = 1
        toolLabel.Text = ""
        toolLabel.TextColor3 = Color3.fromRGB(180, 120, 255)
        toolLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        toolLabel.TextStrokeTransparency = 0.3
        toolLabel.TextSize = 10
        toolLabel.Font = Enum.Font.GothamBold
        toolLabel.Parent = bg
        espData.toolLabel = toolLabel
    end

    -- Health bar
    if espState.healthBars and not isCamera then
        local hpY = espState.toolESP and 46 or 32
        local hpBg = Instance.new("Frame")
        hpBg.Name = "ESPHealth"
        hpBg.Size = UDim2.new(0, 100, 0, 6)
        hpBg.Position = UDim2.new(0.5, -50, 0, hpY)
        hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        hpBg.BorderSizePixel = 0
        hpBg.Parent = bg
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)

        local hpFill = Instance.new("Frame")
        hpFill.Name = "Fill"
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = Colors.green
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBg
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 3)

        espData.healthBg = hpBg
        espData.healthFill = hpFill
    end

    -- Item Icons: BillboardGui separado acima do principal
    if espState.itemIcons and not isCamera then
        local itemBG = Instance.new("BillboardGui")
        itemBG.Name = "VampESP_Items"
        itemBG.Size = UDim2.new(0, 210, 0, 38)
        itemBG.StudsOffset = Vector3.new(0, 6, 0)
        itemBG.AlwaysOnTop = true
        itemBG.Adornee = target
        itemBG.Parent = target

        local itemRow = Instance.new("Frame")
        itemRow.Name = "ESPItemRow"
        itemRow.Size = UDim2.new(1, 0, 1, 0)
        itemRow.BackgroundTransparency = 1
        itemRow.Parent = itemBG

        local itemLayout = Instance.new("UIListLayout")
        itemLayout.FillDirection = Enum.FillDirection.Horizontal
        itemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        itemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        itemLayout.Padding = UDim.new(0, 3)
        itemLayout.Parent = itemRow

        espData.itemBG = itemBG
        espData.itemRow = itemRow
    end

    -- Type label (camera)
    if isCamera then
        local typeLabel = Instance.new("TextLabel")
        typeLabel.Name = "ESPType"
        typeLabel.Size = UDim2.new(1, 0, 0, 12)
        typeLabel.Position = UDim2.new(0, 0, 0, 32)
        typeLabel.BackgroundTransparency = 1
        typeLabel.Text = "📷 CAMERA"
        typeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        typeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        typeLabel.TextStrokeTransparency = 0.3
        typeLabel.TextSize = 10
        typeLabel.Font = Enum.Font.GothamBold
        typeLabel.Parent = bg
    end

    -- Head Dot
    if espState.headDot and not isCamera then
        local head = target:FindFirstChild("Head")
        if head then
            local dotBG = Instance.new("BillboardGui")
            dotBG.Name = "VampESP_HeadDot"
            dotBG.Size = UDim2.new(0, 8, 0, 8)
            dotBG.StudsOffset = Vector3.new(0, 0, 0)
            dotBG.AlwaysOnTop = true
            dotBG.Adornee = head
            dotBG.Parent = head

            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(1, 0, 1, 0)
            dot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            dot.BorderSizePixel = 0
            dot.Parent = dotBG
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

            espData.headDotBG = dotBG
            table.insert(headDotObjects, dotBG)
        end
    end

    -- Skeleton ESP (Beams between body parts)
    if espState.skeleton and not isCamera then
        local bones = skeletonBones
        -- Detect R6 vs R15
        if not target:FindFirstChild("UpperTorso") and target:FindFirstChild("Torso") then
            bones = skeletonBonesR6
        end

        local beamData = {}
        for _, bonePair in ipairs(bones) do
            local partA = target:FindFirstChild(bonePair[1])
            local partB = target:FindFirstChild(bonePair[2])
            if partA and partB then
                local attA = Instance.new("Attachment")
                attA.Name = "VampSkel_A"
                attA.Parent = partA

                local attB = Instance.new("Attachment")
                attB.Name = "VampSkel_B"
                attB.Parent = partB

                local beam = Instance.new("Beam")
                beam.Name = "VampSkel_Beam"
                beam.Attachment0 = attA
                beam.Attachment1 = attB
                beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                beam.FaceCamera = true
                beam.Width0 = 0.15
                beam.Width1 = 0.15
                beam.Transparency = NumberSequence.new(0.15)
                beam.LightEmission = 1
                beam.LightInfluence = 0
                beam.Parent = partA

                table.insert(beamData, { beam = beam, attA = attA, attB = attB })
            end
        end

        espData.skeletonBeams = beamData
        for _, bd in ipairs(beamData) do
            table.insert(skeletonBeams, bd)
        end
    end

    table.insert(espObjects, espData)
end

local function removeESPFromTarget(target)
    local hl = target:FindFirstChild("VampESP_HL")
    if hl then hl:Destroy() end
    local bg = target:FindFirstChild("VampESP_BG")
    if bg then bg:Destroy() end
    local itemBG = target:FindFirstChild("VampESP_Items")
    if itemBG then itemBG:Destroy() end

    -- Clean head dots
    local head = target:FindFirstChild("Head")
    if head then
        local hd = head:FindFirstChild("VampESP_HeadDot")
        if hd then hd:Destroy() end
    end

    -- Clean skeleton beams
    for _, part in ipairs(target:GetDescendants()) do
        if part.Name == "VampSkel_A" or part.Name == "VampSkel_B" then
            part:Destroy()
        elseif part.Name == "VampSkel_Beam" then
            part:Destroy()
        end
    end
end

--==================================================
-- CLEAR ALL ESP
--==================================================

clearESP = function()
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end

    -- Clear tracers
    for _, line in ipairs(tracerLines) do
        if line and line.Parent then line:Destroy() end
    end
    tracerLines = {}

    -- Clear skeleton beams
    for _, bd in ipairs(skeletonBeams) do
        pcall(function() bd.beam:Destroy() end)
        pcall(function() bd.attA:Destroy() end)
        pcall(function() bd.attB:Destroy() end)
    end
    skeletonBeams = {}

    -- Clear head dots
    for _, hd in ipairs(headDotObjects) do
        if hd and hd.Parent then hd:Destroy() end
    end
    headDotObjects = {}

    -- Clear ESP objects
    for _, esp in ipairs(espObjects) do
        if esp.target and esp.target.Parent then
            removeESPFromTarget(esp.target)
        end
    end
    espObjects = {}
end

--==================================================
-- UPDATE ESP (main loop)
--==================================================

updateESP = function()
    clearESP()

    -- Check if any toggle in espToggles-managed features is active
    local anyActive = false
    for _, v in pairs(espState) do
        if v then anyActive = true break end
    end

    -- Ignore footsteps and soundESP for the "any active" check
    -- since they are managed separately
    local coreActive = espState.players or espState.npcs or espState.cameras
        or espState.healthBars or espState.boxESP or espState.chams
        or espState.tracers or espState.skeleton or espState.headDot
        or espState.threatLevel or espState.toolESP or espState.itemIcons

    if not coreActive then
        ESPStatusLabel.Text = "ESP OFF — toggle features above"
        return
    end

    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local playerChars = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = p end
    end

    -- Checa se alguma feature precisa de players (tracers, skeleton, etc.)
    local needsPlayers = espState.players or espState.tracers or espState.skeleton
        or espState.headDot or espState.threatLevel or espState.toolESP
        or espState.healthBars or espState.boxESP or espState.chams
        or espState.itemIcons

    -- Players
    if needsPlayers then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                local char = player.Character
                if char and char:FindFirstChildOfClass("Humanoid") then
                    createESPObject(char, player.Name, Colors.bloodLight, false, false)
                end
            end
        end
    end

    -- NPCs
    if espState.npcs then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not playerChars[obj] then
                createESPObject(obj, obj.Name, Colors.green, false, true)
            end
        end
    end

    -- Cameras
    if espState.cameras then
        local cameraKeywords = { "camera", "cam", "cctv", "security", "surveillance", "monitor" }
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Camera") and obj ~= workspace.CurrentCamera then
                createESPObject(obj, obj.Name, Color3.fromRGB(255, 200, 100), true, false)
            elseif (obj:IsA("BasePart") or obj:IsA("Model")) and not obj:FindFirstChild("VampESP_BG") then
                local lowerName = obj.Name:lower()
                for _, keyword in ipairs(cameraKeywords) do
                    if lowerName:find(keyword) then
                        createESPObject(obj, obj.Name, Color3.fromRGB(255, 200, 100), true, false)
                        break
                    end
                end
            end
        end
    end

    -- Update loop (RenderStepped)
    espConnection = RunService.RenderStepped:Connect(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local myPos = hrp.Position
        local cam = workspace.CurrentCamera

        -- Clear old tracers each frame
        if espState.tracers then
            for _, line in ipairs(tracerLines) do
                if line and line.Parent then line:Destroy() end
            end
            tracerLines = {}
        end

        -- Screen bottom center (tracer origin)
        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)

        for i = #espObjects, 1, -1 do
            local esp = espObjects[i]
            if not esp.target or not esp.target.Parent then
                table.remove(espObjects, i)
            else
                local targetPos
                if esp.target:IsA("Model") then
                    local tHRP = esp.target:FindFirstChild("HumanoidRootPart")
                        or esp.target:FindFirstChild("Head")
                        or esp.target.PrimaryPart
                    if tHRP then targetPos = tHRP.Position end
                elseif esp.target:IsA("BasePart") then
                    targetPos = esp.target.Position
                elseif esp.target:IsA("Camera") then
                    targetPos = esp.target.CFrame.Position
                end

                if targetPos then
                    local dist = math.floor((myPos - targetPos).Magnitude)
                    esp.distLabel.Text = dist .. " studs"

                    -- Threat Level: color name label based on distance
                    if espState.threatLevel and esp.nameLabel then
                        if dist < 30 then
                            esp.nameLabel.TextColor3 = Color3.fromRGB(255, 40, 40)     -- RED close
                        elseif dist < 60 then
                            esp.nameLabel.TextColor3 = Color3.fromRGB(255, 180, 40)    -- YELLOW mid
                        else
                            esp.nameLabel.TextColor3 = Color3.fromRGB(40, 255, 80)     -- GREEN far
                        end
                    end

                    -- Tool ESP: show equipped tool name
                    if esp.toolLabel and esp.target:IsA("Model") then
                        local toolName = ""
                        for _, child in ipairs(esp.target:GetChildren()) do
                            if child:IsA("Tool") then
                                toolName = "🔧 " .. child.Name
                                break
                            end
                        end
                        esp.toolLabel.Text = toolName
                    end

                    -- Item Icons: show backpack tool icons above name
                    if esp.itemRow and esp.target:IsA("Model") then
                        local now = os.clock()
                        local player = nil
                        pcall(function()
                            player = Players:GetPlayerFromCharacter(esp.target)
                        end)
                        if player then
                            local cache = espBackpackCache[player.UserId]
                            if not cache or (now - cache.time) > 3 then
                                -- Refresh cache
                                local tools = {}
                                pcall(function()
                                    -- Character (equipped)
                                    for _, obj in ipairs(esp.target:GetChildren()) do
                                        if obj:IsA("Tool") then
                                            table.insert(tools, { name = obj.Name, tex = obj.TextureId, equipped = true })
                                        end
                                    end
                                    -- Backpack
                                    local bp = player:FindFirstChild("Backpack")
                                    if bp then
                                        for _, obj in ipairs(bp:GetChildren()) do
                                            if obj:IsA("Tool") then
                                                table.insert(tools, { name = obj.Name, tex = obj.TextureId, equipped = false })
                                            end
                                        end
                                    end
                                end)
                                espBackpackCache[player.UserId] = { tools = tools, time = now }
                                cache = espBackpackCache[player.UserId]

                                -- Rebuild icons
                                for _, child in ipairs(esp.itemRow:GetChildren()) do
                                    if child:IsA("ImageLabel") or child:IsA("TextLabel") then
                                        child:Destroy()
                                    end
                                end

                                local count = 0
                                for _, tool in ipairs(cache.tools) do
                                    if count >= 6 then break end
                                    if tool.tex and tool.tex ~= "" then
                                        local icon = Instance.new("ImageLabel")
                                        icon.Size = UDim2.new(0, 32, 0, 32)
                                        icon.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
                                        icon.BackgroundTransparency = 0.3
                                        icon.Image = tool.tex
                                        icon.ScaleType = Enum.ScaleType.Fit
                                        icon.Parent = esp.itemRow
                                        Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 4)
                                        if tool.equipped then
                                            local stroke = Instance.new("UIStroke", icon)
                                            stroke.Color = Color3.fromRGB(80, 255, 80)
                                            stroke.Thickness = 1.5
                                        end
                                    else
                                        local lbl = Instance.new("TextLabel")
                                        lbl.Size = UDim2.new(0, 32, 0, 32)
                                        lbl.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
                                        lbl.BackgroundTransparency = 0.3
                                        lbl.Text = tool.name:sub(1, 2)
                                        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                                        lbl.TextSize = 8
                                        lbl.Font = Enum.Font.GothamBold
                                        lbl.Parent = esp.itemRow
                                        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
                                        if tool.equipped then
                                            local stroke = Instance.new("UIStroke", lbl)
                                            stroke.Color = Color3.fromRGB(80, 255, 80)
                                            stroke.Thickness = 1.5
                                        end
                                    end
                                    count = count + 1
                                end
                            end
                        end
                    end

                    -- Tracers: draw line from screen bottom to target screen position
                    if espState.tracers then
                        local screenPos, onScreen = cam:WorldToScreenPoint(targetPos)
                        if onScreen then
                            local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
                            local tracerColor = Color3.fromRGB(0, 180, 255)
                            if espState.threatLevel then
                                if dist < 30 then
                                    tracerColor = Color3.fromRGB(255, 40, 40)
                                elseif dist < 60 then
                                    tracerColor = Color3.fromRGB(255, 180, 40)
                                else
                                    tracerColor = Color3.fromRGB(40, 255, 80)
                                end
                            end
                            local line = drawTracerLine(screenCenter, targetScreen, tracerColor)
                            table.insert(tracerLines, line)
                        end
                    end
                end

                -- Update health bar
                if esp.healthFill and not esp.isCamera then
                    local hum = esp.target:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        esp.healthFill.Size = UDim2.new(pct, 0, 1, 0)
                        if pct > 0.5 then
                            esp.healthFill.BackgroundColor3 = Colors.green
                        elseif pct > 0.25 then
                            esp.healthFill.BackgroundColor3 = Colors.warning
                        else
                            esp.healthFill.BackgroundColor3 = Colors.glowRed
                        end
                    end
                end
            end
        end
    end)

    ESPStatusLabel.Text = #espObjects .. " targets tracked"
    log("ESP ON:", #espObjects, "targets")
end

toggleESPFeature = function(feature)
    espState[feature] = not espState[feature]
    updateESP()

    -- Refresh toggle UIs
    if espToggles[feature] then
        espToggles[feature].refresh()
    end
end

--==================================================
-- FOOTSTEPS TRAIL SYSTEM (separate from main ESP)
--==================================================

startFootsteps = function()
    espState.footsteps = true
    FootstepsToggle.refresh()

    -- Task loop para colocar marcas a cada 0.5s
    footstepConnection = task.spawn(function()
        while espState.footsteps do
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local pos = hrp.Position

                        local mark = Instance.new("Part")
                        mark.Name = "VampFootstep"
                        mark.Size = Vector3.new(0.6, 0.1, 0.6)
                        mark.Position = Vector3.new(pos.X, pos.Y - 3, pos.Z)
                        mark.Anchored = true
                        mark.CanCollide = false
                        mark.Material = Enum.Material.Neon
                        mark.Color = Color3.fromRGB(120, 200, 80)
                        mark.Transparency = 0.4
                        mark.Parent = workspace

                        table.insert(footstepParts, mark)

                        -- Fade out and destroy after 8s
                        task.spawn(function()
                            task.wait(6)
                            if mark and mark.Parent then
                                TweenService:Create(mark, TweenInfo.new(2), { Transparency = 1 }):Play()
                                task.wait(2)
                                if mark and mark.Parent then mark:Destroy() end
                            end
                        end)
                    end
                end
            end

            -- Limit total marks
            while #footstepParts > 500 do
                local old = table.remove(footstepParts, 1)
                if old and old.Parent then old:Destroy() end
            end

            task.wait(0.5)
        end
    end)

    notify("Footsteps Trail ON", "success")
end

stopFootsteps = function()
    espState.footsteps = false
    FootstepsToggle.refresh()

    -- footstepConnection is a thread, it will exit on next loop check

    -- Clear existing marks
    for _, part in ipairs(footstepParts) do
        if part and part.Parent then part:Destroy() end
    end
    footstepParts = {}

    notify("Footsteps Trail OFF", "info")
end

--==================================================
-- SOUND ESP SYSTEM (separate from main ESP)
--==================================================

startSoundESP = function()
    espState.soundESP = true
    SoundESPToggle.refresh()

    -- Periodic scan for playing sounds
    soundEspConnection = task.spawn(function()
        while espState.soundESP do
            -- Clear old billboards
            for _, obj in ipairs(soundEspObjects) do
                if obj and obj.Parent then obj:Destroy() end
            end
            soundEspObjects = {}

            local myChar = LP.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                local myPos = myHRP.Position

                for _, desc in ipairs(workspace:GetDescendants()) do
                    if desc:IsA("Sound") and desc.Playing then
                        local parent = desc.Parent
                        if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
                            local adornee = parent
                            if parent:IsA("Model") then
                                adornee = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
                            end

                            if adornee and adornee:IsA("BasePart") then
                                local soundPos = adornee.Position
                                local dist = math.floor((myPos - soundPos).Magnitude)

                                local bg = Instance.new("BillboardGui")
                                bg.Name = "VampSoundESP"
                                bg.Size = UDim2.new(0, 160, 0, 30)
                                bg.StudsOffset = Vector3.new(0, 3, 0)
                                bg.AlwaysOnTop = true
                                bg.Adornee = adornee
                                bg.Parent = adornee

                                local lbl = Instance.new("TextLabel")
                                lbl.Size = UDim2.new(1, 0, 1, 0)
                                lbl.BackgroundTransparency = 1
                                lbl.Text = "🔊 " .. desc.Name .. " [" .. dist .. "m]"
                                lbl.TextColor3 = Color3.fromRGB(255, 200, 60)
                                lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                lbl.TextStrokeTransparency = 0.3
                                lbl.TextSize = 10
                                lbl.Font = Enum.Font.GothamBold
                                lbl.Parent = bg

                                table.insert(soundEspObjects, bg)
                            end
                        end
                    end
                end
            end

            task.wait(2)
        end
    end)

    notify("Sound ESP ON", "success")
end

stopSoundESP = function()
    espState.soundESP = false
    SoundESPToggle.refresh()

    -- soundEspConnection is a thread, exits on next loop check

    -- Clear billboards
    for _, obj in ipairs(soundEspObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    soundEspObjects = {}

    notify("Sound ESP OFF", "info")
end

--==================================================
-- AIMBOT SYSTEM
--==================================================

-- Find closest player head to screen center within FOV
getAimbotTarget = function()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local fovRadius = aimbotState.fov
    local closest = nil
    local closestDist = fovRadius

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        -- Team check
        if aimbotState.teamCheck and plr.Team and LP.Team and plr.Team == LP.Team then
            continue
        end
        local char = plr.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = head
        end
    end
    return closest
end

-- Draw FOV circle (using Drawing API if available)
createFovCircle = function()
    if aimbotFovCircle then
        pcall(function() aimbotFovCircle:Remove() end)
        aimbotFovCircle = nil
    end
    pcall(function()
        if Drawing then
            aimbotFovCircle = Drawing.new("Circle")
            aimbotFovCircle.Radius = aimbotState.fov
            aimbotFovCircle.Color = Color3.fromRGB(255, 40, 40)
            aimbotFovCircle.Thickness = 1
            aimbotFovCircle.Transparency = 0.6
            aimbotFovCircle.Filled = false
            aimbotFovCircle.Visible = true
        end
    end)
end

startAimbot = function()
    createFovCircle()

    aimbotConnection = RunService.RenderStepped:Connect(function()
        -- Update FOV circle position to screen center
        if aimbotFovCircle then
            local cam = workspace.CurrentCamera
            if cam then
                pcall(function()
                    aimbotFovCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                end)
            end
        end

        -- Aim when right mouse button is held
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = getAimbotTarget()
            if target then
                local cam = workspace.CurrentCamera
                local targetPos = target.Position
                local currentCF = cam.CFrame
                local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
                -- Smooth interpolation
                local smooth = math.clamp(aimbotState.smoothness, 1, 20)
                local alpha = 1 / smooth
                cam.CFrame = currentCF:Lerp(targetCF, alpha)
            end
        end
    end)
    notify("Aimbot ON (hold right click)", "success")
end

stopAimbot = function()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    if aimbotFovCircle then
        pcall(function() aimbotFovCircle:Remove() end)
        aimbotFovCircle = nil
    end
    notify("Aimbot OFF", "info")
end

--==================================================
-- PIANO AUTO PLAYER LOGIC
--==================================================

-- Parse sheet notation into events + detect BPM
parsePianoSheet = function(text)
    -- Normalize em dash / en dash to hyphen
    text = text:gsub("\xe2\x80\x93", "-")  -- en dash –
    text = text:gsub("\xe2\x80\x94", "-")  -- em dash —
    text = text:gsub("\xc2\xa0", " ")       -- non-breaking space

    -- BPM detection: "120,notes" or "bpm:120 notes" or "BPM=120 notes"
    pianoDetectedBPM = nil
    local bpmMatch = text:match("^(%d+),")
    if bpmMatch and tonumber(bpmMatch) >= 20 and tonumber(bpmMatch) <= 600 then
        pianoDetectedBPM = tonumber(bpmMatch)
        text = text:sub(#bpmMatch + 2) -- remove "120,"
    else
        bpmMatch = text:match("[Bb][Pp][Mm][=:%s]+(%d+)")
        if bpmMatch and tonumber(bpmMatch) >= 20 and tonumber(bpmMatch) <= 600 then
            pianoDetectedBPM = tonumber(bpmMatch)
            text = text:gsub("[Bb][Pp][Mm][=:%s]+%d+%s*", "", 1)
        end
    end

    local events = {}
    local i = 1
    while i <= #text do
        local c = text:sub(i, i)
        if c == "[" then
            local j = text:find("]", i)
            if j then
                local chord = text:sub(i + 1, j - 1)
                table.insert(events, { type = "chord", notes = chord })
                i = j + 1
            else
                i = i + 1
            end
        elseif c == " " then
            table.insert(events, { type = "pause", duration = 1 })
            i = i + 1
        elseif c == "|" then
            table.insert(events, { type = "pause", duration = 2 })
            i = i + 1
        elseif c == "\n" or c == "\r" then
            table.insert(events, { type = "pause", duration = 1.5 })
            i = i + 1
        elseif c == "-" then
            table.insert(events, { type = "pause", duration = 0.5 })
            i = i + 1
        else
            table.insert(events, { type = "note", key = c })
            i = i + 1
        end
    end
    return events
end

-- Map shift-symbols to their base number key
pianoSymbolToNumber = {
    ["!"] = Enum.KeyCode.One,
    ["@"] = Enum.KeyCode.Two,
    ["$"] = Enum.KeyCode.Four,
    ["%"] = Enum.KeyCode.Five,
    ["^"] = Enum.KeyCode.Six,
    ["*"] = Enum.KeyCode.Eight,
    ["("] = Enum.KeyCode.Nine,
}

-- Map number chars to KeyCode
pianoNumberKeys = {
    ["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two, ["3"] = Enum.KeyCode.Three,
    ["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five, ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven, ["8"] = Enum.KeyCode.Eight, ["9"] = Enum.KeyCode.Nine,
    ["0"] = Enum.KeyCode.Zero,
}

-- Get KeyCode + whether shift is needed for a piano key character
getPianoKeyCode = function(key)
    -- Shift symbols (!, @, $, %, ^, *, ()
    if pianoSymbolToNumber[key] then
        return pianoSymbolToNumber[key], true
    end
    -- Numbers
    if pianoNumberKeys[key] then
        return pianoNumberKeys[key], false
    end
    -- Uppercase letter → needs shift
    local upper = key:upper()
    local lower = key:lower()
    local needsShift = (key == upper and key ~= lower)
    local keyCode = Enum.KeyCode[upper]
    if keyCode then
        return keyCode, needsShift
    end
    return nil, false
end

-- Press a piano key DOWN (returns release function)
pressPianoKey = function(key)
    local keyCode, needsShift = getPianoKeyCode(key)
    if not keyCode then return nil end

    -- Method 1: VirtualInputManager
    local vim = nil
    local ok1 = pcall(function()
        vim = game:GetService("VirtualInputManager")
        if needsShift then
            vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        end
        vim:SendKeyEvent(true, keyCode, false, game)
    end)

    if ok1 and vim then
        return function()
            pcall(function()
                vim:SendKeyEvent(false, keyCode, false, game)
                if needsShift then
                    vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
                end
            end)
        end
    end

    -- Method 2: keypress/keyrelease (executor-specific)
    local ok2 = pcall(function()
        if keypress and keyrelease then
            if needsShift then keypress(0xA0) end
            keypress(string.byte(key:upper()))
        end
    end)

    if ok2 then
        return function()
            pcall(function()
                keyrelease(string.byte(key:upper()))
                if needsShift then keyrelease(0xA0) end
            end)
        end
    end

    return nil
end

-- Fire a key press with optional hold duration (legacy compat)
firePianoKey = function(key, holdTime)
    local release = pressPianoKey(key)
    if release then
        task.wait(holdTime or 0.03)
        release()
    end
end

-- Play piano sheet with sustain + BPM
startPianoAuto = function(sheetText)
    if pianoAutoPlaying then
        stopPianoAuto()
    end

    local events = parsePianoSheet(sheetText)
    if #events == 0 then
        notify("Empty sheet!", "warning")
        return
    end

    -- BPM: manual > auto-detect > fallback
    local usedBPM = pianoManualBPM or pianoDetectedBPM
    local beatDelay
    if usedBPM then
        beatDelay = 60 / usedBPM / 4 -- semicolcheia (16th note)
    else
        beatDelay = 0.15 -- fallback padrão
    end

    pianoAutoPlaying = true
    pianoBPMLocked = (usedBPM ~= nil) -- travar speed quando BPM definido

    -- Preencher campo BPM com valor detectado (se não foi manual)
    if pianoDetectedBPM and not pianoManualBPM and PianoBPMInput then
        pcall(function() PianoBPMInput.Text = tostring(pianoDetectedBPM) end)
    end

    local statusMsg = usedBPM
        and ("♪ " .. usedBPM .. " BPM")
        or ("♪ Playing (" .. #events .. " notes)")
    if PianoAutoStatus then PianoAutoStatus.Text = statusMsg end
    if PianoAutoStatus then PianoAutoStatus.TextColor3 = Color3.fromRGB(80, 200, 100) end
    notify(statusMsg, "success")

    -- Travar slider visual quando BPM detectado
    if pianoBPMLocked and PianoAutoSpeedSlider then
        pcall(function()
            PianoAutoSpeedSlider.BackgroundTransparency = 0.7
        end)
    end

    pianoAutoThread = task.spawn(function()
        for _, event in ipairs(events) do
            if not pianoAutoPlaying then break end
            -- Se BPM detectado, ignorar speed do slider — tempo é fixo
            local delay = pianoBPMLocked and beatDelay or (beatDelay / pianoAutoSpeed)
            local holdTime = delay * 0.85 -- segurar 85% do beat, soltar 15% antes do próximo

            if event.type == "note" then
                -- Pressionar e segurar pela duração do beat
                local release = pressPianoKey(event.key)
                if release then
                    task.wait(holdTime)
                    release()
                    task.wait(delay - holdTime) -- gap antes da próxima nota
                else
                    task.wait(delay)
                end

            elseif event.type == "chord" then
                -- Pressionar TODAS as notas do acorde simultaneamente
                local releases = {}
                for ci = 1, #event.notes do
                    if not pianoAutoPlaying then break end
                    local rel = pressPianoKey(event.notes:sub(ci, ci))
                    if rel then table.insert(releases, rel) end
                end
                -- Segurar o acorde
                task.wait(holdTime)
                -- Soltar todas
                for _, rel in ipairs(releases) do
                    rel()
                end
                task.wait(delay - holdTime)

            elseif event.type == "pause" then
                task.wait(delay * event.duration)
            end
        end

        pianoAutoPlaying = false
        pianoBPMLocked = false
        if PianoAutoSpeedSlider then
            pcall(function() PianoAutoSpeedSlider.BackgroundTransparency = 0 end)
        end
        local doneMsg = usedBPM
            and ("♪ Done! (" .. usedBPM .. " BPM)")
            or "♪ Done!"
        if PianoAutoStatus then PianoAutoStatus.Text = doneMsg end
        if PianoAutoStatus then PianoAutoStatus.TextColor3 = Color3.fromRGB(140, 120, 255) end
        notify("Piano finished!", "info")
    end)
end

stopPianoAuto = function()
    pianoAutoPlaying = false
    pianoBPMLocked = false
    if PianoAutoSpeedSlider then
        pcall(function() PianoAutoSpeedSlider.BackgroundTransparency = 0 end)
    end
    if pianoAutoThread then
        pcall(function() task.cancel(pianoAutoThread) end)
        pianoAutoThread = nil
    end
    if PianoAutoStatus then PianoAutoStatus.Text = "Stopped" end
    if PianoAutoStatus then PianoAutoStatus.TextColor3 = Colors.textDim end
    notify("Piano stopped", "info")
end


--[[ ═══════ MODULE: 20_movement.luau ═══════ ]]

--==================================================
-- MOVEMENT LOGIC
--==================================================

-- Apply speed/jump to humanoid
applySpeed = function()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = movementState.speed
        hum.UseJumpPower = true
        hum.JumpPower = movementState.jumpPower
    end
end

--==================================================
-- FLY
--==================================================

startFly = function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        notify("No character found", "error")
        return
    end

    -- Clean up old
    if flyBG then pcall(function() flyBG:Destroy() end) end
    if flyBV then pcall(function() flyBV:Destroy() end) end

    -- Disable falling animation
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:ChangeState(Enum.HumanoidStateType.Physics)

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    flyBG.P = 10000
    flyBG.D = 500
    flyBG.Parent = hrp

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(4e5, 4e5, 4e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyConnection = RunService.RenderStepped:Connect(function()
        -- Keep humanoid from falling state
        if hum:GetState() == Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end

        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.yAxis end

        if dir.Magnitude > 0 then
            flyBV.Velocity = dir.Unit * movementState.speed * 3
        else
            flyBV.Velocity = Vector3.zero
        end
        flyBG.CFrame = cam.CFrame
    end)

    notify("Fly ON", "success")
    log("Fly ON")
end

stopFly = function()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end

    -- Re-enable falling states
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    notify("Fly OFF", "info")
    log("Fly OFF")
end

--==================================================
-- NOCLIP
--==================================================

toggleNoclip = function()
    if movementState.noclip then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LP.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        notify("Noclip ON", "success")
        log("Noclip ON")
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        notify("Noclip OFF", "info")
        log("Noclip OFF")
    end
end

--==================================================
-- INFINITE JUMP
--==================================================

toggleInfiniteJump = function()
    if movementState.infiniteJump then
        jumpConnection = UIS.JumpRequest:Connect(function()
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        notify("Infinite Jump ON", "success")
        log("Infinite Jump ON")
    else
        if jumpConnection then
            jumpConnection:Disconnect()
            jumpConnection = nil
        end
        notify("Infinite Jump OFF", "info")
        log("Infinite Jump OFF")
    end
end

--==================================================
-- FREECAM
--==================================================

startFreecam = function()
    local cam = workspace.CurrentCamera
    savedCameraState = {
        subject = cam.CameraSubject,
        ctype = cam.CameraType,
        mouseBehavior = UIS.MouseBehavior,
        mouseIcon = UIS.MouseIconEnabled,
    }
    cam.CameraType = Enum.CameraType.Scriptable

    -- Extract initial yaw/pitch from current camera
    local rx, ry, _ = cam.CFrame:ToEulerAnglesYXZ()
    local yaw = ry
    local pitch = rx
    local sensitivity = 0.003

    -- Lock mouse to center + hide cursor
    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
    UIS.MouseIconEnabled = false

    -- Anchor character so it doesn't move while in freecam
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = true
    end

    freecamConnection = RunService.RenderStepped:Connect(function(dt)
        -- Mouse rotation
        local delta = UIS:GetMouseDelta()
        yaw = yaw - delta.X * sensitivity
        pitch = math.clamp(pitch - delta.Y * sensitivity, -math.rad(89), math.rad(89))

        local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)

        -- Movement
        local speed = movementState.speed * 2
        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + rotation.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - rotation.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - rotation.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + rotation.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end

        local pos = cam.CFrame.Position
        if move.Magnitude > 0 then
            pos = pos + move.Unit * speed * dt
        end

        cam.CFrame = CFrame.new(pos) * rotation
    end)

    notify("Freecam ON (mouse to look)", "success")
    log("Freecam ON")
end

stopFreecam = function()
    if freecamConnection then
        freecamConnection:Disconnect()
        freecamConnection = nil
    end

    -- Unanchor character
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
    end

    local cam = workspace.CurrentCamera

    -- Sempre restaurar mouse primeiro (evita ficar travado)
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    UIS.MouseIconEnabled = true

    if savedCameraState then
        -- Verifica se o subject salvo ainda é valido
        local subject = savedCameraState.subject
        local subjectValid = false
        pcall(function()
            subjectValid = subject and subject.Parent ~= nil
        end)

        if subjectValid then
            cam.CameraSubject = subject
        else
            -- Subject morreu/respawnou — usa humanoid atual
            local newChar = LP.Character
            local newHum = newChar and newChar:FindFirstChildOfClass("Humanoid")
            if newHum then
                cam.CameraSubject = newHum
            end
        end

        cam.CameraType = Enum.CameraType.Custom
        savedCameraState = nil
    else
        -- Fallback: restaura camera pro character atual
        local newChar = LP.Character
        local newHum = newChar and newChar:FindFirstChildOfClass("Humanoid")
        if newHum then
            cam.CameraSubject = newHum
        end
        cam.CameraType = Enum.CameraType.Custom
    end

    notify("Freecam OFF", "info")
    log("Freecam OFF")
end

--==================================================
-- CLICK TP
--==================================================

startClickTP = function()
    clickTPConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local mouse = LP:GetMouse()
        if mouse.Target then
            local pos = mouse.Hit.Position + Vector3.new(0, 3, 0)
            hrp.CFrame = CFrame.new(pos)
            notify("Teleported!", "success")
        end
    end)
    notify("ClickTP ON — click anywhere to teleport", "success")
end

stopClickTP = function()
    if clickTPConnection then
        clickTPConnection:Disconnect()
        clickTPConnection = nil
    end
    notify("ClickTP OFF", "info")
end

--==================================================
-- ANTIVOID
--==================================================

startAntiVoid = function()
    antiVoidLastSafe = nil
    antiVoidConnection = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pos = hrp.Position
        if pos.Y < -50 then
            if antiVoidLastSafe then
                hrp.CFrame = antiVoidLastSafe
                notify("AntiVoid saved you!", "warning")
            end
        else
            antiVoidLastSafe = hrp.CFrame
        end
    end)
    notify("AntiVoid ON", "success")
end

stopAntiVoid = function()
    if antiVoidConnection then
        antiVoidConnection:Disconnect()
        antiVoidConnection = nil
    end
    antiVoidLastSafe = nil
    notify("AntiVoid OFF", "info")
end

--==================================================
-- SPIN
--==================================================

startSpin = function()
    spinConnection = RunService.RenderStepped:Connect(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(movementState.spinSpeed or 10), 0)
    end)
    notify("Spin ON", "success")
end

stopSpin = function()
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
    notify("Spin OFF", "info")
end

--==================================================
-- FLASHBACK (Position Recall)
--==================================================

flashbackSavedCFrame = nil

saveFlashback = function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        flashbackSavedCFrame = hrp.CFrame
        notify("Position saved!", "success")
    else
        notify("No character", "error")
    end
end

doFlashback = function()
    if not flashbackSavedCFrame then
        notify("No position saved!", "warning")
        return
    end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = flashbackSavedCFrame
        notify("Flashed back!", "success")
    end
end

--==================================================
-- FE FLIP
--==================================================

doFeFlip = function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        notify("No character", "error")
        return
    end
    notify("Flip!", "success")
    local startCF = hrp.CFrame
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    for i = 1, 36 do
        hrp.CFrame = startCF * CFrame.new(0, math.sin(math.rad(i * 10)) * 4, -i * 0.15) * CFrame.Angles(math.rad(i * 10), 0, 0)
        task.wait()
    end
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
end


--[[ ═══════ MODULE: 20b_utils_logic.luau ═══════ ]]

--==================================================
-- UTILS LOGIC (Lógica de utilitários)
--==================================================

-- ════════════════════════════════════════════════
-- 1. Servidor - Hop & Rejoin
-- ════════════════════════════════════════════════

doServerHop = function()
	-- Teleporta para outro servidor do mesmo jogo
	TeleportService = game:GetService("TeleportService")
	placeId = game.PlaceId
	notify("Hopping to new server...", "info")
	pcall(function()
		TeleportService:Teleport(placeId)
	end)
end

doRejoin = function()
	-- Reconecta ao mesmo servidor
	TeleportService = game:GetService("TeleportService")
	notify("Rejoining server...", "info")
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
	end)
end

-- ════════════════════════════════════════════════
-- 2. Copiar IDs
-- ════════════════════════════════════════════════

copyPlaceId = function()
	id = tostring(game.PlaceId)
	if setclipboard then
		setclipboard(id)
	elseif toclipboard then
		toclipboard(id)
	end
	notify("Place ID copied: " .. id, "success")
end

copyJobId = function()
	id = game.JobId
	if setclipboard then
		setclipboard(id)
	elseif toclipboard then
		toclipboard(id)
	end
	notify("Job ID copied: " .. id:sub(1, 8) .. "...", "success")
end

-- ════════════════════════════════════════════════
-- 3. Anti-AFK
-- ════════════════════════════════════════════════

startAntiAfk = function()
	if antiAfkConnection then return end
	antiAfkEnabled = true
	-- Sobrescreve evento de idle para impedir kick por AFK
	antiAfkConnection = LP.Idled:Connect(function()
		vu = game:GetService("VirtualUser")
		vu:CaptureController()
		vu:ClickButton2(Vector2.new())
	end)
	notify("Anti-AFK ON", "success")
end

stopAntiAfk = function()
	antiAfkEnabled = false
	if antiAfkConnection then
		antiAfkConnection:Disconnect()
		antiAfkConnection = nil
	end
	notify("Anti-AFK OFF", "info")
end

-- ════════════════════════════════════════════════
-- 4. Player de Som
-- ════════════════════════════════════════════════

playSound = function(audioId)
	stopSound() -- para o som atual primeiro
	snd = Instance.new("Sound")
	snd.SoundId = "rbxassetid://" .. tostring(audioId)
	snd.Volume = (SoundVolumeValue or 50) / 100
	snd.Looped = soundLoopState.loop or false
	snd.Parent = game:GetService("SoundService")
	snd:Play()
	currentSound = snd
	notify("Playing sound: " .. tostring(audioId), "success")

	-- Atualiza status na UI
	if SoundStatusLabel then
		SoundStatusLabel.Text = "Playing: " .. tostring(audioId)
		SoundStatusLabel.TextColor3 = Colors.green
	end

	-- Escuta quando terminar
	snd.Ended:Connect(function()
		if SoundStatusLabel and not snd.Looped then
			SoundStatusLabel.Text = "Finished"
			SoundStatusLabel.TextColor3 = Colors.textDim
		end
	end)
end

stopSound = function()
	if currentSound then
		pcall(function() currentSound:Stop() currentSound:Destroy() end)
		currentSound = nil
	end
	-- Para também todos os sons no SoundService
	pcall(function()
		for _, snd in pairs(game:GetService("SoundService"):GetChildren()) do
			if snd:IsA("Sound") and snd.Name == "Sound" then
				snd:Stop()
				snd:Destroy()
			end
		end
	end)
	if SoundStatusLabel then
		SoundStatusLabel.Text = "No sound playing"
		SoundStatusLabel.TextColor3 = Colors.textDim
	end
end

listMapSounds = function()
	-- Encontra todos os sons no workspace
	mapSoundsList = {}
	scanForSounds = function(parent)
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("Sound") then
				table.insert(mapSoundsList, child)
			end
			if #child:GetChildren() > 0 then
				pcall(function() scanForSounds(child) end)
			end
		end
	end
	pcall(function() scanForSounds(game.Workspace) end)
	pcall(function() scanForSounds(game:GetService("SoundService")) end)

	-- Constrói lista na UI dentro do MapSoundsScroll
	if MapSoundsScroll then
		for _, child in pairs(MapSoundsScroll:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		for i, snd in ipairs(mapSoundsList) do
			btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 22)
			btn.BackgroundColor3 = Colors.card or Color3.fromRGB(25, 20, 35)
			btn.Text = "🔊 " .. snd.Name .. " (" .. tostring(snd.SoundId):sub(1, 30) .. ")"
			btn.TextColor3 = Colors.text or Color3.fromRGB(220, 220, 220)
			btn.TextSize = 9
			btn.Font = Enum.Font.Code
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.TextTruncate = Enum.TextTruncate.AtEnd
			btn.AutoButtonColor = false
			btn.Parent = MapSoundsScroll
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

			btn.MouseButton1Click:Connect(function()
				-- Alterna play/stop deste som
				if snd.Playing then
					snd:Stop()
					btn.BackgroundColor3 = Colors.card or Color3.fromRGB(25, 20, 35)
					notify("Stopped: " .. snd.Name, "info")
				else
					snd:Play()
					btn.BackgroundColor3 = Colors.glowPurple or Color3.fromRGB(100, 60, 180)
					notify("Playing: " .. snd.Name, "success")
				end
			end)
		end

		MapSoundsScroll.CanvasSize = UDim2.new(0, 0, 0, #mapSoundsList * 25)
	end

	notify("Found " .. #mapSoundsList .. " sounds", "info")
end

playAllMapSounds = function()
	if mapSoundsList then
		for _, snd in ipairs(mapSoundsList) do
			pcall(function() snd:Play() end)
		end
		notify("Playing all " .. #mapSoundsList .. " sounds!", "success")
	end
end

stopAllMapSounds = function()
	if mapSoundsList then
		for _, snd in ipairs(mapSoundsList) do
			pcall(function() snd:Stop() end)
		end
		notify("Stopped all sounds", "info")
	end
end

-- ════════════════════════════════════════════════
-- 5. Waypoints (Pontos de teletransporte)
-- ════════════════════════════════════════════════

saveWaypoint = function()
	char = LP.Character
	hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		notify("No character!", "error")
		return
	end

	pos = hrp.CFrame
	name = "WP #" .. (#savedWaypoints + 1) .. " (" .. math.floor(pos.Position.X) .. ", " .. math.floor(pos.Position.Y) .. ", " .. math.floor(pos.Position.Z) .. ")"
	table.insert(savedWaypoints, { name = name, cframe = pos })

	refreshWaypointList()
	notify("Waypoint saved!", "success")
end

refreshWaypointList = function()
	if not WaypointScroll then return end

	-- Limpa existentes
	for _, child in pairs(WaypointScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for i, wp in ipairs(savedWaypoints) do
		row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 24)
		row.BackgroundColor3 = Colors.card or Color3.fromRGB(25, 20, 35)
		row.BorderSizePixel = 0
		row.Parent = WaypointScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

		label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -60, 1, 0)
		label.Position = UDim2.new(0, 6, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = wp.name
		label.TextColor3 = Colors.text or Color3.fromRGB(220, 220, 220)
		label.TextSize = 9
		label.Font = Enum.Font.Code
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Parent = row

		-- Botão de teleporte
		tpBtn = Instance.new("TextButton")
		tpBtn.Size = UDim2.new(0, 26, 0, 18)
		tpBtn.Position = UDim2.new(1, -56, 0, 3)
		tpBtn.BackgroundColor3 = Colors.glowPurple or Color3.fromRGB(100, 60, 180)
		tpBtn.Text = "⚡"
		tpBtn.TextColor3 = Colors.text or Color3.fromRGB(220, 220, 220)
		tpBtn.TextSize = 10
		tpBtn.Font = Enum.Font.GothamBold
		tpBtn.AutoButtonColor = false
		tpBtn.Parent = row
		Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)

		tpBtn.MouseButton1Click:Connect(function()
			char2 = LP.Character
			hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
			if hrp2 then
				hrp2.CFrame = wp.cframe
				notify("Teleported to " .. wp.name, "success")
			end
		end)

		-- Botão de deletar
		delBtn = Instance.new("TextButton")
		delBtn.Size = UDim2.new(0, 22, 0, 18)
		delBtn.Position = UDim2.new(1, -26, 0, 3)
		delBtn.BackgroundColor3 = Colors.bloodDark or Color3.fromRGB(120, 30, 30)
		delBtn.Text = "X"
		delBtn.TextColor3 = Colors.text or Color3.fromRGB(220, 220, 220)
		delBtn.TextSize = 9
		delBtn.Font = Enum.Font.GothamBold
		delBtn.AutoButtonColor = false
		delBtn.Parent = row
		Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)

		delBtn.MouseButton1Click:Connect(function()
			table.remove(savedWaypoints, i)
			refreshWaypointList()
			notify("Waypoint deleted", "info")
		end)
	end

	WaypointScroll.CanvasSize = UDim2.new(0, 0, 0, #savedWaypoints * 27)
	if WaypointCountLabel then
		WaypointCountLabel.Text = #savedWaypoints .. " waypoints saved"
	end
end

clearAllWaypoints = function()
	savedWaypoints = {}
	refreshWaypointList()
	notify("All waypoints cleared", "info")
end

-- ════════════════════════════════════════════════
-- 6. Escala do Personagem
-- ════════════════════════════════════════════════

applyCharacterScale = function(height, width, head)
	char = LP.Character
	if not char then return end
	hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	pcall(function()
		bodyHeight = hum:FindFirstChild("BodyHeightScale")
		bodyWidth = hum:FindFirstChild("BodyWidthScale")
		bodyDepth = hum:FindFirstChild("BodyDepthScale")
		headScale = hum:FindFirstChild("HeadScale")

		if bodyHeight then bodyHeight.Value = height end
		if bodyWidth then bodyWidth.Value = width end
		if bodyDepth then bodyDepth.Value = width end -- iguala à largura
		if headScale then headScale.Value = head end
	end)
end

resetCharacterScale = function()
	applyCharacterScale(1.0, 1.0, 1.0)
	-- Reseta sliders da UI
	if CharHeightSlider and CharHeightSlider.setValue then CharHeightSlider.setValue(1.0) end
	if CharWidthSlider and CharWidthSlider.setValue then CharWidthSlider.setValue(1.0) end
	if CharHeadSlider and CharHeadSlider.setValue then CharHeadSlider.setValue(1.0) end
	notify("Scale reset!", "info")
end

-- ════════════════════════════════════════════════
-- 7. Ambiente & Neblina
-- ════════════════════════════════════════════════

removeFog = function()
	lighting = game:GetService("Lighting")
	-- Salva valores originais
	if not savedFogEnd then
		savedFogEnd = lighting.FogEnd
		savedFogStart = lighting.FogStart
	end
	lighting.FogEnd = 1000000
	lighting.FogStart = 1000000

	-- Remove também efeitos de Atmosphere
	for _, child in pairs(lighting:GetChildren()) do
		if child:IsA("Atmosphere") then
			child.Density = 0
		end
	end
	notify("Fog removed!", "success")
end

restoreFog = function()
	lighting = game:GetService("Lighting")
	if savedFogEnd then
		lighting.FogEnd = savedFogEnd
		lighting.FogStart = savedFogStart
		savedFogEnd = nil
		savedFogStart = nil
	end
	-- Restaura atmosphere
	for _, child in pairs(lighting:GetChildren()) do
		if child:IsA("Atmosphere") then
			child.Density = 0.3 -- padrão razoável
		end
	end
	notify("Fog restored!", "info")
end

applyAmbientColor = function(r, g, b)
	lighting = game:GetService("Lighting")
	if not savedAmbient then
		savedAmbient = lighting.Ambient
		savedOutdoorAmbient = lighting.OutdoorAmbient
	end
	lighting.Ambient = Color3.fromRGB(r, g, b)
	lighting.OutdoorAmbient = Color3.fromRGB(r, g, b)
	notify("Ambient applied!", "success")
end

applyAtmosphere = function(density, haze, glow)
	lighting = game:GetService("Lighting")
	atmo = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		atmo = Instance.new("Atmosphere")
		atmo.Parent = lighting
	end
	atmo.Density = density / 100
	atmo.Haze = haze / 10
	atmo.Glare = glow / 100
	notify("Atmosphere applied!", "success")
end

resetAllAmbient = function()
	lighting = game:GetService("Lighting")
	if savedAmbient then
		lighting.Ambient = savedAmbient
		lighting.OutdoorAmbient = savedOutdoorAmbient
		savedAmbient = nil
		savedOutdoorAmbient = nil
	end
	restoreFog()
	-- Reseta atmosphere
	for _, child in pairs(lighting:GetChildren()) do
		if child:IsA("Atmosphere") then
			child.Density = 0.3
			child.Haze = 0
			child.Glare = 0
		end
	end
	-- Reseta sliders
	if AmbientRSlider and AmbientRSlider.setValue then AmbientRSlider.setValue(128) end
	if AmbientGSlider and AmbientGSlider.setValue then AmbientGSlider.setValue(128) end
	if AmbientBSlider and AmbientBSlider.setValue then AmbientBSlider.setValue(128) end
	if AtmoDensitySlider and AtmoDensitySlider.setValue then AtmoDensitySlider.setValue(30) end
	if AtmoHazeSlider and AtmoHazeSlider.setValue then AtmoHazeSlider.setValue(0) end
	if AtmoGlowSlider and AtmoGlowSlider.setValue then AtmoGlowSlider.setValue(0) end
	notify("Ambient reset!", "info")
end


--[[ ═══════ MODULE: 20c_anim_logic.luau ═══════ ]]

--==================================================
-- ANIMATION LOGIC
-- Busca catalogo, unpack bundle, aplicar no Animate script, speed, reset, preview
--==================================================

-- ════════════════════════════════════════════════
-- SNAPSHOT & APPLY
-- ════════════════════════════════════════════════

snapshotOriginalAnimations = function()
    local char = LP.Character
    if not char then return end
    local animate = char:WaitForChild("Animate", 5)
    if not animate then return end
    for _, slotName in ipairs(ANIM_SLOTS) do
        local slot = animate:FindFirstChild(slotName)
        if slot then
            originalAnimations[slotName] = {}
            for _, anim in ipairs(slot:GetChildren()) do
                if anim:IsA("Animation") then
                    do
                        local weightVal = nil
                        local weightObj = anim:FindFirstChild("Weight")
                        if weightObj then weightVal = weightObj.Value end
                        table.insert(originalAnimations[slotName], {
                            name = anim.Name,
                            id = anim.AnimationId,
                            weight = weightVal
                        })
                    end
                end
            end
        end
    end
end

applyAnimationSlot = function(slotName, animId)
    local char = LP.Character
    if not char then
        notify("No character", "error")
        return false
    end
    local animate = char:FindFirstChild("Animate")
    if not animate then
        notify("No Animate script found", "warning")
        return false
    end
    local slot = animate:FindFirstChild(slotName)
    if not slot then return false end
    for _, anim in ipairs(slot:GetChildren()) do
        if anim:IsA("Animation") then
            anim.AnimationId = "rbxassetid://" .. tostring(animId)
        end
    end
    currentAnimations[slotName] = animId
    if updateAnimSlotUI then
        updateAnimSlotUI(slotName)
    end
    return true
end

resetAnimationSlot = function(slotName, silent)
    if not originalAnimations[slotName] then return end
    local char = LP.Character
    local animate = char and char:FindFirstChild("Animate")
    if not animate then return end
    local slot = animate:FindFirstChild(slotName)
    if not slot then return end
    for _, origData in ipairs(originalAnimations[slotName]) do
        local anim = slot:FindFirstChild(origData.name)
        if anim and anim:IsA("Animation") then
            anim.AnimationId = origData.id
        end
    end
    currentAnimations[slotName] = nil
    if updateAnimSlotUI then
        updateAnimSlotUI(slotName)
    end
    if not silent then
        notify(ANIM_SLOT_LABELS[slotName] .. " reset", "info")
    end
end

resetAllAnimations = function()
    for _, slotName in ipairs(ANIM_SLOTS) do
        if currentAnimations[slotName] then
            resetAnimationSlot(slotName, true)
        end
    end
    notify("All animations reset", "info")
end

-- ════════════════════════════════════════════════
-- UNPACK BUNDLE
-- ════════════════════════════════════════════════

unpackAnimationBundle = function(bundleId)
    local ok, details = pcall(function()
        return AssetService:GetBundleDetailsAsync(bundleId)
    end)
    if not ok or not details then
        notify("Failed to load bundle", "error")
        return nil
    end

    local result = {}
    for _, item in ipairs(details.Items) do
        if item.Type == "Asset" then
            do
                local infoOk, info = pcall(function()
                    return MarketplaceService:GetProductInfo(item.Id, Enum.InfoType.Asset)
                end)
                if infoOk and info and info.AssetTypeId then
                    local slotName = ASSET_TYPE_MAP[info.AssetTypeId]
                    if slotName then
                        result[slotName] = { id = item.Id, name = info.Name or item.Name or "Unknown" }
                    end
                end
            end
        end
    end
    return result
end

applyFullBundle = function(bundleData)
    local count = 0
    for slotName, data in pairs(bundleData) do
        if applyAnimationSlot(slotName, data.id) then
            count = count + 1
        end
    end
    notify("Applied " .. count .. " animations", "success")
end

applySelectedBundle = function(bundleData, selectedSlots)
    local count = 0
    for slotName, data in pairs(bundleData) do
        if selectedSlots[slotName] then
            if applyAnimationSlot(slotName, data.id) then
                count = count + 1
            end
        end
    end
    notify("Applied " .. count .. " animations", "success")
end

-- ════════════════════════════════════════════════
-- PREVIEW
-- ════════════════════════════════════════════════

previewAnimation = function(animId)
    if animPreviewTrack then
        pcall(function() animPreviewTrack:Stop() end)
        pcall(function() animPreviewTrack:Destroy() end)
        animPreviewTrack = nil
    end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator", hum)
    end
    do
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. tostring(animId)
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        anim:Destroy()
        if ok and track then
            track.Priority = Enum.AnimationPriority.Action4
            track:Play()
            animPreviewTrack = track
            task.delay(3, function()
                if animPreviewTrack == track then
                    pcall(function() track:Stop(0.3) end)
                    task.delay(0.5, function()
                        pcall(function() track:Destroy() end)
                        if animPreviewTrack == track then animPreviewTrack = nil end
                    end)
                end
            end)
        end
    end
end

-- ════════════════════════════════════════════════
-- SPEED
-- ════════════════════════════════════════════════

animSpeedConnection = RunService.Heartbeat:Connect(function()
    if animSpeed == 1 then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Priority ~= Enum.AnimationPriority.Action
            and track.Priority ~= Enum.AnimationPriority.Action4 then
            track:AdjustSpeed(animSpeed)
        end
    end
end)

-- ════════════════════════════════════════════════
-- CATALOG SEARCH
-- ════════════════════════════════════════════════

searchAnimationCatalog = function(keyword)
    animSearchVersion = animSearchVersion + 1
    local thisVersion = animSearchVersion

    if AnimCatalogGrid then
        for _, child in pairs(AnimCatalogGrid:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
        end
    end

    if AnimCatalogEmpty then
        AnimCatalogEmpty.Visible = false
    end

    if keyword == nil or keyword == "" then
        animTabPreloaded = false
        preloadTrendingAnims()
        return
    end

    if AnimCatalogEmpty then
        AnimCatalogEmpty.Text = "Searching..."
        AnimCatalogEmpty.Visible = true
    end

    task.spawn(function()
        local params = CatalogSearchParams.new()
        params.BundleTypes = { Enum.BundleType.Animations }
        params.SortType = Enum.CatalogSortType.Relevance
        params.SearchKeyword = keyword

        local ok, pages = pcall(function()
            return AvatarEditorService:SearchCatalog(params)
        end)

        if animSearchVersion ~= thisVersion then return end

        if not ok or not pages then
            if AnimCatalogEmpty then
                AnimCatalogEmpty.Text = "Search failed"
                AnimCatalogEmpty.Visible = true
            end
            notify("Animation search failed", "error")
            return
        end

        local pageOk, items = pcall(function()
            return pages:GetCurrentPage()
        end)

        if not pageOk or not items or #items == 0 then
            if AnimCatalogEmpty then
                AnimCatalogEmpty.Text = "No animations found"
                AnimCatalogEmpty.Visible = true
            end
            return
        end

        if AnimCatalogEmpty then AnimCatalogEmpty.Visible = false end
        animCatalogPages = pages
        animCatalogHasMore = not pages.IsFinished

        populateAnimCatalogGrid(items, false)
    end)
end

preloadTrendingAnims = function()
    if animTabPreloaded then return end
    animTabPreloaded = true

    task.spawn(function()
        local params = CatalogSearchParams.new()
        params.BundleTypes = { Enum.BundleType.Animations }
        params.SortType = Enum.CatalogSortType.MostFavorited

        local ok, pages = pcall(function()
            return AvatarEditorService:SearchCatalog(params)
        end)

        if not ok or not pages then return end

        local pageOk, items = pcall(function()
            return pages:GetCurrentPage()
        end)

        if not pageOk or not items or #items == 0 then return end

        if AnimCatalogEmpty then AnimCatalogEmpty.Visible = false end
        animCatalogPages = pages
        animCatalogHasMore = not pages.IsFinished

        populateAnimCatalogGrid(items, false)
    end)
end

loadMoreAnims = function()
    if not animCatalogHasMore or not animCatalogPages or isLoadingMoreAnims then return end
    isLoadingMoreAnims = true

    task.spawn(function()
        local ok = pcall(function()
            animCatalogPages:AdvanceToNextPageAsync()
        end)
        if not ok then
            isLoadingMoreAnims = false
            return
        end

        local pageOk, items = pcall(function()
            return animCatalogPages:GetCurrentPage()
        end)

        isLoadingMoreAnims = false

        if not pageOk or not items or #items == 0 then
            animCatalogHasMore = false
            return
        end

        animCatalogHasMore = not animCatalogPages.IsFinished
        populateAnimCatalogGrid(items, true)
    end)
end

populateAnimCatalogGrid = function(items, append)
    if not AnimCatalogGrid then return end

    if not append then
        for _, child in pairs(AnimCatalogGrid:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
        end
    end

    for _, item in ipairs(items) do
        do
            local card = Instance.new("TextButton")
            card.Size = UDim2.new(0, 60, 0, 82)
            card.BackgroundColor3 = Colors.card
            card.AutoButtonColor = false
            card.BorderSizePixel = 0
            card.Text = ""
            card.Parent = AnimCatalogGrid
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(1, -4, 0, 52)
            thumb.Position = UDim2.new(0, 2, 0, 2)
            thumb.BackgroundTransparency = 1
            thumb.Image = "rbxthumb://type=BundleThumbnail&id=" .. tostring(item.Id) .. "&w=150&h=150"
            thumb.ScaleType = Enum.ScaleType.Fit
            thumb.Parent = card

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -4, 0, 24)
            nameL.Position = UDim2.new(0, 2, 0, 56)
            nameL.BackgroundTransparency = 1
            nameL.Text = item.Name or "Animation"
            nameL.TextColor3 = Colors.textDim
            nameL.TextSize = 8
            nameL.Font = Enum.Font.GothamBold
            nameL.TextXAlignment = Enum.TextXAlignment.Center
            nameL.TextTruncate = Enum.TextTruncate.AtEnd
            nameL.TextWrapped = true
            nameL.Parent = card

            local isFav = isFavoriteAnim(item.Id)
            local starBtn = Instance.new("TextButton")
            starBtn.Size = UDim2.new(0, 16, 0, 16)
            starBtn.Position = UDim2.new(1, -18, 0, 64)
            starBtn.BackgroundTransparency = 1
            starBtn.Text = isFav and "★" or "☆"
            starBtn.TextSize = 12
            starBtn.TextColor3 = isFav and Color3.fromRGB(255, 200, 50) or Colors.textDim
            starBtn.Parent = card

            starBtn.MouseButton1Click:Connect(function()
                local added = toggleFavoriteAnim(item.Id, item.Name or "Animation")
                starBtn.Text = added and "★" or "☆"
                starBtn.TextColor3 = added and Color3.fromRGB(255, 200, 50) or Colors.textDim
            end)

            card.MouseButton1Click:Connect(function()
                openAnimDetailView(item.Id, item.Name or "Animation")
            end)

            makeHoverable(card, Colors.card, Colors.surfaceLight)
        end
    end

    do
        local childCount = 0
        for _, child in pairs(AnimCatalogGrid:GetChildren()) do
            if child:IsA("TextButton") then childCount = childCount + 1 end
        end
        local cols = math.max(1, math.floor(AnimCatalogGrid.AbsoluteSize.X / 66))

        local rows = math.ceil(childCount / cols)
        AnimCatalogGrid.Size = UDim2.new(1, 0, 0, math.max(rows * 88, 88))
    end

    recalcAnimLayout()
end

-- ════════════════════════════════════════════════
-- FAVORITES
-- ════════════════════════════════════════════════

isFavoriteAnim = function(id)
    for _, fav in ipairs(animFavorites) do
        if fav.id == id then return true end
    end
    return false
end

toggleFavoriteAnim = function(id, name)
    for i, fav in ipairs(animFavorites) do
        if fav.id == id then
            table.remove(animFavorites, i)
            refreshAnimFavGrid()
            return false
        end
    end
    table.insert(animFavorites, { id = id, name = name })
    refreshAnimFavGrid()
    return true
end

refreshAnimFavGrid = function()
    if not AnimFavGrid then return end
    for _, child in pairs(AnimFavGrid:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    if #animFavorites == 0 then
        if AnimFavEmpty then AnimFavEmpty.Visible = true end
        AnimFavGrid.Size = UDim2.new(1, 0, 0, 0)
        recalcAnimLayout()
        return
    end

    if AnimFavEmpty then AnimFavEmpty.Visible = false end

    for _, fav in ipairs(animFavorites) do
        do
            local card = Instance.new("TextButton")
            card.Size = UDim2.new(0, 60, 0, 82)
            card.BackgroundColor3 = Colors.card
            card.AutoButtonColor = false
            card.BorderSizePixel = 0
            card.Text = ""
            card.Parent = AnimFavGrid
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(1, -4, 0, 52)
            thumb.Position = UDim2.new(0, 2, 0, 2)
            thumb.BackgroundTransparency = 1
            thumb.Image = "rbxthumb://type=BundleThumbnail&id=" .. tostring(fav.id) .. "&w=150&h=150"
            thumb.ScaleType = Enum.ScaleType.Fit
            thumb.Parent = card

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -4, 0, 24)
            nameL.Position = UDim2.new(0, 2, 0, 56)
            nameL.BackgroundTransparency = 1
            nameL.Text = fav.name
            nameL.TextColor3 = Colors.textDim
            nameL.TextSize = 8
            nameL.Font = Enum.Font.GothamBold
            nameL.TextXAlignment = Enum.TextXAlignment.Center
            nameL.TextTruncate = Enum.TextTruncate.AtEnd
            nameL.TextWrapped = true
            nameL.Parent = card

            card.MouseButton1Click:Connect(function()
                openAnimDetailView(fav.id, fav.name)
            end)

            makeHoverable(card, Colors.card, Colors.surfaceLight)
        end
    end

    do
        local childCount = #animFavorites
        local cols = math.max(1, math.floor(AnimFavGrid.AbsoluteSize.X / 66))

        local rows = math.ceil(childCount / cols)
        AnimFavGrid.Size = UDim2.new(1, 0, 0, rows * 88)
    end
    recalcAnimLayout()
end

-- ════════════════════════════════════════════════
-- DETAIL VIEW
-- ════════════════════════════════════════════════

openAnimDetailView = function(bundleId, bundleName)
    animDetailView = true
    animDetailBundleId = bundleId

    if AnimMainView then AnimMainView.Visible = false end
    if AnimDetailFrame then AnimDetailFrame.Visible = true end

    if AnimDetailSlotList then
        for _, child in pairs(AnimDetailSlotList:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
    end

    if AnimDetailThumb then
        AnimDetailThumb.Image = "rbxthumb://type=BundleThumbnail&id=" .. tostring(bundleId) .. "&w=150&h=150"
    end
    if AnimDetailName then AnimDetailName.Text = bundleName end
    if AnimDetailFavBtn then
        local isFav = isFavoriteAnim(bundleId)
        AnimDetailFavBtn.Text = isFav and "★ Favorited" or "☆ Favorite"
        AnimDetailFavBtn.BackgroundColor3 = isFav and Color3.fromRGB(60, 50, 10) or Colors.card
    end

    if AnimDetailStatus then
        AnimDetailStatus.Text = "Loading bundle..."
        AnimDetailStatus.Visible = true
    end

    if AnimDetailApplyAllBtn then AnimDetailApplyAllBtn.Visible = false end
    if AnimDetailApplySelBtn then AnimDetailApplySelBtn.Visible = false end

    task.spawn(function()
        local bundleData = unpackAnimationBundle(bundleId)
        if not bundleData or animDetailBundleId ~= bundleId then return end

        animDetailBundleData = bundleData
        animDetailSelected = {}

        if AnimDetailStatus then AnimDetailStatus.Visible = false end
        if AnimDetailApplyAllBtn then AnimDetailApplyAllBtn.Visible = true end
        if AnimDetailApplySelBtn then AnimDetailApplySelBtn.Visible = true end

        local order = 0
        for _, slotName in ipairs(ANIM_SLOTS) do
            local data = bundleData[slotName]
            if data then
                order = order + 1
                animDetailSelected[slotName] = true

                do
                    local row = Instance.new("Frame")
                    row.Name = "Slot_" .. slotName
                    row.Size = UDim2.new(1, 0, 0, 30)
                    row.BackgroundColor3 = Colors.card
                    row.BorderSizePixel = 0
                    row.LayoutOrder = order
                    row.Parent = AnimDetailSlotList
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

                    local check = Instance.new("TextButton")
                    check.Size = UDim2.new(0, 22, 0, 22)
                    check.Position = UDim2.new(0, 4, 0, 4)
                    check.BackgroundColor3 = Colors.green
                    check.Text = "✓"
                    check.TextColor3 = Colors.text
                    check.TextSize = 12
                    check.Font = Enum.Font.GothamBold
                    check.AutoButtonColor = false
                    check.Parent = row
                    Instance.new("UICorner", check).CornerRadius = UDim.new(0, 4)

                    check.MouseButton1Click:Connect(function()
                        animDetailSelected[slotName] = not animDetailSelected[slotName]
                        check.Text = animDetailSelected[slotName] and "✓" or ""
                        check.BackgroundColor3 = animDetailSelected[slotName] and Colors.green or Color3.fromRGB(40, 40, 45)
                    end)

                    local slotLabel = Instance.new("TextLabel")
                    slotLabel.Size = UDim2.new(0, 40, 1, 0)
                    slotLabel.Position = UDim2.new(0, 30, 0, 0)
                    slotLabel.BackgroundTransparency = 1
                    slotLabel.Text = ANIM_SLOT_LABELS[slotName]
                    slotLabel.TextColor3 = Colors.text
                    slotLabel.TextSize = 10
                    slotLabel.Font = Enum.Font.GothamBold
                    slotLabel.TextXAlignment = Enum.TextXAlignment.Left
                    slotLabel.Parent = row

                    local animName = Instance.new("TextLabel")
                    animName.Size = UDim2.new(1, -110, 1, 0)
                    animName.Position = UDim2.new(0, 72, 0, 0)
                    animName.BackgroundTransparency = 1
                    animName.Text = data.name
                    animName.TextColor3 = Colors.textDim
                    animName.TextSize = 9
                    animName.Font = Enum.Font.Gotham
                    animName.TextXAlignment = Enum.TextXAlignment.Left
                    animName.TextTruncate = Enum.TextTruncate.AtEnd
                    animName.Parent = row

                    local prevBtn = Instance.new("TextButton")
                    prevBtn.Size = UDim2.new(0, 28, 0, 22)
                    prevBtn.Position = UDim2.new(1, -32, 0, 4)
                    prevBtn.BackgroundColor3 = Colors.purple
                    prevBtn.Text = "▶"
                    prevBtn.TextColor3 = Colors.text
                    prevBtn.TextSize = 10
                    prevBtn.Font = Enum.Font.GothamBold
                    prevBtn.AutoButtonColor = false
                    prevBtn.Parent = row
                    Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0, 4)
                    makeHoverable(prevBtn, Colors.purple, Colors.purpleLight)

                    prevBtn.MouseButton1Click:Connect(function()
                        previewAnimation(data.id)
                    end)
                end
            end
        end

        if AnimDetailSlotList then
            AnimDetailSlotList.Size = UDim2.new(1, 0, 0, order * 34)
        end

        -- Posiciona botao Apply Selected abaixo da lista de slots
        if AnimDetailApplySelBtn then
            AnimDetailApplySelBtn.Position = UDim2.new(0, 0, 0, 134 + order * 34 + 8)
        end

        if AnimDetailScroll then
            AnimDetailScroll.CanvasSize = UDim2.new(0, 0, 0, 160 + order * 34 + 60)
        end
    end)
end

closeAnimDetailView = function()
    animDetailView = false
    animDetailBundleId = nil
    animDetailBundleData = nil
    animDetailSelected = nil
    if animPreviewTrack then
        pcall(function() animPreviewTrack:Stop() end)
        pcall(function() animPreviewTrack:Destroy() end)
        animPreviewTrack = nil
    end
    if AnimMainView then AnimMainView.Visible = true end
    if AnimDetailFrame then AnimDetailFrame.Visible = false end
end


--[[ ═══════ MODULE: 21_emote_shadow.luau ═══════ ]]

--==================================================
-- EMOTE LOGIC
--==================================================

-- Resolve animation ID (bundle → actual animation)
resolveAnimId = function(animId)
    local animIdStr = "rbxassetid://" .. tostring(animId)
    pcall(function()
        local objects = game:GetObjects(animIdStr)
        if objects and #objects > 0 then
            local obj = objects[1]
            if obj:IsA("Animation") then
                animIdStr = obj.AnimationId
            else
                for _, desc in ipairs(obj:GetDescendants()) do
                    if desc:IsA("Animation") then
                        animIdStr = desc.AnimationId
                        break
                    end
                end
            end
            pcall(function() obj:Destroy() end)
        end
    end)
    return animIdStr
end

-- Play emote on a specific character (returns track or nil)
playEmoteOnCharacter = function(char, animIdStr)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator", hum)
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animIdStr

    local ok, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)

    anim:Destroy()

    if ok and track then
        track.Priority = Enum.AnimationPriority.Action
        track:Play()
        track:AdjustSpeed(emoteSpeed)
        return track
    end
    return nil
end

-- Play emote on synced players
syncPlayEmote = function(animIdStr)
    -- Stop existing sync tracks
    for plr, trk in pairs(syncTracks) do
        pcall(function() trk:Stop() end)
        pcall(function() trk:Destroy() end)
    end
    syncTracks = {}

    -- Play on each synced player
    for plr, _ in pairs(syncPlayers) do
        if plr ~= LP and plr.Character then
            local trk = playEmoteOnCharacter(plr.Character, animIdStr)
            if trk then
                syncTracks[plr] = trk
            end
        end
    end
end

-- Stop all synced tracks
syncStopEmote = function()
    for plr, trk in pairs(syncTracks) do
        pcall(function() trk:Stop() end)
        pcall(function() trk:Destroy() end)
    end
    syncTracks = {}
end

-- Pause all synced tracks
syncPauseEmote = function()
    for plr, trk in pairs(syncTracks) do
        pcall(function() trk:AdjustSpeed(0) end)
    end
end

-- Resume all synced tracks
syncResumeEmote = function()
    for plr, trk in pairs(syncTracks) do
        pcall(function() trk:AdjustSpeed(emoteSpeed) end)
    end
end

-- Adjust speed on all synced tracks
syncAdjustSpeed = function(speed)
    for plr, trk in pairs(syncTracks) do
        pcall(function() trk:AdjustSpeed(speed) end)
    end
end

playEmote = function(animId)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then
        notify("No character", "error")
        return
    end

    -- Stop current emote
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop() end)
        pcall(function() currentEmoteTrack:Destroy() end)
        currentEmoteTrack = nil
    end

    local animIdStr = resolveAnimId(animId)
    currentEmoteAnimId = animId

    local track = playEmoteOnCharacter(char, animIdStr)

    if track then
        currentEmoteTrack = track
        emotePaused = false

        -- Sync to other players
        syncPlayEmote(animIdStr)

        local syncCount = 0
        for _ in pairs(syncTracks) do syncCount += 1 end
        local syncMsg = syncCount > 0 and (" + " .. syncCount .. " synced") or ""
        notify("Playing emote " .. emoteSpeed .. "x" .. syncMsg, "success")
        log("Emote playing:", animIdStr)
    else
        notify("Failed to load animation", "error")
    end
end

stopEmote = function()
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop() end)
        pcall(function() currentEmoteTrack:Destroy() end)
        currentEmoteTrack = nil
        emotePaused = false
    end
    syncStopEmote()
    currentEmoteAnimId = nil
    notify("Emote stopped", "info")
end

pauseEmote = function()
    if currentEmoteTrack and not emotePaused then
        pcall(function()
            currentEmoteTrack:AdjustSpeed(0)
        end)
        syncPauseEmote()
        emotePaused = true
        notify("Emote paused", "info")
    end
end

resumeEmote = function()
    if currentEmoteTrack and emotePaused then
        pcall(function()
            currentEmoteTrack:AdjustSpeed(emoteSpeed)
        end)
        syncResumeEmote()
        emotePaused = false
        notify("Emote resumed " .. emoteSpeed .. "x", "success")
    end
end

-- Populate sync player list UI
refreshSyncPlayerList = function(filter)
    -- Clear existing cards
    for _, child in SyncPlayerList:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local players = Players:GetPlayers()
    local count = 0
    local syncCount = 0

    for i, plr in ipairs(players) do
        if plr == LP then continue end

        local name = plr.DisplayName .. " (@" .. plr.Name .. ")"
        -- Filter by search
        if filter and filter ~= "" then
            local lowerFilter = filter:lower()
            if not plr.Name:lower():find(lowerFilter, 1, true)
                and not plr.DisplayName:lower():find(lowerFilter, 1, true) then
                continue
            end
        end

        count += 1
        local isChecked = syncPlayers[plr] ~= nil

        if isChecked then syncCount += 1 end

        local row = Instance.new("Frame")
        row.Name = "Player_" .. plr.Name
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = isChecked and Color3.fromRGB(20, 35, 20) or Colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = SyncPlayerList
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        -- Avatar thumbnail
        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(0, 26, 0, 26)
        thumb.Position = UDim2.new(0, 3, 0, 3)
        thumb.BackgroundColor3 = Colors.bg
        thumb.BorderSizePixel = 0
        thumb.Parent = row
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
        pcall(function()
            thumb.Image = Players:GetUserThumbnailAsync(
                plr.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size48x48
            )
        end)

        -- Name label
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -62, 1, 0)
        lbl.Position = UDim2.new(0, 32, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Colors.text
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        -- Checkbox button
        local check = Instance.new("TextButton")
        check.Name = "Check"
        check.Size = UDim2.new(0, 26, 0, 26)
        check.Position = UDim2.new(1, -29, 0, 3)
        check.BackgroundColor3 = isChecked and Colors.green or Color3.fromRGB(40, 40, 45)
        check.Text = isChecked and "✓" or ""
        check.TextColor3 = Colors.text
        check.TextSize = 14
        check.Font = Enum.Font.GothamBold
        check.AutoButtonColor = false
        check.Parent = row
        Instance.new("UICorner", check).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", check).Color = isChecked and Colors.greenLight or Colors.inputBorder

        -- Toggle handler
        check.MouseButton1Click:Connect(function()
            if syncPlayers[plr] then
                syncPlayers[plr] = nil
                -- Stop synced track for this player
                if syncTracks[plr] then
                    pcall(function() syncTracks[plr]:Stop() end)
                    pcall(function() syncTracks[plr]:Destroy() end)
                    syncTracks[plr] = nil
                end
                check.Text = ""
                check.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                check:FindFirstChildOfClass("UIStroke").Color = Colors.inputBorder
                row.BackgroundColor3 = Colors.card
            else
                syncPlayers[plr] = true
                check.Text = "✓"
                check.BackgroundColor3 = Colors.green
                check:FindFirstChildOfClass("UIStroke").Color = Colors.greenLight
                row.BackgroundColor3 = Color3.fromRGB(20, 35, 20)
                -- If emote is already playing, sync this player immediately
                if currentEmoteAnimId and currentEmoteTrack then
                    local animIdStr = resolveAnimId(currentEmoteAnimId)
                    local trk = playEmoteOnCharacter(plr.Character, animIdStr)
                    if trk then
                        syncTracks[plr] = trk
                        if emotePaused then
                            pcall(function() trk:AdjustSpeed(0) end)
                        end
                    end
                end
            end
            -- Update sync count
            local sc = 0
            for _ in pairs(syncPlayers) do sc += 1 end
            SyncCountLabel.Text = sc .. " player" .. (sc ~= 1 and "s" or "") .. " synced"
        end)
    end

    -- Update list height
    local rowH = 32
    local gap = 2
    local totalH = count > 0 and (count * rowH + (count - 1) * gap) or 0
    SyncPlayerList.Size = UDim2.new(1, 0, 0, totalH)

    -- Update count label
    local sc = 0
    for _ in pairs(syncPlayers) do sc += 1 end
    SyncCountLabel.Text = sc .. " player" .. (sc ~= 1 and "s" or "") .. " synced"

    -- Atualiza header do sync com contagem
    if updateSyncHeaderText then
        updateSyncHeaderText()
    end

    recalcEmoteLayout()
end

--==================================================
-- SHADOW LOGIC
--==================================================

startShadow = function(mode)
    if shadowConnection then
        shadowConnection:Disconnect()
        shadowConnection = nil
    end

    local target = shadowState.target
    if not target or not target.Character then
        notify("Select a shadow target first", "error")
        return
    end

    shadowState.active = true
    shadowState.mode = mode
    shadowHistory = {}
    refreshShadowModeButtons()

    -- Disable falling on local character
    local myChar = LP.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end

    -- Animation mirroring state (global so stopShadow can clean up)
    shadowMirroredTracks = {}
    local lastAnimSync = 0

    -- Apply trail if enabled
    if shadowState.trail then
        applyShadowTrail()
    end

    shadowConnection = RunService.Heartbeat:Connect(function()
        local targetChar = target.Character
        if not targetChar or not targetChar.Parent then
            stopShadow()
            notify("Shadow target left", "error")
            return
        end

        myChar = LP.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
        if not myHRP or not targetHRP then return end

        -- Prevent falling state + zero velocity (anti-flicker)
        myHum = myChar:FindFirstChildOfClass("Humanoid")
        if myHum and myHum:GetState() == Enum.HumanoidStateType.Freefall then
            myHum:ChangeState(Enum.HumanoidStateType.Physics)
        end
        pcall(function()
            myHRP.Velocity = Vector3.new(0, 0, 0)
            myHRP.RotVelocity = Vector3.new(0, 0, 0)
        end)

        local dist = shadowState.distance

        if shadowState.mode == "head" then
            -- Sit on head
            local head = targetChar:FindFirstChild("Head")
            if head then
                myHRP.CFrame = head.CFrame * CFrame.new(0, 1.8, 0)
            end

        elseif shadowState.mode == "orbit" then
            -- Angle-based orbit positioning
            local targetCF = targetHRP.CFrame
            local useCF = targetCF

            if shadowState.delay > 0 then
                -- Store history
                table.insert(shadowHistory, { time = tick(), cf = targetCF })

                -- Find position from delay seconds ago
                local targetTime = tick() - shadowState.delay
                local delayCF = nil
                local cleanIdx = 0
                for i = #shadowHistory, 1, -1 do
                    if shadowHistory[i].time <= targetTime then
                        delayCF = shadowHistory[i].cf
                        cleanIdx = i
                        break
                    end
                end

                -- Clean old entries (keep last 300 max)
                if cleanIdx > 1 then
                    for _ = 1, cleanIdx - 1 do
                        table.remove(shadowHistory, 1)
                    end
                elseif #shadowHistory > 300 then
                    table.remove(shadowHistory, 1)
                end

                useCF = delayCF or targetCF
            end

            local angleRad = math.rad(shadowState.angle)
            local offsetX = math.sin(angleRad) * dist
            local offsetZ = math.cos(angleRad) * dist
            local orbitCF = useCF * CFrame.new(offsetX, shadowState.height, offsetZ)

            if shadowState.faceTarget then
                myHRP.CFrame = CFrame.lookAt(orbitCF.Position, targetHRP.Position)
            else
                myHRP.CFrame = orbitCF
            end
        end

        -- Auto-orbit: increment angle over time
        if shadowState.autoOrbit and shadowState.mode == "orbit" then
            shadowState.angle = (shadowState.angle + shadowState.orbitSpeed * 0.5) % 360
        end

        -- Record target path if recording
        if shadowRecording and targetHRP then
            table.insert(shadowRecordedPath, { time = tick(), cf = targetHRP.CFrame })
            -- Limit recording to ~1800 frames (~30s at 60fps)
            if #shadowRecordedPath > 1800 then
                table.remove(shadowRecordedPath, 1)
            end
        end

        -- Mirror target animations (~every 0.3s) — only if enabled
        local now = tick()
        if shadowState.mirrorAnims and now - lastAnimSync > 0.3 then
            lastAnimSync = now
            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
            if myHum and targetHum then
                local myAnimator = myHum:FindFirstChildOfClass("Animator")
                local targetAnimator = targetHum:FindFirstChildOfClass("Animator")
                if myAnimator and targetAnimator then
                    pcall(function()
                        local targetTracks = targetAnimator:GetPlayingAnimationTracks()
                        local targetIds = {}
                        for _, t in ipairs(targetTracks) do
                            if t.Animation then
                                targetIds[t.Animation.AnimationId] = t.Priority
                            end
                        end
                        -- Stop tracks target isn't playing
                        for id, track in pairs(shadowMirroredTracks) do
                            if not targetIds[id] then
                                pcall(function() track:Stop() end)
                                pcall(function() track:Destroy() end)
                                shadowMirroredTracks[id] = nil
                            end
                        end
                        -- Play tracks target IS playing
                        for id, priority in pairs(targetIds) do
                            if not shadowMirroredTracks[id] then
                                local anim = Instance.new("Animation")
                                anim.AnimationId = id
                                local ok2, myTrack = pcall(function()
                                    return myAnimator:LoadAnimation(anim)
                                end)
                                if ok2 and myTrack then
                                    myTrack.Priority = priority
                                    myTrack:Play()
                                    shadowMirroredTracks[id] = myTrack
                                end
                                anim:Destroy()
                            end
                        end
                    end)
                end
            end
        end
    end)

    local modeLabel = mode == "head" and "head" or ("orbit " .. shadowState.angle .. "°")
    notify("Shadow: " .. modeLabel .. " on " .. target.Name, "success")
    log("Shadow started:", modeLabel, target.Name)
end

stopShadow = function()
    shadowState.active = false
    shadowState.autoOrbit = false
    if shadowConnection then
        shadowConnection:Disconnect()
        shadowConnection = nil
    end
    shadowHistory = {}

    -- Stop and destroy all mirrored animation tracks
    if shadowMirroredTracks then
        for id, track in pairs(shadowMirroredTracks) do
            pcall(function() track:Stop() end)
            pcall(function() track:Destroy() end)
        end
        shadowMirroredTracks = {}
    end

    refreshShadowModeButtons()

    -- Re-enable falling states + zero velocity + force idle restart
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- Zero velocity ANTES de reabilitar freefall (evita sair voando)
    if hrp then
        pcall(function()
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end)
    end

    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)

        -- Stop ALL playing animation tracks so Animate script restarts idle
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            pcall(function()
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
            end)
        end

        -- Reset Animate script to force idle restart
        local animScript = char:FindFirstChild("Animate")
        if animScript then
            pcall(function()
                animScript.Disabled = true
                task.delay(0.1, function()
                    if animScript and animScript.Parent then
                        animScript.Disabled = false
                    end
                end)
            end)
        end
    end

    -- Remove trail
    removeShadowTrail()

    notify("Shadow stopped", "info")
    log("Shadow stopped")
end

--==================================================
-- SHADOW TRAIL
--==================================================

applyShadowTrail = function()
    removeShadowTrail()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local att0 = Instance.new("Attachment")
    att0.Name = "VampTrailAtt0"
    att0.Position = Vector3.new(0, 0, 0.5)
    att0.Parent = hrp

    local att1 = Instance.new("Attachment")
    att1.Name = "VampTrailAtt1"
    att1.Position = Vector3.new(0, 0, -0.5)
    att1.Parent = hrp

    shadowTrailInstance = Instance.new("Trail")
    shadowTrailInstance.Name = "VampShadowTrail"
    shadowTrailInstance.Attachment0 = att0
    shadowTrailInstance.Attachment1 = att1
    shadowTrailInstance.Lifetime = 1.5
    shadowTrailInstance.MinLength = 0.1
    shadowTrailInstance.FaceCamera = true
    shadowTrailInstance.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Colors.glowPurple),
        ColorSequenceKeypoint.new(0.5, Colors.blood),
        ColorSequenceKeypoint.new(1, Colors.bloodDark),
    })
    shadowTrailInstance.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    })
    shadowTrailInstance.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    shadowTrailInstance.Parent = hrp
end

removeShadowTrail = function()
    if shadowTrailInstance then
        pcall(function() shadowTrailInstance:Destroy() end)
        shadowTrailInstance = nil
    end
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, att in ipairs(hrp:GetChildren()) do
                if att.Name == "VampTrailAtt0" or att.Name == "VampTrailAtt1" then
                    att:Destroy()
                end
            end
        end
    end
end

--==================================================
-- SHADOW RECORD & REPLAY
--==================================================

startShadowRecording = function()
    shadowRecordedPath = {}
    shadowRecording = true
    ShadowRecBtn.Text = "⏹ STOP"
    ShadowRecBtn.BackgroundColor3 = Colors.glowRed
    notify("Recording path...", "info")
end

stopShadowRecording = function()
    shadowRecording = false
    ShadowRecBtn.Text = "⏺ REC"
    ShadowRecBtn.BackgroundColor3 = Colors.blood
    notify("Path recorded (" .. #shadowRecordedPath .. " frames)", "success")
end

startShadowReplay = function()
    if #shadowRecordedPath == 0 then
        notify("No recorded path — hit REC first", "warning")
        return
    end

    -- Stop current shadow if active
    if shadowState.active then
        stopShadow()
    end

    shadowReplaying = true
    ShadowPlayReplayBtn.Text = "⏹ STOP"
    ShadowPlayReplayBtn.BackgroundColor3 = Colors.bloodDark

    -- Disable falling
    local myChar = LP.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end

    -- Apply trail if enabled
    if shadowState.trail then
        applyShadowTrail()
    end

    -- Calculate path duration from recorded timestamps
    local startTime = shadowRecordedPath[1].time
    local endTime = shadowRecordedPath[#shadowRecordedPath].time
    local duration = endTime - startTime

    shadowReplayConnection = RunService.Heartbeat:Connect(function()
        if not shadowReplaying then return end

        myChar = LP.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        -- Prevent falling
        myHum = myChar:FindFirstChildOfClass("Humanoid")
        if myHum and myHum:GetState() == Enum.HumanoidStateType.Freefall then
            myHum:ChangeState(Enum.HumanoidStateType.Physics)
        end

        -- Loop through recorded path using elapsed time
        local elapsed = (tick() - startTime) % duration
        local targetTime = startTime + elapsed

        -- Find closest frame
        local bestCF = shadowRecordedPath[1].cf
        for i = #shadowRecordedPath, 1, -1 do
            if shadowRecordedPath[i].time <= targetTime then
                bestCF = shadowRecordedPath[i].cf
                break
            end
        end

        myHRP.CFrame = bestCF
    end)

    notify("Replaying recorded path (loop)", "success")
end

stopShadowReplay = function()
    shadowReplaying = false
    if shadowReplayConnection then
        shadowReplayConnection:Disconnect()
        shadowReplayConnection = nil
    end
    ShadowPlayReplayBtn.Text = "▶ REPLAY"
    ShadowPlayReplayBtn.BackgroundColor3 = Colors.green

    -- Re-enable falling + restore idle
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    removeShadowTrail()
    notify("Replay stopped", "info")
end

--==================================================
-- TROLL FEATURES
--==================================================

flingPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then
        notify("No character found", "error")
        return
    end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP or not myHRP then
        notify("Missing HumanoidRootPart", "error")
        return
    end

    -- TP to target then apply massive velocity
    local savedCF = myHRP.CFrame
    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -2)

    task.delay(0.15, function()
        if not myChar or not myChar.Parent then return end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(math.random(-200, 200), 300, math.random(-200, 200))
        bv.Parent = targetHRP
        task.delay(0.3, function()
            pcall(function() bv:Destroy() end)
        end)

        -- TP back
        task.delay(0.5, function()
            if myHRP and myHRP.Parent then
                myHRP.CFrame = savedCF
            end
        end)
    end)

    notify("Fling: " .. player.DisplayName, "success")
end

headsitPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local head = targetChar:FindFirstChild("Head")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not head or not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    myHum.Sit = true
    myHum:ChangeState(Enum.HumanoidStateType.Seated)

    -- Força animação de sentar
    pcall(function()
        local animator = myHum:FindFirstChildOfClass("Animator")
        if not animator then animator = Instance.new("Animator", myHum) end
        local sitAnim = Instance.new("Animation")
        sitAnim.AnimationId = "rbxassetid://2506281703"
        trollSitTrack = animator:LoadAnimation(sitAnim)
        trollSitTrack.Priority = Enum.AnimationPriority.Action
        trollSitTrack.Looped = true
        trollSitTrack:Play()
    end)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("Head") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP then return end

        head = player.Character:FindFirstChild("Head")
        myHRP.CFrame = head.CFrame * CFrame.new(0, 2, 0)
        if myHum and not myHum.Sit then myHum.Sit = true end
    end)
    notify("Headsit: " .. player.DisplayName, "success")
end

--==================================================
-- MORE TROLLS
--==================================================

-- Salva posição antes de iniciar troll
trollSaveCFrame = function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        trollSavedCFrame = hrp.CFrame
    end
end

-- Zera velocity do HRP (chamar dentro do Heartbeat pra reduzir flicker)
trollZeroVelocity = function()
    pcall(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

stopTroll = function()
    if trollConnection then
        pcall(function()
            if typeof(trollConnection) == "RBXScriptConnection" then
                trollConnection:Disconnect()
            else
                task.cancel(trollConnection)
            end
        end)
        trollConnection = nil
    end
    -- Para animação de sit se estiver rodando
    if trollSitTrack then
        pcall(function() trollSitTrack:Stop() end)
        pcall(function() trollSitTrack:Destroy() end)
        trollSitTrack = nil
    end

    -- Limpa jail parts
    for _, p in ipairs(trollJailParts) do
        if p and p.Parent then p:Destroy() end
    end
    trollJailParts = {}

    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        hum.Sit = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)

        -- Restaurar posição salva (evita cair no void)
        if trollSavedCFrame and hrp then
            hrp.CFrame = trollSavedCFrame
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
        trollSavedCFrame = nil

        -- Stop all playing animation tracks
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            pcall(function()
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
            end)
        end

        -- Reset Animate script to force idle restart
        local animScript = char:FindFirstChild("Animate")
        if animScript then
            pcall(function()
                animScript.Disabled = true
                task.delay(0.1, function()
                    if animScript and animScript.Parent then
                        animScript.Disabled = false
                    end
                end)
            end)
        end

    end
end

-- Auto velocity zero — roda sempre, zera velocity quando troll ativo
-- Reduz flicker pra outros clients (menos rubber-banding)
RunService.Heartbeat:Connect(function()
    if trollConnection then
        trollZeroVelocity()
    end
end)

bangPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not targetHRP or not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 1
        -- Pump motion por TRÁS do alvo
        local offset = math.sin(t * 0.3 * trollSpeedMul) * 1.5
        local behindCF = targetHRP.CFrame * CFrame.new(0, 0, 2 + offset)
        myHRP.CFrame = CFrame.lookAt(behindCF.Position, targetHRP.Position)
    end)
    notify("Bang: " .. player.DisplayName, "success")
end

--==================================================
-- BANG 2 — pela frente, cintura na cabeça
--==================================================

bangFrontPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not targetHRP or not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 1
        -- Pump na frente, levantado (cintura na altura da cabeça)
        local offset = math.sin(t * 0.3 * trollSpeedMul) * 1.5
        local frontCF = targetHRP.CFrame * CFrame.new(0, 1.8, -2 - offset)
        myHRP.CFrame = CFrame.lookAt(frontCF.Position, targetHRP.Position)
    end)
    notify("Bang 2: " .. player.DisplayName, "success")
end

orbitTrollPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local angle = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        angle = (angle + 15 * trollSpeedMul) % 360
        local rad = math.rad(angle)
        local pos = targetHRP.CFrame * CFrame.new(math.sin(rad) * 3, 0, math.cos(rad) * 3)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Orbit troll: " .. player.DisplayName, "success")
end

backpackPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 1.5, 1)
    end)
    notify("Backpack: " .. player.DisplayName, "success")
end

flingAllPlayers = function()
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local savedCF = myHRP.CFrame
    local count = 0

    task.spawn(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -2)
                    task.wait(0.15)
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(math.random(-200, 200), 300, math.random(-200, 200))
                    bv.Parent = targetHRP
                    task.delay(0.3, function()
                        pcall(function() bv:Destroy() end)
                    end)
                    count = count + 1
                    task.wait(0.3)
                end
            end
        end
        task.wait(0.2)
        if myHRP and myHRP.Parent then
            myHRP.CFrame = savedCF
        end
        notify("Flung " .. count .. " players!", "success")
    end)
end

--==================================================
-- HELICOPTER TROLL — deita duro e gira na cabeça
--==================================================

helicopterPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local head = targetChar:FindFirstChild("Head")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not head or not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local angle = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("Head") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        head = player.Character:FindFirstChild("Head")
        angle = (angle + 16 * trollSpeedMul) % 360
        -- Deitado duro (Z=90°) + girando rápido (Y) na cabeça
        myHRP.CFrame = head.CFrame
            * CFrame.new(0, 2.5, 0)
            * CFrame.Angles(math.rad(90), math.rad(angle), 0)
    end)
    notify("Helicopter: " .. player.DisplayName, "success")
end

--==================================================
-- SPIN TOP — gira em pé na cabeça do alvo
--==================================================

spinTopPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local head = targetChar:FindFirstChild("Head")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not head or not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local angle = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("Head") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        head = player.Character:FindFirstChild("Head")
        angle = (angle + 20 * trollSpeedMul) % 360
        -- Em pé girando rápido tipo pião
        myHRP.CFrame = head.CFrame
            * CFrame.new(0, 2, 0)
            * CFrame.Angles(0, math.rad(angle), 0)
    end)
    notify("Spin top: " .. player.DisplayName, "success")
end

--==================================================
-- TRAMPOLINE — pula em cima do alvo
--==================================================

trampolinePlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 1
        -- Pula e desce, loop infinito
        local bounce = math.abs(math.sin(t * 0.08 * trollSpeedMul)) * 5
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 3 + bounce, 0)
    end)
    notify("Trampoline: " .. player.DisplayName, "success")
end

--==================================================
-- CREEP — se aproxima lentamente por trás
--==================================================

creepPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local dist = 20
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        -- Vai se aproximando devagar por trás
        dist = math.max(dist - 0.03 * trollSpeedMul, 1.5)
        local behindCF = targetHRP.CFrame * CFrame.new(0, 0, dist)
        myHRP.CFrame = CFrame.lookAt(behindCF.Position, targetHRP.Position)
    end)
    notify("Creeping on " .. player.DisplayName .. "...", "success")
end

--==================================================
-- LAUNCH — manda o alvo pro céu repetidamente
--==================================================

launchPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local savedCF = myHRP.CFrame

    trollConnection = task.spawn(function()
        while true do
            if not player.Character then break end
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then break end

            myChar = LP.Character
            myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then break end

            -- TP pra perto e aplica velocity pra cima
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -2)
            task.wait(0.15)
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 500, 0)
            bv.Parent = targetHRP
            task.delay(0.2, function()
                pcall(function() bv:Destroy() end)
            end)
            -- Volta pra posição original
            task.wait(0.3)
            if myHRP and myHRP.Parent then
                myHRP.CFrame = savedCF
            end
            task.wait(2 / trollSpeedMul)
        end
    end)
    notify("Launching: " .. player.DisplayName, "success")
end

--==================================================
-- CARPET — deita no chão embaixo do alvo
--==================================================

carpetPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        -- Deitado embaixo dos pés do alvo (tapete humano)
        myHRP.CFrame = targetHRP.CFrame
            * CFrame.new(0, -2.5, 0)
            * CFrame.Angles(math.rad(90), 0, 0)
    end)
    notify("Carpet: " .. player.DisplayName, "success")
end

--==================================================
-- DIZZY — orbita super rápido e perto
--==================================================

dizzyPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local angle = 0
    local yBob = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        -- Orbita SUPER rápido e colado (raio 1.5)
        angle = (angle + 30 * trollSpeedMul) % 360
        yBob = yBob + 0.15 * trollSpeedMul
        local rad = math.rad(angle)
        local yOffset = math.sin(yBob) * 1.5
        local pos = targetHRP.CFrame * CFrame.new(math.sin(rad) * 1.5, yOffset, math.cos(rad) * 1.5)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Dizzy: " .. player.DisplayName, "success")
end

--==================================================
-- REMOTE SPY FUNCTIONS
--==================================================

scanRemotes = function()
    scannedRemotes = {}
    local seen = {}

    local function addRemote(obj, src)
        local ok2, path = pcall(function() return obj:GetFullName() end)
        if not ok2 then path = src .. "." .. tostring(obj) end
        if seen[path] then return end
        seen[path] = true
        local prefix = ""
        if src == "nil" then prefix = "👻 "
        elseif src == "gc" then prefix = "🗑 " end
        table.insert(scannedRemotes, {
            instance = obj,
            name = prefix .. obj.Name,
            path = path,
            class = obj.ClassName,
            source = src,
        })
    end

    -- 1. Descendants normais
    pcall(function()
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                addRemote(obj, "tree")
            end
        end
    end)

    -- 2. Nil instances (remotes escondidos sem parent)
    local _env = (typeof(getgenv) == "function" and getgenv()) or {}
    local _getNil = getnilinstances or _env.getnilinstances
    if _getNil then
        pcall(function()
            for _, obj in pairs(_getNil()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                    or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                    addRemote(obj, "nil")
                end
            end
        end)
    end

    -- 3. Garbage collector (referências vazadas)
    local _getGC = getgc or _env.getgc
    if _getGC then
        pcall(function()
            for _, v in pairs(_getGC(true)) do
                if typeof(v) == "Instance" then
                    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                        addRemote(v, "gc")
                    end
                end
            end
        end)
    end

    table.sort(scannedRemotes, function(a, b) return a.name < b.name end)
    log("Deep scanned remotes:", #scannedRemotes)
end

--==================================================
-- SERIALIZE ARG — converte valor Lua em codigo copiavel
--==================================================

serializeArg = function(value)
    local t = typeof(value)
    if t == "string" then
        return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif t == "number" then
        return tostring(value)
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "nil" then
        return "nil"
    elseif t == "Instance" then
        return "game." .. value:GetFullName()
    elseif t == "Vector3" then
        return string.format("Vector3.new(%s, %s, %s)", value.X, value.Y, value.Z)
    elseif t == "CFrame" then
        local c = {value:GetComponents()}
        return "CFrame.new(" .. table.concat(c, ", ") .. ")"
    elseif t == "Color3" then
        return string.format("Color3.new(%s, %s, %s)", value.R, value.G, value.B)
    elseif t == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    elseif t == "EnumItem" then
        return tostring(value)
    elseif t == "table" then
        local parts = {}
        for k, v in pairs(value) do
            if type(k) == "number" then
                table.insert(parts, serializeArg(v))
            else
                table.insert(parts, "[" .. serializeArg(k) .. "] = " .. serializeArg(v))
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return "nil --[[ " .. t .. ": " .. tostring(value) .. " ]]"
    end
end

--==================================================
-- COPY LOG ENTRY — gera script e copia pro clipboard
--==================================================

copyLogEntry = function(entry)
    local argParts = {}
    for _, arg in ipairs(entry.args) do
        pcall(function()
            table.insert(argParts, serializeArg(arg))
        end)
    end
    local argsStr = table.concat(argParts, ", ")

    local script = ""
    -- Comentario com caller se disponivel
    if entry.caller and entry.caller ~= "" then
        script = script .. "-- Caller: " .. entry.caller .. "\n"
    end
    -- Comentario com return se disponivel
    if entry.returnValue then
        script = script .. "-- Return: " .. entry.returnValue .. "\n"
    end
    -- Comando principal
    script = script .. "game." .. entry.path .. ":" .. entry.method .. "(" .. argsStr .. ")"

    pcall(function()
        if setclipboard then
            setclipboard(script)
        elseif toclipboard then
            toclipboard(script)
        end
    end)

    -- Auto-fill args box para re-fire rápido
    pcall(function() RemoteSpyArgsBox.Text = argsStr end)

    -- Auto-select o remote se existe nos scannedRemotes
    pcall(function()
        for _, data in ipairs(scannedRemotes) do
            if data.path == entry.path then
                selectedFireRemote = data
                RemoteSpySelectedLabel.Text = "Selected: " .. data.class:sub(7, 7) .. " " .. data.name
                RemoteSpySelectedLabel.TextColor3 = Color3.fromRGB(100, 220, 200)
                break
            end
        end
    end)

    notify("Copied + auto-selected!", "success")
    log("Copied script:", script:sub(1, 100))
end

--==================================================
-- EXPORT SPY LOG — copia log inteiro pro clipboard
--==================================================

exportSpyLog = function()
    if #remoteSpyLog == 0 then
        notify("Spy log is empty", "warning")
        return
    end

    local lines = {}
    table.insert(lines, "-- Remote Spy Log Export")
    table.insert(lines, "-- " .. #remoteSpyLog .. " entries")
    table.insert(lines, "")

    for idx, entry in ipairs(remoteSpyLog) do
        local secs = math.floor(entry.time % 60)
        local mins = math.floor((entry.time / 60) % 60)
        local hrs = math.floor((entry.time / 3600) % 24)
        local timeStr = string.format("%02d:%02d:%02d", hrs, mins, secs)

        local argParts = {}
        for _, arg in ipairs(entry.args) do
            pcall(function()
                table.insert(argParts, serializeArg(arg))
            end)
        end
        local argsStr = table.concat(argParts, ", ")

        local line = "-- [" .. timeStr .. "]"
        if entry.caller and entry.caller ~= "" then
            line = line .. " from " .. entry.caller
        end
        table.insert(lines, line)
        local cmd = "game." .. entry.path .. ":" .. entry.method .. "(" .. argsStr .. ")"
        if entry.returnValue then
            cmd = cmd .. " -- → " .. entry.returnValue
        end
        table.insert(lines, cmd)
        table.insert(lines, "")
    end

    local fullText = table.concat(lines, "\n")
    pcall(function()
        if setclipboard then
            setclipboard(fullText)
        elseif toclipboard then
            toclipboard(fullText)
        end
    end)
    notify("Exported " .. #remoteSpyLog .. " entries to clipboard!", "success")
end

--==================================================
-- SPY HOOK — com block, call counter, caller, return logger
--==================================================

startRemoteSpy = function()
    if remoteSpyActive then return end

    remoteSpyActive = true
    remoteSpyLog = {}

    -- So instala hook uma vez (evita double-hook)
    if not remoteSpyHook then
        -- Resolve funções do executor (direto ou via getgenv)
        local _env = (typeof(getgenv) == "function" and getgenv()) or {}
        local _hookMeta = hookmetamethod or _env.hookmetamethod
        local _getMethod = getnamecallmethod or _env.getnamecallmethod
        local _wrap = newcclosure or clonefunction or _env.newcclosure or _env.clonefunction
        local _getRawMT = getrawmetatable or _env.getrawmetatable
        local _setReadonly = setreadonly or _env.setreadonly
        local _hookFn = hookfunction or _env.hookfunction
        local _getCaller = getcallingscript or _env.getcallingscript

        local hookOk = false
        local hookStrategy = "none"

        -- Debug: mostra funções disponíveis
        local dbg = "Executor: "
        if _hookMeta then dbg = dbg .. "hookMeta ✓ " else dbg = dbg .. "hookMeta ✗ " end
        if _getMethod then dbg = dbg .. "getMeth ✓ " else dbg = dbg .. "getMeth ✗ " end
        if _hookFn then dbg = dbg .. "hookFn ✓ " else dbg = dbg .. "hookFn ✗ " end
        if _getRawMT then dbg = dbg .. "rawMT ✓ " else dbg = dbg .. "rawMT ✗ " end
        if _wrap then dbg = dbg .. "wrap ✓" else dbg = dbg .. "wrap ✗" end
        notify(dbg, "info")

        -- ═══ Estratégia A: __namecall hook (precisa de getnamecallmethod) ═══
        if _getMethod then
            local function spyHookFn(self, ...)
                local method = _getMethod()
                if method == "FireServer" or method == "InvokeServer" then
                    local isRemote = false
                    pcall(function()
                        isRemote = self:IsA("RemoteEvent") or self:IsA("RemoteFunction")
                    end)
                    if isRemote then
                        local remotePath = "?"
                        pcall(function() remotePath = self:GetFullName() end)
                        remoteCallCounts[remotePath] = (remoteCallCounts[remotePath] or 0) + 1
                        if blockedRemotes[remotePath] then return nil end
                        if remoteSpyActive then
                            local caller = ""
                            pcall(function()
                                if _getCaller then
                                    local cs = _getCaller()
                                    if cs then caller = cs:GetFullName() end
                                end
                            end)
                            local entry = {
                                time = os.clock(), name = "?", path = remotePath,
                                method = method, args = {...}, caller = caller, returnValue = nil,
                            }
                            pcall(function() entry.name = self.Name end)
                            local result = remoteSpyHook(self, ...)
                            if method == "InvokeServer" then
                                pcall(function() entry.returnValue = tostring(result) end)
                            end
                            table.insert(remoteSpyLog, entry)
                            if #remoteSpyLog > 200 then table.remove(remoteSpyLog, 1) end
                            pcall(function() refreshRemoteSpyLog() end)
                            return result
                        end
                    end
                end
                return remoteSpyHook(self, ...)
            end

            local wrappedHook = spyHookFn
            if _wrap then pcall(function() wrappedHook = _wrap(spyHookFn) end) end

            -- Metodo 1: hookmetamethod (preferido)
            if _hookMeta then
                pcall(function()
                    remoteSpyHook = _hookMeta(game, "__namecall", wrappedHook)
                    if remoteSpyHook then hookOk = true end
                end)
            end

            -- Metodo 2: getrawmetatable + setreadonly
            if not hookOk and _getRawMT then
                pcall(function()
                    local mt = _getRawMT(game)
                    local oldNamecall = mt.__namecall
                    remoteSpyHook = oldNamecall
                    if _setReadonly then _setReadonly(mt, false) end
                    mt.__namecall = wrappedHook
                    if _setReadonly then _setReadonly(mt, true) end
                    hookOk = true
                end)
            end

            -- Metodo 3: hookfunction no __namecall
            if not hookOk and _hookFn and _getRawMT then
                pcall(function()
                    local mt = _getRawMT(game)
                    if mt and mt.__namecall then
                        remoteSpyHook = _hookFn(mt.__namecall, wrappedHook)
                        hookOk = true
                    end
                end)
            end
        end

        -- ═══ Estratégia B: hookmetamethod __namecall SEM getnamecallmethod (Xeno) ═══
        if not hookOk and _hookMeta then
            pcall(function()
                local inHook = false
                local orig
                orig = _hookMeta(game, "__namecall", function(self, ...)
                    if inHook then return orig(self, ...) end
                    inHook = true
                    local isRE, isRF = false, false
                    pcall(function()
                        isRE = self:IsA("RemoteEvent")
                        if not isRE then isRF = self:IsA("RemoteFunction") end
                    end)
                    if isRE or isRF then
                        local method = isRE and "FireServer" or "InvokeServer"
                        local remotePath = "?"
                        pcall(function() remotePath = self:GetFullName() end)
                        remoteCallCounts[remotePath] = (remoteCallCounts[remotePath] or 0) + 1
                        if blockedRemotes[remotePath] then inHook = false return nil end
                        if remoteSpyActive then
                            local caller = ""
                            pcall(function()
                                if _getCaller then local cs = _getCaller() if cs then caller = cs:GetFullName() end end
                            end)
                            local entry = {
                                time = os.clock(), name = "?", path = remotePath,
                                method = method, args = {...}, caller = caller, returnValue = nil,
                            }
                            pcall(function() entry.name = self.Name end)
                            local result = orig(self, ...)
                            if isRF then pcall(function() entry.returnValue = tostring(result) end) end
                            table.insert(remoteSpyLog, entry)
                            if #remoteSpyLog > 200 then table.remove(remoteSpyLog, 1) end
                            pcall(function() refreshRemoteSpyLog() end)
                            inHook = false
                            return result
                        end
                    end
                    inHook = false
                    return orig(self, ...)
                end)
                if orig then
                    remoteSpyHook = orig
                    hookOk = true
                end
            end)
        end

        -- ═══ Estratégia C: Hook direto FireServer/InvokeServer (fallback) ═══
        if not hookOk and _hookFn then
            pcall(function()
                local tmpRE = Instance.new("RemoteEvent")
                local tmpRF = Instance.new("RemoteFunction")
                local origFire = tmpRE.FireServer
                local origInvoke = tmpRF.InvokeServer
                tmpRE:Destroy()
                tmpRF:Destroy()

                -- Refs mutáveis — hookfunction retorna o original real
                local realFire, realInvoke

                local function fireSpyHook(self, ...)
                    local remotePath = "?"
                    pcall(function() remotePath = self:GetFullName() end)
                    remoteCallCounts[remotePath] = (remoteCallCounts[remotePath] or 0) + 1
                    if blockedRemotes[remotePath] then return nil end
                    if remoteSpyActive then
                        local caller = ""
                        pcall(function()
                            if _getCaller then local cs = _getCaller() if cs then caller = cs:GetFullName() end end
                        end)
                        local entry = {
                            time = os.clock(), name = "?", path = remotePath,
                            method = "FireServer", args = {...}, caller = caller, returnValue = nil,
                        }
                        pcall(function() entry.name = self.Name end)
                        table.insert(remoteSpyLog, entry)
                        if #remoteSpyLog > 200 then table.remove(remoteSpyLog, 1) end
                        pcall(function() refreshRemoteSpyLog() end)
                    end
                    return realFire(self, ...)
                end

                local function invokeSpyHook(self, ...)
                    local remotePath = "?"
                    pcall(function() remotePath = self:GetFullName() end)
                    remoteCallCounts[remotePath] = (remoteCallCounts[remotePath] or 0) + 1
                    if blockedRemotes[remotePath] then return nil end
                    if remoteSpyActive then
                        local caller = ""
                        pcall(function()
                            if _getCaller then local cs = _getCaller() if cs then caller = cs:GetFullName() end end
                        end)
                        local entry = {
                            time = os.clock(), name = "?", path = remotePath,
                            method = "InvokeServer", args = {...}, caller = caller, returnValue = nil,
                        }
                        pcall(function() entry.name = self.Name end)
                        local result = realInvoke(self, ...)
                        pcall(function() entry.returnValue = tostring(result) end)
                        table.insert(remoteSpyLog, entry)
                        if #remoteSpyLog > 200 then table.remove(remoteSpyLog, 1) end
                        pcall(function() refreshRemoteSpyLog() end)
                        return result
                    end
                    return realInvoke(self, ...)
                end

                local wFire = fireSpyHook
                local wInvoke = invokeSpyHook
                if _wrap then
                    pcall(function() wFire = _wrap(fireSpyHook) end)
                    pcall(function() wInvoke = _wrap(invokeSpyHook) end)
                end

                realFire = _hookFn(origFire, wFire)
                realInvoke = _hookFn(origInvoke, wInvoke)
                remoteSpyHook = true -- marca que hook foi instalado
                hookOk = true
            end)
        end

        if not hookOk then
            remoteSpyHook = nil
            remoteSpyActive = false
            notify("Hook failed — executor not supported", "error")
            return false
        end

        -- Notifica qual estratégia funcionou
        if hookOk then
            if _getMethod and remoteSpyHook and typeof(remoteSpyHook) == "function" then
                hookStrategy = "A (__namecall + getMethod)"
            elseif remoteSpyHook == true then
                hookStrategy = "C (direct hookFn)"
            else
                hookStrategy = "B (__namecall sem getMethod)"
            end
            notify("Hook: " .. hookStrategy, "success")
        end
    end

    notify("Remote Spy ON — logging calls", "success")
    RemoteSpyStatusLabel.Text = "Spy: ON (logging...)"
    RemoteSpyStatusLabel.TextColor3 = Color3.fromRGB(100, 220, 200)
    RemoteSpyToggleBtn.Text = "⏹ STOP SPY"
    RemoteSpyToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 30)
    return true
end

stopRemoteSpy = function()
    remoteSpyActive = false
    RemoteSpyStatusLabel.Text = "Spy: OFF (hook active)"
    RemoteSpyStatusLabel.TextColor3 = Colors.textDim
    RemoteSpyToggleBtn.Text = "🕵 START SPY"
    RemoteSpyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 70)
    notify("Remote Spy OFF", "info")
end

--==================================================
-- PARSE FIRE ARGS
--==================================================

parseFireArgs = function(text)
    if not text or text == "" then return {} end
    local fn, err = loadstring("return {" .. text .. "}")
    if fn then
        local ok, result = pcall(fn)
        if ok and type(result) == "table" then
            return result
        end
    end
    notify("Args parse error — sending as string", "warning")
    return { text }
end

fireTestRemote = function(remote, customArgs)
    if not remote or not remote.Parent then
        notify("Remote no longer exists", "error")
        return
    end
    local remoteName = remote.Name
    local remotePath = pcall(function() return remote:GetFullName() end) and remote:GetFullName() or remoteName
    local args = customArgs or {}
    local argCount = #args

    log("Test fire:", remotePath, "args:", argCount)

    task.spawn(function()
        local ok, err = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(args))
                notify("Fired: " .. remoteName .. " (" .. argCount .. " args)", "success")
            elseif remote:IsA("RemoteFunction") then
                notify("Invoking: " .. remoteName .. "...", "info")
                local result = remote:InvokeServer(unpack(args))
                notify("Invoked: " .. remoteName .. " → " .. tostring(result), "success")
            end
        end)
        if not ok then
            notify("Fire error: " .. tostring(err):sub(1, 60), "error")
        end
    end)
end

--==================================================
-- AUTO-REPEAT — repete fire no remote selecionado
--==================================================

startAutoRepeat = function(interval, count)
    if not selectedFireRemote then
        notify("Select a remote first (🎯)", "warning")
        return
    end
    if autoRepeatActive then
        notify("Already repeating", "warning")
        return
    end

    autoRepeatActive = true
    local remote = selectedFireRemote.instance
    local args = parseFireArgs(RemoteSpyArgsBox.Text)
    local remoteName = selectedFireRemote.name

    RemoteSpyRepeatBtn.Text = "⏹ STOP"
    RemoteSpyRepeatBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)

    task.spawn(function()
        local fired = 0
        while autoRepeatActive and (count == 0 or fired < count) do
            if not remote or not remote.Parent then
                notify("Remote gone, stopping", "error")
                break
            end
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(unpack(args))
                else
                    remote:InvokeServer(unpack(args))
                end
            end)
            fired = fired + 1
            task.wait(interval)
        end
        autoRepeatActive = false
        RemoteSpyRepeatBtn.Text = "▶ REPEAT"
        RemoteSpyRepeatBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
        notify("Repeat done: " .. fired .. "x " .. remoteName, "info")
    end)
end

stopAutoRepeat = function()
    autoRepeatActive = false
end

--==================================================
-- VULNERABILITY SCAN
--==================================================

vulnScanRemotes = function()
    if #scannedRemotes == 0 then
        scanRemotes()
    end
    local vulnCount = 0
    local tested = 0
    local pending = 0

    for _, data in ipairs(scannedRemotes) do
        local remote = data.instance
        if not remote or not remote.Parent then
            data.vuln = "gone"
        else
            tested = tested + 1
            if remote:IsA("RemoteEvent") then
                local ok = pcall(function()
                    remote:FireServer()
                end)
                data.vuln = ok and "vuln" or "safe"
                if ok then vulnCount = vulnCount + 1 end
            else
                data.vuln = "testing"
                pending = pending + 1
                task.spawn(function()
                    local ok = pcall(function()
                        remote:InvokeServer()
                    end)
                    if data.vuln == "testing" then
                        data.vuln = ok and "vuln" or "safe"
                        if ok then vulnCount = vulnCount + 1 end
                    end
                    pending = pending - 1
                end)
            end
        end
    end

    local deadline = os.clock() + 3
    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end

    for _, data in ipairs(scannedRemotes) do
        if data.vuln == "testing" then
            data.vuln = "timeout"
        end
    end

    refreshRemoteList(RemoteSpyFilterBox.Text)
    local msg = "Vuln scan: " .. vulnCount .. " vuln / " .. tested .. " tested"
    if pending > 0 then
        msg = msg .. " (" .. pending .. " timeout)"
    end
    notify(msg, vulnCount > 0 and "error" or "success")
    RemoteSpyStatsLabel.Text = msg
end

--==================================================
-- MASS FIRE
--==================================================

massFireRemotes = function()
    if #scannedRemotes == 0 then
        notify("Scan remotes first", "error")
        return
    end
    local fired = 0
    for _, data in ipairs(scannedRemotes) do
        local remote = data.instance
        if remote and remote.Parent and not blockedRemotes[data.path] then
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer()
                end
            end)
            fired = fired + 1
        end
    end
    notify("Mass fire: " .. fired .. " remotes fired", "success")
end

--==================================================
-- FUZZ REMOTE — testa 18 padrões de args automaticamente
--==================================================

fuzzRemote = function()
    if not selectedFireRemote then
        notify("Select a remote first (🎯)", "warning")
        return
    end
    local remote = selectedFireRemote.instance
    if not remote or not remote.Parent then
        notify("Remote no longer exists", "error")
        return
    end

    local remoteName = selectedFireRemote.name
    notify("🧪 Fuzzing: " .. remoteName .. "...", "info")

    local LP2 = game.Players.LocalPlayer
    local patterns = {
        { "empty",      {} },
        { "true",       {true} },
        { "false",      {false} },
        { "0",          {0} },
        { "1",          {1} },
        { "-1",         {-1} },
        { "huge",       {math.huge} },
        { "999999999",  {999999999} },
        { "string",     {"test"} },
        { "empty str",  {""} },
        { "player",     {LP2} },
        { "name",       {LP2.Name} },
        { "userId",     {LP2.UserId} },
        { "workspace",  {workspace} },
        { "empty tbl",  {{}} },
        { "kv tbl",     {{Action = "test"}} },
        { "multi str",  {"admin", true, 999} },
        { "char",       {LP2.Character} },
    }

    local isEvent = remote:IsA("RemoteEvent")

    task.spawn(function()
        local results = {}
        local okCount = 0
        for _, p in ipairs(patterns) do
            local label, args = p[1], p[2]
            local ok, err
            local ret = nil
            ok, err = pcall(function()
                if isEvent then
                    remote:FireServer(unpack(args))
                else
                    ret = remote:InvokeServer(unpack(args))
                end
            end)

            local icon = ok and "✅" or "❌"
            if ok then okCount = okCount + 1 end
            local detail = ""
            if ok and not isEvent and ret ~= nil then
                detail = " → " .. tostring(ret):sub(1, 50)
            elseif not ok then
                detail = " → " .. tostring(err):sub(1, 50)
            end
            table.insert(results, icon .. " " .. label .. detail)
            task.wait(0.15)
        end

        -- Copia resultados pro clipboard
        local lines = {
            "-- ═══ Fuzz Results ═══",
            "-- Remote: " .. remoteName,
            "-- Type: " .. (isEvent and "RemoteEvent" or "RemoteFunction"),
            "-- Accepted: " .. okCount .. "/" .. #results,
            "",
        }
        for _, r in ipairs(results) do
            table.insert(lines, "-- " .. r)
        end
        local text = table.concat(lines, "\n")
        pcall(function()
            if setclipboard then setclipboard(text)
            elseif toclipboard then toclipboard(text) end
        end)

        notify("Fuzz: " .. okCount .. "/" .. #results .. " accepted — copied!", okCount > 0 and "success" or "warning")
    end)
end

--==================================================
-- DECOMPILE FOR REMOTE — acha uso do remote nos scripts
--==================================================

decompileForRemote = function()
    if not selectedFireRemote then
        notify("Select a remote first (🎯)", "warning")
        return
    end
    local remoteName = selectedFireRemote.name:gsub("👻 ", ""):gsub("🗑 ", "")

    local _env = (typeof(getgenv) == "function" and getgenv()) or {}
    local _decompile = decompile or _env.decompile
    if not _decompile then
        notify("decompile() not available", "error")
        return
    end

    notify("📜 Decompiling for: " .. remoteName .. "...", "info")

    -- Abre painel com status "buscando..."
    DecompileStatusLabel.Text = "Searching " .. remoteName .. "..."
    DecompileStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
    DecompileTitle.Text = "📜 Decompile: " .. remoteName
    for _, c in pairs(DecompileCodeScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    DecompilePanel.Visible = true

    task.spawn(function()
        -- Prioriza scripts que contem o nome do remote no Name ou FullName
        local priority = {}
        local others = {}
        pcall(function()
            for _, obj in pairs(game:GetDescendants()) do
                if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local name = ""
                    pcall(function() name = obj:GetFullName() end)
                    if name:find(remoteName, 1, true) or obj.Name:find(remoteName, 1, true) then
                        table.insert(priority, obj)
                    else
                        table.insert(others, obj)
                    end
                end
            end
        end)

        -- Junta: primeiro os prioritários, depois o resto (max 300)
        local scripts = {}
        for _, s in ipairs(priority) do table.insert(scripts, s) end
        local cap = 300 - #priority
        for i = 1, math.min(cap, #others) do table.insert(scripts, others[i]) end

        local found = {}
        local checked = 0
        local deadline = os.clock() + 60 -- timeout global 60s
        for _, scr in ipairs(scripts) do
            if os.clock() > deadline then break end
            checked = checked + 1
            local ok = pcall(function()
                local source = _decompile(scr)
                if source and source:find(remoteName, 1, true) then
                    -- Coleta todas as linhas primeiro
                    local allLines = {}
                    for line in source:gmatch("[^\n]+") do
                        table.insert(allLines, line)
                        if #allLines > 5000 then break end
                    end
                    -- Acha matches com 2 linhas de contexto antes/depois
                    local context = {}
                    local added = {}
                    for i, line in ipairs(allLines) do
                        if line:find(remoteName, 1, true) then
                            -- 2 linhas antes
                            for c = math.max(1, i - 2), i - 1 do
                                if not added[c] then
                                    added[c] = true
                                    table.insert(context, "  L" .. c .. ": " .. allLines[c]:sub(1, 120))
                                end
                            end
                            -- Linha do match (highlight)
                            if not added[i] then
                                added[i] = true
                                table.insert(context, "▶ L" .. i .. ": " .. line:sub(1, 120))
                            end
                            -- 2 linhas depois
                            for c = i + 1, math.min(#allLines, i + 2) do
                                if not added[c] then
                                    added[c] = true
                                    table.insert(context, "  L" .. c .. ": " .. allLines[c]:sub(1, 120))
                                end
                            end
                        end
                    end
                    if #context > 0 then
                        table.insert(found, {
                            script = scr:GetFullName(),
                            lines = context,
                        })
                    end
                end
            end)
            if #found >= 15 then break end
            if checked % 3 == 0 then
                pcall(function()
                    DecompileStatusLabel.Text = "Checking... " .. checked .. "/" .. #scripts
                        .. " | Found: " .. #found
                end)
                task.wait()
            end
        end

        -- Mostra resultados no painel
        showDecompileResults(remoteName, found, checked)
    end)
end

--==================================================
-- DEATH BALL AUTO-REBATER v3 — FULL AUTO
--==================================================

deathBallActive = false
deathBallConnection = nil
deathBallStats = { rebated = 0, missed = 0 }
deathBallFoundBalls = {}
deathBallCache = {}
deathBallCacheTime = 0
deathBallLastClick = 0
deathBallPrevPositions = {}
deathBallDodgeActive = false
deathBallEspActive = false
deathBallEspObjects = {}
deathBallKillFeed = {}
deathBallKillConn = nil
deathBallPlayerCount = 0
deathBallBotActive = false
deathBallBotConnection = nil
deathBallBotState = "IDLE"
deathBallQueuePos = nil
deathBallMissChance = 0.12
deathBallHumanTimer = 0
deathBallDeathConn = nil
deathBallLastHumanMove = 0
deathBallBotRoundCount = 0
deathBallForceMode = true -- ON por default (full auto)
deathBallDebugMode = false
deathBallAutoDetect = true -- detecta bola automaticamente por velocidade
deathBallDetectedMethod = "none" -- método que funcionou
deathBallLearnedMethod = nil -- método que JÁ funcionou (pra reusar)
deathBallRespawnConn = nil -- reconecta auto-rebater ao respawnar

-- Detecta se uma cor é "vermelha" (targeting) — mais flexível
isRedColor = function(color)
    if color.R > 0.6 and color.G < 0.3 and color.B < 0.3 then return true end
    if color.R > 0.4 and color.G < 0.15 and color.B < 0.15 then return true end
    if color.R > 0.7 and color.G < 0.4 and color.B < 0.2 then return true end
    return false
end

-- Checa se um objeto é parte de um character
isCharacterPart = function(obj)
    local ok, result = pcall(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and obj:IsDescendantOf(p.Character) then
                return true
            end
        end
        return false
    end)
    return ok and result
end

-- AUTO-DETECT: acha QUALQUER objeto se movendo (bola real)
-- Usa delta position pra detectar bolas movidas por CFrame (sem physics)
autoDetectBalls = function(hrp, range)
    local now = os.clock()
    -- Cache curto (0.15s) pra não perder bola rápida
    if now - deathBallCacheTime < 0.15 and #deathBallCache > 0 then
        return deathBallCache
    end
    local balls = {}
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                local pos = obj.Position
                local dist = (pos - hrp.Position).Magnitude
                if dist <= 50 then -- scan amplo pra trackear bola vindo de longe
                    if not isCharacterPart(obj) then
                        local size = obj.Size.Magnitude
                        if size > 0.3 and size < 25 then
                            -- Velocidade: engine velocity OU delta position
                            local speed = 0
                            local vel = obj.Velocity
                            if vel then speed = vel.Magnitude end
                            -- Delta position (detecta bolas movidas por CFrame)
                            local id = tostring(obj)
                            local prev = deathBallPrevPositions[id]
                            if prev then
                                local dt = now - prev.time
                                if dt > 0.01 and dt < 1 then
                                    local deltaSpeed = ((pos - prev.pos) / dt).Magnitude
                                    if deltaSpeed > speed then speed = deltaSpeed end
                                end
                            end
                            deathBallPrevPositions[id] = { pos = pos, time = now }
                            -- Bola = qualquer coisa se movendo (threshold baixo: >2 m/s)
                            if speed > 2 then
                                table.insert(balls, obj)
                            end
                        end
                    end
                end
            end
        end
    end)
    deathBallCache = balls
    deathBallCacheTime = now
    return balls
end

-- Acha bolas por NOME (modo manual, fallback)
findAllBalls = function(ballName)
    local now = os.clock()
    if now - deathBallCacheTime < 0.5 and #deathBallCache > 0 then
        return deathBallCache
    end
    local balls = {}
    local seen = {}
    pcall(function()
        local lower = ballName:lower()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not seen[obj] then
                local nameMatch = obj.Name:lower():find(lower, 1, true)
                local parentMatch = obj.Parent and obj.Parent.Name:lower():find(lower, 1, true)
                if nameMatch or parentMatch then
                    seen[obj] = true
                    table.insert(balls, obj)
                    if parentMatch and obj.Parent:IsA("BasePart") and not seen[obj.Parent] then
                        seen[obj.Parent] = true
                        table.insert(balls, obj.Parent)
                    end
                end
            end
        end
    end)
    deathBallCache = balls
    deathBallCacheTime = now
    return balls
end

-- Calcula velocidade de uma bola via delta de posição
getBallVelocity = function(ball)
    local id = tostring(ball)
    local now = os.clock()
    local prev = deathBallPrevPositions[id]
    local pos = ball.Position
    if prev then
        local dt = now - prev.time
        if dt > 0.01 then
            local vel = (pos - prev.pos) / dt
            deathBallPrevPositions[id] = { pos = pos, time = now, vel = vel, speed = vel.Magnitude }
            return vel, vel.Magnitude
        end
        return prev.vel or Vector3.zero, prev.speed or 0
    end
    deathBallPrevPositions[id] = { pos = pos, time = now, vel = Vector3.zero, speed = 0 }
    return Vector3.zero, 0
end

-- Checa se bola está VINDO na direção do player (dot product)
isBallApproaching = function(ball, hrp)
    local vel, speed = getBallVelocity(ball)
    if speed < 2 then return false, 0, vel end
    local toPlayer = (hrp.Position - ball.Position).Unit
    local dot = vel.Unit:Dot(toPlayer)
    return dot > 0.2, dot, vel -- threshold mais baixo para pegar mais
end

-- Predição: onde a bola vai estar em N segundos
predictBallPosition = function(ball, seconds)
    local vel, speed = getBallVelocity(ball)
    if speed < 2 then return ball.Position end
    return ball.Position + vel * seconds
end

-- Prioriza bola mais perigosa: vindo na direção + mais perto + vermelha é bonus
getBestTarget = function(balls, hrp)
    local best = nil
    local bestScore = -999
    for _, ball in pairs(balls) do
        local ok, score = pcall(function()
            local dist = (ball.Position - hrp.Position).Magnitude
            local color = ball.Color
            local isRed = isRedColor(color)
            local approaching, dot = isBallApproaching(ball, hrp)
            local s = 0
            if isRed then s = s + 100 end
            if approaching then s = s + 80 * dot end -- peso maior
            s = s - dist * 0.5
            -- Bonus: velocidade alta = mais prioridade
            local _, speed = getBallVelocity(ball)
            s = s + math.min(speed, 50) * 0.3
            return s
        end)
        if ok and score > bestScore then
            bestScore = score
            best = ball
        end
    end
    return best
end

-- SMART INTERACTION: F key + mouse click (confirmado pelo jogo)
-- Tenta F primeiro (VIM keypress), depois mouse click, depois fallbacks
tryAllInteractions = function(ball, cam)
    local methods = {}
    local vim = nil
    pcall(function() vim = game:GetService("VirtualInputManager") end)

    -- 1. TECLA F — principal do jogo
    pcall(function()
        if vim then
            -- KeyDown F
            vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.delay(0.05, function()
                pcall(function()
                    vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                end)
            end)
            table.insert(methods, "F")
        end
    end)

    -- 2. Mouse click (VIM)
    pcall(function()
        if vim then
            vim:SendMouseButtonEvent(
                cam.ViewportSize.X / 2,
                cam.ViewportSize.Y / 2,
                0, true, game, 0
            )
            task.delay(0.03, function()
                pcall(function()
                    vim:SendMouseButtonEvent(
                        cam.ViewportSize.X / 2,
                        cam.ViewportSize.Y / 2,
                        0, false, game, 0
                    )
                end)
            end)
            table.insert(methods, "Click")
        end
    end)

    -- 3. mouse1click do executor
    pcall(function()
        local _env = (typeof(getgenv) == "function" and getgenv()) or {}
        local _click = mouse1click or _env.mouse1click
        if _click then
            _click()
            table.insert(methods, "m1c")
        end
    end)

    -- 4. Tool activation (se tiver bat/racket equipada)
    pcall(function()
        local char = LP.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
                table.insert(methods, "Tool")
            end
        end
    end)

    -- 5. ClickDetector (fallback)
    pcall(function()
        local cd = ball:FindFirstChildOfClass("ClickDetector")
        if not cd and ball.Parent then cd = ball.Parent:FindFirstChildOfClass("ClickDetector") end
        if cd then
            local _env = (typeof(getgenv) == "function" and getgenv()) or {}
            local fcd = fireclickdetector or _env.fireclickdetector
            if fcd then fcd(cd) table.insert(methods, "CD") end
        end
    end)

    -- 6. ProximityPrompt (fallback)
    pcall(function()
        local pp = ball:FindFirstChildOfClass("ProximityPrompt")
        if not pp and ball.Parent then pp = ball.Parent:FindFirstChildOfClass("ProximityPrompt") end
        if pp then
            fireproximityprompt(pp)
            table.insert(methods, "PP")
        end
    end)

    if #methods > 0 then
        deathBallDetectedMethod = table.concat(methods, "+")
    end
    return #methods > 0
end

-- ESP: cria Highlight (box/contorno) + Billboard (nome + dist + vel)
createBallESP = function(ball)
    local id = tostring(ball)
    if deathBallEspObjects[id] then return end
    pcall(function()
        -- Highlight = contorno físico na bola (igual ESP de camera)
        local hl = Instance.new("Highlight")
        hl.Name = "DB_HL"
        hl.Adornee = ball
        hl.FillColor = Color3.fromRGB(255, 60, 60)
        hl.FillTransparency = 0.7
        hl.OutlineColor = Color3.fromRGB(255, 80, 80)
        hl.OutlineTransparency = 0
        hl.Parent = ball

        -- Billboard = nome + distancia + velocidade acima da bola
        local bg = Instance.new("BillboardGui")
        bg.Name = "DB_BG"
        bg.Size = UDim2.new(0, 160, 0, 46)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = true
        bg.Adornee = ball
        bg.Parent = ball

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "BallName"
        nameLabel.Size = UDim2.new(1, 0, 0, 16)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ball.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.TextSize = 13
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = bg

        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "BallDist"
        distLabel.Size = UDim2.new(1, 0, 0, 14)
        distLabel.Position = UDim2.new(0, 0, 0, 16)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "? studs"
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLabel.TextStrokeTransparency = 0.3
        distLabel.TextSize = 11
        distLabel.Font = Enum.Font.Gotham
        distLabel.Parent = bg

        local velLabel = Instance.new("TextLabel")
        velLabel.Name = "BallVel"
        velLabel.Size = UDim2.new(1, 0, 0, 12)
        velLabel.Position = UDim2.new(0, 0, 0, 30)
        velLabel.BackgroundTransparency = 1
        velLabel.Text = ""
        velLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
        velLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        velLabel.TextStrokeTransparency = 0.3
        velLabel.TextSize = 10
        velLabel.Font = Enum.Font.GothamBold
        velLabel.Parent = bg

        deathBallEspObjects[id] = {
            highlight = hl,
            billboard = bg,
            nameLabel = nameLabel,
            distLabel = distLabel,
            velLabel = velLabel,
            ball = ball
        }
    end)
end

-- ESP: atualiza todos os Highlights + Billboards
updateBallESP = function(hrp)
    for id, esp in pairs(deathBallEspObjects) do
        pcall(function()
            if not esp.ball or not esp.ball.Parent then
                if esp.highlight then esp.highlight:Destroy() end
                if esp.billboard then esp.billboard:Destroy() end
                deathBallEspObjects[id] = nil
                return
            end
            local dist = (esp.ball.Position - hrp.Position).Magnitude
            local isRed = isRedColor(esp.ball.Color)
            local approaching, dot = isBallApproaching(esp.ball, hrp)
            local _, speed = getBallVelocity(esp.ball)

            -- Atualiza cor do Highlight baseado no estado
            if isRed then
                esp.highlight.FillColor = Color3.fromRGB(255, 40, 40)
                esp.highlight.FillTransparency = 0.4
                esp.highlight.OutlineColor = Color3.fromRGB(255, 60, 60)
                esp.nameLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
                esp.nameLabel.Text = "TARGET " .. esp.ball.Name
            elseif approaching then
                esp.highlight.FillColor = Color3.fromRGB(255, 180, 40)
                esp.highlight.FillTransparency = 0.6
                esp.highlight.OutlineColor = Color3.fromRGB(255, 200, 60)
                esp.nameLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
                esp.nameLabel.Text = "INCOMING " .. esp.ball.Name
            else
                esp.highlight.FillColor = Color3.fromRGB(100, 100, 100)
                esp.highlight.FillTransparency = 0.8
                esp.highlight.OutlineColor = Color3.fromRGB(150, 150, 150)
                esp.nameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                esp.nameLabel.Text = esp.ball.Name
            end

            esp.distLabel.Text = string.format("%.0f studs", dist)
            esp.distLabel.TextColor3 = dist < 15 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 200)

            if speed > 2 then
                esp.velLabel.Text = string.format("%.0f m/s %s", speed, approaching and ">>>" or "")
                esp.velLabel.TextColor3 = approaching and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(150, 150, 150)
            else
                esp.velLabel.Text = "idle"
                esp.velLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
            end
        end)
    end
end

-- ESP: limpa todos
clearBallESP = function()
    for id, esp in pairs(deathBallEspObjects) do
        pcall(function()
            if esp.highlight then esp.highlight:Destroy() end
            if esp.billboard then esp.billboard:Destroy() end
        end)
    end
    deathBallEspObjects = {}
end

-- Kill feed: monitora mortes
startKillFeed = function()
    if deathBallKillConn then return end
    deathBallPlayerCount = #Players:GetPlayers()
    deathBallKillConn = Players.PlayerRemoving:Connect(function(plr)
        if not deathBallActive then return end
        table.insert(deathBallKillFeed, 1, {
            time = os.clock(),
            text = "💀 " .. plr.Name .. " eliminated"
        })
        if #deathBallKillFeed > 20 then
            table.remove(deathBallKillFeed)
        end
        refreshKillFeed()
    end)
    -- Monitor character deaths for more granularity
    for _, plr in pairs(Players:GetPlayers()) do
        pcall(function()
            if plr ~= LP and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Died:Connect(function()
                        if not deathBallActive then return end
                        table.insert(deathBallKillFeed, 1, {
                            time = os.clock(),
                            text = "☠ " .. plr.Name .. " died"
                        })
                        if #deathBallKillFeed > 20 then
                            table.remove(deathBallKillFeed)
                        end
                        refreshKillFeed()
                    end)
                end
            end
        end)
    end
end

stopKillFeed = function()
    if deathBallKillConn then
        deathBallKillConn:Disconnect()
        deathBallKillConn = nil
    end
end

refreshKillFeed = function()
    pcall(function()
        if not DeathBallKillScroll then return end
        for _, c in pairs(DeathBallKillScroll:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        for i, entry in ipairs(deathBallKillFeed) do
            local elapsed = os.clock() - entry.time
            local timeStr = elapsed < 60 and string.format("%.0fs ago", elapsed) or string.format("%.0fm ago", elapsed / 60)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 14)
            lbl.BackgroundTransparency = 1
            lbl.Text = entry.text .. " (" .. timeStr .. ")"
            lbl.TextColor3 = Color3.fromRGB(255, 120, 120)
            lbl.TextSize = 9
            lbl.Font = Enum.Font.Code
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.LayoutOrder = i
            lbl.Parent = DeathBallKillScroll
        end
        DeathBallKillScroll.CanvasSize = UDim2.new(0, 0, 0, #deathBallKillFeed * 16)
    end)
end

-- Auto-dodge: move player perpendicular à trajetória da bola
doDodge = function(ball, hrp)
    pcall(function()
        local vel, speed = getBallVelocity(ball)
        if speed < 5 then return end
        local toBall = (ball.Position - hrp.Position)
        local dist = toBall.Magnitude
        if dist > 40 or dist < 3 then return end
        -- Vetor perpendicular à velocidade (no plano horizontal)
        local right = Vector3.new(-vel.Z, 0, vel.X).Unit
        -- Escolhe lado com mais espaço (raycast simplificado)
        local dodgeDir = right
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:Move(dodgeDir, false)
        end
    end)
end

startDeathBall = function()
    if deathBallActive then return end
    deathBallActive = true
    deathBallStats = { rebated = 0, missed = 0 }
    deathBallPrevPositions = {}
    deathBallLastClick = 0
    deathBallKillFeed = {}
    deathBallDetectedMethod = "none"

    local ballName = DeathBallNameBox.Text or "Ball"
    local baseRange = tonumber(DeathBallRangeBox.Text) or 5 -- só age pertinho
    local baseCooldown = tonumber(DeathBallCooldownBox and DeathBallCooldownBox.Text) or 0.15
    local cam = workspace.CurrentCamera

    -- AUTO: liga ESP junto
    deathBallEspActive = true
    DeathBallEspBtn.Text = "ESP: ON"
    DeathBallEspBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)

    DeathBallAutoBtn.Text = "⚡ AUTO-PLAY: ON"
    DeathBallAutoBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    DeathBallStatusLabel.Text = "Status: Auto-detecting balls..."
    DeathBallStatusLabel.TextColor3 = Color3.fromRGB(100, 220, 200)

    local mode = deathBallAutoDetect and "AUTO-DETECT" or ("name: " .. ballName)
    notify("Death Ball ON — " .. mode .. " + ESP", "success")

    startKillFeed()

    -- AUTO-RECONNECT: se morrer, reconecta o loop ao respawnar
    if deathBallRespawnConn then deathBallRespawnConn:Disconnect() end
    deathBallRespawnConn = LP.CharacterAdded:Connect(function()
        if not deathBallActive then return end
        task.wait(1)
        deathBallPrevPositions = {}
        deathBallCacheTime = 0
        DeathBallStatusLabel.Text = "Status: Respawned — resuming..."
        DeathBallStatusLabel.TextColor3 = Color3.fromRGB(100, 220, 200)
    end)

    deathBallConnection = RunService.Heartbeat:Connect(function()
        if not deathBallActive then return end

        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Re-read base settings live
        baseRange = tonumber(DeathBallRangeBox.Text) or 5 -- só age pertinho
        baseCooldown = tonumber(DeathBallCooldownBox and DeathBallCooldownBox.Text) or 0.15

        -- Acha bolas: AUTO-DETECT por velocidade OU por nome
        local balls
        if deathBallAutoDetect then
            balls = autoDetectBalls(hrp, baseRange)
        else
            balls = findAllBalls(ballName)
        end
        deathBallFoundBalls = balls

        if #balls == 0 then
            DeathBallBallInfo.Text = deathBallAutoDetect
                and "Auto-detect: waiting for moving objects..."
                or "Balls: none found"
            DeathBallBallInfo.TextColor3 = Color3.fromRGB(200, 200, 100)
            DeathBallDistInfo.Text = "Distance: --"
            DeathBallColorInfo.Text = "Method: " .. deathBallDetectedMethod
            DeathBallVelInfo.Text = "Velocity: --"
            return
        end

        -- ESP: cria/atualiza highlights + billboards
        if deathBallEspActive then
            for _, b in pairs(balls) do
                createBallESP(b)
            end
            updateBallESP(hrp)
        end

        -- Pega melhor alvo
        local ball = getBestTarget(balls, hrp)
        if not ball then ball = balls[1] end

        local dist = (ball.Position - hrp.Position).Magnitude
        local color = ball.Color
        local isRed = isRedColor(color)
        local approaching, dot, vel = isBallApproaching(ball, hrp)
        local speed = vel.Magnitude

        -- RANGE FIXO: só age dentro de 5 studs (close range)
        local dynRange = baseRange

        -- COOLDOWN por distância com variação aleatória (parece humano):
        -- <2 studs = 16~19 cps (0.053~0.063s)
        -- <5 studs = 8~12 cps (0.083~0.125s)
        -- >5 studs = nem tenta
        local dynCooldown = baseCooldown
        if dist <= 2 then
            dynCooldown = 1 / (math.random(16, 19) + math.random() * 0.5)
        elseif dist <= 5 then
            dynCooldown = 1 / (math.random(8, 12) + math.random() * 0.5)
        end

        -- Info panel
        DeathBallBallInfo.Text = string.format("Balls: %d | Best: %s (%s)", #balls, ball.Name, ball.ClassName)
        DeathBallBallInfo.TextColor3 = Color3.fromRGB(100, 220, 200)
        DeathBallDistInfo.Text = string.format("Distance: %.1f studs (range: %.0f)", dist, dynRange)
        DeathBallDistInfo.TextColor3 = dist < dynRange and Color3.fromRGB(255, 80, 80) or Colors.textDim
        DeathBallColorInfo.Text = string.format("Method: %s%s",
            deathBallDetectedMethod,
            deathBallLearnedMethod and (" [learned: " .. deathBallLearnedMethod .. "]") or "")
        DeathBallColorInfo.TextColor3 = deathBallLearnedMethod and Color3.fromRGB(100, 255, 100) or Colors.textDim
        DeathBallVelInfo.Text = string.format("Vel: %.0f m/s %s dot:%.1f cd:%.2f",
            speed,
            approaching and "INCOMING" or "away",
            dot or 0,
            dynCooldown)
        DeathBallVelInfo.TextColor3 = approaching and Color3.fromRGB(255, 200, 60) or Colors.textDim

        -- Debug: mostra info detalhada
        if deathBallDebugMode then
            local dbg = string.format("DBG: %s cls=%s vel=%.0f app=%s red=%s dst=%.0f rng=%.0f path=%s",
                ball.Name, ball.ClassName, speed,
                tostring(approaching), tostring(isRed), dist, dynRange,
                ball:GetFullName():sub(1, 35))
            DeathBallStatusLabel.Text = dbg
            DeathBallStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
        end

        -- Auto-dodge
        if deathBallDodgeActive and approaching and not isRed and dist < 30 then
            doDodge(ball, hrp)
        end

        -- Decide se devemos agir
        local shouldAct = deathBallForceMode and (approaching or dist < dynRange) or isRed

        if shouldAct then
            if not deathBallDebugMode then
                DeathBallStatusLabel.Text = string.format("TARGETING %s — %.0fm %.0fm/s", ball.Name, dist, speed)
                DeathBallStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end

            -- Prediction aim
            local timeToReach = dist / math.max(speed, 1)
            local aimTime = math.min(timeToReach * 0.3, 0.5)
            local predictedPos = predictBallPosition(ball, aimTime)

            pcall(function()
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, predictedPos)
            end)

            -- Trigger com dynamic cooldown
            local now = os.clock()
            local shouldMiss = deathBallBotActive and math.random() < deathBallMissChance
            if dist <= dynRange and (now - deathBallLastClick) >= dynCooldown and not shouldMiss then
                if not deathBallDebugMode then
                    DeathBallStatusLabel.Text = "REBATING! [" .. deathBallDetectedMethod .. "]"
                    DeathBallStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                end

                -- SMART INTERACTION
                tryAllInteractions(ball, cam)

                deathBallLastClick = now
                deathBallStats.rebated = deathBallStats.rebated + 1
                DeathBallStatsLabel.Text = "Rebated: " .. deathBallStats.rebated .. " | Missed: " .. deathBallStats.missed
            elseif dist <= dynRange and shouldMiss then
                deathBallStats.missed = deathBallStats.missed + 1
                DeathBallStatsLabel.Text = "Rebated: " .. deathBallStats.rebated .. " | Missed: " .. deathBallStats.missed
                if not deathBallDebugMode then
                    DeathBallStatusLabel.Text = "MISSED (on purpose)"
                    DeathBallStatusLabel.TextColor3 = Color3.fromRGB(255, 160, 60)
                end
            end
        elseif not deathBallDebugMode then
            if approaching and dist < 40 then
                DeathBallStatusLabel.Text = string.format("INCOMING — %.0fm %.0fm/s", dist, speed)
                DeathBallStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
            else
                DeathBallStatusLabel.Text = "Watching..."
                DeathBallStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
            end
        end
    end)
end

stopDeathBall = function()
    deathBallActive = false
    if deathBallConnection then
        deathBallConnection:Disconnect()
        deathBallConnection = nil
    end
    if deathBallRespawnConn then
        deathBallRespawnConn:Disconnect()
        deathBallRespawnConn = nil
    end
    clearBallESP()
    stopKillFeed()
    deathBallPrevPositions = {}
    deathBallEspActive = false
    DeathBallEspBtn.Text = "ESP: OFF"
    DeathBallEspBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    DeathBallAutoBtn.Text = "⚡ AUTO-PLAY: OFF"
    DeathBallAutoBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    DeathBallStatusLabel.Text = "Status: Idle"
    DeathBallStatusLabel.TextColor3 = Colors.textDim
    notify("Death Ball OFF", "info")
end

--==================================================
-- DEATH BALL OBJECT SCANNER (descobre nomes de partes)
--==================================================

deathBallScannerActive = false
deathBallScannerObjects = {}
deathBallScannerConn = nil

-- Scan: cria billboards em TODOS os BaseParts num raio
startObjectScanner = function()
    if deathBallScannerActive then
        stopObjectScanner()
        return
    end
    deathBallScannerActive = true
    local scanRange = tonumber(DeathBallScanRangeBox and DeathBallScanRangeBox.Text) or 50

    DeathBallScanObjBtn.Text = "🔎 SCANNING... (click to stop)"
    DeathBallScanObjBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
    notify("Object Scanner ON — range " .. scanRange .. " studs", "success")

    -- Lista para resultados
    local foundNames = {}

    deathBallScannerConn = RunService.Heartbeat:Connect(function()
        if not deathBallScannerActive then return end

        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Limpa billboards antigos
        for id, obj in pairs(deathBallScannerObjects) do
            pcall(function()
                if not obj.part or not obj.part.Parent then
                    obj.gui:Destroy()
                    deathBallScannerObjects[id] = nil
                elseif (obj.part.Position - hrp.Position).Magnitude > scanRange then
                    obj.gui:Destroy()
                    deathBallScannerObjects[id] = nil
                end
            end)
        end

        -- Scan partes perto
        pcall(function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                    local id = tostring(obj)
                    if not deathBallScannerObjects[id] then
                        local dist = (obj.Position - hrp.Position).Magnitude
                        if dist <= scanRange then
                            -- Ignora partes do próprio character e de players
                            local isChar = false
                            pcall(function()
                                for _, p in pairs(Players:GetPlayers()) do
                                    if p.Character and obj:IsDescendantOf(p.Character) then
                                        isChar = true
                                        break
                                    end
                                end
                            end)

                            if not isChar then
                                pcall(function()
                                    local bb = Instance.new("BillboardGui")
                                    bb.Name = "ObjScan"
                                    bb.Size = UDim2.new(0, 160, 0, 44)
                                    bb.StudsOffset = Vector3.new(0, 2, 0)
                                    bb.AlwaysOnTop = true
                                    bb.Adornee = obj
                                    bb.Parent = CoreGui

                                    local lbl = Instance.new("TextLabel")
                                    lbl.Size = UDim2.new(1, 0, 1, 0)
                                    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                    lbl.BackgroundTransparency = 0.4
                                    lbl.TextColor3 = Color3.fromRGB(0, 255, 200)
                                    lbl.TextSize = 9
                                    lbl.Font = Enum.Font.Code
                                    lbl.TextWrapped = true
                                    lbl.TextStrokeTransparency = 0.5
                                    lbl.RichText = true
                                    lbl.Parent = bb
                                    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)

                                    deathBallScannerObjects[id] = { gui = bb, label = lbl, part = obj }

                                    -- Track unique names
                                    if not foundNames[obj.Name] then
                                        foundNames[obj.Name] = { class = obj.ClassName, count = 0 }
                                    end
                                    foundNames[obj.Name].count = foundNames[obj.Name].count + 1
                                end)
                            end
                        end
                    end
                end
            end
        end)

        -- Atualiza labels com info ao vivo
        for id, data in pairs(deathBallScannerObjects) do
            pcall(function()
                if data.part and data.part.Parent and data.label then
                    local d = (data.part.Position - hrp.Position).Magnitude
                    local c = data.part.Color
                    local vel = ""
                    if data.part:IsA("BasePart") then
                        local v = data.part.Velocity
                        if v.Magnitude > 1 then
                            vel = string.format(" <font color='#ff6'>%.0fm/s</font>", v.Magnitude)
                        end
                    end
                    local colorHex = string.format("#%02x%02x%02x",
                        math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
                    data.label.Text = string.format(
                        "<font color='#0fc'>%s</font> <font color='%s'>■</font>\n%s %.0fs%s",
                        data.part.Name, colorHex, data.part.ClassName, d, vel
                    )
                end
            end)
        end

        -- Atualiza lista de nomes encontrados
        pcall(function()
            if DeathBallScanResultLabel then
                local lines = {}
                local sorted = {}
                for name, info in pairs(foundNames) do
                    table.insert(sorted, { name = name, class = info.class, count = info.count })
                end
                table.sort(sorted, function(a, b) return a.count > b.count end)
                for i, item in ipairs(sorted) do
                    if i > 15 then break end
                    table.insert(lines, item.name .. " (" .. item.class .. ") x" .. item.count)
                end
                DeathBallScanResultLabel.Text = #lines > 0 and table.concat(lines, "\n") or "No objects nearby..."
            end
        end)
    end)
end

stopObjectScanner = function()
    deathBallScannerActive = false
    if deathBallScannerConn then
        deathBallScannerConn:Disconnect()
        deathBallScannerConn = nil
    end
    for id, obj in pairs(deathBallScannerObjects) do
        pcall(function() obj.gui:Destroy() end)
    end
    deathBallScannerObjects = {}
    DeathBallScanObjBtn.Text = "🔎 SCAN OBJECTS (find ball name)"
    DeathBallScanObjBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
    notify("Object Scanner OFF", "info")
end

--==================================================
-- DEATH BALL AFK BOT
--==================================================

-- Salva posição do queue pad
setQueuePosition = function()
    pcall(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            deathBallQueuePos = hrp.Position
            DeathBallQueuePosLabel.Text = string.format("Queue: %.0f, %.0f, %.0f", deathBallQueuePos.X, deathBallQueuePos.Y, deathBallQueuePos.Z)
            DeathBallQueuePosLabel.TextColor3 = Color3.fromRGB(100, 220, 200)
            notify("Queue position saved!", "success")
        end
    end)
end

-- Movimento humano aleatório (anti-pattern)
doHumanMovement = function(hrp, hum)
    pcall(function()
        local rng = math.random()
        if rng < 0.15 then
            -- Pulo aleatório
            hum.Jump = true
        elseif rng < 0.5 then
            -- Andada curta aleatória
            local angle = math.random() * math.pi * 2
            local dist = math.random(3, 8)
            local target = hrp.Position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
            hum:MoveTo(target)
        elseif rng < 0.7 then
            -- Rotação de câmera suave
            local cam = workspace.CurrentCamera
            local yaw = math.rad(math.random(-30, 30))
            cam.CFrame = cam.CFrame * CFrame.Angles(0, yaw, 0)
        end
        -- 30% do tempo fica parado (humano real não se move 100%)
    end)
end

-- Anda até o queue pad
walkToQueue = function()
    pcall(function()
        if not deathBallQueuePos then return end
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        local dist = (hrp.Position - deathBallQueuePos).Magnitude
        if dist > 4 then
            hum:MoveTo(deathBallQueuePos)
        end
    end)
end

-- Detecta se estamos em round (bolas existem)
isInRound = function()
    local ballName = DeathBallNameBox.Text or "Ball"
    local balls = findAllBalls(ballName)
    return #balls > 0
end

-- Conecta evento de morte do personagem
connectDeathEvent = function()
    if deathBallDeathConn then
        deathBallDeathConn:Disconnect()
        deathBallDeathConn = nil
    end
    pcall(function()
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        deathBallDeathConn = hum.Died:Connect(function()
            if not deathBallBotActive then return end
            deathBallBotState = "DEAD"
            DeathBallBotStateLabel.Text = "Bot: 💀 DEAD — waiting respawn..."
            DeathBallBotStateLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end)
    end)
end

startDeathBallBot = function()
    if deathBallBotActive then return end
    if not deathBallQueuePos then
        notify("Set queue position first! Walk to the pad and click SET QUEUE POS", "warning")
        return
    end
    deathBallBotActive = true
    deathBallBotState = "LOBBY"
    deathBallBotRoundCount = 0
    deathBallLastHumanMove = 0

    -- Liga o auto-rebater se não tiver ligado
    if not deathBallActive then
        startDeathBall()
    end

    DeathBallBotBtn.Text = "🤖 AFK BOT: ON"
    DeathBallBotBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
    notify("AFK Bot ON — playing automatically!", "success")

    connectDeathEvent()

    -- Reconecta ao respawn
    LP.CharacterAdded:Connect(function(char)
        if not deathBallBotActive then return end
        task.wait(1)
        deathBallBotState = "LOBBY"
        DeathBallBotStateLabel.Text = "Bot: 🏠 LOBBY — walking to queue..."
        DeathBallBotStateLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
        connectDeathEvent()
    end)

    deathBallBotConnection = RunService.Heartbeat:Connect(function()
        if not deathBallBotActive then return end

        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local now = os.clock()
        local inRound = isInRound()

        -- ═══ STATE MACHINE ═══
        if deathBallBotState == "DEAD" then
            -- Esperando respawn (CharacterAdded vai mudar pra LOBBY)
            return

        elseif deathBallBotState == "LOBBY" then
            -- Andar até o queue
            DeathBallBotStateLabel.Text = "Bot: 🏠 LOBBY — walking to queue..."
            DeathBallBotStateLabel.TextColor3 = Color3.fromRGB(200, 200, 100)

            walkToQueue()

            local dist = deathBallQueuePos and (hrp.Position - deathBallQueuePos).Magnitude or 999
            if dist < 6 then
                deathBallBotState = "QUEUED"
                DeathBallBotStateLabel.Text = "Bot: ⏳ QUEUED — waiting for round..."
                DeathBallBotStateLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
            end

            -- Movimento humano enquanto anda
            if now - deathBallLastHumanMove > math.random(3, 6) then
                deathBallLastHumanMove = now
                if dist < 6 then
                    doHumanMovement(hrp, hum)
                end
            end

        elseif deathBallBotState == "QUEUED" then
            -- Esperando partida começar
            if inRound then
                deathBallBotState = "IN_ROUND"
                deathBallBotRoundCount = deathBallBotRoundCount + 1
                DeathBallBotRoundsLabel.Text = "Rounds: " .. deathBallBotRoundCount
                DeathBallBotStateLabel.Text = "Bot: ⚔ IN ROUND — auto-playing!"
                DeathBallBotStateLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end

            -- Movimento humano aleatório no lobby
            if now - deathBallLastHumanMove > math.random(2, 5) then
                deathBallLastHumanMove = now
                doHumanMovement(hrp, hum)
            end

        elseif deathBallBotState == "IN_ROUND" then
            -- O auto-rebater cuida do gameplay
            -- Só verifica se round acabou
            DeathBallBotStateLabel.Text = "Bot: ⚔ IN ROUND — auto-playing!"
            DeathBallBotStateLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

            if not inRound then
                -- Round acabou, volta pro lobby
                deathBallBotState = "LOBBY"
                DeathBallBotStateLabel.Text = "Bot: 🏠 LOBBY — round over, re-queuing..."
                DeathBallBotStateLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
                task.wait(math.random() * 2 + 1)
            end

            -- Movimento humano leve durante round (olhar ao redor)
            if now - deathBallLastHumanMove > math.random(4, 8) then
                deathBallLastHumanMove = now
                if math.random() < 0.3 then
                    hum.Jump = true
                end
            end
        end

        -- Imperfect play: chance de não clicar (miss de propósito)
        -- Isso é aplicado no startDeathBall main loop via deathBallMissChance
    end)
end

stopDeathBallBot = function()
    deathBallBotActive = false
    deathBallBotState = "IDLE"
    if deathBallBotConnection then
        deathBallBotConnection:Disconnect()
        deathBallBotConnection = nil
    end
    if deathBallDeathConn then
        deathBallDeathConn:Disconnect()
        deathBallDeathConn = nil
    end
    DeathBallBotBtn.Text = "🤖 AFK BOT: OFF"
    DeathBallBotBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    DeathBallBotStateLabel.Text = "Bot: Idle"
    DeathBallBotStateLabel.TextColor3 = Colors.textDim
    notify("AFK Bot OFF", "info")
end

--==================================================
-- MORE FUN TROLLS
--==================================================

-- MAGNET — gruda nas costas do alvo (piggyback)
magnetPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        -- Costas do alvo, um pouco acima (piggyback)
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 1.5, 1)
    end)
    notify("Magnet: " .. player.DisplayName, "success")
end

-- CLONE — sobrepor exatamente no avatar do alvo (impostor)
clonePlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        -- Exatamente na mesma posição (overlap total)
        myHRP.CFrame = targetHRP.CFrame
    end)
    notify("Clone: " .. player.DisplayName, "success")
end

-- UPSIDE DOWN — pendurado de cabeça pra baixo acima do alvo
upsideDownPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        -- Acima do alvo, invertido 180° no eixo Z
        myHRP.CFrame = targetHRP.CFrame
            * CFrame.new(0, 6, 0)
            * CFrame.Angles(0, 0, math.rad(180))
    end)
    notify("Upside Down: " .. player.DisplayName, "success")
end

-- TORNADO — orbita que pulsa (raio muda, sobe e desce)
tornadoPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    local angle = 0
    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        angle = (angle + 12 * trollSpeedMul) % 360
        t = t + 0.08 * trollSpeedMul
        -- Raio pulsa entre 2 e 6
        local radius = 4 + math.sin(t) * 2
        -- Altura sobe e desce
        local yOffset = math.sin(t * 1.5) * 3
        local rad = math.rad(angle)
        local pos = targetHRP.CFrame * CFrame.new(math.sin(rad) * radius, yOffset, math.cos(rad) * radius)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Tornado: " .. player.DisplayName, "success")
end

--==================================================
-- NEW TROLLS (15)
--==================================================

snakePlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 0.05 * trollSpeedMul
        local behind = targetHRP.CFrame * CFrame.new(math.sin(t * 3) * 2, -2.5, -4)
        myHRP.CFrame = CFrame.new(behind.Position, targetHRP.Position) * CFrame.Angles(math.rad(80), 0, 0)
    end)
    notify("Snake: " .. player.DisplayName, "success")
end

mirrorPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        local frontPos = targetHRP.CFrame * CFrame.new(0, 0, -3)
        myHRP.CFrame = CFrame.lookAt(frontPos.Position, targetHRP.Position)
    end)
    notify("Mirror: " .. player.DisplayName, "success")
end

stackPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 5, 0)
    end)
    notify("Stack: " .. player.DisplayName, "success")
end

figure8Player = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 0.03 * trollSpeedMul
        local scale = 5
        local x = scale * math.sin(t)
        local z = scale * math.sin(t) * math.cos(t)
        local pos = targetHRP.CFrame * CFrame.new(x, 0, z)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Figure 8: " .. player.DisplayName, "success")
end

dogPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        local behindPos = targetHRP.CFrame * CFrame.new(0, -2, -4)
        myHRP.CFrame = CFrame.new(behindPos.Position, targetHRP.Position) * CFrame.Angles(math.rad(90), 0, 0)
    end)
    notify("Dog: " .. player.DisplayName, "success")
end

ferrisPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local angle = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        angle = (angle + 3 * trollSpeedMul) % 360
        local rad = math.rad(angle)
        local radius = 5
        local pos = targetHRP.CFrame * CFrame.new(0, math.sin(rad) * radius, math.cos(rad) * radius)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Ferris: " .. player.DisplayName, "success")
end

salsaPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 0.06 * trollSpeedMul
        local xOffset = math.sin(t * 2) * 3
        local zOffset = -3 + math.sin(t * 4) * 0.5
        local pos = targetHRP.CFrame * CFrame.new(xOffset, 0, zOffset)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Salsa: " .. player.DisplayName, "success")
end

ufoPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local angle = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        angle = (angle + 10 * trollSpeedMul) % 360
        local pos = targetHRP.CFrame * CFrame.new(0, 20, 0)
        myHRP.CFrame = CFrame.new(pos.Position) * CFrame.Angles(0, math.rad(angle), 0)
    end)
    notify("UFO: " .. player.DisplayName, "success")
end

boomerangPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 0.02 * trollSpeedMul
        local dist = 30 * (1 - math.cos(t))
        local yOff = math.sin(t * 2) * 5
        local pos = targetHRP.CFrame * CFrame.new(0, yOff, -dist)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Boomerang: " .. player.DisplayName, "success")
end

rollerPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local angle = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        angle = (angle + 4 * trollSpeedMul) % 360
        local rad = math.rad(angle)
        local radius = 6
        local yOff = math.sin(rad * 3) * 8
        local pos = targetHRP.CFrame * CFrame.new(math.sin(rad) * radius, yOff, math.cos(rad) * radius)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Roller: " .. player.DisplayName, "success")
end

spiralPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local angle = 0
    local height = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        angle = (angle + 8 * trollSpeedMul) % 360
        height = height + 0.15 * trollSpeedMul
        if height > 20 then height = 0 end
        local rad = math.rad(angle)
        local radius = 4
        local pos = targetHRP.CFrame * CFrame.new(math.sin(rad) * radius, height, math.cos(rad) * radius)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Spiral: " .. player.DisplayName, "success")
end

surfPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local angle = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        angle = (angle + 5 * trollSpeedMul) % 360
        local rad = math.rad(angle)
        local radius = 5
        local pos = targetHRP.CFrame * CFrame.new(math.sin(rad) * radius, -1, math.cos(rad) * radius)
        local lookDir = targetHRP.CFrame * CFrame.new(math.sin(rad + 0.1) * radius, -1, math.cos(rad + 0.1) * radius)
        myHRP.CFrame = CFrame.lookAt(pos.Position, lookDir.Position) * CFrame.Angles(0, 0, math.rad(90))
    end)
    notify("Surf: " .. player.DisplayName, "success")
end

bouncerPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 0.08 * trollSpeedMul
        local xOff = math.sin(t) * 6
        local yOff = math.abs(math.sin(t * 2)) * 3
        local pos = targetHRP.CFrame * CFrame.new(xOff, yOff, -2)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Bouncer: " .. player.DisplayName, "success")
end

lapSitPlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    myHum.Sit = true
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP then return end
        if myHum then myHum.Sit = true end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, -0.5, -1)
    end)
    notify("Lap Sit: " .. player.DisplayName, "success")
end

wavePlayer = function(player)
    stopTroll()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end
    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    local t = 0
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        t = t + 0.04 * trollSpeedMul
        local zOff = math.sin(t) * 8
        local xOff = math.sin(t * 2) * 4
        local yOff = math.sin(t * 3) * 2
        local pos = targetHRP.CFrame * CFrame.new(xOff, yOff, zOff)
        myHRP.CFrame = CFrame.lookAt(pos.Position, targetHRP.Position)
    end)
    notify("Wave: " .. player.DisplayName, "success")
end

--==================================================
-- NEW TROLLS: Parasite, Stalk, Push, Swap, Jail
--==================================================

parasitePlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not targetHRP or not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        -- Fica dentro do character alvo (sobreposto)
        myHRP.CFrame = player.Character:FindFirstChild("HumanoidRootPart").CFrame
    end)
    notify("Parasite: " .. player.DisplayName, "success")
end

stalkPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not targetHRP or not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
        -- 10 studs atrás, olhando pra ele
        local behindCF = tHRP.CFrame * CFrame.new(0, 0, 10)
        myHRP.CFrame = CFrame.lookAt(behindCF.Position, tHRP.Position)
    end)
    notify("Stalking: " .. player.DisplayName, "success")
end

pushPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not targetHRP or not myHRP or not myHum then return end

    trollSaveCFrame()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        myChar = LP.Character
        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
        -- Fica 1 stud na frente dele empurrando
        local pushCF = tHRP.CFrame * CFrame.new(0, 0, -1)
        myHRP.CFrame = CFrame.lookAt(pushCF.Position, tHRP.Position)
        myHRP.Velocity = (tHRP.Position - myHRP.Position).Unit * 80
    end)
    notify("Pushing: " .. player.DisplayName, "success")
end

swapPlayer = function(player)
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP or not myHRP then return end

    -- Swap instantâneo (teleporta você pra posição dele)
    myHRP.CFrame = targetHRP.CFrame
    notify("Swapped with: " .. player.DisplayName, "success")
end

jailPlayer = function(player)
    stopTroll()
    local targetChar = player.Character
    if not targetChar then notify("No character", "error") return end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    -- Limpa jail anterior
    for _, p in ipairs(trollJailParts) do
        if p and p.Parent then p:Destroy() end
    end
    trollJailParts = {}

    -- Cria gaiola de 6 paredes ao redor do alvo
    local pos = targetHRP.Position
    local wallSize = 8
    local walls = {
        { size = Vector3.new(wallSize, wallSize, 0.5), cf = CFrame.new(pos + Vector3.new(0, 0, wallSize/2)) },
        { size = Vector3.new(wallSize, wallSize, 0.5), cf = CFrame.new(pos + Vector3.new(0, 0, -wallSize/2)) },
        { size = Vector3.new(0.5, wallSize, wallSize), cf = CFrame.new(pos + Vector3.new(wallSize/2, 0, 0)) },
        { size = Vector3.new(0.5, wallSize, wallSize), cf = CFrame.new(pos + Vector3.new(-wallSize/2, 0, 0)) },
        { size = Vector3.new(wallSize, 0.5, wallSize), cf = CFrame.new(pos + Vector3.new(0, wallSize/2, 0)) },
        { size = Vector3.new(wallSize, 0.5, wallSize), cf = CFrame.new(pos + Vector3.new(0, -wallSize/2, 0)) },
    }

    for _, w in ipairs(walls) do
        local part = Instance.new("Part")
        part.Size = w.size
        part.CFrame = w.cf
        part.Anchored = true
        part.CanCollide = true
        part.Material = Enum.Material.ForceField
        part.Color = Color3.fromRGB(180, 0, 0)
        part.Transparency = 0.5
        part.Parent = workspace
        table.insert(trollJailParts, part)
    end

    -- Seguir o alvo (atualiza posição da jail)
    trollConnection = RunService.Heartbeat:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            stopTroll()
            return
        end
        local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
        local tPos = tHRP.Position
        local i = 1
        for _, w in ipairs(walls) do
            if trollJailParts[i] and trollJailParts[i].Parent then
                local offsets = {
                    Vector3.new(0, 0, wallSize/2),
                    Vector3.new(0, 0, -wallSize/2),
                    Vector3.new(wallSize/2, 0, 0),
                    Vector3.new(-wallSize/2, 0, 0),
                    Vector3.new(0, wallSize/2, 0),
                    Vector3.new(0, -wallSize/2, 0),
                }
                trollJailParts[i].CFrame = CFrame.new(tPos + offsets[i])
            end
            i = i + 1
        end
    end)
    notify("Jailed: " .. player.DisplayName .. " (client-side)", "success")
end

--==================================================
-- PLAYER INFO CARDS
--==================================================

createPlayerInfoCard = function(player)
    if not player or not player.Character then return end
    if player == LP then return end
    local char = player.Character

    -- Remove existing
    local existing = char:FindFirstChild("VampPlayerInfo")
    if existing then existing:Destroy() end

    local bg = Instance.new("BillboardGui")
    bg.Name = "VampPlayerInfo"
    bg.Size = UDim2.new(0, 160, 0, 80)
    bg.StudsOffset = Vector3.new(0, 6, 0)
    bg.AlwaysOnTop = true
    bg.Adornee = char
    bg.Parent = char

    -- Card frame
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    card.BackgroundTransparency = 0.1
    card.Parent = bg
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = Color3.fromRGB(40, 180, 60)
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.3
    addGradient(card, Color3.fromRGB(20, 20, 24), Color3.fromRGB(8, 8, 10), 90)

    -- Photo (circular)
    local photoFrame = Instance.new("Frame")
    photoFrame.Size = UDim2.new(0, 36, 0, 36)
    photoFrame.Position = UDim2.new(0, 6, 0, 6)
    photoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    photoFrame.Parent = card
    Instance.new("UICorner", photoFrame).CornerRadius = UDim.new(1, 0)
    local photoStroke = Instance.new("UIStroke", photoFrame)
    photoStroke.Color = Colors.blood
    photoStroke.Thickness = 1

    local photo = Instance.new("ImageLabel")
    photo.Size = UDim2.new(1, 0, 1, 0)
    photo.BackgroundTransparency = 1
    photo.Parent = photoFrame
    Instance.new("UICorner", photo).CornerRadius = UDim.new(1, 0)

    -- Load thumbnail async
    task.spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        if ok and thumb then photo.Image = thumb end
    end)

    -- Display name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -48, 0, 14)
    nameLabel.Position = UDim2.new(0, 46, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = Colors.text
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card

    -- @username
    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(1, -48, 0, 12)
    userLabel.Position = UDim2.new(0, 46, 0, 18)
    userLabel.BackgroundTransparency = 1
    userLabel.Text = "@" .. player.Name
    userLabel.TextColor3 = Colors.textDim
    userLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    userLabel.TextStrokeTransparency = 0.5
    userLabel.TextSize = 9
    userLabel.Font = Enum.Font.Gotham
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.TextTruncate = Enum.TextTruncate.AtEnd
    userLabel.Parent = card

    -- ID
    local idLabel = Instance.new("TextLabel")
    idLabel.Size = UDim2.new(1, -48, 0, 12)
    idLabel.Position = UDim2.new(0, 46, 0, 30)
    idLabel.BackgroundTransparency = 1
    idLabel.Text = "ID: " .. tostring(player.UserId)
    idLabel.TextColor3 = Colors.textDim
    idLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    idLabel.TextStrokeTransparency = 0.5
    idLabel.TextSize = 8
    idLabel.Font = Enum.Font.Code
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.Parent = card

    -- Account age
    local ageText
    local ageDays = player.AccountAge
    if ageDays >= 365 then
        ageText = string.format("%.1f years", ageDays / 365)
    elseif ageDays >= 30 then
        ageText = math.floor(ageDays / 30) .. " months"
    else
        ageText = ageDays .. " days"
    end

    local ageLabel = Instance.new("TextLabel")
    ageLabel.Size = UDim2.new(1, -12, 0, 12)
    ageLabel.Position = UDim2.new(0, 6, 0, 48)
    ageLabel.BackgroundTransparency = 1
    ageLabel.Text = "📅 " .. ageText
    ageLabel.TextColor3 = Color3.fromRGB(80, 220, 100)
    ageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ageLabel.TextStrokeTransparency = 0.5
    ageLabel.TextSize = 9
    ageLabel.Font = Enum.Font.GothamBold
    ageLabel.TextXAlignment = Enum.TextXAlignment.Left
    ageLabel.Parent = card

    -- Distance (updated every frame)
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, -12, 0, 12)
    distLabel.Position = UDim2.new(0, 6, 0, 62)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "? studs"
    distLabel.TextColor3 = Colors.textDim
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.TextSize = 8
    distLabel.Font = Enum.Font.Code
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    distLabel.Parent = card

    table.insert(playerInfoBillboards, {
        player = player,
        billboard = bg,
        distLabel = distLabel,
    })
end

clearPlayerInfo = function()
    if playerInfoConnection then
        playerInfoConnection:Disconnect()
        playerInfoConnection = nil
    end
    for _, info in ipairs(playerInfoBillboards) do
        if info.billboard and info.billboard.Parent then
            info.billboard:Destroy()
        end
    end
    playerInfoBillboards = {}
end

updatePlayerInfo = function()
    clearPlayerInfo()
    if not playerInfoActive then return end

    -- Create for all existing players
    for _, player in ipairs(Players:GetPlayers()) do
        createPlayerInfoCard(player)
    end

    -- Update loop: distance + auto-detect new/respawned players
    local checkTimer = 0
    playerInfoConnection = RunService.RenderStepped:Connect(function(dt)
        local myChar = LP.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local myPos = myHRP.Position

        -- Update distance for tracked players
        for i = #playerInfoBillboards, 1, -1 do
            local info = playerInfoBillboards[i]
            if not info.player or not info.player.Parent or not info.player.Character or not info.billboard.Parent then
                if info.billboard and info.billboard.Parent then
                    info.billboard:Destroy()
                end
                table.remove(playerInfoBillboards, i)
            else
                local tHRP = info.player.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local dist = math.floor((myPos - tHRP.Position).Magnitude)
                    info.distLabel.Text = dist .. " studs"
                end
            end
        end

        -- Check for new/respawned players every 2 seconds
        checkTimer = checkTimer + dt
        if checkTimer >= 2 then
            checkTimer = 0
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    local found = false
                    for _, info in ipairs(playerInfoBillboards) do
                        if info.player == player then
                            found = true
                            break
                        end
                    end
                    if not found then
                        createPlayerInfoCard(player)
                    end
                end
            end
        end
    end)

    notify("Player Info Cards ON", "success")
end

--==================================================
-- ANTI-AFK
--==================================================

startAntiAfk = function()
    if antiAfkActive then return end
    antiAfkActive = true
    antiAfkConnection = task.spawn(function()
        while antiAfkActive do
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            task.wait(60)
        end
    end)
    AntiAfkBtn.Text = "⚡ ANTI-AFK: ON"
    AntiAfkBtn.BackgroundColor3 = Colors.green
    notify("Anti-AFK ON", "success")
end

stopAntiAfk = function()
    antiAfkActive = false
    if antiAfkConnection then
        pcall(function() task.cancel(antiAfkConnection) end)
        antiAfkConnection = nil
    end
    AntiAfkBtn.Text = "⚡ ANTI-AFK: OFF"
    AntiAfkBtn.BackgroundColor3 = Color3.fromRGB(50, 25, 25)
    notify("Anti-AFK OFF", "info")
end

--==================================================
-- CHAT SPY
--==================================================

startChatSpy = function()
    if chatSpyActive then return end
    chatSpyActive = true
    chatSpyConnections = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local conn = player.Chatted:Connect(function(msg)
                if not chatSpyActive then return end
                table.insert(chatSpyLog, {
                    time = os.time(),
                    player = player.DisplayName,
                    message = msg,
                })
                if #chatSpyLog > 200 then
                    table.remove(chatSpyLog, 1)
                end
                refreshChatSpyLog()
            end)
            table.insert(chatSpyConnections, conn)
        end
    end

    -- Listen for new players joining
    local addedConn = Players.PlayerAdded:Connect(function(player)
        local conn = player.Chatted:Connect(function(msg)
            if not chatSpyActive then return end
            table.insert(chatSpyLog, {
                time = os.time(),
                player = player.DisplayName,
                message = msg,
            })
            if #chatSpyLog > 200 then
                table.remove(chatSpyLog, 1)
            end
            refreshChatSpyLog()
        end)
        table.insert(chatSpyConnections, conn)
    end)
    table.insert(chatSpyConnections, addedConn)

    ChatSpyToggleBtn.Text = "🛑 STOP SPY"
    ChatSpyToggleBtn.BackgroundColor3 = Colors.blood
    ChatSpyStatusLabel.Text = "Spy: ON"
    ChatSpyStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 100)
    notify("Chat Spy ON", "success")
end

stopChatSpy = function()
    chatSpyActive = false
    if chatSpyConnections then
        for _, conn in ipairs(chatSpyConnections) do
            pcall(function() conn:Disconnect() end)
        end
        chatSpyConnections = {}
    end
    ChatSpyToggleBtn.Text = "🕵 START SPY"
    ChatSpyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
    ChatSpyStatusLabel.Text = "Spy: OFF"
    ChatSpyStatusLabel.TextColor3 = Colors.textDim
    notify("Chat Spy OFF", "info")
end

--==================================================
-- EXECUTE SCRIPT
--==================================================

executeScript = function(code)
    if not code or code == "" then
        notify("No script to execute", "error")
        return
    end
    local ok, err = pcall(function()
        local fn = loadstring(code)
        if fn then
            fn()
        else
            error("Failed to parse script")
        end
    end)
    if ok then
        notify("Script executed!", "success")
    else
        notify("Error: " .. tostring(err):sub(1, 60), "error")
    end
end

--==================================================
-- COSMETICS
--==================================================

applyCosmeticHeadless = function()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 1
        local face = head:FindFirstChildOfClass("Decal") or head:FindFirstChild("face") or head:FindFirstChild("Face")
        if face then face.Transparency = 1 end
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("SpecialMesh") then
                child.Scale = Vector3.new(0, 0, 0)
            end
        end
    end
    -- Hide hat/hair accessories
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local handle = acc:FindFirstChild("Handle")
            if handle then
                local att = handle:FindFirstChildOfClass("Attachment")
                if att and (att.Name:find("Hat") or att.Name:find("Hair") or att.Name:find("Face")) then
                    handle.Transparency = 1
                end
            end
        end
    end
    cosmeticState.headless = true
    notify("Headless applied", "success")
end

removeCosmeticHeadless = function()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        local face = head:FindFirstChildOfClass("Decal") or head:FindFirstChild("face") or head:FindFirstChild("Face")
        if face then face.Transparency = 0 end
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("SpecialMesh") then
                child.Scale = Vector3.new(1, 1, 1)
            end
        end
    end
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local handle = acc:FindFirstChild("Handle")
            if handle then handle.Transparency = 0 end
        end
    end
    cosmeticState.headless = false
    notify("Headless removed", "info")
end

applyCosmeticInvisible = function()
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
        end
    end
    cosmeticState.invisible = true
    notify("Invisible applied", "success")
end

removeCosmeticInvisible = function()
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0
        elseif part:IsA("Decal") then
            part.Transparency = 0
        end
    end
    cosmeticState.invisible = false
    notify("Visible again", "info")
end

applyCosmeticGhost = function()
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0.7
        end
    end
    cosmeticState.ghost = true
    notify("Ghost mode applied", "success")
end

removeCosmeticGhost = function()
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0
        end
    end
    cosmeticState.ghost = false
    notify("Ghost removed", "info")
end

resetAllCosmetics = function()
    if cosmeticState.headless then removeCosmeticHeadless() end
    if cosmeticState.invisible then removeCosmeticInvisible() end
    if cosmeticState.ghost then removeCosmeticGhost() end
    notify("All cosmetics reset", "info")
end

--==================================================
-- EMOTE CATALOG SEARCH
--==================================================

searchEmoteCatalog = function(keyword)
    emoteSearchVersion = emoteSearchVersion + 1
    local thisVersion = emoteSearchVersion

    -- Clear grid
    for _, child in pairs(EmoteCatalogGrid:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end

    EmoteCatalogEmpty.Visible = false

    if keyword == nil or keyword == "" then
        -- Re-show trending if user clears search
        emoteTabPreloaded = false
        preloadTrendingEmotes()
        return
    end

    EmoteCatalogEmpty.Text = "Searching..."
    EmoteCatalogEmpty.Visible = true

    task.spawn(function()
        local params = CatalogSearchParams.new()
        params.AssetTypes = { Enum.AvatarAssetType.EmoteAnimation }
        params.SortType = Enum.CatalogSortType.Relevance
        params.SearchKeyword = keyword

        local ok, pages = pcall(function()
            return AvatarEditorService:SearchCatalog(params)
        end)

        if emoteSearchVersion ~= thisVersion then return end

        if not ok or not pages then
            EmoteCatalogEmpty.Text = "Search failed (AvatarEditorService)"
            EmoteCatalogEmpty.Visible = true
            log("Emote search failed:", tostring(pages))
            return
        end

        local pageOk, items = pcall(function()
            return pages:GetCurrentPage()
        end)

        if not pageOk or not items or #items == 0 then
            EmoteCatalogEmpty.Text = "No emotes found"
            EmoteCatalogEmpty.Visible = true
            return
        end

        EmoteCatalogEmpty.Visible = false
        emoteCatalogPages = pages
        emoteCatalogHasMore = not pages.IsFinished

        populateEmoteCatalogGrid(items, false)
    end)
end

populateEmoteCatalogGrid = function(items, append)
    if not append then
        for _, child in pairs(EmoteCatalogGrid:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
        end
    end

    for _, item in ipairs(items) do
        local card = Instance.new("TextButton")
        card.Size = UDim2.new(0, 60, 0, 82)
        card.BackgroundColor3 = Colors.card
        card.AutoButtonColor = false
        card.BorderSizePixel = 0
        card.Text = ""
        card.Parent = EmoteCatalogGrid
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

        -- Thumbnail
        local isBundle = item.BundleType ~= nil
        local thumbType = isBundle and "BundleThumbnail" or "Asset"
        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(1, -4, 0, 52)
        thumb.Position = UDim2.new(0, 2, 0, 2)
        thumb.BackgroundTransparency = 1
        thumb.Image = "rbxthumb://type=" .. thumbType .. "&id=" .. tostring(item.Id) .. "&w=150&h=150"
        thumb.ScaleType = Enum.ScaleType.Fit
        thumb.Parent = card

        -- Name label
        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(1, -4, 0, 24)
        nameL.Position = UDim2.new(0, 2, 0, 56)
        nameL.BackgroundTransparency = 1
        nameL.Text = item.Name or "Emote"
        nameL.TextColor3 = Colors.textDim
        nameL.TextSize = 8
        nameL.Font = Enum.Font.GothamBold
        nameL.TextXAlignment = Enum.TextXAlignment.Center
        nameL.TextTruncate = Enum.TextTruncate.AtEnd
        nameL.TextWrapped = true
        nameL.Parent = card

        -- Favorite star button
        local isFav = isFavoriteEmote(item.Id)
        local starBtn = Instance.new("TextButton")
        starBtn.Size = UDim2.new(0, 16, 0, 16)
        starBtn.Position = UDim2.new(1, -18, 0, 64)
        starBtn.BackgroundTransparency = 1
        starBtn.Text = isFav and "★" or "☆"
        starBtn.TextSize = 12
        starBtn.TextColor3 = isFav and Color3.fromRGB(255, 200, 50) or Colors.textDim
        starBtn.Parent = card

        starBtn.MouseButton1Click:Connect(function()
            local added = toggleFavoriteEmote(item.Id, item.Name or "Emote", isBundle)
            starBtn.Text = added and "★" or "☆"
            starBtn.TextColor3 = added and Color3.fromRGB(255, 200, 50) or Colors.textDim
        end)

        -- Click to play
        card.MouseButton1Click:Connect(function()
            playEmote(item.Id)
        end)

        makeHoverable(card, Colors.card, Colors.surfaceLight)
    end

    -- Update grid height based on content
    local childCount = 0
    for _, child in pairs(EmoteCatalogGrid:GetChildren()) do
        if child:IsA("TextButton") then childCount = childCount + 1 end
    end
    local cols = math.max(1, math.floor(EmoteCatalogGrid.AbsoluteSize.X / 66))
    if cols < 1 then cols = 5 end
    local rows = math.ceil(childCount / cols)
    EmoteCatalogGrid.Size = UDim2.new(1, 0, 0, math.max(rows * 88, 88))

    -- Refresh scroll canvas
    recalcEmoteLayout()
end

loadMoreEmotes = function()
    if not emoteCatalogHasMore or not emoteCatalogPages or isLoadingMoreEmotes then return end
    isLoadingMoreEmotes = true

    task.spawn(function()
        local ok = pcall(function()
            emoteCatalogPages:AdvanceToNextPageAsync()
        end)
        if not ok then
            isLoadingMoreEmotes = false
            return
        end

        local pageOk, items = pcall(function()
            return emoteCatalogPages:GetCurrentPage()
        end)

        isLoadingMoreEmotes = false

        if not pageOk or not items or #items == 0 then
            emoteCatalogHasMore = false
            return
        end

        emoteCatalogHasMore = not emoteCatalogPages.IsFinished
        populateEmoteCatalogGrid(items, true)
    end)
end

--==================================================
-- PRE-LOAD POPULAR EMOTES
--==================================================

preloadTrendingEmotes = function()
    if emoteTabPreloaded then return end
    emoteTabPreloaded = true

    EmoteCatalogEmpty.Text = "Loading popular emotes..."
    EmoteCatalogEmpty.Visible = true

    -- Clear grid
    for _, child in pairs(EmoteCatalogGrid:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end

    emoteSearchVersion = emoteSearchVersion + 1
    local thisVersion = emoteSearchVersion

    task.spawn(function()
        local params = CatalogSearchParams.new()
        params.AssetTypes = { Enum.AvatarAssetType.EmoteAnimation }
        params.SortType = Enum.CatalogSortType.MostFavorited

        local ok, pages = pcall(function()
            return AvatarEditorService:SearchCatalog(params)
        end)

        if emoteSearchVersion ~= thisVersion then return end

        if not ok or not pages then
            EmoteCatalogEmpty.Text = "Failed to load popular emotes"
            EmoteCatalogEmpty.Visible = true
            emoteTabPreloaded = false
            return
        end

        local pageOk, items = pcall(function()
            return pages:GetCurrentPage()
        end)

        if not pageOk or not items or #items == 0 then
            EmoteCatalogEmpty.Text = "No popular emotes found"
            EmoteCatalogEmpty.Visible = true
            return
        end

        EmoteCatalogEmpty.Visible = false
        emoteCatalogPages = pages
        emoteCatalogHasMore = not pages.IsFinished

        populateEmoteCatalogGrid(items, false)
    end)
end

--==================================================
-- FAVORITE EMOTES
--==================================================

loadFavoriteEmotes = function()
    favoriteEmotes = {}
    pcall(function()
        if isfile and isfile("VampireFavoriteEmotes.json") then
            local raw = readfile("VampireFavoriteEmotes.json")
            local parsed = HttpService:JSONDecode(raw)
            if type(parsed) == "table" then
                favoriteEmotes = parsed
            end
        end
    end)
    refreshFavoriteGrid()
end

saveFavoriteEmotes = function()
    pcall(function()
        if writefile then
            writefile("VampireFavoriteEmotes.json", HttpService:JSONEncode(favoriteEmotes))
        end
    end)
end

toggleFavoriteEmote = function(id, name, isBundle)
    -- Check if already favorited
    for i, fav in ipairs(favoriteEmotes) do
        if fav.id == id then
            table.remove(favoriteEmotes, i)
            saveFavoriteEmotes()
            refreshFavoriteGrid()
            notify("Removed from favorites", "info")
            return false
        end
    end
    -- Add new favorite
    table.insert(favoriteEmotes, { id = id, name = name, isBundle = isBundle or false })
    saveFavoriteEmotes()
    refreshFavoriteGrid()
    notify("Added to favorites!", "success")
    return true
end

isFavoriteEmote = function(id)
    for _, fav in ipairs(favoriteEmotes) do
        if fav.id == id then return true end
    end
    return false
end

refreshFavoriteGrid = function()
    -- Clear existing children
    for _, child in pairs(EmoteFavGrid:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end

    if #favoriteEmotes == 0 then
        EmoteFavEmpty.Visible = true
        EmoteFavGrid.Size = UDim2.new(1, 0, 0, 24)
    else
        EmoteFavEmpty.Visible = false

        for idx, fav in ipairs(favoriteEmotes) do
            local card = Instance.new("TextButton")
            card.Size = UDim2.new(0, 60, 0, 82)
            card.BackgroundColor3 = Colors.card
            card.AutoButtonColor = false
            card.BorderSizePixel = 0
            card.Text = ""
            card.LayoutOrder = idx
            card.Parent = EmoteFavGrid
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

            -- Thumbnail
            local thumbType = fav.isBundle and "BundleThumbnail" or "Asset"
            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(1, -4, 0, 44)
            thumb.Position = UDim2.new(0, 2, 0, 2)
            thumb.BackgroundTransparency = 1
            thumb.Image = "rbxthumb://type=" .. thumbType .. "&id=" .. tostring(fav.id) .. "&w=150&h=150"
            thumb.ScaleType = Enum.ScaleType.Fit
            thumb.Parent = card

            -- Name label
            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -4, 0, 18)
            nameL.Position = UDim2.new(0, 2, 0, 48)
            nameL.BackgroundTransparency = 1
            nameL.Text = fav.name or "Emote"
            nameL.TextColor3 = Colors.textDim
            nameL.TextSize = 8
            nameL.Font = Enum.Font.GothamBold
            nameL.TextXAlignment = Enum.TextXAlignment.Center
            nameL.TextTruncate = Enum.TextTruncate.AtEnd
            nameL.TextWrapped = true
            nameL.Parent = card

            -- Unfavorite star button
            local starBtn = Instance.new("TextButton")
            starBtn.Size = UDim2.new(0, 16, 0, 16)
            starBtn.Position = UDim2.new(1, -18, 0, 64)
            starBtn.BackgroundTransparency = 1
            starBtn.Text = "★"
            starBtn.TextSize = 12
            starBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
            starBtn.Parent = card

            starBtn.MouseButton1Click:Connect(function()
                toggleFavoriteEmote(fav.id, fav.name, fav.isBundle)
            end)

            -- Click card to play
            card.MouseButton1Click:Connect(function()
                playEmote(fav.id)
            end)

            makeHoverable(card, Colors.card, Colors.surfaceLight)
        end

        -- Calculate grid height
        local cols = math.max(1, math.floor(EmoteFavGrid.AbsoluteSize.X / 66))
        if cols < 1 then cols = 3 end
        local rows = math.ceil(#favoriteEmotes / cols)
        EmoteFavGrid.Size = UDim2.new(1, 0, 0, math.max(rows * 88, 88))
    end

    -- Recalculate layout of everything below favorites
    recalcEmoteLayout()
end


--[[ ═══════ MODULE: 22_events.luau ═══════ ]]

--==================================================
-- EVENTS
--==================================================

--==================================================
-- SCANNER TAB EVENTS
--==================================================

ScanBtn.MouseButton1Click:Connect(function()
    runScan()
end)

ExportBtn.MouseButton1Click:Connect(function()
    exportAllJSON()
end)

CopyBtn.MouseButton1Click:Connect(copyToClipboard)

-- Search filter
SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    filterResults(SearchBar.Text)
end)

-- Auto-scan toggle
AutoScanToggle.btn.MouseButton1Click:Connect(function()
    autoScanConfig.enabled = not autoScanConfig.enabled
    AutoScanToggle.refresh()
    autoScanSettingToggle.refresh() -- sync settings tab
    if autoScanConfig.enabled then
        startAutoScan()
    else
        stopAutoScan()
    end
end)

-- Unspectate (scanner + player tabs)
UnspectateBtn.MouseButton1Click:Connect(function()
    stopSpectate()
end)

PlayerUnspectateBtn.MouseButton1Click:Connect(function()
    stopSpectate()
end)

--==================================================
-- ESP TAB EVENTS
--==================================================

for feature, toggle in pairs(espToggles) do
    toggle.btn.MouseButton1Click:Connect(function()
        toggleESPFeature(feature)
    end)
end

-- Footsteps toggle (separate from espToggles)
FootstepsToggle.btn.MouseButton1Click:Connect(function()
    if espState.footsteps then
        stopFootsteps()
    else
        startFootsteps()
    end
end)

-- Sound ESP toggle (separate from espToggles)
SoundESPToggle.btn.MouseButton1Click:Connect(function()
    if espState.soundESP then
        stopSoundESP()
    else
        startSoundESP()
    end
end)

ESPOffBtn.MouseButton1Click:Connect(function()
    -- Stop separate systems first
    if espState.footsteps then stopFootsteps() end
    if espState.soundESP then stopSoundESP() end
    -- Stop aimbot
    if aimbotState.enabled then
        aimbotState.enabled = false
        AimbotToggle.refresh()
        stopAimbot()
    end
    -- Reset all state
    for k in pairs(espState) do
        espState[k] = false
    end
    clearESP()
    for _, toggle in pairs(espToggles) do
        toggle.refresh()
    end
    FootstepsToggle.refresh()
    SoundESPToggle.refresh()
    ESPStatusLabel.Text = "ESP OFF — toggle features above"
    notify("All ESP disabled", "info")
end)

-- Aimbot toggle
AimbotToggle.btn.MouseButton1Click:Connect(function()
    aimbotState.enabled = not aimbotState.enabled
    AimbotToggle.refresh()
    if aimbotState.enabled then
        startAimbot()
    else
        stopAimbot()
    end
end)

-- Aimbot team check toggle
AimbotTeamCheckToggle.btn.MouseButton1Click:Connect(function()
    aimbotState.teamCheck = not aimbotState.teamCheck
    AimbotTeamCheckToggle.refresh()
end)

--==================================================
-- PLAYER TAB EVENTS
--==================================================

RefreshPlayersBtn.MouseButton1Click:Connect(function()
    refreshPlayerList(PlayerSearchBox.Text)
    notify("Player list refreshed", "info")
end)

-- Player search filter
do
    local playerFilterTimer = nil
    PlayerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if playerFilterTimer then
            task.cancel(playerFilterTimer)
        end
        playerFilterTimer = task.delay(0.3, function()
            playerFilterTimer = nil
            refreshPlayerList(PlayerSearchBox.Text)
        end)
    end)
end

-- Auto-refresh when tab switches to player
-- (handled in switchTab below)

--==================================================
-- MOVEMENT TAB EVENTS
--==================================================

moveToggles.fly.btn.MouseButton1Click:Connect(function()
    movementState.fly = not movementState.fly
    moveToggles.fly.refresh()
    if movementState.fly then
        startFly()
    else
        stopFly()
    end
end)

moveToggles.noclip.btn.MouseButton1Click:Connect(function()
    movementState.noclip = not movementState.noclip
    moveToggles.noclip.refresh()
    toggleNoclip()
end)

moveToggles.infiniteJump.btn.MouseButton1Click:Connect(function()
    movementState.infiniteJump = not movementState.infiniteJump
    moveToggles.infiniteJump.refresh()
    toggleInfiniteJump()
end)

moveToggles.freecam.btn.MouseButton1Click:Connect(function()
    movementState.freecam = not movementState.freecam
    moveToggles.freecam.refresh()
    if movementState.freecam then
        startFreecam()
    else
        stopFreecam()
    end
end)

-- ClickTP toggle
moveToggles.clickTP.btn.MouseButton1Click:Connect(function()
    movementState.clickTP = not movementState.clickTP
    moveToggles.clickTP.refresh()
    if movementState.clickTP then
        startClickTP()
    else
        stopClickTP()
    end
end)

-- AntiVoid toggle
moveToggles.antiVoid.btn.MouseButton1Click:Connect(function()
    movementState.antiVoid = not movementState.antiVoid
    moveToggles.antiVoid.refresh()
    if movementState.antiVoid then
        startAntiVoid()
    else
        stopAntiVoid()
    end
end)

-- Spin toggle
moveToggles.spin.btn.MouseButton1Click:Connect(function()
    movementState.spin = not movementState.spin
    moveToggles.spin.refresh()
    if movementState.spin then
        startSpin()
    else
        stopSpin()
    end
end)

-- Flashback buttons
FlashbackSaveBtn.MouseButton1Click:Connect(function()
    saveFlashback()
end)

FlashbackRecallBtn.MouseButton1Click:Connect(function()
    doFlashback()
end)

-- feFlip button
FeFlipBtn.MouseButton1Click:Connect(function()
    doFeFlip()
end)

ResetMoveBtn.MouseButton1Click:Connect(function()
    -- Stop all
    if movementState.fly then
        movementState.fly = false
        moveToggles.fly.refresh()
        stopFly()
    end
    if movementState.noclip then
        movementState.noclip = false
        moveToggles.noclip.refresh()
        toggleNoclip()
    end
    if movementState.infiniteJump then
        movementState.infiniteJump = false
        moveToggles.infiniteJump.refresh()
        toggleInfiniteJump()
    end
    if movementState.freecam then
        movementState.freecam = false
        moveToggles.freecam.refresh()
        stopFreecam()
    end
    if movementState.clickTP then
        movementState.clickTP = false
        moveToggles.clickTP.refresh()
        stopClickTP()
    end
    if movementState.antiVoid then
        movementState.antiVoid = false
        moveToggles.antiVoid.refresh()
        stopAntiVoid()
    end
    if movementState.spin then
        movementState.spin = false
        moveToggles.spin.refresh()
        stopSpin()
    end
    -- Reset speed
    movementState.speed = 16
    movementState.jumpPower = 50
    movementState.spinSpeed = 10
    speedSlider.setValue(16)
    jumpSlider.setValue(50)
    spinSpeedSlider.setValue(10)
    applySpeed()
    notify("Movement reset", "info")
end)

-- Apply speed on character spawn
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    applySpeed()
end)

--==================================================
-- EMOTE TAB EVENTS
--==================================================

PauseEmoteBtn.MouseButton1Click:Connect(function()
    if emotePaused then
        resumeEmote()
        PauseEmoteBtn.Text = "⏸ PAUSE"
        PauseEmoteBtn.BackgroundColor3 = Colors.warning
    else
        pauseEmote()
        PauseEmoteBtn.Text = "▶ RESUME"
        PauseEmoteBtn.BackgroundColor3 = Colors.green
    end
end)

StopEmoteBtn.MouseButton1Click:Connect(function()
    stopEmote()
    PauseEmoteBtn.Text = "⏸ PAUSE"
    PauseEmoteBtn.BackgroundColor3 = Colors.warning
end)

-- Emote catalog search (debounced 0.4s) — ignora IDs numericos (tratados no Enter)
do
    local emoteSearchTimer = nil
    EmoteSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if emoteSearchTimer then
            task.cancel(emoteSearchTimer)
        end
        local text = EmoteSearchBox.Text
        -- Se for numero puro, nao faz catalog search (espera Enter)
        if string.match(text, "^%d+$") then return end
        emoteSearchTimer = task.delay(0.4, function()
            emoteSearchTimer = nil
            searchEmoteCatalog(EmoteSearchBox.Text)
        end)
    end)
end

-- Enter no search box: se for ID numerico, toca direto; senao busca catalogo
EmoteSearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local text = EmoteSearchBox.Text
        if string.match(text, "^%d+$") then
            local id = tonumber(text)
            if id and id > 0 then
                playEmote(id)
            end
        else
            searchEmoteCatalog(text)
        end
    end
end)

-- Emote catalog scroll pagination (load more near bottom)
EmoteScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    local scrollPos = EmoteScroll.CanvasPosition.Y
    local canvasH = EmoteScroll.CanvasSize.Y.Offset
    local frameH = EmoteScroll.AbsoluteSize.Y
    if canvasH > 0 and (scrollPos + frameH) >= (canvasH - 60) then
        loadMoreEmotes()
    end
end)

--==================================================
-- SYNC PLAYERS EVENTS
--==================================================

-- Atualiza texto do header com contagem de synced
updateSyncHeaderText = function()
    local sc = 0
    for _ in pairs(syncPlayers) do sc = sc + 1 end
    local arrow = SyncPlayersExpanded and "▾" or "▸"
    SyncPlayersHeader.Text = arrow .. " Sync Players (" .. sc .. " synced)"
end
updateSyncHeaderText()

-- Toggle expand/collapse
SyncPlayersHeader.MouseButton1Click:Connect(function()
    SyncPlayersExpanded = not SyncPlayersExpanded
    updateSyncHeaderText()
    if SyncPlayersExpanded then
        refreshSyncPlayerList(SyncSearchBox.Text)
    end
    recalcEmoteLayout()
end)

-- Refresh player list
SyncRefreshBtn.MouseButton1Click:Connect(function()
    refreshSyncPlayerList(SyncSearchBox.Text)
end)

-- Search filter (debounced 0.3s)
do
    local syncSearchTimer = nil
    SyncSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if syncSearchTimer then
            task.cancel(syncSearchTimer)
        end
        syncSearchTimer = task.delay(0.3, function()
            syncSearchTimer = nil
            refreshSyncPlayerList(SyncSearchBox.Text)
        end)
    end)
end

-- Select All
SyncSelectAllBtn.MouseButton1Click:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            syncPlayers[plr] = true
        end
    end
    -- If emote is playing, sync all new players
    if currentEmoteAnimId and currentEmoteTrack then
        local animIdStr = resolveAnimId(currentEmoteAnimId)
        for plr, _ in pairs(syncPlayers) do
            if plr ~= LP and not syncTracks[plr] and plr.Character then
                local trk = playEmoteOnCharacter(plr.Character, animIdStr)
                if trk then
                    syncTracks[plr] = trk
                    if emotePaused then
                        pcall(function() trk:AdjustSpeed(0) end)
                    end
                end
            end
        end
    end
    refreshSyncPlayerList(SyncSearchBox.Text)
end)

-- Deselect All
SyncDeselectAllBtn.MouseButton1Click:Connect(function()
    syncStopEmote()
    syncPlayers = {}
    refreshSyncPlayerList(SyncSearchBox.Text)
end)

-- Clean up sync tracks when players leave
Players.PlayerRemoving:Connect(function(plr)
    syncPlayers[plr] = nil
    if syncTracks[plr] then
        pcall(function() syncTracks[plr]:Stop() end)
        pcall(function() syncTracks[plr]:Destroy() end)
        syncTracks[plr] = nil
    end
    -- Auto-refresh if the list is visible
    if activeTab == "emote" then
        refreshSyncPlayerList(SyncSearchBox.Text)
    end
end)

-- Auto-refresh when new player joins
Players.PlayerAdded:Connect(function(plr)
    if activeTab == "emote" then
        task.wait(1) -- small delay for character to load
        refreshSyncPlayerList(SyncSearchBox.Text)
    end
end)

--==================================================
-- SHADOW PANEL EVENTS
--==================================================

-- Shadow preset buttons
for _, data in ipairs(shadowPresetButtons) do
    data.btn.MouseButton1Click:Connect(function()
        local def = data.def
        if def.mode == "head" then
            if shadowState.active and shadowState.mode == "head" then
                stopShadow()
            else
                startShadow("head")
            end
        else
            -- Orbit mode: set angle, height, faceTarget, then start
            shadowState.angle = def.angle
            shadowState.height = def.height
            shadowState.faceTarget = def.faceTarget
            ShadowPanelAngleSlider.setValue(def.angle)
            ShadowPanelHeightSlider.setValue(def.height)
            ShadowFaceTargetToggle.refresh()
            startShadow("orbit")
        end
    end)
end

-- Face Target toggle
ShadowFaceTargetToggle.btn.MouseButton1Click:Connect(function()
    shadowState.faceTarget = not shadowState.faceTarget
    ShadowFaceTargetToggle.refresh()
end)

-- Mirror Anims toggle
ShadowMirrorAnimsToggle.btn.MouseButton1Click:Connect(function()
    shadowState.mirrorAnims = not shadowState.mirrorAnims
    ShadowMirrorAnimsToggle.refresh()
    -- If turning off mirror, clean up existing mirrored tracks
    if not shadowState.mirrorAnims and shadowMirroredTracks then
        for id, track in pairs(shadowMirroredTracks) do
            pcall(function() track:Stop() end)
            pcall(function() track:Destroy() end)
        end
        shadowMirroredTracks = {}
        -- Restart idle animation
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                pcall(function()
                    for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                        t:Stop(0)
                    end
                end)
            end
            local animScript = char:FindFirstChild("Animate")
            if animScript then
                pcall(function()
                    animScript.Disabled = true
                    task.delay(0.1, function()
                        if animScript and animScript.Parent then
                            animScript.Disabled = false
                        end
                    end)
                end)
            end
        end
    end
end)

-- Auto-Orbit toggle
ShadowAutoOrbitToggle.btn.MouseButton1Click:Connect(function()
    shadowState.autoOrbit = not shadowState.autoOrbit
    ShadowAutoOrbitToggle.refresh()
end)

-- Trail toggle
ShadowTrailToggle.btn.MouseButton1Click:Connect(function()
    shadowState.trail = not shadowState.trail
    ShadowTrailToggle.refresh()
    if shadowState.trail and shadowState.active then
        applyShadowTrail()
    elseif not shadowState.trail then
        removeShadowTrail()
    end
end)

-- Record button
ShadowRecBtn.MouseButton1Click:Connect(function()
    if shadowRecording then
        stopShadowRecording()
    else
        if not shadowState.active then
            notify("Start shadow first to record", "warning")
            return
        end
        startShadowRecording()
    end
end)

-- Replay button
ShadowPlayReplayBtn.MouseButton1Click:Connect(function()
    if shadowReplaying then
        stopShadowReplay()
    else
        startShadowReplay()
    end
end)

-- Reset button — resets all shadow settings to defaults
ShadowResetBtn.MouseButton1Click:Connect(function()
    shadowState.angle = 0
    shadowState.height = 0
    shadowState.distance = 4
    shadowState.delay = 0
    shadowState.faceTarget = false
    shadowState.mirrorAnims = true
    shadowState.autoOrbit = false
    shadowState.orbitSpeed = 2
    shadowState.trail = false
    -- Sync UI
    ShadowPanelAngleSlider.setValue(0)
    ShadowPanelHeightSlider.setValue(0)
    ShadowPanelDistSlider.setValue(4)
    ShadowPanelDelaySlider.setValue(0)
    ShadowOrbitSpeedSlider.setValue(2)
    ShadowFaceTargetToggle.refresh()
    ShadowMirrorAnimsToggle.refresh()
    ShadowAutoOrbitToggle.refresh()
    ShadowTrailToggle.refresh()
    refreshShadowModeButtons()
    removeShadowTrail()
    notify("Shadow settings reset", "info")
end)

StopShadowBtn.MouseButton1Click:Connect(function()
    if shadowRecording then stopShadowRecording() end
    if shadowReplaying then stopShadowReplay() end
    stopShadow()
    ShadowMirrorAnimsToggle.refresh()
    ShadowAutoOrbitToggle.refresh()
    ShadowTrailToggle.refresh()
end)

ShadowPanelClose.MouseButton1Click:Connect(function()
    if shadowRecording then stopShadowRecording() end
    if shadowReplaying then stopShadowReplay() end
    stopShadow()
    ShadowMirrorAnimsToggle.refresh()
    ShadowAutoOrbitToggle.refresh()
    ShadowPanel.Visible = false
end)

--==================================================
-- TROLL PANEL EVENTS
--==================================================

TrollFlingBtn.MouseButton1Click:Connect(function()
    if trollTarget then flingPlayer(trollTarget) end
end)

TrollHeadsitBtn.MouseButton1Click:Connect(function()
    if trollTarget then headsitPlayer(trollTarget) end
end)

TrollBangBtn.MouseButton1Click:Connect(function()
    if trollTarget then bangPlayer(trollTarget) end
end)

TrollBackpackBtn.MouseButton1Click:Connect(function()
    if trollTarget then backpackPlayer(trollTarget) end
end)

TrollBang2Btn.MouseButton1Click:Connect(function()
    if trollTarget then bangFrontPlayer(trollTarget) end
end)

TrollOrbitBtn.MouseButton1Click:Connect(function()
    if trollTarget then orbitTrollPlayer(trollTarget) end
end)

TrollFlingAllBtn.MouseButton1Click:Connect(function()
    flingAllPlayers()
end)

TrollHelicopterBtn.MouseButton1Click:Connect(function()
    if trollTarget then helicopterPlayer(trollTarget) end
end)

TrollSpinTopBtn.MouseButton1Click:Connect(function()
    if trollTarget then spinTopPlayer(trollTarget) end
end)

TrollTrampolineBtn.MouseButton1Click:Connect(function()
    if trollTarget then trampolinePlayer(trollTarget) end
end)

TrollCreepBtn.MouseButton1Click:Connect(function()
    if trollTarget then creepPlayer(trollTarget) end
end)

TrollLaunchBtn.MouseButton1Click:Connect(function()
    if trollTarget then launchPlayer(trollTarget) end
end)

TrollCarpetBtn.MouseButton1Click:Connect(function()
    if trollTarget then carpetPlayer(trollTarget) end
end)

TrollDizzyBtn.MouseButton1Click:Connect(function()
    if trollTarget then dizzyPlayer(trollTarget) end
end)

TrollMagnetBtn.MouseButton1Click:Connect(function()
    if trollTarget then magnetPlayer(trollTarget) end
end)

TrollCloneBtn.MouseButton1Click:Connect(function()
    if trollTarget then clonePlayer(trollTarget) end
end)

TrollUpsideDownBtn.MouseButton1Click:Connect(function()
    if trollTarget then upsideDownPlayer(trollTarget) end
end)

TrollTornadoBtn.MouseButton1Click:Connect(function()
    if trollTarget then tornadoPlayer(trollTarget) end
end)

TrollSnakeBtn.MouseButton1Click:Connect(function()
    if trollTarget then snakePlayer(trollTarget) end
end)

TrollMirrorBtn.MouseButton1Click:Connect(function()
    if trollTarget then mirrorPlayer(trollTarget) end
end)

TrollStackBtn.MouseButton1Click:Connect(function()
    if trollTarget then stackPlayer(trollTarget) end
end)

TrollFigure8Btn.MouseButton1Click:Connect(function()
    if trollTarget then figure8Player(trollTarget) end
end)

TrollDogBtn.MouseButton1Click:Connect(function()
    if trollTarget then dogPlayer(trollTarget) end
end)

TrollFerrisBtn.MouseButton1Click:Connect(function()
    if trollTarget then ferrisPlayer(trollTarget) end
end)

TrollSalsaBtn.MouseButton1Click:Connect(function()
    if trollTarget then salsaPlayer(trollTarget) end
end)

TrollUfoBtn.MouseButton1Click:Connect(function()
    if trollTarget then ufoPlayer(trollTarget) end
end)

TrollBoomerangBtn.MouseButton1Click:Connect(function()
    if trollTarget then boomerangPlayer(trollTarget) end
end)

TrollRollerBtn.MouseButton1Click:Connect(function()
    if trollTarget then rollerPlayer(trollTarget) end
end)

TrollSpiralBtn.MouseButton1Click:Connect(function()
    if trollTarget then spiralPlayer(trollTarget) end
end)

TrollSurfBtn.MouseButton1Click:Connect(function()
    if trollTarget then surfPlayer(trollTarget) end
end)

TrollBouncerBtn.MouseButton1Click:Connect(function()
    if trollTarget then bouncerPlayer(trollTarget) end
end)

TrollLapSitBtn.MouseButton1Click:Connect(function()
    if trollTarget then lapSitPlayer(trollTarget) end
end)

TrollWaveBtn.MouseButton1Click:Connect(function()
    if trollTarget then wavePlayer(trollTarget) end
end)

TrollParasiteBtn.MouseButton1Click:Connect(function()
    if trollTarget then parasitePlayer(trollTarget) end
end)

TrollStalkBtn.MouseButton1Click:Connect(function()
    if trollTarget then stalkPlayer(trollTarget) end
end)

TrollPushBtn.MouseButton1Click:Connect(function()
    if trollTarget then pushPlayer(trollTarget) end
end)

TrollSwapBtn.MouseButton1Click:Connect(function()
    if trollTarget then swapPlayer(trollTarget) end
end)

TrollJailBtn.MouseButton1Click:Connect(function()
    if trollTarget then jailPlayer(trollTarget) end
end)

TrollStopBtn.MouseButton1Click:Connect(function()
    stopTroll()
    notify("Troll stopped", "info")
end)

TrollPanelClose.MouseButton1Click:Connect(function()
    stopTroll()
    TrollPanel.Visible = false
end)

TrollCloseBottomBtn.MouseButton1Click:Connect(function()
    stopTroll()
    TrollPanel.Visible = false
end)

--==================================================
-- SETTINGS TAB EVENTS
--==================================================

spectateHLToggle.btn.MouseButton1Click:Connect(function()
    spectateConfig.showHighlight = not spectateConfig.showHighlight
    spectateHLToggle.refresh()
    -- Apply immediately if spectating
    if spectatingInfo then
        if spectateConfig.showHighlight then
            local targetChar = spectatingInfo.character
            if spectatingInfo.player and spectatingInfo.player.Character then
                targetChar = spectatingInfo.player.Character
            end
            if targetChar and not spectateHighlight then
                spectateHighlight = Instance.new("Highlight")
                spectateHighlight.Name = "VampSpectateHL"
                spectateHighlight.FillColor = Colors.blood
                spectateHighlight.FillTransparency = 0.7
                spectateHighlight.OutlineColor = Colors.bloodLight
                spectateHighlight.OutlineTransparency = 0
                spectateHighlight.Adornee = targetChar
                spectateHighlight.Parent = targetChar
            end
        else
            if spectateHighlight then
                spectateHighlight:Destroy()
                spectateHighlight = nil
            end
        end
    end
end)

autoScanSettingToggle.btn.MouseButton1Click:Connect(function()
    autoScanConfig.enabled = not autoScanConfig.enabled
    autoScanSettingToggle.refresh()
    -- Sync with scanner tab toggle
    AutoScanToggle.refresh()
    if autoScanConfig.enabled then
        startAutoScan()
    else
        stopAutoScan()
    end
end)

--==================================================
-- COSMETIC EVENTS
--==================================================

cosmeticHeadlessToggle.btn.MouseButton1Click:Connect(function()
    if cosmeticState.headless then
        removeCosmeticHeadless()
    else
        applyCosmeticHeadless()
    end
    cosmeticHeadlessToggle.refresh()
end)

cosmeticInvisibleToggle.btn.MouseButton1Click:Connect(function()
    if cosmeticState.invisible then
        removeCosmeticInvisible()
    else
        -- Turn off ghost if going invisible
        if cosmeticState.ghost then
            removeCosmeticGhost()
            cosmeticGhostToggle.refresh()
        end
        applyCosmeticInvisible()
    end
    cosmeticInvisibleToggle.refresh()
end)

cosmeticGhostToggle.btn.MouseButton1Click:Connect(function()
    if cosmeticState.ghost then
        removeCosmeticGhost()
    else
        -- Turn off invisible if going ghost
        if cosmeticState.invisible then
            removeCosmeticInvisible()
            cosmeticInvisibleToggle.refresh()
        end
        applyCosmeticGhost()
    end
    cosmeticGhostToggle.refresh()
end)

cosmeticHideNametagsToggle.btn.MouseButton1Click:Connect(function()
    cosmeticState.hideNametags = not cosmeticState.hideNametags
    cosmeticHideNametagsToggle.refresh()

    if cosmeticState.hideNametags then
        -- Esconder nametags do jogo (BillboardGui em Head de todos players)
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                local char = player.Character
                if not char then return end
                local head = char:FindFirstChild("Head")
                if not head then return end
                for _, child in ipairs(head:GetChildren()) do
                    if child:IsA("BillboardGui") and child.Name ~= "VampNametag" then
                        child:SetAttribute("VampHiddenNametag", true)
                        child.Enabled = false
                    end
                end
                -- Também esconder no Humanoid (DisplayName overhead)
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                end
            end)
        end
        -- Esconder VampNametag própria
        pcall(function()
            local char = LP.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head then
                    local vt = head:FindFirstChild("VampNametag")
                    if vt then vt.Enabled = false end
                end
            end
        end)
        -- Listener pra novos personagens
        nametagHideConn = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(char)
                if not cosmeticState.hideNametags then return end
                task.wait(1)
                pcall(function()
                    local head = char:WaitForChild("Head", 5)
                    if not head then return end
                    for _, child in ipairs(head:GetChildren()) do
                        if child:IsA("BillboardGui") and child.Name ~= "VampNametag" then
                            child:SetAttribute("VampHiddenNametag", true)
                            child.Enabled = false
                        end
                    end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    end
                end)
            end)
        end)
        notify("All nametags hidden", "success")
    else
        -- Restaurar nametags do jogo
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                local char = player.Character
                if not char then return end
                local head = char:FindFirstChild("Head")
                if head then
                    for _, child in ipairs(head:GetChildren()) do
                        if child:IsA("BillboardGui") and child:GetAttribute("VampHiddenNametag") then
                            child.Enabled = true
                            child:SetAttribute("VampHiddenNametag", nil)
                        end
                    end
                end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                end
            end)
        end
        -- Restaurar VampNametag própria
        pcall(function()
            local char = LP.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head then
                    local vt = head:FindFirstChild("VampNametag")
                    if vt then vt.Enabled = true end
                end
            end
        end)
        -- Desconectar listener
        if nametagHideConn then
            nametagHideConn:Disconnect()
            nametagHideConn = nil
        end
        notify("Nametags restored", "info")
    end
end)

-- Hide/Show Script Nametag (VampNametag)
cosmeticHideVampTagToggle.btn.MouseButton1Click:Connect(function()
    cosmeticState.hideVampNametag = not cosmeticState.hideVampNametag
    cosmeticHideVampTagToggle.refresh()

    local char = LP.Character
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            local vt = head:FindFirstChild("VampNametag")
            if cosmeticState.hideVampNametag then
                if vt then vt:Destroy() end
                notify("Script nametag hidden", "info")
            else
                if not vt then createVampireNametag(char) end
                notify("Script nametag restored", "success")
            end
        end
    end
end)

cosmeticHideGameUIToggle.btn.MouseButton1Click:Connect(function()
    cosmeticState.hideGameUI = not cosmeticState.hideGameUI
    cosmeticHideGameUIToggle.refresh()

    if cosmeticState.hideGameUI then
        -- Esconder CoreGui (chat, leaderboard, health, backpack, etc)
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
        end)
        -- Esconder TODAS GUIs do PlayerGui (exceto a nossa)
        pcall(function()
            local playerGui = LP:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                for _, gui in ipairs(playerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui ~= ScreenGui then
                        gui:SetAttribute("VampHiddenUI", gui.Enabled)
                        gui.Enabled = false
                    end
                end
            end
        end)
        notify("Game UI hidden", "success")
    else
        -- Restaurar CoreGui
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)
        -- Restaurar PlayerGui
        pcall(function()
            local playerGui = LP:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                for _, gui in ipairs(playerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui:GetAttribute("VampHiddenUI") ~= nil then
                        gui.Enabled = gui:GetAttribute("VampHiddenUI")
                        gui:SetAttribute("VampHiddenUI", nil)
                    end
                end
            end
        end)
        notify("Game UI restored", "info")
    end
end)

CosmeticResetBtn.MouseButton1Click:Connect(function()
    -- Restaurar nametags se estavam escondidas
    if cosmeticState.hideNametags then
        cosmeticState.hideNametags = false
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                local char = player.Character
                if not char then return end
                local head = char:FindFirstChild("Head")
                if head then
                    for _, child in ipairs(head:GetChildren()) do
                        if child:IsA("BillboardGui") and child:GetAttribute("VampHiddenNametag") then
                            child.Enabled = true
                            child:SetAttribute("VampHiddenNametag", nil)
                        end
                    end
                end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                end
            end)
        end
        pcall(function()
            local char = LP.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head then
                    local vt = head:FindFirstChild("VampNametag")
                    if vt then vt.Enabled = true end
                end
            end
        end)
        if nametagHideConn then
            nametagHideConn:Disconnect()
            nametagHideConn = nil
        end
    end
    -- Restaurar Game UI se estava escondida
    if cosmeticState.hideGameUI then
        cosmeticState.hideGameUI = false
        pcall(function()
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)
        pcall(function()
            local playerGui = LP:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                for _, gui in ipairs(playerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui:GetAttribute("VampHiddenUI") ~= nil then
                        gui.Enabled = gui:GetAttribute("VampHiddenUI")
                        gui:SetAttribute("VampHiddenUI", nil)
                    end
                end
            end
        end)
    end
    -- Forçar re-enable do backpack nativo caso algo tenha ficado preso
    pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end)
    resetAllCosmetics()
    cosmeticHeadlessToggle.refresh()
    cosmeticInvisibleToggle.refresh()
    cosmeticGhostToggle.refresh()
    cosmeticHideNametagsToggle.refresh()
    cosmeticHideGameUIToggle.refresh()
end)

--==================================================
-- REMOTE SPY EVENTS
--==================================================

RemoteSpyOpenBtn.MouseButton1Click:Connect(function()
    openRemoteSpyPanel()
end)

RemoteSpyScanBtn.MouseButton1Click:Connect(function()
    scanRemotes()
    refreshRemoteList(RemoteSpyFilterBox.Text)
    notify("Scanned: " .. #scannedRemotes .. " remotes", "success")
end)

RemoteSpyVulnScanBtn.MouseButton1Click:Connect(function()
    RemoteSpyVulnScanBtn.Text = "⚠ Scanning..."
    task.spawn(function()
        vulnScanRemotes()
        RemoteSpyVulnScanBtn.Text = "⚠ VULN SCAN"
    end)
end)

RemoteSpyFireCustomBtn.MouseButton1Click:Connect(function()
    if not selectedFireRemote then
        notify("Select a remote first (click 🎯)", "warning")
        return
    end
    local remote = selectedFireRemote.instance
    local args = parseFireArgs(RemoteSpyArgsBox.Text)
    fireTestRemote(remote, args)
end)

RemoteSpyMassFireBtn.MouseButton1Click:Connect(function()
    massFireRemotes()
end)

RemoteSpyFuzzBtn.MouseButton1Click:Connect(function()
    fuzzRemote()
end)

RemoteSpyDecompileBtn.MouseButton1Click:Connect(function()
    decompileForRemote()
end)

DecompileCloseBtn.MouseButton1Click:Connect(function()
    DecompilePanel.Visible = false
end)

DecompileCopyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then setclipboard(decompileResultText)
        elseif toclipboard then toclipboard(decompileResultText) end
    end)
    notify("Decompile results copied!", "success")
end)

RemoteSpyToggleBtn.MouseButton1Click:Connect(function()
    if remoteSpyActive then
        stopRemoteSpy()
    else
        startRemoteSpy()
    end
end)

RemoteSpyClearBtn.MouseButton1Click:Connect(function()
    remoteSpyLog = {}
    refreshRemoteSpyLog()
    notify("Spy log cleared", "info")
end)

RemoteSpyRepeatBtn.MouseButton1Click:Connect(function()
    if autoRepeatActive then
        stopAutoRepeat()
        RemoteSpyRepeatBtn.Text = "▶ REPEAT"
        RemoteSpyRepeatBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 140)
    else
        if not selectedFireRemote then
            notify("Select a remote first (click 🎯)", "warning")
            return
        end
        local interval = tonumber(RemoteSpyRepeatIntervalBox.Text) or 1
        local count = tonumber(RemoteSpyRepeatCountBox.Text) or 0
        if interval < 0.1 then interval = 0.1 end
        startAutoRepeat(interval, count)
        RemoteSpyRepeatBtn.Text = "⏹ STOP"
        RemoteSpyRepeatBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    end
end)

RemoteSpyExportBtn.MouseButton1Click:Connect(function()
    exportSpyLog()
end)

RemoteSpyCloseBtn.MouseButton1Click:Connect(function()
    if autoRepeatActive then stopAutoRepeat() end
    RemoteSpyPanel.Visible = false
end)

RemoteSpyCloseBottomBtn.MouseButton1Click:Connect(function()
    if autoRepeatActive then stopAutoRepeat() end
    RemoteSpyPanel.Visible = false
end)

-- Remote list filter debounce
do
    local remoteFilterTimer = nil
    RemoteSpyFilterBox:GetPropertyChangedSignal("Text"):Connect(function()
        if remoteFilterTimer then
            task.cancel(remoteFilterTimer)
        end
        remoteFilterTimer = task.delay(0.3, function()
            remoteFilterTimer = nil
            refreshRemoteList(RemoteSpyFilterBox.Text)
        end)
    end)
end

-- Spy log filter debounce
do
    local spyLogFilterTimer = nil
    RemoteSpyLogFilterBox:GetPropertyChangedSignal("Text"):Connect(function()
        if spyLogFilterTimer then
            task.cancel(spyLogFilterTimer)
        end
        spyLogFilterTimer = task.delay(0.3, function()
            spyLogFilterTimer = nil
            refreshRemoteSpyLog()
        end)
    end)
end

--==================================================
-- PLAYER INFO EVENTS
--==================================================

PlayerInfoToggle.btn.MouseButton1Click:Connect(function()
    playerInfoState.active = not playerInfoState.active
    PlayerInfoToggle.refresh()
    playerInfoActive = playerInfoState.active
    if playerInfoActive then
        updatePlayerInfo()
    else
        clearPlayerInfo()
        notify("Player Info Cards OFF", "info")
    end
end)

--==================================================
-- DEV TOOLS EVENTS
--==================================================

AntiAfkBtn.MouseButton1Click:Connect(function()
    if antiAfkActive then
        stopAntiAfk()
    else
        startAntiAfk()
    end
end)

ChatSpyOpenBtn.MouseButton1Click:Connect(function()
    openChatSpyPanel()
end)

ExecRunBtn.MouseButton1Click:Connect(function()
    executeScript(ExecScriptBox.Text)
end)

--==================================================
-- CHAT SPY EVENTS
--==================================================

ChatSpyToggleBtn.MouseButton1Click:Connect(function()
    if chatSpyActive then
        stopChatSpy()
    else
        startChatSpy()
    end
end)

ChatSpyClearBtn.MouseButton1Click:Connect(function()
    chatSpyLog = {}
    refreshChatSpyLog()
    notify("Chat log cleared", "info")
end)

ChatSpyCloseX.MouseButton1Click:Connect(function()
    ChatSpyPanel.Visible = false
end)

ChatSpyCloseBtn.MouseButton1Click:Connect(function()
    ChatSpyPanel.Visible = false
end)

-- Chat spy filter debounce
do
    local chatFilterTimer = nil
    ChatSpyFilterBox:GetPropertyChangedSignal("Text"):Connect(function()
        if chatFilterTimer then
            task.cancel(chatFilterTimer)
        end
        chatFilterTimer = task.delay(0.3, function()
            chatFilterTimer = nil
            refreshChatSpyLog()
        end)
    end)
end

--==================================================
-- BACKPACK VIEWER EVENTS
--==================================================

BackpackCloseX.MouseButton1Click:Connect(function()
    BackpackPanel.Visible = false
end)

BackpackCloseBtn.MouseButton1Click:Connect(function()
    BackpackPanel.Visible = false
end)

BackpackRefreshBtn.MouseButton1Click:Connect(function()
    if backpackTarget then
        scanBackpack(backpackTarget)
        refreshBackpackList()
        notify("Backpack refreshed", "info")
    end
end)

-- Backpack filter debounce
do
    local bpFilterTimer = nil
    BackpackFilterBox:GetPropertyChangedSignal("Text"):Connect(function()
        if bpFilterTimer then
            task.cancel(bpFilterTimer)
        end
        bpFilterTimer = task.delay(0.3, function()
            bpFilterTimer = nil
            refreshBackpackList()
        end)
    end)
end

--[[ PARKVOICE EVENTS — DESABILITADO
ParkVoiceCard.MouseButton1Click:Connect(function()
    openParkVoicePanel()
end)

ParkVoiceFlowerBtn.MouseButton1Click:Connect(function()
    ParkVoiceFlowerBtn.Text = "Scanning..."
    ParkVoiceStatus.Text = "Firing all remotes..."
    ParkVoiceStatus.TextColor3 = Color3.fromRGB(200, 140, 40)
    task.spawn(function()
        vulnScanRemotes()
        ParkVoiceFlowerBtn.Text = "FLOWER"
        ParkVoiceStatus.Text = "Done! Fired all remotes."
        ParkVoiceStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
    end)
end)

ParkVoiceCloseX.MouseButton1Click:Connect(function()
    ParkVoicePanel.Visible = false
end)

ParkVoiceCloseBtn.MouseButton1Click:Connect(function()
    ParkVoicePanel.Visible = false
end)
--]] -- FIM PARKVOICE EVENTS DESABILITADO

--==================================================
-- DEATH BALL EVENTS
--==================================================

DeathBallCard.MouseButton1Click:Connect(function()
    DeathBallPanel.Visible = true
    notify("Death Ball v2 panel opened", "info")
end)

-- ═══ PIANO AUTO EVENTS ═══
PianoAutoCard.MouseButton1Click:Connect(function()
    PianoAutoPanel.Visible = not PianoAutoPanel.Visible
    if PianoAutoPanel.Visible then
        notify("Piano Auto Player opened", "info")
    end
end)

PianoAutoCloseBtn.MouseButton1Click:Connect(function()
    PianoAutoPanel.Visible = false
end)

PianoAutoPlayBtn.MouseButton1Click:Connect(function()
    local sheet = PianoAutoSheet.Text
    if sheet == "" then
        notify("Paste a sheet first!", "warning")
        return
    end
    -- Ler BPM manual do input (prioridade sobre auto-detect)
    local manualBPM = tonumber(PianoBPMInput.Text)
    if manualBPM and manualBPM >= 20 and manualBPM <= 600 then
        pianoManualBPM = manualBPM
    else
        pianoManualBPM = nil
    end
    startPianoAuto(sheet)
end)

PianoAutoStopBtn.MouseButton1Click:Connect(function()
    stopPianoAuto()
end)

-- Piano speed slider interaction (drag on the custom slider)
do
    local pianoSliderDragging = false
    local function updatePianoSpeed(inputX)
        if pianoBPMLocked then return end -- BPM detectado = speed travado
        local absPos = PianoAutoSpeedSlider.AbsolutePosition.X
        local absSize = PianoAutoSpeedSlider.AbsoluteSize.X
        if absSize <= 0 then return end
        local pct = math.clamp((inputX - absPos) / absSize, 0, 1)
        -- Range: 0.5x to 5.0x
        local speed = 0.5 + pct * 4.5
        speed = math.floor(speed * 10 + 0.5) / 10  -- round to 0.1
        pianoAutoSpeed = speed
        PianoAutoSpeedFill.Size = UDim2.new(pct, 0, 1, 0)
        PianoAutoSpeedKnob.Position = UDim2.new(pct, -6, 0.5, -6)
        PianoAutoSpeedLabel.Text = "⚡ Speed: " .. string.format("%.1fx", speed)
    end

    PianoAutoSpeedSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pianoSliderDragging = true
            updatePianoSpeed(input.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if pianoSliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updatePianoSpeed(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pianoSliderDragging = false
        end
    end)
end

DeathBallAutoBtn.MouseButton1Click:Connect(function()
    if deathBallActive then
        stopDeathBall()
    else
        startDeathBall()
    end
end)

-- ESP toggle
DeathBallEspBtn.MouseButton1Click:Connect(function()
    deathBallEspActive = not deathBallEspActive
    if deathBallEspActive then
        DeathBallEspBtn.Text = "ESP: ON"
        DeathBallEspBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
        notify("Ball ESP ON", "success")
    else
        DeathBallEspBtn.Text = "ESP: OFF"
        DeathBallEspBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        clearBallESP()
        notify("Ball ESP OFF", "info")
    end
end)

-- Dodge toggle
DeathBallDodgeBtn.MouseButton1Click:Connect(function()
    deathBallDodgeActive = not deathBallDodgeActive
    if deathBallDodgeActive then
        DeathBallDodgeBtn.Text = "DODGE: ON"
        DeathBallDodgeBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
        notify("Auto-Dodge ON", "success")
    else
        DeathBallDodgeBtn.Text = "DODGE: OFF"
        DeathBallDodgeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        notify("Auto-Dodge OFF", "info")
    end
end)

-- Scan for balls (multi-ball)
DeathBallScanBtn.MouseButton1Click:Connect(function()
    local ballName = DeathBallNameBox.Text or "Ball"
    deathBallCacheTime = 0
    local balls = findAllBalls(ballName)
    if #balls > 0 then
        local names = {}
        for i, b in ipairs(balls) do
            if i <= 5 then table.insert(names, b.Name .. " (" .. b:GetFullName():sub(1, 30) .. ")") end
        end
        notify("Found " .. #balls .. " balls!", "success")
        DeathBallBallInfo.Text = "Balls: " .. #balls .. " found"
        DeathBallBallInfo.TextColor3 = Color3.fromRGB(100, 220, 200)
    else
        notify("No balls with name '" .. ballName .. "' found", "warning")
        DeathBallBallInfo.Text = "Balls: none found"
        DeathBallBallInfo.TextColor3 = Color3.fromRGB(200, 100, 60)
    end
end)

-- Auto-Detect toggle
DeathBallAutoDetectBtn.MouseButton1Click:Connect(function()
    deathBallAutoDetect = not deathBallAutoDetect
    deathBallCacheTime = 0 -- force re-scan
    if deathBallAutoDetect then
        DeathBallAutoDetectBtn.Text = "AUTO-DETECT: ON"
        DeathBallAutoDetectBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
        notify("Auto-detect ON — finds balls by velocity", "success")
    else
        DeathBallAutoDetectBtn.Text = "AUTO-DETECT: OFF"
        DeathBallAutoDetectBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        notify("Auto-detect OFF — using Ball Name field", "info")
    end
end)

-- Debug Mode toggle
DeathBallDebugBtn.MouseButton1Click:Connect(function()
    deathBallDebugMode = not deathBallDebugMode
    if deathBallDebugMode then
        DeathBallDebugBtn.Text = "DEBUG: ON"
        DeathBallDebugBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
        notify("Debug ON — shows raw ball data in status", "info")
    else
        DeathBallDebugBtn.Text = "DEBUG: OFF"
        DeathBallDebugBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        notify("Debug OFF", "info")
    end
end)

DeathBallCloseBtn.MouseButton1Click:Connect(function()
    if deathBallScannerActive then stopObjectScanner() end
    if deathBallBotActive then stopDeathBallBot() end
    if deathBallActive then stopDeathBall() end
    clearBallESP()
    DeathBallPanel.Visible = false
end)

DeathBallCloseBtnBottom.MouseButton1Click:Connect(function()
    if deathBallScannerActive then stopObjectScanner() end
    if deathBallBotActive then stopDeathBallBot() end
    if deathBallActive then stopDeathBall() end
    clearBallESP()
    DeathBallPanel.Visible = false
end)

-- AFK Bot toggle
DeathBallBotBtn.MouseButton1Click:Connect(function()
    if deathBallBotActive then
        stopDeathBallBot()
    else
        startDeathBallBot()
    end
end)

-- Set Queue Position
DeathBallSetQueueBtn.MouseButton1Click:Connect(function()
    setQueuePosition()
end)

-- Miss chance live update
DeathBallMissBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(DeathBallMissBox.Text)
    if val then
        deathBallMissChance = math.clamp(val / 100, 0, 0.5)
    end
end)

-- Object Scanner toggle
DeathBallScanObjBtn.MouseButton1Click:Connect(function()
    if deathBallScannerActive then
        stopObjectScanner()
    else
        startObjectScanner()
    end
end)

-- Helper: carrega SynSaveInstance
local function loadSSI()
    local Params = {
        RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
        SSI = "saveinstance",
    }
    local loader = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)
    if not loader then error("Failed to load SynSaveInstance") end
    return loader()
end

ConfirmSaveBtn.MouseButton1Click:Connect(function()
    ConfirmSaveBtn.Text = "💾 ..."
    task.spawn(function()
        local ok, err = pcall(function()
            local synsaveinstance = loadSSI()

            local fname = FileNameBox.Text
            if fname == "" then
                fname = game.PlaceId .. "_" .. os.date("%Y%m%d_%H%M%S")
            end

            local options = {
                FileName = fname,
                DecompileMode = saveConfigState.DecompileMode and "decompile" or "none",
                SavePlayers = saveConfigState.SavePlayers,
                RemovePlayerCharacters = saveConfigState.RemovePlayerCharacters,
                NilInstances = saveConfigState.NilInstances,
                SaveNonCreatable = saveConfigState.SaveNonCreatable,
                IsolateLocalPlayer = saveConfigState.IsolateLocalPlayer,
                SaveCameraInstances = saveConfigState.SaveCameraInstances,
            }

            log("Save options:", HttpService:JSONEncode(options))
            synsaveinstance(options)
        end)
        if ok then
            ConfirmSaveBtn.Text = "💾 SAVED!"
            notify("Instance saved!", "success")
        else
            log("Save ERROR:", tostring(err))
            ConfirmSaveBtn.Text = "💾 ERR"
            notify("Save error: " .. tostring(err):sub(1, 50), "error")
        end
        task.delay(3, function() ConfirmSaveBtn.Text = "💾 SAVE" end)
    end)
end)

SaveAllBtn.MouseButton1Click:Connect(function()
    SaveAllBtn.Text = "⚡ ..."
    task.spawn(function()
        local ok, err = pcall(function()
            local synsaveinstance = loadSSI()
            local options = {}
            log("Save All: default options")
            synsaveinstance(options)
        end)
        if ok then
            SaveAllBtn.Text = "⚡ SAVED!"
            notify("All saved!", "success")
        else
            log("Save All ERROR:", tostring(err))
            SaveAllBtn.Text = "⚡ ERR"
            notify("Save error", "error")
        end
        task.delay(3, function() SaveAllBtn.Text = "⚡ SAVE ALL" end)
    end)
end)

SaveCharsBtn.MouseButton1Click:Connect(function()
    SaveCharsBtn.Text = "🧍 ..."
    task.spawn(function()
        local ok, err = pcall(function()
            -- Marcar quais Models do Workspace tem Humanoid (são rigs)
            local rigModels = {}
            for _, desc in ipairs(game.Workspace:GetDescendants()) do
                if desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") then
                    rigModels[desc.Parent] = true
                end
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    rigModels[player.Character] = true
                end
            end

            -- Montar IgnoreList: tudo do Workspace que NAO contem rigs
            local ignoreList = {}
            for _, child in ipairs(game.Workspace:GetChildren()) do
                if child:IsA("Terrain") then
                    table.insert(ignoreList, child)
                elseif rigModels[child] then
                    -- É um rig direto no workspace, manter
                else
                    -- Verificar se algum descendente é rig
                    local hasRig = false
                    if child:IsA("Model") or child:IsA("Folder") then
                        for _, desc in ipairs(child:GetDescendants()) do
                            if desc:IsA("Model") and rigModels[desc] then
                                hasRig = true
                                break
                            end
                        end
                    end
                    if not hasRig then
                        table.insert(ignoreList, child)
                    end
                end
            end

            local rigCount = 0
            for _ in rigModels do rigCount += 1 end
            log("Save Characters: " .. rigCount .. " rigs, ignoring " .. #ignoreList .. " workspace children")

            if rigCount == 0 then
                error("No characters/rigs found in Workspace")
            end

            -- Ignorar services que nao sao Workspace (PlayerGui, scripts, etc)
            local servicesToIgnore = {
                "Players", "ReplicatedStorage", "ReplicatedFirst",
                "StarterGui", "StarterPack", "StarterPlayer",
                "Lighting", "SoundService", "Chat", "TextChatService",
                "ServerScriptService", "ServerStorage",
            }
            for _, svc in ipairs(servicesToIgnore) do
                pcall(function()
                    table.insert(ignoreList, game:GetService(svc))
                end)
            end
            -- Ignorar scripts dentro dos rigs tambem
            table.insert(ignoreList, "Script")
            table.insert(ignoreList, "LocalScript")
            table.insert(ignoreList, "ModuleScript")

            -- Salvar usando mesma logica do Save All mas ignorando tudo exceto rigs
            local synsaveinstance = loadSSI()
            synsaveinstance({
                IgnoreList = ignoreList,
                DecompileTimeout = 0,
                RemovePlayerCharacters = false,
            })
        end)
        if ok then
            SaveCharsBtn.Text = "🧍 SAVED!"
            notify("Characters saved!", "success")
        else
            log("Save Characters ERROR:", tostring(err))
            SaveCharsBtn.Text = "🧍 ERR"
            notify("Save error: " .. tostring(err), "error")
        end
        task.delay(3, function() SaveCharsBtn.Text = "🧍 CHARACTERS" end)
    end)
end)

SaveNPCsBtn.MouseButton1Click:Connect(function()
    SaveNPCsBtn.Text = "🤖 ..."
    task.spawn(function()
        local ok, err = pcall(function()
            -- Mapear characters de players reais pra excluir
            local playerChars = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    playerChars[player.Character] = true
                end
            end

            -- Coletar só NPCs (Models com Humanoid que NAO sao player characters)
            local npcModels = {}
            for _, desc in ipairs(game.Workspace:GetDescendants()) do
                if desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") then
                    if not playerChars[desc.Parent] then
                        npcModels[desc.Parent] = true
                    end
                end
            end

            -- Montar IgnoreList: tudo do Workspace que NAO contem NPCs
            local ignoreList = {}
            for _, child in ipairs(game.Workspace:GetChildren()) do
                if child:IsA("Terrain") then
                    table.insert(ignoreList, child)
                elseif npcModels[child] then
                    -- É um NPC direto no workspace, manter
                else
                    local hasNPC = false
                    if child:IsA("Model") or child:IsA("Folder") then
                        for _, desc in ipairs(child:GetDescendants()) do
                            if desc:IsA("Model") and npcModels[desc] then
                                hasNPC = true
                                break
                            end
                        end
                    end
                    if not hasNPC then
                        table.insert(ignoreList, child)
                    end
                end
            end

            -- Ignorar player characters explicitamente
            for char in playerChars do
                table.insert(ignoreList, char)
            end

            -- Ignorar services e scripts
            local servicesToIgnore = {
                "Players", "ReplicatedStorage", "ReplicatedFirst",
                "StarterGui", "StarterPack", "StarterPlayer",
                "Lighting", "SoundService", "Chat", "TextChatService",
                "ServerScriptService", "ServerStorage",
            }
            for _, svc in ipairs(servicesToIgnore) do
                pcall(function()
                    table.insert(ignoreList, game:GetService(svc))
                end)
            end
            table.insert(ignoreList, "Script")
            table.insert(ignoreList, "LocalScript")
            table.insert(ignoreList, "ModuleScript")

            local npcCount = 0
            for _ in npcModels do npcCount += 1 end
            log("Save NPCs: " .. npcCount .. " NPCs found, ignoring " .. #ignoreList .. " items")

            if npcCount == 0 then
                error("No NPCs found in Workspace")
            end

            local synsaveinstance = loadSSI()
            synsaveinstance({
                IgnoreList = ignoreList,
                DecompileTimeout = 0,
                RemovePlayerCharacters = true,
            })
        end)
        if ok then
            SaveNPCsBtn.Text = "🤖 SAVED!"
            notify("NPCs saved!", "success")
        else
            log("Save NPCs ERROR:", tostring(err))
            SaveNPCsBtn.Text = "🤖 ERR"
            notify("Save error: " .. tostring(err), "error")
        end
        task.delay(3, function() SaveNPCsBtn.Text = "🤖 NPCs" end)
    end)
end)

--==================================================
-- PREVIEW EVENTS
--==================================================

PreviewClose.MouseButton1Click:Connect(function()
    clearPreview()
    PreviewFrame.Visible = false
end)

--==================================================
-- GLOBAL EVENTS
--==================================================

-- X fecha tudo (destroy)
CloseBtn.MouseButton1Click:Connect(function()
    stopSpectate()
    stopEmote()
    stopTroll()
    resetAllCosmetics()
    if shadowRecording then stopShadowRecording() end
    if shadowReplaying then stopShadowReplay() end
    stopShadow()
    ShadowPanel.Visible = false
    TrollPanel.Visible = false
    stopRemoteSpy()
    if autoRepeatActive then stopAutoRepeat() end
    RemoteSpyPanel.Visible = false
    DecompilePanel.Visible = false
    if deathBallScannerActive then stopObjectScanner() end
    if deathBallBotActive then stopDeathBallBot() end
    if deathBallActive then stopDeathBall() end
    clearBallESP()
    DeathBallPanel.Visible = false
    PianoAutoPanel.Visible = false
    --ParkVoicePanel.Visible = false -- PARKVOICE DESABILITADO
    stopChatSpy()
    ChatSpyPanel.Visible = false
    BackpackPanel.Visible = false
    if antiAfkActive then stopAntiAfk() end
    clearPlayerInfo()
    playerInfoActive = false
    playerInfoState.active = false
    if espState.footsteps then stopFootsteps() end
    if espState.soundESP then stopSoundESP() end
    clearESP()
    clearPreview()
    clearResults()
    stopAutoScan()
    if movementState.fly then stopFly() end
    if movementState.noclip then
        movementState.noclip = false
        toggleNoclip()
    end
    if movementState.infiniteJump then
        movementState.infiniteJump = false
        toggleInfiniteJump()
    end
    if movementState.freecam then stopFreecam() end
    if movementState.clickTP then stopClickTP() end
    if movementState.antiVoid then stopAntiVoid() end
    if movementState.spin then stopSpin() end
    if aimbotState.enabled then stopAimbot() end
    if pianoAutoPlaying then stopPianoAuto() end
    -- Remove nametag
    pcall(function()
        local char = LP.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head then
                local tag = head:FindFirstChild("VampNametag")
                if tag then tag:Destroy() end
            end
        end
    end)
    -- Reset speed
    movementState.speed = 16
    movementState.jumpPower = 50
    applySpeed()
    ScreenGui:Destroy()
end)

-- Minimizar = volta pro MiniBar
MinBtn.MouseButton1Click:Connect(function()
    closeScanner()
end)

-- Ctrl+G = toggle abrir/fechar | N = toggle freecam
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == HOTKEY then
        if REQUIRE_CTRL and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
            toggleScanner()
        elseif not REQUIRE_CTRL then
            toggleScanner()
        end
    elseif input.KeyCode == Enum.KeyCode.N then
        movementState.freecam = not movementState.freecam
        moveToggles.freecam.refresh()
        if movementState.freecam then
            startFreecam()
        else
            stopFreecam()
        end
    end
end)

--==================================================
-- TAB SWITCH ENHANCEMENT (refresh data on tab change)
--==================================================

-- Override switchTab to add refresh behavior
local baseSwitchTab = switchTab
switchTab = function(tabId)
    baseSwitchTab(tabId)

    -- Refresh player list when switching to player tab
    if tabId == "player" then
        refreshPlayerList()
        updateServerInfo()
    end

    -- Pre-load trending emotes + favorites + sync list on emote tab open
    if tabId == "emote" then
        preloadTrendingEmotes()
        if #favoriteEmotes == 0 then
            loadFavoriteEmotes()
        end
        refreshSyncPlayerList(SyncSearchBox.Text)
    end

    if tabId == "anim" then
        if not animTabPreloaded then
            preloadTrendingAnims()
        end
    end
end

--==================================================
-- VAMPIRE NAMETAG
--==================================================

createVampireNametag = function(char)
    if not char then return end
    local head = char:WaitForChild("Head", 5)
    if not head then return end

    -- Remove existing
    local existing = head:FindFirstChild("VampNametag")
    if existing then existing:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "VampNametag"
    bb.Size = UDim2.new(0, 300, 0, 60)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = false
    bb.Adornee = head
    bb.Parent = head

    -- Nametag text (sem fundo, dinâmico baseado no role)
    local role = authRole or "user"
    local badge = getRoleBadge(role)
    local roleNames = {
        admin = "Vampire Admin",
        vip = "Vampire VIP",
        contributor = "Vampire Dev",
        user = "Vampire User",
    }
    local tagText = badge .. " " .. (roleNames[role] or "Vampire User")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Position = UDim2.new(0, 0, 0.5, -15)
    label.BackgroundTransparency = 1
    label.Text = tagText
    label.TextColor3 = getRoleColor(role)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.3
    label.TextSize = 15
    label.Font = Enum.Font.GothamBold
    label.Parent = bb
end

-- Apply nametag on current + future characters (respeita toggle)
if LP.Character and not cosmeticState.hideVampNametag then
    task.spawn(function()
        createVampireNametag(LP.Character)
    end)
end
LP.CharacterAdded:Connect(function(char)
    if not cosmeticState.hideVampNametag then
        task.spawn(function()
            createVampireNametag(char)
        end)
    end
end)

--==================================================
-- UTILS TAB EVENTS
--==================================================

-- Server Hop
ServerHopBtn.MouseButton1Click:Connect(function()
    doServerHop()
end)

-- Rejoin
RejoinBtn.MouseButton1Click:Connect(function()
    doRejoin()
end)

-- Copy Place ID
CopyPlaceIdBtn.MouseButton1Click:Connect(function()
    copyPlaceId()
end)

-- Copy Job ID
CopyJobIdBtn.MouseButton1Click:Connect(function()
    copyJobId()
end)

-- Anti-AFK toggle
UtilsAntiAfkBtn.MouseButton1Click:Connect(function()
    if antiAfkEnabled then
        stopAntiAfk()
        UtilsAntiAfkBtn.Text = "⚡ ANTI-AFK: OFF"
        UtilsAntiAfkBtn.BackgroundColor3 = Colors.green
    else
        startAntiAfk()
        UtilsAntiAfkBtn.Text = "⚡ ANTI-AFK: ON"
        UtilsAntiAfkBtn.BackgroundColor3 = Colors.glowPurple
    end
end)

-- Waypoints
WaypointSaveBtn.MouseButton1Click:Connect(function()
    saveWaypoint()
end)

WaypointClearBtn.MouseButton1Click:Connect(function()
    clearAllWaypoints()
end)

--==================================================
-- SOUND PLAYER EVENTS (Utils tab)
--==================================================

SoundPlayBtn.MouseButton1Click:Connect(function()
    local audioId = SoundIdInput.Text
    if audioId == "" then
        notify("Enter an Audio ID!", "warning")
        return
    end
    playSound(audioId)
end)

SoundStopBtn.MouseButton1Click:Connect(function()
    stopSound()
end)

--==================================================
-- SOUND PLAYER PANEL EVENTS (Games tab)
--==================================================

-- Toggle sound player panel from card
SoundPlayerCard.MouseButton1Click:Connect(function()
    SoundPlayerPanel.Visible = not SoundPlayerPanel.Visible
end)

SoundPlayerCloseBtn.MouseButton1Click:Connect(function()
    SoundPlayerPanel.Visible = false
end)

-- Map sounds buttons
MapSoundsBtn.MouseButton1Click:Connect(function()
    listMapSounds()
end)

MapSoundsPlayAllBtn.MouseButton1Click:Connect(function()
    playAllMapSounds()
end)

MapSoundsStopAllBtn.MouseButton1Click:Connect(function()
    stopAllMapSounds()
end)

-- Sound volume slider (Games panel) - custom slider like piano speed
do
    local soundSliderDragging = false
    local function updateSoundVolume(inputX)
        local absPos = SoundVolumeSlider.AbsolutePosition.X
        local absSize = SoundVolumeSlider.AbsoluteSize.X
        if absSize <= 0 then return end
        local pct = math.clamp((inputX - absPos) / absSize, 0, 1)
        local vol = math.floor(pct * 100 + 0.5)
        SoundVolumeValue = vol
        SoundVolumeFill.Size = UDim2.new(pct, 0, 1, 0)
        SoundVolumeKnob.Position = UDim2.new(pct, -6, 0.5, -6)
        SoundVolumeLabel.Text = "🔊 Volume: " .. vol .. "%"
        -- Update current playing sound volume
        if currentSound then
            pcall(function() currentSound.Volume = vol / 100 end)
        end
    end

    SoundVolumeSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            soundSliderDragging = true
            updateSoundVolume(input.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if soundSliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSoundVolume(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            soundSliderDragging = false
        end
    end)
end

--==================================================
-- CHARACTER SCALE EVENTS
--==================================================

CharScaleResetBtn.MouseButton1Click:Connect(function()
    resetCharacterScale()
end)

--==================================================
-- AMBIENT & FOG EVENTS
--==================================================

FogRemoveBtn.MouseButton1Click:Connect(function()
    removeFog()
end)

FogRestoreBtn.MouseButton1Click:Connect(function()
    restoreFog()
end)

AmbientApplyBtn.MouseButton1Click:Connect(function()
    local r = AmbientRSlider.getValue and AmbientRSlider.getValue() or 128
    local g = AmbientGSlider.getValue and AmbientGSlider.getValue() or 128
    local b = AmbientBSlider.getValue and AmbientBSlider.getValue() or 128
    applyAmbientColor(r, g, b)
end)

AtmoApplyBtn.MouseButton1Click:Connect(function()
    local d = AtmoDensitySlider.getValue and AtmoDensitySlider.getValue() or 30
    local h = AtmoHazeSlider.getValue and AtmoHazeSlider.getValue() or 0
    local g = AtmoGlowSlider.getValue and AtmoGlowSlider.getValue() or 0
    applyAtmosphere(d, h, g)
end)

AmbientResetBtn.MouseButton1Click:Connect(function()
    resetAllAmbient()
end)

--==================================================
-- ONLINE USERS SCANNER
--==================================================

-- Detecta quem no servidor está na whitelist
refreshOnlineUsers = function()
    if not hasPermission("see_online_users") then return end

    -- Limpar lista anterior
    for _, child in OnlineUsersScroll:GetChildren() do
        if child:IsA("Frame") then child:Destroy() end
    end

    local Players = game:GetService("Players")
    local onlineCount = 0

    for _, entry in ipairs(authWhitelist) do
        local player = Players:FindFirstChild(entry.name)
        if not player then
            -- Tentar por UserId
            for _, p in Players:GetPlayers() do
                if p.UserId == entry.id then
                    player = p
                    break
                end
            end
        end

        if player and player ~= LP then
            onlineCount = onlineCount + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundColor3 = Colors.card
            row.BackgroundTransparency = 0.3
            row.Parent = OnlineUsersScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 22, 1, 0)
            badge.Position = UDim2.new(0, 4, 0, 0)
            badge.BackgroundTransparency = 1
            badge.Text = getRoleBadge(entry.role or "user")
            badge.TextSize = 14
            badge.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -60, 1, 0)
            nameLabel.Position = UDim2.new(0, 28, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            nameLabel.TextColor3 = getRoleColor(entry.role or "user")
            nameLabel.TextSize = 10
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = row

            local roleLabel = Instance.new("TextLabel")
            roleLabel.Size = UDim2.new(0, 50, 1, 0)
            roleLabel.Position = UDim2.new(1, -54, 0, 0)
            roleLabel.BackgroundTransparency = 1
            roleLabel.Text = string.upper(entry.role or "user")
            roleLabel.TextColor3 = getRoleColor(entry.role or "user")
            roleLabel.TextSize = 8
            roleLabel.Font = Enum.Font.Code
            roleLabel.TextXAlignment = Enum.TextXAlignment.Right
            roleLabel.Parent = row
        end
    end

    OnlineUsersScroll.CanvasSize = UDim2.new(0, 0, 0, onlineCount * 26)
    OnlineUsersCountLabel.Text = onlineCount .. " whitelist user(s) online"
end

--==================================================
-- ANIMATION TAB EVENTS
--==================================================

-- Slot reset buttons
for _, slotName in ipairs(ANIM_SLOTS) do
    do
        local slotUI = AnimSlotRows[slotName]
        if slotUI and slotUI.resetBtn then
            slotUI.resetBtn.MouseButton1Click:Connect(function()
                resetAnimationSlot(slotName)
            end)
        end
    end
end

-- Reset All (updateAnimSlotUI ja é chamado dentro de resetAnimationSlot)
AnimResetAllBtn.MouseButton1Click:Connect(function()
    resetAllAnimations()
end)

-- Catalog search (debounced 0.4s) — ignora IDs numericos
do
    local animSearchTimer = nil
    AnimSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if animSearchTimer then
            task.cancel(animSearchTimer)
        end
        local text = AnimSearchBox.Text
        if string.match(text, "^%d+$") then return end
        animSearchTimer = task.delay(0.4, function()
            animSearchTimer = nil
            searchAnimationCatalog(AnimSearchBox.Text)
        end)
    end)
end

-- Enter: ID numerico abre detail view, texto busca catalogo
AnimSearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local text = AnimSearchBox.Text
        if string.match(text, "^%d+$") then
            local id = tonumber(text)
            if id and id > 0 then
                openAnimDetailView(id, "Bundle #" .. tostring(id))
            end
        else
            searchAnimationCatalog(text)
        end
    end
end)

-- Scroll pagination
AnimScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    if animDetailView then return end
    local scrollPos = AnimScroll.CanvasPosition.Y
    local canvasH = AnimScroll.CanvasSize.Y.Offset
    local frameH = AnimScroll.AbsoluteSize.Y
    if canvasH > 0 and (scrollPos + frameH) >= (canvasH - 60) then
        loadMoreAnims()
    end
end)

-- Detail view: Back
AnimDetailBackBtn.MouseButton1Click:Connect(function()
    closeAnimDetailView()
end)

-- Detail view: Favorite
AnimDetailFavBtn.MouseButton1Click:Connect(function()
    if animDetailBundleId then
        local name = AnimDetailName.Text
        local added = toggleFavoriteAnim(animDetailBundleId, name)
        AnimDetailFavBtn.Text = added and "★ Favorited" or "☆ Favorite"
        AnimDetailFavBtn.BackgroundColor3 = added and Color3.fromRGB(60, 50, 10) or Colors.card
    end
end)

-- Detail view: Apply All
AnimDetailApplyAllBtn.MouseButton1Click:Connect(function()
    if animDetailBundleData then
        applyFullBundle(animDetailBundleData)
    end
end)

-- Detail view: Apply Selected
AnimDetailApplySelBtn.MouseButton1Click:Connect(function()
    if animDetailBundleData and animDetailSelected then
        applySelectedBundle(animDetailBundleData, animDetailSelected)
    end
end)

-- Snapshot on load + respawn re-apply
do
    snapshotOriginalAnimations()

    LP.CharacterAdded:Connect(function(char)
        local animate = char:WaitForChild("Animate", 5)
        if not animate then return end
        snapshotOriginalAnimations()
        for slotName, animId in pairs(currentAnimations) do
            applyAnimationSlot(slotName, animId)
        end
    end)
end

--==================================================
-- INIT
--==================================================

-- Load favorite emotes from file
loadFavoriteEmotes()

-- Set default tab
switchTab("scanner")

-- Start auto-scan if enabled
if autoScanConfig.enabled then
    task.delay(1, function()
        startAutoScan()
    end)
end

-- Scan online users periodicamente
if hasPermission("see_online_users") then
    task.delay(2, refreshOnlineUsers)
    task.spawn(function()
        while task.wait(30) do
            refreshOnlineUsers()
        end
    end)
end

log("══════════════════════════════════════")
log(SCRIPT_NAME .. " " .. SCRIPT_VERSION)
log("Create By VampireSonata")
log("Role: " .. string.upper(authRole or "user") .. " " .. getRoleBadge(authRole or "user"))
log("══════════════════════════════════════")
log("MiniBar mode! Ctrl+G to toggle")
log("══════════════════════════════════════")

notify(getRoleBadge(authRole or "user") .. " " .. SCRIPT_NAME .. " loaded! [" .. string.upper(authRole or "user") .. "]", "success")

