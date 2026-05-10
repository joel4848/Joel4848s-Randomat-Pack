local EVENT = {}

EVENT.Title       = "Whose line is it anyway?"
EVENT.Description = "Shows where other players are looking, and warns you if it's at you!"
EVENT.id          = "whoseline"
EVENT.Categories  = {"biased_innocent", "biased", "lowimpact"}

function EVENT:Begin()

end

function EVENT:End()

end

function EVENT:GetConVars()
    local checks = {}
    for _, v in ipairs({"per_player_colours", "warn_target_colour", "warn_target_name", "show_lines"}) do
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