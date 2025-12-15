local EVENT = {}

CreateConVar("randomat_budgetjetpacks_newJumpAmount", 99999, FCVAR_ARCHIVE, "'Jetpack' extra jump amount (for testing)", 0, 99999)
CreateConVar("randomat_budgetjetpacks_newJumpPower", 2, FCVAR_ARCHIVE, "'Jetpack' jump power multiplier", 1, 10)

EVENT.Title = "Budget Jetpacks For All!"
EVENT.Description = "Infinite stronger multijumps!"
EVENT.id = "budgetjetpacks"
EVENT.Categories = {"moderateimpact"}

function EVENT:Begin()

-- Record previous multijump amount and set new
    if ConVarExists("multijump_default_jumps") then
        newJumpAmount = GetConVar("randomat_budgetjetpacks_newJumpAmount"):GetInt()
        orginalJumps = GetConVar("multijump_default_jumps"):GetInt()
        GetConVar("multijump_default_jumps"):SetInt(newJumpAmount)
    end

-- Record previous multijump power and set new
    if ConVarExists("multijump_default_power") then
        newJumpPower = GetConVar("randomat_budgetjetpacks_newJumpPower"):GetInt()
        orginalPower = GetConVar("multijump_default_power"):GetInt()
        GetConVar("multijump_default_power"):SetInt(newJumpPower)
    end

end

function EVENT:End()
-- Record previous multijump amount and set new
    if ConVarExists("multijump_default_jumps") then
        GetConVar("multijump_default_jumps"):SetInt(orginalJumps)
    end

-- Record previous multijump power and set new
    if ConVarExists("multijump_default_power") then
        GetConVar("multijump_default_power"):SetInt(orginalPower)
    end
end

function EVENT:Condition()
    return ConVarExists("multijump_default_jumps")
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"newJumpPower"}) do
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

    return sliders
end

Randomat:register(EVENT)