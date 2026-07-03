local EVENT = {}
EVENT.id = "whoseline"

local DEFAULT_COLOR = Color(255, 50, 50, 200)

local lookers = {}
local colours = {}

function EVENT:Begin()
    lookers = {}
    colours = {}

    local function VecToColor(vec, alpha)
        return Color(vec.x * 255, vec.y * 255, vec.z * 255, alpha or 255)
    end

    local function GetPlayerColor(ply, alpha)
        if not IsValid(ply) then return DEFAULT_COLOR end

        local sid64 = ply:SteamID64()
        if colours[sid64] and colours[sid64][alpha] then return colours[sid64][alpha] end

        local perColours = GetConVar("randomat_whoseline_per_player_colours")
        local colour = DEFAULT_COLOR
        if perColours and perColours:GetBool() then
            local vec = ply:GetNWVector("PlayerColor", Vector(1, 0.2, 0.2))
            colour = VecToColor(vec, alpha or 200)
        end

        if not colours[sid64] then
            colours[sid64] = {}
        end
        colours[sid64][alpha] = colour
        return colour
    end

    -- Beam/sprite
    hook.Add("PostDrawOpaqueRenderables", "randomat_whoseline_lasers", function()
        local localPly = LocalPlayer()
        if not IsValid(localPly) or not GetConVar("randomat_whoseline_show_lines"):GetBool() then return end

        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() and ply ~= localPly and not ply:GetNoDraw() then

                -- Offset start point 2 units forward because weirdly it starts BEHIND the head otherwise
                -- It also seems to start off to the side but I think that's to do with the default player models
                local startPos = ply:EyePos() + (ply:GetAimVector() * 2)

                local tr = util.TraceLine({
                    start = startPos,
                    endpos = startPos + (ply:GetAimVector() * 32768),
                    filter = ply,
                    mask = MASK_VISIBLE_AND_NPCS
                })

                local lookerColour = GetPlayerColor(ply, 180)

                render.SetMaterial(Material("effects/laser1"))
                render.DrawBeam(startPos, tr.HitPos, 25, 0, 1, lookerColour)

                render.SetMaterial(Material("effects/blueflare1"))
                render.DrawSprite(tr.HitPos, 8, 8, lookerColour)
            end
        end
    end)

    -- 'Looker' detection'
    hook.Add("Think", "randomat_whoseline_looker_check", function()

        local localPly = LocalPlayer()
        if not IsValid(localPly) or not localPly:Alive() then
            lookers = {}
            return
        end

        local newLookers = {}
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() and ply ~= localPly then

                local tr = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = ply:EyePos() + (ply:GetAimVector() * 32768),
                    filter = ply,
                    mask = MASK_VISIBLE_AND_NPCS
                })

                if tr.Entity == localPly then
                    table.insert(newLookers, ply)
                end
            end
        end
        lookers = newLookers
    end)

    -- Warning symbols
    hook.Add("HUDPaint", "randomat_whoseline_warning_icons", function()
        if #lookers == 0 then return end

        if not GetConVar("randomat_whoseline_warn_target_colour"):GetBool() or not GetConVar("randomat_whoseline_per_player_colours"):GetBool() then return end

        local iconSize = 96
        local spacing = 8
        local padding = 10
        local count = #lookers

        local totalIconsWidth = (count * iconSize) + ((count - 1) * spacing)
        local boxW = totalIconsWidth + (padding * 2)
        local boxH = iconSize + (padding * 2)

        local startX = (ScrW() / 2) - (totalIconsWidth / 2)
        local yPos = 20

        draw.RoundedBox(8, startX - padding, yPos - padding, boxW, boxH, Color(0, 0, 0, 245))

        for i, ply in ipairs(lookers) do
            if IsValid(ply) then
                local col = GetPlayerColor(ply, 255)
                local currentX = startX + (i - 1) * (iconSize + spacing)

                surface.SetMaterial(Material("vgui/ttt/whoseline/looked_at.png"))
                surface.SetDrawColor(col.r, col.g, col.b, 255)
                surface.DrawTexturedRect(currentX, yPos, iconSize, iconSize)
            end
        end
    end)

    -- Warning name list
    surface.CreateFont("RdmtWhoseLineWarningFont", {
        font = "Roboto",
        size = 25
    })

    hook.Add("HUDPaint", "randomat_whoseline_hud", function()

        if not GetConVar("randomat_whoseline_warn_target_name"):GetBool() then return end

        local lines = { "Players looking at you:" }
        for _, ply in ipairs(lookers) do
            if IsValid(ply) then
                table.insert(lines, " > " .. ply:Nick())
            end
        end

        local x = ScrW() * 0.02
        local y = ScrH() * 0.35
        local lineH = 28
        local padding = 10

        surface.SetFont("RdmtWhoseLineWarningFont")
        local maxW = 0
        for _, line in ipairs(lines) do
            local w = surface.GetTextSize(line)
            if w > maxW then maxW = w end
        end

        local boxW = maxW + (padding * 2)
        local boxH = (#lines * lineH) + (padding * 2)
        draw.RoundedBox(4, x - padding, y - padding, boxW, boxH, Color(0, 0, 0, 250))

        for i, line in ipairs(lines) do
            local col
            if i == 1 then
                col = Color(255, 220, 80, 255) -- Header (Yellow)
            else
                local ply = lookers[i - 1]
                col = GetPlayerColor(ply, 255)
            end

            draw.SimpleText(line, "RdmtWhoseLineWarningFont", x, y + ((i - 1) * lineH), col)
        end
    end)
end

function EVENT:End()
    lookers = {}
    colours = {}

    hook.Remove("PostDrawOpaqueRenderables", "randomat_whoseline_lasers")
    hook.Remove("Think", "randomat_whoseline_looker_check")
    hook.Remove("HUDPaint", "randomat_whoseline_warning_icons")
    hook.Remove("HUDPaint", "randomat_whoseline_hud")
end

Randomat:register(EVENT)