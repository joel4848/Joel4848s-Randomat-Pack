local function IsPlayerValid(p)
    return IsPlayer(p) and p:Alive() and not p:IsSpec()
end

local hookIds = {}

net.Receive("Rdmt_Joel4848_RewardPunish_CrouchInvisBegin", function()
    local target = net.ReadString()

    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_CrouchInvis_" .. target
    table.insert(hookIds, hookId)

    hook.Add("TTTTargetIDPlayerBlockIcon", hookId .. "_TTTTargetIDPlayerBlockIcon", function(ply, cli)
        if not IsPlayerValid(cli) or not IsPlayerValid(ply) then return end

        if ply:GetNWBool("RdmtInvisible") then
            return true
        end
    end)

    hook.Add("TTTTargetIDPlayerBlockInfo", hookId .. "_TTTTargetIDPlayerBlockInfo", function(ply, cli)
        if not IsPlayerValid(cli) or not IsPlayerValid(ply) then return end

        if ply:GetNWBool("RdmtInvisible") then
            return true
        end
    end)
end)

net.Receive("Rdmt_Joel4848_RewardPunish_CrouchInvisEnd", function()
    for _, hookId in ipairs(hookIds) do
        hook.Remove("TTTTargetIDPlayerBlockIcon", hookId .. "_TTTTargetIDPlayerBlockIcon")
        hook.Remove("TTTTargetIDPlayerBlockInfo", hookId .. "_TTTTargetIDPlayerBlockInfo")
    end
    table.Empty(hookIds)
end)