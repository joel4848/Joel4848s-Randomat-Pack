net.Receive("Rdmt_Joel4848_RewardPunish_LockedCameraBegin", function()
    -- Prevents up/down movement with the mouse
    hook.Add("InputMouseApply", "Rdmt_Joel4848_RewardPunish_ChangedFOV_InputMouseApply", function(cmd, x, y, ang)
        if  not Randomat.Client:Alive() or Randomat.Client:IsSpec() then return end

        ang.pitch = 0
        ang.yaw = ang.yaw - (x / 50)
        cmd:SetViewAngles(ang)

        return true
    end)
end)

net.Receive("Rdmt_Joel4848_RewardPunish_LockedCameraEnd", function()
    hook.Remove("InputMouseApply", "Rdmt_Joel4848_RewardPunish_ChangedFOV_InputMouseApply")
end)