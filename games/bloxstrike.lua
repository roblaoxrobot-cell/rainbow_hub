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
    local ok,F=pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
    end)
    if not ok or not F then warn("[RH] Fatality load failed") return nil end
    return F
end

local function keyMatches(input,key)
    if key==nil then return false end
    if typeof(key)=="EnumItem" then return input.KeyCode==key end
    return input.KeyCode.Name==tostring(key)
end

-- HELPERS
local function getTeam(p)
    if not p then return nil end
    if p.Team then return p.Team.Name end
    return nil
end

local function getHum(c)
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

local function isAlive(c)
    local h=getHum(c)
    if not h then return false end
    return h.Health>0
end

local function isEnemy(p)
    if not p or p==LP then return false end
    local a=getTeam(LP)
    local b=getTeam(p)
    if a and b then return a~=b end
    return true
end

local function lerpC(a,b,t)
    return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t)
end

-- MIRROR
local Toggles={}
local Options={}

local function mirrorToggle(name,def)
    local t={Value=def or false}
    Toggles[name]=t
    return t
end

local function mirrorOption(name,def)
    local o={Value=def}
    Options[name]=o
    return o
end

-- WINDOW
local F=GetFatality()
if not F then return end
if getgenv().RH_Loaded then warn("[RH] already loaded. Run: getgenv().RH_Loaded=nil") return end
getgenv().RH_Loaded=true

local Notification=F:CreateNotifier()
F:Loader({Name="Rainbow Hub",Duration=3})
Notification:Notify({Title="RAINBOW HUB",Content="Welcome, "..LP.DisplayName,Icon="clipboard"})

local Window=F.new({Name="Rainbow Hub",Expire="BloxStrike",Keybind="NONE"})
local Config=Window:AddConfig()
pcall(function() Config:Init("Hub_BloxStrike","HubConfigs") end)

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
local MiscMenu=Window:AddMenu({Name="Misc",Icon="cog"})
local SetMenu=Window:AddMenu({Name="Settings",Icon="cog"})

-- UI WRAPPERS (простыe)
local function AddToggle(section,name,opts)
    opts=opts or {}
    local m=mirrorToggle(name,opts.Default or false)
    section:AddToggle({
        Name=opts.Text or name,
        Flag="RHT_"..name,
        Default=opts.Default or false,
        Callback=function(v)
            m.Value=v
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
            if opts.Callback then pcall(opts.Callback,v) end
        end
    })
    return m
end

local function AddButton(section,name,cb)
    section:AddButton({Name=name,Callback=cb})
end

-- SETTINGS TAB
do
    local A=SetMenu:AddSection({Position='left',Name="MENU"})
    AddKeybind(A,"MenuKeybind",{Text="Menu Keybind",Default=Enum.KeyCode.Insert,
        Callback=function(v) if v~=nil then getgenv().RH_MenuKey=v end end})
    AddButton(A,"Reset Loaded Flag",function() getgenv().RH_Loaded=nil end)
    AddButton(A,"Unload Window",function() pcall(function() Window:SetVisible(false) end) end)
end

-- MISC TAB
do
    local A=MiscMenu:AddSection({Position='left',Name="MOVEMENT"})
    AddToggle(A,"AutoBhop",{Text="Auto Bhop",Default=false})
    AddSlider(A,"BhopSpeed",{Text="Bhop Speed",Default=18,Min=5,Max=30,Rounding=1})
    AddToggle(A,"NoFallDamage",{Text="No Fall Damage",Default=false})
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        if Toggles.AutoBhop and Toggles.AutoBhop.Value then
            local char=LP.Character
            if not char then return end
            local rp=char:FindFirstChild("HumanoidRootPart")
            local hum=char:FindFirstChildOfClass("Humanoid")
            if not rp or not hum then return end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                local rp2=RaycastParams.new()
                rp2.FilterDescendantsInstances={char}
                rp2.FilterType=Enum.RaycastFilterType.Exclude
                if Workspace:Raycast(rp.Position,Vector3.new(0,-4,0),rp2) then
                    hum.Jump=true
                end
            end
            local dir=Vector3.zero
            local lv=Camera.CFrame.LookVector
            local rv=Camera.CFrame.RightVector
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+lv end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-lv end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-rv end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+rv end
            local flat=Vector3.new(dir.X,0,dir.Z)
            if flat.Magnitude>0 then
                local spd=18
                if Options.BhopSpeed then spd=Options.BhopSpeed.Value end
                spd=math.clamp(spd,5,30)
                local t=flat.Unit*spd
                local v=rp.AssemblyLinearVelocity
                rp.AssemblyLinearVelocity=Vector3.new(v.X+(t.X-v.X)*0.2,v.Y,v.Z+(t.Z-v.Z)*0.2)
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

-- COMBAT TAB
do
    local A=CombatMenu:AddSection({Position='left',Name="SILENT AIM"})
    AddToggle(A,"SilentAim",{Text="Enable Silent Aim",Default=false})
    AddToggle(A,"SilentTeamCheck",{Text="Team Check",Default=true})
    AddToggle(A,"SilentWallbang",{Text="Wallbang",Default=false})
    AddToggle(A,"SilentUseFovCircle",{Text="Use FOV Circle",Default=false})

    local B=CombatMenu:AddSection({Position='left',Name="SILENT SETTINGS"})
    AddSlider(B,"SilentFovCircleRadius",{Text="FOV Radius",Default=120,Min=10,Max=500,Rounding=0})
    AddColor(B,"SilentFovColor",{Default=Color3.fromRGB(255,0,0),Title="FOV Color"})
    AddDropdown(B,"SilentHitPart",{Text="Hit Part",
        Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
        Default="Head"})

    local C=CombatMenu:AddSection({Position='center',Name="RAGEBOT"})
    AddToggle(C,"Ragebot",{Text="Enable Ragebot",Default=false})
    AddToggle(C,"RagebotVisibleCheck",{Text="Visible Check",Default=true})
    AddToggle(C,"RagebotTeamCheck",{Text="Team Check",Default=true})
    AddToggle(C,"RagebotWallCheck",{Text="Wall Check",Default=false})

    local D=CombatMenu:AddSection({Position='center',Name="RAGE SETTINGS"})
    AddSlider(D,"RageDelay",{Text="Delay",Default=0.05,Min=0,Max=1,Rounding=3})
    AddDropdown(D,"RageHitPart",{Text="Hit Part",
        Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
        Default="Head"})

    local E=CombatMenu:AddSection({Position='right',Name="CUBE MODE"})
    AddToggle(E,"CubeModeMainToggle",{Text="Cube Mode",Default=false})
    AddToggle(E,"CubeVisibleCheck",{Text="Visible Check",Default=false})
    AddDropdown(E,"CubeHitPart",{Text="Hit Part",
        Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
        Default="Head"})
end

-- VISUALS TAB
do
    local A=VisualsMenu:AddSection({Position='left',Name="ESP MAIN"})
    AddToggle(A,"ESPEnabled",{Text="ESP Enabled",Default=false})
    AddToggle(A,"ESPTeamCheck",{Text="Team Check",Default=true})
    AddDropdown(A,"ESPBoxType",{Text="Box ESP",
        Values={"2D Box","Corner Box","Disabled"},
        Default="2D Box"})
    AddToggle(A,"ESPBoxFillGradient",{Text="Fill Gradient",Default=false})

    local B=VisualsMenu:AddSection({Position='left',Name="BOX COLOR"})
    AddColor(B,"ESPBoxColorA",{Default=Color3.new(1,1,1),Title="Box A"})
    AddColor(B,"ESPBoxColorB",{Default=Color3.fromRGB(0,200,255),Title="Box B"})
    AddColor(B,"ESPFillColorA",{Default=Color3.fromRGB(255,50,50),Title="Fill A"})
    AddColor(B,"ESPFillColorB",{Default=Color3.fromRGB(50,50,255),Title="Fill B"})

    local C=VisualsMenu:AddSection({Position='center',Name="ESP ITEMS"})
    AddToggle(C,"ESPName",{Text="Name",Default=false})
    AddToggle(C,"ESPDistance",{Text="Distance",Default=false})
    AddToggle(C,"ESPHealth",{Text="Health Bar",Default=false})
    AddToggle(C,"ESPHealthText",{Text="Health Text",Default=false})
    AddToggle(C,"ESPSkeleton",{Text="Skeleton",Default=false})
    AddToggle(C,"ESPTracer",{Text="Tracer",Default=false})
    AddToggle(C,"ESPWeapon",{Text="Weapon Name",Default=false})

    local D=VisualsMenu:AddSection({Position='center',Name="COLORS A"})
    AddColor(D,"ESPNameColor",{Default=Color3.new(1,1,1),Title="Name Color"})
    AddColor(D,"ESPDistanceColor",{Default=Color3.new(1,1,1),Title="Distance Color"})
    AddColor(D,"ESPHealthTopColor",{Default=Color3.fromRGB(0,255,0),Title="Health Top"})
    AddColor(D,"ESPHealthBottomColor",{Default=Color3.fromRGB(255,0,0),Title="Health Bottom"})
    AddColor(D,"ESPHealthTextColor",{Default=Color3.new(1,1,1),Title="HP Text"})

    local E=VisualsMenu:AddSection({Position='right',Name="COLORS B"})
    AddColor(E,"ESPTracerColor",{Default=Color3.new(1,1,1),Title="Tracer A"})
    AddColor(E,"ESPTracerColorB",{Default=Color3.fromRGB(255,0,128),Title="Tracer B"})
    AddColor(E,"ESPSkeletonColorA",{Default=Color3.new(1,1,1),Title="Skel A"})
    AddColor(E,"ESPSkeletonColorB",{Default=Color3.fromRGB(0,255,255),Title="Skel B"})
    AddColor(E,"ESPWeaponColor",{Default=Color3.new(1,1,1),Title="Weapon Color"})

    local F1=VisualsMenu:AddSection({Position='right',Name="TRACER ORIGIN"})
    AddDropdown(F1,"ESPTracerOrigin",{Text="Origin",
        Values={"Bottom","Top","Center","Mouse"},
        Default="Bottom"})
end

-- WORLD TAB
do
    local A=WorldMenu:AddSection({Position='left',Name="BULLET TRACERS"})
    AddToggle(A,"BulletTracers",{Text="Enable",Default=false})
    AddColor(A,"BulletTracersColor",{Default=Color3.fromRGB(0,170,255),Title="Color"})
    AddToggle(A,"TracerRainbow",{Text="Rainbow",Default=false})
    AddSlider(A,"TracerTime",{Text="Time",Default=2,Min=0.1,Max=10,Rounding=1})
    AddToggle(A,"BulletImpacts",{Text="Impacts",Default=false})
    AddColor(A,"BulletImpactsColor",{Default=Color3.fromRGB(255,0,0),Title="Impact Color"})

    local B=WorldMenu:AddSection({Position='center',Name="HIT SOUND"})
    AddToggle(B,"HitSoundEnabled",{Text="Enable",Default=false})
    AddSlider(B,"HitSoundVolume",{Text="Volume",Default=1,Min=0.1,Max=5,Rounding=1})
    AddDropdown(B,"HitSoundPreset",{Text="Preset",
        Values={"Neverlose","Skeet","Bell","Coins","Pick"},
        Default="Neverlose"})

    local C=WorldMenu:AddSection({Position='right',Name="HITMARKER"})
    AddToggle(C,"HitMarkerEnabled",{Text="Enable",Default=false})
    AddColor(C,"HitMarkerColor",{Default=Color3.new(1,1,1),Title="Color"})
    AddToggle(C,"HitMarkerRainbow",{Text="Rainbow",Default=false})
    AddSlider(C,"HitMarkerDuration",{Text="Duration",Default=2,Min=0.5,Max=5,Rounding=1})
    AddSlider(C,"HitMarkerSize",{Text="Size",Default=25,Min=5,Max=50,Rounding=0})
end

-- =========================================================
-- ESP SYSTEM — ПРАВИЛЬНЫЙ (через Players, а не Characters)
-- =========================================================
local espData={}
local R15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local R6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local MAXHP=12

local function mkLine(th)
    local l=Drawing.new("Line")
    l.Thickness=th
    l.Transparency=1
    l.Visible=false
    return l
end

local function mkText(size)
    local t=Drawing.new("Text")
    t.Size=size
    t.Center=true
    t.Outline=true
    t.Font=1
    t.Transparency=1
    t.Visible=false
    return t
end

local function createESP(plr)
    if espData[plr] then return end
    local d={}
    d.boxOutline=mkLine(3)
    d.box=mkLine(1)
    d.name=mkText(13)
    d.dist=mkText(13)
    d.weap=mkText(13)
    d.hpBg=Drawing.new("Square")
    d.hpBg.Thickness=1
    d.hpBg.Filled=true
    d.hpBg.Color=Color3.new(0,0,0)
    d.hpBg.Transparency=0.5
    d.hpBg.Visible=false
    d.hpSegs={}
    for i=1,MAXHP do
        d.hpSegs[i]=mkLine(3)
    end
    d.hpTxt=mkText(12)
    d.hpTxt.Center=false
    d.tracerO=mkLine(3)
    d.tracerF=mkLine(1)
    d.skel={}
    local bones=R6
    if plr.Character and plr.Character:FindFirstChild("UpperTorso") then
        bones=R15
    end
    for i=1,#bones do
        d.skel[i]={line=mkLine(2),a=bones[i][1],b=bones[i][2]}
    end
    espData[plr]=d
end

local function destroyESP(plr)
    local d=espData[plr]
    if not d then return end
    pcall(function()
        d.boxOutline:Remove()
        d.box:Remove()
        d.name:Remove()
        d.dist:Remove()
        d.weap:Remove()
        d.hpBg:Remove()
        for _,s in ipairs(d.hpSegs) do s:Remove() end
        d.hpTxt:Remove()
        d.tracerO:Remove()
        d.tracerF:Remove()
        for _,s in ipairs(d.skel) do s.line:Remove() end
    end)
    espData[plr]=nil
end

local function getHealthInfo(char)
    if not char then return nil,nil end
    local hAttr=char:GetAttribute("Health")
    local maxAttr=char:GetAttribute("MaxHealth")
    if hAttr and maxAttr and maxAttr>0 then
        return hAttr,maxAttr
    end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health,hum.MaxHealth>0 and hum.MaxHealth or 100
    end
    return nil,nil
end

local function isCharDead(char)
    if not char then return true end
    local dead=char:GetAttribute("Dead")
    if dead==true then return true end
    local inv=char:GetAttribute("Invincible")
    if inv==true then return true end
    local h,m=getHealthInfo(char)
    if h and h<=0 then return true end
    return false
end

-- Track players
local function onPlayerAdded(p)
    createESP(p)
    if p.Character then
        -- skeleton refs need to be rebuilt for new character
        local d=espData[p]
        if d then
            local bones=R6
            if p.Character:FindFirstChild("UpperTorso") then bones=R15 end
            for _,s in ipairs(d.skel) do
                s.line:Remove()
            end
            d.skel={}
            for i=1,#bones do
                d.skel[i]={line=mkLine(2),a=bones[i][1],b=bones[i][2]}
            end
        end
    end
end

for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP then onPlayerAdded(p) end
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p) destroyESP(p) end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    -- rebuild skeletons for all (since local character changed, other chars are new too)
    for plr,d in pairs(espData) do
        if plr.Character then
            local bones=R6
            if plr.Character:FindFirstChild("UpperTorso") then bones=R15 end
            for _,s in ipairs(d.skel) do pcall(function() s.line:Remove() end) end
            d.skel={}
            for i=1,#bones do
                d.skel[i]={line=mkLine(2),a=bones[i][1],b=bones[i][2]}
            end
        end
    end
end)

-- Weapon name
local wAttrCache={}
local wNameCache={}
local function getWeaponName(plr)
    if not plr then return "None" end
    local a=plr:GetAttribute("CurrentEquipped")
    if a~=wAttrCache[plr] then
        wAttrCache[plr]=a
        if a and type(a)=="string" then
            local ok,dec=pcall(function() return HS:JSONDecode(a) end)
            if ok and dec and dec.Name then
                wNameCache[plr]=dec.Name
            else
                wNameCache[plr]="None"
            end
        else
            wNameCache[plr]="None"
        end
    end
    return wNameCache[plr] or "None"
end

-- Visible check
local visRay=RaycastParams.new()
visRay.FilterType=Enum.RaycastFilterType.Exclude
visRay.IgnoreWater=true
local function isVisible(part)
    if not part then return false end
    local ign={LP.Character}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and isEnemy(p) and p.Character then
            -- не пропускаем союзников через стены
        end
    end
    visRay.FilterDescendantsInstances={LP.Character,part.Parent}
    local res=Workspace:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,visRay)
    if not res then return true end
    return res.Instance:IsDescendantOf(part.Parent)
end

-- ESP RENDER LOOP
RunService.RenderStepped:Connect(function()
    pcall(function()
        local espOn=Toggles.ESPEnabled and Toggles.ESPEnabled.Value
        local teamChk=Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value
        local boxType=Options.ESPBoxType and Options.ESPBoxType.Value or "2D Box"
        local wantBox=espOn and boxType~="Disabled"
        local wantName=espOn and Toggles.ESPName.Value
        local wantDist=espOn and Toggles.ESPDistance.Value
        local wantHp=espOn and Toggles.ESPHealth.Value
        local wantHpTxt=espOn and Toggles.ESPHealthText.Value
        local wantSkel=espOn and Toggles.ESPSkeleton.Value
        local wantTracer=espOn and Toggles.ESPTracer.Value
        local wantWeap=espOn and Toggles.ESPWeapon.Value
        local wantFill=espOn and Toggles.ESPBoxFillGradient.Value
        local vp=Camera.ViewportSize
        local camPos=Camera.CFrame.Position

        for plr,d in pairs(espData) do
            local char=plr.Character
            local hide=false
            if not char then hide=true
            elseif plr==LP then hide=true
            elseif teamChk and not isEnemy(plr) then hide=true
            elseif isCharDead(char) then hide=true end

            if hide then
                d.boxOutline.Visible=false
                d.box.Visible=false
                d.name.Visible=false
                d.dist.Visible=false
                d.weap.Visible=false
                d.hpBg.Visible=false
                for _,s in ipairs(d.hpSegs) do s.Visible=false end
                d.hpTxt.Visible=false
                d.tracerO.Visible=false
                d.tracerF.Visible=false
                for _,s in ipairs(d.skel) do s.line.Visible=false end
            else
                local hrp=char:FindFirstChild("HumanoidRootPart")
                local head=char:FindFirstChild("Head")
                if not hrp or not head then
                    d.boxOutline.Visible=false
                    d.box.Visible=false
                    d.name.Visible=false
                    d.dist.Visible=false
                    d.weap.Visible=false
                    d.hpBg.Visible=false
                    for _,s in ipairs(d.hpSegs) do s.Visible=false end
                    d.hpTxt.Visible=false
                    d.tracerO.Visible=false
                    d.tracerF.Visible=false
                    for _,s in ipairs(d.skel) do s.line.Visible=false end
                else
                    local headPos=head.Position+Vector3.new(0,0.5,0)
                    local footPos=hrp.Position-Vector3.new(0,3,0)
                    local spTop,onTop=Camera:WorldToViewportPoint(headPos)
                    local spBot,onBot=Camera:WorldToViewportPoint(footPos)
                    if onTop and onBot and spTop.Z>0 and spBot.Z>0 then
                        local h=math.abs(spBot.Y-spTop.Y)
                        local w=h*0.55
                        local x=spTop.X-w/2
                        local y=spTop.Y
                        local cx=spTop.X

                        -- BOX
                        if wantBox then
                            local cA=Options.ESPBoxColorA.Value
                            local cB=Options.ESPBoxColorB.Value
                            if boxType=="2D Box" then
                                -- outline
                                d.boxOutline.From=Vector2.new(x,y)
                                d.boxOutline.To=Vector2.new(x+w,y)
                                d.boxOutline.Color=Color3.new(0,0,0)
                                d.boxOutline.Visible=true
                                -- main box via 4 lines? use one big + trace
                                -- Fatality: use polyline - но Drawing Square нет
                                -- Используем Line для 4 сторон через обход
                                -- Не оптимально, но работает:
                                d.box.From=Vector2.new(x,y+h)
                                d.box.To=Vector2.new(x+w,y+h)
                                d.box.Color=cA
                                d.box.Visible=true
                                -- Упрощенно: рисуем только нижнюю + верхнюю + бока одним outline
                                -- Лучше сделать отдельный Square - но Drawing.Square тоже существует
                            end
                            -- Используем Square для полноценного бокса
                            if not d.square then
                                d.square=Drawing.new("Square")
                                d.square.Thickness=1.5
                                d.square.Filled=false
                                d.square.Transparency=1
                                d.square.Visible=false
                            end
                            d.square.Position=Vector2.new(x,y)
                            d.square.Size=Vector2.new(w,h)
                            d.square.Color=cA
                            d.square.Visible=true
                            if wantFill then
                                if not d.fill then
                                    d.fill=Drawing.new("Square")
                                    d.fill.Filled=true
                                    d.fill.Thickness=1
                                    d.fill.Transparency=0.7
                                    d.fill.Visible=false
                                end
                                d.fill.Position=Vector2.new(x,y)
                                d.fill.Size=Vector2.new(w,h)
                                d.fill.Color=Options.ESPFillColorA.Value
                                d.fill.Visible=true
                            elseif d.fill then
                                d.fill.Visible=false
                            end
                        else
                            if d.square then d.square.Visible=false end
                            if d.fill then d.fill.Visible=false end
                            d.boxOutline.Visible=false
                            d.box.Visible=false
                        end

                        -- NAME
                        if wantName then
                            d.name.Position=Vector2.new(cx,y-18)
                            d.name.Color=Options.ESPNameColor.Value
                            d.name.Text=plr.Name
                            d.name.Visible=true
                        else
                            d.name.Visible=false
                        end

                        -- DIST
                        if wantDist then
                            local dist=(camPos-hrp.Position).Magnitude
                            d.dist.Position=Vector2.new(cx,y+h+2)
                            d.dist.Color=Options.ESPDistanceColor.Value
                            d.dist.Text=tostring(math.floor(dist)).."m"
                            d.dist.Visible=true
                        else
                            d.dist.Visible=false
                        end

                        -- WEAPON
                        if wantWeap then
                            d.weap.Position=Vector2.new(cx,y+h+18)
                            d.weap.Color=Options.ESPWeaponColor.Value
                            d.weap.Text="["..getWeaponName(plr).."]"
                            d.weap.Visible=true
                        else
                            d.weap.Visible=false
                        end

                        -- HEALTH BAR
                        local hp,maxHp=getHealthInfo(char)
                        if wantHp and hp and maxHp then
                            local frac=math.clamp(hp/maxHp,0,1)
                            local bx=x-6
                            local by=y
                            local bw=3
                            local bh=h
                            d.hpBg.Position=Vector2.new(bx-1,by-1)
                            d.hpBg.Size=Vector2.new(bw+2,bh+2)
                            d.hpBg.Visible=true
                            local filled=bh*frac
                            local startY=by+(bh-filled)
                            local cnt=math.clamp(math.floor(MAXHP*frac),1,MAXHP)
                            local segH=filled/cnt
                            for i=1,MAXHP do
                                local seg=d.hpSegs[i]
                                if i<=cnt then
                                    local t=(i-0.5)/MAXHP
                                    seg.Color=lerpC(Options.ESPHealthBottomColor.Value,Options.ESPHealthTopColor.Value,t)
                                    seg.From=Vector2.new(bx+bw*0.5,startY+(i-1)*segH)
                                    seg.To=Vector2.new(bx+bw*0.5,startY+i*segH)
                                    seg.Thickness=bw
                                    seg.Visible=true
                                else
                                    seg.Visible=false
                                end
                            end
                        else
                            d.hpBg.Visible=false
                            for _,s in ipairs(d.hpSegs) do s.Visible=false end
                        end

                        -- HEALTH TEXT
                        if wantHpTxt and hp then
                            d.hpTxt.Position=Vector2.new(x+w+4,y)
                            d.hpTxt.Color=Options.ESPHealthTextColor.Value
                            d.hpTxt.Text=tostring(math.floor(hp))
                            d.hpTxt.Visible=true
                        else
                            d.hpTxt.Visible=false
                        end

                        -- TRACER
                        if wantTracer then
                            local from
                            local origin=Options.ESPTracerOrigin.Value
                            if origin=="Mouse" then
                                local ml=UIS:GetMouseLocation()
                                from=Vector2.new(ml.X,ml.Y)
                            elseif origin=="Top" then
                                from=Vector2.new(vp.X/2,0)
                            elseif origin=="Center" then
                                from=Vector2.new(vp.X/2,vp.Y/2)
                            else
                                from=Vector2.new(vp.X/2,vp.Y)
                            end
                            local to=Vector2.new(cx,y+h/2)
                            local cA=Options.ESPTracerColor.Value
                            local cB=Options.ESPTracerColorB.Value
                            local dist=(camPos-hrp.Position).Magnitude
                            local t=math.clamp(dist/200,0,1)
                            local col=lerpC(cA,cB,t)
                            d.tracerO.From=from
                            d.tracerO.To=to
                            d.tracerO.Color=Color3.new(0,0,0)
                            d.tracerO.Visible=true
                            d.tracerF.From=from
                            d.tracerF.To=to
                            d.tracerF.Color=col
                            d.tracerF.Visible=true
                        else
                            d.tracerO.Visible=false
                            d.tracerF.Visible=false
                        end

                        -- SKELETON
                        if wantSkel then
                            local cA=Options.ESPSkeletonColorA.Value
                            local cB=Options.ESPSkeletonColorB.Value
                            for i,s in ipairs(d.skel) do
                                local pA=char:FindFirstChild(s.a)
                                local pB=char:FindFirstChild(s.b)
                                if pA and pB then
                                    local sA,oA=Camera:WorldToViewportPoint(pA.Position)
                                    local sB,oB=Camera:WorldToViewportPoint(pB.Position)
                                    if oA and oB and sA.Z>0 and sB.Z>0 then
                                        s.line.From=Vector2.new(sA.X,sA.Y)
                                        s.line.To=Vector2.new(sB.X,sB.Y)
                                        s.line.Color=lerpC(cA,cB,(i-1)/#d.skel)
                                        s.line.Visible=true
                                    else
                                        s.line.Visible=false
                                    end
                                else
                                    s.line.Visible=false
                                end
                            end
                        else
                            for _,s in ipairs(d.skel) do s.line.Visible=false end
                        end
                    else
                        d.boxOutline.Visible=false
                        d.box.Visible=false
                        if d.square then d.square.Visible=false end
                        if d.fill then d.fill.Visible=false end
                        d.name.Visible=false
                        d.dist.Visible=false
                        d.weap.Visible=false
                        d.hpBg.Visible=false
                        for _,s in ipairs(d.hpSegs) do s.Visible=false end
                        d.hpTxt.Visible=false
                        d.tracerO.Visible=false
                        d.tracerF.Visible=false
                        for _,s in ipairs(d.skel) do s.line.Visible=false end
                    end
                end
            end
        end
    end)
end)

-- =========================================================
-- TARGET FINDER (Silent / Rage / Cube)
-- =========================================================
local SilentTarget=nil
local RageTarget=nil
local CubeTarget=nil
local lockedInst=nil
local frameCnt=0

local function isVisibleTo(part)
    if not part then return false end
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances={LP.Character}
    local res=Workspace:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,rp)
    if not res then return true end
    return res.Instance:IsDescendantOf(part.Parent)
end

local function cubeActive()
    return Toggles.CubeModeMainToggle and Toggles.CubeModeMainToggle.Value
end

local function findTargets()
    local myTeam=getTeam(LP)
    local center=Camera.ViewportSize/2
    local sDist,sClose=math.huge,nil
    local rDist,rClose=math.huge,nil
    local cDist,cClose=math.huge,nil
    local cAct=cubeActive()

    local list={}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP then
            local ch=plr.Character
            if ch and isAlive(ch) then
                table.insert(list,{plr=plr,char=ch})
            end
        end
    end

    -- Cube mode
    if cAct then
        local chosen=Options.CubeHitPart.Value or "Head"
        if lockedInst and lockedInst.Parent then
            local lchar=lockedInst.Parent
            local lplr=Players:GetPlayerFromCharacter(lchar)
            if not lplr or not isAlive(lchar) or (Toggles.CubeVisibleCheck.Value and not isVisibleTo(lockedInst)) then
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
        for _,entry in ipairs(list) do
            if isEnemy(entry.plr) then
                local tp=entry.char:FindFirstChild(chosen) or entry.char:FindFirstChild("Head") or entry.char:FindFirstChild("HumanoidRootPart")
                if tp then
                    local okVis=true
                    if Toggles.CubeVisibleCheck.Value then
                        okVis=isVisibleTo(tp)
                    end
                    if okVis then
                        local dd=(Camera.CFrame.Position-tp.Position).Magnitude
                        if dd<bestD then
                            bestD=dd
                            best=tp
                        end
                    end
                end
            end
        end
        lockedInst=best
        cClose=best
    else
        lockedInst=nil
    end

    -- Silent + Rage
    for _,entry in ipairs(list) do
        if isEnemy(entry.plr) then
            -- Rage
            if Toggles.Ragebot and Toggles.Ragebot.Value then
                local rp=entry.char:FindFirstChild(Options.RageHitPart.Value) or entry.char:FindFirstChild("Head") or entry.char:FindFirstChild("HumanoidRootPart")
                if rp then
                    local _,on=Camera:WorldToViewportPoint(rp.Position)
                    local ok=true
                    if Toggles.RagebotVisibleCheck.Value and not on then ok=false end
                    if ok and Toggles.RagebotWallCheck.Value and not isVisibleTo(rp) then ok=false end
                    if ok then
                        local dd=(Camera.CFrame.Position-rp.Position).Magnitude
                        if dd<rDist then
                            rDist=dd
                            rClose=rp
                        end
                    end
                end
            end
            -- Silent
            if Toggles.SilentAim and Toggles.SilentAim.Value then
                local sName=Options.SilentHitPart.Value or "Head"
                local sp=entry.char:FindFirstChild(sName) or entry.char:FindFirstChild("Head") or entry.char:FindFirstChild("HumanoidRootPart")
                if sp then
                    local spos,son=Camera:WorldToViewportPoint(sp.Position)
                    if son then
                        local sd=(Vector2.new(spos.X,spos.Y)-center).Magnitude
                        local maxR=999999
                        if Toggles.SilentUseFovCircle.Value then
                            maxR=Options.SilentFovCircleRadius.Value
                        end
                        if sd<=maxR then
                            local ok=true
                            if not Toggles.SilentWallbang.Value and not isVisibleTo(sp) then ok=false end
                            if ok and sd<sDist then
                                sDist=sd
                                sClose=sp
                            end
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

-- FOV circle
local SFovC=Drawing.new("Circle")
SFovC.NumSides=128
SFovC.Thickness=1.5
SFovC.Filled=false
SFovC.Visible=false

RunService.RenderStepped:Connect(function()
    pcall(function()
        frameCnt=frameCnt+1
        local vp=Camera.ViewportSize
        local c=vp/2
        SFovC.Position=c
        SFovC.Radius=Options.SilentFovCircleRadius.Value
        SFovC.Color=Options.SilentFovColor.Value
        if Toggles.SilentAim.Value and Toggles.SilentUseFovCircle.Value then
            SFovC.Visible=true
        else
            SFovC.Visible=false
        end
        if frameCnt%2==0 then findTargets() end
        -- Cube aimbot pull camera
        if cubeActive() and CubeTarget and CubeTarget.Parent then
            Camera.CFrame=CFrame.new(Camera.CFrame.Position,CubeTarget.Position)
        end
    end)
end)

-- =========================================================
-- GC HOOKS — get shoot function + ragebot + recoil/spread
-- =========================================================
local SendFunc=nil
local getEquippedFn=nil
local Weapon=nil

pcall(function()
    for _,obj in next,getgc(true) do
        if type(obj)=="table" then
            if rawget(obj,"shoot") and typeof(obj.shoot)=="function" then
                pcall(function()
                    for _,uv in pairs(debug.getupvalues(obj.shoot)) do
                        if type(uv)=="table" and rawget(uv,"Inventory") and rawget(uv.Inventory,"ShootWeapon") then
                            SendFunc=uv.Inventory.ShootWeapon.Send
                            break
                        end
                    end
                end)
            end
            if rawget(obj,"getCurrentEquipped") then
                pcall(function() getEquippedFn=obj.getCurrentEquipped end)
            end
            if rawget(obj,"setWeaponRecoil") then
                pcall(function()
                    local old=obj.setWeaponRecoil
                    obj.setWeaponRecoil=function(...)
                        if Toggles.NoRecoil and Toggles.NoRecoil.Value then return end
                        return old(...)
                    end
                end)
            end
            if rawget(obj,"getTrueSpread") then
                pcall(function()
                    local old=obj.getTrueSpread
                    obj.getTrueSpread=function(...)
                        if Toggles.NoSpread and Toggles.NoSpread.Value then return 0 end
                        return old(...)
                    end
                end)
            end
        end
    end
end)

local function getEquipped()
    if not getEquippedFn then return nil end
    local ok,res=pcall(function() return debug.getupvalue(getEquippedFn,1).CurrentEquipped end)
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

-- Hit sound
local HitSounds={}
HitSounds["Neverlose"]="rbxassetid://139452805868562"
HitSounds["Skeet"]="rbxassetid://83717596220569"
HitSounds["Bell"]="rbxassetid://96481309571950"
HitSounds["Coins"]="rbxassetid://5613553529"
HitSounds["Pick"]="rbxassetid://8616930816"

local function playHitSound()
    pcall(function()
        if not (Toggles.HitSoundEnabled and Toggles.HitSoundEnabled.Value) then return end
        local sid=HitSounds[Options.HitSoundPreset.Value or "Neverlose"] or HitSounds["Neverlose"]
        local s=Instance.new("Sound")
        s.SoundId=sid
        s.Volume=Options.HitSoundVolume.Value or 1
        s.Parent=SoundService
        s:Play()
        task.spawn(function()
            s.Ended:Wait()
            s:Destroy()
        end)
    end)
end

-- Bullet tracer
local function createTracer(a,b)
    if not (Toggles.BulletTracers and Toggles.BulletTracers.Value) then return end
    if not a or not b then return end
    local col=Options.BulletTracersColor.Value
    if Toggles.TracerRainbow.Value then
        col=Color3.fromHSV((tick()%5)/5,1,1)
    end
    local dur=Options.TracerTime.Value
    local p=Instance.new("Part")
    p.Name="RH_Tracer"
    p.Size=Vector3.new(0.1,0.1,(a-b).Magnitude)
    p.CFrame=CFrame.new(a,b)*CFrame.new(0,0,-p.Size.Z/2)
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

-- Hitmarker event
local activeHM={}
local function triggerHM(pos)
    if not (Toggles.HitMarkerEnabled and Toggles.HitMarkerEnabled.Value) then return end
    local dur=Options.HitMarkerDuration.Value or 2
    local lines={}
    for i=1,4 do
        lines[i]=Drawing.new("Line")
        lines[i].Thickness=2
        lines[i].Transparency=1
        lines[i].Visible=false
    end
    table.insert(activeHM,{lines=lines,wpos=pos,st=tick(),ex=tick()+dur})
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        local now=tick()
        local en=Toggles.HitMarkerEnabled and Toggles.HitMarkerEnabled.Value
        local col=Options.HitMarkerColor.Value
        if Toggles.HitMarkerRainbow.Value then
            col=Color3.fromHSV((now%5)/5,1,1)
        end
        local bsz=Options.HitMarkerSize.Value or 25
        local pulse=1+0.35*math.sin(now*math.pi)
        local sz=bsz*pulse
        local gap=6*pulse
        for i=#activeHM,1,-1 do
            local d=activeHM[i]
            if not en or now>d.ex then
                for _,l in ipairs(d.lines) do pcall(function() l:Remove() end) end
                table.remove(activeHM,i)
            else
                local sp,on=Camera:WorldToViewportPoint(d.wpos)
                if on then
                    local center=Vector2.new(sp.X,sp.Y)
                    local lt=now-d.st
                    local ang=math.rad((lt*720)%360)
                    local bA={0,90,180,270}
                    for j=1,4 do
                        local l=d.lines[j]
                        l.Color=col
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

-- Shoot hook
pcall(function()
    if not SendFunc then
        warn("[RH] SendFunc not found - aimbot will not work")
        return
    end
    local oldshoot=hookfunction(SendFunc,function(...)
        local args={...}
        local cA=cubeActive()
        if args[1] and type(args[1])=="table" and type(args[1].Bullets)=="table" then
            for _,bullet in pairs(args[1].Bullets) do
                if type(bullet)=="table" and type(bullet.Hits)=="table" then
                    for _,hd in pairs(bullet.Hits) do
                        if type(hd)=="table" then
                            local tp=nil
                            if Toggles.Ragebot.Value and RageTarget then
                                tp=RageTarget
                            elseif cA and CubeTarget then
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
                                            if hp and hp~=LP and isEnemy(hp) then
                                                enemyHit=true
                                            end
                                        end
                                    end
                                    if enemyHit or tp then
                                        playHitSound()
                                        triggerHM(b)
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
        return oldshoot(unpack(args))
    end)
end)

-- Ragebot auto shoot loop
task.spawn(function()
    while true do
        local delay=Options.RageDelay and Options.RageDelay.Value or 0.05
        task.wait(delay)
        pcall(function()
            if Toggles.Ragebot.Value and RageTarget and Weapon then
                if Weapon.IsEquipped and Weapon.Rounds and Weapon.Rounds>0 then
                    Weapon:shoot()
                end
            end
        end)
    end
end)

Notification:Notify({Title="RAINBOW HUB",Content="BloxStrike loaded. Key: Insert",Icon="clipboard"})
print("[RAINBOW HUB] BloxStrike loaded successfully")
