local EVENT = {}

EVENT.Title       = "Averaging Out"
EVENT.Description = "Health ticks up or down to half"
EVENT.id          = "averagingout"
EVENT.Categories  = {"largeimpact"}

CreateConVar("randomat_averagingout_health_amount", 1, FCVAR_NONE, "How much health changes per 'tick'", 1, 100)
CreateConVar("randomat_averagingout_health_time", 1, FCVAR_NONE, "The 'tick' length (s) that health changes over", 0.1, 60)

function EVENT:Begin()
    local healthAmount = GetConVar("randomat_averagingout_health_amount"):GetInt()
    local healthTime   = GetConVar("randomat_averagingout_health_time"):GetFloat()

    timer.Create("Randomat_AveragingOut_HealthChange", healthTime, 0, function()
        for _, v in ipairs(self:GetAlivePlayers()) do
            local halfMax = math.ceil(v:GetMaxHealth() / 2)
            local health = v:Health()

            if health > halfMax then
                newHealth = math.max(health - healthAmount, halfMax)
                v:SetHealth(newHealth)
            elseif health < halfMax then
                newHealth = math.min(health + healthAmount, halfMax)
                v:SetHealth(newHealth)
            end
        end
    end)
end

function EVENT:GetConVars()
    local sliders = {}

    for _, v in ipairs({"health_amount"}) do
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

    for _, v in ipairs({"health_time"}) do
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

    return sliders
end

function EVENT:End()
    timer.Remove("Randomat_AveragingOut_HealthChange")
end

Randomat:register(EVENT)