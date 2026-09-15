AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "F*cking Hands"
    SWEP.Slot = 8
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType = "fist"
SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 1

SWEP.Kind = WEAPON_NONE
SWEP.UseHands = true
SWEP.AllowDrop = false

local STANDARD_AMMO_TYPES = {
    ["357"] = true,
    ["Pistol"] = true,
    ["AlyxGun"] = true,
    ["SMG1"] = true,
    ["Buckshot"] = true,
    ["AirboatGun"] = true
}

function SWEP:PrimaryAttack()
    local delay = GetConVar("randomat_scoopitup_punch_delay"):GetFloat()
    self:SetNextPrimaryFire(CurTime() + delay)
    self:SetNextSecondaryFire(CurTime() + delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner.LagCompensation then
        owner:LagCompensation(true)
    end

    local anim = math.random() < 0.5 and "fists_right" or "fists_left"
    local vm = owner:GetViewModel()
    if IsValid(vm) then
        vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
    end
    owner:SetAnimation(PLAYER_ATTACK1)
    owner:ViewPunch(Angle(4, 0, 0))

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)
    local tr = util.TraceHull({
        start = spos,
        endpos = sdest,
        filter = owner,
        mask = MASK_SHOT_HULL,
        mins = Vector(-10, -10, -10),
        maxs = Vector(10, 10, 10)
    })

    self:EmitSound(Sound("Weapon_Crowbar.Single"))

    if tr.HitWorld or IsValid(tr.Entity) then
        self:SendWeaponAnim(ACT_VM_HITCENTER)

        -- Show impact particles
        if not (CLIENT and not IsFirstTimePredicted()) then
            local edata = EffectData()
            edata:SetStart(spos)
            edata:SetOrigin(tr.HitPos)
            edata:SetNormal(tr.HitNormal or tr.Normal)
            edata:SetSurfaceProp(tr.SurfaceProps)
            edata:SetHitBox(tr.HitBox)
            edata:SetEntity(tr.Entity or NULL)
            util.Effect("Impact", edata)
        end

        if SERVER then
            local refillPct = GetConVar("randomat_scoopitup_refill_percentage"):GetInt()
            for _, wep in ipairs(owner:GetWeapons()) do
                if IsValid(wep) and wep ~= self then
                    local ammoID = wep:GetPrimaryAmmoType()
                    local ammoName = game.GetAmmoName(ammoID) or (wep.Primary and wep.Primary.Ammo)

                    -- Only reload weapons that use normal ammo
                    if ammoName and STANDARD_AMMO_TYPES[ammoName] then
                        local maxClip = wep.Primary and wep.Primary.ClipSize or -1
                        if maxClip > 0 then
                            local amountToAdd = math.max(1, math.ceil(maxClip * (refillPct / 100)))
                            local newClip = math.min(maxClip, wep:Clip1() + amountToAdd)
                            wep:SetClip1(newClip)
                        end
                    end
                end
            end
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if owner.LagCompensation then
        owner:LagCompensation(false)
    end
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
end

function SWEP:Deploy()
    local owner = self:GetOwner()
    if IsValid(owner) then
        local vm = owner:GetViewModel()
        if IsValid(vm) then
            vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
        end
    end
    return true
end

function SWEP:OnDrop()
    self:Remove()
end