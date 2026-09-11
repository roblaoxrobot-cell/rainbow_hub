-- RAINBOW HUB | BloxStrike | Fatality UI
local CoreGui=game:GetService("CoreGui")
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local HS=game:GetService("HttpService")
local LP=Players.LocalPlayer
local Camera=Workspace.CurrentCamera

local function GetFatality()
    local ok,F=pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))() end)
    if not ok or not F then warn("[RH] Fatality load failed") return nil end
    return F
end

local function keyMatches(input,key)
    if key==nil then return false end
    if typeof(key)=="EnumItem" then return input.KeyCode==key end
    return input.KeyCode.Name==tostring(key)
end

-- MATERIAL PENETRATION
local MaterialLimits={}
MaterialLimits[Enum.Material.Asphalt]=0.25
MaterialLimits[Enum.Material.Basalt]=0.25
MaterialLimits[Enum.Material.Brick]=0.25
MaterialLimits[Enum.Material.Cobblestone]=0.25
MaterialLimits[Enum.Material.Concrete]=0.25
MaterialLimits[Enum.Material.CrackedLava]=0.25
MaterialLimits[Enum.Material.DiamondPlate]=0.25
MaterialLimits[Enum.Material.Foil]=0.25
MaterialLimits[Enum.Material.Glacier]=0.25
MaterialLimits[Enum.Material.Granite]=0.25
MaterialLimits[Enum.Material.Grass]=0.25
MaterialLimits[Enum.Material.Ground]=0.25
MaterialLimits[Enum.Material.Ice]=0.25
MaterialLimits[Enum.Material.LeafyGrass]=0.25
MaterialLimits[Enum.Material.Limestone]=0.25
MaterialLimits[Enum.Material.Marble]=0.25
MaterialLimits[Enum.Material.Metal]=0.25
MaterialLimits[Enum.Material.Mud]=0.25
MaterialLimits[Enum.Material.Pavement]=0.25
MaterialLimits[Enum.Material.Rock]=0.25
MaterialLimits[Enum.Material.Salt]=0.25
MaterialLimits[Enum.Material.Sand]=0.25
MaterialLimits[Enum.Material.Sandstone]=0.25
MaterialLimits[Enum.Material.Slate]=0.25
MaterialLimits[Enum.Material.Snow]=0.25
MaterialLimits[Enum.Material.ForceField]=0.25
MaterialLimits[Enum.Material.Neon]=0.25
MaterialLimits[Enum.Material.CorrodedMetal]=0.25
MaterialLimits[Enum.Material.Pebble]=0.25
MaterialLimits[Enum.Material.CeramicTiles]=0.25
MaterialLimits[Enum.Material.Plaster]=0.25
MaterialLimits[Enum.Material.Plastic]=7
MaterialLimits[Enum.Material.SmoothPlastic]=7
MaterialLimits[Enum.Material.Wood]=7
MaterialLimits[Enum.Material.WoodPlanks]=7
MaterialLimits[Enum.Material.Cardboard]=7
MaterialLimits[Enum.Material.Glass]=100
MaterialLimits[Enum.Material.Fabric]=100
local MaterialVariantLimits={}
MaterialVariantLimits["IndoorWall"]=0.25
MaterialVariantLimits["Sandy Brick"]=0.25

local function GetPenetrationStats(origin,direction,maxPen,ignoreList,targetRoot)
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.CollisionGroup="Bullet"
    local filter=ignoreList or {LP.Character,Camera}
    params.FilterDescendantsInstances=filter
    local currentOrigin=origin
    local currentDir=direction
    local accMat={}
    local accVar={}
    local stats={TotalThickness=0,Success=false}
    local backParams=RaycastParams.new()
    backParams.FilterType=Enum.RaycastFilterType.Include
    backParams.CollisionGroup="Bullet"
    for _=1,100 do
        if not currentOrigin or not currentDir then break end
        local result=Workspace:Raycast(currentOrigin,currentDir*1000,params)
        if not result then
            if not targetRoot then stats.Success=true end
            break
        end
        if targetRoot and result.Instance:IsDescendantOf(targetRoot) then
            stats.Success=true
            return stats
        end
        table.insert(filter,result.Instance)
        params.FilterDescendantsInstances=filter
        local enterPos=result.Position
        local fakeEnd=enterPos+(currentDir*1000)
        backParams.FilterDescendantsInstances={result.Instance}
        local backRes=Workspace:Raycast(fakeEnd,enterPos-fakeEnd,backParams)
        local thickness=0.5
        if not backRes then
            thickness=5
        else
            thickness=(enterPos-backRes.Position).Magnitude
            local variant=backRes.Instance.MaterialVariant
            if variant~="" and MaterialVariantLimits[variant] then
                accVar[variant]=(accVar[variant] or 0)+thickness
                if accVar[variant]>MaterialVariantLimits[variant]+maxPen then return stats end
            else
                local mat=backRes.Material
                accMat[mat]=(accMat[mat] or 0)+thickness
                local lim=MaterialLimits[mat] or 0.25
                if accMat[mat]>lim+maxPen then return stats end
            end
            currentOrigin=backRes.Position
        end
        stats.TotalThickness=stats.TotalThickness+thickness
    end
    return stats
end

local function GetMoveDir()
    local d=Vector3.zero
    local lv=Camera.CFrame.LookVector
    local rv=Camera.CFrame.RightVector
    if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+lv end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-lv end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-rv end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+rv end
    local f=Vector3.new(d.X,0,d.Z)
    if f.Magnitude>0 then return f.Unit end
    return f
end

local function getTeam(p)
    if not p then return nil end
    if p.Team then return p.Team.Name end
    return nil
end

local function hasVest(c)
    if not c then return false end
    local a=c:FindFirstChild("CharacterArmor")
    if not a then return false end
    if a:FindFirstChild("VestDetails") then return true end
    return false
end

local function isAlly(c)
    if not LP.Character then return false end
    local a=hasVest(LP.Character)
    local b=hasVest(c)
    if not a then return not b end
    return b
end

local function isEnemy(c)
    if not c then return false end
    if not LP.Character then return false end
    local a=hasVest(LP.Character)
    local b=hasVest(c)
    if a then return not b end
    return b
end

local function lerpC(a,b,t)
    return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t)
end

-- MIRROR
local Toggles={}
local Options={}

local function mirrorToggle(name,def)
    local t={Value=def or false,_cb={}}
    t.SetValue=function(self,v)
        self.Value=v
        for _,cb in ipairs(self._cb) do pcall(cb,v) end
    end
    t.OnChanged=function(self,cb) table.insert(self._cb,cb) end
    Toggles[name]=t
    return t
end

local function mirrorOption(name,def)
    local o={Value=def,_cb={}}
    o.SetValue=function(self,v)
        self.Value=v
        for _,cb in ipairs(self._cb) do pcall(cb,v) end
    end
    o.OnChanged=function(self,cb) table.insert(self._cb,cb) end
    o.GetState=function(self) return self.Value end
    o.SetValues=function(self) end
    Options[name]=o
    return o
end

-- WINDOW
local F=GetFatality()
if not F then return end
if getgenv().RH_Loaded then warn("[RH] already loaded") return end
getgenv().RH_Loaded=true
local Notification=F:CreateNotifier()
F:Loader({Name="Rainbow Hub",Duration=3})
Notification:Notify({Title="RAINBOW HUB",Content="Welcome, "..LP.DisplayName,Icon="clipboard"})

local Window=F.new({Name="Rainbow Hub",Expire="BloxStrike",Keybind="NONE"})
local Config=Window:AddConfig()
Config:Init("Hub_BloxStrike","HubConfigs")

local MenuVisible=true
getgenv().RH_MenuKey=Enum.KeyCode.Insert
UIS.InputBegan:Connect(function(input,gp)
    if gp then return end
    if keyMatches(input,getgenv().RH_MenuKey) then
        MenuVisible=not MenuVisible
        pcall(function() Window:SetVisible(MenuVisible) end)
    end
end)

local CombatMenu=Window:AddMenu({Name="Combat",Icon="skull"})
local VisualsMenu=Window:AddMenu({Name="Visuals",Icon="eye"})
local WorldMenu=Window:AddMenu({Name="World",Icon="settings"})
local WeaponsMenu=Window:AddMenu({Name="Weapons",Icon="crosshair"})
local MiscMenu=Window:AddMenu({Name="Misc",Icon="cog"})
local SkinMenu=Window:AddMenu({Name="Skins",Icon="shield"})
local SetMenu=Window:AddMenu({Name="Settings",Icon="cog"})

local function AddToggle(section,name,opts)
    opts=opts or {}
    local m=mirrorToggle(name,opts.Default or false)
    section:AddToggle({
        Name=opts.Text or name,
        Flag="RHT_"..name,
        Default=opts.Default or false,
        Callback=function(v)
            m.Value=v
            for _,cb in ipairs(m._cb) do pcall(cb,v) end
            if opts.Callback then pcall(opts.Callback,v) end
        end
    })
    return m
end

local function AddSlider(section,name,opts)
    opts=opts or {}
    local m=mirrorOption(name,opts.Default or 0)
    section:AddSlider({
        Name=opts.Text or name,
        Flag="RHS_"..name,
        Default=opts.Default or 0,
        Min=opts.Min or 0,
        Max=opts.Max or 100,
        Round=opts.Rounding or 0,
        Callback=function(v)
            m.Value=v
            for _,cb in ipairs(m._cb) do pcall(cb,v) end
            if opts.Callback then pcall(opts.Callback,v) end
        end
    })
    return m
end

local function AddDropdown(section,name,opts)
    opts=opts or {}
    local m=mirrorOption(name,opts.Default or (opts.Values and opts.Values[1]) or "")
    section:AddDropdown({
        Name=opts.Text or name,
        Flag="RHD_"..name,
        Values=opts.Values or {},
        Default=opts.Default,
        Callback=function(v)
            m.Value=v
            for _,cb in ipairs(m._cb) do pcall(cb,v) end
            if opts.Callback then pcall(opts.Callback,v) end
        end
    })
    return m
end

local function AddKeybind(section,name,opts)
    opts=opts or {}
    local m=mirrorOption(name,opts.Default or Enum.KeyCode.Unknown)
    section:AddKeybind({
        Name=opts.Text or name,
        Flag="RHK_"..name,
        Default=opts.Default or Enum.KeyCode.Unknown,
        Callback=function(v)
            m.Value=v
            for _,cb in ipairs(m._cb) do pcall(cb,v) end
            if opts.Callback then pcall(opts.Callback,v) end
        end
    })
    return m
end

local function AddColor(section,name,opts)
    opts=opts or {}
    local m=mirrorOption(name,opts.Default or Color3.new(1,1,1))
    section:AddColorPicker({
        Name=opts.Title or opts.Text or name,
        Flag="RHC_"..name,
        Default=opts.Default or Color3.new(1,1,1),
        Callback=function(v)
            m.Value=v
            for _,cb in ipairs(m._cb) do pcall(cb,v) end
            if opts.Callback then pcall(opts.Callback,v) end
        end
    })
    return m
end

local function AddInput(section,name,opts)
    opts=opts or {}
    local m=mirrorOption(name,opts.Default or "")
    section:AddInput({
        Name=opts.Text or name,
        Flag="RHI_"..name,
        Default=opts.Default or "",
        Placeholder=opts.Placeholder or "",
        Callback=function(v)
            m.Value=v
            for _,cb in ipairs(m._cb) do pcall(cb,v) end
            if opts.Callback then pcall(opts.Callback,v) end
        end
    })
    return m
end

local function AddButton(section,name,cb)
    section:AddButton({Name=name,Callback=cb})
end

-- SETTINGS
do
    local A=SetMenu:AddSection({Position='left',Name="INTERFACE"})
    AddKeybind(A,"MenuKeybind",{Text="Menu Keybind",Default=Enum.KeyCode.Insert,
        Callback=function(v) if v~=nil then getgenv().RH_MenuKey=v end end})
    AddButton(A,"Unload",function()
        pcall(function() Window:SetVisible(false) end)
        getgenv().RH_Loaded=false
    end)
end

-- MISC
do
    local A=MiscMenu:AddSection({Position='left',Name="MOVEMENT"})
    AddToggle(A,"AutoBhop",{Text="Auto Bhop",Default=false})
    AddSlider(A,"BhopSpeed",{Text="Bhop Speed",Default=18,Min=5,Max=30,Rounding=1})
    AddToggle(A,"NoFallDamage",{Text="No Fall Damage",Default=false})
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        local char=LP.Character
        if not char then return end
        local rp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        if Toggles.AutoBhop and Toggles.AutoBhop.Value then
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                local rp2=RaycastParams.new()
                rp2.FilterDescendantsInstances={char}
                rp2.FilterType=Enum.RaycastFilterType.Exclude
                if Workspace:Raycast(rp.Position,Vector3.new(0,-4,0),rp2) then
                    hum.Jump=true
                end
            end
            local dir=GetMoveDir()
            if dir.Magnitude>0 then
                local spd=18
                if Options.BhopSpeed then spd=Options.BhopSpeed.Value end
                spd=math.clamp(spd,5,30)
                local t=dir*spd
                local v=rp.AssemblyLinearVelocity
                local nx=v.X+(t.X-v.X)*0.2
                local nz=v.Z+(t.Z-v.Z)*0.2
                rp.AssemblyLinearVelocity=Vector3.new(nx,v.Y,nz)
            end
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        if Toggles.NoFallDamage and Toggles.NoFallDamage.Value then
            local char=LP.Character
            if char then
                local hum=char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
                end
            end
        end
    end)
end)

-- COMBAT
do
    local A=CombatMenu:AddSection({Position='left',Name="SILENT AIM"})
    AddToggle(A,"SilentAim",{Text="Enable Silent Aim",Default=false})
    AddToggle(A,"SilentWallbang",{Text="Wallbang",Default=false})
    AddToggle(A,"SilentTeamCheck",{Text="Team Check",Default=true})
    AddToggle(A,"SilentUseFovCircle",{Text="Use FOV Circle",Default=false})

    local B=CombatMenu:AddSection({Position='left',Name="SILENT SETTINGS"})
    AddSlider(B,"SilentFovCircleRadius",{Text="FOV Radius",Default=50,Min=0,Max=300,Rounding=0})
    AddColor(B,"SilentFovColor",{Default=Color3.fromRGB(255,0,0),Title="FOV Color"})
    AddDropdown(B,"SilentHitPart",{Text="Hit Part",Values={"HumanoidRootPart","Head","UpperTorso","LowerTorso"},Default="Head"})

    local C=CombatMenu:AddSection({Position='center',Name="RAGEBOT"})
    AddToggle(C,"Ragebot",{Text="Enable Ragebot",Default=false})
    AddToggle(C,"RagebotVisibleCheck",{Text="Visible Check",Default=true})
    AddToggle(C,"RagebotTeamCheck",{Text="Team Check",Default=true})
    AddToggle(C,"RagebotWallCheck",{Text="Wall Check",Default=false})

    local D=CombatMenu:AddSection({Position='center',Name="RAGE SETTINGS"})
    AddSlider(D,"RageDelay",{Text="Delay",Default=0.01,Min=0,Max=1,Rounding=3})
    AddDropdown(D,"RageHitPart",{Text="Hit Part",Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},Default="Head"})

    local E=CombatMenu:AddSection({Position='right',Name="TRIGGERBOT"})
    AddToggle(E,"CubeTriggerbot",{Text="Enable Triggerbot",Default=false})
    AddSlider(E,"CubeTriggerbotDelay",{Text="Delay",Default=0.01,Min=0,Max=1,Rounding=3})

    local F1=CombatMenu:AddSection({Position='right',Name="CUBE MODE"})
    AddToggle(F1,"CubeModeMainToggle",{Text="Cube Mode",Default=false})
    AddToggle(F1,"CubeAimbotEnabled",{Text="Smart Aimbot",Default=false})
    AddToggle(F1,"CubeVisibleCheck",{Text="Visible Check",Default=false})
    AddDropdown(F1,"CubeHitPart",{Text="Hit Part",Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},Default="Head"})
end

do
    local A=CombatMenu:AddSection({Position='right',Name="CUBE CHECKER"})
    AddToggle(A,"BulletImpactV1Enabled",{Text="Enable Checker",Default=false})
    AddColor(A,"BulletImpactV1Color",{Default=Color3.fromRGB(255,0,0),Title="Color"})
    AddToggle(A,"BulletImpactV1Rainbow",{Text="Rainbow",Default=false})
    AddSlider(A,"BulletImpactV1Size",{Text="Size",Default=1.5,Min=0.5,Max=4,Rounding=1})
    AddSlider(A,"BulletImpactV1Dist",{Text="Max Dist",Default=20,Min=1,Max=50,Rounding=0})

    local B=CombatMenu:AddSection({Position='left',Name="SHOW TARGET"})
    AddToggle(B,"ShowTargetPlayer",{Text="Enable",Default=false})
    AddDropdown(B,"ShowTargetMode",{Text="Mode",Values={"Line","Crosshair"},Default="Crosshair"})
    AddColor(B,"ShowTargetLineColor",{Default=Color3.fromRGB(0,255,255),Title="Line Color"})
    AddColor(B,"ShowTargetCrosshairColor",{Default=Color3.fromRGB(0,255,255),Title="Crosshair Color"})

    local C=CombatMenu:AddSection({Position='center',Name="EXTRA"})
    AddToggle(C,"ShowPenetration",{Text="Show Penetration",Default=false})
end

-- VISUALS - ESP MAIN
do
    local A=VisualsMenu:AddSection({Position='left',Name="ESP MAIN"})
    AddToggle(A,"ESPEnabled",{Text="ESP Enabled",Default=false})
    AddToggle(A,"ESPTeamCheck",{Text="Team Check",Default=true})
    AddDropdown(A,"ESPBoxType",{Text="Box ESP",Values={"2D Box","3D Box","Corner Box","Disabled"},Default="2D Box"})
    AddToggle(A,"ESPBoxFillGradient",{Text="Fill Gradient",Default=false})
    AddToggle(A,"ESPBoxFillRotation",{Text="Fill Rotation",Default=false})
    AddSlider(A,"ESPBoxRotationSpeed",{Text="Rotation Speed",Default=2,Min=0.1,Max=10,Rounding=1})

    local B=VisualsMenu:AddSection({Position='left',Name="BOX COLOR"})
    AddColor(B,"ESPBoxColorA",{Default=Color3.new(1,1,1),Title="Box Color A"})
    AddColor(B,"ESPBoxColorB",{Default=Color3.fromRGB(0,200,255),Title="Box Color B"})
    AddColor(B,"ESPFillColorA",{Default=Color3.fromRGB(255,50,50),Title="Fill Color A"})
    AddColor(B,"ESPFillColorB",{Default=Color3.fromRGB(50,50,255),Title="Fill Color B"})

    local C=VisualsMenu:AddSection({Position='center',Name="ESP ITEMS"})
    AddToggle(C,"ESPName",{Text="Name",Default=false})
    AddToggle(C,"ESPDistance",{Text="Distance",Default=false})
    AddToggle(C,"ESPWeapon",{Text="Weapon Name",Default=false})
    AddToggle(C,"ESPHealth",{Text="Health Bar",Default=false})
    AddToggle(C,"ESPHealthText",{Text="Health Text",Default=false})
    AddToggle(C,"ESPSkeleton",{Text="Skeleton",Default=false})
    AddToggle(C,"ESPTracer",{Text="Tracer",Default=false})
end

do
    local D=VisualsMenu:AddSection({Position='center',Name="COLORS A"})
    AddColor(D,"ESPNameColor",{Default=Color3.new(1,1,1),Title="Name Color"})
    AddColor(D,"ESPDistanceColor",{Default=Color3.new(1,1,1),Title="Distance Color"})
    AddColor(D,"ESPWeaponColor",{Default=Color3.new(1,1,1),Title="Weapon Color"})
    AddColor(D,"ESPHealthTopColor",{Default=Color3.fromRGB(0,255,0),Title="Health Top"})
    AddColor(D,"ESPHealthBottomColor",{Default=Color3.fromRGB(255,0,0),Title="Health Bottom"})

    local E=VisualsMenu:AddSection({Position='right',Name="COLORS B"})
    AddColor(E,"ESPHealthTextColor",{Default=Color3.new(1,1,1),Title="HP Text Color"})
    AddColor(E,"ESPTracerColor",{Default=Color3.new(1,1,1),Title="Tracer Color A"})
    AddColor(E,"ESPTracerColorB",{Default=Color3.fromRGB(255,0,128),Title="Tracer Color B"})
    AddColor(E,"ESPSkeletonColorA",{Default=Color3.new(1,1,1),Title="Skel A"})
    AddColor(E,"ESPSkeletonColorB",{Default=Color3.fromRGB(0,255,255),Title="Skel B"})

    local F1=VisualsMenu:AddSection({Position='right',Name="TRACER & CIRC"})
    AddDropdown(F1,"ESPTracerOrigin",{Text="Tracer Origin",Values={"Bottom","Top","Center","Mouse"},Default="Bottom"})
    AddToggle(F1,"ESPCircularTarget",{Text="Circular Target",Default=false})
    AddColor(F1,"ESPCircularTargetColor",{Default=Color3.fromRGB(255,200,0),Title="Circ Color"})
end

do
    local A=VisualsMenu:AddSection({Position='left',Name="CHAMS"})
    AddToggle(A,"ChamsEnabled",{Text="Enable",Default=false})
    AddToggle(A,"ChamsTeamCheck",{Text="Team Check",Default=true})
    AddDropdown(A,"ChamsMaterialVisible",{Text="Material Visible",Values={"Neon","Metal","ForceField","SmoothPlastic"},Default="Neon"})
    AddColor(A,"ChamsColorVisible",{Default=Color3.fromRGB(0,200,0),Title="Visible Color"})
    AddSlider(A,"ChamsAlphaVisible",{Text="Vis Fill Alpha",Default=0.3,Min=0,Max=1,Rounding=2})

    local B=VisualsMenu:AddSection({Position='center',Name="CHAMS UNVIS"})
    AddDropdown(B,"ChamsMaterialUnvisible",{Text="Material Unvisible",Values={"Neon","Metal","ForceField","SmoothPlastic"},Default="Metal"})
    AddColor(B,"ChamsColorUnvisible",{Default=Color3.fromRGB(200,0,0),Title="Unvisible Color"})
    AddSlider(B,"ChamsAlphaUnvisible",{Text="Unvis Fill Alpha",Default=0.3,Min=0,Max=1,Rounding=2})
    AddSlider(B,"ChamsOutlineAlphaVisible",{Text="Vis Outline",Default=0,Min=0,Max=1,Rounding=2})
    AddSlider(B,"ChamsOutlineAlphaUnvisible",{Text="Unvis Outline",Default=0,Min=0,Max=1,Rounding=2})

    local C=VisualsMenu:AddSection({Position='right',Name="GRENADE ESP"})
    AddToggle(C,"GrenadeTracers",{Text="Grenade Tracers",Default=false})
    AddColor(C,"GrenadeTracerColor",{Default=Color3.fromRGB(255,100,0),Title="Tracer Color"})
    AddToggle(C,"MolotovZoneESP",{Text="Molotov Zone",Default=false})
    AddColor(C,"GrenadeZoneColor",{Default=Color3.fromRGB(255,60,0),Title="Zone Color"})
    AddToggle(C,"SmokeZoneESP",{Text="Smoke Zone",Default=false})
    AddColor(C,"SmokeZoneColor",{Default=Color3.fromRGB(180,180,180),Title="Smoke Color"})
end

-- WEAPONS
do
    local A=WeaponsMenu:AddSection({Position='left',Name="WEAPON MODS"})
    AddToggle(A,"Firerate",{Text="Firerate Changer",Default=false})
    AddSlider(A,"FirerateSlider",{Text="Firerate",Default=0.01,Min=0,Max=1,Rounding=3})
    AddToggle(A,"NoRecoil",{Text="No Recoil",Default=false})
    AddToggle(A,"NoSpread",{Text="No Spread",Default=false})
    AddToggle(A,"InstantReload",{Text="Instant Reload",Default=false})

    local B=WeaponsMenu:AddSection({Position='right',Name="GRENADES"})
    AddToggle(B,"Antiflashbang",{Text="No Flashbang",Default=false})
    AddToggle(B,"Antismoke",{Text="No Smoke",Default=false})
end

-- WORLD
do
    local A=WorldMenu:AddSection({Position='left',Name="TRACERS"})
    AddToggle(A,"BulletTracers",{Text="Bullet Tracers",Default=false})
    AddColor(A,"BulletTracersColor",{Default=Color3.fromRGB(0,170,255),Title="Tracer Color"})
    AddDropdown(A,"TracerStyle",{Text="Style",Values={"Block","Cylinder (Obelius)"},Default="Block"})
    AddToggle(A,"TracerRainbow",{Text="Rainbow",Default=false})
    AddSlider(A,"TracerTime",{Text="Time",Default=2,Min=0.1,Max=10,Rounding=1})
    AddToggle(A,"BulletImpacts",{Text="Impacts",Default=false})
    AddColor(A,"BulletImpactsColor",{Default=Color3.fromRGB(255,0,0),Title="Impact Color"})

    local B=WorldMenu:AddSection({Position='center',Name="CUSTOM HANDS"})
    AddToggle(B,"CustomHandsEnabled",{Text="Enable",Default=false})
    AddSlider(B,"HandsX",{Text="X",Default=0.2,Min=-2,Max=2,Rounding=3})
    AddSlider(B,"HandsY",{Text="Y",Default=-0.155,Min=-2,Max=2,Rounding=3})
    AddSlider(B,"HandsZ",{Text="Z",Default=0.075,Min=-2,Max=2,Rounding=3})

    local C=WorldMenu:AddSection({Position='center',Name="WEAPON CHAMS"})
    AddToggle(C,"WeaponChamsEnabled",{Text="Enable",Default=false})
    AddColor(C,"WeaponChamsColor",{Default=Color3.fromRGB(0,150,255),Title="Color"})
    AddDropdown(C,"WeaponChamsMode",{Text="Material",Values={"Glass","ForceField","Metal","Highlight","Neon"},Default="Glass"})
    AddSlider(C,"GlassTransparency",{Text="Glass Alpha",Default=0.4,Min=0,Max=1,Rounding=2})
    AddSlider(C,"MetalReflectance",{Text="Metal Reflect",Default=1.0,Min=0,Max=1,Rounding=1})

    local D=WorldMenu:AddSection({Position='right',Name="HIT SOUND"})
    AddToggle(D,"HitSoundEnabled",{Text="Enable",Default=false})
    AddToggle(D,"CustomHitSoundToggle",{Text="Custom Sound",Default=false})
    AddSlider(D,"HitSoundVolume",{Text="Volume",Default=1,Min=0.1,Max=5,Rounding=1})
    AddDropdown(D,"HitSoundPreset",{Text="Preset",Values={"Neverlose","Skeet","Bell","Bell2","Bubble","Rust","Coins","Pick"},Default="Neverlose"})
    AddInput(D,"CustomHitSoundID",{Text="Custom ID",Default="",Placeholder="rbxassetid://..."})
end

do
    local A=WorldMenu:AddSection({Position='left',Name="CAMERA"})
    AddToggle(A,"CustomFovToggle",{Text="Custom FOV",Default=false})
    AddSlider(A,"FovAmount",{Text="FOV Amount",Default=90,Min=70,Max=120,Rounding=0})
    AddToggle(A,"ThirdPerson",{Text="Third Person",Default=false})
    AddSlider(A,"ThirdPersonDist",{Text="TP Distance",Default=10,Min=5,Max=50,Rounding=1})

    local B=WorldMenu:AddSection({Position='center',Name="SCOPE"})
    AddToggle(B,"CustomScopeFov",{Text="Custom Scope FOV",Default=false})
    AddSlider(B,"ScopeFovValue",{Text="Scope FOV",Default=70,Min=10,Max=100,Rounding=1})
    AddToggle(B,"RemoveScope",{Text="Remove Scope",Default=false})
    AddToggle(B,"CustomScopeCrosshair",{Text="Scope Crosshair",Default=false})
    AddColor(B,"ScopeCrosshairColor",{Default=Color3.fromRGB(255,255,255),Title="Color"})
    AddSlider(B,"ScopeCrosshairThickness",{Text="Thickness",Default=2,Min=1,Max=10,Rounding=1})
    AddSlider(B,"ScopeCrosshairLengthLR",{Text="Length L&R",Default=150,Min=0,Max=1000,Rounding=0})
    AddSlider(B,"ScopeCrosshairLengthTB",{Text="Length T&B",Default=100,Min=0,Max=1000,Rounding=0})

    local C=WorldMenu:AddSection({Position='right',Name="SKYBOX"})
    AddToggle(C,"EnableSkybox",{Text="Enable Skybox",Default=false})
    AddDropdown(C,"SkyboxPreset",{Text="Preset",Values={"Night","Ocean Sunset","Deep Space","Purple Nebula","Minecraft","Retro"},Default="Night"})
    AddToggle(C,"Atmosphere",{Text="Atmosphere",Default=false})
    AddSlider(C,"AtmosphereDensity",{Text="Density",Default=0.3,Min=0,Max=1,Rounding=2})
    AddSlider(C,"AtmosphereHaze",{Text="Haze",Default=0,Min=0,Max=10,Rounding=1})
    AddSlider(C,"AtmosphereGlare",{Text="Glare",Default=0,Min=0,Max=10,Rounding=1})
end

-- SKINS
do
    local A=SkinMenu:AddSection({Position='left',Name="SKIN CHANGER"})
    AddToggle(A,"EnableSkins",{Text="Enable Weapon Skins",Default=false})
    AddToggle(A,"KnifeChangerToggle",{Text="Enable Knife Changer",Default=false})
    AddDropdown(A,"KnifeModel",{Text="Knife Model",Values={"Karambit","Butterfly Knife","Flip Knife","Gut Knife","M9 Bayonet","Skeleton Knife","Stiletto Knife"},Default="Skeleton Knife"})
    AddToggle(A,"GloveChangerToggle",{Text="Enable Gloves",Default=false})
end

-- ===== ESP SYSTEM =====
local espinstances={}
local R15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local R6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local CORNERS={{0,0,0},{1,0,0},{0,1,0},{1,1,0},{0,0,1},{1,0,1},{0,1,1},{1,1,1}}
local EDGES={{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
local _rot=0
local MAXFILL=200
local MAXHP=12
local GRAD_STEPS=4
local BD=20
local BW=86
local BH=155
local cache=setmetatable({},{__mode="k"})

local function halfext(p)
    local c=cache[p]
    if not c then
        local s=p.Size
        c={s.X*0.5,s.Y*0.5,s.Z*0.5}
        cache[p]=c
    end
    return c[1],c[2],c[3]
end

local function aabb(parts)
    local x0,y0,z0=math.huge,math.huge,math.huge
    local x1,y1,z1=-math.huge,-math.huge,-math.huge
    for i=1,#parts do
        local p=parts[i]
        local hx,hy,hz=halfext(p)
        local px,py,pz,r00,r01,r02,r10,r11,r12,r20,r21,r22=p.CFrame:GetComponents()
        local ex=math.abs(r00)*hx+math.abs(r01)*hy+math.abs(r02)*hz
        local ey=math.abs(r10)*hx+math.abs(r11)*hy+math.abs(r12)*hz
        local ez=math.abs(r20)*hx+math.abs(r21)*hy+math.abs(r22)*hz
        if px-ex<x0 then x0=px-ex end
        if py-ey<y0 then y0=py-ey end
        if pz-ez<z0 then z0=pz-ez end
        if px+ex>x1 then x1=px+ex end
        if py+ey>y1 then y1=py+ey end
        if pz+ez>z1 then z1=pz+ez end
    end
    if x0==math.huge then return nil end
    return x0,y0,z0,x1,y1,z1
end

local function projbox(x0,y0,z0,x1,y1,z1)
    local cx=(x0+x1)*0.5
    local cy=(y0+y1)*0.5
    local cz=(z0+z1)*0.5
    local sp,vis=Camera:WorldToViewportPoint(Vector3.new(cx,cy,cz))
    if not vis and sp.Z<=0 then return nil,nil,false end
    local d=sp.Z
    if d<=0 then d=0.1 end
    local sc=BD/d
    local w=BW*sc
    local h=BH*sc
    return Vector2.new(sp.X-w*0.5,sp.Y-h*0.5),Vector2.new(sp.X+w*0.5,sp.Y+h*0.5),true
end

local function projcorners(x0,y0,z0,x1,y1,z1)
    local sc={}
    local on=false
    for i=1,8 do
        local c=CORNERS[i]
        local wx=x0
        if c[1]==1 then wx=x1 end
        local wy=y0
        if c[2]==1 then wy=y1 end
        local wz=z0
        if c[3]==1 then wz=z1 end
        local pos,vis=Camera:WorldToViewportPoint(Vector3.new(wx,wy,wz))
        sc[i]=Vector2.new(pos.X,pos.Y)
        if vis then on=true end
    end
    return sc,on
end

local function ensureparts(inst,data)
    if data.pl then return data.pl end
    local list={}
    if inst:IsA("Model") then
        for _,p in next,inst:GetDescendants() do
            if p:IsA("BasePart") then
                list[#list+1]=p
                cache[p]=nil
            end
        end
    elseif inst:IsA("BasePart") then
        list[1]=inst
        cache[inst]=nil
    end
    data.pl=list
    return list
end

local function mklines(n,th)
    local r={}
    for i=1,n do
        local l=Drawing.new("Line")
        l.Thickness=th
        l.Transparency=1
        l.Visible=false
        r[i]=l
    end
    return r
end

local function mkfill()
    local r={}
    for i=1,MAXFILL do
        local l=Drawing.new("Line")
        l.Thickness=4
        l.Transparency=0.3
        l.Visible=false
        r[i]=l
    end
    return r
end

local function filldraw(fl,x,y,w,h,cA,cB,ang)
    local dx=math.cos(ang)
    local dy=math.sin(ang)
    local cx=x+w*0.5
    local cy=y+h*0.5
    local md=math.max((math.abs(dx)*w+math.abs(dy)*h)*0.5,1)
    local rows=math.clamp(math.floor(h*0.8),15,MAXFILL)
    local rh=h/rows
    for i=1,rows do
        local py=y+(i-0.5)*rh
        local tL=math.clamp((((x-cx)*dx+(py-cy)*dy)/md)*0.5+0.5,0,1)
        local tR=math.clamp((((x+w-cx)*dx+(py-cy)*dy)/md)*0.5+0.5,0,1)
        local l=fl[i]
        l.Color=lerpC(cA,cB,(tL+tR)*0.5)
        l.Thickness=math.clamp(rh+1.5,2,8)
        l.From=Vector2.new(x+1,py)
        l.To=Vector2.new(x+w-1,py)
        l.Visible=true
    end
    for i=rows+1,#fl do
        fl[i].Visible=false
    end
end

local function graddraw(box,x,y,w,h,cA,cB,rotOff)
    local g=box.grad
    local idx=0
    local sides={
        {x,y,x+w,y},
        {x+w,y,x+w,y+h},
        {x+w,y+h,x,y+h},
        {x,y+h,x,y}
    }
    for si=1,4 do
        local s=sides[si]
        for st=0,GRAD_STEPS-1 do
            idx=idx+1
            local tA=st/GRAD_STEPS
            local tB=(st+1)/GRAD_STEPS
            local tMid=(((si-1)/4)+(tA/4)+rotOff)%1
            local col=lerpC(cA,cB,tMid)
            local l=g[idx]
            if l then
                l.From=Vector2.new(s[1]+(s[3]-s[1])*tA,s[2]+(s[4]-s[2])*tA)
                l.To=Vector2.new(s[1]+(s[3]-s[1])*tB,s[2]+(s[4]-s[2])*tB)
                l.Color=col
                l.Visible=true
            end
        end
    end
    for i=idx+1,#g do
        g[i].Visible=false
    end
end

local function hidebox(box)
    box.outline.Visible=false
    box.fill.Visible=false
    for _,l in ipairs(box.grad) do l.Visible=false end
    for _,l in ipairs(box.fillgrad) do l.Visible=false end
    for _,l in ipairs(box.cornfill) do l.Visible=false end
    for _,l in ipairs(box.cornoutline) do l.Visible=false end
    for _,l in ipairs(box.b3d) do l.Visible=false end
end

local esp={}

function esp.addbox(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].box then return end
    local function mkl(th)
        local l=Drawing.new("Line")
        l.Thickness=th
        l.Transparency=1
        l.Visible=false
        return l
    end
    local function mks(th,f)
        local s=Drawing.new("Square")
        s.Thickness=th
        s.Filled=f
        s.Transparency=1
        s.Visible=false
        return s
    end
    local box={}
    box.outline=mks(3,false)
    box.fill=mks(1,false)
    box.grad={}
    for i=1,16 do box.grad[i]=mkl(1) end
    box.fillgrad=mkfill()
    box.cornfill={}
    box.cornoutline={}
    for i=1,8 do
        box.cornfill[i]=mkl(1)
        box.cornoutline[i]=mkl(3)
    end
    box.b3d={}
    for i=1,12 do box.b3d[i]=mkl(2) end
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].box=box
end

function esp.addhp(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].hp then return end
    local bg=Drawing.new("Square")
    bg.Thickness=1
    bg.Filled=true
    bg.Color=Color3.new(0,0,0)
    bg.Transparency=0.5
    bg.Visible=false
    local segs={}
    for i=1,MAXHP do
        local l=Drawing.new("Line")
        l.Thickness=3
        l.Transparency=1
        l.Visible=false
        segs[i]=l
    end
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].hp={bg=bg,segs=segs}
end

function esp.addhptext(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].hptext then return end
    local t=Drawing.new("Text")
    t.Center=false
    t.Outline=true
    t.Font=1
    t.Transparency=1
    t.Visible=false
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].hptext=t
end

function esp.addname(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].name then return end
    local t=Drawing.new("Text")
    t.Center=true
    t.Outline=true
    t.Font=1
    t.Transparency=1
    t.Visible=false
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].name=t
end

function esp.adddist(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].dist then return end
    local t=Drawing.new("Text")
    t.Center=true
    t.Outline=true
    t.Font=1
    t.Transparency=1
    t.Visible=false
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].dist=t
end

function esp.addtracer(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].tracer then return end
    local o=Drawing.new("Line")
    o.Thickness=3
    o.Transparency=1
    o.Visible=false
    local f=Drawing.new("Line")
    f.Thickness=1
    f.Transparency=1
    f.Visible=false
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].tracer={o=o,f=f}
end

function esp.addskel(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].skel then return end
    local isR15=inst:FindFirstChild("UpperTorso")~=nil
    local bones=isR15 and R15 or R6
    local lines={}
    local bp={}
    for i=1,#bones do
        local l=Drawing.new("Line")
        l.Thickness=2
        l.Transparency=1
        l.Visible=false
        lines[i]=l
        bp[i]={inst:FindFirstChild(bones[i][1]),inst:FindFirstChild(bones[i][2])}
    end
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].skel={lines=lines,bp=bp,sc={}}
end

function esp.addweap(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].weap then return end
    local t=Drawing.new("Text")
    t.Center=true
    t.Outline=true
    t.Font=1
    t.Transparency=1
    t.Visible=false
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].weap=t
end

function esp.addcirc(inst)
    if not inst then return end
    if espinstances[inst] and espinstances[inst].circ then return end
    local SEG=32
    local lines={}
    for i=1,SEG do
        local l=Drawing.new("Line")
        l.Thickness=1.5
        l.Transparency=1
        l.Visible=false
        lines[i]=l
    end
    local TR=25
    local trail={}
    local glow={}
    for i=1,TR do
        local l=Drawing.new("Line")
        l.Thickness=2.5
        l.Transparency=0.4
        l.Visible=false
        trail[i]=l
        local g=Drawing.new("Line")
        g.Thickness=5
        g.Transparency=0.15
        g.Visible=false
        glow[i]=g
    end
    espinstances[inst]=espinstances[inst] or {}
    espinstances[inst].circ={lines=lines,trail=trail,glow=glow,seg=SEG,alpha=0,up=true,hist={}}
end

local function hideall(data)
    if data.box then hidebox(data.box) end
    if data.hp then
        data.hp.bg.Visible=false
        for _,s in ipairs(data.hp.segs) do s.Visible=false end
    end
    if data.hptext then data.hptext.Visible=false end
    if data.name then data.name.Visible=false end
    if data.dist then data.dist.Visible=false end
    if data.tracer then
        data.tracer.o.Visible=false
        data.tracer.f.Visible=false
    end
    if data.skel then
        for _,l in ipairs(data.skel.lines) do l.Visible=false end
    end
    if data.weap then data.weap.Visible=false end
    if data.circ then
        for _,l in ipairs(data.circ.lines) do l.Visible=false end
        for _,l in ipairs(data.circ.trail) do l.Visible=false end
        for _,l in ipairs(data.circ.glow) do l.Visible=false end
    end
end

local function cleaninst(inst,data)
    pcall(function()
        if data.box then
            data.box.outline:Remove()
            data.box.fill:Remove()
            for _,l in next,data.box.grad do l:Remove() end
            for _,l in next,data.box.fillgrad do l:Remove() end
            for _,l in next,data.box.cornfill do l:Remove() end
            for _,l in next,data.box.cornoutline do l:Remove() end
            for _,l in next,data.box.b3d do l:Remove() end
        end
        if data.hp then
            data.hp.bg:Remove()
            for _,s in ipairs(data.hp.segs) do s:Remove() end
        end
        if data.hptext then data.hptext:Remove() end
        if data.name then data.name:Remove() end
        if data.dist then data.dist:Remove() end
        if data.tracer then
            data.tracer.o:Remove()
            data.tracer.f:Remove()
        end
        if data.skel then
            for _,l in next,data.skel.lines do l:Remove() end
        end
        if data.weap then data.weap:Remove() end
        if data.circ then
            for _,l in ipairs(data.circ.lines) do l:Remove() end
            for _,l in ipairs(data.circ.trail) do l:Remove() end
            for _,l in ipairs(data.circ.glow) do l:Remove() end
        end
    end)
end

local wcache={}
local wname={}
local function GetWeaponName(plr)
    if not plr then return "None" end
    local a=plr:GetAttribute("CurrentEquipped")
    if a~=wcache[plr] then
        wcache[plr]=a
        if a then
            local ok,dec=pcall(function() return HS:JSONDecode(a) end)
            if ok and dec then
                wname[plr]=dec.Name or "None"
            else
                wname[plr]="None"
            end
        else
            wname[plr]="None"
        end
    end
    return wname[plr] or "None"
end

local function scrpos(cache,part)
    local c=cache[part]
    if c then return c[1],c[2] end
    local pos,vis=Camera:WorldToViewportPoint(part.Position)
    local sp=Vector2.new(pos.X,pos.Y)
    cache[part]={sp,vis}
    return sp,vis
end

-- ↑↑↑ ЧАСТЬ 1 ЗАКОНЧИЛАСЬ ↑↑↑
RunService.RenderStepped:Connect(function(dt)
    if Toggles.ESPBoxFillRotation and Toggles.ESPBoxFillRotation.Value then
        _rot=(_rot+dt*(Options.ESPBoxRotationSpeed and Options.ESPBoxRotationSpeed.Value or 2))%(math.pi*2)
    end
    local camPos=Camera.CFrame.Position
    local vp=Camera.ViewportSize
    local teamChk=Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value
    local rotOff=_rot/(math.pi*2)

    for inst,data in next,espinstances do
        if not inst or not inst.Parent then
            cleaninst(inst,data)
            espinstances[inst]=nil
            continue
        end
        if inst==LP.Character then hideall(data) continue end
        if teamChk and isAlly(inst) then hideall(data) continue end

        local hAttr=inst:GetAttribute("Health")
        local maxAttr=inst:GetAttribute("MaxHealth") or 100
        local deadAttr=inst:GetAttribute("Dead")
        if deadAttr==true or (hAttr and hAttr<=0) then hideall(data) continue end

        local nBox=Toggles.ESPEnabled.Value and Options.ESPBoxType.Value~="Disabled" and data.box~=nil
        local nHp=Toggles.ESPEnabled.Value and Toggles.ESPHealth.Value and data.hp~=nil
        local nHpTxt=Toggles.ESPEnabled.Value and Toggles.ESPHealthText.Value and data.hptext~=nil
        local nName=Toggles.ESPEnabled.Value and Toggles.ESPName.Value and data.name~=nil
        local nDist=Toggles.ESPEnabled.Value and Toggles.ESPDistance.Value and data.dist~=nil
        local nTrc=Toggles.ESPEnabled.Value and Toggles.ESPTracer.Value and data.tracer~=nil
        local nSkel=Toggles.ESPEnabled.Value and Toggles.ESPSkeleton.Value and data.skel~=nil
        local nWep=Toggles.ESPEnabled.Value and Toggles.ESPWeapon.Value and data.weap~=nil
        local nCirc=Toggles.ESPEnabled.Value and Toggles.ESPCircularTarget.Value and data.circ~=nil

        if data.box and not nBox then hidebox(data.box) end
        if data.hp and not nHp then
            data.hp.bg.Visible=false
            for _,s in ipairs(data.hp.segs) do s.Visible=false end
        end
        if data.hptext and not nHpTxt then data.hptext.Visible=false end
        if data.name and not nName then data.name.Visible=false end
        if data.dist and not nDist then data.dist.Visible=false end
        if data.tracer and not nTrc then
            data.tracer.o.Visible=false
            data.tracer.f.Visible=false
        end
        if data.skel and not nSkel then
            for _,l in ipairs(data.skel.lines) do l.Visible=false end
        end
        if data.weap and not nWep then data.weap.Visible=false end
        if data.circ and not nCirc then
            for _,l in ipairs(data.circ.lines) do l.Visible=false end
            for _,l in ipairs(data.circ.trail) do l.Visible=false end
            for _,l in ipairs(data.circ.glow) do l.Visible=false end
        end

        if not (nBox or nHp or nHpTxt or nName or nDist or nTrc or nSkel or nWep or nCirc) then continue end

        local parts=ensureparts(inst,data)
        local min2,max2,onscr
        local c3d,on3d
        local x0,y0,z0,x1,y1,z1=aabb(parts)
        if x0 then
            min2,max2,onscr=projbox(x0,y0,z0,x1,y1,z1)
            if nBox and Options.ESPBoxType.Value=="3D Box" then
                c3d,on3d=projcorners(x0,y0,z0,x1,y1,z1)
            end
        end

        if data.box and nBox and onscr and min2 and max2 then
            local x=min2.X
            local y=min2.Y
            local w=max2.X-min2.X
            local h=max2.Y-min2.Y
            local cA=Options.ESPBoxColorA.Value
            local cB=Options.ESPBoxColorB.Value
            local fA=Options.ESPFillColorA.Value
            local fB=Options.ESPFillColorB.Value
            local bt=Options.ESPBoxType.Value
            if bt=="2D Box" then
                if Toggles.ESPBoxFillGradient.Value then
                    filldraw(data.box.fillgrad,x,y,w,h,fA,fB,_rot)
                else
                    for _,l in ipairs(data.box.fillgrad) do l.Visible=false end
                end
                graddraw(data.box,x,y,w,h,cA,cB,rotOff)
                data.box.outline.Visible=false
                data.box.fill.Visible=false
                for _,l in ipairs(data.box.cornfill) do l.Visible=false end
                for _,l in ipairs(data.box.cornoutline) do l.Visible=false end
                for _,l in ipairs(data.box.b3d) do l.Visible=false end
            elseif bt=="Corner Box" then
                for _,l in ipairs(data.box.grad) do l.Visible=false end
                data.box.outline.Visible=false
                data.box.fill.Visible=false
                if Toggles.ESPBoxFillGradient.Value then
                    filldraw(data.box.fillgrad,x,y,w,h,fA,fB,_rot)
                else
                    for _,l in ipairs(data.box.fillgrad) do l.Visible=false end
                end
                local len=math.min(w,h)*0.25
                local corners={
                    {Vector2.new(x,y),Vector2.new(x+len,y)},
                    {Vector2.new(x,y),Vector2.new(x,y+len)},
                    {Vector2.new(x+w-len,y),Vector2.new(x+w,y)},
                    {Vector2.new(x+w,y),Vector2.new(x+w,y+len)},
                    {Vector2.new(x,y+h),Vector2.new(x+len,y+h)},
                    {Vector2.new(x,y+h-len),Vector2.new(x,y+h)},
                    {Vector2.new(x+w-len,y+h),Vector2.new(x+w,y+h)},
                    {Vector2.new(x+w,y+h-len),Vector2.new(x+w,y+h)}
                }
                for i=1,8 do
                    local col=lerpC(cA,cB,(i-1)/8)
                    data.box.cornoutline[i].From=corners[i][1]
                    data.box.cornoutline[i].To=corners[i][2]
                    data.box.cornoutline[i].Color=Color3.new(0,0,0)
                    data.box.cornoutline[i].Visible=true
                    data.box.cornfill[i].From=corners[i][1]
                    data.box.cornfill[i].To=corners[i][2]
                    data.box.cornfill[i].Color=col
                    data.box.cornfill[i].Visible=true
                end
                for _,l in ipairs(data.box.b3d) do l.Visible=false end
            elseif bt=="3D Box" then
                for _,l in ipairs(data.box.fillgrad) do l.Visible=false end
                for _,l in ipairs(data.box.grad) do l.Visible=false end
                data.box.outline.Visible=false
                data.box.fill.Visible=false
                for _,l in ipairs(data.box.cornfill) do l.Visible=false end
                for _,l in ipairs(data.box.cornoutline) do l.Visible=false end
                if c3d and #c3d==8 then
                    for i=1,12 do
                        local e=EDGES[i]
                        data.box.b3d[i].From=c3d[e[1]]
                        data.box.b3d[i].To=c3d[e[2]]
                        data.box.b3d[i].Color=lerpC(cA,cB,(i-1)/12)
                        data.box.b3d[i].Visible=on3d
                    end
                else
                    for _,l in ipairs(data.box.b3d) do l.Visible=false end
                end
            end
        elseif data.box then
            hidebox(data.box)
        end

        if data.hp then
            local bg=data.hp.bg
            local segs=data.hp.segs
            if nHp and onscr and min2 and max2 and hAttr then
                local x=min2.X-6
                local y=min2.Y
                local w=3
                local h=max2.Y-min2.Y
                local maxHp=maxAttr>0 and maxAttr or 100
                local frac=math.clamp(hAttr/maxHp,0,1)
                bg.Position=Vector2.new(x-1,y-1)
                bg.Size=Vector2.new(w+2,h+2)
                bg.Visible=true
                local bh=h*frac
                local startY=y+(h-bh)
                local cnt=math.clamp(math.floor(MAXHP*frac),1,MAXHP)
                local segH=bh/cnt
                for i=1,MAXHP do
                    local seg=segs[i]
                    if i<=cnt then
                        seg.Color=lerpC(Options.ESPHealthBottomColor.Value,Options.ESPHealthTopColor.Value,(i-0.5)/MAXHP)
                        seg.From=Vector2.new(x+w*0.5,startY+(i-1)*segH)
                        seg.To=Vector2.new(x+w*0.5,startY+i*segH)
                        seg.Thickness=w
                        seg.Visible=true
                    else
                        seg.Visible=false
                    end
                end
            else
                bg.Visible=false
                for _,s in ipairs(segs) do s.Visible=false end
            end
        end

        if data.hptext then
            if nHpTxt and onscr and min2 and max2 and hAttr then
                data.hptext.Text=tostring(math.floor(hAttr+0.5))
                data.hptext.Size=12
                data.hptext.Color=Options.ESPHealthTextColor.Value
                data.hptext.Position=Vector2.new(max2.X+4,min2.Y+(max2.Y-min2.Y)*(1-(hAttr/maxAttr))-4)
                data.hptext.Visible=true
            else
                data.hptext.Visible=false
            end
        end

        if data.name then
            if nName and onscr and min2 and max2 then
                data.name.Text=inst.Name
                data.name.Size=13
                data.name.Color=Options.ESPNameColor.Value
                data.name.Position=Vector2.new((min2.X+max2.X)*0.5,min2.Y-15)
                data.name.Visible=true
            else
                data.name.Visible=false
            end
        end

        if data.dist then
            if nDist and onscr and min2 and max2 then
                local d=999
                if inst:IsA("Model") and inst.PrimaryPart then
                    d=(camPos-inst.PrimaryPart.Position).Magnitude
                elseif inst:IsA("BasePart") then
                    d=(camPos-inst.Position).Magnitude
                end
                data.dist.Text=tostring(math.floor(d)).."m"
                data.dist.Size=13
                data.dist.Color=Options.ESPDistanceColor.Value
                data.dist.Position=Vector2.new((min2.X+max2.X)*0.5,max2.Y+2)
                data.dist.Visible=true
            else
                data.dist.Visible=false
            end
        end

        if data.weap then
            if nWep and onscr and min2 and max2 then
                if not data.plr then data.plr=Players:GetPlayerFromCharacter(inst) end
                local wn=data.plr and GetWeaponName(data.plr) or "None"
                data.weap.Text="["..wn.."]"
                data.weap.Size=13
                data.weap.Color=Options.ESPWeaponColor.Value
                data.weap.Position=Vector2.new((min2.X+max2.X)*0.5,max2.Y+15)
                data.weap.Visible=true
            else
                data.weap.Visible=false
            end
        end

        if data.tracer then
            if nTrc and onscr and min2 and max2 then
                local from
                local o=Options.ESPTracerOrigin.Value
                if o=="Mouse" then
                    local ml=UIS:GetMouseLocation()
                    from=Vector2.new(ml.X,ml.Y)
                elseif o=="Top" then
                    from=Vector2.new(vp.X/2,0)
                elseif o=="Center" then
                    from=Vector2.new(vp.X/2,vp.Y/2)
                else
                    from=Vector2.new(vp.X/2,vp.Y)
                end
                local to=(min2+max2)/2
                local d=0
                if inst:IsA("Model") and inst.PrimaryPart then
                    d=math.clamp((camPos-inst.PrimaryPart.Position).Magnitude/200,0,1)
                end
                local col=lerpC(Options.ESPTracerColor.Value,Options.ESPTracerColorB.Value,d)
                data.tracer.o.From=from
                data.tracer.o.To=to
                data.tracer.o.Color=Color3.new(0,0,0)
                data.tracer.o.Visible=true
                data.tracer.f.From=from
                data.tracer.f.To=to
                data.tracer.f.Color=col
                data.tracer.f.Visible=true
            else
                data.tracer.o.Visible=false
                data.tracer.f.Visible=false
            end
        end

        if data.skel then
            if nSkel then
                local bp=data.skel.bp
                local lines=data.skel.lines
                local sc=data.skel.sc
                for k in next,sc do sc[k]=nil end
                local any=false
                for i=1,#bp do
                    local pA=bp[i][1]
                    local pB=bp[i][2]
                    local line=lines[i]
                    if pA and pB and pA.Parent and pB.Parent then
                        local posA,vA=scrpos(sc,pA)
                        local posB,vB=scrpos(sc,pB)
                        if vA or vB then
                            line.From=posA
                            line.To=posB
                            line.Color=lerpC(Options.ESPSkeletonColorA.Value,Options.ESPSkeletonColorB.Value,(i-1)/#bp)
                            line.Thickness=2
                            line.Visible=true
                            any=true
                        else
                            line.Visible=false
                        end
                    else
                        line.Visible=false
                    end
                end
                if not any then
                    for _,l in ipairs(lines) do l.Visible=false end
                end
            else
                for _,l in ipairs(data.skel.lines) do l.Visible=false end
            end
        end

        if data.circ then
            local ct=data.circ
            local head=inst:FindFirstChild("Head")
            local root=inst:FindFirstChild("HumanoidRootPart") or head
            if inst:IsA("Model") and inst.PrimaryPart then root=inst.PrimaryPart end
            if nCirc and head and root then
                local sp=2.0
                if ct.up then
                    ct.alpha=ct.alpha+dt*sp
                    if ct.alpha>=1 then
                        ct.alpha=1
                        ct.up=false
                    end
                else
                    ct.alpha=ct.alpha-dt*sp
                    if ct.alpha<=0 then
                        ct.alpha=0
                        ct.up=true
                    end
                end
                local footPos=root.Position-Vector3.new(0,(root.Size.Y*0.8)+1.2,0)
                local headPos=head.Position+Vector3.new(0,0.3,0)
                local curPos=footPos:Lerp(headPos,ct.alpha)
                table.insert(ct.hist,1,curPos)
                if #ct.hist>#ct.trail then table.remove(ct.hist) end
                for i=1,#ct.trail do
                    local tl=ct.trail[i]
                    local gl=ct.glow[i]
                    local p1=ct.hist[i]
                    local p2=ct.hist[i+1]
                    if p1 and p2 then
                        local s1,v1=Camera:WorldToViewportPoint(p1)
                        local s2,v2=Camera:WorldToViewportPoint(p2)
                        if v1 or v2 then
                            local fade=math.clamp(1-(i/#ct.trail),0.05,1)
                            gl.From=Vector2.new(s1.X,s1.Y)
                            gl.To=Vector2.new(s2.X,s2.Y)
                            gl.Color=Options.ESPCircularTargetColor.Value
                            gl.Transparency=fade*0.35
                            gl.Visible=true
                            tl.From=Vector2.new(s1.X,s1.Y)
                            tl.To=Vector2.new(s2.X,s2.Y)
                            tl.Color=Options.ESPCircularTargetColor.Value
                            tl.Transparency=fade*0.85
                            tl.Visible=true
                        else
                            tl.Visible=false
                            gl.Visible=false
                        end
                    else
                        tl.Visible=false
                        gl.Visible=false
                    end
                end
                local R=2.2
                local SEG=ct.seg
                local col=Options.ESPCircularTargetColor.Value
                for i=1,SEG do
                    local aA=(math.pi*2)*((i-1)/SEG)
                    local aB=(math.pi*2)*(i/SEG)
                    local wA=curPos+Vector3.new(math.cos(aA)*R,0,math.sin(aA)*R)
                    local wB=curPos+Vector3.new(math.cos(aB)*R,0,math.sin(aB)*R)
                    local sA,vA=Camera:WorldToViewportPoint(wA)
                    local sB,vB=Camera:WorldToViewportPoint(wB)
                    local line=ct.lines[i]
                    if vA or vB then
                        line.From=Vector2.new(sA.X,sA.Y)
                        line.To=Vector2.new(sB.X,sB.Y)
                        line.Color=col
                        line.Visible=true
                    else
                        line.Visible=false
                    end
                end
            else
                for _,l in ipairs(ct.lines) do l.Visible=false end
                for _,l in ipairs(ct.trail) do l.Visible=false end
                for _,l in ipairs(ct.glow) do l.Visible=false end
            end
        end
    end
end)

-- CHARACTER SCANNER
local espChars={}
local function addChar(c)
    if not c or espChars[c] then return end
    if c==LP.Character then return end
    esp.addbox(c)
    esp.addname(c)
    esp.addhp(c)
    esp.addhptext(c)
    esp.adddist(c)
    esp.addtracer(c)
    esp.addskel(c)
    esp.addweap(c)
    esp.addcirc(c)
    espChars[c]=true
end
local function remChar(c)
    if c then
        if espinstances[c] then
            cleaninst(c,espinstances[c])
            espinstances[c]=nil
        end
        espChars[c]=nil
    end
end

local charsFolder=Workspace:WaitForChild("Characters",5)
local function scanChars()
    if not charsFolder then return end
    local function proc(cont)
        for _,ch in ipairs(cont:GetChildren()) do
            if ch:IsA("Model") then
                if ch:GetAttribute("Health")~=nil or ch:FindFirstChild("Head") then
                    addChar(ch)
                end
                proc(ch)
            end
        end
    end
    proc(charsFolder)
end
scanChars()

if charsFolder then
    charsFolder.DescendantAdded:Connect(function(d)
        if d:IsA("Model") then
            task.wait(0.1)
            if d:GetAttribute("Health")~=nil or d:FindFirstChild("Head") then
                addChar(d)
            end
        end
    end)
    charsFolder.DescendantRemoving:Connect(function(d)
        if d:IsA("Model") then remChar(d) end
    end)
end

-- TARGET SYSTEM
local SilentTarget=nil
local RageTarget=nil
local CubeTarget=nil
local lockedInst=nil
local rayP=RaycastParams.new()
rayP.FilterType=Enum.RaycastFilterType.Exclude
rayP.IgnoreWater=true

local function isVisible(target)
    local ign={LP.Character}
    local myT=getTeam(LP)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and getTeam(p)==myT and p.Character then
            table.insert(ign,p.Character)
        end
    end
    rayP.FilterDescendantsInstances=ign
    local origin=Camera.CFrame.Position
    local dir=target.Position-origin
    local res=Workspace:Raycast(origin,dir,rayP)
    if res then
        local m=res.Instance:FindFirstAncestorOfClass("Model")
        local hp=Players:GetPlayerFromCharacter(m)
        if hp and hp.Character==target.Parent then return true end
        return false
    end
    return true
end

local function cubeActive()
    if Toggles.CubeModeMainToggle and Toggles.CubeModeMainToggle.Value then return true end
    return false
end

local function FindTargets()
    local lchar=LP.Character
    if not lchar then return end
    local myT=getTeam(LP)
    local center=Camera.ViewportSize/2
    local sDist=math.huge
    local sClose=nil
    local rDist=math.huge
    local rClose=nil
    local cDist=math.huge
    local cClose=nil
    local cActive=cubeActive()

    local cf=Workspace:FindFirstChild("Characters")
    if not cf then return end

    local all={}
    for _,obj in ipairs(cf:GetDescendants()) do
        if obj:IsA("Model") then
            local h=obj:FindFirstChild("Head")
            local r=obj:FindFirstChild("HumanoidRootPart")
            if (h or r) and obj~=lchar then
                local dead=obj:GetAttribute("Dead") or obj:GetAttribute("Invincible")
                local hp=obj:GetAttribute("Health")
                if not dead and (hp==nil or hp>0) then
                    table.insert(all,obj)
                end
            end
        end
    end

    if cActive then
        local chosen=Options.CubeHitPart.Value or "Head"
        if lockedInst and lockedInst.Parent then
            local cm=lockedInst.Parent
            local dead=cm:GetAttribute("Dead") or cm:GetAttribute("Invincible")
            local hp=cm:GetAttribute("Health")
            if dead or (hp and hp<=0) then
                lockedInst=nil
            elseif Toggles.CubeVisibleCheck.Value and not isVisible(lockedInst) then
                lockedInst=nil
            end
        else
            lockedInst=nil
        end

        local best=lockedInst
        local bestD=math.huge
        if lockedInst then
            local bp=lockedInst.Parent:FindFirstChild(chosen) or lockedInst
            if bp then bestD=(Camera.CFrame.Position-bp.Position).Magnitude end
        end
        for _,ch in ipairs(all) do
            if not isEnemy(ch) then continue end
            local tp=ch:FindFirstChild(chosen) or ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
            if not tp then continue end
            local okVis=true
            if Toggles.CubeVisibleCheck.Value then okVis=isVisible(tp) end
            if okVis then
                local d=(Camera.CFrame.Position-tp.Position).Magnitude
                if d<bestD then
                    bestD=d
                    best=tp
                end
            end
        end
        lockedInst=best
        cClose=best
    else
        lockedInst=nil
    end

    for _,ch in ipairs(all) do
        if not isEnemy(ch) then continue end
        if Toggles.Ragebot and Toggles.Ragebot.Value then
            local rp=ch:FindFirstChild(Options.RageHitPart.Value) or ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
            if rp then
                local _,on=Camera:WorldToViewportPoint(rp.Position)
                local alive=true
                if Toggles.RagebotVisibleCheck.Value and not on then alive=false end
                if alive and Toggles.RagebotWallCheck.Value and not isVisible(rp) then alive=false end
                if alive then
                    local d=(Camera.CFrame.Position-rp.Position).Magnitude
                    if d<rDist then
                        rDist=d
                        rClose=rp
                    end
                end
            end
        end
        if Toggles.SilentAim and Toggles.SilentAim.Value then
            local sName=Options.SilentHitPart.Value or "Head"
            local sp=ch:FindFirstChild(sName) or ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
            if sp then
                local spos,son=Camera:WorldToViewportPoint(sp.Position)
                if son then
                    local sd=(Vector2.new(spos.X,spos.Y)-center).Magnitude
                    local maxR=999999
                    if Toggles.SilentUseFovCircle.Value then
                        maxR=Options.SilentFovCircleRadius.Value
                    end
                    if sd<=maxR then
                        local ok=false
                        if Toggles.SilentWallbang.Value then ok=true else ok=isVisible(sp) end
                        if ok and sd<sDist then
                            sDist=sd
                            sClose=sp
                        end
                    end
                end
            end
        end
    end
    SilentTarget=sClose
    RageTarget=rClose
    CubeTarget=cClose
end

local SFovC=Drawing.new("Circle")
SFovC.NumSides=128
SFovC.Thickness=1.5
SFovC.Filled=false
SFovC.Visible=false

local frameCnt=0
RunService.RenderStepped:Connect(function()
    frameCnt=frameCnt+1
    local vp=Camera.ViewportSize
    local c=vp/2
    pcall(function()
        SFovC.Position=c
        SFovC.Radius=Options.SilentFovCircleRadius.Value
        SFovC.Color=Options.SilentFovColor.Value
        SFovC.Visible=Toggles.SilentAim.Value and Toggles.SilentUseFovCircle.Value
    end)
    if frameCnt%2==0 then FindTargets() end
    if cubeActive() and CubeTarget and CubeTarget.Parent then
        pcall(function()
            Camera.CFrame=CFrame.new(Camera.CFrame.Position,CubeTarget.Position)
        end)
    end
end)

-- SHOW TARGET
local STLines={}
for i=1,4 do
    local l=Drawing.new("Line")
    l.Thickness=2
    l.Transparency=1
    l.Visible=false
    STLines[i]=l
end
local STConn=Drawing.new("Line")
STConn.Thickness=1.5
STConn.Transparency=1
STConn.Visible=false

RunService.RenderStepped:Connect(function()
    pcall(function()
        local cA=cubeActive()
        local en=cA and Toggles.ShowTargetPlayer.Value
        local md=Options.ShowTargetMode.Value
        local closest=nil
        local minD=math.huge
        local myT=getTeam(LP)
        local chosen=Options.CubeHitPart.Value
        if en then
            for _,v in ipairs(Players:GetPlayers()) do
                if v~=LP then
                    local ch=v.Character
                    if ch then
                        local hum=ch:FindFirstChildOfClass("Humanoid")
                        local dead=ch:GetAttribute("Dead") or ch:GetAttribute("Invincible") or (hum and hum.Health<=0)
                        if not dead then
                            local vT=getTeam(v)
                            if myT~=vT then
                                local pp=ch:FindFirstChild(chosen) or ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
                                if pp then
                                    local d=(Camera.CFrame.Position-pp.Position).Magnitude
                                    if d<minD then
                                        minD=d
                                        closest=pp
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        local lVis=false
        local cVis=false
        if en and closest and closest.Parent then
            local sp,on=Camera:WorldToViewportPoint(closest.Position)
            local center=Vector2.new(sp.X,sp.Y)
            local t=tick()
            if md=="Crosshair" then
                local col=Options.ShowTargetCrosshairColor.Value
                local pulse=1+0.3*math.sin(t*math.pi*2)
                local size=16*pulse
                local gap=5*pulse
                local ang=math.rad((t*180)%360)
                local bA={0,math.pi/2,math.pi,3*math.pi/2}
                for j=1,4 do
                    local l=STLines[j]
                    l.Color=col
                    l.Thickness=2
                    local a=ang+bA[j]
                    local ca=math.cos(a)
                    local sa=math.sin(a)
                    l.From=center+Vector2.new(ca*gap,sa*gap)
                    l.To=center+Vector2.new(ca*(gap+size),sa*(gap+size))
                    l.Visible=true
                end
                cVis=true
            elseif md=="Line" then
                local col=Options.ShowTargetLineColor.Value
                local vp=Camera.ViewportSize/2
                STConn.From=vp
                STConn.To=center
                STConn.Color=col
                STConn.Visible=true
                lVis=true
            end
        end
        if not cVis then
            for j=1,4 do STLines[j].Visible=false end
        end
        if not lVis then STConn.Visible=false end
    end)
end)

-- CUBE CHECKER
local CubePart=Instance.new("Part")
CubePart.Name="RH_CubeChecker"
CubePart.Size=Vector3.new(1.5,1.5,0.01)
CubePart.Anchored=true
CubePart.CanCollide=false
CubePart.CanQuery=false
CubePart.CanTouch=false
CubePart.Material=Enum.Material.Neon
CubePart.Transparency=0.98
local SB=Instance.new("SelectionBox")
SB.Adornee=CubePart
SB.Color3=Color3.fromRGB(255,0,0)
SB.LineThickness=0.04
SB.Transparency=0.2
SB.Parent=CubePart
local IRP=RaycastParams.new()
IRP.FilterType=Enum.RaycastFilterType.Exclude
IRP.IgnoreWater=true

RunService.RenderStepped:Connect(function()
    pcall(function()
        local cA=cubeActive()
        local en=cA and Toggles.BulletImpactV1Enabled.Value
        CubePart.Parent=en and Workspace or nil
        if en then
            local sz=Options.BulletImpactV1Size.Value
            local mx=Options.BulletImpactV1Dist.Value
            CubePart.Size=Vector3.new(sz,sz,0.01)
            local col=Options.BulletImpactV1Color.Value
            if Toggles.BulletImpactV1Rainbow.Value then
                col=Color3.fromHSV((tick()%5)/5,1,1)
            end
            IRP.FilterDescendantsInstances={LP.Character,CubePart}
            local res=Workspace:Raycast(Camera.CFrame.Position,Camera.CFrame.LookVector*mx,IRP)
            if res then
                CubePart.Parent=Workspace
                CubePart.CFrame=CFrame.lookAt(res.Position+res.Normal*0.02,res.Position+res.Normal)
                if CubeTarget and cA and Toggles.CubeAimbotEnabled.Value then
                    CubePart.Color=Color3.fromRGB(0,255,0)
                    SB.Color3=Color3.fromRGB(0,255,0)
                else
                    CubePart.Color=col
                    SB.Color3=col
                end
            else
                CubePart.Parent=nil
            end
        end
    end)
end)

-- PENETRATION
task.spawn(function()
    local txt=Drawing.new("Text")
    txt.Visible=false
    txt.Center=true
    txt.Size=18
    txt.Font=2
    txt.Color=Color3.fromRGB(0,255,0)
    txt.Outline=true
    local pp=RaycastParams.new()
    pp.FilterType=Enum.RaycastFilterType.Exclude
    pp.CollisionGroup="Bullet"
    RunService.RenderStepped:Connect(function()
        local sh=Toggles.ShowPenetration and Toggles.ShowPenetration.Value
        if sh and Camera then
            txt.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2-70)
            pp.FilterDescendantsInstances={LP.Character,Camera}
            local res=Workspace:Raycast(Camera.CFrame.Position,Camera.CFrame.LookVector*1000,pp)
            if res then
                local st=GetPenetrationStats(Camera.CFrame.Position,Camera.CFrame.LookVector,4,{LP.Character,Camera},nil)
                if st.Success then
                    txt.Visible=true
                    txt.Text=string.format("WALLBANG: YES\n(%.1f studs)",st.TotalThickness or 0)
                    txt.Color=Color3.fromRGB(0,255,0)
                else
                    txt.Visible=true
                    txt.Text="WALLBANG: NO"
                    txt.Color=Color3.fromRGB(255,0,0)
                end
            else
                txt.Visible=false
            end
        else
            txt.Visible=false
        end
    end)
end)

-- GC HOOKS
local originalFR={}
local frObjs={}
local SendFunc=nil
local getCurrentEquipped=nil

pcall(function()
    for _,obj in next,getgc(true) do
        if type(obj)=="table" and rawget(obj,"FireRate") then
            pcall(function()
                table.insert(originalFR,table.clone(obj))
                table.insert(frObjs,obj)
            end)
        end
        if type(obj)=="table" and rawget(obj,"setWeaponRecoil") then
            pcall(function()
                local old
                old=hookfunction(obj.setWeaponRecoil,function(...)
                    if Toggles.NoRecoil.Value then return end
                    return old(...)
                end)
            end)
        end
        if type(obj)=="function" and debug.getinfo(obj).name=="calculateRecoilOffset" then
            pcall(function()
                local old
                old=hookfunction(obj,function(...)
                    if Toggles.NoRecoil.Value then return UDim2.new() end
                    return old(...)
                end)
            end)
        end
        if type(obj)=="table" and rawget(obj,"weaponKick") then
            pcall(function()
                local old
                old=hookfunction(obj.weaponKick,function(p1,p2)
                    if Toggles.NoRecoil.Value then return end
                    return old(p1,p2)
                end)
            end)
        end
        if type(obj)=="table" and rawget(obj,"getTrueSpread") then
            pcall(function()
                local old
                old=hookfunction(obj.getTrueSpread,function(p1)
                    if Toggles.NoSpread.Value then return 0 end
                    return old(p1)
                end)
            end)
        end
        if type(obj)=="function" and debug.getinfo(obj).name=="Flash" then
            pcall(function()
                local old
                old=hookfunction(obj,function(...)
                    if Toggles.Antiflashbang.Value then return end
                    return old(...)
                end)
            end)
        end
        if type(obj)=="function" and debug.getinfo(obj).name=="CreateVoxel" and debug.getupvalue(obj,1) and tostring(debug.getupvalue(obj,1))=="Smoke" then
            pcall(function()
                local old
                old=hookfunction(obj,function(...)
                    if Toggles.Antismoke.Value then return end
                    return old(...)
                end)
            end)
        end
        if type(obj)=="table" and rawget(obj,"shoot") and typeof(obj.shoot)=="function" then
            pcall(function()
                for _,uv in pairs(debug.getupvalues(obj.shoot)) do
                    if type(uv)=="table" and rawget(uv,"Inventory") and rawget(uv.Inventory,"ShootWeapon") then
                        SendFunc=uv.Inventory.ShootWeapon.Send
                        break
                    end
                end
            end)
        end
        if type(obj)=="table" and rawget(obj,"getCurrentEquipped") then
            pcall(function() getCurrentEquipped=obj.getCurrentEquipped end)
        end
    end
end)

local Weapon=nil
local function getEquipped()
    if not getCurrentEquipped then return nil end
    local ok,res=pcall(function() return debug.getupvalue(getCurrentEquipped,1).CurrentEquipped end)
    if not ok then return nil end
    return res
end
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if getEquipped then Weapon=getEquipped() end
        end)
    end
end)

local HitSoundPresets={}
HitSoundPresets["Neverlose"]="rbxassetid://139452805868562"
HitSoundPresets["Skeet"]="rbxassetid://83717596220569"
HitSoundPresets["Bell"]="rbxassetid://96481309571950"
HitSoundPresets["Bell2"]="rbxassetid://124010691633262"
HitSoundPresets["Bubble"]="rbxassetid://104824514322839"
HitSoundPresets["Rust"]="rbxassetid://1255040462"
HitSoundPresets["Coins"]="rbxassetid://5613553529"
HitSoundPresets["Pick"]="rbxassetid://8616930816"

local function PlayHitSound()
    pcall(function()
        if not (Toggles.HitSoundEnabled and Toggles.HitSoundEnabled.Value) then return end
        local sid=""
        if Toggles.CustomHitSoundToggle and Toggles.CustomHitSoundToggle.Value then
            local ci=Options.CustomHitSoundID and Options.CustomHitSoundID.Value
            if ci and ci~="" then
                if not ci:find("rbxassetid://") then
                    local clean=ci:gsub("%D","")
                    if clean~="" then sid="rbxassetid://"..clean end
                else
                    sid=ci
                end
            end
        end
        if sid=="" then
            sid=HitSoundPresets[Options.HitSoundPreset and Options.HitSoundPreset.Value or "Neverlose"] or "rbxassetid://139452805868562"
        end
        local s=Instance.new("Sound")
        s.SoundId=sid
        s.Volume=Options.HitSoundVolume and Options.HitSoundVolume.Value or 1
        s.Parent=SoundService
        s:Play()
        task.spawn(function()
            s.Ended:Wait()
            s:Destroy()
        end)
    end)
end

local triggerHMEvent=nil
task.spawn(function()
    local active={}
    triggerHMEvent=function(pos)
        if not (Toggles.HitMarkerEnabled and Toggles.HitMarkerEnabled.Value) then return end
        local dur=Options.HitMarkerDuration and Options.HitMarkerDuration.Value or 2
        local thick=Options.HitMarkerThickness and Options.HitMarkerThickness.Value or 2
        local lines={}
        for i=1,4 do
            local l=Drawing.new("Line")
            l.Thickness=thick
            l.Transparency=1
            l.Visible=false
            lines[i]=l
        end
        table.insert(active,{lines=lines,wpos=pos,st=tick(),ex=tick()+dur})
    end
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local now=tick()
            local en=Toggles.HitMarkerEnabled and Toggles.HitMarkerEnabled.Value
            local col=Options.HitMarkerColor and Options.HitMarkerColor.Value or Color3.new(1,1,1)
            if Toggles.HitMarkerRainbow and Toggles.HitMarkerRainbow.Value then
                col=Color3.fromHSV((now%5)/5,1,1)
            end
            local bsz=Options.HitMarkerSize and Options.HitMarkerSize.Value or 25
            local ss=Options.HitMarkerSpinSpeed and Options.HitMarkerSpinSpeed.Value or 720
            local pulse=1+0.35*math.sin(now*math.pi)
            local sz=bsz*pulse
            local gap=6*pulse
            for i=#active,1,-1 do
                local d=active[i]
                if not en or now>d.ex then
                    for _,l in ipairs(d.lines) do pcall(function() l:Remove() end) end
                    table.remove(active,i)
                else
                    local sp,on=Camera:WorldToViewportPoint(d.wpos)
                    if on then
                        local center=Vector2.new(sp.X,sp.Y)
                        local lt=now-d.st
                        local ang=math.rad((lt*ss)%360)
                        local bA={0,90,180,270}
                        for j=1,4 do
                            local l=d.lines[j]
                            l.Color=col
                            l.Thickness=Options.HitMarkerThickness and Options.HitMarkerThickness.Value or 2
                            local a=ang+math.rad(bA[j])
                            local ca=math.cos(a)
                            local sa=math.sin(a)
                            l.From=center+Vector2.new(ca*gap,sa*gap)
                            l.To=center+Vector2.new(ca*(gap+sz),sa*(gap+sz))
                            l.Visible=true
                        end
                    else
                        for _,l in ipairs(d.lines) do l.Visible=false end
                    end
                end
            end
        end)
    end)
end)

local function createTracer(a,b)
    if not (Toggles.BulletTracers and Toggles.BulletTracers.Value) then return end
    if not a or not b then return end
    local st=Options.TracerStyle.Value or "Block"
    local col=Options.BulletTracersColor.Value
    if Toggles.TracerRainbow.Value then
        col=Color3.fromHSV((tick()%5)/5,1,1)
    end
    local dur=Options.TracerTime.Value
    local p=Instance.new("Part")
    p.Name="RH_Tracer"
    if st=="Cylinder (Obelius)" then
        p.Shape=Enum.PartType.Cylinder
        p.Size=Vector3.new((a-b).Magnitude,0.12,0.12)
        p.CFrame=CFrame.new(a,b)*CFrame.new(0,0,-p.Size.X/2)*CFrame.Angles(0,math.rad(90),0)
    else
        p.Size=Vector3.new(0.1,0.1,(a-b).Magnitude)
        p.CFrame=CFrame.new(a,b)*CFrame.new(0,0,-p.Size.Z/2)
    end
    p.Anchored=true
    p.CanCollide=false
    p.CanQuery=false
    p.CanTouch=false
    p.Material=Enum.Material.Neon
    p.Color=col
    p.Transparency=0
    p.CastShadow=false
    p.Parent=Workspace
    task.spawn(function()
        local s0=tick()
        while tick()-s0<dur do
            p.Transparency=(tick()-s0)/dur
            if Toggles.TracerRainbow.Value then
                p.Color=Color3.fromHSV((tick()%5)/5,1,1)
            end
            task.wait()
        end
        p:Destroy()
    end)
end

local function createImpact(pos)
    if not (Toggles.BulletImpacts and Toggles.BulletImpacts.Value) then return end
    if not pos then return end
    local p=Instance.new("Part")
    p.Name="RH_Impact"
    p.Size=Vector3.new(0.6,0.6,0.6)
    p.Position=pos
    p.Anchored=true
    p.CanCollide=false
    p.Material=Enum.Material.Neon
    p.Color=Options.BulletImpactsColor.Value
    p.Transparency=0
    p.Parent=Workspace
    task.spawn(function()
        local s0=tick()
        while tick()-s0<3 do
            p.Transparency=(tick()-s0)/3
            task.wait()
        end
        p:Destroy()
    end)
end

pcall(function()
    if not SendFunc then return end
    local oldshoot=hookfunction(SendFunc,function(...)
        local args={...}
        local cA=cubeActive()
        if args[1] and type(args[1].Bullets)=="table" then
            for _,bullet in pairs(args[1].Bullets) do
                if type(bullet.Hits)=="table" then
                    for _,hd in pairs(bullet.Hits) do
                        local tp=nil
                        if Toggles.Ragebot.Value and RageTarget then
                            tp=RageTarget
                        elseif cA and Toggles.CubeAimbotEnabled.Value and CubeTarget then
                            local chosen=Options.CubeHitPart.Value
                            if CubeTarget.Parent then
                                tp=CubeTarget.Parent:FindFirstChild(chosen) or CubeTarget
                            else
                                tp=CubeTarget
                            end
                        elseif Toggles.SilentAim.Value and SilentTarget then
                            tp=SilentTarget
                        end
                        if tp then
                            hd.Instance=tp
                            hd.Position=tp.Position
                        end
                        pcall(function()
                            if Camera and hd.Position then
                                local a=Camera.CFrame.Position
                                local b=hd.Position
                                createTracer(a,b)
                                createImpact(b)
                                local enemyHit=false
                                if hd.Instance then
                                    local anc=hd.Instance:FindFirstAncestorOfClass("Model")
                                    if anc then
                                        local hp=Players:GetPlayerFromCharacter(anc)
                                        if hp and hp~=LP and getTeam(hp)~=getTeam(LP) then
                                            enemyHit=true
                                        end
                                    end
                                end
                                if enemyHit or tp then
                                    PlayHitSound()
                                    if triggerHMEvent then
                                        pcall(function() triggerHMEvent(b) end)
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

task.spawn(function()
    while true do
        task.wait(Options.RageDelay and Options.RageDelay.Value or 0.02)
        if Toggles.Ragebot.Value and RageTarget and Weapon and Weapon.IsEquipped and Weapon.Rounds>0 then
            pcall(function() Weapon:shoot() end)
        end
    end
end)

task.spawn(function()
    local trp=RaycastParams.new()
    trp.FilterType=Enum.RaycastFilterType.Exclude
    trp.IgnoreWater=true
    while true do
        task.wait(Options.CubeTriggerbotDelay and Options.CubeTriggerbotDelay.Value or 0.01)
        pcall(function()
            local cA=cubeActive()
            if cA and Toggles.CubeTriggerbot.Value then
                local sh=false
                trp.FilterDescendantsInstances={LP.Character}
                local res=Workspace:Raycast(Camera.CFrame.Position,Camera.CFrame.LookVector*1000,trp)
                if res and res.Instance then
                    local ch=res.Instance:FindFirstAncestorOfClass("Model")
                    if ch then
                        local p=Players:GetPlayerFromCharacter(ch)
                        if p and p~=LP then
                            local _,on=Camera:WorldToViewportPoint(res.Instance.Position)
                            if on and not ch:GetAttribute("Dead") and not ch:GetAttribute("Invincible") then
                                if getTeam(LP)~=getTeam(p) then sh=true end
                            end
                        end
                    end
                end
                if not sh and CubeTarget and CubeTarget.Parent then
                    local _,on=Camera:WorldToViewportPoint(CubeTarget.Position)
                    if on then
                        local cl=Camera.CFrame.LookVector
                        local tt=(CubeTarget.Position-Camera.CFrame.Position).Unit
                        if cl:Dot(tt)>0.88 then
                            local ch=CubeTarget.Parent
                            if ch and ch:IsA("Model") then
                                local dead=ch:GetAttribute("Dead") or ch:GetAttribute("Invincible")
                                local hp=ch:GetAttribute("Health")
                                if not dead and (hp==nil or hp>0) and isEnemy(ch) then sh=true end
                            end
                        end
                    end
                end
                if sh and Weapon then pcall(function() Weapon:shoot() end) end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if Toggles.Firerate.Value then
                for _,obj in next,frObjs do
                    pcall(function()
                        setreadonly(obj,false)
                        rawset(obj,"FireRate",math.max(Options.FirerateSlider.Value,0.01))
                        setreadonly(obj,true)
                    end)
                end
            else
                for i,obj in next,frObjs do
                    pcall(function()
                        setreadonly(obj,false)
                        rawset(obj,"FireRate",originalFR[i].FireRate)
                        setreadonly(obj,true)
                    end)
                end
            end
        end)
    end
end)

task.spawn(function()
    local RELOAD={Reload=true,ReloadStart=true,ReloadAction=true,ReloadEnd=true}
    local SPEED=199
    local hooked={}
    local function hookAnim(a)
        if not a or hooked[a] then return end
        hooked[a]=true
        pcall(function()
            local op=a.play
            a.play=function(self,name,...)
                local tr=op(self,name,...)
                if tr and RELOAD[name] then
                    task.defer(function()
                        pcall(function()
                            if Toggles.InstantReload and Toggles.InstantReload.Value and tr.IsPlaying then
                                tr:AdjustSpeed(SPEED)
                            end
                        end)
                    end)
                end
                return tr
            end
        end)
    end
    local lastW=nil
    while task.wait(0.1) do
        pcall(function()
            if not getEquipped then return end
            local w=getEquipped()
            if not w then return end
            if w~=lastW then
                lastW=w
                if w.Viewmodel and w.Viewmodel.Animation then hookAnim(w.Viewmodel.Animation) end
                if w.CharacterAnimator then hookAnim(w.CharacterAnimator) end
            end
            if not (Toggles.InstantReload and Toggles.InstantReload.Value) then return end
            if w.IsReloading then
                pcall(function()
                    if w.Viewmodel and w.Viewmodel.Animation and w.Viewmodel.Animation.Animations then
                        for name,tr in pairs(w.Viewmodel.Animation.Animations) do
                            if RELOAD[name] and tr.IsPlaying then tr:AdjustSpeed(SPEED) end
                        end
                    end
                    if w.CharacterAnimator and w.CharacterAnimator.Animations then
                        for name,tr in pairs(w.CharacterAnimator.Animations) do
                            if RELOAD[name] and tr.IsPlaying then tr:AdjustSpeed(SPEED) end
                        end
                    end
                end)
            end
        end)
    end
end)

-- WEAPON CHAMS
local activeNeon={}
RunService.RenderStepped:Connect(function()
    pcall(function()
        local en=Toggles.WeaponChamsEnabled and Toggles.WeaponChamsEnabled.Value
        local mode=Options.WeaponChamsMode and Options.WeaponChamsMode.Value or "Glass"
        local color=Options.WeaponChamsColor and Options.WeaponChamsColor.Value or Color3.fromRGB(0,150,255)
        local wm=nil
        for _,ch in ipairs(Camera:GetChildren()) do
            if ch:IsA("Model") and ch.Name~="Viewmodel" and not ch.Name:lower():find("light") then
                local w=ch:FindFirstChild("Weapon") or ch
                if w:IsA("Model") and w.Name~="Viewmodel" and not w.Name:lower():find("light") then
                    wm=w
                    break
                end
            end
        end
        if not en or not wm then
            for _,h in pairs(activeNeon) do
                if h and h.Parent then h:Destroy() end
            end
            activeNeon={}
            return
        end
        local cur={}
        for _,part in ipairs(wm:GetDescendants()) do
            if part:IsA("BasePart") and part.Name~="Hitbox" and part.Name~="HumanoidRootPart" then
                pcall(function()
                    if mode=="Highlight" then
                        cur[part]=true
                        local h=part:FindFirstChild("RH_WeaponChamsHL")
                        if not h then
                            h=Instance.new("Highlight")
                            h.Name="RH_WeaponChamsHL"
                            h.Adornee=part
                            h.Parent=part
                            h.FillTransparency=0
                            h.OutlineTransparency=1
                            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                            table.insert(activeNeon,h)
                        end
                        h.FillColor=color
                    else
                        local h=part:FindFirstChild("RH_WeaponChamsHL")
                        if h then h:Destroy() end
                        if mode~="Neon" then
                            for _,v in ipairs(part:GetChildren()) do
                                if v:IsA("SurfaceAppearance") or v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
                            end
                        end
                        if mode=="Glass" then
                            part.Material=Enum.Material.Glass
                            part.Color=color
                            part.Transparency=Options.GlassTransparency and Options.GlassTransparency.Value or 0.4
                        elseif mode=="ForceField" then
                            part.Material=Enum.Material.ForceField
                            part.Color=color
                            part.Transparency=0
                        elseif mode=="Metal" then
                            part.Material=Enum.Material.Metal
                            part.Color=color
                            part.Reflectance=Options.MetalReflectance and Options.MetalReflectance.Value or 1
                            part.Transparency=0
                        elseif mode=="Neon" then
                            part.Material=Enum.Material.Neon
                            part.Color=color
                            part.Transparency=0
                            for _,v in ipairs(part:GetChildren()) do
                                if v:IsA("SurfaceAppearance") or v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
                            end
                        end
                    end
                end)
            end
        end
        if mode=="Highlight" then
            for i=#activeNeon,1,-1 do
                local h=activeNeon[i]
                if not h or not h.Parent or not cur[h.Adornee] then
                    if h then h:Destroy() end
                    table.remove(activeNeon,i)
                end
            end
        end
    end)
end)

-- CUSTOM HANDS
RunService.RenderStepped:Connect(function()
    pcall(function()
        if not (Toggles.CustomHandsEnabled and Toggles.CustomHandsEnabled.Value) then return end
        local xO=Options.HandsX and Options.HandsX.Value or 0.2
        local yO=Options.HandsY and Options.HandsY.Value or -0.155
        local zO=Options.HandsZ and Options.HandsZ.Value or 0.075
        for _,ch in ipairs(Camera:GetChildren()) do
            if ch:IsA("Model") then
                local s=ch:FindFirstChild("Stats")
                if s then
                    local d=s:FindFirstChild("Default")
                    if d and d:IsA("Vector3Value") then
                        d.Value=Vector3.new(xO,yO,zO)
                    end
                end
            end
        end
    end)
end)

-- CUSTOM FOV + THIRD PERSON
RunService.RenderStepped:Connect(function()
    pcall(function()
        if Toggles.CustomFovToggle and Toggles.CustomFovToggle.Value then
            Camera.FieldOfView=Options.FovAmount and Options.FovAmount.Value or 90
        end
        if Toggles.ThirdPerson and Toggles.ThirdPerson.Value then
            local d=Options.ThirdPersonDist and Options.ThirdPersonDist.Value or 10
            d=math.clamp(d,5,50)
            LP.CameraMode=Enum.CameraMode.Classic
            LP.CameraMaxZoomDistance=d
            LP.CameraMinZoomDistance=d
        end
    end)
end)

-- CHAMS
task.spawn(function()
    local folder
    pcall(function()
        folder=Instance.new("Folder",CoreGui)
        folder.Name="RH_Chams"
    end)
    local HL={}
    local function getM(s)
        if s=="Metal" then return Enum.Material.Metal end
        if s=="ForceField" then return Enum.Material.ForceField end
        if s=="SmoothPlastic" then return Enum.Material.SmoothPlastic end
        return Enum.Material.Neon
    end
    local function remCh(c)
        if HL[c] then
            pcall(function() HL[c].v:Destroy() end)
            pcall(function() HL[c].u:Destroy() end)
            HL[c]=nil
        end
    end
    local RP=RaycastParams.new()
    RP.FilterType=Enum.RaycastFilterType.Exclude
    local function isVis(c)
        local r=c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
        if not r then return false end
        local cp=Workspace.CurrentCamera.CFrame.Position
        local dir=r.Position-cp
        RP.FilterDescendantsInstances={LP.Character,c}
        return Workspace:Raycast(cp,dir,RP)==nil
    end
    RunService.RenderStepped:Connect(function()
        local en=Toggles.ChamsEnabled.Value
        local tchk=Toggles.ChamsTeamCheck.Value
        local mV=getM(Options.ChamsMaterialVisible.Value)
        local mU=getM(Options.ChamsMaterialUnvisible.Value)
        local cV=Options.ChamsColorVisible.Value
        local cU=Options.ChamsColorUnvisible.Value
        local fAV=Options.ChamsAlphaVisible.Value
        local fAU=Options.ChamsAlphaUnvisible.Value
        local oAV=Options.ChamsOutlineAlphaVisible.Value
        local oAU=Options.ChamsOutlineAlphaUnvisible.Value
        local cf=Workspace:FindFirstChild("Characters")
        if not cf then return end
        local enemies={}
        for _,obj in ipairs(cf:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj~=LP.Character then
                if tchk and isAlly(obj) then
                    remCh(obj)
                elseif not en then
                    remCh(obj)
                else
                    table.insert(enemies,obj)
                end
            end
        end
        for _,ch in ipairs(enemies) do
            if not HL[ch] then
                local hv=Instance.new("Highlight")
                hv.DepthMode=Enum.HighlightDepthMode.Occluded
                hv.Parent=folder
                local hu=Instance.new("Highlight")
                hu.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                hu.Parent=folder
                HL[ch]={v=hv,u=hu}
                ch.AncestryChanged:Connect(function(_,p)
                    if p==nil then remCh(ch) end
                end)
            end
            local hl=HL[ch]
            local seen=isVis(ch)
            hl.v.Adornee=ch
            hl.v.FillColor=cV
            hl.v.OutlineColor=cV
            hl.v.FillTransparency=fAV
            hl.v.OutlineTransparency=oAV
            hl.v.Enabled=seen
            hl.u.Adornee=ch
            hl.u.FillColor=cU
            hl.u.OutlineColor=cU
            hl.u.FillTransparency=fAU
            hl.u.OutlineTransparency=oAU
            hl.u.Enabled=not seen
            local tM=seen and mV or mU
            local tC=seen and cV or cU
            for _,part in ipairs(ch:GetDescendants()) do
                pcall(function()
                    if part:IsA("SurfaceAppearance") or part:IsA("Decal") or part:IsA("Texture") then
                        part:Destroy()
                    elseif part:IsA("MeshPart") and part.TextureID~="" then
                        part.TextureID=""
                    elseif part:IsA("SpecialMesh") and part.TextureId~="" then
                        part.TextureId=""
                    end
                    if part:IsA("BasePart") then
                        if not part:GetAttribute("OrigMat") then
                            part:SetAttribute("OrigMat",part.Material.Name)
                            part:SetAttribute("OrigColor",part.Color)
                        end
                        part.Material=tM
                        part.Color=tC
                    end
                end)
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if p.Character then remCh(p.Character) end
    end)
end)

-- SCOPE CROSSHAIR GUI
task.spawn(function()
    local gui=Instance.new("ScreenGui")
    gui.Name="RH_Scope"
    gui.ResetOnSpawn=false
    pcall(function() gui.Parent=CoreGui end)
    local container=Instance.new("Frame",gui)
    container.BackgroundTransparency=1
    container.AnchorPoint=Vector2.new(0.5,0.5)
    container.Position=UDim2.new(0.5,0,0.5,0)
    container.Size=UDim2.new(0,0,0,0)
    local function mk(ap)
        local f=Instance.new("Frame",container)
        f.AnchorPoint=ap
        f.BorderSizePixel=0
        return f
    end
    local l=mk(Vector2.new(1,0.5))
    local r=mk(Vector2.new(0,0.5))
    local t=mk(Vector2.new(0.5,1))
    local b=mk(Vector2.new(0.5,0))
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local scoped=false
            local pg=LP:FindFirstChild("PlayerGui")
            if pg then
                local s,sc=pcall(function() return pg.MainGui.Gameplay.Middle.SniperScope end)
                if s and sc and sc.Visible then scoped=true end
            end
            local en=Toggles.CustomScopeCrosshair and Toggles.CustomScopeCrosshair.Value and scoped
            container.Visible=en
            if en then
                local col=Options.ScopeCrosshairColor and Options.ScopeCrosshairColor.Value or Color3.new(1,1,1)
                l.BackgroundColor3=col
                r.BackgroundColor3=col
                t.BackgroundColor3=col
                b.BackgroundColor3=col
                local th=Options.ScopeCrosshairThickness and Options.ScopeCrosshairThickness.Value or 2
                local lr=Options.ScopeCrosshairLengthLR and Options.ScopeCrosshairLengthLR.Value or 150
                local tb=Options.ScopeCrosshairLengthTB and Options.ScopeCrosshairLengthTB.Value or 100
                l.Size=UDim2.new(0,lr,0,th)
                r.Size=UDim2.new(0,lr,0,th)
                t.Size=UDim2.new(0,th,0,tb)
                b.Size=UDim2.new(0,th,0,tb)
            end
        end)
    end)
end)

-- REMOVE SCOPE
task.spawn(function()
    local cached=nil
    RunService.RenderStepped:Connect(function()
        if cached and not cached.Parent then cached=nil end
        if not cached then
            local pg=LP:FindFirstChild("PlayerGui")
            if pg then
                local s,sc=pcall(function() return pg.MainGui.Gameplay.Middle.SniperScope end)
                if s and sc then cached=sc end
            end
        end
        if not cached then return end
        if not (Toggles.RemoveScope and Toggles.RemoveScope.Value) then
            if cached.Size~=UDim2.new(1,0,1,0) then cached.Size=UDim2.new(1,0,1,0) end
            return
        end
        if cached.Visible==true then
            cached.Size=UDim2.new(0,0,0,0)
        else
            if cached.Size~=UDim2.new(1,0,1,0) then cached.Size=UDim2.new(1,0,1,0) end
        end
    end)
end)

-- CUSTOM SCOPE FOV
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        pcall(function()
            if not (Toggles.CustomScopeFov and Toggles.CustomScopeFov.Value) then return end
            local pg=LP:FindFirstChild("PlayerGui")
            if not pg then return end
            local sc=pg:FindFirstChild("MainGui")
            if sc then sc=sc:FindFirstChild("Gameplay") end
            if sc then sc=sc:FindFirstChild("Middle") end
            if sc then sc=sc:FindFirstChild("SniperScope") end
            if sc and sc.Visible and Options.ScopeFovValue then
                Camera.FieldOfView=Options.ScopeFovValue.Value
            end
        end)
    end)
end)

-- SKYBOX
local skyTbl={}
skyTbl["Night"]={SkyboxBk="rbxassetid://1514717643",SkyboxDn="rbxassetid://1514716936",SkyboxFt="rbxassetid://1514715910",SkyboxLf="rbxassetid://1514714945",SkyboxRt="rbxassetid://1514714011",SkyboxUp="rbxassetid://1514713374"}
skyTbl["Ocean Sunset"]={SkyboxBk="rbxassetid://17525686840",SkyboxDn="rbxassetid://17525678473",SkyboxFt="rbxassetid://17525684686",SkyboxLf="rbxassetid://17525680663",SkyboxRt="rbxassetid://17525682665",SkyboxUp="rbxassetid://17525674545"}
skyTbl["Deep Space"]={SkyboxBk="http://www.roblox.com/asset/?id=159248188",SkyboxDn="http://www.roblox.com/asset/?id=159248183",SkyboxFt="http://www.roblox.com/asset/?id=159248187",SkyboxLf="http://www.roblox.com/asset/?id=159248173",SkyboxRt="http://www.roblox.com/asset/?id=159248192",SkyboxUp="http://www.roblox.com/asset/?id=159248176"}
skyTbl["Purple Nebula"]={SkyboxBk="http://www.roblox.com/asset/?id=15983968922",SkyboxDn="http://www.roblox.com/asset/?id=15983966825",SkyboxFt="http://www.roblox.com/asset/?id=15983965025",SkyboxLf="http://www.roblox.com/asset/?id=15983967420",SkyboxRt="http://www.roblox.com/asset/?id=15983966246",SkyboxUp="http://www.roblox.com/asset/?id=15983964246"}
skyTbl["Minecraft"]={SkyboxBk="http://www.roblox.com/asset/?id=8735166756",SkyboxDn="http://www.roblox.com/asset/?id=8735166707",SkyboxFt="http://www.roblox.com/asset/?id=8735231668",SkyboxLf="http://www.roblox.com/asset/?id=8735166755",SkyboxRt="http://www.roblox.com/asset/?id=8735166751",SkyboxUp="http://www.roblox.com/asset/?id=8735166729"}
skyTbl["Retro"]={SkyboxBk="rbxasset://sky/null_plainsky512_bk.jpg",SkyboxDn="rbxasset://sky/null_plainsky512_dn.jpg",SkyboxFt="rbxasset://sky/null_plainsky512_ft.jpg",SkyboxLf="rbxasset://sky/null_plainsky512_lf.jpg",SkyboxRt="rbxasset://sky/null_plainsky512_rt.jpg",SkyboxUp="rbxasset://sky/null_plainsky512_up.jpg"}

local function UpdateSky(name)
    local data=skyTbl[name]
    if not data then return end
    for _,v in pairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("Clouds") then v:Destroy() end
    end
    local sky=Lighting:FindFirstChild("RH_Sky")
    if not sky then
        for _,v in pairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
        sky=Instance.new("Sky")
        sky.Name="RH_Sky"
        sky.Parent=Lighting
    end
    sky.SkyboxBk=data.SkyboxBk
    sky.SkyboxDn=data.SkyboxDn
    sky.SkyboxFt=data.SkyboxFt
    sky.SkyboxLf=data.SkyboxLf
    sky.SkyboxRt=data.SkyboxRt
    sky.SkyboxUp=data.SkyboxUp
    sky.SunTextureId=""
    sky.MoonTextureId=""
    sky.StarCount=0
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if Toggles.EnableSkybox and Toggles.EnableSkybox.Value then
                UpdateSky(Options.SkyboxPreset and Options.SkyboxPreset.Value or "Night")
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if Toggles.Atmosphere and Toggles.Atmosphere.Value then
                if Toggles.EnableSkybox and Toggles.EnableSkybox.Value then
                    Toggles.EnableSkybox:SetValue(false)
                end
                local a=Lighting:FindFirstChildOfClass("Atmosphere")
                if not a then a=Instance.new("Atmosphere",Lighting) end
                a.Density=Options.AtmosphereDensity and Options.AtmosphereDensity.Value or 0.3
                a.Haze=Options.AtmosphereHaze and Options.AtmosphereHaze.Value or 0
                a.Glare=Options.AtmosphereGlare and Options.AtmosphereGlare.Value or 0
            else
                local a=Lighting:FindFirstChildOfClass("Atmosphere")
                if a and not (Toggles.EnableSkybox and Toggles.EnableSkybox.Value) then a:Destroy() end
            end
        end)
    end
end)

-- GRENADE TRACERS
local TrackedGrenades={}
local GPat={"grenade","flash","molotov","bang","frag","he_","_he","throwable","projectile","nade","incendiary","decoy","c4"}
local GBlack={"gun","rifle","pistol","bullet","casing","debris","light","muzzle","launch","effect","arm","leg","torso","head","humanoid","mesh","handle","constraint","weld","motor","zone","voxel"}

local function isGrenade(obj)
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    local n=obj.Name:lower()
    for _,p in ipairs(GBlack) do
        if n:find(p) then return false end
    end
    if #n>20 and n:find("%-") then return true end
    for _,p in ipairs(GPat) do
        if n:find(p) then return true end
    end
    return false
end

local function StartGT(part)
    if not part or not part:IsA("BasePart") then return end
    if TrackedGrenades[part] then return end
    TrackedGrenades[part]=true
    local MAXT=30
    local hist={}
    local lines={}
    for i=1,MAXT do
        local l=Drawing.new("Line")
        l.Visible=false
        l.Thickness=2
        l.Transparency=1
        lines[i]=l
    end
    local conn
    conn=RunService.RenderStepped:Connect(function()
        if not (Toggles.GrenadeTracers and Toggles.GrenadeTracers.Value) then
            for _,l in ipairs(lines) do l.Visible=false end
            return
        end
        if not part or not part.Parent then
            conn:Disconnect()
            TrackedGrenades[part]=nil
            for _,l in ipairs(lines) do pcall(function() l:Remove() end) end
            return
        end
        local col=Options.GrenadeTracerColor.Value
        table.insert(hist,1,part.Position)
        if #hist>MAXT+1 then table.remove(hist) end
        for i=1,MAXT do
            local l=lines[i]
            local p1=hist[i]
            local p2=hist[i+1]
            if not p1 or not p2 then
                l.Visible=false
            else
                local s1,o1=Camera:WorldToViewportPoint(p1)
                local s2,o2=Camera:WorldToViewportPoint(p2)
                if (o1 or o2) and s1.Z>0 and s2.Z>0 then
                    local fade=1-(i/MAXT)
                    l.From=Vector2.new(s1.X,s1.Y)
                    l.To=Vector2.new(s2.X,s2.Y)
                    l.Color=col
                    l.Thickness=math.max(2*fade,0.5)
                    l.Transparency=1-fade
                    l.Visible=true
                else
                    l.Visible=false
                end
            end
        end
    end)
end

local function TryTrack(obj)
    if TrackedGrenades[obj] then return end
    local part=obj
    if obj:IsA("Model") then
        part=obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
    end
    if not part or not part:IsA("BasePart") then return end
    if part.Size.Magnitude>8 then return end
    if Players:GetPlayerFromCharacter(obj) then return end
    if Players:GetPlayerFromCharacter(obj.Parent) then return end
    TrackedGrenades[obj]=true
    obj.AncestryChanged:Connect(function(_,p)
        if p==nil then TrackedGrenades[obj]=nil end
    end)
    StartGT(part)
end

task.spawn(function()
    task.wait(0.5)
    for _,c in ipairs(Workspace:GetChildren()) do
        if isGrenade(c) then TryTrack(c) end
    end
    Workspace.ChildAdded:Connect(function(c)
        task.wait()
        if isGrenade(c) then TryTrack(c) end
        c.ChildAdded:Connect(function(s)
            task.wait()
            if isGrenade(s) then TryTrack(s) end
        end)
    end)
end)

-- SKIN CHANGER
task.spawn(function()
    pcall(function()
        local skins=RS:FindFirstChild("Assets")
        if not skins then return end
        skins=skins:FindFirstChild("Skins")
        if not skins then return end
        local skM=RS:FindFirstChild("Database")
        if skM then skM=skM:FindFirstChild("Components") end
        if skM then skM=skM:FindFirstChild("Libraries") end
        if skM then skM=skM:FindFirstChild("Skins") end
        local vM=RS:FindFirstChild("Classes")
        if vM then vM=vM:FindFirstChild("WeaponComponent") end
        if vM then vM=vM:FindFirstChild("Classes") end
        if vM then vM=vM:FindFirstChild("Viewmodel") end
        if not skM or not vM then return end
        local Sk=require(skM)
        local Vm=require(vM)
        local baseKnives={}
        baseKnives["CT Knife"]=true
        baseKnives["T Knife"]=true
        baseKnives["Knife"]=true
        local function isKnife(w)
            if baseKnives[w] then return true end
            return false
        end
        local oGCM=Sk.GetCameraModel
        if oGCM then
            Sk.GetCameraModel=function(w,sk,...)
                if Toggles.KnifeChangerToggle and Toggles.KnifeChangerToggle.Value and w and isKnife(w) then
                    local nk=Options.KnifeModel and Options.KnifeModel.Value or "Skeleton Knife"
                    local s,r=pcall(oGCM,nk,"Vanilla",...)
                    if s and r then return r end
                end
                return oGCM(w,sk,...)
            end
        end
        local oVN=Vm.new
        if oVN then
            Vm.new=function(vc,w,sk,...)
                if Toggles.KnifeChangerToggle and Toggles.KnifeChangerToggle.Value and w and isKnife(w) then
                    local nk=Options.KnifeModel and Options.KnifeModel.Value or "Skeleton Knife"
                    local s,r=pcall(oVN,vc,nk,"Vanilla",...)
                    if s and r then return r end
                end
                return oVN(vc,w,sk,...)
            end
        end
    end)
end)

Notification:Notify({Title="RAINBOW HUB",Content="BloxStrike loaded. Key: Insert",Icon="clipboard"})
print("[RAINBOW HUB] BloxStrike loaded successfully")
