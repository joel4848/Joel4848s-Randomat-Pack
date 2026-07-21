local EVENT = {}

Joel4848 = Joel4848 or {}

EVENT.Title = "That &#@%!*% dog!"
EVENT.Description = "Randomly spawns &#@%!*% dogs that'll get under your &#@%!*% feet"
EVENT.id = "damndog"
EVENT.Categories = {"moderateimpact"}

util.AddNetworkString("DamnDogSpawnDog")

CreateConVar("randomat_damndog_trip_power_multiplier", 1.5, FCVAR_NONE, "How far the player is flung when they trip", 0, 100)
CreateConVar("randomat_damndog_interval_lower", 20, FCVAR_NONE, "The shortest time between damn dog spawns", 1, 120)
CreateConVar("randomat_damndog_interval_upper", 30, FCVAR_NONE, "The longest time between damn dog spawns", 1, 120)
CreateConVar("randomat_damndog_affect_all", 0, FCVAR_NONE, "Whether everyone gets a dog at the same time", 0, 1)
CreateConVar("randomat_damndog_spawn_distance", 75, FCVAR_NONE, "How far dogs spawn from their players", 1, 1000)
CreateConVar("randomat_damndog_cat_chance", 10, FCVAR_NONE, "Percentage chance the dog is, in fact, a cat", 5, 100)

local lowerTime
local upperTime
local affectAll
local dogSpawnDistance

local dogChoices = {
    [1]  = {model = "dog2/annoying_dog"},
    [2]  = {model = "dog1/npc_dog"},
    [3]  = {model = "dog3/doge_player",   scale = 0.75, skin = 0},
    [4]  = {model = "dog3/doge_player",   scale = 0.75, skin = 1},
    [5]  = {model = "dog3/doge_player",   scale = 0.75, skin = 2},
    [6]  = {model = "dog3/doge_player",   scale = 0.75, skin = 3},
    [7]  = {model = "dog4/slinky_dog",    scale = 0.6},
    [8]  = {model = "dog6/hotdog",        scale = 2},
    [9]  = {model = "dog9/odie",          scale = 0.5},
    [10] = {model = "dog5/snoopdogg",     scale = 0.75}
}
local notDogChoices = {
    [1] = {model = "dog7/jinxcat",        scale = 0.7},
    [2] = {model = "dog8/cat burger",     scale = 3},
    [3] = {model = "dog10/garfield"}
}

local function ChooseDog()
    local catChance = GetConVar("randomat_damndog_cat_chance"):GetInt()

    local choiceTable = dogChoices
    local dogOrNot = math.random(1, 100)
    local notDog = false

    if dogOrNot <= catChance then
        choiceTable = notDogChoices
        notDog = true
    end

    local choice = math.random(1, #choiceTable)
    return choiceTable[choice].model, choiceTable[choice].scale or nil, choiceTable[choice].skin or nil, notDog
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
    local ang = moveDir:Angle()
    ang.p = 0

    local dogModel, dogScale, dogSkin, notDog = ChooseDog()
    ply.notDog = notDog

    local zOffset = 0
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
    dog:SetAngles(ang)
    dog:Spawn()
    dog:Activate()

    ply:SetNWEntity("RdmtRagdollDog", dog)

    return dog -- Not that my own dog ever listens when I tell her to return. Thanks Bel.
end

local function StartIndividualTimer(ply, thisEvent)
    if not IsValid(ply) or not thisEvent.DamnDogTimers then return end
    if thisEvent.DamnDogTimers[ply] then return end

    local timerName = "RdmtDamnDog_" .. ply:SteamID64()
    thisEvent.DamnDogTimers[ply] = timerName

    timer.Create(timerName, math.random(lowerTime, upperTime), 1, function()
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
    lowerTime = GetConVar("randomat_damndog_interval_lower"):GetInt()
    upperTime = GetConVar("randomat_damndog_interval_upper"):GetInt()
    affectAll = GetConVar("randomat_damndog_affect_all"):GetBool()

    if lowerTime > upperTime then
        upperTime = lowerTime + 1
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
        timer.Create("RdmtDamnDogMain", math.random(lowerTime, upperTime), 0, function()
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

            timer.Adjust("RdmtDamnDogMain", math.random(lowerTime, upperTime))
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

------------------------------------------------------------------------------
-- Ragdoll shit
------------------------------------------------------------------------------

local function HandleWeaponPAP(weap, upgrade)
    -- If PAP is installed, this weapon was given successfully, and the old one was PAP'd, then PAP the new one too
    if not TTTPAP then return end
    if not upgrade then return end
    if not IsValid(weap) then return end

    TTTPAP:ApplyUpgrade(weap, upgrade)
end

local function PlayerNotStuck(ply)
    local pos = ply:GetPos()
    local t = {
        start = pos,
        endpos = pos,
        mask = MASK_PLAYERSOLID,
        filter = ply
    }
    return util.TraceEntity(t, ply).StartSolid == false
end

local function FindPassableSpace(ply, direction, step)
    local i = 0
    while (i < 100) do
        local origin = ply:GetPos()

        origin = origin + step * direction

        ply:SetPos(origin)
        if PlayerNotStuck(ply) then
            return true, ply:GetPos()
        end
        i = i + 1
    end
    return false, nil
end

--
--    Purpose: Unstucks player
--    Note: Very expensive to call, you have been warned!
--
local function UnstuckPlayer(ply)
    if not PlayerNotStuck(ply) then
        local oldPos = ply:GetPos()
        local angle = ply:GetAngles()
        local forward = angle:Forward()
        local right = angle:Right()
        local up = angle:Up()

        local SearchScale = 1 -- Increase and it will unstuck you from even harder places but with lost accuracy. Please, don't try higher values than 12
        -- Forward
        local success, pos = FindPassableSpace(ply, forward, SearchScale)
        if not success then success, pos = FindPassableSpace(ply, right, SearchScale) end -- Right
        if not success then success, pos = FindPassableSpace(ply, right, -SearchScale) end -- Left
        if not success then success, pos = FindPassableSpace(ply, up, SearchScale) end -- Up
        if not success then success, pos = FindPassableSpace(ply, up, -SearchScale) end -- Down
        if not success then success, pos = FindPassableSpace(ply, forward, -SearchScale) end -- Back
        if not success then
            return false
        end

        -- Not stuck?
        if oldPos == pos then
            return true
        else
            ply:SetPos(pos)
            if ply:IsValid() and ply:GetPhysicsObject():IsValid() then
                if ply:IsPlayer() then
                    ply:SetVelocity(vector_origin)
                end
                ply:GetPhysicsObject():SetVelocity(vector_origin) -- prevents bugs :s
            end

            return true
        end
    end
end

function UnRagdollPlayer(v)
    v.ragdoll:SetNWBool("RdmtDamnDogHasBubble", false)
    v.inRagdoll = false
    v:SetParent()

    local ragdoll = v.ragdoll
    v.ragdoll = nil -- Gotta do this before spawn or our hook catches it
    -- Set these so players don't get their role weapons given back if they've already used them
    v.Resurrecting = true
    v.DeathRoleWeapons = nil
    v:Spawn()

    if IsValid(ragdoll) then

        local pos = ragdoll:GetPos()
        pos.z = pos.z + 10
        v:SetPos(pos)
        v:SetVelocity(ragdoll:GetVelocity())
        local yaw = ragdoll:GetAngles().yaw
        v:SetAngles(Angle(0, yaw, 0))
        if ragdoll.DisallowDeleting then
            ragdoll:DisallowDeleting(false)
        end

        ragdoll:Remove()
    end

    for i, _ in pairs(v.spawnInfo.weps) do
        local wep = v:Give(i)
        if not IsValid(wep) then continue end

        if v.spawnInfo.weps[i].Clip then
            wep:SetClip1(v.spawnInfo.weps[i].Clip)
        end
        v:SetAmmo(v.spawnInfo.weps[i].Reserve, wep:GetPrimaryAmmoType())
        HandleWeaponPAP(wep, v.spawnInfo.weps[i].PAPUpgrade)
    end

    if v.spawnInfo.activeWeapon then
        v:SelectWeapon(v.spawnInfo.activeWeapon)
    end

    v:SetCredits(v.spawnInfo.credits)
    v:SetModel(v.spawnInfo.model)
    v:SetPlayerColor(v.spawnInfo.playerColor)
    v:DrawViewModel(true)

    -- Re-set Dead Ringer state
    v:SetNWInt("DRStatus", v.spawnInfo.deadRinger.status)
    v:SetNWInt("DRCharge", v.spawnInfo.deadRinger.charge)

    for i, j in pairs(v.spawnInfo.equipment) do
        if j then
            v:GiveEquipmentItem(i)
        end
    end

    v:SetMaxHealth(v.spawnInfo.maxhealth)
    v:SetHealth(math.max(0, v.spawnInfo.health))
    if v:Health() <= 0 then
        v:Kill()
    else
        timer.Simple(0.1, function()
            if v:IsInWorld() then
                UnstuckPlayer(v) -- Thanks to SunRed on GitHub for the unstuck script
            end
        end)
    end

    v.inRagdoll = false
end

local RagdollPartsCache = {}

local function GetRagdollParts(ply, ragdoll)
    local sid = ply:SteamID64()
    local currentModel = ply:GetModel()

    -- Return cached parts if we already have them and the player's model hasn't changed
    if RagdollPartsCache[sid] and RagdollPartsCache[sid].model == currentModel then
        return RagdollPartsCache[sid].lower, RagdollPartsCache[sid].upper
    end

    -- Get the parts of the ragdoll we want
    local foundParts = {}
    for j = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local partIndex = ragdoll:TranslatePhysBoneToBone(j)
        if partIndex and partIndex ~= -1 then
            local partName = ragdoll:GetBoneName(partIndex)
            if partName then
                foundParts[string.lower(partName)] = j
            end
        end
    end

    local function findPair(left, right)
        local l, r = nil, nil
        for name, idx in pairs(foundParts) do
            if string.find(name, left, 1, true) then l = idx end
            if string.find(name, right, 1, true) then r = idx end
        end
        if l or r then
            local pairIdxs = {}
            if l then table.insert(pairIdxs, l) end
            if r then table.insert(pairIdxs, r) end
            return pairIdxs
        end
        return nil
    end

    local function findSingle(target)
        for name, idx in pairs(foundParts) do
            if string.find(name, target, 1, true) then return {idx} end
        end
        return nil
    end

    -- Pick by priority for 'lower'
    local lower = findPair("l_foot", "r_foot")
        or findPair("l_toe0", "r_toe0")
        or findPair("l_calf", "r_calf")
        or {}

    -- Pick by priority for 'upper'
    local upper = findSingle("head1")
        or findSingle("neck1")
        or findSingle("spine4")
        or findSingle("spine2")
        or {}

    -- Save to cache rather than do the above bits every time a player ragdolls
    RagdollPartsCache[sid] = {
        model = currentModel,
        lower = lower,
        upper = upper
    }

    return lower, upper
end

function Joel4848:RagdollPlayer(v)
    -- Remove individual timer if it exists when they ragdoll
    local timerName = "RdmtDamnDog_" .. v:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
    v.PendingDogSpawn = false -- Cancel any pending spawns so they don't trigger mid-ragdoll

    v.onGround = v:OnGround()
    v.inRagdoll = true
    v.lastRagdoll = CurTime()

    v.inRagdoll = true
    v.lastRagdoll = CurTime()
    v.spawnInfo = {}

    local weps = {}
    for _, j in ipairs(v:GetWeapons()) do
        weps[j.ClassName] = {}
        weps[j.ClassName].Clip = j:Clip1()
        weps[j.ClassName].Reserve = v:GetAmmoCount(j:GetPrimaryAmmoType())
        weps[j.ClassName].PAPUpgrade = j.PAPUpgrade
    end

    local equipment = {}
    -- Keep track of what equipment the player had
    local i = 1
    while i <= EQUIP_MAX do
        equipment[i] = v:HasEquipmentItem(i)
        if CR_VERSION then
            i = i + 1
        -- Double the index since this is a bit-mask
        else
            i = i * 2
        end
    end

    local info = {
        weps = weps,
        activeWeapon = WEPS.GetClass(v:GetActiveWeapon()),
        health = v:Health(),
        maxhealth = v:GetMaxHealth(),
        model = v:GetModel(),
        credits = v:GetCredits(),
        equipment = equipment,
        playerColor = v:GetPlayerColor(),
        -- Save Dead Ringer state
        deadRinger = {
            status = v:GetNWInt("DRStatus", 0),
            charge = v:GetNWInt("DRCharge", 8)
        }
    }
    v.spawnInfo = info

    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll.ragdolledPly = v
    ragdoll:SetNWBool("RdmtRagdollRagdoll", true)
    local velocity = v:GetVelocity()
    ragdoll:SetPos(v:GetPos())
    ragdoll:SetModel(info.model)
    ragdoll:SetSkin(v:GetSkin())
    for _, value in pairs(v:GetBodyGroups()) do
        ragdoll:SetBodygroup(value.id, v:GetBodygroup(value.id))
    end
    ragdoll:SetAngles(v:GetAngles())
    ragdoll:SetColor(v:GetColor())
    CORPSE.SetPlayerNick(ragdoll, v)
    ragdoll:Spawn()
    ragdoll:Activate()

    v:SetParent(ragdoll)

    if v.notDog then
        ragdoll:SetNWBool("RdmtDamnDogHasBubble", true)

        local textOptions = {
            "&#@%!*% cat!",
            -- "That's a weird &#@%!*% dog",
            "Does Joel not know what a &#@%!*% dog is?!"
        }
        table.Shuffle(textOptions)
        local bubbleText = textOptions[math.random(1, #textOptions)]

        ragdoll:SetNWString("RdmtDamnDogBubbleText", bubbleText)
    end

    local velocityMultiplier = GetConVar("randomat_damndog_trip_power_multiplier"):GetFloat()
    local forwardDir = velocity:GetNormalized()
    local baseVel = velocity * velocityMultiplier

    -- Get the parts to apply velocity to
    local lowerParts, upperParts = GetRagdollParts(v, ragdoll)

    local isLower = {}
    for _, idx in ipairs(lowerParts) do isLower[idx] = true end

    local isUpper = {}
    for _, idx in ipairs(upperParts) do isUpper[idx] = true end

    for k = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys_obj = ragdoll:GetPhysicsObjectNum(k)
        if IsValid(phys_obj) and v.onGround then
            local targetVel = Vector(baseVel.x, baseVel.y, baseVel.z)

            if isLower[k] then
                -- Lower parts - try and kick them backwards and up a bit
                targetVel.z = targetVel.z + 400
                targetVel = -targetVel + (forwardDir * 150)
            elseif isUpper[k] then
                -- Upper parts - try and kick them forwards and down a bit
                targetVel.z = -targetVel.z
                targetVel = targetVel + (forwardDir * 100)
            else
                -- Other parts - give them a bit of an upwards boots so the ragdoll goes an appreciable distance
                targetVel.z = targetVel.z + 500
            end

            phys_obj:SetVelocity(targetVel)
        end
    end

    v:Spectate(OBS_MODE_CHASE)
    v:SpectateEntity(ragdoll)
    v:StripWeapons()

    if ragdoll.DisallowDeleting then
        ragdoll:DisallowDeleting(true, function(old, new)
            if IsValid(v) then v.ragdoll = new end
        end)
    end

    v:SetNWEntity("RdmtRagdollDog", dog)
    v:SetNWBool("RdmtIsRagdolledByDog", true)

    v.ragdoll = ragdoll
    local ragdolltime = 5

    hook.Add("Think", v:SteamID64() .. "UnragdollTimer", function()
        if not IsValid(v) then return end

        v:DrawViewModel(false)

        if not IsValid(ragdoll) then return end

        local physObj = ragdoll:GetPhysicsObjectNum(1)
        if not IsValid(physObj) then return end

        -- Unragdoll player when they're stationary and some time has passed
        if physObj:GetVelocity():Length() <= 10 and (CurTime() - v.lastRagdoll) > ragdolltime then
            hook.Remove("Think", v:SteamID64() .. "UnragdollTimer")

            v:SetNWBool("RdmtIsRagdolledByDog", false)
            v:SetNWEntity("RdmtRagdollDog", nil)

            UnRagdollPlayer(v)

            if IsValid(v.ragdollDog) then
                v.ragdollDog:Remove()
            end
        end
    end)
end

function EVENT:End()
    timer.Remove("RdmtDamnDogMain")

    for _, ply in player.Iterator() do
        timer.Remove("RdmtDamnDog_" .. ply:SteamID64())
        ply.PendingDogSpawn = nil
        if IsValid(ply.LastSpawnedDog) then ply.LastSpawnedDog:Remove() end

        hook.Remove("Think", ply:SteamID64() .. "UnragdollTimer")

        if ply.inRagdoll then UnRagdollPlayer(ply) end
    end
end

function EVENT:GetConVars()
    local sliders = {}

    for _, v in ipairs({"trip_power_multiplier"}) do
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

    for _, v in ipairs({"interval_lower", "interval_upper", "spawn_distance", "cat_chance"}) do
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
    for _, v in ipairs({"affect_all"}) do
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