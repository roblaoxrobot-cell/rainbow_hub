local function LoadUniversal()
    local F = GetFatality()
    if not F then return end
    local Notification = F:CreateNotifier()

    local RunService  = game:GetService("RunService")
    local UIS         = game:GetService("UserInputService")
    local Workspace   = game:GetService("Workspace")
    local Camera      = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    if getgenv().RainbowHubLoaded then return end
    getgenv().RainbowHubLoaded = true

    local G = {
        Aimbot = { Enabled=false, FOV=120, Smoothness=0.25, Hitbox="Head", TeamCheck=true, WallCheck=false,
                   DrawFOV=true, FOVColor=Color3.fromRGB(255,106,133), Keybind=Enum.KeyCode.E, Mode="Hold" },
        ESP = { Box=false, Skeleton=false, Name=false, Distance=false, Health=false,
                Color=Color3.fromRGB(255,106,133), TeamColor=true },
        Hitbox = { Enabled=false, Size=5 },
        Speed = { Enabled=false, Value=32, Keybind=Enum.KeyCode.LeftShift, Mode="Hold" },
        Fly = { Enabled=false, Speed=60, Keybind=Enum.KeyCode.F, Mode="Toggle" },
        Spinbot = { Enabled=false, Keybind=Enum.KeyCode.LeftAlt, Mode="Toggle", Speed=1440 },
        NoClip = false,
    }
    local aiming, speedHolding, speedToggled, flyToggled, spinActive = false, false, false, false, false
    local spinAngle = 0
    local spinConn = nil

    F:Loader({ Name = "Rainbow Hub", Duration = 3 })
    Notification:Notify({ Title = "RAINBOW HUB", Content = "Welcome, " .. LocalPlayer.DisplayName, Icon = "clipboard" })

    local Window = F.new({ Name = "Rainbow Hub", Expire = "Universal", Keybind = "NONE" })
    local Config = Window:AddConfig()
    Config:Init("Hub_Universal", "HubConfigs")

    local menuVisible = true
    getgenv().UNVOpenKey = Enum.KeyCode.Insert
    getgenv().UNVIgnoreGP = false

    UIS.InputBegan:Connect(function(input, gp)
        if gp and not getgenv().UNVIgnoreGP then return end
        if keyMatches(input, getgenv().UNVOpenKey) then
            menuVisible = not menuVisible
            pcall(function() Window:SetVisible(menuVisible) end)
        end
    end)

    local AimMenu    = Window:AddMenu({ Name = "Aimbot",   Icon = "skull" })
    local VisualMenu = Window:AddMenu({ Name = "Visuals",  Icon = "eye" })
    local MoveMenu   = Window:AddMenu({ Name = "Movement", Icon = "settings" })
    local AntiAimMenu = Window:AddMenu({ Name = "Anti-Aim", Icon = "shield" })
    local SetMenuTab = Window:AddMenu({ Name = "Settings", Icon = "cog" })

    local hasDrawing = pcall(function() return Drawing.new("Circle") end)
    local fovCircle
    if hasDrawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Transparency = 1
        fovCircle.Color = G.Aimbot.FOVColor
    end
    RunService.RenderStepped:Connect(function()
        if fovCircle then
            if G.Aimbot.Enabled and G.Aimbot.DrawFOV then
                fovCircle.Visible = true
                fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                fovCircle.Radius = G.Aimbot.FOV
                fovCircle.Color = G.Aimbot.FOVColor
            else
                fovCircle.Visible = false
            end
        end
    end)

    local function getTarget()
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local best, bestDist = nil, G.Aimbot.FOV
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isTeam = G.Aimbot.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team
                if not isTeam then
                    local char = plr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if char and hum and hum.Health > 0 then
                        local part = char:FindFirstChild(G.Aimbot.Hitbox) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                        if part then
                            local sp, on = Camera:WorldToViewportPoint(part.Position)
                            if on then
                                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if d <= bestDist then bestDist = d; best = part end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local aimBind = "Hub_Aim_" .. tostring(math.random(1e8, 1e9))
    pcall(function() RunService:UnbindFromRenderStep(aimBind) end)
    pcall(function()
        RunService:BindToRenderStep(aimBind, Enum.RenderPriority.Camera.Value + 1, function()
            if not (G.Aimbot.Enabled and aiming) then return end
            local part = getTarget()
            if not part then return end
            local camPos = Camera.CFrame.Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, part.Position), math.clamp(G.Aimbot.Smoothness, 0.01, 1))
        end)
    end)

    UIS.InputBegan:Connect(function(input, gp)
        if G.Aimbot.Enabled and keyMatches(input, G.Aimbot.Keybind) then
            if G.Aimbot.Mode == "Hold" then aiming = true else aiming = not aiming end
        end
    end)
    UIS.InputEnded:Connect(function(input, gp)
        if G.Aimbot.Enabled and G.Aimbot.Mode == "Hold" and keyMatches(input, G.Aimbot.Keybind) then aiming = false end
    end)

    local espData = {}
    local R15 = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local R6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

    local function newDraw(kind, props)
        if not hasDrawing then return nil end
        local d = Drawing.new(kind)
        for k, v in pairs(props or {}) do d[k] = v end
        d.Visible = false
        return d
    end

    local function createESP(plr)
        local data = { Skeleton = {} }
        data.Box = newDraw("Square", {Thickness=1, Filled=false, Color=G.ESP.Color})
        data.Name = newDraw("Text", {Size=14, Center=true, Outline=true, Color=Color3.new(1,1,1)})
        data.Dist = newDraw("Text", {Size=12, Center=true, Outline=true, Color=Color3.fromRGB(200,200,200)})
        data.HealthBar = newDraw("Square", {Thickness=1, Filled=true, Color=Color3.fromRGB(0,255,0)})
        espData[plr] = data
        return data
    end

    local function clearESP(plr)
        local d = espData[plr]
        if not d then return end
        if d.Box then d.Box:Remove() end
        if d.Name then d.Name:Remove() end
        if d.Dist then d.Dist:Remove() end
        if d.HealthBar then d.HealthBar:Remove() end
        for _, l in pairs(d.Skeleton) do l:Remove() end
        espData[plr] = nil
    end

    local function getColor(plr)
        if G.ESP.TeamColor and plr.Team and LocalPlayer.Team then
            if plr.Team == LocalPlayer.Team then return Color3.fromRGB(100,200,255) end
            return Color3.fromRGB(255,100,100)
        end
        return G.ESP.Color
    end

    RunService.RenderStepped:Connect(function()
        if not hasDrawing then return end
        local enabled = G.ESP.Box or G.ESP.Skeleton or G.ESP.Name or G.ESP.Distance or G.ESP.Health
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            if not (enabled and char and hum and hum.Health > 0 and hrp and head) then
                local d = espData[plr]
                if d then
                    if d.Box then d.Box.Visible = false end
                    if d.Name then d.Name.Visible = false end
                    if d.Dist then d.Dist.Visible = false end
                    if d.HealthBar then d.HealthBar.Visible = false end
                    for _, l in pairs(d.Skeleton) do l.Visible = false end
                end
                continue
            end
            local d = espData[plr] or createESP(plr)
            local col = getColor(plr)
            local top = head.Position + Vector3.new(0, 0.6, 0)
            local bot = hrp.Position - Vector3.new(0, 3, 0)
            local ts, on1 = Camera:WorldToViewportPoint(top)
            local bs, on2 = Camera:WorldToViewportPoint(bot)
            if on1 and on2 then
                local h = math.abs(bs.Y - ts.Y)
                local w = h * 0.55
                local x, y, cx = ts.X - w/2, ts.Y, ts.X
                if G.ESP.Box and d.Box then
                    d.Box.Visible = true
                    d.Box.Size = Vector2.new(w, h)
                    d.Box.Position = Vector2.new(x, y)
                    d.Box.Color = col
                elseif d.Box then d.Box.Visible = false end
                if G.ESP.Name and d.Name then
                    d.Name.Visible = true
                    d.Name.Text = plr.Name
                    d.Name.Position = Vector2.new(cx, y - 18)
                    d.Name.Color = col
                elseif d.Name then d.Name.Visible = false end
                if G.ESP.Distance and d.Dist then
                    local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                    d.Dist.Visible = true
                    d.Dist.Text = string.format("[%d]", math.floor(dist))
                    d.Dist.Position = Vector2.new(cx, y + h + 2)
                elseif d.Dist then d.Dist.Visible = false end
                if G.ESP.Health and d.HealthBar then
                    d.HealthBar.Visible = true
                    local f = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local bh = h * f
                    d.HealthBar.Size = Vector2.new(3, bh)
                    d.HealthBar.Position = Vector2.new(x - 6, y + (h - bh))
                    d.HealthBar.Color = Color3.new(1 - f, f, 0)
                elseif d.HealthBar then d.HealthBar.Visible = false end
                if G.ESP.Skeleton then
                    local bones = char:FindFirstChild("UpperTorso") and R15 or R6
                    for i = 1, #bones do
                        if not d.Skeleton[i] then
                            d.Skeleton[i] = newDraw("Line", {Thickness=1.5, Color=col})
                        end
                        local line = d.Skeleton[i]
                        if line then
                            local a = char:FindFirstChild(bones[i][1])
                            local b = char:FindFirstChild(bones[i][2])
                            if a and b then
                                local ap, aon = Camera:WorldToViewportPoint(a.Position)
                                local bp, bon = Camera:WorldToViewportPoint(b.Position)
                                if aon and bon then
                                    line.Visible = true
                                    line.From = Vector2.new(ap.X, ap.Y)
                                    line.To = Vector2.new(bp.X, bp.Y)
                                    line.Color = col
                                else line.Visible = false end
                            else line.Visible = false end
                        end
                    end
                    for i = #bones + 1, #d.Skeleton do
                        if d.Skeleton[i] then d.Skeleton[i].Visible = false end
                    end
                else
                    for _, l in pairs(d.Skeleton) do l.Visible = false end
                end
            else
                if d.Box then d.Box.Visible = false end
                if d.Name then d.Name.Visible = false end
                if d.Dist then d.Dist.Visible = false end
                if d.HealthBar then d.HealthBar.Visible = false end
                for _, l in pairs(d.Skeleton) do l.Visible = false end
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(p) pcall(clearESP, p) end)

    task.spawn(function()
        while task.wait(0.15) do
            pcall(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr == LocalPlayer then continue end
                    local char = plr.Character
                    local head = char and char:FindFirstChild("Head")
                    if head then
                        if not head:GetAttribute("HubOrig") then head:SetAttribute("HubOrig", head.Size) end
                        if G.Hitbox.Enabled then
                            local s = G.Hitbox.Size
                            if head.Size ~= Vector3.new(s,s,s) then head.Size = Vector3.new(s,s,s) end
                        else
                            local o = head:GetAttribute("HubOrig")
                            if o and head.Size ~= o then head.Size = o end
                        end
                    end
                end
            end)
        end
    end)

    local BASE_SPEED = 16
    task.spawn(function()
        while task.wait(0.15) do
            pcall(function()
                local active = G.Speed.Enabled
                if G.Speed.Mode == "Hold" then active = active and speedHolding else active = active and speedToggled end
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local want = active and G.Speed.Value or BASE_SPEED
                    if hum.WalkSpeed ~= want then hum.WalkSpeed = want end
                end
            end)
        end
    end)

    UIS.InputBegan:Connect(function(input, gp)
        if G.Speed.Enabled and keyMatches(input, G.Speed.Keybind) then
            if G.Speed.Mode == "Hold" then speedHolding = true else speedToggled = not speedToggled end
        end
    end)
    UIS.InputEnded:Connect(function(input, gp)
        if G.Speed.Enabled and G.Speed.Mode == "Hold" and keyMatches(input, G.Speed.Keybind) then speedHolding = false end
    end)

    RunService.Stepped:Connect(function()
        if not G.NoClip then return end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end)
    end)

    local flyBV, flyBG, flyConn
    local function startFly()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum) then return end
        pcall(function() hum.PlatformStand = true end)
        flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(9e9,9e9,9e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9); flyBG.P = 1000; flyBG.D = 50; flyBG.CFrame = hrp.CFrame; flyBG.Parent = hrp
        flyConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not flyBV or not flyBV.Parent then return end
                local camCF = Camera.CFrame
                local mv = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then mv += camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then mv += camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0,1,0) end
                if mv.Magnitude > 0 then mv = mv.Unit * G.Fly.Speed end
                flyBV.Velocity = mv; flyBG.CFrame = camCF
            end)
        end)
    end
    local function stopFly()
        pcall(function() if flyBV then flyBV:Destroy() end end)
        pcall(function() if flyBG then flyBG:Destroy() end end)
        pcall(function() if flyConn then flyConn:Disconnect() end end)
        flyBV, flyBG, flyConn = nil, nil, nil
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.PlatformStand = false end) end
        end
    end
    UIS.InputBegan:Connect(function(input, gp)
        if G.Fly.Enabled and keyMatches(input, G.Fly.Keybind) then
            if G.Fly.Mode == "Toggle" then
                flyToggled = not flyToggled
                if flyToggled then startFly() else stopFly() end
            else startFly() end
        end
    end)
    UIS.InputEnded:Connect(function(input, gp)
        if G.Fly.Enabled and G.Fly.Mode == "Hold" and keyMatches(input, G.Fly.Keybind) then stopFly() end
    end)

    local function startSpin()
        if spinConn then return end
        spinConn = RunService.RenderStepped:Connect(function(dt)
            if not spinActive then return end
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    spinAngle = spinAngle + math.rad(G.Spinbot.Speed * dt)
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
                end
            end)
        end)
    end
    local function stopSpin()
        if spinConn then spinConn:Disconnect(); spinConn = nil end
        spinActive = false
    end
    UIS.InputBegan:Connect(function(input, gp)
        if not G.Spinbot.Enabled then return end
        if keyMatches(input, G.Spinbot.Keybind) then
            if G.Spinbot.Mode == "Toggle" then
                spinActive = not spinActive
                if spinActive then startSpin() end
            else
                spinActive = true
                startSpin()
            end
        end
    end)
    UIS.InputEnded:Connect(function(input, gp)
        if not G.Spinbot.Enabled then return end
        if G.Spinbot.Mode == "Hold" and keyMatches(input, G.Spinbot.Keybind) then
            spinActive = false
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        flyToggled = false
        speedHolding = false
        speedToggled = false
        aiming = false
        spinActive = false
        stopFly()
        stopSpin()
    end)

    do
        local M = AimMenu:AddSection({ Position='left', Name="MAIN" })
        local C = AimMenu:AddSection({ Position='center', Name="CHECKS" })
        local E = AimMenu:AddSection({ Position='right', Name="FOV" })
        M:AddToggle({ Name="Enable Aimbot", Flag="UnvAimOn", Callback=function(v) G.Aimbot.Enabled = v; if not v then aiming=false end end })
        M:AddSlider({ Name="FOV", Flag="UnvAimFOV", Default=120, Min=10, Max=600, Callback=function(v) G.Aimbot.FOV = v end })
        M:AddSlider({ Name="Smoothness", Flag="UnvAimSm", Default=0.25, Min=0.01, Max=1, Round=2, Callback=function(v) G.Aimbot.Smoothness = v end })
        M:AddDropdown({ Name="Hitbox", Flag="UnvAimHb", Values={"Head","Torso","UpperTorso","LowerTorso","HumanoidRootPart"}, Default="Head", Callback=function(v) G.Aimbot.Hitbox = v end })
        M:AddDropdown({ Name="Mode", Flag="UnvAimMode", Values={"Hold","Toggle"}, Default="Hold", Callback=function(v) G.Aimbot.Mode = v; aiming=false end })
        M:AddKeybind({ Name="Aim Key", Flag="UnvAimKey", Default=Enum.KeyCode.E, Callback=function(v) if v ~= nil then G.Aimbot.Keybind = v end end })
        C:AddToggle({ Name="Team Check", Flag="UnvAimTeam", Callback=function(v) G.Aimbot.TeamCheck = v end })
        C:AddToggle({ Name="Wall Check", Flag="UnvAimWall", Callback=function(v) G.Aimbot.WallCheck = v end })
        E:AddToggle({ Name="Draw FOV", Flag="UnvAimDraw", Callback=function(v) G.Aimbot.DrawFOV = v end })
        E:AddColorPicker({ Name="FOV Color", Flag="UnvAimFOVC", Default=Color3.fromRGB(255,106,133), Callback=function(c) G.Aimbot.FOVColor = c end })
    end

    do
        local E = VisualMenu:AddSection({ Position='left', Name="ESP" })
        local H = VisualMenu:AddSection({ Position='center', Name="HITBOX" })
        local S = VisualMenu:AddSection({ Position='right', Name="STYLE" })
        E:AddToggle({ Name="Box ESP", Flag="UnvEspBox", Callback=function(v) G.ESP.Box = v end })
        E:AddToggle({ Name="Skeleton ESP", Flag="UnvEspSkel", Callback=function(v) G.ESP.Skeleton = v end })
        E:AddToggle({ Name="Name ESP", Flag="UnvEspName", Callback=function(v) G.ESP.Name = v end })
        E:AddToggle({ Name="Distance", Flag="UnvEspDist", Callback=function(v) G.ESP.Distance = v end })
        E:AddToggle({ Name="Health Bar", Flag="UnvEspHp", Callback=function(v) G.ESP.Health = v end })
        H:AddToggle({ Name="Hitbox Expander", Flag="UnvHbOn", Callback=function(v) G.Hitbox.Enabled = v end })
        H:AddSlider({ Name="Hitbox Size", Flag="UnvHbSize", Default=5, Min=2, Max=30, Round=1, Callback=function(v) G.Hitbox.Size = v end })
        S:AddToggle({ Name="Team Color", Flag="UnvEspTeam", Callback=function(v) G.ESP.TeamColor = v end })
        S:AddColorPicker({ Name="ESP Color", Flag="UnvEspColor", Default=Color3.fromRGB(255,106,133), Callback=function(c) G.ESP.Color = c end })
    end

    do
        local S = MoveMenu:AddSection({ Position='left', Name="SPEEDHACK" })
        local Fl = MoveMenu:AddSection({ Position='center', Name="FLY" })
        local Mi = MoveMenu:AddSection({ Position='right', Name="MISC" })
        S:AddToggle({ Name="Enable Speed", Flag="UnvSpeedOn", Callback=function(v) G.Speed.Enabled = v end })
        S:AddSlider({ Name="Speed", Flag="UnvSpeedVal", Default=32, Min=16, Max=300, Callback=function(v) G.Speed.Value = v end })
        S:AddDropdown({ Name="Mode", Flag="UnvSpeedMode", Values={"Hold","Toggle"}, Default="Hold", Callback=function(v) G.Speed.Mode = v; speedHolding=false; speedToggled=false end })
        S:AddKeybind({ Name="Speed Key", Flag="UnvSpeedKey", Default=Enum.KeyCode.LeftShift, Callback=function(v) if v ~= nil then G.Speed.Keybind = v end end })
        Fl:AddToggle({ Name="Enable Fly", Flag="UnvFlyOn", Callback=function(v) G.Fly.Enabled = v; if not v then stopFly(); flyToggled=false end end })
        Fl:AddSlider({ Name="Fly Speed", Flag="UnvFlySpeed", Default=60, Min=10, Max=500, Callback=function(v) G.Fly.Speed = v end })
        Fl:AddDropdown({ Name="Mode", Flag="UnvFlyMode", Values={"Toggle","Hold"}, Default="Toggle", Callback=function(v) G.Fly.Mode = v; stopFly(); flyToggled=false end })
        Fl:AddKeybind({ Name="Fly Key", Flag="UnvFlyKey", Default=Enum.KeyCode.F, Callback=function(v) if v ~= nil then G.Fly.Keybind = v end end })
        Mi:AddToggle({ Name="NoClip", Flag="UnvNoClip", Callback=function(v) G.NoClip = v end })
    end

    do
        local S = AntiAimMenu:AddSection({ Position='left', Name="SPINBOT" })
        S:AddToggle({ Name="Enable Spinbot", Flag="UnvSpinOn", Callback=function(v)
            G.Spinbot.Enabled = v
            if not v then spinActive = false; stopSpin() end
        end })
        S:AddSlider({ Name="Spin Speed", Flag="UnvSpinSpeed", Default=1440, Min=100, Max=5000, Callback=function(v) G.Spinbot.Speed = v end })
        S:AddDropdown({ Name="Mode", Flag="UnvSpinMode", Values={"Toggle","Hold"}, Default="Toggle", Callback=function(v) G.Spinbot.Mode = v; spinActive=false end })
        S:AddKeybind({ Name="Spin Key", Flag="UnvSpinKey", Default=Enum.KeyCode.LeftAlt, Callback=function(v) if v ~= nil then G.Spinbot.Keybind = v end end })
    end

    do
        local S = SetMenuTab:AddSection({ Position='left', Name="Menu" })
        S:AddKeybind({ Name="Menu Keybind", Flag="UnvMenuKey", Default=Enum.KeyCode.Insert, Callback=function(v) if v~=nil then getgenv().UNVOpenKey = v end end })
        S:AddToggle({ Name="Ignore Game Processed", Flag="UnvIGP", Callback=function(v) getgenv().UNVIgnoreGP = v end })
    end
end
