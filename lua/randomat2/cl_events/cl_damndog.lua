local EVENT = {}

EVENT.id = "damndog"

local dogSpawnKey = KEY_T
local dogKeyWasDown = false

function EVENT:Begin()
    -- TESTING ONLY - REMOVE BEFORE RELEASE
    hook.Add("Think", "DogKeyWatch", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end

        if input.IsKeyDown(dogSpawnKey) then
            if not dogKeyWasDown then
                net.Start("DamnDogSpawnDog")
                net.SendToServer()
            end
            dogKeyWasDown = true
        else
            dogKeyWasDown = false
        end
    end)

    ---------------------------------------------------------------------------------
    surface.CreateFont("RdmtDamnDog_BubbleFont", {
        font = "Arial",
        size = 28,
        weight = 800,
        extended = true
    })

    self:AddHook("PostDrawTranslucentRenderables", function()
        local ragdolls = ents.FindByClass("prop_ragdoll")

        for _, rag in ipairs(ragdolls) do
            if IsValid(rag) and rag:GetNWBool("RdmtDamnDog_HasBubble") then

                local text = rag:GetNWString("RdmtDamnDog_BubbleText")

                local headBone = rag:LookupBone("ValveBiped.Bip01_Head1") or rag:LookupBone("ValveBiped.Bip01_Head")
                local headPos = nil

                if headBone then
                    headPos = rag:GetBonePosition(headBone)
                else
                    headPos = rag:GetPos()
                end

                local drawPos = headPos + Vector(0, 0, 24)

                local clientAngles = EyeAngles()
                clientAngles:RotateAroundAxis(clientAngles:Up(), -90)
                clientAngles:RotateAroundAxis(clientAngles:Forward(), 90)

                cam.Start3D2D(drawPos, clientAngles, 0.15)
                    surface.SetFont("RdmtDamnDog_BubbleFont")
                    local textWidth, textHeight = surface.GetTextSize(text)
                    local padX, padY = 20, 14
                    local boxWidth = textWidth + (padX * 2)
                    local boxHeight = textHeight + (padY * 2)
                    local boxX = -(boxWidth / 6)
                    local boxY = -boxHeight

                    draw.RoundedBox(boxHeight / 2, boxX, boxY, boxWidth, boxHeight, Color(255, 255, 255, 240))

                    draw.SimpleText(text, "RdmtDamnDog_BubbleFont", -boxX * 2, boxY + padY, Color(20, 20, 20, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

                    local circleY = boxY + boxHeight + 4
                    draw.RoundedBox(6, 0, circleY, 12, 12, Color(255, 255, 255, 240))
                    draw.RoundedBox(4, -4, circleY + 14, 8, 8, Color(255, 255, 255, 240))

                cam.End3D2D()
            end
        end
    end)

    local clientEyesSet = 0

    hook.Add("Think", "RdmtDamnDog_DogView", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        -- Check if the local player is currently ragdolled by a dog
        if not ply:GetNWBool("RdmtDamnDog_IsRagdolled", false) then
            -- Reset frame counter when not ragdolled
            clientEyesSet = 0
            return
        end

        local dog = ply:GetNWEntity("RdmtDamnDog_Dog")

        -- Track camera angles toward the dog for the first 120 frames
        if IsValid(dog) and clientEyesSet < 240 then
            local ragdoll = ply:GetObserverTarget()

            -- Fallback to player position if spectator target isn't valid yet
            local sourcePos = IsValid(ragdoll) and ragdoll:GetPos() or ply:GetPos()
            local targetDir = dog:GetPos() - sourcePos

            local targetAng = targetDir:Angle()
            targetAng.x = targetAng.x + 30

            -- Apply locally on the client to prevent prediction stutter
            ply:SetEyeAngles(targetAng)

            clientEyesSet = clientEyesSet + 1
        end
    end)
end

function EVENT:End()
    hook.Remove("Think", "DogKeyWatch")
    hook.Remove("Think", "RdmtDamnDog_DogView")
end

Randomat:register(EVENT)