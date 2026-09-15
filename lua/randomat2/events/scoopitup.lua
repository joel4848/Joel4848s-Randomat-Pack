local EVENT = {}

EVENT.Title       = "SCOOP IT UP WITH YOUR F*CKING HANDS!!"
EVENT.Description = "Punch the ground with your f*cking hands to reload weapons"
EVENT.id          = "scoopitup"
EVENT.Categories  = {"largeimpact"}

CreateConVar("randomat_scoopitup_punch_delay", 1, FCVAR_NONE, "How quickly (s) you can punch to reload", 0.1, 30)
CreateConVar("randomat_scoopitup_refill_percentage", 20, FCVAR_NONE, "The clip percentage reloaded per punch", 1, 100)

local STANDARD_AMMO_TYPES = {
    "357",
    "Pistol",
    "AlyxGun",
    "SMG1",
    "Buckshot",
    "AirboatGun"
}

local function ClearStandardAmmo(ply)
    if not IsValid(ply) then return end
    for _, ammoName in ipairs(STANDARD_AMMO_TYPES) do
        ply:SetAmmo(0, ammoName)
    end
end

local function GiveHands(ply)
    if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
    if not ply:HasWeapon("weapon_ttt_joel4848hands") then
        ply:Give("weapon_ttt_joel4848hands")
    end
end

function EVENT:Begin()
    -- Give f*cking hands weapon and clear ammo reserves for alive players
    for _, v in ipairs(self:GetAlivePlayers()) do
        GiveHands(v)
        ClearStandardAmmo(v)
    end

    -- Give f*cking hands and clear ammo reserves for respawning players
    self:AddHook("PlayerSpawn", function(ply)
        timer.Simple(0.1, function()
            if IsValid(ply) then
                GiveHands(ply)
                ClearStandardAmmo(ply)
            end
        end)
    end)

    -- Make sure ammo reserves stay at zero
    self:AddHook("Think", function()
        for _, v in ipairs(self:GetAlivePlayers()) do
            ClearStandardAmmo(v)
        end
    end)

    -- Prevent picking up ammo boxes
    self:AddHook("TTTCanPickupAmmo", function(ply, ammoEnt)
        if not IsValid(ply) or not IsValid(ammoEnt) or not ammoEnt.AmmoType then return end

        return false
    end)
end

function EVENT:End()
    for _, v in ipairs(self:GetAlivePlayers()) do
        if v:HasWeapon("weapon_ttt_joel4848hands") then
            v:StripWeapon("weapon_ttt_joel4848hands")
        end
    end
end

function EVENT:GetConVars()
    local sliders = {}

    for _, v in ipairs({"refill_percentage"}) do
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

    for _, v in ipairs({"punch_delay"}) do
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

Randomat:register(EVENT)