local EVENT = {}

EVENT.id = "oppositeness"

local OriginalOnSpawnMenuOpen = nil

local moveInverted   = false
local strafeInverted = false
local jumpInverted   = false
local shootInverted  = false
local sprintInverted = false
local mouseXInverted = false
local mouseYInverted = false

local inversions = {
    {active = false, text = "Forwards ↔ Backwards"},
    {active = false, text = "Left ↔ Right"},
    {active = false, text = "Jump ↔ Crouch"},
    {active = false, text = "Shoot ↔ Reload"},
    {active = false, text = "Sprint ↔ Drop Weapon"},
    {active = false, text = "Mouse X Axis"},
    {active = false, text = "Mouse Y Axis"},
}

local function RemoveHooks()
    hook.Remove("InputMouseApply", "RdmtOppositenessXMouseHook")
    hook.Remove("InputMouseApply", "RdmtOppositenessYMouseHook")
    hook.Remove("StartCommand", "RdmtOppositenessMoveHook")
    hook.Remove("TTTSprintKey", "RdmtOppositenessSprintKeyHook")
    hook.Remove("StartCommand", "RdmtOppositeStrafeHook")
    hook.Remove("StartCommand", "RdmtOppositeJumpHook")
    hook.Remove("StartCommand", "RdmtOppositenessShootHook")
    hook.Remove("StartCommand", "RdmtOppositenessSprintHook")
    hook.Remove("PlayerButtonDown", "RdmtOppositenessMenuHook")
    hook.Remove("PlayerButtonUp", "RdmtOppositenessMenuHook")

    if OriginalOnSpawnMenuOpen and GAMEMODE then
        GAMEMODE.OnSpawnMenuOpen = OriginalOnSpawnMenuOpen
    end

    mouseXInverted = false
    mouseYInverted = false
    moveInverted = false
    strafeInverted = false
    jumpInverted = false
    shootInverted = false
    sprintInverted = false
end

-- Shared mouse-inverting hook
local function UpdateMouseHook()
    -- Do nothing if neither is inverted
    if not mouseXInverted and not mouseYInverted then
        hook.Remove("InputMouseApply", "RdmtOppositenessMouseHook")
        return
    end

    hook.Add("InputMouseApply", "RdmtOppositenessMouseHook", function(cmd, x, y, ang)
        if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

        -- X Axis
        if mouseXInverted then
            local yawSensitivity = GetConVar("m_yaw"):GetFloat()
            -- Add instead of subtract to invert
            ang.yaw = ang.yaw + (x * yawSensitivity)
            ang.yaw = math.NormalizeAngle(ang.yaw)
        else
            local yawSensitivity = GetConVar("m_yaw"):GetFloat()
            ang.yaw = ang.yaw - (x * yawSensitivity)
            ang.yaw = math.NormalizeAngle(ang.yaw)
        end

        -- Y Axis
        if mouseYInverted then
            local pitchSensitivity = GetConVar("m_pitch"):GetFloat()
            -- Subtract instead of add to invert
            ang.pitch = ang.pitch - (y * pitchSensitivity)
            ang.pitch = math.NormalizeAngle(ang.pitch)
            ang.pitch = math.Clamp(ang.pitch, -89, 89)
        else
            local pitchSensitivity = GetConVar("m_pitch"):GetFloat()
            ang.pitch = ang.pitch + (y * pitchSensitivity)
            ang.pitch = math.NormalizeAngle(ang.pitch)
            ang.pitch = math.Clamp(ang.pitch, -89, 89)
        end

        cmd:SetViewAngles(ang)
        return true
    end)
end

local function SwitchMouseX()
    mouseXInverted = not mouseXInverted
    inversions[6].active = not inversions[6].active

    UpdateMouseHook()
end

local function SwitchMouseY()
    mouseYInverted = not mouseYInverted
    inversions[7].active = not inversions[7].active

    UpdateMouseHook()
end

local function SwitchMove()
    inversions[1].active = not inversions[1].active

    if moveInverted then
        hook.Remove("StartCommand", "RdmtOppositenessMoveHook")
        hook.Remove("TTTSprintKey", "RdmtOppositenessSprintKeyHook")
        moveInverted = false
    else
        hook.Add("StartCommand", "RdmtOppositenessMoveHook", function(ply, cmd)
            if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

            cmd:SetForwardMove(-cmd:GetForwardMove())
        end)

        hook.Add("TTTSprintKey", "RdmtOppositenessSprintKeyHook", function(ply)
            if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

            return IN_BACK
        end)
        moveInverted = true
    end
end

local function SwitchStrafe()
    inversions[2].active = not inversions[2].active

    if strafeInverted then
        hook.Remove("StartCommand", "RdmtOppositeStrafeHook")
        strafeInverted = false
    else
        hook.Add("StartCommand", "RdmtOppositeStrafeHook", function(ply, cmd)
            if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

            cmd:SetSideMove(-cmd:GetSideMove())
        end)
        strafeInverted = true
    end
end

local function SwitchJump()
    inversions[3].active = not inversions[3].active

    if jumpInverted then
        hook.Remove("StartCommand", "RdmtOppositeJumpHook")
        jumpInverted = false
    else
        hook.Add("StartCommand", "RdmtOppositeJumpHook", function(ply, cmd)
            if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

            if cmd:KeyDown(IN_JUMP) then
                cmd:RemoveKey(IN_JUMP)
                cmd:SetButtons(cmd:GetButtons() + IN_DUCK)
            elseif cmd:KeyDown(IN_DUCK) then
                cmd:RemoveKey(IN_DUCK)
                cmd:SetButtons(cmd:GetButtons() + IN_JUMP)
            end
        end)
        jumpInverted = true
    end
end

local function SwitchShoot()
    inversions[4].active = not inversions[4].active

    if shootInverted then
        hook.Remove("StartCommand", "RdmtOppositenessShootHook")
        shootInverted = false
    else
        hook.Add("StartCommand", "RdmtOppositenessShootHook", function(ply, cmd)
            if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

            if cmd:KeyDown(IN_ATTACK) then
                cmd:RemoveKey(IN_ATTACK)
                cmd:SetButtons(cmd:GetButtons() + IN_RELOAD)
            elseif cmd:KeyDown(IN_RELOAD) then
                cmd:RemoveKey(IN_RELOAD)
                cmd:SetButtons(cmd:GetButtons() + IN_ATTACK)
            end
        end)
        shootInverted = true
    end
end

local function SwitchSprint()
    inversions[5].active = not inversions[5].active

    if sprintInverted then
        hook.Remove("StartCommand", "RdmtOppositenessSprintHook")
        hook.Remove("PlayerButtonDown", "RdmtOppositenessMenuHook")
        hook.Remove("PlayerButtonUp", "RdmtOppositenessMenuHook")

        if OriginalOnSpawnMenuOpen and GAMEMODE then
            GAMEMODE.OnSpawnMenuOpen = OriginalOnSpawnMenuOpen
        end

        sprintInverted = false
    else
        if GAMEMODE and GAMEMODE.OnSpawnMenuOpen then
            OriginalOnSpawnMenuOpen = GAMEMODE.OnSpawnMenuOpen

            GAMEMODE.OnSpawnMenuOpen = function() end
        end

        hook.Add("StartCommand", "RdmtOppositenessSprintHook", function(ply, cmd)
            if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

            if ply ~= LocalPlayer() then return end
            if not IsValid(ply) then return end

            if cmd:KeyDown(IN_SPEED) then
                cmd:RemoveKey(IN_SPEED)

                if not ply.WasSprintPressed then
                    net.Start("OppositenessSprint")
                    net.SendToServer()
                    ply.WasSprintPressed = true
                end
            else
                ply.WasSprintPressed = false
            end

            if ply.IsOppositenessSprinting then
                cmd:SetButtons(cmd:GetButtons() + IN_SPEED)
            end
        end)

        hook.Add("PlayerButtonDown", "RdmtOppositenessMenuHook", function(ply, button)
            if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

            if ply ~= LocalPlayer() then return end

            local menuButtonName = input.LookupBinding("+menu")
            if not menuButtonName then return end

            local pressedButton = input.GetKeyName(button)

            if pressedButton == menuButtonName then
                ply.IsOppositenessSprinting = true
                return true
            end
        end)

        hook.Add("PlayerButtonUp", "RdmtOppositenessMenuHook", function(ply, button)
            if not LocalPlayer():Alive() or LocalPlayer():IsSpec() then return end

            if ply ~= LocalPlayer() then return end

            local menuButtonName = input.LookupBinding("+menu")
            if not menuButtonName then return end

            local pressedButton = input.GetKeyName(button)

            if pressedButton == menuButtonName then
                ply.IsOppositenessSprinting = false
            end
        end)

        sprintInverted = true
    end
end

function EVENT:Begin()
	local showSwappedConVar = GetConVar("randomat_oppositeness_display_current_swaps")

	surface.CreateFont("Swapped_Large", {
		font = "Verdana",
		size = 30,
		weight = 900,
		antialias = true,
		shadow = true
	})

	surface.CreateFont("Swapped_Medium", {
		font = "Verdana",
		size = 25,
		weight = 900,
		antialias = true,
		shadow = true
	})

    surface.SetFont("Swapped_Large")
    local titleW, titleH = surface.GetTextSize("Currently Swapped:")

    surface.SetFont("Swapped_Medium")
    local maxLineW = titleW
    local lineH    = 0

    for _, entry in ipairs(inversions) do
        local w, h = surface.GetTextSize(entry.text)
        if w > maxLineW then maxLineW = w end
        lineH = h
    end

    self:AddHook("HUDPaint", function()
		if showSwappedConVar:GetBool() then
			local padding = 10
			local boxX = padding
			local boxY = padding
			local boxW = maxLineW + padding * 2
			local boxH = titleH + padding * 3

			for _, entry in ipairs(inversions) do
				if entry.active then
					boxH = boxH + lineH + padding
				end
			end

			draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(0, 0, 0, 240))

			local textX = boxX + boxW / 2
			local titleY = boxY + padding

			draw.SimpleText("Currently Swapped:", "Swapped_Large", textX, titleY, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			draw.RoundedBox(0, boxX + padding * 2, titleY + titleH + padding - 2, boxW - padding * 4, 4, Color(255, 255, 255, 255))

			local textY = titleY + titleH + padding * 2

			for _, entry in ipairs(inversions) do
				LocalPlayer():PrintMessage(HUD_PRINTTALK, entry.text .. " = " .. tostring(entry.active))
				if entry.active then
					draw.SimpleText(entry.text, "Swapped_Medium", textX, textY, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
					textY = textY + lineH + padding - 2
				end
			end
		end
    end)
end

-------- Net stuff --------
net.Receive("OppositenessMouseX", SwitchMouseX)
net.Receive("OppositenessMouseY", SwitchMouseY)
net.Receive("OppositenessMove",   SwitchMove)
net.Receive("OppositenessStrafe", SwitchStrafe)
net.Receive("OppositenessJump",   SwitchJump)
net.Receive("OppositenessShoot",  SwitchShoot)
net.Receive("OppositenessSprint", SwitchSprint)
net.Receive("OppositenessEnd",    RemoveHooks)

function EVENT:End()
    RemoveHooks()
end

Randomat:register(EVENT)
