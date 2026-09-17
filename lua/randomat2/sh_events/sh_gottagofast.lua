local EVENT = {}

EVENT.Title       = "Gotta go fast!"
EVENT.Description = "The longer you hold a direction key down, the faster you go"
EVENT.id          = "gottagofast"
EVENT.Categories  = {"smallimpact"}

CreateConVar("randomat_gottagofast_maximum_multiplier", 20, FCVAR_REPLICATED, "The maximum possible speed multiplier", 1, 200)
CreateConVar("randomat_gottagofast_speed_rate", 10, FCVAR_REPLICATED, "The rate at which speed increases", 0.1, 100)
CreateConVar("randomat_gottagofast_speedometer_enabled", 1, FCVAR_REPLICATED, "Whether players see a speedometer", 0, 1)

function EVENT:Begin()
    local rate = GetConVar("randomat_gottagofast_speed_rate"):GetFloat() / 1000
    local max  = GetConVar("randomat_gottagofast_maximum_multiplier"):GetInt()
    local speedometerEnabled = GetConVar("randomat_gottagofast_speedometer_enabled"):GetBool()

    local playerMults = {}

    for _, ply in player.Iterator() do
        local sid64 = ply:SteamID64()
        playerMults[sid64] = 1
    end

    local nextCheck = CurTime()

    self:AddHook("FinishMove", function(ply, moveData)
        if not ply:Alive() or ply:IsSpec() then return end

        if CurTime() < nextCheck then return end

        local sid64   = ply:SteamID64()
        local moving  = moveData:GetForwardSpeed() ~= 0 or moveData:GetSideSpeed() ~= 0
        local keyHeld = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)

        if moving and keyHeld then
            playerMults[sid64] = math.min(playerMults[sid64] + rate, max)
        else
            playerMults[sid64] = 1
        end

        nextCheck = CurTime() + 0.01
    end)

    local TableInsert = table.insert

    self:AddHook("TTTSpeedMultiplier", function(ply, mults)
        local sid64 = ply:SteamID64()
        local mult  = playerMults[sid64] or 1
        if IsPlayer(ply) then
            TableInsert(mults, mult)
        end
    end)

    if CLIENT and speedometerEnabled then
        -- Multiplier to actually display (for smooth needle drop)
        local displayMultiplier = 1

        hook.Add("HUDPaint", "HUDPaint_GottaGoFast", function()
            local ply = LocalPlayer()

            if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end

            local sid64            = ply:SteamID64()
            local targetMultiplier = playerMults[sid64] or 1
            local maxMultiplier    = GetConVar("randomat_gottagofast_maximum_multiplier"):GetInt()
            local neverZeroMax     = math.max(1.01, maxMultiplier)

            -- Do smooth drop
            if displayMultiplier < targetMultiplier then
                displayMultiplier = targetMultiplier
            elseif displayMultiplier > targetMultiplier then
                -- Drop needle over 1s -- 0.5s
                local dropRate = (neverZeroMax - 1) -- / 0.5
                displayMultiplier = math.max(targetMultiplier, displayMultiplier - (dropRate * FrameTime()))
            end

            local centreX   = ScrW() / 2
            local centreY   = ScrH() - 150
            local radius    = 180
            local thickness = 20

            surface.SetDrawColor(30, 30, 30, 220)
            draw.NoTexture()

            local segments = 40
            for i = 0, segments - 1 do
                local a1 = math.rad(135 + (i / segments) * 270)
                local a2 = math.rad(135 + ((i + 1) / segments) * 270)

                local speedometer = {
                    {x = centreX + math.cos(a1) * (radius - thickness), y = centreY + math.sin(a1) * (radius - thickness)},
                    {x = centreX + math.cos(a1) * radius,               y = centreY + math.sin(a1) * radius},
                    {x = centreX + math.cos(a2) * radius,               y = centreY + math.sin(a2) * radius},
                    {x = centreX + math.cos(a2) * (radius - thickness), y = centreY + math.sin(a2) * (radius - thickness)}
                }
                surface.DrawPoly(speedometer)
            end

            -- Work out needle angle
            local fraction = math.Clamp((displayMultiplier - 1) / (neverZeroMax - 1), 0, 1)
            local needleAngle = math.rad(135 + (fraction * 270))

            local needleX = centreX + math.cos(needleAngle) * (radius - 10)
            local needleY = centreY + math.sin(needleAngle) * (radius - 10)

            surface.SetDrawColor(255, 50, 50, 255)

            local needleAngle1 = needleAngle - math.pi/2
            local needleAngle2 = needleAngle + math.pi/2
            local needle = {
                {x = centreX + math.cos(needleAngle1) * 6, y = centreY + math.sin(needleAngle1) * 6},
                {x = needleX, y = needleY},
                {x = centreX + math.cos(needleAngle2) * 6, y = centreY + math.sin(needleAngle2) * 6}
            }
            surface.DrawPoly(needle)

            local centreRadius = 12
            surface.SetDrawColor(200, 200, 200, 255)
            local circlePoly = {}
            for i = 1, 36 do
                local circleAngle = math.rad(i * 10)
                table.insert(circlePoly, {x = centreX + math.cos(circleAngle) * centreRadius, y = centreY + math.sin(circleAngle) * centreRadius})
            end
            surface.DrawPoly(circlePoly)

            local boxW = 120
            local boxH = 40
            local boxX = centreX - boxW / 2
            local boxY = centreY - radius / 2 -- ScrH() - 10 - boxH

            draw.RoundedBox(8, boxX, boxY, boxW, boxH, Color(0, 0, 0, 200))
            draw.SimpleText(string.format("%.2fx", displayMultiplier), "DermaLarge", centreX, boxY + boxH / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end)
    end
end

function EVENT:End()
    timer.Remove("Randomat_GottaGoFast_KeyCheck")
    hook.Remove("HUDPaint", "HUDPaint_GottaGoFast")
end

if SERVER then
    function EVENT:GetConVars()
        local sliders = {}

        for _, v in ipairs({"maximum_multiplier"}) do
            local name = "randomat_" .. self.id .. "_" .. v
            if ConVarExists(name) then
                local convar = GetConVar(name)
                table.insert(sliders, {
                    cmd = v,
                    dsc = convar:GetHelpText(),
                    min = convar:GetMin(),
                    max = convar:GetMax(),
                    dcm = 0
                })
            end
        end

        for _, v in ipairs({"speed_rate"}) do
            local name = "randomat_" .. self.id .. "_" .. v
            if ConVarExists(name) then
                local convar = GetConVar(name)
                table.insert(sliders, {
                    cmd = v,
                    dsc = convar:GetHelpText(),
                    min = convar:GetMin(),
                    max = convar:GetMax(),
                    dcm = 1
                })
            end
        end

        local checks = {}
        for _, v in ipairs({"speedometer_enabled"}) do
            local name = "randomat_" .. self.id .. "_" .. v
            if ConVarExists(name) then
                local convar = GetConVar(name)
                table.insert(checks, {
                    cmd = v,
                    dsc = convar:GetHelpText()
                })
            end
        end

        local textboxes = {}

        local layout = {
            ["speedometer_enabled"] = 1,
            ["maximum_multiplier"]  = 2,
            ["speed_rate"]          = 3
        }

        return sliders, checks, textboxes, layout
    end
end

Randomat:register(EVENT)