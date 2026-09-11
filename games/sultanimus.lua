-- =========================================================
--  SULTANISIMUS HVH GAME SCRIPT (games/sultanisimus.lua)
--  Loaded by loader.lua
-- =========================================================

local F = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
if not F then warn("[sultanisimus] Failed to load Fatality UI.") return end
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
--  GLOBALS
-- =========================================================
getgenv().KillAll  = false
getgenv().AutoHeal = false

-- =========================================================
--  KILL ALL LOOP
-- =========================================================
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if not getgenv().KillAll then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                pcall(function()
                    local args = { "Shoot", plr.Character, "Head", true, 100 }
                    game:GetService("ReplicatedStorage"):WaitForChild("Dmg"):FireServer(unpack(args))
                end)
            end
        end
    end)
end)

-- =========================================================
--  AUTO HEAL LOOP
-- =========================================================
task.spawn(function()
    Workspace.ChildAdded:Connect(function(v)
        if not getgenv().AutoHeal then return end
        if v and v.Name == "ActiveHealingPart" then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    v:PivotTo(hrp.CFrame)
                end
            end)
        end
    end)
end)

-- =========================================================
--  FATALITY UI
-- =========================================================
F:Loader({ Name = "Rainbow Hub", Duration = 3 })

Notification:Notify({
    Title = "RAINBOW HUB",
    Content = "Welcome, " .. LocalPlayer.DisplayName,
    Icon = "clipboard",
})

local Window = F.new({ Name = "Rainbow Hub", Expire = "Sultanisimus", Keybind = "NONE" })
local Config = Window:AddConfig()
Config:Init("Hub_Sultan", "HubConfigs")

local menuVisible = true
getgenv().SultanOpenKey = Enum.KeyCode.Insert
getgenv().SultanIgnoreGP = false

UIS.InputBegan:Connect(function(input, gp)
    if gp and not getgenv().SultanIgnoreGP then return end
    if keyMatches(input, getgenv().SultanOpenKey) then
        menuVisible = not menuVisible
        pcall(function() Window:SetVisible(menuVisible) end)
    end
end)

local ExploitsMenu = Window:AddMenu({ Name = "Exploits", Icon = "settings" })
local MiscMenu     = Window:AddMenu({ Name = "Misc",     Icon = "cog" })
local InfoMenu     = Window:AddMenu({ Name = "Info",     Icon = "info" })

-- =========================================================
--  EXPLOITS
-- =========================================================
do
    local MainExploits = ExploitsMenu:AddSection({ Position = 'left', Name = "COMBAT" })

    MainExploits:AddToggle({
        Name = "Kill All",
        Flag = "SultanKillAll",
        Callback = function(value)
            getgenv().KillAll = value
            Notification:Notify({
                Title = "Rainbow Hub",
                Content = value and "Kill All enabled" or "Kill All disabled",
                Icon = value and "check" or "bell",
            })
        end,
    })

    MainExploits:AddToggle({
        Name = "Auto Heal",
        Flag = "SultanAutoHeal",
        Callback = function(value)
            getgenv().AutoHeal = value
            Notification:Notify({
                Title = "Rainbow Hub",
                Content = value and "Auto Heal enabled" or "Auto Heal disabled",
                Icon = value and "check" or "bell",
            })
        end,
    })
end

-- =========================================================
--  MISC
-- =========================================================
do
    local MiscSect = MiscMenu:AddSection({ Position = 'left', Name = "CHARACTER" })

    MiscSect:AddSlider({
        Name = "Walk Speed",
        Flag = "SultanSpeed",
        Default = 16,
        Min = 16,
        Max = 300,
        Callback = function(v)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end,
    })

    MiscSect:AddSlider({
        Name = "Jump Power",
        Flag = "SultanJump",
        Default = 50,
        Min = 0,
        Max = 500,
        Callback = function(v)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end,
    })

    MiscSect:AddToggle({
        Name = "Infinite Jump",
        Flag = "SultanInfJump",
        Callback = function(v) getgenv().SultanInfJump = v end,
    })

    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if getgenv().SultanInfJump and input.KeyCode == Enum.KeyCode.Space then
            pcall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end)
end

-- =========================================================
--  INFO
-- =========================================================
do
    local InfoSect = InfoMenu:AddSection({ Position = 'left', Name = "Info" })

    InfoSect:AddButton({
        Name = "Current Version",
        Callback = function()
            Notification:Notify({
                Title = "Rainbow Hub",
                Content = "Current version: 1.0 (Sultanisimus)",
                Icon = "clipboard",
            })
        end,
    })
end

print("[sultanisimus] loaded successfully")