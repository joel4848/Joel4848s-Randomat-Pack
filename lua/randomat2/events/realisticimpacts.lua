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
        if ply.ignoreDamageTest then return end

        local dmgType = dmginfo:GetDamageType()
        local damage = dmginfo:GetDamage()
        local inflictor = dmginfo:GetInflictor()
        local attacker = dmginfo:GetAttacker()
        if not IsValid(attacker) then return end

        if not dmginfo:IsBulletDamage() then return end

        -- Push away in the direction the attacker is shooting
        local vec = Vector(attacker:EyePos().x - attacker:GetEyeTrace().HitPos.x, attacker:EyePos().y - attacker:GetEyeTrace().HitPos.y, attacker:EyePos().z - attacker:GetEyeTrace().HitPos.z)
        vec:Normalize()

        -- Borrowing The Stig's "weird maths"
        local newVelocity = vec * math.exp(tonumber(math.pow(damage / 2, 1 / 2))) * GetConVar("randomat_realisticimpacts_mul"):GetFloat()

        -- IF the force is greater than the convar allows, cap it
        local maxForce = GetConVar("randomat_realisticimpacts_max"):GetInt() * 10000
        if newVelocity:Length() > maxForce then
            newVelocity = (newVelocity / newVelocity:Length()) * maxForce
        end

        -- Lift the target off the ground a bit before applying force so gmod friction doesn't cuck us
        -- (Same as how a discombob does it)
        if ply:IsOnGround() then
            ply:SetPos(ply:GetPos() + Vector(0, 0, 10))
        end

        -- Send 'em
        ply:SetGroundEntity(NULL)
        ply:SetVelocity(-newVelocity)

        timer.Simple(0.1, function()
            local newDmg = DamageInfo()
            newDmg:SetDamageType(dmgType)
            newDmg:SetDamage(damage)
            newDmg:SetInflictor(inflictor)
            newDmg:SetAttacker(attacker)
            ply.ignoreDamageTest = true
            ply:TakeDamageInfo(newDmg)
            ply.ignoreDamageTest = false
        end)

        return true
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