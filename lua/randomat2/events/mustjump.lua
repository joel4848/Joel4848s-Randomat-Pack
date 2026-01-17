local EVENT = {}

EVENT.Title = "You MUST jump twice."
EVENT.Description = "Explodes players who DON'T use their double jumps!"
EVENT.id = "mustjump"
EVENT.Type = EVENT_TYPE_JUMPING
EVENT.Categories = {"largeimpact"}

CreateConVar("randomat_mustjump_spam", 0, FCVAR_NONE, "Whether to show the message again for a player who doesn't die")
CreateConVar("randomat_mustjump_spamTimer", 5, FCVAR_NONE, "Whether to show the message again for a player who doesn't die", 0, 60)
CreateConVar("randomat_mustjump_killBlastImmune", 1, FCVAR_NONE, "Whether to kill players who are immune to blast damage")

local timerIds = {}

function EVENT:Begin()

    for _, v in player.Iterator() do
        v.rdmtSpamCooldown = 0
        v.rdmtSurvived = 0
    end

    local spam = GetConVar("randomat_mustjump_spam"):GetBool()
    local spamTimer = GetConVar("randomat_mustjump_spamTimer"):GetInt()
    local killBlastImmune = GetConVar("randomat_mustjump_killBlastImmune"):GetBool()

    self:AddHook("PlayerDeath", function(victim)
        if not IsValid(victim) then return end

        victim.rdmtSurvived = 0
    end)


    -- Delay start so players don't get killed if the randomat triggers mid-jump
    timer.Create("RdmtMustJumpStartDelay", 1, 1, function()
        self:AddHook("KeyPress", function(ply, key)
            -- Detect jump key pressed and player is valid etc.
            if key == IN_JUMP and IsValid(ply) and ply:Alive() and not ply:IsSpec() then
                -- Don't start checks if player is in water, but what's fair for water level? Wiki says:        
                -- 0 - The entity isn't in water.
                -- 1 - Slightly submerged (at least to the feet).
                -- 2 - The majority of the entity is submerged (at least to the waist).
                -- 3 - Completely submerged.
                -- Going to go with >1 for now i.e. ignores if they're swimming, or waist-deep in water struggling to get out (wouldn't feel fair)
                if ply:WaterLevel() > 1 then return end
                    -- Don't start checks if jump WAS player using their double jump
                    if ply:GetJumpLevel() > 0 then return end
            ply.rdmtMustJumpActive = true
            PrintMessage(HUD_PRINTTALK, "~~~~~~~~~~~~~~~~~~~~~~~~~")
            PrintMessage(HUD_PRINTTALK, "- " .. ply:Nick() .. "'s rdmtSurvived is " .. tostring(ply.rdmtSurvived))
            end
        end)

        self:AddHook("Think", function()
            for _, ply in ipairs(player.GetAll()) do
                if ply.rdmtMustJumpActive then
                    if ply.rdmtWasOnGround == nil then
                        ply.rdmtWasOnGround = ply:OnGround()
                    end
                    if ply.rdmtWasOnGround == false and ply:OnGround() then
                        if ply:GetJumpLevel() < 1 then
                        
                            util.BlastDamage(ply, ply, ply:GetPos(), 100, 500)
                            if not Randomat:ShouldActLikeJester(ply) and killBlastImmune then
                                local timerId = "RdmtMustJumpKillDelay_" .. ply:SteamID64()
                                table.insert(timerIds, timerId)

                                -- Delay this by a frame so on-death hooks can trigger first (thanks Mal)
                                timer.Create(timerId, 0, 1, function()
                                    if not IsPlayer(ply) then return end
                                    if not ply:Alive() or ply:IsSpec() then return end

                                    timer.Create(timerId, 0.25, 1, function()
                                        ply:Kill()
                                    end)
                                end)
                            else
                                if not IsPlayer(ply) then return end
                                if not ply:Alive() or ply:IsSpec() then return end
                                ply.rdmtSurvived = 1
                                PrintMessage(HUD_PRINTTALK, "- " .. ply:Nick() .. "'s rdmtSurvived is " .. tostring(ply.rdmtSurvived))
                                PrintMessage(HUD_PRINTTALK, "~~~~~~~~~~~~~~~~~~~~~~~~~")
                            end
                        
                            if spam then
                                self:SmallNotify(ply:Nick() .. " forgot to double jump.")
                            end
                        end
                        ply.rdmtMustJumpActive = nil
                        ply.rdmtWasOnGround = nil
                    end
                    ply.rdmtWasOnGround = ply:OnGround()
                end
            end
        end)
    end)
end

function EVENT:End()
    for _, timerId in ipairs(timerIds) do
        timer.Remove(timerId)
    end
    table.Empty(timerIds)
    timer.Remove("RdmtMustJumpStartDelay")

    for _, ply in ipairs(player.GetAll()) do
        ply.rdmtMustJumpActive = nil
        ply.rdmtWasOnGround = nil
    end

    self:RemoveHook("KeyPress")
    self:RemoveHook("Think")
end

function EVENT:Condition()
    return cvars.Number("multijump_default_jumps", -1) == 1
end

function EVENT:GetConVars()
    local checks = {}
    for _, v in ipairs({"spam", "killBlastImmune"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end
    return {}, checks
end

Randomat:register(EVENT)