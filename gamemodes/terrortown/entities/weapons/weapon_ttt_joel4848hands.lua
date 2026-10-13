AddCSLuaFile()

if SERVER then
    util.AddNetworkString("Randomat_ScoopItUp_PunchReloadText")
end

if CLIENT then
    SWEP.PrintName     = "F*cking Hands"
    SWEP.Slot          = 8
    SWEP.ViewModelFOV  = 54
    SWEP.ViewModelFlip = false
end

SWEP.Base     = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType   = "fist"
SWEP.ViewModel  = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "none"
SWEP.Primary.Delay       = 1

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.Delay       = 1

SWEP.Kind      = WEAPON_NONE
SWEP.UseHands  = true
SWEP.AllowDrop = false

local STANDARD_AMMO_TYPES = {
    ["357"]        = true,
    ["Pistol"]     = true,
    ["AlyxGun"]    = true,
    ["SMG1"]       = true,
    ["Buckshot"]   = true,
    ["AirboatGun"] = true
}

local textDelay    = 0.5
local textDuration = 1.5

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

    local spos  = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)
    local tr = util.TraceHull({
        start  = spos,
        endpos = sdest,
        filter = owner,
        mask   = MASK_SHOT_HULL,
        mins   = Vector(-10, -10, -10),
        maxs   = Vector(10, 10, 10)
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
            local refillPercentage = GetConVar("randomat_scoopitup_refill_percentage"):GetInt()
            local reloadedWeapons  = {}

            for _, wep in ipairs(owner:GetWeapons()) do
                if IsValid(wep) and wep ~= self then
                    local ammoID   = wep:GetPrimaryAmmoType()
                    local ammoName = game.GetAmmoName(ammoID) or (wep.Primary and wep.Primary.Ammo)

                    -- Only reload weapons that use normal ammo
                    if ammoName and STANDARD_AMMO_TYPES[ammoName] then
                        local maxClip = wep.Primary and wep.Primary.ClipSize or -1
                        if maxClip > 0 then
                            local amountToAdd = math.max(1, math.ceil(maxClip * (refillPercentage / 100)))
                            local newClip = math.min(maxClip, wep:Clip1() + amountToAdd)
                            wep:SetClip1(newClip)

                            table.insert(reloadedWeapons, {
                                class   = wep:GetClass(),
                                clip    = newClip,
                                maxClip = maxClip
                            })
                        end
                    end
                end
            end

            if #reloadedWeapons > 0 then
                net.Start("Randomat_ScoopItUp_PunchReloadText")
                    net.WriteVector(tr.HitPos)
                    net.WriteTable(reloadedWeapons)
                net.Send(owner)
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

if CLIENT then
    local floatingText = {}

    net.Receive("Randomat_ScoopItUp_PunchReloadText", function()
        local hitPos          = net.ReadVector()
        local reloadedWeapons = net.ReadTable()
        local now             = CurTime()
        local ply             = LocalPlayer()

        local tempWeapons = {}

        for _, w in ipairs(reloadedWeapons) do
            local class   = w.class
            local clip    = w.clip
            local maxClip = w.maxClip

            local slot = 0
            local wep = IsValid(ply) and ply:GetWeapon(class)

            -- Get slot for sorting
            if IsValid(wep) then
                if wep.Slot then
                    slot = wep.Slot
                elseif wep.Kind then
                    if wep.Kind == WEAPON_HEAVY then slot = 2
                    elseif wep.Kind == WEAPON_PISTOL then slot = 1
                    end
                end
            else
                local fallback = weapons.Get(class)
                if fallback then
                    if fallback.Slot then
                        slot = fallback.Slot
                    elseif fallback.Kind then
                        if fallback.Kind == WEAPON_HEAVY then slot = 2
                        elseif fallback.Kind == WEAPON_PISTOL then slot = 1
                        end
                    end
                end
            end

            table.insert(tempWeapons, {
                class   = class,
                clip    = clip,
                maxClip = maxClip,
                slot    = slot
            })
        end

        -- Primary -> Secondary -> Others (higher slots first)
        local function GetSlotPriority(slot)
            if slot == 2 then return 100 end
            if slot == 1 then return 90 end
            return slot
        end

        -- Maybe this?
        table.sort(tempWeapons, function(a, b)
            return GetSlotPriority(a.slot) > GetSlotPriority(b.slot)
        end)

        for i, info in ipairs(tempWeapons) do
            local name = Randomat:GetWeaponName(info.class) or info.class

            local direction = Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(0.5, 1.5)):GetNormalized()
            local speed = math.Rand(15, 30)

            table.insert(floatingText, {
                text = name .. ": " .. info.clip .. "/" .. info.maxClip,
                pos = hitPos,
                velocity = direction * speed,
                spawnTime = now + ((i - 1) * textDelay),
                startTime = nil
            })
        end
    end)

    hook.Add("PostDrawTranslucentRenderables", "ScoopItUp_DrawFloatingText", function(bDrawingDepth, bDrawingSkybox)
        if bDrawingSkybox or #floatingText == 0 then return end

        local now = CurTime()
        local eyeAngle = EyeAngles()

        local drawAngle = Angle(eyeAngle.p, eyeAngle.y, eyeAngle.r)
        drawAngle:RotateAroundAxis(drawAngle:Up(), -90)
        drawAngle:RotateAroundAxis(drawAngle:Forward(), 90)

        for i = #floatingText, 1, -1 do
            local textData = floatingText[i]

            if now >= textData.spawnTime then
                if not textData.startTime then
                    textData.startTime = now
                end

                local age = now - textData.startTime
                if age >= textDuration then
                    table.remove(floatingText, i)
                else
                    local alpha = math.Clamp(255 * (1 - (age / textDuration)), 0, 255)
                    local currentPos = textData.pos + (textData.velocity * age)

                    cam.Start3D2D(currentPos, drawAngle, 0.1)
                        draw.SimpleTextOutlined(
                            textData.text,
                            "DermaLarge",
                            0, 0,
                            Color(255, 255, 255, alpha),
                            TEXT_ALIGN_CENTER,
                            TEXT_ALIGN_CENTER,
                            2,
                            Color(0, 0, 0, alpha)
                        )
                    cam.End3D2D()
                end
            end
        end
    end)
end