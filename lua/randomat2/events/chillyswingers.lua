local EVENT = {}

local eventnames = {}

table.insert(eventnames, "Chilly Swingers")
table.insert(eventnames, "Glacial Knockers")

EVENT.Title = "Chilly Swingers"
EVENT.Description = "Forces everyone to use freeze guns, homerun bats and grenades"
EVENT.id = "chillyswingers"
EVENT.Categories = {"item", "rolechange", "largeimpact"}
EVENT.type = EVENT_TYPE_WEAPON_OVERRIDE

function EVENT:BeforeEventTrigger(ply, options, ...)
    self.Title = table.Random(eventnames)
end

function EVENT:HandleRoleWeapons(ply)
    local updated = false
    local changing_teams = Randomat:IsMonsterTeam(ply) or Randomat:IsIndependentTeam(ply)

    -- Convert all bad guys to traitors so we don't have to worry about fighting with special weapon replacement logic
    if (Randomat:IsTraitorTeam(ply) and ply:GetRole() ~= ROLE_TRAITOR) or changing_teams then
        Randomat:SetRole(ply, ROLE_TRAITOR)
        updated = true
    elseif Randomat:IsJesterTeam(ply) then
        Randomat:SetRole(ply, ROLE_INNOCENT)
        updated = true
    end

    -- Remove role weapons from anyone on the traitor team now
    if updated then
        self:StripRoleWeapons(ply)
    end

    return updated, changing_teams
end

function EVENT:Begin()

    -- Transform all jesters to innocents and independents to traitors so we know there can only be an innocent or traitor win
    local new_traitors = {}

    for _, v in ipairs(self:GetAlivePlayers()) do
        local _, new_traitor = self:HandleRoleWeapons(v)

        if new_traitor then
            table.insert(new_traitors, v)
        end
    end

    SendFullStateUpdate()
    self:NotifyTeamChange(new_traitors, ROLE_TEAM_TRAITOR)

    -- Prevent players from picking up weapons from the ground (This seems better than deleting all spawned weapons?)
    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if not IsValid(wep) then return false end

        local class = WEPS.GetClass(wep)
        
        -- Allow freeze guns and homerun bats
        if class == "weapon_ttt_freezegun" or class == "weapon_ttt_homebat" or class == "weapon_ttt_unarmed" then
            return true
        end

        -- Allow grenade-type weapons only if player doesn't already have one
        if wep.Kind == WEAPON_NADE then
            for _, ply_wep in ipairs(ply:GetWeapons()) do
                if IsValid(ply_wep) and ply_wep.Kind == WEAPON_NADE then
                    return false -- Player already has a grenade
                end
            end
            return true
        end

        return false
    end)

    for i, ply in pairs(self:GetAlivePlayers()) do
        
        -- Strip all living players' weapons except grenades
        for _, wep in ipairs(ply:GetWeapons()) do
            if IsValid(wep) and wep.Kind ~= WEAPON_NADE then
                ply:StripWeapon(wep:GetClass())
            end
        end

        ply:SetFOV(0, 0.2)

        -- Give everyone a freeze gun and a homerun bat
        ply:Give("weapon_ttt_freezegun")
        ply:Give("weapon_ttt_homebat")
        ply:Give("weapon_ttt_unarmed")
    end

    self:AddHook("PlayerSpawn", function(ply)
        timer.Simple(1, function()
            -- Strip all living players' weapons except grenades
            for _, wep in ipairs(ply:GetWeapons()) do
                if IsValid(wep) and wep.Kind ~= WEAPON_NADE then
                    ply:StripWeapon(wep:GetClass())
                end
            end

            ply:SetFOV(0, 0.2)
            ply:Give("weapon_ttt_freezegun")
            ply:Give("weapon_ttt_homebat")
            ply:Give("weapon_ttt_unarmed")
        end)
    end)

    -- Prevents players from buying non-passive items
    self:AddHook("TTTCanOrderEquipment", function(ply, id, is_item)
        if not IsValid(ply) then return end

        if not is_item then
            ply:PrintMessage(HUD_PRINTCENTER, "Passive items only!")
            ply:ChatPrint("You can only buy passive items during '" .. Randomat:GetEventTitle(EVENT) .. "'\nYour purchase has been refunded.")

            return false
        end
    end)

    -- 1 second delay to the infinite ammo hook
    timer.Simple(1, function()
        self:AddHook("Think", function()
            for _, ply in pairs(self:GetAlivePlayers()) do
                local wep = ply:GetActiveWeapon()
                if not IsValid(wep) then continue end
            
                local class = wep:GetClass()
            
                -- Always keep homerun bat 'clip' full
                if class == "weapon_ttt_homebat" then
                    if wep.Primary and wep.Primary.ClipSize then
                        wep:SetClip1(wep.Primary.ClipSize)
                    end
                
                -- Freeze gun stuff:
                elseif class == "weapon_ttt_freezegun" then
                    local ammoType = wep:GetPrimaryAmmoType()
                    if ammoType < 0 then continue end
                
                    -- Limit clip to 1
                    if wep:Clip1() > 1 then
                        wep:SetClip1(1)
                    end
                
                    -- Force 1 reserve ammo
                    ply:SetAmmo(1, ammoType)
                
                    -- Auto-reload
                    if wep:Clip1() == 0
                        and ply:GetAmmoCount(ammoType) > 0
                        and not wep.Randomat_AutoReloading then
                        
                        wep.Randomat_AutoReloading = true
                        wep:Reload()
                    end
                
                    -- Reset flag once the clip is refilled
                    if wep:Clip1() > 0 then
                        wep.Randomat_AutoReloading = false
                    end
                end
            end
        end)
    end)

end

function EVENT:End()
    for i, ply in ipairs(self:GetAlivePlayers()) do
        ply:Give("weapon_zm_improvised")
        ply:Give("weapon_zm_carry")
        ply:Give("weapon_ttt_unarmed")
    end
end

function EVENT:Condition()
    local freezegunexists = WEPS.GetStored("weapon_ttt_freezegun") ~= nil
    local homerunbatexists = WEPS.GetStored("weapon_ttt_homebat") ~= nil
    return freezegunexists and homerunbatexists
end

Randomat:register(EVENT)