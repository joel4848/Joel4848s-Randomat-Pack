local ents = ents
local math = math
local table = table
local timer = timer
local player = player

local MathRandom = math.random
local TableInsert = table.insert
local TableRemoveByValue = table.RemoveByValue
local PlayerIterator = player.Iterator

local EVENT = {}

EVENT.Title       = "Speedracer"
EVENT.Description = "Make it to each location in time... or else!"
EVENT.id          = "speedracer"
EVENT.Categories  = {"gamemode", "largeimpact"}

function RewardSuccess(successfulPlayers)
    for _, ply in ipairs(successfulPlayers) do
        local reward = Joel4848:ApplyReward(ply)

        Randomat:SmallNotify("You made it! Your reward is: " .. reward.Name)
    end

end

function PunishFailure(failingPlayers)
    for _, ply in ipairs(failingPlayers) do
        local punishment = Joel4848:ApplyPunishment(ply, {"blindish"})

        Randomat:SmallNotify("Too slow! Your punishment is: " .. punishment.Name)
    end
end

local function GetSpeedracerPosition()
    local spawns = GetSpawnEnts and GetSpawnEnts(true, false) or {}
    for _, e in ents.Iterator() do
        if IsValid(e:GetParent()) then continue end
        if e:WaterLevel() ~= 0 then continue end
        local entity_class = e:GetClass()
        if string.StartsWith(entity_class, "weapon_") or string.StartsWith(entity_class, "item_") then
            TableInsert(spawns, e)
        end
    end
    local spawn = spawns[MathRandom(#spawns)]
    return spawn:GetPos()
end

local offsets = {}
for i = 0, 360, 15 do
    TableInsert(offsets, Vector(math.sin(math.rad(i)), math.cos(math.rad(i)), 0))
end

local function FindStartLocation(pos)
    local midsize = Vector(33, 33, 74)
    local halfWidth = midsize.x / 2

    local mins = Vector(-halfWidth, -halfWidth, 0)
    local maxs = Vector(halfWidth, halfWidth, midsize.z)

    local feetMins = Vector(-halfWidth, -halfWidth, 0)
    local feetMaxs = Vector(halfWidth, halfWidth, 1)

    -- Check if the center position is free
    local trCenter = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = mins,
        maxs = maxs
    })
    if not trCenter.Hit then return pos end

    for radiusMultiplier = 1, 3 do
        local currentRadius = midsize.x * radiusMultiplier

        for i = 1, #offsets do
            local testPos = pos + (offsets[i] * currentRadius)

            -- Check if there is floor under the entire box
            local floorTrace = util.TraceHull({
                start = testPos + Vector(0, 0, 30),
                endpos = testPos - Vector(0, 0, 50),
                mins = feetMins,
                maxs = feetMaxs,
                mask = MASK_SOLID_BRUSHONLY
            })

            -- If it didn't hit a solid floor, skip this location
            if not floorTrace.Hit then continue end

            local spawnPos = floorTrace.HitPos

            -- Check the full player box fits here
            local tr = util.TraceHull({
                start = spawnPos,
                endpos = spawnPos,
                mins = mins,
                maxs = maxs
            })

            if not tr.Hit then
                return spawnPos
            end
        end
    end

    return false
end

function EVENT:Begin()
    local delayCvar        = GetConVar("randomat_speedracer_delay")
    local timerInitialCvar = GetConVar("randomat_speedracer_timer_initial")
    local timerCvar        = GetConVar("randomat_speedracer_timer")
    local autoadvanceCvar  = GetConVar("randomat_speedracer_autoadvance")

    local distance = GetConVar("randomat_speedracer_distance"):GetFloat() * (UNITS_PER_METER or 39.37)
    local distanceSquared = distance * distance

    local isFirstRound      = true
    local reachedThisRound  = {}
    local successOrder      = {}
    local previousSuccesses = {}

    local StartHuntPhase
    local StartDelayPhase

    StartDelayPhase = function()
        SetGlobalBool("SpeedracerActive", false)
        timer.Remove("Randomat_Speedracer_Check")

        local successes = {}
        local failures = {}
        local failureNames = {}
        local everyoneMadeIt = true
        local firstSuccess = successOrder[1]

        for _, ply in PlayerIterator() do
            if not IsValid(ply) or not ply:Alive() then continue end
            if reachedThisRound[ply] then
                TableInsert(successes, ply)
            else
                TableInsert(failures, ply)
                TableInsert(failureNames, ply:Nick())
                everyoneMadeIt = false
            end
        end

        -- Check if anyone who succeeded previously is dead/missing
        for _, ply in ipairs(previousSuccesses) do
            if not reachedThisRound[ply] then
                everyoneMadeIt = false
                if IsValid(ply) and not table.HasValue(failures, ply) then
                    TableInsert(failureNames, ply:Nick())
                end
            end
        end

        if everyoneMadeIt then
            self:SmallNotify("Everyone made it!")
        else
            local failureString = ""
            local count = #failureNames

            if count > 0 then
                if count == 1 then
                    failureString = failureNames[1] .. " didn't make it!"
                elseif count == 2 then
                    failureString = failureNames[1] .. " and " .. failureNames[2] .. " didn't make it!"
                else
                    local namesPart = table.concat(failureNames, ", ", 1, count - 1)
                    failureString = namesPart .. " and " .. failureNames[count] .. " didn't make it!"
                end
            end

            self:SmallNotify(failureString)
        end

        if GetConVar("randomat_speedracer_kill_failures"):GetBool() then
            for _, ply in ipairs(failures) do
                ply:Kill()
            end
        end

        if GetConVar("randomat_speedracer_reward_first_success"):GetBool() and firstSuccess then
            RewardSuccess({firstSuccess})
        end

        if GetConVar("randomat_speedracer_reward_success"):GetBool() and #successes > 0 then
            RewardSuccess(successes)
        end

        if GetConVar("randomat_speedracer_punish_failures"):GetBool() and #failures > 0 then
            PunishFailure(failures)
        end

        previousSuccesses = successes
        timer.Create("Randomat_Speedracer_Main", delayCvar:GetInt(), 1, StartHuntPhase)
    end

    StartHuntPhase = function()
        local time = isFirstRound and timerInitialCvar:GetInt() or timerCvar:GetInt()
        isFirstRound = false

        local pos = GetSpeedracerPosition()
        SetGlobalVector("SpeedracerTarget", pos)
        SetGlobalFloat("SpeedracerEnd", CurTime() + time)
        SetGlobalBool("SpeedracerActive", true)

        table.Empty(reachedThisRound)
        table.Empty(successOrder)

        local requiredToAdvance = {}
        for _, ply in ipairs(previousSuccesses) do
            if IsValid(ply) then requiredToAdvance[ply] = true end
        end
        for _, ply in PlayerIterator() do
            if IsValid(ply) and ply:Alive() then
                requiredToAdvance[ply] = true
            end
        end

        self:SmallNotify("Go!")

        timer.Create("Randomat_Speedracer_Check", 0.1, 0, function()
            local allMadeIt = true

            for _, ply in PlayerIterator() do
                -- If they disconnect/die, remove them
                if not IsValid(ply) or not ply:Alive() then
                    if reachedThisRound[ply] then
                        reachedThisRound[ply] = nil
                        TableRemoveByValue(successOrder, ply)
                    end
                    continue
                end

                local isInside = ply:GetPos():DistToSqr(pos) <= distanceSquared

                -- Made it
                if isInside and not reachedThisRound[ply] then
                    reachedThisRound[ply] = true
                    TableInsert(successOrder, ply)
                    self:SmallNotify("You have entered the safe zone!", 5, ply)

                -- Unmade it
                elseif not isInside and reachedThisRound[ply] then
                    reachedThisRound[ply] = nil
                    TableRemoveByValue(successOrder, ply)
                    self:SmallNotify("You have left the safe zone!", 5, ply)
                end
            end

            if autoadvanceCvar:GetBool() then
                for requiredPlayers, _ in pairs(requiredToAdvance) do
                    if not reachedThisRound[requiredPlayers] then
                        allMadeIt = false
                        break
                    end
                end

                if allMadeIt then
                    timer.Remove("Randomat_Speedracer_Main")
                    StartDelayPhase()
                end
            end
        end)

        timer.Create("Randomat_Speedracer_Main", time, 1, StartDelayPhase)
    end

    timer.Create("Randomat_Speedracer_Start1", 5, 1, function()
        self:SmallNotify("Freezing and teleporting everyone to the start line in 5 seconds...")

        timer.Create("Randomat_Speedracer_Start2", 5, 1, function()
            -- Teleport people to the start location frame by frame
            local startPos = GetSpeedracerPosition()
            local playersToTeleport = self:GetAlivePlayers()
            local index = 1

            timer.Create("Speedracer_StartlineTeleport", 0, #playersToTeleport, function()
                local ply = playersToTeleport[index]

                if IsValid(ply) and ply:Alive() then
                    local newPos
                    if index == 1 then
                        newPos = FindStartLocation(startPos)
                    else
                        newPos = FindStartLocation(playersToTeleport[index-1]:GetPos())
                    end

                    if not newPos then
                        newPos = startPos
                    end

                    ply:Freeze(true)
                    ply:SetPos(newPos)

                    index = index + 1
                end
            end)

            -- Start the actual event
            timer.Create("Randomat_Speedracer_Main", delayCvar:GetInt(), 1, function()
                for _, ply in ipairs(playersToTeleport) do
                    ply:Freeze(false)
                end
                StartHuntPhase()
            end)
        end)
    end)
end

function EVENT:End()
    timer.Remove("Randomat_Speedracer_Main")
    timer.Remove("Randomat_Speedracer_Check")
    timer.Remove("Speedracer_StartlineTeleport")
    timer.Remove("Randomat_Speedracer_Start1")
    timer.Remove("Randomat_Speedracer_Start2")
    SetGlobalBool("SpeedracerActive", false)

    Joel4848:CleanUpRewardPunish()
end

function EVENT:GetConVars()
    local sliders = {}

    for _, v in ipairs({"delay", "timer", "timer_initial"}) do
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

    for _, v in ipairs({"distance"}) do
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
    for _, v in ipairs({"autoadvance", "kill_failures", "reward_first_success", "reward_success", "punish_failures"}) do
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
        ["timer_initial"]        = 1,
        ["timer"]                = 2,
        ["delay"]                = 3,
        ["autoadvance"]          = 4,
        ["kill_failures"]        = 5,
        ["reward_first_success"] = 6,
        ["reward_success"]       = 7,
        ["punish_failures"]      = 8,
        ["distance"]             = 9,
    }

    return sliders, checks, textboxes, layout
end

Randomat:register(EVENT)