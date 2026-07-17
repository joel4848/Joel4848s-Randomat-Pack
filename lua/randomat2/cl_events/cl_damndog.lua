local EVENT = {}

EVENT.id = "damndog"

local dogSpawnKey = KEY_T
local dogKeyWasDown = false

function EVENT:Begin()
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
end

function EVENT:End()
    hook.Remove("Think", "DogKeyWatch")
end

Randomat:register(EVENT)