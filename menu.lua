--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║               ROBLOX UTILITY HUB - VOID SCRIPT               ║
    ║          Built on top of VoidUI Library v2.2                 ║
    ║          Sidebar Scroll & Window Height Fix Applied          ║
    ║          Fully Organized · Feature-Complete · Luau           ║
    ║          [RE-RESTORED TABS]                                  ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ──────────────────────────────────────────────────────────────
--  LOAD VOID LIBRARY
-- ──────────────────────────────────────────────────────────────
local VoidLib
if isfile and isfile("Library2.lua") then
    VoidLib = loadstring(readfile("Library2.lua"))()
elseif isfile and isfile("Library.lua") then
    VoidLib = loadstring(readfile("Library.lua"))()
else
    local ok, res = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/VenezzaX/VoidUI/refs/heads/main/Library2.lua")
    end)
    if ok and res and res ~= "" and not res:find("404") and not res:find("not found") then
        VoidLib = loadstring(res)()
    else
        VoidLib = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/VenezzaX/VoidUI/refs/heads/main/Library.lua"
        ))()
    end
end

-- ──────────────────────────────────────────────────────────────
--  SERVICES
-- ──────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting         = game:GetService("Lighting")
local VirtualUser      = game:GetService("VirtualUser")

local playerCards = {}
local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse  = LP:GetMouse()
local uiVisible = true
local windowFrame = nil
local notify = nil
local autoReinjectToggle = nil
local isFreecam = false
local freecamConnection = nil
local freecamInputConn = nil
local freecamInputBeganConn = nil
local freecamInputEndedConn = nil
local freecamBasePos = nil
local currentSpectateTarget = nil
local spectatePlayer = nil

-- ──────────────────────────────────────────────────────────────
--  STATE CONFIGURATION
-- ──────────────────────────────────────────────────────────────
local S = {
    -- Stat values
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    BHop = false,
    AirWalk = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 60,
    BlinkDistance = 25,
    BlinkDirection = "Camera Look", -- "Camera Look" or "Movement Direction"
    BlinkKey = Enum.KeyCode.Q,
    
    GhostMode = false,
    GhostCFrame = nil,
    GhostDummy = nil,
    
    ESPBoxes = false,
    ESPTracers = false,
    ESPNames = false,
    ESPHealth = false,
    ESPDistances = false,
    ESPTeamCheck = false,
    ESPTransparency = 0.8,
    
    OverheadInfo = false,
    
    HitboxExpanded = false,
    HitboxSize = 10,
    HitboxTeamCheck = false,
    HitboxTransparency = 0.5,
    
    AimbotActive = false,
    AimbotTeamCheck = false,
    AimbotFOV = 120,
    AimbotSmooth = 5,
    AimbotPart = "Head",
    AimbotVisibility = false,
    AimbotShowFOV = false,
    
    FlingTarget = nil,
    FlingActive = false,
    
    FollowTarget = nil,
    FollowActive = false,
    
    InstantPrompts = false,
    AntiVoid = false,
    AntiVoidY = -500,
    
    ToastEnabled = true,
    ToastChatEnabled = false,
    AutoReinject = true,

    -- New Movement/Advantage States
    Float = false,
    WaterWalk = false,
    TallAnim = false,
    Spin = false,
    SpinSpeed = 15,
    GravityEnabled = false,
    CustomGravity = 196.2,
    ForceWalkSpeed = false,
    ForceJumpPower = false,
    AntiAFK = false,
    GhostTeleportToEnd = false,
    
    -- New Exploit States
    GodMode = false,
    KillAura = false,
    KillAuraRange = 15,
    AutoClicker = false,
    AutoInteract = false,
    AutoInteractRadius = 15,
    ToolMagnet = false,
    AutoJump = false,
    SavedWaypointCF = nil,
    AntiFling = false,
    
    -- New Visual States
    MapXray = false,
    ClearVision = false,
    FullBright = false,
    TimeCycle = false,
    TimeCycleSpeed = 1,
    TimeOfDay = 14,
    CameraMaxZoom = 128,
    
    -- New Utility States
    ClickDelete = false,
    CameraFOV = 70,
    ForceShiftLock = false,
    ESPColor = "Red",
    AntiAnchor = false,
    No3DRender = false,
    FPSCap = 60,
    ClickTeleport = false,
    SprintEnabled = false,
    SprintSpeed = 35,
    AntiSit = false,
    GraphicsReducer = false,
    AutoRejoin = false,
    FreecamSpeed = 40,
    TracerOrigin = "Bottom",
    
    -- Internals
    FloatBody = nil,
    WaterPlat = nil,
    WaterRaycastParams = nil,
    TallWalkTrack = nil,
    TallIdleTrack = nil,
    TallRunningConn = nil,
    GodModeConn = nil,
    OriginalPartTransparencies = {},
    
    -- Connection tracking
    Connections = {},
    ESPPool = {},      -- [Player] = { BoxOutline, BoxFill, TracerLine, NameTag, HealthBar }
    OverheadPool = {}, -- [Player] = BillboardGui
    HitboxStore = {},  -- [Player] = { OriginalSize, OriginalCanCollide }
    AirWalkPlat = nil,
    
    -- Cache Data
    LastSafePosition = CFrame.new(0, 50, 0),
    ChatHistory = {},
    FavoriteMaps = {},
    
    -- Keybind Mappings (Rebindable)
    FlyKey = Enum.KeyCode.F,
    NoClipKey = Enum.KeyCode.N,
    BHopKey = Enum.KeyCode.B,
    InfJumpKey = Enum.KeyCode.J,
    GhostKey = Enum.KeyCode.G,
    BlinkKey = Enum.KeyCode.Q,
}

-- ──────────────────────────────────────────────────────────────
--  CLEANUP ROUTINE (Prevents memory leaks on re-run)
-- ──────────────────────────────────────────────────────────────
local function destroyESP(p)
    local pool = S.ESPPool[p]
    if pool then
        pcall(function() pool.boxOutline:Remove() end)
        pcall(function() pool.boxFill:Remove() end)
        pcall(function() pool.tracer:Remove() end)
        pcall(function() pool.nameTag:Remove() end)
        pcall(function() pool.healthText:Remove() end)
        pcall(function() pool.distText:Remove() end)
        S.ESPPool[p] = nil
    end
end

local function restoreHitbox(p)
    local char = p.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
    if hrp then
        local adorn = hrp:FindFirstChild("VoidHitboxAdorn")
        if adorn then pcall(function() adorn:Destroy() end) end
        
        local stored = S.HitboxStore[p]
        if stored then
            hrp.Size = stored.OriginalSize
            hrp.CanCollide = stored.OriginalCanCollide
        end
    end
    S.HitboxStore[p] = nil
end

local function cleanupAll()
    for _, c in ipairs(S.Connections) do
        pcall(function() c:Disconnect() end)
    end
    S.Connections = {}
    
    for p, _ in pairs(S.ESPPool) do
        destroyESP(p)
    end
    
    for p, bill in pairs(S.OverheadPool) do
        pcall(function() bill:Destroy() end)
    end
    S.OverheadPool = {}
    
    for p, _ in pairs(S.HitboxStore) do
        restoreHitbox(p)
    end
    S.HitboxStore = {}
    
    if S.AirWalkPlat then
        pcall(function() S.AirWalkPlat:Destroy() end)
        S.AirWalkPlat = nil
    end
    
    if S.GhostDummy then
        pcall(function() S.GhostDummy:Destroy() end)
        S.GhostDummy = nil
    end

    if S.FloatBody then
        pcall(function() S.FloatBody:Destroy() end)
        S.FloatBody = nil
    end

    if S.WaterPlat then
        pcall(function() S.WaterPlat:Destroy() end)
        S.WaterPlat = nil
    end

    if playerCards then
        for p, item in pairs(playerCards) do
            pcall(function()
                if item.HPConn then item.HPConn:Disconnect() end
                if item.CharConn then item.CharConn:Disconnect() end
            end)
        end
        playerCards = {}
    end

    pcall(function()
        if isFreecam then
            isFreecam = false
            local char = LP.Character
            local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
            if hrp then hrp.Anchored = false end
            
            if freecamConnection then freecamConnection:Disconnect() freecamConnection = nil end
            if freecamInputConn then freecamInputConn:Disconnect() freecamInputConn = nil end
            if freecamInputBeganConn then freecamInputBeganConn:Disconnect() freecamInputBeganConn = nil end
            if freecamInputEndedConn then freecamInputEndedConn:Disconnect() freecamInputEndedConn = nil end
            
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            Camera.CameraType = Enum.CameraType.Custom
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
    end)

    pcall(function()
        if LP.Character then
            revertTallAnimations(LP.Character)
            disableGodMode()
        end
    end)

    pcall(function()
        toggleMapXray(false)
        toggleClearVision(false)
    end)

    pcall(function()
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoor
    end)
    
    pcall(function()
        if getgenv().VoidFOVCircle then
            getgenv().VoidFOVCircle:Remove()
        end
    end)
end

if getgenv().VoidUtilityHubCleanup then
    getgenv().VoidUtilityHubCleanup()
end
getgenv().VoidUtilityHubCleanup = cleanupAll

-- ──────────────────────────────────────────────────────────────
--  UTILITY HELPERS
-- ──────────────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()
    local c = getChar()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c.PrimaryPart)
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- BHOP custom physics helper (Reworked to use frame-based strafe and speed boosting)

-- Tall animations helpers
local function applyTallAnimations(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    if S.TallWalkTrack then S.TallWalkTrack:Stop() end
    if S.TallIdleTrack then S.TallIdleTrack:Stop() end
    if S.TallRunningConn then S.TallRunningConn:Disconnect() end

    hum.WalkSpeed = 34
    hum.UseJumpPower = true
    hum.JumpPower = 75
    hum.JumpHeight = 7.2

    local walkAnim = Instance.new("Animation")
    walkAnim.AnimationId = "rbxassetid://128769966446762"
    S.TallWalkTrack = hum:LoadAnimation(walkAnim)
    S.TallWalkTrack.Looped = true

    local idleAnim = Instance.new("Animation")
    idleAnim.AnimationId = "rbxassetid://87574253549013"
    S.TallIdleTrack = hum:LoadAnimation(idleAnim)
    S.TallIdleTrack.Looped = true

    S.TallRunningConn = hum.Running:Connect(function(speedVal)
        if speedVal > 0 then
            if S.TallIdleTrack then S.TallIdleTrack:Stop() end
            if S.TallWalkTrack and not S.TallWalkTrack.IsPlaying then S.TallWalkTrack:Play() end
        else
            if S.TallWalkTrack then S.TallWalkTrack:Stop() end
            if S.TallIdleTrack and not S.TallIdleTrack.IsPlaying then S.TallIdleTrack:Play() end
        end
    end)
    S.TallIdleTrack:Play()
end

local function revertTallAnimations(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if S.TallWalkTrack then S.TallWalkTrack:Stop() S.TallWalkTrack = nil end
    if S.TallIdleTrack then S.TallIdleTrack:Stop() S.TallIdleTrack = nil end
    if S.TallRunningConn then S.TallRunningConn:Disconnect() S.TallRunningConn = nil end
    hum.WalkSpeed = S.WalkSpeed
    hum.JumpPower = S.JumpPower
    hum.UseJumpPower = true
end

-- God Mode helpers
local function applyGodMode(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 3)
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        if S.GodModeConn then S.GodModeConn:Disconnect() end
        S.GodModeConn = RunService.Heartbeat:Connect(function()
            if humanoid and humanoid.Parent and humanoid.Health > 0 then
                humanoid.MaxHealth = math.huge
                humanoid.Health = math.huge
            end
        end)
    end
end

local function disableGodMode()
    if S.GodModeConn then
        S.GodModeConn:Disconnect()
        S.GodModeConn = nil
    end
    local char = LP.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
end

-- Float Mode helper
local function toggleFloat(v)
    S.Float = v
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if v and hrp then
        if not S.FloatBody then
            S.FloatBody = Instance.new("BodyVelocity")
            S.FloatBody.Name = "VoidFloatBody"
            S.FloatBody.Velocity = Vector3.new(0, 0, 0)
            S.FloatBody.MaxForce = Vector3.new(0, math.huge, 0)
            S.FloatBody.Parent = hrp
        end
    else
        if S.FloatBody then S.FloatBody:Destroy(); S.FloatBody = nil end
    end
end

-- Water Walk helper
local function toggleWaterWalk(v)
    S.WaterWalk = v
    if not v and S.WaterPlat then
        pcall(function() S.WaterPlat:Destroy() end)
        S.WaterPlat = nil
    end
end

-- Map X-Ray helper
local function toggleMapXray(v)
    S.MapXray = v
    if v then
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Parent:FindFirstChildOfClass("Humanoid") and part.Name ~= "Terrain" then
                S.OriginalPartTransparencies[part] = part.Transparency
                part.Transparency = 0.5
            end
        end
    else
        for part, trans in pairs(S.OriginalPartTransparencies) do
            if part and part.Parent then
                part.Transparency = trans
            end
        end
        S.OriginalPartTransparencies = {}
    end
end

-- Clear Vision helper
local function toggleClearVision(v)
    S.ClearVision = v
    if v then
        Lighting.FogEnd = 100000
        for _, descendant in ipairs(Lighting:GetDescendants()) do
            if descendant:IsA("BlurEffect") or descendant:IsA("DepthOfFieldEffect") or descendant:IsA("Atmosphere") or descendant:IsA("ColorCorrectionEffect") then
                descendant.Enabled = false
            end
        end
    else
        Lighting.FogEnd = 10000
        for _, descendant in ipairs(Lighting:GetDescendants()) do
            if descendant:IsA("BlurEffect") or descendant:IsA("DepthOfFieldEffect") or descendant:IsA("Atmosphere") or descendant:IsA("ColorCorrectionEffect") then
                descendant.Enabled = true
            end
        end
    end
end

-- Graphics Reducer helper
local function toggleGraphicsReducer(v)
    S.GraphicsReducer = v
    if v then
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Material = Enum.Material.SmoothPlastic
            elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                descendant.Transparency = 1
            elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then
                descendant.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
    else
        Lighting.GlobalShadows = true
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("Decal") or descendant:IsA("Texture") then
                descendant.Transparency = 0
            elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then
                descendant.Enabled = true
            end
        end
    end
end

-- Auto-Rejoin setup
local rejoinHooked = false
local function setupAutoRejoin()
    if rejoinHooked then return end
    rejoinHooked = true
    pcall(function()
        game:GetService("GuiService").ErrorMessageChanged:Connect(function()
            if S.AutoRejoin then
                if notify then
                    notify("Kicked from server! Rejoining in 5 seconds...", Color3.fromRGB(218, 38, 38))
                else
                    warn("Kicked from server! Rejoining in 5 seconds...")
                end
                task.wait(5)
                TeleportService:Teleport(game.PlaceId, LP)
            end
        end)
    end)
end

local queue_on_teleport = queue_on_teleport or queueteleport or (syn and syn.queue_on_teleport) or queue_to_teleport or (fluxus and fluxus.queue_on_teleport)
local function setupAutoReinject()
    local code = [[
        repeat task.wait() until game:IsLoaded()
        local start = tick()
        repeat
            task.wait(0.1)
        until (isfile and readfile) or (tick() - start > 10)
        
        if isfile and isfile("Script.lua") then
            loadstring(readfile("Script.lua"))()
        else
            local ok, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VenezzaX/VoidUI/refs/heads/main/menu.lua", true))()
            end)
            if not ok then
                warn("Void Utility Hub auto-reinject failed: " .. tostring(err))
            end
        end
    ]]

    if S.AutoReinject then
        if queue_on_teleport then
            pcall(queue_on_teleport, code)
        end
        if writefile then
            pcall(writefile, "autoexec/VoidUtilityHub.lua", code)
        end
    else
        if writefile and isfile and delfile then
            pcall(function()
                if isfile("autoexec/VoidUtilityHub.lua") then
                    delfile("autoexec/VoidUtilityHub.lua")
                end
            end)
        end
    end
end


-- ──────────────────────────────────────────────────────────────
--  WINDOW CREATION
-- ──────────────────────────────────────────────────────────────
local Win = VoidLib:CreateWindow("xzyp Void Utility Hub", "v1.2")

-- Dynamic size update to fit all tabs at runtime
pcall(function()
    local gui = game:GetService("CoreGui"):FindFirstChild("VoidLib_xzyp Void Utility Hub")
    if gui then
        local win = gui:FindFirstChild("VoidWindow", true)
        if win then
            win.Size = UDim2.new(0, 660, 0, 580)
        end
    end
end)

notify = function(msg, color)
    if S.ToastEnabled then
        Win:Toast(msg, color or Color3.fromRGB(218, 38, 38))
    end
end

pcall(function()
    Win:SetAutoReinject(S.AutoReinject, function(enabled)
        S.AutoReinject = enabled
        saveConfig()
        setupAutoReinject()
        if autoReinjectToggle then
            autoReinjectToggle:Set(enabled)
        end
    end)
end)

pcall(function()
    Win:SetOnClose(function()
        pcall(function() Win:ResetAllToggles() end)
        
        -- Reset non-toggle cheat properties
        S.WalkSpeed = 16
        S.JumpPower = 50
        pcall(function()
            local hum = getHum()
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
            Workspace.Gravity = 196.2
        end)
        
        notify("Interface closed - all features disabled!", Color3.fromRGB(218, 38, 38))
    end)
end)

local function teleportToPlace(placeId)
    notify("Teleporting to Place " .. placeId .. "...", Color3.fromRGB(218, 170, 42))
    setupAutoReinject()
    pcall(function()
        TeleportService:Teleport(placeId, LP)
    end)
end

local function robloxGet(url)
    local proxies = {
        "roproxy.com",
        "roproxy.link",
        "setup.roproxy.com"
    }
    
    local isRoblox = url:find("roblox%.com")
    
    if isRoblox then
        for _, proxy in ipairs(proxies) do
            local cleanUrl = url:gsub("roblox%.com", proxy)
            local ok, res = pcall(function()
                return game:HttpGet(cleanUrl)
            end)
            if ok and res and type(res) == "string" and res ~= "" then
                local low = res:lower()
                if not low:find("access denied") and not low:find("too many requests") and not low:find("502 bad gateway") and not low:find("cloudflare") and not low:find("error") then
                    return res
                end
            end
        end
    end
    
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and res then
        return res
    end
    return nil
end

local friendshipCache = {}
local function checkFriendship(userId)
    if friendshipCache[userId] ~= nil then
        return friendshipCache[userId]
    end
    local isFr = false
    pcall(function() isFr = LP:IsFriendsWith(userId) end)
    friendshipCache[userId] = isFr
    return isFr
end

local function teleportToHRP(targetHRP)
    local myChar = LP.Character
    local myHRP = getHRP()
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHRP and targetHRP then
        if myHum then myHum.Sit = false end
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        myHRP.AssemblyLinearVelocity = Vector3.zero
        return true
    end
    return false
end

-- ──────────────────────────────────────────────────────────────
--  PERSISTENT DATA MANAGEMENT
-- ──────────────────────────────────────────────────────────────
local function saveFavorites()
    pcall(function()
        if writefile then
            writefile("utility_hub_favorites.json", HttpService:JSONEncode(S.FavoriteMaps))
        end
    end)
end

local function loadFavorites()
    pcall(function()
        if readfile and isfile and isfile("utility_hub_favorites.json") then
            local data = readfile("utility_hub_favorites.json")
            S.FavoriteMaps = HttpService:JSONDecode(data) or {}
        end
    end)
end
loadFavorites()

local function saveConfig()
    pcall(function()
        if writefile then
            local configData = {}
            for k, v in pairs(S) do
                if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                    configData[k] = v
                elseif typeof(v) == "EnumItem" then
                    configData[k] = {__type = "EnumItem", Value = tostring(v)}
                end
            end
            writefile("utility_hub_config.json", HttpService:JSONEncode(configData))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile("utility_hub_config.json") then
            local data = readfile("utility_hub_config.json")
            local configData = HttpService:JSONDecode(data)
            if configData then
                for k, v in pairs(configData) do
                    if type(v) == "table" and v.__type == "EnumItem" then
                        local enumType, enumName = v.Value:match("^Enum%.([^%.]+)%.([^%.]+)$")
                        if enumType and enumName and Enum[enumType] and Enum[enumType][enumName] then
                            S[k] = Enum[enumType][enumName]
                        end
                    else
                        S[k] = v
                    end
                end
            end
        end
    end)
    -- Reset volatile/unsafe states on startup so they don't execute automatically
    S.Fly = false
    S.NoClip = false
    S.BHop = false
    S.AirWalk = false
    S.GhostMode = false
    S.Float = false
    S.WaterWalk = false
    S.TallAnim = false
    S.Spin = false
    S.GravityEnabled = false
    S.GodMode = false
    S.KillAura = false
    S.AutoClicker = false
    S.FlingActive = false
    S.FollowActive = false
    S.AntiAnchor = false
    S.No3DRender = false
    S.ClickTeleport = false
    S.SprintEnabled = false
    S.GraphicsReducer = false
end
loadConfig()
setupAutoRejoin()
setupAutoReinject()

pcall(function()
    if setfpscap and S.FPSCap then
        setfpscap(S.FPSCap)
    end
end)


-- ──────────────────────────────────────────────────────────────
--  TAB 1 ▸ HOME
-- ──────────────────────────────────────────────────────────────
local homeTab = Win:AddTab("Home")

homeTab:AddSection("LOCAL PLAYER INFO")

-- Profile card
local profileFrame = homeTab:AddFrame(75)
profileFrame.BackgroundTransparency = 1
do
    local bg = Instance.new("Frame", profileFrame)
    bg.Size             = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    bg.BorderSizePixel  = 0

    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = Color3.fromRGB(34, 34, 34)
    stroke.Thickness = 1

    local img = Instance.new("ImageLabel", bg)
    img.Size             = UDim2.new(0, 55, 0, 55)
    img.Position         = UDim2.new(0, 8, 0.5, -27.5)
    img.BackgroundColor3 = Color3.fromRGB(7, 7, 7)
    img.BorderSizePixel  = 0
    
    task.spawn(function()
        pcall(function()
            img.Image = ("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=60&height=60&format=png"):format(LP.UserId)
        end)
    end)

    local nameL = Instance.new("TextLabel", bg)
    nameL.Size               = UDim2.new(1, -80, 0, 18)
    nameL.Position           = UDim2.new(0, 72, 0, 8)
    nameL.BackgroundTransparency = 1
    nameL.Font               = Enum.Font.GothamBold
    nameL.TextSize           = 12
    nameL.TextColor3         = Color3.fromRGB(235, 235, 235)
    nameL.TextXAlignment     = Enum.TextXAlignment.Left
    nameL.Text               = LP.DisplayName .. " (@" .. LP.Name .. ")"

    local hpL = Instance.new("TextLabel", bg)
    hpL.Size               = UDim2.new(1, -80, 0, 14)
    hpL.Position           = UDim2.new(0, 72, 0, 28)
    hpL.BackgroundTransparency = 1
    hpL.Font               = Enum.Font.Gotham
    hpL.TextSize           = 10
    hpL.TextColor3         = Color3.fromRGB(55, 200, 80)
    hpL.TextXAlignment     = Enum.TextXAlignment.Left
    hpL.Text               = "HP: -- / --"

    local idL = Instance.new("TextLabel", bg)
    idL.Size               = UDim2.new(1, -80, 0, 14)
    idL.Position           = UDim2.new(0, 72, 0, 44)
    idL.BackgroundTransparency = 1
    idL.Font               = Enum.Font.Gotham
    idL.TextSize           = 9
    idL.TextColor3         = Color3.fromRGB(120, 120, 120)
    idL.TextXAlignment     = Enum.TextXAlignment.Left
    idL.Text               = "UserID: " .. LP.UserId

    table.insert(S.Connections, RunService.Heartbeat:Connect(function()
        local hum = getHum()
        if hum then
            hpL.Text = ("HP: %d / %d"):format(math.floor(hum.Health), math.floor(hum.MaxHealth))
        end
    end))
end

homeTab:AddSection("HUD DETAILS")
local rowHomeFPS    = homeTab:AddInfoRow("Frames Per Second", "--")
local rowHomePing   = homeTab:AddInfoRow("Network Ping", "--")
local rowHomeRegion = homeTab:AddInfoRow("Server Region", "Loading...")

homeTab:AddSection("QUICK ACTIONS")
homeTab:AddButton("Reset Character", "RESET", function()
    local hum = getHum()
    if hum then hum.Health = 0 notify("Character reset!", Color3.fromRGB(218, 38, 38)) end
end)

homeTab:AddButton("Quick Rejoin Server", "REJOIN", function()
    notify("Rejoining server...", Color3.fromRGB(218, 170, 42))
    task.delay(0.5, function()
        TeleportService:Teleport(game.PlaceId, LP)
    end)
end)

local toggleToasts = homeTab:AddToggle("Global Toast Notifications", true, function(v)
    S.ToastEnabled = v
end)

homeTab:AddSection("LIVE CHAT FEED")
local homeChatFeed = homeTab:AddScrollFeed(120)

-- ──────────────────────────────────────────────────────────────
--  TAB 2 ▸ VISUALS
-- ──────────────────────────────────────────────────────────────
local visualTab = Win:AddTab("Visuals")

visualTab:AddSection("ESP (EXTRA SENSORY PERCEPTION)")
local espBoxesToggle = visualTab:AddToggle("Player Box Outlines", S.ESPBoxes, function(v) S.ESPBoxes = v saveConfig() end)
local espTracersToggle = visualTab:AddToggle("Tracer Lines", S.ESPTracers, function(v) S.ESPTracers = v saveConfig() end)
local espNamesToggle = visualTab:AddToggle("Show Player Names", S.ESPNames, function(v) S.ESPNames = v saveConfig() end)
local espHealthToggle = visualTab:AddToggle("Show Health Text", S.ESPHealth, function(v) S.ESPHealth = v saveConfig() end)
local espDistToggle = visualTab:AddToggle("Show Distance Text", S.ESPDistances, function(v) S.ESPDistances = v saveConfig() end)
local espTeamToggle = visualTab:AddToggle("Skip Teammates", S.ESPTeamCheck, function(v) S.ESPTeamCheck = v saveConfig() end)
local espColorDrop = visualTab:AddDropdown("ESP Custom Color Scheme", {"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}, table.find({"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}, S.ESPColor) or 1, function(_, opt)
    S.ESPColor = opt
    saveConfig()
end)
local espTracerOriginDrop = visualTab:AddDropdown("ESP Tracer Origin", {"Bottom", "Center", "Top"}, table.find({"Bottom", "Center", "Top"}, S.TracerOrigin) or 1, function(_, opt)
    S.TracerOrigin = opt
    saveConfig()
end)
local espTransSlider = visualTab:AddSlider("Box Transparency (%)", 0, 100, S.ESPTransparency * 100, function(v)
    S.ESPTransparency = v / 100
    saveConfig()
end)

visualTab:AddSection("OVERHEAD HEADS-UP DISPLAY")
-- Overhead billboard builder helper
local function makeOverhead(p)
    if p == LP then return end
    local char = p.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
    if not hrp then return end
    
    if S.OverheadPool[p] then
        pcall(function() S.OverheadPool[p]:Destroy() end)
    end
    
    local bill = Instance.new("BillboardGui")
    bill.Name = "VoidOverhead_" .. p.Name
    bill.Size = UDim2.new(0, 140, 0, 42)
    bill.StudsOffset = Vector3.new(0, 3.8, 0)
    bill.AlwaysOnTop = true
    bill.Adornee = hrp
    bill.Parent = hrp
    
    local f = Instance.new("Frame", bill)
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    
    local l = Instance.new("UIListLayout", f)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.VerticalAlignment = Enum.VerticalAlignment.Bottom
    l.Padding = UDim.new(0, 2)
    
    local teamIndicator = Instance.new("Frame", f)
    teamIndicator.Size = UDim2.new(0, 25, 0, 2)
    teamIndicator.BorderSizePixel = 0
    teamIndicator.BackgroundColor3 = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(218, 38, 38)
    
    local nameL = Instance.new("TextLabel", f)
    nameL.Text = p.DisplayName
    nameL.Font = Enum.Font.GothamBold
    nameL.TextSize = 11
    nameL.TextColor3 = Color3.fromRGB(235, 235, 235)
    nameL.BackgroundTransparency = 1
    nameL.Size = UDim2.new(1, 0, 0, 14)
    nameL.TextStrokeTransparency = 0.3
    
    local hpL = Instance.new("TextLabel", f)
    hpL.Font = Enum.Font.Gotham
    hpL.TextSize = 9
    hpL.TextColor3 = Color3.fromRGB(50, 195, 75)
    hpL.BackgroundTransparency = 1
    hpL.Size = UDim2.new(1, 0, 0, 12)
    hpL.TextStrokeTransparency = 0.3
    
    S.OverheadPool[p] = bill
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local conn
        conn = hum.HealthChanged:Connect(function(health)
            if not bill or not bill.Parent or not S.OverheadInfo then
                conn:Disconnect()
                return
            end
            hpL.Text = string.format("HP: %d / %d", math.floor(health), math.floor(hum.MaxHealth))
            local pct = health / math.max(hum.MaxHealth, 1)
            hpL.TextColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
        end)
        
        hpL.Text = string.format("HP: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
        local pct = hum.Health / math.max(hum.MaxHealth, 1)
        hpL.TextColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
    end
end

local function refreshOverheads()
    for _, bill in pairs(S.OverheadPool) do
        pcall(function() bill:Destroy() end)
    end
    S.OverheadPool = {}
    
    if S.OverheadInfo then
        for _, p in ipairs(Players:GetPlayers()) do
            makeOverhead(p)
        end
    end
end

local overheadToggle = visualTab:AddToggle("Heads-Up Overheads", S.OverheadInfo, function(v)
    S.OverheadInfo = v
    refreshOverheads()
    saveConfig()
end)

visualTab:AddSection("HITBOX EXPANSION")

local function applyHitbox(p)
    if p == LP then return end
    local char = p.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
    if not hrp then return end
    
    if S.HitboxTeamCheck and p.Team == LP.Team then
        restoreHitbox(p)
        return
    end
    
    if not S.HitboxStore[p] then
        S.HitboxStore[p] = {
            OriginalSize = hrp.Size,
            OriginalCanCollide = hrp.CanCollide
        }
    end
    
    hrp.Size = Vector3.new(S.HitboxSize, S.HitboxSize, S.HitboxSize)
    hrp.CanCollide = false
    
    local adorn = hrp:FindFirstChild("VoidHitboxAdorn")
    if not adorn then
        adorn = Instance.new("BoxHandleAdornment")
        adorn.Name = "VoidHitboxAdorn"
        adorn.AlwaysOnTop = true
        adorn.ZIndex = 5
        adorn.Adornee = hrp
        adorn.Parent = hrp
    end
    adorn.Size = hrp.Size
    adorn.Color3 = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(218, 38, 38)
    adorn.Transparency = S.HitboxTransparency
end

local function updateHitboxes()
    if S.HitboxExpanded then
        for _, p in ipairs(Players:GetPlayers()) do
            applyHitbox(p)
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            restoreHitbox(p)
        end
    end
end

local hitboxToggle = visualTab:AddToggle("Enable Hitbox Expansion", S.HitboxExpanded, function(v)
    S.HitboxExpanded = v
    updateHitboxes()
    saveConfig()
end)

local hitboxSizeSlider = visualTab:AddSlider("Hitbox Size (studs)", 2, 30, S.HitboxSize, function(v)
    S.HitboxSize = v
    updateHitboxes()
    saveConfig()
end)

local hitboxTeamToggle = visualTab:AddToggle("Hitbox Team Check", S.HitboxTeamCheck, function(v)
    S.HitboxTeamCheck = v
    updateHitboxes()
    saveConfig()
end)

local hitboxTransSlider = visualTab:AddSlider("Hitbox Box Transparency (%)", 0, 100, S.HitboxTransparency * 100, function(v)
    S.HitboxTransparency = v / 100
    updateHitboxes()
    saveConfig()
end)

visualTab:AddSection("MAP & RENDERING ADVANTAGES")
visualTab:AddToggle("Map X-Ray (See through walls)", S.MapXray, function(v)
    toggleMapXray(v)
    saveConfig()
end)
visualTab:AddToggle("Clear Vision (No Fog/Blur)", S.ClearVision, function(v)
    toggleClearVision(v)
    saveConfig()
end)

-- ──────────────────────────────────────────────────────────────
--  TAB 3 ▸ COMBAT
-- ──────────────────────────────────────────────────────────────
local combatTab = Win:AddTab("Combat")


combatTab:AddSection("OFFENSIVE EXPLOITS")
combatTab:AddToggle("God Mode (Infinite Health)", S.GodMode, function(v)
    S.GodMode = v
    if v then
        if LP.Character then applyGodMode(LP.Character) end
    else
        disableGodMode()
    end
    saveConfig()
end)
combatTab:AddToggle("Kill Aura (Requires Melee)", S.KillAura, function(v)
    S.KillAura = v
    saveConfig()
end)
combatTab:AddSlider("Kill Aura Range (studs)", 5, 50, S.KillAuraRange, function(v)
    S.KillAuraRange = v
    saveConfig()
end)
combatTab:AddToggle("Auto Clicker (Hold Left Click)", S.AutoClicker, function(v)
    S.AutoClicker = v
    saveConfig()
end)

combatTab:AddSection("AIMBOT SYSTEM")
local aimbotToggle = combatTab:AddToggle("Enable Target Aimbot", S.AimbotActive, function(v)
    S.AimbotActive = v
    notify("Aimbot " .. (v and "Enabled (Hold Right Click)" or "Disabled"), Color3.fromRGB(50, 195, 75))
    saveConfig()
end)

local aimbotTeamToggle = combatTab:AddToggle("Aimbot Team Check", S.AimbotTeamCheck, function(v)
    S.AimbotTeamCheck = v
    saveConfig()
end)

local aimbotShowFOVToggle = combatTab:AddToggle("Draw FOV Circle", S.AimbotShowFOV, function(v)
    S.AimbotShowFOV = v
    saveConfig()
end)

local aimbotFOVSlider = combatTab:AddSlider("FOV Circle Radius", 20, 600, S.AimbotFOV, function(v)
    S.AimbotFOV = v
    saveConfig()
end)

local aimbotSmoothSlider = combatTab:AddSlider("Aimbot Smoothness", 1, 30, S.AimbotSmooth, function(v)
    S.AimbotSmooth = v
    saveConfig()
end)

local aimbotVisToggle = combatTab:AddToggle("Wall Visibility Check", S.AimbotVisibility, function(v)
    S.AimbotVisibility = v
    saveConfig()
end)

local aimbotPartDrop = combatTab:AddDropdown("Locked Target Part", {"Head", "Torso", "Random"}, table.find({"Head", "Torso", "Random"}, S.AimbotPart) or 1, function(_, opt)
    S.AimbotPart = opt
    saveConfig()
end)

-- Aimbot Drawing Circle Setup
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = Color3.fromRGB(218, 38, 38)
fovCircle.Filled = false
fovCircle.Transparency = 1
getgenv().VoidFOVCircle = fovCircle

-- ──────────────────────────────────────────────────────────────
--  TAB 4 ▸ MOVEMENT
-- ──────────────────────────────────────────────────────────────
local moveTab = Win:AddTab("Movement")

moveTab:AddButton("Reset Speed & Jump defaults", "RESET", function()
    S.WalkSpeed = 16
    S.JumpPower = 50
    speedSlider:Set(16)
    jumpSlider:Set(50)
    local hum = getHum()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end
end)

moveTab:AddSection("CHARACTER STAT MODIFICATIONS")
local speedSlider = moveTab:AddSlider("WalkSpeed Speed", 16, 250, S.WalkSpeed, function(v)
    S.WalkSpeed = v
    local hum = getHum()
    if hum then hum.WalkSpeed = v end
    saveConfig()
end)
moveTab:AddToggle("Always Enforce WalkSpeed (Anti-Slow)", S.ForceWalkSpeed, function(v)
    S.ForceWalkSpeed = v
    saveConfig()
end)
local sprintToggle = moveTab:AddToggle("LeftShift Sprint Speed Boost", S.SprintEnabled, function(v)
    S.SprintEnabled = v
    if not v then
        local hum = getHum()
        if hum then hum.WalkSpeed = S.WalkSpeed end
    end
    saveConfig()
end)
local sprintSpeedSlider = moveTab:AddSlider("Sprint Speed Factor", 20, 150, S.SprintSpeed, function(v)
    S.SprintSpeed = v
    saveConfig()
end)

local jumpSlider = moveTab:AddSlider("JumpPower Strength", 50, 350, S.JumpPower, function(v)
    S.JumpPower = v
    local hum = getHum()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = v
    end
    saveConfig()
end)
moveTab:AddToggle("Always Enforce JumpPower", S.ForceJumpPower, function(v)
    S.ForceJumpPower = v
    saveConfig()
end)

local flyToggle = moveTab:AddToggle("Fly Mode (WASD+Space/Ctrl)", S.Fly, function(v)
    S.Fly = v
    if v then flyOn() else flyOff() end
    saveConfig()
end)

local flySpeedSlider = moveTab:AddSlider("Fly speed factor", 10, 300, S.FlySpeed, function(v)
    S.FlySpeed = v
    saveConfig()
end)

local infJumpToggle = moveTab:AddToggle("Infinite Jump Ability", S.InfJump, function(v)
    S.InfJump = v
    saveConfig()
end)

local bhopToggle = moveTab:AddToggle("Auto bunnyhop", S.BHop, function(v)
    S.BHop = v
    saveConfig()
end)

local airwalkToggle = moveTab:AddToggle("Air Walk Plate platform", S.AirWalk, function(v)
    S.AirWalk = v
    saveConfig()
end)

local noclipToggle = moveTab:AddToggle("NoClip (Pass walls)", S.NoClip, function(v)
    S.NoClip = v
    saveConfig()
end)

moveTab:AddSection("BLINK TELEPORT")
local blinkDistSlider = moveTab:AddSlider("Blink Range (studs)", 5, 150, S.BlinkDistance, function(v)
    S.BlinkDistance = v
    saveConfig()
end)

local blinkModeDrop = moveTab:AddDropdown("Blink Vector Direction", {"Camera Look", "Movement Direction"}, S.BlinkDirection == "Movement Direction" and 2 or 1, function(_, opt)
    S.BlinkDirection = opt
    saveConfig()
end)

local blinkBind = moveTab:AddKeybind("Blink Teleport Key", S.BlinkKey, function(k)
    S.BlinkKey = k
    saveConfig()
end)

moveTab:AddSection("GHOST STATE MODE")
local ghostToggle = moveTab:AddToggle("Enable Ghost mode", S.GhostMode, function(v)
    S.GhostMode = v
    if v then
        enableGhostMode()
    else
        disableGhostMode()
    end
    saveConfig()
end)
local ghostTpToggle = moveTab:AddToggle("Teleport to Ghost End Position", S.GhostTeleportToEnd, function(v)
    S.GhostTeleportToEnd = v
    saveConfig()
end)

moveTab:AddSection("ADVANCED PHYSICAL MODIFIERS")
moveTab:AddToggle("Float Mode (Float in Place)", S.Float, function(v)
    toggleFloat(v)
    saveConfig()
end)
moveTab:AddToggle("Water Walk (Jesus Mode)", S.WaterWalk, function(v)
    toggleWaterWalk(v)
    saveConfig()
end)
moveTab:AddToggle("Tall Animations (R15 Gigantism)", S.TallAnim, function(v)
    S.TallAnim = v
    if v and LP.Character then
        applyTallAnimations(LP.Character)
    elseif LP.Character then
        revertTallAnimations(LP.Character)
    end
    saveConfig()
end)
moveTab:AddToggle("Player Spin (Tornado)", S.Spin, function(v)
    S.Spin = v
    saveConfig()
end)
moveTab:AddSlider("Spin Speed", 1, 100, S.SpinSpeed, function(v)
    S.SpinSpeed = v
    saveConfig()
end)
moveTab:AddToggle("Gravity Modifier", S.GravityEnabled, function(v)
    S.GravityEnabled = v
    if not v then Workspace.Gravity = 196.2 end
    saveConfig()
end)
moveTab:AddSlider("Gravity Level", 0, 500, S.CustomGravity, function(v)
    S.CustomGravity = v
    saveConfig()
end)
moveTab:AddToggle("Anti-Anchor (Prevent Server Freeze)", S.AntiAnchor, function(v)
    S.AntiAnchor = v
    saveConfig()
end)
moveTab:AddToggle("Anti-Sit (Prevent Sitting)", S.AntiSit, function(v)
    S.AntiSit = v
    if v then
        local hum = getHum()
        if hum then hum.Sit = false end
    end
    saveConfig()
end)

-- ──────────────────────────────────────────────────────────────
--  TAB 5 ▸ PLAYERS (ENHANCED PLAYER LIST)
-- ──────────────────────────────────────────────────────────────
local playersTab = Win:AddTab("Players")

playersTab:AddSection("SPECTATE SYSTEM CONTROL")
local specNameRow = playersTab:AddInfoRow("Viewing Target Name", "--")
local specHpRow   = playersTab:AddInfoRow("Target Health", "--")
local specTeamRow = playersTab:AddInfoRow("Target Team", "--")

local spectateIndex = 1
local isSpectating = false
isFreecam = false
freecamConnection = nil

local function getSpectateList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p) end
    end
    return list
end

local function applySpectate()
    local list = getSpectateList()
    if #list == 0 then
        notify("No targets in server to spectate", Color3.fromRGB(218, 38, 38))
        return
    end
    spectateIndex = math.clamp(spectateIndex, 1, #list)
    local target = list[spectateIndex]
    if target then
        spectatePlayer(target)
    end
end

local camYaw = 0
local camPitch = 0
freecamInputConn = nil
freecamBasePos = nil

local function getFreecamBasis()
    local rot = CFrame.fromOrientation(camPitch, camYaw, 0)
    local forward = rot.LookVector
    local right = rot.RightVector
    local flatForward = Vector3.new(forward.X, 0, forward.Z)
    local flatRight = Vector3.new(right.X, 0, right.Z)

    if flatForward.Magnitude > 0 then flatForward = flatForward.Unit end
    if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end

    return rot, flatForward, flatRight
end

local function enableFreecam()
    isFreecam = true
    
    local hrp = getHRP()
    if hrp then
        hrp.Anchored = true
    end

    Camera.CameraType = Enum.CameraType.Scriptable
    freecamBasePos = Camera.CFrame.Position
    notify("Freecam active. Hold Right-Click to look around. WASD to move.", Color3.fromRGB(50, 195, 75))

    local pitch, yaw = Camera.CFrame:ToOrientation()
    camYaw = yaw
    camPitch = pitch

    if freecamInputConn then freecamInputConn:Disconnect() freecamInputConn = nil end
    if freecamInputBeganConn then freecamInputBeganConn:Disconnect() freecamInputBeganConn = nil end
    if freecamInputEndedConn then freecamInputEndedConn:Disconnect() freecamInputEndedConn = nil end

    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end

    freecamInputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not isFreecam then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end)

    freecamInputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    freecamInputConn = UserInputService.InputChanged:Connect(function(input)
        if not isFreecam then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local delta = input.Delta
            camYaw = camYaw - delta.X * 0.003
            camPitch = math.clamp(camPitch - delta.Y * 0.003, -math.rad(80), math.rad(80))
        end
    end)

    if freecamConnection then
        freecamConnection:Disconnect()
        freecamConnection = nil
    end

    freecamConnection = RunService.RenderStepped:Connect(function(dt)
        if not isFreecam then return end

        local hrp = getHRP()
        if hrp and not hrp.Anchored then
            hrp.Anchored = true
        end

        local rot, flatForward, flatRight = getFreecamBasis()
        local dir = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += flatForward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= flatForward end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= flatRight end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += flatRight end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir -= Vector3.new(0, 1, 0)
        end

        local speedMultiplier = UserInputService:IsKeyDown(Enum.KeyCode.RightShift) and 3 or 1
        local moveSpeed = S.FreecamSpeed * speedMultiplier

        if dir.Magnitude > 0 then
            freecamBasePos += dir.Unit * moveSpeed * dt
        end

        Camera.CFrame = CFrame.new(freecamBasePos) * rot
    end)
end

local function disableFreecam()
    isFreecam = false
    
    local hrp = getHRP()
    if hrp then
        hrp.Anchored = false
    end

    if freecamConnection then freecamConnection:Disconnect() freecamConnection = nil end
    if freecamInputConn then freecamInputConn:Disconnect() freecamInputConn = nil end
    if freecamInputBeganConn then freecamInputBeganConn:Disconnect() freecamInputBeganConn = nil end
    if freecamInputEndedConn then freecamInputEndedConn:Disconnect() freecamInputEndedConn = nil end
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    freecamBasePos = nil
    Camera.CameraType = Enum.CameraType.Custom
    local hum = getHum()
    if hum then
        Camera.CameraSubject = hum
    end
    notify("Freecam disabled", Color3.fromRGB(218, 38, 38))
end

playersTab:AddButton("Toggle Freecam mode", "FREECAM", function()
    if isFreecam then disableFreecam() else enableFreecam() end
end)
playersTab:AddSlider("Freecam Flight Speed", 10, 300, S.FreecamSpeed, function(v)
    S.FreecamSpeed = v
    saveConfig()
end)

playersTab:AddSection("ENHANCED PLAYER UTILITY LIST")
local listOuterFrame = playersTab:AddFrame(220)
listOuterFrame.BackgroundTransparency = 1

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, 0, 1, 0)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 3
playerScroll.ScrollBarImageColor3 = Color3.fromRGB(218, 38, 38)
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerScroll.Parent = listOuterFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerScroll
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
end)

local function addPlayerCard(p)
    if playerCards[p] then return end
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 50)
    card.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    card.BorderSizePixel = 0
    card.Parent = playerScroll
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(34, 34, 34)
    stroke.Thickness = 1
    stroke.Parent = card
    
    local pfp = Instance.new("ImageLabel")
    pfp.Size = UDim2.new(0, 40, 0, 40)
    pfp.Position = UDim2.new(0, 5, 0.5, -20)
    pfp.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    pfp.BorderSizePixel = 0
    pfp.Parent = card
    
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(
                p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if ok and img then pfp.Image = img end
    end)
    
    local nameL = Instance.new("TextLabel")
    nameL.Text = p.DisplayName
    nameL.Font = Enum.Font.GothamBold
    nameL.TextSize = 11
    nameL.TextColor3 = Color3.fromRGB(230, 230, 230)
    nameL.BackgroundTransparency = 1
    nameL.Position = UDim2.new(0, 52, 0, 4)
    nameL.Size = UDim2.new(0, 140, 0, 14)
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.Parent = card
    
    local userL = Instance.new("TextLabel")
    userL.Text = "@" .. p.Name
    userL.Font = Enum.Font.Gotham
    userL.TextSize = 9
    userL.TextColor3 = Color3.fromRGB(120, 120, 120)
    userL.BackgroundTransparency = 1
    userL.Position = UDim2.new(0, 52, 0, 18)
    userL.Size = UDim2.new(0, 140, 0, 12)
    userL.TextXAlignment = Enum.TextXAlignment.Left
    userL.Parent = card
    
    local friendL = Instance.new("TextLabel")
    friendL.Font = Enum.Font.GothamBold
    friendL.TextSize = 9
    friendL.BackgroundTransparency = 1
    friendL.Position = UDim2.new(0, 190, 0, 8)
    friendL.Size = UDim2.new(0, 60, 0, 12)
    friendL.TextXAlignment = Enum.TextXAlignment.Left
    friendL.Parent = card
    
    task.spawn(function()
        local isFr = checkFriendship(p.UserId)
        if isFr then
            friendL.Text = "⭐ Friend"
            friendL.TextColor3 = Color3.fromRGB(218, 170, 42)
        else
            friendL.Text = "Guest"
            friendL.TextColor3 = Color3.fromRGB(75, 75, 75)
        end
    end)
    
    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(0, 130, 0, 4)
    hpBg.Position = UDim2.new(0, 52, 0, 34)
    hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    hpBg.BorderSizePixel = 0
    hpBg.Parent = card
    
    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BorderSizePixel = 0
    hpFill.BackgroundColor3 = Color3.fromRGB(50, 195, 75)
    hpFill.Parent = hpBg
    
    local function updateHpBar()
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            hpFill.Size = UDim2.new(pct, 0, 1, 0)
            hpFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
        else
            hpFill.Size = UDim2.new(0, 0, 1, 0)
        end
    end
    updateHpBar()
    
    -- TP Button
    local tpBtn = Instance.new("TextButton")
    tpBtn.Text = "TP"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.BackgroundColor3 = Color3.fromRGB(50, 195, 75)
    tpBtn.Size = UDim2.new(0, 45, 0, 20)
    tpBtn.Position = UDim2.new(1, -105, 0.5, -10)
    tpBtn.Parent = card
    
    local strokeTp = Instance.new("UIStroke")
    strokeTp.Color = Color3.fromRGB(20, 100, 30)
    strokeTp.Thickness = 1
    strokeTp.Parent = tpBtn
    
    tpBtn.MouseButton1Click:Connect(function()
        local targetHRP = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP and teleportToHRP(targetHRP) then
            notify("Teleported to " .. p.DisplayName, Color3.fromRGB(50, 195, 75))
        else
            notify("Target not loaded", Color3.fromRGB(218, 38, 38))
        end
    end)
    
    -- VIEW/UNVIEW Button
    local viewBtn = Instance.new("TextButton")
    local isCurrentlyViewing = (currentSpectateTarget == p)
    viewBtn.Text = isCurrentlyViewing and "UNVIEW" or "VIEW"
    viewBtn.Font = Enum.Font.GothamBold
    viewBtn.TextSize = 10
    viewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    viewBtn.BackgroundColor3 = isCurrentlyViewing and Color3.fromRGB(218, 38, 38) or Color3.fromRGB(22, 22, 22)
    viewBtn.Size = UDim2.new(0, 50, 0, 20)
    viewBtn.Position = UDim2.new(1, -55, 0.5, -10)
    viewBtn.Parent = card
    
    local strokeView = Instance.new("UIStroke")
    strokeView.Color = isCurrentlyViewing and Color3.fromRGB(130, 20, 20) or Color3.fromRGB(34, 34, 34)
    strokeView.Thickness = 1
    strokeView.Parent = viewBtn
    
    viewBtn.MouseButton1Click:Connect(function()
        if currentSpectateTarget == p then
            spectatePlayer(nil)
        else
            spectatePlayer(p)
        end
    end)
    
    playerCards[p] = {
        Card = card,
        ViewBtn = viewBtn,
        UIStroke = strokeView,
        HPConn = nil,
        CharConn = nil
    }

    local function hookHum(char)
        if playerCards[p] and playerCards[p].HPConn then
            pcall(function() playerCards[p].HPConn:Disconnect() end)
            playerCards[p].HPConn = nil
        end
        task.spawn(function()
            local hum = char:WaitForChild("Humanoid", 5) or char:FindFirstChildOfClass("Humanoid")
            if hum then
                local conn = hum.HealthChanged:Connect(function()
                    updateHpBar()
                end)
                if playerCards[p] then
                    playerCards[p].HPConn = conn
                else
                    conn:Disconnect()
                end
                updateHpBar()
            end
        end)
    end
    
    local charConn = p.CharacterAdded:Connect(function(char)
        hookHum(char)
    end)
    playerCards[p].CharConn = charConn
    
    if p.Character then
        hookHum(p.Character)
    end
end

local function removePlayerCard(p)
    local item = playerCards[p]
    if item then
        pcall(function()
            if item.HPConn then item.HPConn:Disconnect() end
            if item.CharConn then item.CharConn:Disconnect() end
            if item.Card then item.Card:Destroy() end
        end)
        playerCards[p] = nil
        if currentSpectateTarget == p then
            spectatePlayer(nil)
        end
    end
end

local function rebuildPlayerList()
    local live = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            live[p] = true
            if not playerCards[p] then
                addPlayerCard(p)
            end
        end
    end

    for p, _ in pairs(playerCards) do
        if not live[p] then
            removePlayerCard(p)
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        table.insert(S.Connections, p.CharacterAdded:Connect(function()
            task.defer(rebuildPlayerList)
        end))
    end
end

table.insert(S.Connections, Players.PlayerAdded:Connect(function(p)
    table.insert(S.Connections, p.CharacterAdded:Connect(function()
        task.defer(rebuildPlayerList)
    end))
end))

table.insert(S.Connections, Players.PlayerAdded:Connect(function(p)
    addPlayerCard(p)
    rebuildPlayerList()
end))

table.insert(S.Connections, Players.PlayerRemoving:Connect(function(p)
    destroyESP(p)
    
    local overhead = S.OverheadPool[p]
    if overhead then
        pcall(function() overhead:Destroy() end)
        S.OverheadPool[p] = nil
    end
    
    local stored = S.HitboxStore[p]
    if stored then
        pcall(function() restoreHitbox(p) end)
    end

    if tpSelectPlayer == p then tpSelectPlayer = nil end
    if flingSelectPlayer == p then flingSelectPlayer = nil end
    if S.FollowTarget == p then S.FollowTarget = nil; S.FollowActive = false end
    
    removePlayerCard(p)
end))

rebuildPlayerList()

playersTab:AddButton("Manually Rebuild Player List", "REFRESH", rebuildPlayerList)

playersTab:AddSection("PLAYER FLING SYSTEM")
local flingSelectPlayer = nil
local flingDrop = playersTab:AddDropdown("Select Player", {"(none)"}, 1, function(_, opt)
    flingSelectPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        local formatName = p.DisplayName .. " (@" .. p.Name .. ")"
        if formatName == opt then
            flingSelectPlayer = p
            break
        end
    end
end)

local function refreshFlingDropdown(filter)
    local list = {"(none)"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local matches = true
            if filter and filter ~= "" then
                matches = p.Name:lower():find(filter:lower()) or p.DisplayName:lower():find(filter:lower())
            end
            if matches then
                table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")")
            end
        end
    end
    
    local oldFling = flingSelectPlayer
    if flingDrop then
        flingDrop:SetOptions(list)
        local formattedOld = oldFling and (oldFling.DisplayName .. " (@" .. oldFling.Name .. ")")
        if formattedOld and table.find(list, formattedOld) then
            flingSelectPlayer = oldFling
        else
            flingSelectPlayer = nil
        end
    end
end

local flingSearchInput = playersTab:AddTextInput("Search Target Name", "SEARCH", function(txt)
    refreshFlingDropdown(txt)
end)

playersTab:AddButton("Fling Targeted Player", "FLING", function()
    if not flingSelectPlayer then
        notify("Select a player first!", Color3.fromRGB(218, 38, 38))
        return
    end
    
    local myChar = LP.Character
    local myHRP = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar.PrimaryPart)
    local tgtChar = flingSelectPlayer.Character
    local tgtHRP = tgtChar and (tgtChar:FindFirstChild("HumanoidRootPart") or tgtChar:FindFirstChild("Torso") or tgtChar.PrimaryPart)
    
    if not myHRP or not tgtHRP then
        notify("Character or target root not loaded!", Color3.fromRGB(218, 38, 38))
        return
    end
    
    local originalCF = myHRP.CFrame
    S.FlingActive = true
    notify("Initiating fling on target...", Color3.fromRGB(218, 170, 42))
    
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if myHum then myHum:ChangeState(Enum.HumanoidStateType.Physics) end
    
    local disableCollisions
    disableCollisions = RunService.Stepped:Connect(function()
        if not S.FlingActive or not myChar then
            disableCollisions:Disconnect()
            return
        end
        for _, p in ipairs(myChar:GetDescendants()) do
            if p:IsA("BasePart") then
                if p.Name == "HumanoidRootPart" then
                    p.CanCollide = true
                else
                    p.CanCollide = false
                end
            end
        end
    end)
    
    task.spawn(function()
        local startT = tick()
        while tick() - startT < 3.5 and S.FlingActive and tgtHRP and tgtHRP.Parent and myHRP and myHRP.Parent do
            local angle = tick() * 30
            local offset = Vector3.new(math.sin(angle) * 1.2, 0.1, math.cos(angle) * 1.2)
            myHRP.CFrame = CFrame.new(tgtHRP.Position + offset + (tgtHRP.Velocity * 0.12))
            myHRP.AssemblyLinearVelocity = Vector3.new(10000, 10000, 10000)
            myHRP.AssemblyAngularVelocity = Vector3.new(0, 50000, 0)
            task.wait()
        end
        S.FlingActive = false
        if myHRP and myHRP.Parent then
            myHRP.AssemblyLinearVelocity = Vector3.zero
            myHRP.AssemblyAngularVelocity = Vector3.zero
            myHRP.CFrame = originalCF
        end
        if myHum and myHum.Parent then myHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        notify("Fling process complete", Color3.fromRGB(50, 195, 75))
    end)
end)

playersTab:AddButton("Fling All Players", "FLING ALL", function()
    notify("Flinging all players...", Color3.fromRGB(218, 170, 42))
    task.spawn(function()
        local myChar = LP.Character
        local myHRP = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar.PrimaryPart)
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum then return end
        local originalCF = myHRP.CFrame
        local disableCollisions
        disableCollisions = RunService.Stepped:Connect(function()
            if not S.FlingActive or not myChar then
                disableCollisions:Disconnect()
                return
            end
            for _, p in ipairs(myChar:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = (p.Name == "HumanoidRootPart")
                end
            end
        end)
        S.FlingActive = true
        myHum:ChangeState(Enum.HumanoidStateType.Physics)
        for _, p in ipairs(Players:GetPlayers()) do
            local targetHRP = p.Character and (p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart)
            if p ~= LP and p.Character and targetHRP then
                local startT = tick()
                while tick() - startT < 0.8 and S.FlingActive and targetHRP and targetHRP.Parent and myHRP and myHRP.Parent do
                    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 1)
                    myHRP.AssemblyLinearVelocity = Vector3.new(10000, 10000, 10000)
                    myHRP.AssemblyAngularVelocity = Vector3.new(0, 50000, 0)
                    task.wait()
                end
            end
        end
        S.FlingActive = false
        if myHRP and myHRP.Parent then
            myHRP.AssemblyLinearVelocity = Vector3.zero
            myHRP.AssemblyAngularVelocity = Vector3.zero
            myHRP.CFrame = originalCF
        end
        if myHum and myHum.Parent then myHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        notify("Fling All process complete", Color3.fromRGB(50, 195, 75))
    end)
end)

playerCards = {}
currentSpectateTarget = nil

local function resetCameraToSelf()
    currentSpectateTarget = nil
    isSpectating = false

    if freecamConnection then freecamConnection:Disconnect() freecamConnection = nil end
    if freecamInputConn then freecamInputConn:Disconnect() freecamInputConn = nil end
    isFreecam = false
    freecamBasePos = nil

    Camera.CameraType = Enum.CameraType.Custom
    local hum = getHum()
    if hum then
        Camera.CameraSubject = hum
    end

    specNameRow:SetValue("--")
    specHpRow:SetValue("--")
    specTeamRow:SetValue("--")
    specNameRow:SetColor(Color3.fromRGB(235, 235, 235))

    for _, item in pairs(playerCards) do
        if item.ViewBtn then
            item.ViewBtn.Text = "VIEW"
            item.ViewBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        end
        if item.UIStroke then
            item.UIStroke.Color = Color3.fromRGB(34, 34, 34)
        end
    end
end

spectatePlayer = function(targetPlayer)
    if not targetPlayer then
        resetCameraToSelf()
        return
    end

    if isFreecam then
        disableFreecam()
    end

    local hum = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        currentSpectateTarget = targetPlayer
        isSpectating = true
        Camera.CameraType = Enum.CameraType.Watch
        Camera.CameraSubject = hum
        notify("Viewing " .. targetPlayer.DisplayName, Color3.fromRGB(218, 170, 42))

        for p, item in pairs(playerCards) do
            if item.ViewBtn then
                if p == targetPlayer then
                    item.ViewBtn.Text = "UNVIEW"
                    item.ViewBtn.BackgroundColor3 = Color3.fromRGB(218, 38, 38)
                    if item.UIStroke then
                        item.UIStroke.Color = Color3.fromRGB(130, 20, 20)
                    end
                else
                    item.ViewBtn.Text = "VIEW"
                    item.ViewBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                    if item.UIStroke then
                        item.UIStroke.Color = Color3.fromRGB(34, 34, 34)
                    end
                end
            end
        end
    else
        notify("Target humanoid not loaded!", Color3.fromRGB(218, 38, 38))
        resetCameraToSelf()
    end
end

playersTab:AddSection("TELEPORT & WATCH UTILITIES")
local tpSelectPlayer = nil
local tpDrop = playersTab:AddDropdown("Target Teleport Player", {"(none)"}, 1, function(_, opt)
    tpSelectPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        local formatName = p.DisplayName .. " (@" .. p.Name .. ")"
        if formatName == opt then
            tpSelectPlayer = p
            break
        end
    end
end)

local function refreshPlayerDropdowns()
    local list = {"(none)"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    
    local oldTP = tpSelectPlayer
    if tpDrop then
        tpDrop:SetOptions(list)
        local formattedOld = oldTP and (oldTP.DisplayName .. " (@" .. oldTP.Name .. ")")
        if formattedOld and table.find(list, formattedOld) then
            tpSelectPlayer = oldTP
        else
            tpSelectPlayer = nil
        end
    end
    
    local oldFling = flingSelectPlayer
    if flingDrop then
        flingDrop:SetOptions(list)
        local formattedOld = oldFling and (oldFling.DisplayName .. " (@" .. oldFling.Name .. ")")
        if formattedOld and table.find(list, formattedOld) then
            flingSelectPlayer = oldFling
        else
            flingSelectPlayer = nil
        end
    end
end
table.insert(S.Connections, Players.PlayerAdded:Connect(refreshPlayerDropdowns))
table.insert(S.Connections, Players.PlayerRemoving:Connect(refreshPlayerDropdowns))
refreshPlayerDropdowns()

playersTab:AddButton("Teleport To Target", "WARP", function()
    local tgtHRP = tpSelectPlayer and tpSelectPlayer.Character and (tpSelectPlayer.Character:FindFirstChild("HumanoidRootPart") or tpSelectPlayer.Character:FindFirstChild("Torso") or tpSelectPlayer.Character.PrimaryPart)
    if tgtHRP and teleportToHRP(tgtHRP) then
        notify("Warped to " .. tpSelectPlayer.DisplayName, Color3.fromRGB(50, 195, 75))
    else
        notify("Warp Target not available", Color3.fromRGB(218, 38, 38))
    end
end)
playersTab:AddButton("Teleport to Nearest Player", "NEAREST", function()
    local myHRP = getHRP()
    if not myHRP then
        notify("Self root part not found!", Color3.fromRGB(218, 38, 38))
        return
    end
    local nearest = nil
    local shortestDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart
            if root then
                local dist = (root.Position - myHRP.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearest = p
                end
            end
        end
    end
    if nearest then
        local targetHRP = nearest.Character:FindFirstChild("HumanoidRootPart") or nearest.Character:FindFirstChild("Torso") or nearest.Character.PrimaryPart
        if teleportToHRP(targetHRP) then
            notify("Teleported to nearest: " .. nearest.DisplayName .. string.format(" (%.1f studs)", shortestDist), Color3.fromRGB(50, 195, 75))
        end
    else
        notify("No other players found nearby", Color3.fromRGB(218, 38, 38))
    end
end)
playersTab:AddButton("Teleport to Random Player", "RANDOM", function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart
            if root then
                table.insert(list, p)
            end
        end
    end
    if #list > 0 then
        local chosen = list[math.random(1, #list)]
        local targetHRP = chosen.Character:FindFirstChild("HumanoidRootPart") or chosen.Character:FindFirstChild("Torso") or chosen.Character.PrimaryPart
        if teleportToHRP(targetHRP) then
            notify("Teleported to random: " .. chosen.DisplayName, Color3.fromRGB(50, 195, 75))
        end
    else
        notify("No alternative player found to teleport to", Color3.fromRGB(218, 38, 38))
    end
end)

playersTab:AddButton("Watch Player Camera", "SPECTATE", function()
    if not tpSelectPlayer then
        notify("Select target first!", Color3.fromRGB(218, 38, 38))
        return
    end
    spectatePlayer(tpSelectPlayer)
end)

local followToggle = playersTab:AddToggle("Auto Follow Player", S.FollowActive, function(v)
    S.FollowActive = v
    S.FollowTarget = tpSelectPlayer
    if v then notify("Following Target", Color3.fromRGB(218, 170, 42)) end
    saveConfig()
end)

-- ──────────────────────────────────────────────────────────────
--  TAB 6 ▸ WORLD
-- ──────────────────────────────────────────────────────────────
local worldTab = Win:AddTab("World")

worldTab:AddSection("UTILITY TRIGGERS")
local promptToggle = worldTab:AddToggle("Instant Proximity Prompts", S.InstantPrompts, function(v)
    S.InstantPrompts = v
    if v then
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then p.HoldDuration = 0 end
        end
    end
    saveConfig()
end)

table.insert(S.Connections, Workspace.DescendantAdded:Connect(function(obj)
    if S.InstantPrompts and obj:IsA("ProximityPrompt") then
        obj.HoldDuration = 0
    end
    if S.GraphicsReducer then
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end
end))

worldTab:AddButton("Fire All ClickDetectors", "FIRE CD", function()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            pcall(function()
                fireclickdetector(obj)
                count = count + 1
            end)
        end
    end
    notify(string.format("Fired %d ClickDetectors!", count), Color3.fromRGB(50, 195, 75))
end)

worldTab:AddSection("WORLD AUTOMATIONS")
worldTab:AddToggle("Auto-Trigger Nearby Prompts", S.AutoInteract, function(v)
    S.AutoInteract = v
    saveConfig()
end)
worldTab:AddSlider("Auto-Trigger Radius (studs)", 5, 50, S.AutoInteractRadius, function(v)
    S.AutoInteractRadius = v
    saveConfig()
end)
worldTab:AddToggle("Tool & Drop Magnet", S.ToolMagnet, function(v)
    S.ToolMagnet = v
    saveConfig()
end)
worldTab:AddToggle("Auto-Jump (Edge Detection)", S.AutoJump, function(v)
    S.AutoJump = v
    saveConfig()
end)
worldTab:AddToggle("Anti-Fling (No Player Collision)", S.AntiFling, function(v)
    S.AntiFling = v
    saveConfig()
end)

worldTab:AddSection("MAP WAYPOINTS")
worldTab:AddButton("Save Current Location", "SAVE", function()
    local hrp = getHRP()
    if hrp then
        S.SavedWaypointCF = hrp.CFrame
        notify("Current location coordinates locked!", Color3.fromRGB(50, 195, 75))
    else
        notify("HumanoidRootPart not found", Color3.fromRGB(218, 38, 38))
    end
end)
worldTab:AddButton("Teleport to Saved Location", "WARP", function()
    if S.SavedWaypointCF then
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = S.SavedWaypointCF
            notify("Returned to saved waypoint!", Color3.fromRGB(50, 195, 75))
        else
            notify("HumanoidRootPart not found", Color3.fromRGB(218, 38, 38))
        end
    else
        notify("No waypoint saved yet", Color3.fromRGB(218, 38, 38))
    end
end)

worldTab:AddButton("Destroy All Killbricks", "CLEANSE", function()
    local count = 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("TouchTransmitter") and v.Parent and not v.Parent:IsDescendantOf(LP.Character) then
            local parentName = v.Parent.Name:lower()
            if parentName:match("kill") or parentName:match("lava") or v.Parent.BrickColor.Name == "Bright red" then
                v:Destroy()
                count = count + 1
            end
        end
    end
    notify(string.format("Destroyed %d potential killbrick scripts!", count), Color3.fromRGB(50, 195, 75))
end)

worldTab:AddButton("Destroy All Seats", "NO SEATS", function()
    local count = 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if (v:IsA("Seat") or v:IsA("VehicleSeat")) and not v:IsDescendantOf(LP.Character) then
            pcall(function()
                v:Destroy()
                count = count + 1
            end)
        end
    end
    notify(string.format("Destroyed %d seats client-side!", count), Color3.fromRGB(50, 195, 75))
end)

worldTab:AddSection("ANTI-VOID SAFETY NET")
local antiVoidToggle = worldTab:AddToggle("Anti-Void Rescue Mode", S.AntiVoid, function(v)
    S.AntiVoid = v
    saveConfig()
end)

local antiVoidSlider = worldTab:AddSlider("Anti-Void Height Y Offset", -2000, -100, S.AntiVoidY, function(v)
    S.AntiVoidY = v
    saveConfig()
end)

-- ──────────────────────────────────────────────────────────────
--  TAB 8 ▸ SERVER
-- ──────────────────────────────────────────────────────────────
local serverTab = Win:AddTab("Server")

serverTab:AddSection("SERVER MANAGEMENT ACTIONS")
serverTab:AddButton("Rejoin Current Instance", "REJOIN", function()
    notify("Rejoining server instance...", Color3.fromRGB(218, 170, 42))
    setupAutoReinject()
    task.delay(0.5, function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
end)

local function fetchServerList()
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    
    for page = 1, 3 do
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&cursor=%s", placeId, cursor)
        local res = robloxGet(url)
        if not res or type(res) ~= "string" then break end
        
        local ok, data = pcall(function()
            return HttpService:JSONDecode(res)
        end)
        
        if ok and data and data.data then
            for _, srv in ipairs(data.data) do
                table.insert(servers, srv)
            end
            if data.nextPageCursor and data.nextPageCursor ~= "" then
                cursor = data.nextPageCursor
            else
                break
            end
        else
            break
        end
    end
    
    return #servers > 0 and servers or nil
end

local function teleportToLowestPop()
    notify("Scanning for servers...", Color3.fromRGB(218, 170, 42))
    local servers = fetchServerList()
    if not servers or #servers == 0 then
        notify("Failed to fetch list", Color3.fromRGB(218, 38, 38))
        return
    end
    
    table.sort(servers, function(a, b)
        return (a.playing or 0) < (b.playing or 0)
    end)
    
    local curJob = game.JobId
    for _, srv in ipairs(servers) do
        local playing = srv.playing or 0
        local maxPl = srv.maxPlayers or 50
        if srv.id ~= curJob and playing < maxPl then
            notify(string.format("Warping to low pop (%d/%d)...", playing, maxPl), Color3.fromRGB(50, 195, 75))
            setupAutoReinject()
            local success = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
            end)
            if success then return end
        end
    end
    notify("No alternative server candidate found", Color3.fromRGB(218, 38, 38))
end

local function teleportToHighestPop()
    notify("Scanning for servers...", Color3.fromRGB(218, 170, 42))
    local servers = fetchServerList()
    if not servers or #servers == 0 then
        notify("Failed to fetch list", Color3.fromRGB(218, 38, 38))
        return
    end
    
    table.sort(servers, function(a, b)
        return (a.playing or 0) > (b.playing or 0)
    end)
    
    local curJob = game.JobId
    for _, srv in ipairs(servers) do
        local playing = srv.playing or 0
        local maxPl = srv.maxPlayers or 50
        if srv.id ~= curJob and playing < maxPl then
            notify(string.format("Warping to high pop (%d/%d)...", playing, maxPl), Color3.fromRGB(50, 195, 75))
            setupAutoReinject()
            local success = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
            end)
            if success then return end
        end
    end
    notify("No alternative server candidate found", Color3.fromRGB(218, 38, 38))
end

local function teleportToRandom()
    notify("Scanning for servers...", Color3.fromRGB(218, 170, 42))
    local servers = fetchServerList()
    if not servers or #servers == 0 then
        notify("Failed to fetch list", Color3.fromRGB(218, 38, 38))
        return
    end
    
    local curJob = game.JobId
    local candidates = {}
    for _, srv in ipairs(servers) do
        local playing = srv.playing or 0
        local maxPl = srv.maxPlayers or 50
        if srv.id ~= curJob and playing < maxPl then
            table.insert(candidates, srv)
        end
    end
    
    if #candidates > 0 then
        local chosen = candidates[math.random(1, #candidates)]
        local playing = chosen.playing or 0
        local maxPl = chosen.maxPlayers or 50
        notify(string.format("Warping to random (%d/%d)...", playing, maxPl), Color3.fromRGB(50, 195, 75))
        setupAutoReinject()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, LP)
        end)
    else
        notify("No alternative server candidate found", Color3.fromRGB(218, 38, 38))
    end
end

serverTab:AddButton("Standard Server Hop", "HOP", teleportToRandom)
serverTab:AddButton("Join Random Server", "RANDOM", teleportToRandom)
serverTab:AddButton("Join Lowest Population", "LOW POP", teleportToLowestPop)
serverTab:AddButton("Join Highest Population", "HIGH POP", teleportToHighestPop)
serverTab:AddButton("Copy Server Instance JobId", "COPY JOBID", function()
    local setclip = setclipboard or writeclipboard or toclipboard or print
    pcall(function() setclip(game.JobId) end)
    notify("Server JobId copied to clipboard!", Color3.fromRGB(50, 195, 75))
end)

serverTab:AddSection("SERVER INSTANCE DETAILS")
local rowRegion = serverTab:AddInfoRow("Region Location", "Loading...")
local rowPing   = serverTab:AddInfoRow("Connection Ping", "--")
local rowPlayers = serverTab:AddInfoRow("Player Count Status", "--")
local rowAge    = serverTab:AddInfoRow("Instance Uptime Age", "--")

pcall(function()
    local regionStr = "Roblox Cloud (" .. (game.JobId ~= "" and game.JobId:sub(1, 8) or "Studio") .. ")"
    rowRegion:SetValue(regionStr)
    rowHomeRegion:SetValue(regionStr)
end)

serverTab:AddSection("FAVORITE EXPERIENCES")

local favOuterFrame = serverTab:AddFrame(160)
favOuterFrame.BackgroundTransparency = 1

local favScroll = Instance.new("ScrollingFrame")
favScroll.Size = UDim2.new(1, 0, 1, 0)
favScroll.BackgroundTransparency = 1
favScroll.BorderSizePixel = 0
favScroll.ScrollBarThickness = 3
favScroll.ScrollBarImageColor3 = Color3.fromRGB(218, 38, 38)
favScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
favScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
favScroll.Parent = favOuterFrame

local favLayout = Instance.new("UIListLayout")
favLayout.Padding = UDim.new(0, 4)
favLayout.SortOrder = Enum.SortOrder.LayoutOrder
favLayout.Parent = favScroll

local rebuildFavorites -- Forward decl
rebuildFavorites = function()
    for _, child in ipairs(favScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    for idx, map in ipairs(S.FavoriteMaps) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 40)
        card.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        card.BorderSizePixel = 0
        card.Parent = favScroll
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(34, 34, 34)
        stroke.Thickness = 1
        stroke.Parent = card
        
        local th = Instance.new("ImageLabel")
        th.Size = UDim2.new(0, 30, 0, 30)
        th.Position = UDim2.new(0, 5, 0.5, -15)
        th.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
        th.BorderSizePixel = 0
th.ScaleType = Enum.ScaleType.Crop
th.Image = map.iconUrl
    or (map.universeId and ("rbxthumb://type=GameIcon&id=" .. map.universeId .. "&w=150&h=150"))
    or ("rbxthumb://type=PlaceIcon&id=" .. map.id .. "&w=150&h=150")
        th.Parent = card
        
        local nameL = Instance.new("TextLabel")
        nameL.Text = map.name
        nameL.Font = Enum.Font.GothamBold
        nameL.TextSize = 10
        nameL.TextColor3 = Color3.fromRGB(230, 230, 230)
        nameL.BackgroundTransparency = 1
        nameL.Position = UDim2.new(0, 42, 0, 3)
        nameL.Size = UDim2.new(0.5, 0, 0, 14)
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        nameL.Parent = card
        
        local detailsL = Instance.new("TextLabel")
        detailsL.Text = "Last Played: " .. (map.lastPlayed or "Never")
        detailsL.Font = Enum.Font.Gotham
        detailsL.TextSize = 8
        detailsL.TextColor3 = Color3.fromRGB(120, 120, 120)
        detailsL.BackgroundTransparency = 1
        detailsL.Position = UDim2.new(0, 42, 0, 16)
        detailsL.Size = UDim2.new(0.5, 0, 0, 12)
        detailsL.TextXAlignment = Enum.TextXAlignment.Left
        detailsL.Parent = card
        
        local jb = Instance.new("TextButton")
        jb.Text = "JOIN"
        jb.Font = Enum.Font.GothamBold
        jb.TextSize = 9
        jb.TextColor3 = Color3.fromRGB(255, 255, 255)
        jb.BackgroundColor3 = Color3.fromRGB(218, 38, 38)
        jb.Size = UDim2.new(0, 45, 0, 18)
        jb.Position = UDim2.new(1, -90, 0.5, -9)
        jb.Parent = card
        
        local sj = Instance.new("UIStroke")
        sj.Color = Color3.fromRGB(130, 20, 20)
        sj.Thickness = 1
        sj.Parent = jb
        
        jb.MouseButton1Click:Connect(function()
            notify("Joining fav: " .. map.name, Color3.fromRGB(218, 170, 42))
            map.lastPlayed = os.date("%Y-%m-%d %H:%M")
            saveFavorites()
            rebuildFavorites()
            task.delay(0.3, function()
                TeleportService:Teleport(map.id, LP)
            end)
        end)
        
        local rb = Instance.new("TextButton")
        rb.Text = "✕"
        rb.Font = Enum.Font.GothamBold
        rb.TextSize = 10
        rb.TextColor3 = Color3.fromRGB(218, 38, 38)
        rb.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        rb.Size = UDim2.new(0, 25, 0, 18)
        rb.Position = UDim2.new(1, -35, 0.5, -9)
        rb.Parent = card
        
        local sr = Instance.new("UIStroke")
        sr.Color = Color3.fromRGB(34, 34, 34)
        sr.Thickness = 1
        sr.Parent = rb
        
        rb.MouseButton1Click:Connect(function()
            table.remove(S.FavoriteMaps, idx)
            saveFavorites()
            rebuildFavorites()
            notify("Experience removed from list", Color3.fromRGB(218, 38, 38))
        end)
    end
    
    if #S.FavoriteMaps == 0 then
        local empty = Instance.new("TextLabel")
        empty.Text = "Favorites list is empty."
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.TextColor3 = Color3.fromRGB(120, 120, 120)
        empty.Size = UDim2.new(1, 0, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Parent = favScroll
    end
end

serverTab:AddTextInput("Save Place ID to Favorites", "+ ADD", function(text)
    local pid = tonumber(text:match("%d+"))
    if not pid then notify("Enter a valid place ID", Color3.fromRGB(218, 38, 38)) return end
    
    for _, item in ipairs(S.FavoriteMaps) do
        if item.id == pid then notify("Already in favorites!", Color3.fromRGB(218, 170, 42)) return end
    end
    
    notify("Resolving Place ID info...", Color3.fromRGB(218, 170, 42))
    
    task.spawn(function()
    local gameName = "Place: " .. pid
    local universeId = nil
    local iconUrl = nil

    pcall(function()
        local res = HttpService:JSONDecode(
            robloxGet(("https://apis.roblox.com/universes/v1/places/%d/universe"):format(pid))
        )
        if res and res.universeId then
            universeId = res.universeId

            local resDetails = HttpService:JSONDecode(
                robloxGet(("https://games.roblox.com/v1/games?universeIds=%d"):format(universeId))
            )
            if resDetails and resDetails.data and resDetails.data[1] then
                gameName = resDetails.data[1].name
            end

            local thumbRes = HttpService:JSONDecode(
                robloxGet(("https://thumbnails.roblox.com/v1/games/icons?universeIds=%d&returnPolicy=PlaceHolder&size=150x150&format=Png&isCircular=false"):format(universeId))
            )
            if thumbRes and thumbRes.data and thumbRes.data[1] and thumbRes.data[1].imageUrl then
                iconUrl = thumbRes.data[1].imageUrl
            end
        end
    end)
        
        table.insert(S.FavoriteMaps, {
            id = pid,
            universeId = universeId,
            iconUrl = iconUrl,
            name = gameName,
            lastPlayed = "Added: " .. os.date("%m-%d %H:%M")
        })
        saveFavorites()
        rebuildFavorites()
        notify("Saved: " .. gameName, Color3.fromRGB(50, 195, 75))
    end)
end)

rebuildFavorites()

-- ──────────────────────────────────────────────────────────────
--  TAB 7 ▸ SOCIAL
-- ──────────────────────────────────────────────────────────────
local socialTab = Win:AddTab("Social")

socialTab:AddSection("ONLINE FRIEND TRACKER")
local friendsOuterFrame = socialTab:AddFrame(180)
friendsOuterFrame.BackgroundTransparency = 1

local friendsScroll = Instance.new("ScrollingFrame")
friendsScroll.Size = UDim2.new(1, 0, 1, 0)
friendsScroll.BackgroundTransparency = 1
friendsScroll.BorderSizePixel = 0
friendsScroll.ScrollBarThickness = 3
friendsScroll.ScrollBarImageColor3 = Color3.fromRGB(218, 38, 38)
friendsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
friendsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
friendsScroll.Parent = friendsOuterFrame

local friendsLayout = Instance.new("UIListLayout")
friendsLayout.Padding = UDim.new(0, 4)
friendsLayout.SortOrder = Enum.SortOrder.LayoutOrder
friendsLayout.Parent = friendsScroll

local function rebuildFriendsList()
    for _, child in ipairs(friendsScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    task.spawn(function()
        local ok, onlineFriends = pcall(function()
            return LP:GetFriendsOnline(200)
        end)
        
        if not ok or not onlineFriends then
            local empty = Instance.new("TextLabel")
            empty.Text = "Failed to query online friends."
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextColor3 = Color3.fromRGB(120, 120, 120)
            empty.Size = UDim2.new(1, 0, 0, 30)
            empty.BackgroundTransparency = 1
            empty.Parent = friendsScroll
            return
        end
        
        local count = 0
        for _, item in ipairs(onlineFriends) do
            count = count + 1
            if count > 100 then break end
            
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 50)
            card.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            card.BorderSizePixel = 0
            card.Parent = friendsScroll
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(34, 34, 34)
            stroke.Thickness = 1
            stroke.Parent = card
            
            local av = Instance.new("ImageLabel")
            av.Size = UDim2.new(0, 36, 0, 36)
            av.Position = UDim2.new(0, 6, 0.5, -18)
            av.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
            av.BorderSizePixel = 0
            av.Parent = card
            
            task.spawn(function()
                local imgOk, img = pcall(function()
                    return Players:GetUserThumbnailAsync(
                        item.VisitorId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
                if imgOk then av.Image = img end
            end)
            
            local nameL = Instance.new("TextLabel")
            nameL.Text = item.DisplayName or item.UserName or "Friend"
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 10
            nameL.TextColor3 = Color3.fromRGB(230, 230, 230)
            nameL.BackgroundTransparency = 1
            nameL.Position = UDim2.new(0, 48, 0, 4)
            nameL.Size = UDim2.new(0, 110, 0, 14)
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Parent = card
            
            local userL = Instance.new("TextLabel")
            userL.Text = "@" .. (item.UserName or "")
            userL.Font = Enum.Font.Gotham
            userL.TextSize = 8
            userL.TextColor3 = Color3.fromRGB(120, 120, 120)
            userL.BackgroundTransparency = 1
            userL.Position = UDim2.new(0, 48, 0, 18)
            userL.Size = UDim2.new(0, 110, 0, 12)
            userL.TextXAlignment = Enum.TextXAlignment.Left
            userL.Parent = card
            
            local detailL = Instance.new("TextLabel")
            detailL.Font = Enum.Font.Gotham
            detailL.TextSize = 8
            detailL.BackgroundTransparency = 1
            detailL.Position = UDim2.new(0, 48, 0, 30)
            detailL.Size = UDim2.new(0, 110, 0, 12)
            detailL.TextXAlignment = Enum.TextXAlignment.Left
            detailL.Parent = card

            local isInGame = false
            local statusText = "🟢 Online"
            local statusColor = Color3.fromRGB(50, 195, 75)
            
            if item.LocationType == 1 or item.LocationType == 4 or item.LocationType == 5 or (item.GameId and item.GameId ~= "") then
                if item.PlaceId and item.PlaceId > 0 then
                    isInGame = true
                    statusText = "🎮 Playing"
                end
            elseif item.LocationType == 3 then
                statusText = "🔧 In Studio"
                statusColor = Color3.fromRGB(218, 170, 42)
            else
                statusText = "🔵 Online"
                statusColor = Color3.fromRGB(0, 162, 255)
            end
            
            detailL.Text = statusText
            detailL.TextColor3 = statusColor
            
            if isInGame then
                -- Display Game Icon
                local gameIcon = Instance.new("ImageLabel", card)
                gameIcon.Size = UDim2.new(0, 30, 0, 30)
                gameIcon.Position = UDim2.new(0, 165, 0.5, -15)
                gameIcon.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
                gameIcon.BorderSizePixel = 0
                gameIcon.Image = "rbxthumb://type=GameIcon&id=" .. item.PlaceId .. "&w=150&h=150"
                
                local sGame = Instance.new("UIStroke", gameIcon)
                sGame.Color = Color3.fromRGB(34, 34, 34)
                sGame.Thickness = 1
                
                -- Display Game Name
                local gameL = Instance.new("TextLabel", card)
                gameL.Font = Enum.Font.Gotham
                gameL.TextSize = 8
                gameL.TextColor3 = Color3.fromRGB(200, 200, 200)
                gameL.BackgroundTransparency = 1
                gameL.Position = UDim2.new(0, 200, 0.5, -15)
                gameL.Size = UDim2.new(0, 90, 0, 30)
                gameL.TextXAlignment = Enum.TextXAlignment.Left
                gameL.TextWrapped = true
                gameL.Text = item.LastLocation or "In-game"
                
                local joinBtn = Instance.new("TextButton")
                joinBtn.Text = "JOIN"
                joinBtn.Font = Enum.Font.GothamBold
                joinBtn.TextSize = 9
                joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                joinBtn.BackgroundColor3 = Color3.fromRGB(50, 195, 75)
                joinBtn.Size = UDim2.new(0, 45, 0, 20)
                joinBtn.Position = UDim2.new(1, -55, 0.5, -10)
                joinBtn.Parent = card
                
                local sBtn = Instance.new("UIStroke")
                sBtn.Color = Color3.fromRGB(20, 100, 30)
                sBtn.Thickness = 1
                sBtn.Parent = joinBtn
                
                joinBtn.MouseButton1Click:Connect(function()
                    if item.GameId and item.GameId ~= "" then
                        notify("Connecting to friend's server session...", Color3.fromRGB(50, 195, 75))
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(item.PlaceId, item.GameId, LP)
                        end)
                    else
                        notify("Warping to friend's experience...", Color3.fromRGB(50, 195, 75))
                        pcall(function()
                            TeleportService:Teleport(item.PlaceId, LP)
                        end)
                    end
                end)
            end
        end
        
        if count == 0 then
            local empty = Instance.new("TextLabel")
            empty.Text = "No friends online."
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextColor3 = Color3.fromRGB(120, 120, 120)
            empty.Size = UDim2.new(1, 0, 0, 30)
            empty.BackgroundTransparency = 1
            empty.Parent = friendsScroll
        end
    end)
end

socialTab:AddButton("Query Friends Status", "REFRESH", rebuildFriendsList)
rebuildFriendsList()

socialTab:AddSection("CHAT LOGGER FEED")
local socialChatFeed = socialTab:AddScrollFeed(200)

local function logMessage(speaker, msg, color)
    local entry = {
        Speaker = speaker,
        Message = msg,
        Color = color or Color3.fromRGB(200, 200, 200),
        Timestamp = os.date("%H:%M:%S")
    }
    table.insert(S.ChatHistory, entry)
    
    pcall(function()
        homeChatFeed:AddEntry(string.format("[%s] [%s]: %s", entry.Timestamp, speaker, msg), entry.Color)
        socialChatFeed:AddEntry(string.format("[%s] [%s]: %s", entry.Timestamp, speaker, msg), entry.Color)
    end)
    
    if S.ToastChatEnabled then
        notify(string.format("[%s]: %s", speaker, string.sub(msg, 1, 35)), entry.Color)
    end
end

-- Filter & Refresh Log Entries
local function refreshChatFeed(searchFilter)
    socialChatFeed:Clear()
    for _, log in ipairs(S.ChatHistory) do
        local matches = true
        if searchFilter and searchFilter ~= "" then
            matches = log.Speaker:lower():find(searchFilter:lower()) or log.Message:lower():find(searchFilter:lower())
        end
        if matches then
            socialChatFeed:AddEntry(string.format("[%s] [%s]: %s", log.Timestamp, log.Speaker, log.Message), log.Color)
        end
    end
end

local chatLogSearch = socialTab:AddTextInput("Filter chat logs text", "FILTER", function(text)
    refreshChatFeed(text)
end)

socialTab:AddButton("Copy Entire Chat Logs", "COPY", function()
    local text = ""
    for _, log in ipairs(S.ChatHistory) do
        text = text .. string.format("[%s] [%s]: %s\n", log.Timestamp, log.Speaker, log.Message)
    end
    
    local write = setclipboard or writeclipboard or toclipboard or print
    local ok = pcall(function() write(text) end)
    if ok then
        notify("Logs copied to clipboard!", Color3.fromRGB(50, 195, 75))
    else
        notify("Clipboard write failed", Color3.fromRGB(218, 38, 38))
    end
end)

local chatToastToggle = socialTab:AddToggle("Toast notifications on chat", S.ToastChatEnabled, function(v)
    S.ToastChatEnabled = v
    saveConfig()
end)

local hookedPlayers = {}
local function hookChat(p)
    if hookedPlayers[p] then return end
    hookedPlayers[p] = true
    table.insert(S.Connections, p.Chatted:Connect(function(msg)
        logMessage(p.DisplayName, msg, p.Team and p.Team.TeamColor.Color or Color3.fromRGB(200, 200, 200))
    end))
end

for _, p in ipairs(Players:GetPlayers()) do hookChat(p) end
table.insert(S.Connections, Players.PlayerAdded:Connect(function(p)
    logMessage("System", p.DisplayName .. " (@" .. p.Name .. ") joined the game.", Color3.fromRGB(50, 195, 75))
    hookChat(p)
end))
table.insert(S.Connections, Players.PlayerRemoving:Connect(function(p)
    logMessage("System", p.DisplayName .. " (@" .. p.Name .. ") left the game.", Color3.fromRGB(218, 38, 38))
end))

-- ──────────────────────────────────────────────────────────────
--  TAB 8.5 ▸ UTILITIES
-- ──────────────────────────────────────────────────────────────
local utilsTab = Win:AddTab("Utilities")

utilsTab:AddSection("EXPLOIT UTILITIES")
utilsTab:AddToggle("Force Enable Shift Lock", S.ForceShiftLock, function(v)
    S.ForceShiftLock = v
    pcall(function()
        LP.DevEnableMouseLock = v
    end)
    saveConfig()
end)
utilsTab:AddButton("Unlock Max Camera Zoom", "UNLOCK", function()
    LP.CameraMaxZoomDistance = 100000
    notify("Camera zoom limits unlocked infinitely!", Color3.fromRGB(50, 195, 75))
end)
utilsTab:AddButton("Give Universal BTools (Building Tools)", "BTOOLS", function()
    for i = 1, 4 do
        local t = Instance.new("HopperBin")
        t.BinType = i
        t.Parent = LP.Backpack
    end
    notify("HopperBins building tools granted to inventory!", Color3.fromRGB(50, 195, 75))
end)
utilsTab:AddToggle("Click-Delete Parts (Alt + LeftClick)", S.ClickDelete, function(v)
    S.ClickDelete = v
    saveConfig()
end)
utilsTab:AddToggle("Click Teleport (Ctrl + LeftClick)", S.ClickTeleport, function(v)
    S.ClickTeleport = v
    saveConfig()
end)
utilsTab:AddButton("Copy Game Place ID", "COPY PLACEID", function()
    local setclip = setclipboard or writeclipboard or toclipboard or print
    pcall(function() setclip(tostring(game.PlaceId)) end)
    notify("Game Place ID copied!", Color3.fromRGB(50, 195, 75))
end)
utilsTab:AddButton("Copy My Position", "COPY POS", function()
    local hrp = getHRP()
    if hrp then
        local pos = hrp.Position
        local posStr = string.format("Vector3.new(%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
        local setclip = setclipboard or writeclipboard or toclipboard or print
        pcall(function() setclip(posStr) end)
        notify("Position Vector3 copied!", Color3.fromRGB(50, 195, 75))
    else
        notify("Position not found!", Color3.fromRGB(218, 38, 38))
    end
end)
utilsTab:AddButton("Re-Enable Reset Button", "ENABLE RESET", function()
    pcall(function()
        game:GetService("StarterGui"):SetCore("ResetButtonAllowed", true)
    end)
    notify("Reset button enabled!", Color3.fromRGB(50, 195, 75))
end)
utilsTab:AddToggle("Anti-AFK (Prevent Idle Kick)", S.AntiAFK, function(v)
    S.AntiAFK = v
    saveConfig()
end)
utilsTab:AddToggle("Auto-Rejoin on Kick", S.AutoRejoin, function(v)
    S.AutoRejoin = v
    saveConfig()
end)

utilsTab:AddSection("PERFORMANCE OPTIMIZATIONS")
utilsTab:AddToggle("Lag Reducer (No 3D Rendering)", S.No3DRender, function(v)
    S.No3DRender = v
    pcall(function()
        RunService:Set3dRenderingEnabled(not v)
    end)
    saveConfig()
end)
utilsTab:AddToggle("Maximum FPS Booster (Smooth Details)", S.GraphicsReducer, function(v)
    toggleGraphicsReducer(v)
    saveConfig()
end)
utilsTab:AddSlider("FPS Limit Cap", 15, 360, S.FPSCap, function(v)
    S.FPSCap = v
    pcall(function()
        if setfpscap then
            setfpscap(v)
        end
    end)
    saveConfig()
end)

utilsTab:AddSection("ENVIRONMENT LIGHTING")
utilsTab:AddToggle("FullBright (Remove shadows & ambient)", S.FullBright, function(v)
    S.FullBright = v
    if v then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoor
    end
    saveConfig()
end)
utilsTab:AddSlider("Time of Day (Hours)", 0, 24, S.TimeOfDay or 14, function(v)
    S.TimeOfDay = v
    Lighting.ClockTime = v
    saveConfig()
end)
utilsTab:AddToggle("Auto cinematic Time Cycle", S.TimeCycle, function(v)
    S.TimeCycle = v
    saveConfig()
end)
utilsTab:AddSlider("Time Cycle speed rate", 1, 10, S.TimeCycleSpeed, function(v)
    S.TimeCycleSpeed = v
    saveConfig()
end)
utilsTab:AddSlider("Field of View (Camera FOV)", 10, 120, S.CameraFOV, function(v)
    S.CameraFOV = v
    local camera = Workspace.CurrentCamera
    if camera then camera.FieldOfView = v end
    saveConfig()
end)

-- ──────────────────────────────────────────────────────────────
--  EXTERNAL SCRIPT LOADERS & HELPERS
-- ──────────────────────────────────────────────────────────────
local function runExternalScript(name, url, requiredPlaceId)
    if requiredPlaceId and game.PlaceId ~= requiredPlaceId then
        notify(string.format("Error: Must be in specific game place to run %s!", name), Color3.fromRGB(218, 38, 38))
        return
    end
    notify("Loading " .. name .. "...", Color3.fromRGB(218, 170, 42))
    task.spawn(function()
        local success, err = pcall(function()
            local code = game:HttpGet(url .. "?t=" .. tostring(tick()))
            if not code or code == "" then
                error("Empty response or failed request")
            end
            local func, loadErr = loadstring(code)
            if not func then
                error("Loadstring syntax error: " .. tostring(loadErr))
            end
            func()
        end)
        if success then
            notify(name .. " executed successfully!", Color3.fromRGB(50, 195, 75))
            logMessage("System", name .. " executed successfully.", Color3.fromRGB(50, 195, 75))
        else
            notify("Failed to execute " .. name .. ": " .. tostring(err), Color3.fromRGB(218, 38, 38))
            logMessage("System", "Failed to execute " .. name .. ": " .. tostring(err), Color3.fromRGB(218, 38, 38))
            warn("[Void Utility Hub] Error running " .. name .. ": " .. tostring(err))
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
--  TAB 8.6 ▸ SCRIPTS HUB
-- ──────────────────────────────────────────────────────────────
local scriptsTab = Win:AddTab("Scripts Hub")

scriptsTab:AddSection("EXTERNAL UTILITY SCRIPTS")

scriptsTab:AddButton("Load Rotector Anti-Cheat Bypass", "ROTECTOR", function()
    runExternalScript("Rotector", "https://raw.githubusercontent.com/VenezzaX/RobloxRotector/refs/heads/main/Rotector.lua")
end)

scriptsTab:AddButton("Load FE Emotes Script", "FE EMOTES", function()
    runExternalScript("FE Emotes", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/FeEmotes.lua")
end)

scriptsTab:AddButton("Load Gamepass Bypass", "GAMEPASS BYPASS", function()
    runExternalScript("Gamepass Bypass", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/gamepassbypass.lua")
end)

scriptsTab:AddButton("Load Coordinate UI", "COORDINATE UI", function()
    runExternalScript("Coordinate UI", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/CoordinateUI.lua")
end)

scriptsTab:AddButton("Load Dex Explorer (Injected)", "DEX", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end)
    notify("Dex Explorer loaded successfully!", Color3.fromRGB(50, 195, 75))
end)

scriptsTab:AddButton("Load Cobalt UI Wrapper", "COBALT", function()
    pcall(function()
        loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))()
    end)
    notify("Cobalt UI loaded successfully!", Color3.fromRGB(50, 195, 75))
end)

scriptsTab:AddButton("Load Infinite Yield Admin", "IY ADMIN", function()
    pcall(function()
        loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'),true))()
    end)
    notify("Infinite Yield loaded successfully!", Color3.fromRGB(50, 195, 75))
end)

scriptsTab:AddButton("Load SimpleSpy V3 (Remote Spy)", "SIMPLESPY", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
    end)
    notify("SimpleSpy V3 loaded successfully!", Color3.fromRGB(50, 195, 75))
end)

scriptsTab:AddButton("Load Hydroxide Remote Spy", "HYDROXIDE", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/PolyphonyDev/Hydroxide/main/init.lua"))()
    end)
    notify("Hydroxide Spy loaded successfully!", Color3.fromRGB(50, 195, 75))
end)

-- ──────────────────────────────────────────────────────────────
--  TAB 8.7 ▸ AUDITS & TESTS
-- ──────────────────────────────────────────────────────────────
local auditsTab = Win:AddTab("Audits & Tests")

auditsTab:AddSection("GENERAL EXECUTOR AUDITS")

auditsTab:AddButton("Run UNC Test Compliance Suite", "UNC TEST", function()
    runExternalScript("UNC Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/Unc.lua")
end)

auditsTab:AddButton("Run Executor Vulnerability Test", "VULN TEST", function()
    runExternalScript("Vulnerability Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/VulnerabilityTest.lua")
end)

auditsTab:AddButton("Run Workspace Instance Dumper", "DUMP WORKSPACE", function()
    runExternalScript("Workspace Dumper", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/WorkspaceDumper.lua")
end)

auditsTab:AddSection("PLACE-SPECIFIC AUDITS")

auditsTab:AddButton("Run SUNC Exploit Tester", "RUN SUNC", function()
    runExternalScript("SUNC Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/Sunc.lua", 90441122676618)
end)

auditsTab:AddButton("Run Myriad Executor Test Suite", "RUN MYRIAD", function()
    runExternalScript("Myriad Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/MyriadTest.lua", 79035306837882)
end)

auditsTab:AddSection("AUDIT GAME TELEPORTS")

auditsTab:AddButton("Teleport to SUNC Test Game", "SUNC GAME", function()
    teleportToPlace(90441122676618)
end)

auditsTab:AddButton("Teleport to Myriad Test Game", "MYRIAD GAME", function()
    teleportToPlace(79035306837882)
end)

-- ──────────────────────────────────────────────────────────────
--  TAB 8.5 ▸ CONSOLE
-- ──────────────────────────────────────────────────────────────
local consoleTab = Win:AddTab("Console")

consoleTab:AddSection("CONSOLE FILTER & CONTROLS")
local showInfo = true
local showWarn = true
local showError = true

local consoleLogs = {}
local consoleFeed = nil

local function rebuildConsoleFeed()
    if not consoleFeed then return end
    consoleFeed:Clear()
    for _, log in ipairs(consoleLogs) do
        local message = log.message
        local messageType = log.messageType
        local color = Color3.fromRGB(220, 220, 220)
        local prefix = ""
        local shouldShow = false
        
        if messageType == Enum.MessageType.MessageOutput or messageType == Enum.MessageType.MessageInfo then
            if messageType == Enum.MessageType.MessageInfo then
                color = Color3.fromRGB(80, 180, 240)
                prefix = "[INFO] "
            else
                color = Color3.fromRGB(220, 220, 220)
            end
            shouldShow = showInfo
        elseif messageType == Enum.MessageType.MessageWarning then
            color = Color3.fromRGB(240, 200, 50)
            prefix = "[WARN] "
            shouldShow = showWarn
        elseif messageType == Enum.MessageType.MessageError then
            color = Color3.fromRGB(240, 70, 70)
            prefix = "[ERROR] "
            shouldShow = showError
        end
        
        if shouldShow then
            consoleFeed:AddEntry(prefix .. message, color)
        end
    end
end

consoleTab:AddToggle("Show Prints & Info", true, function(v)
    showInfo = v
    rebuildConsoleFeed()
end)
consoleTab:AddToggle("Show Warnings", true, function(v)
    showWarn = v
    rebuildConsoleFeed()
end)
consoleTab:AddToggle("Show Errors", true, function(v)
    showError = v
    rebuildConsoleFeed()
end)

consoleTab:AddButton("Clear Console Log", "CLEAR", function()
    consoleLogs = {}
    if consoleFeed then
        consoleFeed:Clear()
    end
end)

consoleTab:AddSection("CONSOLE OUTPUT LOG")
consoleFeed = consoleTab:AddScrollFeed(320)

-- Populate initial history (limit to last 150 entries to avoid load lag)
local LogService = game:GetService("LogService")
pcall(function()
    local history = LogService:GetLogHistory()
    local startIdx = math.max(1, #history - 150)
    for i = startIdx, #history do
        local log = history[i]
        table.insert(consoleLogs, { message = log.message, messageType = log.messageType })
    end
    rebuildConsoleFeed()
end)

-- Real-time log listener
local logConnection = LogService.MessageOut:Connect(function(message, messageType)
    table.insert(consoleLogs, { message = message, messageType = messageType })
    if #consoleLogs > 500 then
        table.remove(consoleLogs, 1)
    end
    
    if not consoleFeed then return end
    
    local color = Color3.fromRGB(220, 220, 220)
    local shouldShow = false
    local prefix = ""
    
    if messageType == Enum.MessageType.MessageOutput or messageType == Enum.MessageType.MessageInfo then
        if messageType == Enum.MessageType.MessageInfo then
            color = Color3.fromRGB(80, 180, 240)
            prefix = "[INFO] "
        else
            color = Color3.fromRGB(220, 220, 220)
        end
        shouldShow = showInfo
    elseif messageType == Enum.MessageType.MessageWarning then
        color = Color3.fromRGB(240, 200, 50)
        prefix = "[WARN] "
        shouldShow = showWarn
    elseif messageType == Enum.MessageType.MessageError then
        color = Color3.fromRGB(240, 70, 70)
        prefix = "[ERROR] "
        shouldShow = showError
    end
    
    if shouldShow then
        consoleFeed:AddEntry(prefix .. message, color)
    end
end)
table.insert(S.Connections, logConnection)

-- ──────────────────────────────────────────────────────────────
--  TAB 9 ▸ SETTINGS
-- ──────────────────────────────────────────────────────────────
local settingsTab = Win:AddTab("Settings")

settingsTab:AddSection("GLOBAL INTERFACE CONTROL")
settingsTab:AddInfoRow("Hide/Show UI Frame Toggle", "[RightControl]")
autoReinjectToggle = settingsTab:AddToggle("Auto-Reinject on Teleport/Hop", S.AutoReinject, function(v)
    S.AutoReinject = v
    saveConfig()
    setupAutoReinject()
    pcall(function()
        Win:SetAutoReinject(v, function(enabled)
            S.AutoReinject = enabled
            saveConfig()
            setupAutoReinject()
            if autoReinjectToggle then
                autoReinjectToggle:Set(enabled)
            end
        end)
    end)
end)

settingsTab:AddSection("KEYBIND ASSIGNMENTS")
settingsTab:AddKeybind("Fly Mode Toggle Bind", S.FlyKey, function(k) S.FlyKey = k saveConfig() end)
settingsTab:AddKeybind("NoClip Wall Pass Bind", S.NoClipKey, function(k) S.NoClipKey = k saveConfig() end)
settingsTab:AddKeybind("Bunnyhop Toggle Bind", S.BHopKey, function(k) S.BHopKey = k saveConfig() end)
settingsTab:AddKeybind("Infinite Jump Toggle Bind", S.InfJumpKey, function(k) S.InfJumpKey = k saveConfig() end)
settingsTab:AddKeybind("Ghost State Toggle Bind", S.GhostKey, function(k) S.GhostKey = k saveConfig() end)
settingsTab:AddKeybind("Blink Teleport Key Bind", S.BlinkKey, function(k) S.BlinkKey = k saveConfig() end)

-- ──────────────────────────────────────────────────────────────
--  GHOST MODE IMPLEMENTATION HELPER
-- ──────────────────────────────────────────────────────────────
function enableGhostMode()
    local myChar = LP.Character
    local myHRP = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar.PrimaryPart)
    if not myHRP then return end
    
    S.GhostCFrame = myHRP.CFrame
    
    pcall(function()
        myChar.Archivable = true
        local clone = myChar:Clone()
        clone.Name = "GhostDummyMarker"
        for _, obj in ipairs(clone:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") or obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.Anchored = true
                obj.CanCollide = false
                obj.Transparency = 0.5
            end
        end
        clone.Parent = Workspace
        S.GhostDummy = clone
    end)
    
    for _, part in ipairs(myChar:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0.5
        end
    end
    
    S.Fly = true
    flyOn()
    S.NoClip = true
    notify("Ghost state active: body parked", Color3.fromRGB(218, 170, 42))
end

function disableGhostMode()
    local myChar = LP.Character
    local myHRP = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar.PrimaryPart)
    
    if S.GhostDummy then
        pcall(function() S.GhostDummy:Destroy() end)
        S.GhostDummy = nil
    end
    
    if myHRP and S.GhostCFrame then
        if not S.GhostTeleportToEnd then
            myHRP.CFrame = S.GhostCFrame
            notify("Ghost returned to body origin", Color3.fromRGB(50, 195, 75))
        else
            notify("Teleported body to ghost position!", Color3.fromRGB(50, 195, 75))
        end
        S.GhostCFrame = nil
    end
    
    if myChar then
        for _, part in ipairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0
            end
        end
    end
    
    S.Fly = false
    flyOff()
    S.NoClip = false
end

-- ──────────────────────────────────────────────────────────────
--  FLYING CORE UTILITIES
-- ──────────────────────────────────────────────────────────────
local function updateFlyVelocity()
    local hrp = getHRP()
    if not hrp then return end
    local bv = hrp:FindFirstChild("VoidFlyBV")
    local bg = hrp:FindFirstChild("VoidFlyBG")
    if not bv or not bg then return end
    
    local dir = Vector3.zero
    local cf = Camera.CFrame
    local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
    if fwd.Magnitude > 0 then fwd = fwd.Unit end
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + fwd end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - fwd end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
    
    bv.Velocity = (dir.Magnitude > 0) and (dir.Unit * S.FlySpeed) or Vector3.zero
    bg.CFrame = cf
end

function flyOn()
    local char = getChar()
    local hrp = getHRP()
    local hum = getHum()
    if not char or not hrp or not hum then return end
    
    hum.PlatformStand = true
    
    pcall(function()
        if hrp:FindFirstChild("VoidFlyBV") then hrp.VoidFlyBV:Destroy() end
        if hrp:FindFirstChild("VoidFlyBG") then hrp.VoidFlyBG:Destroy() end
    end)
    
    local bv = Instance.new("BodyVelocity")
    bv.Name = "VoidFlyBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    
    local bg = Instance.new("BodyGyro")
    bg.Name = "VoidFlyBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.D = 100
    bg.Parent = hrp
end

function flyOff()
    local char = getChar()
    local hrp = getHRP()
    local hum = getHum()
    if hum then hum.PlatformStand = false end
    if hrp then
        pcall(function()
            if hrp:FindFirstChild("VoidFlyBV") then hrp.VoidFlyBV:Destroy() end
            if hrp:FindFirstChild("VoidFlyBG") then hrp.VoidFlyBG:Destroy() end
        end)
    end
end

-- ──────────────────────────────────────────────────────────────
--  VISIBILITY RAYCAST
-- ──────────────────────────────────────────────────────────────
local function isPartVisible(part, char)
    if not part then return false end
    local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera") or Camera
    local origin = Camera.CFrame.Position
    local destination = part.Position
    local direction = destination - origin
    if direction.Magnitude == 0 then return true end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character, char}
    params.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction, params)
    return result == nil
end

local function getAimbotTargetPart(char)
    if S.AimbotPart == "Head" then
        return char:FindFirstChild("Head")
    elseif S.AimbotPart == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif S.AimbotPart == "Random" then
        local parts = {}
        local head = char:FindFirstChild("Head")
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if head then table.insert(parts, head) end
        if torso then table.insert(parts, torso) end
        if #parts > 0 then
            return parts[math.random(1, #parts)]
        end
    end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function getAimbotTarget()
    local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera") or Camera
    local bestTarget = nil
    local closestDist = S.AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if S.AimbotTeamCheck and p.Team == LP.Team then continue end
        
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then continue end
        
        local part = getAimbotTargetPart(char)
        if not part then continue end
        
        if S.AimbotVisibility and not isPartVisible(part, char) then continue end
        
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        
        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist < closestDist then
            closestDist = dist
            bestTarget = part
        end
    end
    return bestTarget
end

-- ──────────────────────────────────────────────────────────────
--  ESP SCREEN BOUNDING BOX CALCULATION
-- ──────────────────────────────────────────────────────────────
local function getBoundingBox(char)
    local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera") or Camera
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
    if not hrp then return nil end
    
    local size = Vector3.new(4.2, 5.5, 2.5)
    local cf = hrp.CFrame
    
    local corners = {
        cf * Vector3.new(-size.X/2,  size.Y/2,  size.Z/2),
        cf * Vector3.new( size.X/2,  size.Y/2,  size.Z/2),
        cf * Vector3.new(-size.X/2, -size.Y/2,  size.Z/2),
        cf * Vector3.new( size.X/2, -size.Y/2,  size.Z/2),
        cf * Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
        cf * Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
        cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
        cf * Vector3.new( size.X/2, -size.Y/2, -size.Z/2)
    }
    
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyVisible = false
    
    for _, corner in ipairs(corners) do
        local sp, onScreen = Camera:WorldToViewportPoint(corner)
        if sp.Z > 0 then
            anyVisible = true
            if sp.X < minX then minX = sp.X end
            if sp.X > maxX then maxX = sp.X end
            if sp.Y < minY then minY = sp.Y end
            if sp.Y > maxY then maxY = sp.Y end
        end
    end
    
    if not anyVisible then return nil end
    return { Vector2.new(minX, minY), Vector2.new(maxX, maxY) }
end

-- ──────────────────────────────────────────────────────────────
--  RUNTIME TICK LOOPS & BINDINGS
-- ──────────────────────────────────────────────────────────────

-- ── 1. RenderStepped Aimbot, FOV, and ESP Update ───────────────
table.insert(S.Connections, RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera") or Camera
    -- fog clear safety
    if S.ClearVision then
        Lighting.FogEnd = 100000
    end

    -- fov circle
    fovCircle.Visible = S.AimbotActive and S.AimbotShowFOV
    if fovCircle.Visible then
        local vp = Camera.ViewportSize
        fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        fovCircle.Radius = S.AimbotFOV
    end
    
    -- target look
    if S.AimbotActive and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local targetPart = getAimbotTarget()
        if targetPart then
            local goalCF = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            local sm = math.max(S.AimbotSmooth, 1)
            Camera.CFrame = Camera.CFrame:Lerp(goalCF, 1 / sm)
        end
    end
    
    -- esp updates
    local espColorMapping = {
        ["Red"] = Color3.fromRGB(220, 40, 40),
        ["Green"] = Color3.fromRGB(55, 200, 80),
        ["Blue"] = Color3.fromRGB(40, 120, 220),
        ["Yellow"] = Color3.fromRGB(220, 175, 45),
        ["Cyan"] = Color3.fromRGB(45, 200, 220),
        ["White"] = Color3.fromRGB(255, 255, 255)
    }
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        local valid = char and hrp and hum and hum.Health > 0
        if valid and (S.ESPBoxes or S.ESPTracers or S.ESPNames or S.ESPHealth or S.ESPDistances) then
            if S.ESPTeamCheck and p.Team == LP.Team then
                destroyESP(p)
                continue
            end
            
            local box = getBoundingBox(char)
            local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if box and sp.Z > 0 then
                local topLeft = box[1]
                local bottomRight = box[2]
                local width = bottomRight.X - topLeft.X
                local height = bottomRight.Y - topLeft.Y
                
                local teamCol = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(218, 38, 38)
                local espDrawCol = espColorMapping[S.ESPColor] or teamCol
                
                if not S.ESPPool[p] then
                    S.ESPPool[p] = {
                        boxOutline = Drawing.new("Square"),
                        boxFill = Drawing.new("Square"),
                        tracer = Drawing.new("Line"),
                        nameTag = Drawing.new("Text"),
                        healthText = Drawing.new("Text"),
                        distText = Drawing.new("Text")
                    }
                end
                local pool = S.ESPPool[p]
                
                local outline = pool.boxOutline
                outline.Visible = S.ESPBoxes
                outline.Position = topLeft
                outline.Size = Vector2.new(width, height)
                outline.Color = espDrawCol
                outline.Thickness = 1.5
                outline.Transparency = 1
                outline.Filled = false
                
                local fill = pool.boxFill
                fill.Visible = S.ESPBoxes
                fill.Position = topLeft
                fill.Size = Vector2.new(width, height)
                fill.Color = espDrawCol
                fill.Transparency = 1 - S.ESPTransparency
                fill.Filled = true
                
                local tracer = pool.tracer
                tracer.Visible = S.ESPTracers
                local vp = Camera.ViewportSize
                local originY = vp.Y
                if S.TracerOrigin == "Center" then
                    originY = vp.Y / 2
                elseif S.TracerOrigin == "Top" then
                    originY = 0
                end
                tracer.From = Vector2.new(vp.X / 2, originY)
                tracer.To = Vector2.new(sp.X, sp.Y)
                tracer.Color = espDrawCol
                tracer.Thickness = 1.5
                tracer.Transparency = 0.8
                
                local dist = math.round((hrp.Position - Camera.CFrame.Position).Magnitude)
                
                local nameTag = pool.nameTag
                nameTag.Visible = S.ESPNames
                nameTag.Text = p.DisplayName
                nameTag.Size = 13
                nameTag.Center = true
                nameTag.Outline = true
                nameTag.Color = Color3.new(1, 1, 1)
                nameTag.Position = Vector2.new(topLeft.X + width / 2, topLeft.Y - 15)
                
                local healthText = pool.healthText
                healthText.Visible = S.ESPHealth
                healthText.Text = string.format("%d HP", math.floor(hum.Health))
                healthText.Size = 11
                healthText.Center = true
                healthText.Outline = true
                local hpPct = hum.Health / math.max(hum.MaxHealth, 1)
                healthText.Color = Color3.fromRGB(255 * (1 - hpPct), 255 * hpPct, 0)
                healthText.Position = Vector2.new(topLeft.X + width / 2, bottomRight.Y + 2)
                
                local distText = pool.distText
                distText.Visible = S.ESPDistances
                distText.Text = string.format("[%d studs]", dist)
                distText.Size = 10
                distText.Center = true
                distText.Outline = true
                distText.Color = Color3.fromRGB(200, 200, 200)
                distText.Position = Vector2.new(topLeft.X + width / 2, bottomRight.Y + (S.ESPHealth and 15 or 2))
            else
                destroyESP(p)
            end
        else
            destroyESP(p)
        end
    end
end))

-- ── 2. Heartbeat Loops (Movements, Anti-Void, Follow, Stats) ────
local fpsCount = 0
local lastFpsTick = tick()
local lastPingTick = tick()
local pingVal = 0

table.insert(S.Connections, RunService.Heartbeat:Connect(function(dt)
    -- 1. FPS & Ping & HUD Label
    pcall(function()
        fpsCount = fpsCount + 1
        local curT = tick()
        local updated = false
        if curT - lastFpsTick >= 1 then
            rowHomeFPS:SetValue(tostring(fpsCount))
            lastFpsTick = curT
            updated = true
        end
        
        if curT - lastPingTick >= 2 then
            lastPingTick = curT
            task.spawn(function()
                local t0 = tick()
                RunService.Heartbeat:Wait()
                pingVal = math.max(1, math.floor((tick() - t0) * 1000))
                pcall(function()
                    rowHomePing:SetValue(pingVal .. "ms")
                    rowPing:SetValue(pingVal .. "ms")
                    rowPlayers:SetValue(string.format("%d / %d", #Players:GetPlayers(), Players.MaxPlayers))
                    rowAge:SetValue(string.format("%.2f hours", Workspace.DistributedGameTime / 3600))
                    Win.HUDLabel.Text = string.format("FPS: %d  |  PING: %dms", fpsCount, pingVal)
                end)
            end)
        elseif updated then
            Win.HUDLabel.Text = string.format("FPS: %d  |  PING: %dms", fpsCount, pingVal)
        end
        if updated then
            fpsCount = 0
        end
    end)
    
    local myChar = getChar()
    local myHRP = getHRP()
    local myHum = getHum()
    
    -- Anti-Anchor
    if S.AntiAnchor and myChar then
        pcall(function()
            for _, part in ipairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") and part.Anchored then
                    part.Anchored = false
                end
            end
        end)
    end
    
    -- Anti-Sit
    if S.AntiSit and myHum and myHum.Sit then
        pcall(function()
            myHum.Sit = false
        end)
    end
    
    -- 2. Fly
    if S.Fly then
        pcall(updateFlyVelocity)
    end
    
    -- 3. WalkSpeed & JumpPower
    pcall(function()
        if myHum then
            local isSprinting = S.SprintEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            if isSprinting then
                myHum.WalkSpeed = S.SprintSpeed
            elseif S.ForceWalkSpeed then
                myHum.WalkSpeed = S.WalkSpeed
            end
            if S.ForceJumpPower then
                myHum.UseJumpPower = true
                myHum.JumpPower = S.JumpPower
            end
        end
    end)
    
    -- 4. BHop
    if S.BHop and myHRP and myHum then
        pcall(function()
            if myHum.MoveDirection.Magnitude > 0 then
                if myHum.FloorMaterial ~= Enum.Material.Air then
                    myHum.Jump = true
                    local wishDir = myHum.MoveDirection.Unit
                    local currentVel = myHRP.Velocity
                    local horizontalVel = Vector3.new(currentVel.X, 0, currentVel.Z)
                    
                    local speedBoost = wishDir * 4.5
                    local newHorizontal = horizontalVel + speedBoost
                    if newHorizontal.Magnitude > 120 then
                        newHorizontal = newHorizontal.Unit * 120
                    end
                    myHRP.Velocity = Vector3.new(newHorizontal.X, currentVel.Y, newHorizontal.Z)
                else
                    -- Air strafe control
                    local wishDir = myHum.MoveDirection.Unit
                    local currentVel = myHRP.Velocity
                    local horizontalVel = Vector3.new(currentVel.X, 0, currentVel.Z)
                    local speed = horizontalVel.Magnitude
                    if speed > 0 then
                        local newHorizontal = (horizontalVel + wishDir * 1.5).Unit * speed
                        myHRP.Velocity = Vector3.new(newHorizontal.X, currentVel.Y, newHorizontal.Z)
                    end
                end
            end
        end)
    end
    
    -- 5. AirWalk Platform
    pcall(function()
        if S.AirWalk then
            if myHum and myHRP then
                if myHum.FloorMaterial == Enum.Material.Air then
                    if not S.AirWalkPlat then
                        local plat = Instance.new("Part")
                        plat.Name = "VoidAirWalkPlat"
                        plat.Size = Vector3.new(6, 0.2, 6)
                        plat.Anchored = true
                        plat.CanCollide = true
                        plat.Transparency = 1
                        plat.Parent = Workspace
                        S.AirWalkPlat = plat
                    end
                    S.AirWalkPlat.CFrame = CFrame.new(myHRP.Position.X, myHRP.Position.Y - 3.1, myHRP.Position.Z)
                else
                    if S.AirWalkPlat then S.AirWalkPlat:Destroy(); S.AirWalkPlat = nil end
                end
            end
        else
            if S.AirWalkPlat then S.AirWalkPlat:Destroy(); S.AirWalkPlat = nil end
        end
    end)
    
    -- 6. Water Walk
    pcall(function()
        if S.WaterWalk and myHRP and myChar then
            if not S.WaterRaycastParams then
                S.WaterRaycastParams = RaycastParams.new()
                S.WaterRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
                S.WaterRaycastParams.IgnoreWater = false
            end
            S.WaterRaycastParams.FilterDescendantsInstances = {myChar, S.WaterPlat}
            local raycastResult = Workspace:Raycast(myHRP.Position + Vector3.new(0, 2, 0), Vector3.new(0, -10, 0), S.WaterRaycastParams)
            if raycastResult and raycastResult.Material == Enum.Material.Water then
                if not S.WaterPlat then
                    local plat = Instance.new("Part")
                    plat.Name = "VoidWaterPlat"
                    plat.Size = Vector3.new(100, 1, 100)
                    plat.Anchored = true
                    plat.Transparency = 1
                    plat.CanCollide = true
                    plat.Parent = Workspace
                    S.WaterPlat = plat
                end
                S.WaterPlat.CFrame = CFrame.new(myHRP.Position.X, raycastResult.Position.Y - 0.5, myHRP.Position.Z)
            else
                if S.WaterPlat then S.WaterPlat:Destroy(); S.WaterPlat = nil end
            end
        else
            if S.WaterPlat then S.WaterPlat:Destroy(); S.WaterPlat = nil end
        end
    end)
    
    -- 7. Anti-Void
    pcall(function()
        if S.AntiVoid and myHRP then
            if myHRP.Position.Y > S.AntiVoidY then
                S.LastSafePosition = myHRP.CFrame
            else
                if not S.LastAntiVoidTime or (tick() - S.LastAntiVoidTime) > 1.5 then
                    S.LastAntiVoidTime = tick()
                    myHRP.CFrame = S.LastSafePosition
                    myHRP.AssemblyLinearVelocity = Vector3.zero
                    notify("Anti-Void pulled you back!", Color3.fromRGB(218, 170, 42))
                end
            end
        end
    end)
    
    -- 8. Auto Follow
    pcall(function()
        if S.FollowActive and S.FollowTarget then
            local tgtHRP = S.FollowTarget.Character and (S.FollowTarget.Character:FindFirstChild("HumanoidRootPart") or S.FollowTarget.Character:FindFirstChild("Torso") or S.FollowTarget.Character.PrimaryPart)
            if tgtHRP then teleportToHRP(tgtHRP) end
        end
    end)
    
    -- 9. Hitbox expansions
    pcall(function()
        if S.HitboxExpanded then
            for _, p in ipairs(Players:GetPlayers()) do applyHitbox(p) end
        end
    end)
    
    -- 10. Gravity
    pcall(function()
        if S.GravityEnabled then Workspace.Gravity = S.CustomGravity end
    end)
    
    -- 11. Time of Day
    pcall(function()
        if S.TimeCycle then
    S.TimeOfDay = ((S.TimeOfDay or Lighting.ClockTime) + dt * S.TimeCycleSpeed * 0.1) % 24
    Lighting.ClockTime = S.TimeOfDay
else
    Lighting.ClockTime = S.TimeOfDay or Lighting.ClockTime
end
    end)
    
    -- 12. Tornado Spin
    pcall(function()
        if S.Spin and myHRP then myHRP.CFrame = myHRP.CFrame * CFrame.Angles(0, math.rad(S.SpinSpeed), 0) end
    end)
    
    -- 13. Auto Interact Prompts
    pcall(function()
        if S.AutoInteract and myHRP then
            for _, prompt in ipairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
                    local dist = (myHRP.Position - prompt.Parent.Position).Magnitude
                    if dist <= S.AutoInteractRadius then fireproximityprompt(prompt) end
                end
            end
        end
    end)
    
    -- 14. Tool Magnet
    pcall(function()
        if S.ToolMagnet and myHRP then
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("Tool") and item:FindFirstChild("Handle") then
                    item.Handle.CFrame = myHRP.CFrame
                end
            end
        end
    end)
    
    -- 15. Auto Jump
    pcall(function()
        if S.AutoJump and myHum and myHRP and myHum.FloorMaterial ~= Enum.Material.Air then
            local edgeRay = Ray.new(myHRP.Position + (myHRP.CFrame.LookVector * 2), Vector3.new(0, -5, 0))
            local hit = Workspace:FindPartOnRay(edgeRay, myChar)
            if not hit then myHum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    
    -- 16. Kill Aura
    pcall(function()
        if S.KillAura and myChar and myHRP then
            local tool = myChar:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Handle") then
                for _, p in ipairs(Players:GetPlayers()) do
                    local root = p.Character and (p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart)
                    if p ~= LP and p.Character and root and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                        if (root.Position - myHRP.Position).Magnitude <= S.KillAuraRange then
                            firetouchinterest(tool.Handle, root, 0)
                            firetouchinterest(tool.Handle, root, 1)
                        end
                    end
                end
            end
        end
    end)
    
    -- 17. Auto Clicker
    pcall(function()
        if S.AutoClicker and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            VirtualUser:ClickButton1(Vector2.new())
        end
    end)
    
    -- 18. Spectate info updates
    pcall(function()
        if not isFreecam and Camera.CameraType == Enum.CameraType.Watch then
            local subj = Camera.CameraSubject
            if not subj or typeof(subj) ~= "Instance" or not subj.Parent then
                Camera.CameraType = Enum.CameraType.Custom
                if myHum then Camera.CameraSubject = myHum end
                specNameRow:SetValue("--")
                specHpRow:SetValue("--")
                specTeamRow:SetValue("--")
            else
                local targetHum = subj:IsA("Humanoid") and subj
                local targetPlayer = targetHum and Players:GetPlayerFromCharacter(targetHum.Parent)
                if targetPlayer and targetHum then
                    local teamCol = targetPlayer.Team and targetPlayer.Team.TeamColor.Color or Color3.fromRGB(200, 200, 200)
                    specNameRow:SetValue(targetPlayer.DisplayName)
                    specNameRow:SetColor(teamCol)
                    specHpRow:SetValue(string.format("%d HP / %d", math.floor(targetHum.Health), math.floor(targetHum.MaxHealth)))
                    specTeamRow:SetValue(targetPlayer.Team and targetPlayer.Team.Name or "Neutral")
                end
            end
        end
    end)
end))

-- ── 3. Collision Pass loop (Noclip) ───────────────────────────
table.insert(S.Connections, RunService.Stepped:Connect(function()
    if S.NoClip then
        local char = getChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end
end))

-- ── 4. User Inputs (Keybinds) ─────────────────────────────────
table.insert(S.Connections, UserInputService.InputBegan:Connect(function(inp, gpe)
    -- Toggle UI visibility key
    if inp.KeyCode == Enum.KeyCode.RightControl then
        toggleUIVisibility()
        return
    end

    if gpe then return end
    
    -- Mouse click checks
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if S.ClickDelete and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
            local target = Mouse.Target
            if target and not target.Parent:FindFirstChildOfClass("Humanoid") then
                target:Destroy()
            end
        elseif S.ClickTeleport and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local hit = Mouse.Hit
            local hrp = getHRP()
            local hum = getHum()
            if hit and hrp then
                if hum then hum.Sit = false end
                hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) * hrp.CFrame.Rotation
                hrp.AssemblyLinearVelocity = Vector3.zero
                notify("Teleported to cursor!", Color3.fromRGB(50, 195, 75))
            end
        end
    end
    
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = inp.KeyCode
    
    if k == Enum.KeyCode.LeftShift then
        if S.SprintEnabled then
            local hum = getHum()
            if hum then
                hum.WalkSpeed = S.SprintSpeed
            end
        end
    elseif k == S.FlyKey then
        S.Fly = not S.Fly
        if S.Fly then flyOn() else flyOff() end
        notify("Fly Mode " .. (S.Fly and "ON" or "OFF"), Color3.fromRGB(218, 170, 42))
    elseif k == S.NoClipKey then
        S.NoClip = not S.NoClip
        notify("NoClip " .. (S.NoClip and "ON" or "OFF"), Color3.fromRGB(218, 170, 42))
    elseif k == S.BHopKey then
        S.BHop = not S.BHop
        notify("Bunnyhop " .. (S.BHop and "ON" or "OFF"), Color3.fromRGB(218, 170, 42))
    elseif k == S.InfJumpKey then
        S.InfJump = not S.InfJump
        notify("Infinite Jump " .. (S.InfJump and "ON" or "OFF"), Color3.fromRGB(218, 170, 42))
    elseif k == S.GhostKey then
        S.GhostMode = not S.GhostMode
        if S.GhostMode then enableGhostMode() else disableGhostMode() end
    elseif k == S.BlinkKey then
        local hrp = getHRP()
        local hum = getHum()
        if hrp and hum then
            local dir
            if S.BlinkDirection == "Camera Look" then
                dir = Camera.CFrame.LookVector
            else
                dir = hum.MoveDirection.Magnitude > 0 and hum.MoveDirection or hrp.CFrame.LookVector
            end
            
            local targetPos = hrp.Position + dir.Unit * S.BlinkDistance
            if not S.Fly then
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {LP.Character}
                
                local rayResult = Workspace:Raycast(targetPos + Vector3.new(0, 2, 0), Vector3.new(0, -15, 0), raycastParams)
                if rayResult then
                    targetPos = Vector3.new(targetPos.X, rayResult.Position.Y + 3.0, targetPos.Z)
                end
            end
            
            hrp.CFrame = CFrame.new(targetPos) * hrp.CFrame.Rotation
            notify("Blinked forward safely!", Color3.fromRGB(50, 195, 75))
        end
    end
end))

table.insert(S.Connections, UserInputService.InputEnded:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.LeftShift then
        local hum = getHum()
        if hum then
            hum.WalkSpeed = S.WalkSpeed
        end
    end
end))

-- ── 5. Jump Requests (InfJump, AirWalk platform removal) ──────
table.insert(S.Connections, UserInputService.JumpRequest:Connect(function()
    if S.InfJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
    if S.AirWalk and S.AirWalkPlat then
        pcall(function() S.AirWalkPlat:Destroy() end)
        S.AirWalkPlat = nil
    end
end))

-- ── 6. Character Respawn Handler (Re-apply stats) ─────────────
local function onCharSpawn(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.UseJumpPower = true
        hum.WalkSpeed = S.WalkSpeed
        hum.JumpPower = S.JumpPower
    end
    
    if S.Fly then
        task.wait(0.1)
        flyOn()
    end
    
    if S.Float then
        task.wait(0.1)
        toggleFloat(true)
    end
    
    -- BHop is managed frame-by-frame inside the heartbeat loop
    
    if S.TallAnim then
        applyTallAnimations(char)
    end
    
    if S.GodMode then
        applyGodMode(char)
    end
    
    if S.OverheadInfo then
        task.wait(0.3)
        refreshOverheads()
    end

    if S.ForceShiftLock then
        pcall(function()
            LP.DevEnableMouseLock = true
        end)
    end
end

if LP.Character then onCharSpawn(LP.Character) end
table.insert(S.Connections, LP.CharacterAdded:Connect(onCharSpawn))

table.insert(S.Connections, LP.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

-- UI Visibility Control
local function findWindowFrame()
    local targets = {
        "VoidLib_xzyp Void Utility Hub",
        "VLVoid Utility Hub",
        "VoidLibVoid Utility Hub",
        "Void Utility Hub"
    }

    local containers = {}
    if gethui then pcall(function() table.insert(containers, gethui()) end) end
    if CoreGui then table.insert(containers, CoreGui) end
    if LP and LP:FindFirstChild("PlayerGui") then table.insert(containers, LP.PlayerGui) end

    for _, container in ipairs(containers) do
        for _, name in ipairs(targets) do
            local gui = container:FindFirstChild(name)
            if gui then
                local win = gui:FindFirstChild("Win") or gui:FindFirstChild("VoidWindow", true)
                if win then
                    return win
                end
            end
        end
    end

    -- Fallback: dynamically find the window frame in any screen GUI containing "VoidLib" or "Void"
    for _, container in ipairs(containers) do
        local success, children = pcall(function() return container:GetChildren() end)
        if success and children then
            for _, child in ipairs(children) do
                if child:IsA("ScreenGui") and (child.Name:find("VoidLib") or child.Name:find("Void")) then
                    local win = child:FindFirstChild("VoidWindow", true) or child:FindFirstChild("Win", true)
                    if win then
                        return win
                    end
                end
            end
        end
    end

    return nil
end

function toggleUIVisibility()
    if not windowFrame or not windowFrame.Parent then
        windowFrame = findWindowFrame()
    end
    if windowFrame then
        uiVisible = not windowFrame.Visible
        windowFrame.Visible = uiVisible
    end
end

-- ──────────────────────────────────────────────────────────────
--  READY STARTUP NOTIFICATION
-- ──────────────────────────────────────────────────────────────
logMessage("System", "Void Utility Hub loaded successfully. Keybind: RCtrl to toggle UI", Color3.fromRGB(50, 195, 75))
notify("Void Utility Hub loaded! [RCtrl] to toggle UI", Color3.fromRGB(50, 195, 75))

print("[Void Utility Hub] Loaded successfully!")
