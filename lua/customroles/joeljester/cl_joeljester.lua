local hook = hook
local net = net
local string = string

local AddHook = hook.Add

-------------
-- CONVARS --
-------------

local jester_win_by_traitors = GetConVar("ttt_joeljester_win_by_traitors")
local jester_healthstation_reduce_max = GetConVar("ttt_joeljester_healthstation_reduce_max")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Jester_Translations_Initialize", function()
    LANG.AddToLanguage("english", "win_jester", "The {role} has fooled you all!")
    LANG.AddToLanguage("english", "ev_win_jester", "The tricky {role} won the round!")
    LANG.AddToLanguage("english", "score_jester_killedby", "Killed by")
    LANG.AddToLanguage("english", "radio_jes_celebrate", "{jester} Celebrate")
    LANG.AddToLanguage("english", "cheatsheet_desc_jester", "Wins the round if they can get another player to kill them.")
    LANG.AddToLanguage("english", "info_popup_jester", [[You are {role}! You want to die but you
deal no damage so you must be killed by some one else.]])
end)

----------------
-- WIN CHECKS --
----------------

local function JoelJester_TTTScoringWinTitle(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_JESTER then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_JOELJESTER]) }, c = ROLE_COLORS[ROLE_JOELJESTER] }
    end
end

local jester_secondary_wins = false
local function JoelJester_TTTScoringSecondaryWins(wintype, secondary_wins)
    if jester_secondary_wins then
        table.insert(secondary_wins, ROLE_JOELJESTER)
    end
end

------------
-- EVENTS --
------------

local function JoelJester_TTTEventFinishText(e)
    if e.win == WIN_JESTER then
        return LANG.GetParamTranslation("ev_win_jester", { role = string.lower(ROLE_STRINGS[ROLE_JOELJESTER]) })
    end
end

local function JoelJester_TTTEventFinishIconText(e, win_string, role_string)
    if e.win == WIN_JESTER then
        return win_string, ROLE_STRINGS[ROLE_JOELJESTER]
    end
end

-------------
-- SCORING --
-------------

net.Receive("TTT_UpdateJoelJesterSecondaryWins", function()
    jester_secondary_wins = true
end)

local function ResetJoelJesterSecondaryWin()
    jester_secondary_wins = false
end
net.Receive("TTT_ResetJoelJesterSecondaryWins", ResetJoelJesterSecondaryWin)
AddHook("TTTPrepareRound", "JoelJester_WinTracking_TTTPrepareRound", ResetJoelJesterSecondaryWin)
AddHook("TTTBeginRound", "JoelJester_WinTracking_TTTBeginRound", ResetJoelJesterSecondaryWin)

local function JoelJester_TTTScoringSummaryRender(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsJester() then
        local jesterKiller = ply:GetNWString("JoelJesterKiller", "")
        if #jesterKiller > 0 then
            return roleFileName, groupingRole, roleColor, name, jesterKiller, LANG.GetTranslation("score_jester_killedby")
        end
    end
end

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "JoelJester_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_JOELJESTER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html =  "The " .. ROLE_STRINGS[ROLE_JOELJESTER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to be killed by another player."

        if not jester_win_by_traitors:GetBool() then
            local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful! Jesters <span style='text-decoration: underline'>DO NOT</span> win if they are killed by a member of the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team</span>!</span>"
        end

        if jester_healthstation_reduce_max:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_JOELJESTER] .. " uses a health station, their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>maximum health is reduced</span> toward their current health instead of them being healed.</span>"
        end

        return html
    end
end)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_JOELJESTER] = {
    ["TTTEventFinishIconText"]  = JoelJester_TTTEventFinishIconText,
    ["TTTEventFinishText"]      = JoelJester_TTTEventFinishText,
    ["TTTScoringSecondaryWins"] = JoelJester_TTTScoringSecondaryWins,
    ["TTTScoringSummaryRender"] = JoelJester_TTTScoringSummaryRender,
    ["TTTScoringWinTitle"]      = JoelJester_TTTScoringWinTitle
}