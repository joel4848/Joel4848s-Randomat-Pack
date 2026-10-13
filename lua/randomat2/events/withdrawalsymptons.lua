local EVENT = {}

EVENT.Title       = "Withdrawal Symptoms"
EVENT.Description = "All healing is temporary"
EVENT.id          = "withdrawalsymptoms"
EVENT.Categories  = {"moderateimpact"}

CreateConVar("randomat_withdrawalsymptoms_health_amount", 1, FCVAR_NONE, "How much temporary health is lost per 'tick'", 1, 100)
CreateConVar("randomat_withdrawalsymptoms_health_time", 1, FCVAR_NONE, "The 'tick' length (s) that temporary health is lost over", 0.1, 60)

local playerHealth = {}

function EVENT:Begin()
    local healthAmount = GetConVar("randomat_withdrawalsymptoms_health_amount"):GetInt()
    local healthTime   = GetConVar("randomat_withdrawalsymptoms_health_time"):GetFloat()

    for _, v in ipairs(self:GetAlivePlayers()) do
        local sid64 = v:SteamID64()
        playerHealth[sid64] = v:Health()
    end

    self:AddHook("PlayerSpawn", function(ply)
        -- "PlayerSpawn" also gets called when a player is moved to AFK
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end
        -- Save the player's initial health on spawn so if they get ressed, it resets to full
        playerHealth[ply:SteamID64()] = ply:Health()
    end)

    self:AddHook("Think", function()
        for _, v in ipairs(self:GetAlivePlayers()) do
            local sid64 = v:SteamID64()
            local hp = v:Health()

            if hp < playerHealth[sid64] then
                playerHealth[sid64] = hp
            end

            v:SetNWInt("Randomat_WithdrawalSymptoms_Health", playerHealth[sid64])
        end
    end)

    timer.Create("Randomat_WithdrawalSymptoms_HealthDrain", healthTime, 0, function()
        for _, v in ipairs(self:GetAlivePlayers()) do
            local sid64 = v:SteamID64()
            local hp = v:Health()

            if hp > playerHealth[sid64] then
                newHealth = math.max(hp - healthAmount, playerHealth[sid64])
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
    timer.Remove("Randomat_WithdrawalSymptoms_HealthDrain")

    for _, v in ipairs(self:GetAlivePlayers()) do
        v:SetNWInt("Randomat_WithdrawalSymptoms_Health", nil)
    end
end

Randomat:register(EVENT)