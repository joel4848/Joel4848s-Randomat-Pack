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
EVENT.DisplayTitle = "Oppositeness Intensifies"
EVENT.Description = "Controls periodically switch"
EVENT.id = "oppositeness"
EVENT.Categories = {"largeimpact"}

local baseIntervalConVar = GetConVar("randomat_oppositeness_interval")
local acceleratesConVar  = GetConVar("randomat_oppositeness_accelerates")
local accelRateConVar    = GetConVar("randomat_oppositeness_accelerates_rate")
local accelMinConVar     = GetConVar("randomat_oppositeness_accelerates_minimum_time")
local allowMouseConVar   = GetConVar("randomat_oppositeness_allow_mouse_inversion")
local doMouseBothConVar  = GetConVar("randomat_oppositeness_mouse_invert_both")

local mouseXWeightConVar    = GetConVar("randomat_oppositeness_mouseX_weight")
local mouseYWeightConVar    = GetConVar("randomat_oppositeness_mouseY_weight")
local mouseBothWeightConVar = GetConVar("randomat_oppositeness_mouse_both_weight")
local moveWeightConVar      = GetConVar("randomat_oppositeness_forwards_backwards_weight")
local strafeWeightConVar    = GetConVar("randomat_oppositeness_left_right_weight")
local jumpWeightConVar      = GetConVar("randomat_oppositeness_jump_crouch_weight")
local shootWeightConVar     = GetConVar("randomat_oppositeness_shoot_reload_weight")
local sprintWeightConVar    = GetConVar("randomat_oppositeness_sprint_drop_weight")

local baseInterval
local accelerates
local accelRate
local accelMin
local allowMouse
local doMouseBoth

local mouseXInverted = false
local mouseYInverted = false
local moveInverted   = false
local strafeInverted = false
local jumpInverted   = false
local shootInverted  = false
local sprintInverted = false

local mouseXWeight
local mouseYWeight
local mouseBothWeight
local moveWeight
local strafeWeight
local jumpWeight
local shootWeight
local sprintWeight

local weights = {}

local switches = {
    "mouseX",
    "mouseY",
    "mouseBoth",
    "move",
    "strafe",
    "jump",
    "shoot",
    "sprint"
}

local switchChecks = {}

local announcements = {
    "mouse X axis",
    "mouse Y axis",
    "mouse axes",
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

    if choice <= 3 then
        -- "Uninverting"/"Inverting" for mouse axes
        messageStart = switchChecks[choice] and "Uninverting " or "Inverting "
        switchChecks[choice] = not switchChecks[choice]
    else
        -- "Unswapping"/"Swapping" for everything else
        messageStart = switchChecks[choice] and "Unswapping " or "Swapping "
        switchChecks[choice] = not switchChecks[choice]
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
    elseif switch == "mouseBoth" then
        net.Start("OppositenessMouseX")
        net.Broadcast()
        net.Start("OppositenessMouseY")
        net.Broadcast()
        mouseXInverted = not mouseXInverted
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
            -- Reverse ladder climb speed so that players can climb ladders using the back key
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

    for i, weight in ipairs(weights) do
        if not allowMouse then
            -- If we're not allowing mouse switching, ignore all mouse switches
            if i == 1 or i == 2 or i == 3 then continue end
        else
            if doMouseBoth then
                -- If we're doing both mouse axes together, ignore individual mouse switches
                if i == 1 or i == 2 then continue end
            else
                -- If we're NOT doing both mouse axes together, then ignore the combined mouse switch
                if i == 3 then continue end
            end
        end

        -- Add an entry for each weight value
        for _ = 1, weight do
            table.insert(weighted_choices, i)
        end
    end

    if #weighted_choices == 0 then
        return allowMouse and (doMouseBoth and 3 or math.random(1, 2)) or math.random(4, 8)
    end

    table.Shuffle(weighted_choices)

    local total = table.Count(weighted_choices)
    local idx = math.random(total)
    local choice = weighted_choices[idx]

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
            choice = GetWeightedChoice()
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
    baseInterval = baseIntervalConVar:GetInt()
    accelerates  = acceleratesConVar:GetBool()
    accelRate    = accelRateConVar:GetInt()
    accelMin     = accelMinConVar:GetInt()
    allowMouse   = allowMouseConVar:GetBool()
    doMouseBoth  = doMouseBothConVar:GetBool()

    mouseXWeight    = mouseXWeightConVar:GetInt()
    mouseYWeight    = mouseYWeightConVar:GetInt()
    mouseBothWeight = mouseBothWeightConVar:GetInt()
    moveWeight      = moveWeightConVar:GetInt()
    strafeWeight    = strafeWeightConVar:GetInt()
    jumpWeight      = jumpWeightConVar:GetInt()
    shootWeight     = shootWeightConVar:GetInt()
    sprintWeight    = sprintWeightConVar:GetInt()

    weights = {
        mouseXWeight,
        mouseYWeight,
        mouseBothWeight,
        moveWeight,
        strafeWeight,
        jumpWeight,
        shootWeight,
        sprintWeight
    }

    switchChecks = {
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false
    }

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

    -- I think these are redundant now?
    mouseXInverted = false
    mouseYInverted = false
    moveInverted   = false
    strafeInverted = false
    jumpInverted   = false
    shootInverted  = false
    sprintInverted = false
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"interval", "accelerates_minimum_time", "mouseX_weight", "mouseY_weight", "mouse_both_weight", "forwards_backwards_weight", "left_right_weight", "jump_crouch_weight", "shoot_reload_weight", "sprint_drop_weight"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
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
                dcm = 1
            })
        end
    end

    local checks = {}
    for _, v in ipairs({"accelerates", "allow_mouse_inversion", "mouse_invert_both", "display_current_swaps"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end

    local textboxes = {}

    local layout = {
        ["accelerates"]              = 1,
        ["display_current_swaps"]    = 2,
        ["interval"]                 = 3,
        ["accelerates_rate"]         = 4,
        ["accelerates_minimum_time"] = 5,

        ["Mouse Axis Swapping"] = {
            pos = 6,
            items = {
                "allow_mouse_inversion",
                "mouse_invert_both",
            }
        },

        ["Swap Weighting"] = {
            pos = 7,
            items = {
                "forwards_backwards_weight",
                "left_right_weight",
                "jump_crouch_weight",
                "shoot_reload_weight",
                "sprint_drop_weight",
                "mouseX_weight",
                "mouseY_weight",
                "mouse_both_weight",
            }
        },
    }

    return sliders, checks, textboxes, layout
end

Randomat:register(EVENT)