-- =========================================================
--  SELL LEMONS GAME SCRIPT (games/selllemons.lua)
--  Ported to Fatality UI (original by Voxels.RBX)
--  Loaded by loader.lua
-- =========================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local F = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
if not F then warn("[selllemons] Failed to load Fatality UI.") return end
local Notification = F:CreateNotifier()

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Workspace        = game:GetService("Workspace")
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[selllemons] Failed to load LocalPlayer.")
    return
end

local function keyMatches(input, key)
    if key == nil then return false end
    if typeof(key) == "EnumItem" then return input.KeyCode == key end
    return input.KeyCode.Name == tostring(key)
end

-- =========================================================
--  ANTI-IDLE
-- =========================================================
pcall(function()
    for _, idle in pairs(getconnections(LocalPlayer.Idled)) do
        idle:Disable()
    end
end)

-- =========================================================
--  DATA
-- =========================================================
local ScriptData = {
    PlayerTycoon = nil,
    Values       = nil,
    Powers       = nil,
    Streams      = nil,

    AutoBuy               = false,
    AutoUpgrade           = false,
    AutoRebirth           = false,
    AutoEvolve            = false,
    AutoAscend            = false,
    AutoBuyPowers         = false,
    AutoWakeIncomeSources = false,
    AutoPhoneOffers       = false,
    AutoCollectFruits     = false,

    MainSettings = {
        ButtonBuy = {
            BuyInterval         = 0.05,
            UseForeverPurchase  = false,
        },
        Rebirth = {
            MaximumRebirths                   = 0,
            MinimumPotential                  = 1000,
            XFactor                           = 10,
            RebirthWhenUnableToBuy            = false,
            TimeBeforeRebirthWhenUnableToBuy  = 30,
            RebirthAfterCertainTime           = false,
            TimeAmount                        = 60,
        },
        Evolve = {
            MaximumEvolution = 0,
        },
    },

    Modules = {
        Tycoon=nil, Analyzer=nil, Balance=nil, Balances=nil, Upgrades=nil,
        Rebirth=nil, Evolve=nil, Ascension=nil, PhoneOffers=nil, TycoonPowers=nil,
    },

    Remotes = {
        Rebirth=nil, Evolve=nil, Ascend=nil, UpgradePowerLevel=nil,
        WakeIncomeStream=nil, PhoneOffer=nil,
    },
}

-- =========================================================
--  FIND HELPERS
-- =========================================================
local function FindValues(Value, AnotherChild, ReturnLast)
    if not ScriptData.PlayerTycoon then return end
    local Values = ScriptData.PlayerTycoon:FindFirstChild("Values")
    if not Values then warn("[selllemons] Values folder not found.") end
    local ReturnValue = Values:FindFirstChild(Value)
    if not ReturnValue then warn("[selllemons] Config not found in Values: " .. tostring(Value)) end
    if not AnotherChild then
        return ReturnValue
    else
        local Check = ReturnValue:FindFirstChild(AnotherChild)
        if Check and not ReturnLast then
            return ReturnValue, Check
        elseif Check and ReturnLast then
            return Check
        end
    end
end

local function FindTycoon()
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:match("Tycoon%d") then
            if v:FindFirstChild("Owner") and v.Owner.Value == LocalPlayer then
                return v
            end
        end
    end
end

-- =========================================================
--  WAIT FOR TYCOON / VALUES / POWERS / STREAMS
-- =========================================================
local StartTime = tick()
repeat
    ScriptData.PlayerTycoon = FindTycoon()
    if tick() - StartTime > 30 then
        warn("[selllemons] Tycoon unable to be found.")
        Notification:Notify({ Title = "Error", Content = "Tycoon not found.", Icon = "bell" })
        return
    end
    task.wait(0.25)
until ScriptData.PlayerTycoon ~= nil

StartTime = tick()
repeat
    ScriptData.Values = FindValues("Values")
    if tick() - StartTime > 5 then
        warn("[selllemons] Values not found.")
        return
    end
until ScriptData.Values ~= nil

StartTime = tick()
repeat
    ScriptData.Powers = FindValues("Powers", "Permanent", true)
    if tick() - StartTime > 5 then
        warn("[selllemons] Powers not found.")
        return
    end
until ScriptData.Powers ~= nil

StartTime = tick()
repeat
    ScriptData.Streams = FindValues("Income", "Streams", true)
    if tick() - StartTime > 5 then
        warn("[selllemons] Streams not found.")
        return
    end
until ScriptData.Streams ~= nil

-- =========================================================
--  LOAD MODULES & REMOTES
-- =========================================================
local S1, R1 = pcall(function()
    ScriptData.Modules.Tycoon       = require(ReplicatedStorage.Modules.Tycoon.Tycoon)
    ScriptData.Modules.Balances     = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonBalances)
    ScriptData.Modules.Upgrades     = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonUpgrades)
    ScriptData.Modules.Rebirth      = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonRebirth)
    ScriptData.Modules.Evolve       = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonEvolution)
    ScriptData.Modules.Ascension    = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonAscension)
    ScriptData.Modules.PhoneOffers  = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonPhoneOffers)
    ScriptData.Modules.TycoonPowers = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonPowers)
    ScriptData.Modules.Analyzer     = require(ReplicatedStorage.Modules.Tycoon.Component.TycoonAnalyzer)
    ScriptData.Modules.Balance      = require(ReplicatedStorage.Balance)
end)

local S2, R2 = pcall(function()
    ScriptData.Remotes.Rebirth           = ScriptData.PlayerTycoon.Remotes.Rebirth
    ScriptData.Remotes.Evolve            = ScriptData.PlayerTycoon.Remotes.Evolve
    ScriptData.Remotes.Ascend            = ScriptData.PlayerTycoon.Remotes.Ascend
    ScriptData.Remotes.UpgradePowerLevel = ScriptData.PlayerTycoon.Remotes.UpgradePowerLevel
    ScriptData.Remotes.WakeIncomeStream  = ScriptData.PlayerTycoon.Remotes.WakeIncomeStream
    ScriptData.Remotes.PhoneOffer        = ScriptData.PlayerTycoon.Remotes.PhoneOffer
end)

if not S1 or not S2 then
    if not S1 then warn("[selllemons] Module failed: " .. tostring(R1)) end
    if not S2 then warn("[selllemons] Remote failed: " .. tostring(R2)) end
end

local function RequestComp(Class)
    if not (ScriptData.Modules.Tycoon and Class) then return nil end
    local Success, Return = pcall(function()
        local LiveTycoon = ScriptData.Modules.Tycoon.getLocal()
        return LiveTycoon and LiveTycoon:GetComponent(Class)
    end)
    return Success and Return or nil
end

local Resolving = false
local function WaitForResolve()
    Resolving = true
    task.wait(2)
    Resolving = false
end

-- =========================================================
--  AUTO BUY BUTTONS
-- =========================================================
task.spawn(function()
    local IsBusy = false

    local function BuyButtons()
        if IsBusy or Resolving then return end
        IsBusy = true

        local Analyzer = RequestComp(ScriptData.Modules.Analyzer)
        if not Analyzer then IsBusy = false return end

        local Purchases = Analyzer:GetPurchases()

        for _, id in ipairs(ScriptData.Modules.Balance.PurchaseOrder) do
            local Purchase = Purchases[id]

            if Purchase and Purchase:IsEnabled() and not Purchase:IsPurchased() then
                local Remote = Purchase.Instance:FindFirstChild("Purchase", true)

                if Remote and Remote:IsA("RemoteFunction") then
                    if ScriptData.MainSettings.ButtonBuy.UseForeverPurchase then
                        local Success = pcall(function()
                            Remote:InvokeServer(true)
                        end)
                        if not Success then
                            pcall(function() Remote:InvokeServer() end)
                        end
                    else
                        pcall(function() Remote:InvokeServer() end)
                    end
                end

                if type(ScriptData.MainSettings.ButtonBuy.BuyInterval) == "number"
                    and ScriptData.MainSettings.ButtonBuy.BuyInterval > 0 then
                    task.wait(ScriptData.MainSettings.ButtonBuy.BuyInterval)
                end

                break
            end
        end

        IsBusy = false
    end

    while true do
        task.wait()
        if not ScriptData.AutoBuy then continue end
        BuyButtons()
    end
end)

-- =========================================================
--  AUTO UPGRADE
-- =========================================================
task.spawn(function()
    local UpgradeRemotes = {}
    local LastUpgradeScan = 0

    local function RefreshUpgradeRemotes()
        UpgradeRemotes = {}
        local Purchases = ScriptData.PlayerTycoon:FindFirstChild("Purchases")
        if not Purchases then return end
        for _, v in ipairs(Purchases:GetDescendants()) do
            if v:IsA("RemoteFunction") and v.Name == "Upgrade" then
                table.insert(UpgradeRemotes, v)
            end
        end
    end

    while true do
        task.wait(0.5)
        if not ScriptData.AutoUpgrade then continue end

        if tick() - LastUpgradeScan > 3 then
            RefreshUpgradeRemotes()
            LastUpgradeScan = tick()
        end

        for _, r in ipairs(UpgradeRemotes) do
            if r.Parent then
                task.spawn(function()
                    for i = 1, 10 do
                        task.wait()
                        pcall(function() r:InvokeServer(i) end)
                    end
                end)
            end
        end
    end
end)

-- =========================================================
--  AUTO REBIRTH
-- =========================================================
task.spawn(function()
    local RebirthBusy = false
    local LastConflictNotify = 0
    local LastUnableBuyTime = 0
    local LastRebirthTime = tick()
    local LastTimeState = false
    local LastSuccessfulRebirth = 0
    local LastAutoRebirthToggle = 0
    local RebirthCooldown = 2.5

    local function GetBalances() return RequestComp(ScriptData.Modules.Balances) end
    local function GetRebirth()  return RequestComp(ScriptData.Modules.Rebirth) end

    local function GetCurrentInvestors()
        local Balances = GetBalances()
        if not Balances then return 0 end
        local Success, Value = pcall(function() return Balances:GetInvestors() end)
        return Success and Value or 0
    end

    local function GetPotentialInvestors()
        local RebirthComp = GetRebirth()
        if not RebirthComp then return 0 end
        local Success, Value = pcall(function() return RebirthComp:GetPotentialInvestors() end)
        return Success and Value or 0
    end

    local function IsMinimumMet(PotentialLog, Minimum)
        if Minimum == 0 then return true end
        return PotentialLog >= math.log10(Minimum)
    end

    local function GetInvestorMultiplierCondition(PotentialLog, CurrentLog, Multiplier)
        return PotentialLog >= CurrentLog + math.log10(Multiplier)
    end

    local function DoRebirth()
        pcall(function()
            ScriptData.Remotes.Rebirth:InvokeServer()
            WaitForResolve()
        end)
    end

    local function HasAnythingToBuy()
        for _, v in ipairs(ScriptData.PlayerTycoon.Purchases:GetDescendants()) do
            if v:IsA("Model") then
                local Shown     = v:GetAttribute("Shown")
                local Purchased = v:GetAttribute("Purchased")
                if Shown == true and Purchased ~= true then
                    return true
                end
            end
        end
        return false
    end

    local function GetCurrentRebirths()
        if not ScriptData.Values then return 0 end
        return ScriptData.Values:GetAttribute("Rebirths") or 0
    end

    while true do
        task.wait(0.1)

        if not ScriptData.AutoRebirth or RebirthBusy then
            if not ScriptData.AutoRebirth then LastAutoRebirthToggle = 0 end
            continue
        end

        if LastAutoRebirthToggle == 0 then
            LastAutoRebirthToggle = tick()
            continue
        end

        if tick() - LastAutoRebirthToggle < 3 then continue end
        if tick() - LastSuccessfulRebirth < RebirthCooldown then continue end

        local Remote = ScriptData.Remotes.Rebirth
        if not Remote then continue end

        local MaxRebirths = ScriptData.MainSettings.Rebirth.MaximumRebirths
        if MaxRebirths > 0 then
            local CurrentRebirths = GetCurrentRebirths()
            if CurrentRebirths >= MaxRebirths then continue end
        end

        local Settings = ScriptData.MainSettings.Rebirth
        local ShouldRebirth = false

        if Settings.RebirthWhenUnableToBuy and Settings.RebirthAfterCertainTime then
            if tick() - LastConflictNotify >= 5 then
                Notification:Notify({
                    Title   = "Rebirth Conflict",
                    Content = "Cannot use both options together.",
                    Icon    = "bell",
                })
                LastConflictNotify = tick()
            end
            continue
        end

        if Settings.RebirthAfterCertainTime then
            if LastTimeState ~= true then
                LastRebirthTime = tick()
                LastTimeState = true
            end
            if tick() - LastRebirthTime >= Settings.TimeAmount then
                ShouldRebirth = true
            end
        else
            LastTimeState = false

            if Settings.RebirthWhenUnableToBuy then
                if not HasAnythingToBuy() then
                    if LastUnableBuyTime == 0 then
                        LastUnableBuyTime = tick()
                    elseif tick() - LastUnableBuyTime >= Settings.TimeBeforeRebirthWhenUnableToBuy then
                        ShouldRebirth = true
                    end
                else
                    LastUnableBuyTime = 0
                end
            end

            if not ShouldRebirth then
                local Potential = GetPotentialInvestors()
                local Current   = GetCurrentInvestors()

                if Potential > 0 then
                    local MinMet = IsMinimumMet(Potential, Settings.MinimumPotential)
                    if MinMet then
                        if Settings.XFactor > 0 then
                            if GetInvestorMultiplierCondition(Potential, Current, Settings.XFactor) then
                                ShouldRebirth = true
                            end
                        elseif Settings.MinimumPotential > 0 then
                            ShouldRebirth = true
                        elseif Settings.XFactor == 0 and Settings.MinimumPotential == 0 then
                            if tick() - LastRebirthTime >= 8 then
                                ShouldRebirth = true
                            end
                        end
                    end
                end
            end
        end

        if ShouldRebirth and ScriptData.AutoRebirth then
            RebirthBusy = true
            DoRebirth()

            LastRebirthTime        = tick()
            LastUnableBuyTime      = 0
            LastSuccessfulRebirth  = tick()
            LastAutoRebirthToggle  = tick()

            task.wait(1.5)
            RebirthBusy = false
        end
    end
end)

-- =========================================================
--  AUTO EVOLVE
-- =========================================================
task.spawn(function()
    local function TryEvolve()
        pcall(function()
            ScriptData.Remotes.Evolve:InvokeServer()
            WaitForResolve()
        end)
    end

    while true do
        task.wait(0.5)
        if not ScriptData.AutoEvolve then continue end

        local FreshModule = RequestComp(ScriptData.Modules.Evolve)
        if not FreshModule then continue end

        local Progress = FreshModule:GetEvolutionProgress()

        if Progress == 1 and ScriptData.MainSettings.Evolve.MaximumEvolution > 0 then
            local CurrentEvolve = ScriptData.Values:GetAttribute("Evolution")
            if CurrentEvolve and CurrentEvolve < ScriptData.MainSettings.Evolve.MaximumEvolution then
                TryEvolve()
            end
        elseif Progress == 1 and ScriptData.MainSettings.Evolve.MaximumEvolution == 0 then
            TryEvolve()
        end
    end
end)

-- =========================================================
--  AUTO ASCEND
-- =========================================================
task.spawn(function()
    local function TryAscend()
        pcall(function()
            ScriptData.Remotes.Ascend:InvokeServer()
            WaitForResolve()
        end)
    end

    while true do
        task.wait(0.5)
        if not ScriptData.AutoAscend then continue end

        local FreshModule = RequestComp(ScriptData.Modules.Ascension)
        if not FreshModule then continue end

        if FreshModule:GetAscensionProgress() == 1 then
            TryAscend()
        end
    end
end)

-- =========================================================
--  AUTO BUY POWERS
-- =========================================================
task.spawn(function()
    local function TryBuyPowers()
        local FreshModule = RequestComp(ScriptData.Modules.TycoonPowers)
        if not FreshModule then return end

        local Success, Levels = pcall(function()
            return FreshModule:GetLevels()
        end)

        if not Success or not Levels then return end

        for PowerName, CurrentLevel in pairs(Levels) do
            local MaxLevel = FreshModule:GetMaxLevel(PowerName)
            if not MaxLevel or CurrentLevel < MaxLevel then
                pcall(function()
                    FreshModule:UpgradeAsync(PowerName)
                end)
                task.wait(0.1)
            end
        end
    end

    while true do
        task.wait(0.5)
        if not ScriptData.AutoBuyPowers then continue end
        TryBuyPowers()
    end
end)

-- =========================================================
--  AUTO PHONE OFFERS
-- =========================================================
task.spawn(function()
    local Phone = ScriptData.Remotes.PhoneOffer
    if not Phone then return end

    local function AcceptOffer()
        if ScriptData.AutoPhoneOffers then
            pcall(function() Phone:FireServer("Accept") end)
        end
    end

    Phone.OnClientEvent:Connect(function(value)
        if type(value) == "number" then AcceptOffer() end
    end)

    while true do
        task.wait(1)
        if ScriptData.AutoPhoneOffers then
            local FreshModule = RequestComp(ScriptData.Modules.PhoneOffers)
            if FreshModule then
                local Success, Offer = pcall(function()
                    return FreshModule:GetCurrentOffer()
                end)
                if Success and type(Offer) == "number" then
                    AcceptOffer()
                end
            end
        end
    end
end)

-- =========================================================
--  AUTO WAKE INCOME SOURCES
-- =========================================================
task.spawn(function()
    local IncomeStreams = {}

    local function IndexStreams()
        IncomeStreams = {}
        for _, v in pairs(ScriptData.Streams:GetChildren()) do
            table.insert(IncomeStreams, v)
        end
    end

    local function TryWakeIncome()
        if #IncomeStreams == 0 then IndexStreams() end
        for _, v in ipairs(IncomeStreams) do
            local Check = v:GetAttribute("Automatic")
            if not Check then
                pcall(function()
                    ScriptData.Remotes.WakeIncomeStream:InvokeServer(tostring(v))
                end)
            end
        end
    end

    while true do
        task.wait()
        if not ScriptData.AutoWakeIncomeSources then continue end
        TryWakeIncome()
    end
end)

-- =========================================================
--  AUTO COLLECT FRUITS
-- =========================================================
task.spawn(function()
    local Trees = {}
    local OriginalCFrame = nil

    local function UpdateTree(v, IsAdding)
        if v:IsA("Model") and v.Name == "LemonTree" then
            if IsAdding then
                if not table.find(Trees, v) then table.insert(Trees, v) end
            else
                local Index = table.find(Trees, v)
                if Index then table.remove(Trees, Index) end
            end
        end
    end

    for _, v in ipairs(Workspace:GetDescendants()) do UpdateTree(v, true) end

    Workspace.DescendantAdded:Connect(function(v) UpdateTree(v, true) end)
    Workspace.DescendantRemoving:Connect(function(v) UpdateTree(v, false) end)

    while true do
        task.wait(0.1)

        if ScriptData.AutoCollectFruits then
            for _, Tree in ipairs(Trees) do
                if Tree and Tree.Parent then
                    for _, v in ipairs(Tree:GetDescendants()) do
                        if v:IsA("BasePart") and v.Name == "Fruit" then
                            if not ScriptData.AutoCollectFruits then break end

                            local Detector = v:FindFirstChild("ClickPart") and v.ClickPart:FindFirstChildOfClass("ClickDetector")
                            if Detector then
                                local Character        = LocalPlayer.Character
                                local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

                                if HumanoidRootPart then
                                    pcall(function()
                                        if not OriginalCFrame then
                                            OriginalCFrame = HumanoidRootPart.CFrame
                                        end
                                        HumanoidRootPart.CFrame = Tree:GetPivot() + Vector3.new(0, Tree:GetExtentsSize().Y/2, 0)
                                        task.wait(0.05)
                                        fireclickdetector(Detector)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        elseif OriginalCFrame then
            local Character        = LocalPlayer.Character
            local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
            if HumanoidRootPart then
                pcall(function()
                    HumanoidRootPart.CFrame = OriginalCFrame
                    OriginalCFrame = nil
                end)
            end
        end
    end
end)

-- =========================================================
--  FATALITY UI
-- =========================================================
F:Loader({ Name = "Rainbow Hub", Duration = 3 })

Notification:Notify({
    Title   = "RAINBOW HUB",
    Content = "Welcome, " .. LocalPlayer.DisplayName,
    Icon    = "clipboard",
})

local Window = F.new({ Name = "Rainbow Hub", Expire = "Sell Lemons", Keybind = "NONE" })
local Config = Window:AddConfig()
Config:Init("Hub_SellLemons", "HubConfigs")

local menuVisible = true
getgenv().SLMenuKey = Enum.KeyCode.Insert
getgenv().SLIgnoreGP = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp and not getgenv().SLIgnoreGP then return end
    if keyMatches(input, getgenv().SLMenuKey) then
        menuVisible = not menuVisible
        pcall(function() Window:SetVisible(menuVisible) end)
    end
end)

local MainMenu     = Window:AddMenu({ Name = "Main",          Icon = "settings" })
local FarmMenu     = Window:AddMenu({ Name = "Auto Farm",     Icon = "skull" })
local RebirthMenu  = Window:AddMenu({ Name = "Rebirth",       Icon = "shield" })
local MiscMenu     = Window:AddMenu({ Name = "Misc",          Icon = "cog" })
local SettingsMenu = Window:AddMenu({ Name = "Settings",      Icon = "cog" })

-- =========================================================
--  MAIN
-- =========================================================
do
    local Auto    = MainMenu:AddSection({ Position = 'left',   Name = "AUTO" })
    local Extras  = MainMenu:AddSection({ Position = 'center', Name = "EXTRAS" })
    local Render  = MainMenu:AddSection({ Position = 'right',  Name = "RENDER" })

    Auto:AddToggle({ Name = "Auto Buy", Flag = "SL_AutoBuy",
        Callback = function(v)
            ScriptData.AutoBuy = v
            Notification:Notify({ Title = "Auto Buy", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Auto:AddToggle({ Name = "Auto Upgrade", Flag = "SL_AutoUpgrade",
        Callback = function(v)
            ScriptData.AutoUpgrade = v
            Notification:Notify({ Title = "Auto Upgrade", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Auto:AddToggle({ Name = "Auto Rebirth", Flag = "SL_AutoRebirth",
        Callback = function(v)
            ScriptData.AutoRebirth = v
            Notification:Notify({ Title = "Auto Rebirth", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Auto:AddToggle({ Name = "Auto Evolve", Flag = "SL_AutoEvolve",
        Callback = function(v)
            ScriptData.AutoEvolve = v
            Notification:Notify({ Title = "Auto Evolve", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Auto:AddToggle({ Name = "Auto Ascend", Flag = "SL_AutoAscend",
        Callback = function(v)
            ScriptData.AutoAscend = v
            Notification:Notify({ Title = "Auto Ascend", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Extras:AddToggle({ Name = "Auto Buy Powers", Flag = "SL_AutoBuyPowers",
        Callback = function(v)
            ScriptData.AutoBuyPowers = v
            Notification:Notify({ Title = "Auto Buy Powers", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Extras:AddToggle({ Name = "Auto Accept Phone Offers", Flag = "SL_AutoPhoneOffers",
        Callback = function(v)
            ScriptData.AutoPhoneOffers = v
            Notification:Notify({ Title = "Auto Phone Offers", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Extras:AddToggle({ Name = "Auto Wake Income Sources", Flag = "SL_AutoWakeIncome",
        Callback = function(v)
            ScriptData.AutoWakeIncomeSources = v
            Notification:Notify({ Title = "Auto Wake Income", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Extras:AddToggle({ Name = "Collect Fruits", Flag = "SL_AutoFruits",
        Callback = function(v)
            ScriptData.AutoCollectFruits = v
            Notification:Notify({ Title = "Collect Fruits", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end })

    Render:AddToggle({ Name = "Disable 3D Rendering (FPS)", Flag = "SL_NoRender",
        Callback = function(v)
            pcall(function()
                if v then RunService:Set3dRenderingEnabled(false)
                else RunService:Set3dRenderingEnabled(true) end
            end)
        end })
end

-- =========================================================
--  AUTO FARM (buy / evolve settings)
-- =========================================================
do
    local Buy   = FarmMenu:AddSection({ Position = 'left',   Name = "BUY SETTINGS" })
    local Evol  = FarmMenu:AddSection({ Position = 'center', Name = "EVOLVE SETTINGS" })

    Buy:AddSlider({
        Name = "Buy Interval (sec)", Flag = "SL_BuyInterval",
        Default = 0.05, Min = 0.01, Max = 1, Round = 2,
        Callback = function(v)
            ScriptData.MainSettings.ButtonBuy.BuyInterval = v
        end,
    })

    Buy:AddToggle({
        Name = "Use Forever Purchase", Flag = "SL_ForeverPurchase",
        Callback = function(v)
            ScriptData.MainSettings.ButtonBuy.UseForeverPurchase = v
            Notification:Notify({ Title = "Forever Purchase", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end,
    })

    Evol:AddSlider({
        Name = "Max Evolve (0 = no max)", Flag = "SL_MaxEvolve",
        Default = 0, Min = 0, Max = 100, Round = 0,
        Callback = function(v)
            ScriptData.MainSettings.Evolve.MaximumEvolution = v
        end,
    })
end

-- =========================================================
--  REBIRTH
-- =========================================================
do
    local R = RebirthMenu:AddSection({ Position = 'left',   Name = "REBIRTH" })
    local T = RebirthMenu:AddSection({ Position = 'center', Name = "TIME BASED" })

    R:AddSlider({
        Name = "Max Rebirths (0 = off)", Flag = "SL_MaxRebirths",
        Default = 0, Min = 0, Max = 500, Round = 0,
        Callback = function(v)
            ScriptData.MainSettings.Rebirth.MaximumRebirths = v
        end,
    })

    R:AddSlider({
        Name = "Minimum Investors", Flag = "SL_MinInvestors",
        Default = 1000, Min = 0, Max = 1000000, Round = 0,
        Callback = function(v)
            ScriptData.MainSettings.Rebirth.MinimumPotential = v
        end,
    })

    R:AddSlider({
        Name = "X Factor (0 = off)", Flag = "SL_XFactor",
        Default = 10, Min = 0, Max = 100, Round = 0,
        Callback = function(v)
            ScriptData.MainSettings.Rebirth.XFactor = v
        end,
    })

    T:AddToggle({
        Name = "Rebirth After Certain Time", Flag = "SL_RebirthTime",
        Callback = function(v)
            ScriptData.MainSettings.Rebirth.RebirthAfterCertainTime = v
            Notification:Notify({ Title = "Rebirth By Time", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end,
    })

    T:AddSlider({
        Name = "Time Interval (sec)", Flag = "SL_RebirthTimeAmount",
        Default = 60, Min = 5, Max = 600, Round = 0,
        Callback = function(v)
            ScriptData.MainSettings.Rebirth.TimeAmount = v
        end,
    })

    T:AddToggle({
        Name = "Rebirth When Unable To Buy", Flag = "SL_RebirthUnable",
        Callback = function(v)
            ScriptData.MainSettings.Rebirth.RebirthWhenUnableToBuy = v
            Notification:Notify({ Title = "Rebirth Unable To Buy", Content = v and "Enabled" or "Disabled", Icon = v and "check" or "bell" })
        end,
    })

    T:AddSlider({
        Name = "Unable Buy Interval (sec)", Flag = "SL_RebirthUnableAmount",
        Default = 30, Min = 5, Max = 300, Round = 0,
        Callback = function(v)
            ScriptData.MainSettings.Rebirth.TimeBeforeRebirthWhenUnableToBuy = v
        end,
    })
end

-- =========================================================
--  MISC
-- =========================================================
do
    local Extra = MiscMenu:AddSection({ Position = 'left', Name = "EXTRA" })

    Extra:AddButton({
        Name = "Reset 3D Rendering",
        Callback = function()
            pcall(function() RunService:Set3dRenderingEnabled(true) end)
            Notification:Notify({ Title = "Rainbow Hub", Content = "3D rendering restored.", Icon = "check" })
        end,
    })
end

-- =========================================================
--  SETTINGS
-- =========================================================
do
    local S = SettingsMenu:AddSection({ Position = 'left', Name = "MENU" })
    S:AddKeybind({
        Name = "Menu Keybind", Flag = "SL_MenuKey",
        Default = Enum.KeyCode.Insert,
        Callback = function(v) if v ~= nil then getgenv().SLMenuKey = v end end,
    })
    S:AddToggle({
        Name = "Ignore Game Processed", Flag = "SL_IgnoreGP",
        Callback = function(v) getgenv().SLIgnoreGP = v end,
    })
end

print("[selllemons] loaded successfully")
