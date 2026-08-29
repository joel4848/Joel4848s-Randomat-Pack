local EVENT = {}

local eventnames = {}

table.insert(eventnames, "Bait Shark")
table.insert(eventnames, "Just when you thought it was safe to get back in the shark costume...")
table.insert(eventnames, "swaJ")
table.insert(eventnames, "Cosplay With Consequences")


EVENT.Title = "Bait Shark"
EVENT.Description = "Lone Sharky vs Traitors with limited harpoons. Sharky wins if all harpoons miss!"
EVENT.id = "baitshark"
EVENT.Categories = {"rolechange", "weapon", "largeimpact"}


function EVENT:BeforeEventTrigger(ply, options, ...)
    self.Title = table.Random(eventnames)
end


util.AddNetworkString("rdmtStartHalo")
util.AddNetworkString("rdmtStopHalo")
util.AddNetworkString("rdmtStartBlind")
util.AddNetworkString("rdmtStopBlind")
util.AddNetworkString("rdmtSharkWinScreen")
util.AddNetworkString("rdmtSharkWinScreenUnhook")


CreateConVar("randomat_baitshark_harpoonAmount", 1, {FCVAR_NONE}, "Number of harpoons each traitor gets", 1, 10)
CreateConVar("randomat_baitshark_killTraitorsOnEmpty", 0, {FCVAR_NONE}, "Whether traitors die after missing with all their harpoons", 0, 1)
CreateConVar("randomat_baitshark_innocentSpeedMulti", 1.3, {FCVAR_NONE}, "The innocent player's speed multiplier", 1, 2)
CreateConVar("randomat_baitshark_makeInnocentShark", 1, {FCVAR_NONE}, "Whether to change the innocent's model to a shark", 0, 1)
CreateConVar("randomat_baitshark_highlightInnocent", 0, {FCVAR_NONE}, "Whether the traitors can see the innocent through walls", 0, 1)
CreateConVar("randomat_baitshark_traitorBlindDuration", 15, {FCVAR_NONE}, "How long to blind & freeze traitors for", 0, 30)


-- Get available shark player models (Sharky looking scared with 'poon me' postit note body)
local SHARK_MODELS = {
    {
        name = "sharky",
        model = "models/bradyjharty/yogscast/sharky.mdl",
        skin = 0,
        bodygroupValues = {
            [0] = 0, -- Head
            [1] = 0, -- Eyes
            [2] = 0, -- Eyelids
            [3] = 2, -- Brows
            [4] = 1, -- Mouth
            [5] = 5, -- Body
            [6] = 0, -- Shoulders
            [7] = 0, -- Arms
            [8] = 0  -- Feet
        }
    },
    {
        name = "left_shark",
        model = "models/freeman/player/left_shark.mdl",
        skin = 1,
        bodygroupValues = {}
    },
    {
        name = "bedgar_shark",
        model = "models/ben/left_shark.mdl",
        skin = 0,
        bodygroupValues = {}
    }
}

-- Find first available shark model in order of preference (Sharky -> Left Shark -> Bedgar Shark)
local function GetAvailableSharkModel()
    for _, data in ipairs(SHARK_MODELS) do
        if util.IsValidModel(data.model) then
            return data
        end
    end
    return nil
end


function EVENT:Begin()

    self.OriginalTimeScale = game.GetTimeScale()
    self.RoundEnded = false
    self.SpectatingPlayers = {}
    self.killmissers = GetConVar("randomat_baitshark_killTraitorsOnEmpty"):GetBool()
    self.TrackedHarpoons = {}
    self.MissedCounts = {}

    timer.Remove("rdmtBaitSharkHarpoonTimer")

    local lastPoonNotified = false
    local innocentHit = false
    local safetynetTimerCreated =  false
    local alivePlayers = self:GetAlivePlayers()
    if #alivePlayers < 2 then return end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply.rdmtHarpoonsRemaining = GetConVar("randomat_baitshark_harpoonAmount"):GetInt()
            ply.rdmtCurrentHarpoon = 0
            ply.rdmtMissedAll = false
        end
    end

    -- Role stuff

    -- Choose innocent
    self.innocent = table.Random(alivePlayers)
    local traitors = {}

    -- Store the innocent's original speeds
    if IsValid(self.innocent) then
        self.innocentOriginalSpeeds = {
            walk = self.innocent:GetWalkSpeed(),
            run = self.innocent:GetRunSpeed(),
            sprint = self.innocent:GetMaxSpeed(),
            crouch = self.innocent:GetCrouchedWalkSpeed()
        }
    end

    -- Apply speed multi to innocent and record traitors
    for _, ply in ipairs(alivePlayers) do
        if ply == self.innocent then
            Randomat:SetRole(ply, ROLE_INNOCENT)

            local speedMulti = GetConVar("randomat_baitshark_innocentSpeedMulti"):GetFloat()
            ply:SetWalkSpeed(ply:GetWalkSpeed() * speedMulti)
            ply:SetRunSpeed(ply:GetRunSpeed() * speedMulti)
            ply:SetMaxSpeed(ply:GetMaxSpeed() * speedMulti)
            ply:SetCrouchedWalkSpeed(ply:GetCrouchedWalkSpeed() * speedMulti)
        else
            Randomat:SetRole(ply, ROLE_TRAITOR)
            table.insert(traitors, ply)
        end
    end

    SendFullStateUpdate()
    self:NotifyTeamChange(traitors, ROLE_TEAM_TRAITOR)


    -- Change innocent player's model to shark
    self.OriginalPlayerModels = self.OriginalPlayerModels or {}

    local shark = GetAvailableSharkModel()

    if IsValid(self.innocent)
        and shark
        and GetConVar("randomat_baitshark_makeInnocentShark"):GetBool() then

        self.OriginalPlayerModels[self.innocent] = Randomat:GetPlayerModelData(self.innocent)

        Randomat:ForceSetPlayermodel(self.innocent, {
            model = shark.model,
            skin = shark.skin,
            bodygroupValues = shark.bodygroupValues
        })
    end

    -- Make innocent visible through walls if enabled
    if GetConVar("randomat_baitshark_highlightInnocent"):GetBool() and IsValid(self.innocent) then
        -- Add the culling bypass
        self:AddCullingBypass(nil, function(ply, tgt)
            return IsValid(tgt) and tgt == self.innocent
        end)

        net.Start("rdmtStartHalo")
        net.WriteEntity(self.innocent)
        net.Broadcast()
    end

    -- Strip weapons (and give holstered for testing player model has changed correctly)
    for _, ply in ipairs(alivePlayers) do
        ply:StripWeapons()
        ply:Give("weapon_ttt_unarmed")
        ply:SetFOV(0, 0.2)
    end

    -- Prevent players from picking up weapons except poons (otherwise I can't give them poons)
    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if not IsValid(wep) then return false end

        local class = WEPS.GetClass(wep)

        if class == "weapon_ttt_hwapoon" then
            return true
        end

        return false
    end)

    -- Prevent traitors from buying non-passive items
    self:AddHook("TTTCanOrderEquipment", function(ply, id, is_item)
        if not IsValid(ply) then return end

        if not is_item then
            ply:PrintMessage(HUD_PRINTCENTER, "Passive items only!")
            ply:ChatPrint("You can only buy passive items during '" .. Randomat:GetEventTitle(EVENT) .. "'\nYour purchase has been refunded.")

            return false
        end
    end)


    -- Blind and Freeze traitors if enabled
    local blindDuration = GetConVar("randomat_baitshark_traitorBlindDuration"):GetInt()

    if blindDuration > 0 then
        for _, ply in ipairs(traitors) do
            if not IsValid(ply) or not ply:Alive() then continue end

            -- Blind and freeze traitors
            ply:Freeze(true)
            net.Start("rdmtStartBlind")
            net.Broadcast()

            -- Unblind and unfreeze traitors after duration
            timer.Create("rdmtBlindDurationTimer", blindDuration, 1, function()

                for _, p in ipairs(traitors) do
                    if not IsValid(p) or not p:Alive() then continue end
                    p:Freeze(false)
                end

                net.Start("rdmtStopBlind")
                net.Broadcast()
            end)
        end
    end

    -- Poon tracking/hit detection
    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        local inf = dmginfo:GetInflictor()
        local attacker = dmginfo:GetAttacker()

        if not IsValid(attacker) or not IsValid(inf) then return end
        if inf:GetClass() ~= "hwapoon_arrow" then return end
        if not self.TrackedHarpoons[inf] then return end

        -- Record what the poon hit
        inf.Hit = true
        inf.HitEnt = target
    end)

    -- Give new poon if traitor has any left
    local maxHarpoons = GetConVar("randomat_baitshark_harpoonAmount"):GetInt()

    if blindDuration >= 3 then
        self.initialHarpoonGiveDelay = blindDuration - 3
    else
        self.initialHarpoonGiveDelay = blindDuration
    end

    timer.Simple(self.initialHarpoonGiveDelay, function()
        timer.Create("rdmtBaitSharkHarpoonTimer", 3, 0, function()
            for _, ply in ipairs(traitors) do
                if not IsValid(ply) or not ply:Alive() then continue end

                -- Only give a new harpoon if they don't currently have one
                if not ply:HasWeapon("weapon_ttt_hwapoon") then
                    if ply.rdmtHarpoonsRemaining and ply.rdmtHarpoonsRemaining > 0 then

                        ply:Give("weapon_ttt_hwapoon")
                        ply:SelectWeapon("weapon_ttt_hwapoon")

                        ply.rdmtCurrentHarpoon = maxHarpoons - ply.rdmtHarpoonsRemaining + 1

                        ply.rdmtHarpoonsRemaining = ply.rdmtHarpoonsRemaining - 1

                        local finalHarpoon = true

                        for _, p in ipairs(self:GetAlivePlayers(true)) do
                            if p:IsTraitor() then
                                if (p.rdmtHarpoonsRemaining or 0) > 0 then
                                    finalHarpoon = false
                                end
                            end
                        end

                        if not finalHarpoon then
                            if ply.rdmtCurrentHarpoon == maxHarpoons then
                                if GetConVar("randomat_baitshark_killTraitorsOnEmpty"):GetBool() then
                                    Randomat:SmallNotify("THIS IS YOUR LAST POON! IF YOU MISS, YOU DIE!", 5, ply, false, false, Color(240, 75, 30))
                                else
                                    Randomat:SmallNotify("THIS IS YOUR LAST POON!", 3, ply, false, false, Color(240, 75, 30))
                                end
                            elseif ply.rdmtCurrentHarpoon == 1 then
                                Randomat:SmallNotify("This is your " .. ply.rdmtCurrentHarpoon .. "st poon of " .. maxHarpoons, 3, ply, false, false, Color(240, 75, 30))
                            elseif ply.rdmtCurrentHarpoon == 2 then
                                Randomat:SmallNotify("This is your " .. ply.rdmtCurrentHarpoon .. "nd poon of " .. maxHarpoons, 3, ply, false, false, Color(240, 75, 30))
                            elseif ply.rdmtCurrentHarpoon == 3 then
                                Randomat:SmallNotify("This is your " .. ply.rdmtCurrentHarpoon .. "rd poon of " .. maxHarpoons, 3, ply, false, false, Color(240, 75, 30))
                            elseif ply.rdmtCurrentHarpoon >= 4 then
                                Randomat:SmallNotify("This is your " .. ply.rdmtCurrentHarpoon .. "th poon of " .. maxHarpoons, 3, ply, false, false, Color(240, 75, 30))
                            end
                        end
                    end
                end
            end
        end)
    end)


    -- Restore timescale and force spectate if round ends
    self:AddHook("TTTEndRound", function()
        if not self.RoundEnded then
            self.RoundEnded = true

            -- Restore timescale immediately
            if self.OriginalTimeScale then
                game.SetTimeScale(self.OriginalTimeScale)
            end

            -- Stop forcing spectate on players
            for ply, _ in pairs(self.SpectatingPlayers) do
                if IsValid(ply) then
                    ply:UnSpectate()
                    -- If they were alive when forced to spectate, reset their view
                    if ply:Alive() then
                        ply:SetObserverMode(OBS_MODE_NONE)
                    end
                end
            end
            self.SpectatingPlayers = {}
        end
    end)


    -- Main randomat logic crap
    self:AddHook("Think", function()
        if self.RoundEnded then return end

        if IsValid(self.innocent) then
            local ply = self.innocent
            for _, wep in ipairs(ply:GetWeapons()) do
                local class = wep:GetClass()

                if class ~= "weapon_ttt_unarmed" then
                    ply:StripWeapon(class)
                    ply:SetFOV(0, 0.2)
                end
            end
        end

        self.TrackedHarpoons = self.TrackedHarpoons or {}
        self.MissedCounts = self.MissedCounts or {}

        -- Track new thrown poons
        for _, ent in ipairs(ents.FindByClass("hwapoon_arrow")) do
            if not self.TrackedHarpoons[ent] then
                local owner = ent:GetOwner()
                if IsValid(owner) and owner:IsPlayer() then
                    self.TrackedHarpoons[ent] = owner
                    self.MissedCounts[owner] = self.MissedCounts[owner] or 0
                end
            end
        end

        -- Process poons that have resolved (hit something or disappeared)
        for ent, owner in pairs(self.TrackedHarpoons) do
            -- Skip poons we've already processed
            if ent.rdmtCounted then
                self.TrackedHarpoons[ent] = nil
                continue
            end

            -- Count poon disappearing as a miss
            if not IsValid(ent) then
                if IsValid(owner) then
                    self.MissedCounts[owner] = self.MissedCounts[owner] + 1
                end
                self.TrackedHarpoons[ent] = nil
                continue
            end

            -- Poon hits something
            if ent.Hit == true then
                ent.rdmtCounted = true

                local hitEnt = ent.HitEnt

                -- Count as miss unless it hit the innocent
                local missed = true
                if IsValid(hitEnt) and hitEnt:IsPlayer() and hitEnt == self.innocent then

                    missed = false
                    innocentHit = true

                    if GetConVar("randomat_baitshark_highlightInnocent"):GetBool() then
                        net.Start("rdmtStopHalo")
                        net.Broadcast()
                    end

                    timer.Simple(1, function()
                        if self.OriginalTimeScale then
                            game.SetTimeScale(self.OriginalTimeScale)
                        end
                    end)

                    -- If the innocent survives the harpoon hit, kill them
                    if IsValid(self.innocent) and self.innocent:Alive() then
                        local dmg = DamageInfo()

                        dmg:SetDamage(9999)
                        dmg:SetDamageType(DMG_SLASH)

                        if IsValid(owner) then
                            dmg:SetAttacker(owner)
                        end

                        dmg:SetInflictor(IsValid(ent) and ent or owner)
                        dmg:SetDamageForce(ent:GetVelocity())
                        dmg:SetDamagePosition(self.innocent:WorldSpaceCenter())

                        self.innocent:TakeDamageInfo(dmg)
                    end
                end

                if missed and IsValid(owner) then
                    self.MissedCounts[owner] = self.MissedCounts[owner] + 1
                end

                self.TrackedHarpoons[ent] = nil
            end
        end

        -- Flag players who have missed with all their poons
        for _, ply in ipairs(self:GetAlivePlayers()) do
            if not Randomat:IsTraitorTeam(ply) then continue end

            ply.rdmtMissedAll = ply.rdmtMissedAll or false

            if (self.MissedCounts[ply] or 0) >= maxHarpoons then
                ply.rdmtMissedAll = true
                -- Kill them if enabled
                if self.killmissers then
                    ply:Kill()
                    if maxHarpoons > 1 then
                        self:SmallNotify("You have failed me for the last time.", 5, ply, false, false, Color(240, 75, 30))
                    else
                        self:SmallNotify("You have failed me.", 5, ply, false, false, Color(240, 75, 30))
                    end
                end
            end
        end

        -- End round with innocent win if all poons have missed
        local allMissed = true

        for _, ply in ipairs(self:GetAlivePlayers(true)) do
            if ply:IsTraitor() and not ply.rdmtMissedAll then
                allMissed = false
                break
            end
        end

        if allMissed and not self.RoundEnded then
            self.RoundEnded = true

            for _, ply in ipairs(self:GetAlivePlayers(true)) do
                if ply:IsInnocent() then
                    net.Start("rdmtSharkWinScreen")
                    net.Broadcast()
                    -- Delay for dramatic effect before ending the round
                    timer.Simple(1, function()
                        if IsValid(ply) and ply:IsInnocent() then
                            EndRound(WIN_INNOCENT)
                            timer.Remove("rdmtSafetynetTimer")
                        end
                    end)
                    break
                end
            end
        end

        -- Notify all traitors when only one poon remains
        local traitorsWithPoon = 0
        local allHarpoonsEmpty = true
        for _, ply in ipairs(self:GetAlivePlayers(true)) do
            if ply:IsTraitor() then
                if ply:HasWeapon("weapon_ttt_hwapoon") then
                    traitorsWithPoon = traitorsWithPoon + 1
                end
                if (ply.rdmtHarpoonsRemaining or 0) > 0 then
                    allHarpoonsEmpty = false
                end
            end
        end

        if allHarpoonsEmpty and traitorsWithPoon == 1 and not lastPoonNotified then
            self:SmallNotify("Only one poon remains in the round! If it misses, the Shark wins!")
            lastPoonNotified = true
        end

        -- Slow-motion for final poon
        if lastPoonNotified and traitorsWithPoon == 0 and game.GetTimeScale() ~= 0.2 then
            timer.Simple(0.1, function()
                if not innocentHit then
                    game.SetTimeScale(0.2)
                end
            end)

            -- Find the last thrown poon
            local lastArrow = nil
            if self.TrackedHarpoons then
                for ent, owner in pairs(self.TrackedHarpoons) do
                    if IsValid(ent) and not ent.rdmtCounted then
                        lastArrow = ent
                        break
                    end
                end
            end

            -- Force all non-innocent players to spectate the final poon
            if IsValid(lastArrow) then
                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and not ply:IsInnocent() then
                        ply:SpectateEntity(lastArrow)
                        ply:SetObserverMode(OBS_MODE_CHASE)
                        self.SpectatingPlayers[ply] = true
                    end
                end
            end
        end

        -- Safetynet in case final poon hits but doesn't kill innocent: End round with innocent win if all poons thrown and no other resolution for 10 seconds.
        if allHarpoonsEmpty and traitorsWithPoon == 0 and not safetynetTimerCreated then
            safetynetTimerCreated = true

            timer.Create("rdmtSafetynetTimer", 6, 1, function()
                for _, ply in ipairs(self:GetAlivePlayers(true)) do
                    if ply:IsInnocent() then
                        if IsValid(ply) and ply:IsInnocent() then
                            net.Start("rdmtSharkWinScreen")
                            net.Broadcast()
                            EndRound(WIN_INNOCENT)
                        end
                        break
                    end
                end
            end)
        end
    end)
end

function EVENT:End()
    -- Restore game speed
    if self.OriginalTimeScale then
        game.SetTimeScale(self.OriginalTimeScale)
        self.OriginalTimeScale = nil
    end

    -- Stop forcing spectate
    if self.SpectatingPlayers then
        for ply, _ in pairs(self.SpectatingPlayers) do
            if IsValid(ply) then
                ply:UnSpectate()
                if ply:Alive() then
                    ply:SetObserverMode(OBS_MODE_NONE)
                end
            end
        end
        self.SpectatingPlayers = nil
    end

    -- Restore innocent player's original speeds
    if IsValid(self.innocent) and self.innocentOriginalSpeeds then
        self.innocent:SetWalkSpeed(self.innocentOriginalSpeeds.walk)
        self.innocent:SetRunSpeed(self.innocentOriginalSpeeds.run)
        self.innocent:SetMaxSpeed(self.innocentOriginalSpeeds.sprint)
        self.innocent:SetCrouchedWalkSpeed(self.innocentOriginalSpeeds.crouch)
    end
    self.innocentOriginalSpeeds = nil

    -- Restore innocent player's original model
    if self.OriginalPlayerModels then
        for ply, data in pairs(self.OriginalPlayerModels) do
            if IsValid(ply) and data then
                Randomat:ForceSetPlayermodel(ply, data)
            end
        end
    end
    self.OriginalPlayerModels = nil

    -- Stop client halos
    if GetConVar("randomat_baitshark_highlightInnocent"):GetBool() then
        net.Start("rdmtStopHalo")
        net.Broadcast()
    end

    -- Unblind and unfreeze everyone
    net.Start("rdmtStopBlind")
    net.Broadcast()

    -- Unhook from win screen
    net.Start("rdmtSharkWinScreenUnhook")
    net.Broadcast()

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:Freeze(false)
        end
    end

    timer.Remove("rdmtBlindDurationTimer")
    timer.Remove("rdmtBaitSharkHarpoonTimer")
    timer.Remove("rdmtSafetynetTimer")

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply.rdmtHarpoonsRemaining = nil
            ply.rdmtMissedAll = nil
        end
    end

    self.MissedCounts = nil
    self.TrackedHarpoons = nil
    self.RoundEnded = nil
    self.innocent = nil
end


function EVENT:GetConVars()
    local sliders = {}

    for _, v in ipairs({"harpoonAmount", "traitorBlindDuration"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end

    for _, v in ipairs({"innocentSpeedMulti"}) do
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

    local checks = {}
    for _, v in ipairs({"killTraitorsOnEmpty", "makeInnocentShark", "highlightInnocent"}) do
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

function EVENT:Condition()
    local harpoonExists = weapons.Get("weapon_ttt_hwapoon") ~= nil
    return harpoonExists
end

Randomat:register(EVENT)