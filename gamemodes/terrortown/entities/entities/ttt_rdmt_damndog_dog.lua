AddCSLuaFile()

Joel4848 = Joel4848 or {}

ENT.Type = "anim"

local dogEntity = dogEntity or nil

function ENT:Initialize()
    -- Use SOLID_BBOX or SOLID_VPHYSICS, but force the move type to NONE or freeze motion
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE) -- Prevents physics simulation from breaking the skeleton
    self:SetSolid(SOLID_VPHYSICS)
    self:SetHealth(1)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        -- phys:EnableGravity(false)
        -- phys:EnableMotion(false) -- ABSOLUTELY REQUIRED: Stops the limbs from stretching/falling
    end

    -- Use standard HL2 Activity Enums to force a proper standing stance
    -- ACT_HL2MP_IDLE is the standard generic standard stand animation for playermodels
    local sequence = self:SelectWeightedSequence(ACT_HL2MP_IDLE)

    -- Fallback to standard idle if the playermodel uses basic animations
    if sequence == -1 then
        sequence = self:SelectWeightedSequence(ACT_IDLE)
    end

    if sequence ~= -1 then
        self:SetSequence(sequence)
        self:SetPlaybackRate(1.0)
    end
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmgInfo)
    self:Remove()
    return true
end

function ENT:Think()
end

function ENT:Break()
end

function ENT:Touch(ply)
    if IsValid(ply) and ply:IsPlayer() and ply:Alive() and not ply.inRagdoll then
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)

        ply.ragdollDog = self
        Joel4848:RagdollPlayer(ply)
    end
end