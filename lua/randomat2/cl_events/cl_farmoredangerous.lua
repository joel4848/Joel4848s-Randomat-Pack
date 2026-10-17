local EVENT = {}

EVENT.id = "farmoredangerous"

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

local scrW = ScrW()
local scrH = ScrH()

function EVENT:Begin()
    self:AddHook("HUDPaint", function()
        local ply = LocalPlayer()

        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end

        local trace = ply:GetEyeTrace()
        local distanceUnits = trace.HitPos:Distance(ply:EyePos())

        local distanceMeters = distanceUnits * 0.0254

        local min    = GetConVar("randomat_farmoredangerous_distance_minimum"):GetInt()
        local max    = GetConVar("randomat_farmoredangerous_distance_maximum"):GetInt()
        local dmgMin = GetConVar("randomat_farmoredangerous_damage_minimum"):GetInt() / 100
        local dmgMax = GetConVar("randomat_farmoredangerous_damage_maximum"):GetInt() / 100

        if max < min then max = min end
        if dmgMax < dmgMin then dmgMax = dmgMin end

        local multiplier = math.Remap(math.Clamp(distanceUnits, min, max), min, max, dmgMin, dmgMax)
        local multiPercent = math.Round(multiplier * 100)

        local rangeX = -100
        local rangeY = -100

        local damageX = 100
        local damageY = -100

        local centreX = scrW / 2
        local centreY = scrH / 2

        local valueColor = Color(255, 255, 0)
        if multiPercent == 0 then
            valueColor = Color(255, 50, 50)
        elseif multiPercent <= 50 then
            valueColor = Color(255, 150, 0)
        elseif multiPercent >= 100 then
            valueColor = Color(50, 255, 50)
        end

        local rangeValStr = string.format("%.1fm", distanceMeters)
        local damageValStr = string.format("%d%%", multiPercent)


        -- Range label
        draw.SimpleTextOutlined("Range:", "TargetID_20", centreX + rangeX, centreY + rangeY, color_white, TEXT_ALIGN_centre, TEXT_ALIGN_centre, 1, color_black)
        -- Range value
        draw.SimpleTextOutlined(rangeValStr, "TargetID_25", centreX + rangeX, centreY + rangeY + 22, color_white, TEXT_ALIGN_centre, TEXT_ALIGN_centre, 1, color_black)

        -- Damage label
        draw.SimpleTextOutlined("Damage:", "TargetID_20", centreX + damageX, centreY + damageY, color_white, TEXT_ALIGN_centre, TEXT_ALIGN_centre, 1, color_black)
        -- Damage value
        draw.SimpleTextOutlined(damageValStr, "TargetID_25", centreX + damageX, centreY + damageY + 22, valueColor, TEXT_ALIGN_centre, TEXT_ALIGN_centre, 1, color_black)
    end)
end

function EVENT:End()

end

Randomat:register(EVENT)