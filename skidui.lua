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
local TweenService     = game:GetService("TweenService")

local playerCards = {}
local consoleLogs = {}
local consoleLogsMap = {}
local currentSpectateTarget = nil
local spectateIndex = 1
local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse  = LP:GetMouse()
local uiVisible = true

local visRaycastParams = RaycastParams.new()
visRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
visRaycastParams.IgnoreWater = true
local windowFrame = nil
local notify = nil
local autoReinjectToggle = nil
local isFreecam = false
local freecamConnection = nil
local freecamInputConn = nil
local freecamInputBeganConn = nil
local freecamInputEndedConn = nil
local freecamBasePos = nil
local originalAmbient = Lighting.Ambient
local originalOutdoor = Lighting.OutdoorAmbient

local gameDefaultSpeed = 16
local gameDefaultJumpPower = 50
local gameDefaultUseJumpPower = true

pcall(function()
    local char = LP.Character
    local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 2))
    if hum then
        gameDefaultSpeed = hum.WalkSpeed
        gameDefaultJumpPower = hum.JumpPower
        gameDefaultUseJumpPower = hum.UseJumpPower
    end
end)

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
    FlingAllActive = false,
    
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
    OriginalLightingEffects = {},
    OriginalFogEnd = nil,
    
    -- Connection tracking
    Connections = {},
    ChatConnections = {},
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

    -- Theme and HUD Settings
    ThemeColor = "Purple",
    HUDWatermark = true,
    HUDCoords = true,
    HUDArrayList = true,
    MacroKey = Enum.KeyCode.H,
    MacroText = "Meteor Client on Top!",
    UIToggleKey = Enum.KeyCode.RightControl,

    currentOptionsModule = ""
}

-- Statistics and Dynamic row wrapper variables
local serverStatsLabels = { region = nil, ping = nil, players = nil, age = nil }
local rowRegion = { SetValue = function(self, val) if serverStatsLabels.region then serverStatsLabels.region.Text = tostring(val) end end }
local rowPing = { SetValue = function(self, val) if serverStatsLabels.ping then serverStatsLabels.ping.Text = tostring(val) end end }
local rowPlayers = { SetValue = function(self, val) if serverStatsLabels.players then serverStatsLabels.players.Text = tostring(val) end end }
local rowAge = { SetValue = function(self, val) if serverStatsLabels.age then serverStatsLabels.age.Text = tostring(val) end end }

local spectateStatsLabels = { name = nil, hp = nil, team = nil }
local specNameRow = { 
    SetValue = function(self, val) if spectateStatsLabels.name then spectateStatsLabels.name.Text = tostring(val) end end, 
    SetColor = function(self, col) if spectateStatsLabels.name then spectateStatsLabels.name.TextColor3 = col end end 
}
local specHpRow = { SetValue = function(self, val) if spectateStatsLabels.hp then spectateStatsLabels.hp.Text = tostring(val) end end }
local specTeamRow = { SetValue = function(self, val) if spectateStatsLabels.team then spectateStatsLabels.team.Text = tostring(val) end end }

local rowHomeFPS = { SetValue = function() end }
local rowHomePing = { SetValue = function() end }
local rowHomeRegion = { SetValue = function() end }

local activeChatFeed = nil
local rowHomeChatFeed = {
    AddEntry = function(self, text, color)
        if activeChatFeed then activeChatFeed:AddEntry(text, color) end
    end
}
local homeChatFeed = rowHomeChatFeed
local socialChatFeed = rowHomeChatFeed

local activeConsoleFeed = nil
local rowConsoleFeed = {
    Clear = function(self) if activeConsoleFeed then activeConsoleFeed:Clear() end end,
    AddEntry = function(self, text, color)
        if activeConsoleFeed then activeConsoleFeed:AddEntry(text, color) end
    end
}
local consoleFeed = rowConsoleFeed

-- ──────────────────────────────────────────────────────────────
--  CLEANUP ROUTINE (Prevents memory leaks on re-run)
-- ──────────────────────────────────────────────────────────────
local function destroyESP(p)
    local pool = S.ESPPool[p]
    if pool then
        pcall(function() pool.boxOutline.Visible = false; pool.boxOutline:Remove() end)
        pcall(function() pool.boxFill.Visible = false; pool.boxFill:Remove() end)
        pcall(function() pool.tracer.Visible = false; pool.tracer:Remove() end)
        pcall(function() pool.nameTag.Visible = false; pool.nameTag:Remove() end)
        pcall(function() pool.healthText.Visible = false; pool.healthText:Remove() end)
        pcall(function() pool.distText.Visible = false; pool.distText:Remove() end)
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
    pcall(function()
        local cg = game:GetService("CoreGui")
        local old = cg:FindFirstChild("MeteorRobloxGUI")
        if old then old:Destroy() end
        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local oldPg = pg:FindFirstChild("MeteorRobloxGUI")
            if oldPg then oldPg:Destroy() end
        end
    end)
    for _, c in ipairs(S.Connections) do
        pcall(function() c:Disconnect() end)
    end
    S.Connections = {}
    
    if S.GodModeConn then pcall(function() S.GodModeConn:Disconnect() end) S.GodModeConn = nil end
    if S.TallRunningConn then pcall(function() S.TallRunningConn:Disconnect() end) S.TallRunningConn = nil end
    
    for p, conn in pairs(S.ChatConnections) do
        pcall(function() conn:Disconnect() end)
    end
    S.ChatConnections = {}
    
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
        if S.OriginalFogEnd == nil then
            S.OriginalFogEnd = Lighting.FogEnd
        end
        Lighting.FogEnd = 100000
        for _, descendant in ipairs(Lighting:GetDescendants()) do
            if descendant:IsA("BlurEffect") or descendant:IsA("DepthOfFieldEffect") or descendant:IsA("Atmosphere") or descendant:IsA("ColorCorrectionEffect") then
                if S.OriginalLightingEffects[descendant] == nil then
                    S.OriginalLightingEffects[descendant] = descendant.Enabled
                end
                descendant.Enabled = false
            end
        end
    else
        if S.OriginalFogEnd ~= nil then
            Lighting.FogEnd = S.OriginalFogEnd
            S.OriginalFogEnd = nil
        end
        for descendant, originalEnabled in pairs(S.OriginalLightingEffects) do
            pcall(function()
                if descendant and descendant.Parent then
                    descendant.Enabled = originalEnabled
                end
            end)
        end
        S.OriginalLightingEffects = {}
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
        local conn = game:GetService("GuiService").ErrorMessageChanged:Connect(function()
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
        table.insert(S.Connections, conn)
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
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VenezzaX/VoidUI/refs/heads/main/skidui.lua", true))()
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

-- Spectate & Follow target logic
local function spectatePlayer(target)
    currentSpectateTarget = target
    if target and target.Character then
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraType = Enum.CameraType.Watch
            Camera.CameraSubject = hum
            return
        end
    end
    -- Fallback to self
    Camera.CameraType = Enum.CameraType.Custom
    local myChar = LP.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        Camera.CameraSubject = myHum
    end
    currentSpectateTarget = nil
end

local function resetCameraToSelf()
    spectatePlayer(nil)
end

-- Freecam logic
local function enableFreecam()
    if isFreecam then return end
    isFreecam = true
    
    local char = LP.Character
    local hrp = getHRP()
    if hrp then
        hrp.Anchored = true
    end
    
    Camera.CameraType = Enum.CameraType.Scriptable
    freecamBasePos = Camera.CFrame
    
    local moveVector = Vector3.zero
    
    freecamInputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local key = input.KeyCode
        if key == Enum.KeyCode.W then
            moveVector = moveVector + Vector3.new(0, 0, -1)
        elseif key == Enum.KeyCode.S then
            moveVector = moveVector + Vector3.new(0, 0, 1)
        elseif key == Enum.KeyCode.A then
            moveVector = moveVector + Vector3.new(-1, 0, 0)
        elseif key == Enum.KeyCode.D then
            moveVector = moveVector + Vector3.new(1, 0, 0)
        elseif key == Enum.KeyCode.Space then
            moveVector = moveVector + Vector3.new(0, 1, 0)
        elseif key == Enum.KeyCode.LeftShift then
            moveVector = moveVector + Vector3.new(0, -1, 0)
        end
    end)
    
    freecamInputEndedConn = UserInputService.InputEnded:Connect(function(input, gpe)
        local key = input.KeyCode
        if key == Enum.KeyCode.W then
            moveVector = moveVector - Vector3.new(0, 0, -1)
        elseif key == Enum.KeyCode.S then
            moveVector = moveVector - Vector3.new(0, 0, 1)
        elseif key == Enum.KeyCode.A then
            moveVector = moveVector - Vector3.new(-1, 0, 0)
        elseif key == Enum.KeyCode.D then
            moveVector = moveVector - Vector3.new(1, 0, 0)
        elseif key == Enum.KeyCode.Space then
            moveVector = moveVector - Vector3.new(0, 1, 0)
        elseif key == Enum.KeyCode.LeftShift then
            moveVector = moveVector - Vector3.new(0, -1, 0)
        end
    end)
    
    freecamConnection = RunService.RenderStepped:Connect(function(dt)
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
        
        local cameraRot = Camera.CFrame - Camera.CFrame.Position
        local moveDir = cameraRot * moveVector
        if moveDir.Magnitude > 0 then
            freecamBasePos = freecamBasePos + moveDir.Unit * ((S.FreecamSpeed or 40) * dt)
        end
        Camera.CFrame = CFrame.new(freecamBasePos.Position) * cameraRot
    end)
end

local function disableFreecam()
    if not isFreecam then return end
    isFreecam = false
    
    if freecamConnection then freecamConnection:Disconnect(); freecamConnection = nil end
    if freecamInputBeganConn then freecamInputBeganConn:Disconnect(); freecamInputBeganConn = nil end
    if freecamInputEndedConn then freecamInputEndedConn:Disconnect(); freecamInputEndedConn = nil end
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    Camera.CameraType = Enum.CameraType.Custom
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        Camera.CameraSubject = hum
    end
    
    local hrp = getHRP()
    if hrp then
        hrp.Anchored = false
    end
end

-- Server Hop & Teleports
local function serverHop(sortOrder)
    notify("Fetching servers list...", Color3.fromRGB(218, 170, 42))
    task.spawn(function()
        local placeId = game.PlaceId
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100", tostring(placeId), sortOrder or "Asc")
        local res = robloxGet(url)
        if res then
            local data = HttpService:JSONDecode(res)
            if data and data.data then
                local possibleServers = {}
                for _, srv in ipairs(data.data) do
                    if srv.id ~= game.JobId and srv.playing and srv.playing < srv.maxPlayers then
                        table.insert(possibleServers, srv)
                    end
                end
                
                if #possibleServers > 0 then
                    local chosen = possibleServers[math.random(1, #possibleServers)]
                    notify("Found server! Teleporting...", Color3.fromRGB(50, 195, 75))
                    setupAutoReinject()
                    task.wait(0.5)
                    TeleportService:TeleportToPlaceInstance(placeId, chosen.id, LP)
                else
                    notify("No suitable server found!", Color3.fromRGB(218, 38, 38))
                end
            else
                notify("No server data in list!", Color3.fromRGB(218, 38, 38))
            end
        else
            notify("Failed to query Roblox servers proxy!", Color3.fromRGB(218, 38, 38))
        end
    end)
end

local function teleportToRandom()
    serverHop("Asc")
end

local function teleportToLowestPop()
    serverHop("Asc")
end

local function teleportToHighestPop()
    serverHop("Desc")
end

-- External Scripts Loader Helper
local function runExternalScript(name, url, optionalPlaceId)
    if optionalPlaceId and game.PlaceId ~= optionalPlaceId then
        notify("This script requires PlaceId " .. tostring(optionalPlaceId), Color3.fromRGB(218, 38, 38))
        return
    end
    notify("Loading script: " .. name .. "...", Color3.fromRGB(218, 170, 42))
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(url))()
        end)
        if ok then
            notify("Loaded " .. name .. " successfully!", Color3.fromRGB(50, 195, 75))
        else
            notify("Failed to load " .. name .. ": " .. tostring(err), Color3.fromRGB(218, 38, 38))
        end
    end)
end

-- Custom Logging Utilities
local function logMessage(sender, text, color)
    local logObj = {
        message = string.format("[%s]: %s", sender, text),
        messageType = Enum.MessageType.MessageOutput,
        timestamp = os.date("%H:%M:%S")
    }
    table.insert(consoleLogs, logObj)
    if #consoleLogs > 500 then table.remove(consoleLogs, 1) end
    if activeConsoleFeed then
        activeConsoleFeed:AddEntry(logObj.message, color or Color3.fromRGB(200, 200, 200))
    end
end

-- Developer Console & Chat logs hook
local function connectConsoleLogger()
    local LogService = game:GetService("LogService")
    
    pcall(function()
        local history = LogService:GetLogHistory()
        for _, log in ipairs(history) do
            local msg = log.message
            local msgType = log.messageType
            local rawTime = log.timestamp
            if rawTime and rawTime > 1e11 then
                rawTime = rawTime / 1000
            end
            local timestamp = os.date("%H:%M:%S", rawTime)
            
            local key = msgType.Value .. "_" .. msg
            local existingLog = consoleLogsMap[key]
            if existingLog then
                existingLog.count = (existingLog.count or 1) + 1
                existingLog.timestamp = timestamp
                for idx, item in ipairs(consoleLogs) do
                    if item == existingLog then
                        table.remove(consoleLogs, idx)
                        break
                    end
                end
                table.insert(consoleLogs, existingLog)
            else
                local logObj = {
                    message = msg,
                    messageType = msgType,
                    timestamp = timestamp,
                    count = 1
                }
                table.insert(consoleLogs, logObj)
                consoleLogsMap[key] = logObj
                if #consoleLogs > 500 then
                    local removed = table.remove(consoleLogs, 1)
                    if removed then
                        local rKey = removed.messageType.Value .. "_" .. removed.message
                        consoleLogsMap[rKey] = nil
                    end
                end
            end
            
            if activeConsoleFeed then
                local prefix = ""
                local col = Color3.fromRGB(220, 220, 220)
                if msgType == Enum.MessageType.MessageInfo then
                    col = Color3.fromRGB(80, 180, 240)
                    prefix = "[INFO] "
                elseif msgType == Enum.MessageType.MessageWarning then
                    col = Color3.fromRGB(240, 200, 50)
                    prefix = "[WARN] "
                elseif msgType == Enum.MessageType.MessageError then
                    col = Color3.fromRGB(240, 70, 70)
                    prefix = "[ERROR] "
                end
                
                local currentLog = consoleLogsMap[key]
                activeConsoleFeed:AddEntry(prefix .. msg, col, currentLog.count)
            end
        end
    end)

    local con = LogService.MessageOut:Connect(function(msg, msgType)
        local timestamp = os.date("%H:%M:%S")
        local key = msgType.Value .. "_" .. msg
        local existingLog = consoleLogsMap[key]
        if existingLog then
            existingLog.count = (existingLog.count or 1) + 1
            existingLog.timestamp = timestamp
            for idx, item in ipairs(consoleLogs) do
                if item == existingLog then
                    table.remove(consoleLogs, idx)
                    break
                end
            end
            table.insert(consoleLogs, existingLog)
        else
            local logObj = {
                message = msg,
                messageType = msgType,
                timestamp = timestamp,
                count = 1
            }
            table.insert(consoleLogs, logObj)
            consoleLogsMap[key] = logObj
            if #consoleLogs > 500 then
                local removed = table.remove(consoleLogs, 1)
                if removed then
                    local rKey = removed.messageType.Value .. "_" .. removed.message
                    consoleLogsMap[rKey] = nil
                end
            end
        end
        if activeConsoleFeed then
            local prefix = ""
            local col = Color3.fromRGB(220, 220, 220)
            if msgType == Enum.MessageType.MessageInfo then
                col = Color3.fromRGB(80, 180, 240)
                prefix = "[INFO] "
            elseif msgType == Enum.MessageType.MessageWarning then
                col = Color3.fromRGB(240, 200, 50)
                prefix = "[WARN] "
            elseif msgType == Enum.MessageType.MessageError then
                col = Color3.fromRGB(240, 70, 70)
                prefix = "[ERROR] "
            end
            activeConsoleFeed:AddEntry(prefix .. msg, col)
        end
    end)
    table.insert(S.Connections, con)
end

local lastChats = {}
local function isDuplicateChat(speaker, message)
    local t = tick()
    local last = lastChats[speaker]
    if last and last.message == message and (t - last.time) < 0.2 then
        return true
    end
    lastChats[speaker] = {message = message, time = t}
    return false
end

local function appendToChatLogFile(timestamp, speaker, message)
    pcall(function()
        if writefile and readfile then
            local filename = "utility_hub_chat_logs.txt"
            local logLine = string.format("[%s] [%s]: %s\n", timestamp, speaker, message)
            if isfile(filename) then
                if appendfile then
                    appendfile(filename, logLine)
                else
                    local current = readfile(filename)
                    writefile(filename, current .. logLine)
                end
            else
                writefile(filename, logLine)
            end
        end
    end)
end

local function connectChatLogger()
    local chatService = game:GetService("TextChatService")
    local useModern = false
    pcall(function()
        if chatService.ChatVersion == Enum.ChatVersion.TextChatService then
            useModern = true
        end
    end)

    if useModern then
        pcall(function()
            local modernCon = chatService.MessageReceived:Connect(function(msgObj)
                local speaker = "System"
                if msgObj.TextSource then
                    local p = Players:GetPlayerByUserId(msgObj.TextSource.UserId)
                    if p then
                        speaker = p.DisplayName
                    else
                        speaker = msgObj.TextSource.DisplayName or "System"
                    end
                end
                local text = msgObj.Text
                if isDuplicateChat(speaker, text) then return end

                local timestamp = os.date("%H:%M:%S")
                local log = {
                    Speaker = speaker,
                    Message = text,
                    Timestamp = timestamp,
                    Color = Color3.fromRGB(200, 200, 200)
                }
                table.insert(S.ChatHistory, log)
                if #S.ChatHistory > 200 then table.remove(S.ChatHistory, 1) end
                if activeChatFeed then
                    activeChatFeed:AddEntry(string.format("[%s] [%s]: %s", timestamp, speaker, text), log.Color)
                end
                appendToChatLogFile(timestamp, speaker, text)
                if S.ToastChatEnabled and speaker ~= LP.DisplayName then
                    showToast(speaker .. ": " .. text, currentThemeColor)
                end
            end)
            table.insert(S.Connections, modernCon)
        end)
    else
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                S.ChatConnections[p] = p.Chatted:Connect(function(msg)
                    local speaker = p.DisplayName
                    if isDuplicateChat(speaker, msg) then return end

                    local timestamp = os.date("%H:%M:%S")
                    local log = {
                        Speaker = speaker,
                        Message = msg,
                        Timestamp = timestamp,
                        Color = Color3.fromRGB(200, 200, 200)
                    }
                    table.insert(S.ChatHistory, log)
                    if #S.ChatHistory > 200 then table.remove(S.ChatHistory, 1) end
                    if activeChatFeed then
                        activeChatFeed:AddEntry(string.format("[%s] [%s]: %s", timestamp, speaker, msg), log.Color)
                    end
                    appendToChatLogFile(timestamp, speaker, msg)
                    if S.ToastChatEnabled and p ~= LP then
                        showToast(speaker .. ": " .. msg, currentThemeColor)
                    end
                end)
            end
            
            local playerAddedCon = Players.PlayerAdded:Connect(function(p)
                S.ChatConnections[p] = p.Chatted:Connect(function(msg)
                    local speaker = p.DisplayName
                    if isDuplicateChat(speaker, msg) then return end

                    local timestamp = os.date("%H:%M:%S")
                    local log = {
                        Speaker = speaker,
                        Message = msg,
                        Timestamp = timestamp,
                        Color = Color3.fromRGB(200, 200, 200)
                    }
                    table.insert(S.ChatHistory, log)
                    if #S.ChatHistory > 200 then table.remove(S.ChatHistory, 1) end
                    if activeChatFeed then
                        activeChatFeed:AddEntry(string.format("[%s] [%s]: %s", timestamp, speaker, msg), log.Color)
                    end
                    appendToChatLogFile(timestamp, speaker, msg)
                    if S.ToastChatEnabled and p ~= LP then
                        showToast(speaker .. ": " .. msg, currentThemeColor)
                    end
                end)
            end)
            table.insert(S.Connections, playerAddedCon)
        end)
    end
end

-- Overhead tags logic
local function createOverhead(p)
    if p == LP then return end
    local char = p.Character
    local head = char and char:WaitForChild("Head", 3)
    if not head then return end
    
    if S.OverheadPool[p] then
        pcall(function() S.OverheadPool[p]:Destroy() end)
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "VoidOverhead"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Adornee = head
    billboard.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextColor3 = p.TeamColor and p.TeamColor.Color or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    local function updateText()
        local hum = char:FindFirstChildOfClass("Humanoid")
        local health = hum and math.floor(hum.Health) or 0
        label.Text = string.format("%s\n<font color='#2ecc71'>%d HP</font> | %s", p.DisplayName, health, p.Team and p.Team.Name or "Neutral")
    end
    label.RichText = true
    updateText()
    label.Parent = billboard
    
    S.OverheadPool[p] = billboard
    
    local connection = nil
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        connection = hum.HealthChanged:Connect(updateText)
        table.insert(S.Connections, connection)
    end
end

local function refreshOverheads()
    for p, bill in pairs(S.OverheadPool) do
        pcall(function() bill:Destroy() end)
    end
    S.OverheadPool = {}
    
    if not S.OverheadInfo then return end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            createOverhead(p)
        end
    end
end

-- Hitbox Expander & Bounding Boxes
local function applyHitbox(p)
    if p == LP then return end
    if S.HitboxTeamCheck and p.Team == LP.Team then return end
    
    local char = p.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
    if hrp then
        if S.HitboxExpanded then
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
                adorn.Color3 = p.TeamColor and p.TeamColor.Color or currentThemeColor
                adorn.Adornee = hrp
                adorn.Parent = hrp
            end
            adorn.Size = hrp.Size
            adorn.Transparency = S.HitboxTransparency
        else
            restoreHitbox(p)
        end
    end
end

local function updateHitboxes()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if S.HitboxExpanded then
                applyHitbox(p)
            else
                restoreHitbox(p)
            end
        end
    end
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
    S.FlingAllActive = false
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
--  METEOR CLIENT / ROBOCRAFT CUSTOM GUI FRAMEWORK
-- ──────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MeteorRobloxGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    local cg = game:GetService("CoreGui")
    screenGui.Parent = cg
end)
if not screenGui.Parent then
    pcall(function() screenGui.Parent = LP:WaitForChild("PlayerGui") end)
end

-- Theme Color System definitions
local themeColors = {
    ["Purple"] = Color3.fromRGB(141, 47, 196),
    ["Red"]    = Color3.fromRGB(218, 38, 38),
    ["Green"]  = Color3.fromRGB(46, 204, 113),
    ["Blue"]   = Color3.fromRGB(41, 128, 185),
    ["Yellow"] = Color3.fromRGB(241, 196, 15),
    ["Cyan"]   = Color3.fromRGB(26, 188, 156),
    ["Pink"]   = Color3.fromRGB(232, 44, 154),
    ["Orange"] = Color3.fromRGB(230, 126, 34)
}
local currentThemeColor = themeColors[S.ThemeColor or "Purple"] or themeColors["Purple"]
local themeHeaders = {}
local themeTexts = {}
local themeFills = {}
local themeToggles = {}

local activeTab = "Modules"
local menuBlur = Lighting:FindFirstChild("WeAreSkiddingBlur")
if not menuBlur then
    menuBlur = Instance.new("BlurEffect")
    menuBlur.Name = "WeAreSkiddingBlur"
    menuBlur.Size = 0
    menuBlur.Enabled = false
    menuBlur.Parent = Lighting
end

local function updateMenuBlur()
    if not uiVisible then
        TweenService:Create(menuBlur, TweenInfo.new(0.25), {Size = 0}):Play()
        task.delay(0.25, function()
            if not uiVisible then menuBlur.Enabled = false end
        end)
        return
    end

    local needsBlur = (activeTab == "Settings")
    if needsBlur then
        menuBlur.Enabled = true
        TweenService:Create(menuBlur, TweenInfo.new(0.25), {Size = 16}):Play()
    else
        TweenService:Create(menuBlur, TweenInfo.new(0.25), {Size = 0}):Play()
        task.delay(0.25, function()
            if activeTab == "Modules" or not uiVisible then
                menuBlur.Enabled = false
            end
        end)
    end
end
local tabButtons = {}
local windows = {}
local moduleButtons = {}
local floatingWindows = {}

-- Declaring HUD structures beforehand so they are in scope
local hudWatermark = nil
local hudCoords = nil
local hudArrayListFrame = nil

local function updateHUDArrayList()
    if not hudArrayListFrame then return end
    for _, child in ipairs(hudArrayListFrame:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    
    if not S.HUDArrayList then return end
    
    local activeMods = {}
    for modName, item in pairs(moduleButtons) do
        if item.Button.TextColor3 == Color3.fromRGB(100, 240, 100) then
            table.insert(activeMods, modName)
        end
    end
    
    table.sort(activeMods, function(a, b)
        return #a > #b
    end)
    
    for _, modName in ipairs(activeMods) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextColor3 = currentThemeColor
        lbl.TextXAlignment = Enum.TextXAlignment.Right
        lbl.Text = modName .. "   "
        lbl.Parent = hudArrayListFrame

        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 2, 1, 0)
        accent.Position = UDim2.new(1, -2, 0, 0)
        accent.BackgroundColor3 = currentThemeColor
        accent.BorderSizePixel = 0
        accent.Parent = lbl
    end
end

local function applyThemeColor(colorName)
    local col = themeColors[colorName] or themeColors["Purple"]
    currentThemeColor = col
    S.ThemeColor = colorName
    
    for _, obj in ipairs(themeHeaders) do
        pcall(function() obj.BackgroundColor3 = col end)
    end
    for _, obj in ipairs(themeTexts) do
        pcall(function() obj.TextColor3 = col end)
    end
    for _, obj in ipairs(themeFills) do
        pcall(function() obj.BackgroundColor3 = col end)
    end
    for _, updateFunc in ipairs(themeToggles) do
        pcall(updateFunc)
    end
    
    for name, btn in pairs(tabButtons) do
        if name == activeTab then
            btn.TextColor3 = col
        end
    end
    
    if hudWatermark then
        hudWatermark.TextColor3 = col
    end
    
    task.defer(updateHUDArrayList)
end

-- Top Bar styled like Meteor client
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 24)
topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

local topStroke = Instance.new("UIStroke")
topStroke.Color = Color3.fromRGB(30, 30, 30)
topStroke.Thickness = 1
topStroke.Parent = topBar

local function getExecutorName()
    if identifyexecutor then
        local ok, name = pcall(identifyexecutor)
        if ok and name then return name end
    end
    if syn then return "Synapse" end
    if krnl then return "Krnl" end
    if fluxus then return "Fluxus" end
    return "Unknown"
end
local executorName = getExecutorName()

local topTitle = Instance.new("TextLabel")
topTitle.Size = UDim2.new(0, 450, 1, 0)
topTitle.Position = UDim2.new(0, 10, 0, 0)
topTitle.BackgroundTransparency = 1
topTitle.Font = Enum.Font.GothamBold
topTitle.TextSize = 11
topTitle.TextColor3 = currentThemeColor
topTitle.TextXAlignment = Enum.TextXAlignment.Left
topTitle.Text = "WeAreSkidding <font color='#ffffff'>On Roblox v1.3</font> <font color='#888888'>(" .. executorName .. ")</font>"
topTitle.RichText = true
topTitle.Parent = topBar

local hudTextLabel = Instance.new("TextLabel")
hudTextLabel.Size = UDim2.new(0, 300, 1, 0)
hudTextLabel.Position = UDim2.new(1, -310, 0, 0)
hudTextLabel.BackgroundTransparency = 1
hudTextLabel.Font = Enum.Font.Code
hudTextLabel.TextSize = 10
hudTextLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
hudTextLabel.TextXAlignment = Enum.TextXAlignment.Right
hudTextLabel.Text = "FPS: -- | PING: --"
hudTextLabel.Parent = topBar

-- Custom Notification Toast System
local toastContainer = Instance.new("Frame")
toastContainer.Size = UDim2.new(0, 260, 0, 300)
toastContainer.Position = UDim2.new(1, -270, 1, -325)
toastContainer.BackgroundTransparency = 1
toastContainer.BorderSizePixel = 0
toastContainer.Parent = screenGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastContainer

local function showToast(message, color)
    if not S.ToastEnabled then return end
    
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 38)
    toast.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    toast.BorderSizePixel = 0
    toast.Parent = toastContainer

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or currentThemeColor
    stroke.Thickness = 1.2
    stroke.Parent = toast

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(245, 245, 245)
    lbl.Text = message
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast

    toast.Size = UDim2.new(1, 0, 0, 0)
    lbl.TextTransparency = 1
    stroke.Transparency = 1
    
    local tweenService = game:GetService("TweenService")
    tweenService:Create(toast, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 38)}):Play()
    tweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    tweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()

    task.delay(3.5, function()
        if toast and toast.Parent then
            local t1 = tweenService:Create(toast, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)})
            local t2 = tweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 1})
            local t3 = tweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1})
            t1:Play()
            t2:Play()
            t3:Play()
            t1.Completed:Connect(function()
                toast:Destroy()
            end)
        end
    end)
end

notify = function(msg, color)
    showToast(msg, color)
end

-- Custom dragging helper
local function makeDraggable(frame, handle)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function formatVal(val)
    if type(val) == "number" then
        local str = string.format("%.2f", val)
        str = str:gsub("%.00$", "")
        if str:find("%.") then
            str = str:gsub("0+$", "")
        end
        return str
    end
    return tostring(val)
end

-- Custom resizable helper
local function makeResizable(frame, handle)
    local dragging = false
    local dragStart, startSize

    local function update(input)
        local delta = input.Position - dragStart
        local newWidth = math.max(120, startSize.X.Offset + delta.X)
        local newHeight = math.max(50, startSize.Y.Offset + delta.Y)
        frame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startSize = frame.Size

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

local function findWindowFrame(obj)
    local curr = obj
    while curr do
        if curr:IsA("Frame") and curr:GetAttribute("BaseWidth") then
            return curr
        end
        curr = curr.Parent
    end
    return nil
end

local function scaleGuiObject(obj, scale)
    if not obj:IsA("GuiObject") then return end
    if obj:IsA("UIListLayout") or obj:IsA("UIPadding") or obj:IsA("UIStroke") or obj:IsA("UIGridLayout") then return end
    if obj.Name == "resizeHandle" then return end
    
    local baseSize = obj:GetAttribute("BaseSize")
    if not baseSize then
        baseSize = obj.Size
        obj:SetAttribute("BaseSize", baseSize)
    end
    
    local basePos = obj:GetAttribute("BasePos")
    if not basePos then
        basePos = obj.Position
        obj:SetAttribute("BasePos", basePos)
    end
    
    obj.Size = UDim2.new(
        baseSize.X.Scale,
        baseSize.X.Offset * scale,
        baseSize.Y.Scale,
        baseSize.Y.Offset * scale
    )
    obj.Position = UDim2.new(
        basePos.X.Scale,
        basePos.X.Offset * scale,
        basePos.Y.Scale,
        basePos.Y.Offset * scale
    )
    
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        local baseTextSize = obj:GetAttribute("BaseTextSize")
        if not baseTextSize then
            baseTextSize = obj.TextSize
            obj:SetAttribute("BaseTextSize", baseTextSize)
        end
        obj.TextSize = math.clamp(math.round(baseTextSize * scale), 7, 24)
    end
end

local function autoScaleContent(winFrame, scale)
    local contentFrame = winFrame:FindFirstChild("content") or winFrame:FindFirstChildOfClass("ScrollingFrame")
    if contentFrame then
        local listLayout = contentFrame:FindFirstChildOfClass("UIListLayout")
        if listLayout then
            local basePadding = listLayout:GetAttribute("BasePadding")
            if not basePadding then
                basePadding = listLayout.Padding.Offset
                listLayout:SetAttribute("BasePadding", basePadding)
            end
            listLayout.Padding = UDim.new(0, basePadding * scale)
        end
        
        local uiPadding = contentFrame:FindFirstChildOfClass("UIPadding")
        if uiPadding then
            local basePadT = uiPadding:GetAttribute("BasePadTop")
            local basePadB = uiPadding:GetAttribute("BasePadBottom")
            local basePadL = uiPadding:GetAttribute("BasePadLeft")
            local basePadR = uiPadding:GetAttribute("BasePadRight")
            if not basePadT then
                basePadT = uiPadding.PaddingTop.Offset
                basePadB = uiPadding.PaddingBottom.Offset
                basePadL = uiPadding.PaddingLeft.Offset
                basePadR = uiPadding.PaddingRight.Offset
                uiPadding:SetAttribute("BasePadTop", basePadT)
                uiPadding:SetAttribute("BasePadBottom", basePadB)
                uiPadding:SetAttribute("BasePadLeft", basePadL)
                uiPadding:SetAttribute("BasePadRight", basePadR)
            end
            uiPadding.PaddingTop = UDim.new(0, basePadT * scale)
            uiPadding.PaddingBottom = UDim.new(0, basePadB * scale)
            uiPadding.PaddingLeft = UDim.new(0, basePadL * scale)
            uiPadding.PaddingRight = UDim.new(0, basePadR * scale)
        end
    end
    
    for _, child in ipairs(winFrame:GetDescendants()) do
        scaleGuiObject(child, scale)
    end
end

local function adjustWindowSizeToContent(winFrame, contentFrame)
    local totalContentHeight = 0
    local count = 0
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "resizeHandle" then
            local baseH = child:GetAttribute("BaseSize") and child:GetAttribute("BaseSize").Y.Offset or child.Size.Y.Offset
            totalContentHeight = totalContentHeight + baseH
            count = count + 1
        end
    end
    
    local listLayout = contentFrame:FindFirstChildOfClass("UIListLayout")
    local paddingVal = listLayout and listLayout.Padding.Offset or 4
    
    local uiPadding = contentFrame:FindFirstChildOfClass("UIPadding")
    local padT = uiPadding and uiPadding.PaddingTop.Offset or 6
    local padB = uiPadding and uiPadding.PaddingBottom.Offset or 6
    
    local contentHeight = padT + padB + totalContentHeight + math.max(0, count - 1) * paddingVal
    local headerHeight = 22
    local finalHeight = headerHeight + contentHeight
    
    finalHeight = math.clamp(finalHeight, 50, 300)
    
    local width = winFrame.Size.X.Offset
    winFrame.Size = UDim2.new(0, width, 0, finalHeight)
    winFrame:SetAttribute("BaseWidth", width)
    winFrame:SetAttribute("BaseHeight", finalHeight)
end

-- Settings builders for nested inline options frames
-- Helper to add premium metallic/glassy vertical gradient to elements
local function addHeaderGradient(obj)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160))
    })
    grad.Rotation = 90
    grad.Parent = obj
end

-- Settings builders for nested inline options frames
local function addToggleOption(parent, name, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -34, 1, 0)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 26, 0, 14)
    btn.Position = UDim2.new(1, -30, 0.5, -7)
    btn.BackgroundColor3 = defaultVal and currentThemeColor or Color3.fromRGB(55, 55, 55)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 7)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.Color = defaultVal and currentThemeColor or Color3.fromRGB(80, 80, 80)
    btnStroke.Parent = btn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = defaultVal and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = btn

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 5)
    knobCorner.Parent = knob

    local active = defaultVal
    local function updateToggle(animate)
        local targetPos = active and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        local targetCol = active and currentThemeColor or Color3.fromRGB(55, 55, 55)
        local targetStrokeCol = active and currentThemeColor or Color3.fromRGB(80, 80, 80)
        if animate then
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = targetCol}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = targetStrokeCol}):Play()
        else
            knob.Position = targetPos
            btn.BackgroundColor3 = targetCol
            btnStroke.Color = targetStrokeCol
        end
    end

    table.insert(themeToggles, function()
        updateToggle(false)
    end)

    btn.MouseButton1Click:Connect(function()
        active = not active
        updateToggle(true)
        callback(active)
    end)

    return {
        Set = function(val)
            active = val
            updateToggle(false)
        end
    }
end

local function addSliderOption(parent, name, min, max, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 12)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.35, 0, 0, 12)
    valLabel.Position = UDim2.new(0.65, -4, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 10
    valLabel.TextColor3 = currentThemeColor
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Text = formatVal(defaultVal)
    valLabel.Parent = row
    table.insert(themeTexts, valLabel)

    local slideBg = Instance.new("Frame")
    slideBg.Size = UDim2.new(1, -8, 0, 5)
    slideBg.Position = UDim2.new(0, 4, 0, 15)
    slideBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slideBg.BorderSizePixel = 0
    slideBg.Parent = row

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 2.5)
    bgCorner.Parent = slideBg

    local slideFill = Instance.new("Frame")
    local startPct = math.clamp((defaultVal - min) / (max - min), 0, 1)
    slideFill.Size = UDim2.new(startPct, 0, 1, 0)
    slideFill.BackgroundColor3 = currentThemeColor
    slideFill.BorderSizePixel = 0
    slideFill.Parent = slideBg
    table.insert(themeFills, slideFill)

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2.5)
    fillCorner.Parent = slideFill

    local slideKnob = Instance.new("Frame")
    slideKnob.Size = UDim2.new(0, 10, 0, 10)
    slideKnob.Position = UDim2.new(1, -5, 0.5, -5)
    slideKnob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    slideKnob.BorderSizePixel = 0
    slideKnob.Parent = slideFill

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 5)
    knobCorner.Parent = slideKnob

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = Color3.fromRGB(30, 30, 30)
    knobStroke.Thickness = 1
    knobStroke.Parent = slideKnob

    local slideBtn = Instance.new("TextButton")
    slideBtn.Size = UDim2.new(1, 0, 1, 0)
    slideBtn.BackgroundTransparency = 1
    slideBtn.Text = ""
    slideBtn.Parent = slideBg

    local function updateSlider(input)
        local sizeX = slideBg.AbsoluteSize.X
        if sizeX <= 0 then sizeX = 112 end
        local posX = input.Position.X - slideBg.AbsolutePosition.X
        local pct = math.clamp(posX / sizeX, 0, 1)
        slideFill.Size = UDim2.new(pct, 0, 1, 0)
        local val = math.floor(min + (max - min) * pct + 0.5)
        valLabel.Text = tostring(val)
        callback(val)
    end

    local dragging = false
    slideBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    slideBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local moveCon = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    table.insert(S.Connections, moveCon)

    return {
        Set = function(val)
            local pct = math.clamp((val - min) / (max - min), 0, 1)
            slideFill.Size = UDim2.new(pct, 0, 1, 0)
            valLabel.Text = formatVal(val)
        end
    }
end

local function addDropdownOption(parent, name, optionsList, defaultValIndex, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 12)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -8, 0, 14)
    dropBtn.Position = UDim2.new(0, 4, 0, 12)
    dropBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    dropBtn.BorderSizePixel = 0
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.TextSize = 9
    dropBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    dropBtn.Text = optionsList[defaultValIndex] or "(none)"
    dropBtn.Parent = row

    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 4)
    dropCorner.Parent = dropBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 50)
    stroke.Parent = dropBtn

    addHeaderGradient(dropBtn)

    local open = false
    local listContainer = nil

    local function toggleDropdown()
        open = not open
        local scale = 1.0
        local winFrame = findWindowFrame(row)
        if winFrame then
            local baseW = winFrame:GetAttribute("BaseWidth") or winFrame.Size.X.Offset
            if baseW > 0 then
                scale = winFrame.Size.X.Offset / baseW
            end
        end

        if open then
            listContainer = Instance.new("Frame")
            listContainer.Size = UDim2.new(1, 0, 0, #optionsList * 14 * scale)
            listContainer:SetAttribute("BaseSize", UDim2.new(1, 0, 0, #optionsList * 14))
            listContainer:SetAttribute("BasePos", UDim2.new(0, 0, 1, 0))
            listContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            listContainer.BorderSizePixel = 0
            listContainer.ZIndex = 20
            listContainer.Parent = dropBtn

            local listCorner = Instance.new("UICorner")
            listCorner.CornerRadius = UDim.new(0, 4)
            listCorner.Parent = listContainer

            local listStroke = Instance.new("UIStroke")
            listStroke.Color = Color3.fromRGB(45, 45, 45)
            listStroke.Parent = listContainer

            local layout = Instance.new("UIListLayout")
            layout.Parent = listContainer

            for i, opt in ipairs(optionsList) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 14 * scale)
                btn:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 14))
                btn:SetAttribute("BasePos", UDim2.new(0, 0, 0, 0))
                btn:SetAttribute("BaseTextSize", 7)
                btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                btn.BorderSizePixel = 0
                btn.Font = Enum.Font.Gotham
                btn.TextSize = math.clamp(math.round(7 * scale), 7, 24)
                btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                btn.Text = opt
                btn.ZIndex = 20
                btn.Parent = listContainer

                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 3)
                itemCorner.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    dropBtn.Text = opt
                    callback(i, opt)
                    toggleDropdown()
                end)
            end
            row.Size = UDim2.new(1, 0, 0, (30 + #optionsList * 14) * scale)
            row:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 30 + #optionsList * 14))
        else
            if listContainer then
                listContainer:Destroy()
                listContainer = nil
            end
            row.Size = UDim2.new(1, 0, 0, 30 * scale)
            row:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 30))
        end
    end

    dropBtn.MouseButton1Click:Connect(toggleDropdown)

    return {
        Set = function(valText)
            dropBtn.Text = valText
        end,
        SetOptions = function(newList)
            optionsList = newList
            if open then
                toggleDropdown()
                toggleDropdown()
            end
        end
    }
end

local function addKeybindOption(parent, name, defaultKey, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row

    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0, 50, 0, 14)
    bindBtn.Position = UDim2.new(1, -54, 0.5, -7)
    bindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    bindBtn.BorderSizePixel = 0
    bindBtn.Font = Enum.Font.GothamBold
    bindBtn.TextSize = 9
    bindBtn.TextColor3 = currentThemeColor
    bindBtn.Text = defaultKey and defaultKey.Name or "[none]"
    bindBtn.Parent = row
    table.insert(themeTexts, bindBtn)

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = bindBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 50)
    stroke.Parent = bindBtn

    addHeaderGradient(bindBtn)

    local listening = false
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "..."
        bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    local con = UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            local key = input.KeyCode
            bindBtn.Text = key.Name
            bindBtn.TextColor3 = currentThemeColor
            callback(key)
        end
    end)
    table.insert(S.Connections, con)

    return {
        Set = function(key)
            bindBtn.Text = key and key.Name or "[none]"
        end
    }
end

local function addTextboxOption(parent, name, placeholder, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 12)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -8, 0, 14)
    box.Position = UDim2.new(0, 4, 0, 12)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Gotham
    box.TextSize = 9
    box.TextColor3 = Color3.fromRGB(240, 240, 240)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = row

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 50)
    stroke.Parent = box

    box.FocusLost:Connect(function(enterPressed)
        callback(box.Text)
    end)

    return {
        Set = function(valText)
            box.Text = valText
        end
    }
end

local function addButtonOption(parent, name, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 14)
    btn.Position = UDim2.new(0, 4, 0.5, -7)
    btn.BackgroundColor3 = currentThemeColor
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name
    btn.Parent = row
    table.insert(themeHeaders, btn)

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Transparency = 0.85
    btnStroke.Parent = btn

    addHeaderGradient(btn)

    btn.MouseButton1Click:Connect(callback)
end

local function addSectionHeader(parent, title)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -8, 1, 0)
    text.Position = UDim2.new(0, 4, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextSize = 10
    text.TextColor3 = currentThemeColor
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Text = "── " .. title:upper() .. " ──"
    text.Parent = row
    table.insert(themeTexts, text)
end

local function addInfoRowOption(parent, name, initialValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 16)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.5, -8, 1, 0)
    valLabel.Position = UDim2.new(0.5, 4, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 10
    valLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Text = initialValue
    valLabel.Parent = row

    return {
        Label = valLabel,
        SetValue = function(self, val)
            valLabel.Text = tostring(val)
        end,
        SetColor = function(self, color)
            valLabel.TextColor3 = color
        end
    }
end

local function addCustomFrameOption(parent, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundTransparency = 1
    row.Parent = parent
    return row
end

local function addScrollFeedOption(parent, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, height)
    row.Position = UDim2.new(0, 4, 0, 0)
    row.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    row.BorderSizePixel = 0
    row.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(30, 30, 30)
    stroke.Parent = row

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = row

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 1)
    layout.Parent = scroll

    local entriesMap = {}
    local entryCount = 0

    return {
        Clear = function()
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("TextLabel") then c:Destroy() end
            end
            entriesMap = {}
            entryCount = 0
        end,
        AddEntry = function(self, text, color, count)
            local initialCount = count or 1
            local existing = entriesMap[text]
            if existing then
                existing.count = existing.count + initialCount
                existing.label.Text = string.format("%s (x%d)", text, existing.count)
                return
            end

            entryCount = entryCount + 1
            local currentOrder = entryCount

            local scale = 1.0
            local winFrame = findWindowFrame(row)
            if winFrame then
                local baseW = winFrame:GetAttribute("BaseWidth") or winFrame.Size.X.Offset
                if baseW > 0 then
                    scale = winFrame.Size.X.Offset / baseW
                end
            end

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 12 * scale)
            label:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 12))
            label:SetAttribute("BasePos", UDim2.new(0, 0, 0, 0))
            label:SetAttribute("BaseTextSize", 7)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Code
            label.TextSize = math.clamp(math.round(7 * scale), 7, 24)
            label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.LayoutOrder = currentOrder
            
            local displayText = text
            if initialCount > 1 then
                displayText = string.format("%s (x%d)", text, initialCount)
            end
            label.Text = displayText
            label.TextWrapped = true
            label.Parent = scroll

            entriesMap[text] = { label = label, count = initialCount }

            task.defer(function()
                scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
            end)
        end
    }
end

-- Draggable category windows builder
local windows = {}
local moduleButtons = {}

local catPositions = {
    ["Combat"] = 20,
    ["Player"] = 210,
    ["Movement"] = 400,
    ["Render"] = 590,
    ["World"] = 780,
    ["Misc"] = 970,
    ["Search"] = 1160
}

local function getOrCreateWindow(catName, defaultX, defaultY)
    if windows[catName] then return windows[catName] end

    local x = catPositions[catName] or defaultX
    local y = defaultY

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 180, 0, 22)
    win.AutomaticSize = Enum.AutomaticSize.Y
    win.Position = UDim2.new(0, x, 0, y)
    win.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = screenGui

    local winCorner = Instance.new("UICorner")
    winCorner.CornerRadius = UDim.new(0, 6)
    winCorner.Parent = win

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundColor3 = currentThemeColor
    header.BorderSizePixel = 0
    header.Font = Enum.Font.GothamBold
    header.TextSize = 10
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "  " .. catName
    header.Parent = win
    table.insert(themeHeaders, header)
    addHeaderGradient(header)

    local collapseBtn = Instance.new("TextLabel")
    collapseBtn.Size = UDim2.new(0, 22, 0, 22)
    collapseBtn.Position = UDim2.new(1, -22, 0, 0)
    collapseBtn.BackgroundTransparency = 1
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.TextSize = 9
    collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    collapseBtn.Text = "▼"
    collapseBtn.Parent = header

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.Position = UDim2.new(0, 0, 0, 22)
    list.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    list.BackgroundTransparency = 0.15
    list.BorderSizePixel = 0
    list.Parent = win

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 1)
    listLayout.Parent = list

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(30, 30, 30)
    stroke.Parent = win

    makeDraggable(win, header)

    local collapsed = false
    local function toggleCollapse()
        collapsed = not collapsed
        list.Visible = not collapsed
        collapseBtn.Text = collapsed and "▲" or "▼"
    end

    header.MouseButton1Click:Connect(toggleCollapse)

    windows[catName] = { Frame = win, List = list, Layout = listLayout }
    return windows[catName]
end

-- Helper to build separate draggable windows for options/configs
local function createFloatingWindow(title, width, height, defaultX, defaultY)
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, width, 0, height)
    win.Position = UDim2.new(0, defaultX, 0, defaultY)
    win.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Visible = false
    win.ZIndex = 5
    win.Parent = screenGui

    local winCorner = Instance.new("UICorner")
    winCorner.CornerRadius = UDim.new(0, 6)
    winCorner.Parent = win

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundColor3 = currentThemeColor
    header.BorderSizePixel = 0
    header.Font = Enum.Font.GothamBold
    header.TextSize = 10
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "  " .. title
    header.Parent = win
    table.insert(themeHeaders, header)
    addHeaderGradient(header)

    local collapsed = false
    local baseHeight = height

    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 22, 0, 22)
    collapseBtn.Position = UDim2.new(1, -44, 0, 0)
    collapseBtn.BackgroundTransparency = 1
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.TextSize = 10
    collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    collapseBtn.Text = "-"
    collapseBtn.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -22, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 10
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.Parent = header
    closeBtn.MouseButton1Click:Connect(function()
        win.Visible = false
        win:SetAttribute("UserOpen", false)
    end)

    local content = Instance.new("ScrollingFrame")
    content.Name = "content"
    content.Size = UDim2.new(1, 0, 1, -22)
    content.Position = UDim2.new(0, 0, 0, 22)
    content.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    content.BackgroundTransparency = 0.15
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 2
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = win

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = content

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 40)
    stroke.Thickness = 1.2
    stroke.Parent = win

    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "resizeHandle"
    resizeHandle.Size = UDim2.new(0, 6, 0, 6)
    resizeHandle.Position = UDim2.new(1, -6, 1, -6)
    resizeHandle.BackgroundColor3 = currentThemeColor
    resizeHandle.BackgroundTransparency = 0.3
    resizeHandle.BorderSizePixel = 0
    resizeHandle.ZIndex = 10
    resizeHandle.Parent = win
    table.insert(themeFills, resizeHandle)

    makeResizable(win, resizeHandle)

    collapseBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        content.Visible = not collapsed
        resizeHandle.Visible = not collapsed
        
        if collapsed then
            baseHeight = win.Size.Y.Offset
            win.Size = UDim2.new(0, win.Size.X.Offset, 0, 22)
            collapseBtn.Text = "+"
        else
            win.Size = UDim2.new(0, win.Size.X.Offset, 0, baseHeight)
            collapseBtn.Text = "-"
        end
    end)

    makeDraggable(win, header)
    table.insert(floatingWindows, win)

    win:SetAttribute("BaseWidth", width)
    win:SetAttribute("BaseHeight", height)

    local isScaling = false
    win:GetPropertyChangedSignal("Size"):Connect(function()
        if collapsed then return end
        if isScaling then return end
        isScaling = true

        local currentWidth = win.Size.X.Offset
        local baseWidth = win:GetAttribute("BaseWidth") or width
        if baseWidth > 0 then
            local scale = currentWidth / baseWidth
            autoScaleContent(win, scale)

            -- Recalculate content height dynamically
            local totalContentHeight = 0
            local count = 0
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("Frame") and child.Name ~= "resizeHandle" then
                    totalContentHeight = totalContentHeight + child.Size.Y.Offset
                    count = count + 1
                end
            end

            local listLayout = content:FindFirstChildOfClass("UIListLayout")
            local paddingVal = listLayout and listLayout.Padding.Offset or (4 * scale)

            local uiPadding = content:FindFirstChildOfClass("UIPadding")
            local padT = uiPadding and uiPadding.PaddingTop.Offset or (6 * scale)
            local padB = uiPadding and uiPadding.PaddingBottom.Offset or (6 * scale)

            local contentHeight = padT + padB + totalContentHeight + math.max(0, count - 1) * paddingVal + 2 * scale
            local headerHeight = 22 * scale
            local finalHeight = headerHeight + contentHeight

            finalHeight = math.clamp(finalHeight, 50 * scale, 400 * scale)
            win.Size = UDim2.new(0, currentWidth, 0, finalHeight)
        end
        isScaling = false
    end)

    return win, content
end

-- Compatibility API mapping to inline options frames or separate draggable windows
-- Compatibility API mapping to inline options frames or separate draggable windows
local function registerModule(catName, name, defaultX, defaultY, isToggle, defaultState, callback, populateOptionsFunc, useSeparateWindow, winWidth, winHeight)
    local win = getOrCreateWindow(catName, defaultX, defaultY)

    local container = Instance.new("Frame")
    container.Name = "Mod_" .. name
    container.Size = UDim2.new(1, 0, 0, 20)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = win.List

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.5
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 9
    btn.TextColor3 = (isToggle and defaultState) and Color3.fromRGB(100, 240, 100) or Color3.fromRGB(200, 200, 200)
    btn.Text = "  " .. name
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = container

    local active = defaultState
    local function updateColor()
        btn.TextColor3 = (isToggle and active) and Color3.fromRGB(100, 240, 100) or Color3.fromRGB(200, 200, 200)
        task.defer(updateHUDArrayList)
    end

    local drawer = nil
    local floatingWin = nil
    local gear = nil

    local function updateBg()
        local isOpened = false
        if useSeparateWindow and floatingWin then
            isOpened = floatingWin.Visible
        elseif drawer then
            isOpened = drawer.Visible
        end
        if isOpened then
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            btn.BackgroundTransparency = 0.3
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.BackgroundTransparency = 0.5
        end
    end

    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.2
    end)
    btn.MouseLeave:Connect(function()
        updateBg()
    end)

    btn.MouseButton1Click:Connect(function()
        if isToggle then
            active = not active
            updateColor()
            if callback then callback(active) end
        else
            if callback then callback() end
        end
    end)

    local isTweening = false
    local function toggleDrawer()
        if isTweening then return end
        if useSeparateWindow and floatingWin then
            floatingWin.Visible = not floatingWin.Visible
            floatingWin:SetAttribute("UserOpen", floatingWin.Visible)
            updateBg()
            if gear then
                local targetRot = floatingWin.Visible and 90 or 0
                local targetCol = floatingWin.Visible and currentThemeColor or Color3.fromRGB(120, 120, 120)
                TweenService:Create(gear, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Rotation = targetRot,
                    TextColor3 = targetCol
                }):Play()
            end
        elseif drawer then
            local open = not drawer.Visible
            isTweening = true
            if open then
                drawer.AutomaticSize = Enum.AutomaticSize.None
                drawer.ClipsDescendants = true
                drawer.Size = UDim2.new(1, 0, 0, 0)
                drawer.Visible = true
                updateBg()

                local optionsFrame = drawer:FindFirstChild("optionsFrame")
                local targetHeight = 0
                if optionsFrame then
                    for _, child in ipairs(optionsFrame:GetChildren()) do
                        if child:IsA("Frame") then
                            targetHeight = targetHeight + child.Size.Y.Offset + 3
                        end
                    end
                end
                targetHeight = targetHeight + 6

                if gear then
                    TweenService:Create(gear, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Rotation = 90,
                        TextColor3 = currentThemeColor
                    }):Play()
                end

                local tween = TweenService:Create(drawer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, targetHeight)
                })
                tween.Completed:Connect(function()
                    drawer.AutomaticSize = Enum.AutomaticSize.Y
                    isTweening = false
                end)
                tween:Play()

                S.currentOptionsModule = name
            else
                drawer.AutomaticSize = Enum.AutomaticSize.None
                drawer.ClipsDescendants = true

                if gear then
                    TweenService:Create(gear, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Rotation = 0,
                        TextColor3 = Color3.fromRGB(120, 120, 120)
                    }):Play()
                end

                local tween = TweenService:Create(drawer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, 0)
                })
                tween.Completed:Connect(function()
                    drawer.Visible = false
                    updateBg()
                    isTweening = false
                end)
                tween:Play()

                if S.currentOptionsModule == name then S.currentOptionsModule = "" end
            end
        end
    end

    if populateOptionsFunc then
        if useSeparateWindow then
            local targetX = defaultX + 150
            if targetX > 900 then targetX = defaultX - (winWidth or 230) - 10 end
            local winFrame, contentFrame = createFloatingWindow(name, winWidth or 230, winHeight or 220, targetX, defaultY)
            floatingWin = winFrame
            populateOptionsFunc(contentFrame)
            adjustWindowSizeToContent(winFrame, contentFrame)

            winFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                updateBg()
                if gear then
                    local targetRot = winFrame.Visible and 90 or 0
                    local targetCol = winFrame.Visible and currentThemeColor or Color3.fromRGB(120, 120, 120)
                    TweenService:Create(gear, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Rotation = targetRot,
                        TextColor3 = targetCol
                    }):Play()
                end
            end)
        else
            drawer = Instance.new("Frame")
            drawer.Name = "drawer"
            drawer.Size = UDim2.new(1, 0, 0, 0)
            drawer.AutomaticSize = Enum.AutomaticSize.Y
            drawer.Position = UDim2.new(0, 0, 0, 20)
            drawer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            drawer.BackgroundTransparency = 0.3
            drawer.BorderSizePixel = 0
            drawer.Visible = false
            drawer.Parent = container

            local accent = Instance.new("Frame")
            accent.Size = UDim2.new(0, 2, 1, 0)
            accent.Position = UDim2.new(0, 2, 0, 0)
            accent.BackgroundColor3 = currentThemeColor
            accent.BorderSizePixel = 0
            accent.Parent = drawer
            table.insert(themeFills, accent)

            local optionsFrame = Instance.new("Frame")
            optionsFrame.Name = "optionsFrame"
            optionsFrame.Size = UDim2.new(1, -8, 0, 0)
            optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
            optionsFrame.Position = UDim2.new(0, 8, 0, 0)
            optionsFrame.BackgroundTransparency = 1
            optionsFrame.BorderSizePixel = 0
            optionsFrame.Parent = drawer

            local drawerLayout = Instance.new("UIListLayout")
            drawerLayout.Padding = UDim.new(0, 3)
            drawerLayout.Parent = optionsFrame

            local uipadding = Instance.new("UIPadding")
            uipadding.PaddingTop = UDim.new(0, 2)
            uipadding.PaddingBottom = UDim.new(0, 4)
            uipadding.Parent = optionsFrame

            populateOptionsFunc(optionsFrame)
        end

        gear = Instance.new("TextButton")
        gear.Size = UDim2.new(0, 20, 0, 20)
        gear.AnchorPoint = Vector2.new(0.5, 0.5)
        gear.Position = UDim2.new(1, -10, 0.5, 0)
        gear.BackgroundTransparency = 1
        gear.Font = Enum.Font.Gotham
        gear.TextSize = 10
        gear.TextColor3 = Color3.fromRGB(120, 120, 120)
        gear.Text = ">"
        gear.Parent = btn

        gear.MouseButton1Click:Connect(toggleDrawer)
    end

    btn.MouseButton2Click:Connect(toggleDrawer)

    moduleButtons[name] = { 
        Button = btn, 
        Container = container,
        Update = updateColor, 
        SetActive = function(val)
            active = val
            updateColor()
        end 
    }
end

-- Win global compatibility mock
local Win = {
    HUDLabel = hudTextLabel,
    ResetAllToggles = function()
        for _, mod in pairs(moduleButtons) do
            mod.SetActive(false)
        end
    end,
    SetAutoReinject = function(self, val, callback)
        -- mock
    end,
    SetOnClose = function(self, callback)
        -- mock
    end
}

-- Search filtering
local searchWin = getOrCreateWindow("Search", 860, 50)
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -10, 0, 22)
searchBox.Position = UDim2.new(0, 5, 0, 5)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 9
searchBox.TextColor3 = Color3.fromRGB(240, 240, 240)
searchBox.PlaceholderText = "Search modules..."
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchWin.List

local searchStroke = Instance.new("UIStroke")
searchStroke.Color = Color3.fromRGB(50, 50, 50)
searchStroke.Parent = searchBox

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 4)
searchCorner.Parent = searchBox

searchWin.List.Size = UDim2.new(1, 0, 0, 32)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local text = searchBox.Text:lower()
    for modName, item in pairs(moduleButtons) do
        if text == "" or modName:lower():find(text) then
            item.Container.Visible = true
        else
            item.Container.Visible = false
        end
    end
end)

-- ──────────────────────────────────────────────────────────────
--  NAVIGATION BAR, HUD OVERLAY, AND CUSTOM TAB PANELS
-- ──────────────────────────────────────────────────────────────
local navBar = Instance.new("Frame")
navBar.Size = UDim2.new(0, 600, 1, 0)
navBar.Position = UDim2.new(0.5, -300, 0, 0)
navBar.BackgroundTransparency = 1
navBar.Parent = topBar

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navLayout.Padding = UDim.new(0, 16)
navLayout.Parent = navBar

local settingsPanel, settingsContent = nil, nil

local function selectTab(tabName)
    activeTab = tabName
    for name, btn in pairs(tabButtons) do
        if name == tabName then
            btn.TextColor3 = currentThemeColor
            btn.Font = Enum.Font.GothamBold
        else
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Font = Enum.Font.Gotham
        end
    end
    
    local isModules = (tabName == "Modules")
    for catName, win in pairs(windows) do
        win.Frame.Visible = isModules
    end
    
    for _, win in ipairs(floatingWindows) do
        if isModules then
            win.Visible = win:GetAttribute("UserOpen") == true
        else
            win.Visible = false
        end
    end
    
    if settingsPanel then settingsPanel.Visible = (tabName == "Settings") end

    updateMenuBlur()
end

-- HUD Watermark setup
hudWatermark = Instance.new("TextLabel")
hudWatermark.Size = UDim2.new(0, 240, 0, 20)
hudWatermark.Position = UDim2.new(0, 10, 0, 30)
hudWatermark.BackgroundTransparency = 1
hudWatermark.Font = Enum.Font.GothamBold
hudWatermark.TextSize = 12
hudWatermark.TextColor3 = currentThemeColor
hudWatermark.TextXAlignment = Enum.TextXAlignment.Left
hudWatermark.Text = "WeAreSkidding <font color='#ffffff'>On Roblox</font>"
hudWatermark.RichText = true
hudWatermark.Visible = S.HUDWatermark
hudWatermark.Parent = screenGui

-- HUD Coordinates setup
hudCoords = Instance.new("TextLabel")
hudCoords.Size = UDim2.new(0, 240, 0, 20)
hudCoords.Position = UDim2.new(0, 10, 0, 46)
hudCoords.BackgroundTransparency = 1
hudCoords.Font = Enum.Font.Code
hudCoords.TextSize = 10
hudCoords.TextColor3 = Color3.fromRGB(200, 200, 200)
hudCoords.TextXAlignment = Enum.TextXAlignment.Left
hudCoords.Text = "XYZ: 0.0, 0.0, 0.0"
hudCoords.Visible = S.HUDCoords
hudCoords.Parent = screenGui

-- HUD ArrayList setup
hudArrayListFrame = Instance.new("Frame")
hudArrayListFrame.Size = UDim2.new(0, 200, 0, 400)
hudArrayListFrame.Position = UDim2.new(1, -205, 0, 30)
hudArrayListFrame.BackgroundTransparency = 1
hudArrayListFrame.BorderSizePixel = 0
hudArrayListFrame.Parent = screenGui

local arrayLayout = Instance.new("UIListLayout")
arrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
arrayLayout.VerticalAlignment = Enum.VerticalAlignment.Top
arrayLayout.Padding = UDim.new(0, 2)
arrayLayout.Parent = hudArrayListFrame

-- Drag Panels creation helper
local function createPanel(title, width, height)
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, width, 0, height)
    win.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    win.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Visible = false
    win.Parent = screenGui

    local winCorner = Instance.new("UICorner")
    winCorner.CornerRadius = UDim.new(0, 6)
    winCorner.Parent = win

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundColor3 = currentThemeColor
    header.BorderSizePixel = 0
    header.Parent = win
    table.insert(themeHeaders, header)
    addHeaderGradient(header)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -30, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 10
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title
    titleLbl.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -22, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 10
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.Parent = header
    closeBtn.MouseButton1Click:Connect(function()
        win.Visible = false
        selectTab("Modules")
    end)

    local content = Instance.new("ScrollingFrame")
    content.Name = "content"
    content.Size = UDim2.new(1, 0, 1, -22)
    content.Position = UDim2.new(0, 0, 0, 22)
    content.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    content.BackgroundTransparency = 0.15
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 2
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = win

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = content

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 40)
    stroke.Thickness = 1.2
    stroke.Parent = win

    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "resizeHandle"
    resizeHandle.Size = UDim2.new(0, 6, 0, 6)
    resizeHandle.Position = UDim2.new(1, -6, 1, -6)
    resizeHandle.BackgroundColor3 = currentThemeColor
    resizeHandle.BackgroundTransparency = 0.3
    resizeHandle.BorderSizePixel = 0
    resizeHandle.ZIndex = 10
    resizeHandle.Parent = win
    table.insert(themeFills, resizeHandle)

    makeResizable(win, resizeHandle)
    makeDraggable(win, header)

    win:SetAttribute("BaseWidth", width)
    win:SetAttribute("BaseHeight", height)

    local isScaling = false
    win:GetPropertyChangedSignal("Size"):Connect(function()
        if isScaling then return end
        isScaling = true

        local currentWidth = win.Size.X.Offset
        local baseWidth = win:GetAttribute("BaseWidth") or width
        if baseWidth > 0 then
            local scale = currentWidth / baseWidth
            autoScaleContent(win, scale)

            -- Recalculate content height dynamically
            local totalContentHeight = 0
            local count = 0
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("Frame") and child.Name ~= "resizeHandle" then
                    totalContentHeight = totalContentHeight + child.Size.Y.Offset
                    count = count + 1
                end
            end

            local listLayout = content:FindFirstChildOfClass("UIListLayout")
            local paddingVal = listLayout and listLayout.Padding.Offset or (4 * scale)

            local uiPadding = content:FindFirstChildOfClass("UIPadding")
            local padT = uiPadding and uiPadding.PaddingTop.Offset or (6 * scale)
            local padB = uiPadding and uiPadding.PaddingBottom.Offset or (6 * scale)

            local contentHeight = padT + padB + totalContentHeight + math.max(0, count - 1) * paddingVal + 2 * scale
            local headerHeight = 22 * scale
            local finalHeight = headerHeight + contentHeight

            finalHeight = math.clamp(finalHeight, 50 * scale, 400 * scale)
            win.Size = UDim2.new(0, currentWidth, 0, finalHeight)
        end
        isScaling = false
    end)

    return win, content
end

-- Create Settings Panel
settingsPanel, settingsContent = createPanel("Client Settings", 280, 350)

-- Section 1: Configuration Profiles
addSectionHeader(settingsContent, "Configuration Profiles")
addButtonOption(settingsContent, "Apply legit closet profile", function()
    Win:ResetAllToggles()
    S.WalkSpeed = 22
    S.JumpPower = 55
    S.ForceWalkSpeed = true
    S.ESPBoxes = true
    S.ESPTransparency = 0.9
    S.AimbotActive = true
    S.AimbotFOV = 40
    S.AimbotSmooth = 15
    S.ESPNames = true
    
    if moduleButtons["Speed Modification"] then moduleButtons["Speed Modification"].SetActive(true) end
    if moduleButtons["ESP Box Outlines"] then moduleButtons["ESP Box Outlines"].SetActive(true) end
    if moduleButtons["Aimbot"] then moduleButtons["Aimbot"].SetActive(true) end
    if moduleButtons["Show Player Names"] then moduleButtons["Show Player Names"].SetActive(true) end
    
    saveConfig()
    notify("Closet Legit profile applied!", Color3.fromRGB(46, 204, 113))
end)
addButtonOption(settingsContent, "Apply blatant flight profile", function()
    Win:ResetAllToggles()
    S.Fly = true
    S.NoClip = true
    S.InfJump = true
    S.WalkSpeed = 65
    S.JumpPower = 80
    S.ForceWalkSpeed = true
    S.ForceJumpPower = true
    S.ESPBoxes = true
    S.ESPHealth = true
    S.ESPNames = true
    S.ESPDistances = true
    
    if moduleButtons["Fly Mode"] then moduleButtons["Fly Mode"].SetActive(true) end
    if moduleButtons["NoClip Passes"] then moduleButtons["NoClip Passes"].SetActive(true) end
    if moduleButtons["Infinite Jump"] then moduleButtons["Infinite Jump"].SetActive(true) end
    if moduleButtons["Speed Modification"] then moduleButtons["Speed Modification"].SetActive(true) end
    if moduleButtons["Jump Hack Strength"] then moduleButtons["Jump Hack Strength"].SetActive(true) end
    if moduleButtons["ESP Box Outlines"] then moduleButtons["ESP Box Outlines"].SetActive(true) end
    if moduleButtons["Show Player Names"] then moduleButtons["Show Player Names"].SetActive(true) end
    if moduleButtons["Show Health Text"] then moduleButtons["Show Health Text"].SetActive(true) end
    
    flyOn()
    saveConfig()
    notify("Blatant profile applied!", Color3.fromRGB(241, 196, 15))
end)
addButtonOption(settingsContent, "Apply rage combat profile", function()
    Win:ResetAllToggles()
    S.Fly = true
    S.NoClip = true
    S.KillAura = true
    S.GodMode = true
    S.AimbotActive = true
    S.AimbotFOV = 600
    S.AimbotSmooth = 1
    S.HitboxExpanded = true
    S.HitboxSize = 25
    S.InstantPrompts = true
    S.AntiVoid = true
    
    if moduleButtons["Fly Mode"] then moduleButtons["Fly Mode"].SetActive(true) end
    if moduleButtons["NoClip Passes"] then moduleButtons["NoClip Passes"].SetActive(true) end
    if moduleButtons["Kill Aura"] then moduleButtons["Kill Aura"].SetActive(true) end
    if moduleButtons["God Mode"] then moduleButtons["God Mode"].SetActive(true) end
    if moduleButtons["Aimbot"] then moduleButtons["Aimbot"].SetActive(true) end
    if moduleButtons["Hitbox Expansion"] then moduleButtons["Hitbox Expansion"].SetActive(true) end
    if moduleButtons["Instant Prompts"] then moduleButtons["Instant Prompts"].SetActive(true) end
    if moduleButtons["Anti-Void Net"] then moduleButtons["Anti-Void Net"].SetActive(true) end
    
    flyOn()
    if LP.Character then applyGodMode(LP.Character) end
    updateHitboxes()
    saveConfig()
    notify("Rage profile applied!", Color3.fromRGB(218, 38, 38))
end)

-- Section 2: UI & HUD Customization
addSectionHeader(settingsContent, "UI & HUD Customization")
addDropdownOption(settingsContent, "Interface Theme Color", {"Purple", "Red", "Green", "Blue", "Yellow", "Cyan", "Pink", "Orange"}, table.find({"Purple", "Red", "Green", "Blue", "Yellow", "Cyan", "Pink", "Orange"}, S.ThemeColor) or 1, function(_, opt)
    applyThemeColor(opt)
    saveConfig()
end)
addKeybindOption(settingsContent, "Menu Toggle Keybind", S.UIToggleKey or Enum.KeyCode.RightControl, function(k)
    S.UIToggleKey = k
    saveConfig()
    notify("UI Toggle Keybind set to: " .. k.Name, Color3.fromRGB(50, 195, 75))
end)
addToggleOption(settingsContent, "Show Toasts Enabled", S.ToastEnabled, function(v)
    S.ToastEnabled = v
    saveConfig()
end)
addToggleOption(settingsContent, "Display Client Watermark", S.HUDWatermark, function(v)
    S.HUDWatermark = v
    hudWatermark.Visible = v
    saveConfig()
end)
addToggleOption(settingsContent, "Display Player Coordinates", S.HUDCoords, function(v)
    S.HUDCoords = v
    hudCoords.Visible = v
    saveConfig()
end)
addToggleOption(settingsContent, "Display Active ArrayList", S.HUDArrayList, function(v)
    S.HUDArrayList = v
    updateHUDArrayList()
    saveConfig()
end)

-- Section 3: Targets & Input Settings
addSectionHeader(settingsContent, "Targets & Input Settings")
addTextboxOption(settingsContent, "Specify Target / Friend", "Username", function(txt)
    if txt == "" then return end
    notify("Target lock set to: " .. txt, Color3.fromRGB(50, 195, 75))
end)
addButtonOption(settingsContent, "Clear Current Friends Lists", function()
    notify("Friends lists reset", Color3.fromRGB(218, 38, 38))
end)
addTextboxOption(settingsContent, "Configure Macro Text", "Say something...", function(txt)
    S.MacroText = txt
    saveConfig()
    notify("Macro text configured!", Color3.fromRGB(50, 195, 75))
end)
addKeybindOption(settingsContent, "Trigger Macro Key", S.MacroKey or Enum.KeyCode.H, function(k)
    S.MacroKey = k
    saveConfig()
    notify("Macro trigger set to: " .. k.Name, Color3.fromRGB(50, 195, 75))
end)

-- Section 4: Config Storage & Client Controls
addSectionHeader(settingsContent, "Config & Client Controls")
addTextboxOption(settingsContent, "Configuration Name", "utility_hub_config", function(txt)
    -- Reserved
end)
addButtonOption(settingsContent, "Save Current Settings", function()
    saveConfig()
    notify("Configuration saved successfully!", Color3.fromRGB(50, 195, 75))
end)
addButtonOption(settingsContent, "Load Stored Settings", function()
    loadConfig()
    notify("Configuration loaded successfully!", Color3.fromRGB(50, 195, 75))
end)
addButtonOption(settingsContent, "Reset Settings to Default", function()
    Win:ResetAllToggles()
    S.WalkSpeed = 16
    S.JumpPower = 50
    S.InfJump = false
    S.BHop = false
    S.AirWalk = false
    S.NoClip = false
    S.Fly = false
    S.FlySpeed = 60
    S.ESPBoxes = false
    S.ESPTracers = false
    S.ESPNames = false
    S.ESPHealth = false
    S.ESPDistances = false
    S.ESPTeamCheck = false
    S.AimbotActive = false
    S.AntiAFK = false
    S.AutoRejoin = false
    S.GravityEnabled = false
    S.CustomGravity = 196.2
    S.ThemeColor = "Purple"
    applyThemeColor("Purple")
    saveConfig()
    notify("All settings reset to default!", Color3.fromRGB(218, 38, 38))
end)
addButtonOption(settingsContent, "Destruct Client GUI Completely", function()
    cleanupAll()
end)

adjustWindowSizeToContent(settingsPanel, settingsContent)

-- Tab buttons creation
local tabs = {"Modules", "Settings"}
for _, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 95, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextColor3 = (tabName == activeTab) and currentThemeColor or Color3.fromRGB(200, 200, 200)
    if tabName == activeTab then btn.Font = Enum.Font.GothamBold end
    btn.Text = tabName
    btn.Parent = navBar
    
    btn.MouseEnter:Connect(function()
        if activeTab ~= tabName then
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= tabName then
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        selectTab(tabName)
    end)
    
    tabButtons[tabName] = btn
end

selectTab("Modules")

-- ──────────────────────────────────────────────────────────────
--  REGISTER COMBAT MODULES (DefaultX = 20)
-- ──────────────────────────────────────────────────────────────
registerModule("Combat", "God Mode", 20, 50, true, S.GodMode, function(v)
    S.GodMode = v
    if v then
        if LP.Character then applyGodMode(LP.Character) end
    else
        disableGodMode()
    end
    saveConfig()
end)

registerModule("Combat", "Kill Aura", 20, 50, true, S.KillAura, function(v)
    S.KillAura = v
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Range (studs)", 5, 50, S.KillAuraRange, function(v)
        S.KillAuraRange = v
        saveConfig()
    end)
end, false)

registerModule("Combat", "Auto Clicker", 20, 50, true, S.AutoClicker, function(v)
    S.AutoClicker = v
    saveConfig()
end)

registerModule("Combat", "Aimbot", 20, 50, true, S.AimbotActive, function(v)
    S.AimbotActive = v
    notify("Aimbot " .. (v and "Enabled (Hold Right Click)" or "Disabled"), Color3.fromRGB(50, 195, 75))
    saveConfig()
end, function(drawer)
    addToggleOption(drawer, "Aimbot Team Check", S.AimbotTeamCheck, function(v)
        S.AimbotTeamCheck = v
        saveConfig()
    end)
    addToggleOption(drawer, "Draw FOV Circle", S.AimbotShowFOV, function(v)
        S.AimbotShowFOV = v
        saveConfig()
    end)
    addSliderOption(drawer, "FOV Circle Radius", 20, 600, S.AimbotFOV, function(v)
        S.AimbotFOV = v
        saveConfig()
    end)
    addSliderOption(drawer, "Aimbot Smoothness", 1, 30, S.AimbotSmooth, function(v)
        S.AimbotSmooth = v
        saveConfig()
    end)
    addToggleOption(drawer, "Wall Visibility Check", S.AimbotVisibility, function(v)
        S.AimbotVisibility = v
        saveConfig()
    end)
    addDropdownOption(drawer, "Locked Target Part", {"Head", "Torso", "Random"}, table.find({"Head", "Torso", "Random"}, S.AimbotPart) or 1, function(_, opt)
        S.AimbotPart = opt
        saveConfig()
    end)
end, false)

registerModule("Combat", "Fling Player", 20, 50, true, S.FlingActive, function(v)
    S.FlingActive = v
    if v then
        S.FlingAllActive = false
        local mod = moduleButtons["Fling All"]
        if mod then mod.SetActive(false) end
    else
        S.FlingTarget = nil
        task.spawn(function()
            local hrp = getHRP()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                if S.LastSafePosition then
                    hrp.CFrame = S.LastSafePosition
                end
                task.wait(0.05)
                if hrp:IsDescendantOf(game) then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)
    end
    saveConfig()
end, function(drawer)
    addTextboxOption(drawer, "Fling Target Player", "Username", function(txt)
        if txt == "" then
            S.FlingTarget = nil
            notify("Fling target cleared", Color3.fromRGB(218, 38, 38))
            return
        end
        local found = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and (p.Name:lower():find(txt:lower()) or p.DisplayName:lower():find(txt:lower())) then
                found = p
                break
            end
        end
        if found then
            S.FlingTarget = found
            notify("Fling target set to: " .. found.DisplayName, Color3.fromRGB(50, 195, 75))
        else
            S.FlingTarget = nil
            notify("Player not found: " .. txt, Color3.fromRGB(218, 38, 38))
        end
    end)
end, false)

registerModule("Combat", "Fling All", 20, 50, true, S.FlingAllActive, function(v)
    S.FlingAllActive = v
    if v then
        S.FlingActive = false
        local mod = moduleButtons["Fling Player"]
        if mod then mod.SetActive(false) end
    else
        flingAllTarget = nil
        task.spawn(function()
            local hrp = getHRP()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                if S.LastSafePosition then
                    hrp.CFrame = S.LastSafePosition
                end
                task.wait(0.05)
                if hrp:IsDescendantOf(game) then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)
    end
    saveConfig()
end, nil, false)


-- ──────────────────────────────────────────────────────────────
--  REGISTER PLAYER MODULES (DefaultX = 160)
-- ──────────────────────────────────────────────────────────────
registerModule("Player", "Reset Character", 160, 50, false, false, function()
    local hum = getHum()
    if hum then hum.Health = 0 notify("Character reset!", Color3.fromRGB(218, 38, 38)) end
end)

registerModule("Player", "Force Shift Lock", 160, 50, true, S.ForceShiftLock, function(v)
    S.ForceShiftLock = v
    pcall(function() LP.DevEnableMouseLock = v end)
    saveConfig()
end)

registerModule("Player", "Unlock Max Zoom", 160, 50, false, false, function()
    LP.CameraMaxZoomDistance = 100000
    notify("Camera zoom limits unlocked infinitely!", Color3.fromRGB(50, 195, 75))
end)

registerModule("Player", "Give BTools", 160, 50, false, false, function()
    for i = 1, 4 do
        local t = Instance.new("HopperBin")
        t.BinType = i
        t.Parent = LP.Backpack
    end
    notify("HopperBins building tools granted to inventory!", Color3.fromRGB(50, 195, 75))
end)

registerModule("Player", "Click-Delete", 160, 50, true, S.ClickDelete, function(v)
    S.ClickDelete = v
    saveConfig()
end)

registerModule("Player", "Click-Teleport", 160, 50, true, S.ClickTeleport, function(v)
    S.ClickTeleport = v
    saveConfig()
end)

registerModule("Player", "Anti-AFK", 160, 50, true, S.AntiAFK, function(v)
    S.AntiAFK = v
    saveConfig()
end)

registerModule("Player", "Auto-Rejoin", 160, 50, true, S.AutoRejoin, function(v)
    S.AutoRejoin = v
    saveConfig()
end)

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

registerModule("Player", "Spectate & Freecam", 160, 50, true, false, function(v)
    if not v then resetCameraToSelf() end
end, function(drawer)
    local rName = addInfoRowOption(drawer, "Viewing Target Name", currentSpectateTarget and currentSpectateTarget.DisplayName or "--")
    local rHp = addInfoRowOption(drawer, "Target Health", "--")
    local rTeam = addInfoRowOption(drawer, "Target Team", "--")
    
    spectateStatsLabels.name = rName.Label
    spectateStatsLabels.hp = rHp.Label
    spectateStatsLabels.team = rTeam.Label

    addToggleOption(drawer, "Auto Follow Player", S.FollowActive, function(v)
        S.FollowActive = v
        S.FollowTarget = currentSpectateTarget
        saveConfig()
    end)

    addButtonOption(drawer, "Teleport to Nearest Player", function()
        local myHRP = getHRP()
        if not myHRP then notify("Self root part not found!", Color3.fromRGB(218, 38, 38)) return end
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

    addButtonOption(drawer, "Teleport to Random Player", function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart
                if root then table.insert(list, p) end
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

    addSliderOption(drawer, "Freecam Speed", 10, 300, S.FreecamSpeed, function(v)
        S.FreecamSpeed = v
        saveConfig()
    end)

    addToggleOption(drawer, "Freecam Active Mode", isFreecam, function(v)
        if v then enableFreecam() else disableFreecam() end
    end)

    -- Custom scrolling list of players
    local listContainer = addCustomFrameOption(drawer, 100)
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -8, 0, 14)
    box.Position = UDim2.new(0, 4, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Gotham
    box.TextSize = 7
    box.TextColor3 = Color3.fromRGB(240, 240, 240)
    box.PlaceholderText = "Filter player list..."
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = listContainer

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -16)
    scroll.Position = UDim2.new(0, 4, 0, 16)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = listContainer

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll

    local function renderPlayers()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        local filter = box.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local formatted = p.DisplayName .. " (@" .. p.Name .. ")"
                if filter == "" or formatted:lower():find(filter) then
                    local card = Instance.new("Frame")
                    card.Size = UDim2.new(1, -2, 0, 16)
                    card.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    card.BorderSizePixel = 0
                    card.Parent = scroll

                    local nameL = Instance.new("TextLabel")
                    nameL.Size = UDim2.new(0.5, 0, 1, 0)
                    nameL.Position = UDim2.new(0, 2, 0, 0)
                    nameL.BackgroundTransparency = 1
                    nameL.Font = Enum.Font.GothamMedium
                    nameL.TextSize = 7
                    nameL.TextColor3 = Color3.fromRGB(220, 220, 220)
                    nameL.TextXAlignment = Enum.TextXAlignment.Left
                    nameL.Text = p.DisplayName
                    nameL.Parent = card

                    local tp = Instance.new("TextButton")
                    tp.Size = UDim2.new(0, 20, 0, 12)
                    tp.Position = UDim2.new(1, -44, 0.5, -6)
                    tp.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                    tp.BorderSizePixel = 0
                    tp.Font = Enum.Font.GothamBold
                    tp.TextSize = 6
                    tp.TextColor3 = Color3.fromRGB(255, 255, 255)
                    tp.Text = "TP"
                    tp.Parent = card

                    tp.MouseButton1Click:Connect(function()
                        local targetHRP = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP and teleportToHRP(targetHRP) then
                            notify("Teleported to " .. p.DisplayName, Color3.fromRGB(50, 195, 75))
                        else
                            notify("Target not loaded", Color3.fromRGB(218, 38, 38))
                        end
                    end)

                    local view = Instance.new("TextButton")
                    view.Size = UDim2.new(0, 22, 0, 12)
                    view.Position = UDim2.new(1, -22, 0.5, -6)
                    local isViewing = (currentSpectateTarget == p)
                    view.BackgroundColor3 = isViewing and Color3.fromRGB(218, 38, 38) or Color3.fromRGB(40, 40, 40)
                    view.BorderSizePixel = 0
                    view.Font = Enum.Font.GothamBold
                    view.TextSize = 6
                    view.TextColor3 = Color3.fromRGB(255, 255, 255)
                    view.Text = isViewing and "UNVIEW" or "VIEW"
                    view.Parent = card

                    view.MouseButton1Click:Connect(function()
                        if currentSpectateTarget == p then
                            spectatePlayer(nil)
                        else
                            spectatePlayer(p)
                        end
                        renderPlayers()
                    end)
                end
            end
        end
    end

    box:GetPropertyChangedSignal("Text"):Connect(renderPlayers)
    local addedConn = Players.PlayerAdded:Connect(renderPlayers)
    local removedConn = Players.PlayerRemoving:Connect(function(p)
        if currentSpectateTarget == p then
            spectatePlayer(nil)
        end
        renderPlayers()
    end)
    table.insert(S.Connections, addedConn)
    table.insert(S.Connections, removedConn)
    renderPlayers()
end, true, 200, 280)


-- ──────────────────────────────────────────────────────────────
--  REGISTER MOVEMENT MODULES (DefaultX = 300)
-- ──────────────────────────────────────────────────────────────
registerModule("Movement", "Speed Modification", 300, 50, true, S.ForceWalkSpeed, function(v)
    S.ForceWalkSpeed = v
    local hum = getHum()
    if hum then hum.WalkSpeed = v and S.WalkSpeed or gameDefaultSpeed end
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "WalkSpeed Speed", 16, 250, S.WalkSpeed, function(v)
        S.WalkSpeed = v
        local hum = getHum()
        if hum then hum.WalkSpeed = v end
        saveConfig()
    end)
    addToggleOption(drawer, "Always Enforce WalkSpeed", S.ForceWalkSpeed, function(v)
        S.ForceWalkSpeed = v
        saveConfig()
    end)
end, false)

registerModule("Movement", "Sprint Speed Boost", 300, 50, true, S.SprintEnabled, function(v)
    S.SprintEnabled = v
    if not v then
        local hum = getHum()
        if hum then hum.WalkSpeed = (S.ForceWalkSpeed and S.WalkSpeed) or gameDefaultSpeed end
    end
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Sprint Speed factor", 20, 150, S.SprintSpeed, function(v)
        S.SprintSpeed = v
        saveConfig()
    end)
end, false)

registerModule("Movement", "Jump Hack Strength", 300, 50, true, S.ForceJumpPower, function(v)
    S.ForceJumpPower = v
    local hum = getHum()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = v and S.JumpPower or 50
    end
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "JumpPower Strength", 50, 350, S.JumpPower, function(v)
        S.JumpPower = v
        local hum = getHum()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
        saveConfig()
    end)
    addToggleOption(drawer, "Always Enforce JumpPower", S.ForceJumpPower, function(v)
        S.ForceJumpPower = v
        saveConfig()
    end)
end, false)

registerModule("Movement", "Fly Mode", 300, 50, true, S.Fly, function(v)
    S.Fly = v
    if v then flyOn() else flyOff() end
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Fly Speed factor", 10, 300, S.FlySpeed, function(v)
        S.FlySpeed = v
        saveConfig()
    end)
end, false)

registerModule("Movement", "Infinite Jump", 300, 50, true, S.InfJump, function(v)
    S.InfJump = v
    saveConfig()
end)

registerModule("Movement", "Auto Bunnyhop", 300, 50, true, S.BHop, function(v)
    S.BHop = v
    saveConfig()
end)

registerModule("Movement", "Air Walk Platform", 300, 50, true, S.AirWalk, function(v)
    S.AirWalk = v
    saveConfig()
end)

registerModule("Movement", "NoClip Passes", 300, 50, true, S.NoClip, function(v)
    S.NoClip = v
    saveConfig()
end)

registerModule("Movement", "Blink Teleport", 300, 50, false, false, nil, function(drawer)
    addSliderOption(drawer, "Blink Range (studs)", 5, 150, S.BlinkDistance, function(v)
        S.BlinkDistance = v
        saveConfig()
    end)
    addDropdownOption(drawer, "Blink Vector Direction", {"Camera Look", "Movement Direction"}, S.BlinkDirection == "Movement Direction" and 2 or 1, function(_, opt)
        S.BlinkDirection = opt
        saveConfig()
    end)
    addKeybindOption(drawer, "Blink Key Bind", S.BlinkKey, function(k)
        S.BlinkKey = k
        saveConfig()
    end)
end, false)

registerModule("Movement", "Ghost State Mode", 300, 50, true, S.GhostMode, function(v)
    S.GhostMode = v
    if v then enableGhostMode() else disableGhostMode() end
    saveConfig()
end, function(drawer)
    addToggleOption(drawer, "Teleport to Ghost End", S.GhostTeleportToEnd, function(v)
        S.GhostTeleportToEnd = v
        saveConfig()
    end)
end, false)

registerModule("Movement", "Float Mode", 300, 50, true, S.Float, function(v)
    toggleFloat(v)
    saveConfig()
end)

registerModule("Movement", "Water Walk", 300, 50, true, S.WaterWalk, function(v)
    toggleWaterWalk(v)
    saveConfig()
end)

registerModule("Movement", "Tall Animations", 300, 50, true, S.TallAnim, function(v)
    S.TallAnim = v
    if v and LP.Character then
        applyTallAnimations(LP.Character)
    elseif LP.Character then
        revertTallAnimations(LP.Character)
    end
    saveConfig()
end)

registerModule("Movement", "Player Spin", 300, 50, true, S.Spin, function(v)
    S.Spin = v
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Spin Speed", 1, 100, S.SpinSpeed, function(v)
        S.SpinSpeed = v
        saveConfig()
    end)
end, false)

registerModule("Movement", "Gravity Modifier", 300, 50, true, S.GravityEnabled, function(v)
    S.GravityEnabled = v
    if not v then Workspace.Gravity = 196.2 end
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Gravity Level", 0, 500, S.CustomGravity, function(v)
        S.CustomGravity = v
        saveConfig()
    end)
end, false)

registerModule("Movement", "Anti-Anchor", 300, 50, true, S.AntiAnchor, function(v)
    S.AntiAnchor = v
    saveConfig()
end)

registerModule("Movement", "Anti-Sit", 300, 50, true, S.AntiSit, function(v)
    S.AntiSit = v
    if v then
        local hum = getHum()
        if hum then hum.Sit = false end
    end
    saveConfig()
end)


-- ──────────────────────────────────────────────────────────────
--  REGISTER RENDER MODULES (DefaultX = 440)
-- ──────────────────────────────────────────────────────────────
registerModule("Render", "ESP Box Outlines", 440, 50, true, S.ESPBoxes, function(v)
    S.ESPBoxes = v
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Box Transparency (%)", 0, 100, S.ESPTransparency * 100, function(v)
        S.ESPTransparency = v / 100
        saveConfig()
    end)
    addDropdownOption(drawer, "ESP Scheme Color", {"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}, table.find({"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}, S.ESPColor) or 1, function(_, opt)
        S.ESPColor = opt
        saveConfig()
    end)
end, false)

registerModule("Render", "ESP Tracer Lines", 440, 50, true, S.ESPTracers, function(v)
    S.ESPTracers = v
    saveConfig()
end, function(drawer)
    addDropdownOption(drawer, "ESP Tracer Origin", {"Bottom", "Center", "Top"}, table.find({"Bottom", "Center", "Top"}, S.TracerOrigin) or 1, function(_, opt)
        S.TracerOrigin = opt
        saveConfig()
    end)
end, false)

registerModule("Render", "Show Player Names", 440, 50, true, S.ESPNames, function(v)
    S.ESPNames = v
    saveConfig()
end)

registerModule("Render", "Show Health Text", 440, 50, true, S.ESPHealth, function(v)
    S.ESPHealth = v
    saveConfig()
end)

registerModule("Render", "Show Distance Text", 440, 50, true, S.ESPDistances, function(v)
    S.ESPDistances = v
    saveConfig()
end)

registerModule("Render", "Skip Teammates", 440, 50, true, S.ESPTeamCheck, function(v)
    S.ESPTeamCheck = v
    saveConfig()
end)

registerModule("Render", "Heads-Up Overheads", 440, 50, true, S.OverheadInfo, function(v)
    S.OverheadInfo = v
    refreshOverheads()
    saveConfig()
end)

registerModule("Render", "Hitbox Expansion", 440, 50, true, S.HitboxExpanded, function(v)
    S.HitboxExpanded = v
    updateHitboxes()
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Hitbox Size (studs)", 2, 30, S.HitboxSize, function(v)
        S.HitboxSize = v
        updateHitboxes()
        saveConfig()
    end)
    addToggleOption(drawer, "Hitbox Team Check", S.HitboxTeamCheck, function(v)
        S.HitboxTeamCheck = v
        updateHitboxes()
        saveConfig()
    end)
    addSliderOption(drawer, "Hitbox Transparency (%)", 0, 100, S.HitboxTransparency * 100, function(v)
        S.HitboxTransparency = v / 100
        updateHitboxes()
        saveConfig()
    end)
end, false)

registerModule("Render", "Map X-Ray", 440, 50, true, S.MapXray, function(v)
    toggleMapXray(v)
    saveConfig()
end)

registerModule("Render", "Clear Vision", 440, 50, true, S.ClearVision, function(v)
    toggleClearVision(v)
    saveConfig()
end)

registerModule("Render", "No 3D Rendering", 440, 50, true, S.No3DRender, function(v)
    S.No3DRender = v
    pcall(function() RunService:Set3dRenderingEnabled(not v) end)
    saveConfig()
end)

registerModule("Render", "Lag Reducer", 440, 50, true, S.GraphicsReducer, function(v)
    toggleGraphicsReducer(v)
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "FPS Limit Cap", 15, 360, S.FPSCap, function(v)
        S.FPSCap = v
        pcall(function() if setfpscap then setfpscap(v) end end)
        saveConfig()
    end)
end, false)

registerModule("Render", "FullBright Mode", 440, 50, true, S.FullBright, function(v)
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

registerModule("Render", "Time of Day Cycle", 440, 50, true, S.TimeCycle, function(v)
    S.TimeCycle = v
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Time of Day (Hours)", 0, 24, S.TimeOfDay or 14, function(v)
        S.TimeOfDay = v
        Lighting.ClockTime = v
        saveConfig()
    end)
    addToggleOption(drawer, "Auto Cinematic Time Cycle", S.TimeCycle, function(v)
        S.TimeCycle = v
        saveConfig()
    end)
    addSliderOption(drawer, "Time Cycle speed rate", 1, 10, S.TimeCycleSpeed, function(v)
        S.TimeCycleSpeed = v
        saveConfig()
    end)
end, false)

registerModule("Render", "Field of View", 440, 50, false, false, nil, function(drawer)
    addSliderOption(drawer, "Camera FOV", 10, 120, S.CameraFOV, function(v)
        S.CameraFOV = v
        local camera = Workspace.CurrentCamera
        if camera then camera.FieldOfView = v end
        saveConfig()
    end)
end, false)


-- ──────────────────────────────────────────────────────────────
--  REGISTER WORLD MODULES (DefaultX = 580)
-- ──────────────────────────────────────────────────────────────
registerModule("World", "Instant Prompts", 580, 50, true, S.InstantPrompts, function(v)
    S.InstantPrompts = v
    if v then
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then p.HoldDuration = 0 end
        end
    end
    saveConfig()
end)

registerModule("World", "Fire CD Detectors", 580, 50, false, false, function()
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

registerModule("World", "Auto-Trigger Prompts", 580, 50, true, S.AutoInteract, function(v)
    S.AutoInteract = v
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Trigger Radius (studs)", 5, 50, S.AutoInteractRadius, function(v)
        S.AutoInteractRadius = v
        saveConfig()
    end)
end, false)

registerModule("World", "Tool Magnet", 580, 50, true, S.ToolMagnet, function(v)
    S.ToolMagnet = v
    saveConfig()
end)

registerModule("World", "Auto-Jump Edges", 580, 50, true, S.AutoJump, function(v)
    S.AutoJump = v
    saveConfig()
end)

registerModule("World", "Anti-Fling System", 580, 50, true, S.AntiFling, function(v)
    S.AntiFling = v
    saveConfig()
end)

registerModule("World", "Save Current Location", 580, 50, false, false, function()
    local hrp = getHRP()
    if hrp then
        S.SavedWaypointCF = hrp.CFrame
        notify("Current location locked!", Color3.fromRGB(50, 195, 75))
    else
        notify("HumanoidRootPart not found", Color3.fromRGB(218, 38, 38))
    end
end)

registerModule("World", "Warp to Saved Location", 580, 50, false, false, function()
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

registerModule("World", "Destroy Killbricks", 580, 50, false, false, function()
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

registerModule("World", "Destroy Seats", 580, 50, false, false, function()
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

registerModule("World", "Anti-Void Net", 580, 50, true, S.AntiVoid, function(v)
    S.AntiVoid = v
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Anti-Void Height Y Offset", -2000, -100, S.AntiVoidY, function(v)
        S.AntiVoidY = v
        saveConfig()
    end)
end, false)


-- ──────────────────────────────────────────────────────────────
--  REGISTER MISC MODULES (DefaultX = 720)
-- ──────────────────────────────────────────────────────────────
registerModule("Misc", "Server Controls", 720, 50, false, false, nil, function(drawer)
    addButtonOption(drawer, "Rejoin Instance", function()
        notify("Rejoining server instance...", Color3.fromRGB(218, 170, 42))
        setupAutoReinject()
        task.delay(0.5, function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end)
    end)
    
    addButtonOption(drawer, "Standard Server Hop", teleportToRandom)
    addButtonOption(drawer, "Join Random Server", teleportToRandom)
    addButtonOption(drawer, "Join Lowest Population", teleportToLowestPop)
    addButtonOption(drawer, "Join Highest Population", teleportToHighestPop)
    addButtonOption(drawer, "Copy Server JobId", function()
        local setclip = setclipboard or writeclipboard or toclipboard or print
        pcall(function() setclip(game.JobId) end)
        notify("Server JobId copied to clipboard!", Color3.fromRGB(50, 195, 75))
    end)

    local rRegion = addInfoRowOption(drawer, "Region Location", "Loading...")
    local rPing = addInfoRowOption(drawer, "Connection Ping", "--")
    local rPlayers = addInfoRowOption(drawer, "Player Count Status", "--")
    local rAge = addInfoRowOption(drawer, "Instance Uptime Age", "--")

    serverStatsLabels.region = rRegion.Label
    serverStatsLabels.ping = rPing.Label
    serverStatsLabels.players = rPlayers.Label
    serverStatsLabels.age = rAge.Label

    S.regionLabel = { Text = "Roblox Cloud (" .. (game.JobId ~= "" and game.JobId:sub(1, 8) or "Studio") .. ")" }
    S.pingLabel = { Text = "--" }
    S.playersLabel = { Text = "--" }
    S.ageLabel = { Text = "--" }
end, true, 200, 240)

local function rebuildFavorites(scroll, filter)
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    for idx, map in ipairs(S.FavoriteMaps) do
        local matches = true
        if filter and filter ~= "" then
            matches = map.name:lower():find(filter:lower()) or tostring(map.id):find(filter)
        end
        
        if matches then
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -2, 0, 24)
            card.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            card.BorderSizePixel = 0
            card.Parent = scroll
            
            local nameL = Instance.new("TextLabel")
            nameL.Text = map.name
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 7
            nameL.TextColor3 = Color3.fromRGB(230, 230, 230)
            nameL.BackgroundTransparency = 1
            nameL.Position = UDim2.new(0, 2, 0, 1)
            nameL.Size = UDim2.new(0.5, 0, 0, 10)
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Parent = card
            
            local detailsL = Instance.new("TextLabel")
            detailsL.Text = "Last: " .. (map.lastPlayed or "Never")
            detailsL.Font = Enum.Font.Gotham
            detailsL.TextSize = 6
            detailsL.TextColor3 = Color3.fromRGB(120, 120, 120)
            detailsL.BackgroundTransparency = 1
            detailsL.Position = UDim2.new(0, 2, 0, 11)
            detailsL.Size = UDim2.new(0.5, 0, 0, 10)
            detailsL.TextXAlignment = Enum.TextXAlignment.Left
            detailsL.Parent = card
            
            local jb = Instance.new("TextButton")
            jb.Text = "JOIN"
            jb.Font = Enum.Font.GothamBold
            jb.TextSize = 7
            jb.TextColor3 = Color3.fromRGB(255, 255, 255)
            jb.BackgroundColor3 = Color3.fromRGB(218, 38, 38)
            jb.Size = UDim2.new(0, 26, 0, 12)
            jb.Position = UDim2.new(1, -44, 0.5, -6)
            jb.Parent = card
            
            jb.MouseButton1Click:Connect(function()
                notify("Joining fav: " .. map.name, Color3.fromRGB(218, 170, 42))
                map.lastPlayed = os.date("%Y-%m-%d %H:%M")
                saveFavorites()
                rebuildFavorites(scroll, filter)
                task.delay(0.3, function()
                    TeleportService:Teleport(map.id, LP)
                end)
            end)
            
            local rb = Instance.new("TextButton")
            rb.Text = "X"
            rb.Font = Enum.Font.GothamBold
            rb.TextSize = 8
            rb.TextColor3 = Color3.fromRGB(218, 38, 38)
            rb.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            rb.Size = UDim2.new(0, 14, 0, 12)
            rb.Position = UDim2.new(1, -16, 0.5, -6)
            rb.Parent = card
            
            rb.MouseButton1Click:Connect(function()
                table.remove(S.FavoriteMaps, idx)
                saveFavorites()
                rebuildFavorites(scroll, filter)
                notify("Experience removed from list", Color3.fromRGB(218, 38, 38))
            end)
        end
    end
end

registerModule("Misc", "Favorites Manager", 720, 50, false, false, nil, function(drawer)
    addTextboxOption(drawer, "Save Place ID to Favorites", "Place ID", function(txt)
        local pid = tonumber(txt:match("%d+"))
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
            notify("Saved: " .. gameName, Color3.fromRGB(50, 195, 75))
        end)
    end)

    local frame = addCustomFrameOption(drawer, 80)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, 0)
    scroll.Position = UDim2.new(0, 4, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll

    rebuildFavorites(scroll)
end, true, 200, 200)

local function rebuildFriends(scroll)
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local scale = 1.0
    local winFrame = findWindowFrame(scroll)
    if winFrame then
        local baseW = winFrame:GetAttribute("BaseWidth") or winFrame.Size.X.Offset
        if baseW > 0 then
            scale = winFrame.Size.X.Offset / baseW
        end
    end

    task.spawn(function()
        local ok, onlineFriends = pcall(function() return LP:GetFriendsOnline(200) end)
        if not ok or not onlineFriends then
            local empty = Instance.new("TextLabel")
            empty.Text = "Failed to query friends."
            empty.Font = Enum.Font.Gotham
            empty.TextSize = math.clamp(math.round(8 * scale), 7, 24)
            empty.Size = UDim2.new(1, 0, 0, 14 * scale)
            empty:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 14))
            empty:SetAttribute("BasePos", UDim2.new(0, 0, 0, 0))
            empty:SetAttribute("BaseTextSize", 8)
            empty.TextColor3 = Color3.fromRGB(120, 120, 120)
            empty.BackgroundTransparency = 1
            empty.Parent = scroll
            return
        end

        for _, item in ipairs(onlineFriends) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -2, 0, 24 * scale)
            card:SetAttribute("BaseSize", UDim2.new(1, -2, 0, 24))
            card:SetAttribute("BasePos", UDim2.new(0, 0, 0, 0))
            card.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            card.BorderSizePixel = 0
            card.Parent = scroll
            
            local nameL = Instance.new("TextLabel")
            nameL.Text = item.DisplayName or item.UserName
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = math.clamp(math.round(7 * scale), 7, 24)
            nameL:SetAttribute("BaseTextSize", 7)
            nameL.TextColor3 = Color3.fromRGB(230, 230, 230)
            nameL.BackgroundTransparency = 1
            nameL.Position = UDim2.new(0, 2, 0, 1 * scale)
            nameL.Size = UDim2.new(0.5, 0, 0, 10 * scale)
            nameL:SetAttribute("BaseSize", UDim2.new(0.5, 0, 0, 10))
            nameL:SetAttribute("BasePos", UDim2.new(0, 2, 0, 1))
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Parent = card
            
            local isInGame = false
            local statusText = "🟢 Online"
            local statusColor = Color3.fromRGB(50, 195, 75)
            
            if item.LocationType == 1 or item.LocationType == 4 or item.LocationType == 5 or (item.GameId and item.GameId ~= "") then
                if item.PlaceId and item.PlaceId > 0 then
                    isInGame = true
                    statusText = "🎮 Play: " .. (item.LastLocation or "In-game")
                end
            elseif item.LocationType == 3 then
                statusText = "🔧 Studio"
                statusColor = Color3.fromRGB(218, 170, 42)
            end
            
            local detL = Instance.new("TextLabel")
            detL.Text = statusText
            detL.Font = Enum.Font.Gotham
            detL.TextSize = math.clamp(math.round(6 * scale), 7, 24)
            detL:SetAttribute("BaseTextSize", 6)
            detL.TextColor3 = statusColor
            detL.BackgroundTransparency = 1
            detL.Position = UDim2.new(0, 2, 0, 11 * scale)
            detL.Size = UDim2.new(0.7, 0, 0, 10 * scale)
            detL:SetAttribute("BaseSize", UDim2.new(0.7, 0, 0, 10))
            detL:SetAttribute("BasePos", UDim2.new(0, 2, 0, 11))
            detL.TextXAlignment = Enum.TextXAlignment.Left
            detL.Parent = card
            
            if isInGame then
                local join = Instance.new("TextButton")
                join.Size = UDim2.new(0, 26 * scale, 0, 12 * scale)
                join:SetAttribute("BaseSize", UDim2.new(0, 26, 0, 12))
                join.Position = UDim2.new(1, -28 * scale, 0.5, -6 * scale)
                join:SetAttribute("BasePos", UDim2.new(1, -28, 0.5, -6))
                join.BackgroundColor3 = Color3.fromRGB(50, 195, 75)
                join.BorderSizePixel = 0
                join.Font = Enum.Font.GothamBold
                join.TextSize = math.clamp(math.round(7 * scale), 7, 24)
                join:SetAttribute("BaseTextSize", 7)
                join.TextColor3 = Color3.fromRGB(255, 255, 255)
                join.Text = "JOIN"
                join.Parent = card

                join.MouseButton1Click:Connect(function()
                    if item.GameId and item.GameId ~= "" then
                        notify("Connecting to friend...", Color3.fromRGB(50, 195, 75))
                        pcall(function() TeleportService:TeleportToPlaceInstance(item.PlaceId, item.GameId, LP) end)
                    else
                        notify("Warping to friend...", Color3.fromRGB(50, 195, 75))
                        pcall(function() TeleportService:Teleport(item.PlaceId, LP) end)
                    end
                end)
            end
        end
    end)
end

registerModule("Misc", "Online Friends", 720, 50, false, false, nil, function(drawer)
    local frame = addCustomFrameOption(drawer, 100)
    
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1, -8, 0, 14)
    refreshBtn.Position = UDim2.new(0, 4, 0, 0)
    refreshBtn.BackgroundColor3 = currentThemeColor
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 8
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.Text = "Refresh Online Friends"
    refreshBtn.Parent = frame
    table.insert(themeHeaders, refreshBtn)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -16)
    scroll.Position = UDim2.new(0, 4, 0, 16)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll

    refreshBtn.MouseButton1Click:Connect(function()
        rebuildFriends(scroll)
    end)

    rebuildFriends(scroll)
end, true, 200, 200)

registerModule("Misc", "Chat Logger", 720, 50, false, false, nil, function(drawer)
    local filter = ""
    local chatFeed = addScrollFeedOption(drawer, 80)
    activeChatFeed = chatFeed
    
    addTextboxOption(drawer, "Filter chat logs text", "Filter text", function(txt)
        filter = txt
        chatFeed:Clear()
        for _, log in ipairs(S.ChatHistory) do
            local matches = true
            if filter ~= "" then
                matches = log.Speaker:lower():find(filter:lower()) or log.Message:lower():find(filter:lower())
            end
            if matches then
                chatFeed:AddEntry(string.format("[%s] [%s]: %s", log.Timestamp, log.Speaker, log.Message), log.Color)
            end
        end
    end)

    addButtonOption(drawer, "Copy Entire Chat Logs", function()
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

    addToggleOption(drawer, "Toast notifications on chat", S.ToastChatEnabled, function(v)
        S.ToastChatEnabled = v
        saveConfig()
    end)

    for _, log in ipairs(S.ChatHistory) do
        chatFeed:AddEntry(string.format("[%s] [%s]: %s", log.Timestamp, log.Speaker, log.Message), log.Color)
    end
end, true, 240, 220)

registerModule("Misc", "External Scripts Hub", 720, 50, false, false, nil, function(drawer)
    addButtonOption(drawer, "Load Rotector Anti-Cheat", function()
        runExternalScript("Rotector", "https://raw.githubusercontent.com/VenezzaX/RobloxRotector/refs/heads/main/Rotector.lua")
    end)
    addButtonOption(drawer, "Load FE Emotes Script", function()
        runExternalScript("FE Emotes", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/FeEmotes.lua")
    end)
    addButtonOption(drawer, "Load Gamepass Bypass", function()
        runExternalScript("Gamepass Bypass", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/gamepassbypass.lua")
    end)
    addButtonOption(drawer, "Load Coordinate UI", function()
        runExternalScript("Coordinate UI", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/CoordinateUI.lua")
    end)
    addButtonOption(drawer, "Load Dex Explorer (Injected)", function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end)
        notify("Dex Explorer loaded successfully!", Color3.fromRGB(50, 195, 75))
    end)
    addButtonOption(drawer, "Load Cobalt UI Wrapper", function()
        pcall(function() loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))() end)
        notify("Cobalt UI loaded successfully!", Color3.fromRGB(50, 195, 75))
    end)
    addButtonOption(drawer, "Load Infinite Yield Admin", function()
        pcall(function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'),true))() end)
        notify("Infinite Yield loaded successfully!", Color3.fromRGB(50, 195, 75))
    end)
    addButtonOption(drawer, "Load SimpleSpy V3 (Remote)", function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))() end)
        notify("SimpleSpy V3 loaded successfully!", Color3.fromRGB(50, 195, 75))
    end)
    addButtonOption(drawer, "Load Hydroxide Remote Spy", function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/PolyphonyDev/Hydroxide/main/init.lua"))() end)
        notify("Hydroxide Spy loaded successfully!", Color3.fromRGB(50, 195, 75))
    end)
end, true, 200, 220)

registerModule("Misc", "UNC compliance & Audits", 720, 50, false, false, nil, function(drawer)
    addButtonOption(drawer, "Run UNC Test Compliance Suite", function()
        runExternalScript("UNC Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/Unc.lua")
    end)
    addButtonOption(drawer, "Run Executor Vuln Test", function()
        runExternalScript("Vulnerability Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/VulnerabilityTest.lua")
    end)
    addButtonOption(drawer, "Run Workspace Instance Dumper", function()
        runExternalScript("Workspace Dumper", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/WorkspaceDumper.lua")
    end)
    addButtonOption(drawer, "Run SUNC Exploit Tester", function()
        runExternalScript("SUNC Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/Sunc.lua", 90441122676618)
    end)
    addButtonOption(drawer, "Run Myriad Executor Test", function()
        runExternalScript("Myriad Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/MyriadTest.lua", 79035306837882)
    end)
    addButtonOption(drawer, "Teleport to SUNC Test Game", function()
        teleportToPlace(90441122676618)
    end)
    addButtonOption(drawer, "Teleport to Myriad Test Game", function()
        teleportToPlace(79035306837882)
    end)
end, true, 200, 180)

registerModule("Misc", "Console Log Viewer", 720, 50, false, false, nil, function(drawer)
    local conFeed = addScrollFeedOption(drawer, 80)
    activeConsoleFeed = conFeed
    local showI = true
    local showW = true
    local showE = true

    local function rebuildConsole()
        conFeed:Clear()
        for _, log in ipairs(consoleLogs) do
            local msg = log.message
            local mType = log.messageType
            local col = Color3.fromRGB(220, 220, 220)
            local prefix = ""
            local show = false
            
            if mType == Enum.MessageType.MessageOutput or mType == Enum.MessageType.MessageInfo then
                if mType == Enum.MessageType.MessageInfo then
                    col = Color3.fromRGB(80, 180, 240)
                    prefix = "[INFO] "
                end
                show = showI
            elseif mType == Enum.MessageType.MessageWarning then
                col = Color3.fromRGB(240, 200, 50)
                prefix = "[WARN] "
                show = showW
            elseif mType == Enum.MessageType.MessageError then
                col = Color3.fromRGB(240, 70, 70)
                prefix = "[ERROR] "
                show = showE
            end
            
            if show then
                conFeed:AddEntry(prefix .. msg, col, log.count)
            end
        end
    end

    addToggleOption(drawer, "Show Prints & Info", showI, function(v)
        showI = v
        rebuildConsole()
    end)
    addToggleOption(drawer, "Show Warnings", showW, function(v)
        showW = v
        rebuildConsole()
    end)
    addToggleOption(drawer, "Show Errors", showE, function(v)
        showE = v
        rebuildConsole()
    end)
    addButtonOption(drawer, "Clear Console Log", function()
        consoleLogs = {}
        consoleLogsMap = {}
        conFeed:Clear()
    end)

    rebuildConsole()
end, true, 240, 220)

registerModule("Misc", "Settings & Keybinds", 720, 50, false, false, nil, function(drawer)
    addToggleOption(drawer, "Auto-Reinject", S.AutoReinject, function(v)
        S.AutoReinject = v
        saveConfig()
        setupAutoReinject()
    end)
    
    addKeybindOption(drawer, "Fly Bind", S.FlyKey, function(k) S.FlyKey = k saveConfig() end)
    addKeybindOption(drawer, "NoClip Bind", S.NoClipKey, function(k) S.NoClipKey = k saveConfig() end)
    addKeybindOption(drawer, "Bunnyhop Bind", S.BHopKey, function(k) S.BHopKey = k saveConfig() end)
    addKeybindOption(drawer, "InfJump Bind", S.InfJumpKey, function(k) S.InfJumpKey = k saveConfig() end)
    addKeybindOption(drawer, "Ghost Bind", S.GhostKey, function(k) S.GhostKey = k saveConfig() end)
    addKeybindOption(drawer, "Blink Bind", S.BlinkKey, function(k) S.BlinkKey = k saveConfig() end)
end, false)

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
    local fwd = cf.LookVector
    
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
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    
    local bg = Instance.new("BodyGyro")
    bg.Name = "VoidFlyBG"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
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
    
    visRaycastParams.FilterDescendantsInstances = {LP.Character, char}
    
    local result = Workspace:Raycast(origin, direction, visRaycastParams)
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
    local hrp = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not hrp then return nil end
    
    local hrPos = hrp.Position
    local topSp, topOnScreen = Camera:WorldToViewportPoint(hrPos + Vector3.new(0, 3, 0))
    if topSp.Z <= 0 then return nil end
    
    local botSp = Camera:WorldToViewportPoint(hrPos - Vector3.new(0, 3.5, 0))
    local height = math.abs(topSp.Y - botSp.Y)
    local width = height * 0.6
    
    return {
        Vector2.new(topSp.X - width/2, topSp.Y),
        Vector2.new(topSp.X + width/2, botSp.Y)
    }
end

-- ──────────────────────────────────────────────────────────────
--  RUNTIME TICK LOOPS & BINDINGS
-- ──────────────────────────────────────────────────────────────

-- ── 1. RenderStepped Aimbot, FOV, and ESP Update ───────────────
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = Color3.fromRGB(218, 38, 38)
fovCircle.Filled = false
fovCircle.Transparency = 1
getgenv().VoidFOVCircle = fovCircle

table.insert(S.Connections, RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera") or Camera
    if S.ClearVision then
        Lighting.FogEnd = 100000
    end

    fovCircle.Visible = S.AimbotActive and S.AimbotShowFOV
    if fovCircle.Visible then
        local vp = Camera.ViewportSize
        fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        fovCircle.Radius = S.AimbotFOV
    end
    
    if S.AimbotActive and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local targetPart = getAimbotTarget()
        if targetPart then
            local goalCF = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            local sm = math.max(S.AimbotSmooth, 1)
            Camera.CFrame = Camera.CFrame:Lerp(goalCF, 1 / sm)
        end
    end
    
    local espColorMapping = {
        ["Red"] = Color3.fromRGB(220, 40, 40),
        ["Green"] = Color3.fromRGB(55, 200, 80),
        ["Blue"] = Color3.fromRGB(40, 120, 220),
        ["Yellow"] = Color3.fromRGB(220, 175, 45),
        ["Cyan"] = Color3.fromRGB(45, 200, 220),
        ["White"] = Color3.fromRGB(255, 255, 255)
    }
    -- Clean up disconnected players
    for p, _ in pairs(S.ESPPool) do
        if not p or p.Parent ~= Players then
            destroyESP(p)
        end
    end
    for p, _ in pairs(S.HitboxStore) do
        if not p or p.Parent ~= Players then
            restoreHitbox(p)
        end
    end
    for p, bill in pairs(S.OverheadPool) do
        if not p or p.Parent ~= Players then
            pcall(function() bill:Destroy() end)
            S.OverheadPool[p] = nil
        end
    end

    local espEnabled = (S.ESPBoxes or S.ESPTracers or S.ESPNames or S.ESPHealth or S.ESPDistances)
    if espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local char = p.Character
            local hrp = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            local valid = char and hrp and hum and hum.Health > 0
            if valid then
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
                    local pool = S.ESPPool[p]
                    if pool then
                        pool.boxOutline.Visible = false
                        pool.boxFill.Visible = false
                        pool.tracer.Visible = false
                        pool.nameTag.Visible = false
                        pool.healthText.Visible = false
                        pool.distText.Visible = false
                    end
                end
            else
                destroyESP(p)
            end
        end
    else
        if next(S.ESPPool) ~= nil then
            for p, _ in pairs(S.ESPPool) do
                destroyESP(p)
            end
        end
    end
end))

-- ── 2. Heartbeat Loops (Movements, Anti-Void, Follow, Stats) ────
local fpsCount = 0
local lastFpsTick = tick()
local lastPingTick = tick()
local pingVal = 0

local flingAllTarget = nil
local flingAllTime = 0

local function getNextFlingAllTarget(currentTarget)
    local candidates = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                table.insert(candidates, p)
            end
        end
    end
    if #candidates == 0 then return nil end
    local currentIndex = 0
    if currentTarget then
        for idx, p in ipairs(candidates) do
            if p == currentTarget then
                currentIndex = idx
                break
            end
        end
    end
    local nextIndex = currentIndex + 1
    if nextIndex > #candidates then
        nextIndex = 1
    end
    return candidates[nextIndex]
end

table.insert(S.Connections, RunService.Heartbeat:Connect(function(dt)
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
    
    if S.AntiAnchor and myChar then
        pcall(function()
            for _, part in ipairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") and part.Anchored then
                    part.Anchored = false
                end
            end
        end)
    end
    
    if S.AntiSit and myHum and myHum.Sit then
        pcall(function()
            myHum.Sit = false
        end)
    end
    
    if S.Fly then
        pcall(updateFlyVelocity)
    end
    
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
    
    pcall(function()
        if S.FollowActive and S.FollowTarget then
            local tgtHRP = S.FollowTarget.Character and (S.FollowTarget.Character:FindFirstChild("HumanoidRootPart") or S.FollowTarget.Character:FindFirstChild("Torso") or S.FollowTarget.Character.PrimaryPart)
            if tgtHRP then teleportToHRP(tgtHRP) end
        end
    end)
    
    pcall(function()
        if S.HitboxExpanded then
            for _, p in ipairs(Players:GetPlayers()) do applyHitbox(p) end
        end
    end)
    
    pcall(function()
        if S.GravityEnabled then Workspace.Gravity = S.CustomGravity end
    end)
    
    pcall(function()
        if S.TimeCycle then
            S.TimeOfDay = ((S.TimeOfDay or Lighting.ClockTime) + dt * S.TimeCycleSpeed * 0.1) % 24
            Lighting.ClockTime = S.TimeOfDay
        else
            Lighting.ClockTime = S.TimeOfDay or Lighting.ClockTime
        end
    end)
    
    pcall(function()
        if S.Spin and myHRP then myHRP.CFrame = myHRP.CFrame * CFrame.Angles(0, math.rad(S.SpinSpeed), 0) end
    end)
    
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
    
    pcall(function()
        if S.ToolMagnet and myHRP then
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("Tool") and item:FindFirstChild("Handle") then
                    item.Handle.CFrame = myHRP.CFrame
                end
            end
        end
    end)
    
    pcall(function()
        if S.AutoJump and myHum and myHRP and myHum.FloorMaterial ~= Enum.Material.Air then
            local edgeRay = Ray.new(myHRP.Position + (myHRP.CFrame.LookVector * 2), Vector3.new(0, -5, 0))
            local hit = Workspace:FindPartOnRay(edgeRay, myChar)
            if not hit then myHum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    
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
    
    pcall(function()
        if S.AutoClicker and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            VirtualUser:ClickButton1(Vector2.new())
        end
    end)
    
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
    
    pcall(function()
        if S.HUDCoords and myHRP then
            local pos = myHRP.Position
            hudCoords.Text = string.format("XYZ: %.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
        end
    end)
    
    pcall(function()
        if S.AntiFling then
            if myHRP and not S.FlingActive and not S.FlingAllActive then
                if myHRP.AssemblyLinearVelocity.Magnitude > 150 then
                    myHRP.AssemblyLinearVelocity = Vector3.zero
                end
                if myHRP.AssemblyAngularVelocity.Magnitude > 100 then
                    myHRP.AssemblyAngularVelocity = Vector3.zero
                end
            end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    for _, part in ipairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            pcall(function()
                                part.CanCollide = false
                                part.AssemblyLinearVelocity = Vector3.zero
                                part.AssemblyAngularVelocity = Vector3.zero
                            end)
                        end
                    end
                end
            end
        end
    end)
    
    pcall(function()
        if S.FlingActive and S.FlingTarget and myHRP then
            local targetChar = S.FlingTarget.Character
            local targetHRP = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar.PrimaryPart)
            local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            if targetHRP and targetHum and targetHum.Health > 0 then
                for _, part in ipairs(myChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 1)
                myHRP.AssemblyLinearVelocity = Vector3.new(0, 1000, 0)
                myHRP.AssemblyAngularVelocity = Vector3.new(0, 50000, 0)
            else
                S.FlingActive = false
                local mod = moduleButtons["Fling Player"]
                if mod then mod.SetActive(false) end
                notify("Fling target lost or dead!", Color3.fromRGB(218, 38, 38))
            end
        elseif S.FlingAllActive and myHRP then
            local now = tick()
            local targetChar = flingAllTarget and flingAllTarget.Character
            local targetHRP = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar.PrimaryPart)
            local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            
            if not targetHRP or not targetHum or targetHum.Health <= 0 or (now - flingAllTime) >= 0.5 then
                flingAllTarget = getNextFlingAllTarget(flingAllTarget)
                flingAllTime = now
                if flingAllTarget then
                    targetChar = flingAllTarget.Character
                    targetHRP = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar.PrimaryPart)
                else
                    targetHRP = nil
                end
            end
            
            if targetHRP then
                for _, part in ipairs(myChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 1)
                myHRP.AssemblyLinearVelocity = Vector3.new(0, 1000, 0)
                myHRP.AssemblyAngularVelocity = Vector3.new(0, 50000, 0)
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
local function toggleUIVisibility()
    uiVisible = not uiVisible
    screenGui.Enabled = uiVisible
    if updateMenuBlur then updateMenuBlur() end
end

table.insert(S.Connections, UserInputService.InputBegan:Connect(function(inp, gpe)
    if inp.KeyCode == (S.UIToggleKey or Enum.KeyCode.RightControl) or inp.KeyCode == Enum.KeyCode.RightControl then
        toggleUIVisibility()
        return
    end

    if gpe then return end
    
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
    
    if k == (S.MacroKey or Enum.KeyCode.H) and S.MacroText and S.MacroText ~= "" then
        pcall(function()
            local chatService = game:GetService("TextChatService")
            if chatService and chatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local textChannel = chatService.TextChannels:FindFirstChild("RBXGeneral")
                if textChannel then
                    textChannel:SendAsync(S.MacroText)
                end
            else
                local sayMsg = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                sayMsg = sayMsg and sayMsg:FindFirstChild("SayMessageRequest")
                if sayMsg then
                    sayMsg:FireServer(S.MacroText, "All")
                end
            end
        end)
    end
    
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
        local mod = moduleButtons["Fly Mode"]
        if mod then mod.SetActive(S.Fly) end
    elseif k == S.NoClipKey then
        S.NoClip = not S.NoClip
        notify("NoClip " .. (S.NoClip and "ON" or "OFF"), Color3.fromRGB(218, 170, 42))
        local mod = moduleButtons["NoClip Passes"]
        if mod then mod.SetActive(S.NoClip) end
    elseif k == S.BHopKey then
        S.BHop = not S.BHop
        notify("Bunnyhop " .. (S.BHop and "ON" or "OFF"), Color3.fromRGB(218, 170, 42))
        local mod = moduleButtons["Auto Bunnyhop"]
        if mod then mod.SetActive(S.BHop) end
    elseif k == S.InfJumpKey then
        S.InfJump = not S.InfJump
        notify("Infinite Jump " .. (S.InfJump and "ON" or "OFF"), Color3.fromRGB(218, 170, 42))
        local mod = moduleButtons["Infinite Jump"]
        if mod then mod.SetActive(S.InfJump) end
    elseif k == S.GhostKey then
        S.GhostMode = not S.GhostMode
        if S.GhostMode then enableGhostMode() else disableGhostMode() end
        local mod = moduleButtons["Ghost State Mode"]
        if mod then mod.SetActive(S.GhostMode) end
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
        if S.SprintEnabled then
            local hum = getHum()
            if hum then
                hum.WalkSpeed = (S.ForceWalkSpeed and S.WalkSpeed) or gameDefaultSpeed
            end
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
        if not S.ForceWalkSpeed then
            gameDefaultSpeed = hum.WalkSpeed
        end
        if not S.ForceJumpPower then
            gameDefaultJumpPower = hum.JumpPower
            gameDefaultUseJumpPower = hum.UseJumpPower
        end
        hum.UseJumpPower = S.ForceJumpPower and true or gameDefaultUseJumpPower
        hum.WalkSpeed = (S.ForceWalkSpeed and S.WalkSpeed) or gameDefaultSpeed
        hum.JumpPower = (S.ForceJumpPower and S.JumpPower) or gameDefaultJumpPower
    end
    
    if S.Fly then
        task.wait(0.1)
        flyOn()
    end
    
    if S.Float then
        task.wait(0.1)
        toggleFloat(true)
    end
    
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

table.insert(S.Connections, Players.PlayerRemoving:Connect(function(p)
    pcall(function()
        destroyESP(p)
        restoreHitbox(p)
        if S.OverheadPool[p] then
            pcall(function() S.OverheadPool[p]:Destroy() end)
            S.OverheadPool[p] = nil
        end
        if S.ChatConnections[p] then
            pcall(function() S.ChatConnections[p]:Disconnect() end)
            S.ChatConnections[p] = nil
        end
        if currentSpectateTarget == p then
            spectatePlayer(nil)
        end
    end)
end))

table.insert(S.Connections, LP.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

-- ──────────────────────────────────────────────────────────────
--  READY STARTUP NOTIFICATION
-- ──────────────────────────────────────────────────────────────
pcall(connectConsoleLogger)
pcall(connectChatLogger)
pcall(function()
    applyThemeColor(S.ThemeColor or "Purple")
    updateHUDArrayList()
end)

local toggleKeyName = S.UIToggleKey and S.UIToggleKey.Name or "RCtrl"
logMessage("System", "WeAreSkidding loaded successfully. Keybind: [" .. toggleKeyName .. "] to toggle UI", Color3.fromRGB(50, 195, 75))
notify("WeAreSkidding loaded! [" .. toggleKeyName .. "] to toggle UI", Color3.fromRGB(50, 195, 75))

print("[WeAreSkidding] Custom GUI loaded successfully!")
