local EVENT = {}

EVENT.Title = "Up Close And Personal"
EVENT.Description = "Weapon damage scales with distance"
EVENT.id = "upclose"
EVENT.Categories = {"largeimpact"}

function EVENT:Begin()
    local min    = GetConVar("randomat_upclose_distance_minimum"):GetInt()
    local max    = GetConVar("randomat_upclose_distance_maximum"):GetInt()
    local dmgMin = GetConVar("randomat_upclose_damage_minimum"):GetInt() / 100
    local dmgMax = GetConVar("randomat_upclose_damage_maximum"):GetInt() / 100

    if max < min then max = min end
    if dmgMax < dmgMin then dmgMax = dmgMin end

    local function GetMultiplier(distance)
        return math.Remap(math.Clamp(distance, min, max), min, max, dmgMax, dmgMin)
    end

    self:AddHook("EntityTakeDamage", function(target, dmg)
        local attacker = dmg:GetAttacker()
        local distance = target:GetPos():Distance(attacker:GetPos())
        local multiplier = GetMultiplier(distance)
        dmg:ScaleDamage(multiplier)
    end)
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"distance_minimum", "distance_maximum", "damage_minimum", "damage_maximum"}) do
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