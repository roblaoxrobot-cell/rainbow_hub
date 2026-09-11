-- =========================================================
--  PENABLOX HVH GAME SCRIPT (games/penablox.lua)
--  Loaded by loader.lua
-- =========================================================

local F = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
if not F then warn("[penablox] Failed to load Fatality UI.") return end
local Notification = F:CreateNotifier()

local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function keyMatches(input, key)
    if key == nil then return false end
    if typeof(key) == "EnumItem" then return input.KeyCode == key end
    return input.KeyCode.Name == tostring(key)
end

-- =========================================================
--  CHECK FUNCTIONS
-- =========================================================
local function checkspecificfunction(funcName)
    if getfenv()[funcName] == nil and _G[funcName] == nil then return false end
    return true
end

-- =========================================================
--  GLOBALS
-- =========================================================
getgenv().RageBotEnabled = getgenv().RageBotEnabled or false
getgenv().RageBotMethod  = getgenv().RageBotMethod or "Event Hook"
getgenv().RageBotHitPos  = getgenv().RageBotHitPos or "Auto"
getgenv().RageBotHitPart = getgenv().RageBotHitPart or "Head"

if getgenv().RageBotHitPos == "Auto" then
    if game:GetService("Players").LocalPlayer:FindFirstChild("hitparts") then
        game:GetService("Players").LocalPlayer:FindFirstChild("hitparts").Value = "Legs,Torso,Arms,Head"
    end
end

if not getgenv().typeofantiaim or not getgenv().antiaimjitter or not getgenv().antiaimdelayness or not getgenv().antiaimrandomness then
    getgenv().typeofantiaim     = "Static"
    getgenv().antiaimjitter     = 0
    getgenv().antiaimdelayness  = 0
    getgenv().antiaimrandomness = 0
    getgenv().rightantiaim      = 0
    getgenv().leftantiaim       = 0
    getgenv().BodyYawantiaim    = 0
    getgenv().Pitchantiaim      = 0
end

-- =========================================================
--  DISABLE IN-GAME ANTI-CHEAT
-- =========================================================
task.spawn(function()
    if not checkspecificfunction("getgc") then
        Notification:Notify({ Title = "Warning", Content = "getgc is missing, can't disable client checks.", Icon = "bell" })
        return
    end

    -- movement protections
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "WalkspeedProtect") then
            pcall(function()
                v.WalkspeedProtect.enabled = false
                v.FlyProtect.enabled       = false
                v.TeleportDetect.enabled   = false
                v.CFrameMonitor.enabled    = false
                v.NoClipProtect.enabled    = false
                v.HitboxProtect.enabled    = false
                v.PartRemoveProtect        = false
                v.PartRenameProtect        = false
            end)
        end
    end

    -- kick radius
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "RADIUS_KICK") and rawget(v, "POS_KICK") then
            pcall(function()
                v.RADIUS_KICK = math.huge
                v.POS_KICK = math.huge
                v.POS_MISMATCH_TIME = math.huge
                v.MISMATCH_THRESHOLD = math.huge
                v.DT_SPAM_RADIUS = math.huge
                v.DT_RADIUS = math.huge
                v.RADIUS = math.huge
            end)
        end
    end

    -- hook kick functions
    for _, v in pairs(getgc(true)) do
        if type(v) == "function" and getfenv(v).script == nil then
            local name = debug.info(v, "n")
            if name == "sendKick" or name == "checkCFrameMovement" then
                pcall(function()
                    hookfunction(v, function() return end)
                    warn("[penablox] Prevented: " .. name)
                end)
            end
        end
    end

    Notification:Notify({ Title = "Rainbow Hub", Content = "Client checks disabled", Icon = "check" })
end)

-- =========================================================
--  DISABLE DEFAULT RAGEBOT
-- =========================================================
local function disabledefaultragebot()
    if not checkspecificfunction("getconnections") then
        warn("[penablox] getconnections is missing, can't disable default ragebot.")
        return
    end
    if LocalPlayer:FindFirstChild("Mindmg") then
        LocalPlayer.Mindmg.Value = 1
    end
    local bob = workspace:FindFirstChild("Bob")
    if not bob then warn("[penablox] I didn't find bob") return end
    for _, conn in pairs(getconnections(bob.ChildAdded)) do
        pcall(function() conn:Disconnect() end)
    end
    for _, conn in pairs(getconnections(game:GetService("ReplicatedStorage").MainEvent.OnClientEvent)) do
        pcall(function() conn:Disconnect() end)
    end
end

-- =========================================================
--  ANTI-AIM (yaw hook + AAHandler loop)
-- =========================================================
task.spawn(function()
    local function hookyaw()
        local plr = LocalPlayer
        local chr = plr.Character or plr.CharacterAdded:Wait()
        local Root = chr:WaitForChild("HumanoidRootPart")
        local oldNewIndex
        oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
            if not checkcaller() and self == Root and key == "CFrame" and getgenv().AntiAimEnabled then
                local rot = getgenv().BaseYawantiaim or 0
                value = value * CFrame.Angles(0, math.rad(rot), 0)
            end
            return oldNewIndex(self, key, value)
        end)
    end
    local s_hook, e_hook = pcall(hookyaw)
    if not s_hook then warn("[penablox] Failed to hook yaw: " .. tostring(e_hook)) end

    if not checkspecificfunction("require") then
        Notification:Notify({ Title = "Warning", Content = "require is missing, can't start anti-aim.", Icon = "bell" })
        return
    end
    if not checkspecificfunction("hookmetamethod") then
        Notification:Notify({ Title = "Warning", Content = "hookmetamethod is missing, some anti-aim features might not work.", Icon = "bell" })
    end

    if getgenv().AAIsLooped then return end
    local AAHandler = require(game:GetService("ReplicatedFirst"):WaitForChild("AAHandler"))
    getgenv().AAIsLooped = true

    while task.wait(0.1) do
        if not AAHandler then warn("[penablox] AAHandler is missing.") return end
        if getgenv().AntiAimEnabled then
            local ok, err = pcall(function()
                AAHandler.SendYawJitter(
                    nil,
                    getgenv().typeofantiaim or "Static",
                    getgenv().BaseYawantiaim or 0,
                    getgenv().leftantiaim or 0,
                    getgenv().rightantiaim or 0,
                    getgenv().antiaimjitter or 0,
                    getgenv().antiaimdelayness or 0,
                    getgenv().antiaimrandomness or 0
                )
                AAHandler.SendBodyYaw(nil, getgenv().BodyYawantiaim or 0)
                AAHandler.SendPitchMode(nil, "Static", getgenv().Pitchantiaim or 0, 0, 0, 0, 0, 0)
            end)
            if not ok then
                Notification:Notify({ Title = "Warning", Content = "Failed to send anti-aim data, error: " .. tostring(err), Icon = "bell" })
            end
        end
    end
end)

-- =========================================================
--  HELPERS — closest player, encrypt/decrypt, hitpart finder
-- =========================================================
local function GetClosestPlayer()
    local nearestPlayer, nearestDistance = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local head = character and character:FindFirstChild("Head")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if head and humanoid and humanoid.Health > 0 then
                local distance = (head.Position - myRoot.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end
    return nearestPlayer
end

local function encryptstring(text)
    local json = game:GetService("TextChatService").BubbleChatConfiguration:FindFirstChild("ImageLabel"):GetAttribute("SuperSecretKey")
    local s, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), json)
    if not s or type(data) ~= "table" then return text end
    local result = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        result = result .. (data[char] or char)
    end
    return result
end

local function decryptstring(text)
    local json = game:GetService("TextChatService").BubbleChatConfiguration:FindFirstChild("ImageLabel"):GetAttribute("SuperSecretKey")
    local s, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), json)
    if not s or type(data) ~= "table" then return text end
    local rd = {}
    for real, junk in pairs(data) do rd[junk] = real end
    local decrypted = text
    for junk, real in pairs(rd) do
        local pattern = junk:gsub("([^%w])", "%%%1")
        decrypted = decrypted:gsub(pattern, real)
    end
    return decrypted
end

local function GetPartNameAtPos(targetPos)
    local cameraPos = workspace.CurrentCamera.CFrame.Position
    local direction = (targetPos - cameraPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then table.insert(targets, p.Character) end
    end
    params.FilterDescendantsInstances = targets
    local result = workspace:Raycast(cameraPos, direction, params)
    return (result and result.Instance) and result.Instance.Name or "Torso"
end

-- =========================================================
--  CUSTOM RESOLVER — Divine.lua OLD (credit: hush)
-- =========================================================
task.spawn(function()
    Notification:Notify({
        Title = "Rainbow Hub",
        Content = 'Credits to hush for the "Divine.lua OLD" resolver.',
        Duration = 10,
        Icon = "bell",
    })

    local cloneref = cloneref or function(obj) return obj end
    local WS         = cloneref(game:GetService("Workspace"))
    local RS         = cloneref(game:GetService("RunService"))
    local PlayersSvc = cloneref(Players)
    local LP         = PlayersSvc.LocalPlayer

    local HIT_WINDOW  = 0.25
    local STACK_LIMIT = 10
    local FLUSH_TIME  = 2

    local yawSamples, resolvedYaw, lockedYaw = {}, {}, {}
    local lastHitTime, lastFlush = 0, os.clock()
    local missCounter, lastMissed = {}, {}

    local function norm(a) return math.atan2(math.sin(a), math.cos(a)) end
    local function diff(a, b) return math.abs(norm(a - b)) end
    local function lerpAngle(a, b, t) return a + norm(b - a) * t end

    local function flushthis()
        table.clear(yawSamples); table.clear(resolvedYaw); table.clear(lockedYaw)
        lastFlush = os.clock()
    end

    local function getClosest()
        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local best, bestDist = nil, math.huge
        for _, plr in ipairs(PlayersSvc:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - myRoot.Position).Magnitude
                    if dist < bestDist then best = plr; bestDist = dist end
                end
            end
        end
        return best
    end

    local function getHRPYaw(hrp)
        local look = hrp.CFrame.LookVector
        return math.atan2(look.X, look.Z)
    end

    local function pushYaw(plr)
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        yawSamples[plr] = yawSamples[plr] or {}
        table.insert(yawSamples[plr], getHRPYaw(hrp))
        if #yawSamples[plr] > STACK_LIMIT then table.remove(yawSamples[plr], 1) end
    end

    local function classifyAA(plr)
        local pile = yawSamples[plr]
        if not pile or #pile < STACK_LIMIT then return "LEGIT" end
        local totalDelta, flips = 0, 0
        for i = 2, #pile do
            local d = diff(pile[i], pile[i - 1])
            totalDelta += d
            if math.sign(math.sin(pile[i])) ~= math.sign(math.sin(pile[i - 1])) then flips += 1 end
        end
        local avg = totalDelta / (#pile - 1)
        if avg < math.rad(4) then return "LEGIT"
        elseif avg < math.rad(18) and flips < 3 then return "STATIC_AA"
        else return "JITTER_AA" end
    end

    do
        local oldPrint = print
        print = function(...)
            for _, v in ipairs({...}) do
                if tostring(v):find("Missed due to desync") then
                    local unlucky = getClosest()
                    if unlucky then
                        missCounter[unlucky] = (missCounter[unlucky] or 0) + 1
                        lockedYaw[unlucky]  = nil
                        resolvedYaw[unlucky] = nil
                        lastMissed[unlucky]  = true
                    end
                end
            end
            oldPrint(...)
        end
    end

    local function resolveYaw(plr)
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return 0 end
        local realYaw = getHRPYaw(hrp)
        local mode = classifyAA(plr)
        if mode == "LEGIT" then return realYaw end
        if mode == "STATIC_AA" then
            if not lockedYaw[plr] and os.clock() - lastHitTime <= HIT_WINDOW then
                lockedYaw[plr] = realYaw
                lastHitTime = 0
            end
            return lockedYaw[plr] or realYaw
        end
        local side = math.sign(math.sin(realYaw))
        if lastMissed[plr] then side = -side; lastMissed[plr] = nil end
        local biased = norm(realYaw + side * getgenv().DivineLuaBIASAngle)
        if getgenv().DivineLuaLERPEnabled then
            local last = resolvedYaw[plr] or biased
            resolvedYaw[plr] = lerpAngle(last, biased, getgenv().DivineLuaLERPSpeed)
            return resolvedYaw[plr]
        end
        return biased
    end

    local function applyYaw(plr, yaw)
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rj = hrp:FindFirstChild("RootJoint")
        if not rj then return end
        if not rj:GetAttribute("BaseC0") then rj:SetAttribute("BaseC0", rj.C0) end
        rj.C0 = rj:GetAttribute("BaseC0") * CFrame.Angles(0, yaw, 0)
    end

    RS.Heartbeat:Connect(function()
        if not getgenv().CustomResolverEnabled or getgenv().CustomResolverMode ~= "Divine.lua OLD" then return end
        if not getgenv().DivineLuaCorrection then return end
        if os.clock() - lastFlush > FLUSH_TIME then flushthis() end
        local tgt = getClosest()
        if tgt then
            pushYaw(tgt)
            local yaw = resolveYaw(tgt)
            applyYaw(tgt, yaw)
        end
    end)
end)

-- =========================================================
--  FORCE HIT — event hook
-- =========================================================
task.spawn(function()
    if not checkspecificfunction("hookfunction") then
        Notification:Notify({ Title = "Warning", Content = "hookfunction is missing, can't start force hit method.", Icon = "bell" })
        return
    end
    pcall(function()
        local oldFireServer
        oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
            local args = {...}
            if tostring(self) == "MainEvent" and getgenv().RageBotEnabled then
                if getgenv().RageBotMethod == "Event Hook" and checkspecificfunction("hookfunction") then
                    local action = decryptstring(args[1])
                    if action == "Shoot" or action == "MeleeHit" then
                        local target = GetClosestPlayer()
                        if target and target.Character and target.Character:FindFirstChild("Head") then
                            local HitPos = getgenv().RageBotHitPos or "Torso"
                            local AutoPart = nil
                            if getgenv().RageBotHitPos == "Auto" then
                                if LocalPlayer:FindFirstChild("TargetPos") and LocalPlayer.TargetPos.Value ~= Vector3.new(0,0,0) then
                                    AutoPart = LocalPlayer.TargetPos.Value
                                else
                                    AutoPart = "Torso"
                                end
                            end
                            local dmgpart = getgenv().RageBotHitPart or "Head"
                            if HitPos and dmgpart then
                                args[3] = encryptstring(dmgpart)
                                if AutoPart then
                                    local foolishpart = GetPartNameAtPos(AutoPart)
                                    local tuffpart = target.Character:FindFirstChild(foolishpart)
                                    if tuffpart and tuffpart.Position ~= Vector3.new(0,0,0) then
                                        args[7] = tuffpart.Position or AutoPart
                                        if typeof(args[6]) == "Vector3" and typeof(AutoPart) == "Vector3" then
                                            args[5] = (args[6] - tuffpart.Position).Magnitude
                                        end
                                    else
                                        args[7] = AutoPart
                                        if typeof(args[6]) == "Vector3" and typeof(AutoPart) == "Vector3" then
                                            args[5] = (args[6] - AutoPart).Magnitude
                                        end
                                    end
                                else
                                    args[7] = target.Character[HitPos].Position
                                    if typeof(args[6]) == "Vector3" then
                                        args[5] = (args[6] - target.Character[HitPos].Position).Magnitude
                                    end
                                end
                                args[8] = encryptstring("nil")
                                args[9] = encryptstring("nil")
                            end
                        end
                    end
                end
            end
            return oldFireServer(self, unpack(args))
        end)
    end)
end)

-- =========================================================
--  MOVEMENT MODULE HOOK (RemoveVelocity)
-- =========================================================
task.spawn(function()
    local MovementModule = require(game:GetService("ReplicatedStorage"):WaitForChild("MovementHandler"))
    local orig_speed  = MovementModule.GetPlanarSpeed
    local orig_vert   = MovementModule.GetVerticalVelocity
    local orig_ground = MovementModule.IsGrounded
    local orig_crouch = MovementModule.IsCrouching

    RunService.Heartbeat:Connect(function()
        if getgenv().RemoveVelocity then
            MovementModule.GetPlanarSpeed = function() return 0 end
            MovementModule.GetVerticalVelocity = function() return 0 end
            MovementModule.IsGrounded = function() return true end
            MovementModule.IsCrouching = function() return true end
        else
            if MovementModule.GetPlanarSpeed ~= orig_speed then
                MovementModule.GetPlanarSpeed = orig_speed
                MovementModule.GetVerticalVelocity = orig_vert
                MovementModule.IsGrounded = orig_ground
                MovementModule.IsCrouching = orig_crouch
            end
        end
    end)
end)

-- =========================================================
--  MATH.RANDOM HOOK
-- =========================================================
task.spawn(function()
    local oldMathRandom
    oldMathRandom = hookfunction(math.random, function(...)
        local args = {...}
        if getgenv().RemoveMathRandom and not checkcaller() then
            if #args == 0 then return 0
            elseif #args == 1 then return 1
            elseif #args == 2 then return args[1] end
        end
        return oldMathRandom(...)
    end)
end)

-- =========================================================
--  INFINITE AMMO LOOP
-- =========================================================
task.spawn(function()
    while task.wait(1) do
        local s, f = pcall(function()
            if getgenv().InfiniteAmmo then
                game:GetService("ReplicatedStorage"):WaitForChild("Reload"):FireServer()
            end
        end)
        if not s then
            Notification:Notify({ Title = "Warning", Content = "Failed to reload for infinite ammo, error: " .. tostring(f), Icon = "bell" })
            break
        end
    end
end)

-- =========================================================
--  FATALITY UI
-- =========================================================
F:Loader({ Name = "Rainbow Hub", Duration = 3 })

repeat task.wait() until LocalPlayer.PlayerGui:FindFirstChild("LimoriaUI") and LocalPlayer.PlayerGui.LimoriaUI.Window.Visible == true

Notification:Notify({
    Title = "RAINBOW HUB",
    Content = "Welcome, " .. LocalPlayer.DisplayName,
    Icon = "clipboard",
})

local Window = F.new({ Name = "Rainbow Hub", Expire = "Penablox", Keybind = "NONE" })
local Config = Window:AddConfig()
Config:Init("Hub_Pena", "HubConfigs")

local menuVisible = true
getgenv().OpenKey = Enum.KeyCode.Insert
getgenv().IgnoreGP = false

UIS.InputBegan:Connect(function(input, gp)
    if gp and not getgenv().IgnoreGP then return end
    if keyMatches(input, getgenv().OpenKey) then
        menuVisible = not menuVisible
        pcall(function() Window:SetVisible(menuVisible) end)
    end
end)

local RageMenu     = Window:AddMenu({ Name = "Rage",     Icon = "skull" })
local AntiAimMenu  = Window:AddMenu({ Name = "Anti Aim", Icon = "shield" })
local VisualMenu   = Window:AddMenu({ Name = "Visuals",  Icon = "eye" })
local MiscMenu     = Window:AddMenu({ Name = "Misc",     Icon = "settings" })
local SettingsMenu = Window:AddMenu({ Name = "Settings", Icon = "cog" })

-- =========================================================
--  RAGE MENU
-- =========================================================
do
    local MainRage    = RageMenu:AddSection({ Position = 'left',   Name = "MAIN" })
    local ExploitSect = RageMenu:AddSection({ Position = 'center', Name = "EXPLOITS" })
    local ExtaSect    = RageMenu:AddSection({ Position = 'right',  Name = "CONFIGURATION" })

    MainRage:AddToggle({
        Name = "Custom resolver", Flag = "CustomResolverEnabled",
        Callback = function(v) getgenv().CustomResolverEnabled = v end,
    })

    MainRage:AddDropdown({
        Name = "Resolver Mode", Flag = "CustomResolverMode",
        Values = {"Divine.lua OLD"}, Default = "None",
        Callback = function(v)
            getgenv().CustomResolverMode = v
            if v == "Divine.lua OLD" then
                getgenv().DivineLuaCorrection = v
            else
                getgenv().DivineLuaCorrection = false
            end
        end,
    })

    local forcehittoggle = ExploitSect:AddToggle({
        Name = "Force Hit", Flag = "ForceHitEnabled", Risky = true, Option = true,
        Callback = function(v)
            getgenv().RageBotEnabled = v
            if v then disabledefaultragebot() end
        end,
    })

    forcehittoggle.Option:AddDropdown({
        Name = "Method", Flag = "ForceHitMethod",
        Values = {"Event Hook"}, Default = "Event Hook",
        Callback = function(v) getgenv().RageBotMethod = v end,
    })

    forcehittoggle.Option:AddDropdown({
        Name = "Hit Position", Flag = "ForceHitHitPos",
        Values = {"Auto","Head","Torso","HumanoidRootPart","Arms","Legs"}, Default = "Auto",
        Callback = function(v)
            getgenv().RageBotHitPos = v
            if v == "Auto" and LocalPlayer:FindFirstChild("hitparts") then
                LocalPlayer.hitparts.Value = "Legs,Torso,Arms,Head"
            end
        end,
    })

    forcehittoggle.Option:AddDropdown({
        Name = "Damage Part", Flag = "ForceHitDamagePart",
        Values = {"Head","Torso","HumanoidRootPart","Arms","Legs"}, Default = "Head",
        Callback = function(v) getgenv().RageBotHitPart = v end,
    })

    ExploitSect:AddToggle({
        Name = "Infinite Ammo", Flag = "InfiniteAmmo", Risky = true,
        Callback = function(v) getgenv().InfiniteAmmo = v end,
    })

    local function setspread(bs, ms, mjs, mins, msps, vi, hi, cm)
        bs = bs or 0.5; ms = ms or 2.5; mjs = mjs or 15; mins = mins or 0.01
        msps = msps or 15; vi = vi or 2; hi = hi or 0.2; cm = cm or 0.3
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "BaseSpread") and rawget(t, "MoveSpread")
               and rawget(t, "MaxJumpSpread") and rawget(t, "MinSpread") and rawget(t, "MaxSpread")
               and rawget(t, "VelocityInfluence") and rawget(t, "HorizontalInfluence")
               and rawget(t, "CrouchMultiplier") then
                t.BaseSpread = bs; t.MoveSpread = ms; t.MaxJumpSpread = mjs
                t.MinSpread = mins; t.MaxSpread = msps; t.VelocityInfluence = vi
                t.HorizontalInfluence = hi; t.CrouchMultiplier = cm
            end
        end
    end

    ExploitSect:AddToggle({
        Name = "Spread Modifier", Flag = "NoSpread", Risky = true,
        Callback = function(v)
            getgenv().NoSpread = v
            if v then setspread(0, 0, 0, 0, 0, 0, 0, 0)
            else setspread(0.5, 2.5, 15, 0.01, 15, 2, 0.2, 0.3) end
        end,
    })

    ExploitSect:AddSlider({
        Name = "Spread Amount", Flag = "SpreadAmount", Default = 0, Min = 0, Max = 15,
        Callback = function(v)
            if v and getgenv().NoSpread then setspread(0, 0, 0, v, v, 0, 0, 0) end
        end,
    })

    ExtaSect:AddToggle({
        Name = "Disable In-Game Resolver", Flag = "DisableInGameResolver",
        Callback = function(v)
            if v and LocalPlayer:FindFirstChild("ResolverEnabled") then
                LocalPlayer.ResolverEnabled.Value = false
            elseif not v and LocalPlayer:FindFirstChild("ResolverEnabled") then
                LocalPlayer.ResolverEnabled.Value = true
            end
        end,
    })

    ExtaSect:AddToggle({
        Name = "Divine Lerp", Flag = "DivineLerpEnabled",
        Callback = function(v) getgenv().DivineLuaLERPEnabled = v end,
    })

    ExtaSect:AddSlider({
        Name = "Divine Lerp", Flag = "DivineLerpSpeed", Default = 0.35, Min = 0, Round = 2, Max = 1,
        Callback = function(v) getgenv().DivineLuaLERPSpeed = v end,
    })

    ExtaSect:AddSlider({
        Name = "Divine Bias", Flag = "DivineBiasAngle", Default = math.rad(25), Min = 0, Round = 2, Max = math.rad(90),
        Callback = function(v) getgenv().DivineLuaBIASAngle = v end,
    })
end

-- =========================================================
--  ANTI-AIM MENU
-- =========================================================
do
    local AA_General = AntiAimMenu:AddSection({ Position = 'left',   Name = "GENERAL" })
    local AA_Angles  = AntiAimMenu:AddSection({ Position = 'center', Name = "ANGLES" })
    local AA_Extra   = AntiAimMenu:AddSection({ Position = 'right',  Name = "EXTRA" })

    AA_General:AddToggle({
        Name = "Enable Anti-Aim", Flag = "AntiAimEnabled",
        Callback = function(v) getgenv().AntiAimEnabled = v end,
    })

    AA_General:AddDropdown({
        Name = "Mode", Flag = "AntiAimMode",
        Values = {"Static","Offset","Center","3-Way","5-Way","Off","Rainbow"}, Default = "Static",
        Callback = function(v) getgenv().typeofantiaim = v end,
    })

    AA_Angles:AddSlider({ Name = "Base Yaw",  Default = 0, Min = -180, Max = 180, Flag = "BaseYaw",  Callback = function(v) getgenv().BaseYawantiaim = v end })
    AA_Angles:AddSlider({ Name = "Yaw Left",  Default = 0, Min = -180, Max = 180, Flag = "YawLeft",  Callback = function(v) getgenv().leftantiaim = v end })
    AA_Angles:AddSlider({ Name = "Yaw Right", Default = 0, Min = -180, Max = 180, Flag = "YawRight", Callback = function(v) getgenv().rightantiaim = v end })
    AA_Angles:AddSlider({ Name = "Pitch",     Default = 0, Min = -90,  Max = 90,  Flag = "Pitch",    Callback = function(v) getgenv().Pitchantiaim = v end })
    AA_Angles:AddSlider({ Name = "Body Yaw",  Default = 0, Min = -80,  Max = 80,  Flag = "BodyYaw",  Callback = function(v) getgenv().BodyYawantiaim = v end })

    AA_Extra:AddSlider({ Name = "Jitter Amount", Default = 0, Max = 180, Flag = "JitterAmount",  Callback = function(v) getgenv().antiaimjitter = v end })
    AA_Extra:AddSlider({ Name = "Delay", Default = 0, Min = 0.00, Max = 0.011, Flag = "AntiAimDelay", Round = 3, Callback = function(v) getgenv().antiaimdelayness = v end })
end

-- =========================================================
--  VISUALS MENU
-- =========================================================
do
    local ESP = VisualMenu:AddSection({ Position = 'left', Name = "ESP" })
    ESP:AddToggle({ Name = "Chinese ESP", Flag = "ChineseESP", Callback = function(v) getgenv().ChineseESP = v end })

    local PrefixData = { Prefix = " [Rainbow Hub] ", PrefixColor = Color3.fromRGB(255, 0, 0) }

    local function applyPrefix()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and v.Dev and v.AlphaTester and v.Booster then
                v.Dev.prefix = PrefixData.Prefix
                v.Dev.color = PrefixData.PrefixColor
                v.Dev.players[LocalPlayer.UserId] = true
                break
            end
        end
    end

    local proxy = setmetatable({}, {
        __index = function(_, key) return PrefixData[key] end,
        __newindex = function(_, key, newValue) PrefixData[key] = newValue end,
    })

    ESP:AddToggle({
        Name = "Prefix", Flag = "PrefixEnabled",
        Callback = function(v)
            if v then
                applyPrefix()
            else
                for _, v2 in pairs(getgc(true)) do
                    if type(v2) == "table" and v2.Dev and v2.AlphaTester and v2.Booster then
                        v2.Dev.players[LocalPlayer.UserId] = false
                        break
                    end
                end
            end
        end,
    })

    ESP:AddColorPicker({
        Name = "Prefix Color", Flag = "PrefixColor", Default = Color3.fromRGB(255, 0, 0),
        Callback = function(color) proxy.PrefixColor = color; applyPrefix() end,
    })
end

-- =========================================================
--  MISC MENU
-- =========================================================
do
    local Exploits = MiscMenu:AddSection({ Position = 'left', Name = "EXPLOITS" })

    Exploits:AddToggle({
        Name = "Remove Velocity", Flag = "RemoveVelocity", Risky = true,
        Callback = function(v)
            getgenv().RemoveVelocity = v
            if not getgenv().SpreadHooked and checkspecificfunction("hookmetamethod") then
                getgenv().SpreadHooked = true
                local oldIndex
                oldIndex = hookmetamethod(game, "__index", function(t, k)
                    if getgenv().RemoveVelocity and not checkcaller() then
                        if (k == "Velocity" or k == "AssemblyLinearVelocity") and t.Name == "HumanoidRootPart" then
                            return Vector3.new(0, 0, 0)
                        end
                    end
                    return oldIndex(t, k)
                end)
            end
        end,
    })

    Exploits:AddToggle({
        Name = "Remove Math.Random()", Flag = "RemoveMathRandom", Risky = true,
        Callback = function(v) getgenv().RemoveMathRandom = v end,
    })
end

-- =========================================================
--  SETTINGS MENU
-- =========================================================
do
    local MenuSect = SettingsMenu:AddSection({ Position = 'left', Name = "Menu" })
    MenuSect:AddKeybind({
        Name = "Keybind", Flag = "MenuToggleKey", Default = Enum.KeyCode.Insert,
        Callback = function(v) if v ~= nil then getgenv().OpenKey = v end end,
    })
    MenuSect:AddToggle({
        Name = "Ignore Game Processed", Flag = "IgnoreGP",
        Callback = function(v) getgenv().IgnoreGP = v end,
    })
end

-- =========================================================
--  AUTO-REJOIN ON KICK
-- =========================================================
game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    task.wait(0.5)
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

print("[penablox] loaded successfully")