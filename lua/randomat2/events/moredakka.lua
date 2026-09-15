local EVENT = {}

EVENT.Title = "More Dakka!"
EVENT.Description = "All yer slugs in one handy clip, ya lucky gitz!"
EVENT.id = "moredakka"
EVENT.Categories = {"moderateimpact"}

-- Fallbacks for guns without defined `wep.Primary.ClipMax` (e.g. the Sahmin Gun)
local defaultClipMaxes = {
    ["357"]        = 20,
    ["Pistol"]     = 60,
    ["AlyxGun"]    = 36,
    ["SMG1"]       = 60,
    ["Buckshot"]   = 24,
    ["AirboatGun"] = 200
}

local function RestoreWeapon(wep, ply)
    if not IsValid(wep) or not wep.MoreDakkaSetup then return end

    wep.Primary.ClipSize = wep.OldClipSize
    wep.Primary.ClipMax = wep.OldClipMax

    local currentClip = wep:Clip1()
    if currentClip > wep.OldClipSize then
        local excess = currentClip - wep.OldClipSize
        wep:SetClip1(wep.OldClipSize)

        if IsValid(ply) and ply:IsPlayer() then
            ply:GiveAmmo(excess, wep:GetPrimaryAmmoType(), true)
        end
    end

    wep.MoreDakkaSetup = nil
end

local function SetupWeapon(wep)
    if not IsValid(wep) or not wep.Primary then return end
    if wep.MoreDakkaSetup then return end

    wep.OldClipSize = wep.Primary.ClipSize or 0
    wep.OldClipMax = wep.Primary.ClipMax

    -- Use fallbacks if necessary
    if not wep.OldClipMax or wep.OldClipMax == -1 then
        local ammoTypeStr = isstring(wep.Primary.Ammo) and wep.Primary.Ammo or ""
        wep.OldClipMax = defaultClipMaxes[ammoTypeStr] or 60
    end

    if wep.OldClipSize > 0 and wep.OldClipMax > 0 then
        wep.Primary.ClipSize = wep.OldClipSize + wep.OldClipMax
        wep.MoreDakkaSetup = true
    end
end

function EVENT:Begin()
    for _, ply in player.Iterator() do
        for _, wep in ipairs(ply:GetWeapons()) do
            SetupWeapon(wep)
        end
    end

    self:AddHook("WeaponEquip", function(wep, ply)
        timer.Simple(0, function()
            SetupWeapon(wep)
        end)
    end)

    self:AddHook("PlayerDroppedWeapon", function(ply, wep)
        RestoreWeapon(wep, ply)
    end)

    self:AddHook("Think", function()
        for _, ply in player.Iterator() do
            if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then continue end

            local activeWep = ply:GetActiveWeapon()
            local ammoPools = {}

            -- Group weapons by ammo type
            for _, wep in ipairs(ply:GetWeapons()) do
                if not wep.MoreDakkaSetup then continue end

                local ammoType = wep:GetPrimaryAmmoType()
                if ammoType <= 0 then continue end

                if not ammoPools[ammoType] then ammoPools[ammoType] = {} end
                table.insert(ammoPools[ammoType], wep)
            end

            -- Shared ammo pools
            for ammoType, weps in pairs(ammoPools) do
                local currentTotal = ply:GetAmmoCount(ammoType)
                local maxAllowed = 0
                local activeWepForAmmo = weps[1]
                local hasInactiveAmmo = false
                local activeWepClip = 0

                for _, w in ipairs(weps) do
                    local clip = math.max(0, w:Clip1())
                    currentTotal = currentTotal + clip

                    local combinedMax = w.OldClipSize + w.OldClipMax
                    if combinedMax > maxAllowed then maxAllowed = combinedMax end

                    if w == activeWep then
                        activeWepForAmmo = w
                        activeWepClip = clip
                    elseif clip > 0 then
                        hasInactiveAmmo = true
                    end
                end

                local clampedTotal = math.min(currentTotal, maxAllowed)
                local excess = currentTotal - maxAllowed

                if hasInactiveAmmo or ply:GetAmmoCount(ammoType) > 0 or activeWepClip ~= clampedTotal or excess > 0 then
                    ply:SetAmmo(0, ammoType)

                    for _, w in ipairs(weps) do
                        if w == activeWepForAmmo then
                            w:SetClip1(clampedTotal)
                        else
                            w:SetClip1(0)
                        end
                    end
                end
            end
        end
    end)

    self:AddHook("TTTCanPickupAmmo", function(ply, ammoEnt)
        if not IsValid(ply) or not IsValid(ammoEnt) or not ammoEnt.AmmoType then return end

        local ammoID = game.GetAmmoID(ammoEnt.AmmoType)
        local currentTotal = ply:GetAmmoCount(ammoID)
        local maxAllowed = 0
        local matched = false

        for _, wep in ipairs(ply:GetWeapons()) do
            if IsValid(wep) and wep.MoreDakkaSetup and wep:GetPrimaryAmmoType() == ammoID then
                matched = true
                currentTotal = currentTotal + math.max(0, wep:Clip1())

                local wepMax = wep.OldClipSize + wep.OldClipMax
                if wepMax > maxAllowed then maxAllowed = wepMax end
            end
        end

        if matched and currentTotal >= maxAllowed then
            return false
        end

        return nil
    end)
end

function EVENT:End()
    for _, ent in ipairs(ents.GetAll()) do
        if ent:IsWeapon() and ent.MoreDakkaSetup then
            RestoreWeapon(ent, IsValid(ent:GetOwner()) and ent:GetOwner() or nil)
        end
    end
end

Randomat:register(EVENT)