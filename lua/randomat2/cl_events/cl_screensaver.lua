local EVENT = {}
EVENT.id = "screensaver"

function EVENT:Begin()
    local MathAbs      = math.abs
    local screenWidth  = ScrW()
    local screenHeight = ScrH()

    local vX = 2
    local vY = 2
    local currentX, currentY

    self:AddHook("TTTHUDInfoPositionOverride", function(client, x, y, width, height)
        if not currentX or not currentY then
            currentX = x
            currentY = y
        end

        currentX = currentX + vX
        currentY = currentY + vY

        -- Side bounces
        if currentX <= 0 then
            currentX = 0
            vX = MathAbs(vX)
        elseif currentX + width >= screenWidth then
            currentX = screenWidth - width
            vX = -MathAbs(vX)
        end

        -- Top/bottom bounces
        if currentY <= 30 then
            currentY = 30
            vY = MathAbs(vY)
        elseif currentY + height >= screenHeight then
            currentY = screenHeight - height
            vY = -MathAbs(vY)
        end

        -- Return overridden position to HUD
        return currentX, currentY
    end)
end

Randomat:register(EVENT)