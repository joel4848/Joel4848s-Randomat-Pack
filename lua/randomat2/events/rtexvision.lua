local EVENT = {}

CreateConVar("randomat_rtexvision_attackRevealTime", 1, FCVAR_NONE, "Vision time after attacking", 0.1, 30)
CreateConVar("randomat_rtexvision_moveRevealTime", 1, FCVAR_NONE, "Vision time after stopping moving", 0.1, 30)

EVENT.Title = "R-Tex Vision"
EVENT.Description = "Your vision is now based on YOUR movement"
EVENT.id = "rtexvision"
EVENT.Categories = {"biased", "moderateimpact"}

local MathAbs = math.abs
local MathRound = math.Round

local attackState = {}

local function IsTooSlow(crouching, prone, vel)
    local min = 100
    if prone then min = 35
    elseif crouching then min = 40 end
    return MathRound(MathAbs(vel)) < min
end

local function SetVision(ply, state)
    ply:SetNWBool("RdmtRTexVisionActive", state)
end

local function RefreshVisionTimer(ply, time, suffix)
    timer.Create("RdmtRTexVision_" .. suffix .. "_" .. ply:SteamID64(),
        time, 1, function()
            if IsValid(ply) then
                SetVision(ply, false)
            end
        end)
end

function EVENT:Begin()

    for _, ply in ipairs(self:GetAlivePlayers()) do
        SetVision(ply, false)
    end
    
    self:AddHook("PlayerSpawn", function(ply)
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end
        SetVision(ply, false)
    end)
    
    -- Players given vision back when they die
    self:AddHook("PlayerDeath", function(victim)
        if IsValid(victim) then
            SetVision(victim, true)
        end
    end)
    
    -- Detect movement
    self:AddHook("FinishMove", function(ply, mv)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end

        local crouching = ply:Crouching()
        local prone = ply.IsProne and ply:IsProne()
        local vel = mv:GetVelocity()
        local in_vehicle, parent = Randomat:IsPlayerInVehicle(ply)
        if in_vehicle then
            vel = parent:GetVelocity()
            crouching = false
            prone = false
        end
        
        local moving =
            not IsTooSlow(crouching, prone, vel.x) or
            not IsTooSlow(crouching, prone, vel.y) or
            not IsTooSlow(crouching, prone, vel.z)
        
        if moving then
            SetVision(ply, true)
            local moveDelay = GetConVar("randomat_rtexvision_moveRevealTime"):GetFloat()
            if moveDelay > 0 then
                RefreshVisionTimer(ply, moveDelay, "Move")
            end
        end
        
        -- Bodged continuous attack detection in here because I'm no longer using EntityFireBullets
        -- Please don't judge me
        local attackHeld = ply:KeyDown(IN_ATTACK)
        local attackDelay = GetConVar("randomat_rtexvision_attackRevealTime"):GetFloat()
        local wasAttacking = attackState[ply] or false
        
        if attackHeld then
            SetVision(ply, true)
            timer.Remove("RdmtRTexVision_Attack_" .. ply:SteamID64())
            attackState[ply] = true
        else
            if wasAttacking and attackDelay > 0 then
                RefreshVisionTimer(ply, attackDelay, "Attack")
            end
            attackState[ply] = false
        end
    end)
end

function EVENT:End()
    for _, ply in player.Iterator() do
        SetVision(ply, false)
        timer.Remove("RdmtRTexVision_Attack_" .. ply:SteamID64())
        timer.Remove("RdmtRTexVision_Move_" .. ply:SteamID64())
    end
    attackState = {}
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"attackRevealTime", "moveRevealTime"}) do
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
    return sliders
end

Randomat:register(EVENT)
