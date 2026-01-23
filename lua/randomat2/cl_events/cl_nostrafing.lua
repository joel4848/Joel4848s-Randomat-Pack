local EVENT = {}
EVENT.id = "nostrafing"

function EVENT:Begin()

    self:AddHook("SetupMove", function(ply, mv, cmd)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        mv:SetSideSpeed(0)
    end)

end

Randomat:register(EVENT)