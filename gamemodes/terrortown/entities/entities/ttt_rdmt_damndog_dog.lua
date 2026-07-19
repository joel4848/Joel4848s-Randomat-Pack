AddCSLuaFile()
ENT.Type = "anim"

local dogEntity = dogEntity or nil

function ENT:Initialize()
    self:SetModel("models/damndog/dog1/npc_dog.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetHealth(1)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmgInfo)
    self:Remove()
    return true
end

function ENT:Think()
end

function ENT:Break()
end

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

local function UnRagdollPlayer(v)
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

local RagdollBoneCache = {}

local function GetRagdollCartwheelBones(ply, ragdoll)
    local sid = ply:SteamID64()
    local currentModel = ply:GetModel()

    -- Return cached parts if we already have them and the player's model hasn't changed
    if RagdollBoneCache[sid] and RagdollBoneCache[sid].model == currentModel then
        return RagdollBoneCache[sid].lower, RagdollBoneCache[sid].upper
    end

    -- Get the parts of the ragdoll we want
    local foundBones = {}
    for j = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local boneIndex = ragdoll:TranslatePhysBoneToBone(j)
        if boneIndex and boneIndex ~= -1 then
            local boneName = ragdoll:GetBoneName(boneIndex)
            if boneName then
                foundBones[string.lower(boneName)] = j
            end
        end
    end

    local function findPair(left, right)
        local l, r = nil, nil
        for name, idx in pairs(foundBones) do
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
        for name, idx in pairs(foundBones) do
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
    RagdollBoneCache[sid] = {
        model = currentModel,
        lower = lower,
        upper = upper
    }

    return lower, upper
end

local function RagdollPlayer(v)
    -- Remove individual timer if it exists when they ragdoll
    local timerName = "RdmtDamnDog_" .. v:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
    v.PendingDogSpawn = false -- Cancel any pending spawns so they don't trigger mid-ragdoll

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

    local velocityMultiplier = GetConVar("randomat_damndog_trip_power_multiplier"):GetFloat()
    local forwardDir = velocity:GetNormalized()
    local baseVel = velocity * velocityMultiplier

    -- Get the bones to apply velocity to
    local lowerBones, upperBones = GetRagdollCartwheelBones(v, ragdoll)

    local isLower = {}
    for _, idx in ipairs(lowerBones) do isLower[idx] = true end

    local isUpper = {}
    for _, idx in ipairs(upperBones) do isUpper[idx] = true end

    for k = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys_obj = ragdoll:GetPhysicsObjectNum(k)
        if IsValid(phys_obj) then
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

    v.ragdoll = ragdoll
    local ragdolltime = 5
    local eyesSet = 120

    hook.Add("Think", v:Nick() .. "UnragdollTimer", function()
        if not IsValid(v) then return end

        v:DrawViewModel(false)

        if not IsValid(ragdoll) then return end

        local dog = v.ragdollDog
        if IsValid(dog) and eyesSet < 120 then
            local targetDir = dog:GetPos() - ragdoll:GetPos()

            local targetAng = targetDir:Angle()
            targetAng.x = targetAng.x + 30

            v:SetEyeAngles(targetAng)

            eyesSet = eyesSet + 1
        end

        local physObj = ragdoll:GetPhysicsObjectNum(1)
        if not IsValid(physObj) then return end

        -- Unragdoll player when they're stationary and some time has passed
        if physObj:GetVelocity():Length() <= 10 and (CurTime() - v.lastRagdoll) > ragdolltime then
            hook.Remove("Think", v:Nick() .. "UnragdollTimer")
            UnRagdollPlayer(v)
            if IsValid(v.ragdollDog) then
                v.ragdollDog:Remove()
            end
        end
    end)
end

function ENT:Touch(ply)
    if IsValid(ply) and ply:IsPlayer() and ply:Alive() and not ply.inRagdoll then
        ply.ragdollDog = self
        RagdollPlayer(ply)
    end
end