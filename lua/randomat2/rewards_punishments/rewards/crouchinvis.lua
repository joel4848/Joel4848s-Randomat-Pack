local REWARD = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_CrouchInvisBegin")
util.AddNetworkString("Rdmt_Joel4848_RewardPunish_CrouchInvisEnd")

REWARD.Name = "Invisible Crouching"
REWARD.Id = "crouchinvis"

local crouchinvis_reveal_timer = CreateConVar("rdmt_joel4848_rewardpunish_crouchinvis_reveal_timer", "3", FCVAR_NONE, "How long to reveal after shooting.", 0, 30)

local hookIds = {}

local function SetPlayerVisibility(ply, visible)
    if visible then
        Randomat:SetPlayerVisible(ply)
    else
        Randomat:SetPlayerInvisible(ply)
    end
    ply:DrawWorldModel(visible)
end

function REWARD:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_CrouchInvis_" .. target:SteamID64()
    table.insert(hookIds, hookId)

    hook.Add("FinishMove", hookId .. "_FinishMove", function(ply, mv)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() or target ~= ply then return end
        SetPlayerVisibility(ply, not ply:Crouching() or ply:GetNWBool("Rdmt_Joel4848_RewardPunish_CrouchInvisRevealed", false))
    end)

    hook.Add("PlayerDeath", hookId .. "_PlayerDeath", function(victim, entity, killer)
        if not IsValid(victim) or target ~= victim then return end
        SetPlayerVisibility(victim, true)
    end)

    hook.Add("EntityFireBullets", hookId .. "_EntityFireBullets", function(entity, data)
        if not IsPlayer(entity) or target ~= entity then return end
        local reveal_time = crouchinvis_reveal_timer:GetInt()
        if reveal_time > 0 then
            entity:SetNWBool("Rdmt_Joel4848_RewardPunish_CrouchInvisRevealed", true)
            timer.Create("Rdmt_Joel4848_RewardPunish_CrouchInvisRevealTimer_" .. entity:SteamID64(), reveal_time, 1, function()
                entity:SetNWBool("Rdmt_Joel4848_RewardPunish_CrouchInvisRevealed", false)
            end)
        end
    end)

    net.Start("Rdmt_Joel4848_RewardPunish_CrouchInvisBegin")
    net.WriteString(target:SteamID64())
    net.Broadcast()
end

function REWARD:CleanUp()
    for _, hookId in ipairs(hookIds) do
        hook.Remove("FinishMove", hookId .. "_FinishMove")
        hook.Remove("PlayerDeath", hookId .. "_PlayerDeath")
        hook.Remove("EntityFireBullets", hookId .. "_EntityFireBullets")
    end
    table.Empty(hookIds)

    for _, p in player.Iterator() do
        SetPlayerVisibility(p, true)
        timer.Remove("Rdmt_Joel4848_RewardPunish_CrouchInvisRevealTimer_" .. p:SteamID64())
    end

    net.Start("Rdmt_Joel4848_RewardPunish_CrouchInvisEnd")
    net.Broadcast()
end

function REWARD:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"reveal_timer"}) do
        local name = "randomat_joel4848_rewardpunish_" .. self.Id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = self.Id .. "_" .. v,
                dsc = self.Name .. " - " .. convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end
end

function REWARD:Condition()
    return not Randomat:IsEventActive("trexvision") and not Randomat:IsEventActive("gaseous")
end

Joel4848:RegisterReward(REWARD)