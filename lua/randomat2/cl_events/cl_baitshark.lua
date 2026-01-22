local innocentPlayer = nil

-- Start drawing halo on the innocent
net.Receive("rdmtStartHalo", function()
    innocentPlayer = net.ReadEntity()
    
    hook.Add("PreDrawHalos", "BaitSharkRandomatHalos", function()
        if IsValid(innocentPlayer) then
            halo.Add({innocentPlayer}, Color(0, 255, 0), 0, 0, 1, true, true)
        end
    end)
end)

-- Stop drawing halo
net.Receive("rdmtStopHalo", function()
    innocentPlayer = nil
    hook.Remove("PreDrawHalos", "BaitSharkRandomatHalos")
end)

-- Start traitor blindness
net.Receive("rdmtStartBlind", function()
    client = LocalPlayer()
    hook.Add("HUDPaint", "BlindPlayer", function()
        if IsValid(client) and client:Alive() and Randomat:IsTraitorTeam(client) then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        end
    end)
end)

-- Stop traitor blindness
net.Receive("rdmtStopBlind", function()
    client = nil
    hook.Remove("HUDPaint", "BlindPlayer")
end)

-- Hook round end screen
net.Receive("rdmtSharkWinScreen", function()
    if CR_VERSION then
        hook.Add("TTTScoringWinTitle", "BaitSharkRandomatWinTitle", function(wintype, wintitles, title)
            local winner

            for i, ply in ipairs(player.GetAll(innocentPlayer)) do
                if ply:Alive() and not ply:IsSpec() then
                    winner = ply
                end
            end

            if not winner then return end
            LANG.AddToLanguage("english", "win_baitshark", string.upper(winner:Nick() .. " wins!"))

            local newTitle = {
                txt = "win_baitshark",
                c = ROLE_COLORS[ROLE_INNOCENT],
                params = nil
            }

            return newTitle
        end)
    end
end)

-- Unhook round end screen
net.Receive("rdmtSharkWinScreenUnhook", function()
    hook.Remove("TTTScoringWinTitle", "BaitSharkRandomatWinTitle")
end)