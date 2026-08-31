net.Receive("Rdmt_Joel4848_RewardPunish_ReversedControlsBegin", function()
    local hardmode = net.ReadBool()
    hook.Add("StartCommand", "Rdmt_Joel4848_RewardPunish_ReversedControls_StartCommand", function(ply, cmd)
        if ply ~= Randomat.Client then return end

        -- Make the player move the opposite direction
        cmd:SetForwardMove(-cmd:GetForwardMove())
        cmd:SetSideMove(-cmd:GetSideMove())

        -- Attack reloads, reload attacks
        if cmd:KeyDown(IN_ATTACK) then
            cmd:RemoveKey(IN_ATTACK)
            cmd:SetButtons(cmd:GetButtons() + IN_RELOAD)
        elseif cmd:KeyDown(IN_RELOAD) then
            cmd:RemoveKey(IN_RELOAD)
            cmd:SetButtons(cmd:GetButtons() + IN_ATTACK)
        -- If hard mode is enabled then reverse jump and duck too
        elseif hardmode then
            if cmd:KeyDown(IN_JUMP) then
                cmd:RemoveKey(IN_JUMP)
                cmd:SetButtons(cmd:GetButtons() + IN_DUCK)
            elseif cmd:KeyDown(IN_DUCK) then
                cmd:RemoveKey(IN_DUCK)
                cmd:SetButtons(cmd:GetButtons() + IN_JUMP)
            end
        end
    end)

    -- Override the sprint key so the player can sprint forward while holding the back key
    hook.Add("TTTSprintKey", "Rdmt_Joel4848_RewardPunish_ReversedControls_TTTSprintKey", function(ply)
        if ply ~= Randomat.Client then return end

        return IN_BACK
    end)
end)

net.Receive("Rdmt_Joel4848_RewardPunish_ReversedControlsEnd", function()
    hook.Remove("StartCommand", "Rdmt_Joel4848_RewardPunish_ReversedControls_StartCommand")
    hook.Remove("TTTSprintKey", "Rdmt_Joel4848_RewardPunish_ReversedControls_TTTSprintKey")
end)