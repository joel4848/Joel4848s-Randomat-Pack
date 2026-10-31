-- Cached global lookups
local CamEnd3D2D        = cam.End3D2D
local CamStart3D2D      = cam.Start3D2D
local DrawSimpleText    = draw.SimpleText
local MathClamp         = math.Clamp
local NetReadEntity     = net.ReadEntity
local NetReadVector     = net.ReadVector
local RenderDrawBeam    = render.DrawBeam
local RenderSetMaterial = render.SetMaterial
local TableInsert       = table.insert
local TableRemove       = table.remove

local EVENT = {}
EVENT.id = "traceevidence"

local gunWords = {
    "Bam!", "Bang!", "Blam!", "Blammo!", "Boink!", "Bonk!", "Clack!", "Clang!", "Click!", "Clack!",
    "Crack!", "Dakka!", "Fwip!", "Fwop!", "Fwup!", "Kablam!", "Kablammo!", "Kablooey!", "Kapow!",
    "Kerplunk!", "Kerpow!", "Paff!", "Pap!", "Pew!", "Piff!", "Pink!", "Plink!", "Ploink!", "Poff!",
    "Poink!", "Poomf!", "Pop!", "Pow!", "Rat-a-tat!", "Schwack!", "Schwick!", "Smack!", "Snap!",
    "Snip!", "Splat!", "Splot!", "Spoink!", "Thonk!", "Thud!", "Thwack!", "Thwick!", "Thwock!",
    "Thwump!", "Tink!", "Toink!", "Tonk!", "Wham!", "Whump!", "Zap!", "Zing!", "Zowie!"
}

surface.CreateFont("RdmtTraceEvidenceWordFont", {
    font = "Comic Sans MS",
    size = 80,
    weight = 900,
    italic = true
})

local tracers = {}
local playerColourCache = {}

local perColoursConVar = CreateConVar("randomat_traceevidence_per_player_colours", 1, FCVAR_NONE, "Whether each player has a unique tracer colour", 0, 1)
local durationConVar   = CreateConVar("randomat_traceevidence_duration", 10, FCVAR_NONE, "How long the tracers show for", 1, 120)
local wordsConVar      = CreateConVar("randomat_traceevidence_draw_words", 1, FCVAR_NONE, "Whether to draw impact words", 0, 1)

local defaultColour = Color(0, 255, 255)

function EVENT:Begin()
    local fadeTime = 3
    tracers = {}
    playerColourCache = {}

    local function GetCachedBaseColour(ply)
        if not IsValid(ply) then return defaultColour end
        if not perColoursConVar:GetBool() then return defaultColour end

        local sid64 = ply:SteamID64()
        if not playerColourCache[sid64] then
            local playerColour = ply:GetNWVector("PlayerColor", Vector(0, 1, 1))
            local baseColour   = Color(playerColour.x * 255, playerColour.y * 255, playerColour.z * 255)

            playerColourCache[sid64] = baseColour
        end

        return playerColourCache[sid64]
    end

    net.Receive("RandomatTraceEvidence", function()
        local ply        = NetReadEntity()
        local startPos   = NetReadVector()
        local hitPos     = NetReadVector()
        local randomWord = gunWords[math.random(#gunWords)]

        TableInsert(tracers, {
            startTime = CurTime(),
            tr        = {StartPos = startPos, HitPos = hitPos},
            ply       = ply,
            word      = randomWord
        })
    end)

    self:AddHook("PostDrawOpaqueRenderables", function()
        local duration = durationConVar:GetFloat()
        local now      = CurTime()
        local eyeAngle = EyeAngles()

        local drawAngle = Angle(eyeAngle.p, eyeAngle.y, eyeAngle.r)
        drawAngle:RotateAroundAxis(drawAngle:Up(), -90)
        drawAngle:RotateAroundAxis(drawAngle:Forward(), 90)

        for i = #tracers, 1, -1 do
            local tracer        = tracers[i]
            local age           = now - tracer.startTime
            local timeRemaining = tracer.startTime + duration - now

            if timeRemaining <= 0 then
                TableRemove(tracers, i)
            else
                local brightness = 1
                if duration >= fadeTime then
                    if timeRemaining < fadeTime then
                        brightness = MathClamp(timeRemaining / fadeTime, 0, 1)
                    end
                else
                    brightness = MathClamp(timeRemaining / duration, 0, 1)
                end

                local baseColour = GetCachedBaseColour(tracer.ply)
                local colour     = Color(baseColour.r * brightness, baseColour.g * brightness, baseColour.b * brightness)

                RenderSetMaterial(Material("effects/laser1"))
                RenderDrawBeam(tracer.tr.StartPos, tracer.tr.HitPos, 25, 0, 1, colour)

                local wordProgress   = MathClamp(age / 1.0, 0, 1)
                local wordBrightness = 1 - wordProgress
                local driftDistance  = 70 * wordProgress

                local directionToStart = tracer.tr.StartPos - tracer.tr.HitPos
                local distance         = directionToStart:Length()
                directionToStart:Div(distance)

                local textPos = tracer.tr.HitPos + Vector(0, 0, 12) + (directionToStart * driftDistance)

                if wordsConVar:GetBool() then
                    CamStart3D2D(textPos, drawAngle, 0.1)
                        DrawSimpleText(
                            tracer.word,
                            "RdmtTraceEvidenceWordFont",
                            0, 0,
                            Color(255, 255, 255, wordBrightness * 255),
                            TEXT_ALIGN_CENTER,
                            TEXT_ALIGN_CENTER
                        )
                    CamEnd3D2D()
                end
            end
        end
    end)
end

function EVENT:End()
    tracers = {}
    playerColourCache = {}
end

Randomat:register(EVENT)