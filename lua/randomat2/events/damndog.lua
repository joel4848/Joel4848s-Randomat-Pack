local EVENT = {}

EVENT.Title = "That &#@%!*% dog!"
EVENT.Description = "Woof!"
EVENT.id = "damndog"
EVENT.Categories = {"moderateimpact"}

util.AddNetworkString("DamnDogSpawnDog")

CreateConVar("randomat_damndog_trip_power_multiplier", 1.5, FCVAR_NONE, "How far the player is flung when they trip", 0, 100)
CreateConVar("randomat_damndog_interval_lower", 20, FCVAR_NONE, "The shortest time between damn dog spawns", 1, 60)
CreateConVar("randomat_damndog_interval_upper", 30, FCVAR_NONE, "The longest time between damn dog spawns", 1, 60)
CreateConVar("randomat_damndog_affect_all", 0, FCVAR_NONE, "Whether everyone gets a dog at the same time", 0, 1)
CreateConVar("randomat_damndog_spawn_distance", 75, FCVAR_NONE, "How far dogs spawn from their players", 1, 1000)

local lower
local upper
local affectAll
local dogSpawnDistance

local dogChoices = {
    [1] = {model = "dog2/annoying_dog"},
    [2] = {model = "dog1/npc_dog"},
    [3] = {model = "dog3/doge_player", height = 21, scale = 0.75, skin = 0},
    [4] = {model = "dog3/doge_player", height = 21, scale = 0.75, skin = 1},
    [5] = {model = "dog3/doge_player", height = 21, scale = 0.75, skin = 2},
    [6] = {model = "dog3/doge_player", height = 21, scale = 0.75, skin = 3}
}

local function ChooseDog()
    choice = math.random(1, #dogChoices)
    table.Shuffle(dogChoices)
    return dogChoices[choice].model, dogChoices[choice].height or nil, dogChoices[choice].scale or nil, dogChoices[choice].skin or nil
end

local function SpawnDog(ply)
    local plyPos = ply:GetPos()
    dogSpawnDistance = GetConVar("randomat_damndog_spawn_distance"):GetInt()

    local moveDir = ply:GetVelocity()

    dogSpawnDistance = dogSpawnDistance * math.Clamp(moveDir:Length() / 220, 1, math.huge)

    -- A dog shouldn't spawn if they're not moving, but for safety if somehow it still does, use eye angles
    if moveDir:LengthSqr() <= 0 then
        moveDir = ply:EyeAngles():Forward()
    end

    moveDir = moveDir:GetNormalized()

    local pos = plyPos + moveDir * dogSpawnDistance
    -- local ang = moveDir:Angle()

    local dogModel, dogHeight, dogScale, dogSkin = ChooseDog()

    local zOffset = (ply:IsOnGround() and dogHeight) and dogHeight or 0
    local targetPos = pos + Vector(0, 0, zOffset)

    local trace = util.TraceLine({
        start = plyPos + Vector(0, 0, 32),
        endpos = targetPos,
        filter = ply,
        mask = MASK_SOLID
    })

    if trace.Hit then
        targetPos = trace.HitPos + (trace.HitNormal * 2)
    end

    local dog = ents.Create("ttt_rdmt_damndog_dog")
    dog:SetModel("models/damndog/" .. dogModel .. ".mdl")
    dog:SetPos(targetPos)
    dog:SetModelScale(dogScale or 1, 0)
    if dogSkin then dog:SetSkin(dogSkin) end
    -- dog:SetAngles(ang)
    dog:Spawn()
    dog:Activate()

    return dog -- Not that my own dog ever listens when I tell her to return. Thanks Bel.
end

local function StartIndividualTimer(ply, thisEvent)
    if not IsValid(ply) or not thisEvent.DamnDogTimers then return end
    if thisEvent.DamnDogTimers[ply] then return end

    local timerName = "RdmtDamnDog_" .. ply:SteamID64()
    thisEvent.DamnDogTimers[ply] = timerName

    timer.Create(timerName, math.random(lower, upper), 1, function()
        if thisEvent.DamnDogTimers then thisEvent.DamnDogTimers[ply] = nil end

        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() or ply.inRagdoll then return end

        if ply:GetVelocity():LengthSqr() > 10 then -- Only spawn a dog if the player is moving
            -- Remove their last dog if it still exists
            if IsValid(ply.LastSpawnedDog) then ply.LastSpawnedDog:Remove() end

            ply.LastSpawnedDog = SpawnDog(ply)

            -- Start their next timer if a dog has now spawned
            StartIndividualTimer(ply, thisEvent)
        else -- If they're not moving, mark them as due a dog spawn
            ply.PendingDogSpawn = true
        end
    end)
end

function EVENT:Begin()
    lower = GetConVar("randomat_damndog_interval_lower"):GetInt()
    upper = GetConVar("randomat_damndog_interval_upper"):GetInt()
    affectAll = GetConVar("randomat_damndog_affect_all"):GetBool()

    if lower > upper then
        upper = lower + 1
    end

    -- Check for movement and do deferred dog spawning
    self.DamnDogTimers = self.DamnDogTimers or {}

    self:AddHook("Think", function()
        for _, ply in player.Iterator() do
            if not IsValid(ply) then continue end

            -- If player is due a dog spawn, spawn them one when they move
            if ply:Alive() and not ply:IsSpec() and ply.PendingDogSpawn then
                if ply:GetVelocity():LengthSqr() > 10 then
                    ply.PendingDogSpawn = false

                    if IsValid(ply.LastSpawnedDog) then ply.LastSpawnedDog:Remove() end
                    ply.LastSpawnedDog = SpawnDog(ply)

                    if not affectAll then
                        StartIndividualTimer(ply, self)
                    end
                end
            end

            if not affectAll and ply:Alive() and not ply:IsSpec() and not ply.inRagdoll and not ply.PendingDogSpawn then
                local timerName = "RdmtDamnDog_" .. ply:SteamID64()

                if not timer.Exists(timerName) then
                    self.DamnDogTimers[ply] = nil
                end

                if not self.DamnDogTimers[ply] then
                    StartIndividualTimer(ply, self)
                end
            end
        end
    end)

    if affectAll then
        timer.Create("RdmtDamnDogMain", math.random(lower, upper), 0, function()
            -- If player is moving when the main timer runs out, spawn a dog
            for _, ply in ipairs(self:GetAlivePlayers()) do
                if ply:GetVelocity():LengthSqr() > 10 then
                    -- Remove their last dog if it still exists
                    if IsValid(ply.LastSpawnedDog) then ply.LastSpawnedDog:Remove() end
                    ply.LastSpawnedDog = SpawnDog(ply)
                else
                    ply.PendingDogSpawn = true -- If they're not moving, mark them as due a dog spawn
                end
            end

            timer.Adjust("RdmtDamnDogMain", math.random(lower, upper))
        end)
    else
        for _, ply in ipairs(self:GetAlivePlayers()) do
            StartIndividualTimer(ply, self)
        end
    end

    -- TESTING ONLY - REMOVE BEFORE RELEASE
    net.Receive("DamnDogSpawnDog", function(_, ply)
        if IsValid(ply) then
            if IsValid(ply.LastSpawnedDog) then ply.LastSpawnedDog:Remove() end
            ply.LastSpawnedDog = SpawnDog(ply)
        end
    end)

    -- Make ragdolled players immune to crushing and falling damage
    self:AddHook("PostEntityTakeDamage", function(ent, dmg, taken)
        if not taken then return end
        if not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" then return end
        if dmg:IsDamageType(DMG_CRUSH) or dmg:IsDamageType(DMG_FALL) then return end
        for _, v in player.Iterator() do
            if ent == v.ragdoll and v.spawnInfo then
                v.spawnInfo.health = v.spawnInfo.health - dmg:GetDamage()
                return
            end
        end
    end)

    self:AddHook("EntityTakeDamage", function(target, dmg)
        -- Check if the thing taking damage is a valid, alive player
        if IsValid(target) and target:IsPlayer() and target:Alive() then
            -- Check if it's fall or physics crush damage
            if dmg:IsDamageType(DMG_FALL) or dmg:IsDamageType(DMG_CRUSH) then
                -- Look for any nearby damn dogs to see if they caused/are involved in the collision
                for _, dog in ipairs(ents.FindByClass("ttt_rdmt_damndog_dog")) do
                    if IsValid(dog) then
                        -- If the player is essentially touching the dog's bounding area, nullify the damage
                        local maxDistance = dog:BoundingRadius() * dog:GetModelScale() + 32
                        if target:GetPos():Distance(dog:GetPos()) <= maxDistance then
                            dmg:ScaleDamage(0)
                            return true -- Overrides the damage completely
                        end
                    end
                end
            end
        end
    end)

    -- Fixes killed players being immediately spawned a dog and then ragdolled if revived
    self:AddHook("PlayerDeath", function(victim)
        if not IsValid(victim) then return end

        victim.PendingDogSpawn = nil
        victim.inRagdoll = nil

        self.DamnDogTimers[victim] = nil
        timer.Remove("RdmtDamnDog_" .. victim:SteamID64())
        if IsValid(victim.LastSpawnedDog) then
            victim.LastSpawnedDog:Remove()
            victim.LastSpawnedDog = nil
        end
    end)
end

function EVENT:End()
    timer.Remove("RdmtDamnDogMain")

    for _, ply in player.Iterator() do
        timer.Remove("RdmtDamnDog_" .. ply:SteamID64())
        ply.PendingDogSpawn = nil
        if IsValid(ply.LastSpawnedDog) then ply.LastSpawnedDog:Remove() end
    end
end

Randomat:register(EVENT)