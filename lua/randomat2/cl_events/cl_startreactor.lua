local EVENT = {}
EVENT.id = "startreactor"

local StartReactorFrame
local panels
local panels_red
local lights = {}
local buttons = {}
local disabledButtons = {}
local leftTimerText = "unchanged"
local rightDisplayText = ""
local pattern = {}
local inputRequired = nil
local sequencePos = nil
local initialDelay = 11
local alivePlayers = alivePlayers or {}
local lastPatternLenth = 0
local showSuccessHUD = showSuccessHUD or false

local countdownEnd = 0
local isCountingDown = false
local wasSuccessful = false
local leftDisplayDormant = true
local rightDisplayDormant = true

local beepText = nil
local startBeeps = nil
local restTime = nil
local timerLength = nil

local scale = 4
local fontSize = 8 * scale
local announcementText = ""
local isShowingAnnouncement = false

local function GetRestTime()
    return GetConVar("randomat_startreactor_rest_time"):GetInt()
end

local function ClientAlive()
    if not IsValid(Randomat.Client) then return false end
    return alivePlayers[Randomat.Client:SteamID64()] or false
end

resource.AddFile("resource/fonts/inyourfacejoffrey.ttf")
surface.CreateFont("AmogusFont", {
	font = "inyourfacejoffrey",
    size = fontSize,
})
surface.CreateFont("AmogusFont_Giant", {
    font = "inyourfacejoffrey",
    size = 60,
    weight = 500,
    additive = false,
    antialias = true
})
surface.CreateFont("AmogusFont_10", {
    font = "inyourfacejoffrey",
    size = 10,
    weight = 500,
    additive = false,
    antialias = true
})
surface.CreateFont("AmogusFont_15", {
    font = "inyourfacejoffrey",
    size = 15,
    weight = 500,
    additive = false,
    antialias = true
})
surface.CreateFont("AmogusFont_25", {
    font = "inyourfacejoffrey",
    size = 25,
    weight = 500,
    additive = false,
    antialias = true
})
surface.CreateFont("AmogusFont_30", {
    font = "inyourfacejoffrey",
    size = 30,
    weight = 500,
    additive = false,
    antialias = true
})
surface.CreateFont("AmogusFont_35", {
    font = "inyourfacejoffrey",
    size = 35,
    weight = 500,
    additive = false,
    antialias = true
})
surface.CreateFont("AmogusFont_40", {
    font = "inyourfacejoffrey",
    size = 40,
    weight = 500,
    additive = false,
    antialias = true
})
surface.CreateFont("AmogusFont_45", {
    font = "inyourfacejoffrey",
    size = 45,
    weight = 500,
    additive = false,
    antialias = true
})
surface.CreateFont("AmogusFont_50", {
    font = "inyourfacejoffrey",
    size = 50,
    weight = 500,
    additive = false,
    antialias = true
})

local function HideHUDForClient()
    if IsValid(StartReactorFrame) then
        StartReactorFrame:SetVisible(false)
    end

    hook.Remove("HUDPaint", "RdmtStartReactorPromptText")
    hook.Remove("Think", "RdmtStartReactorTimerUpdate")
    timer.Remove("RdmtStartReactorPlayPattern")
end

local function CountdownBeeps()
    startBeeps = 0
    restTime = GetRestTime()
    timerLength = 0

    if lastPatternLenth == 0 then
        timerLength = initialDelay - 1
    else
        timerLength = GetRestTime() - 1
    end

    timer.Create("RdmtStartReactorWaitTime", timerLength, 1, function()
    end)

    -- if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
        if #pattern == 0 then
            startBeeps = initialDelay - 4
        else
            restTime = GetRestTime()
            startBeeps = restTime - 4
        end

        if startBeeps > 0 then
            timer.Create("RdmtStartReactorBeeps1Timer", startBeeps, 1, function()
                -- if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
                    Randomat.Client:EmitSound("startreactor/countdown_beep.wav", 100, 100, 1)
                    leftDisplayDormant = false
                    isCountingDown = true
                    wasSuccessful = false
                    beepText = "WAIT: 3"
                -- end
                timer.Create("RdmtStartReactorBeeps2Timer", 1, 1, function()
                    -- if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
                        Randomat.Client:EmitSound("startreactor/countdown_beep.wav", 100, 100, 1)
                        beepText = "WAIT: 2"
                    -- end
                    timer.Create("RdmtStartReactorBeeps3Timer", 1, 1, function()
                        -- if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
                            Randomat.Client:EmitSound("startreactor/countdown_beep.wav", 100, 100, 1)
                            beepText = "WAIT: 1"
                        -- end
                        timer.Create("RdmtStartReactorBeeps4Timer", 1, 1, function()
                            -- if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
                                Randomat.Client:EmitSound("startreactor/countdown_beep_long.wav", 100, 200, 1)
                                beepText = "Go!"
                            -- end
                        end)
                    end)
                end)
            end)
        end
    -- end
end

function StartClientCountdown(timeToEnter)
    countdownEnd = CurTime() + timeToEnter
    local warning1 = timeToEnter - 3
    local warning2 = timeToEnter - 2
    local warning3 = timeToEnter - 1

    leftDisplayDormant = false
    isCountingDown = true
    beepText = nil
    timer.Create("RdmtStartReactorEnterTimer", timeToEnter, 1, function()
        leftDisplayDormant = true
        -- if not wasSuccessful then
        --     HideHUDForClient()
        -- end
        CountdownBeeps()
    end)

    timer.Create("RdmtStartReactorWarning1Timer", warning1, 1, function()
        if not wasSuccessful and Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
            Randomat.Client:EmitSound("startreactor/alarm_sabotage_loud.wav", 100, 100, 1)
        end
    end)

    timer.Create("RdmtStartReactorWarning2Timer", warning2, 1, function()
        if not wasSuccessful and Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
            Randomat.Client:EmitSound("startreactor/alarm_sabotage_loud.wav", 100, 100, 1)
        end
    end)

    timer.Create("RdmtStartReactorWarning3Timer", warning3, 1, function()
        if not wasSuccessful and Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
            Randomat.Client:EmitSound("startreactor/alarm_sabotage_loud.wav", 100, 100, 1)
        end
    end)
end

local function EnableButtons()
    if not (Randomat.Client:Alive() and not Randomat.Client:IsSpec()) then return end

    for _, btn in pairs(buttons) do
        if IsValid(btn) then
            btn:SetVisible(true)
        end
    end
    for _, btnd in pairs(disabledButtons) do
        if IsValid(btnd) then
            btnd:SetVisible(false)
        end
    end
    rightDisplayDormant = false
end

local function DisableButtons()
    for _, btn in pairs(buttons) do
        if IsValid(btn) then
            btn:SetVisible(false)
        end
    end
    for _, btnd in pairs(disabledButtons) do
        if IsValid(btnd) then
            btnd:SetVisible(true)
        end
    end
end

local function StartInput()
    EnableButtons()
    inputRequired = true
    sequencePos = 1
end

local function PlayPattern()
    local length = #pattern
    local patternPosition = 1
    local currentLight = pattern[patternPosition]

    lastPatternLenth = length or 0

    DisableButtons()
    rightDisplayDormant = true

    timer.Create("RdmtStartReactorPlayPattern", 0.4, length, function ()
        currentLight = pattern[patternPosition]
        local pitches = {50, 60, 70, 80, 90, 105, 115, 127, 139}
        local pitch = pitches[currentLight]

        if lights[currentLight] then
            lights[currentLight].lit = true
            Randomat.Client:EmitSound("startreactor/panel_reactorstart_loud.wav", 100, pitch, 1)
        end
        timer.Create("RdmtStartReactorLightsTimer", 0.25, 1, function()
            if lights[currentLight] then
                lights[currentLight].lit = false
            end
            if patternPosition == length + 1 then
                timer.Create("RdmtStartReactorStartInputTimer", 0.7, 1, function()
                    StartInput()
                    rightDisplayDormant = false
                end)
            end
        end)
        patternPosition = patternPosition + 1

    end)
end

local function InputSuccessful()
    isCountingDown = false
    wasSuccessful = true

    DisableButtons()

    net.Start("RdmtStartReactorSuccess")
    net.SendToServer()

    timer.Create("RdmtStartReactorSuccessSoundTimer", 0.2, 1, function()
        Randomat.Client:EmitSound("startreactor/task_complete_loud.wav", 100, pitch, 1)

        if panels:GetImage() and panels:GetImage() == "vgui/ttt/startreactor/ssbackground_red.png" then
            panels:SetImage("vgui/ttt/startreactor/ssbackground.png")
        end
    end)
end

local function InputReceived(btn)
    if btn ~= pattern[sequencePos] then
        Randomat.Client:EmitSound("startreactor/panel_reactor_startfail.wav", 100, 100, 1)
        DisableButtons()

        for id, btnd in pairs(disabledButtons) do
            if IsValid(btnd) then
                btnd:SetImage("vgui/ttt/startreactor/ssbutton" .. id .. "_red.png")
            end
        end

        timer.Create("RdmtStartReactorDarkButtonsTimer", 1, 1, function()
            for id, btnd in pairs(disabledButtons) do
                if IsValid(btnd) then
                    btnd:SetImage("vgui/ttt/startreactor/ssbutton" .. id .. "_dark.png")
                end
            end
        end)

        timer.Create("RdmtStartReactorPlayPatternTimer", 1.6, 1, function()
            PlayPattern()
        end)
    end

    if sequencePos == #pattern and btn == pattern[sequencePos] then
        InputSuccessful()
    end

    sequencePos = sequencePos + 1
end

local function CreateStartReactorUI()
    local scrW, scrH = ScrW(), ScrH()
    local height = 81 * scale
    local width = 143 * scale
    local top = (scrH * 0.75) - (height / 2)
    local left = (scrW / 2) - (width / 2)

    leftDisplayDormant = true
    rightDisplayDormant = true

    -- Daddy frame
    StartReactorFrame = vgui.Create("DFrame")
    StartReactorFrame:SetSize(width, height)
    StartReactorFrame:SetPos(left, top)
    StartReactorFrame:SetTitle("")
    StartReactorFrame:SetDraggable(false)
    StartReactorFrame:ShowCloseButton(false)
    StartReactorFrame:SetDeleteOnClose(true)

    -- Have to draw something apparently but then make it alpha 0
    StartReactorFrame.Paint = function(self,w,h)
        draw.RoundedBox(0,4,4,w-8,h-8,Color(0, 0, 0))
    end

    -- "Hold tab to interact" prompt
    hook.Add("HUDPaint", "RdmtStartReactorPromptText", function()
        local x = ScrW() / 2
        local y = top + height + 15

        local showscores = Key("+showscores", "TAB")
        local promptText = "Hold " .. showscores .. " to interact"
        local promptFont = "TargetID"

        surface.SetFont(promptFont)
        local textW, textH = surface.GetTextSize(promptText)

        local padding = 10
        local boxW = textW + padding
        local boxH = textH + padding / 2
        local boxX = x - boxW / 2
        local boxY = y - boxH / 2

        -- Box
        draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(0, 0, 0, 200))
        -- Shadow
        -- draw.SimpleText(promptText, promptFont, x + 1, y + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Text
        draw.SimpleText(promptText, promptFont, x, y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    -- Start Reactor UI background image (green)
    panels = vgui.Create("DImage", StartReactorFrame)
    panels:SetSize(width, height)
    panels:SetImage("vgui/ttt/startreactor/ssbackground.png")

    -- Lights
    lights = {}
    local lightCellSize = (width * 0.97)/10

    for y=1,3 do
        for x=1,3 do
            local id = (y-1)*3 + x

            local light = vgui.Create("DPanel", StartReactorFrame)
            light:SetSize(lightCellSize*0.9, lightCellSize*0.9)
            light:SetPos((x-1)*lightCellSize + width/9.3, (y-1)*lightCellSize + height/2.95)

            light.lit = nil

            light.Paint = function(self,w,h)
                if self.lit then
                    draw.RoundedBox(2,0,0,w,h,Color(90, 170, 255))
                end
            end

            lights[id] = light
        end
    end

    -- Button grid
    local buttonCellSize = width * 0.105
    buttons = {}

    for y=1,3 do
        for x=1,3 do
            local id = (y-1)*3 + x

            local btn = vgui.Create("DImageButton", StartReactorFrame)

            btn:SetSize(buttonCellSize*0.95, buttonCellSize*0.95)
            btn:SetPos((x-1)*buttonCellSize + (width/16.7)*10, (y-1)*buttonCellSize + (height/32)*10)
            btn:SetText("")
            btn:SetVisible(false)

            btn:SetImage("vgui/ttt/startreactor/ssbutton" .. id .. ".png")

            buttons[id] = btn

            btn.OnDepressed = function(self)
                local pitches = {50, 60, 70, 80, 90, 105, 115, 127, 139}
                local thisPitch = pitches[id]
                btn:SetImage("vgui/ttt/startreactor/ssbutton" .. id .. "_blue.png")

                Randomat.Client:EmitSound("startreactor/panel_reactorstart_loud.wav", 100, thisPitch, 1)

                if inputRequired then
                    InputReceived(id)
                end

            end

            btn.OnReleased = function(self)
                btn:SetImage("vgui/ttt/startreactor/ssbutton" .. id .. ".png")
                if lights[id] then
                    lights[id].lit = false
                end
            end

        end
    end

    -- Disabled 'button' grid
    local disabledButtonCellSize = width * 0.105
    disabledButtons = {}

    for y=1,3 do
        for x=1,3 do
            local id = (y-1)*3 + x

            local btnd = vgui.Create("DImage", StartReactorFrame)
            btnd:SetSize(disabledButtonCellSize*0.95, disabledButtonCellSize*0.95)
            btnd:SetPos((x-1)*disabledButtonCellSize + (width/16.7)*10, (y-1)*disabledButtonCellSize + (height/32)*10)

            btnd:SetImage("vgui/ttt/startreactor/ssbutton" .. id .. "_dark.png")

            disabledButtons[id] = btnd
        end
    end

    -- Left display
    local displayH = height * 0.1

    local leftDisplay = vgui.Create("DLabel", panels)
    leftDisplay:SetSize(width * 0.29, displayH)
    leftDisplay:SetPos(width/9.6, height/6.3)
    leftDisplay:SetFont("AmogusFont")
    leftDisplay:SetContentAlignment(5)
    function leftDisplay:Think()

        if beepText then
            self:SetText(beepText)

            if panels:GetImage() and panels:GetImage() == "vgui/ttt/startreactor/ssbackgroundd.png" then
                panels:SetImage("vgui/ttt/startreactor/ssbackground_red.png")
            end
        elseif leftDisplayDormant then
            if lastPatternLenth == 0 then
                self:SetText("WAIT: " .. math.ceil(timer.TimeLeft("RdmtStartReactorWaitTime")))
            elseif lastPatternLenth > 0 then
                self:SetText("WAIT: " .. math.ceil(timer.TimeLeft("RdmtStartReactorWaitTime")))
            else
                self:SetText("WAIT")
            end

            if panels:GetImage() and panels:GetImage() == "vgui/ttt/startreactor/ssbackground_red.png" then
                panels:SetImage("vgui/ttt/startreactor/ssbackground.png")
            end

        elseif isCountingDown then
            self:SetText(leftTimerText or "No Timer Text")

            if panels:GetImage() and panels:GetImage() == "vgui/ttt/startreactor/ssbackground.png" then
                panels:SetImage("vgui/ttt/startreactor/ssbackground_red.png")
            end
        elseif wasSuccessful then
            self:SetText(leftTimerText or "CORRECT")

            if panels:GetImage() and panels:GetImage() == "vgui/ttt/startreactor/ssbackground_red.png" then
                panels:SetImage("vgui/ttt/startreactor/ssbackground.png")
            end
        else
            self:SetText("404 text not found")
        end
    end

    -- Right display
    -- local displayH = height * 0.1

    local rightDisplay = vgui.Create("DLabel", panels)
    rightDisplay:SetSize(width * 0.29, displayH)
    rightDisplay:SetPos(width/1.64, height/6.3)
    rightDisplay:SetFont("AmogusFont")
    rightDisplay:SetContentAlignment(5)

    function rightDisplay:Think()
        if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
            if leftDisplayDormant then
                self:SetText("WAIT")
            elseif isCountingDown then
                self:SetText("GO")
            elseif wasSuccessful then
                self:SetText("CORRECT")
            elseif beepText then
                self:SetText("WAIT")
            else
                self:SetText("404 text not found")
            end
        else
            self:SetText("You are dead")
        end
    end
end

local function DestroyStartReactorUI()
    if IsValid(StartReactorFrame) then
        StartReactorFrame:Close()
    end

    StartReactorFrame = nil
    Lights = {}

    hook.Remove("HUDPaint", "RdmtStartReactorPromptText")
end

net.Receive("RdmtStartReactorSuccess", function()
    successfulPlayers = net.ReadTable()
end)

net.Receive("RdmtStartReactorPattern", function()
    pattern = net.ReadTable()
    local timeToEnter = net.ReadFloat()

    -- if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
        StartClientCountdown(timeToEnter)
        PlayPattern()
    -- end

    showSuccessHUD = true
end)

net.Receive("RdmtStartReactorEjectionAnnouncement", function()
    local fullString = net.ReadString()
    announcementText = ""
    isShowingAnnouncement = true

    local charIndex = 1

    timer.Create("RdmtStartReactorEjectionTyper", 0.10, #fullString, function()
        announcementText = fullString:sub(1, charIndex)
        charIndex = charIndex + 1
        surface.PlaySound("startreactor/eject_text_loud.wav")

        if charIndex > #fullString then
            timer.Create("RdmtStartReactorAnnouncementTimer", 4, 1, function()
                isShowingAnnouncement = false
            end)
        end
    end)

    showSuccessHUD = false
end)

net.Receive("RdmtStartReactorDeadAliveChange", function()
    alivePlayers = net.ReadTable()

    if alivePlayers[Randomat.Client:SteamID64()] then
        hook.Remove("HUDPaint", "RdmtStartReactorDrawSuccessfulPlayersHud")
    else
        DisableButtons()

        hook.Add("HUDPaint", "RdmtStartReactorDrawSuccessfulPlayersHud", function()
            if showSuccessHUD then
                local titleFont = "AmogusFont_45"
                local rowFont = "AmogusFont_35"
                local lineH = 38
                local padding = 15
                local iconSize = 30
                local columnGap = 20

                local plys = {}
                surface.SetFont(rowFont)
                local maxNameW = 0

                for sid64, isSuccess in pairs(successfulPlayers) do
                    local ply = player.GetBySteamID64(sid64)
                    if IsValid(ply) then
                        local name = ply:Nick()
                        local w, _ = surface.GetTextSize(name)
                        if w > maxNameW then maxNameW = w end

                        table.insert(plys, {
                            name = name,
                            success = isSuccess
                        })
                    end
                end

                -- Box bigness
                surface.SetFont(titleFont)
                local titleW, titleH = surface.GetTextSize("Task Complete:")

                local contentW = math.max(titleW, maxNameW + columnGap + iconSize)
                local boxW = contentW + (padding * 2)
                local boxH = titleH + (#plys * lineH) + (padding * 2)

                -- Location location location
                local x = ScrW() * 0.02
                local y = ScrH() * 0.35

                -- Background Box
                draw.RoundedBox(8, x, y, boxW, boxH, Color(0, 0, 0, 200))

                -- Title
                draw.SimpleText("Task Complete:", titleFont, x + (boxW / 2), y + padding, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

                local startListY = y + padding + titleH + 10

                for i, data in ipairs(plys) do
                    local rowY = startListY + ((i - 1) * lineH)

                    -- Player Names
                    draw.SimpleText(data.name, rowFont, x + padding, rowY, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)

                    -- Icons
                    local ssTick = Material("vgui/ttt/startreactor/sstick.png")
                    local ssCross = Material("vgui/ttt/startreactor/sscross.png")

                    surface.SetDrawColor(255, 255, 255, 255)
                    if data.success then
                        surface.SetMaterial(ssTick)
                    else
                        surface.SetMaterial(ssCross)
                    end

                    surface.DrawTexturedRect(x + boxW - padding - iconSize, rowY + (lineH - iconSize) / 2, iconSize, iconSize)
                end
            end
        end)
    end
end)

function EVENT:Begin()
    -- if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
        CreateStartReactorUI()
        DisableButtons()
        CountdownBeeps()
    -- end

    self:AddHook("Think", function()
        if not isCountingDown then return end
        local timeLeft = math.max(0, countdownEnd - CurTime())

        if timeLeft <= 0 then
            leftTimerText = "00:00:00"
            isCountingDown = false
            return
        end

        local mins = math.floor(timeLeft / 60)
        local secs = math.floor(timeLeft % 60)
        local hundredths = math.floor((timeLeft % 1) * 100)

        leftTimerText = string.format("%02d:%02d:%02d", mins, secs, hundredths)

    end)

    self:AddHook("HUDPaint", function()
        if not isShowingAnnouncement then return end

        local x = ScrW() / 2
        local y = ScrH() / 2

        -- Shadow
        draw.SimpleText(announcementText, "AmogusFont_Giant", x + 4, y + 4, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Text
        draw.SimpleText(announcementText, "AmogusFont_Giant", x, y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)
end

function EVENT:End()
    pattern = {}
    lastPatternLenth = 0
    countdownEnd = 0
    isCountingDown = false
    wasSuccessful = false
    leftDisplayDormant = true
    rightDisplayDormant = true
    startBeeps = nil
    restTime = nil
    timerLength = nil
    beepText = nil
    inputRequired = nil
    sequencePos = nil
    isShowingAnnouncement = false
    announcementText = ""
    showSuccessHUD = false
    successfulPlayers = {}
    lights = {}

    HideHUDForClient()

    timer.Remove("RdmtStartReactorEjectionTyper")
    timer.Remove("RdmtStartReactorBeeps1Timer")
    timer.Remove("RdmtStartReactorBeeps2Timer")
    timer.Remove("RdmtStartReactorBeeps3Timer")
    timer.Remove("RdmtStartReactorBeeps4Timer")
    timer.Remove("RdmtStartReactorEnterTimer")
    timer.Remove("RdmtStartReactorLightsTimer")
    timer.Remove("RdmtStartReactorStartInputTimer")
    timer.Remove("RdmtStartReactorDarkButtonsTimer")
    timer.Remove("RdmtStartReactorPlayPatternTimer")
    timer.Remove("RdmtStartReactorAnnouncementTimer")
    timer.Remove("RdmtStartReactorPlayPattern")
    timer.Remove("RdmtStartReactorWarning1Timer")
    timer.Remove("RdmtStartReactorWarning2Timer")
    timer.Remove("RdmtStartReactorWarning3Timer")
    timer.Remove("RdmtStartReactorWaitTime")
    timer.Remove("RdmtStartReactorSuccessSoundTimer")

    hook.Remove("HUDPaint", "RdmtStartReactorDrawEjectionAnnouncement")
    hook.Remove("HUDPaint", "RdmtStartReactorDrawSuccessfulPlayersHud")
    hook.Remove("HUDPaint", "RdmtStartReactorPromptText")
    DestroyStartReactorUI()
end

Randomat:register(EVENT)