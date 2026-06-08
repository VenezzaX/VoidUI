--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║               VOID LIBRARY  v2.1                          ║
    ║       Standalone Roblox Luau UI Framework                 ║
    ║       Black · Blocky · Sidebar Admin Panel                ║
    ╚═══════════════════════════════════════════════════════════╝

    FULL API:
        VoidLib:CreateWindow(title, version)       → Win
        Win:AddTab(name)                           → Tab
        Win:Toast(msg, color)
        Win:Destroy()
        Win.HUDLabel                               TextLabel

        Tab:AddSection(label)
        Tab:AddToggle(label, default, cb)          → { Value, Set(v) }
        Tab:AddSlider(label, min, max, def, cb)    → { Value, Set(v) }
        Tab:AddButton(label, btnText, cb)          → { SetLabel(t) }
        Tab:AddDropdown(label, opts, def, cb)      → { Value, Index, SetOptions(t) }
        Tab:AddKeybind(label, defaultKey, cb)      → { Key, Set(k) }
        Tab:AddInfoRow(label, value)               → { SetValue(v), SetColor(c) }
        Tab:AddTextInput(placeholder, btnText, cb) → { GetText(), SetText(t), Clear() }
        Tab:AddPlayerList(b1, c1 [,b2, c2])        → { Refresh() }
        Tab:AddScrollFeed(height)                  → { AddEntry(t,c), Clear() }
        Tab:AddFrame(height)                       → Frame
]]

-- ────────────────────────────────────────────────────────
--  SERVICES
-- ────────────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

-- ────────────────────────────────────────────────────────
--  THEME
-- ────────────────────────────────────────────────────────
local C = {
    BG         = Color3.fromRGB(6,   6,   6),
    Sidebar    = Color3.fromRGB(11,  11,  11),
    Panel      = Color3.fromRGB(15,  15,  15),
    Row        = Color3.fromRGB(19,  19,  19),
    Hover      = Color3.fromRGB(27,  27,  27),
    Border     = Color3.fromRGB(34,  34,  34),
    BorderHi   = Color3.fromRGB(52,  52,  52),
    Accent     = Color3.fromRGB(218, 38,  38),
    AccentDim  = Color3.fromRGB(130, 20,  20),
    AccentGlow = Color3.fromRGB(255, 75,  75),
    AccentBG   = Color3.fromRGB(45,  10,  10),
    Text       = Color3.fromRGB(232, 232, 232),
    TextSub    = Color3.fromRGB(120, 120, 120),
    TextMuted  = Color3.fromRGB(58,  58,  58),
    White      = Color3.fromRGB(255, 255, 255),
    Green      = Color3.fromRGB(50,  195, 75),
    Yellow     = Color3.fromRGB(218, 170, 42),
    Red        = Color3.fromRGB(218, 38,  38),
    Track      = Color3.fromRGB(28,  28,  28),
    On         = Color3.fromRGB(218, 38,  38),
    Off        = Color3.fromRGB(32,  32,  32),
}

-- ────────────────────────────────────────────────────────
--  HELPERS
-- ────────────────────────────────────────────────────────
local function anim(obj, goal, t, s, d)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.13, s or Enum.EasingStyle.Quart, d or Enum.EasingDirection.Out),
        goal):Play()
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function outline(parent, color, thick)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or C.Border; s.Thickness = thick or 1
    return s
end

local function padding(parent, t, b, l, r)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
end

local function vList(parent, gap)
    local l = Instance.new("UIListLayout", parent)
    l.FillDirection = Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, gap or 0)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    return l
end

local function hList(parent, gap)
    local l = Instance.new("UIListLayout", parent)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, gap or 0)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    return l
end

local function scrollFrame(parent)
    local sf = new("ScrollingFrame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
    }, parent)
    vList(sf, 2)
    padding(sf, 8, 10, 8, 8)
    return sf
end

-- Global: is a keybind currently being recorded?
local _bindActive = false

-- ════════════════════════════════════════════════════════
--  LIBRARY
-- ════════════════════════════════════════════════════════
local VoidLib = {}
VoidLib.__index = VoidLib

function VoidLib:CreateWindow(title, version)
    if CoreGui:FindFirstChild("VL_" .. title) then
        CoreGui:FindFirstChild("VL_" .. title):Destroy()
    end

    local W, H     = 620, 460
    local TH       = 42   -- titlebar height
    local SW       = 130  -- sidebar width

    -- Root
    local gui = new("ScreenGui", {
        Name = "VL_" .. title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, CoreGui)

    -- Toast container (bottom right)
    local toastHolder = new("Frame", {
        Size = UDim2.new(0,278,0,500),
        Position = UDim2.new(1,-288,1,-510),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, gui)
    local tl = vList(toastHolder, 5)
    tl.VerticalAlignment = Enum.VerticalAlignment.Bottom

    -- Main window
    local win = new("Frame", {
        Name = "Win",
        Size = UDim2.new(0,W,0,H),
        Position = UDim2.new(0.5,-W/2,0.5,-H/2),
        BackgroundColor3 = C.BG, BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    outline(win, C.Border, 1)

    -- ── Titlebar ────────────────────────────────────────
    local tb = new("Frame", {
        Size = UDim2.new(1,0,0,TH),
        BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 4,
    }, win)
    outline(tb, C.Border, 1)

    -- Accent stripe
    new("Frame", { Size=UDim2.new(0,3,1,0), BackgroundColor3=C.Accent, BorderSizePixel=0, ZIndex=5 }, tb)

    -- Logo dot
    new("Frame", { Size=UDim2.new(0,7,0,7), Position=UDim2.new(0,13,0.5,-3.5),
        BackgroundColor3=C.Accent, BorderSizePixel=0, ZIndex=5 }, tb)

    -- Title
    new("TextLabel", { Text=title, TextSize=14, Font=Enum.Font.GothamBold,
        TextColor3=C.White, BackgroundTransparency=1,
        Position=UDim2.new(0,26,0,0), Size=UDim2.new(0,155,1,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5 }, tb)

    -- Version
    new("TextLabel", { Text=version or "", TextSize=9, Font=Enum.Font.Gotham,
        TextColor3=C.TextMuted, BackgroundTransparency=1,
        Position=UDim2.new(0,128,0,0), Size=UDim2.new(0,55,1,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5 }, tb)

    -- HUD label (center)
    local hudLbl = new("TextLabel", {
        Name="HUDLabel", Text="FPS: --  |  PING: --ms",
        TextSize=10, Font=Enum.Font.GothamBold,
        TextColor3=C.TextSub, BackgroundTransparency=1,
        Position=UDim2.new(0,188,0,0),
        Size=UDim2.new(1,-290,1,0),
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=5,
    }, tb)

    -- Window buttons
    local minBtn = new("TextButton", {
        Text="─", TextSize=12, Font=Enum.Font.GothamBold,
        TextColor3=C.TextSub, BackgroundColor3=C.BG,
        BorderSizePixel=0, Size=UDim2.new(0,30,0,22),
        Position=UDim2.new(1,-68,0.5,-11), ZIndex=5,
    }, tb)
    outline(minBtn, C.Border, 1)

    local xBtn = new("TextButton", {
        Text="✕", TextSize=11, Font=Enum.Font.GothamBold,
        TextColor3=C.Accent, BackgroundColor3=C.AccentBG,
        BorderSizePixel=0, Size=UDim2.new(0,30,0,22),
        Position=UDim2.new(1,-34,0.5,-11), ZIndex=5,
    }, tb)
    outline(xBtn, C.AccentDim, 1)

    -- Drag
    local dragging, ds, ws
    tb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging=true; ds=i.Position; ws=win.Position
        end
    end)
    tb.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            win.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
        end
    end)

    -- Minimize / Close
    local mini=false
    minBtn.MouseButton1Click:Connect(function()
        mini=not mini
        anim(win,{Size=mini and UDim2.new(0,W,0,TH) or UDim2.new(0,W,0,H)},0.2)
        minBtn.Text=mini and "□" or "─"
    end)
    xBtn.MouseButton1Click:Connect(function()
        anim(win,{Size=UDim2.new(0,W,0,0)},0.15)
        task.delay(0.16,function() pcall(function() gui:Destroy() end) end)
    end)
    minBtn.MouseEnter:Connect(function() anim(minBtn,{BackgroundColor3=C.Hover}) end)
    minBtn.MouseLeave:Connect(function() anim(minBtn,{BackgroundColor3=C.BG})   end)
    xBtn.MouseEnter:Connect(function()  anim(xBtn,{BackgroundColor3=C.AccentDim}) end)
    xBtn.MouseLeave:Connect(function()  anim(xBtn,{BackgroundColor3=C.AccentBG})  end)

    -- ── Body (sidebar + content) ─────────────────────────
    local body = new("Frame", {
        Size=UDim2.new(1,0,1,-TH), Position=UDim2.new(0,0,0,TH),
        BackgroundTransparency=1, BorderSizePixel=0,
    }, win)

    -- Sidebar
    local sidebar = new("Frame", {
        Size=UDim2.new(0,SW,1,0),
        BackgroundColor3=C.Sidebar, BorderSizePixel=0,
    }, body)
    outline(sidebar, C.Border, 1)

    -- Sidebar top label
    new("TextLabel", {
        Text="MENU", TextSize=8, Font=Enum.Font.GothamBold,
        TextColor3=C.TextMuted, BackgroundTransparency=1,
        Position=UDim2.new(0,12,0,8), Size=UDim2.new(1,0,0,18),
        TextXAlignment=Enum.TextXAlignment.Left,
    }, sidebar)

    local tabStack = new("Frame", {
        Size=UDim2.new(1,0,1,-26), Position=UDim2.new(0,0,0,26),
        BackgroundTransparency=1, BorderSizePixel=0,
    }, sidebar)
    vList(tabStack, 1)

    -- Content
    local content = new("Frame", {
        Size=UDim2.new(1,-SW,1,0), Position=UDim2.new(0,SW,0,0),
        BackgroundColor3=C.BG, BorderSizePixel=0, ClipsDescendants=true,
    }, body)

    -- Separator line between sidebar & content
    new("Frame", { Size=UDim2.new(0,1,1,0), BackgroundColor3=C.Border, BorderSizePixel=0 }, content)

    -- ── Window Object ─────────────────────────────────────
    local Win = {
        _tabBtns   = {},
        _tabAccent = {},
        _tabLabels = {},
        _tabFrames = {},
        _activeIdx = 1,
        _gui       = gui,
        HUDLabel   = hudLbl,
    }

    -- Toast
    function Win:Toast(msg, col)
        col = col or C.Accent
        local f = new("Frame", {
            Size=UDim2.new(0,268,0,40),
            BackgroundColor3=C.Panel, BorderSizePixel=0,
            Position=UDim2.new(1,10,0,0),
        }, toastHolder)
        outline(f, col, 1)
        new("Frame", { Size=UDim2.new(0,3,1,0), BackgroundColor3=col, BorderSizePixel=0 }, f)
        new("TextLabel", {
            Text=msg, TextSize=11, Font=Enum.Font.GothamBold,
            TextColor3=C.Text, BackgroundTransparency=1,
            Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-14,1,0),
            TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,
        }, f)
        anim(f, {Position=UDim2.new(1,-278,0,0)}, 0.25)
        task.delay(3, function()
            anim(f, {Position=UDim2.new(1,10,0,0)}, 0.2)
            task.delay(0.22, function() pcall(function() f:Destroy() end) end)
        end)
    end

    function Win:Destroy()
        pcall(function() gui:Destroy() end)
    end

    -- Internal: switch active tab
    local function switchTab(idx)
        Win._activeIdx = idx
        for i, btn in ipairs(Win._tabBtns) do
            local on = (i==idx)
            anim(btn, {BackgroundColor3 = on and C.AccentBG or C.Sidebar})
            Win._tabLabels[i].TextColor3 = on and C.White or C.TextSub
            anim(Win._tabAccent[i], {BackgroundColor3 = on and C.Accent or C.Sidebar})
        end
        for i, frame in ipairs(Win._tabFrames) do
            frame.Visible = (i==idx)
        end
    end

    -- AddTab
    function Win:AddTab(name)
        local idx = #self._tabBtns + 1

        -- Sidebar button
        local btn = new("TextButton", {
            Text="", BackgroundColor3=idx==1 and C.AccentBG or C.Sidebar,
            BorderSizePixel=0, Size=UDim2.new(1,0,0,40), ZIndex=3,
        }, tabStack)

        -- Left accent bar
        local bar = new("Frame", {
            Size=UDim2.new(0,3,1,0),
            BackgroundColor3=idx==1 and C.Accent or C.Sidebar,
            BorderSizePixel=0, ZIndex=4,
        }, btn)
        self._tabAccent[idx] = bar

        local lbl = new("TextLabel", {
            Text=name:upper(), TextSize=11, Font=Enum.Font.GothamBold,
            TextColor3=idx==1 and C.White or C.TextSub,
            BackgroundTransparency=1,
            Position=UDim2.new(0,14,0,0), Size=UDim2.new(1,-14,1,0),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
        }, btn)
        self._tabLabels[idx] = lbl
        self._tabBtns[idx]   = btn

        local ci = idx
        btn.MouseButton1Click:Connect(function() switchTab(ci) end)
        btn.MouseEnter:Connect(function()
            if Win._activeIdx ~= ci then anim(btn,{BackgroundColor3=C.Hover}) end
        end)
        btn.MouseLeave:Connect(function()
            if Win._activeIdx ~= ci then anim(btn,{BackgroundColor3=C.Sidebar}) end
        end)

        -- Content frame
        local cf = new("Frame", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Visible=idx==1, BorderSizePixel=0,
        }, content)
        self._tabFrames[idx] = cf

        local sf = scrollFrame(cf)

        -- ── TAB COMPONENT BUILDERS ───────────────────────
        local Tab = {}

        -- SECTION
        function Tab:AddSection(label)
            local row = new("Frame", {
                Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, BorderSizePixel=0,
            }, sf)
            new("Frame", {
                Size=UDim2.new(0,3,0,11), Position=UDim2.new(0,0,0.5,-5.5),
                BackgroundColor3=C.Accent, BorderSizePixel=0,
            }, row)
            new("TextLabel", {
                Text=label:upper(), TextSize=9, Font=Enum.Font.GothamBold,
                TextColor3=C.TextSub, BackgroundTransparency=1,
                Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-12,1,0),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, row)
            new("Frame", {
                Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
                BackgroundColor3=C.Border, BorderSizePixel=0,
            }, row)
            return row
        end

        -- TOGGLE
        function Tab:AddToggle(label, default, cb)
            local state = default == true

            local row = new("Frame", {
                Size=UDim2.new(1,0,0,38), BackgroundColor3=C.Row, BorderSizePixel=0,
            }, sf)
            outline(row, C.Border, 1)

            -- Status strip (left edge)
            local strip = new("Frame", {
                Size=UDim2.new(0,2,1,0),
                BackgroundColor3=state and C.Accent or C.Border, BorderSizePixel=0,
            }, row)

            new("TextLabel", {
                Text=label, TextSize=12, Font=Enum.Font.GothamBold,
                TextColor3=C.Text, BackgroundTransparency=1,
                Position=UDim2.new(0,11,0,0), Size=UDim2.new(1,-70,1,0),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, row)

            -- Pill
            local pill = new("Frame", {
                Size=UDim2.new(0,44,0,20), Position=UDim2.new(1,-56,0.5,-10),
                BackgroundColor3=state and C.On or C.Off, BorderSizePixel=0,
            }, row)
            outline(pill, C.Border, 1)

            local knob = new("Frame", {
                Size=UDim2.new(0,14,0,14),
                Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
                BackgroundColor3=C.White, BorderSizePixel=0,
            }, pill)

            local hit = new("TextButton", {
                Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), ZIndex=2,
            }, row)

            local T = { Value=state }
            local function apply(v)
                T.Value = v
                anim(pill,  {BackgroundColor3=v and C.On or C.Off})
                anim(knob,  {Position=v and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
                anim(strip, {BackgroundColor3=v and C.Accent or C.Border})
            end
            function T:Set(v) apply(v); if cb then cb(v) end end
            T.SetValue = T.Set

            hit.MouseButton1Click:Connect(function()
                apply(not T.Value); if cb then cb(T.Value) end
            end)
            hit.MouseEnter:Connect(function() anim(row,{BackgroundColor3=C.Hover})  end)
            hit.MouseLeave:Connect(function() anim(row,{BackgroundColor3=C.Row})    end)
            return T
        end

        -- SLIDER
        function Tab:AddSlider(label, minV, maxV, def, cb)
            local val = math.clamp(def or minV, minV, maxV)

            local row = new("Frame", {
                Size=UDim2.new(1,0,0,50), BackgroundColor3=C.Row, BorderSizePixel=0,
            }, sf)
            outline(row, C.Border, 1)

            new("Frame", { Size=UDim2.new(0,2,1,0), BackgroundColor3=C.AccentDim, BorderSizePixel=0 }, row)

            new("TextLabel", {
                Text=label, TextSize=11, Font=Enum.Font.GothamBold,
                TextColor3=C.Text, BackgroundTransparency=1,
                Position=UDim2.new(0,11,0,6), Size=UDim2.new(0.72,0,0,16),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, row)

            local vLbl = new("TextLabel", {
                Text=tostring(val), TextSize=12, Font=Enum.Font.GothamBold,
                TextColor3=C.Accent, BackgroundTransparency=1,
                Position=UDim2.new(0.72,0,0,5), Size=UDim2.new(0.28,-12,0,18),
                TextXAlignment=Enum.TextXAlignment.Right,
            }, row)

            local track = new("Frame", {
                Size=UDim2.new(1,-22,0,3), Position=UDim2.new(0,11,0,34),
                BackgroundColor3=C.Track, BorderSizePixel=0,
            }, row)

            local p0 = (val-minV)/math.max(maxV-minV,1)
            local fill = new("Frame", {
                Size=UDim2.new(p0,0,1,0), BackgroundColor3=C.Accent, BorderSizePixel=0,
            }, track)
            local thumb = new("Frame", {
                Size=UDim2.new(0,11,0,11), Position=UDim2.new(p0,-6,0.5,-6),
                BackgroundColor3=C.White, BorderSizePixel=0,
            }, track)
            outline(thumb, C.Accent, 1)

            local S = { Value=val }
            local drag=false

            local function applyPos(ax)
                local p = math.clamp((ax-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
                local v = math.floor(minV+(maxV-minV)*p+0.5)
                S.Value=v; vLbl.Text=tostring(v)
                fill.Size=UDim2.new(p,0,1,0); thumb.Position=UDim2.new(p,-6,0.5,-6)
                if cb then cb(v) end
            end
            function S:Set(v)
                v=math.clamp(v,minV,maxV); self.Value=v
                local p=(v-minV)/math.max(maxV-minV,1)
                vLbl.Text=tostring(v)
                fill.Size=UDim2.new(p,0,1,0); thumb.Position=UDim2.new(p,-6,0.5,-6)
            end
            S.SetValue = S.Set

            local th = new("TextButton", {
                Text="", BackgroundTransparency=1,
                Size=UDim2.new(1,0,5,0), Position=UDim2.new(0,0,-2,0), ZIndex=3,
            }, track)
            th.MouseButton1Down:Connect(function()
                drag=true; applyPos(UserInputService:GetMouseLocation().X)
            end)
            UserInputService.InputChanged:Connect(function(i)
                if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                    applyPos(i.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
            end)
            return S
        end

        -- BUTTON
        function Tab:AddButton(label, btnText, cb)
            local row = new("Frame", {
                Size=UDim2.new(1,0,0,38), BackgroundColor3=C.Row, BorderSizePixel=0,
            }, sf)
            outline(row, C.Border, 1)

            local lbl = new("TextLabel", {
                Text=label, TextSize=12, Font=Enum.Font.GothamBold,
                TextColor3=C.Text, BackgroundTransparency=1,
                Position=UDim2.new(0,11,0,0), Size=UDim2.new(0.62,0,1,0),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, row)

            local btn = new("TextButton", {
                Text=btnText or "RUN", TextSize=10, Font=Enum.Font.GothamBold,
                TextColor3=C.White, BackgroundColor3=C.Accent,
                BorderSizePixel=0, Size=UDim2.new(0,84,0,24),
                Position=UDim2.new(1,-96,0.5,-12),
            }, row)
            outline(btn, C.AccentDim, 1)

            btn.MouseButton1Click:Connect(function()
                anim(btn,{BackgroundColor3=C.AccentGlow},0.06)
                task.delay(0.12,function() anim(btn,{BackgroundColor3=C.Accent},0.1) end)
                if cb then cb() end
            end)
            btn.MouseEnter:Connect(function()  anim(btn,{BackgroundColor3=C.AccentDim}) end)
            btn.MouseLeave:Connect(function()  anim(btn,{BackgroundColor3=C.Accent})    end)
            row.MouseEnter:Connect(function()  anim(row,{BackgroundColor3=C.Hover})     end)
            row.MouseLeave:Connect(function()  anim(row,{BackgroundColor3=C.Row})       end)

            local Btn={}
            function Btn:SetLabel(t) lbl.Text=t end
            return Btn
        end

        -- DROPDOWN
        function Tab:AddDropdown(label, opts, def, cb)
            local sel=def or 1; local open=false

            local row = new("Frame", {
                Size=UDim2.new(1,0,0,38), BackgroundColor3=C.Row, BorderSizePixel=0,
                ClipsDescendants=false, ZIndex=5,
            }, sf)
            outline(row, C.Border, 1)

            new("TextLabel", {
                Text=label, TextSize=12, Font=Enum.Font.GothamBold,
                TextColor3=C.Text, BackgroundTransparency=1,
                Position=UDim2.new(0,11,0,0), Size=UDim2.new(0.52,0,1,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
            }, row)

            local selLbl = new("TextLabel", {
                Text=opts[sel] or "...", TextSize=11, Font=Enum.Font.Gotham,
                TextColor3=C.Accent, BackgroundTransparency=1,
                Position=UDim2.new(0.52,0,0,0), Size=UDim2.new(0.4,0,1,0),
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=5,
            }, row)

            local arr = new("TextLabel", {
                Text="▾", TextSize=13, Font=Enum.Font.GothamBold,
                TextColor3=C.TextSub, BackgroundTransparency=1,
                Position=UDim2.new(1,-22,0,0), Size=UDim2.new(0,18,1,0),
                TextXAlignment=Enum.TextXAlignment.Center, ZIndex=5,
            }, row)

            local ddF = new("Frame", {
                Size=UDim2.new(1,0,0,math.min(#opts,5)*28),
                Position=UDim2.new(0,0,1,2),
                BackgroundColor3=C.Panel, BorderSizePixel=0,
                Visible=false, ZIndex=20, ClipsDescendants=true,
            }, row)
            outline(ddF, C.Accent, 1)

            local ddS = new("ScrollingFrame", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0,
                ScrollBarThickness=2, ScrollBarImageColor3=C.Accent,
                CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
                ZIndex=20,
            }, ddF)
            vList(ddS, 0)

            local DD={Value=opts[sel], Index=sel}

            local function buildOpts(o)
                for _,c in ipairs(ddS:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for i,opt in ipairs(o) do
                    local it = new("TextButton", {
                        Text="  "..opt, TextSize=11, Font=Enum.Font.Gotham,
                        TextColor3=C.Text,
                        BackgroundColor3=i==sel and C.AccentDim or C.Panel,
                        BorderSizePixel=0, Size=UDim2.new(1,0,0,28),
                        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=21,
                    }, ddS)
                    local ci=i
                    it.MouseButton1Click:Connect(function()
                        sel=ci; DD.Value=opt; DD.Index=ci
                        selLbl.Text=opt; open=false
                        ddF.Visible=false; arr.Text="▾"
                        row.ZIndex = 5
                        if cb then cb(ci,opt) end
                    end)
                    it.MouseEnter:Connect(function() anim(it,{BackgroundColor3=C.AccentDim}) end)
                    it.MouseLeave:Connect(function()
                        anim(it,{BackgroundColor3=ci==sel and C.AccentDim or C.Panel})
                    end)
                end
            end
            buildOpts(opts)

            function DD:SetOptions(o)
                opts = o
                local oldVal = self.Value
                local found = table.find(o, oldVal)
                if found then
                    sel = found
                    self.Value = oldVal
                    self.Index = found
                    selLbl.Text = oldVal
                else
                    sel = 1
                    self.Value = o[1]
                    self.Index = 1
                    selLbl.Text = o[1] or "..."
                end
                buildOpts(o)
            end

            local hit = new("TextButton", {
                Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), ZIndex=6,
            }, row)
            hit.MouseButton1Click:Connect(function()
                open=not open; ddF.Visible=open; arr.Text=open and "▴" or "▾"
                row.ZIndex = open and 15 or 5
            end)
            row.MouseEnter:Connect(function() anim(row,{BackgroundColor3=C.Hover}) end)
            row.MouseLeave:Connect(function() anim(row,{BackgroundColor3=C.Row})   end)
            return DD
        end

        -- KEYBIND
        function Tab:AddKeybind(label, defKey, cb)
            local curKey = defKey or Enum.KeyCode.Unknown
            local listening = false

            local row = new("Frame", {
                Size=UDim2.new(1,0,0,38), BackgroundColor3=C.Row, BorderSizePixel=0,
            }, sf)
            outline(row, C.Border, 1)

            new("TextLabel", {
                Text=label, TextSize=12, Font=Enum.Font.GothamBold,
                TextColor3=C.Text, BackgroundTransparency=1,
                Position=UDim2.new(0,11,0,0), Size=UDim2.new(0.62,0,1,0),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, row)

            local function kName(k)
                local s=tostring(k):gsub("Enum%.KeyCode%.","")
                return s=="Unknown" and "NONE" or s
            end

            local kBtn = new("TextButton", {
                Text="["..kName(curKey).."]",
                TextSize=10, Font=Enum.Font.GothamBold,
                TextColor3=C.TextSub, BackgroundColor3=C.BG,
                BorderSizePixel=0, Size=UDim2.new(0,80,0,24),
                Position=UDim2.new(1,-92,0.5,-12),
            }, row)
            outline(kBtn, C.Border, 1)

            local KB={Key=curKey}
            function KB:Set(k)
                curKey=k; self.Key=k; listening=false; _bindActive=false
                kBtn.Text="["..kName(k).."]"
                kBtn.TextColor3=C.TextSub
                anim(kBtn,{BackgroundColor3=C.BG})
                outline(kBtn, C.Border, 1)
            end

            kBtn.MouseButton1Click:Connect(function()
                if listening then
                    listening=false; _bindActive=false
                    kBtn.Text="["..kName(curKey).."]"; kBtn.TextColor3=C.TextSub
                    anim(kBtn,{BackgroundColor3=C.BG})
                else
                    listening=true; _bindActive=true
                    kBtn.Text="[...]"; kBtn.TextColor3=C.Accent
                    anim(kBtn,{BackgroundColor3=C.AccentBG})
                end
            end)

            UserInputService.InputBegan:Connect(function(inp, gpe)
                if not listening or gpe then return end
                if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
                if inp.KeyCode==Enum.KeyCode.Escape then
                    KB:Set(curKey)
                else
                    KB:Set(inp.KeyCode)
                    if cb then cb(inp.KeyCode) end
                end
            end)

            row.MouseEnter:Connect(function() anim(row,{BackgroundColor3=C.Hover}) end)
            row.MouseLeave:Connect(function() anim(row,{BackgroundColor3=C.Row})   end)
            return KB
        end

        -- INFO ROW
        function Tab:AddInfoRow(label, val)
            local row = new("Frame", {
                Size=UDim2.new(1,0,0,32), BackgroundColor3=C.Row, BorderSizePixel=0,
            }, sf)
            outline(row, C.Border, 1)

            new("TextLabel", {
                Text=label, TextSize=11, Font=Enum.Font.Gotham,
                TextColor3=C.TextSub, BackgroundTransparency=1,
                Position=UDim2.new(0,11,0,0), Size=UDim2.new(0.54,0,1,0),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, row)

            local vl = new("TextLabel", {
                Text=val or "--", TextSize=11, Font=Enum.Font.GothamBold,
                TextColor3=C.Text, BackgroundTransparency=1,
                Position=UDim2.new(0.54,0,0,0), Size=UDim2.new(0.46,-12,1,0),
                TextXAlignment=Enum.TextXAlignment.Right,
            }, row)

            local IR={}
            function IR:SetValue(v) vl.Text=tostring(v) end
            function IR:SetColor(c) vl.TextColor3=c end
            IR.ValueLabel=vl
            return IR
        end

        -- TEXT INPUT
        function Tab:AddTextInput(placeholder, btnText, cb)
            local row = new("Frame", {
                Size=UDim2.new(1,0,0,38), BackgroundColor3=C.Row, BorderSizePixel=0,
            }, sf)
            outline(row, C.Accent, 1)

            local box = new("TextBox", {
                PlaceholderText=placeholder or "...", Text="",
                TextSize=11, Font=Enum.Font.Gotham,
                TextColor3=C.Text, PlaceholderColor3=C.TextMuted,
                BackgroundColor3=C.BG, BorderSizePixel=0,
                ClearTextOnFocus=false,
                Size=UDim2.new(1,-104,0,24), Position=UDim2.new(0,8,0.5,-12),
            }, row)
            outline(box, C.Border, 1)

            local btn = new("TextButton", {
                Text=btnText or "GO", TextSize=10, Font=Enum.Font.GothamBold,
                TextColor3=C.White, BackgroundColor3=C.Accent,
                BorderSizePixel=0, Size=UDim2.new(0,84,0,24),
                Position=UDim2.new(1,-96,0.5,-12),
            }, row)
            outline(btn, C.AccentDim, 1)

            btn.MouseButton1Click:Connect(function() if cb then cb(box.Text) end end)
            box.FocusLost:Connect(function(enter) if enter and cb then cb(box.Text) end end)
            btn.MouseEnter:Connect(function() anim(btn,{BackgroundColor3=C.AccentDim}) end)
            btn.MouseLeave:Connect(function() anim(btn,{BackgroundColor3=C.Accent})    end)

            local TI={}
            function TI:GetText() return box.Text end
            function TI:SetText(t) box.Text=t end
            function TI:Clear() box.Text="" end
            return TI
        end

        -- PLAYER LIST  (supports 1 or 2 action buttons per row)
        function Tab:AddPlayerList(btn1Lbl, btn1Cb, btn2Lbl, btn2Cb)
            local dual = btn2Lbl ~= nil

            local container = new("Frame", {
                Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1, BorderSizePixel=0,
            }, sf)
            vList(container, 2)

            local PL={}
            function PL:Refresh()
                for _,c in ipairs(container:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _,p in ipairs(Players:GetPlayers()) do
                    if p==LP then continue end

                    local row = new("Frame", {
                        Size=UDim2.new(1,0,0,42), BackgroundColor3=C.Row, BorderSizePixel=0,
                    }, container)
                    outline(row, C.Border, 1)

                    -- Avatar
                    local av = new("ImageLabel", {
                        Size=UDim2.new(0,30,0,30), Position=UDim2.new(0,6,0.5,-15),
                        BackgroundColor3=C.Panel, BorderSizePixel=0,
                    }, row)
                    outline(av, C.Border, 1)
                    local cp=p
                    task.spawn(function()
                        local ok,img=pcall(function()
                            return Players:GetUserThumbnailAsync(
                                cp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                        end)
                        if ok then av.Image=img end
                    end)

                    -- Name + username
                    local nw = dual and 0.36 or 0.52
                    new("TextLabel", {
                        Text=p.DisplayName, TextSize=12, Font=Enum.Font.GothamBold,
                        TextColor3=C.Text, BackgroundTransparency=1,
                        Position=UDim2.new(0,44,0,4), Size=UDim2.new(nw,0,0,16),
                        TextXAlignment=Enum.TextXAlignment.Left,
                    }, row)
                    new("TextLabel", {
                        Text="@"..p.Name, TextSize=10, Font=Enum.Font.Gotham,
                        TextColor3=C.TextSub, BackgroundTransparency=1,
                        Position=UDim2.new(0,44,0,21), Size=UDim2.new(nw,0,0,14),
                        TextXAlignment=Enum.TextXAlignment.Left,
                    }, row)

                    -- Button 1
                    local bw = dual and 56 or 78
                    local b1xOff = dual and -(bw*2+10) or -(bw+10)
                    local b1 = new("TextButton", {
                        Text=btn1Lbl, TextSize=10, Font=Enum.Font.GothamBold,
                        TextColor3=C.White, BackgroundColor3=C.Accent,
                        BorderSizePixel=0, Size=UDim2.new(0,bw,0,22),
                        Position=UDim2.new(1,b1xOff,0.5,-11),
                    }, row)
                    outline(b1, C.AccentDim, 1)
                    local pp=p
                    b1.MouseButton1Click:Connect(function() if btn1Cb then btn1Cb(pp) end end)
                    b1.MouseEnter:Connect(function() anim(b1,{BackgroundColor3=C.AccentDim}) end)
                    b1.MouseLeave:Connect(function() anim(b1,{BackgroundColor3=C.Accent})    end)

                    -- Button 2 (optional)
                    if dual then
                        local b2 = new("TextButton", {
                            Text=btn2Lbl, TextSize=10, Font=Enum.Font.GothamBold,
                            TextColor3=C.TextSub, BackgroundColor3=C.BG,
                            BorderSizePixel=0, Size=UDim2.new(0,bw,0,22),
                            Position=UDim2.new(1,-(bw+6),0.5,-11),
                        }, row)
                        outline(b2, C.Border, 1)
                        b2.MouseButton1Click:Connect(function() if btn2Cb then btn2Cb(pp) end end)
                        b2.MouseEnter:Connect(function() anim(b2,{BackgroundColor3=C.Hover}) end)
                        b2.MouseLeave:Connect(function() anim(b2,{BackgroundColor3=C.BG})   end)
                    end

                    row.MouseEnter:Connect(function() anim(row,{BackgroundColor3=C.Hover}) end)
                    row.MouseLeave:Connect(function() anim(row,{BackgroundColor3=C.Row})   end)
                end
            end

            PL:Refresh()
            Players.PlayerAdded:Connect(function()   task.defer(function() PL:Refresh() end) end)
            Players.PlayerRemoving:Connect(function() task.defer(function() PL:Refresh() end) end)
            return PL
        end

        -- SCROLL FEED
        function Tab:AddScrollFeed(height)
            local feed = new("ScrollingFrame", {
                Size=UDim2.new(1,0,0,height or 240),
                BackgroundColor3=C.Panel, BorderSizePixel=0,
                ScrollBarThickness=3, ScrollBarImageColor3=C.Accent,
                CanvasSize=UDim2.new(0,0,0,0),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                ScrollingDirection=Enum.ScrollingDirection.Y,
                ElasticBehavior=Enum.ElasticBehavior.Never,
            }, sf)
            outline(feed, C.Border, 1)
            padding(feed, 5,5,8,8)
            vList(feed, 2)

            local F={}
            function F:AddEntry(text, col)
                local lbl = new("TextLabel", {
                    Text=text, TextSize=11, Font=Enum.Font.Gotham,
                    TextColor3=col or C.TextSub, BackgroundTransparency=1,
                    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                    TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
                }, feed)
                task.defer(function()
                    pcall(function()
                        feed.CanvasPosition=Vector2.new(0,feed.AbsoluteCanvasSize.Y)
                    end)
                end)
                return lbl
            end
            function F:Clear()
                for _,c in ipairs(feed:GetChildren()) do
                    if c:IsA("TextLabel") then c:Destroy() end
                end
            end
            return F
        end

        -- RAW FRAME  (for custom content)
        function Tab:AddFrame(height)
            return new("Frame", {
                Size=UDim2.new(1,0,0,height or 60),
                BackgroundColor3=C.Row, BorderSizePixel=0,
            }, sf)
        end

        return Tab
    end -- AddTab

    return Win
end -- CreateWindow

return VoidLib
