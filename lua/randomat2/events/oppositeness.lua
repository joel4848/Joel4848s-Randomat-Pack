local EVENT = {}

util.AddNetworkString("OppositenessMouseX")
util.AddNetworkString("OppositenessMouseY")
util.AddNetworkString("OppositenessMove")
util.AddNetworkString("OppositenessStrafe")
util.AddNetworkString("OppositenessJump")
util.AddNetworkString("OppositenessShoot")
util.AddNetworkString("OppositenessSprint")
util.AddNetworkString("OppositenessEnd")

EVENT.Title = {
    { text = "Oppositeness " },
    { text = "Intensifies", italic = true }
}
EVENT.Description = "Controls periodically switch"
EVENT.id = "oppositeness"
EVENT.Categories = {"largeimpact"}

CreateConVar("randomat_oppositeness_interval", 30, FCVAR_NONE, "Interval (s) between switches", 1, 120)
CreateConVar("randomat_oppositeness_accelerates", 1, FCVAR_NONE, "Whether interval reduces each switch", 0, 1)
CreateConVar("randomat_oppositeness_accelerates_rate", 1, FCVAR_NONE, "How much (s) the interval reduces each switch", 1, 60)
CreateConVar("randomat_oppositeness_accelerates_minimum_time", 10, FCVAR_NONE, "The shortest interval between switches", 1, 120)
CreateConVar("randomat_oppositeness_allow_mouse_inversion", 1, FCVAR_NONE, "Whether the mouse axes can be inverted", 0, 1)

CreateConVar("randomat_oppositeness_mouseX_weight", 1, FCVAR_NONE, "How likely the mouse X axis is to be inverted", 0, 50)
CreateConVar("randomat_oppositeness_mouseY_weight", 1, FCVAR_NONE, "How likely the mouse Y axis is to be inverted", 0, 50)
CreateConVar("randomat_oppositeness_forwards_backwards_weight", 1, FCVAR_NONE, "How likely forwads/backwards are to be switched", 0, 50)
CreateConVar("randomat_oppositeness_left_right_weight", 1, FCVAR_NONE, "How likely left/right are to be switched", 0, 50)
CreateConVar("randomat_oppositeness_jump_crouch_weight", 1, FCVAR_NONE, "How likely jump/crouch are to be switched", 0, 50)
CreateConVar("randomat_oppositeness_shoot_reload_weight", 1, FCVAR_NONE, "How likely shoot/reload are to be switched", 0, 50)
CreateConVar("randomat_oppositeness_sprint_drop_weight", 1, FCVAR_NONE, "How likely sprint/drop weapon are to be switched", 0, 50)

local baseInterval
local accelerates
local accelRate
local accelMin
local allowMouse

local mouseXInverted = false
local mouseYInverted = false
local moveInverted = false
local strafeInverted = false
local jumpInverted = false
local shootInverted = false
local sprintInverted = false

local mouseXWeight
local mouseYWeight
local moveWeight
local strafeWeight
local jumpWeight
local shootWeight
local sprintWeight

local weights = {
    mouseXWeight,
    mouseYWeight,
    moveWeight,
    strafeWeight,
    jumpWeight,
    shootWeight,
    sprintWeight
}

local switches = {
    "mouseX",
    "mouseY",
    "move",
    "strafe",
    "jump",
    "shoot",
    "sprint"
}

local switchChecks = {
    mouseXInverted,
    mouseYInverted,
    moveInverted,
    strafeInverted,
    jumpInverted,
    shootInverted,
    sprintInverted
}

local announcements = {
    "mouse X axis",
    "mouse Y axis",
    "forwards/backwards",
    "left/right",
    "jump/crouch",
    "shoot/reload",
    "sprint/drop weapon"
}

local initialInterval = 5
local count

local function announceSwitch(choice)
    local messageStart = nil

    if choice == 1 then
        messageStart = mouseX and "Uninverting " or "Inverting "
    elseif choice == 2 then
        messageStart = mouseY and "Uninverting " or "Inverting "
    else
        messageStart = switchChecks[choice] and "Unswapping " or "Swapping "
    end

    Randomat:SmallNotify(messageStart .. announcements[choice] .. "!")
end

local function SendSwitch(switch)
    local alivePlayers = Randomat:GetPlayers(false, true)

    if switch == "mouseX" then
        net.Start("OppositenessMouseX")
        net.Broadcast()
        mouseXInverted = not mouseXInverted
    elseif switch == "mouseY" then
        net.Start("OppositenessMouseY")
        net.Broadcast()
        mouseYInverted = not mouseYInverted
    elseif switch == "move" then
        net.Start("OppositenessMove")
        net.Broadcast()

        if moveInverted then
            for _, p in ipairs(alivePlayers) do
                p:SetLadderClimbSpeed(200)
            end

            hook.Remove("TTTSprintKey", "RdmtOppositenessServerMoveHook")
        else
            for _, p in ipairs(alivePlayers) do
                p:SetLadderClimbSpeed(-200)
            end

            -- Override the sprint key so living players can sprint forward while holding the back key
            hook.Add("TTTSprintKey", "RdmtOppositenessServerMoveHook", function(ply)
                if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end
                return IN_BACK
            end)
        end

        moveInverted = not moveInverted
    elseif switch == "strafe" then
        net.Start("OppositenessStrafe")
        net.Broadcast()
        strafeInverted = not strafeInverted
    elseif switch == "jump" then
        net.Start("OppositenessJump")
        net.Broadcast()
        jumpInverted = not jumpInverted
    elseif switch == "shoot" then
        net.Start("OppositenessShoot")
        net.Broadcast()
        shootInverted = not shootInverted
    elseif switch == "sprint" then
        net.Start("OppositenessSprint")
        net.Broadcast()
        sprintInverted = not sprintInverted
    end
end

local function WeightsChanged()
    for _, weight in ipairs(weights) do
        if weight ~= 1 then return true end
    end

    return false
end

local function GetWeightedChoice()
    local weighted_choices = {}

    for i, switch in pairs(weights) do
        if not allowMouse and (i == 1 or i == 2) then
            continue
        end

        local weight = switch

        for _ = 1, weight do
            TableInsert(weighted_choices, i)
        end
    end

    table.Shuffle(weighted_choices)

    -- Then get a random index from the random list for more randomness
    local total = table.Count(weighted_choices)
    local idx = math.random(total)
    local choice = weighted_events[idx]

    return choice
end

local function RunInterval()
    local thisInterval

    if count == 0 then
        thisInterval = initialInterval
    elseif accelerates then
        thisInterval = math.Clamp(baseInterval - ((count - 1) * accelRate), accelMin, baseInterval)
    else
        thisInterval = baseInterval
    end

    timer.Create("RdmtOppositenessInterval", thisInterval, 0, function()
        local choice

        if WeightsChanged() then
            GetWeightedChoice()
        else
            choice = allowMouse and math.random(1, 7) or math.random(3, 7)
        end

        local thisSwitch = switches[choice]

        announceSwitch(choice)
        SendSwitch(thisSwitch)
        count = count + 1
        RunInterval()
    end)
end

net.Receive("OppositenessSprint", function(ln, ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.AllowDrop then
        ply:DropWeapon(wep)
        ply:SetFOV(0, 0.2)
    end
end)

function EVENT:Begin()

baseInterval = GetConVar("randomat_oppositeness_interval"):GetInt()
accelerates = GetConVar("randomat_oppositeness_accelerates"):GetBool()
accelRate = GetConVar("randomat_oppositeness_accelerates_rate"):GetInt()
accelMin = GetConVar("randomat_oppositeness_accelerates_minimum_time"):GetInt()
allowMouse = GetConVar("randomat_oppositeness_allow_mouse_inversion"):GetBool()

mouseXWeight = GetConVar("randomat_oppositeness_mouseX_weight"):GetInt()
mouseYWeight = GetConVar("randomat_oppositeness_mouseY_weight"):GetInt()
moveWeight = GetConVar("randomat_oppositeness_forwards_backwards_weight"):GetInt()
strafeWeight = GetConVar("randomat_oppositeness_left_right_weight"):GetInt()
jumpWeight = GetConVar("randomat_oppositeness_jump_crouch_weight"):GetInt()
shootWeight = GetConVar("randomat_oppositeness_shoot_reload_weight"):GetInt()
sprintWeight = GetConVar("randomat_oppositeness_sprint_drop_weight"):GetInt()

    -- Sanity checks
    if accelMin > baseInterval then accelMin = baseInterval end
    if accelRate > baseInterval - accelMin then accelRate = baseInterval - accelMin end

    count = 0

    RunInterval()

    self:AddHook("PlayerDeath", function(victim, entity, killer)
        if not IsValid(victim) then return end
        victim:SetLadderClimbSpeed(200)
    end)

    self:AddHook("PlayerSpawn", function(ply)
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end
        if moveInverted then ply:SetLadderClimbSpeed(-200) end
    end)
end

function EVENT:End()
    timer.Remove("RdmtOppositenessInterval")
    timer.Remove("RemoveMe")

    hook.Remove("TTTSprintKey", "RdmtOppositenessServerMoveHook")

    for _, p in player.Iterator() do
        p:SetLadderClimbSpeed(200)
    end

    net.Start("OppositenessEnd")
    net.Broadcast()

    mouseXInverted = false
    mouseYInverted = false
    moveInverted = false
    strafeInverted = false
    jumpInverted = false
    shootInverted = false
    sprintInverted = false
end

function EVENT:GetConVars()
    local layout = {
        ["interval"] = 1,
        ["allow_mouse_inversion"] = 2,

        ["Switch Acceleration"] = {
            pos = 3,
            collapsible = false,
            items = {
                "accelerates",
                "accelerates_rate",
                "accelerates_minimum_time"
            }
        },

        ["Switch Weights"] = {
            pos = 4,
            collapsible = true,
            items = {
                "mouseX_weight",
                "mouseY_weight",
                "forwards_backwards_weight",
                "left_right_weight",
                "jump_crouch_weight",
                "shoot_reload_weight",
                "sprint_drop_weight"
            }
        }
    }

    local positions = {}
    local categories = {}
    self.CategoryConfig = {}

    for key, data in pairs(layout) do
        if type(data) == "table" then
            self.CategoryConfig[key] = {
                pos = data.pos,
                collapsible = data.collapsible or false,
                expanded = data.expanded or false
            }

            for k, v in pairs(data.items or {}) do
                positions[v] = k
                categories[v] = key
            end
        else
            positions[key] = data
        end
    end

    local sliders = {}
    for _, v in ipairs({"interval", "accelerates_minimum_time", "mouseX_weight", "mouseY_weight", "forwards_backwards_weight", "left_right_weight", "jump_crouch_weight", "shoot_reload_weight", "sprint_drop_weight"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0,
                pos = positions[v],
                cat = categories[v]
            })
        end
    end

    for _, v in ipairs({"accelerates_rate"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 1,
                pos = positions[v],
                cat = categories[v]
            })
        end
    end

    local checks = {}
    for _, v in ipairs({"accelerates", "allow_mouse_inversion"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText(),
                pos = positions[v],
                cat = categories[v] -- NEW
            })
        end
    end

    return sliders, checks
end

Randomat:register(EVENT)