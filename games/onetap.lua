-- =========================================================================
-- RAINBOW HUB | One Tap | Fatality UI
-- =========================================================================

local CoreGui         = game:GetService("CoreGui")
local Players         = game:GetService("Players")
local Workspace       = game:GetService("Workspace")
local RunService      = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local SoundService    = game:GetService("SoundService")
local Lighting        = game:GetService("Lighting")
local HttpService     = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- =========================================================================
-- [ FATALITY LOADER ]
-- =========================================================================
local function GetFatality()
    local ok, F = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
    end)
    if not ok or not F then warn("[RH] Fatality load failed") return nil end
    return F
end

local function keyMatches(input, key)
    if key == nil then return false end
    if typeof(key) == "EnumItem" then return input.KeyCode == key end
    return input.KeyCode.Name == tostring(key)
end

-- =========================================================================
-- [ HELPERS ]
-- =========================================================================
local function getTeam(player)
    if not player then return nil end
    if player.Team then return player.Team.Name end
    return nil
end

local function isAlive(character)
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isEnemy(player)
    if not player or player == LP then return false end
    local myTeam = getTeam(LP)
    local theirTeam = getTeam(player)
    if myTeam and theirTeam then return myTeam ~= theirTeam end
    return true
end

local function lerpColor(a, b, t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

-- =========================================================================
-- [ MIRROR LAYER ]
-- =========================================================================
local Toggles = {}
local Options = {}

local function mirrorToggle(name, def)
    local t = { Value = def or false }
    Toggles[name] = t
    return t
end

local function mirrorOption(name, def)
    local o = { Value = def }
    Options[name] = o
    return o
end

-- =========================================================================
-- [ WINDOW INIT ]
-- =========================================================================
local F = GetFatality()
if not F then return end
local Notification = F:CreateNotifier()
if getgenv().RH_OneTap_Loaded then return end
getgenv().RH_OneTap_Loaded = true

F:Loader({Name = "Rainbow Hub", Duration = 3})
Notification:Notify({Title="RAINBOW HUB", Content="Welcome, " .. LP.DisplayName, Icon="clipboard"})

local Window = F.new({Name="Rainbow Hub", Expire="One Tap", Keybind="NONE"})
local Config = Window:AddConfig()
Config:Init("Hub_OneTap", "HubConfigs")

local MenuVisible = true
getgenv().RH_MenuKey = Enum.KeyCode.Insert

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if keyMatches(input, getgenv().RH_MenuKey) then
        MenuVisible = not MenuVisible
        pcall(function() Window:SetVisible(MenuVisible) end)
    end
end)

-- =========================================================================
-- [ MENUS ]
-- =========================================================================
local CombatMenu  = Window:AddMenu({Name="Combat",     Icon="skull"})
local VisualsMenu = Window:AddMenu({Name="Visuals",    Icon="eye"})
local MiscMenu    = Window:AddMenu({Name="Misc",       Icon="cog"})
local SetMenu     = Window:AddMenu({Name="Settings",   Icon="cog"})

-- =========================================================================
-- [ UI WRAPPERS ]
-- =========================================================================
local function AddToggle(section, name, opts)
    opts = opts or {}
    local m = mirrorToggle(name, opts.Default or false)
    section:AddToggle({
        Name = opts.Text or name,
        Flag = "RH_T_"..name,
        Default = opts.Default or false,
        Callback = function(v)
            m.Value = v
            if opts.Callback then pcall(opts.Callback, v) end
        end
    })
    return m
end

local function AddSlider(section, name, opts)
    opts = opts or {}
    local m = mirrorOption(name, opts.Default or 0)
    section:AddSlider({
        Name = opts.Text or name,
        Flag = "RH_S_"..name,
        Default = opts.Default or 0,
        Min = opts.Min or 0,
        Max = opts.Max or 100,
        Round = opts.Rounding or 0,
        Callback = function(v)
            m.Value = v
            if opts.Callback then pcall(opts.Callback, v) end
        end
    })
    return m
end

local function AddDropdown(section, name, opts)
    opts = opts or {}
    local m = mirrorOption(name, opts.Default or (opts.Values and opts.Values[1]) or "")
    section:AddDropdown({
        Name = opts.Text or name,
        Flag = "RH_D_"..name,
        Values = opts.Values or {},
        Default = opts.Default,
        Callback = function(v)
            m.Value = v
            if opts.Callback then pcall(opts.Callback, v) end
        end
    })
    return m
end

local function AddKeybind(section, name, opts)
    opts = opts or {}
    local m = mirrorOption(name, opts.Default or Enum.KeyCode.Unknown)
    section:AddKeybind({
        Name = opts.Text or name,
        Flag = "RH_K_"..name,
        Default = opts.Default or Enum.KeyCode.Unknown,
        Callback = function(v)
            m.Value = v
            if opts.Callback then pcall(opts.Callback, v) end
        end
    })
    return m
end

local function AddColor(section, name, opts)
    opts = opts or {}
    local m = mirrorOption(name, opts.Default or Color3.new(1,1,1))
    section:AddColorPicker({
        Name = opts.Title or opts.Text or name,
        Flag = "RH_C_"..name,
        Default = opts.Default or Color3.new(1,1,1),
        Callback = function(v)
            m.Value = v
            if opts.Callback then pcall(opts.Callback, v) end
        end
    })
    return m
end

local function AddButton(section, name, cb)
    section:AddButton({Name=name, Callback = cb})
end

-- =========================================================================
-- [ SETTINGS TAB ]
-- =========================================================================
do
    local S = SetMenu:AddSection({Position='left', Name="INTERFACE"})
    AddKeybind(S, "MenuKeybind", {Text="Menu Keybind", Default=Enum.KeyCode.Insert,
        Callback=function(v) if v~=nil then getgenv().RH_MenuKey=v end end})
    AddButton(S, "Unload", function()
        pcall(function() Window:SetVisible(false) end)
        getgenv().RH_OneTap_Loaded = false
    end)
end

-- =========================================================================
-- [ MISC TAB ]
-- =========================================================================
do
    local S = MiscMenu:AddSection({Position='left', Name="MOVEMENT"})
    AddToggle(S, "AutoBhop", {Text="Auto Bhop", Default=false})
    AddSlider(S, "BhopSpeed", {Text="Bhop Speed", Default=18, Min=5, Max=30, Rounding=1})
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        if not Toggles.AutoBhop.Value then return end
        local char = LP.Character
        if not char then return end
        local rp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local rp2 = RaycastParams.new()
            rp2.FilterDescendantsInstances = {char}
            rp2.FilterType = Enum.RaycastFilterType.Exclude
            if Workspace:Raycast(rp.Position, Vector3.new(0,-4,0), rp2) then
                hum.Jump = true
            end
        end
        -- Bhop speed logic can be added here if needed
    end)
end)

-- =========================================================================
-- [ COMBAT TAB ]
-- =========================================================================
do
    local S = CombatMenu:AddSection({Position='left', Name="SILENT AIM"})
    AddToggle(S, "SilentAim", {Text="Enable Silent Aim", Default=false})
    AddToggle(S, "SilentTeamCheck", {Text="Team Check", Default=true})
    AddToggle(S, "SilentWallbang", {Text="Wallbang", Default=false})
    AddToggle(S, "SilentUseFovCircle", {Text="Use FOV Circle", Default=false})
    AddSlider(S, "SilentFovCircleRadius", {Text="FOV Radius", Default=120, Min=10, Max=500, Rounding=0})
    AddColor(S, "SilentFovColor", {Default=Color3.fromRGB(255,0,0), Title="FOV Color"})
    AddDropdown(S, "SilentHitPart", {Text="Hit Part",
        Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
        Default="Head"})

    local B = CombatMenu:AddSection({Position='center', Name="AUTO FIRE"})
    AddToggle(B, "AutoFire", {Text="Enable Auto Fire", Default=false})
    AddSlider(B, "AutoFireDelay", {Text="Fire Delay", Default=0.05, Min=0.01, Max=1, Rounding=2})
    AddKeybind(B, "AutoFireKey", {Text="Auto Fire Key", Default=Enum.KeyCode.E})

    local C = CombatMenu:AddSection({Position='right', Name="WEAPON MODS"})
    AddToggle(C, "NoRecoil", {Text="No Recoil", Default=false})
    AddToggle(C, "NoSpread", {Text="No Spread", Default=false})
    AddToggle(C, "InstantReload", {Text="Instant Reload", Default=false})
    AddToggle(C, "RapidFire", {Text="Rapid Fire", Default=false})
    AddSlider(C, "RapidFireDelay", {Text="Rapid Fire Delay", Default=0.01, Min=0, Max=0.5, Rounding=3})
end

-- =========================================================================
-- [ VISUALS TAB ]
-- =========================================================================
do
    local S = VisualsMenu:AddSection({Position='left', Name="ESP"})
    AddToggle(S, "ESPEnabled", {Text="ESP Enabled", Default=false})
    AddToggle(S, "ESPTeamCheck", {Text="Team Check", Default=true})
    AddToggle(S, "ESPBox", {Text="Box ESP", Default=true})
    AddColor(S, "ESPBoxColor", {Default=Color3.fromRGB(255,106,133), Title="Box Color"})
    AddToggle(S, "ESPSkeleton", {Text="Skeleton ESP", Default=false})
    AddColor(S, "ESPSkeletonColor", {Default=Color3.fromRGB(0,255,255), Title="Skeleton Color"})
    AddToggle(S, "ESPName", {Text="Name ESP", Default=true})
    AddColor(S, "ESPNameColor", {Default=Color3.new(1,1,1), Title="Name Color"})
    AddToggle(S, "ESPHealth", {Text="Health Bar", Default=true})
    AddColor(S, "ESPHealthTopColor", {Default=Color3.fromRGB(0,255,0), Title="Health Top"})
    AddColor(S, "ESPHealthBottomColor", {Default=Color3.fromRGB(255,0,0), Title="Health Bottom"})
end

-- =========================================================================
-- [ ESP SYSTEM ]
-- =========================================================================
local espData = {}
local SKELETON_R6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local SKELETON_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local MAX_HP_SEGMENTS = 12

local function createESP(plr)
    if espData[plr] then return end
    local d = {}

    -- Box
    d.box = Drawing.new("Square")
    d.box.Thickness = 2
    d.box.Filled = false
    d.box.Transparency = 1
    d.box.Visible = false

    -- Name
    d.name = Drawing.new("Text")
    d.name.Size = 13
    d.name.Center = true
    d.name.Outline = true
    d.name.Font = 1
    d.name.Transparency = 1
    d.name.Visible = false

    -- Health Bar
    d.hpBg = Drawing.new("Square")
    d.hpBg.Thickness = 1
    d.hpBg.Filled = true
    d.hpBg.Color = Color3.new(0,0,0)
    d.hpBg.Transparency = 0.5
    d.hpBg.Visible = false
    d.hpSegs = {}
    for i=1,MAX_HP_SEGMENTS do
        d.hpSegs[i] = Drawing.new("Line")
        d.hpSegs[i].Thickness = 3
        d.hpSegs[i].Transparency = 1
        d.hpSegs[i].Visible = false
    end

    -- Skeleton
    d.skel = {}
    local bones = plr.Character and plr.Character:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
    for i=1,#bones do
        d.skel[i] = { line = Drawing.new("Line"), a = bones[i][1], b = bones[i][2] }
        d.skel[i].line.Thickness = 2
        d.skel[i].line.Transparency = 1
        d.skel[i].line.Visible = false
    end

    espData[plr] = d
end

local function destroyESP(plr)
    local d = espData[plr]
    if not d then return end
    pcall(function()
        d.box:Remove()
        d.name:Remove()
        d.hpBg:Remove()
        for _, s in ipairs(d.hpSegs) do s:Remove() end
        for _, s in ipairs(d.skel) do s.line:Remove() end
    end)
    espData[plr] = nil
end

local function onPlayerAdded(plr)
    if plr == LP then return end
    createESP(plr)
end

for _, plr in ipairs(Players:GetPlayers()) do
    onPlayerAdded(plr)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(plr) destroyESP(plr) end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    for plr, d in pairs(espData) do
        if plr.Character then
            local bones = plr.Character:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
            for _, s in ipairs(d.skel) do pcall(function() s.line:Remove() end) end
            d.skel = {}
            for i=1,#bones do
                d.skel[i] = { line = Drawing.new("Line"), a = bones[i][1], b = bones[i][2] }
                d.skel[i].line.Thickness = 2
                d.skel[i].line.Transparency = 1
                d.skel[i].line.Visible = false
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        local espOn = Toggles.ESPEnabled.Value
        local teamCheck = Toggles.ESPTeamCheck.Value
        local wantBox = espOn and Toggles.ESPBox.Value
        local wantName = espOn and Toggles.ESPName.Value
        local wantHp = espOn and Toggles.ESPHealth.Value
        local wantSkel = espOn and Toggles.ESPSkeleton.Value
        local vp = Camera.ViewportSize

        for plr, d in pairs(espData) do
            local char = plr.Character
            local hide = not char or plr == LP or not isAlive(char)
            if teamCheck and not isEnemy(plr) then hide = true end

            if hide then
                d.box.Visible = false
                d.name.Visible = false
                d.hpBg.Visible = false
                for _, s in ipairs(d.hpSegs) do s.Visible = false end
                for _, s in ipairs(d.skel) do s.line.Visible = false end
            else
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                if hrp and head then
                    local headPos = head.Position + Vector3.new(0, 0.5, 0)
                    local footPos = hrp.Position - Vector3.new(0, 3, 0)
                    local spTop, onTop = Camera:WorldToViewportPoint(headPos)
                    local spBot, onBot = Camera:WorldToViewportPoint(footPos)
                    if onTop and onBot and spTop.Z > 0 and spBot.Z > 0 then
                        local h = math.abs(spBot.Y - spTop.Y)
                        local w = h * 0.55
                        local x = spTop.X - w / 2
                        local y = spTop.Y
                        local cx = spTop.X

                        -- Box
                        if wantBox then
                            d.box.Position = Vector2.new(x, y)
                            d.box.Size = Vector2.new(w, h)
                            d.box.Color = Options.ESPBoxColor.Value
                            d.box.Visible = true
                        else
                            d.box.Visible = false
                        end

                        -- Name
                        if wantName then
                            d.name.Position = Vector2.new(cx, y - 18)
                            d.name.Color = Options.ESPNameColor.Value
                            d.name.Text = plr.Name
                            d.name.Visible = true
                        else
                            d.name.Visible = false
                        end

                        -- Health Bar
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if wantHp and hum then
                            local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            local bx = x - 6
                            local by = y
                            local bw = 3
                            local bh = h
                            d.hpBg.Position = Vector2.new(bx - 1, by - 1)
                            d.hpBg.Size = Vector2.new(bw + 2, bh + 2)
                            d.hpBg.Visible = true
                            local filled = bh * frac
                            local startY = by + (bh - filled)
                            local cnt = math.clamp(math.floor(MAX_HP_SEGMENTS * frac), 1, MAX_HP_SEGMENTS)
                            local segH = filled / cnt
                            for i = 1, MAX_HP_SEGMENTS do
                                local seg = d.hpSegs[i]
                                if i <= cnt then
                                    local t = (i - 0.5) / MAX_HP_SEGMENTS
                                    seg.Color = lerpColor(Options.ESPHealthBottomColor.Value, Options.ESPHealthTopColor.Value, t)
                                    seg.From = Vector2.new(bx + bw * 0.5, startY + (i - 1) * segH)
                                    seg.To = Vector2.new(bx + bw * 0.5, startY + i * segH)
                                    seg.Thickness = bw
                                    seg.Visible = true
                                else
                                    seg.Visible = false
                                end
                            end
                        else
                            d.hpBg.Visible = false
                            for _, s in ipairs(d.hpSegs) do s.Visible = false end
                        end

                        -- Skeleton
                        if wantSkel then
                            for i, s in ipairs(d.skel) do
                                local pA = char:FindFirstChild(s.a)
                                local pB = char:FindFirstChild(s.b)
                                if pA and pB then
                                    local sA, oA = Camera:WorldToViewportPoint(pA.Position)
                                    local sB, oB = Camera:WorldToViewportPoint(pB.Position)
                                    if oA and oB and sA.Z > 0 and sB.Z > 0 then
                                        s.line.From = Vector2.new(sA.X, sA.Y)
                                        s.line.To = Vector2.new(sB.X, sB.Y)
                                        s.line.Color = Options.ESPSkeletonColor.Value
                                        s.line.Visible = true
                                    else
                                        s.line.Visible = false
                                    end
                                else
                                    s.line.Visible = false
                                end
                            end
                        else
                            for _, s in ipairs(d.skel) do s.line.Visible = false end
                        end
                    else
                        d.box.Visible = false
                        d.name.Visible = false
                        d.hpBg.Visible = false
                        for _, s in ipairs(d.hpSegs) do s.Visible = false end
                        for _, s in ipairs(d.skel) do s.line.Visible = false end
                    end
                end
            end
        end
    end)
end)

-- =========================================================================
-- [ TARGET SYSTEM & FOV ]
-- =========================================================================
local SilentTarget = nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(part)
    if not part then return false end
    rayParams.FilterDescendantsInstances = {LP.Character, Camera}
    local res = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
    if not res then return true end
    return res.Instance:IsDescendantOf(part.Parent)
end

local function findTarget()
    local myTeam = getTeam(LP)
    local center = Camera.ViewportSize / 2
    local closest, minDist = nil, math.huge
    local maxR = Options.SilentFovCircleRadius.Value

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and isAlive(plr.Character) then
            if Toggles.SilentTeamCheck.Value and not isEnemy(plr) then continue end
            local partName = Options.SilentHitPart.Value
            local part = plr.Character:FindFirstChild(partName) or plr.Character:FindFirstChild("Head")
            if part then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist <= maxR then
                        if Toggles.SilentWallbang.Value or isVisible(part) then
                            if dist < minDist then
                                minDist = dist
                                closest = part
                            end
                        end
                    end
                end
            end
        end
    end
    SilentTarget = closest
end

-- FOV Circle Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.NumSides = 128
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Visible = false

local frameCounter = 0
RunService.RenderStepped:Connect(function()
    frameCounter = frameCounter + 1
    local center = Camera.ViewportSize / 2

    -- Update FOV circle
    fovCircle.Position = center
    fovCircle.Radius = Options.SilentFovCircleRadius.Value
    fovCircle.Color = Options.SilentFovColor.Value
    fovCircle.Visible = Toggles.SilentAim.Value and Toggles.SilentUseFovCircle.Value

    -- Find target every other frame
    if frameCounter % 2 == 0 then
        if Toggles.SilentAim.Value then
            findTarget()
        else
            SilentTarget = nil
        end
    end
end)

-- =========================================================================
-- [ GC HOOKS - Weapon Functions ]
-- =========================================================================
local SendFunc = nil
local getCurrentEquipped = nil

pcall(function()
    for _, obj in next, getgc(true) do
        -- Find the function that sends bullet data
        if type(obj) == "table" and rawget(obj, "shoot") and typeof(obj.shoot) == "function" then
            pcall(function()
                for _, uv in pairs(debug.getupvalues(obj.shoot)) do
                    if type(uv) == "table" and rawget(uv, "Inventory") and rawget(uv.Inventory, "ShootWeapon") then
                        SendFunc = uv.Inventory.ShootWeapon.Send
                        break
                    end
                end
            end)
        end
        -- Find getCurrentEquipped
        if type(obj) == "table" and rawget(obj, "getCurrentEquipped") then
            pcall(function() getCurrentEquipped = obj.getCurrentEquipped end)
        end
        -- No Recoil
        if type(obj) == "table" and rawget(obj, "setWeaponRecoil") then
            pcall(function()
                local old = obj.setWeaponRecoil
                obj.setWeaponRecoil = function(...)
                    if Toggles.NoRecoil.Value then return end
                    return old(...)
                end
            end)
        end
        -- No Spread
        if type(obj) == "table" and rawget(obj, "getTrueSpread") then
            pcall(function()
                local old = obj.getTrueSpread
                obj.getTrueSpread = function(...)
                    if Toggles.NoSpread.Value then return 0 end
                    return old(...)
                end
            end)
        end
    end
end)

local Weapon = nil
local function getEquipped()
    if not getCurrentEquipped then return nil end
    local ok, res = pcall(function()
        return debug.getupvalue(getCurrentEquipped, 1).CurrentEquipped
    end)
    if not ok then return nil end
    return res
end

task.spawn(function()
    while task.wait(1) do
        pcall(function() if getEquipped then Weapon = getEquipped() end end)
    end
end)

-- =========================================================================
-- [ SHOOT HOOK - Silent Aim ]
-- =========================================================================
pcall(function()
    if not SendFunc then return end
    local oldshoot = hookfunction(SendFunc, function(...)
        local args = {...}
        if SilentTarget and Toggles.SilentAim.Value then
            -- Check if the args contain a table with bullet hits
            if args[1] and type(args[1]) == "table" and type(args[1].Bullets) == "table" then
                for _, bullet in pairs(args[1].Bullets) do
                    if type(bullet) == "table" and type(bullet.Hits) == "table" then
                        for _, hitData in pairs(bullet.Hits) do
                            if type(hitData) == "table" then
                                hitData.Instance = SilentTarget
                                hitData.Position = SilentTarget.Position
                            end
                        end
                    end
                end
            end
        end
        return oldshoot(unpack(args))
    end)
end)

-- =========================================================================
-- [ AUTO FIRE LOOP ]
-- =========================================================================
task.spawn(function()
    while true do
        local delay = Options.AutoFireDelay.Value or 0.05
        task.wait(delay)
        pcall(function()
            if Toggles.AutoFire.Value and SilentTarget and Weapon then
                if Weapon.IsEquipped and Weapon.Rounds and Weapon.Rounds > 0 then
                    -- Fire the weapon
                    pcall(function() Weapon:shoot() end)
                end
            end
        end)
    end
end)

-- =========================================================================
-- [ INSTANT RELOAD & RAPID FIRE ]
-- =========================================================================
task.spawn(function()
    local RELOAD_ANIMS = {Reload=true, ReloadStart=true, ReloadAction=true, ReloadEnd=true}
    local hooked = {}
    local function hookAnim(anim)
        if not anim or hooked[anim] then return end
        hooked[anim] = true
        pcall(function()
            local op = anim.play
            anim.play = function(self, name, ...)
                local track = op(self, name, ...)
                if track and RELOAD_ANIMS[name] and Toggles.InstantReload.Value then
                    task.defer(function()
                        if track.IsPlaying then
                            track:AdjustSpeed(199)
                        end
                    end)
                end
                return track
            end
        end)
    end
    local lastW
    while task.wait(0.1) do
        pcall(function()
            if not getEquipped then return end
            local w = getEquipped()
            if not w then return end
            if w ~= lastW then
                lastW = w
                if w.Viewmodel and w.Viewmodel.Animation then hookAnim(w.Viewmodel.Animation) end
                if w.CharacterAnimator then hookAnim(w.CharacterAnimator) end
            end
            if Toggles.InstantReload.Value and w.IsReloading then
                -- Force fast reload if possible
                if w.Viewmodel and w.Viewmodel.Animation and w.Viewmodel.Animation.Animations then
                    for name, track in pairs(w.Viewmodel.Animation.Animations) do
                        if RELOAD_ANIMS[name] and track.IsPlaying then track:AdjustSpeed(199) end
                    end
                end
            end
        end)
    end
end)

-- Rapid Fire Loop (Modifies FireRate or shoot delay)
task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if not Toggles.RapidFire.Value then return end
            if not Weapon then return end
            -- Attempt to modify fire rate directly on the weapon object
            if Weapon.FireRate then
                Weapon.FireRate = Options.RapidFireDelay.Value
            end
            -- Also try to hook the shoot function for rapid fire
            if not getgenv().RH_RapidFireHooked and Weapon.shoot then
                local oldShoot = Weapon.shoot
                Weapon.shoot = function(...)
                    if Toggles.RapidFire.Value then
                        -- Rapid fire: shoot multiple times or reduce delay
                        -- This is a simple approach, might need adjustment per game
                        return oldShoot(...)
                    end
                    return oldShoot(...)
                end
                getgenv().RH_RapidFireHooked = true
            end
        end)
    end
end)

-- =========================================================================
-- [ FINAL ]
-- =========================================================================
Notification:Notify({Title="RAINBOW HUB", Content="One Tap loaded. Key: Insert", Icon="clipboard"})
print("[RAINBOW HUB] One Tap loaded successfully")
