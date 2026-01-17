local EVENT = {}

EVENT.Title = "Don't Stop Me Noooooowwwwwww"
EVENT.Description = "Everyone randomly freezes - no immunity!"
EVENT.id = "dontstopmenow"
EVENT.Type = EVENT_TYPE_JUMPING
EVENT.Categories = {"moderateimpact"}

CreateConVar("randomat_dontstopmenow_delayUpper", 45, FCVAR_NONE, "The upper limit for the random timer", 2, 120)
CreateConVar("randomat_dontstopmenow_delayLower", 20, FCVAR_NONE, "The lower limit for the random timer", 1, 120)
CreateConVar("randomat_dontstopmenow_freezeUpper", 5, FCVAR_NONE, "The upper limit for the freeze duration", 2, 60)
CreateConVar("randomat_dontstopmenow_freezeLower", 5, FCVAR_NONE, "The lower limit for the freeze duration", 1, 60)
CreateConVar("randomat_dontstopmenow_affectAll", 0, FCVAR_NONE, "Does the event affect everyone at the same time")
CreateConVar("randomat_dontstopmenow_allowMouseInput", 1, FCVAR_NONE, "Can players look and shoot while frozen")

function EVENT:Begin()

    local delayupper = GetConVar("randomat_dontstopmenow_delayUpper"):GetInt()
    local delaylower = GetConVar("randomat_dontstopmenow_delayLower"):GetInt()
    local freezeupper = GetConVar("randomat_dontstopmenow_freezeUpper"):GetInt()
    local freezelower = GetConVar("randomat_dontstopmenow_freezeLower"):GetInt()
    local affectall = GetConVar("randomat_dontstopmenow_affectAll"):GetBool()
    local allowmouse = GetConVar("randomat_dontstopmenow_allowMouseInput"):GetBool()

    -- For sanity (Thanks Mal)
    if delaylower > delayupper then
        delayupper = delaylower + 1
    end

    if freezelower > freezeupper then
        freezeupper = freezelower + 1
    end

    self.DSMNIndividualFreeze = self.DSMNIndividualFreeze or {}
    self.DSMNIndividualUnfreeze = self.DSMNIndividualUnfreeze or {}

    self:AddHook("SetupMove", function(ply, mv, cmd)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        if ply.rdmtNoMoveButMouse then
            -- Stop all movement
            mv:SetForwardSpeed(0)
            mv:SetSideSpeed(0)
            mv:SetUpSpeed(0)
            
            -- Prevent jumping and crouching
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_DUCK)))
        end
    end)

    self:AddHook("PlayerDeath", function(victim)
        if IsValid(victim) then
            victim.rdmtNoMoveButMouse = false
            victim:Freeze(false)

            -- Clean up individual timers if they exist
            if self.DSMNIndividualFreeze and self.DSMNIndividualFreeze[victim] then
                local freezeTimerName = self.DSMNIndividualFreeze[victim]
                local unfreezeTimerName = self.DSMNIndividualUnfreeze[victim]
                timer.Remove(freezeTimerName)
                timer.Remove(unfreezeTimerName)
                self.DSMNIndividualFreeze[victim] = nil
                self.DSMNIndividualUnfreeze[victim] = nil
            end
        end
    end)

    if affectall then
        -- Function to start the next delay timer
        local function StartDelayTimer()

            timer.Create("RdmtDSMNAllFreeze", math.random(delaylower, delayupper), 1, function()
                local alive = self:GetAlivePlayers(true)

                -- Freeze all players
                for _, ply in ipairs(alive) do
                    if allowmouse then
                        ply.rdmtNoMoveButMouse = true
                        Randomat:SmallNotify("Stop!", 3, ply, false, false, Color(240, 75, 30))
                    else
                        ply:Freeze(true)
                        Randomat:SmallNotify("Stop!", 3, ply, false, false, Color(240, 75, 30))
                    end
                end

                -- Start unfreeze timer
                timer.Create("RdmtDSMNAllUnfreeze", math.random(freezelower, freezeupper), 1, function()
                    -- Unfreeze all players
                    for _, ply in ipairs(alive) do
                        if IsValid(ply) then
                            if allowmouse then
                                ply.rdmtNoMoveButMouse = false
                                Randomat:SmallNotify("Unstop!", 3, ply, false, false, Color(50, 255, 50))
                            else
                                ply:Freeze(false)
                                Randomat:SmallNotify("Unstop!", 3, ply, false, false, Color(50, 255, 50))
                            end
                        end
                    end
                    
                    -- Start the next delay timer after unfreezing
                    StartDelayTimer()
                end)
            end)
        end
        
        -- Start the first delay timer
        StartDelayTimer()
        
    else
        -- Individual timers for each player
        timer.Create("RdmtDSMNIndividualTimers", 1, 0, function()
            for _, ply in ipairs(self:GetAlivePlayers(true)) do
                if not self.DSMNIndividualFreeze[ply] then
                    local freezeTimerName = "RdmtDSMNIndividualFreeze_" .. ply:SteamID64()
                    local unfreezeTimerName = "RdmtDSMNIndividualUnfreeze_" .. ply:SteamID64()
                    self.DSMNIndividualFreeze[ply] = freezeTimerName
                    self.DSMNIndividualUnfreeze[ply] = unfreezeTimerName

                    -- Function to start the delay timer for this player
                    local function StartPlayerDelayTimer()
                        timer.Create(freezeTimerName, math.random(delaylower, delayupper), 1, function()
                            if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then
                                timer.Remove(freezeTimerName)
                                self.DSMNIndividualFreeze[ply] = nil
                                return
                            end

                            -- Freeze the player
                            if allowmouse then
                                ply.rdmtNoMoveButMouse = true
                                -- Randomat:SmallNotify(msg, length, target, silent, allow_secret, font_color)

                                Randomat:SmallNotify("Stop!", 3, ply, false, false, Color(240, 75, 30))

                            else
                                ply:Freeze(true)
                                Randomat:SmallNotify("Stop!", 3, ply, false, false, Color(240, 75, 30))
                            end

                            -- Start unfreeze timer
                            timer.Create(unfreezeTimerName, math.random(freezelower, freezeupper), 1, function()
                                if IsValid(ply) then
                                    if allowmouse then
                                        ply.rdmtNoMoveButMouse = false
                                        Randomat:SmallNotify("Unstop!", 3, ply, false, false, Color(50, 255, 50))
                                    else
                                        ply:Freeze(false)
                                        Randomat:SmallNotify("Unstop!", 3, ply, false, false, Color(50, 255, 50))
                                    end
                                end
                                
                                -- Start the next delay timer after unfreezing
                                StartPlayerDelayTimer()
                            end)
                        end)
                    end
                    
                    -- Start the first delay timer for this player
                    StartPlayerDelayTimer()
                end
            end
        end)
    end
end

function EVENT:End()
    -- Remove global/affectAll timers
    timer.Remove("RdmtDSMNAllFreeze")
    timer.Remove("RdmtDSMNAllUnfreeze")
    timer.Remove("RdmtDSMNIndividualTimers")

    -- Remove all individual timers
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local freezeTimerName = "RdmtDSMNIndividualFreeze_" .. ply:SteamID64()
            local unfreezeTimerName = "RdmtDSMNIndividualUnfreeze_" .. ply:SteamID64()
        
            timer.Remove(freezeTimerName)
            timer.Remove(unfreezeTimerName)
        
            ply:Freeze(false)
            ply.rdmtNoMoveButMouse = false
        end
    end

    -- Clear tables
    self.DSMNIndividualFreeze = nil
    self.DSMNIndividualUnfreeze = nil

    -- Remove the SetupMove hook to stop microstutters
    self:RemoveHook("SetupMove", "RdmtNoMoveButMouse")
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"delayUpper", "delayLower", "freezeUpper", "freezeLower"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax()
            })
        end
    end
    
    local checks = {}
    for _, v in ipairs({"affectAll", "allowMouseInput"}) do
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