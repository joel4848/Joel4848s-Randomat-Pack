-- Cached global lookups
local DrawRoundedBox = draw.RoundedBox
local DrawSimpleTextOutlined = draw.SimpleTextOutlined
local HaloAdd                = halo.Add
local MathCeil               = math.ceil
local MathFloor              = math.floor
local MathMax                = math.max
local PlayerIterator         = player.Iterator
local StringFormat           = string.format
local StringUpper            = string.upper
local SurfaceGetTextSize     = surface.GetTextSize
local SurfaceSetFont         = surface.SetFont
local TableInsert            = table.insert

local scrW = ScrW()

local EVENT = {}
EVENT.id = "winnerstayson"

local haloColour = Color(255, 0, 0)

local originalName
local originalNameExt
local originalNamePlural

local function IsCombatant(ply)
    return ply:GetNWBool("RdmtWSOCombatant", false)
end

local function OverrideRoleStrings()
    originalName       = ROLE_STRINGS[ROLE_INNOCENT]
    originalNameExt    = ROLE_STRINGS_EXT[ROLE_INNOCENT]
    originalNamePlural = ROLE_STRINGS_PLURAL[ROLE_INNOCENT]

    ROLE_STRINGS[ROLE_INNOCENT]        = "Challenger"
    ROLE_STRINGS_EXT[ROLE_INNOCENT]    = "a challenger"
    ROLE_STRINGS_PLURAL[ROLE_INNOCENT] = "Challengers"
end

local function RestoreRoleStrings()
    if originalName then
        ROLE_STRINGS[ROLE_INNOCENT] = originalName
        ROLE_STRINGS_EXT[ROLE_INNOCENT] = originalNameExt
        ROLE_STRINGS_PLURAL[ROLE_INNOCENT] = originalNamePlural
    end

    originalName       = nil
    originalNameExt    = nil
    originalNamePlural = nil
end

local defaultColour = Color(0, 255, 255)
local playerColourCache = {}

function EVENT:Begin()
    surface.CreateFont("WSO_names", {
        font      = "Stencil",
        size      = 80,
        weight    = 1000,
        antialias = true
    })

    surface.CreateFont("WSO_vs", {
        font      = "Stencil",
        size      = 60,
        weight    = 1000,
        antialias = true,
        italic    = true
    })

    surface.CreateFont("WSO_timer", {
        font      = "Roboto",
        size      = 30,
        weight    = 700,
        antialias = true,
    })

    OverrideRoleStrings()

    self:AddHook("TTTHUDRoleNameOverride", function(client, text)
        if client:GetRole() ~= ROLE_INNOCENT then return end
        return IsCombatant(client) and "Combatant" or "Challenger"
    end)

    playerColourCache = {}

    local function GetCachedColour(ply)
        if not IsValid(ply) then return defaultColour end

        local sid64 = ply:SteamID64()
        if not playerColourCache[sid64] then
            local playerColourVector = ply:GetNWVector("PlayerColor", Vector(0, 1, 1))

            playerColourCache[sid64] = Color(playerColourVector.x * 255, playerColourVector.y * 255, playerColourVector.z * 255)
        end

        return playerColourCache[sid64]
    end

    local boxBackground = Color(0, 0, 0, 240)

    self:AddHook("HUDPaint", function()
        local player1 = nil
        local player2 = nil

        for _, ply in PlayerIterator() do
            if IsCombatant(ply) then
                if not player1 then
                    player1 = ply
                elseif not player2 then
                    player2 = ply
                end
            end

            if player1 and player2 then break end
        end

        -- This is chaos, but italicising the "vs" ballsed up so much in terms of aligning everything
        local remaining = MathMax(0, MathCeil(GetGlobalFloat("Randomat_WSO_End", 0) - CurTime()))
        local timerText = StringFormat("%02d:%02d until both combatants die", MathFloor(remaining / 60), remaining % 60)

        local p1Nick = player1 and player1:Nick() or ""
        local p2Nick = player2 and player2:Nick() or ""

        local padding = 10

        SurfaceSetFont("WSO_names")
        local p1NickW, p1NickH = SurfaceGetTextSize(p1Nick)
        local p2NickW, p2NickH = SurfaceGetTextSize(p2Nick)
        SurfaceSetFont("WSO_vs")
        local vsW, vsH = SurfaceGetTextSize("vs")

        -- Get the ACTUAL text height, as surface.GetTextSize returns the font size rather than the actual drawn text height
        p1NickH = p1NickH - 30
        p2NickH = p2NickH - 30
        vsH     = vsH - 22

        local p1NickX = (scrW / 2) - ((p2NickW + vsW / 2) / 2)
        local vsX     = p1NickX + p1NickW / 2 + vsW / 2 - 25
        local p2NickX = vsX + p2NickW / 2 + 20

        local p1NickY = (p1NickH / 2) + padding * 2.5
        local vsY     = p1NickY + p1NickH / 2 + vsH / 2 - 10
        local p2NickY = vsY + p2NickH - 20

        SurfaceSetFont("WSO_timer")
        local _, timerH = SurfaceGetTextSize(timerText)
        local timerX = scrW / 2
        local timerY = p2NickY + p2NickH / 2 + padding * 2

        local boxX = p1NickX - p1NickW / 2 - padding
        local boxY = p1NickY - p1NickH / 2 - padding * 1.5
        local boxW = (p2NickX + (p2NickW / 2)) - (p1NickX - (p1NickW / 2)) + padding * 2
        local boxH = p2NickY + p2NickH / 2 + padding * 0.5 + timerH

        if player1 and player2 then
            DrawRoundedBox(5, boxX, boxY, boxW, boxH, boxBackground)
            DrawSimpleTextOutlined(p1Nick, "WSO_names", p1NickX, p1NickY, GetCachedColour(player1), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, COLOR_BLACK)
            DrawSimpleTextOutlined(p2Nick, "WSO_names", p2NickX, p2NickY, GetCachedColour(player2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, COLOR_BLACK)
            DrawSimpleTextOutlined("vs", "WSO_vs", vsX, vsY, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, COLOR_BLACK)
            DrawSimpleTextOutlined(timerText, "WSO_timer", timerX, timerY, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, COLOR_BLACK)
        end
    end)

    self:AddHook("PreDrawHalos", function()
        local client = LocalPlayer()
        if not IsValid(client) or not client:Alive() or client:IsSpec() or not IsCombatant(client) then return end

        local otherCombatant = {}
        for _, ply in PlayerIterator() do
            if ply ~= client and ply:Alive() and not ply:IsSpec() and IsCombatant(ply) then
                TableInsert(otherCombatant, ply)
            end
        end
        if #otherCombatant > 0 then
            HaloAdd(otherCombatant, haloColour, 0, 0, 1, true, true)
        end
    end)

    if CR_VERSION then
        hook.Add("TTTScoringWinTitle", "Randomat_WSO_TTTScoringWinTitle", function(wintype, wintitles, title)
            local winner

            for i, ply in PlayerIterator() do
                if ply:Alive() and not ply:IsSpec() then
                    winner = ply
                end
            end

            if winner then
                LANG.AddToLanguage("english", "win_winnerstayson", StringUpper(winner:Nick() .. " wins!"))
            else
                LANG.AddToLanguage("english", "win_winnerstayson", StringUpper("Mum wins!"))
            end

            local newTitle = {
                txt = "win_winnerstayson",
                c = ROLE_COLORS[ROLE_INNOCENT],
                params = nil
            }

            return newTitle
        end)

        hook.Add("TTTPrepareRound", "Randomat_WSO_TTTPrepareRound", function()
            hook.Remove("TTTScoringWinTitle", "Randomat_WSO_TTTScoringWinTitle")
            hook.Remove("TTTPrepareRound", "Randomat_WSO_TTTPrepareRound")
        end)
    end
end

function EVENT:End()
    playerColourCache = {}
    RestoreRoleStrings()
end

Randomat:register(EVENT)