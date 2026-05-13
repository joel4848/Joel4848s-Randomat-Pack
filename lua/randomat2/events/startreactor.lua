local EVENT = {}

EVENT.Title = "Simon Sus (a.k.a. Buttonracer)"
EVENT.Description = "Enter each pattern correctly before the timer runs out, or be ejected!"
EVENT.id = "startreactor"
EVENT.Categories = {"gamemode", "largeimpact"}

util.AddNetworkString("RdmtStartReactorPattern")
util.AddNetworkString("RdmtStartReactorSuccess")
util.AddNetworkString("RdmtStartReactorEjectionAnnouncement")
util.AddNetworkString("RdmtStartReactorDeadAliveChange")

local initialTime = CreateConVar("randomat_startreactor_initial_time", 10, FCVAR_NONE, "Time (s) for players to enter the first pattern", 5, 60):GetInt()
local timeIncrease = CreateConVar("randomat_startreactor_additional_time", 1, FCVAR_NONE, "Additional time (s) players get for each additional light in the pattern", 5, 60):GetInt()
local eject = CreateConVar("randomat_startreactor_actually_eject", 1, FCVAR_NONE, "Whether to eject unsuccessful players from the map", 0, 1):GetBool()

-- local restTime = GetConVar("randomat_startreactor_rest_time"):GetInt()

local pattern = {}
local ejectedPlayers = {}
local initialDelay = 5
local roundCount = 0
local alivePlayers = alivePlayers or {}
local successfulPlayers = successfulPlayers or {}

local function BroadcastSuccessfulPlayers()
    successfulPlayers = {}

    for _, ply in ipairs(player.GetAll()) do
        print("Running add to successfulPlayers for " .. ply:Nick())
        print("ply.successful = " .. tostring(ply.successful))
        successfulPlayers[ply:SteamID64()] = ply.successful
        print("successfulPlayers now contains:")
        PrintTable(successfulPlayers)
    end

    net.Start("RdmtStartReactorSuccess")
        net.WriteTable(successfulPlayers)
    net.Broadcast()
end

local function BroadcastAlivePlayers()
    local alivePlayers = {}

    for _, ply in ipairs(player.GetAll()) do
        alivePlayers[ply:SteamID64()] = (ply:Alive() and not ply:IsSpec())
    end

    net.Start("RdmtStartReactorDeadAliveChange")
        net.WriteTable(alivePlayers)
    net.Broadcast()
end

local function GetRestTime()
    return GetConVar("randomat_startreactor_rest_time"):GetInt()
end

local function CreatePattern(timeLimit)
    local nextNumber
    repeat
        nextNumber = math.random(1, 9)
    until not (#pattern >= 2 and pattern[#pattern] == nextNumber and pattern[#pattern-1] == nextNumber)

    table.insert(pattern, nextNumber)

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply.successful = false
        end
    end

    successfulPlayers = {}

    net.Start("RdmtStartReactorSuccess")
        net.WriteTable(successfulPlayers)
    net.Broadcast()

    net.Start("RdmtStartReactorPattern")
        net.WriteTable(pattern) 
        net.WriteFloat(timeLimit) 
    net.Broadcast()
end

function EjectionAnnouncement(names)
    local count = #names
    local fullMessage = ""

    if count == 0 then
        fullMessage = "No one was ejected."
    elseif count == 1 then
        fullMessage = names[1] .. " was ejected."
    elseif count == 2 then
        fullMessage = names[1] .. " and " .. names[2] .. " were ejected."
    else
        local initialPart = table.concat(names, ", ", 1, count - 1)
        fullMessage = initialPart .. " and " .. names[count] .. " were ejected."
    end

    net.Start("RdmtStartReactorEjectionAnnouncement")
        net.WriteString(fullMessage)
    net.Broadcast()
end

local function StartReactorRound()
    if not Randomat:IsEventActive("startreactor") then return end
    roundCount = roundCount + 1
    local timeToSucceed = initialTime + ((roundCount - 1) * timeIncrease)

    CreatePattern(timeToSucceed)
    
    timer.Create("RdmtStartReactorSuccessTimer", timeToSucceed, 1, function()
        ejectedPlayers = {}
        for _, ply in ipairs(player.GetAll()) do
            if not ply.successful and ply:Alive() and not ply:IsSpec() then
                ply:Kill()

                table.insert(ejectedPlayers, ply:Nick())

                if eject then
                    timer.Create("RdmtStartReactorTickTimer", 0.1, 1, function()
                        if not IsValid(ply) then return end

                        local ragdoll = ply.server_ragdoll or ply:GetRagdollEntity()

                        if IsValid(ragdoll) then
                            originalCollisionGroup = ragdoll:GetCollisionGroup()
                            ragdoll:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

                            for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                                local phys = ragdoll:GetPhysicsObjectNum(i)
                                if IsValid(phys) then
                                    phys:ApplyForceCenter(Vector(0, 0, 50000))
                                    phys:EnableGravity(false)
                                end
                            end
                    
                            timer.Create("RdmtStartReactorRagdollTimer", 1, 1, function()
                                ragdoll:SetCollisionGroup(originalCollisionGroup)
                            end)
                        end
                    end)
                end
            end
            ply.successful = false
        end
        EjectionAnnouncement(ejectedPlayers)

        timer.Create("RdmtStartReactorRestTimer", GetRestTime(), 1, function()
            StartReactorRound() 
        end)
    end)
end

function EVENT:Begin()
    roundCount = 0
    pattern = {}

    for _, ply in ipairs(player.GetAll()) do
        ply.successful = false
    end

    BroadcastAlivePlayers()
    BroadcastSuccessfulPlayers()

    timer.Create("RdmtStartReactorInitialTimer", initialDelay, 1, function()
        StartReactorRound()
    end)

    hook.Add("PostPlayerDeath", "randomat_startreactor_postplayerdeath", function()
        BroadcastAlivePlayers()
        BroadcastSuccessfulPlayers()
    end)

    hook.Add("PlayerSpawn", "randomat_startreactor_playerspawn", function()
        BroadcastAlivePlayers()
        BroadcastSuccessfulPlayers()
    end)
end

net.Receive("RdmtStartReactorSuccess", function(ln, ply)
    ply.successful = true

    BroadcastSuccessfulPlayers()
end)

function EVENT:End()
    timer.Remove("RdmtStartReactorSuccessTimer")
    timer.Remove("RdmtStartReactorTickTimer")
    timer.Remove("RdmtStartReactorRagdollTimer")
    timer.Remove("RdmtStartReactorRestTimer")
    timer.Remove("RdmtStartReactorInitialTimer")

    hook.Remove("PostPlayerDeath", "randomat_startreactor_postplayerdeath")
    hook.Remove("PlayerSpawn", "randomat_startreactor_playerspawn")

    successfulPlayers = {}
    roundCount = 0
end

function EVENT:GetConVars()
    local sliders = {}
    
    for _, v in ipairs({"initial_time", "additional_time", "rest_time"}) do
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

    local checks = {}
    for _, v in ipairs({"actually_eject"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end
    return sliders, checks
end

Randomat:register(EVENT)