local PUNISHMENT = {}

PUNISHMENT.Name = "Permanent H.U.G.E."
PUNISHMENT.Id = "undroppablehuge"

local hookIds = {}

local function UpdateHuge(huge)
    -- Don't let them drop it
    huge.AllowDrop = false
    -- Disable ironsights
    huge.NoSights = true
    -- Give them infinite ammo
    huge:SetClip1(huge.Primary.ClipSize)
end

function PUNISHMENT:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_UndroppableHUGE_" .. target:SteamID64()
    table.insert(hookIds, hookId)

    hook.Add("Think", hookId, function()
        for _, wep in ipairs(target:GetWeapons()) do
            if wep.Kind ~= WEAPON_HEAVY then continue end

            local class = WEPS.GetClass(wep)
            if class == "weapon_zm_sledge" then
                UpdateHuge(wep)
                continue
            end

            target:StripWeapon(class)
            target:Give("weapon_zm_sledge")
        end
    end)
end

function PUNISHMENT:CleanUp()
    for _, hookId in ipairs(hookIds) do
        hook.Remove("Think", hookId)
    end
    table.Empty(hookIds)
end

function PUNISHMENT:Condition()
    return not Randomat:IsEventActive("derptective")
end

Joel4848:RegisterPunishment(PUNISHMENT)