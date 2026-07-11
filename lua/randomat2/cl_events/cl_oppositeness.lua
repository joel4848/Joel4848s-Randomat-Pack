local EVENT = {}
EVENT.id = "oppositeness"

local OriginalOnSpawnMenuOpen = nil

local mouseXInverted = false
local mouseYInverted = false
local moveInverted = false
local strafeInverted = false
local jumpInverted = false
local shootInverted = false
local sprintInverted = false

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
    UpdateMouseHook()
end

local function SwitchMouseY()
    mouseYInverted = not mouseYInverted
    UpdateMouseHook()
end

local function SwitchMove()
    if moveInverted then
        hook.Remove("StartCommand", "RdmtOppositenessMoveHook")
        hook.Remove("TTTSprintKey", "RdmtOppositenessSprintKeyHook")
        moveInverted = false
    else
        hook.Add("StartCommand", "RdmtOppositenessMoveHook", function(ply, cmd)
            cmd:SetForwardMove(-cmd:GetForwardMove())
        end)

        hook.Add("TTTSprintKey", "RdmtOppositenessSprintKeyHook", function(ply)
            return IN_BACK
        end)
        moveInverted = true
    end
end

local function SwitchStrafe()
    if strafeInverted then
        hook.Remove("StartCommand", "RdmtOppositeStrafeHook")
        strafeInverted = false
    else
        hook.Add("StartCommand", "RdmtOppositeStrafeHook", function(ply, cmd)
            cmd:SetSideMove(-cmd:GetSideMove())
        end)
        strafeInverted = true
    end
end

local function SwitchJump()
    if jumpInverted then
        hook.Remove("StartCommand", "RdmtOppositeJumpHook")
        jumpInverted = false
    else
        hook.Add("StartCommand", "RdmtOppositeJumpHook", function(ply, cmd)
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
    if shootInverted then
        hook.Remove("StartCommand", "RdmtOppositenessShootHook")
        shootInverted = false
    else
        hook.Add("StartCommand", "RdmtOppositenessShootHook", function(ply, cmd)
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

-------- Net stuff --------
net.Receive("OppositenessMouseX", SwitchMouseX)
net.Receive("OppositenessMouseY", SwitchMouseY)
net.Receive("OppositenessMove", SwitchMove)
net.Receive("OppositenessStrafe", SwitchStrafe)
net.Receive("OppositenessJump", SwitchJump)
net.Receive("OppositenessShoot", SwitchShoot)
net.Receive("OppositenessSprint", SwitchSprint)
net.Receive("OppositenessEnd", RemoveHooks)

EVENT.End = RemoveHooks

Randomat:register(EVENT)
