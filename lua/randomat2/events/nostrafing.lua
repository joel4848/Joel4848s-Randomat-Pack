local EVENT = {}

local eventnames = {}
table.insert(eventnames, "Let's straighten things out")
table.insert(eventnames, "Stay in your lane!")
table.insert(eventnames, "The Path of Righteousness")
table.insert(eventnames, "Sidestepping Schmidestepping")
table.insert(eventnames, "No flank you")
table.insert(eventnames, "One-track mind")
table.insert(eventnames, "One foot in front of the other")
table.insert(eventnames, "Toe the line")
table.insert(eventnames, "Walk This Way")
table.insert(eventnames, "Strafing is for sweaty tryhards!")

EVENT.Title = "No strafing"
EVENT.Description = "'A' and 'D' keys are disabled"
EVENT.id = "nostrafing"
EVENT.Categories = {"largeimpact"}

function EVENT:BeforeEventTrigger(ply, options, ...)
    self.Title = table.Random(eventnames)
end

function EVENT:Begin()

    self:AddHook("SetupMove", function(ply, mv, cmd)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        mv:SetSideSpeed(0)
    end)

end

Randomat:register(EVENT)