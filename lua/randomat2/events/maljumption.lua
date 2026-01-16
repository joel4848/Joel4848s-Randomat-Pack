local EVENT = {}

EVENT.Title = "Maljumption"
EVENT.Description = "Causes players to randomly jump"
EVENT.id = "maljumption"
EVENT.Categories = {"lowimpact"}

CreateConVar("randomat_maljumption_upper", 15, FCVAR_NONE, "The upper limit for the random timer", 2, 60)
CreateConVar("randomat_maljumption_lower", 1, FCVAR_NONE, "The lower limit for the random timer", 1, 60)
-- affectall defaults to '1' so players randomly jump more often. Need to investigate having separate timers for each player
CreateConVar("randomat_maljumption_affectall", 1, FCVAR_NONE, "Set to 1 for the event to affect everyone at the same time")

function EVENT:Begin()
    local lower = GetConVar("randomat_maljumption_lower"):GetInt()
    local upper = GetConVar("randomat_maljumption_upper"):GetInt()
    local affectall = GetConVar("randomat_maljumption_affectall"):GetBool()
    
    -- For sanity (Thanks Mal)
    if lower > upper then
        upper = lower + 1
    end
    
    self.MaljumptionTimers = self.MaljumptionTimers or {}
    
    local function ForceJump(ply)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        
        ply:ConCommand("+jump")
        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply:ConCommand("-jump")
            end
        end)
    end
    
    -- affectall = 1 global timer
    if affectall then
        timer.Create("RdmtMaljumptionMain", math.random(lower, upper), 0, function()
            for _, ply in ipairs(self:GetAlivePlayers(true)) do
                ForceJump(ply)
            end
            
            timer.Adjust("RdmtMaljumptionMain", math.random(lower, upper))
        end)
        return
    end
    
    -- affectall = 0 individual timers
    timer.Create("RdmtMaljumptionIndividual", 1, 0, function()
        for _, ply in ipairs(self:GetAlivePlayers(true)) do
            if not self.MaljumptionTimers[ply] then
                local timerName = "RdmtMaljumption_" .. ply:SteamID64()
                self.MaljumptionTimers[ply] = timerName
                
                timer.Create(timerName, math.random(lower, upper), 0, function()
                    if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then
                        timer.Remove(timerName)
                        self.MaljumptionTimers[ply] = nil
                        return
                    end
                    
                    ForceJump(ply)
                    timer.Adjust(timerName, math.random(lower, upper))
                end)
            end
        end
    end)
end

function EVENT:End()
    
    timer.Remove("RdmtMaljumptionMain")
    timer.Remove("RdmtMaljumptionIndividual")
    
    if self.MaljumptionTimers then
        for ply, timerName in pairs(self.MaljumptionTimers) do
            timer.Remove(timerName)
            if IsValid(ply) then
                ply:ConCommand("-jump")
            end
        end
    end
    
    self.MaljumptionTimers = nil
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"upper", "lower"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = v == "duration" and 1 or 0
            })
        end
    end
    
    local checks = {}
    for _, v in ipairs({"affectall"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end
    return sliders, checks
end

Randomat:register(EVENT)