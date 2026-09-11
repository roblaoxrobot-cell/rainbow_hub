-- =========================================================
--  EUROPHIUM HVH GAME SCRIPT (games/europhium.lua)
--  Loaded by loader.lua
-- =========================================================

local F = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
if not F then warn("[europhium] Failed to load Fatality UI.") return end
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
getgenv().ForceHit      = false
getgenv().RageBotMethod = "Event Hook"
getgenv().RageBotPart   = "Head"
getgenv().NoSpread      = false
getgenv().SelectedGun   = "All"

-- =========================================================
--  FORCE HIT — FireServer hook
-- =========================================================
task.spawn(function()
    pcall(function()
        if not hookfunction then
            warn("[europhium] hookfunction is missing — Force Hit disabled.")
            return
        end

        local oldFireServer
        oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
            if not getgenv().ForceHit then
                return oldFireServer(self, ...)
            end

            if getgenv().RageBotMethod == "Event Hook" then
                local args = {...}
                local PartToHit = getgenv().RageBotPart or "Head"
                if not checkcaller() and self.Name == "sOwop02SPqas" then
                    local hitPart = args[1]
                    if hitPart and hitPart.Parent and hitPart.Parent:FindFirstChild(PartToHit) then
                        args[1] = hitPart.Parent[PartToHit]
                    end
                end
                return oldFireServer(self, unpack(args))
            else
                return oldFireServer(self, ...)
            end
        end))
    end)
end)

-- =========================================================
--  NO SPREAD — hook all functions with "SpreadJumping" constant
-- =========================================================
task.spawn(function()
    pcall(function()
        if not getgc or not islclosure or not debug or not hookfunction then return end
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" and islclosure(v) then
                local ok, constants = pcall(debug.getconstants, v)
                if ok and constants and table.find(constants, "SpreadJumping") then
                    pcall(function()
                        hookfunction(v, function()
                            if getgenv().NoSpread then
                                return 0
                            else
                                return v
                            end
                        end)
                    end)
                end
            end
        end
    end)
end)

-- =========================================================
--  NaN PITCH — ConfigUpdateEvent namecall hook
-- =========================================================
task.spawn(function()
    pcall(function()
        if not hookmetamethod or not getnamecallmethod then return end
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            if method == "FireServer" and tostring(self) == "ConfigUpdateEvent" then
                if getgenv().AntiAim and getgenv().AntiAim.NaNPitch then
                    if type(args[1]) == "table" and args[1].Pitch ~= nil then
                        args[1].Pitch = 0/0
                    end
                end
            end
            return oldNamecall(self, unpack(args))
        end))
    end)
end)

-- =========================================================
--  GUN MODS — scout / deagle / both
-- =========================================================
function applyGunMod(gun, mod, value)
    local ScoutStats = {
        ["Firerate"] = 0.8,
        ["SpreadStanding"] = 0.4,
        ["SpreadWalking"] = 1,
        ["SpreadJumping"] = 8,
        ["Damage"] = 84,
        ["AutoStopHoldTime"] = 0.25,
        ["MoveSpreadMultiplier"] = 0.02,
        ["ReloadTime"] = 3.5,
        ["Ammo"] = 10,
        ["CanScope"] = true,
    }
    local DeagleStats = {
        ["Firerate"] = 3,
        ["SpreadStanding"] = 0.6,
        ["SpreadWalking"] = 1.5,
        ["SpreadJumping"] = 15,
        ["Damage"] = 63,
        ["AutoStopHoldTime"] = 0.25,
        ["MoveSpreadMultiplier"] = 0.05,
        ["ReloadTime"] = 2.5,
        ["Ammo"] = 7,
        ["CanScope"] = false,
    }

    local deagle, scout
    local s, e = pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "SpreadStanding") and rawget(v, "Firerate") then
                    if v.Firerate == ScoutStats.Firerate
                       and v.SpreadStanding == ScoutStats.SpreadStanding
                       and v.CanScope == ScoutStats.CanScope then
                        scout = v
                    elseif v.Firerate == DeagleStats.Firerate
                       and v.SpreadStanding == DeagleStats.SpreadStanding
                       and v.CanScope == DeagleStats.CanScope then
                        deagle = v
                    end
                end
            end
        end

        if gun == "All" and scout and deagle then
            if mod == "InfiniteAmmo" then
                scout.Ammo = 0/0
                deagle.Ammo = 0/0
            elseif mod == "DamageMultiplier" and value then
                scout.Damage = ScoutStats.Damage * value
                deagle.Damage = DeagleStats.Damage * value
            elseif mod == "FastFireRate" then
                scout.Firerate = 0/0
                deagle.Firerate = 0/0
            elseif mod == "InstaReload" then
                scout.ReloadTime = 0.01
                deagle.ReloadTime = 0.01
            end
        end

        if gun == "Scout" and scout then
            if mod == "InfiniteAmmo" then
                scout.Ammo = 0/0
            elseif mod == "DamageMultiplier" and value then
                scout.Damage = ScoutStats.Damage * value
            elseif mod == "FastFireRate" then
                scout.Firerate = 0/0
            elseif mod == "InstaReload" then
                scout.ReloadTime = 0.01
            end
        end

        if gun == "Deagle" and deagle then
            if mod == "InfiniteAmmo" then
                deagle.Ammo = 0/0
            elseif mod == "DamageMultiplier" and value then
                deagle.Damage = DeagleStats.Damage * value
            elseif mod == "FastFireRate" then
                deagle.Firerate = 0/0
            elseif mod == "InstaReload" then
                deagle.ReloadTime = 0.01
            end
        end

        if gun == "Reset" then
            if scout then
                for stat, val in pairs(ScoutStats) do scout[stat] = val end
            end
            if deagle then
                for stat, val in pairs(DeagleStats) do deagle[stat] = val end
            end
        end
    end)

    if not s then
        Notification:Notify({
            Title = "Error",
            Content = "Failed to apply gun mod, " .. tostring(e),
            Icon = "bell",
        })
    end
end

-- =========================================================
--  FATALITY UI
-- =========================================================
F:Loader({ Name = "Rainbow Hub", Duration = 3 })

Notification:Notify({
    Title = "RAINBOW HUB",
    Content = "Welcome, " .. LocalPlayer.DisplayName,
    Icon = "clipboard",
})

local Window = F.new({ Name = "Rainbow Hub", Expire = "Europhium", Keybind = "NONE" })
local Config = Window:AddConfig()
Config:Init("Hub_Euro", "HubConfigs")

local menuVisible = true
getgenv().EuroOpenKey = Enum.KeyCode.Insert
getgenv().EuroIgnoreGP = false

UIS.InputBegan:Connect(function(input, gp)
    if gp and not getgenv().EuroIgnoreGP then return end
    if keyMatches(input, getgenv().EuroOpenKey) then
        menuVisible = not menuVisible
        pcall(function() Window:SetVisible(menuVisible) end)
    end
end)

local RageMenu     = Window:AddMenu({ Name = "Rage",     Icon = "skull" })
local AntiAimMenu  = Window:AddMenu({ Name = "Anti Aim", Icon = "shield" })
local VisualsMenu  = Window:AddMenu({ Name = "Visuals",  Icon = "eye" })
local SettingsMenu = Window:AddMenu({ Name = "Settings", Icon = "cog" })
local InfoMenu     = Window:AddMenu({ Name = "Info",     Icon = "info" })

-- =========================================================
--  RAGE MENU
-- =========================================================
do
    local ExploitSect = RageMenu:AddSection({ Position = 'left',   Name = "EXPLOITS" })
    local GunSect     = RageMenu:AddSection({ Position = 'center', Name = "GUN MODS" })
    local ConfigSect  = RageMenu:AddSection({ Position = 'right',  Name = "CONFIGURATION" })

    -- Force Hit
    local ForceHitToggle = ExploitSect:AddToggle({
        Name = "Force Hit",
        Flag = "ForceHitEnabled",
        Risky = true,
        Option = true,
        Callback = function(v)
            getgenv().ForceHit = v
            Notification:Notify({
                Title = "Rainbow Hub",
                Content = v and "Force Hit enabled" or "Force Hit disabled",
                Icon = v and "check" or "bell",
            })
        end,
    })

    ForceHitToggle.Option:AddDropdown({
        Name = "Method",
        Flag = "ForceHitMethod",
        Values = {"Event Hook"},
        Default = "Event Hook",
        Callback = function(v) getgenv().RageBotMethod = v end,
    })

    ForceHitToggle.Option:AddDropdown({
        Name = "Hit Part",
        Flag = "ForceHitHitPart",
        Values = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"},
        Default = "Head",
        Callback = function(v) getgenv().RageBotPart = v end,
    })

    -- No Spread
    ExploitSect:AddToggle({
        Name = "No Spread",
        Flag = "NoSpread",
        Risky = true,
        Callback = function(v)
            getgenv().NoSpread = v
            Notification:Notify({
                Title = "Rainbow Hub",
                Content = v and "No Spread enabled" or "No Spread disabled",
                Icon = v and "check" or "bell",
            })
        end,
    })

    -- Gun selector
    GunSect:AddDropdown({
        Name = "Gun",
        Flag = "GunSelect",
        Values = {"All", "Scout", "Deagle"},
        Default = "All",
        Callback = function(v) getgenv().SelectedGun = v end,
    })

    GunSect:AddToggle({
        Name = "Infinite Ammo",
        Flag = "GunInfAmmo",
        Callback = function(v)
            applyGunMod("All", "InfiniteAmmo", v)
        end,
    })

    GunSect:AddToggle({
        Name = "Damage Multiplier",
        Flag = "GunDmgMulToggle",
        Callback = function(v)
            pcall(function()
                applyGunMod(getgenv().SelectedGun or "All", "DamageMultiplier", v and 5 or 1)
            end)
        end,
    })

    GunSect:AddSlider({
        Name = "Damage Multiplier",
        Flag = "GunDmgMulSlider",
        Min = 1,
        Max = 100,
        Default = 1,
        Callback = function(v)
            pcall(function()
                applyGunMod(getgenv().SelectedGun or "All", "DamageMultiplier", v)
            end)
        end,
    })

    GunSect:AddToggle({
        Name = "Fast Firerate",
        Flag = "GunFastFire",
        Callback = function(v)
            pcall(function()
                applyGunMod(getgenv().SelectedGun or "All", "FastFireRate", v)
            end)
        end,
    })

    GunSect:AddToggle({
        Name = "Insta Reload",
        Flag = "GunInstaReload",
        Callback = function(v)
            pcall(function()
                applyGunMod(getgenv().SelectedGun or "All", "InstaReload", v)
            end)
        end,
    })

    GunSect:AddButton({
        Name = "Reset Gun Mods",
        Callback = function()
            pcall(function()
                applyGunMod("Reset")
            end)
            Notification:Notify({
                Title = "Rainbow Hub",
                Content = "Gun mods reset to default.",
                Icon = "check",
            })
        end,
    })

    -- Config placeholder (informative)
    ConfigSect:AddButton({
        Name = "Save Config",
        Callback = function()
            Notification:Notify({
                Title = "Rainbow Hub",
                Content = "Config saved (Hub_Euro)",
                Icon = "check",
            })
        end,
    })
end

-- =========================================================
--  ANTI AIM MENU
-- =========================================================
do
    local AA_Main    = AntiAimMenu:AddSection({ Position = 'left',   Name = "MAIN" })
    local AA_Exploit = AntiAimMenu:AddSection({ Position = 'center', Name = "EXPLOITS" })

    AA_Main:AddToggle({
        Name = "Enable Anti-Aim",
        Flag = "AntiAimEnabled",
        Callback = function(v)
            getgenv().AntiAim = getgenv().AntiAim or {}
            getgenv().AntiAim.Enabled = v
        end,
    })

    AA_Exploit:AddToggle({
        Name = "NaN Pitch",
        Flag = "NaNPitch",
        Callback = function(v)
            getgenv().AntiAim = getgenv().AntiAim or {}
            getgenv().AntiAim.NaNPitch = v
            Notification:Notify({
                Title = "Rainbow Hub",
                Content = v and "NaN Pitch enabled" or "NaN Pitch disabled",
                Icon = v and "check" or "bell",
            })
        end,
    })
end

-- =========================================================
--  VISUALS MENU
-- =========================================================
do
    local ESP = VisualsMenu:AddSection({ Position = 'left', Name = "ESP" })
    ESP:AddToggle({
        Name = "Chinese ESP",
        Flag = "ChineseESP",
        Callback = function(v) getgenv().ChineseESP = v end,
    })
end

-- =========================================================
--  SETTINGS
-- =========================================================
do
    local S = SettingsMenu:AddSection({ Position = 'left', Name = "Menu" })
    S:AddKeybind({
        Name = "Menu Keybind",
        Flag = "EuroMenuKey",
        Default = Enum.KeyCode.Insert,
        Callback = function(v) if v ~= nil then getgenv().EuroOpenKey = v end end,
    })
    S:AddToggle({
        Name = "Ignore Game Processed",
        Flag = "EuroIGP",
        Callback = function(v) getgenv().EuroIgnoreGP = v end,
    })
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
                Content = "Current version: 1.0 (Europhium)",
                Icon = "clipboard",
            })
        end,
    })
end

-- =========================================================
--  AUTO-REJOIN ON KICK
-- =========================================================
game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    task.wait(0.5)
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

print("[europhium] loaded successfully")