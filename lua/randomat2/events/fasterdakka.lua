local EVENT = {}

EVENT.Title = "Faster Dakka!"
EVENT.Description = "Less bullets means more faster shootin'!"
EVENT.id = "fasterdakka"
EVENT.Categories = {"moderateimpact"}

CreateConVar("randomat_fasterdakka_max_rate_multiplier", 10, FCVAR_NONE, "The highest the firing rate multiplier will get", 1, 100)
CreateConVar("randomat_fasterdakka_max_rate_percentage", 30, FCVAR_NONE, "The clip percentage at which max rate will be reached", 1, 100)

function EVENT:Begin()
    self:AddHook("EntityFireBullets", function(ent, data)
        if not IsValid(ent) or not ent:IsPlayer() then return end

        local wep = ent:GetActiveWeapon()
        if not IsValid(wep) then return end

        local clipCapacity = wep:GetMaxClip1()
        if clipCapacity <= 0 then return end

        local currentBullets = wep:Clip1()

        timer.Simple(0, function()
            if not IsValid(wep) then return end

            local maximumMultiplier = GetConVar("randomat_fasterdakka_max_rate_multiplier"):GetFloat()
            local fastestClipPercentage = GetConVar("randomat_fasterdakka_max_rate_percentage"):GetFloat() / 100

            local clipPercentage = currentBullets / clipCapacity
            local fireRateMultiplier = 1

            if clipPercentage <= fastestClipPercentage then
                fireRateMultiplier = maximumMultiplier
            elseif fastestClipPercentage < 1 then
                local fraction = (1.0 - clipPercentage) / (1.0 - fastestClipPercentage)
                fireRateMultiplier = 1.0 + fraction * (maximumMultiplier - 1.0)
            end

            if fireRateMultiplier > 1 then
                local nextShot = wep:GetNextPrimaryFire()
                local delay = nextShot - CurTime()

                if delay > 0 then
                    -- Shorten the delay and overwrite the NextPrimaryFire
                    wep:SetNextPrimaryFire(CurTime() + (delay / fireRateMultiplier))
                end
            end
        end)
    end)
end

function EVENT:End()

end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"max_rate_multiplier", "max_rate_percentage"}) do
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