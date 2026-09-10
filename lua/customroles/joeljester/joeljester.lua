AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_UpdateJoelJesterSecondaryWins")
util.AddNetworkString("TTT_ResetJoelJesterSecondaryWins")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_joeljester_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a jester was killed. Killer is notified unless \"ttt_jester_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_joeljester_notify_killer", "1", FCVAR_NONE, "Whether to notify a jester's killer", 0, 1)
CreateConVar("ttt_joeljester_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a jester is killed", 0, 1)
CreateConVar("ttt_joeljester_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a jester is a killed", 0, 1)
local jester_win_ends_round = CreateConVar("ttt_joeljester_win_ends_round", "1", FCVAR_NONE, "Whether the jester winning causes the round to end", 0, 1)

local jester_win_by_traitors = GetConVar("ttt_joeljester_win_by_traitors")

local jester_immune_fall       = CreateConVar("ttt_joeljester_immune_fall", "1", FCVAR_NONE, "Whether the jester is immune to fall damage", 0, 1)
local jester_immune_fire       = CreateConVar("ttt_joeljester_immune_fire", "1", FCVAR_NONE, "Whether the jester is immune to fire damage", 0, 1)
local jester_immune_explosion  = CreateConVar("ttt_joeljester_immune_explosions", "1", FCVAR_NONE, "Whether the jester is immune to explosion damage", 0, 1)
local jester_swaps_with_killer = CreateConVar("ttt_joeljester_swaps_with_killer", "0", FCVAR_NONE, "Whether the jester swaps roles with their killer", 0, 1)
local jester_killer_dies       = CreateConVar("ttt_joeljester_killer_dies", "0", FCVAR_NONE, "Whether the jester's killer dies", 0, 1)
local jester_respawns          = CreateConVar("ttt_joeljester_respawns", "0", FCVAR_NONE, "Whether the jester respawns after being killed", 0, 1)

-------------------
-- ROLE FEATURES --
-------------------

-- Prevent fall damage
local function JoelJester_OnPlayerHitGround(ply, in_water, on_floater, speed)
    if GetRoundState() == ROUND_ACTIVE and ply:IsRole(ROLE_JOELJESTER) and jester_immune_fall:GetBool() and not ply:IsRoleAbilityDisabled() then
        return true
    end
end

-- Prevent other damage
local function JoelJester_EntityTakeDamage(ent, dmginfo)
    if not IsValid(ent) then return end

    local blockDamage = (dmginfo:IsExplosionDamage() and jester_immune_explosion:GetBool()) or
                        (dmginfo:IsDamageType(DMG_BURN) and jester_immune_fire:GetBool()) or
                        (dmginfo:IsFallDamage() and jester_immune_fall:GetBool()) or
                        dmginfo:IsDamageType(DMG_CRUSH) or
                        dmginfo:IsDamageType(DMG_DROWN) or
                        dmginfo:GetDamageType() == 0 or
                        dmginfo:IsDamageType(DMG_DISSOLVE)

    local att = dmginfo:GetAttacker()

    -- Block the damage unless the Jester's role is disabled
    if GetRoundState() == ROUND_ACTIVE and ent:IsPlayer() then
        if ent:IsRole(ROLE_JOELJESTER) and (not IsValid(att) or att:GetClass() ~= "trigger_hurt") then
            if blockDamage and not ent:IsRoleAbilityDisabled() then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)
            end
        end
    end

    -- Prevent damage from jesters
    if IsPlayer(att) and att:IsRole(ROLE_JOELJESTER) then
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
    end
end

local function JoelJester_PlayerTakeDamage(ent, infl, att, amount, dmginfo)
    local ignite_info = ent.ignite_info
    if ent.ignite_info_ext then
        if not ignite_info then
            if ent.ignite_info_ext.end_time > CurTime() then
                ignite_info = ent.ignite_info_ext
            else
                ent.ignite_info_ext = nil
            end
        else
            if not ent.ignite_info_ext.att then
                ent.ignite_info_ext.att = ent.ignite_info.att
            end
            if not ent.ignite_info_ext.infl then
                ent.ignite_info_ext.infl = ent.ignite_info.infl
            end
        end
    end

    if ignite_info and dmginfo:IsDamageType(DMG_DIRECT) then
        local datt = dmginfo:GetAttacker()
        if not IsPlayer(datt) and IsValid(ignite_info.att) and IsValid(ignite_info.infl) then
            dmginfo:SetAttacker(ignite_info.att)
            dmginfo:SetInflictor(ignite_info.infl)

            if ignite_info.att:IsRole(ROLE_JOELJESTER) then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)
            end
        end
    end
end

----------------
-- WIN CHECKS --
----------------

local function HandleJesterWin()
    if not jester_win_ends_round:GetBool() then
        net.Start("TTT_UpdateJoelJesterSecondaryWins")
        net.Broadcast()
        return
    end

    if GetConVar("ttt_debug_preventwin"):GetBool() then return end

    StopWinChecks()
    timer.Simple(1, function() EndRound(WIN_JESTER) end)
end

local function JoelJester_WinCheck_PlayerDeath(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end

    if victim:IsRole(ROLE_JOELJESTER) then
        -- 1. Always trigger the notification, confetti, and sound
        JesterTeamKilledNotification(attacker, victim,
            function()
                return attacker:Nick() .. " was dumb enough to kill the " .. ROLE_STRINGS[ROLE_JOELJESTER] .. "!"
            end,
            function()
                return true
            end
        )

        victim:SetNWString("JoelJesterKiller", attacker:Nick())

        if attacker:IsTraitorTeam() and not jester_win_by_traitors:GetBool() then return end

        if victim:IsRoleAbilityDisabled() then
            victim.JesterShouldWin = true
            return
        end

        if jester_swaps_with_killer:GetBool() then
            local killerRole = attacker:GetRole()
            -- attacker:SetRole(ROLE_JOELJESTER)
            victim:SetRole(killerRole)
            SendFullStateUpdate()
        end

        if jester_killer_dies:GetBool() then
            attacker:Kill()
        end

        if jester_respawns:GetBool() then
            local spawnPos = victim:GetPos()
            local spawnEyeAngles = victim:EyeAngles()
            local body = victim.server_ragdoll or victim:GetRagdollEntity()
            timer.Simple(0.1, function()
                if IsValid(victim) and not victim:Alive() then
                    victim:SpawnForRound(true)
                    victim:SetPos(spawnPos)
                    victim:SetEyeAngles(spawnEyeAngles)
                    victim:SetHealth(victim:GetMaxHealth())
                    body:Remove()
                end
            end)
        end

        HandleJesterWin()
    end
end

local function JoelJester_TTTOnRoleAbilityEnabled(ply)
    if not IsPlayer(ply) or not ply:IsRole(ROLE_JOELJESTER) then return end
    if ply:Alive() or not ply:IsSpec() then return end
    if not ply.JesterShouldWin then return end
    ply.JesterShouldWin = false
    HandleJesterWin()
end

local function JoelJester_TTTPrintResultMessage(type)
    if type == WIN_JESTER then
        LANG.Msg("win_jester", { role = ROLE_STRINGS[ROLE_JOELJESTER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_JOELJESTER] .. " wins.\n")
        return true
    end
end

AddHook("TTTPrepareRound", "JoelJester_TTTPrepareRound", function()
    for _, v in PlayerIterator() do
        v.JesterShouldWin = false
        v:SetNWString("JoelJesterKiller", "")
    end
    net.Start("TTT_ResetJoelJesterSecondaryWins")
    net.Broadcast()
end)

AddHook("TTTBeginRound", "JoelJester_TTTBeginRound", function()
    net.Start("TTT_ResetJoelJesterSecondaryWins")
    net.Broadcast()
end)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_JOELJESTER] = {
    ["PlayerDeath"]                  = JoelJester_WinCheck_PlayerDeath,
    ["TTTOnRoleAbilityEnabled"]      = JoelJester_TTTOnRoleAbilityEnabled,
    ["TTTPrintResultMessage"]        = JoelJester_TTTPrintResultMessage,
    ["JoelJester_PlayerTakeDamage"]  = JoelJester_PlayerTakeDamage,
    ["JoelJester_EntityTakeDamage"]  = JoelJester_EntityTakeDamage,
    ["JoelJester_OnPlayerHitGround"] = JoelJester_OnPlayerHitGround
}