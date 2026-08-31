local sensitivity = nil

net.Receive("Rdmt_Joel4848_RewardPunish_RandomSensitivityValue", function()
    local value = net.ReadFloat()
    if value > 0 then
        sensitivity = value
    else
        sensitivity = nil
    end
end)

hook.Add("AdjustMouseSensitivity", "Rdmt_Joel4848_RewardPunish_RandomSensitivity_AdjustMouseSensitivity", function(default_sensitivity)
    return sensitivity
end)