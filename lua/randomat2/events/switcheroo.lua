local EVENT = {}

EVENT.Title       = "The Ol' Switcheroo"
EVENT.Description = "Every weapon is a player swap gun!"
EVENT.id          = "switcheroo"
EVENT.Categories  = {"biased_innocent", "largeimpact"}

function EVENT:Begin()
    local function MoveRagdoll(ragdoll, destination)
        local count = ragdoll:GetPhysicsObjectCount()
        if count == 0 then return end

        local lowestZPos      = math.huge
        local lowestBone      = nil
        local lowestBoneIndex = -1

        -- Find the lowest bone
        -- Of COURSE it needs to be count - 1, oops
        for i = 0, count - 1 do
            local phys = ragdoll:GetPhysicsObjectNum(i)

            if IsValid(phys) then
                local bonePos = phys:GetPos()

                if bonePos.z < lowestZPos then
                    lowestZPos      = bonePos.z
                    lowestBone      = phys
                    lowestBoneIndex = i
                end
            end
        end

        local boneOffsets   = {}
        local lowestBonePos = lowestBone:GetPos()

        -- Get all bones' positions relative to the lowest bone
        for i = 0, count - 1 do
            if i == lowestBoneIndex then continue end
            local phys = ragdoll:GetPhysicsObjectNum(i)

            if IsValid(phys) then
                local bonePos = phys:GetPos()

                boneOffsets[i] = bonePos - lowestBonePos
            end
        end

        local lowestBoneVelocity        = lowestBone:GetVelocity()
        local lowestBoneAngularVelocity = lowestBone:GetAngleVelocity()

        lowestBone:SetPos(Vector(destination.x, destination.y, destination.z + 5), true)
        lowestBone:SetVelocity(lowestBoneVelocity)
        lowestBone:SetAngleVelocity(lowestBoneAngularVelocity)

        -- Set all bones' positions relative to the lowest bone's new position
        for i = 0, count - 1 do
            if i == lowestBoneIndex then continue end
            local phys = ragdoll:GetPhysicsObjectNum(i)

            if IsValid(phys) then
                local velocity        = phys:GetVelocity()
                local angularVelocity = phys:GetAngleVelocity()

                phys:SetPos(lowestBone:GetPos() + boneOffsets[i])

                phys:SetVelocity(velocity)
                phys:SetAngleVelocity(angularVelocity)
            end
        end
    end

    local swapOrigins = {}

    -- Record/check original positions with their times for if a single attack damages multiple players
    local function GetSwapOrigin(attacker)
        local now    = CurTime()
        local origin = swapOrigins[attacker]

        if not origin or origin.time ~= now then
            origin = {pos = attacker:GetPos(), time = now}
            swapOrigins[attacker] = origin
        end

        return origin.pos
    end

    local function DoSwap(attacker, target, isFatal)
        if not (IsValid(attacker) and attacker:IsPlayer() and IsValid(target) and target:IsPlayer()) then return end

        -- Get the attack position
        local originPos = GetSwapOrigin(attacker)

        local attackerPos    = attacker:GetPos()
        local attackerAngles = attacker:EyeAngles()
        local targetPos      = target:GetPos()
        local targetAngles   = target:EyeAngles()

        if isFatal then
            attacker:SetPos(targetPos)
            attacker:SetEyeAngles(targetAngles)

            local ragdoll = target.server_ragdoll

            if IsValid(ragdoll) then
                MoveRagdoll(ragdoll, originPos)
            else
                timer.Simple(0, function()
                    if IsValid(target) and IsValid(target.server_ragdoll) then
                        MoveRagdoll(target.server_ragdoll, originPos)
                    end
                end)
            end
        else
            local targetVelocity = target:GetVelocity()

            attacker:SetPos(targetPos)
            attacker:SetEyeAngles(targetAngles)
            target:SetPos(attackerPos)
            target:SetEyeAngles(attackerAngles)

            target:SetVelocity(targetVelocity)

            if targetVelocity.z > 0 then target:SetGroundEntity(NULL) end
        end
    end

    -- Do swaps for any damage
    self:AddHook("PostEntityTakeDamage", function(ent, dmg)
        local attacker = dmg:GetAttacker()
        local target   = ent

        if not (IsValid(attacker) and attacker:IsPlayer() and IsValid(target) and target:IsPlayer()) then return end

        local isFatal = (target:Health() <= 0)

        DoSwap(attacker, target, isFatal)
    end)

    -- Do swaps for non-damaging bullets
    self:AddHook("PostEntityFireBullets", function(ply, data)
        local attacker = ply
        local target   = data.Trace.Entity

        if not (IsValid(attacker) and attacker:IsPlayer() and IsValid(target) and target:IsPlayer()) then return end

        -- If damage isn't 0 then don't do anything, because the "PostEntityTakeDamage" hook will do it instead
        if data.Damage ~= 0 then return end

        DoSwap(attacker, target, false)
    end)
end

Randomat:register(EVENT)