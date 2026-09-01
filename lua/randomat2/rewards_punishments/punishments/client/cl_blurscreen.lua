net.Receive("Rdmt_Joel4848_RewardPunish_BlurScreenBegin", function()
    -- Prevents up/down movement with the mouse
    hook.Add("RenderScreenspaceEffects", "Rdmt_Joel4848_RewardPunish_BlurScreen_RenderScreenspaceEffects", function(cmd, x, y, ang)
        if  not Randomat.Client:Alive() or Randomat.Client:IsSpec() then return end

        DrawMaterialOverlay("pp/blurx", 1 )
        DrawMaterialOverlay("pp/blury", 1 )
    end)
end)

net.Receive("Rdmt_Joel4848_RewardPunish_BlurScreenEnd", function()
    hook.Remove("RenderScreenspaceEffects", "Rdmt_Joel4848_RewardPunish_BlurScreen_RenderScreenspaceEffects")
end)