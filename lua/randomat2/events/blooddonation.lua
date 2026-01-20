local EVENT = {}

EVENT.Title = "Compulsory Blood Donation"
EVENT.Description = "Gain temporary health equal to the damage you deal"
EVENT.id = "blooddonation"
EVENT.Categories = {"moderateimpact"}

CreateConVar("randomat_blooddonation_maxattackerhealth", 0, FCVAR_NONE, "The max health a player can reach (0 to disable)", 0, 1000)

function EVENT:Begin()

    local maxattackerhealth = GetConVar("randomat_blooddonation_maxattackerhealth"):GetInt()

    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        if not IsPlayer(target) then return end

        local attacker = dmginfo:GetAttacker()
        if not IsPlayer(attacker) then return end
        if attacker == target then return end

        local damage = dmginfo:GetDamage()
        if damage <= 0 then return end

        local targethealth = target:Health()
        local healamount = math.min(damage, targethealth)
        local newattackerhealth = attacker:Health() + healamount
        if maxattackerhealth > 0 and newattackerhealth > maxattackerhealth then
            newattackerhealth = maxattackerhealth
        end

        attacker:SetHealth(newattackerhealth)
    end)
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"maxattackerhealth"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax()
            })
        end
    end
    return sliders
end

Randomat:register(EVENT)