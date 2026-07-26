local EVENT = {}
EVENT.id = "bodycam"

CreateClientConVar("cl_randomat_bodycam_fisheye_enabled", 1, true, false, "Whether to enable the fisheye screen distortion", 0, 1)

----------------------------------------------------------------
-- Cache stuff
----------------------------------------------------------------

local SurfaceSetDrawColor = surface.SetDrawColor
local SurfaceDrawRect	  = surface.DrawRect
local SurfaceDrawPoly	  = surface.DrawPoly

local DrawNoTexture	 = draw.NoTexture
local TableInsert	 = table.insert
local InputIsKeyDown = input.IsKeyDown

local screenWidth  = ScrW()
local screenHeight = ScrH()

local MathRad 	   = math.rad
local MathSin 	   = math.sin
local MathCos 	   = math.cos
local MathMax	   = math.max
local MathTruncate = math.Truncate
local MathClamp	   = math.Clamp

local RenderSetStencilWriteMask		  = render.SetStencilWriteMask
local RenderSetStencilTestMask		  = render.SetStencilTestMask
local RenderSetStencilReferenceValue  = render.SetStencilReferenceValue
local RenderSetStencilCompareFunction = render.SetStencilCompareFunction
local RenderSetStencilPassOperation	  = render.SetStencilPassOperation
local RenderSetStencilFailOperation	  = render.SetStencilFailOperation
local RenderSetStencilZFailOperation  = render.SetStencilZFailOperation
local RenderClearStencil			  = render.ClearStencil
local RenderSetStencilEnable		  = render.SetStencilEnable
local RenderComputeLighting 		  = render.ComputeLighting
local RenderComputeDynamicLighting 	  = render.ComputeDynamicLighting
local RenderSuppressEngineLighting	  = render.SuppressEngineLighting

----------------------------------------------------------------
-- Adjustable bits
----------------------------------------------------------------

-- Motion blur
local NV_MOTION_BLUR = true
local NV_BLUR_INTENSITY = 1.0

-- Makes things a LITTLE bit wiggly, not sure if I like it
local NV_USE_DISTORT = true

-- Draws lines over the screen
local NV_DRAW_SCANLINES = true
local NV_SCANLINE_ALPHA = 255

-- the green colour-grade applied over everything while night vision is on
local NV_COLOR_BRIGHTNESS = 0.8
local NV_COLOR_CONTRAST = 1.1
local NV_COLOR_ADD_GREEN = -0.1
local NV_COLOR_MUL_GREEN = 0.1

-- FLIR
-- -0.05 at brightness 0.44; -0.4 at brightness >7?
local IR_BRIGHTNESS = -0.05 -- -0.1 -- -0.65
local IR_CONTRAST = 1.5 -- 1 -- 2.2
-- 0.4 at B0.44; 0.55 at B>7?
local IR_ENTITY_BRIGHTNESS = 0.4 -- 0.4

-- Add illumnation so it actually does something nightvisiony
local NV_ILLUM_RADIUS = 2048
-- local NV_ILLUM_BRIGHTNESS = 20

-- ISIB ('Illumination-Smart Intensity Balancing' apparently) reduces the NV light in brighter places
local NV_USE_ISIB = true
local NV_ISIB_SENSITIVITY = 10 -- 2 to 10

function EVENT:Begin()
    LocalPlayer():PrintMessage(HUD_PRINTTALK, "If the fisheye effect makes you nauseous, run")
    LocalPlayer():PrintMessage(HUD_PRINTTALK, "'cl_randomat_bodycam_fisheye_enabled 0' in the console")

    ----------------------------------------------------------------
    -- Fisheye and border
    ----------------------------------------------------------------

    local function DrawOval(x, y, radiusX, radiusY, seg)
        local oval = {}
        for i = 0, seg do
            local a = MathRad((i / seg) * -360)
            TableInsert(oval, {
                x = x + MathSin(a) * radiusX,
                y = y + MathCos(a) * radiusY,
                u = MathSin(a) / 2 + 0.5,
                v = MathCos(a) / 2 + 0.5
            })
        end
        SurfaceDrawPoly(oval)
    end

    ------------------------------------------------------------------
    -- HUD Mode Status Text
    ------------------------------------------------------------------
    surface.CreateFont("HUD_ModeLarge", {
        font = "Verdana",
        size = 40,
        weight = 900,
        antialias = true,
        shadow = true
    })

    surface.CreateFont("HUD_HintLarge", {
        font = "Verdana",
        size = 28,
        weight = 500,
        antialias = true,
        shadow = true
    })

    local modeNames = {
        [0] = "Normal",
        [1] = "Night Vision",
        [2] = "FLIR"
    }

    local function DrawHUDText()
        local currentModeText = modeNames[NV_Mode] or "Normal"

        local textX = 50
        local textY = 50

        draw.SimpleText(
            "MODE: " .. currentModeText,
            "HUD_ModeLarge",
            textX,
            textY,
            Color(50, 255, 50, 255),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP
        )

        draw.SimpleText(
            "Press 'G' to change",
            "HUD_HintLarge",
            textX,
            textY + 40,
            Color(200, 200, 200, 220),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP
        )
    end

    hook.Add("HUDPaint", "RdmtBodycam_FisheyeBorder", function()
        RenderSetStencilWriteMask(0xFF)
        RenderSetStencilTestMask(0xFF)
        RenderSetStencilReferenceValue(0)
        RenderSetStencilCompareFunction(STENCIL_ALWAYS)
        RenderSetStencilPassOperation(STENCIL_KEEP)
        RenderSetStencilFailOperation(STENCIL_KEEP)
        RenderSetStencilZFailOperation(STENCIL_KEEP)
        RenderClearStencil()
        RenderSetStencilEnable(true)
        RenderSetStencilReferenceValue(1)
        RenderSetStencilCompareFunction(STENCIL_NEVER)
        RenderSetStencilFailOperation(STENCIL_REPLACE)
        DrawNoTexture()
        SurfaceSetDrawColor(COLOR_WHITE)
        local centerX = screenWidth / 2
        local centerY = screenHeight / 2
        local radiusX = screenWidth * 0.478
        local radiusY = screenHeight * 0.478
        DrawOval(centerX, centerY, radiusX, radiusY, 100)
        RenderSetStencilCompareFunction(STENCIL_NOTEQUAL)
        RenderSetStencilFailOperation(STENCIL_KEEP)
        SurfaceSetDrawColor(0, 0, 0, 255)
        SurfaceDrawRect(0, 0, screenWidth, screenHeight)
        RenderSetStencilEnable(false)

        DrawHUDText()
    end)

    hook.Add("RenderScreenspaceEffects", "RdmtBodycam_FisheyeEffect", function()
        local enableFisheye = GetConVar("cl_randomat_bodycam_fisheye_enabled"):GetBool()
        if not enableFisheye then return end

        DrawMaterialOverlay("models/props_c17/fisheyelens", -0.1)
    end)

    hook.Add("CalcView", "RdmtBodycam_FisheyeCorrection", function(ply, pos, angles, fov)
        local enableFisheye = GetConVar("cl_randomat_bodycam_fisheye_enabled"):GetBool()
        if not enableFisheye then return end

        local correctionOffset = 0.00016 * fov * fov + 0.01216 * fov + 0.195
        correctionOffset = MathMax(0, correctionOffset)
        local viewAngles = Angle(angles.p, angles.y - correctionOffset, angles.r)
        local view = {
            origin = pos,
            angles = viewAngles,
            fov = fov,
            drawviewer = false
        }
        return view
    end)

    ----------------------------------------------------------------
    -- NV/FLIR state/colour setup
    ----------------------------------------------------------------

    NV_Mode = NV_Mode or 0

    local sndOn  = Sound("items/nvg_on.wav")
    local sndOff = Sound("items/nvg_off.wav")

    local NightVisionColor = {
        ["$pp_colour_addr"] = -1,
        ["$pp_colour_addg"] = NV_COLOR_ADD_GREEN,
        ["$pp_colour_addb"] = -1,
        ["$pp_colour_brightness"] = NV_COLOR_BRIGHTNESS,
        ["$pp_colour_contrast"] = NV_COLOR_CONTRAST,
        ["$pp_colour_colour"] = 0,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = NV_COLOR_MUL_GREEN,
        ["$pp_colour_mulb"] = 0
    }

    local InfraredColor = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = IR_BRIGHTNESS,
        ["$pp_colour_contrast"] = IR_CONTRAST,
        ["$pp_colour_colour"] = 0,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }

    local InfraredEntityColor = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = IR_ENTITY_BRIGHTNESS,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 0,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }

    ----------------------------------------------------------------
    -- Dynamic brightness stuff
    ----------------------------------------------------------------

    local downVector = Vector(0, 0, -1)

    local function GetAmbientLightLevel(pos)
        local lighting = RenderComputeLighting(pos, downVector)
        local dynamicLighting = RenderComputeDynamicLighting(pos, downVector)
        return (lighting - dynamicLighting):Length() * 33
    end

    local smoothedAmbient = 0
    local transitionSpeed = 3 -- lower is slower, higher is faster

    local mapAmbientVec = render.GetAmbientLightColor()
    local mapAmbientScalar = (mapAmbientVec.x + mapAmbientVec.y + mapAmbientVec.z) / 3
    local ambientBias = MathClamp(mapAmbientScalar * 1.2, 0, 0.5)

    hook.Add("Think", "RdmtBodycam_FlirBrightness", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local frameTime = FrameTime()
        local eyePos = ply:EyePos()
        local ambient = MathTruncate(GetAmbientLightLevel(eyePos), 3)

        local targetClamped = MathClamp(ambient, 0, 7)

        smoothedAmbient = Lerp(frameTime * transitionSpeed, smoothedAmbient, targetClamped)

        local ADJUSTED_IR_BRIGHTNESS = -(((9 / 140) * smoothedAmbient) + 0.04) + (ambientBias * 0.1 )
        InfraredColor["$pp_colour_brightness"] = ADJUSTED_IR_BRIGHTNESS

        local ADJUSTED_IR_ENTITY_BRIGHTNESS = ((5 / 140) * smoothedAmbient) + (2 / 8) + (ambientBias * 0.5)
        InfraredEntityColor["$pp_colour_brightness"] = ADJUSTED_IR_ENTITY_BRIGHTNESS
    end)

    ----------------------------------------------------------------
    -- NV screen effects
    ----------------------------------------------------------------

    hook.Add("RenderScreenspaceEffects", "RdmtBodycam_NVScreenEffects", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if NV_Mode ~= 1 then return end

        if NV_USE_DISTORT then
            DrawMaterialOverlay("models/shadertest/shader3", 0.0001)
        end

        if NV_MOTION_BLUR then
            DrawMotionBlur(0.05 * NV_BLUR_INTENSITY, 0.2 * NV_BLUR_INTENSITY, 0.023 * NV_BLUR_INTENSITY)
        end

        NightVisionColor["$pp_colour_brightness"] = NV_COLOR_BRIGHTNESS
        NightVisionColor["$pp_colour_contrast"] = NV_COLOR_CONTRAST
        DrawColorModify(NightVisionColor)
    end)

    local scanLineGap = 10
    NV_SCANLINE_ALPHA = 50

    hook.Add("HUDPaintBackground", "RdmtBodycam_NVScalines", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if NV_Mode ~= 1 then return end

        -- Draw scanlines
        if NV_DRAW_SCANLINES then
            DrawNoTexture()
            SurfaceSetDrawColor(25, 50, 25, NV_SCANLINE_ALPHA)

            local scrollSpeed = 20 -- higher = faster

            local yOffset = (CurTime() * scrollSpeed) % scanLineGap

            for lineY = yOffset - scanLineGap, screenHeight, scanLineGap do
                local t = (2 * lineY / screenHeight) - 1
                local y = 1 - math.abs(t)^8
                thisAlpha = NV_SCANLINE_ALPHA * y

                SurfaceSetDrawColor(25, 50, 25, thisAlpha)
                SurfaceDrawRect(0, lineY, screenWidth, 1)
            end
        end
    end)

    ----------------------------------------------------------------
    -- FLIR
    ----------------------------------------------------------------

    local function IsThermalWorldEntity(ent)
        if not IsValid(ent) then return false end

        local class = ent:GetClass()

        if class:find("cl_") or class:find("env_") or class:find("viewmodel") then
            return false
        end

        if ent:IsWeapon()
            or class:find("ammo")
            or class:find("prop_physics")
            or class:find("prop_dynamic")
            or class:find("prop_ragdoll")
            or class:find("item_") then
            return true
        end

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) and phys:IsMoveable() then
            return true
        end

        return false
    end

    hook.Add("PostDrawOpaqueRenderables", "RdmtBodycam_FLIRGlowingEntities", function()
        if NV_Mode ~= 2 then return end

        RenderClearStencil()
        RenderSetStencilEnable(true)

        RenderSetStencilFailOperation(STENCIL_KEEP)
        RenderSetStencilZFailOperation(STENCIL_KEEP)
        RenderSetStencilPassOperation(STENCIL_REPLACE)
        RenderSetStencilCompareFunction(STENCIL_ALWAYS)

        RenderSuppressEngineLighting(true)

        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and not ent:IsEffectActive(EF_NODRAW) then

                -- Higher brightness for players/NPCs
                if ent:IsNPC() or ent:IsPlayer() then
                    RenderSetStencilReferenceValue(1)
                    ent:DrawModel()

                -- Slightly the less higher brightness for other things we're making glow
                elseif IsThermalWorldEntity(ent) then
                    RenderSetStencilReferenceValue(2)
                    ent:DrawModel()
                end

            end
        end

        RenderSuppressEngineLighting(false)

        RenderSetStencilCompareFunction(STENCIL_EQUAL)
        RenderSetStencilReferenceValue(1)
        DrawColorModify(InfraredEntityColor)

        RenderSetStencilReferenceValue(2)

        local origBrightness = InfraredEntityColor["$pp_colour_brightness"]
        InfraredEntityColor["$pp_colour_brightness"] = origBrightness / 2

        DrawColorModify(InfraredEntityColor)

        InfraredEntityColor["$pp_colour_brightness"] = origBrightness

        RenderSetStencilEnable(false)
    end)

    ------------------------------------------------------------------
    -- Calculate Gun Heat
    ------------------------------------------------------------------
    local gunHeat = 0

    hook.Add("PostEntityFireBullets", "RdmtBodycam_FLIRTrackGunHeat", function(ent, bullet)
        if not IsValid(ent) or ent ~= LocalPlayer() then return end

        local wep = ent:GetActiveWeapon()
        if IsValid(wep) then
            local maxClip = wep:GetMaxClip1()
            if maxClip <= 0 then maxClip = 30 end

            gunHeat = math.Clamp(gunHeat + (2 / maxClip), 0, 1)
        end
    end)


    hook.Add("Think", "RdmtBodycam_FLIRCoolGunHeat", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        if gunHeat > 0 then
            local frameTime = FrameTime()
            gunHeat = Lerp(frameTime * 0.1, gunHeat, 0)

            if gunHeat < 0.001 then gunHeat = 0 end
        end
    end)

    ------------------------------------------------------------------
    -- Weapon Heat Pass
    ------------------------------------------------------------------

    hook.Add("PreDrawViewModel", "RdmtBodycam_WeaponHeatPre", function(vm, ply, weapon)
        if NV_Mode ~= 2 then return end

        render.ClearStencil()
        render.SetStencilEnable(true)

        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)

        render.SetStencilReferenceValue(3)
        RenderSuppressEngineLighting(true)
    end)

    hook.Add("PostDrawViewModel", "RdmtBodycam_WeaponHeatPost", function(vm, ply, weapon)
        if NV_Mode ~= 2 then return end

        RenderSuppressEngineLighting(false)

        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilReferenceValue(3)

        local origBrightness = InfraredEntityColor["$pp_colour_brightness"] or 1
        local dynamicBrightness = (origBrightness * 0.35) + (gunHeat * origBrightness)

        local gunColorTable = table.Copy(InfraredEntityColor)
        gunColorTable["$pp_colour_brightness"] = dynamicBrightness

        DrawColorModify(gunColorTable)
        render.SetStencilEnable(false)
    end)

    ------------------------------------------------------------------
    -- Hand heat (doesn't seem to work?)
    ------------------------------------------------------------------
    hook.Add("PreDrawPlayerHands", "RdmtBodycam_HandHeatPre", function(hands, vm, ply, weapon)
        if NV_Mode ~= 2 then return end

        render.SetStencilEnable(true)

        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)

        render.SetStencilReferenceValue(1)
        RenderSuppressEngineLighting(true)
    end)

    hook.Add("PostDrawPlayerHands", "RdmtBodycam_HandHeatPost", function(hands, vm, ply, weapon)
        if NV_Mode ~= 2 then return end

        RenderSuppressEngineLighting(false)

        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilReferenceValue(1)

        DrawColorModify(InfraredEntityColor)
        render.SetStencilEnable(false)
    end)

    hook.Add("RenderScreenspaceEffects", "RdmtBodycam_FLIRBackground", function()
        if NV_Mode ~= 2 then return end

        InfraredColor["$pp_colour_contrast"] = IR_CONTRAST + (ambientBias * 0.8)

        DrawColorModify(InfraredColor)
    end)

    ----------------------------------------------------------------
    -- Nightvision
    ----------------------------------------------------------------

    local NV_AmbientLevel = 0
    local NV_ISIBScale = 1
    local NV_ISIB_SPEED = 1

    hook.Add("Think", "RdmtBodycam_NVUpdateIllumination", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if NV_Mode ~= 1 then return end

        local frameTime = FrameTime()
        local eyePos = ply:EyePos()

        NV_AmbientLevel = GetAmbientLightLevel(eyePos)

        if NV_USE_ISIB then
            local target = 1 / MathMax(1, NV_AmbientLevel * NV_ISIB_SENSITIVITY * 0.1)
            target = MathClamp(target, 0.15, 1)
            NV_ISIBScale = Lerp(frameTime * NV_ISIB_SPEED, NV_ISIBScale, target)
        else
            NV_ISIBScale = 1
        end

        local dlight = DynamicLight(ply:EntIndex())
        if not dlight then return end

        dlight.Pos = ply:GetPos()
        dlight.r = 10
        dlight.g = 10
        dlight.b = 10
        dlight.Brightness = 0
        dlight.MinLight = 1 * NV_ISIBScale
        dlight.Size = NV_ILLUM_RADIUS -- * NV_ISIBScale
        dlight.Decay = math.huge
        dlight.DieTime = CurTime() + 0.1
    end)

    ------------------------------------------------------------------
    -- Make NV illumination not illumnate hands/held weapon
    ------------------------------------------------------------------

    hook.Add("PreDrawViewModel", "NV_SuppressIllumination_VM", function(vm, ply, weapon)
        if NV_Mode == 1 then
            RenderSuppressEngineLighting(true)
        end
    end)

    hook.Add("PostDrawViewModel", "NV_SuppressIllumination_VM_Post", function(vm, ply, weapon)
        if NV_Mode == 1 then
            RenderSuppressEngineLighting(false)
        end
    end)

    hook.Add("PreDrawPlayerHands", "NV_SuppressIllumination_Hands", function(hands, vm, ply, weapon)
        if NV_Mode == 1 then
            RenderSuppressEngineLighting(true)
        end
    end)

    hook.Add("PostDrawPlayerHands", "NV_SuppressIllumination_Hands_Post", function(hands, vm, ply, weapon)
        if NV_Mode == 1 then
            RenderSuppressEngineLighting(false)
        end
    end)

    ----------------------------------------------------------------
    -- Mode changing bits
    ----------------------------------------------------------------

    local function SetMode(newMode)
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        if newMode == NV_Mode then return end

        if newMode == 1 then
            surface.PlaySound(sndOn)
        elseif NV_Mode == 1 then
            surface.PlaySound(sndOff)
        end

        NV_Mode = newMode
    end

    local cc_e
    local cc_r
    local cc_g
    local cc_b
    local cc_t
    local orig_cc_e
    local orig_cc_r
    local orig_cc_g
    local orig_cc_b
    local orig_cc_t

    local function GetCrosshairOriginalValues()
        cc_e = GetConVar("ttt_crosshair_color_enable")
        cc_r = GetConVar("ttt_crosshair_color_r")
        cc_g = GetConVar("ttt_crosshair_color_g")
        cc_b = GetConVar("ttt_crosshair_color_b")
        cc_t = GetConVar("ttt_crosshair_thickness")
        orig_cc_e = cc_e:GetBool()
        orig_cc_r = cc_r:GetInt()
        orig_cc_g = cc_g:GetInt()
        orig_cc_b = cc_b:GetInt()
        orig_cc_t = cc_t:GetInt()
    end

    gotCrosshairOriginalValues = false

    self:AddHook("PlayerButtonDown", function(ply, button)
        if button ~= KEY_G then return end

        if not gotCrosshairOriginalValues then
            GetCrosshairOriginalValues()
            gotCrosshairOriginalValues = true
        end

        local nextMode = (NV_Mode + 1) % 3
        SetMode(nextMode)

        if nextMode == 1 then
            cc_e:SetBool(true)
            cc_r:SetInt(0)
            cc_g:SetInt(0)
            cc_b:SetInt(0)
            cc_t:SetInt(3)
        else
            cc_e:SetBool(orig_cc_e)
            cc_r:SetInt(orig_cc_r)
            cc_g:SetInt(orig_cc_g)
            cc_b:SetInt(orig_cc_b)
            cc_t:SetInt(orig_cc_t)
        end

        return true
    end)

    self:AddHook("PlayerBindPress", function(_, bind, pressed, key)
        if pressed and bind:find("impulse 201") and key == KEY_G then
            return true
        end
    end)
end

function EVENT.End()
    hook.Remove("RenderScreenspaceEffects", "RdmtBodycam_FisheyeEffect")
    hook.Remove("HUDPaint", "RdmtBodycam_FisheyeBorder")
    hook.Remove("CalcView", "RdmtBodycam_FisheyeCorrection")

    hook.Remove("RenderScreenspaceEffects", "RdmtBodycam_NVScreenEffects")
    hook.Remove("HUDPaintBackground", "RdmtBodycam_NVScalines")
    hook.Remove("Think", "RdmtBodycam_NVUpdateIllumination")

    hook.Remove("PreDrawViewModel", "NV_SuppressIllumination_VM")
    hook.Remove("PostDrawViewModel", "NV_SuppressIllumination_VM_Post")
    hook.Remove("PreDrawPlayerHands", "NV_SuppressIllumination_Hands")
    hook.Remove("PostDrawPlayerHands", "NV_SuppressIllumination_Hands_Post")

    hook.Remove("PostDrawOpaqueRenderables", "RdmtBodycam_FLIRGlowingEntities")
    hook.Remove("RenderScreenspaceEffects", "RdmtBodycam_FLIRBackground")

    hook.Remove("Think", "RdmtBodycam_FlirBrightness")
    hook.Remove("PlayerBindPress", "RdmtBodycam_ChangeMode")

    hook.Remove("PostEntityFireBullets", "RdmtBodycam_FLIRTrackGunHeat")
    hook.Remove("Think", "RdmtBodycam_FLIRCoolGunHeat")
    hook.Remove("PreDrawViewModel", "RdmtBodycam_WeaponHeatPre")
    hook.Remove("PostDrawViewModel", "RdmtBodycam_WeaponHeatPost")
    hook.Remove("PreDrawPlayerHands", "RdmtBodycam_HandHeatPre")
    hook.Remove("PostDrawPlayerHands", "RdmtBodycam_HandHeatPost")
end

Randomat:register(EVENT)