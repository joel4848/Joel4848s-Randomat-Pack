local EVENT = {}

EVENT.Title       = "Trace Evidence"
EVENT.Description = "Draws tracers when players fire bullets"
EVENT.id          = "traceevidence"
EVENT.Categories  = {"biased_innocent", "biased", "smallimpact"}

util.AddNetworkString("RandomatTraceEvidence")

local lastBeams = {}

function EVENT:Begin()
    lastBeams = {}

    self:AddHook("PostEntityFireBullets", function(ent, data)
        if not IsValid(ent) or not ent:IsPlayer() then return end
        if lastBeams[ent] and (CurTime() < lastBeams[ent] + 0.1 and CurTime() > lastBeams[ent] + 0.01) then return end

        lastBeams[ent] = CurTime()

        net.Start("RandomatTraceEvidence")
            net.WriteEntity(ent)
            net.WriteVector(data.Trace.StartPos)
            net.WriteVector(data.Trace.HitPos)
        net.Broadcast()
    end)
end

function EVENT:End()
    lastBeams = {}
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"duration"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end

    local checks = {}
    for _, v in ipairs({"per_player_colours", "draw_words"}) do
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