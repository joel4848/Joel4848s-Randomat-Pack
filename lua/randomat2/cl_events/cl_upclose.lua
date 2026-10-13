local EVENT = {}

EVENT.id = "upclose"

surface.CreateFont("TargetID_20", {
	font = "Verdana",
	extended = false,
	size = 20,
	weight = 700,
    antialias = true,
	-- shadow = true,
    outline = true
})

surface.CreateFont("TargetID_25", {
	font = "Verdana",
	extended = false,
	size = 25,
	weight = 700,
    antialias = true,
	-- shadow = true,
    outline = true
})

function EVENT:Begin()
    self:AddHook("HUDPaint", function()
        local ply = LocalPlayer()

        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end

        local trace = ply:GetEyeTrace()
        local distanceUnits = trace.HitPos:Distance(ply:EyePos())

        local distanceMeters = distanceUnits * 0.0254

        local min    = GetConVar("randomat_upclose_distance_minimum"):GetInt()
        local max    = GetConVar("randomat_upclose_distance_maximum"):GetInt()
        local dmgMin = GetConVar("randomat_upclose_damage_minimum"):GetInt() / 100
        local dmgMax = GetConVar("randomat_upclose_damage_maximum"):GetInt() / 100

        if max < min then max = min end
        if dmgMax < dmgMin then dmgMax = dmgMin end

        local multiplier = math.Remap(math.Clamp(distanceUnits, min, max), min, max, dmgMax, dmgMin)
        local multiPercent = math.Round(multiplier * 100)

        -- Position variables relative to the center of the screen
        local rangeX = -100
        local rangeY = -100

        local damageX = 100
        local damageY = -100

        -- Screen center anchor
        local centerX = ScrW() / 2
        local centerY = ScrH() / 2

        -- Dynamic color based on damage percentage
        local valueColor = Color(255, 255, 0)
        if multiPercent == 0 then
            valueColor = Color(255, 50, 50)
        elseif multiPercent <= 50 then
            valueColor = Color(255, 150, 0)
        elseif multiPercent >= 100 then
            valueColor = Color(50, 255, 50)
        end

        -- Formatting strings
        local rangeValStr = string.format("%.1fm", distanceMeters)
        local damageValStr = string.format("%d%%", multiPercent)

        ------------------
        -- DRAW RANGE BLOCK
        ------------------
        -- Label
        draw.SimpleTextOutlined("Range:", "TargetID_20", centerX + rangeX, centerY + rangeY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        -- Value (Centered vertically 22px below the label)
        draw.SimpleTextOutlined(rangeValStr, "TargetID_25", centerX + rangeX, centerY + rangeY + 22, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

        -------------------|
        -- DRAW DAMAGE BLOCK
        -------------------|
        -- Label
        draw.SimpleTextOutlined("Damage:", "TargetID_20", centerX + damageX, centerY + damageY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        -- Value (Centered vertically 22px below the label)
        draw.SimpleTextOutlined(damageValStr, "TargetID_25", centerX + damageX, centerY + damageY + 22, valueColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end)
end

function EVENT:End()

end

Randomat:register(EVENT)