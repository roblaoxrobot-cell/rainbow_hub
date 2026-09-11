-- =========================================================================
-- NINJA LEGENDS  |  Fatality UI  |  Rainbow Hub Port
-- =========================================================================

local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")
local RS            = game:GetService("ReplicatedStorage")
local UIS           = game:GetService("UserInputService")

local LP = Players.LocalPlayer

-- =========================================================================
-- [ FATALITY LOADER ]
-- =========================================================================
local function GetFatality()
    local ok, F = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
    end)
    if not ok or not F then warn("[NL] Fatality load failed") return nil end
    return F
end

local function keyMatches(input, key)
    if key == nil then return false end
    if typeof(key) == "EnumItem" then return input.KeyCode == key end
    return input.KeyCode.Name == tostring(key)
end

local F = GetFatality()
if not F then return end
if getgenv().NL_Loaded then return end
getgenv().NL_Loaded = true

local Notification = F:CreateNotifier()
F:Loader({Name = "Rainbow Hub", Duration = 3})
Notification:Notify({Title="RAINBOW HUB", Content="Welcome, "..LP.DisplayName, Icon="clipboard"})

local Window = F.new({Name="Rainbow Hub", Expire="Ninja Legends", Keybind="NONE"})
local Config = Window:AddConfig()
Config:Init("Hub_Ninja", "HubConfigs")

-- ── Menu toggle keybind ─────────────────────────────────────────────────
local menuVisible = true
getgenv().NL_MenuKey = Enum.KeyCode.Insert
getgenv().NL_IgnoreGP = false

UIS.InputBegan:Connect(function(input, gp)
    if gp and not getgenv().NL_IgnoreGP then return end
    if keyMatches(input, getgenv().NL_MenuKey) then
        menuVisible = not menuVisible
        pcall(function() Window:SetVisible(menuVisible) end)
    end
end)

-- =========================================================================
-- [ MENUS ]
-- =========================================================================
local MainMenu = Window:AddMenu({Name="Main",      Icon="settings"})
local FarmMenu = Window:AddMenu({Name="Auto Farm", Icon="skull"})
local TpMenu   = Window:AddMenu({Name="Teleport",  Icon="eye"})
local EggMenu  = Window:AddMenu({Name="Crystal",   Icon="shield"})
local MiscMenu = Window:AddMenu({Name="Misc",      Icon="cog"})

-- =========================================================================
-- [ STATE ]
-- =========================================================================
local G = {
    AutoSwing=false, AutoSell=false,
    AutoBuySword=false, AutoBuyBelts=false, AutoBuySkills=false, AutoBuyShurikens=false,
    AutoFarmChi=false, AutoFarmCoin=false, AutoHoops=false,
    OpenCrystal=false, CrystalName="",
    EvolvePet=false,
    Invisibility=false,
    InfJump=false,
}

local ninjaEvent = LP:WaitForChild("ninjaEvent", 10)

-- =========================================================================
-- [ MAIN — CHARACTER ]
-- =========================================================================
do
    local S = MainMenu:AddSection({Position='left', Name="CHARACTER"})
    S:AddSlider({Name="Speed", Flag="NL_Speed", Default=16, Min=0, Max=500,
        Callback=function(v)
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end})
    S:AddSlider({Name="Jump Power", Flag="NL_Jump", Default=50, Min=0, Max=500,
        Callback=function(v)
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum.UseJumpPower = true end)
                hum.JumpPower = v
            end
        end})
end

-- =========================================================================
-- [ AUTO FARM ]
-- =========================================================================
do
    local Farm = FarmMenu:AddSection({Position='left',  Name="AUTO FARM"})
    local Buy  = FarmMenu:AddSection({Position='center',Name="AUTO BUY"})
    local Chi  = FarmMenu:AddSection({Position='right', Name="COLLECT"})

    -- Auto Swing
    Farm:AddToggle({Name="Auto Swing", Flag="NL_AutoSwing", Default=false,
        Callback=function(v)
            G.AutoSwing = v
            task.spawn(function()
                while G.AutoSwing do
                    task.wait(0.1)
                    pcall(function() if ninjaEvent then ninjaEvent:FireServer("swingKatana") end end)
                end
            end)
        end})

    -- Auto Sell
    Farm:AddToggle({Name="Auto Sell", Flag="NL_AutoSell", Default=false,
        Callback=function(v)
            G.AutoSell = v
            task.spawn(function()
                while G.AutoSell do
                    task.wait(0.1)
                    pcall(function()
                        local c = Workspace:FindFirstChild("sellAreaCircles")
                            and Workspace.sellAreaCircles:FindFirstChild("sellAreaCircle15")
                        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        local dest = Workspace:FindFirstChild("Part")
                        if c and c:FindFirstChild("circleInner") and hrp and dest then
                            c.circleInner.CFrame = hrp.CFrame
                            task.wait()
                            c.circleInner.CFrame = dest.CFrame
                        end
                    end)
                end
            end)
        end})

    -- Auto Buy Swords
    Buy:AddToggle({Name="Auto Buy Swords", Flag="NL_BuySwords", Default=false,
        Callback=function(v)
            G.AutoBuySword = v
            task.spawn(function()
                while G.AutoBuySword do
                    task.wait(0.5)
                    pcall(function() if ninjaEvent then ninjaEvent:FireServer("buyAllSwords","Blazing Vortex Island") end end)
                end
            end)
        end})

    -- Auto Buy Belts
    Buy:AddToggle({Name="Auto Buy Belts", Flag="NL_BuyBelts", Default=false,
        Callback=function(v)
            G.AutoBuyBelts = v
            task.spawn(function()
                while G.AutoBuyBelts do
                    task.wait(0.5)
                    pcall(function() if ninjaEvent then ninjaEvent:FireServer("buyAllBelts","Blazing Vortex Island") end end)
                end
            end)
        end})

    -- Auto Buy Skills
    Buy:AddToggle({Name="Auto Buy Skills", Flag="NL_BuySkills", Default=false,
        Callback=function(v)
            G.AutoBuySkills = v
            task.spawn(function()
                while G.AutoBuySkills do
                    task.wait(0.5)
                    pcall(function() if ninjaEvent then ninjaEvent:FireServer("buyAllSkills","Blazing Vortex Island") end end)
                end
            end)
        end})

    -- Auto Buy Shurikens
    Buy:AddToggle({Name="Auto Buy Shurikens", Flag="NL_BuyShurikens", Default=false,
        Callback=function(v)
            G.AutoBuyShurikens = v
            task.spawn(function()
                while G.AutoBuyShurikens do
                    task.wait(0.5)
                    pcall(function() if ninjaEvent then ninjaEvent:FireServer("buyAllShurikens","Blazing Vortex Island") end end)
                end
            end)
        end})

    -- Auto Farm Chi
    Chi:AddToggle({Name="Auto Farm Chi", Flag="NL_FarmChi", Default=false,
        Callback=function(v)
            G.AutoFarmChi = v
            task.spawn(function()
                while G.AutoFarmChi do
                    task.wait(0.3)
                    pcall(function()
                        local valley = Workspace:FindFirstChild("spawnedCoins")
                            and Workspace.spawnedCoins:FindFirstChild("Valley")
                        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
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
        end})

    -- Auto Farm Coin
    Chi:AddToggle({Name="Auto Farm Coin", Flag="NL_FarmCoin", Default=false,
        Callback=function(v)
            G.AutoFarmCoin = v
            task.spawn(function()
                while G.AutoFarmCoin do
                    task.wait(0.3)
                    pcall(function()
                        local valley = Workspace:FindFirstChild("spawnedCoins")
                            and Workspace.spawnedCoins:FindFirstChild("Valley")
                        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
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
        end})

    -- Auto Hoops
    Chi:AddToggle({Name="Auto Hoops", Flag="NL_Hoops", Default=false,
        Callback=function(v)
            G.AutoHoops = v
            task.spawn(function()
                while G.AutoHoops do
                    task.wait(0.3)
                    pcall(function()
                        local hoops = Workspace:FindFirstChild("Hoops")
                        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
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
        end})
end

-- =========================================================================
-- [ TELEPORT ]
-- =========================================================================
do
    local S = TpMenu:AddSection({Position='left', Name="ISLANDS"})

    local islandList = {}
    pcall(function()
        local folder = Workspace:FindFirstChild("islandUnlockParts")
        if folder then
            for _, v in ipairs(folder:GetChildren()) do
                table.insert(islandList, v.Name)
            end
        end
    end)
    if #islandList == 0 then islandList = {"None"} end

    S:AddDropdown({Name="Select Island", Flag="NL_TpIsland",
        Values=islandList, Default=islandList[1],
        Callback=function(v) getgenv().NL_TpIsl = v end})

    S:AddButton({Name="Teleport", Callback=function()
        pcall(function()
            local isl = getgenv().NL_TpIsl
            local folder = Workspace:FindFirstChild("islandUnlockParts")
            local part = folder and folder:FindFirstChild(isl)
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if part and part:FindFirstChild("islandSignPart") and hrp then
                hrp.CFrame = part.islandSignPart.CFrame
            end
        end)
    end})

    S:AddButton({Name="Unlock All Islands", Callback=function()
        task.spawn(function()
            pcall(function()
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
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
    end})
end

-- =========================================================================
-- [ CRYSTAL ]
-- =========================================================================
do
    local S = EggMenu:AddSection({Position='left', Name="CRYSTALS"})

    local crystalList = {}
    pcall(function()
        local folder = Workspace:FindFirstChild("mapCrystalsFolder")
        if folder then
            for _, v in ipairs(folder:GetChildren()) do
                table.insert(crystalList, v.Name)
            end
        end
    end)
    if #crystalList == 0 then crystalList = {"None"} end

    S:AddDropdown({Name="Select Crystal", Flag="NL_CrystalName",
        Values=crystalList, Default=crystalList[1],
        Callback=function(v) G.CrystalName = v end})

    S:AddToggle({Name="Open Crystal", Flag="NL_OpenCrystal", Default=false,
        Callback=function(v)
            G.OpenCrystal = v
            task.spawn(function()
                while G.OpenCrystal do
                    task.wait(0.1)
                    pcall(function()
                        local ev = RS:FindFirstChild("rEvents")
                            and RS.rEvents:FindFirstChild("openCrystalRemote")
                        if ev and G.CrystalName ~= "" then
                            ev:InvokeServer("openCrystal", G.CrystalName)
                        end
                    end)
                end
            end)
        end})
end

-- =========================================================================
-- [ MISC ]
-- =========================================================================
do
    local S = MiscMenu:AddSection({Position='left', Name="MISC"})

    -- Invisibility
    S:AddToggle({Name="Invisibility", Flag="NL_Invis", Default=false,
        Callback=function(v)
            G.Invisibility = v
            task.spawn(function()
                while G.Invisibility do
                    task.wait(0.5)
                    pcall(function() if ninjaEvent then ninjaEvent:FireServer("goInvisible") end end)
                end
            end)
        end})

    -- Inf Jump
    S:AddToggle({Name="Inf Jump", Flag="NL_InfJump", Default=false,
        Callback=function(v) G.InfJump = v end})

    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if G.InfJump and input.KeyCode == Enum.KeyCode.Space then
            pcall(function()
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end})
end

-- =========================================================================
-- [ MENU KEYBIND SETTINGS ]
-- =========================================================================
do
    local S = MiscMenu:AddSection({Position='right', Name="MENU"})
    S:AddKeybind({Name="Menu Keybind", Flag="NL_MenuKey", Default=Enum.KeyCode.Insert,
        Callback=function(v) if v ~= nil then getgenv().NL_MenuKey = v end end})
    S:AddToggle({Name="Ignore Game Processed", Flag="NL_IGP", Default=false,
        Callback=function(v) getgenv().NL_IgnoreGP = v end})
end

Notification:Notify({Title="RAINBOW HUB", Content="Ninja Legends loaded", Icon="clipboard"})
print("[RAINBOW HUB] Ninja Legends loaded")
