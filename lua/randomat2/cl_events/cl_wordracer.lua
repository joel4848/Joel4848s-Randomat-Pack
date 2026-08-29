local EVENT = {}

EVENT.id = "wordracer"

local validGuesses = {}

local SCALE_FACTOR = 0.85

-- Colours
local COLOUR_BG                 = Color(18, 18, 19, 252)
local COLOUR_ABSENT             = Color(58, 58, 60)
local COLOUR_BORDER_EMPTY       = Color(58, 58, 60)
local COLOUR_BORDER_FILLED      = Color(86, 87, 88)
local COLOUR_TEXT               = Color(255, 255, 255)
local COLOUR_KEY_UNUSED         = Color(129, 131, 132)
local COLOUR_PRESENT            = Color(181, 159, 59)
local COLOUR_CORRECT            = Color(83, 141, 78)
local COLOUR_TIMER_WHITE        = Color(255, 255, 255)
local COLOUR_TIMER_AMBER        = Color(255, 180, 0)
local COLOUR_TIMER_RED          = Color(230, 50, 50)
local COLOUR_ERROR_MESSAGE_BG   = Color(255, 255, 255)
local COLOUR_ERROR_MESSAGE_TEXT = Color(0, 0, 0)

WordRacerFrame = WordRacerFrame or nil
if IsValid(WordRacerFrame) then WordRacerFrame:Remove() end
local currentAnswer = ""
local timeLimit = 60
local startTime = 0
local isFinished = false
local finalResult = false
local frozenTime = 0

-- Evaluate guesses
local function EvaluateGuess(guess, target)
    local result = {"absent", "absent", "absent", "absent", "absent"}
    local targetChars = {}

    for i = 1, 5 do
        targetChars[i] = string.sub(target, i, i)
    end

    -- Find correct letters in correct place
    for i = 1, 5 do
        local gChar = string.sub(guess, i, i)
        if gChar == targetChars[i] then
            result[i] = "correct"
            targetChars[i] = nil
        end
    end

    -- Find correct letters in wrong place
    for i = 1, 5 do
        if result[i] ~= "correct" then
            local gChar = string.sub(guess, i, i)
            for j = 1, 5 do
                if targetChars[j] and targetChars[j] == gChar then
                    result[i] = "present"
                    targetChars[j] = nil
                    break
                end
            end
        end
    end

    net.Start("rdmtWordRacer_GuessUpdate")
        net.WriteTable(result)
    net.SendToServer()

    return result
end

-- Create UI
local function CreateWordRacerUI()
    if IsValid(WordRacerFrame) then WordRacerFrame:Remove() end

    local scale = math.Clamp(SCALE_FACTOR, 0.5, 1.5)

    local tileSize = math.Round(ScrH() * 0.052 * scale)
    local tileMargin = math.Round(tileSize * 0.1)
    local gridWidth = (tileSize * 5) + (tileMargin * 4)
    local gridHeight = (tileSize * 6) + (tileMargin * 5)

    local keyH = math.Round(ScrH() * 0.042 * scale)
    local baseKeyW = math.Round(keyH * 0.8)
    local keyGap = math.Round(keyH * 0.12)
    local row1Width = (11 * baseKeyW) + (9 * keyGap)
    local keyboardWidth = row1Width
    local keyboardHeight = (3 * keyH) + (2 * keyGap)

    local hintH = math.Round(ScrH() * 0.02 * scale)
    local timerH = math.Round(ScrH() * 0.045 * scale)
    local sectionSpacing = math.Round(ScrH() * 0.012 * scale)
    local padding = math.Round(ScrH() * 0.015 * scale)

    local frameW = math.max(gridWidth, keyboardWidth) + (padding * 2)

    local hintY = padding
    local timerY = hintY + hintH + sectionSpacing
    local gridY = timerY + timerH + sectionSpacing
    local keyboardY = gridY + gridHeight + sectionSpacing

    local frameH = keyboardY + keyboardHeight + padding

    local gridX = (frameW - gridWidth) / 2
    local keyboardX = (frameW - keyboardWidth) / 2

    local guesses = {}
    local evaluationResults = {}
    local keyStates = {}
    local currentRow = 1
    local currentColumn = 1

    local shakestartTime = 0
    local shakeDuration = 0.4
    local shakeRow = 0
    local errorMessage = nil
    local errorMessageExpiry = 0

    local function TriggerError(msg)
        if msg ~= "Success!" then
            shakestartTime = CurTime()
            shakeRow = currentRow
        end

        errorMessage = msg
        errorMessageExpiry = msg == "Success!" and CurTime() + 3 or CurTime() + 1.5
    end

    for row = 1, 6 do
        guesses[row] = {}
        evaluationResults[row] = nil
        for column = 1, 5 do
            guesses[row][column] = ""
        end
    end

    -- Daddy frame
    WordRacerFrame = vgui.Create("DFrame")
    WordRacerFrame:SetSize(frameW, frameH)
    WordRacerFrame:SetPos(ScrW() - frameW - 20, (ScrH() - frameH) / 2)
    WordRacerFrame:SetTitle("")
    WordRacerFrame:ShowCloseButton(false)
    WordRacerFrame:SetDraggable(false)
    WordRacerFrame:SetKeyboardInputEnabled(false)

    -- Fonts
    surface.CreateFont("WordRacer_Tile", {
        font = "Tahoma",
        size = math.Round(tileSize * 0.65),
        weight = 800
    })
    surface.CreateFont("WordRacer_Key", {
        font = "Tahoma",
        size = math.Round(keyH * 0.75),
        weight = 700
    })
    surface.CreateFont("WordRacer_Key_Enter", {
        font = "Tahoma",
        size = math.Round(keyH * 0.5),
        weight = 700
    })
    surface.CreateFont("WordRacer_Key_Back", {
        font = "Tahoma",
        size = math.Round(keyH),
        weight = 700
    })
    surface.CreateFont("WordRacer_Timer", {
        font = "Tahoma",
        size = math.Round(timerH * 0.85),
        weight = 800
    })
    surface.CreateFont("WordRacer_Hint", {
        font = "Tahoma",
        size = math.Round(hintH * 0.85),
        weight = 600
    })
    surface.CreateFont("WordRacer_Error", {
        font = "Tahoma",
        size = math.Round(tileSize * 0.6),
        weight = 800
    })

    WordRacerFrame.Paint = function(s, w, h)
        -- Background
        draw.RoundedBox(8, 0, 0, w, h, COLOUR_BG)

        -- Interact button hint
        local keyName = string.upper(input.GetKeyName(input.GetKeyCode(input.LookupBinding("+showscores") or "KEY_TAB")) or "TAB")
        draw.SimpleText("Hold " .. keyName .. " to interact", "WordRacer_Hint", w / 2, hintY, COLOUR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Timer display
        local timeRemaining = timeLimit
        if timeLimit > 0 then
            local elapsed = isFinished and (frozenTime - startTime) or (CurTime() - startTime)
            timeRemaining = math.max(0, timeLimit - elapsed)

            if not isFinished and timeRemaining <= 0 then
                isFinished = true
                finalResult = false
                net.Start("rdmtWordRacer_Success")
                    net.WriteBool(false)
                net.SendToServer()

                if IsValid(WordRacerFrame) then
                    WordRacerFrame:Remove()
                    WordRacerFrame = nil
                end
            end
        end

        -- Timer text & colour
        local timerText = ""
        local timerColour = COLOUR_TIMER_WHITE

        local mins   = math.floor(timeRemaining / 60)
        local secs   = math.floor(timeRemaining % 60)
        local millis = math.floor((timeRemaining % 1) * 100)

        if isFinished then
            timerColour = finalResult and COLOUR_CORRECT or COLOUR_TIMER_RED
            timerText   = string.format("%02d:%02d:%02d", mins, secs, millis)
        elseif timeLimit > 0 then
            if timeRemaining <= 10 then
                timerColour = COLOUR_TIMER_RED
            elseif timeRemaining <= 30 then
                timerColour = COLOUR_TIMER_AMBER
            end

            timerText = string.format("%02d:%02d:%02d", mins, secs, millis)
        elseif timeLimit == 0 then
            timerText = "∞"
            timerColour = COLOUR_CORRECT
        end

        draw.SimpleText(timerText, "WordRacer_Timer", w / 2, timerY, timerColour, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Guess box grid
        for row = 1, 6 do
            -- Guess box error shake bits
            local rowOffsetX = 0
            if row == shakeRow and CurTime() < (shakestartTime + shakeDuration) then
                local progress = (CurTime() - shakestartTime) / shakeDuration
                rowOffsetX = math.sin((CurTime() - shakestartTime) * 40) * (8 * (1 - progress))
            end

            for column = 1, 5 do
                local x = gridX + (column - 1) * (tileSize + tileMargin) + rowOffsetX
                local y = gridY + (row - 1) * (tileSize + tileMargin)

                local letter = guesses[row][column]
                local tileBg = COLOUR_BG
                local borderColour = (letter == "") and COLOUR_BORDER_EMPTY or COLOUR_BORDER_FILLED

                if evaluationResults[row] then
                    local status = evaluationResults[row][column]
                    if status == "correct" then
                        tileBg = COLOUR_CORRECT
                        borderColour = COLOUR_CORRECT
                    elseif status == "present" then
                        tileBg = COLOUR_PRESENT
                        borderColour = COLOUR_PRESENT
                    else
                        tileBg = COLOUR_ABSENT
                        borderColour = COLOUR_ABSENT
                    end
                end

                draw.RoundedBox(4, x, y, tileSize, tileSize, borderColour)
                draw.RoundedBox(4, x + 2, y + 2, tileSize - 4, tileSize - 4, tileBg)

                if letter ~= "" then
                    draw.SimpleText(string.upper(letter), "WordRacer_Tile", x + tileSize / 2, y + tileSize / 2, COLOUR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end

        -- Error message
        if errorMessage and CurTime() < errorMessageExpiry then
            surface.SetFont("WordRacer_Error")
            local textW, textH = surface.GetTextSize(errorMessage)
            local errorMessageW = textW + 20
            local errorMessageH = textH + 10
            local errorMessageX = (w - errorMessageW) / 2
            local errorMessageY = gridY - errorMessageH / 2

            draw.RoundedBox(6, errorMessageX, errorMessageY, errorMessageW, errorMessageH, COLOUR_ERROR_MESSAGE_BG)
            draw.SimpleText(errorMessage, "WordRacer_Error", w / 2, errorMessageY + errorMessageH / 2, COLOUR_ERROR_MESSAGE_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Keyboard clicky bits
    local function InputLetter(char)
        if isFinished or currentRow > 6 or currentColumn > 5 then return end
        guesses[currentRow][currentColumn] = string.lower(char)
        currentColumn = currentColumn + 1
    end

    local function InputBackspace()
        if isFinished or currentRow > 6 or currentColumn <= 1 then return end
        currentColumn = currentColumn - 1
        guesses[currentRow][currentColumn] = ""
    end

    local function InputEnter()
        if isFinished or currentRow > 6 then return end

        if currentColumn <= 5 then
            TriggerError("Not enough letters")
            return
        end

        local word = table.concat(guesses[currentRow], "")
        if not validGuesses[word] then
            TriggerError("Not in word list")
            return
        end

        local eval = EvaluateGuess(word, currentAnswer)
        evaluationResults[currentRow] = eval

        -- Update keyboard colours
        for i = 1, 5 do
            local l = string.sub(word, i, i)
            local st = eval[i]
            if st == "correct" then
                keyStates[l] = COLOUR_CORRECT
            elseif st == "present" and keyStates[l] ~= COLOUR_CORRECT then
                keyStates[l] = COLOUR_PRESENT
            elseif st == "absent" and not keyStates[l] then
                keyStates[l] = COLOUR_ABSENT
            end
        end

        if word == currentAnswer then
            TriggerError("Success!")
            isFinished = true
            finalResult = true
            frozenTime = CurTime()
            net.Start("rdmtWordRacer_Success")
                net.WriteBool(true)
            net.SendToServer()
        else
            currentRow = currentRow + 1
            currentColumn = 1
            if currentRow > 6 then
                isFinished = true
                finalResult = false
                frozenTime = CurTime()
                net.Start("rdmtWordRacer_Success")
                    net.WriteBool(false)
                net.SendToServer()

                if IsValid(WordRacerFrame) then
                    WordRacerFrame:Remove()
                    WordRacerFrame = nil
                end
            end
        end
    end

    -- Keyboard buttons
    local keyboardPanel = vgui.Create("DPanel", WordRacerFrame)
    keyboardPanel:SetPos(keyboardX, keyboardY)
    keyboardPanel:SetSize(keyboardWidth, keyboardHeight)
    keyboardPanel.Paint = function() end

    local keyRows = {
        {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p"},
        {"a", "s", "d", "f", "g", "h", "j", "k", "l"},
        {"ENTER", "z", "x", "c", "v", "b", "n", "m", "BACK"}
    }

    for rowIndex, rowKeys in ipairs(keyRows) do
        local rowY = (rowIndex - 1) * (keyH + keyGap)

        local rowWidth = 0
        for _, k in ipairs(rowKeys) do
            local w = (k == "ENTER" or k == "BACK") and (baseKeyW * 2) or baseKeyW
            rowWidth = rowWidth + w
        end
        rowWidth = rowWidth + (#rowKeys - 1) * keyGap

        local currentX = (keyboardWidth - rowWidth) / 2

        for _, key in ipairs(rowKeys) do
            local keyW = (key == "ENTER" or key == "BACK") and (baseKeyW * 2) or baseKeyW
            local btn = vgui.Create("DButton", keyboardPanel)
            btn:SetPos(currentX, rowY)
            btn:SetSize(keyW, keyH)
            btn:SetText("")

            btn.Paint = function(s, w, h)
                local btnColour = keyStates[key] or COLOUR_KEY_UNUSED
                draw.RoundedBox(4, 0, 0, w, h, btnColour)

                local label    = key == "BACK" and "⌫" or string.upper(key)
                local keyFont  = key == "ENTER" and "WordRacer_Key_Enter" or key == "BACK" and "WordRacer_Key_Back" or "WordRacer_Key"
                local keyTextX = key == "ENTER" and w / 2 + 1 or key == "BACK" and w / 2 - 1 or w / 2
                local keyTextY = key == "BACK" and h / 2 - 3 or h / 2

                draw.SimpleText(label, keyFont, keyTextX, keyTextY, COLOUR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            btn.DoClick = function()
                if key == "ENTER" then
                    InputEnter()
                elseif key == "BACK" then
                    InputBackspace()
                else
                    InputLetter(key)
                end
            end

            btn.DoDoubleClick = btn.DoClick

            currentX = currentX + keyW + keyGap
        end
    end

    WordRacerFrame.Think = function(s)
        local ply = LocalPlayer()
        local isSpectator = not IsValid(ply) or not ply:Alive() or ply:IsSpec()

        if isSpectator then
            s:Remove()
            WordRacerFrame = nil
            return
        end

        local scorePressed = input.IsKeyDown(input.GetKeyCode(input.LookupBinding("+showscores") or "KEY_TAB"))
        if scorePressed and not s:IsKeyboardInputEnabled() then
            s:SetKeyboardInputEnabled(true)
        elseif not scorePressed and s:IsKeyboardInputEnabled() then
            s:SetKeyboardInputEnabled(false)
        end
    end

    WordRacerFrame.OnKeyCodePressed = function(s, code)
        if isFinished then return end
        if code >= KEY_A and code <= KEY_Z then
            local char = string.char(code - KEY_A + string.byte("a"))
            InputLetter(char)
        elseif code == KEY_BACKSPACE then
            InputBackspace()
        elseif code == KEY_ENTER or code == KEY_PAD_ENTER then
            InputEnter()
        end
    end
end

net.Receive("rdmtWordRacer_Answer", function()
    currentAnswer = net.ReadString()
    timeLimit = net.ReadInt(16)
    startTime = CurTime()
    isFinished = false
    finalResult = false

    CreateWordRacerUI()
end)

local TEST_INCLUDE_LOCAL = true
WordRacerProgressFrame = WordRacerProgressFrame or nil
if IsValid(WordRacerProgressFrame) then WordRacerProgressFrame:Remove() end

local activePlayers = {}

function UpdatePlayerGuesses(guesses, showAll)
    local showEveryone = showAll or false

    local AVATAR_SIZE = 58
    local BOX_SIZE    = 26
    local BOX_GAP     = 4

    surface.CreateFont("WordRacer_ProgressNickname", {
        font = "Tahoma",
        size = 24,
        weight = 600
    })

    local ply = LocalPlayer()
    local isSpectator = not ply:Alive() or (ply.IsSpec and ply:IsSpec()) or (ply.Team and ply:Team() == TEAM_SPEC)

    if not showEveryone and not isSpectator then
        if IsValid(WordRacerProgressFrame) then WordRacerProgressFrame:Remove() end
        return
    end

    surface.SetFont("WordRacer_ProgressNickname")
    local maxWidth = 5 * BOX_SIZE + 4 * BOX_GAP
    local playerCount = 0

    for _, p in player.Iterator() do
        if p == LocalPlayer() and not TEST_INCLUDE_LOCAL then continue end

        if not p:Alive() and not guesses[p] and activePlayers[p] ~= true then continue end

        activePlayers[p] = true
        playerCount = playerCount + 1

        local textW, _ = surface.GetTextSize(p:Nick())
        if textW > maxWidth then
            maxWidth = textW
        end
    end

    if playerCount == 0 then
        if IsValid(WordRacerProgressFrame) then WordRacerProgressFrame:Remove() end
        return
    end

    local frameW = AVATAR_SIZE + 20 + maxWidth + 20
    local frameH = math.min(playerCount * (AVATAR_SIZE + 10) + 10, ScrH() * 0.8)

    local frameY = (ScrH() - frameH) / 2

    if not IsValid(WordRacerProgressFrame) then
        WordRacerProgressFrame = vgui.Create("DPanel")
        WordRacerProgressFrame.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, COLOUR_BG)
        end

        WordRacerProgressFrame.Scroll = vgui.Create("DScrollPanel", WordRacerProgressFrame)
        WordRacerProgressFrame.Scroll:Dock(FILL)
        WordRacerProgressFrame.Scroll:DockMargin(10, 10, 10, 10)

        WordRacerProgressFrame.PlayerRows = {}
    end

    WordRacerProgressFrame:SetSize(frameW, frameH)
    WordRacerProgressFrame:SetPos(20, frameY)

    WordRacerProgressFrame.LatestGuesses = guesses

    local pRows = WordRacerProgressFrame.PlayerRows

    for p, _ in pairs(activePlayers) do
        if not IsValid(pRows[p]) then
            local row = vgui.Create("DPanel", WordRacerProgressFrame.Scroll)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 10)
            row:SetHeight(AVATAR_SIZE)
            row.Paint = function() end

            local avatar = vgui.Create("AvatarImage", row)
            avatar:SetSize(AVATAR_SIZE, AVATAR_SIZE)
            avatar:SetPos(0, 0)
            avatar:SetPlayer(p, AVATAR_SIZE)

            local _, nameHeight = surface.GetTextSize(p:Nick())
            local inRowPadding  = (AVATAR_SIZE - nameHeight - BOX_SIZE) / 3
            local nameLabelY    = inRowPadding
            local boxesY        = nameHeight + 2 * inRowPadding

            local nameLabel = vgui.Create("DLabel", row)
            nameLabel:SetPos(AVATAR_SIZE + 10, nameLabelY)
            nameLabel:SetSize(maxWidth, nameHeight)
            nameLabel:SetFont("WordRacer_ProgressNickname")
            nameLabel:SetText(p:Nick())
            nameLabel:SetTextColor(COLOUR_TEXT)

            local boxContainer = vgui.Create("DPanel", row)
            boxContainer:SetPos(AVATAR_SIZE + 10, boxesY)
            boxContainer:SetSize(AVATAR_SIZE + 5 * BOX_SIZE + 4 * BOX_GAP, BOX_SIZE + BOX_GAP)
            boxContainer.Paint = function(s, w, h)
                local pGuess = WordRacerProgressFrame.LatestGuesses[p]

                for i = 1, 5 do
                    local bx = (i - 1) * (BOX_SIZE + BOX_GAP)
                    local status = pGuess and pGuess[i] or nil
                    local color = color_black

                    if status == "correct" then color = COLOUR_CORRECT
                    elseif status == "present" then color = COLOUR_PRESENT
                    elseif status == "absent" then color = COLOUR_ABSENT
                    end

                    draw.RoundedBox(2, bx, 0, BOX_SIZE, BOX_SIZE, COLOUR_BORDER_FILLED)
                    draw.RoundedBox(2, bx + 1, 1, BOX_SIZE - 2, BOX_SIZE - 2, color)
                end
            end

            pRows[p] = row
        end
    end

    for p, row in pairs(pRows) do
        if not activePlayers[p] then
            if IsValid(row) then row:Remove() end
            pRows[p] = nil
        end
    end
end

local receivedGuesses = {}

net.Receive("rdmtWordRacer_GuessUpdate", function()
    receivedGuesses = net.ReadTable()
    local showAll   = net.ReadBool()
    UpdatePlayerGuesses(receivedGuesses, showAll)
end)

function EVENT:Begin()
    for _, word in ipairs(WordRacer.answerWords) do validGuesses[word] = true end
    for _, word in ipairs(WordRacer.guessOnlyWords) do validGuesses[word] = true end
end

function EVENT:End()
    receivedGuesses = {}
    activePlayers   = {}

    if IsValid(WordRacerFrame) then
        WordRacerFrame:Remove()
        WordRacerFrame = nil
    end

    if IsValid(WordRacerProgressFrame) then
        WordRacerProgressFrame:Remove()
        WordRacerProgressFrame = nil
    end
end

Randomat:register(EVENT)