local EVENT = {}

-- Create the ConVars (Customizable settings)
CreateConVar("randomat_realisticimpacts_max", 15, FCVAR_NONE, "Maximum magnitude a gun can change someone's velocity by", 1, 100)
CreateConVar("randomat_realisticimpacts_mul", 6, FCVAR_NONE, "Push multiplier", 1, 100)

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

        -- Push away in the direction the attacker is shooting
        local vec = Vector(attacker:EyePos().x - attacker:GetEyeTrace().HitPos.x, attacker:EyePos().y - attacker:GetEyeTrace().HitPos.y, attacker:EyePos().z - attacker:GetEyeTrace().HitPos.z)
        vec:Normalize()

        -- Borrowing The Stig's "weird maths"
        -- local newVelocity = vec * math.exp(tonumber(math.pow(damage / 2, 1 / 2))) * GetConVar("randomat_realisticimpacts_mul"):GetFloat()

        local baseForce = math.sqrt(damage) * 30
        local forceMultiplier = GetConVar("randomat_realisticimpacts_mul"):GetFloat()
        local forceMagnitude = baseForce * forceMultiplier
        local newVelocity = vec * forceMagnitude

        -- If the force is greater than the convar allows, cap it
        local maxForce = GetConVar("randomat_realisticimpacts_max"):GetInt() * 100
        if newVelocity:Length() > maxForce then
            newVelocity = newVelocity:GetNormalized() * maxForce
        end

        timer.Simple(0, function()
            -- Lift the target off the ground a bit before applying force so gmod friction doesn't cuck us
            -- (Same as how a discombob does it)
            if ply:IsOnGround() then
                ply:SetPos(ply:GetPos() + Vector(0, 0, 10))
            end

            local body = ply.server_ragdoll or ply:GetRagdollEntity()

            if IsValid(body) then
                timer.Simple(0, function()
                    body:SetPos(body:GetPos() + Vector(0, 0, 100))

                    timer.Simple(0, function()
                        for i=0, body:GetPhysicsObjectCount() - 1 do
                            local phys = body:GetPhysicsObjectNum(i)
                            phys:SetPos(phys:GetPos() + Vector(0, 0, 10))

                            timer.Simple(0, function()
                                body:SetGroundEntity(NULL)
                                phys:SetMass(0)
                                phys:SetDragCoefficient(0)
                                phys:ApplyForceCenter(-newVelocity * 2)
                            end)
                        end
                    end)
                end)
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