-- =========================================================================
-- NINJA LEGENDS | Rainbow Hub | Fatality UI
-- File: games/ninjalegends.lua
-- =========================================================================

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RS        = game:GetService("ReplicatedStorage")
local UIS       = game:GetService("UserInputService")
local LP        = Players.LocalPlayer

-- =========================================================================
-- FATALITY LOADER
-- =========================================================================
local function GetFatality()
    local ok, F = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
    end)
    if not ok or not F then
        warn("[NL] Fatality load failed")
        return nil
    end
    return F
end

local F = GetFatality()
if not F then return end

if getgenv().NL_Loaded then
    warn("[NL] Already loaded")
    return
end
getgenv().NL_Loaded = true

local Notif = F:CreateNotifier()
F:Loader({ Name = "Rainbow Hub", Duration = 3 })
Notif:Notify({ Title = "RAINBOW HUB", Content = "Ninja Legends", Icon = "clipboard" })

local Window = F.new({ Name = "Rainbow Hub", Expire = "Ninja Legends", Keybind = "NONE" })
local Config = Window:AddConfig()
Config:Init("Hub_Ninja", "HubConfigs")

-- =========================================================================
-- MENUS
-- =========================================================================
local MainMenu = Window:AddMenu({ Name = "Main",     Icon = "settings" })
local FarmMenu = Window:AddMenu({ Name = "AutoFarm", Icon = "skull" })
local BuyMenu  = Window:AddMenu({ Name = "AutoBuy",  Icon = "crosshair" })
local ChiMenu  = Window:AddMenu({ Name = "Collect",  Icon = "eye" })
local TpMenu   = Window:AddMenu({ Name = "Teleport", Icon = "eye" })
local CryMenu  = Window:AddMenu({ Name = "Crystal",  Icon = "shield" })
local MiscMenu = Window:AddMenu({ Name = "Misc",     Icon = "cog" })

-- =========================================================================
-- STATE
-- =========================================================================
local G = {
    AutoSwing        = false,
    AutoSell         = false,
    AutoBuySword     = false,
    AutoBuyBelts     = false,
    AutoBuySkills    = false,
    AutoBuyShurikens = false,
    AutoFarmChi      = false,
    AutoFarmCoin     = false,
    AutoHoops        = false,
    OpenCrystal      = false,
    CrystalName      = "",
    Invisibility     = false,
    InfJump          = false,
}

local ninjaEvent = LP:WaitForChild("ninjaEvent", 10)

-- =========================================================================
-- MAIN — CHARACTER
-- =========================================================================
do
    local S = MainMenu:AddSection({ Position = "left", Name = "CHARACTER" })

    S:AddSlider({
        Name = "Speed",
        Flag = "NL_Speed",
        Default = 16, Min = 0, Max = 500,
        Callback = function(v)
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end,
    })

    S:AddSlider({
        Name = "Jump Power",
        Flag = "NL_Jump",
        Default = 50, Min = 0, Max = 500,
        Callback = function(v)
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then
                pcall(function() h.UseJumpPower = true end)
                h.JumpPower = v
            end
        end,
    })

    S:AddToggle({
        Name = "Inf Jump",
        Flag = "NL_InfJump",
        Default = false,
        Callback = function(v) G.InfJump = v end,
    })

    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if G.InfJump and input.KeyCode == Enum.KeyCode.Space then
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end

-- =========================================================================
-- AUTO FARM
-- =========================================================================
do
    local S = FarmMenu:AddSection({ Position = "left", Name = "AUTO FARM" })

    S:AddToggle({
        Name = "Auto Swing",
        Flag = "NL_AutoSwing",
        Default = false,
        Callback = function(v)
            G.AutoSwing = v
            task.spawn(function()
                while G.AutoSwing do
                    task.wait(0.1)
                    pcall(function()
                        if ninjaEvent then
                            ninjaEvent:FireServer("swingKatana")
                        end
                    end)
                end
            end)
        end,
    })

    S:AddToggle({
        Name = "Auto Sell",
        Flag = "NL_AutoSell",
        Default = false,
        Callback = function(v)
            G.AutoSell = v
            task.spawn(function()
                while G.AutoSell do
                    task.wait(0.1)
                    pcall(function()
                        local sf  = Workspace:FindFirstChild("sellAreaCircles")
                        local c   = sf and sf:FindFirstChild("sellAreaCircle15")
                        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        local dst = Workspace:FindFirstChild("Part")
                        if c and c:FindFirstChild("circleInner") and hrp and dst then
                            c.circleInner.CFrame = hrp.CFrame
                            task.wait()
                            c.circleInner.CFrame = dst.CFrame
                        end
                    end)
                end
            end)
        end,
    })
end

-- =========================================================================
-- AUTO BUY
-- =========================================================================
do
    local S = BuyMenu:AddSection({ Position = "left", Name = "AUTO BUY" })
    local ISLAND = "Blazing Vortex Island"

    S:AddToggle({
        Name = "Auto Buy Swords",
        Flag = "NL_BuySwords",
        Default = false,
        Callback = function(v)
            G.AutoBuySword = v
            task.spawn(function()
                while G.AutoBuySword do
                    task.wait(0.5)
                    pcall(function()
                        if ninjaEvent then
                            ninjaEvent:FireServer("buyAllSwords", ISLAND)
                        end
                    end)
                end
            end)
        end,
    })

    S:AddToggle({
        Name = "Auto Buy Belts",
        Flag = "NL_BuyBelts",
        Default = false,
        Callback = function(v)
            G.AutoBuyBelts = v
            task.spawn(function()
                while G.AutoBuyBelts do
                    task.wait(0.5)
                    pcall(function()
                        if ninjaEvent then
                            ninjaEvent:FireServer("buyAllBelts", ISLAND)
                        end
                    end)
                end
            end)
        end,
    })

    S:AddToggle({
        Name = "Auto Buy Skills",
        Flag = "NL_BuySkills",
        Default = false,
        Callback = function(v)
            G.AutoBuySkills = v
            task.spawn(function()
                while G.AutoBuySkills do
                    task.wait(0.5)
                    pcall(function()
                        if ninjaEvent then
                            ninjaEvent:FireServer("buyAllSkills", ISLAND)
                        end
                    end)
                end
            end)
        end,
    })

    S:AddToggle({
        Name = "Auto Buy Shurikens",
        Flag = "NL_BuyShurikens",
        Default = false,
        Callback = function(v)
            G.AutoBuyShurikens = v
            task.spawn(function()
                while G.AutoBuyShurikens do
                    task.wait(0.5)
                    pcall(function()
                        if ninjaEvent then
                            ninjaEvent:FireServer("buyAllShurikens", ISLAND)
                        end
                    end)
                end
            end)
        end,
    })
end

-- =========================================================================
-- COLLECT (Chi / Coin / Hoops)
-- =========================================================================
do
    local S = ChiMenu:AddSection({ Position = "left", Name = "COLLECT" })

    S:AddToggle({
        Name = "Auto Farm Chi",
        Flag = "NL_FarmChi",
        Default = false,
        Callback = function(v)
            G.AutoFarmChi = v
            task.spawn(function()
                while G.AutoFarmChi do
                    task.wait(0.3)
                    pcall(function()
                        local sc     = Workspace:FindFirstChild("spawnedCoins")
                        local valley = sc and sc:FindFirstChild("Valley")
                        local hrp    = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if valley and hrp then
                            for _, c in ipairs(valley:GetChildren()) do
                                if c.Name == "Blue Chi Crate" then
                                    hrp.CFrame = CFrame.new(c.Position)
                                    task.wait(0.2)
                                    break
                                end
                            end
                        end
                    end)
                end
            end)
        end,
    })

    S:AddToggle({
        Name = "Auto Farm Coin",
        Flag = "NL_FarmCoin",
        Default = false,
        Callback = function(v)
            G.AutoFarmCoin = v
            task.spawn(function()
                while G.AutoFarmCoin do
                    task.wait(0.3)
                    pcall(function()
                        local sc     = Workspace:FindFirstChild("spawnedCoins")
                        local valley = sc and sc:FindFirstChild("Valley")
                        local hrp    = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if valley and hrp then
                            for _, c in ipairs(valley:GetChildren()) do
                                if c.Name == "Purple Coin Crate" then
                                    hrp.CFrame = CFrame.new(c.Position)
                                    task.wait(0.2)
                                    break
                                end
                            end
                        end
                    end)
                end
            end)
        end,
    })

    S:AddToggle({
        Name = "Auto Hoops",
        Flag = "NL_Hoops",
        Default = false,
        Callback = function(v)
            G.AutoHoops = v
            task.spawn(function()
                while G.AutoHoops do
                    task.wait(0.3)
                    pcall(function()
                        local hoops = Workspace:FindFirstChild("Hoops")
                        local hrp   = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if hoops and hrp then
                            for _, h in ipairs(hoops:GetDescendants()) do
                                if h.ClassName == "MeshPart" and h:FindFirstChild("touchPart") then
                                    h.touchPart.CFrame = hrp.CFrame
                                end
                            end
                        end
                    end)
                end
            end)
        end,
    })
end

-- =========================================================================
-- TELEPORT — ISLANDS
-- =========================================================================
do
    local S = TpMenu:AddSection({ Position = "left", Name = "ISLANDS" })

    local islandList = {}
    pcall(function()
        local folder = Workspace:FindFirstChild("islandUnlockParts")
        if folder then
            for _, v in ipairs(folder:GetChildren()) do
                table.insert(islandList, v.Name)
            end
        end
    end)
    if #islandList == 0 then islandList = { "None" } end

    S:AddDropdown({
        Name = "Select Island",
        Flag = "NL_TpIsland",
        Values = islandList,
        Default = islandList[1],
        Callback = function(v) getgenv().NL_TpIsl = v end,
    })

    S:AddButton({
        Name = "Teleport",
        Callback = function()
            pcall(function()
                local isl    = getgenv().NL_TpIsl
                local folder = Workspace:FindFirstChild("islandUnlockParts")
                local part   = folder and folder:FindFirstChild(isl)
                local hrp    = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if part and part:FindFirstChild("islandSignPart") and hrp then
                    hrp.CFrame = part.islandSignPart.CFrame
                end
            end)
        end,
    })

    S:AddButton({
        Name = "Unlock All Islands",
        Callback = function()
            task.spawn(function()
                pcall(function()
                    local hrp    = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local folder = Workspace:FindFirstChild("islandUnlockParts")
                    if not hrp or not folder then return end
                    for _, v in ipairs(folder:GetChildren()) do
                        if v:FindFirstChild("islandSignPart") then
                            hrp.CFrame = v.islandSignPart.CFrame
                            task.wait(0.2)
                        end
                    end
                end)
            end)
        end,
    })
end

-- =========================================================================
-- CRYSTAL
-- =========================================================================
do
    local S = CryMenu:AddSection({ Position = "left", Name = "CRYSTALS" })

    local crystalList = {}
    pcall(function()
        local folder = Workspace:FindFirstChild("mapCrystalsFolder")
        if folder then
            for _, v in ipairs(folder:GetChildren()) do
                table.insert(crystalList, v.Name)
            end
        end
    end)
    if #crystalList == 0 then crystalList = { "None" } end

    S:AddDropdown({
        Name = "Select Crystal",
        Flag = "NL_CrystalName",
        Values = crystalList,
        Default = crystalList[1],
        Callback = function(v) G.CrystalName = v end,
    })

    S:AddToggle({
        Name = "Open Crystal",
        Flag = "NL_OpenCrystal",
        Default = false,
        Callback = function(v)
            G.OpenCrystal = v
            task.spawn(function()
                while G.OpenCrystal do
                    task.wait(0.1)
                    pcall(function()
                        local rEvents = RS:FindFirstChild("rEvents")
                        local ev = rEvents and rEvents:FindFirstChild("openCrystalRemote")
                        if ev and G.CrystalName ~= "" then
                            ev:InvokeServer("openCrystal", G.CrystalName)
                        end
                    end)
                end
            end)
        end,
    })
end

-- =========================================================================
-- MISC
-- =========================================================================
do
    local S = MiscMenu:AddSection({ Position = "left", Name = "MISC" })

    S:AddToggle({
        Name = "Invisibility",
        Flag = "NL_Invis",
        Default = false,
        Callback = function(v)
            G.Invisibility = v
            task.spawn(function()
                while G.Invisibility do
                    task.wait(0.5)
                    pcall(function()
                        if ninjaEvent then
                            ninjaEvent:FireServer("goInvisible")
                        end
                    end)
                end
            end)
        end,
    })
end

-- =========================================================================
-- MENU SETTINGS
-- =========================================================================
do
    local S = MiscMenu:AddSection({ Position = "right", Name = "MENU" })

    S:AddKeybind({
        Name = "Menu Keybind",
        Flag = "NL_MenuKey",
        Default = Enum.KeyCode.Insert,
        Callback = function(v)
            if v ~= nil then
                getgenv().NL_MenuKey = v
            end
        end,
    })

    S:AddToggle({
        Name = "Ignore Game Processed",
        Flag = "NL_IGP",
        Default = false,
        Callback = function(v) getgenv().NL_IgnoreGP = v end,
    })
end

-- =========================================================================
-- DONE
-- =========================================================================
Notif:Notify({
    Title = "RAINBOW HUB",
    Content = "Ninja Legends loaded",
    Icon = "clipboard",
})
print("[RAINBOW HUB] Ninja Legends loaded successfully")
