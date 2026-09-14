-- =========================================================
--  PENABLOX HVH GAME SCRIPT (games/penablox.lua)
--  Loaded by loader.lua | v5.2 | HUB-COMPLETE + WalkSpeed 600
-- =========================================================

local F = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
if not F then warn("[penablox] Failed to load Fatality UI.") return end
local Notification = F:CreateNotifier()

local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local Pathfinding = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer

local function keyMatches(input, key)
    if key == nil then return false end
    if typeof(key) == "EnumItem" then return input.KeyCode == key end
    return input.KeyCode.Name == tostring(key)
end

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

getgenv().FakeLagEnabled   = false
getgenv().FakeLagStrength  = 200
getgenv().FakeLagInterval  = 400
getgenv().ShowLagEnabled   = false
getgenv().LagColor         = Color3.fromRGB(255, 100, 255)
getgenv().LagFillAlpha     = 0.5
getgenv().LagPartAlpha     = 0.4

getgenv().RapidFireEnabled = false
getgenv().RapidFireCount   = 5
getgenv().RapidFireDelay   = 0.01

getgenv().WalkbotEnabled   = false
getgenv().WalkbotBind      = Enum.KeyCode.K
getgenv().WalkbotSpeed     = 24
getgenv().WalkbotJump      = true
getgenv().WalkbotCrouch    = true
getgenv().WalkbotShowPath  = true
getgenv().WalkbotPathColor = Color3.fromRGB(0, 220, 80)

getgenv().PlayerWalkSpeed  = 16
getgenv().PlayerJumpPower  = 50

if getgenv().RageBotHitPos == "Auto" then
    if LocalPlayer:FindFirstChild("hitparts") then
        LocalPlayer.hitparts.Value = "Legs,Torso,Arms,Head"
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
        Notification:Notify({ Title = "Warning", Content = "getgc is missing.", Icon = "bell" })
        return
    end

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
    if not checkspecificfunction("getconnections") then return end
    if LocalPlayer:FindFirstChild("Mindmg") then
        LocalPlayer.Mindmg.Value = 1
    end
    local bob = workspace:FindFirstChild("Bob")
    if not bob then return end
    for _, conn in pairs(getconnections(bob.ChildAdded)) do
        pcall(function() conn:Disconnect() end)
    end
    for _, conn in pairs(getconnections(game:GetService("ReplicatedStorage").MainEvent.OnClientEvent)) do
        pcall(function() conn:Disconnect() end)
    end
end

-- =========================================================
--  PLAYER WALKSPEED LOOP
-- =========================================================
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if getgenv().WalkbotEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum.WalkSpeed ~= getgenv().PlayerWalkSpeed then
                hum.WalkSpeed = getgenv().PlayerWalkSpeed
            end
            if hum.UseJumpPower and hum.JumpPower ~= getgenv().PlayerJumpPower then
                hum.JumpPower = getgenv().PlayerJumpPower
            end
        end)
    end
end)

-- =========================================================
--  HELPERS
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
--  FAKE LAG + GHOST
-- =========================================================
local fakeLagT = {
    active = false,
    serverCF = nil,
    thread = nil,
    ghostModel = nil,
    ghostHL = nil,
}

local function lagOn()
    pcall(function()
        if setfflag then
            setfflag("DebugSimulatePacketLoss", "1")
            setfflag("DebugSimulatePacketLossPercent", "100")
            setfflag("DebugSimulateIncomingPacketLoss", "1")
            setfflag("DebugSimulateIncomingPacketLossPercent", "100")
        end
    end)
end

local function lagOff()
    pcall(function()
        if setfflag then
            setfflag("DebugSimulatePacketLoss", "0")
            setfflag("DebugSimulatePacketLossPercent", "0")
            setfflag("DebugSimulateIncomingPacketLoss", "0")
            setfflag("DebugSimulateIncomingPacketLossPercent", "0")
        end
    end)
end

local function destroyGhost()
    if fakeLagT.ghostModel then pcall(function() fakeLagT.ghostModel:Destroy() end) end
    if fakeLagT.ghostHL then pcall(function() fakeLagT.ghostHL:Destroy() end) end
    fakeLagT.ghostModel = nil
    fakeLagT.ghostHL = nil
end

local function createGhost()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    destroyGhost()

    local model = Instance.new("Model")
    model.Name = "RH_FakeLagGhost"

    local count = 0
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local p = Instance.new("Part")
            p.Name = part.Name
            p.Size = part.Size
            p.CFrame = part.CFrame
            p.Anchored = true
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
            p.CastShadow = false
            p.Massless = true
            p.Transparency = getgenv().LagPartAlpha or 0.4
            p.Material = Enum.Material.ForceField
            p.Color = getgenv().LagColor or Color3.fromRGB(255,100,255)
            p.Reflectance = 0
            p.Parent = model
            count = count + 1
        end
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent ~= char then
            local ancestor = part.Parent
            local isAccessory = false
            while ancestor and ancestor ~= char do
                if ancestor:IsA("Accessory") or ancestor:IsA("Tool") then
                    isAccessory = true
                    break
                end
                ancestor = ancestor.Parent
            end
            if not isAccessory and not model:FindFirstChild(part.Name) then
                local p = Instance.new("Part")
                p.Name = part.Name
                p.Size = part.Size
                p.CFrame = part.CFrame
                p.Anchored = true
                p.CanCollide = false
                p.CanQuery = false
                p.CanTouch = false
                p.CastShadow = false
                p.Massless = true
                p.Transparency = getgenv().LagPartAlpha or 0.4
                p.Material = Enum.Material.ForceField
                p.Color = getgenv().LagColor or Color3.fromRGB(255,100,255)
                p.Parent = model
                count = count + 1
            end
        end
    end

    model.Parent = workspace

    fakeLagT.ghostHL = Instance.new("Highlight")
    fakeLagT.ghostHL.Name = "RH_FakeLagGhostHL"
    fakeLagT.ghostHL.FillColor = getgenv().LagColor or Color3.fromRGB(255,100,255)
    fakeLagT.ghostHL.FillTransparency = getgenv().LagFillAlpha or 0.5
    fakeLagT.ghostHL.OutlineColor = getgenv().LagColor or Color3.fromRGB(255,100,255)
    fakeLagT.ghostHL.OutlineTransparency = 0
    fakeLagT.ghostHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    fakeLagT.ghostHL.Adornee = model
    fakeLagT.ghostHL.Parent = model

    fakeLagT.ghostModel = model
    return count > 0
end

local function updateGhost()
    if not fakeLagT.ghostModel then return end
    local char = LocalPlayer.Character
    if not char then destroyGhost() return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then destroyGhost() return end

    local serverCF = fakeLagT.serverCF
    if not serverCF then serverCF = hrp.CFrame end

    local offset = serverCF * hrp.CFrame:Inverse()

    for _, part in ipairs(fakeLagT.ghostModel:GetChildren()) do
        if part:IsA("BasePart") then
            local real = char:FindFirstChild(part.Name)
            if real and real:IsA("BasePart") then
                part.Size = real.Size
                part.CFrame = offset * real.CFrame
                part.Color = getgenv().LagColor or Color3.fromRGB(255,100,255)
            else
                part:Destroy()
            end
        end
    end

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and not fakeLagT.ghostModel:FindFirstChild(part.Name) then
            local p = Instance.new("Part")
            p.Name = part.Name
            p.Size = part.Size
            p.CFrame = offset * part.CFrame
            p.Anchored = true
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
            p.CastShadow = false
            p.Massless = true
            p.Transparency = getgenv().LagPartAlpha or 0.4
            p.Material = Enum.Material.ForceField
            p.Color = getgenv().LagColor or Color3.fromRGB(255,100,255)
            p.Parent = fakeLagT.ghostModel
        end
    end
end

local function stopFakeLag()
    if fakeLagT.thread then
        pcall(function() task.cancel(fakeLagT.thread) end)
        fakeLagT.thread = nil
    end
    lagOff()
    fakeLagT.active = false
    fakeLagT.serverCF = nil
end

local function startFakeLag()
    stopFakeLag()
    if not getgenv().FakeLagEnabled then return end
    fakeLagT.active = true
    fakeLagT.thread = task.spawn(function()
        while getgenv().FakeLagEnabled do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.1); continue end
            fakeLagT.serverCF = hrp.CFrame
            lagOn()
            task.wait(getgenv().FakeLagStrength / 1000)
            lagOff()
            task.wait(getgenv().FakeLagInterval / 1000)
        end
    end)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not (getgenv().ShowLagEnabled and getgenv().FakeLagEnabled) then
            destroyGhost()
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then destroyGhost() return end
        if not fakeLagT.ghostModel or not fakeLagT.ghostModel.Parent then
            createGhost()
        end
        updateGhost()
    end)
end)

-- =========================================================
--  RAPID FIRE
-- =========================================================
local rapidFireT = {active = false, thread = nil}

local function startRapidFire()
    if rapidFireT.thread then
        pcall(function() task.cancel(rapidFireT.thread) end)
        rapidFireT.thread = nil
    end
    if not getgenv().RapidFireEnabled then return end
    rapidFireT.active = true
    rapidFireT.thread = task.spawn(function()
        while getgenv().RapidFireEnabled do task.wait(0.1) end
    end)
end

local function stopRapidFire()
    if rapidFireT.thread then
        pcall(function() task.cancel(rapidFireT.thread) end)
        rapidFireT.thread = nil
    end
    rapidFireT.active = false
end

-- =========================================================
--  ANTI-AIM
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

    if not checkspecificfunction("require") then return end
    if getgenv().AAIsLooped then return end
    local AAHandler = require(game:GetService("ReplicatedFirst"):WaitForChild("AAHandler"))
    getgenv().AAIsLooped = true

    local unhit = {
        nextFlip = 0, currentType = "Jitter", currentYaw = 0, currentJitter = 120,
        currentDelay = 0.003, currentRandom = 0.9, currentBody = 0,
        currentPitchType = "Jitter", currentPitch = 0, paused = false, pauseUntil = 0,
    }
    local AA_TYPES = {"Static", "Jitter", "Offset", "Center", "3-Way", "5-Way", "Rainbow"}

    while task.wait(0.02) do
        if not AAHandler then return end
        if getgenv().AntiAimEnabled then
            local mode = getgenv().typeofantiaim or "Static"
            if mode == "Unhit" then
                local now = tick()
                if now >= unhit.nextFlip then
                    unhit.nextFlip = now + (math.random(30, 150) / 1000)
                    unhit.currentType = AA_TYPES[math.random(1, #AA_TYPES)]
                    unhit.currentYaw = math.random(-180, 180)
                    unhit.currentJitter = math.random(60, 180)
                    unhit.currentDelay = math.random(1, 8) / 1000
                    unhit.currentRandom = math.random(40, 100) / 100
                    unhit.currentBody = math.random(-80, 80)
                    unhit.currentPitchType = AA_TYPES[math.random(1, #AA_TYPES)]
                    unhit.currentPitch = math.random(-45, 45)
                    if math.random(1, 100) <= 15 then
                        unhit.paused = true
                        unhit.pauseUntil = now + (math.random(100, 300) / 1000)
                    end
                end
                if unhit.paused then
                    if now >= unhit.pauseUntil then
                        unhit.paused = false
                    else
                        pcall(function()
                            AAHandler.SendYawJitter(nil, "Static", 0, 0, 0, 0, 0, 0)
                            AAHandler.SendBodyYaw(nil, 0)
                            AAHandler.SendPitchMode(nil, "Static", 0, 0, 0, 0, 0, 0)
                        end)
                        continue
                    end
                end
                pcall(function()
                    AAHandler.SendYawJitter(nil, unhit.currentType, unhit.currentYaw, math.random(-180, 0), math.random(0, 180), unhit.currentJitter, unhit.currentDelay, unhit.currentRandom)
                    AAHandler.SendBodyYaw(nil, unhit.currentBody)
                    AAHandler.SendPitchMode(nil, unhit.currentPitchType, unhit.currentPitch, math.random(-45, 45), math.random(-45, 45), math.random(60, 180), math.random(1, 8) / 1000, math.random(40, 100) / 100)
                end)
            else
                pcall(function()
                    AAHandler.SendYawJitter(nil, mode, getgenv().BaseYawantiaim or 0, getgenv().leftantiaim or 0, getgenv().rightantiaim or 0, getgenv().antiaimjitter or 0, getgenv().antiaimdelayness or 0, getgenv().antiaimrandomness or 0)
                    AAHandler.SendBodyYaw(nil, getgenv().BodyYawantiaim or 0)
                    AAHandler.SendPitchMode(nil, "Static", getgenv().Pitchantiaim or 0, 0, 0, 0, 0, 0)
                end)
            end
        end
    end
end)

-- =========================================================
--  HUB RESOLVER
-- =========================================================
local HUB = {
    Enabled = true, Strength = 1.2, FovLimit = 25, ShowCham = false,
    ChamColor = Color3.fromRGB(255, 200, 0),
    samples = {}, lastYaw = {}, aaType = {}, side = {},
    chamParts = {}, chamHL = {},
}

local function normAngle(a) return math.atan2(math.sin(a), math.cos(a)) end
local function angleDiff(a, b) return math.abs(normAngle(a - b)) end
local function getHRPYaw(hrp)
    local look = hrp.CFrame.LookVector
    return math.atan2(look.X, look.Z)
end

task.spawn(function()
    while task.wait(0.02) do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local curYaw = getHRPYaw(hrp)
                    HUB.samples[plr] = HUB.samples[plr] or {}
                    table.insert(HUB.samples[plr], curYaw)
                    if #HUB.samples[plr] > 30 then table.remove(HUB.samples[plr], 1) end
                    HUB.lastYaw[plr] = curYaw
                end
            end
        end
    end
end)

local function classifyAA(plr)
    local s = HUB.samples[plr]
    if not s or #s < 6 then return "legit" end
    local total, flips = 0, 0
    for i = 2, #s do
        local d = angleDiff(s[i], s[i-1])
        total = total + d
        if math.sign(math.sin(s[i])) ~= math.sign(math.sin(s[i-1])) then flips = flips + 1 end
    end
    local avg = total / (#s - 1)
    if avg < math.rad(3) then return "legit" end
    if flips >= 2 then return "jitter" end
    if avg > math.rad(40) then return "spin" end
    return "static"
end

task.spawn(function()
    while task.wait(0.1) do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                HUB.aaType[plr] = classifyAA(plr)
            end
        end
    end
end)

local function hubResolve(plr)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0, "legit" end
    local type_ = HUB.aaType[plr] or "legit"
    if type_ == "legit" then return 0, "legit" end

    local correction = 0
    if type_ == "static" then
        correction = math.pi * 0.5
    elseif type_ == "jitter" then
        local s = HUB.side[plr] or 1
        HUB.side[plr] = -s
        correction = math.rad(90) * s
    elseif type_ == "spin" then
        local curYaw = getHRPYaw(hrp)
        local prevYaw = HUB.samples[plr][#HUB.samples[plr] - 1] or curYaw
        local delta = normAngle(curYaw - prevYaw)
        correction = delta * 3
    end

    local maxRad = math.rad(HUB.FovLimit)
    correction = math.clamp(correction, -maxRad, maxRad)
    return correction * HUB.Strength, type_
end

function ResolvePosition(plr, part)
    if not HUB.Enabled then return part.Position, nil end
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position, nil end
    local correction, type_ = hubResolve(plr)
    if correction == 0 then return part.Position, type_ end
    local rel = hrp.CFrame:ToObjectSpace(part.CFrame)
    local rotated = hrp.CFrame * CFrame.Angles(0, correction, 0) * rel
    return rotated.Position, type_
end

local function removeCham(plr)
    if HUB.chamParts[plr] then pcall(function() HUB.chamParts[plr]:Destroy() end); HUB.chamParts[plr] = nil end
    if HUB.chamHL[plr] then pcall(function() HUB.chamHL[plr]:Destroy() end); HUB.chamHL[plr] = nil end
end

local function makeCham(plr)
    if HUB.chamParts[plr] then return end
    local p = Instance.new("Part")
    p.Name = "RH_HUBCham"
    p.Size = Vector3.new(2.5, 5, 2.5)
    p.Anchored = true
    p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = HUB.ChamColor
    p.Transparency = 0.55
    p.Parent = workspace
    local hl = Instance.new("Highlight")
    hl.FillColor = HUB.ChamColor
    hl.FillTransparency = 0.7
    hl.OutlineColor = HUB.ChamColor
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = p
    hl.Parent = p
    HUB.chamParts[plr] = p
    HUB.chamHL[plr] = hl
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not HUB.ShowCham then
            for plr in pairs(HUB.chamParts) do removeCham(plr) end
            return
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local type_ = HUB.aaType[plr] or "legit"
                if char and hum and hum.Health > 0 and hrp and type_ ~= "legit" then
                    makeCham(plr)
                    local correction = hubResolve(plr)
                    local part = HUB.chamParts[plr]
                    if part then
                        part.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, correction, 0)
                        part.Color = HUB.ChamColor
                        HUB.chamHL[plr].FillColor = HUB.ChamColor
                        HUB.chamHL[plr].OutlineColor = HUB.ChamColor
                    end
                else
                    removeCham(plr)
                end
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    removeCham(plr)
    HUB.samples[plr] = nil
    HUB.lastYaw[plr] = nil
    HUB.aaType[plr] = nil
    HUB.side[plr] = nil
end)

-- =========================================================
--  WALKBOT
-- =========================================================
local Walkbot = {
    path = nil, waypoints = {}, wpIndex = 1, lastRepath = 0,
    target = nil, lastTargetPos = nil, pathParts = {},
    lastPos = nil, stuckTime = 0, defaultHipHeight = 2,
}

local function wbGetRoot(char) if not char then return nil end; return char:FindFirstChild("HumanoidRootPart") end
local function wbGetHumanoid(char) if not char then return nil end; return char:FindFirstChildOfClass("Humanoid") end
local function wbGetTeam(p) if not p then return nil end; if p.Team then return p.Team.Name end; return nil end
local function wbIsEnemy(p)
    if not p or p == LocalPlayer then return false end
    local a, b = wbGetTeam(LocalPlayer), wbGetTeam(p)
    if a and b then return a ~= b end
    return true
end

local function wbFindTarget()
    local myRoot = wbGetRoot(LocalPlayer.Character)
    if not myRoot then return nil end
    local best, bestDist = nil, 800
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and wbIsEnemy(plr) then
            local root = wbGetRoot(plr.Character)
            local hum = wbGetHumanoid(plr.Character)
            if root and hum and hum.Health > 0 then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < bestDist then bestDist = d; best = plr end
            end
        end
    end
    return best
end

local function wbClearPathVisual()
    for _, p in ipairs(Walkbot.pathParts) do pcall(function() p:Destroy() end) end
    Walkbot.pathParts = {}
end

local function wbComputePath(targetChar)
    local myRoot = wbGetRoot(LocalPlayer.Character)
    local targetRoot = wbGetRoot(targetChar)
    if not myRoot or not targetRoot then return false end
    local path = Pathfinding:CreatePath({
        AgentRadius = 2, AgentHeight = 5,
        AgentCanJump = true, AgentCanClimb = false,
        WaypointSpacing = 12,
    })
    local ok = pcall(function() path:ComputeAsync(myRoot.Position, targetRoot.Position) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then return false end
    local rawWps = path:GetWaypoints()
    local filtered = {}
    for i = 1, #rawWps, 2 do table.insert(filtered, rawWps[i]) end
    if #rawWps > 0 and filtered[#filtered] ~= rawWps[#rawWps] then
        table.insert(filtered, rawWps[#rawWps])
    end
    Walkbot.path = path
    Walkbot.waypoints = filtered
    Walkbot.wpIndex = 1
    Walkbot.lastTargetPos = targetRoot.Position
    return true
end

local function wbDrawPath()
    if not getgenv().WalkbotShowPath or #Walkbot.waypoints < 2 then
        wbClearPathVisual(); return
    end
    local needed = #Walkbot.waypoints - 1
    for i = needed + 1, #Walkbot.pathParts do
        if Walkbot.pathParts[i] then pcall(function() Walkbot.pathParts[i]:Destroy() end); Walkbot.pathParts[i] = nil end
    end
    for i = 1, needed do
        local a = Walkbot.waypoints[i].Position
        local b = Walkbot.waypoints[i + 1].Position
        local mid = (a + b) / 2
        local dir = b - a
        local len = dir.Magnitude
        if len >= 0.01 then
            local part = Walkbot.pathParts[i]
            if not part or not part.Parent then
                part = Instance.new("Part")
                part.Name = "RH_WalkPath"
                part.Anchored = true
                part.CanCollide = false; part.CanQuery = false; part.CanTouch = false; part.CastShadow = false
                part.Material = Enum.Material.SmoothPlastic
                part.Reflectance = 0
                part.Parent = workspace
                Walkbot.pathParts[i] = part
            end
            part.Size = Vector3.new(0.12, 0.12, len)
            part.CFrame = CFrame.new(mid, b)
            part.Color = getgenv().WalkbotPathColor
            part.Transparency = 0
        end
    end
end

local function wbApplyVelocity(myRoot, dir, speed)
    if dir.Magnitude < 0.01 then return end
    local md = dir.Unit
    local cv = myRoot.AssemblyLinearVelocity
    local tx, tz = md.X * speed, md.Z * speed
    local s = 0.25
    local nx = cv.X + (tx - cv.X) * s
    local nz = cv.Z + (tz - cv.Z) * s
    local hs = math.sqrt(nx*nx + nz*nz)
    if hs > speed then nx = (nx/hs)*speed; nz = (nz/hs)*speed end
    pcall(function() myRoot.AssemblyLinearVelocity = Vector3.new(nx, cv.Y, nz) end)
end

local function wbStopVelocity(myRoot)
    if not myRoot then return end
    local v = myRoot.AssemblyLinearVelocity
    pcall(function() myRoot.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0) end)
end

local wbJumpParams = RaycastParams.new()
wbJumpParams.FilterType = Enum.RaycastFilterType.Exclude
local function wbObstacleAhead(myRoot, myChar)
    wbJumpParams.FilterDescendantsInstances = {myChar}
    local origin = myRoot.Position + Vector3.new(0, -1, 0)
    return workspace:Raycast(origin, myRoot.CFrame.LookVector * 3, wbJumpParams) ~= nil
end

local wbCrouchParams = RaycastParams.new()
wbCrouchParams.FilterType = Enum.RaycastFilterType.Exclude
local function wbCeilingAbove(myRoot, myChar)
    wbCrouchParams.FilterDescendantsInstances = {myChar}
    local origin = myRoot.Position + Vector3.new(0, 3, 0)
    return workspace:Raycast(origin, Vector3.new(0, 3, 0), wbCrouchParams) ~= nil
end

local function wbApplyCrouch(hum, crouching)
    if not hum then return end
    if hum.RigType == Enum.HumanoidRigType.R15 then
        if crouching then hum.HipHeight = 1.2
        else if hum.HipHeight ~= Walkbot.defaultHipHeight then hum.HipHeight = Walkbot.defaultHipHeight end end
    end
end

local function wbIsStuck(myRoot)
    local now = tick()
    if not Walkbot.lastPos then Walkbot.lastPos = myRoot.Position; Walkbot.stuckTime = now; return false end
    local moved = (myRoot.Position - Walkbot.lastPos).Magnitude
    if moved < 0.3 then
        if now - Walkbot.stuckTime > 0.5 then
            Walkbot.stuckTime = now; Walkbot.lastPos = myRoot.Position; return true
        end
        return false
    else
        Walkbot.stuckTime = now; Walkbot.lastPos = myRoot.Position; return false
    end
end

task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if not getgenv().WalkbotEnabled then wbClearPathVisual(); return end

            local myChar = LocalPlayer.Character
            local myRoot = wbGetRoot(myChar)
            local myHum = wbGetHumanoid(myChar)
            if not myRoot or not myHum then wbClearPathVisual(); return end

            myHum.WalkSpeed = getgenv().WalkbotSpeed
            if myHum.UseJumpPower and myHum.JumpPower ~= 50 then myHum.JumpPower = 50 end

            local target = wbFindTarget()
            if not target then
                Walkbot.target = nil; Walkbot.path = nil; Walkbot.waypoints = {}
                wbClearPathVisual(); wbStopVelocity(myRoot); return
            end

            local targetRoot = wbGetRoot(target.Character)
            if not targetRoot then wbClearPathVisual(); wbStopVelocity(myRoot); return end

            local dist = (targetRoot.Position - myRoot.Position).Magnitude
            if dist < 4 then wbClearPathVisual(); wbStopVelocity(myRoot); return end

            if getgenv().WalkbotCrouch then
                wbApplyCrouch(myHum, wbCeilingAbove(myRoot, myChar))
            end

            local now = tick()
            local targetMoved = Walkbot.lastTargetPos and (targetRoot.Position - Walkbot.lastTargetPos).Magnitude > 12
            local targetChanged = Walkbot.target ~= target
            local needRepath = not Walkbot.path or targetChanged or targetMoved
                or (now - Walkbot.lastRepath > 3.0 and Walkbot.wpIndex > #Walkbot.waypoints)

            if needRepath then
                Walkbot.target = target
                Walkbot.lastRepath = now
                wbComputePath(target.Character)
            end

            local moveDir = nil
            local speed = getgenv().WalkbotSpeed

            if #Walkbot.waypoints > 0 and Walkbot.wpIndex <= #Walkbot.waypoints then
                local targetIdx = Walkbot.wpIndex
                local curWp = Walkbot.waypoints[Walkbot.wpIndex]
                if curWp then
                    local curDist = (curWp.Position - myRoot.Position).Magnitude
                    if curDist < 6 and Walkbot.wpIndex < #Walkbot.waypoints then
                        targetIdx = Walkbot.wpIndex + 1
                    end
                end
                local aimWp = Walkbot.waypoints[targetIdx]
                if aimWp then
                    local d = aimWp.Position - myRoot.Position
                    moveDir = Vector3.new(d.X, 0, d.Z)
                    if aimWp.Action == Enum.PathWaypointAction.Jump and d.Magnitude < 6 then myHum.Jump = true end
                end
                if curWp and (curWp.Position - myRoot.Position).Magnitude < 4 then
                    if curWp.Action == Enum.PathWaypointAction.Jump then myHum.Jump = true end
                    Walkbot.wpIndex = Walkbot.wpIndex + 1
                end
            end

            if not moveDir and dist < 150 then
                local d = targetRoot.Position - myRoot.Position
                moveDir = Vector3.new(d.X, 0, d.Z)
            end

            if moveDir then wbApplyVelocity(myRoot, moveDir, speed) else wbStopVelocity(myRoot) end

            if getgenv().WalkbotJump then
                if wbIsStuck(myRoot) then myHum.Jump = true end
                if wbObstacleAhead(myRoot, myChar) then
                    local v = myRoot.AssemblyLinearVelocity
                    local hs = math.sqrt(v.X*v.X + v.Z*v.Z)
                    if hs < speed * 0.5 then myHum.Jump = true end
                end
            end

            wbDrawPath()
        end)
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == getgenv().WalkbotBind then
        getgenv().WalkbotEnabled = not getgenv().WalkbotEnabled
        Notification:Notify({
            Title = "Walkbot",
            Content = getgenv().WalkbotEnabled and "Enabled" or "Disabled",
            Icon = "clipboard",
        })
        if not getgenv().WalkbotEnabled then wbClearPathVisual() end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    Walkbot.path = nil; Walkbot.waypoints = {}; Walkbot.wpIndex = 1
    Walkbot.target = nil; Walkbot.lastTargetPos = nil; Walkbot.lastPos = nil
    wbClearPathVisual()
    local hum = wbGetHumanoid(LocalPlayer.Character)
    if hum and hum.RigType == Enum.HumanoidRigType.R15 then
        hum.HipHeight = Walkbot.defaultHipHeight
    end
end)

LocalPlayer.CharacterRemoving:Connect(wbClearPathVisual)

-- =========================================================
--  MAIN HOOK
-- =========================================================
task.spawn(function()
    if not checkspecificfunction("hookfunction") then
        Notification:Notify({ Title = "Warning", Content = "hookfunction is missing.", Icon = "bell" })
        return
    end
    pcall(function()
        local oldFireServer
        oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
            local args = {...}
            if tostring(self) == "MainEvent" then
                local action = decryptstring(args[1])

                if getgenv().RageBotEnabled and (action == "Shoot" or action == "MeleeHit") then
                    if getgenv().RageBotMethod == "Event Hook" then
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
                                        local resolved = ResolvePosition(target, tuffpart)
                                        args[7] = resolved or tuffpart.Position
                                        if typeof(args[6]) == "Vector3" then args[5] = (args[6] - args[7]).Magnitude end
                                    else
                                        args[7] = AutoPart
                                        if typeof(args[6]) == "Vector3" and typeof(AutoPart) == "Vector3" then
                                            args[5] = (args[6] - AutoPart).Magnitude
                                        end
                                    end
                                else
                                    local tpart = target.Character[HitPos]
                                    if tpart then
                                        local resolved = ResolvePosition(target, tpart)
                                        args[7] = resolved or tpart.Position
                                        if typeof(args[6]) == "Vector3" then args[5] = (args[6] - args[7]).Magnitude end
                                    end
                                end
                                args[8] = encryptstring("nil")
                                args[9] = encryptstring("nil")
                            end
                        end
                    end
                end

                if getgenv().RapidFireEnabled and (action == "Shoot" or action == "MeleeHit") then
                    for i = 1, getgenv().RapidFireCount do
                        oldFireServer(self, unpack(args))
                        task.wait(getgenv().RapidFireDelay)
                    end
                    return
                end
            end
            return oldFireServer(self, unpack(args))
        end)
    end)
end)

-- =========================================================
--  MOVEMENT MODULE HOOK
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
--  INFINITE AMMO
-- =========================================================
task.spawn(function()
    while task.wait(1) do
        local s = pcall(function()
            if getgenv().InfiniteAmmo then
                game:GetService("ReplicatedStorage"):WaitForChild("Reload"):FireServer()
            end
        end)
        if not s then break end
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
local WalkbotMenu  = Window:AddMenu({ Name = "Walkbot",  Icon = "crosshair" })
local SettingsMenu = Window:AddMenu({ Name = "Settings", Icon = "cog" })

-- RAGE MENU
do
    local MainRage    = RageMenu:AddSection({ Position = 'left',   Name = "HUB RESOLVER" })
    local ExploitSect = RageMenu:AddSection({ Position = 'center', Name = "EXPLOITS" })
    local ExtaSect    = RageMenu:AddSection({ Position = 'right',  Name = "CONFIGURATION" })

    MainRage:AddToggle({ Name = "HUB Resolver", Flag = "HUBEnabled", Default = true,
        Callback = function(v) HUB.Enabled = v end })
    MainRage:AddToggle({ Name = "Show Resolved Cham", Flag = "HUBShowCham", Default = false,
        Callback = function(v) HUB.ShowCham = v; if not v then for plr in pairs(HUB.chamParts) do removeCham(plr) end end end })
    MainRage:AddColorPicker({ Name = "Cham Color", Flag = "HUBChamColor", Default = Color3.fromRGB(255, 200, 0),
        Callback = function(c)
            HUB.ChamColor = c
            for plr, part in pairs(HUB.chamParts) do
                if part then part.Color = c end
                if HUB.chamHL[plr] then HUB.chamHL[plr].FillColor = c; HUB.chamHL[plr].OutlineColor = c end
            end
        end })
    MainRage:AddSlider({ Name = "Strength", Flag = "HUBStr", Default = 1.2, Min = 0, Max = 3, Round = 2,
        Callback = function(v) HUB.Strength = v end })
    MainRage:AddSlider({ Name = "FOV Limit", Flag = "HUBFov", Default = 25, Min = 5, Max = 90, Round = 0,
        Callback = function(v) HUB.FovLimit = v end })

    local forcehittoggle = ExploitSect:AddToggle({
        Name = "Force Hit", Flag = "ForceHitEnabled", Risky = true, Option = true,
        Callback = function(v) getgenv().RageBotEnabled = v; if v then disabledefaultragebot() end end })
    forcehittoggle.Option:AddDropdown({ Name = "Method", Flag = "ForceHitMethod",
        Values = {"Event Hook"}, Default = "Event Hook",
        Callback = function(v) getgenv().RageBotMethod = v end })
    forcehittoggle.Option:AddDropdown({ Name = "Hit Position", Flag = "ForceHitHitPos",
        Values = {"Auto","Head","Torso","HumanoidRootPart","Arms","Legs"}, Default = "Auto",
        Callback = function(v)
            getgenv().RageBotHitPos = v
            if v == "Auto" and LocalPlayer:FindFirstChild("hitparts") then
                LocalPlayer.hitparts.Value = "Legs,Torso,Arms,Head"
            end
        end })
    forcehittoggle.Option:AddDropdown({ Name = "Damage Part", Flag = "ForceHitDamagePart",
        Values = {"Head","Torso","HumanoidRootPart","Arms","Legs"}, Default = "Head",
        Callback = function(v) getgenv().RageBotHitPart = v end })

    ExploitSect:AddToggle({ Name = "Infinite Ammo", Flag = "InfiniteAmmo", Risky = true,
        Callback = function(v) getgenv().InfiniteAmmo = v end })

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

    ExploitSect:AddToggle({ Name = "Spread Modifier", Flag = "NoSpread", Risky = true,
        Callback = function(v)
            getgenv().NoSpread = v
            if v then setspread(0, 0, 0, 0, 0, 0, 0, 0)
            else setspread(0.5, 2.5, 15, 0.01, 15, 2, 0.2, 0.3) end
        end })
    ExploitSect:AddSlider({ Name = "Spread Amount", Flag = "SpreadAmount", Default = 0, Min = 0, Max = 15,
        Callback = function(v) if v and getgenv().NoSpread then setspread(0, 0, 0, v, v, 0, 0, 0) end end })

    ExtaSect:AddToggle({ Name = "Disable In-Game Resolver", Flag = "DisableInGameResolver",
        Callback = function(v)
            if v and LocalPlayer:FindFirstChild("ResolverEnabled") then
                LocalPlayer.ResolverEnabled.Value = false
            elseif not v and LocalPlayer:FindFirstChild("ResolverEnabled") then
                LocalPlayer.ResolverEnabled.Value = true
            end
        end })

    local RapidFireSec = RageMenu:AddSection({ Position = 'center', Name = "RAPID FIRE" })
    RapidFireSec:AddToggle({ Name = "Rapid Fire", Flag = "RapidFireEnabled", Default = false,
        Callback = function(v) getgenv().RapidFireEnabled = v; if v then startRapidFire() else stopRapidFire() end end })
    RapidFireSec:AddSlider({ Name = "Bullets per Shot", Flag = "RapidFireCount", Default = 5, Min = 1, Max = 20, Round = 0,
        Callback = function(v) getgenv().RapidFireCount = v end })
    RapidFireSec:AddSlider({ Name = "Delay (s)", Flag = "RapidFireDelay", Default = 0.01, Min = 0.001, Max = 0.1, Round = 3,
        Callback = function(v) getgenv().RapidFireDelay = v end })
end

-- ANTI-AIM MENU
do
    local AA_General = AntiAimMenu:AddSection({ Position = 'left',   Name = "GENERAL" })
    local AA_Angles  = AntiAimMenu:AddSection({ Position = 'center', Name = "ANGLES" })
    local AA_Extra   = AntiAimMenu:AddSection({ Position = 'right',  Name = "EXTRA" })

    AA_General:AddToggle({ Name = "Enable Anti-Aim", Flag = "AntiAimEnabled",
        Callback = function(v) getgenv().AntiAimEnabled = v end })
    AA_General:AddDropdown({ Name = "Mode", Flag = "AntiAimMode",
        Values = {"Static","Offset","Center","3-Way","5-Way","Off","Rainbow","Unhit"},
        Default = "Static",
        Callback = function(v) getgenv().typeofantiaim = v end })

    AA_Angles:AddSlider({ Name = "Base Yaw",  Default = 0, Min = -180, Max = 180, Flag = "BaseYaw",  Callback = function(v) getgenv().BaseYawantiaim = v end })
    AA_Angles:AddSlider({ Name = "Yaw Left",  Default = 0, Min = -180, Max = 180, Flag = "YawLeft",  Callback = function(v) getgenv().leftantiaim = v end })
    AA_Angles:AddSlider({ Name = "Yaw Right", Default = 0, Min = -180, Max = 180, Flag = "YawRight", Callback = function(v) getgenv().rightantiaim = v end })
    AA_Angles:AddSlider({ Name = "Pitch",     Default = 0, Min = -90,  Max = 90,  Flag = "Pitch",    Callback = function(v) getgenv().Pitchantiaim = v end })
    AA_Angles:AddSlider({ Name = "Body Yaw",  Default = 0, Min = -80,  Max = 80,  Flag = "BodyYaw",  Callback = function(v) getgenv().BodyYawantiaim = v end })

    AA_Extra:AddSlider({ Name = "Jitter Amount", Default = 0, Max = 180, Flag = "JitterAmount",  Callback = function(v) getgenv().antiaimjitter = v end })
    AA_Extra:AddSlider({ Name = "Delay", Default = 0, Min = 0.00, Max = 0.011, Flag = "AntiAimDelay", Round = 3, Callback = function(v) getgenv().antiaimdelayness = v end })
end

-- VISUALS MENU
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
    ESP:AddToggle({ Name = "Prefix", Flag = "PrefixEnabled",
        Callback = function(v)
            if v then applyPrefix()
            else
                for _, v2 in pairs(getgc(true)) do
                    if type(v2) == "table" and v2.Dev and v2.AlphaTester and v2.Booster then
                        v2.Dev.players[LocalPlayer.UserId] = false
                        break
                    end
                end
            end
        end })
    ESP:AddColorPicker({ Name = "Prefix Color", Flag = "PrefixColor", Default = Color3.fromRGB(255, 0, 0),
        Callback = function(color) proxy.PrefixColor = color; applyPrefix() end })
end

-- MISC MENU
do
    local Exploits = MiscMenu:AddSection({ Position = 'left', Name = "EXPLOITS" })
    Exploits:AddToggle({ Name = "Remove Velocity", Flag = "RemoveVelocity", Risky = true,
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
        end })
    Exploits:AddToggle({ Name = "Remove Math.Random()", Flag = "RemoveMathRandom", Risky = true,
        Callback = function(v) getgenv().RemoveMathRandom = v end })

    local FakeLagSec = MiscMenu:AddSection({ Position = 'center', Name = "FAKE LAG" })
    FakeLagSec:AddToggle({ Name = "Fake Lag", Flag = "FakeLagEnabled", Default = false,
        Callback = function(v) getgenv().FakeLagEnabled = v; if v then startFakeLag() else stopFakeLag() end end })
    FakeLagSec:AddSlider({ Name = "Strength (ms)", Flag = "FakeLagStrength", Default = 200, Min = 50, Max = 1000, Round = 0,
        Callback = function(v) getgenv().FakeLagStrength = v; if getgenv().FakeLagEnabled then startFakeLag() end end })
    FakeLagSec:AddSlider({ Name = "Interval (ms)", Flag = "FakeLagInterval", Default = 400, Min = 50, Max = 2000, Round = 0,
        Callback = function(v) getgenv().FakeLagInterval = v; if getgenv().FakeLagEnabled then startFakeLag() end end })
    FakeLagSec:AddToggle({ Name = "Show Ghost", Flag = "ShowLagEnabled", Default = false,
        Callback = function(v) getgenv().ShowLagEnabled = v; if not v then destroyGhost() end end })
    FakeLagSec:AddColorPicker({ Name = "Ghost Color", Flag = "LagColor", Default = Color3.fromRGB(255, 100, 255),
        Callback = function(c)
            getgenv().LagColor = c
            if fakeLagT.ghostHL then fakeLagT.ghostHL.FillColor = c; fakeLagT.ghostHL.OutlineColor = c end
            if fakeLagT.ghostModel then
                for _, p in ipairs(fakeLagT.ghostModel:GetChildren()) do
                    if p:IsA("BasePart") then p.Color = c end
                end
            end
        end })
    FakeLagSec:AddSlider({ Name = "Ghost Fill Alpha", Flag = "LagFillAlpha", Default = 0.5, Min = 0, Max = 1, Round = 2,
        Callback = function(c)
            getgenv().LagFillAlpha = c
            if fakeLagT.ghostHL then fakeLagT.ghostHL.FillTransparency = c end
        end })
    FakeLagSec:AddSlider({ Name = "Ghost Part Alpha", Flag = "LagPartAlpha", Default = 0.4, Min = 0, Max = 1, Round = 2,
        Callback = function(c)
            getgenv().LagPartAlpha = c
            if fakeLagT.ghostModel then
                for _, p in ipairs(fakeLagT.ghostModel:GetChildren()) do
                    if p:IsA("BasePart") then p.Transparency = c end
                end
            end
        end })
end

-- WALKBOT MENU
do
    local WBSec = WalkbotMenu:AddSection({ Position = 'left', Name = "WALKBOT" })

    WBSec:AddToggle({ Name = "Enable Walkbot", Flag = "WalkbotEnabled", Default = false,
        Callback = function(v)
            getgenv().WalkbotEnabled = v
            if not v then wbClearPathVisual() end
        end })

    WBSec:AddKeybind({ Name = "Toggle Bind", Flag = "WalkbotBind", Default = Enum.KeyCode.K,
        Callback = function(v) if v ~= nil then getgenv().WalkbotBind = v end end })

    WBSec:AddSlider({ Name = "Walk Speed", Flag = "WalkbotSpeed", Default = 24, Min = 10, Max = 600, Round = 0,
        Callback = function(v) getgenv().WalkbotSpeed = v end })

    WBSec:AddToggle({ Name = "Auto Jump", Flag = "WalkbotJump", Default = true,
        Callback = function(v) getgenv().WalkbotJump = v end })

    WBSec:AddToggle({ Name = "Auto Crouch", Flag = "WalkbotCrouch", Default = true,
        Callback = function(v) getgenv().WalkbotCrouch = v end })

    WBSec:AddToggle({ Name = "Show Path", Flag = "WalkbotShowPath", Default = true,
        Callback = function(v)
            getgenv().WalkbotShowPath = v
            if not v then wbClearPathVisual() end
        end })

    WBSec:AddColorPicker({ Name = "Path Color", Flag = "WalkbotPathColor", Default = Color3.fromRGB(0, 220, 80),
        Callback = function(c)
            getgenv().WalkbotPathColor = c
            for _, p in ipairs(Walkbot.pathParts) do
                if p and p.Parent then p.Color = c end
            end
        end })

    WBSec:AddButton({ Name = "Reset Walkbot State", Callback = function()
        Walkbot.path = nil
        Walkbot.waypoints = {}
        Walkbot.wpIndex = 1
        Walkbot.target = nil
        wbClearPathVisual()
        Notification:Notify({ Title = "Walkbot", Content = "State reset", Icon = "clipboard" })
    end })
end

-- SETTINGS MENU
do
    local CharSect = SettingsMenu:AddSection({ Position = 'left', Name = "CHARACTER" })

    CharSect:AddSlider({ Name = "WalkSpeed", Flag = "PlayerWalkSpeed", Default = 16, Min = 8, Max = 600, Round = 0,
        Callback = function(v)
            getgenv().PlayerWalkSpeed = v
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end })

    CharSect:AddSlider({ Name = "Jump Power", Flag = "PlayerJumpPower", Default = 50, Min = 20, Max = 600, Round = 0,
        Callback = function(v)
            getgenv().PlayerJumpPower = v
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.UseJumpPower then hum.JumpPower = v end
        end })

    CharSect:AddButton({ Name = "Apply Now", Callback = function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = getgenv().PlayerWalkSpeed
            if hum.UseJumpPower then hum.JumpPower = getgenv().PlayerJumpPower end
        end
        Notification:Notify({ Title = "Character", Content = "Applied", Icon = "clipboard" })
    end })

    CharSect:AddButton({ Name = "Reset to Default", Callback = function()
        getgenv().PlayerWalkSpeed = 16
        getgenv().PlayerJumpPower = 50
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            if hum.UseJumpPower then hum.JumpPower = 50 end
        end
        Notification:Notify({ Title = "Character", Content = "Reset to default", Icon = "clipboard" })
    end })

    local MenuSect = SettingsMenu:AddSection({ Position = 'center', Name = "Menu" })
    MenuSect:AddKeybind({ Name = "Menu Keybind", Flag = "MenuToggleKey", Default = Enum.KeyCode.Insert,
        Callback = function(v) if v ~= nil then getgenv().OpenKey = v end end })
    MenuSect:AddToggle({ Name = "Ignore Game Processed", Flag = "IgnoreGP",
        Callback = function(v) getgenv().IgnoreGP = v end })
end

-- AUTO-REJOIN
game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    task.wait(0.5)
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

Notification:Notify({
    Title = "RAINBOW HUB",
    Content = "Walkbot bind: " .. getgenv().WalkbotBind.Name,
    Icon = "clipboard",
})

print("[penablox] loaded — HUB v5.2 | WalkSpeed 600 max")
