-- =========================================================================
-- MEMESENSE PORT → FATALITY UI  |  BloxStrike Edition  |  by Axiom
-- Universal (loadstring ready)
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
    if not ok or not F then warn("[MS] Fatality load failed") return nil end
    return F
end

local function keyMatches(input, key)
    if key == nil then return false end
    if typeof(key) == "EnumItem" then return input.KeyCode == key end
    return input.KeyCode.Name == tostring(key)
end

-- =========================================================================
-- [ MATERIAL PENETRATION SYSTEM ]
-- =========================================================================
local MaterialLimits = {
    [Enum.Material.Asphalt]=0.25,[Enum.Material.Basalt]=0.25,[Enum.Material.Brick]=0.25,
    [Enum.Material.Cobblestone]=0.25,[Enum.Material.Concrete]=0.25,[Enum.Material.CrackedLava]=0.25,
    [Enum.Material.DiamondPlate]=0.25,[Enum.Material.Foil]=0.25,[Enum.Material.Glacier]=0.25,
    [Enum.Material.Granite]=0.25,[Enum.Material.Grass]=0.25,[Enum.Material.Ground]=0.25,
    [Enum.Material.Ice]=0.25,[Enum.Material.LeafyGrass]=0.25,[Enum.Material.Limestone]=0.25,
    [Enum.Material.Marble]=0.25,[Enum.Material.Metal]=0.25,[Enum.Material.Mud]=0.25,
    [Enum.Material.Pavement]=0.25,[Enum.Material.Rock]=0.25,[Enum.Material.Salt]=0.25,
    [Enum.Material.Sand]=0.25,[Enum.Material.Sandstone]=0.25,[Enum.Material.Slate]=0.25,
    [Enum.Material.Snow]=0.25,[Enum.Material.ForceField]=0.25,[Enum.Material.Neon]=0.25,
    [Enum.Material.CorrodedMetal]=0.25,[Enum.Material.Pebble]=0.25,[Enum.Material.CeramicTiles]=0.25,
    [Enum.Material.Plaster]=0.25,[Enum.Material.Plastic]=7,[Enum.Material.SmoothPlastic]=7,
    [Enum.Material.Wood]=7,[Enum.Material.WoodPlanks]=7,[Enum.Material.Cardboard]=7,
    [Enum.Material.Glass]=100,[Enum.Material.Fabric]=100,
}
local MaterialVariantLimits = { ["IndoorWall"]=0.25, ["Sandy Brick"]=0.25 }

local function GetPenetrationStats(origin, direction, maxPen, ignoreList, targetRoot)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.CollisionGroup = "Bullet"
    local filter = ignoreList or {LP.Character, Camera}
    params.FilterDescendantsInstances = filter
    local currentOrigin, currentDir = origin, direction
    local accMat, accVar = {}, {}
    local stats = {TotalThickness=0, MaterialStats={}, Success=false, FailReason="Max Steps", EndPos=Vector3.zero}
    local backParams = RaycastParams.new()
    backParams.FilterType = Enum.RaycastFilterType.Include
    backParams.CollisionGroup = "Bullet"
    for _=1,100 do
        if not currentOrigin or not currentDir then break end
        local result = Workspace:Raycast(currentOrigin, currentDir*1000, params)
        if not result then
            if not targetRoot then stats.Success=true; stats.EndPos=currentOrigin+(currentDir*1000)
            else stats.FailReason="Void (Missed)" end
            break
        end
        if targetRoot and result.Instance:IsDescendantOf(targetRoot) then
            stats.Success=true; stats.EndPos=result.Position; stats.FailReason="Hit"; return stats
        end
        table.insert(filter, result.Instance)
        params.FilterDescendantsInstances = filter
        local enterPos = result.Position
        local fakeEnd = enterPos + (currentDir*1000)
        backParams.FilterDescendantsInstances = {result.Instance}
        local backRes = Workspace:Raycast(fakeEnd, enterPos - fakeEnd, backParams)
        local thickness, limit, matName = 0.5, 0.25, result.Instance.Material.Name
        if not backRes then thickness=5; stats.FailReason="Infinite/Block" else
            thickness = (enterPos - backRes.Position).Magnitude
            local variant = backRes.Instance.MaterialVariant
            if variant~="" and MaterialVariantLimits[variant] then
                matName = variant; limit = MaterialVariantLimits[variant]
                accVar[variant] = (accVar[variant] or 0) + thickness
                if accVar[variant] > limit + maxPen then
                    stats.FailReason = string.format("Var: %s", variant)
                    stats.MaterialStats = {Type="Variant", Name=variant, Thickness=accVar[variant], Limit=limit+maxPen}
                    return stats
                end
            else
                local mat = backRes.Material
                matName = mat.Name; limit = MaterialLimits[mat] or 0.25
                accMat[mat] = (accMat[mat] or 0) + thickness
                if accMat[mat] > limit + maxPen then
                    stats.FailReason = string.format("%s", matName)
                    stats.MaterialStats = {Type="Material", Name=matName, Thickness=accMat[mat], Limit=limit+maxPen}
                    return stats
                end
            end
            currentOrigin = backRes.Position
        end
        stats.TotalThickness = stats.TotalThickness + thickness
    end
    return stats
end

-- =========================================================================
-- [ MATH / HELPERS ]
-- =========================================================================
local function GetMoveDirection()
    local dir = Vector3.zero
    local lv, rv = Camera.CFrame.LookVector, Camera.CFrame.RightVector
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += lv end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= lv end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= rv end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += rv end
    local flat = Vector3.new(dir.X, 0, dir.Z)
    if flat.Magnitude > 0 then return flat.Unit end
    return flat
end

local function get_player_team(player)
    if not player then return nil end
    if player.Team then return player.Team.Name end
    return nil
end

local function IsValidTarget(character, teamCheckEnabled)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    local tp = Players:GetPlayerFromCharacter(character)
    if not tp or tp == LP then return false end
    if teamCheckEnabled then
        if LP.Team and tp.Team and LP.Team == tp.Team then return false end
    end
    return true
end

local function hasVestDetails(character)
    if not character then return false end
    local armor = character:FindFirstChild("CharacterArmor")
    if armor and armor:FindFirstChild("VestDetails") then return true end
    return false
end

local function isCharacterAlly(targetChar)
    if not LP.Character then return false end
    local myHasVest = hasVestDetails(LP.Character)
    local targetHasVest = hasVestDetails(targetChar)
    if not myHasVest then return not targetHasVest
    else return targetHasVest end
end

local function isEnemy(char)
    if not char then return false end
    local lchar = LP.Character
    if not lchar then return false end
    local myHasVest = hasVestDetails(lchar)
    local targetHasVest = hasVestDetails(char)
    if myHasVest then return not targetHasVest
    else return targetHasVest end
end

local function lerpColor(a,b,t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

-- =========================================================================
-- [ MIRROR LAYER — эмулируем Obsidian API Toggles.X.Value / Options.X.Value ]
-- =========================================================================
local Toggles = {}
local Options = {}

local function mirrorToggle(name, def)
    Toggles[name] = {Value = def or false, _callbacks = {}}
    function Toggles[name]:SetValue(v)
        self.Value = v
        for _,cb in ipairs(self._callbacks) do pcall(cb, v) end
    end
    function Toggles[name]:OnChanged(cb) table.insert(self._callbacks, cb) end
    return Toggles[name]
end

local function mirrorOption(name, def)
    Options[name] = {Value = def, _callbacks = {}}
    function Options[name]:SetValue(v)
        self.Value = v
        for _,cb in ipairs(self._callbacks) do pcall(cb, v) end
    end
    function Options[name]:OnChanged(cb) table.insert(self._callbacks, cb) end
    function Options[name]:GetState() return self.Value end
    function Options[name]:SetValues() end
    return Options[name]
end

-- =========================================================================
-- [ WINDOW INIT ]
-- =========================================================================
local F = GetFatality()
if not F then return end
local Notification = F:CreateNotifier()
if getgenv().MS_Loaded then return end
getgenv().MS_Loaded = true

F:Loader({Name = "MEMESENSE", Duration = 3})
Notification:Notify({Title="MEMESENSE", Content="Welcome, " .. LP.DisplayName, Icon="clipboard"})

local Window = F.new({Name="MEMESENSE", Expire="BloxStrike", Keybind="NONE"})
local Config = Window:AddConfig()
Config:Init("Hub_Memesense", "HubConfigs")

local MenuVisible = true
getgenv().MS_OpenKey = Enum.KeyCode.RightShift

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if keyMatches(input, getgenv().MS_OpenKey) then
        MenuVisible = not MenuVisible
        pcall(function() Window:SetVisible(MenuVisible) end)
    end
end)

-- =========================================================================
-- [ MENUS ]
-- =========================================================================
local CombatMenu  = Window:AddMenu({Name="Combat",     Icon="skull"})
local WeaponsMenu = Window:AddMenu({Name="Weapons",    Icon="crosshair"})
local VisualsMenu = Window:AddMenu({Name="Visuals",    Icon="eye"})
local WorldMenu   = Window:AddMenu({Name="World",      Icon="settings"})
local MiscMenu    = Window:AddMenu({Name="Misc",       Icon="cog"})
local SkinMenu    = Window:AddMenu({Name="SkinChanger",Icon="shield"})
local SetMenu     = Window:AddMenu({Name="Settings",   Icon="cog"})

-- =========================================================================
-- [ UI WRAPPERS → Fatality + Mirror ]
-- =========================================================================
local function AddToggle(section, name, opts)
    opts = opts or {}
    local m = mirrorToggle(name, opts.Default or false)
    section:AddToggle({
        Name = opts.Text or name,
        Flag = "MS_T_"..name,
        Default = opts.Default or false,
        Callback = function(v)
            m.Value = v
            for _,cb in ipairs(m._callbacks) do pcall(cb, v) end
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
        Flag = "MS_S_"..name,
        Default = opts.Default or 0,
        Min = opts.Min or 0,
        Max = opts.Max or 100,
        Round = opts.Rounding or 0,
        Callback = function(v)
            m.Value = v
            for _,cb in ipairs(m._callbacks) do pcall(cb, v) end
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
        Flag = "MS_D_"..name,
        Values = opts.Values or {},
        Default = opts.Default,
        Callback = function(v)
            m.Value = v
            for _,cb in ipairs(m._callbacks) do pcall(cb, v) end
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
        Flag = "MS_K_"..name,
        Default = opts.Default or Enum.KeyCode.Unknown,
        Callback = function(v)
            m.Value = v
            for _,cb in ipairs(m._callbacks) do pcall(cb, v) end
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
        Flag = "MS_C_"..name,
        Default = opts.Default or Color3.new(1,1,1),
        Callback = function(v)
            m.Value = v
            for _,cb in ipairs(m._callbacks) do pcall(cb, v) end
            if opts.Callback then pcall(opts.Callback, v) end
        end
    })
    return m
end

local function AddInput(section, name, opts)
    opts = opts or {}
    local m = mirrorOption(name, opts.Default or "")
    section:AddInput({
        Name = opts.Text or name,
        Flag = "MS_I_"..name,
        Default = opts.Default or "",
        Placeholder = opts.Placeholder or "",
        Callback = function(v)
            m.Value = v
            for _,cb in ipairs(m._callbacks) do pcall(cb, v) end
            if opts.Callback then pcall(opts.Callback, v) end
        end
    })
    return m
end

local function AddButton(section, name, cb)
    section:AddButton({Name=name, Callback = cb})
end

local function AddLabel(section, txt)
    -- Fatality может не иметь AddLabel — используем пустой toggle без логики
    pcall(function() section:AddLabel(txt) end)
end

-- =========================================================================
-- =========================================================================
--                            SETTINGS TAB
-- =========================================================================
-- =========================================================================
do
    local S = SetMenu:AddSection({Position='left', Name="INTERFACE"})
    AddKeybind(S, "MenuKeybind", {Text="Menu Keybind", Default=Enum.KeyCode.RightShift,
        Callback=function(v) if v~=nil then getgenv().MS_OpenKey=v end end})
    AddButton(S, "Unload", function()
        pcall(function() Window:SetVisible(false) end)
        getgenv().MS_Loaded = false
    end)
end

-- =========================================================================
-- =========================================================================
--                                MISC TAB
-- =========================================================================
-- =========================================================================
do
    local S = MiscMenu:AddSection({Position='left', Name="MOVEMENT"})
    AddToggle(S, "AutoBhop", {Text="Auto Bhop", Default=false})
    AddSlider(S, "BhopSpeed", {Text="Bhop Speed", Default=18, Min=5, Max=30, Rounding=1})
    AddToggle(S, "NoFallDamage", {Text="No Fall Damage", Default=false})
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = LP.Character
        if not char then return end
        local rp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        if Toggles.AutoBhop and Toggles.AutoBhop.Value then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local rp2 = RaycastParams.new()
                rp2.FilterDescendantsInstances = {char}
                rp2.FilterType = Enum.RaycastFilterType.Exclude
                if Workspace:Raycast(rp.Position, Vector3.new(0,-4,0), rp2) then hum.Jump = true end
            end
            local dir = GetMoveDirection()
            if dir.Magnitude > 0 then
                local spd = math.clamp(Options.BhopSpeed and Options.BhopSpeed.Value or 18, 5, 30)
                local target = dir * spd
                local v = rp.AssemblyLinearVelocity
                local nx = v.X + (target.X - v.X) * 0.2
                local nz = v.Z + (target.Z - v.Z) * 0.2
                rp.AssemblyLinearVelocity = Vector3.new(nx, v.Y, nz)
            end
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        if Toggles.NoFallDamage and Toggles.NoFallDamage.Value then
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                end
            end
        end
    end)
end)

-- =========================================================================
-- =========================================================================
--                               WORLD TAB
-- =========================================================================
-- =========================================================================
local WorldBox = WorldMenu:AddSection({Position='left', Name="WORLD"})
local WeaponVisBox = WorldMenu:AddSection({Position='center', Name="WEAPON VISUAL"})
local CustomHandsBox = WorldMenu:AddSection({Position='center', Name="CUSTOM HANDS"})
local WeaponChamsBox = WorldMenu:AddSection({Position='right', Name="WEAPON CHAMS"})
local HitSoundBox = WorldMenu:AddSection({Position='left', Name="HIT SOUND"})
local CustomCameraBox = WorldMenu:AddSection({Position='center', Name="CAMERA"})
local CustomScopeBox = WorldMenu:AddSection({Position='right', Name="SCOPE"})
local HitMarkerBox = WorldMenu:AddSection({Position='left', Name="HITMARKER"})
local NightBox = WorldMenu:AddSection({Position='center', Name="NIGHT MODE"})
local AtmosBox = WorldMenu:AddSection({Position='right', Name="ATMOSPHERE"})

-- ── Weapon Visual / Tracers ─────────────────────────────────────────────
AddToggle(WeaponVisBox, "BulletTracers", {Text="Bullet Tracers", Default=false})
AddColor(WeaponVisBox, "BulletTracersColor", {Default=Color3.fromRGB(0,170,255), Title="Tracer Color"})
AddDropdown(WeaponVisBox, "TracerStyle", {Text="Tracer Style", Values={"Block","Cylinder (Obelius)"}, Default="Block"})
AddToggle(WeaponVisBox, "TracerRainbow", {Text="Tracer Rainbow", Default=false})
AddSlider(WeaponVisBox, "TracerTime", {Text="Tracer Time", Default=2, Min=0.1, Max=10, Rounding=1})
AddToggle(WeaponVisBox, "BulletImpacts", {Text="Bullet Impacts", Default=false})
AddColor(WeaponVisBox, "BulletImpactsColor", {Default=Color3.fromRGB(255,0,0), Title="Impact Color"})

-- ── Custom Hands ────────────────────────────────────────────────────────
AddToggle(CustomHandsBox, "CustomHandsEnabled", {Text="Enable", Default=false})
AddSlider(CustomHandsBox, "HandsX", {Text="X", Default=0.2, Min=-2, Max=2, Rounding=3})
AddSlider(CustomHandsBox, "HandsY", {Text="Y", Default=-0.155, Min=-2, Max=2, Rounding=3})
AddSlider(CustomHandsBox, "HandsZ", {Text="Z", Default=0.075, Min=-2, Max=2, Rounding=3})

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not (Toggles.CustomHandsEnabled and Toggles.CustomHandsEnabled.Value) then return end
        local xO = Options.HandsX and Options.HandsX.Value or 0.2
        local yO = Options.HandsY and Options.HandsY.Value or -0.155
        local zO = Options.HandsZ and Options.HandsZ.Value or 0.075
        for _, child in ipairs(Camera:GetChildren()) do
            if child:IsA("Model") then
                local stats = child:FindFirstChild("Stats")
                if stats then
                    local def = stats:FindFirstChild("Default")
                    if def and def:IsA("Vector3Value") then
                        def.Value = Vector3.new(xO, yO, zO)
                    end
                end
            end
        end
    end)
end)

-- ── Weapon Chams ────────────────────────────────────────────────────────
AddToggle(WeaponChamsBox, "WeaponChamsEnabled", {Text="Enable", Default=false})
AddColor(WeaponChamsBox, "WeaponChamsColor", {Default=Color3.fromRGB(0,150,255), Title="Chams Color"})
AddDropdown(WeaponChamsBox, "WeaponChamsMode", {Text="Material", Values={"Glass","ForceField","Metal","Highlight","Neon"}, Default="Glass"})
AddSlider(WeaponChamsBox, "GlassTransparency", {Text="Glass Transparency", Default=0.4, Min=0, Max=1, Rounding=2})
AddSlider(WeaponChamsBox, "MetalReflectance", {Text="Metal Reflectance", Default=1.0, Min=0, Max=1, Rounding=1})

local activeNeonHighlights = {}
RunService.RenderStepped:Connect(function()
    pcall(function()
        local enabled = Toggles.WeaponChamsEnabled and Toggles.WeaponChamsEnabled.Value
        local mode = Options.WeaponChamsMode and Options.WeaponChamsMode.Value or "Glass"
        local color = Options.WeaponChamsColor and Options.WeaponChamsColor.Value or Color3.fromRGB(0,150,255)
        local wm = nil
        for _, child in ipairs(Camera:GetChildren()) do
            if child:IsA("Model") and child.Name ~= "Viewmodel" and not child.Name:lower():find("light") then
                local w = child:FindFirstChild("Weapon") or child
                if w:IsA("Model") and w.Name ~= "Viewmodel" and not w.Name:lower():find("light") then
                    wm = w
                    break
                end
            end
        end
        if not enabled or not wm then
            for _, h in pairs(activeNeonHighlights) do
                if h and h.Parent then h:Destroy() end
            end
            activeNeonHighlights = {}
            return
        end
        local current = {}
        for _, part in ipairs(wm:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "Hitbox" and part.Name ~= "HumanoidRootPart" then
                pcall(function()
                    if mode == "Highlight" then
                        current[part] = true
                        local h = part:FindFirstChild("MS_WeaponChamsHL")
                        if not h then
                            h = Instance.new("Highlight")
                            h.Name = "MS_WeaponChamsHL"
                            h.Adornee = part
                            h.Parent = part
                            h.FillTransparency = 0
                            h.OutlineTransparency = 1
                            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            table.insert(activeNeonHighlights, h)
                        end
                        h.FillColor = color
                    else
                        local h = part:FindFirstChild("MS_WeaponChamsHL")
                        if h then h:Destroy() end
                        if mode ~= "Neon" then
                            for _, v in ipairs(part:GetChildren()) do
                                if v:IsA("SurfaceAppearance") or v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
                            end
                        end
                        if mode == "Glass" then
                            part.Material = Enum.Material.Glass
                            part.Color = color
                            part.Transparency = Options.GlassTransparency and Options.GlassTransparency.Value or 0.4
                        elseif mode == "ForceField" then
                            part.Material = Enum.Material.ForceField
                            part.Color = color
                            part.Transparency = 0
                        elseif mode == "Metal" then
                            part.Material = Enum.Material.Metal
                            part.Color = color
                            part.Reflectance = Options.MetalReflectance and Options.MetalReflectance.Value or 1
                            part.Transparency = 0
                        elseif mode == "Neon" then
                            part.Material = Enum.Material.Neon
                            part.Color = color
                            part.Transparency = 0
                            for _, v in ipairs(part:GetChildren()) do
                                if v:IsA("SurfaceAppearance") or v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
                            end
                        end
                    end
                end)
            end
        end
        if mode == "Highlight" then
            for i = #activeNeonHighlights, 1, -1 do
                local h = activeNeonHighlights[i]
                if not h or not h.Parent or not current[h.Adornee] then
                    if h then h:Destroy() end
                    table.remove(activeNeonHighlights, i)
                end
            end
        end
    end)
end)

-- ── Hit Sound ───────────────────────────────────────────────────────────
AddToggle(HitSoundBox, "HitSoundEnabled", {Text="Enable Hit Sound", Default=false})
AddToggle(HitSoundBox, "CustomHitSoundToggle", {Text="Custom Hit Sound", Default=false})
AddSlider(HitSoundBox, "HitSoundVolume", {Text="Volume", Default=1, Min=0.1, Max=5, Rounding=1})

local HitSoundPresets = {
    ["Neverlose"]="rbxassetid://139452805868562",
    ["Skeet"]="rbxassetid://83717596220569",
    ["Bell"]="rbxassetid://96481309571950",
    ["Bell2"]="rbxassetid://124010691633262",
    ["Bubble"]="rbxassetid://104824514322839",
    ["Rust"]="rbxassetid://1255040462",
    ["Agro1"]="rbxassetid://132463144859699",
    ["Agro2"]="rbxassetid://102651850556408",
    ["Coins"]="rbxassetid://5613553529",
    ["Schaater"]="rbxassetid://17405655409",
    ["Pick"]="rbxassetid://8616930816",
}
AddDropdown(HitSoundBox, "HitSoundPreset", {Text="Preset", Values={"Neverlose","Skeet","Bell","Bell2","Bubble","Rust","Agro1","Agro2","Coins","Schaater","Pick"}, Default="Neverlose"})
AddInput(HitSoundBox, "CustomHitSoundID", {Text="Custom Sound ID", Default="", Placeholder="ID or rbxassetid://..."})

local function PlayHitSound()
    pcall(function()
        if not (Toggles.HitSoundEnabled and Toggles.HitSoundEnabled.Value) then return end
        local sid = ""
        if Toggles.CustomHitSoundToggle and Toggles.CustomHitSoundToggle.Value then
            local ci = Options.CustomHitSoundID and Options.CustomHitSoundID.Value
            if ci and ci ~= "" then
                if not ci:find("rbxassetid://") then
                    local clean = ci:gsub("%D","")
                    if clean ~= "" then sid = "rbxassetid://" .. clean end
                else sid = ci end
            end
        end
        if sid == "" then
            sid = HitSoundPresets[Options.HitSoundPreset and Options.HitSoundPreset.Value or "Neverlose"]
                or "rbxassetid://139452805868562"
        end
        local s = Instance.new("Sound")
        s.SoundId = sid
        s.Volume = Options.HitSoundVolume and Options.HitSoundVolume.Value or 1
        s.Parent = SoundService
        s:Play()
        task.spawn(function()
            s.Ended:Wait()
            s:Destroy()
        end)
    end)
end

-- ── Custom Camera ───────────────────────────────────────────────────────
AddToggle(CustomCameraBox, "CustomFovToggle", {Text="Custom FOV", Default=false})
AddKeybind(CustomCameraBox, "CustomFovKey", {Text="FOV Key", Default=Enum.KeyCode.One})
AddSlider(CustomCameraBox, "FovAmount", {Text="FOV Amount", Default=90, Min=70, Max=120, Rounding=0})
AddToggle(CustomCameraBox, "ThirdPerson", {Text="Third Person", Default=false, Callback=function(v)
    if v then
        LP.CameraMode = Enum.CameraMode.Classic
        local d = Options.ThirdPersonDist and Options.ThirdPersonDist.Value or 10
        LP.CameraMaxZoomDistance = d
        LP.CameraMinZoomDistance = d
    else
        LP.CameraMode = Enum.CameraMode.LockFirstPerson
        LP.CameraMaxZoomDistance = 0.5
        LP.CameraMinZoomDistance = 0.5
    end
end})
AddSlider(CustomCameraBox, "ThirdPersonDist", {Text="Third Person Distance", Default=10, Min=5, Max=50, Rounding=1,
    Callback=function(v)
        if Toggles.ThirdPerson and Toggles.ThirdPerson.Value then
            LP.CameraMaxZoomDistance = v
            LP.CameraMinZoomDistance = v
        end
    end})

-- ── Custom Scope ────────────────────────────────────────────────────────
AddToggle(CustomScopeBox, "CustomScopeFov", {Text="Custom Scope FOV", Default=false})
AddSlider(CustomScopeBox, "ScopeFovValue", {Text="Scope FOV", Default=70, Min=10, Max=100, Rounding=1})
AddToggle(CustomScopeBox, "RemoveScope", {Text="Remove Scope", Default=false})
AddToggle(CustomScopeBox, "CustomScopeCrosshair", {Text="Scope Crosshair", Default=false})
AddColor(CustomScopeBox, "ScopeCrosshairColor", {Default=Color3.fromRGB(255,255,255), Title="Crosshair Color"})
AddSlider(CustomScopeBox, "ScopeCrosshairThickness", {Text="Thickness", Default=2, Min=1, Max=10, Rounding=1})
AddSlider(CustomScopeBox, "ScopeCrosshairLengthLR", {Text="Length L&R", Default=150, Min=0, Max=1000, Rounding=0})
AddSlider(CustomScopeBox, "ScopeCrosshairLengthTB", {Text="Length T&B", Default=100, Min=0, Max=1000, Rounding=0})

-- ── HitMarker ───────────────────────────────────────────────────────────
AddToggle(HitMarkerBox, "HitMarkerEnabled", {Text="Enable HitMarker", Default=false})
AddColor(HitMarkerBox, "HitMarkerColor", {Default=Color3.fromRGB(255,255,255), Title="HitMarker Color"})
AddToggle(HitMarkerBox, "HitMarkerRainbow", {Text="Rainbow", Default=false})
AddSlider(HitMarkerBox, "HitMarkerDuration", {Text="Duration", Default=2, Min=0.5, Max=5, Rounding=1})
AddSlider(HitMarkerBox, "HitMarkerSpinSpeed", {Text="Spin Speed", Default=720, Min=0, Max=1440, Rounding=0})
AddSlider(HitMarkerBox, "HitMarkerSize", {Text="Size", Default=25, Min=5, Max=50, Rounding=0})
AddSlider(HitMarkerBox, "HitMarkerThickness", {Text="Thickness", Default=2, Min=1, Max=6, Rounding=1})

local TriggerHitMarkerEvent = nil
task.spawn(function()
    local active = {}
    TriggerHitMarkerEvent = function(hitPos)
        if not (Toggles.HitMarkerEnabled and Toggles.HitMarkerEnabled.Value) then return end
        local dur = Options.HitMarkerDuration and Options.HitMarkerDuration.Value or 2
        local thick = Options.HitMarkerThickness and Options.HitMarkerThickness.Value or 2
        local lines = {}
        for i=1,4 do
            local l = Drawing.new("Line")
            l.Thickness = thick
            l.Transparency = 1
            l.Visible = false
            lines[i] = l
        end
        table.insert(active, {lines=lines, worldPos=hitPos, spawnTick=tick(), expireTick=tick()+dur})
    end
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local now = tick()
            local enabled = Toggles.HitMarkerEnabled and Toggles.HitMarkerEnabled.Value
            local col = Options.HitMarkerColor and Options.HitMarkerColor.Value or Color3.new(1,1,1)
            if Toggles.HitMarkerRainbow and Toggles.HitMarkerRainbow.Value then
                col = Color3.fromHSV((now % 5) / 5, 1, 1)
            end
            local baseSize = Options.HitMarkerSize and Options.HitMarkerSize.Value or 25
            local spinSpeed = Options.HitMarkerSpinSpeed and Options.HitMarkerSpinSpeed.Value or 720
            local pulse = 1 + 0.35 * math.sin(now * math.pi)
            local size = baseSize * pulse
            local gap = 6 * pulse
            for i = #active, 1, -1 do
                local d = active[i]
                if not enabled or now > d.expireTick then
                    for _, l in ipairs(d.lines) do pcall(function() l:Remove() end) end
                    table.remove(active, i)
                else
                    local sp, on = Camera:WorldToViewportPoint(d.worldPos)
                    if on then
                        local center = Vector2.new(sp.X, sp.Y)
                        local lt = now - d.spawnTick
                        local ang = math.rad((lt * spinSpeed) % 360)
                        local baseAngles = {0, 90, 180, 270}
                        for j=1,4 do
                            local l = d.lines[j]
                            l.Color = col
                            l.Thickness = Options.HitMarkerThickness and Options.HitMarkerThickness.Value or 2
                            local a = ang + math.rad(baseAngles[j])
                            local c, s = math.cos(a), math.sin(a)
                            l.From = center + Vector2.new(c*gap, s*gap)
                            l.To   = center + Vector2.new(c*(gap+size), s*(gap+size))
                            l.Visible = true
                        end
                    else
                        for _, l in ipairs(d.lines) do l.Visible = false end
                    end
                end
            end
        end)
    end)
end)

-- ── Scope Crosshair GUI ─────────────────────────────────────────────────
task.spawn(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MS_ScopeCrosshair"
    gui.ResetOnSpawn = false
    pcall(function() gui.Parent = CoreGui end)
    local container = Instance.new("Frame", gui)
    container.BackgroundTransparency = 1
    container.AnchorPoint = Vector2.new(0.5,0.5)
    container.Position = UDim2.new(0.5,0,0.5,0)
    container.Size = UDim2.new(0,0,0,0)
    local function mkLine(ap)
        local f = Instance.new("Frame", container)
        f.AnchorPoint = ap
        f.BorderSizePixel = 0
        return f
    end
    local l = mkLine(Vector2.new(1,0.5))
    local r = mkLine(Vector2.new(0,0.5))
    local t = mkLine(Vector2.new(0.5,1))
    local b = mkLine(Vector2.new(0.5,0))
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local isScoped = false
            local pg = LP:FindFirstChild("PlayerGui")
            if pg then
                local s, sc = pcall(function() return pg.MainGui.Gameplay.Middle.SniperScope end)
                if s and sc and sc.Visible then isScoped = true end
            end
            local enabled = Toggles.CustomScopeCrosshair and Toggles.CustomScopeCrosshair.Value and isScoped
            container.Visible = enabled
            if enabled then
                local col = Options.ScopeCrosshairColor and Options.ScopeCrosshairColor.Value or Color3.new(1,1,1)
                l.BackgroundColor3, r.BackgroundColor3, t.BackgroundColor3, b.BackgroundColor3 = col, col, col, col
                local th = Options.ScopeCrosshairThickness and Options.ScopeCrosshairThickness.Value or 2
                local lr = Options.ScopeCrosshairLengthLR and Options.ScopeCrosshairLengthLR.Value or 150
                local tb = Options.ScopeCrosshairLengthTB and Options.ScopeCrosshairLengthTB.Value or 100
                l.Size = UDim2.new(0, lr, 0, th)
                r.Size = UDim2.new(0, lr, 0, th)
                t.Size = UDim2.new(0, th, 0, tb)
                b.Size = UDim2.new(0, th, 0, tb)
            end
        end)
    end)
end)

-- ── Remove Scope ────────────────────────────────────────────────────────
task.spawn(function()
    local cached
    RunService.RenderStepped:Connect(function()
        if cached and not cached.Parent then cached = nil end
        if not cached then
            local pg = LP:FindFirstChild("PlayerGui")
            if pg then
                local s, sc = pcall(function() return pg.MainGui.Gameplay.Middle.SniperScope end)
                if s and sc then cached = sc end
            end
        end
        if not cached then return end
        if not (Toggles.RemoveScope and Toggles.RemoveScope.Value) then
            if cached.Size ~= UDim2.new(1,0,1,0) then cached.Size = UDim2.new(1,0,1,0) end
            return
        end
        if cached.Visible == true then cached.Size = UDim2.new(0,0,0,0)
        else
            if cached.Size ~= UDim2.new(1,0,1,0) then cached.Size = UDim2.new(1,0,1,0) end
        end
    end)
end)

-- ── Custom Scope FOV ────────────────────────────────────────────────────
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        pcall(function()
            if not (Toggles.CustomScopeFov and Toggles.CustomScopeFov.Value) then return end
            local pg = LP:FindFirstChild("PlayerGui")
            if not pg then return end
            local sc = pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("Gameplay")
                and pg.MainGui.Gameplay:FindFirstChild("Middle")
                and pg.MainGui.Gameplay.Middle:FindFirstChild("SniperScope")
            if sc and sc.Visible and Options.ScopeFovValue then
                Camera.FieldOfView = Options.ScopeFovValue.Value
            end
        end)
    end)
end)

-- ── Custom FOV / Third Person loop ──────────────────────────────────────
RunService.RenderStepped:Connect(function()
    pcall(function()
        if Toggles.CustomFovToggle and Toggles.CustomFovToggle.Value then
            Camera.FieldOfView = Options.FovAmount and Options.FovAmount.Value or 90
        end
        if Toggles.ThirdPerson and Toggles.ThirdPerson.Value then
            local d = math.clamp(Options.ThirdPersonDist and Options.ThirdPersonDist.Value or 10, 5, 50)
            LP.CameraMode = Enum.CameraMode.Classic
            LP.CameraMaxZoomDistance = d
            LP.CameraMinZoomDistance = d
        end
    end)
end)

-- ── Skybox System ───────────────────────────────────────────────────────
local skyboxtable = {
    ["Night"]={SkyboxBk="rbxassetid://1514717643",SkyboxDn="rbxassetid://1514716936",SkyboxFt="rbxassetid://1514715910",SkyboxLf="rbxassetid://1514714945",SkyboxRt="rbxassetid://1514714011",SkyboxUp="rbxassetid://1514713374"},
    ["Ocean Sunset"]={SkyboxBk="rbxassetid://17525686840",SkyboxDn="rbxassetid://17525678473",SkyboxFt="rbxassetid://17525684686",SkyboxLf="rbxassetid://17525680663",SkyboxRt="rbxassetid://17525682665",SkyboxUp="rbxassetid://17525674545"},
    ["My Summer Car"]={SkyboxBk="rbxassetid://16648590964",SkyboxDn="rbxassetid://16648617436",SkyboxFt="rbxassetid://16648595424",SkyboxLf="rbxassetid://16648566370",SkyboxRt="rbxassetid://16648577071",SkyboxUp="rbxassetid://16648598180"},
    ["Deep Space"]={SkyboxBk="http://www.roblox.com/asset/?id=159248188",SkyboxDn="http://www.roblox.com/asset/?id=159248183",SkyboxFt="http://www.roblox.com/asset/?id=159248187",SkyboxLf="http://www.roblox.com/asset/?id=159248173",SkyboxRt="http://www.roblox.com/asset/?id=159248192",SkyboxUp="http://www.roblox.com/asset/?id=159248176"},
    ["Purple Nebula"]={SkyboxBk="http://www.roblox.com/asset/?id=15983968922",SkyboxDn="http://www.roblox.com/asset/?id=15983966825",SkyboxFt="http://www.roblox.com/asset/?id=15983965025",SkyboxLf="http://www.roblox.com/asset/?id=15983967420",SkyboxRt="http://www.roblox.com/asset/?id=15983966246",SkyboxUp="http://www.roblox.com/asset/?id=15983964246"},
    ["Minecraft"]={SkyboxBk="http://www.roblox.com/asset/?id=8735166756",SkyboxDn="http://www.roblox.com/asset/?id=8735166707",SkyboxFt="http://www.roblox.com/asset/?id=8735231668",SkyboxLf="http://www.roblox.com/asset/?id=8735166755",SkyboxRt="http://www.roblox.com/asset/?id=8735166751",SkyboxUp="http://www.roblox.com/asset/?id=8735166729"},
    ["Spongebob"]={SkyboxBk="http://www.roblox.com/asset/?id=277099484",SkyboxDn="http://www.roblox.com/asset/?id=277099500",SkyboxFt="http://www.roblox.com/asset/?id=277099554",SkyboxLf="http://www.roblox.com/asset/?id=277099531",SkyboxRt="http://www.roblox.com/asset/?id=277099589",SkyboxUp="http://www.roblox.com/asset/?id=277101591"},
    ["Retro"]={SkyboxBk="rbxasset://sky/null_plainsky512_bk.jpg",SkyboxDn="rbxasset://sky/null_plainsky512_dn.jpg",SkyboxFt="rbxasset://sky/null_plainsky512_ft.jpg",SkyboxLf="rbxasset://sky/null_plainsky512_lf.jpg",SkyboxRt="rbxasset://sky/null_plainsky512_rt.jpg",SkyboxUp="rbxasset://sky/null_plainsky512_up.jpg"},
    ["City"]={SkyboxBk="http://www.roblox.com/asset/?id=9134792889",SkyboxDn="http://www.roblox.com/asset/?id=9134791975",SkyboxFt="http://www.roblox.com/asset/?id=9134793457",SkyboxLf="http://www.roblox.com/asset/?id=9134791234",SkyboxRt="http://www.roblox.com/asset/?id=9134790419",SkyboxUp="http://www.roblox.com/asset/?id=9134791633"},
}
local skyNames = {}
for k in pairs(skyboxtable) do table.insert(skyNames, k) end
table.sort(skyNames)

local function UpdateSkybox(name)
    local data = skyboxtable[name]
    if not data then return end
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("Clouds") then v:Destroy() end
    end
    local sky = Lighting:FindFirstChild("MS_Sky")
    if not sky then
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
        sky = Instance.new("Sky"); sky.Name = "MS_Sky"; sky.Parent = Lighting
    end
    sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt = data.SkyboxBk, data.SkyboxDn, data.SkyboxFt
    sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = data.SkyboxLf, data.SkyboxRt, data.SkyboxUp
    sky.SunTextureId, sky.MoonTextureId, sky.StarCount = "", "", 0
end

AddToggle(WorldBox, "EnableSkybox", {Text="Enable Skybox", Default=false, Callback=function(v)
    if v then
        if Toggles.Atmosphere and Toggles.Atmosphere.Value then Toggles.Atmosphere:SetValue(false) end
        UpdateSkybox(Options.SkyboxPreset and Options.SkyboxPreset.Value or "Night")
    end
end})
AddDropdown(WorldBox, "SkyboxPreset", {Text="Skybox", Values=skyNames, Default="Night",
    Callback=function(v) if Toggles.EnableSkybox and Toggles.EnableSkybox.Value then UpdateSkybox(v) end end})

-- ── Weather ─────────────────────────────────────────────────────────────
local WeatherPart, GroundPart
local function UpdateWeather(wType)
    if WeatherPart then WeatherPart:Destroy(); WeatherPart=nil end
    if GroundPart then GroundPart:Destroy(); GroundPart=nil end
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "MS_RainDrop" then v:Destroy() end
    end
    if wType == "None" then return end
    WeatherPart = Instance.new("Part")
    WeatherPart.Name="MS_Weather_Sky"; WeatherPart.Size=Vector3.new(100,1,100)
    WeatherPart.Transparency=1; WeatherPart.Anchored=true; WeatherPart.CanCollide=false
    WeatherPart.Parent = Workspace.CurrentCamera
    local se = Instance.new("ParticleEmitter", WeatherPart)
    se.EmissionDirection = Enum.NormalId.Bottom; se.Enabled = true
    GroundPart = Instance.new("Part")
    GroundPart.Name="MS_Weather_Ground"; GroundPart.Size=Vector3.new(50,1,50)
    GroundPart.Transparency=1; GroundPart.Anchored=true; GroundPart.CanCollide=false
    GroundPart.Parent = Workspace.CurrentCamera
    local ge = Instance.new("ParticleEmitter", GroundPart); ge.Enabled = false
    if wType == "Rain" then
        se.Texture = "rbxassetid://241868005"; se.Rate = 10000
        se.Color = ColorSequence.new(Color3.new(1,1,1)); se.LightEmission = 0.2
        se.Transparency = NumberSequence.new(0); se.Size = NumberSequence.new(3,6)
        se.Lifetime = NumberRange.new(2,2.5); se.Speed = NumberRange.new(80,100)
        se.SpreadAngle = Vector2.new(0,0); se.Acceleration = Vector3.new(0,-50,0)
        se.Orientation = Enum.ParticleOrientation.FacingCamera
    elseif wType == "Snow" then
        se.Texture = "rbxassetid://99851851"; se.Rate = 200
        se.Color = ColorSequence.new(Color3.new(1,1,1)); se.Size = NumberSequence.new(0.25,0.35)
        se.Speed = NumberRange.new(30,30); se.Lifetime = NumberRange.new(5,10)
        se.SpreadAngle = Vector2.new(50,50); se.LightEmission = 0.5
    elseif wType == "Hell Fire" then
        se.Texture = "rbxassetid://242205518"; se.Rate = 400
        se.Color = ColorSequence.new(Color3.fromRGB(255,100,0), Color3.fromRGB(150,0,0))
        se.Size = NumberSequence.new(2,4); se.Speed = NumberRange.new(40,60)
        se.Lifetime = NumberRange.new(2,3); se.Acceleration = Vector3.new(0,-10,0)
        se.RotSpeed = NumberRange.new(50,100)
    end
end
AddDropdown(WorldBox, "WeatherType", {Text="Weather", Values={"None","Rain","Snow","Hell Fire"}, Default="None",
    Callback=function(v) UpdateWeather(v) end})

RunService.RenderStepped:Connect(function()
    if not Workspace.CurrentCamera then return end
    local cc = Workspace.CurrentCamera.CFrame
    if WeatherPart then WeatherPart.CFrame = cc * CFrame.new(0,30,0) end
end)

-- ── Lighting Controls ───────────────────────────────────────────────────
local DefaultLighting = {
    Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
    Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
    FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart, GlobalShadows=Lighting.GlobalShadows,
}
local function UpdateLighting()
    if Toggles.EnableTime and Toggles.EnableTime.Value then
        Lighting.ClockTime = Options.WorldClockTime.Value
    else Lighting.ClockTime = DefaultLighting.ClockTime end
    if Toggles.EnableBrightness and Toggles.EnableBrightness.Value then
        Lighting.Brightness = Options.WorldBrightness.Value
    else Lighting.Brightness = DefaultLighting.Brightness end
    if Toggles.EnableColors and Toggles.EnableColors.Value then
        Lighting.Ambient = Options.WorldAmbient.Value
        Lighting.OutdoorAmbient = Options.WorldOutdoorAmbient.Value
    else
        Lighting.Ambient = DefaultLighting.Ambient
        Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
    end
end
AddToggle(WorldBox, "EnableTime", {Text="Enable Time", Default=false, Callback=function() UpdateLighting() end})
AddSlider(WorldBox, "WorldClockTime", {Text="Clock Time", Default=12, Min=0, Max=24, Rounding=1, Callback=function() UpdateLighting() end})
AddToggle(WorldBox, "EnableBrightness", {Text="Enable Brightness", Default=false, Callback=function() UpdateLighting() end})
AddSlider(WorldBox, "WorldBrightness", {Text="Brightness", Default=2, Min=0, Max=10, Rounding=1, Callback=function() UpdateLighting() end})
AddToggle(WorldBox, "EnableColors", {Text="Enable Colors", Default=false, Callback=function() UpdateLighting() end})
AddColor(WorldBox, "WorldAmbient", {Default=Color3.fromRGB(127,127,127), Title="Ambient Color", Callback=function() UpdateLighting() end})
AddColor(WorldBox, "WorldOutdoorAmbient", {Default=Color3.fromRGB(127,127,127), Title="Outdoor Color", Callback=function() UpdateLighting() end})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if Toggles.EnableSkybox and Toggles.EnableSkybox.Value then
                UpdateSkybox(Options.SkyboxPreset and Options.SkyboxPreset.Value or "Night")
            end
            UpdateLighting()
        end)
    end
end)

-- ── Night Mode (World Color) ────────────────────────────────────────────
local WorldSettings = { WorldColorEnabled=false, WorldColor=Color3.new(1,1,1),
    SkyColorEnabled=false, SkyColor=Color3.new(1,1,1) }
local function isLocalPlayerObject(obj)
    local char = LP.Character
    if char and (obj == char or obj:IsDescendantOf(char)) then return true end
    if obj:IsDescendantOf(Workspace.CurrentCamera) then return true end
    if obj.Name == "CubeChecker_Physical" or obj.Name:find("MS_") then return true end
    return false
end
local function colorObject(obj)
    if isLocalPlayerObject(obj) then return end
    if obj:IsA("BasePart") then
        if not obj:GetAttribute("OrigColor") then obj:SetAttribute("OrigColor", obj.Color) end
        obj.Color = WorldSettings.WorldColor
    elseif obj:IsA("Texture") or obj:IsA("Decal") then
        if not obj:GetAttribute("OrigColor3") then obj:SetAttribute("OrigColor3", obj.Color3) end
        obj.Color3 = WorldSettings.WorldColor
    end
end
local function restoreObject(obj)
    if obj:IsA("BasePart") then
        if obj:GetAttribute("OrigColor") then obj.Color = obj:GetAttribute("OrigColor") end
    elseif obj:IsA("Texture") or obj:IsA("Decal") then
        if obj:GetAttribute("OrigColor3") then obj.Color3 = obj:GetAttribute("OrigColor3") end
    end
end
local function RefreshWorldColor()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if WorldSettings.WorldColorEnabled then colorObject(obj) else restoreObject(obj) end
    end
end
Workspace.DescendantAdded:Connect(function(obj)
    if WorldSettings.WorldColorEnabled then
        task.defer(function() if obj and obj.Parent then colorObject(obj) end end)
    end
end)
RunService.RenderStepped:Connect(function()
    if WorldSettings.SkyColorEnabled then
        local sc = WorldSettings.SkyColor
        Lighting.Ambient, Lighting.OutdoorAmbient = sc, sc
        Lighting.ColorShift_Bottom, Lighting.ColorShift_Top = sc, sc
        Lighting.FogColor = sc
        local a = Lighting:FindFirstChild("MS_AtmSky")
        if not a then a = Instance.new("Atmosphere"); a.Name="MS_AtmSky"; a.Parent=Lighting end
        a.Color, a.Decay = sc, sc
    else
        local a = Lighting:FindFirstChild("MS_AtmSky")
        if a then a:Destroy() end
    end
end)
AddToggle(NightBox, "WorldColorToggle", {Text="World Color", Default=false,
    Callback=function(v) WorldSettings.WorldColorEnabled = v; RefreshWorldColor() end})
AddColor(NightBox, "WorldColorPicker", {Default=Color3.fromRGB(255,255,255), Title="World Color",
    Callback=function(c) WorldSettings.WorldColor = c; if WorldSettings.WorldColorEnabled then RefreshWorldColor() end end})
AddToggle(NightBox, "SkyColorToggle", {Text="Second Color", Default=false,
    Callback=function(v) WorldSettings.SkyColorEnabled = v end})
AddColor(NightBox, "SkyColorPicker", {Default=Color3.fromRGB(255,255,255), Title="Second Color",
    Callback=function(c) WorldSettings.SkyColor = c end})

-- ── Atmosphere ──────────────────────────────────────────────────────────
AddToggle(AtmosBox, "Atmosphere", {Text="Enable", Default=false, Callback=function(v)
    if v and Toggles.EnableSkybox and Toggles.EnableSkybox.Value then Toggles.EnableSkybox:SetValue(false) end
end})
AddSlider(AtmosBox, "AtmosphereDensity", {Text="Density", Default=0.3, Min=0, Max=1, Rounding=2})
AddSlider(AtmosBox, "SubAtmosphereHaze", {Text="Haze", Default=0, Min=0, Max=10, Rounding=1})
AddSlider(AtmosBox, "AtmosphereGlare", {Text="Glare", Default=0, Min=0, Max=10, Rounding=1})
AddToggle(AtmosBox, "EnableColorCorrection", {Text="Color Correction", Default=false})
AddSlider(AtmosBox, "SaturationSlider", {Text="Saturation", Default=0, Min=-1, Max=1, Rounding=2})
AddSlider(AtmosBox, "ContrastSlider", {Text="Contrast", Default=0, Min=-1, Max=1, Rounding=1})

task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if Toggles.Atmosphere and Toggles.Atmosphere.Value then
                if Toggles.EnableSkybox and Toggles.EnableSkybox.Value then Toggles.EnableSkybox:SetValue(false) end
                local a = Lighting:FindFirstChildOfClass("Atmosphere")
                if not a then a = Instance.new("Atmosphere", Lighting) end
                a.Density = Options.AtmosphereDensity and Options.AtmosphereDensity.Value or 0.3
                a.Haze = Options.SubAtmosphereHaze and Options.SubAtmosphereHaze.Value or 0
                a.Glare = Options.AtmosphereGlare and Options.AtmosphereGlare.Value or 0
            else
                local a = Lighting:FindFirstChildOfClass("Atmosphere")
                if a then a:Destroy() end
            end
            if Toggles.EnableColorCorrection and Toggles.EnableColorCorrection.Value then
                local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) end
                cc.Enabled = true
                cc.Saturation = Options.SaturationSlider and Options.SaturationSlider.Value or 0
                cc.Contrast = Options.ContrastSlider and Options.ContrastSlider.Value or 0
            else
                local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                if cc then cc.Enabled = false end
            end
        end)
    end
end)

-- =========================================================================
-- =========================================================================
--                             COMBAT TAB
-- =========================================================================
-- =========================================================================
local CombatBox = CombatMenu:AddSection({Position='left', Name="MEMESENSE MODE"})
local BlatantBox = CombatMenu:AddSection({Position='right', Name="BLATANT / RAGE"})

AddToggle(CombatBox, "MemesenseMainToggle", {Text="Memesense Mode", Default=false})
AddKeybind(CombatBox, "MemesenseKeybind", {Text="Memesense Keybind", Default=Enum.KeyCode.Unknown})
AddToggle(CombatBox, "CubeAimbotEnabled", {Text="Cube Smart Aimbot", Default=false})
AddToggle(CombatBox, "CubeVisibleCheck", {Text="Visible Check", Default=false})
AddDropdown(CombatBox, "CubeHitPart", {Text="Hit Selection", Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, Default="Head"})
AddToggle(CombatBox, "CubeTriggerbot", {Text="Enable Triggerbot", Default=false})
AddSlider(CombatBox, "CubeTriggerbotDelay", {Text="Triggerbot Delay", Default=0.01, Min=0, Max=1, Rounding=3})
AddToggle(CombatBox, "BulletImpactV1Enabled", {Text="Cube Checker", Default=false})
AddColor(CombatBox, "BulletImpactV1Color", {Default=Color3.fromRGB(255,0,0), Title="Cube Checker Color"})
AddToggle(CombatBox, "BulletImpactV1Rainbow", {Text="Cube Checker Rainbow", Default=false})
AddSlider(CombatBox, "BulletImpactV1Size", {Text="Impact Size", Default=1.5, Min=0.5, Max=4, Rounding=1})
AddSlider(CombatBox, "BulletImpactV1Dist", {Text="Max Ray Distance", Default=20, Min=1, Max=50, Rounding=0})
AddToggle(CombatBox, "ShowTargetPlayer", {Text="Show Target Player", Default=false})
AddDropdown(CombatBox, "ShowTargetMode", {Text="Target Display Mode", Values={"Line","Crosshair"}, Default="Crosshair"})
AddColor(CombatBox, "ShowTargetLineColor", {Default=Color3.fromRGB(0,255,255), Title="Line Color"})
AddColor(CombatBox, "ShowTargetCrosshairColor", {Default=Color3.fromRGB(0,255,255), Title="Crosshair Color"})
AddToggle(CombatBox, "ShowPenetration", {Text="Show Penetration", Default=false})

-- ── Silent Aim + Ragebot ────────────────────────────────────────────────
AddToggle(BlatantBox, "SilentAim", {Text="Enable Silent Aim", Default=false})
AddToggle(BlatantBox, "SilentWallbang", {Text="Wallbang", Default=false})
AddToggle(BlatantBox, "SilentUseFovCircle", {Text="Use FOV Circle", Default=false})
AddColor(BlatantBox, "SilentFovColor", {Default=Color3.fromRGB(255,0,0), Title="Silent FOV Color"})
AddSlider(BlatantBox, "SilentFovCircleRadius", {Text="FOV Radius", Default=50, Min=0, Max=300, Rounding=0})
AddDropdown(BlatantBox, "SilentHitPart", {Text="Hit Selection", Values={
    "HumanoidRootPart","Head","LeftLowerArm","LowerTorso","RightHand","RightLowerArm",
    "LeftFoot","LeftHand","RightFoot","RightLowerLeg","LeftLowerLeg","RightUpperArm",
    "LeftUpperArm","UpperTorso","RightUpperLeg","LeftUpperLeg"}, Default="Head"})
AddToggle(BlatantBox, "SilentTeamCheck", {Text="Team Check", Default=true})

AddToggle(BlatantBox, "Ragebot", {Text="Enable Ragebot", Default=false})
AddSlider(BlatantBox, "RageDelay", {Text="Delay", Default=0.01, Min=0, Max=1, Rounding=3})
AddDropdown(BlatantBox, "RageHitPart", {Text="Hit Selection", Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, Default="Head"})
AddToggle(BlatantBox, "RagebotVisibleCheck", {Text="Visible Check", Default=true})
AddToggle(BlatantBox, "RagebotTeamCheck", {Text="Team Check", Default=true})
AddToggle(BlatantBox, "RagebotWallCheck", {Text="Wall Check", Default=false})

local priorityTargetName = nil
local function refreshPriorityList()
    local names = {"[ AUTO ]"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local pt, lt = get_player_team(p), get_player_team(LP)
            if pt==nil or lt==nil or pt~=lt then table.insert(names, p.Name) end
        end
    end
    return names
end
AddDropdown(BlatantBox, "RagePriorityTarget", {Text="Priority Target",
    Values=refreshPriorityList(), Default="[ AUTO ]",
    Callback=function(v) priorityTargetName = (v=="[ AUTO ]") and nil or v end})
AddButton(BlatantBox, "Refresh Priority List", function()
    Options.RagePriorityTarget:SetValues(refreshPriorityList())
    Options.RagePriorityTarget:SetValue("[ AUTO ]")
    priorityTargetName = nil
end)

-- =========================================================================
-- =========================================================================
--                            VISUALS TAB
-- =========================================================================
-- =========================================================================
local ESPBox = VisualsMenu:AddSection({Position='left', Name="ESP"})
local GrenadeBox = VisualsMenu:AddSection({Position='right', Name="GRENADE ESP"})
local ChamsBox = VisualsMenu:AddSection({Position='right', Name="CHAMS"})

-- ── ESP ─────────────────────────────────────────────────────────────────
AddToggle(ESPBox, "ESPEnabled", {Text="ESP Enabled", Default=false})
AddToggle(ESPBox, "ESPTeamCheck", {Text="Team Check", Default=true})
AddDropdown(ESPBox, "ESPBoxType", {Text="Box ESP", Values={"2D Box","3D Box","Corner Box","Disabled"}, Default="2D Box"})
AddColor(ESPBox, "ESPBoxColorA", {Default=Color3.new(1,1,1), Title="Box Color A"})
AddColor(ESPBox, "ESPBoxColorB", {Default=Color3.fromRGB(0,200,255), Title="Box Color B"})
AddToggle(ESPBox, "ESPBoxFillGradient", {Text="Fill Gradient", Default=false})
AddColor(ESPBox, "ESPFillColorA", {Default=Color3.fromRGB(255,50,50), Title="Fill Color A"})
AddColor(ESPBox, "ESPFillColorB", {Default=Color3.fromRGB(50,50,255), Title="Fill Color B"})
AddToggle(ESPBox, "ESPBoxFillRotation", {Text="Fill Rotation", Default=false})
AddSlider(ESPBox, "ESPBoxRotationSpeed", {Text="Rotation Speed", Default=2, Min=0.1, Max=10, Rounding=1})
AddToggle(ESPBox, "ESPName", {Text="Name ESP", Default=false})
AddColor(ESPBox, "ESPNameColor", {Default=Color3.new(1,1,1), Title="Name Color"})
AddToggle(ESPBox, "ESPHealth", {Text="Health Bar", Default=false})
AddColor(ESPBox, "ESPHealthTopColor", {Default=Color3.fromRGB(0,255,0), Title="Health Top"})
AddColor(ESPBox, "ESPHealthBottomColor", {Default=Color3.fromRGB(255,0,0), Title="Health Bottom"})
AddToggle(ESPBox, "ESPHealthText", {Text="Health Text", Default=false})
AddColor(ESPBox, "ESPHealthTextColor", {Default=Color3.new(1,1,1), Title="HP Text Color"})
AddToggle(ESPBox, "ESPDistance", {Text="Distance ESP", Default=false})
AddColor(ESPBox, "ESPDistanceColor", {Default=Color3.new(1,1,1), Title="Distance Color"})
AddToggle(ESPBox, "ESPWeapon", {Text="Show Weapon Name", Default=false})
AddColor(ESPBox, "ESPWeaponColor", {Default=Color3.new(1,1,1), Title="Weapon Color"})
AddToggle(ESPBox, "ESPTracer", {Text="Tracer ESP", Default=false})
AddColor(ESPBox, "ESPTracerColor", {Default=Color3.new(1,1,1), Title="Tracer Color A"})
AddColor(ESPBox, "ESPTracerColorB", {Default=Color3.fromRGB(255,0,128), Title="Tracer Color B"})
AddDropdown(ESPBox, "ESPTracerOrigin", {Text="Tracer Origin", Values={"Bottom","Top","Center","Mouse"}, Default="Bottom"})
AddToggle(ESPBox, "ESPSkeleton", {Text="Skeleton ESP", Default=false})
AddColor(ESPBox, "ESPSkeletonColorA", {Default=Color3.new(1,1,1), Title="Skel A"})
AddColor(ESPBox, "ESPSkeletonColorB", {Default=Color3.fromRGB(0,255,255), Title="Skel B"})
AddToggle(ESPBox, "ESPCircularTarget", {Text="Circular Target", Default=false})
AddColor(ESPBox, "ESPCircularTargetColor", {Default=Color3.fromRGB(255,200,0), Title="Circular Target Color"})

-- ── Grenade ESP ─────────────────────────────────────────────────────────
AddToggle(GrenadeBox, "GrenadeTracers", {Text="Grenade Tracers", Default=false})
AddColor(GrenadeBox, "GrenadeTracerColor", {Default=Color3.fromRGB(255,100,0), Title="Tracer Color"})
AddToggle(GrenadeBox, "MolotovZoneESP", {Text="Molotov Zone ESP", Default=false})
AddColor(GrenadeBox, "GrenadeZoneColor", {Default=Color3.fromRGB(255,60,0), Title="Zone Color"})
AddToggle(GrenadeBox, "SmokeZoneESP", {Text="Smoke Zone ESP", Default=false})
AddColor(GrenadeBox, "SmokeZoneColor", {Default=Color3.fromRGB(180,180,180), Title="Smoke Color"})

-- ── Chams ───────────────────────────────────────────────────────────────
AddToggle(ChamsBox, "ChamsEnabled", {Text="Enabled", Default=false})
AddToggle(ChamsBox, "ChamsTeamCheck", {Text="TeamCheck", Default=true})
AddDropdown(ChamsBox, "ChamsMaterialVisible", {Text="MaterialVisible", Values={"Neon","Metal","ForceField","SmoothPlastic"}, Default="Neon"})
AddColor(ChamsBox, "ChamsColorVisible", {Default=Color3.fromRGB(0,200,0), Title="ColorVisible"})
AddSlider(ChamsBox, "ChamsAlphaVisible", {Text="FillTransparencyVis", Default=0.3, Min=0, Max=1, Rounding=2})
AddSlider(ChamsBox, "ChamsOutlineAlphaVisible", {Text="OutlineVis", Default=0, Min=0, Max=1, Rounding=2})
AddDropdown(ChamsBox, "ChamsMaterialUnvisible", {Text="MaterialUnvisible", Values={"Neon","Metal","ForceField","SmoothPlastic"}, Default="Metal"})
AddColor(ChamsBox, "ChamsColorUnvisible", {Default=Color3.fromRGB(200,0,0), Title="ColorUnvisible"})
AddSlider(ChamsBox, "ChamsAlphaUnvisible", {Text="FillTransparencyUnvis", Default=0.3, Min=0, Max=1, Rounding=2})
AddSlider(ChamsBox, "ChamsOutlineAlphaUnvisible", {Text="OutlineUnvis", Default=0, Min=0, Max=1, Rounding=2})

-- =========================================================================
-- [ ESP SYSTEM ]
-- =========================================================================
local espinstances = {}
local SKELETON_BONES_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SKELETON_BONES_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local AABB_CORNER_SIGNS = {{0,0,0},{1,0,0},{0,1,0},{1,1,0},{0,0,1},{1,0,1},{0,1,1},{1,1,1}}
local BOX_3D_EDGES = {{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}

local _rotAngle = 0
local MAX_FILL_LINES = 200
local MAX_HP_SEGMENTS = 12
local GRAD_STEPS = 4
local BASE_DIST, BASE_W, BASE_H = 20, 86, 155
local partHalfExtentCache = setmetatable({}, {__mode="k"})

local function get_part_half_extent(part)
    local c = partHalfExtentCache[part]
    if not c then
        local s = part.Size
        c = {hx=s.X*.5, hy=s.Y*.5, hz=s.Z*.5}
        partHalfExtentCache[part] = c
    end
    return c.hx, c.hy, c.hz
end

local function compute_world_aabb(parts)
    local x0,y0,z0 = math.huge, math.huge, math.huge
    local x1,y1,z1 = -math.huge, -math.huge, -math.huge
    for i=1,#parts do
        local p = parts[i]
        local hx,hy,hz = get_part_half_extent(p)
        local px,py,pz,r00,r01,r02,r10,r11,r12,r20,r21,r22 = p.CFrame:GetComponents()
        local ex = math.abs(r00)*hx+math.abs(r01)*hy+math.abs(r02)*hz
        local ey = math.abs(r10)*hx+math.abs(r11)*hy+math.abs(r12)*hz
        local ez = math.abs(r20)*hx+math.abs(r21)*hy+math.abs(r22)*hz
        if px-ex<x0 then x0=px-ex end; if py-ey<y0 then y0=py-ey end; if pz-ez<z0 then z0=pz-ez end
        if px+ex>x1 then x1=px+ex end; if py+ey>y1 then y1=py+ey end; if pz+ez>z1 then z1=pz+ez end
    end
    if x0==math.huge then return nil end
    return x0,y0,z0,x1,y1,z1
end

local function project_fixed_box(x0,y0,z0,x1,y1,z1)
    local cx,cy,cz = (x0+x1)*.5,(y0+y1)*.5,(z0+z1)*.5
    local sp,vis = Camera:WorldToViewportPoint(Vector3.new(cx,cy,cz))
    if not vis and sp.Z <= 0 then return nil,nil,false end
    local depth = sp.Z
    if depth <= 0 then depth = 0.1 end
    local scale = BASE_DIST/depth
    local w,h = BASE_W*scale, BASE_H*scale
    return Vector2.new(sp.X-w*.5, sp.Y-h*.5), Vector2.new(sp.X+w*.5, sp.Y+h*.5), true
end

local function project_aabb_corners_3d(x0,y0,z0,x1,y1,z1)
    local sc, on = {}, false
    for i=1,8 do
        local s = AABB_CORNER_SIGNS[i]
        local wx = s[1]==0 and x0 or x1
        local wy = s[2]==0 and y0 or y1
        local wz = s[3]==0 and z0 or z1
        local pos, vis = Camera:WorldToViewportPoint(Vector3.new(wx,wy,wz))
        sc[i] = Vector2.new(pos.X,pos.Y)
        if vis then on = true end
    end
    return sc, on
end

local function ensure_character_parts(instance, data)
    if data.partlist then return data.partlist end
    local list = {}
    local function add(p)
        if p:IsA("BasePart") then
            list[#list+1] = p
            partHalfExtentCache[p] = nil
        end
    end
    if instance:IsA("Model") then
        for _, p in next, instance:GetDescendants() do add(p) end
    elseif instance:IsA("BasePart") then add(instance) end
    data.partlist = list
    return list
end

local function setupFillLines()
    local lines = {}
    for i=1, MAX_FILL_LINES do
        local l = Drawing.new("Line")
        l.Thickness = 4
        l.Transparency = 0.3
        l.Visible = false
        lines[i] = l
    end
    return lines
end

local function drawFillGradient360(fillLines, x, y, w, h, colorA, colorB, angle)
    local dx, dy = math.cos(angle), math.sin(angle)
    local cx, cy = x+w*0.5, y+h*0.5
    local maxDot = math.max((math.abs(dx)*w + math.abs(dy)*h)*0.5, 1)
    local rows = math.clamp(math.floor(h*0.8), 15, MAX_FILL_LINES)
    local rowH = h/rows
    for i=1, rows do
        local py = y + (i-0.5)*rowH
        local dotL = ((x-cx)*dx + (py-cy)*dy)/maxDot
        local dotR = ((x+w-cx)*dx + (py-cy)*dy)/maxDot
        local tL = math.clamp(dotL*0.5+0.5, 0, 1)
        local tR = math.clamp(dotR*0.5+0.5, 0, 1)
        local line = fillLines[i]
        line.Color = lerpColor(colorA, colorB, (tL+tR)*0.5)
        line.Thickness = math.clamp(rowH+1.5, 2, 8)
        line.From = Vector2.new(x+1, py)
        line.To = Vector2.new(x+w-1, py)
        line.Visible = true
    end
    for i=rows+1, #fillLines do fillLines[i].Visible = false end
end

local function drawBoxOutlineGradient(box, x, y, w, h, colorA, colorB, rotOff)
    local grad = box.grad_lines
    local idx = 0
    local sides = {{x,y,x+w,y},{x+w,y,x+w,y+h},{x+w,y+h,x,y+h},{x,y+h,x,y}}
    for si=1,4 do
        local s = sides[si]
        local x1,y1,x2,y2 = s[1],s[2],s[3],s[4]
        for step=0, GRAD_STEPS-1 do
            idx = idx+1
            local tA, tB = step/GRAD_STEPS, (step+1)/GRAD_STEPS
            local tMid = (((si-1)/4)+(tA/4)+rotOff)%1
            local col = lerpColor(colorA, colorB, tMid)
            local line = grad[idx]
            if line then
                line.From = Vector2.new(x1+(x2-x1)*tA, y1+(y2-y1)*tA)
                line.To = Vector2.new(x1+(x2-x1)*tB, y1+(y2-y1)*tB)
                line.Color = col
                line.Visible = true
            end
        end
    end
    for i=idx+1, #grad do grad[i].Visible = false end
end

local function hideBox(box)
    box.outline.Visible = false
    box.fill.Visible = false
    for _, l in ipairs(box.grad_lines) do l.Visible = false end
    for _, l in ipairs(box.fill_grad_lines) do l.Visible = false end
    for _, l in ipairs(box.corner_fill) do l.Visible = false end
    for _, l in ipairs(box.corner_outline) do l.Visible = false end
    for _, l in ipairs(box.box_3d_lines) do l.Visible = false end
end

local espfunctions = {}
function espfunctions.add_box(instance)
    if not instance or (espinstances[instance] and espinstances[instance].box) then return end
    local function mkLine(th) local l=Drawing.new("Line"); l.Thickness=th; l.Transparency=1; l.Visible=false; return l end
    local function mkSq(th,f) local s=Drawing.new("Square"); s.Thickness=th; s.Filled=f; s.Transparency=1; s.Visible=false; return s end
    local box = {}
    box.outline = mkSq(3, false)
    box.fill = mkSq(1, false)
    box.grad_lines = {}
    for i=1,16 do box.grad_lines[i] = mkLine(1) end
    box.fill_grad_lines = setupFillLines()
    box.corner_fill = {}; box.corner_outline = {}
    for i=1,8 do box.corner_fill[i]=mkLine(1); box.corner_outline[i]=mkLine(3) end
    box.box_3d_lines = {}
    for i=1,12 do box.box_3d_lines[i] = mkLine(2) end
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].box = box
end

function espfunctions.add_healthbar(instance)
    if not instance or (espinstances[instance] and espinstances[instance].healthbar) then return end
    local bg = Drawing.new("Square")
    bg.Thickness, bg.Filled, bg.Color, bg.Transparency, bg.Visible = 1, true, Color3.new(0,0,0), 0.5, false
    local segs = {}
    for i=1, MAX_HP_SEGMENTS do
        local l = Drawing.new("Line")
        l.Thickness = 3; l.Transparency = 1; l.Visible = false
        segs[i] = l
    end
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].healthbar = {background = bg, segments = segs}
end

function espfunctions.add_healthtext(instance)
    if not instance or (espinstances[instance] and espinstances[instance].healthtext) then return end
    local t = Drawing.new("Text")
    t.Center=false; t.Outline=true; t.Font=1; t.Transparency=1; t.Visible=false
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].healthtext = t
end

function espfunctions.add_name(instance)
    if not instance or (espinstances[instance] and espinstances[instance].name) then return end
    local t = Drawing.new("Text")
    t.Center=true; t.Outline=true; t.Font=1; t.Transparency=1; t.Visible=false
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].name = t
end

function espfunctions.add_distance(instance)
    if not instance or (espinstances[instance] and espinstances[instance].distance) then return end
    local t = Drawing.new("Text")
    t.Center=true; t.Outline=true; t.Font=1; t.Transparency=1; t.Visible=false
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].distance = t
end

function espfunctions.add_tracer(instance)
    if not instance or (espinstances[instance] and espinstances[instance].tracer) then return end
    local o = Drawing.new("Line"); o.Thickness=3; o.Transparency=1
    local f = Drawing.new("Line"); f.Thickness=1; f.Transparency=1
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].tracer = {outline=o, fill=f}
end

function espfunctions.add_skeleton(instance, options)
    if not instance or (espinstances[instance] and espinstances[instance].skeleton) then return end
    options = options or {}
    local isR15 = instance:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and SKELETON_BONES_R15 or SKELETON_BONES_R6
    local lines, bp = {}, {}
    for i=1,#bones do
        local l = Drawing.new("Line")
        l.Thickness = options.thickness or 2
        l.Transparency = 1; l.Visible = false
        lines[i] = l
        bp[i] = {instance:FindFirstChild(bones[i][1]), instance:FindFirstChild(bones[i][2])}
    end
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].skeleton = {lines=lines, bone_parts=bp, screenCache={}}
end

function espfunctions.add_weapon(instance)
    if not instance or (espinstances[instance] and espinstances[instance].weapon) then return end
    local t = Drawing.new("Text")
    t.Center=true; t.Outline=true; t.Font=1; t.Transparency=1; t.Visible=false
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].weapon = t
end

function espfunctions.add_circulartarget(instance)
    if not instance or (espinstances[instance] and espinstances[instance].circulartarget) then return end
    local SEGS = 32
    local lines = {}
    for i=1,SEGS do
        local l = Drawing.new("Line"); l.Thickness=1.5; l.Transparency=1; l.Visible=false
        lines[i] = l
    end
    local TRAIL = 25
    local trailLines, glowLines = {}, {}
    for i=1,TRAIL do
        local l = Drawing.new("Line"); l.Thickness=2.5; l.Transparency=0.4; l.Visible=false
        trailLines[i] = l
        local g = Drawing.new("Line"); g.Thickness=5; g.Transparency=0.15; g.Visible=false
        glowLines[i] = g
    end
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].circulartarget = {
        lines=lines, trailLines=trailLines, neonGlowLines=glowLines,
        segments=SEGS, alpha=0, movingUp=true, trailHistory={}
    }
end

local function hide_all(data)
    if data.box then hideBox(data.box) end
    if data.healthbar then
        data.healthbar.background.Visible = false
        for _,s in ipairs(data.healthbar.segments) do s.Visible = false end
    end
    if data.healthtext then data.healthtext.Visible = false end
    if data.name then data.name.Visible = false end
    if data.distance then data.distance.Visible = false end
    if data.tracer then data.tracer.outline.Visible=false; data.tracer.fill.Visible=false end
    if data.skeleton then for _,l in ipairs(data.skeleton.lines) do l.Visible = false end end
    if data.weapon then data.weapon.Visible = false end
    if data.circulartarget then
        for _,l in ipairs(data.circulartarget.lines) do l.Visible = false end
        for _,l in ipairs(data.circulartarget.trailLines) do l.Visible = false end
        for _,l in ipairs(data.circulartarget.neonGlowLines) do l.Visible = false end
    end
end

local function cleanup_instance(instance, data)
    pcall(function()
        if data.box then
            data.box.outline:Remove(); data.box.fill:Remove()
            for _,l in next,data.box.grad_lines do l:Remove() end
            for _,l in next,data.box.fill_grad_lines do l:Remove() end
            for _,l in next,data.box.corner_fill do l:Remove() end
            for _,l in next,data.box.corner_outline do l:Remove() end
            for _,l in next,data.box.box_3d_lines do l:Remove() end
        end
        if data.healthbar then
            data.healthbar.background:Remove()
            for _,s in ipairs(data.healthbar.segments) do s:Remove() end
        end
        if data.healthtext then data.healthtext:Remove() end
        if data.name then data.name:Remove() end
        if data.distance then data.distance:Remove() end
        if data.tracer then data.tracer.outline:Remove(); data.tracer.fill:Remove() end
        if data.skeleton then for _,l in next,data.skeleton.lines do l:Remove() end end
        if data.weapon then data.weapon:Remove() end
        if data.circulartarget then
            for _,l in ipairs(data.circulartarget.lines) do l:Remove() end
            for _,l in ipairs(data.circulartarget.trailLines) do l:Remove() end
            for _,l in ipairs(data.circulartarget.neonGlowLines) do l:Remove() end
        end
    end)
end

local weaponAttrCache, weaponNameCache = {}, {}
local function GetWeaponName(player)
    if not player then return "None" end
    local attr = player:GetAttribute("CurrentEquipped")
    if attr ~= weaponAttrCache[player] then
        weaponAttrCache[player] = attr
        if attr then
            local ok, dec = pcall(function() return HttpService:JSONDecode(attr) end)
            weaponNameCache[player] = (ok and dec and dec.Name) or "None"
        else weaponNameCache[player] = "None" end
    end
    return weaponNameCache[player] or "None"
end

local function get_cached_screen_pos(cache, part)
    local c = cache[part]
    if c then return c[1], c[2] end
    local pos, vis = Camera:WorldToViewportPoint(part.Position)
    local sp = Vector2.new(pos.X, pos.Y)
    cache[part] = {sp, vis}
    return sp, vis
end

-- ── ESP Render Loop ─────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
    if Toggles.ESPBoxFillRotation and Toggles.ESPBoxFillRotation.Value then
        _rotAngle = (_rotAngle + dt * (Options.ESPBoxRotationSpeed and Options.ESPBoxRotationSpeed.Value or 2)) % (math.pi*2)
    end
    local camPos = Camera.CFrame.Position
    local vp = Camera.ViewportSize
    local teamCheck = Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value
    local rotOff1 = _rotAngle / (math.pi*2)

    for instance, data in next, espinstances do
        if not instance or not instance.Parent then
            cleanup_instance(instance, data)
            espinstances[instance] = nil
            continue
        end
        if instance == LP.Character then hide_all(data); continue end
        if teamCheck and isCharacterAlly(instance) then hide_all(data); continue end

        local healthAttr = instance:GetAttribute("Health")
        local maxHealthAttr = instance:GetAttribute("MaxHealth") or 100
        local isDeadAttr = instance:GetAttribute("Dead")
        if isDeadAttr == true or (healthAttr and healthAttr <= 0) then
            hide_all(data); continue
        end

        local needBox    = Toggles.ESPEnabled.Value and Options.ESPBoxType.Value ~= "Disabled" and data.box ~= nil
        local needHp     = Toggles.ESPEnabled.Value and Toggles.ESPHealth.Value and data.healthbar ~= nil
        local needHpTxt  = Toggles.ESPEnabled.Value and Toggles.ESPHealthText.Value and data.healthtext ~= nil
        local needName   = Toggles.ESPEnabled.Value and Toggles.ESPName.Value and data.name ~= nil
        local needDist   = Toggles.ESPEnabled.Value and Toggles.ESPDistance.Value and data.distance ~= nil
        local needTracer = Toggles.ESPEnabled.Value and Toggles.ESPTracer.Value and data.tracer ~= nil
        local needSkel   = Toggles.ESPEnabled.Value and Toggles.ESPSkeleton.Value and data.skeleton ~= nil
        local needWep    = Toggles.ESPEnabled.Value and Toggles.ESPWeapon.Value and data.weapon ~= nil
        local needCirc   = Toggles.ESPEnabled.Value and Toggles.ESPCircularTarget.Value and data.circulartarget ~= nil

        if data.box and not needBox then hideBox(data.box) end
        if data.healthbar and not needHp then
            data.healthbar.background.Visible = false
            for _,s in ipairs(data.healthbar.segments) do s.Visible = false end
        end
        if data.healthtext and not needHpTxt then data.healthtext.Visible = false end
        if data.name and not needName then data.name.Visible = false end
        if data.distance and not needDist then data.distance.Visible = false end
        if data.tracer and not needTracer then data.tracer.outline.Visible=false; data.tracer.fill.Visible=false end
        if data.skeleton and not needSkel then for _,l in ipairs(data.skeleton.lines) do l.Visible = false end end
        if data.weapon and not needWep then data.weapon.Visible = false end
        if data.circulartarget and not needCirc then
            for _,l in ipairs(data.circulartarget.lines) do l.Visible = false end
            for _,l in ipairs(data.circulartarget.trailLines) do l.Visible = false end
            for _,l in ipairs(data.circulartarget.neonGlowLines) do l.Visible = false end
        end

        if not (needBox or needHp or needHpTxt or needName or needDist or needTracer or needSkel or needWep or needCirc) then continue end

        local parts = ensure_character_parts(instance, data)
        local min2, max2, onscreen
        local c3d, on3d
        local x0,y0,z0,x1,y1,z1 = compute_world_aabb(parts)
        if x0 then
            min2, max2, onscreen = project_fixed_box(x0,y0,z0,x1,y1,z1)
            if needBox and Options.ESPBoxType.Value == "3D Box" then
                c3d, on3d = project_aabb_corners_3d(x0,y0,z0,x1,y1,z1)
            end
        end

        -- BOX
        if data.box and needBox and onscreen and min2 and max2 then
            local x,y = min2.X, min2.Y
            local w = max2.X - min2.X
            local h = max2.Y - min2.Y
            local cA = Options.ESPBoxColorA.Value
            local cB = Options.ESPBoxColorB.Value
            local fA = Options.ESPFillColorA.Value
            local fB = Options.ESPFillColorB.Value
            local bt = Options.ESPBoxType.Value
            if bt == "2D Box" then
                if Toggles.ESPBoxFillGradient.Value then
                    drawFillGradient360(data.box.fill_grad_lines, x, y, w, h, fA, fB, _rotAngle)
                else
                    for _,l in ipairs(data.box.fill_grad_lines) do l.Visible = false end
                end
                drawBoxOutlineGradient(data.box, x, y, w, h, cA, cB, rotOff1)
                data.box.outline.Visible = false
                data.box.fill.Visible = false
                for _,l in ipairs(data.box.corner_fill) do l.Visible = false end
                for _,l in ipairs(data.box.corner_outline) do l.Visible = false end
                for _,l in ipairs(data.box.box_3d_lines) do l.Visible = false end
            elseif bt == "Corner Box" then
                for _,l in ipairs(data.box.grad_lines) do l.Visible = false end
                data.box.outline.Visible = false
                data.box.fill.Visible = false
                if Toggles.ESPBoxFillGradient.Value then
                    drawFillGradient360(data.box.fill_grad_lines, x, y, w, h, fA, fB, _rotAngle)
                else for _,l in ipairs(data.box.fill_grad_lines) do l.Visible = false end end
                local len = math.min(w,h)*.25
                local corners = {
                    {Vector2.new(x,y), Vector2.new(x+len,y)},
                    {Vector2.new(x,y), Vector2.new(x,y+len)},
                    {Vector2.new(x+w-len,y), Vector2.new(x+w,y)},
                    {Vector2.new(x+w,y), Vector2.new(x+w,y+len)},
                    {Vector2.new(x,y+h), Vector2.new(x+len,y+h)},
                    {Vector2.new(x,y+h-len), Vector2.new(x,y+h)},
                    {Vector2.new(x+w-len,y+h), Vector2.new(x+w,y+h)},
                    {Vector2.new(x+w,y+h-len), Vector2.new(x+w,y+h)},
                }
                for i=1,8 do
                    local t = (i-1)/8
                    local col = lerpColor(cA, cB, t)
                    data.box.corner_outline[i].From = corners[i][1]
                    data.box.corner_outline[i].To = corners[i][2]
                    data.box.corner_outline[i].Color = Color3.new(0,0,0)
                    data.box.corner_outline[i].Visible = true
                    data.box.corner_fill[i].From = corners[i][1]
                    data.box.corner_fill[i].To = corners[i][2]
                    data.box.corner_fill[i].Color = col
                    data.box.corner_fill[i].Visible = true
                end
                for _,l in ipairs(data.box.box_3d_lines) do l.Visible = false end
            elseif bt == "3D Box" then
                for _,l in ipairs(data.box.fill_grad_lines) do l.Visible = false end
                for _,l in ipairs(data.box.grad_lines) do l.Visible = false end
                data.box.outline.Visible = false
                data.box.fill.Visible = false
                for _,l in ipairs(data.box.corner_fill) do l.Visible = false end
                for _,l in ipairs(data.box.corner_outline) do l.Visible = false end
                if c3d and #c3d == 8 then
                    for i=1,12 do
                        local e = BOX_3D_EDGES[i]
                        data.box.box_3d_lines[i].From = c3d[e[1]]
                        data.box.box_3d_lines[i].To = c3d[e[2]]
                        data.box.box_3d_lines[i].Color = lerpColor(cA, cB, (i-1)/12)
                        data.box.box_3d_lines[i].Visible = on3d
                    end
                else
                    for _,l in ipairs(data.box.box_3d_lines) do l.Visible = false end
                end
            end
        elseif data.box then
            hideBox(data.box)
        end

        -- HEALTH BAR
        if data.healthbar then
            local bg = data.healthbar.background
            local segs = data.healthbar.segments
            if needHp and onscreen and min2 and max2 and healthAttr then
                local x = min2.X - 6
                local y = min2.Y
                local w = 3
                local h = max2.Y - min2.Y
                local maxHp = maxHealthAttr > 0 and maxHealthAttr or 100
                local frac = math.clamp(healthAttr/maxHp, 0, 1)
                bg.Position = Vector2.new(x-1, y-1)
                bg.Size = Vector2.new(w+2, h+2)
                bg.Visible = true
                local bh = h*frac
                local startY = y + (h - bh)
                local activeCnt = math.clamp(math.floor(MAX_HP_SEGMENTS*frac), 1, MAX_HP_SEGMENTS)
                local segH = bh/activeCnt
                for i=1,MAX_HP_SEGMENTS do
                    local seg = segs[i]
                    if i <= activeCnt then
                        local segFrac = (i-0.5)/MAX_HP_SEGMENTS
                        seg.Color = lerpColor(Options.ESPHealthBottomColor.Value, Options.ESPHealthTopColor.Value, segFrac)
                        seg.From = Vector2.new(x+w*0.5, startY + (i-1)*segH)
                        seg.To = Vector2.new(x+w*0.5, startY + i*segH)
                        seg.Thickness = w
                        seg.Visible = true
                    else seg.Visible = false end
                end
            else
                bg.Visible = false
                for _,s in ipairs(segs) do s.Visible = false end
            end
        end

        -- HEALTH TEXT
        if data.healthtext then
            if needHpTxt and onscreen and min2 and max2 and healthAttr then
                local cur = math.floor(healthAttr + 0.5)
                local maxHp = maxHealthAttr > 0 and maxHealthAttr or 100
                data.healthtext.Text = tostring(cur)
                data.healthtext.Size = 12
                data.healthtext.Color = Options.ESPHealthTextColor.Value
                data.healthtext.Position = Vector2.new(max2.X+4, min2.Y + (max2.Y-min2.Y)*(1 - (healthAttr/maxHp)) - 4)
                data.healthtext.Visible = true
            else data.healthtext.Visible = false end
        end

        -- NAME
        if data.name then
            if needName and onscreen and min2 and max2 then
                data.name.Text = instance.Name
                data.name.Size = 13
                data.name.Color = Options.ESPNameColor.Value
                data.name.Position = Vector2.new((min2.X+max2.X)*.5, min2.Y-15)
                data.name.Visible = true
            else data.name.Visible = false end
        end

        -- DISTANCE
        if data.distance then
            if needDist and onscreen and min2 and max2 then
                local dist = 999
                if instance:IsA("Model") and instance.PrimaryPart then
                    dist = (camPos - instance.PrimaryPart.Position).Magnitude
                elseif instance:IsA("BasePart") then
                    dist = (camPos - instance.Position).Magnitude
                end
                data.distance.Text = tostring(math.floor(dist)).."m"
                data.distance.Size = 13
                data.distance.Color = Options.ESPDistanceColor.Value
                data.distance.Position = Vector2.new((min2.X+max2.X)*.5, max2.Y+2)
                data.distance.Visible = true
            else data.distance.Visible = false end
        end

        -- WEAPON
        if data.weapon then
            if needWep and onscreen and min2 and max2 then
                if not data.player then data.player = Players:GetPlayerFromCharacter(instance) end
                local wn = data.player and GetWeaponName(data.player) or "None"
                data.weapon.Text = "["..wn.."]"
                data.weapon.Size = 13
                data.weapon.Color = Options.ESPWeaponColor.Value
                data.weapon.Position = Vector2.new((min2.X+max2.X)*.5, max2.Y+15)
                data.weapon.Center = true
                data.weapon.Visible = true
            else data.weapon.Visible = false end
        end

        -- TRACER
        if data.tracer then
            if needTracer and onscreen and min2 and max2 then
                local from
                local origin = Options.ESPTracerOrigin.Value
                if origin == "Mouse" then
                    local ml = UserInputService:GetMouseLocation()
                    from = Vector2.new(ml.X, ml.Y)
                elseif origin == "Top" then from = Vector2.new(vp.X/2, 0)
                elseif origin == "Center" then from = Vector2.new(vp.X/2, vp.Y/2)
                else from = Vector2.new(vp.X/2, vp.Y) end
                local to = (min2+max2)/2
                local dist = 0
                if instance:IsA("Model") and instance.PrimaryPart then
                    dist = math.clamp((camPos-instance.PrimaryPart.Position).Magnitude/200, 0, 1)
                end
                local col = lerpColor(Options.ESPTracerColor.Value, Options.ESPTracerColorB.Value, dist)
                data.tracer.outline.From = from
                data.tracer.outline.To = to
                data.tracer.outline.Color = Color3.new(0,0,0)
                data.tracer.outline.Visible = true
                data.tracer.fill.From = from
                data.tracer.fill.To = to
                data.tracer.fill.Color = col
                data.tracer.fill.Visible = true
            else
                data.tracer.outline.Visible = false
                data.tracer.fill.Visible = false
            end
        end

        -- SKELETON
        if data.skeleton then
            if needSkel then
                local bp = data.skeleton.bone_parts
                local lines = data.skeleton.lines
                local sc = data.skeleton.screenCache
                for k in next, sc do sc[k] = nil end
                local any = false
                for i=1,#bp do
                    local pA, pB = bp[i][1], bp[i][2]
                    local line = lines[i]
                    if pA and pB and pA.Parent and pB.Parent then
                        local posA, vA = get_cached_screen_pos(sc, pA)
                        local posB, vB = get_cached_screen_pos(sc, pB)
                        if vA or vB then
                            line.From = posA
                            line.To = posB
                            line.Color = lerpColor(Options.ESPSkeletonColorA.Value, Options.ESPSkeletonColorB.Value, (i-1)/#bp)
                            line.Thickness = 2
                            line.Visible = true
                            any = true
                        else line.Visible = false end
                    else line.Visible = false end
                end
                if not any then for _,l in ipairs(lines) do l.Visible = false end end
            else
                for _,l in ipairs(data.skeleton.lines) do l.Visible = false end
            end
        end

        -- CIRCULAR TARGET
        if data.circulartarget then
            local ct = data.circulartarget
            local head = instance:FindFirstChild("Head")
            local root = instance:IsA("Model") and instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or head
            if needCirc and head and root then
                local speed = 2.0
                if ct.movingUp then
                    ct.alpha = ct.alpha + dt*speed
                    if ct.alpha >= 1 then ct.alpha = 1; ct.movingUp = false end
                else
                    ct.alpha = ct.alpha - dt*speed
                    if ct.alpha <= 0 then ct.alpha = 0; ct.movingUp = true end
                end
                local footPos = root.Position - Vector3.new(0, (root.Size.Y*0.8)+1.2, 0)
                local headPos = head.Position + Vector3.new(0, 0.3, 0)
                local currentPos = footPos:Lerp(headPos, ct.alpha)
                table.insert(ct.trailHistory, 1, currentPos)
                if #ct.trailHistory > #ct.trailLines then table.remove(ct.trailHistory) end
                for i=1,#ct.trailLines do
                    local tl = ct.trailLines[i]
                    local gl = ct.neonGlowLines[i]
                    local p1, p2 = ct.trailHistory[i], ct.trailHistory[i+1]
                    if p1 and p2 then
                        local s1, v1 = Camera:WorldToViewportPoint(p1)
                        local s2, v2 = Camera:WorldToViewportPoint(p2)
                        if v1 or v2 then
                            local fade = math.clamp(1 - (i/#ct.trailLines), 0.05, 1)
                            gl.From = Vector2.new(s1.X, s1.Y); gl.To = Vector2.new(s2.X, s2.Y)
                            gl.Color = Options.ESPCircularTargetColor.Value
                            gl.Transparency = fade*0.35
                            gl.Visible = true
                            tl.From = Vector2.new(s1.X, s1.Y); tl.To = Vector2.new(s2.X, s2.Y)
                            tl.Color = Options.ESPCircularTargetColor.Value
                            tl.Transparency = fade*0.85
                            tl.Visible = true
                        else tl.Visible = false; gl.Visible = false end
                    else tl.Visible = false; gl.Visible = false end
                end
                local R = 2.2
                local SEGS = ct.segments
                local col = Options.ESPCircularTargetColor.Value
                for i=1,SEGS do
                    local aA = (math.pi*2)*((i-1)/SEGS)
                    local aB = (math.pi*2)*(i/SEGS)
                    local wA = currentPos + Vector3.new(math.cos(aA)*R, 0, math.sin(aA)*R)
                    local wB = currentPos + Vector3.new(math.cos(aB)*R, 0, math.sin(aB)*R)
                    local sA, vA = Camera:WorldToViewportPoint(wA)
                    local sB, vB = Camera:WorldToViewportPoint(wB)
                    local line = ct.lines[i]
                    if vA or vB then
                        line.From = Vector2.new(sA.X, sA.Y)
                        line.To = Vector2.new(sB.X, sB.Y)
                        line.Color = col
                        line.Visible = true
                    else line.Visible = false end
                end
            else
                for _,l in ipairs(ct.lines) do l.Visible = false end
                for _,l in ipairs(ct.trailLines) do l.Visible = false end
                for _,l in ipairs(ct.neonGlowLines) do l.Visible = false end
            end
        end
    end
end)

-- ── Character Scanner ───────────────────────────────────────────────────
local espCharacters = {}
local function addEspToCharacter(character)
    if not character or espCharacters[character] then return end
    if character == LP.Character then return end
    espfunctions.add_box(character)
    espfunctions.add_name(character)
    espfunctions.add_healthbar(character)
    espfunctions.add_healthtext(character)
    espfunctions.add_distance(character)
    espfunctions.add_tracer(character)
    espfunctions.add_skeleton(character, {thickness=2})
    espfunctions.add_weapon(character)
    espfunctions.add_circulartarget(character)
    espCharacters[character] = true
end
local function removeEspFromCharacter(character)
    if character then
        if espinstances[character] then
            cleanup_instance(character, espinstances[character])
            espinstances[character] = nil
        end
        espCharacters[character] = nil
    end
end

local charactersFolder = Workspace:WaitForChild("Characters", 5)
local function scanCharactersFolder()
    if not charactersFolder then return end
    local function processContainer(container)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") then
                if child:GetAttribute("Health") ~= nil or child:FindFirstChild("Head") then
                    addEspToCharacter(child)
                end
                processContainer(child)
            end
        end
    end
    processContainer(charactersFolder)
end
scanCharactersFolder()

if charactersFolder then
    charactersFolder.DescendantAdded:Connect(function(desc)
        if desc:IsA("Model") then
            task.wait(0.1)
            if desc:GetAttribute("Health") ~= nil or desc:FindFirstChild("Head") then
                addEspToCharacter(desc)
            end
        end
    end)
    charactersFolder.DescendantRemoving:Connect(function(desc)
        if desc:IsA("Model") then removeEspFromCharacter(desc) end
    end)
end

Players.PlayerRemoving:Connect(function(p)
    if priorityTargetName and p.Name == priorityTargetName then
        priorityTargetName = nil
        pcall(function()
            Options.RagePriorityTarget:SetValues(refreshPriorityList())
            Options.RagePriorityTarget:SetValue("[ AUTO ]")
        end)
    end
end)

-- =========================================================================
-- [ FOV CIRCLES ]
-- =========================================================================
local SilentFovCircle = Drawing.new("Circle")
SilentFovCircle.NumSides=128; SilentFovCircle.Thickness=1; SilentFovCircle.Filled=false; SilentFovCircle.Visible=false
local AimbotFovCircle = Drawing.new("Circle")
AimbotFovCircle.NumSides=128; AimbotFovCircle.Thickness=1; AimbotFovCircle.Filled=false; AimbotFovCircle.Visible=false

-- =========================================================================
-- [ TARGET SYSTEM ]
-- =========================================================================
local SilentTarget, AimbotTarget, RageTarget, CubeSmartTarget
local lockedTargetInstance
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(target)
    local ignore = {LP.Character}
    local myTeam = get_player_team(LP)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and get_player_team(p) == myTeam and p.Character then
            table.insert(ignore, p.Character)
        end
    end
    rayParams.FilterDescendantsInstances = ignore
    local origin = Camera.CFrame.Position
    local dir = target.Position - origin
    local res = Workspace:Raycast(origin, dir, rayParams)
    if res then
        local hitModel = res.Instance:FindFirstAncestorOfClass("Model")
        local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
        if hitPlayer and hitPlayer.Character == target.Parent then return true end
        return false
    end
    return true
end

local function getMemesenseActive()
    local active = Toggles.MemesenseMainToggle and Toggles.MemesenseMainToggle.Value
    if Options.MemesenseKeybind and Options.MemesenseKeybind.Value ~= Enum.KeyCode.Unknown then
        -- keybind logic handled elsewhere
    end
    return active
end

local function FindAllTargets()
    local lchar = LP.Character
    if not lchar then return end
    local myTeam = get_player_team(LP)
    local screenCenter = Camera.ViewportSize / 2
    local sDist, sClose = math.huge, nil
    local rDist, rClose = math.huge, nil
    local cDist, cClose = math.huge, nil
    local memesenseActive = getMemesenseActive()

    local charsFolder = Workspace:FindFirstChild("Characters")
    if not charsFolder then return end

    local allChars = {}
    for _, obj in ipairs(charsFolder:GetDescendants()) do
        if obj:IsA("Model") then
            local head = obj:FindFirstChild("Head")
            local root = obj:FindFirstChild("HumanoidRootPart")
            if (head or root) and obj ~= lchar then
                local dead = obj:GetAttribute("Dead") or obj:GetAttribute("Invincible")
                local hp = obj:GetAttribute("Health")
                if not dead and (hp == nil or hp > 0) then
                    table.insert(allChars, obj)
                end
            end
        end
    end

    -- Memesense cube target
    if memesenseActive then
        local chosen = Options.CubeHitPart.Value or "Head"
        if lockedTargetInstance and lockedTargetInstance.Parent then
            local cm = lockedTargetInstance.Parent
            local dead = cm:GetAttribute("Dead") or cm:GetAttribute("Invincible")
            local hp = cm:GetAttribute("Health")
            if dead or (hp and hp <= 0) then lockedTargetInstance = nil
            elseif Toggles.CubeVisibleCheck.Value and not isVisible(lockedTargetInstance) then
                lockedTargetInstance = nil
            end
        else lockedTargetInstance = nil end

        local best = lockedTargetInstance
        local bestDist = math.huge
        if lockedTargetInstance then
            local bp = lockedTargetInstance.Parent:FindFirstChild(chosen) or lockedTargetInstance
            if bp then bestDist = (Camera.CFrame.Position - bp.Position).Magnitude end
        end
        for _, char in ipairs(allChars) do
            if not isEnemy(char) then continue end
            local tp = char:FindFirstChild(chosen) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if not tp then continue end
            local passVis = true
            if Toggles.CubeVisibleCheck.Value then passVis = isVisible(tp) end
            if passVis then
                local d = (Camera.CFrame.Position - tp.Position).Magnitude
                if d < bestDist then bestDist = d; best = tp end
            end
        end
        lockedTargetInstance = best
        cClose = best
    else lockedTargetInstance = nil end

    -- Rage + Silent
    for _, char in ipairs(allChars) do
        if not isEnemy(char) then continue end
        if Toggles.Ragebot and Toggles.Ragebot.Value then
            local rp = char:FindFirstChild(Options.RageHitPart.Value)
                or char:FindFirstChild("Head")
                or char:FindFirstChild("HumanoidRootPart")
            if rp then
                local _, on = Camera:WorldToViewportPoint(rp.Position)
                local alive = true
                if Toggles.RagebotVisibleCheck.Value and not on then alive = false end
                if alive and Toggles.RagebotWallCheck.Value and not isVisible(rp) then alive = false end
                if alive then
                    local rd = (Camera.CFrame.Position - rp.Position).Magnitude
                    local p = Players:GetPlayerFromCharacter(char)
                    if priorityTargetName and p and p.Name == priorityTargetName then
                        rClose = rp; rDist = 0
                    else
                        if rd < rDist and rDist > 0 then rDist = rd; rClose = rp end
                    end
                end
            end
        end
        if Toggles.SilentAim and Toggles.SilentAim.Value then
            local spName = Options.SilentHitPart.Value or "Head"
            local sp = char:FindFirstChild(spName) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if sp then
                local spos, son = Camera:WorldToViewportPoint(sp.Position)
                if son then
                    local sd = (Vector2.new(spos.X, spos.Y) - screenCenter).Magnitude
                    local maxR = (Toggles.SilentUseFovCircle.Value and Options.SilentFovCircleRadius.Value) or 999999
                    if sd <= maxR then
                        local wallOk = Toggles.SilentWallbang.Value or isVisible(sp)
                        if wallOk and sd < sDist then sDist = sd; sClose = sp end
                    end
                end
            end
        end
    end
    SilentTarget = sClose
    RageTarget = rClose
    CubeSmartTarget = cClose
end

local frameCounter = 0
RunService.RenderStepped:Connect(function()
    frameCounter = frameCounter + 1
    local vp = Camera.ViewportSize
    local center = vp / 2
    pcall(function()
        SilentFovCircle.Position = center
        SilentFovCircle.Radius = Options.SilentFovCircleRadius.Value
        SilentFovCircle.Color = Options.SilentFovColor.Value
        SilentFovCircle.Visible = Toggles.SilentAim.Value and Toggles.SilentUseFovCircle.Value
        AimbotFovCircle.Position = center
        AimbotFovCircle.Color = Color3.fromRGB(0,255,0)
        AimbotFovCircle.Visible = false
    end)
    if frameCounter % 2 == 0 then FindAllTargets() end
    local memesenseActive = getMemesenseActive()
    local targetToPull = nil
    if memesenseActive and CubeSmartTarget then targetToPull = CubeSmartTarget end
    if targetToPull and targetToPull.Parent then
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetToPull.Position)
        end)
    end
end)

-- =========================================================================
-- [ SHOW TARGET SYSTEM ]
-- =========================================================================
local ShowTargetLines = {}
for i=1,4 do
    local l = Drawing.new("Line")
    l.Thickness=2; l.Transparency=1; l.Visible=false
    ShowTargetLines[i] = l
end
local ShowTargetConnector = Drawing.new("Line")
ShowTargetConnector.Thickness=1.5; ShowTargetConnector.Transparency=1; ShowTargetConnector.Visible=false

RunService.RenderStepped:Connect(function()
    pcall(function()
        local memesenseActive = getMemesenseActive()
        local enabled = memesenseActive and Toggles.ShowTargetPlayer.Value
        local mode = Options.ShowTargetMode.Value
        local closest, minDist = nil, math.huge
        local myTeam = get_player_team(LP)
        local chosen = Options.CubeHitPart.Value
        if enabled then
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= LP then
                    local char = v.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local dead = char:GetAttribute("Dead") or char:GetAttribute("Invincible") or (hum and hum.Health <= 0)
                        if not dead then
                            local vTeam = get_player_team(v)
                            if myTeam ~= vTeam then
                                local pp = char:FindFirstChild(chosen) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                                if pp then
                                    local d = (Camera.CFrame.Position - pp.Position).Magnitude
                                    if d < minDist then minDist = d; closest = pp end
                                end
                            end
                        end
                    end
                end
            end
        end
        local lineVis, crossVis = false, false
        if enabled and closest and closest.Parent then
            local sp, on = Camera:WorldToViewportPoint(closest.Position)
            local center = Vector2.new(sp.X, sp.Y)
            local t = tick()
            if mode == "Crosshair" then
                local col = Options.ShowTargetCrosshairColor.Value
                local pulse = 1 + 0.3 * math.sin(t * math.pi * 2)
                local size = 16*pulse
                local gap = 5*pulse
                local ang = math.rad((t*180)%360)
                local baseAngles = {0, math.pi/2, math.pi, 3*math.pi/2}
                for j=1,4 do
                    local l = ShowTargetLines[j]
                    l.Color = col
                    l.Thickness = 2
                    local a = ang + baseAngles[j]
                    local c, s = math.cos(a), math.sin(a)
                    l.From = center + Vector2.new(c*gap, s*gap)
                    l.To = center + Vector2.new(c*(gap+size), s*(gap+size))
                    l.Visible = true
                end
                crossVis = true
            elseif mode == "Line" then
                local col = Options.ShowTargetLineColor.Value
                local vp = Camera.ViewportSize / 2
                ShowTargetConnector.From = vp
                ShowTargetConnector.To = center
                ShowTargetConnector.Color = col
                ShowTargetConnector.Visible = true
                lineVis = true
            end
        end
        if not crossVis then for j=1,4 do ShowTargetLines[j].Visible = false end end
        if not lineVis then ShowTargetConnector.Visible = false end
    end)
end)

-- =========================================================================
-- [ CUBE CHECKER ]
-- =========================================================================
local CubePart = Instance.new("Part")
CubePart.Name = "CubeChecker_Physical"
CubePart.Size = Vector3.new(1.5,1.5,0.01)
CubePart.Anchored=true; CubePart.CanCollide=false; CubePart.CanQuery=false; CubePart.CanTouch=false
CubePart.Material = Enum.Material.Neon
CubePart.Transparency = 0.98
local selectionBox = Instance.new("SelectionBox")
selectionBox.Adornee = CubePart
selectionBox.Color3 = Color3.fromRGB(255,0,0)
selectionBox.LineThickness = 0.04
selectionBox.Transparency = 0.2
selectionBox.Parent = CubePart

local impactRayParams = RaycastParams.new()
impactRayParams.FilterType = Enum.RaycastFilterType.Exclude
impactRayParams.IgnoreWater = true

RunService.RenderStepped:Connect(function()
    pcall(function()
        local memesenseActive = getMemesenseActive()
        local enabled = memesenseActive and Toggles.BulletImpactV1Enabled.Value
        CubePart.Parent = enabled and Workspace or nil
        if enabled then
            local size = Options.BulletImpactV1Size.Value
            local maxDist = Options.BulletImpactV1Dist.Value
            CubePart.Size = Vector3.new(size, size, 0.01)
            local col = Options.BulletImpactV1Color.Value
            if Toggles.BulletImpactV1Rainbow.Value then
                col = Color3.fromHSV((tick()%5)/5, 1, 1)
            end
            impactRayParams.FilterDescendantsInstances = {LP.Character, CubePart}
            local origin = Camera.CFrame.Position
            local dir = Camera.CFrame.LookVector * maxDist
            local res = Workspace:Raycast(origin, dir, impactRayParams)
            if res then
                CubePart.Parent = Workspace
                CubePart.CFrame = CFrame.lookAt(res.Position + res.Normal*0.02, res.Position + res.Normal)
                if CubeSmartTarget and memesenseActive and Toggles.CubeAimbotEnabled.Value then
                    CubePart.Color = Color3.fromRGB(0,255,0)
                    selectionBox.Color3 = Color3.fromRGB(0,255,0)
                else
                    CubePart.Color = col
                    selectionBox.Color3 = col
                end
            else CubePart.Parent = nil end
        end
    end)
end)

-- =========================================================================
-- [ PENETRATION VISUALIZER ]
-- =========================================================================
task.spawn(function()
    local txt = Drawing.new("Text")
    txt.Visible=false; txt.Center=true; txt.Size=18; txt.Font=2
    txt.Color = Color3.fromRGB(0,255,0); txt.Outline = true
    local pp = RaycastParams.new()
    pp.FilterType = Enum.RaycastFilterType.Exclude
    pp.CollisionGroup = "Bullet"
    RunService.RenderStepped:Connect(function()
        local show = Toggles.ShowPenetration and Toggles.ShowPenetration.Value
        if show and Camera then
            txt.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2 - 70)
            local ignore = {LP.Character, Camera}
            pp.FilterDescendantsInstances = ignore
            local res = Workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector*1000, pp)
            if res then
                local stats = GetPenetrationStats(Camera.CFrame.Position, Camera.CFrame.LookVector, 4, {LP.Character, Camera}, nil)
                if stats.Success then
                    txt.Visible = true
                    txt.Text = string.format("WALLBANG: YES\n(%.1f studs)", stats.TotalThickness or 0)
                    txt.Color = Color3.fromRGB(0,255,0)
                else
                    txt.Visible = true
                    txt.Text = "WALLBANG: NO"
                    txt.Color = Color3.fromRGB(255,0,0)
                end
            else txt.Visible = false end
        else txt.Visible = false end
    end)
end)

-- =========================================================================
-- =========================================================================
--                            WEAPONS TAB
-- =========================================================================
-- =========================================================================
local WeaponModsBox = WeaponsMenu:AddSection({Position='left', Name="WEAPON MODS"})
local GrenadesBox = WeaponsMenu:AddSection({Position='right', Name="GRENADES"})
local WeaponMiscBox = WeaponsMenu:AddSection({Position='center', Name="WEAPON MISC"})

AddToggle(GrenadesBox, "Antiflashbang", {Text="No Flashbang", Default=false})
AddToggle(GrenadesBox, "Antismoke", {Text="No Smoke", Default=false})
AddToggle(WeaponModsBox, "Firerate", {Text="Firerate Changer", Default=false})
AddSlider(WeaponModsBox, "FirerateSlider", {Text="Firerate", Default=0.01, Min=0, Max=1, Rounding=3})
AddToggle(WeaponModsBox, "NoRecoil", {Text="No Recoil", Default=false})
AddToggle(WeaponModsBox, "NoSpread", {Text="No Spread", Default=false})
AddToggle(WeaponMiscBox, "InstantReload", {Text="Instant Reload", Default=false})

-- =========================================================================
-- [ GC HOOKS for weapon system ]
-- =========================================================================
local originalFireRate = {}
local firerateobjs = {}
local SendFunc = nil
local getCurrentEquipped = nil

pcall(function()
    for _, obj in next, getgc(true) do
        if type(obj) == "table" and rawget(obj, "FireRate") then
            pcall(function()
                table.insert(originalFireRate, table.clone(obj))
                table.insert(firerateobjs, obj)
            end)
        end
        if type(obj) == "table" and rawget(obj, "setWeaponRecoil") then
            pcall(function()
                local old
                old = hookfunction(obj.setWeaponRecoil, function(...)
                    if Toggles.NoRecoil.Value then return end
                    return old(...)
                end)
            end)
        end
        if type(obj) == "function" and debug.getinfo(obj).name == "calculateRecoilOffset" then
            pcall(function()
                local old
                old = hookfunction(obj, function(...)
                    if Toggles.NoRecoil.Value then return UDim2.new() end
                    return old(...)
                end)
            end)
        end
        if type(obj) == "table" and rawget(obj, "weaponKick") then
            pcall(function()
                local old
                old = hookfunction(obj.weaponKick, function(p1, p2)
                    if Toggles.NoRecoil.Value then return end
                    return old(p1, p2)
                end)
            end)
        end
        if type(obj) == "table" and rawget(obj, "getTrueSpread") then
            pcall(function()
                local old
                old = hookfunction(obj.getTrueSpread, function(p1)
                    if Toggles.NoSpread.Value then return 0 end
                    return old(p1)
                end)
            end)
        end
        if type(obj) == "function" and debug.getinfo(obj).name == "Flash" then
            pcall(function()
                local old
                old = hookfunction(obj, function(...)
                    if Toggles.Antiflashbang.Value then return end
                    return old(...)
                end)
            end)
        end
        if type(obj) == "function" and debug.getinfo(obj).name == "CreateVoxel"
            and debug.getupvalue(obj, 1) and tostring(debug.getupvalue(obj, 1)) == "Smoke" then
            pcall(function()
                local old
                old = hookfunction(obj, function(...)
                    if Toggles.Antismoke.Value then return end
                    return old(...)
                end)
            end)
        end
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
        if type(obj) == "table" and rawget(obj, "getCurrentEquipped") then
            pcall(function() getCurrentEquipped = obj.getCurrentEquipped end)
        end
    end
end)

local Weapon
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
-- [ TRACERS ]
-- =========================================================================
local function createTracerBean(startPos, endPos)
    if not (Toggles.BulletTracers and Toggles.BulletTracers.Value) then return end
    if not startPos or not endPos then return end
    local style = Options.TracerStyle.Value or "Block"
    local col = Options.BulletTracersColor.Value
    if Toggles.TracerRainbow.Value then
        col = Color3.fromHSV((tick()%5)/5, 1, 1)
    end
    local dur = Options.TracerTime.Value
    local part = Instance.new("Part")
    part.Name = "MS_Tracer"
    if style == "Cylinder (Obelius)" then
        part.Shape = Enum.PartType.Cylinder
        part.Size = Vector3.new((startPos-endPos).Magnitude, 0.12, 0.12)
        part.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0,0,-part.Size.X/2) * CFrame.Angles(0, math.rad(90), 0)
    else
        part.Size = Vector3.new(0.1, 0.1, (startPos-endPos).Magnitude)
        part.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0,0,-part.Size.Z/2)
    end
    part.Anchored=true; part.CanCollide=false; part.CanQuery=false; part.CanTouch=false
    part.Material = Enum.Material.Neon
    part.Color = col
    part.Transparency = 0
    part.CastShadow = false
    part.Parent = Workspace
    task.spawn(function()
        local st = tick()
        while tick() - st < dur do
            local a = (tick()-st)/dur
            part.Transparency = a
            if Toggles.TracerRainbow.Value then
                part.Color = Color3.fromHSV((tick()%5)/5, 1, 1)
            end
            task.wait()
        end
        part:Destroy()
    end)
end

local function createBulletImpact(hitPos)
    if not (Toggles.BulletImpacts and Toggles.BulletImpacts.Value) then return end
    if not hitPos then return end
    local p = Instance.new("Part")
    p.Name = "MS_Impact"
    p.Size = Vector3.new(0.6,0.6,0.6)
    p.Position = hitPos
    p.Anchored=true; p.CanCollide=false
    p.Material = Enum.Material.Neon
    p.Color = Options.BulletImpactsColor.Value
    p.Transparency = 0
    p.Parent = Workspace
    task.spawn(function()
        local st = tick()
        while tick()-st < 3 do
            p.Transparency = (tick()-st)/3
            task.wait()
        end
        p:Destroy()
    end)
end

-- =========================================================================
-- [ SHOOT HOOK ]
-- =========================================================================
pcall(function()
    if not SendFunc then return end
    local oldshoot = hookfunction(SendFunc, function(...)
        local args = {...}
        local memesenseActive = getMemesenseActive()
        if args[1] and type(args[1].Bullets) == "table" then
            for _, bullet in pairs(args[1].Bullets) do
                if type(bullet.Hits) == "table" then
                    for _, hitData in pairs(bullet.Hits) do
                        local targetPart = nil
                        if Toggles.Ragebot.Value and RageTarget then targetPart = RageTarget
                        elseif memesenseActive and Toggles.CubeAimbotEnabled.Value and CubeSmartTarget then
                            local chosen = Options.CubeHitPart.Value
                            targetPart = CubeSmartTarget.Parent and CubeSmartTarget.Parent:FindFirstChild(chosen) or CubeSmartTarget
                        elseif Toggles.SilentAim.Value and SilentTarget then targetPart = SilentTarget end
                        if targetPart then
                            hitData.Instance = targetPart
                            hitData.Position = targetPart.Position
                        end
                        pcall(function()
                            if Camera and hitData.Position then
                                local sp = Camera.CFrame.Position
                                local ep = hitData.Position
                                createTracerBean(sp, ep)
                                createBulletImpact(ep)
                                local isEnemyHit = false
                                if hitData.Instance then
                                    local anc = hitData.Instance:FindFirstAncestorOfClass("Model")
                                    if anc then
                                        local hp = Players:GetPlayerFromCharacter(anc)
                                        if hp and hp ~= LP and get_player_team(hp) ~= get_player_team(LP) then
                                            isEnemyHit = true
                                        end
                                    end
                                end
                                if isEnemyHit or targetPart then
                                    PlayHitSound()
                                    if TriggerHitMarkerEvent then
                                        pcall(function() TriggerHitMarkerEvent(ep) end)
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end
        return oldshoot(unpack(args))
    end)
end)

-- =========================================================================
-- [ RAGEBOT LOOP ]
-- =========================================================================
task.spawn(function()
    while true do
        task.wait(Options.RageDelay and Options.RageDelay.Value or 0.02)
        if Toggles.Ragebot.Value and RageTarget and Weapon and Weapon.IsEquipped and Weapon.Rounds > 0 then
            pcall(function() Weapon:shoot() end)
        end
    end
end)

-- =========================================================================
-- [ TRIGGERBOT ]
-- =========================================================================
task.spawn(function()
    local trp = RaycastParams.new()
    trp.FilterType = Enum.RaycastFilterType.Exclude
    trp.IgnoreWater = true
    while true do
        task.wait(Options.CubeTriggerbotDelay and Options.CubeTriggerbotDelay.Value or 0.01)
        pcall(function()
            local memesenseActive = getMemesenseActive()
            if memesenseActive and Toggles.CubeTriggerbot.Value then
                local should = false
                trp.FilterDescendantsInstances = {LP.Character}
                local res = Workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector*1000, trp)
                if res and res.Instance then
                    local char = res.Instance:FindFirstAncestorOfClass("Model")
                    if char then
                        local p = Players:GetPlayerFromCharacter(char)
                        if p and p ~= LP then
                            local _, on = Camera:WorldToViewportPoint(res.Instance.Position)
                            if on and not char:GetAttribute("Dead") and not char:GetAttribute("Invincible") then
                                if get_player_team(LP) ~= get_player_team(p) then should = true end
                            end
                        end
                    end
                end
                if not should and CubeSmartTarget and CubeSmartTarget.Parent then
                    local _, on = Camera:WorldToViewportPoint(CubeSmartTarget.Position)
                    if on then
                        local cl = Camera.CFrame.LookVector
                        local tt = (CubeSmartTarget.Position - Camera.CFrame.Position).Unit
                        if cl:Dot(tt) > 0.88 then
                            local char = CubeSmartTarget.Parent
                            if char and char:IsA("Model") then
                                local dead = char:GetAttribute("Dead") or char:GetAttribute("Invincible")
                                local hp = char:GetAttribute("Health")
                                if not dead and (hp == nil or hp > 0) and isEnemy(char) then should = true end
                            end
                        end
                    end
                end
                if should and Weapon then pcall(function() Weapon:shoot() end) end
            end
        end)
    end
end)

-- =========================================================================
-- [ FIRERATE LOOP ]
-- =========================================================================
task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if Toggles.Firerate.Value then
                for _, obj in next, firerateobjs do
                    pcall(function()
                        setreadonly(obj, false)
                        rawset(obj, "FireRate", math.max(Options.FirerateSlider.Value, 0.01))
                        setreadonly(obj, true)
                    end)
                end
            else
                for i, obj in next, firerateobjs do
                    pcall(function()
                        setreadonly(obj, false)
                        rawset(obj, "FireRate", originalFireRate[i].FireRate)
                        setreadonly(obj, true)
                    end)
                end
            end
        end)
    end
end)

-- =========================================================================
-- [ INSTANT RELOAD ]
-- =========================================================================
task.spawn(function()
    local RELOAD_ANIMS = {Reload=true, ReloadStart=true, ReloadAction=true, ReloadEnd=true}
    local RELOAD_SPEED = 199
    local hooked = {}
    local function hookAnim(anim)
        if not anim or hooked[anim] then return end
        hooked[anim] = true
        pcall(function()
            local op = anim.play
            anim.play = function(self, name, ...)
                local track = op(self, name, ...)
                if track and RELOAD_ANIMS[name] then
                    task.defer(function()
                        pcall(function()
                            if Toggles.InstantReload and Toggles.InstantReload.Value and track.IsPlaying then
                                track:AdjustSpeed(RELOAD_SPEED)
                            end
                        end)
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
            if not (Toggles.InstantReload and Toggles.InstantReload.Value) then return end
            if w.IsReloading then
                pcall(function()
                    if w.Viewmodel and w.Viewmodel.Animation and w.Viewmodel.Animation.Animations then
                        for name, track in pairs(w.Viewmodel.Animation.Animations) do
                            if RELOAD_ANIMS[name] and track.IsPlaying then track:AdjustSpeed(RELOAD_SPEED) end
                        end
                    end
                    if w.CharacterAnimator and w.CharacterAnimator.Animations then
                        for name, track in pairs(w.CharacterAnimator.Animations) do
                            if RELOAD_ANIMS[name] and track.IsPlaying then track:AdjustSpeed(RELOAD_SPEED) end
                        end
                    end
                end)
            end
        end)
    end
end)

-- =========================================================================
-- [ GRENADE ZONE ESP (Circle Edition) ]
-- =========================================================================
local ActiveZones = {}
local function MakeCylinder(col, thick)
    local p = Instance.new("Part")
    p.Name = "MS_RingSeg"
    p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CastShadow=false
    p.Material = Enum.Material.Neon
    p.Color = col
    p.Transparency = 1
    p.Shape = Enum.PartType.Cylinder
    p.Size = Vector3.new(thick, thick, thick)
    p.Parent = Workspace
    return p
end

local ZRayParams = RaycastParams.new()
ZRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function GetGroundY(x, baseY, z, exclude)
    ZRayParams.FilterDescendantsInstances = exclude or {}
    local res = Workspace:Raycast(Vector3.new(x, baseY+5, z), Vector3.new(0,-14,0), ZRayParams)
    return res and res.Position.Y or baseY
end

local function ComputeZoneBounds(parent)
    local sumX,sumZ,minY,count = 0,0,math.huge,0
    local parts = {}
    for _, v in ipairs(parent:GetChildren()) do
        if v:IsA("BasePart") then
            count = count + 1
            sumX = sumX + v.Position.X
            sumZ = sumZ + v.Position.Z
            local b = v.Position.Y - v.Size.Y*0.5
            if b < minY then minY = b end
            table.insert(parts, v)
        end
    end
    if count == 0 then return nil,nil,false end
    local cx, cz = sumX/count, sumZ/count
    local maxR = 0
    for _, p in ipairs(parts) do
        local dx, dz = p.Position.X-cx, p.Position.Z-cz
        local ext = math.max(p.Size.X, p.Size.Z)*0.5
        local r = math.sqrt(dx*dx+dz*dz) + ext
        if r > maxR then maxR = r end
    end
    return Vector3.new(cx,minY,cz), math.max(maxR,1.2), true
end

local SETTINGS = {
    Smoke = {RadiusTrim=0, HeightOffset=0.3, Segments=40, Thickness=0.28},
    Molotov = {RadiusTrim=4.5, HeightOffset=0.3, Segments=40, Thickness=0.28},
}
local FADE_IN_TIME, FADE_OUT_TIME, RECALC_INTERVAL = 0.4, 0.6, 0.05

local function CreateZoneRing(parent, cfg, isMolotov)
    if ActiveZones[parent] then return end
    local segs = cfg.Segments
    local thick = cfg.Thickness
    local initCol = isMolotov and Options.GrenadeZoneColor.Value or Options.SmokeZoneColor.Value
    local cys = {}
    for i=1,segs do
        cys[i] = MakeCylinder(initCol, thick)
    end
    local record = {
        cylinders=cys, cfg=cfg, isMolotov=isMolotov,
        lastRecalc=0, lastRadius=1, alive=true, fadingOut=false, fadeAlpha=0,
    }
    ActiveZones[parent] = record
    local fadeInStart = tick()
    local function CurrentAlpha()
        if record.fadingOut then return record.fadeAlpha end
        return math.clamp((tick()-fadeInStart)/FADE_IN_TIME, 0, 1)
    end
    local function FadeOut()
        if record.fadingOut then return end
        record.fadingOut = true
        record.fadeAlpha = CurrentAlpha()
        local st, sa = tick(), record.fadeAlpha
        local conn
        conn = RunService.Heartbeat:Connect(function()
            local t = math.clamp((tick()-st)/FADE_OUT_TIME, 0, 1)
            record.fadeAlpha = sa * (1-t)
            local transp = 1 - record.fadeAlpha
            for _, cy in ipairs(cys) do pcall(function() cy.Transparency = transp end) end
            if t >= 1 then
                conn:Disconnect()
                record.alive = false
                for _, cy in ipairs(cys) do pcall(function() cy:Destroy() end) end
                ActiveZones[parent] = nil
            end
        end)
    end
    parent.AncestryChanged:Connect(function(_, p) if p == nil then FadeOut() end end)
    local updateConn
    updateConn = RunService.Heartbeat:Connect(function()
        if not record.alive then updateConn:Disconnect() return end
        if not parent or not parent.Parent then updateConn:Disconnect(); FadeOut(); return end
        local now = tick()
        if now - record.lastRecalc < RECALC_INTERVAL then return end
        record.lastRecalc = now
        local center, radius, found = ComputeZoneBounds(parent)
        if not found then return end
        local trim = cfg.RadiusTrim
        local smoothed = record.lastRadius + (radius - record.lastRadius)*0.25
        record.lastRadius = smoothed
        local finalR = math.max(smoothed - trim, 0.8)
        local alpha = CurrentAlpha()
        local transp = 1 - alpha
        local col = record.isMolotov and Options.GrenadeZoneColor.Value or Options.SmokeZoneColor.Value
        for i, cy in ipairs(cys) do
            local angleA = (math.pi*2)*((i-1)/segs)
            local angleB = (math.pi*2)*(i/segs)
            local angleMid = (angleA+angleB)/2
            local xA, zA = center.X + math.cos(angleA)*finalR, center.Z + math.sin(angleA)*finalR
            local xB, zB = center.X + math.cos(angleB)*finalR, center.Z + math.sin(angleB)*finalR
            local xM, zM = center.X + math.cos(angleMid)*finalR, center.Z + math.sin(angleMid)*finalR
            local yA = GetGroundY(xA, center.Y, zA, cys) + cfg.HeightOffset
            local yB = GetGroundY(xB, center.Y, zB, cys) + cfg.HeightOffset
            local yM = (yA+yB)*0.5
            local posA, posB = Vector3.new(xA,yA,zA), Vector3.new(xB,yB,zB)
            local mid = Vector3.new(xM, yM, zM)
            local dir = posB - posA
            local len = dir.Magnitude
            if len < 0.001 then continue end
            cy.CFrame = CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.rad(90), 0)
            cy.Size = Vector3.new(len, thick, thick)
            cy.Color = col
            cy.Transparency = transp
        end
    end)
end

local ScannedZones = {}
local function IsToggleOn(name)
    if Toggles and Toggles[name] then return Toggles[name].Value end
    return false
end

local function TryHandleZone(obj)
    if not obj or not obj.Parent then return end
    if ScannedZones[obj] then return end
    local nm = obj.Name:lower()
    local isMolotov = (nm:find("firezone") or nm:find("fire_zone") or nm:find("molotov")
        or nm:find("voxelfire") or nm:find("ignite") or nm:find("flamezone")
        or nm:find("firearea") or nm:find("burnzone"))
    local isSmoke = (nm:find("smokezone") or nm:find("smoke_zone") or nm:find("voxelsmoke")
        or nm:find("smokearea") or nm:find("gaszone"))
    if isMolotov and IsToggleOn("MolotovZoneESP") then
        ScannedZones[obj] = true
        CreateZoneRing(obj, SETTINGS.Molotov, true)
    elseif isSmoke and IsToggleOn("SmokeZoneESP") then
        ScannedZones[obj] = true
        CreateZoneRing(obj, SETTINGS.Smoke, false)
    end
end

task.spawn(function()
    task.wait(1)
    local function scanFolder(folder)
        if not folder then return end
        for _, c in ipairs(folder:GetChildren()) do
            TryHandleZone(c)
            for _, sub in ipairs(c:GetChildren()) do TryHandleZone(sub) end
        end
        folder.ChildAdded:Connect(function(child)
            task.wait()
            TryHandleZone(child)
            child.ChildAdded:Connect(function(sub) task.wait(); TryHandleZone(sub) end)
        end)
    end
    scanFolder(Workspace)
    while task.wait(3) do
        for _, c in ipairs(Workspace:GetChildren()) do
            TryHandleZone(c)
            for _, sub in ipairs(c:GetChildren()) do TryHandleZone(sub) end
        end
    end
end)

-- =========================================================================
-- [ GRENADE FLIGHT TRACER ]
-- =========================================================================
local TrackedGrenades = {}
local GRENADE_PATTERNS = {"grenade","flash","molotov","bang","frag","he_","_he","throwable","projectile","nade","incendiary","decoy","c4"}
local GRENADE_BLACKLIST = {"gun","rifle","pistol","bullet","casing","debris","light","muzzle","launch","effect","arm","leg","torso","head","humanoid","mesh","handle","constraint","weld","motor","zone","voxel"}

local function isGrenadeObject(obj)
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    local nm = obj.Name:lower()
    for _, p in ipairs(GRENADE_BLACKLIST) do if nm:find(p) then return false end end
    if #nm > 20 and nm:find("%-") then return true end
    for _, p in ipairs(GRENADE_PATTERNS) do if nm:find(p) then return true end end
    return false
end

local function StartGrenadeTracer(part)
    if not part or not part:IsA("BasePart") then return end
    if TrackedGrenades[part] then return end
    TrackedGrenades[part] = true
    local MAX_TRAIL = 30
    local history, lines = {}, {}
    for i=1,MAX_TRAIL do
        local l = Drawing.new("Line")
        l.Visible=false; l.Thickness=2; l.Transparency=1
        lines[i] = l
    end
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not (Toggles.GrenadeTracers and Toggles.GrenadeTracers.Value) then
            for _,l in ipairs(lines) do l.Visible = false end
            return
        end
        if not part or not part.Parent then
            conn:Disconnect()
            TrackedGrenades[part] = nil
            for _,l in ipairs(lines) do pcall(function() l:Remove() end) end
            return
        end
        local col = Options.GrenadeTracerColor.Value
        table.insert(history, 1, part.Position)
        if #history > MAX_TRAIL + 1 then table.remove(history) end
        for i=1,MAX_TRAIL do
            local l = lines[i]
            local p1, p2 = history[i], history[i+1]
            if not p1 or not p2 then l.Visible = false; continue end
            local s1, o1 = Camera:WorldToViewportPoint(p1)
            local s2, o2 = Camera:WorldToViewportPoint(p2)
            if (o1 or o2) and s1.Z > 0 and s2.Z > 0 then
                local fade = 1 - (i/MAX_TRAIL)
                l.From = Vector2.new(s1.X, s1.Y)
                l.To = Vector2.new(s2.X, s2.Y)
                l.Color = col
                l.Thickness = math.max(2*fade, 0.5)
                l.Transparency = 1-fade
                l.Visible = true
            else l.Visible = false end
        end
    end)
end

local function TryTrackGrenade(obj)
    if TrackedGrenades[obj] then return end
    local part = obj
    if obj:IsA("Model") then
        part = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
    end
    if not part or not part:IsA("BasePart") then return end
    if part.Size.Magnitude > 8 then return end
    if Players:GetPlayerFromCharacter(obj) then return end
    if Players:GetPlayerFromCharacter(obj.Parent) then return end
    TrackedGrenades[obj] = true
    obj.AncestryChanged:Connect(function(_, p) if p == nil then TrackedGrenades[obj] = nil end end)
    StartGrenadeTracer(part)
end

task.spawn(function()
    task.wait(0.5)
    local function scan(folder)
        if not folder then return end
        for _, c in ipairs(folder:GetChildren()) do
            if isGrenadeObject(c) then TryTrackGrenade(c) end
        end
    end
    scan(Workspace)
    Workspace.ChildAdded:Connect(function(c)
        task.wait()
        if isGrenadeObject(c) then TryTrackGrenade(c) end
        c.ChildAdded:Connect(function(sub) task.wait(); if isGrenadeObject(sub) then TryTrackGrenade(sub) end end)
    end)
end)

-- =========================================================================
-- [ CHAMS ]
-- =========================================================================
task.spawn(function()
    local ESPFolder
    pcall(function()
        ESPFolder = Instance.new("Folder", CoreGui)
        ESPFolder.Name = "MS_Chams_Container"
    end)
    local Highlights = {}
    local function getMat(s)
        if s == "Metal" then return Enum.Material.Metal
        elseif s == "ForceField" then return Enum.Material.ForceField
        elseif s == "SmoothPlastic" then return Enum.Material.SmoothPlastic
        else return Enum.Material.Neon end
    end
    local function removeChams(char)
        if Highlights[char] then
            pcall(function() Highlights[char].visible:Destroy() end)
            pcall(function() Highlights[char].unvisible:Destroy() end)
            Highlights[char] = nil
        end
    end
    local RayP = RaycastParams.new()
    RayP.FilterType = Enum.RaycastFilterType.Exclude
    local function isVis(char)
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if not root then return false end
        local camPos = Workspace.CurrentCamera.CFrame.Position
        local dir = root.Position - camPos
        RayP.FilterDescendantsInstances = {LP.Character, char}
        local res = Workspace:Raycast(camPos, dir, RayP)
        return res == nil
    end
    RunService.RenderStepped:Connect(function()
        local enabled = Toggles.ChamsEnabled.Value
        local teamCheckOn = Toggles.ChamsTeamCheck.Value
        local matV = getMat(Options.ChamsMaterialVisible.Value)
        local matU = getMat(Options.ChamsMaterialUnvisible.Value)
        local colV = Options.ChamsColorVisible.Value
        local colU = Options.ChamsColorUnvisible.Value
        local fAV = Options.ChamsAlphaVisible.Value
        local fAU = Options.ChamsAlphaUnvisible.Value
        local oAV = Options.ChamsOutlineAlphaVisible.Value
        local oAU = Options.ChamsOutlineAlphaUnvisible.Value
        local cf = Workspace:FindFirstChild("Characters")
        if not cf then return end
        local enemies = {}
        for _, obj in ipairs(cf:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LP.Character then
                if teamCheckOn and isCharacterAlly(obj) then
                    removeChams(obj)
                    continue
                end
                if not enabled then removeChams(obj); continue end
                table.insert(enemies, obj)
            end
        end
        for _, char in ipairs(enemies) do
            if not Highlights[char] then
                local hv = Instance.new("Highlight")
                hv.DepthMode = Enum.HighlightDepthMode.Occluded
                hv.Parent = ESPFolder
                local hu = Instance.new("Highlight")
                hu.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hu.Parent = ESPFolder
                Highlights[char] = {visible=hv, unvisible=hu}
                char.AncestryChanged:Connect(function(_, p) if p == nil then removeChams(char) end end)
            end
            local hl = Highlights[char]
            local seen = isVis(char)
            hl.visible.Adornee = char
            hl.visible.FillColor = colV
            hl.visible.OutlineColor = colV
            hl.visible.FillTransparency = fAV
            hl.visible.OutlineTransparency = oAV
            hl.visible.Enabled = seen
            hl.unvisible.Adornee = char
            hl.unvisible.FillColor = colU
            hl.unvisible.OutlineColor = colU
            hl.unvisible.FillTransparency = fAU
            hl.unvisible.OutlineTransparency = oAU
            hl.unvisible.Enabled = not seen
            local targetMat = seen and matV or matU
            local targetCol = seen and colV or colU
            for _, part in ipairs(char:GetDescendants()) do
                pcall(function()
                    if part:IsA("SurfaceAppearance") or part:IsA("Decal") or part:IsA("Texture") then
                        part:Destroy()
                    elseif part:IsA("MeshPart") and part.TextureID ~= "" then part.TextureID = ""
                    elseif part:IsA("SpecialMesh") and part.TextureId ~= "" then part.TextureId = "" end
                    if part:IsA("BasePart") then
                        if not part:GetAttribute("OrigMat") then
                            part:SetAttribute("OrigMat", part.Material.Name)
                            part:SetAttribute("OrigColor", part.Color)
                        end
                        part.Material = targetMat
                        part.Color = targetCol
                    end
                end)
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if p.Character then removeChams(p.Character) end
    end)
end)

-- =========================================================================
-- [ SKIN CHANGER ]
-- =========================================================================
local RS = ReplicatedStorage
local G = {knifeChangerSupported = true}
pcall(function()
    local ex = (identifyexecutor and identifyexecutor()) or "Unknown"
    if ex:find("RonixExploit", 1, true) or ex:find("Xeno", 1, true) or ex:find("Solara", 1, true) then
        G.knifeChangerSupported = false
    end
end)
local SD = {SkinsRoot=nil, SkinSelections={}, GloveSelections={}, GloveFolders={}}
pcall(function()
    SD.SkinsRoot = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Skins")
end)
if SD.SkinsRoot then
    pcall(function()
        for _, wf in ipairs(SD.SkinsRoot:GetChildren()) do
            local skins = {}
            for _, sf in ipairs(wf:GetChildren()) do skins[#skins+1] = sf.Name end
            table.sort(skins)
            SD.SkinSelections[wf.Name] = skins
        end
        for _, folder in ipairs(SD.SkinsRoot:GetChildren()) do
            if (folder.Name:match("Glove") or folder.Name:match("Gloves") or folder.Name == "Hand Wraps")
                and not (folder.Name:match("T Glove") or folder.Name:match("CT Glove")) then
                SD.GloveFolders[#SD.GloveFolders+1] = folder
            end
        end
    end)
end
for _, gf in ipairs(SD.GloveFolders) do
    local skins = {"Default"}
    for _, skin in ipairs(gf:GetChildren()) do skins[#skins+1] = skin.Name end
    SD.GloveSelections[gf.Name] = skins
end

local SkinCfg = {
    SkinChanger = {Enabled=false, Skins={}},
    KnifeChanger = {Enabled=false, Model="Skeleton Knife"},
    GloveChanger = {Enabled=false, Gloves={}, Model="Sports Gloves", Skin="Default"},
}
for w, s in pairs(SD.SkinSelections) do SkinCfg.SkinChanger.Skins[w] = s[1] or "Default" end
for _, gf in ipairs(SD.GloveFolders) do SkinCfg.GloveChanger.Gloves[gf.Name] = "Default" end

local baseKnives = {"CT Knife","T Knife","Knife"}
local function Checkknife(w)
    if not w then return false end
    for _, k in ipairs(baseKnives) do if w == k then return true end end
    return false
end

local SkinsBox = SkinMenu:AddSection({Position='left', Name="WEAPON SKINS"})
local GlovesBox = SkinMenu:AddSection({Position='center', Name="GLOVES"})
local KnifeBox  = SkinMenu:AddSection({Position='right', Name="KNIFE"})

AddToggle(SkinsBox, "EnableSkins", {Text="Enable Weapon Skins", Default=false,
    Callback=function(v) SkinCfg.SkinChanger.Enabled = v end})

local KM = {"Karambit","Butterfly Knife","Flip Knife","Gut Knife","M9 Bayonet","Skeleton Knife","Stiletto Knife"}
local EW = {"Driver Gloves","Sports Gloves","Operator Gloves","Hand Wraps"}

AddToggle(KnifeBox, "KnifeChangerToggle", {Text="Enable Knife Changer", Default=false,
    Callback=function(v) SkinCfg.KnifeChanger.Enabled = v end})
AddDropdown(KnifeBox, "KnifeModel", {Text="Knife Model", Values=KM, Default="Skeleton Knife",
    Callback=function(v) SkinCfg.KnifeChanger.Model = v end})
for _, kn in ipairs(KM) do
    local ks = SD.SkinSelections[kn]
    if ks then
        AddDropdown(KnifeBox, "KnifeSkin_"..kn, {Text=kn.." Skin", Values=ks, Default=ks[1] or "Default",
            Callback=function(v) SkinCfg.SkinChanger.Skins[kn] = v end})
    end
end

AddToggle(GlovesBox, "GloveChangerToggle", {Text="Enable Gloves", Default=false,
    Callback=function(v) SkinCfg.GloveChanger.Enabled = v end})
local GM = {}
for k in pairs(SD.GloveSelections) do GM[#GM+1] = k end
table.sort(GM)
AddDropdown(GlovesBox, "GloveModel", {Text="Glove Model", Values=(#GM>0 and GM or {"Sports Gloves"}),
    Default=GM[1] or "Sports Gloves",
    Callback=function(v) SkinCfg.GloveChanger.Model = v end})
for _, gFolder in ipairs(SD.GloveFolders) do
    local gName = gFolder.Name
    local gSkins = SD.GloveSelections[gName]
    if gSkins then
        AddDropdown(GlovesBox, "GloveSkin_"..gName, {Text=gName.." Skin", Values=gSkins,
            Default=gSkins[1] or "Default",
            Callback=function(v) SkinCfg.GloveChanger.Gloves[gName] = v end})
    end
end
for w, s in pairs(SD.SkinSelections) do
    if not table.find(KM, w) and not table.find(GM, w) and not table.find(EW, w) then
        AddDropdown(SkinsBox, "Skin_"..w, {Text=w, Values=s, Default=s[1] or "Default",
            Callback=function(v) SkinCfg.SkinChanger.Skins[w] = v end})
    end
end

-- Skin apply logic (hooking Skins library)
task.spawn(function()
    pcall(function()
        if not G.knifeChangerSupported then return end
        local SM = RS:FindFirstChild("Database") and RS.Database:FindFirstChild("Components")
            and RS.Database.Components:FindFirstChild("Libraries")
            and RS.Database.Components.Libraries:FindFirstChild("Skins")
        local VM = RS:FindFirstChild("Classes") and RS.Classes:FindFirstChild("WeaponComponent")
            and RS.Classes.WeaponComponent:FindFirstChild("Classes")
            and RS.Classes.WeaponComponent.Classes:FindFirstChild("Viewmodel")
        if not SM or not VM then return end
        local Sk = require(SM)
        local Vm = require(VM)
        local oGCM = Sk.GetCameraModel
        Sk.GetCameraModel = function(w, sk, ...)
            if SkinCfg.KnifeChanger.Enabled and w and Checkknife(w) then
                local nk = SkinCfg.KnifeChanger.Model
                local ns = SkinCfg.SkinChanger.Skins[nk] or "Vanilla"
                local s, r = pcall(oGCM, nk, ns, ...)
                if s and r then return r end
            end
            return oGCM(w, sk, ...)
        end
        local oGChM = Sk.GetCharacterModel
        Sk.GetCharacterModel = function(w, sk, ...)
            if SkinCfg.KnifeChanger.Enabled and w and Checkknife(w) then
                local nk = SkinCfg.KnifeChanger.Model
                local ns = SkinCfg.SkinChanger.Skins[nk] or "Vanilla"
                local s, r = pcall(oGChM, nk, ns, ...)
                if s and r then return r end
            end
            return oGChM(w, sk, ...)
        end
        local oVN = Vm.new
        Vm.new = function(vc, w, sk, ...)
            if SkinCfg.KnifeChanger.Enabled and w and Checkknife(w) then
                local nk = SkinCfg.KnifeChanger.Model
                local ns = SkinCfg.SkinChanger.Skins[nk] or "Vanilla"
                local s, r = pcall(oVN, vc, nk, ns, ...)
                if s and r then return r end
            end
            return oVN(vc, w, sk, ...)
        end
        if Sk.GetGloves then
            local oGG = Sk.GetGloves
            Sk.GetGloves = function(g, sk)
                if SkinCfg.GloveChanger.Enabled and SkinCfg.GloveChanger.Model then
                    local gm = SkinCfg.GloveChanger.Model
                    local ts = SkinCfg.GloveChanger.Gloves[gm] or "Default"
                    local s, r = pcall(oGG, gm, ts)
                    if s and r then return r end
                end
                return oGG(g, sk)
            end
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if SkinCfg.SkinChanger.Enabled or SkinCfg.KnifeChanger.Enabled or SkinCfg.GloveChanger.Enabled then
                -- Skin application happens via library hooks
            end
        end)
    end
end)

-- =========================================================================
-- [ INIT FINAL ]
-- =========================================================================
Notification:Notify({Title="MEMESENSE", Content="Loaded. Keybind: RightShift", Icon="clipboard"})
print("[MEMESENSE PORT] Fatality UI build loaded.")
