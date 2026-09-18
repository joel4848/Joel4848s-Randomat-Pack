local EVENT = {}

EVENT.Title = "More Faster More Better"
EVENT.Description = "Weapon damage scales with your velocity"
EVENT.id = "morefastermorebetter"
EVENT.Categories = {"largeimpact"}

CreateConVar("randomat_morefastermorebetter_damage_stationary", 0,   FCVAR_NONE, "Damage percentage while stationary",   0, 10000)
CreateConVar("randomat_morefastermorebetter_damage_walking",    100, FCVAR_NONE, "Damage percentage at walking speed",   0, 10000)
CreateConVar("randomat_morefastermorebetter_damage_sprinting",  140, FCVAR_NONE, "Damage percentage at sprinting speed", 0, 10000)

function EVENT:Begin()
    local stationary = GetConVar("randomat_morefastermorebetter_damage_stationary"):GetInt() / 100
    local walking    = GetConVar("randomat_morefastermorebetter_damage_walking"):GetInt()    / 100
    local sprinting  = GetConVar("randomat_morefastermorebetter_damage_sprinting"):GetInt()  / 100

    if stationary > walking then stationary = walking end
    if sprinting < walking then sprinting = walking end

    local walkSpeed   = 220
    local sprintSpeed = walkSpeed * (1 + cvars.Number("ttt_sprint_bonus_rel", 0.4))

    -- If velocity between stationary and walking
    local x1, y1 = 0, stationary
    local x2, y2 = walkSpeed, walking

    local m = (y2 - y1) / (x2 - x1)
    local c = y2 - m * x2

    -- If velocity above walking
    local sprX1, sprY1 = walkSpeed, walking
    local sprX2, sprY2 = sprintSpeed, sprinting

    local sprM = (sprY2 - sprY1) / (sprX2 - sprX1)
    local sprC = sprY2 - sprM * sprX2

    local function GetMultiplier(x)
        local y
        if x <= 220 then
            y = m * x + c
        else
            y = sprM * x + sprC
        end

        return y
    end

    local recentDoncons = {}

    self:AddHook("EntityRemoved", function(ent)
        if ent:GetClass() == "doncmk2_en" and ent.MFMBVelocity and IsValid(ent:GetOwner()) then
            recentDoncons[ent:GetOwner()] = {
                velocity = ent.MFMBVelocity,
                time     = CurTime(),
                position = ent:GetPos()
            }
        end
    end)

    self:AddHook("OnEntityCreated", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end

            local owner = ent:GetOwner()

            if IsValid(ent) and IsValid(owner) then
                ent.MFMBVelocity = owner:GetVelocity():Length() or nil
            end
        end)
    end)

    self:AddHook("EntityTakeDamage", function(target, dmg)
        local attacker  = dmg:GetAttacker()

        if not attacker:IsPlayer() then return end

        local donconDamage = ConVarExists("ttt_doncon_damage") and GetConVar("ttt_doncon_damage"):GetInt() or 1000
        if dmg:GetDamage() == donconDamage then
            for _, doncon in ipairs(ents.FindByClass("doncmk2_en")) do
                if doncon:GetOwner() == attacker and doncon.MFMBVelocity and doncon:GetPos():Distance(target:GetPos()) < 500 then
                    dmg:SetInflictor(doncon)
                    break
                end
            end
        end

        local inflictor = dmg:GetInflictor()
        local velocity = nil

        if IsValid(inflictor) and inflictor:GetClass() == "env_explosion" and recentDoncons[attacker] then
            local doncon = recentDoncons[attacker]
            if CurTime() - doncon.time < 0.1 and inflictor:GetPos():Distance(doncon.position) < 100 then
                velocity = doncon.velocity
            end
        end

        if not velocity then
            if IsValid(inflictor) and inflictor.MFMBVelocity then
                velocity = inflictor.MFMBVelocity
            else
                velocity = attacker:GetVelocity():Length()
            end
        end

        if target:IsPlayer() then
            local multiplier = GetMultiplier(velocity)
            dmg:ScaleDamage(multiplier)
            PrintMessage(HUD_PRINTTALK, "velocity = " .. tostring(velocity))
            PrintMessage(HUD_PRINTTALK, "multiplier = " .. tostring(multiplier))
        else
            target.MFMBVelocity = velocity
        end
    end)
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"damage_stationary", "damage_walking", "damage_sprinting"}) do
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