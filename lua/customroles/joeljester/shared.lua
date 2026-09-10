AddCSLuaFile()

local AddHook = hook.Add

local ROLE = {}

ROLE.nameraw = "joeljester"
ROLE.name = "Jester"
ROLE.nameplural = "Jesters"
ROLE.nameext = "a Jester"
ROLE.nameshort = "jjs"

ROLE.blockspawnconvars = true

ROLE.desc = [[You are {role}!

You win by getting killed by an innocent!]]

ROLE.shortdesc = "Wins by getting killed by an innocent."

ROLE.team = ROLE_TEAM_JESTER
ROLE.shouldactlikejester = function() return false end
ROLE.startinghealth = nil
ROLE.maxhealth = nil
ROLE.startingcredits = 0

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()
end

CreateConVar("ttt_joeljester_healthstation_reduce_max", "1", FCVAR_REPLICATED, "Whether the jester's max health should be reduced to match their current health", 0, 1)
CreateConVar("ttt_joeljester_win_by_traitors", "1", FCVAR_REPLICATED, "Whether the jester will win the round if they are killed by a traitor", 0, 1)

-- Initialize role features
AddHook("TTTPrepareRound", "JoelJester_Shared_TTTPrepareRound", function()
    if not TRADIO.Sounds.jescelebrate and util.CanRoleSpawn(ROLE_JOELJESTER) then
        TRADIO.AddNewSound("jescelebrate", {
            name = "radio_jes_celebrate",
            name_params = { jester = ROLE_STRINGS[ROLE_JOELJESTER] },
            sound = "birthday.wav"
        })
    end
end)