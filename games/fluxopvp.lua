-- =========================================================
--  FLUXO PVP GAME SCRIPT (games/fluxopvp.lua)
--  Loaded by loader.lua
-- =========================================================

local F = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
if not F then warn("[fluxopvp] Failed to load Fatality UI.") return end
local Notification = F:CreateNotifier()

local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local Workspace  = game:GetService("Workspace")
local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local function keyMatches(input, key)
    if key == nil then return false end
    if typeof(key) == "EnumItem" then return input.KeyCode == key end
    return input.KeyCode.Name == tostring(key)
end

-- =========================================================
--  CONFIG
-- =========================================================
local G = {
    SilentAim = {
        Enabled = false, FOV = 100, Hitbox = "Head", TeamCheck = true,
        ShowFOV = true, FOVColor = Color3.fromRGB(180,100,255), Wallbang = false,
    },
    ESP = {
        Box = false, Health = false, Name = false, Distance = false,
        Tracer = false, Color = Color3.fromRGB(180,100,255),
    },
    Spinbot = {
        Enabled = false, Keybind = Enum.KeyCode.LeftAlt, Mode = "Toggle", Speed = 1440,
    },
    Speed = {
        Enabled = false, Keybind = Enum.KeyCode.LeftControl, Mode = "Hold",
        Value = 36, Default = 16, Holding = false, Active = false,
    },
    Ammo = { Enabled = false },
    Ambient = { Enabled = false, Color = Color3.fromRGB(180,100,255) },
    Watermark = {
        Enabled = false, Text = "RAINBOW HUB",
        Color = Color3.fromRGB(180,100,255), Size = 40,
    },
}

local aimingSpin = false
local spinAngle = 0
local spinConn = nil

F:Loader({ Name = "Rainbow Hub", Duration = 3 })
Notification:Notify({
    Title = "RAINBOW HUB",
    Content = "Welcome, " .. LocalPlayer.DisplayName,
    Icon = "clipboard",
})

-- =========================================================
--  BYPASS — always on (removes iac-respond + resets camera)
-- =========================================================
task.spawn(function()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        for _, c in pairs(rs:GetChildren()) do
            if c:IsA("RemoteEvent") and c.Name == "iac-respond" then c:Destroy() end
        end
        rs.ChildAdded:Connect(function(c)
            if c:IsA("RemoteEvent") and c.Name == "iac-respond" then c:Destroy() end
        end)
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Scriptable
            task.wait(0.1)
            cam.CameraType = Enum.CameraType.Custom
        end
    end)
end)

-- =========================================================
--  DRAWING — Watermark + FOV circle
-- =========================================================
local hasDrawing = pcall(function() return Drawing.new("Text") end)
local watermark, fovCircle

if hasDrawing then
    watermark = Drawing.new("Text")
    watermark.Text = G.Watermark.Text
    watermark.Color = G.Watermark.Color
    watermark.Size = G.Watermark.Size
    watermark.Center = true
    watermark.Outline = true
    watermark.OutlineColor = Color3.new(0,0,0)
    watermark.Transparency = 0.6
    watermark.Visible = false
    RunService.RenderStepped:Connect(function()
        if not watermark then return end
        watermark.Visible = G.Watermark.Enabled
        watermark.Text = G.Watermark.Text
        watermark.Color = G.Watermark.Color
        watermark.Size = G.Watermark.Size
        watermark.Position = Vector2.new(Camera.ViewportSize.X/2, (Camera.ViewportSize.Y/2) - 350)
    end)
end

if hasDrawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.Filled = false
    fovCircle.Transparency = 1
    fovCircle.Visible = false
    RunService.RenderStepped:Connect(function()
        if not fovCircle then return end
        if G.SilentAim.Enabled and G.SilentAim.ShowFOV then
            fovCircle.Visible = true
            fovCircle.Radius = G.SilentAim.FOV
            fovCircle.Color = G.SilentAim.FOVColor
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        else
            fovCircle.Visible = false
        end
    end)
end

-- =========================================================
--  SILENT AIM — Caster.Cast hook
-- =========================================================
task.spawn(function()
    pcall(function()
        local Caster = require(game.ReplicatedStorage.ZexisShared.Modules.Caster)
        if getgenv().FluxoCaster then
            pcall(function() getgenv().FluxoCaster() end)
        end
        local oldCast = Caster.Cast
        Caster.Cast = function(p1, p2, p3, p4, p5, p6)
            if G.SilentAim.Enabled then
                local target = nil
                local maxDist = math.huge
                local mouse = UIS:GetMouseLocation()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local isTeam = G.SilentAim.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team
                        local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
                        local part = plr.Character:FindFirstChild(G.SilentAim.Hitbox) or plr.Character:FindFirstChild("Head")
                        if not isTeam and hum and hum.Health > 0 and part then
                            local sp, on = Camera:WorldToViewportPoint(part.Position)
                            if on then
                                local d = (mouse - Vector2.new(sp.X, sp.Y)).Magnitude
                                if d <= G.SilentAim.FOV and d < maxDist then
                                    maxDist = d
                                    target = plr
                                end
                            end
                        end
                    end
                end
                if target and target.Character then
                    local tPart = target.Character:FindFirstChild(G.SilentAim.Hitbox) or target.Character:FindFirstChild("Head")
                    if tPart then p6 = tPart.Position end
                end
            end
            return oldCast(p1, p2, p3, p4, p5, p6)
        end
        getgenv().FluxoCaster = function() Caster.Cast = oldCast end
    end)
end)

-- =========================================================
--  WALLBANG — namecall hook (shoot remotes only, no camera break)
-- =========================================================
task.spawn(function()
    pcall(function()
        if not hookmetamethod or not getnamecallmethod then return end
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if not G.SilentAim.Wallbang then return oldNamecall(self, ...) end
            local method = getnamecallmethod()

            if method == "FireServer" or method == "InvokeServer" then
                local name = tostring(self):lower()
                if name:find("shoot") or name:find("fire") or name:find("bullet")
                   or name:find("raycast") or name:find("hit") or name:find("dmg") then

                    local args = {...}
                    local playerChars = {}
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            table.insert(playerChars, plr.Character)
                        end
                    end

                    for i, v in ipairs(args) do
                        if typeof(v) == "RaycastParams" then
                            pcall(function()
                                v.FilterDescendantsInstances = playerChars
                                v.FilterType = Enum.RaycastFilterType.Include
                                v.IgnoreWater = true
                            end)
                        elseif typeof(v) == "table" and v.FilterDescendantsInstances ~= nil then
                            pcall(function()
                                v.FilterDescendantsInstances = playerChars
                                v.FilterType = Enum.RaycastFilterType.Include
                            end)
                        end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end

            return oldNamecall(self, ...)
        end))
    end)
end)

-- =========================================================
--  ESP
-- =========================================================
local espData = {}

local function newDraw(kind, props)
    if not hasDrawing then return nil end
    local d = Drawing.new(kind)
    for k, v in pairs(props or {}) do d[k] = v end
    d.Visible = false
    return d
end

local function createESP(plr)
    local d = {}
    d.Box = newDraw("Square", {Thickness=2, Filled=false, Color=G.ESP.Color})
    d.HealthBar = newDraw("Line", {Thickness=2, Color=Color3.new(0,1,0)})
    d.Name = newDraw("Text", {Size=11, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Color=G.ESP.Color})
    d.Dist = newDraw("Text", {Size=10, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Color=G.ESP.Color})
    d.Tracer = newDraw("Line", {Thickness=2, Color=G.ESP.Color})
    espData[plr] = d
    return d
end

local function clearESP(plr)
    local d = espData[plr]
    if not d then return end
    for _, v in pairs(d) do if v then v:Remove() end end
    espData[plr] = nil
end

RunService.RenderStepped:Connect(function()
    if not hasDrawing then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        pcall(function()
            local char = plr.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local myChar = LocalPlayer.Character
            local myHead = myChar and myChar:FindFirstChild("Head")

            if not (hum and hum.Health > 0 and hrp and head and myHead) then
                local d = espData[plr]
                if d then for _, v in pairs(d) do if v then v.Visible = false end end end
                return
            end

            local d = espData[plr] or createESP(plr)

            local rp = Camera:WorldToViewportPoint(hrp.Position)
            local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            local lp = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))

            if rp and hp and lp then
                local boxH = hp.Y - lp.Y
                local boxW = boxH * 0.55
                local bx = rp.X - boxW/2
                local by = rp.Y - boxH/2
                local col = G.ESP.Color

                if d.Box then
                    d.Box.Visible = G.ESP.Box
                    d.Box.Size = Vector2.new(boxW, boxH)
                    d.Box.Position = Vector2.new(bx, by)
                    d.Box.Color = col
                end

                if d.HealthBar then
                    local frac = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                    d.HealthBar.Visible = G.ESP.Health
                    d.HealthBar.From = Vector2.new(bx + boxW + 5, by + boxH*(1-frac))
                    d.HealthBar.To   = Vector2.new(bx + boxW + 5, by + boxH)
                    d.HealthBar.Color = Color3.new(1-frac, frac, 0)
                end

                if d.Name then
                    d.Name.Visible = G.ESP.Name
                    d.Name.Text = plr.Name
                    d.Name.Position = Vector2.new(bx + boxW/2, by - 20)
                    d.Name.Color = col
                end

                if d.Dist then
                    d.Dist.Visible = G.ESP.Distance
                    d.Dist.Text = tostring(math.floor((hrp.Position - myHead.Position).Magnitude)) .. "m"
                    d.Dist.Position = Vector2.new(bx + boxW/2, by + boxH + 2)
                    d.Dist.Color = col
                end

                if d.Tracer then
                    d.Tracer.Visible = G.ESP.Tracer
                    local mp = Camera:WorldToViewportPoint(myHead.Position)
                    d.Tracer.From = Vector2.new(mp.X, mp.Y)
                    d.Tracer.To   = Vector2.new(rp.X, rp.Y)
                    d.Tracer.Color = col
                end
            end
        end)
    end
end)

Players.PlayerAdded:Connect(function(p)
    task.wait(0.5)
    if not espData[p] then createESP(p) end
end)
Players.PlayerRemoving:Connect(function(p) pcall(clearESP, p) end)

-- =========================================================
--  SPEED (loop-based, Hold & Toggle work)
-- =========================================================
task.spawn(function()
    while task.wait(0.15) do
        pcall(function()
            if not G.Speed.Enabled then return end
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if G.Speed.Mode == "Hold" then
                    if not G.Speed.Holding then
                        if hum.WalkSpeed ~= G.Speed.Default then hum.WalkSpeed = G.Speed.Default end
                    end
                elseif G.Speed.Mode == "Toggle" then
                    hum.WalkSpeed = G.Speed.Active and G.Speed.Value or G.Speed.Default
                end
            end
        end)
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if not G.Speed.Enabled then return end
    if keyMatches(input, G.Speed.Keybind) then
        if G.Speed.Mode == "Hold" then
            G.Speed.Holding = true
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = G.Speed.Value end
        else
            G.Speed.Active = not G.Speed.Active
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if not G.Speed.Enabled then return end
    if G.Speed.Mode == "Hold" and keyMatches(input, G.Speed.Keybind) then
        G.Speed.Holding = false
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = G.Speed.Default end
    end
end)

-- =========================================================
--  SPINBOT
-- =========================================================
local function startSpin()
    if spinConn then return end
    spinConn = RunService.RenderStepped:Connect(function(dt)
        if not aimingSpin then return end
        pcall(function()
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                spinAngle = spinAngle + math.rad(G.Spinbot.Speed * dt)
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
            end
        end)
    end)
end

local function stopSpin()
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    aimingSpin = false
end

UIS.InputBegan:Connect(function(input, gp)
    if not G.Spinbot.Enabled then return end
    if keyMatches(input, G.Spinbot.Keybind) then
        if G.Spinbot.Mode == "Toggle" then
            aimingSpin = not aimingSpin
            if aimingSpin then startSpin() end
        else
            aimingSpin = true
            startSpin()
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if G.Spinbot.Enabled and G.Spinbot.Mode == "Hold" and keyMatches(input, G.Spinbot.Keybind) then
        aimingSpin = false
    end
end)

-- =========================================================
--  INFINITE AMMO LOOP
-- =========================================================
task.spawn(function()
    while task.wait(0.5) do
        if G.Ammo.Enabled then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        for _, name in ipairs({"Ammo","Magazine","Bullets","CurrentAmmo","Clip","MaxAmmo","Stored","ReserveAmmo","Amount"}) do
                            local p = tool:FindFirstChild(name)
                            if p then p.Value = 999 end
                        end
                    end
                end
            end)
        end
    end
end)

-- =========================================================
--  PURPLE AMBIENT LOOP
-- =========================================================
task.spawn(function()
    while task.wait(1) do
        if G.Ambient.Enabled then
            pcall(function()
                Lighting.Ambient = G.Ambient.Color
                Lighting.OutdoorAmbient = G.Ambient.Color
                Lighting.Brightness = 1.5
            end)
        end
    end
end)

-- =========================================================
--  RESPAWN HANDLER
-- =========================================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    aimingSpin = false
    stopSpin()
end)

-- =========================================================
--  UI
-- =========================================================
local Window = F.new({ Name = "Rainbow Hub", Expire = "Fluxo PvP", Keybind = "NONE" })
local Config = Window:AddConfig()
Config:Init("Hub_Fluxo", "HubConfigs")

local AIMenu = Window:AddMenu({ Name = "Silent Aim", Icon = "skull" })
local EMenu  = Window:AddMenu({ Name = "Visuals",    Icon = "eye" })
local MMove  = Window:AddMenu({ Name = "Movement",   Icon = "settings" })
local AMenu  = Window:AddMenu({ Name = "Anti-Aim",   Icon = "shield" })
local XMenu  = Window:AddMenu({ Name = "Misc",       Icon = "cog" })

local vis = true
getgenv().FluxoMenuKey = Enum.KeyCode.Insert
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if keyMatches(input, getgenv().FluxoMenuKey) then
        vis = not vis
        pcall(function() Window:SetVisible(vis) end)
    end
end)

-- Silent Aim UI
do
    local M  = AIMenu:AddSection({ Position='left',   Name="AIM" })
    local F2 = AIMenu:AddSection({ Position='right',  Name="FOV" })
    M:AddToggle({ Name="Enable Silent Aim", Flag="FxSAOn",
        Callback=function(v) G.SilentAim.Enabled = v end })
    M:AddDropdown({ Name="Hitbox", Flag="FxSAHb",
        Values={"Head","Torso","UpperTorso","LowerTorso","HumanoidRootPart"}, Default="Head",
        Callback=function(v) G.SilentAim.Hitbox = v end })
    M:AddToggle({ Name="Team Check", Flag="FxSATeam",
        Callback=function(v) G.SilentAim.TeamCheck = v end })
    M:AddToggle({ Name="Wallbang", Flag="FxSAWall",
        Callback=function(v) G.SilentAim.Wallbang = v end })
    F2:AddSlider({ Name="FOV Radius", Flag="FxSAFOV", Default=100, Min=10, Max=800,
        Callback=function(v) G.SilentAim.FOV = v end })
    F2:AddToggle({ Name="Draw FOV", Flag="FxSADraw",
        Callback=function(v) G.SilentAim.ShowFOV = v end })
    F2:AddColorPicker({ Name="FOV Color", Flag="FxSAFOVC",
        Default=Color3.fromRGB(180,100,255),
        Callback=function(c) G.SilentAim.FOVColor = c end })
end

-- Visuals UI
do
    local M = EMenu:AddSection({ Position='left', Name="ESP" })
    M:AddToggle({ Name="Box ESP", Flag="FxEspBox",
        Callback=function(v) G.ESP.Box = v end })
    M:AddToggle({ Name="Health Bar", Flag="FxEspHp",
        Callback=function(v) G.ESP.Health = v end })
    M:AddToggle({ Name="Name", Flag="FxEspName",
        Callback=function(v) G.ESP.Name = v end })
    M:AddToggle({ Name="Distance", Flag="FxEspDist",
        Callback=function(v) G.ESP.Distance = v end })
    M:AddToggle({ Name="Tracer", Flag="FxEspTrace",
        Callback=function(v) G.ESP.Tracer = v end })
    M:AddColorPicker({ Name="ESP Color", Flag="FxEspCol",
        Default=Color3.fromRGB(180,100,255),
        Callback=function(c) G.ESP.Color = c end })
end

-- Movement UI
do
    local M = MMove:AddSection({ Position='left', Name="SPEED" })
    M:AddToggle({ Name="Enable Speed", Flag="FxSpdOn", Callback=function(v)
        G.Speed.Enabled = v
        if not v then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = G.Speed.Default end
        end
    end })
    M:AddSlider({ Name="Speed Value", Flag="FxSpdVal", Default=36, Min=16, Max=200,
        Callback=function(v) G.Speed.Value = v end })
    M:AddDropdown({ Name="Mode", Flag="FxSpdMode", Values={"Hold","Toggle"}, Default="Hold",
        Callback=function(v) G.Speed.Mode = v; G.Speed.Holding=false; G.Speed.Active=false end })
    M:AddKeybind({ Name="Speed Key", Flag="FxSpdKey", Default=Enum.KeyCode.LeftControl,
        Callback=function(v) if v ~= nil then G.Speed.Keybind = v end end })
end

-- Anti-Aim UI
do
    local M = AMenu:AddSection({ Position='left', Name="SPINBOT" })
    M:AddToggle({ Name="Enable Spinbot", Flag="FxSpinOn", Callback=function(v)
        G.Spinbot.Enabled = v
        if not v then aimingSpin = false; stopSpin() end
    end })
    M:AddSlider({ Name="Spin Speed", Flag="FxSpinSpd", Default=1440, Min=100, Max=5000,
        Callback=function(v) G.Spinbot.Speed = v end })
    M:AddDropdown({ Name="Mode", Flag="FxSpinMode", Values={"Toggle","Hold"}, Default="Toggle",
        Callback=function(v) G.Spinbot.Mode = v; aimingSpin = false end })
    M:AddKeybind({ Name="Spin Key", Flag="FxSpinKey", Default=Enum.KeyCode.LeftAlt,
        Callback=function(v) if v ~= nil then G.Spinbot.Keybind = v end end })
end

-- Misc UI
do
    local M = XMenu:AddSection({ Position='left', Name="EXPLOITS" })
    M:AddToggle({ Name="Infinite Ammo", Flag="FxAmmoOn",
        Callback=function(v) G.Ammo.Enabled = v end })
    M:AddToggle({ Name="Purple Ambient", Flag="FxAmbOn",
        Callback=function(v) G.Ambient.Enabled = v end })
    M:AddColorPicker({ Name="Ambient Color", Flag="FxAmbCol",
        Default=Color3.fromRGB(180,100,255),
        Callback=function(c) G.Ambient.Color = c end })
end

do
    local M = XMenu:AddSection({ Position='center', Name="WATERMARK" })
    M:AddToggle({ Name="Show Watermark", Flag="FxWmOn",
        Callback=function(v) G.Watermark.Enabled = v end })
    M:AddSlider({ Name="Watermark Size", Flag="FxWmSize", Default=40, Min=10, Max=100,
        Callback=function(v) G.Watermark.Size = v end })
    M:AddColorPicker({ Name="Watermark Color", Flag="FxWmCol",
        Default=Color3.fromRGB(180,100,255),
        Callback=function(c) G.Watermark.Color = c end })
end

do
    local M = XMenu:AddSection({ Position='right', Name="MENU" })
    M:AddKeybind({ Name="Menu Keybind", Flag="FxMenuKey", Default=Enum.KeyCode.Insert,
        Callback=function(v) if v ~= nil then getgenv().FluxoMenuKey = v end end })
end

print("[fluxopvp] loaded successfully")
