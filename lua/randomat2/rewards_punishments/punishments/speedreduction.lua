local PUNISHMENT = {}

PUNISHMENT.Name = "Move Slowly"
PUNISHMENT.Id = "speedreduction"

local speedreduction_mult = CreateConVar("rdmt_joel4848_rewardpunish_speedreduction_mult", 0.75, FCVAR_NONE, "Speed multiplier (0.75=75%, a 25% drop).", 0.05, 0.95)

local multIds = {}
local multIdPrefix = "Joel4848_RewardPunish_SpeedReduction_"

function PUNISHMENT:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local multId = multIdPrefix .. target:SteamID64()
    table.insert(multIds, multId)

    local mult = speedreduction_mult:GetFloat()
    net.Start("RdmtSetSpeedMultiplier")
    net.WriteFloat(mult)
    net.WriteString(multId)
    net.Send(target)

    hook.Add("TTTSpeedMultiplier", multId, function(ply, mults)
        if ply ~= target or not ply:Alive() or ply:IsSpec() then return end
        table.insert(mults, mult)
    end)
end

function PUNISHMENT:CleanUp()
    net.Start("RdmtRemoveSpeedMultipliers")
    net.WriteString(multIdPrefix)
    net.Broadcast()

    for _, multId in pairs(multIds) do
        hook.Remove("TTTSpeedMultiplier", multId)
    end
end

function PUNISHMENT:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"mult"}) do
        local name = "randomat_joel4848_rewardpunish_" .. self.Id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = self.Id .. "_" .. v,
                dsc = self.Name .. " - " .. convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 2
            })
        end
    end
end

Joel4848:RegisterPunishment(PUNISHMENT)