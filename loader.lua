-- =========================================================
--  HUB LOADER — games selector
-- =========================================================

local REPO   = "roblaoxrobot-cell/rainbow_hub"
local BRANCH = "main"
local BASE   = string.format("https://raw.githubusercontent.com/%s/%s/", REPO, BRANCH)

local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local uis          = game:GetService("UserInputService")
local market       = game:GetService("MarketplaceService")
local Preload      = game:GetService("ContentProvider")
local Players      = game:GetService("Players")

local function K()
    local c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local s = ""
    for i = 1, math.random(7, 16) do s = s .. string.sub(c, math.random(1, #c), math.random(1, #c)) end
    return s
end

local Colors = {
    Black=Color3.fromRGB(16,16,16), Header=Color3.fromRGB(21,21,21),
    Section=Color3.fromRGB(24,24,24), Accent=Color3.fromRGB(255,106,133),
    Border=Color3.fromRGB(29,29,29), Text=Color3.fromRGB(255,255,255),
    Muted=Color3.fromRGB(150,150,150), Select=Color3.fromRGB(30,30,30),
    Green=Color3.fromRGB(150,255,150), Red=Color3.fromRGB(255,100,100),
    Purple=Color3.fromRGB(180,120,255),
}

local FontSB = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)

local function Tween(o, p, t, st)
    local tw = TweenService:Create(o, TweenInfo.new(t or 0.35, st or Enum.EasingStyle.Quint), p)
    tw:Play()
    return tw
end

local function Shadow(parent)
    local s = Instance.new("ImageLabel", parent)
    s.AnchorPoint, s.BackgroundTransparency, s.Position = Vector2.new(0.5,0.5), 1, UDim2.new(0.5,0,0.5,0)
    s.Size = UDim2.new(1,47,1,47)
    s.Image, s.ImageColor3, s.ImageTransparency = "rbxassetid://6014261993", Color3.new(0,0,0), 0.75
    s.ScaleType, s.SliceCenter = Enum.ScaleType.Slice, Rect.new(49,49,450,450)
    s.ZIndex = parent.ZIndex - 1
    return s
end

-- STATUS
local Status = {
    UNIVERSAL="In development", RIVALS="Working", FLUXOPVP="Working",
    MM2="Working", SELLLEMONS="Working", PENABLOX="Working",
    EUROPHIUM="Working", SULTANISIMUS="Working", NINJALEGENDS="Working",
}
local function StatusColor(t)
    t = (t or ""):lower()
    if t:find("working") then return Colors.Green
    elseif t:find("broken") then return Colors.Red
    elseif t:find("dev") then return Colors.Purple end
    return Colors.Muted
end

-- UI
local Gui = Instance.new("ScreenGui", CoreGui)
Gui.Name = K()
Gui.ResetOnSpawn = false

local Main = Instance.new("CanvasGroup", Gui)
Main.AnchorPoint, Main.Position = Vector2.new(0.5,0.5), UDim2.new(0.5,0,0.5,0)
Main.Size, Main.BackgroundColor3, Main.BorderSizePixel = UDim2.new(0,560,0,340), Colors.Black, 0
Main.GroupTransparency = 1
local MC = Instance.new("UICorner", Main)
MC.CornerRadius = UDim.new(0,2)
local MShadow = Shadow(Main)
MShadow.ImageTransparency = 1

local function Close()
    Tween(MShadow, {ImageTransparency=1}, 0.4, Enum.EasingStyle.Linear)
    Tween(MC, {CornerRadius=UDim.new(1,0)}, 0.4, Enum.EasingStyle.Linear)
    local t = Tween(Main, {Size=UDim2.new(0,0,0,0), GroupTransparency=1}, 0.4, Enum.EasingStyle.Linear)
    t.Completed:Wait()
    Gui:Destroy()
end

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1,0,1,0)
Content.BackgroundTransparency = 1
Content.Visible = false

local LoadLbl = Instance.new("TextLabel", Main)
LoadLbl.Size = UDim2.new(1,0,1,0)
LoadLbl.BackgroundTransparency = 1
LoadLbl.FontFace = FontSB
LoadLbl.TextColor3 = Colors.Muted
LoadLbl.TextSize = 14
LoadLbl.Text = "LOADING ASSETS..."

local Header = Instance.new("Frame", Content)
Header.Size, Header.BackgroundColor3, Header.BorderSizePixel = UDim2.new(1,0,0,40), Colors.Header, 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0,2)

local Title = Instance.new("TextLabel", Header)
Title.Position, Title.Size, Title.BackgroundTransparency = UDim2.new(0,15,0,0), UDim2.new(0,300,1,0), 1
Title.FontFace, Title.TextSize = FontSB, 17
Title.RichText = true
Title.Text = '<font color="#ffffff">RAINBOW</font><font color="#ff6a85"> HUB</font>'
Title.TextXAlignment = Enum.TextXAlignment.Left

local XBtn = Instance.new("TextButton", Header)
XBtn.AnchorPoint, XBtn.Position = Vector2.new(1,0.5), UDim2.new(1,-12,0.5,0)
XBtn.Size = UDim2.new(0,24,0,24)
XBtn.BackgroundTransparency = 1
XBtn.Text = "X"
XBtn.TextColor3 = Colors.Muted
XBtn.FontFace = FontSB
XBtn.TextSize = 16
XBtn.MouseButton1Click:Connect(Close)

local Side = Instance.new("Frame", Content)
Side.Position, Side.Size = UDim2.new(0,12,0,52), UDim2.new(0,200,1,-64)
Side.BackgroundColor3, Side.BorderSizePixel = Colors.Section, 0
Instance.new("UICorner", Side).CornerRadius = UDim.new(0,2)
Instance.new("UIStroke", Side).Color = Colors.Border

local CountLbl = Instance.new("TextLabel", Side)
CountLbl.Position, CountLbl.Size = UDim2.new(0,8,0,6), UDim2.new(1,-16,0,14)
CountLbl.BackgroundTransparency = 1
CountLbl.FontFace, CountLbl.TextSize = FontSB, 10
CountLbl.TextColor3 = Colors.Muted
CountLbl.TextXAlignment = Enum.TextXAlignment.Left
CountLbl.Text = "9 GAMES SUPPORTED"

local Search = Instance.new("TextBox", Side)
Search.Position, Search.Size = UDim2.new(0,6,0,24), UDim2.new(1,-12,0,26)
Search.BackgroundColor3 = Colors.Select
Search.BorderSizePixel = 0
Search.FontFace, Search.TextSize = FontSB, 11
Search.TextColor3 = Colors.Text
Search.PlaceholderColor3 = Colors.Muted
Search.PlaceholderText = "Search games..."
Search.ClearTextOnFocus = false
Search.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", Search).CornerRadius = UDim.new(0,2)
Instance.new("UIPadding", Search).PaddingLeft = UDim.new(0,8)

local Scroll = Instance.new("ScrollingFrame", Side)
Scroll.Position = UDim2.new(0,5,0,55)
Scroll.Size = UDim2.new(1,-10,1,-60)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel, Scroll.ScrollBarThickness = 0, 4
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0,3)

local Preview = Instance.new("Frame", Content)
Preview.Position, Preview.Size = UDim2.new(0,225,0,52), UDim2.new(1,-237,1,-64)
Preview.BackgroundColor3 = Colors.Section
Instance.new("UICorner", Preview).CornerRadius = UDim.new(0,2)
Instance.new("UIStroke", Preview).Color = Colors.Border

local PImg = Instance.new("ImageLabel", Preview)
PImg.AnchorPoint, PImg.Position = Vector2.new(0.5,0), UDim2.new(0.5,0,0,25)
PImg.Size, PImg.BackgroundColor3 = UDim2.new(0,100,0,100), Colors.Black
Instance.new("UIStroke", PImg).Color = Colors.Border
Instance.new("UICorner", PImg).CornerRadius = UDim.new(0,2)

local PName = Instance.new("TextLabel", Preview)
PName.Position, PName.Size, PName.BackgroundTransparency = UDim2.new(0,0,0,135), UDim2.new(1,0,0,25), 1
PName.FontFace, PName.TextSize, PName.TextColor3 = FontSB, 16, Colors.Text
PName.Text = "N/A"

local PStatus = Instance.new("TextLabel", Preview)
PStatus.Position, PStatus.Size, PStatus.BackgroundTransparency = UDim2.new(0,0,0,165), UDim2.new(1,0,0,20), 1
PStatus.FontFace, PStatus.TextSize, PStatus.TextColor3 = FontSB, 12, Colors.Muted
PStatus.Text = "SELECT A GAME"

local LoadBtn = Instance.new("TextButton", Preview)
LoadBtn.AnchorPoint, LoadBtn.Position = Vector2.new(0.5,1), UDim2.new(0.5,0,1,-15)
LoadBtn.Size, LoadBtn.BackgroundColor3, LoadBtn.BorderSizePixel = UDim2.new(1,-40,0,35), Colors.Accent, 0
LoadBtn.FontFace, LoadBtn.TextSize, LoadBtn.TextColor3 = FontSB, 13, Color3.new(0,0,0)
LoadBtn.Text, LoadBtn.AutoButtonColor = "LOAD SCRIPT", false
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0,2)

-- GAME LIST
local Selected
local Buttons = {}
local Icons = {}

local function Filter(q)
    q = (q or ""):lower()
    for _, e in ipairs(Buttons) do
        e.btn.Visible = (q == "") or (e.name:lower():find(q, 1, true) ~= nil)
    end
end

Search:GetPropertyChangedSignal("Text"):Connect(function() Filter(Search.Text) end)

local function AddGame(name, iconId, fileName, statusKey)
    task.spawn(function()
        local ok, info = pcall(function() return market:GetProductInfo(iconId) end)
        if ok and info then
            local a = "rbxassetid://" .. (info.IconImageAssetId or 0)
            Icons[fileName] = a
            pcall(function() Preload:PreloadAsync({a}) end)
        end
    end)

    local Btn = Instance.new("TextButton", Scroll)
    Btn.Size, Btn.BackgroundTransparency, Btn.Text = UDim2.new(1,0,0,35), 1, ""
    Btn.BackgroundColor3 = Colors.Select
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,2)

    local Txt = Instance.new("TextLabel", Btn)
    Txt.Size, Txt.Position, Txt.BackgroundTransparency = UDim2.new(1,-10,1,0), UDim2.new(0,12,0,0), 1
    Txt.FontFace, Txt.TextSize, Txt.TextColor3 = FontSB, 11, Colors.Muted
    Txt.Text, Txt.TextXAlignment = name:upper(), Enum.TextXAlignment.Left

    Btn.MouseEnter:Connect(function()
        if Selected ~= fileName then
            Tween(Btn, {BackgroundTransparency=0.8}, 0.2)
            Tween(Txt, {TextColor3=Colors.Text}, 0.2)
        end
    end)
    Btn.MouseLeave:Connect(function()
        if Selected ~= fileName then
            Tween(Btn, {BackgroundTransparency=1}, 0.2)
            Tween(Txt, {TextColor3=Colors.Muted}, 0.2)
        end
    end)

    local function SelectThis()
        Selected = fileName
        PName.Text = name:upper()
        for _, v in pairs(Scroll:GetChildren()) do
            if v:IsA("TextButton") then
                v:FindFirstChildOfClass("TextLabel").TextColor3 = Colors.Muted
                v.BackgroundTransparency = 1
            end
        end
        Txt.TextColor3 = Colors.Accent
        Btn.BackgroundTransparency = 0.5
        PImg.Image = Icons[fileName] or ""
        PImg.ImageTransparency = 0
        local s = Status[statusKey] or "Unknown"
        PStatus.Text = "STATUS: " .. s:upper()
        PStatus.TextColor3 = StatusColor(s)
    end

    Btn.MouseButton1Click:Connect(SelectThis)
    table.insert(Buttons, {name = name, btn = Btn})
end

LoadBtn.MouseButton1Click:Connect(function()
    if not Selected then return end
    LoadBtn.Text = "LOADING..."
    local file = Selected

    task.spawn(function()
        -- try games/ folder first, then root
        local urls = {
            BASE .. "games/" .. file .. ".lua",
            BASE .. file .. ".lua",
        }

        local src = nil
        for _, url in ipairs(urls) do
            print("[HUB] Trying: " .. url)
            local ok, body = pcall(function() return game:HttpGet(url) end)
            if ok and body and #body > 50 and not body:find("404: Not Found") then
                src = body
                print("[HUB] Loaded from: " .. url)
                break
            end
        end

        if not src then
            warn("[HUB] Failed to download " .. file)
            LoadBtn.Text = "NOT FOUND"
            task.wait(2)
            LoadBtn.Text = "LOAD SCRIPT"
            return
        end

        local fn, err = loadstring(src)
        if not fn then
            warn("[HUB] Syntax error in " .. file .. ": " .. tostring(err))
            LoadBtn.Text = "SYNTAX ERR"
            task.wait(2)
            LoadBtn.Text = "LOAD SCRIPT"
            return
        end

        local ok, runErr = pcall(fn)
        if not ok then
            warn("[HUB] Runtime error in " .. file .. ": " .. tostring(runErr))
        end

        LoadBtn.Text = "LOADED"
        task.wait(0.3)
        Close()
    end)
end)

-- Drag
local drag, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then drag = false end
        end)
    end
end)
uis.InputChanged:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- REGISTER GAMES  (file name / status key — filename matches file in repo)
AddGame("Universal",        6026568198, "universal",     "UNIVERSAL")
AddGame("Rivals",           6041285839, "rivals",        "RIVALS")
AddGame("Fluxo PvP",        6031265976, "fluxopvp",      "FLUXOPVP")
AddGame("Murder Mystery 2", 7044284832, "mm2",           "MM2")
AddGame("Sell Lemons",      6034509993, "selllemons",    "SELLLEMONS")
AddGame("Penablox HvH",     6035190846, "penablox",      "PENABLOX")
AddGame("Europhium HvH",    7743867811, "europhium",     "EUROPHIUM")
AddGame("Sultanisimus HvH", 6026568198, "sultanisimus",  "SULTANISIMUS")
AddGame("Ninja Legends",    6041285839, "ninjalegends",  "NINJALEGENDS")

-- START
task.spawn(function()
    Main.Size = UDim2.new(0,560,0,0)
    Tween(MShadow, {ImageTransparency=0.75}, 0.8)
    Tween(Main, {GroupTransparency=0, Size=UDim2.new(0,560,0,340)}, 0.6, Enum.EasingStyle.Back)
    task.wait(0.5)
    Tween(LoadLbl, {TextTransparency=1}, 0.3)
    task.wait(0.3)
    LoadLbl:Destroy()
    Content.Visible = true
end)

print("[RAINBOW HUB] Loader ready")
