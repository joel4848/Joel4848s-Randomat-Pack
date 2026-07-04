local EVENT = {}

-- Create the ConVars (Customizable settings)
CreateConVar("randomat_realisticimpacts_max", 1500, FCVAR_NONE, "Maximum magnitude by which a gun can change someone's velocity by")
CreateConVar("randomat_realisticimpacts_min", 200, FCVAR_NONE, "Minimum magnitude by which a gun can change someone's velocity by")
CreateConVar("randomat_realisticimpacts_mul", 10, FCVAR_NONE, "Push multiplier", 1, 100)

EVENT.Title = {
    {text = "Realistic "},
    {text = "Recoil", strikethrough = true},
    {text = " Impacts"},
}

EVENT.Description = "Getting shot pushes you away"
EVENT.id = "realisticimpacts"
EVENT.Categories = {"smallimpact"}

function EVENT:Begin()
    self:AddHook("EntityTakeDamage", function(ply, dmginfo)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local damage = dmginfo:GetDamage()
        local attacker = dmginfo:GetAttacker()
        if not IsValid(attacker) then return end

        if not dmginfo:IsBulletDamage() then return end

        -- If CR4TTT present, check whether headshots have been disabled
        local headshotsEnabled = true
        if cvars.Number("ttt_disable_headshots", -1) ~= -1 and GetConVar("ttt_disable_headshots"):GetBool() then
            headshotsEnabled = false
        end

        -- Calculate velocity based on pre-headshot-multiplier damage
        if headshotsEnabled and ply:LastHitGroup() == 1 then
            local wep = dmginfo:GetWeapon()
            if not IsValid(wep) then return end
            local damageMulti = wep:GetHeadshotMultiplier(ply, dmginfo) or 2
            damage = damage / damageMulti
        end

        -- Push away in the direction the attacker is shooting
        local vec = Vector(attacker:EyePos().x - attacker:GetEyeTrace().HitPos.x, attacker:EyePos().y - attacker:GetEyeTrace().HitPos.y, attacker:EyePos().z - attacker:GetEyeTrace().HitPos.z)
        vec:Normalize()

        -- Change downwardness of downward shots so that (a) they actually do something, and
        -- (b) the something they do isn't killing the player by crushing them into the ground lol
        if vec.z >= -0.15 then
            vec.z = -0.15
            vec:Normalize()
        end

        -- Borrowing and amending The Stig's "weird maths"
        local newVelocity = vec * math.exp(tonumber(math.pow(damage / 3, 1 / 2.5))) * GetConVar("randomat_realisticimpacts_mul"):GetFloat() * 6

        -- If the force is outside the min or max, make it not be outside the min or max
        local maxForce = GetConVar("randomat_realisticimpacts_max"):GetInt()
        local minForce = GetConVar("randomat_realisticimpacts_min"):GetInt()

        if newVelocity:LengthSqr() > (maxForce * maxForce) then
            newVelocity = newVelocity:GetNormalized() * maxForce
        elseif newVelocity:LengthSqr() < (minForce * minForce) then
            newVelocity = newVelocity:GetNormalized() * minForce
        end

        -- Delay one frame to allow body to spawn if player is now dead
        timer.Simple(0, function()
            -- Lift the target off the ground a bit before applying force so gmod friction doesn't cuck us
            -- (Same as how a discombob does it)
            if ply:IsOnGround() then
                ply:SetPos(ply:GetPos() + Vector(0, 0, 10))
            end

            local body = ply.server_ragdoll or ply:GetRagdollEntity()

            if IsValid(body) then
                -- timer.Simple(0, function()
                    body:SetPos(body:GetPos() + Vector(0, 0, 100))

                    -- timer.Simple(0, function()
                        for i=0, body:GetPhysicsObjectCount() - 1 do
                            local phys = body:GetPhysicsObjectNum(i)
                            phys:SetPos(phys:GetPos() + Vector(0, 0, 10))

                            -- timer.Simple(0, function()
                                body:SetGroundEntity(NULL)
                                phys:SetMass(0)
                                phys:SetDragCoefficient(0)
                                phys:ApplyForceCenter(-newVelocity * 2)
                            -- end)
                        end
                    -- end)
                -- end)
            else
                ply:SetGroundEntity(NULL)
                ply:SetVelocity(-newVelocity)
            end
        end)
    end)
end

function EVENT:GetConVars()
    local sliders = {}

    for _, v in pairs({"max", "mul"}) do
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
    local textboxes = {}

    return sliders, checks, textboxes
end

Randomat:register(EVENT)