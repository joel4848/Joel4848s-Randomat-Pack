local EVENT = {}

EVENT.Title = "Sole Music"
EVENT.Description = "Make music while you walk!"
EVENT.id = "solemusic"
EVENT.Categories = {"lowimpact"}

function EVENT:Begin()
    for _, ply in player.Iterator() do
        print( ply )
    end

    local availableSongs = {}
    for i = 1, #JoelRdmt.SoleMusicSongs do table.insert(availableSongs, i) end
    table.Shuffle(availableSongs)

    local songListIndex = 1
    for _, p in player.Iterator() do
        p:SetNWInt("SoleMusicSong", availableSongs[songListIndex])

        songListIndex = songListIndex + 1
        if songListIndex > #availableSongs then
            songListIndex = 1
            table.Shuffle(availableSongs)
        end
    end
end

function EVENT:End()
    for _, p in ipairs(player.GetAll()) do
        p:SetNWInt("SoleMusicSong", 0)
    end
end

Randomat:register(EVENT)