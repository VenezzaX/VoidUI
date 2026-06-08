--[[
    ╔══════════════════════════════════════════════════════════╗
    ║                  VOID LIBRARY  v1.0                      ║
    ║          Standalone Roblox Luau UI Framework             ║
    ║          Black · Blocky · Modern Admin Panel Style       ║
    ╚══════════════════════════════════════════════════════════╝

    USAGE:
        local VoidLib = loadstring(game:HttpGet("RAW_URL"))()
        local Window  = VoidLib:CreateWindow("MY PANEL", "v1.0")
        local Tab     = Window:AddTab("Combat")
        Tab:AddToggle("ESP", false, function(state) ... end)
        Tab:AddSlider("Speed", 1, 250, 16, function(val) ... end)
        Tab:AddButton("Action", "RUN", function() ... end)
        Window:Toast("Hello!", nil)

    API:
        VoidLib:CreateWindow(title, version)  → Window
        Window:AddTab(name)                   → Tab
        Window:Toast(msg, color)
        Window:Destroy()
        Tab:AddSection(label)
        Tab:AddToggle(label, default, cb)     → Toggle  (.Value, :SetValue(v))
        Tab:AddSlider(label, min, max, def, cb) → Slider (.Value, :SetValue(v))
        Tab:AddButton(label, subLabel, cb)    → Button
        Tab:AddDropdown(label, opts, def, cb) → Dropdown (.Value, :SetOptions(t))
        Tab:AddInfoRow(label, value)          → InfoRow (.Label, .ValueLabel)
        Tab:AddPlayerList(actionLabel, cb)    → PlayerList (:Refresh())
        Tab:AddTextInput(placeholder, btnTxt, cb) → TextInput
        Tab:AddScrollFeed(height)             → Feed (:AddEntry(text, color))
        Tab:AddFrame(height)                  → bare Frame
]]

-- ─────────────────────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────────────────────
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")

local LP = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────
--  THEME
-- ─────────────────────────────────────────────────────────
local Theme = {
    BG          = Color3.fromRGB(8,   8,   8),
    Panel       = Color3.fromRGB(16,  16,  16),
    PanelAlt    = Color3.fromRGB(22,  22,  22),
    PanelHover  = Color3.fromRGB(30,  30,  30),
    Border      = Color3.fromRGB(40,  40,  40),
    BorderBright= Color3.fromRGB(60,  60,  60),
    Accent      = Color3.fromRGB(215, 45,  45),
    AccentDim   = Color3.fromRGB(140, 28,  28),
    AccentGlow  = Color3.fromRGB(255, 85,  85),
    Text        = Color3.fromRGB(238, 238, 238),
    TextDim     = Color3.fromRGB(145, 145, 145),
    TextMuted   = Color3.fromRGB(72,  72,  72),
    White       = Color3.fromRGB(255, 255, 255),
    Green       = Color3.fromRGB(55,  200, 85),
    Yellow      = Color3.fromRGB(225, 178, 50),
    Red         = Color3.fromRGB(215, 45,  45),
    SliderTrack = Color3.fromRGB(36,  36,  36),
    OnColor     = Color3.fromRGB(215, 45,  45),
    OffColor    = Color3.fromRGB(38,  38,  38),
}

-- ─────────────────────────────────────────────────────────
--  INTERNAL HELPERS
-- ─────────────────────────────────────────────────────────
local function tw(obj, props, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.14, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color  = color     or Theme.Border
    s.Thickness = thickness or 1
    return s
end

local function pad(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    return p
end

local function listLayout(parent, dir, padding, sort)
    local l = Instance.new("UIListLayout", parent)
    l.FillDirection  = dir     or Enum.FillDirection.Vertical
    l.Padding        = UDim.new(0, padding or 0)
    l.SortOrder      = sort    or Enum.SortOrder.LayoutOrder
    return l
end

local function makeScroll(parent)
    local sf = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, parent)
    listLayout(sf, nil, 2)
    pad(sf, 8, 8, 8, 8)
    return sf
end

-- ─────────────────────────────────────────────────────────
--  LIBRARY OBJECT
-- ─────────────────────────────────────────────────────────
local VoidLib = {}
VoidLib.__index = VoidLib

-- ─────────────────────────────────────────────────────────
--  CREATE WINDOW
-- ─────────────────────────────────────────────────────────
function VoidLib:CreateWindow(title, version)
    -- Remove duplicate
    if CoreGui:FindFirstChild("VoidLib_" .. title) then
        CoreGui:FindFirstChild("VoidLib_" .. title):Destroy()
    end

    local WIN_W, WIN_H = 580, 440
    local TABBAR_H = 38
    local TITLEBAR_H = 44

    -- Root ScreenGui
    local gui = make("ScreenGui", {
        Name           = "VoidLib_" .. title,
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, CoreGui)

    -- Toast container
    local toastContainer = make("Frame", {
        Name = "ToastContainer",
        Size = UDim2.new(0, 272, 0, 500),
        Position = UDim2.new(1, -282, 1, -520),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, gui)
    local tcLayout = listLayout(toastContainer, nil, 6)
    tcLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    -- Main window frame
    local window = make("Frame", {
        Name = "Window",
        Size = UDim2.new(0, WIN_W, 0, WIN_H),
        Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
        BackgroundColor3 = Theme.BG,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    stroke(window, Theme.Border, 1)

    -- ── Title bar ────────────────────────────────────────
    local titleBar = make("Frame", {
        Size = UDim2.new(1, 0, 0, TITLEBAR_H),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, window)
    stroke(titleBar, Theme.Border, 1)

    -- Red left accent stripe
    make("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, titleBar)

    make("TextLabel", {
        Text = title,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.White,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 160, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleBar)

    make("TextLabel", {
        Text = version or "",
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextColor3 = Theme.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 120, 0, 0),
        Size = UDim2.new(0, 60, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleBar)

    -- FPS / Ping label (title bar right)
    local hudLabel = make("TextLabel", {
        Name = "HUDLabel",
        Text = "FPS: --  |  PING: --ms",
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -230, 0, 0),
        Size = UDim2.new(0, 190, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    }, titleBar)

    -- Minimize / Close
    local minBtn = make("TextButton", {
        Text = "─",
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.TextDim,
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 30, 0, 24),
        Position = UDim2.new(1, -68, 0.5, -12),
        ZIndex = 3,
    }, titleBar)
    stroke(minBtn, Theme.Border, 1)

    local closeBtn = make("TextButton", {
        Text = "✕",
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.Accent,
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 30, 0, 24),
        Position = UDim2.new(1, -34, 0.5, -12),
        ZIndex = 3,
    }, titleBar)
    stroke(closeBtn, Theme.AccentDim, 1)

    -- ── Drag ─────────────────────────────────────────────
    local dragging, dragStart, winStart
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; winStart = window.Position
        end
    end)
    titleBar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            window.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset + d.X,
                                         winStart.Y.Scale, winStart.Y.Offset + d.Y)
        end
    end)

    -- ── Minimize ─────────────────────────────────────────
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        tw(window, { Size = minimized
            and UDim2.new(0, WIN_W, 0, TITLEBAR_H)
            or  UDim2.new(0, WIN_W, 0, WIN_H)
        }, 0.2)
        minBtn.Text = minimized and "□" or "─"
    end)

    closeBtn.MouseButton1Click:Connect(function()
        tw(window, { Size = UDim2.new(0, WIN_W, 0, 0) }, 0.18)
        task.delay(0.2, function() gui:Destroy() end)
    end)

    -- ── Tab bar ──────────────────────────────────────────
    local tabBar = make("Frame", {
        Size = UDim2.new(1, 0, 0, TABBAR_H),
        Position = UDim2.new(0, 0, 0, TITLEBAR_H),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, window)
    stroke(tabBar, Theme.Border, 1)
    listLayout(tabBar, Enum.FillDirection.Horizontal, 0)

    -- Content holder
    local contentHolder = make("Frame", {
        Size = UDim2.new(1, 0, 1, -(TITLEBAR_H + TABBAR_H)),
        Position = UDim2.new(0, 0, 0, TITLEBAR_H + TABBAR_H),
        BackgroundColor3 = Theme.BG,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, window)

    -- ─────────────────────────────────────────────────────
    --  WINDOW OBJECT
    -- ─────────────────────────────────────────────────────
    local Win = { _tabs = {}, _tabBtns = {}, _tabLines = {}, _contentFrames = {}, _gui = gui }

    -- Toast
    function Win:Toast(msg, color)
        color = color or Theme.Accent
        local f = make("Frame", {
            Size = UDim2.new(0, 260, 0, 44),
            BackgroundColor3 = Theme.Panel,
            BorderSizePixel = 0,
            Position = UDim2.new(1, 10, 0, 0),
        }, toastContainer)
        stroke(f, color, 1)

        make("Frame", {
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        }, f)

        make("TextLabel", {
            Text = msg,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -14, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, f)

        tw(f, { Position = UDim2.new(1, -270, 0, 0) }, 0.28)
        task.delay(3.5, function()
            tw(f, { Position = UDim2.new(1, 10, 0, 0) }, 0.22)
            task.delay(0.25, function() pcall(function() f:Destroy() end) end)
        end)
    end

    -- Destroy
    function Win:Destroy()
        pcall(function() gui:Destroy() end)
    end

    -- HUD label reference
    Win.HUDLabel = hudLabel

    -- Switch tab (internal)
    local function switchTab(idx)
        for i, cf in ipairs(Win._contentFrames) do
            cf.Visible = (i == idx)
        end
        for i, btn in ipairs(Win._tabBtns) do
            local active = (i == idx)
            tw(btn, { BackgroundColor3 = active and Theme.AccentDim or Theme.Panel })
            btn.TextColor3 = active and Theme.White or Theme.TextDim
        end
        for i, line in ipairs(Win._tabLines) do
            tw(line, { BackgroundColor3 = i == idx and Theme.Accent or Theme.Border })
        end
    end

    -- Add tab
    function Win:AddTab(name)
        local idx = #self._tabs + 1
        local totalTabs = idx -- will be updated dynamically
        _ = totalTabs

        local btn = make("TextButton", {
            Text = name:upper(),
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextColor3 = idx == 1 and Theme.White or Theme.TextDim,
            BackgroundColor3 = idx == 1 and Theme.AccentDim or Theme.Panel,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 116, 1, 0),  -- fixed width; will be overridden
            LayoutOrder = idx,
        }, tabBar)

        -- Resize all tab buttons equally
        local function resizeTabs()
            local count = #self._tabBtns
            local w = math.floor(WIN_W / count)
            for _, b in ipairs(self._tabBtns) do
                b.Size = UDim2.new(0, w, 1, 0)
            end
        end

        local bottomLine = make("Frame", {
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = idx == 1 and Theme.Accent or Theme.Border,
            BorderSizePixel = 0,
        }, btn)

        local cf = make("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = (idx == 1),
        }, contentHolder)

        self._tabBtns[idx] = btn
        self._tabLines[idx] = bottomLine
        self._contentFrames[idx] = cf
        self._tabs[idx] = name

        resizeTabs()

        local capturedIdx = idx
        btn.MouseButton1Click:Connect(function()
            switchTab(capturedIdx)
        end)

        btn.MouseEnter:Connect(function()
            local current = 0
            for i, b in ipairs(self._tabBtns) do if b == btn then current = i end end
            if current ~= capturedIdx then return end
            -- already active, skip
        end)

        -- Tab content API
        local scroll = makeScroll(cf)
        local Tab = { _scroll = scroll, _win = self }

        -- ─── SECTION ───────────────────────────────────────
        function Tab:AddSection(label)
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, scroll)

            make("TextLabel", {
                Text = "  " .. label:upper(),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.TextMuted,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.8, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            make("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
            }, row)

            return row
        end

        -- ─── TOGGLE ────────────────────────────────────────
        function Tab:AddToggle(label, default, callback)
            local state = default or false

            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            stroke(row, Theme.Border, 1)

            make("TextLabel", {
                Text = label,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -72, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local pill = make("Frame", {
                Size = UDim2.new(0, 46, 0, 22),
                Position = UDim2.new(1, -58, 0.5, -11),
                BackgroundColor3 = state and Theme.OnColor or Theme.OffColor,
                BorderSizePixel = 0,
            }, row)
            stroke(pill, Theme.Border, 1)

            local knob = make("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Theme.White,
                BorderSizePixel = 0,
            }, pill)

            local btn = make("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 2,
            }, row)

            local Toggle = { Value = state }

            local function apply(v)
                Toggle.Value = v
                tw(pill,  { BackgroundColor3 = v and Theme.OnColor or Theme.OffColor })
                tw(knob,  { Position = v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) })
            end

            function Toggle:SetValue(v)
                apply(v)
                if callback then callback(v) end
            end

            btn.MouseButton1Click:Connect(function()
                apply(not Toggle.Value)
                if callback then callback(Toggle.Value) end
            end)

            btn.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = Theme.PanelHover}) end)
            btn.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = Theme.PanelAlt})   end)

            return Toggle
        end

        -- ─── SLIDER ────────────────────────────────────────
        function Tab:AddSlider(label, minV, maxV, default, callback)
            local value = math.clamp(default or minV, minV, maxV)

            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 54),
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            stroke(row, Theme.Border, 1)

            make("TextLabel", {
                Text = label,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(0.7, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local valLbl = make("TextLabel", {
                Text = tostring(value),
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                Position = UDim2.new(0.7, 0, 0, 6),
                Size = UDim2.new(0.3, -12, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)

            local track = make("Frame", {
                Size = UDim2.new(1, -24, 0, 4),
                Position = UDim2.new(0, 12, 0, 36),
                BackgroundColor3 = Theme.SliderTrack,
                BorderSizePixel = 0,
            }, row)

            local pct0 = (value - minV) / math.max(maxV - minV, 1)
            local fill = make("Frame", {
                Size = UDim2.new(pct0, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
            }, track)

            local thumb = make("Frame", {
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(pct0, -6, 0.5, -6),
                BackgroundColor3 = Theme.White,
                BorderSizePixel = 0,
            }, track)

            local Slider = { Value = value }
            local draggingSlider = false

            local function applySlider(absX)
                local tx = track.AbsolutePosition.X
                local tw_ = track.AbsoluteSize.X
                local p = math.clamp((absX - tx) / math.max(tw_, 1), 0, 1)
                local v = math.floor(minV + (maxV - minV) * p)
                Slider.Value = v
                valLbl.Text  = tostring(v)
                fill.Size    = UDim2.new(p, 0, 1, 0)
                thumb.Position = UDim2.new(p, -6, 0.5, -6)
                if callback then callback(v) end
            end

            function Slider:SetValue(v)
                local p = math.clamp((v - minV) / math.max(maxV - minV, 1), 0, 1)
                self.Value = v
                valLbl.Text = tostring(v)
                fill.Size  = UDim2.new(p, 0, 1, 0)
                thumb.Position = UDim2.new(p, -6, 0.5, -6)
            end

            local trackBtn = make("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 5, 0),
                Position = UDim2.new(0, 0, -2, 0),
                ZIndex = 3,
            }, track)

            trackBtn.MouseButton1Down:Connect(function()
                draggingSlider = true
                applySlider(UserInputService:GetMouseLocation().X)
            end)
            UserInputService.InputChanged:Connect(function(i)
                if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
                    applySlider(i.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end)

            return Slider
        end

        -- ─── BUTTON ────────────────────────────────────────
        function Tab:AddButton(label, subLabel, callback)
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            stroke(row, Theme.Border, 1)

            make("TextLabel", {
                Text = label,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.62, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local btn = make("TextButton", {
                Text = subLabel or "RUN",
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.White,
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 88, 0, 24),
                Position = UDim2.new(1, -100, 0.5, -12),
            }, row)
            stroke(btn, Theme.AccentDim, 1)

            btn.MouseButton1Click:Connect(function()
                tw(btn, { BackgroundColor3 = Theme.AccentGlow }, 0.07)
                task.delay(0.14, function() tw(btn, { BackgroundColor3 = Theme.Accent }, 0.1) end)
                if callback then callback() end
            end)
            btn.MouseEnter:Connect(function() tw(btn, { BackgroundColor3 = Theme.AccentDim }) end)
            btn.MouseLeave:Connect(function() tw(btn, { BackgroundColor3 = Theme.Accent   }) end)

            local rowBtn = make("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(0.62, 0, 1, 0),
            }, row)
            rowBtn.MouseEnter:Connect(function() tw(row, { BackgroundColor3 = Theme.PanelHover }) end)
            rowBtn.MouseLeave:Connect(function() tw(row, { BackgroundColor3 = Theme.PanelAlt   }) end)
            rowBtn.MouseButton1Click:Connect(function() if callback then callback() end end)

            local Btn = {}
            function Btn:SetText(t) btn.Text = t end
            return Btn
        end

        -- ─── DROPDOWN ──────────────────────────────────────
        function Tab:AddDropdown(label, options, defaultIdx, callback)
            local selected = defaultIdx or 1
            local open = false

            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
                ClipsDescendants = false,
                ZIndex = 5,
            }, scroll)
            stroke(row, Theme.Border, 1)

            make("TextLabel", {
                Text = label,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            }, row)

            local selLbl = make("TextLabel", {
                Text = options[selected] or "...",
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(0.42, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 5,
            }, row)

            local arrow = make("TextLabel", {
                Text = "▾",
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.TextDim,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -24, 0, 0),
                Size = UDim2.new(0, 20, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 5,
            }, row)

            local ddFrame = make("Frame", {
                Size = UDim2.new(1, 0, 0, math.min(#options, 5) * 30),
                Position = UDim2.new(0, 0, 1, 2),
                BackgroundColor3 = Theme.Panel,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 20,
                ClipsDescendants = true,
            }, row)
            stroke(ddFrame, Theme.Accent, 1)

            local ddScroll = make("ScrollingFrame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 20,
            }, ddFrame)
            listLayout(ddScroll, nil, 0)

            local Dropdown = { Value = options[selected], Index = selected }

            local function buildOptions(opts)
                for _, c in ipairs(ddScroll:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for i, opt in ipairs(opts) do
                    local item = make("TextButton", {
                        Text = "  " .. opt,
                        TextSize = 11,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.Text,
                        BackgroundColor3 = i == selected and Theme.AccentDim or Theme.Panel,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 30),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 21,
                    }, ddScroll)
                    local captI = i
                    item.MouseButton1Click:Connect(function()
                        selected = captI
                        Dropdown.Value = opt
                        Dropdown.Index = captI
                        selLbl.Text = opt
                        open = false
                        ddFrame.Visible = false
                        arrow.Text = "▾"
                        if callback then callback(captI, opt) end
                    end)
                    item.MouseEnter:Connect(function() tw(item, { BackgroundColor3 = Theme.AccentDim }) end)
                    item.MouseLeave:Connect(function()
                        tw(item, { BackgroundColor3 = captI == selected and Theme.AccentDim or Theme.Panel })
                    end)
                end
            end

            buildOptions(options)

            function Dropdown:SetOptions(opts)
                options = opts
                selected = 1
                self.Value = opts[1]
                self.Index = 1
                selLbl.Text = opts[1] or "..."
                buildOptions(opts)
            end

            local toggleBtn = make("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
            }, row)
            toggleBtn.MouseButton1Click:Connect(function()
                open = not open
                ddFrame.Visible = open
                arrow.Text = open and "▴" or "▾"
            end)

            return Dropdown
        end

        -- ─── INFO ROW ──────────────────────────────────────
        function Tab:AddInfoRow(label, valueStr)
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            stroke(row, Theme.Border, 1)

            make("TextLabel", {
                Text = label,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextColor3 = Theme.TextDim,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.52, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local valLbl = make("TextLabel", {
                Text = valueStr or "--",
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0.52, 0, 0, 0),
                Size = UDim2.new(0.48, -12, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)

            local InfoRow = {}
            function InfoRow:SetValue(v) valLbl.Text = tostring(v) end
            function InfoRow:SetColor(c) valLbl.TextColor3 = c end
            InfoRow.Label      = label
            InfoRow.ValueLabel = valLbl
            return InfoRow
        end

        -- ─── TEXT INPUT ────────────────────────────────────
        function Tab:AddTextInput(placeholder, btnTxt, callback)
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            stroke(row, Theme.Border, 1)

            local box = make("TextBox", {
                PlaceholderText = placeholder or "Type here...",
                Text = "",
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.TextMuted,
                BackgroundColor3 = Theme.Panel,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Size = UDim2.new(1, -110, 0, 26),
                Position = UDim2.new(0, 8, 0.5, -13),
            }, row)
            stroke(box, Theme.Border, 1)

            local btn = make("TextButton", {
                Text = btnTxt or "GO",
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.White,
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 88, 0, 26),
                Position = UDim2.new(1, -100, 0.5, -13),
            }, row)
            stroke(btn, Theme.AccentDim, 1)

            btn.MouseButton1Click:Connect(function()
                if callback then callback(box.Text) end
            end)
            box.FocusLost:Connect(function(enter)
                if enter and callback then callback(box.Text) end
            end)

            local TI = {}
            function TI:GetText() return box.Text end
            function TI:SetText(t) box.Text = t end
            function TI:Clear() box.Text = "" end
            return TI
        end

        -- ─── PLAYER LIST ───────────────────────────────────
        function Tab:AddPlayerList(actionLabel, callback)
            local container = make("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, scroll)
            listLayout(container, nil, 2)

            local PL = {}

            function PL:Refresh()
                for _, c in ipairs(container:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p == LP then continue end

                    local row = make("Frame", {
                        Size = UDim2.new(1, 0, 0, 42),
                        BackgroundColor3 = Theme.PanelAlt,
                        BorderSizePixel = 0,
                    }, container)
                    stroke(row, Theme.Border, 1)

                    local thumb = make("ImageLabel", {
                        Size = UDim2.new(0, 30, 0, 30),
                        Position = UDim2.new(0, 6, 0.5, -15),
                        BackgroundColor3 = Theme.Panel,
                        BorderSizePixel = 0,
                    }, row)
                    stroke(thumb, Theme.Border, 1)
                    task.spawn(function()
                        local ok, img = pcall(function()
                            return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                        end)
                        if ok then thumb.Image = img end
                    end)

                    make("TextLabel", {
                        Text = p.DisplayName,
                        TextSize = 12,
                        Font = Enum.Font.GothamBold,
                        TextColor3 = Theme.Text,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 46, 0, 5),
                        Size = UDim2.new(0.58, 0, 0, 16),
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row)

                    make("TextLabel", {
                        Text = "@" .. p.Name,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.TextDim,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 46, 0, 22),
                        Size = UDim2.new(0.58, 0, 0, 14),
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row)

                    local actBtn = make("TextButton", {
                        Text = actionLabel,
                        TextSize = 10,
                        Font = Enum.Font.GothamBold,
                        TextColor3 = Theme.White,
                        BackgroundColor3 = Theme.Accent,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, 80, 0, 24),
                        Position = UDim2.new(1, -92, 0.5, -12),
                    }, row)
                    stroke(actBtn, Theme.AccentDim, 1)

                    local captP = p
                    actBtn.MouseButton1Click:Connect(function()
                        if callback then callback(captP) end
                    end)
                    actBtn.MouseEnter:Connect(function() tw(actBtn, { BackgroundColor3 = Theme.AccentDim }) end)
                    actBtn.MouseLeave:Connect(function() tw(actBtn, { BackgroundColor3 = Theme.Accent   }) end)
                end
            end

            PL:Refresh()
            Players.PlayerAdded:Connect(function()   task.defer(function() PL:Refresh() end) end)
            Players.PlayerRemoving:Connect(function() task.defer(function() PL:Refresh() end) end)
            return PL
        end

        -- ─── SCROLL FEED ───────────────────────────────────
        function Tab:AddScrollFeed(height)
            local feed = make("ScrollingFrame", {
                Size = UDim2.new(1, 0, 0, height or 240),
                BackgroundColor3 = Theme.Panel,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y,
            }, scroll)
            stroke(feed, Theme.Border, 1)
            pad(feed, 6, 6, 8, 8)
            listLayout(feed, nil, 2)

            local Feed = {}
            function Feed:AddEntry(text, color)
                local lbl = make("TextLabel", {
                    Text = text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextColor3 = color or Theme.TextDim,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, feed)
                task.defer(function()
                    feed.CanvasPosition = Vector2.new(0, feed.AbsoluteCanvasSize.Y)
                end)
                return lbl
            end

            function Feed:Clear()
                for _, c in ipairs(feed:GetChildren()) do
                    if c:IsA("TextLabel") then c:Destroy() end
                end
            end

            return Feed
        end

        -- ─── RAW FRAME ─────────────────────────────────────
        function Tab:AddFrame(height)
            return make("Frame", {
                Size = UDim2.new(1, 0, 0, height or 60),
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
        end

        return Tab
    end

    return Win
end

return VoidLib
