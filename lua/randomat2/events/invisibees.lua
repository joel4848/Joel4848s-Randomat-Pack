local EVENT = {}
EVENT.Title = "Invisibees!"
EVENT.Description = "There DEFINITELY aren't any bees..."
EVENT.id = "invisibees"

EVENT.Categories = {"eventtrigger", "largeimpact"}

local bees = "bees"

function EVENT:Begin()
    Randomat:SilentTriggerEvent(bees)

    self:AddHook("OnEntityCreated",  function(bee)
        timer.Simple(0, function()
            if IsValid(bee) and bee:GetClass() == "prop_dynamic" and bee:GetModel() == "models/lucian/props/stupid_bee.mdl" then
                bee:SetColor(Color(255, 255, 255, 3))
                bee:SetMaterial("sprites/heatwave")
            end
        end)
    end)
end

function EVENT:Condition()
    return Randomat:CanEventRun(bees, true)
end

Randomat:register(EVENT)