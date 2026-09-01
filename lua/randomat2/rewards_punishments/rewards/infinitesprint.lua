local REWARD = {}

REWARD.Name = "Infinite Sprint"
REWARD.Id = "infinitesprint"

local hookIds = {}

function REWARD:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_InfiniteSprint_" .. target:SteamID64()
    table.insert(hookIds, hookId)

    hook.Add("TTTSprintStaminaPost", hookId, function(ply)
        if not IsPlayer(target) then return end

        if ply == target then
            return 100
        end
    end)
end

function REWARD:CleanUp()
    for _, hookId in ipairs(hookIds) do
        hook.Remove("TTTSprintStaminaPost", hookId)
    end
    table.Empty(hookIds)
end

function REWARD:Condition()
    -- Check that this variable exists by double negating
    -- We can't just return the variable directly because it's not a boolean
    -- The "TTTSprintStaminaPost" hook is only available in the new CR
    local is_new_cr = not not CR_VERSION
    -- If the enabled convar doesn't exist we assume sprint exists
    local has_sprint = not ConVarExists("ttt_sprint_enabled") or GetConVar("ttt_sprint_enabled"):GetBool()

    -- Don't run this while Run For Your Life is running because then we can't actually track if someone is sprinting...
    return is_new_cr and has_sprint and not Randomat:IsEventActive("runforyourlife")
end

Joel4848:RegisterReward(REWARD)