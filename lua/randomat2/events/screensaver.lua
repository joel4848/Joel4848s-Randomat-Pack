local EVENT = {}

EVENT.Title       = "Screensaver"
EVENT.Description = {
    { text = "Surely it'll hit the corner at " },
    { text = "SOME", italic = true },
    { text = " point?!" }
}
EVENT.DisplayDescription = "Makes the player info HUD (health/ammo etc.) bounce around the screen"
EVENT.id          = "screensaver"
EVENT.Categories  = {"moderateimpact"}

function EVENT:Begin()

end

function EVENT:End()

end

Randomat:register(EVENT)