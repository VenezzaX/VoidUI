--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                  VOID LIBRARY  v2.0                       ║
    ║       Standalone Roblox Luau UI Framework                 ║
    ║       Black · Blocky · Sidebar · Modern Admin Panel       ║
    ╚═══════════════════════════════════════════════════════════╝

    API REFERENCE:
        VoidLib:CreateWindow(title, version)       → Window
        Window:AddTab(name)                        → Tab
        Window:Toast(msg, color)
        Window:Destroy()
        Window.HUDLabel                            TextLabel ref

        Tab:AddSection(label)
        Tab:AddToggle(label, default, cb)          → Toggle  (.Value, :Set(v))
        Tab:AddSlider(label, min, max, def, cb)    → Slider  (.Value, :Set(v))
        Tab:AddButton(label, subLabel, cb)         → Button  (:SetLabel(t))
        Tab:AddDropdown(label, opts, def, cb)      → Dropdown(.Value, .Index, :SetOptions(t))
        Tab:AddKeybind(label, defaultKey, cb)      → Keybind (.Key, :Set(key))
        Tab:AddInfoRow(label, value)               → InfoRow (:SetValue(v), :SetColor(c))
        Tab:AddTextInput(placeholder, btnTxt, cb)  → TextInput(:GetText(), :Clear())
        Tab:AddPlayerList(btn1, cb1, btn2, cb2)    → PlayerList(:Refresh())  [btn2/cb2 optional]
        Tab:AddScrollFeed(height)                  → Feed (:AddEntry(t,c), :Clear())
        Tab:AddRawFrame(height)                    → Frame
]]

-- ────────────────────────────────────────────────────────────
--  SERVICES
-- ────────────────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

-- ────────────────────────────────────────────────────────────
--  THEME
-- ────────────────────────────────────────────────────────────
local T = {
    BG           = Color3.fromRGB(7,   7,   7),
    Sidebar      = Color3.fromRGB(12,  12,  12),
    Panel        = Color3.fromRGB(16,  16,  16),
    PanelAlt     = Color3.fromRGB(20,  20,  20),
    Hover        = Color3.fromRGB(28,  28,  28),
    Border       = Color3.fromRGB(36,  36,  36),
    BorderHi     = Color3.fromRGB(55,  55,  55),
    Accent       = Color3.fromRGB(220, 40,  40),
    AccentDim    = Color3.fromRGB(135, 22,  22),
    AccentGlow   = Color3.fromRGB(255, 80,  80),
    AccentMuted  = Color3.fromRGB(60,  14,  14),
    Text         = Color3.fromRGB(235, 235, 235),
    TextDim      = Color3.fromRGB(130, 130, 130),
    TextMuted    = Color3.fromRGB(60,  60,  60),
    White        = Color3.fromRGB(255, 255, 255),
    Green        = Color3.fromRGB(55,  200, 80),
    Yellow       = Color3.fromRGB(220, 175, 45),
    OnColor      = Color3.fromRGB(220, 40,  40),
    OffColor     = Color3.fromRGB(34,  34,  34),
    TrackBG      = Color3.fromRGB(30,  30,  30),
    BindColor    = Color3.fromRGB(28,  28,  28),
    BindActive   = Color3.fromRGB(55,  14,  14),
}

-- ────────────────────────────────────────────────────────────
--  INTERNALS
-- ────────────────────────────────────────────────────────────
local function tw(obj, props, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.13, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function mkStroke(parent, color, thick)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or T.Border; s.Thickness = thick or 1
    return s
end

local function mkPad(parent, t, b, l, r)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    return p
end

local function mkList(parent, dir, gap, sort)
    local l = Instance.new("UIListLayout", parent)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding       = UDim.new(0, gap or 0)
    l.SortOrder     = sort or Enum.SortOrder.LayoutOrder
    return l
end

local function mkScroll(parent)
    local sf = make("ScrollingFrame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
    }, parent)
    mkList(sf, nil, 2)
    mkPad(sf, 8, 8, 8, 8)
    return sf
end

-- Listening flag for keybinds (prevents conflicts)
local _listeningForBind = false

-- ────────────────────────────────────────────────────────────
--  LIBRARY
-- ────────────────────────────────────────────────────────────
local VoidLib = {}
VoidLib.__index = VoidLib

function VoidLib:CreateWindow(title, version)
    -- Remove existing
    local parent = (gethui and gethui()) or CoreGui
    if parent:FindFirstChild("VoidLib_" .. title) then
        pcall(function() parent:FindFirstChild("VoidLib_" .. title):Destroy() end)
    elseif CoreGui:FindFirstChild("VoidLib_" .. title) then
        pcall(function() CoreGui:FindFirstChild("VoidLib_" .. title):Destroy() end)
    end

    local WIN_W   = 660
    local WIN_H   = 580
    local TITLE_H = 42
    local SIDE_W  = 128

    -- ── Root GUI ────────────────────────────────────────────
    local gui = make("ScreenGui", {
        Name           = "VoidLib_" .. title,
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, (gethui and gethui()) or CoreGui)

    -- ── Toast Container ─────────────────────────────────────
    local toastBox = make("Frame", {
        Name = "ToastContainer",
        Size = UDim2.new(0, 275, 0, 480),
        Position = UDim2.new(1, -285, 1, -500),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, gui)
    local tcL = mkList(toastBox, nil, 5)
    tcL.VerticalAlignment = Enum.VerticalAlignment.Bottom

    -- ── Main Window ─────────────────────────────────────────
    local win = make("Frame", {
        Name = "VoidWindow",
        Size = UDim2.new(0, WIN_W, 0, WIN_H),
        Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    mkStroke(win, T.Border, 1)

    -- ── Title Bar ───────────────────────────────────────────
    local titleBar = make("Frame", {
        Size = UDim2.new(1, 0, 0, TITLE_H),
        BackgroundColor3 = T.Panel,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, win)
    mkStroke(titleBar, T.Border, 1)

    -- Left accent stripe
    make("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, titleBar)

    -- Title dot
    make("Frame", {
        Size = UDim2.new(0, 6, 0, 6),
        Position = UDim2.new(0, 14, 0.5, -3),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, titleBar)

    make("TextLabel", {
        Text = title,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.White,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(0, 160, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, titleBar)

    make("TextLabel", {
        Text = version or "",
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextColor3 = T.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 130, 0, 0),
        Size = UDim2.new(0, 50, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, titleBar)

    local hudLabel = make("TextLabel", {
        Name = "HUDLabel",
        Text = "FPS: --  |  PING: --ms",
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.TextDim,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 190, 0, 0),
        Size = UDim2.new(1, -290, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 4,
    }, titleBar)

    -- Auto-Reinject Toggle Button
    local autoReinjectEnabled = false
    local autoReinjectCallback = nil
    local onCloseCallback = nil

    local reinjectBtn = make("TextButton", {
        Text = "↻",
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.TextDim,
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 32, 0, 22),
        Position = UDim2.new(1, -106, 0.5, -11),
        ZIndex = 4,
    }, titleBar)
    mkStroke(reinjectBtn, T.Border, 1)

    -- Minimize
    local minBtn = make("TextButton", {
        Text = "─",
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.TextDim,
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 32, 0, 22),
        Position = UDim2.new(1, -70, 0.5, -11),
        ZIndex = 4,
    }, titleBar)
    mkStroke(minBtn, T.Border, 1)

    local closeBtn = make("TextButton", {
        Text = "✕",
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.Accent,
        BackgroundColor3 = T.AccentMuted,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 32, 0, 22),
        Position = UDim2.new(1, -34, 0.5, -11),
        ZIndex = 4,
    }, titleBar)
    mkStroke(closeBtn, T.AccentDim, 1)

    -- ── Drag ────────────────────────────────────────────────
    local dragging, dStart, wStart
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dStart = i.Position; wStart = win.Position
        end
    end)
    titleBar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            win.Position = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X,
                                      wStart.Y.Scale, wStart.Y.Offset + d.Y)
        end
    end)

    -- ── Minimize / Close ────────────────────────────────────
    local minimized = false
    local resetAllScrolls

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        tw(win, { Size = minimized
            and UDim2.new(0, WIN_W, 0, TITLE_H)
            or  UDim2.new(0, WIN_W, 0, WIN_H) }, 0.2)
        minBtn.Text = minimized and "□" or "─"
        if not minimized and resetAllScrolls then
            task.delay(0.22, resetAllScrolls)
        end
    end)
    closeBtn.MouseButton1Click:Connect(function()
        tw(win, { Size = UDim2.new(0, WIN_W, 0, 0) }, 0.16)
        task.delay(0.18, function()
            pcall(function()
                win.Visible = false
                win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
            end)
        end)
        if onCloseCallback then
            pcall(onCloseCallback)
        end
    end)
    win:GetPropertyChangedSignal("Visible"):Connect(function()
        if win.Visible then
            minimized = false
            minBtn.Text = "─"
            win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
            if resetAllScrolls then
                task.delay(0.22, resetAllScrolls)
            end
        end
    end)
    reinjectBtn.MouseButton1Click:Connect(function()
        autoReinjectEnabled = not autoReinjectEnabled
        reinjectBtn.TextColor3 = autoReinjectEnabled and T.Accent or T.TextDim
        Win:Toast("Auto-Reinject: " .. (autoReinjectEnabled and "ENABLED" or "DISABLED"), autoReinjectEnabled and T.Accent or T.TextDim)
        if autoReinjectCallback then
            autoReinjectCallback(autoReinjectEnabled)
        end
    end)
    reinjectBtn.MouseEnter:Connect(function()  tw(reinjectBtn,  { BackgroundColor3 = T.Hover }) end)
    reinjectBtn.MouseLeave:Connect(function()  tw(reinjectBtn,  { BackgroundColor3 = T.BG    }) end)
    minBtn.MouseEnter:Connect(function()  tw(minBtn,   { BackgroundColor3 = T.Hover }) end)
    minBtn.MouseLeave:Connect(function()  tw(minBtn,   { BackgroundColor3 = T.BG   }) end)
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, { BackgroundColor3 = T.AccentDim  }) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, { BackgroundColor3 = T.AccentMuted }) end)

    -- ── Body (sidebar + content) ─────────────────────────────
    local body = make("Frame", {
        Size = UDim2.new(1, 0, 1, -TITLE_H),
        Position = UDim2.new(0, 0, 0, TITLE_H),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, win)

    -- Sidebar
    local sidebar = make("Frame", {
        Size = UDim2.new(0, SIDE_W, 1, 0),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel = 0,
    }, body)
    mkStroke(sidebar, T.Border, 1)

    -- Sidebar header label
    make("TextLabel", {
        Text = "NAVIGATION",
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -12, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, sidebar)

    local sideTabList = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
    }, sidebar)
    mkList(sideTabList, nil, 2)

    -- Content holder
    local contentHolder = make("Frame", {
        Size = UDim2.new(1, -SIDE_W, 1, 0),
        Position = UDim2.new(0, SIDE_W, 0, 0),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, body)

    -- Separator between sidebar and content
    make("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = T.Border,
        BorderSizePixel = 0,
    }, contentHolder)

    -- ── Window Object ────────────────────────────────────────
    local Win = {
        _tabBtns       = {},
        _tabAccents    = {},
        _contentFrames = {},
        _tabs          = {},
        _toggles       = {},
        _gui           = gui,
        HUDLabel       = hudLabel,
    }

    resetAllScrolls = function()
        pcall(function()
            sideTabList.CanvasPosition = Vector2.new(0, 0)
        end)
        for _, cf in ipairs(Win._contentFrames) do
            pcall(function()
                local scroll = cf:FindFirstChildOfClass("ScrollingFrame")
                if scroll then
                    scroll.CanvasPosition = Vector2.new(0, 0)
                end
            end)
        end
    end

    -- Toast
    function Win:Toast(msg, color)
        color = color or T.Accent
        local f = make("Frame", {
            Size = UDim2.new(0, 265, 0, 42),
            BackgroundColor3 = T.Panel,
            BorderSizePixel = 0,
            Position = UDim2.new(1, 10, 0, 0),
        }, toastBox)
        mkStroke(f, color, 1)

        make("Frame", {
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        }, f)

        make("TextLabel", {
            Text = msg,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextColor3 = T.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -14, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, f)

        tw(f, { Position = UDim2.new(1, -275, 0, 0) }, 0.25)
        task.delay(3.2, function()
            tw(f, { Position = UDim2.new(1, 10, 0, 0) }, 0.2)
            task.delay(0.22, function() pcall(function() f:Destroy() end) end)
        end)
    end

    function Win:Destroy()
        pcall(function() gui:Destroy() end)
    end

    function Win:SetOnClose(callback)
        onCloseCallback = callback
    end

    function Win:ResetAllToggles()
        for _, toggle in ipairs(self._toggles) do
            local labelText = toggle._label and toggle._label.Text or ""
            local labelLower = labelText:lower()
            local isConfig = labelLower:find("afk") or labelLower:find("rejoin") or labelLower:find("reinject") or labelLower:find("toast") or labelLower:find("shift lock") or labelLower:find("coordinates") or labelLower:find("waypoint") or labelLower:find("lag reducer") or labelLower:find("anti-afk")
            if not isConfig then
                pcall(function()
                    toggle:Set(false)
                end)
            end
        end
    end

    function Win:SetAutoReinject(enabled, callback)
        autoReinjectEnabled = enabled
        autoReinjectCallback = callback
        reinjectBtn.TextColor3 = enabled and T.Accent or T.TextDim
    end

    -- Tab switch
    local function switchTab(idx)
        for i, cf in ipairs(Win._contentFrames) do
            cf.Visible = (i == idx)
        end
        for i, btn in ipairs(Win._tabBtns) do
            local active = (i == idx)
            tw(btn, { BackgroundColor3 = active and T.BG or T.Sidebar })
            btn.TextColor3 = active and T.White or T.TextDim
            tw(Win._tabAccents[i], { Size = active and UDim2.new(0, 4, 1, 0) or UDim2.new(0, 0, 1, 0) })
            Win._tabAccents[i].BackgroundColor3 = active and T.Accent or T.Sidebar
        end
    end

    -- AddTab
    function Win:AddTab(name)
        local idx = #self._tabs + 1

        -- Sidebar button
        local tabBtn = make("TextButton", {
            Text = "",
            BackgroundColor3 = idx == 1 and T.BG or T.Sidebar,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 40),
            LayoutOrder = idx,
            ZIndex = 2,
        }, sideTabList)

        -- Left accent bar
        local accentBar = make("Frame", {
            Size = UDim2.new(0, idx == 1 and 4 or 0, 1, 0),
            BackgroundColor3 = idx == 1 and T.Accent or T.Sidebar,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, tabBtn)
        self._tabAccents[idx] = accentBar

        make("TextLabel", {
            Text = name:upper(),
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextColor3 = idx == 1 and T.White or T.TextDim,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 0),
            Size = UDim2.new(1, -16, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 3,
        }, tabBtn)

        self._tabBtns[idx] = tabBtn

        local captIdx = idx
        tabBtn.MouseButton1Click:Connect(function() switchTab(captIdx) end)
        tabBtn.MouseEnter:Connect(function()
            if captIdx ~= (function()
                for i, b in ipairs(self._tabBtns) do
                    if b.BackgroundColor3 == T.AccentMuted then return i end
                end
                return 0
            end)() then
                tw(tabBtn, { BackgroundColor3 = T.Hover })
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            -- revert only if not active
            local isActive = (tabBtn.BackgroundColor3 == T.BG)
            if not isActive then
                tw(tabBtn, { BackgroundColor3 = T.Sidebar })
            end
        end)

        -- Content frame
        local cf = make("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = (idx == 1),
            BorderSizePixel = 0,
        }, contentHolder)
        self._contentFrames[idx] = cf
        self._tabs[idx] = name

        local scroll = mkScroll(cf)

        -- ── TAB OBJECT ───────────────────────────────────────
        local Tab = { _scroll = scroll, _win = self }

        -- ── SECTION ─────────────────────────────────────────
        function Tab:AddSection(label)
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, scroll)

            -- Accent pip
            make("Frame", {
                Size = UDim2.new(0, 3, 0, 10),
                Position = UDim2.new(0, 0, 0.5, -5),
                BackgroundColor3 = T.Accent,
                BorderSizePixel = 0,
            }, row)

            make("TextLabel", {
                Text = label:upper(),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextColor3 = T.TextMuted,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0.75, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            make("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = T.Border,
                BorderSizePixel = 0,
            }, row)

            return row
        end

        -- ── TOGGLE ──────────────────────────────────────────
        function Tab:AddToggle(label, default, callback)
            local state = default or false

            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = T.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            mkStroke(row, T.Border, 1)

            -- Left status strip
            local strip = make("Frame", {
                Size = UDim2.new(0, 2, 1, 0),
                BackgroundColor3 = state and T.Accent or T.Border,
                BorderSizePixel = 0,
            }, row)

            local labelLabel = make("TextLabel", {
                Text = label,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -74, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            -- Toggle Checkbox
            local box = make("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(1, -28, 0.5, -8),
                BackgroundColor3 = state and T.Accent or T.OffColor,
                BorderSizePixel = 0,
            }, row)
            mkStroke(box, T.Border, 1)

            local checkmark = make("TextLabel", {
                Text = state and "✕" or "",
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextColor3 = T.White,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            }, box)

            local hitbox = make("TextButton", {
                Text = "", BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0), ZIndex = 2,
            }, row)

            local Toggle = { Value = state, _label = labelLabel }
            table.insert(self._win._toggles, Toggle)

            local function applyToggle(v)
                Toggle.Value = v
                tw(box, { BackgroundColor3 = v and T.Accent or T.OffColor })
                checkmark.Text = v and "✕" or ""
                tw(strip, { BackgroundColor3 = v and T.Accent or T.Border })
            end

            function Toggle:Set(v)
                applyToggle(v)
                if callback then callback(v) end
            end
            Toggle.SetValue = Toggle.Set

            hitbox.MouseButton1Click:Connect(function()
                applyToggle(not Toggle.Value)
                if callback then callback(Toggle.Value) end
            end)
            hitbox.MouseEnter:Connect(function() tw(row, { BackgroundColor3 = T.Hover }) end)
            hitbox.MouseLeave:Connect(function() tw(row, { BackgroundColor3 = T.PanelAlt }) end)

            return Toggle
        end

        -- ── SLIDER ──────────────────────────────────────────
        function Tab:AddSlider(label, minV, maxV, default, callback)
            local val = math.clamp(default or minV, minV, maxV)

            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = T.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            mkStroke(row, T.Border, 1)

            -- Left strip
            make("Frame", {
                Size = UDim2.new(0, 2, 1, 0),
                BackgroundColor3 = T.AccentDim,
                BorderSizePixel = 0,
            }, row)

            make("TextLabel", {
                Text = label,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 7),
                Size = UDim2.new(0.72, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local valLbl = make("TextLabel", {
                Text = tostring(val),
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextColor3 = T.Accent,
                BackgroundTransparency = 1,
                Position = UDim2.new(0.72, 0, 0, 6),
                Size = UDim2.new(0.28, -12, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)

            local track = make("Frame", {
                Size = UDim2.new(1, -24, 0, 8), -- Thicker panel track!
                Position = UDim2.new(0, 12, 0, 34),
                BackgroundColor3 = T.TrackBG,
                BorderSizePixel = 0,
            }, row)
            mkStroke(track, T.Border, 1)

            local p0 = (val - minV) / math.max(maxV - minV, 1)
            local fill = make("Frame", {
                Size = UDim2.new(p0, 0, 1, 0),
                BackgroundColor3 = T.Accent,
                BorderSizePixel = 0,
            }, track)

            local marker = make("Frame", {
                Size = UDim2.new(0, 4, 1.6, 0),
                Position = UDim2.new(p0, -2, -0.3, 0),
                BackgroundColor3 = T.White,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, track)
            mkStroke(marker, T.Border, 1)

            local Slider = { Value = val }
            local draggingSlider = false

            local function applySlider(absX)
                local tx = track.AbsolutePosition.X
                local tw_ = math.max(track.AbsoluteSize.X, 1)
                local p = math.clamp((absX - tx) / tw_, 0, 1)
                local v = math.floor(minV + (maxV - minV) * p + 0.5)
                Slider.Value = v
                valLbl.Text = tostring(v)
                fill.Size = UDim2.new(p, 0, 1, 0)
                marker.Position = UDim2.new(p, -2, -0.3, 0)
                if callback then callback(v) end
            end

            function Slider:Set(v)
                val = math.clamp(v, minV, maxV)
                local p = (val - minV) / math.max(maxV - minV, 1)
                self.Value = val
                valLbl.Text = tostring(val)
                fill.Size = UDim2.new(p, 0, 1, 0)
                marker.Position = UDim2.new(p, -2, -0.3, 0)
            end
            Slider.SetValue = Slider.Set

            local trackHit = make("TextButton", {
                Text = "", BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 6, 0),
                Position = UDim2.new(0, 0, -2.5, 0),
                ZIndex = 3,
            }, track)
            trackHit.MouseButton1Down:Connect(function()
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

        -- ── BUTTON ──────────────────────────────────────────
        function Tab:AddButton(label, subLabel, callback)
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = T.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            mkStroke(row, T.Border, 1)

            local lbl = make("TextLabel", {
                Text = label,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local btn = make("TextButton", {
                Text = subLabel or "RUN",
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextColor3 = T.White,
                BackgroundColor3 = T.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 84, 0, 24),
                Position = UDim2.new(1, -96, 0.5, -12),
            }, row)
            mkStroke(btn, T.AccentDim, 1)

            btn.MouseButton1Click:Connect(function()
                tw(btn, { BackgroundColor3 = T.AccentGlow }, 0.06)
                task.delay(0.12, function() tw(btn, { BackgroundColor3 = T.Accent }, 0.1) end)
                if callback then callback() end
            end)
            btn.MouseEnter:Connect(function()  tw(btn, { BackgroundColor3 = T.AccentDim  }) end)
            btn.MouseLeave:Connect(function()  tw(btn, { BackgroundColor3 = T.Accent     }) end)
            row.MouseEnter:Connect(function()  tw(row, { BackgroundColor3 = T.Hover      }) end)
            row.MouseLeave:Connect(function()  tw(row, { BackgroundColor3 = T.PanelAlt   }) end)

            local Btn = {}
            function Btn:SetLabel(t) lbl.Text = t end
            return Btn
        end

-- DROPDOWN
function Tab:AddDropdown(label, options, defaultIdx, callback)
    options = typeof(options) == "table" and options or {}
    if #options == 0 then
        options = {"..."}
    end

    local selected = math.clamp(defaultIdx or 1, 1, #options)
    local open = false

    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = T.PanelAlt,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 5,
    }, scroll)
    mkStroke(row, T.Border, 1)

    make("TextLabel", {
        Text = label,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.52, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    }, row)

    local selLbl = make("TextLabel", {
        Text = tostring(options[selected] or "..."),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextColor3 = T.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.52, 0, 0, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local arrow = make("TextLabel", {
        Text = "▼",
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.TextDim,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -22, 0, 0),
        Size = UDim2.new(0, 18, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 5,
    }, row)

    local ddFrame = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 2),
        BackgroundColor3 = T.Panel,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
        ClipsDescendants = true,
    }, row)
    mkStroke(ddFrame, T.Accent, 1)

    local ddScroll = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ZIndex = 20,
    }, ddFrame)
    local ddList = mkList(ddScroll, nil, 0)

    local DD = {
        Value = options[selected],
        Index = selected
    }

    local function getDropdownHeight(count)
        return math.min(count, 5) * 28
    end

    local function syncCanvas()
        task.defer(function()
            local y = ddList.AbsoluteContentSize.Y
            ddScroll.CanvasSize = UDim2.new(0, 0, 0, y)
        end)
    end

    local function applySelection(index, fireCallback)
        if #options == 0 then
            selected = 1
            DD.Index = 1
            DD.Value = "..."
            selLbl.Text = "..."
            return
        end

        selected = math.clamp(index or 1, 1, #options)
        DD.Index = selected
        DD.Value = options[selected]
        selLbl.Text = tostring(DD.Value or "...")
        for _, c in ipairs(ddScroll:GetChildren()) do
            if c:IsA("TextButton") then
                local ci = c:GetAttribute("OptionIndex")
                c.BackgroundColor3 = (ci == selected) and T.AccentDim or T.Panel
            end
        end

        if fireCallback and callback then
            callback(selected, DD.Value)
        end
    end

    local function rebuildOptions()
        for _, c in ipairs(ddScroll:GetChildren()) do
            if c:IsA("TextButton") then
                c:Destroy()
            end
        end

        local visibleHeight = getDropdownHeight(#options)
        ddFrame.Size = UDim2.new(1, 0, 0, visibleHeight)

        for i, opt in ipairs(options) do
            local item = make("TextButton", {
                Text = "  " .. tostring(opt),
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextColor3 = T.Text,
                BackgroundColor3 = (i == selected) and T.AccentDim or T.Panel,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 28),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 21,
            }, ddScroll)

            item:SetAttribute("OptionIndex", i)

            item.MouseButton1Click:Connect(function()
                applySelection(i, true)
                open = false
                ddFrame.Visible = false
                arrow.Text = "▼"
            end)

            item.MouseEnter:Connect(function()
                tw(item, {BackgroundColor3 = T.AccentDim})
            end)

            item.MouseLeave:Connect(function()
                local isSelected = item:GetAttribute("OptionIndex") == selected
                tw(item, {BackgroundColor3 = isSelected and T.AccentDim or T.Panel})
            end)
        end

        syncCanvas()
        applySelection(selected, false)
    end

    function DD:SetOptions(opts)
        local oldValue = self.Value
        options = typeof(opts) == "table" and opts or {}

        if #options == 0 then
            options = {"..."}
        end

        local newIndex = table.find(options, oldValue) or 1
        selected = math.clamp(newIndex, 1, #options)

        rebuildOptions()

        open = false
        ddFrame.Visible = false
        arrow.Text = "▼"
    end

    rebuildOptions()

    local hit = make("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 6,
    }, row)

    hit.MouseButton1Click:Connect(function()
        open = not open
        ddFrame.Visible = open
        arrow.Text = open and "▲" or "▼"
        if open then
            syncCanvas()
        end
    end)

    row.MouseEnter:Connect(function()
        tw(row, {BackgroundColor3 = T.Hover})
    end)

    row.MouseLeave:Connect(function()
        tw(row, {BackgroundColor3 = T.PanelAlt})
    end)

    return DD
end

        -- ── KEYBIND ─────────────────────────────────────────
        function Tab:AddKeybind(label, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.Unknown
            local listening  = false

            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = T.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            mkStroke(row, T.Border, 1)

            make("TextLabel", {
                Text = label,
                TextSize = 12, Font = Enum.Font.GothamBold,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.62, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local function keyName(k)
                local n = tostring(k):gsub("Enum.KeyCode.", "")
                return n == "Unknown" and "NONE" or n:upper()
            end

            local bindBtn = make("TextButton", {
                Text = "[ " .. keyName(currentKey) .. " ]",
                TextSize = 10, Font = Enum.Font.GothamBold,
                TextColor3 = T.TextDim,
                BackgroundColor3 = T.BindColor,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 84, 0, 24),
                Position = UDim2.new(1, -96, 0.5, -12),
            }, row)
            mkStroke(bindBtn, T.Border, 1)

            local KB = { Key = currentKey }

            function KB:Set(key)
                currentKey = key; self.Key = key
                listening = false; _listeningForBind = false
                bindBtn.Text = "[ " .. keyName(key) .. " ]"
                bindBtn.TextColor3 = T.TextDim
                tw(bindBtn, { BackgroundColor3 = T.BindColor })
                mkStroke(bindBtn, T.Border, 1)
            end

            bindBtn.MouseButton1Click:Connect(function()
                if listening then
                    listening = false; _listeningForBind = false
                    bindBtn.Text = "[ " .. keyName(currentKey) .. " ]"
                    bindBtn.TextColor3 = T.TextDim
                    tw(bindBtn, { BackgroundColor3 = T.BindColor })
                else
                    listening = true; _listeningForBind = true
                    bindBtn.Text = "[ ... ]"
                    bindBtn.TextColor3 = T.Accent
                    tw(bindBtn, { BackgroundColor3 = T.BindActive })
                end
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if not listening then return end
                if gpe then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if input.KeyCode == Enum.KeyCode.Escape then
                    listening = false; _listeningForBind = false
                    bindBtn.Text = "[ " .. keyName(currentKey) .. " ]"
                    bindBtn.TextColor3 = T.TextDim
                    tw(bindBtn, { BackgroundColor3 = T.BindColor })
                    return
                end
                KB:Set(input.KeyCode)
                if callback then callback(input.KeyCode) end
            end)

            row.MouseEnter:Connect(function() tw(row, { BackgroundColor3 = T.Hover    }) end)
            row.MouseLeave:Connect(function() tw(row, { BackgroundColor3 = T.PanelAlt }) end)

            return KB
        end

        -- ── INFO ROW ────────────────────────────────────────
        function Tab:AddInfoRow(label, valueStr)
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = T.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            mkStroke(row, T.Border, 1)

            make("TextLabel", {
                Text = label, TextSize = 11, Font = Enum.Font.Gotham,
                TextColor3 = T.TextDim, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.52, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local valLbl = make("TextLabel", {
                Text = valueStr or "--", TextSize = 11, Font = Enum.Font.GothamBold,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Position = UDim2.new(0.52, 0, 0, 0),
                Size = UDim2.new(0.48, -12, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)

            local IR = {}
            function IR:SetValue(v) valLbl.Text = tostring(v) end
            function IR:SetColor(c) valLbl.TextColor3 = c end
            IR.ValueLabel = valLbl
            return IR
        end

        -- ── TEXT INPUT ──────────────────────────────────────
        function Tab:AddTextInput(placeholder, btnTxt, callback)
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = T.PanelAlt,
                BorderSizePixel = 0,
            }, scroll)
            mkStroke(row, T.Accent, 1)

            local box = make("TextBox", {
                PlaceholderText = placeholder or "Type here...",
                Text = "", TextSize = 11, Font = Enum.Font.Gotham,
                TextColor3 = T.Text, PlaceholderColor3 = T.TextMuted,
                BackgroundColor3 = T.Panel, BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Size = UDim2.new(1, -106, 0, 24),
                Position = UDim2.new(0, 8, 0.5, -12),
            }, row)
            mkStroke(box, T.Border, 1)

            local btn = make("TextButton", {
                Text = btnTxt or "GO", TextSize = 10, Font = Enum.Font.GothamBold,
                TextColor3 = T.White, BackgroundColor3 = T.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 84, 0, 24),
                Position = UDim2.new(1, -96, 0.5, -12),
            }, row)
            mkStroke(btn, T.AccentDim, 1)

            btn.MouseButton1Click:Connect(function()
                if callback then callback(box.Text) end
            end)
            box.FocusLost:Connect(function(enter)
                if enter and callback then callback(box.Text) end
            end)
            btn.MouseEnter:Connect(function() tw(btn, { BackgroundColor3 = T.AccentDim }) end)
            btn.MouseLeave:Connect(function() tw(btn, { BackgroundColor3 = T.Accent    }) end)

            local TI = {}
            function TI:GetText() return box.Text end
            function TI:SetText(t) box.Text = t end
            function TI:Clear() box.Text = "" end
            return TI
        end

        -- ── PLAYER LIST ─────────────────────────────────────
        -- btn2Label / btn2Callback are optional (single-action vs dual-action)
        function Tab:AddPlayerList(btn1Label, btn1Cb, btn2Label, btn2Cb)
            local dual = btn2Label ~= nil

            local container = make("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, scroll)
            mkList(container, nil, 2)

            local PL = {}

            function PL:Refresh()
                for _, c in ipairs(container:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p == LP then continue end

                    local row = make("Frame", {
                        Size = UDim2.new(1, 0, 0, 44),
                        BackgroundColor3 = T.PanelAlt,
                        BorderSizePixel = 0,
                    }, container)
                    mkStroke(row, T.Border, 1)

                    local av = make("ImageLabel", {
                        Size = UDim2.new(0, 30, 0, 30),
                        Position = UDim2.new(0, 6, 0.5, -15),
                        BackgroundColor3 = T.Panel, BorderSizePixel = 0,
                    }, row)
                    mkStroke(av, T.Border, 1)
                    local cp = p
                    task.spawn(function()
                        local ok, img = pcall(function()
                            return Players:GetUserThumbnailAsync(
                                cp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                        end)
                        if ok then av.Image = img end
                    end)

                    make("TextLabel", {
                        Text = p.DisplayName, TextSize = 12, Font = Enum.Font.GothamBold,
                        TextColor3 = T.Text, BackgroundTransparency = 1,
                        Position = UDim2.new(0, 44, 0, 4),
                        Size = UDim2.new(dual and 0.38 or 0.5, 0, 0, 16),
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row)

                    make("TextLabel", {
                        Text = "@" .. p.Name, TextSize = 10, Font = Enum.Font.Gotham,
                        TextColor3 = T.TextDim, BackgroundTransparency = 1,
                        Position = UDim2.new(0, 44, 0, 22),
                        Size = UDim2.new(dual and 0.38 or 0.5, 0, 0, 14),
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row)

                    -- Button 1
                    local b1W = dual and 58 or 80
                    local b1 = make("TextButton", {
                        Text = btn1Label, TextSize = 10, Font = Enum.Font.GothamBold,
                        TextColor3 = T.White, BackgroundColor3 = T.Accent,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, b1W, 0, 22),
                        Position = dual
                            and UDim2.new(1, -(b1W*2 + 16), 0.5, -11)
                            or  UDim2.new(1, -(b1W + 10),   0.5, -11),
                    }, row)
                    mkStroke(b1, T.AccentDim, 1)

                    local pp = p
                    b1.MouseButton1Click:Connect(function()
                        if btn1Cb then btn1Cb(pp) end
                    end)
                    b1.MouseEnter:Connect(function() tw(b1, { BackgroundColor3 = T.AccentDim }) end)
                    b1.MouseLeave:Connect(function() tw(b1, { BackgroundColor3 = T.Accent    }) end)

                    -- Button 2 (optional)
                    if dual then
                        local b2 = make("TextButton", {
                            Text = btn2Label, TextSize = 10, Font = Enum.Font.GothamBold,
                            TextColor3 = T.TextDim,
                            BackgroundColor3 = T.BindColor,
                            BorderSizePixel = 0,
                            Size = UDim2.new(0, b1W, 0, 22),
                            Position = UDim2.new(1, -(b1W + 8), 0.5, -11),
                        }, row)
                        mkStroke(b2, T.Border, 1)

                        b2.MouseButton1Click:Connect(function()
                            if btn2Cb then btn2Cb(pp) end
                        end)
                        b2.MouseEnter:Connect(function() tw(b2, { BackgroundColor3 = T.Hover     }) end)
                        b2.MouseLeave:Connect(function() tw(b2, { BackgroundColor3 = T.BindColor }) end)
                    end

                    row.MouseEnter:Connect(function() tw(row, { BackgroundColor3 = T.Hover    }) end)
                    row.MouseLeave:Connect(function() tw(row, { BackgroundColor3 = T.PanelAlt }) end)
                end
            end

            PL:Refresh()
            Players.PlayerAdded:Connect(function()   task.defer(function() PL:Refresh() end) end)
            Players.PlayerRemoving:Connect(function() task.defer(function() PL:Refresh() end) end)
            return PL
        end

        -- ── SCROLL FEED ─────────────────────────────────────
        function Tab:AddScrollFeed(height)
            local feed = make("ScrollingFrame", {
                Size = UDim2.new(1, 0, 0, height or 240),
                BackgroundColor3 = T.Panel, BorderSizePixel = 0,
                ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent,
                CanvasSize = UDim2.new(0,0,0,0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ElasticBehavior = Enum.ElasticBehavior.Never,
            }, scroll)
            mkStroke(feed, T.Border, 1)
            mkPad(feed, 5, 5, 8, 8)
            mkList(feed, nil, 2)

            local Feed = {}
            function Feed:AddEntry(text, color)
                local lbl = make("TextLabel", {
                    Text = text, TextSize = 11, Font = Enum.Font.Gotham,
                    TextColor3 = color or T.TextDim,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, feed)
                task.defer(function()
                    pcall(function()
                        feed.CanvasPosition = Vector2.new(0, feed.AbsoluteCanvasSize.Y)
                    end)
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

        -- ── RAW FRAME ───────────────────────────────────────
        function Tab:AddRawFrame(height)
            return make("Frame", {
                Size = UDim2.new(1, 0, 0, height or 60),
                BackgroundColor3 = T.PanelAlt, BorderSizePixel = 0,
            }, scroll)
        end

        -- backward compat alias
        Tab.AddFrame = Tab.AddRawFrame

        return Tab
    end -- AddTab

    -- Start on first tab
    if #Win._contentFrames > 0 then
        Win._contentFrames[1].Visible = true
    end

    return Win
end -- CreateWindow

return VoidLib
