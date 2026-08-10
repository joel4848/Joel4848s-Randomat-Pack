local EVENT = {}

EVENT.Title = "Futterbingers"
EVENT.Description = "Pick up every weapon you touch!"
EVENT.id = "futterbingers"
EVENT.Categories = {"lowimpact"}

function EVENT:Begin()
    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if not IsValid(ply) or not IsValid(wep) or not ply:Alive() then return end

        local targetKind = wep.Kind
        local wepClass = wep:GetClass()

        local slotEmpty = true

        if targetKind then
            for _, carriedWep in ipairs(ply:GetWeapons()) do
                if carriedWep.Kind == targetKind then
                    slotEmpty = false
                end
            end
        end

        if slotEmpty then return end

        if wep.futterbingersImmune then return end

        if targetKind then
            for _, carriedWep in ipairs(ply:GetWeapons()) do
                if carriedWep.Kind == targetKind and carriedWep:GetClass() ~= wepClass then

                    local oldOnDrop = carriedWep.OnDrop
                    carriedWep.futterbingersImmune = true

                    carriedWep.OnDrop = function(droppedWep, ...)

                        local timerName = "RdmtFutterbingers_" .. droppedWep:EntIndex()
                        timer.Create(timerName, 1, 1, function()
                            if IsValid(droppedWep) then
                                droppedWep.futterbingersImmune = false
                            end
                        end)

                        local activeWep = ply:GetActiveWeapon() or nil

                        if activeWep and activeWep == droppedWep then
                            wep.ShouldEquip = true
                        end

                        if oldOnDrop then
                            return oldOnDrop(droppedWep, ...)
                        end
                    end

                    ply:DropWeapon(carriedWep)
                end
            end
        end

        -- return true
    end)

    self:AddHook("WeaponEquip", function(wep, ply)
        if not IsValid(ply) or not IsValid(wep) then return end

        if wep.ShouldEquip then
            local weaponClass = wep:GetClass()

            timer.Simple(0.15, function()
                if IsValid(ply) and IsValid(wep) then
                    ply:SelectWeapon(weaponClass)
                    wep.ShouldEquip = nil
                end
            end)
        end
    end)
end

Randomat:register(EVENT)