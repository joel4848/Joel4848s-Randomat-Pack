local math = math
local hook = hook

local MathRand = math.Rand
local MathSin = math.sin
local MathCos = math.cos
local MathMax = math.max
local MathPi = math.pi

local EVENT = {}

EVENT.id = "speedracer"

local client
local radiusVelocity = Vector(0, 0, 80)

local function DrawRadius(pos, radius)
    if not client.SpeedracerRadiusEmitter then client.SpeedracerRadiusEmitter = ParticleEmitter(pos) end
    if not client.SpeedracerRadiusNextPart then client.SpeedracerRadiusNextPart = CurTime() end
    if not client.SpeedracerRadiusDir then client.SpeedracerRadiusDir = 0 end

    pos = pos + Vector(0, 0, 30)
    local radiusSqr = radius * radius

    if client.SpeedracerRadiusNextPart < CurTime() and client:GetPos():DistToSqr(pos) <= 9000000 then
        for _ = 1, 24 do
            client.SpeedracerRadiusEmitter:SetPos(pos)
            client.SpeedracerRadiusNextPart = CurTime() + 0.02
            client.SpeedracerRadiusDir = client.SpeedracerRadiusDir + MathPi / 12

            local vec = Vector(MathSin(client.SpeedracerRadiusDir) * radius, MathCos(client.SpeedracerRadiusDir) * radius, 10)
            local particle = client.SpeedracerRadiusEmitter:Add("particle/wisp.vmt", pos + vec)

            particle:SetVelocity(radiusVelocity)
            particle:SetDieTime(0.5)
            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)
            particle:SetStartSize(3)
            particle:SetEndSize(2)
            particle:SetRoll(MathRand(0, MathPi))
            particle:SetRollDelta(0)

            local color = ROLE_COLORS and ROLE_COLORS[ROLE_TRAITOR] or Color(255, 0, 0)
            if pos:DistToSqr(client:GetPos()) <= radiusSqr then
                color = ROLE_COLORS and ROLE_COLORS[ROLE_INNOCENT] or Color(0, 255, 0)
            end
            particle:SetColor(color.r, color.g, color.b)
        end
        client.SpeedracerRadiusDir = client.SpeedracerRadiusDir + 0.02
    end
end

local function RemoveRadius()
    if client and client.SpeedracerRadiusEmitter then
        client.SpeedracerRadiusEmitter:Finish()
        client.SpeedracerRadiusEmitter = nil
        client.SpeedracerRadiusDir = nil
        client.SpeedracerRadiusNextPart = nil
    end
end

local function DrawLink(pos)
    if not client.SpeedracerLinkEmitter then client.SpeedracerLinkEmitter = ParticleEmitter(client:GetPos()) end
    if not client.SpeedracerLinkNextPart then client.SpeedracerLinkNextPart = CurTime() end
    if not client.SpeedracerLinkOffset then client.SpeedracerLinkOffset = 0 end

    local startPos = client:GetPos() + Vector(0, 0, 30)
    local endPos = pos + Vector(0, 0, 30)
    local dir = endPos - startPos
    dir = dir:GetNormalized() * 50

    if client.SpeedracerLinkNextPart < CurTime() then
        local linkPos = startPos + (dir * client.SpeedracerLinkOffset)
        while startPos:DistToSqr(linkPos) <= 9000000 and startPos:DistToSqr(linkPos) <= startPos:DistToSqr(endPos) do
            client.SpeedracerLinkEmitter:SetPos(linkPos)
            client.SpeedracerLinkNextPart = CurTime() + 0.02

            local particle = client.SpeedracerLinkEmitter:Add("particle/wisp.vmt", linkPos)
            particle:SetVelocity(vector_origin)
            particle:SetDieTime(0.25)
            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)
            particle:SetStartSize(3)
            particle:SetEndSize(2)
            particle:SetRoll(MathRand(0, MathPi))
            particle:SetRollDelta(0)

            local color = ROLE_COLORS and ROLE_COLORS[ROLE_TRAITOR] or Color(255, 0, 0)
            particle:SetColor(color.r, color.g, color.b)
            linkPos:Add(dir)
        end
        client.SpeedracerLinkOffset = client.SpeedracerLinkOffset + 0.04
        if client.SpeedracerLinkOffset > 1 then
            client.SpeedracerLinkOffset = 0
        end
    end
end

local function RemoveLink()
    if client and client.SpeedracerLinkEmitter then
        client.SpeedracerLinkEmitter:Finish()
        client.SpeedracerLinkEmitter = nil
        client.SpeedracerLinkNextPart = nil
        client.SpeedracerLinkOffset = nil
    end
end

local function TargetCleanup()
    RemoveRadius()
    RemoveLink()
end

local function Speedracer_Think()
    if not IsPlayer(client) then client = LocalPlayer() end
    if not IsValid(client) or client:IsSpec() then return end

    if GetGlobalBool("SpeedracerActive", false) then
        local targetPos = GetGlobalVector("SpeedracerTarget")
        local distance = GetConVar("randomat_speedracer_distance"):GetFloat() * (UNITS_PER_METER or 39.37)
        local distanceSquared = distance * distance

        DrawRadius(targetPos, distance)
        if client:GetPos():DistToSqr(targetPos) > distanceSquared then
            DrawLink(targetPos)
        end
    else
        TargetCleanup()
    end
end

local function Speedracer_HUDPaint()
    if not IsPlayer(client) then client = LocalPlayer() end
    if not IsValid(client) or client:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end
    if not GetGlobalBool("SpeedracerActive", false) then return end

    local endTime = GetGlobalFloat("SpeedracerEnd", 0)
    local remaining = MathMax(0, endTime - CurTime())
    if remaining <= 0 then return end

    local x = ScrW() / 2.0
    local y = ScrH() / 2.0
    y = y + (y / 3)
    local w = 300

    local maxTime = GetConVar("randomat_speedracer_timer"):GetInt()
    if remaining > maxTime then maxTime = GetConVar("randomat_speedracer_timer_initial"):GetInt() end
    local progress = 1 - (remaining / maxTime)

    local message = "TIME REMAINING: " .. util.SimpleTime(remaining, "%02i:%02i")

    local targetPos = GetGlobalVector("SpeedracerTarget")
    local distance = 6 * (UNITS_PER_METER or 39.37)
    local distanceSquared = distance * distance
    local color = ROLE_COLORS and ROLE_COLORS[ROLE_TRAITOR] or Color(255, 0, 0)

    if targetPos:DistToSqr(client:GetPos()) <= distanceSquared then
        color = ROLE_COLORS and ROLE_COLORS[ROLE_INNOCENT] or Color(0, 255, 0)
    end

    if CRHUD and CRHUD.PaintProgressBar then
        CRHUD:PaintProgressBar(x, y, w, color, message, progress)
    else
        -- Fallback if standard custom roles HUD isn't available
        draw.RoundedBox(8, x - w/2, y, w, 25, Color(0,0,0,150))
        draw.RoundedBox(8, x - w/2 + 2, y + 2, (w - 4) * progress, 21, color)
        draw.SimpleText(message, "HealthAmmo", x, y + 12, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function EVENT:Begin()
    hook.Add("Think", "Randomat_Speedracer_Think", Speedracer_Think)
    hook.Add("HUDPaint", "Randomat_Speedracer_HUDPaint", Speedracer_HUDPaint)
end

function EVENT:End()
    hook.Remove("Think", "Randomat_Speedracer_Think")
    hook.Remove("HUDPaint", "Randomat_Speedracer_HUDPaint")
    TargetCleanup()
end

Randomat:register(EVENT)