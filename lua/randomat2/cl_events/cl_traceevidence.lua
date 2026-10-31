-- Cached global lookups
local MathClamp         = math.Clamp
local NetReadEntity     = net.ReadEntity
local NetReadVector     = net.ReadVector
local RenderDrawBeam    = render.DrawBeam
local RenderSetMaterial = render.SetMaterial
local TableInsert       = table.insert
local TableRemove       = table.remove

local EVENT = {}
EVENT.id = "traceevidence"

local tracers = {}
local playerColourCache = {}

local perColoursConVar = CreateConVar("randomat_traceevidence_per_player_colours", 1, FCVAR_NONE, "Whether each player has a unique tracer colour", 0, 1)
local durationConVar   = CreateConVar("randomat_traceevidence_duration", 10, FCVAR_NONE, "How long the tracers show for", 1, 120)

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
        local ply      = NetReadEntity()
        local startPos = NetReadVector()
        local hitPos   = NetReadVector()

        TableInsert(tracers, {
            startTime = CurTime(),
            tr  = {StartPos = startPos, HitPos = hitPos},
            ply = ply
        })
    end)

    self:AddHook("PostDrawOpaqueRenderables", function()
        local duration = durationConVar:GetFloat()

        for i = #tracers, 1, -1 do
            local tracer = tracers[i]
            local timeRemaining = tracer.startTime + duration - CurTime()

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
                local colour = Color(baseColour.r * brightness, baseColour.g * brightness, baseColour.b * brightness)

                RenderSetMaterial(Material("effects/laser1"))
                RenderDrawBeam(tracer.tr.StartPos, tracer.tr.HitPos, 25, 0, 1, colour)
            end
        end
    end)
end

function EVENT:End()
    tracers = {}
    playerColourCache = {}
end

Randomat:register(EVENT)