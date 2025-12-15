local EVENT = {}
EVENT.id = "rtexvision"

local function IsPlayerValid(p)
    return IsPlayer(p) and p:Alive() and not p:IsSpec()
end

local function SetHidden(ply, hidden)
    ply:SetNoDraw(hidden)

    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        wep:SetNoDraw(hidden)
    end
end

function EVENT:Begin()
    self:AddHook("Think", function()
        local client = LocalPlayer()
        if not IsPlayerValid(client) then return end

        local can_see = client:GetNWBool("RdmtRTexVisionActive", false)

        for _, ply in ipairs(player.GetAll()) do
            if ply ~= client and IsPlayerValid(ply) then
                SetHidden(ply, not can_see)
            end
        end
    end)

    self:AddHook("TTTTargetIDPlayerBlockIcon", function(ply, cli)
        if ply ~= cli and not cli:GetNWBool("RdmtRTexVisionActive", false) then
            return true
        end
    end)

    self:AddHook("TTTTargetIDPlayerBlockInfo", function(ply, cli)
        if ply ~= cli and not cli:GetNWBool("RdmtRTexVisionActive", false) then
            return true
        end
    end)
end

function EVENT:End()
    for _, ply in ipairs(player.GetAll()) do
        ply:SetNoDraw(false)
        
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            wep:SetNoDraw(false)
        end
    end
end

Randomat:register(EVENT)
