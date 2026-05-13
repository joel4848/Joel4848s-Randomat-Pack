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
local initialDelay = 5
local alivePlayers = alivePlayers or {}
local lastPatternLenth = 0

local countdownEnd = 0
local isCountingDown = false
local wasSuccessful = false
local leftDisplayDormant = true
local rightDisplayDormant = true

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

local function HideHUDForClient()
    if IsValid(StartReactorFrame) then
        StartReactorFrame:SetVisible(false)
    end

    hook.Remove("Think", "RdmtStartReactorTimerUpdate")
    timer.Remove("RdmtStartReactorPlayPattern")
end

local function CountdownBeeps()
    local startBeeps = 0
    local restTime = GetRestTime()
    local timerLength = 0

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

        if panels:GetImage() == "vgui/ttt/startreactor/ssbackground_red.png" then
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
    StartReactorFrame:ShowCloseButton(true)
    StartReactorFrame:SetDeleteOnClose(true)

    -- Have to draw something apparently but then make it alpha 0
    StartReactorFrame.Paint = function(self,w,h)
        draw.RoundedBox(0,4,4,w-8,h-8,Color(0, 0, 0))
    end

    -- Start Reactor UI background image (green)
    panels = vgui.Create("DImage", StartReactorFrame)
    panels:SetSize(width, height)
    panels:SetImage("vgui/ttt/startreactor/ssbackground.png")

    -- Lights
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
                local pitch = pitches[id]
                btn:SetImage("vgui/ttt/startreactor/ssbutton" .. id .. "_blue.png")

                Randomat.Client:EmitSound("startreactor/panel_reactorstart_loud.wav", 100, pitch, 1)

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
    local buttonCellSize = width * 0.105
    disabledbuttons = {}

    for y=1,3 do
        for x=1,3 do
            local id = (y-1)*3 + x

            local btnd = vgui.Create("DImage", StartReactorFrame)
            btnd:SetSize(buttonCellSize*0.95, buttonCellSize*0.95)
            btnd:SetPos((x-1)*buttonCellSize + (width/16.7)*10, (y-1)*buttonCellSize + (height/32)*10)

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

            if panels:GetImage() == "vgui/ttt/startreactor/ssbackgroundd.png" then
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

            if panels:GetImage() == "vgui/ttt/startreactor/ssbackground_red.png" then
                panels:SetImage("vgui/ttt/startreactor/ssbackground.png")
            end

        elseif isCountingDown then
            self:SetText(leftTimerText or "No Timer Text")

            if panels:GetImage() == "vgui/ttt/startreactor/ssbackground.png" then
                panels:SetImage("vgui/ttt/startreactor/ssbackground_red.png")
            end
        elseif wasSuccessful then
            self:SetText(leftTimerText or "CORRECT")

            if panels:GetImage() == "vgui/ttt/startreactor/ssbackground_red.png" then
                panels:SetImage("vgui/ttt/startreactor/ssbackground.png")
            end
        else
            self:SetText("fuck")
        end
    end

    -- Right display
    local displayH = height * 0.1

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
                self:SetText("fuck")
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
    leftLights = {}
end

net.Receive("RdmtStartReactorSuccess", function()
    successfulPlayers = net.ReadTable()
    PrintTable(successfulPlayers)
end)

net.Receive("RdmtStartReactorPattern", function()
    pattern = net.ReadTable()
    local timeToEnter = net.ReadFloat()

    -- if Randomat.Client:Alive() and not Randomat.Client:IsSpec() then
        StartClientCountdown(timeToEnter) 
        PlayPattern()
    -- end
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
end)

net.Receive("RdmtStartReactorDeadAliveChange", function()
    alivePlayers = net.ReadTable()

    if alivePlayers[Randomat.Client:SteamID64()] then
        hook.Remove("HUDPaint", "RdmtStartReactorDrawSuccessfulPlayersHud")
    else
        DisableButtons()

        hook.Add("HUDPaint", "RdmtStartReactorDrawSuccessfulPlayersHud", function()
            local lines = { "Players:" }

            for _, ply in ipairs(successfulPlayers) do
                -- if IsValid(ply) then
                    table.insert(lines, "Test")
                    table.insert(lines, ply:Nick() .. ": " .. tostring(successfulPlayers[ply:SteamID64()]))
                -- end
            end

            local x = ScrW() * 0.02
            local y = ScrH() * 0.35
            local lineH = 28
            local padding = 10

            surface.SetFont("AmogusFont")
            local maxW = 0
            for _, line in ipairs(lines) do
                local w = surface.GetTextSize(line)
                if w > maxW then maxW = w end
            end

            local boxW = maxW + (padding * 2)
            local boxH = (#lines * lineH) + (padding * 2)
            draw.RoundedBox(4, x - padding, y - padding, boxW, boxH, Color(0, 0, 0, 250))

            for i, line in ipairs(lines) do
                draw.SimpleText(line, "AmogusFont", x, y + ((i - 1) * lineH), Color(255, 255, 255, 255))
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
    lastPatternLenth = 0
    countdownEnd = 0
    isCountingDown = false
    wasSuccessful = false
    leftDisplayDormant = true
    rightDisplayDormant = true

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

    hook.Remove("HUDPaint", "RdmtStartReactorDrawEjectionAnnouncement")
    hook.Remove("HUDPaint", "RdmtStartReactorDrawSuccessfulPlayersHud")
    DestroyStartReactorUI()
end

Randomat:register(EVENT)