local function IsTargetHighlighted(ply, target)
    return ply.IsTargetHighlighted and ply:IsTargetHighlighted(target)
end

net.Receive("Rdmt_Joel4848_RewardPunish_BlindishBegin", function()
    hook.Add("PreDrawHalos", "Rdmt_Joel4848_RewardPunish_Blindish_PreDrawHalos", function()
        local alivePlys = {}
        for _, v in player.Iterator() do
            if v ~= Randomat.Client and v:Alive() and not v:IsSpec() and not IsTargetHighlighted(Randomat.Client, v) then
                table.insert(alivePlys, v)
            end
        end

        halo.Add(alivePlys, COLOR_RED, 0, 0, 1, true, true)
    end)
end)

net.Receive("Rdmt_Joel4848_RewardPunish_BlindishEnd", function()
    hook.Remove("PreDrawHalos", "Rdmt_Joel4848_RewardPunish_Blindish_PreDrawHalos")
end)