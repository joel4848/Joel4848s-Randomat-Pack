net.Receive("Rdmt_Joel4848_RewardPunish_FlipScreenBegin", function()
    local view = { origin = vector_origin, angles = angle_zero, fov = 0 }
    hook.Add("CalcView", "Rdmt_Joel4848_RewardPunish_FlipScreen_CalcView", function(ply, origin, angles, fov)
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() or ply ~= Randomat.Client then return end

        view.origin = origin
        view.angles = angles
        view.fov = fov

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            local func = wep.CalcView
            if func then
                view.origin, view.angles, view.fov = func(wep, ply, origin * 1, angles * 1, fov)
            end
        end

        view.angles.r = view.angles.r + 180

        return view
    end)

    hook.Add("InputMouseApply", "Rdmt_Joel4848_RewardPunish_FlipScreen_InputMouseApply", function(cmd, x, y, ang)
        if not Randomat.Client:Alive() or Randomat.Client:IsSpec() then return end

        ang.yaw = ang.yaw + (x / 50)
        ang.pitch = math.Clamp(ang.pitch - y / 50, -89, 89)
        cmd:SetViewAngles(ang)

        return true
    end)
end)

net.Receive("Rdmt_Joel4848_RewardPunish_FlipScreenEnd", function()
    hook.Remove("CalcView", "Rdmt_Joel4848_RewardPunish_FlipScreen_CalcView")
    hook.Remove("InputMouseApply", "Rdmt_Joel4848_RewardPunish_FlipScreen_InputMouseApply")
end)