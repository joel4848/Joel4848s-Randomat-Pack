local EVENT = {}

EVENT.Title       = "Gotta go fast!"
EVENT.Description = "The longer you hold a direction key down, the faster you go"
EVENT.id          = "gottagofast"
EVENT.Categories  = {"smallimpact"}

CreateConVar("randomat_gottagofast_speed_rate", 0.01, FCVAR_REPLICATED, "The rate at which speed increases", 0.01, 10)
CreateConVar("randomat_gottagofast_max_multiplier", 20, FCVAR_REPLICATED, "The maximum possible speed multiplier", 1, 100)

function EVENT:Begin()
    local rate = GetConVar("randomat_gottagofast_speed_rate"):GetFloat()
    local max  = GetConVar("randomat_gottagofast_max_multiplier"):GetInt()

    local playerMults = {}

    for _, ply in player.Iterator() do
        playerMults[ply] = 1
    end

    timer.Create("Randomat_GottaGoFast_KeyCheck", 0.1, 0, function()
        for _, ply in player.Iterator() do
            if not ply:Alive() or ply:IsSpec() then return end

            sid64 = ply:SteamID64()

            if (ply:KeyDown(IN_FORWARD) and ply:KeyDown(IN_BACK) and ply:KeyDown(IN_MOVELEFT) and ply:KeyDown(IN_MOVERIGHT)) then
                playerMults[sid64] = 1
            elseif (ply:KeyDown(IN_FORWARD) and ply:KeyDown(IN_BACK)) and not (ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)) then
                playerMults[sid64] = 1
            elseif not (ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK)) and (ply:KeyDown(IN_MOVELEFT) and ply:KeyDown(IN_MOVERIGHT)) then
                playerMults[sid64] = 1
            elseif ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT) then
                playerMults[sid64] = math.min(playerMults[sid64] + rate, max)
            else
                playerMults[sid64] = 1
            end
        end
    end)

    local TableInsert = table.insert

    self:AddHook("TTTSpeedMultiplier", function(ply, mults)
        sid64 = ply:SteamID64()
        mult  = playerMults[sid64] or 1
        if IsPlayer(ply) then
            TableInsert(mults, mult)
        end
    end)
end

function EVENT:End()
    timer.Remove("Randomat_GottaGoFast_KeyCheck")
end

if SERVER then
    function EVENT:GetConVars()
        local sliders = {}

        for _, v in ipairs({"max_multiplier"}) do
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

        for _, v in ipairs({"speed_rate"}) do
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
end

Randomat:register(EVENT)