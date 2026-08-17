local EVENT = {}

EVENT.id = "sussybuffet"
EVENT.Categories = {"moderateimpact"}

queuePanel = queuePanel or nil
choicePanels = choicePanels or {}

DrawRoundedBoxEx = draw.RoundedBoxEx
DrawSimpleText   = draw.SimpleText

local function ClearChoicePanels()
    for _, p in ipairs(choicePanels) do
        if IsValid(p) then
            p:Remove()
        end
    end
    choicePanels = {}
end

ClearChoicePanels()
if IsValid(queuePanel) then
    queuePanel:Remove()
end

surface.CreateFont("BuffetName", {
    font = "Tahoma",
    size = 16,
    weight = 1000
})

surface.CreateFont("BuffetTimer", {
    font = "Tahoma",
    size = 32,
    weight = 1000
})

surface.CreateFont("BuffetSmall", {
    font = "Tahoma",
    size = 38,
    weight = 1000
})

surface.CreateFont("BuffetRegular", {
    font = "Tahoma",
    size = 48,
    weight = 1000
})

surface.CreateFont("BuffetLarge", {
    font = "Tahoma",
    size = 64,
    weight = 1000
})

-- local outlineMat = Material("vgui/ttt/sussybuffet/outline_large.png")
local glowMat = Material("vgui/ttt/sussybuffet/glow_larger.png")

local function GetColorMode()
    if not modeCVar then
        modeCVar = GetConVar("ttt_color_mode")
    end

    if not overrideModeCVar then
        overrideModeCVar = GetConVar("ttt_color_mode_override")
    end

    local overrideMode = overrideModeCVar and overrideModeCVar:GetString() or "none"
    if overrideMode ~= "none" then
        return overrideMode
    end
    return modeCVar and modeCVar:GetString() or "default"
end

local function ModifyColor(color, type)
    if not type then return color end

    local h, s, l = ColorToHSL(color)
    if type == "dark" then
        l = math.max(l - 0.125, 0.125)
    elseif type == "highlight" or type == "radar" then
        s = 1
    end

    local c = HSLToColor(h, s, l)
    if type == "scoreboard" then
        c = ColorAlpha(c, 30)
    elseif type == "sprite" then
        c = ColorAlpha(c, 130)
    elseif type == "radar" then
        c = ColorAlpha(c, 230)
    end

    return c
end

-- Get correct role colours (thanks Mal)
local function GetRoleColor(role, colorType)
    local mode = GetColorMode()

    if role == ROLE_INNOCENT then
        return ModifyColor(COLOR_INNOCENT[mode], colorType)
    elseif role == ROLE_TRAITOR then
        return ModifyColor(COLOR_TRAITOR[mode], colorType)
    elseif role == ROLE_DETECTIVE then
        return ModifyColor(COLOR_DETECTIVE[mode], colorType)
    end

    return GetRoleTeamColor(player.GetRoleTeam(role), colorType)
end

local infoTextBits = nil

net.Receive("RdmtSussyBuffetInfoToClient", function()
    local choices = net.ReadUInt(8)
    local rerolls = net.ReadUInt(8)
    local det = net.ReadUInt(8)
    local inn = net.ReadUInt(8)
    local tra = net.ReadUInt(8)
    local jes = net.ReadUInt(8)
    local ind = net.ReadUInt(8)
    local respawn = net.ReadBool()
    local dupes = net.ReadBool()

    local groups = {}
    local lineOrderPos = 0

    -- Group lines that appear together
    local function AddGroup(lines)
        table.insert(groups, {
            lineOrderPos = lineOrderPos,
            lines = lines
        })
        lineOrderPos = lineOrderPos + 1
    end

    -- Do correct pluralisations (because I'm a nerd ok?)
    local function GetRoleString(count)
        return count == 1 and " role" or " roles"
    end

    -- Title
    AddGroup({
        {
            align = TEXT_ALIGN_CENTER,
            segs = {{text = "Here's how it works:", font = "BuffetLarge"}}
        }
    })

    -- Timer paused
    AddGroup({
        {
            align = TEXT_ALIGN_LEFT,
            segs = {{text = "- The round timer has been paused, and you're all invincible", font = "BuffetSmall"}}
        }
    })

    -- Respawn (if enabled)
    if respawn then
        AddGroup({
            {
                align = TEXT_ALIGN_LEFT,
                segs = {{text = "- Dead players have been respawned so they can take part too!", font = "BuffetSmall"}}
            }
        })
    end

    -- Secret picking order
    AddGroup({
        {
            align = TEXT_ALIGN_LEFT,
            segs = {
                {text = "← The picking order is ", font = "BuffetSmall"},
                {text = "SECRET", font = "BuffetRegular", colour = Color(255, 0, 0)}
            }
        }
    })

    -- Choices/rerolls
    AddGroup({
        {
            align = TEXT_ALIGN_LEFT,
            segs = {
                {text = "- You get ", font = "BuffetSmall"},
                {text = tostring(choices), font = "BuffetRegular", colour = Color(0, 255, 130)},
                {text = " choices and ", font = "BuffetSmall"},
                {text = tostring(rerolls), font = "BuffetRegular", colour = Color(0, 255, 130)},
                {text = " rerolls", font = "BuffetSmall"}
            }
        }
    })

    -- Team amounts
    AddGroup({
        {
            align = TEXT_ALIGN_LEFT,
            segs = {{text = "- After the buffet there will be:", font = "BuffetSmall"}}
        },
        {
            align = TEXT_ALIGN_LEFT,
            segs = {
                {text = "    - ", font = "BuffetSmall"},
                {text = tostring(det), font = "BuffetRegular", colour = GetRoleColor(ROLE_MARSHAL, "highlight")},
                {text = " Detective" .. GetRoleString(det), font = "BuffetSmall"}
            }
        },
        {
            align = TEXT_ALIGN_LEFT,
            segs = {
                {text = "    - ", font = "BuffetSmall"},
                {text = tostring(inn), font = "BuffetRegular", colour = GetRoleColor(ROLE_DEPUTY, "highlight")},
                {text = " Innocent" .. GetRoleString(inn), font = "BuffetSmall"}
            }
        },
        {
            align = TEXT_ALIGN_LEFT,
            segs = {
                {text = "    - ", font = "BuffetSmall"},
                {text = tostring(tra), font = "BuffetRegular", colour = GetRoleColor(ROLE_HYPNOTIST, "highlight")},
                {text = " Traitor" .. GetRoleString(tra), font = "BuffetSmall"}
            }
        },
        {
            align = TEXT_ALIGN_LEFT,
            segs = {
                {text = "    - ", font = "BuffetSmall"},
                {text = tostring(jes), font = "BuffetRegular", colour = GetRoleColor(ROLE_JESTER, "highlight")},
                {text = " Jester" .. GetRoleString(jes), font = "BuffetSmall"}
            }
        },
        {
            align = TEXT_ALIGN_LEFT,
            segs = {
                {text = "    - ", font = "BuffetSmall"},
                {text = tostring(ind), font = "BuffetRegular", colour = Color(180, 90, 0)},
                {text = " Independent/Monster" .. GetRoleString(ind), font = "BuffetSmall"}
            }
        }
    })

    -- Duplicate role info (depending on if they are/aren't enabled)
    if dupes then
        AddGroup({
            {
                align = TEXT_ALIGN_LEFT,
                segs = {
                    {text = "- There ", font = "BuffetSmall"},
                    {text = "MAY", font = "BuffetRegular", colour = Color(0, 255, 130)},
                    {text = " be duplicate roles", font = "BuffetSmall"}
                }
            }
        })
    else
        AddGroup({
            {
                align = TEXT_ALIGN_LEFT,
                segs = {
                    {text = "- There will ", font = "BuffetSmall"},
                    {text = "NOT", font = "BuffetRegular", colour = Color(0, 255, 130)},
                    {text = " be duplicate roles", font = "BuffetSmall"}
                }
            }
        })
    end

    -- Calculate how big the background box needs to be
    local totalWidth = 0
    local totalHeight = 0
    local padding = 20
    local lineSpacing = 5

    for _, group in ipairs(groups) do
        for _, line in ipairs(group.lines) do
            local lineWidth = 0
            local lineHeight = 0
            for _, seg in ipairs(line.segs) do
                surface.SetFont(seg.font)
                local w, h = surface.GetTextSize(seg.text)
                seg.w = w
                seg.h = h
                lineWidth = lineWidth + w
                if h > lineHeight then lineHeight = h end
            end
            line.w = lineWidth
            line.h = lineHeight

            if lineWidth > totalWidth then totalWidth = lineWidth end
            totalHeight = totalHeight + lineHeight + lineSpacing
        end
    end

    totalWidth = totalWidth + (padding * 2)
    totalHeight = totalHeight + (padding * 2) - lineSpacing

    infoTextBits = {groups = groups, w = totalWidth, h = totalHeight, maxLineOrderPos = lineOrderPos - 1, startTime = CurTime()}

    hook.Add("HUDPaint", "RdmtSussyBuffetInfoHUD", function()
        if not infoTextBits then return end

        local t = CurTime() - infoTextBits.startTime
        local maxTime = infoTextBits.maxLineOrderPos * 4
        local endTime = maxTime + 3 -- 3 second delay after the last line

        -- Clean up after display time ends
        if t > endTime + 2 then
            hook.Remove("HUDPaint", "RdmtSussyBuffetInfoHUD")
            infoTextBits = nil
            return
        end

        -- Do a nice fade out at the end
        local globalAlpha = 1
        if t > endTime then
            globalAlpha = 1 - math.Clamp(t - endTime, 0, 1)
        end

        local boxW = infoTextBits.w
        local boxH = infoTextBits.h
        local boxX = (ScrW() - boxW) / 2
        local boxY = (ScrH() - boxH) / 2

        -- Draw Background
        DrawRoundedBoxEx(20, boxX, boxY, boxW, boxH, Color(0, 0, 0, 240 * globalAlpha), true, false, false, true)

        local currentY = boxY + 20

        -- Draw the text bits
        for _, group in ipairs(infoTextBits.groups) do
            local appearTime = group.lineOrderPos * 4

            if t >= appearTime then
                -- Quick fade in
                local lineAlpha = math.Clamp((t - appearTime) / 0.2, 0, 1)
                local textAlpha = 255 * lineAlpha * globalAlpha

                for _, line in ipairs(group.lines) do
                    local currentX = boxX + 20

                    if line.align == TEXT_ALIGN_CENTER then
                        currentX = boxX + (boxW / 2) - (line.w / 2)
                    end

                    local centerOfLineY = currentY + (line.h / 2)

                    for _, seg in ipairs(line.segs) do
                        DrawSimpleText(seg.text, seg.font, currentX, centerOfLineY, seg.colour and ColorAlpha(seg.colour, textAlpha) or Color(255, 255, 255, textAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        currentX = currentX + seg.w
                    end
                    currentY = currentY + line.h + lineSpacing
                end
            else
                for _, line in ipairs(group.lines) do
                    currentY = currentY + line.h + lineSpacing
                end
            end
        end
    end)
end)

local choiceTimerStart = 0
local choiceTimerDuration = 0

local function StartChoiceTimer(duration)
    choiceTimerStart = CurTime()
    choiceTimerDuration = duration or 10
    timer.Create("RdmtSussyBuffet_ClientChoiceTimer", duration, 1, function()
        net.Start("RdmtSussyBuffetChoices")
            net.WriteUInt(4, 3)
        net.SendToServer()
    end)
end

local scrW, scrH = ScrW(), ScrH()
local mgnColour = Color(0, 255, 130)
local mgnColourDark = Color(0, 195, 101)

local function DisplayNewRole(role)
    ClearChoicePanels()

    local roleName = ROLE_STRINGS[role] or "Unknown"
    local roleColorDark = GetRoleColor(role, "dark")
    local roleColorHighlight = GetRoleColor(role, "highlight")
    local iconPath = util.GetRoleIconPath(ROLE_STRINGS_SHORT[role], "score", "png")

    local prefixText = "You will be: "
    surface.SetFont("BuffetSmall")
    local prefixW, _ = surface.GetTextSize(prefixText)

    surface.SetFont("BuffetRegular")
    local roleW, _ = surface.GetTextSize(roleName)

    local totalTextW = prefixW + roleW

    local buttonSize = math.floor(scrH * 0.08)
    local padding = math.floor(buttonSize / 2)

    local width = padding + buttonSize + padding + totalTextW + padding
    local height = buttonSize + (padding * 2)

    local left = math.floor((scrW / 2) - (width / 2))
    local top = math.floor((scrH / 2) - (height / 2))

    -- Background
    local frame = vgui.Create("DFrame")
    table.insert(choicePanels, frame)
    frame:SetSize(width, height)
    frame:SetPos(left, top)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:SetDeleteOnClose(true)

    -- Role icon
    local iconBox = vgui.Create("DImage", frame)
    iconBox:SetSize(buttonSize, buttonSize)
    iconBox:SetPos(padding, padding)
    iconBox.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, roleColorDark)
    end

    local icon = vgui.Create("DImage", iconBox)
    icon:SetSize(buttonSize, buttonSize)
    icon:SetPos(0, 0)
    icon:SetImage(iconPath)
    icon:SetKeepAspect(true)

    frame.Paint = function(self, w, h)
        -- Background
        DrawRoundedBoxEx(32, 0, 0, w, h, Color(0, 0, 0, 240), true, false, false, true)

        -- Icon outline
        local outlineOffset = 5
        local bx, by = padding, padding
        draw.RoundedBox(4, bx - outlineOffset, by - outlineOffset, buttonSize + (outlineOffset * 2), buttonSize + (outlineOffset * 2), roleColorHighlight)

        -- Text
        local curX = bx + buttonSize + padding
        local centerY = by + math.floor(buttonSize / 2)

        DrawSimpleText(prefixText, "BuffetSmall", curX, centerY, mgnColour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Role name text
        DrawSimpleText(roleName, "BuffetRegular", curX + prefixW, centerY, roleColorHighlight, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Fade panel out after delay
    frame:AlphaTo(0, 1, 3, function(_, pnl)
        if IsValid(pnl) then
            pnl:Remove()
        end
    end)
end

local promptTextParts = {
    {text = "Reroll for ", font = "BuffetSmall"},
    {text = "2", font = "BuffetLarge"},
    {text = " choices", font = "BuffetSmall"}
}

local promptTextWidth = 0
for _, part in ipairs(promptTextParts) do
    surface.SetFont(part.font)
    promptTextWidth = promptTextWidth + surface.GetTextSize(part.text)
end

local function CreateChoiceUI(choices)
    local height = math.floor(scrH / 2)

    local padding    = math.floor(height / 15)
    local buttonSize = math.floor((height - padding * 6) / 5)

    local width = math.floor(5 * padding + buttonSize + promptTextWidth) -- Why 5?!

    local top  = math.floor((scrH / 2) - (height / 2))
    local left = math.floor((scrW / 2) - (width / 2))

    -- Background Frame
    local background = vgui.Create("DFrame")
    table.insert(choicePanels, background)
    background:SetSize(width, height + 60)
    background:SetPos(left, top - 30)
    background:SetTitle("")
    background:SetDraggable(false)
    background:ShowCloseButton(false)
    background:SetDeleteOnClose(true)

    local allButtons = {}
    local roleButtons = {}

    -- Arrow icon
    local arrow = vgui.Create("DImage", background)
    table.insert(choicePanels, arrow)

    arrow:SetSize(buttonSize, buttonSize)
    arrow:SetPos(padding, padding)
    arrow:SetText("")
    arrow:SetImage("vgui/ttt/sussybuffet/arrow.png")

    -- Role buttons
    for id = 1, 3 do
        local btn = vgui.Create("DImageButton", background)
        table.insert(choicePanels, btn)

        local yPos = padding + id * (buttonSize + padding)
        local hasChoice = #choices >= id
        local buttonImage = hasChoice and util.GetRoleIconPath(ROLE_STRINGS_SHORT[choices[id]], "score", "png") or "vgui/ttt/sussybuffet/cross.png"

        btn:SetSize(buttonSize, buttonSize)
        btn:SetPos(padding, yPos)
        btn:SetText("")
        btn:SetImage(buttonImage)
        if not hasChoice then
            btn:SetEnabled(false)
            btn:SetMouseInputEnabled(false)
        end

        btn.DoClick = function()
            timer.Remove("RdmtSussyBuffet_ClientChoiceTimer")
            ClearChoicePanels()
            DisplayNewRole(choices[id])

            net.Start("RdmtSussyBuffetChoices")
                net.WriteUInt(id, 3)
            net.SendToServer()
        end

        btn.Paint = function(self, w, h)
            local buttonColour = hasChoice and GetRoleColor(choices[id], "dark") or Color(25, 25, 25, 255)
            draw.RoundedBox(2, 0, 0, w, h, buttonColour)
        end

        btn.GetBorderColor = function()
            return hasChoice and GetRoleColor(choices[id], "highlight") or Color(50, 50, 50, 255)
        end

        roleButtons[id] = btn
        table.insert(allButtons, btn)
    end

    -- Mulligan button
    local mgn = vgui.Create("DImageButton", background)
    table.insert(choicePanels, mgn)

    local mgnY = padding + 4 * (buttonSize + padding)

    mgn:SetSize(buttonSize, buttonSize)
    mgn:SetPos(padding, mgnY)
    mgn:SetText("")
    mgn:SetImage("vgui/ttt/sussybuffet/reroll.png")

    mgn.DoClick = function()
        timer.Remove("RdmtSussyBuffet_ClientChoiceTimer")
        -- ClearChoicePanels()
        net.Start("RdmtSussyBuffetChoices")
            net.WriteUInt(4, 3)
        net.SendToServer()
    end

    mgn.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, mgnColourDark)
    end

    mgn.GetBorderColor = function() return mgnColour end
    table.insert(allButtons, mgn)

    -- Background paint
    background.Paint = function(self, w, h)
        -- Draw background
        DrawRoundedBoxEx(32, 0, 0, w, h, Color(0, 0, 0, 240), true, false, false, true)

        local outlineOffset = 5
        local glowOffset = math.floor(height / 20)

        -- Outlines and glows
        for idx, btn in ipairs(allButtons) do
            if not IsValid(btn) then continue end

            local bx, by = btn:GetPos()
            local bw, bh = btn:GetSize()

            local isHovered = btn:IsHovered() or btn:IsChildHovered()
            local borderColour = btn:GetBorderColor()

            surface.SetDrawColor(borderColour)

            if isHovered and (idx == 4 or #choices >= idx) then
                surface.SetMaterial(glowMat)
                surface.DrawTexturedRect(bx - glowOffset, by - glowOffset, bw + (glowOffset * 2), bh + (glowOffset * 2))
            end

            draw.RoundedBox(4, bx - outlineOffset, by - outlineOffset, bw + (outlineOffset * 2), bh + (outlineOffset * 2), borderColour)
        end

        -- Draw prompt text
        surface.SetFont("BuffetLarge")
        local _, promptTextH = surface.GetTextSize("Choose a role")

        local arrowW, arrowH = arrow:GetSize()
        local promptTextX = 2 * padding + arrowW
        local promptTextY = padding + arrowH / 2 - promptTextH / 2

        DrawSimpleText("Choose a role", "BuffetLarge", promptTextX, promptTextY, Color(255, 255, 255))

        -- Draw role name text
        for id = 1, 3 do
            local btn = roleButtons[id]
            if not IsValid(btn) then continue end

            local buttonText = #choices >= id and ROLE_STRINGS[choices[id]] or ""
            if buttonText == "" then continue end

            surface.SetFont("BuffetRegular")
            local _, th = surface.GetTextSize(buttonText)

            local bx, by = btn:GetPos()
            local bw, bh = btn:GetSize()
            local tx = bx + bw + padding
            local ty = by + bh / 2 - th / 2
            local teamColour = GetRoleColor(choices[id], "highlight")

            DrawSimpleText(buttonText, "BuffetRegular", tx, ty, teamColour)
        end

        -- Draw mulligan text
        if IsValid(mgn) then
            local mx, my = mgn:GetPos()
            local mw, mh = mgn:GetSize()
            local lastText = #choices == 3 and " new choices" or " new choice"

            local textParts = {
                {text = "Reroll for ", font = "BuffetSmall", color = mgnColour},
                {text = tostring(#choices - 1), font = "BuffetLarge", color = Color(255, 255, 255)},
                {text = lastText, font = "BuffetSmall", color = mgnColour}
            }

            local curX = mx + mw + padding
            local centerY = my + math.floor(mh / 2)

            for _, part in ipairs(textParts) do
                DrawSimpleText(part.text, part.font, curX, centerY, part.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                surface.SetFont(part.font)
                local tw, _ = surface.GetTextSize(part.text)
                curX = curX + tw
            end
        end

        -- Timer
        if choiceTimerStart > 0 and choiceTimerDuration > 0 then
            local remaining = math.max(0, (choiceTimerStart + choiceTimerDuration) - CurTime())
            local fraction = math.Clamp(remaining / choiceTimerDuration, 0, 1)

            -- Color based on % remaining
            local timerColor = Color(255, 255, 255)
            if fraction < 0.2 then
                timerColor = Color(255, 50, 50)
            elseif fraction < 0.5 then
                timerColor = Color(255, 220, 0)
            end

            -- Time text
            local prefixText = "Time remaining: "
            local timeText = math.Round(remaining, 2) -- .. "s"

            surface.SetFont("BuffetTimer")
            local prefixW, th = surface.GetTextSize(prefixText)
            local timeW, _ = surface.GetTextSize("8.88")

            -- Timer text
            local totalTextW = prefixW + timeW
            local textStartX = math.floor((w / 2) - (totalTextW / 2))
            local textY = h - 45

            DrawSimpleText(prefixText, "BuffetTimer", textStartX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawSimpleText(timeText, "BuffetTimer", textStartX + prefixW, textY, timerColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Timer bar
            local maxBarW = w - (2 * padding)
            local currentBarW = math.floor(maxBarW * fraction)
            local barX = math.floor((w / 2) - (currentBarW / 2))
            local barY = textY + math.floor(th / 2) + 8
            local barHeight = 6

            if currentBarW > 0 then
                draw.RoundedBox(3, barX, barY, currentBarW, barHeight, timerColor)
            end
        end
    end
end

local currentActiveIndex = 0

local function CreateQueueUI(queueSize, localIndex)
    if IsValid(queuePanel) then queuePanel:Remove() end

    local iconSize = math.floor(scrH * 0.05)
    local padding = math.floor(iconSize / 4)

    -- Text size
    surface.SetFont("BuffetSmall")
    local tw1, th1 = surface.GetTextSize("Currently")
    local tw2, th2 = surface.GetTextSize("choosing:")

    local titleHeight = th1 + th2
    local maxTextWidth = math.max(tw1, tw2)

    -- Panel size
    local totalWidth = math.max(maxTextWidth, iconSize) + (padding * 4)
    local iconsHeight = (iconSize * queueSize) + (padding * (queueSize - 1))
    local totalHeight = 4 * padding + titleHeight + iconsHeight

    local left = math.floor(scrW * 0.02)
    local top = math.floor((scrH / 2) - (totalHeight / 2))

    -- Background
    queuePanel = vgui.Create("DPanel")
    -- table.insert(choicePanels, queuePanel)
    queuePanel:SetSize(totalWidth, totalHeight)
    queuePanel:SetPos(left, top)
    queuePanel:SetMouseInputEnabled(true)
    queuePanel:MakePopup(true)
    queuePanel:SetKeyboardInputEnabled(false)

    -- Paint background and title
    queuePanel.Paint = function(self, w, h)
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 240))

        local centerX = math.floor(w / 2)
        DrawSimpleText("Currently", "BuffetSmall", centerX, padding, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        DrawSimpleText("choosing:", "BuffetSmall", centerX, padding + th1, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    local goldBorder = Color(255, 215, 0)
    local glowOffset = 15

    -- Icon column pos
    local iconStartX = math.floor((totalWidth / 2) - (iconSize / 2))
    local iconStartY = 2.5 * padding + titleHeight

    -- Do the icon column
    for i = 1, queueSize do
        local iconY = iconStartY + (i - 1) * (iconSize + padding)

        local iconBox = vgui.Create("DPanel", queuePanel)
        -- table.insert(choicePanels, iconBox)
        iconBox:SetSize(iconSize, iconSize)
        iconBox:SetPos(iconStartX, iconY)

        local isLocalPlayer = (i == localIndex)

        if isLocalPlayer then
            local av = vgui.Create("AvatarImage", iconBox)
            av:SetSize(iconSize - 4, iconSize - 4)
            av:SetPos(2, 2)
            av:SetPlayer(LocalPlayer(), 64)
        else
            local img = vgui.Create("DImage", iconBox)
            img:SetSize(iconSize - 4, iconSize - 4)
            img:SetPos(2, 2)
            img:SetImage("vgui/ttt/sussybuffet/hidden_player.png")
        end

        iconBox.Paint = function(self, w, h)
            local isActive = (currentActiveIndex == i)

            -- Golden glow for the active player
            if isActive then
                DisableClipping(true)

                if glowMat then
                    surface.SetMaterial(glowMat)
                    surface.SetDrawColor(goldBorder)
                    surface.DrawTexturedRect(-glowOffset, -glowOffset, w + (glowOffset * 2), h + (glowOffset * 2))
                end
                draw.RoundedBox(4, -2, -2, w + 4, h + 4, goldBorder)

                DisableClipping(false)
            end

            -- Icon background
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))

            -- Hidden players outline
            if not isLocalPlayer then
                draw.RoundedBox(0, 2, 2, w - 4, h - 4, Color(40, 40, 40))
            end
        end
    end
end

net.Receive("RdmtSussyBuffetChoices", function()
    ClearChoicePanels()
    local choices = net.ReadTable(true)
    timer.Simple(0, function()
        if #choices == 1 then
            DisplayNewRole(choices[1])
            net.Start("RdmtSussyBuffetChoices")
                net.WriteUInt(1, 3)
            net.SendToServer()
        else
            CreateChoiceUI(choices)
            StartChoiceTimer(GetConVar("randomat_sussybuffet_choice_time"):GetInt())
        end
    end)
end)

net.Receive("RdmtSussyBuffetQueueInit", function()
    local queueSize = net.ReadUInt(8)
    local localIndex = net.ReadUInt(8)
    timer.Simple(0, function()
        CreateQueueUI(queueSize, localIndex)
    end)
end)

net.Receive("RdmtSussyBuffetQueueUpdate", function()
    local activeIndex = net.ReadUInt(8)

    if activeIndex == 0 then
        if IsValid(queuePanel) then
            queuePanel:Remove()
        end
    else
        currentActiveIndex = activeIndex
    end
end)

function EVENT:Begin()
    ClearChoicePanels()
    if IsValid(queuePanel) then
        queuePanel:Remove()
    end
end

function EVENT:End()
    timer.Remove("RdmtSussyBuffet_ClientChoiceTimer")

    ClearChoicePanels()
    if IsValid(queuePanel) then
        queuePanel:Remove()
    end

    queuePanel = nil

    hook.Remove("HUDPaint", "RdmtSussyBuffetInfoHUD")
    infoTextBits = nil

end

Randomat:register(EVENT)