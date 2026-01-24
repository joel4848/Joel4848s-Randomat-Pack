local EVENT = {}
EVENT.id = "dontstopmenow"

function EVENT:Begin()

    self:AddHook("SetupMove", function(ply, mv, cmd)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        local rdmtNoMoveButMouse = ply:GetNWBool("RdmtNoMoveButMouse", false)
        if rdmtNoMoveButMouse then
            -- Stop all movement
            mv:SetForwardSpeed(0)
            mv:SetSideSpeed(0)
            mv:SetUpSpeed(0)

            -- Prevent jumping and crouching
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_DUCK)))
        end
    end)

end

Randomat:register(EVENT)