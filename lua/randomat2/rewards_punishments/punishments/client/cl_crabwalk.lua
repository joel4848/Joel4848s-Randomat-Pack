net.Receive("Rdmt_Joel4848_RewardPunish_CrabWalkBegin", function()
    hook.Add("StartCommand", "Rdmt_Joel4848_RewardPunish_CrabWalk_StartCommand", function(ply, cmd)
        if ply ~= Randomat.Client or not ply:Alive() or ply:IsSpec() then return end
        cmd:SetForwardMove(0)
    end)
end)

net.Receive("Rdmt_Joel4848_RewardPunish_CrabWalkEnd", function()
    hook.Remove("StartCommand", "Rdmt_Joel4848_RewardPunish_CrabWalk_StartCommand")
end)