local EVENT = {}

EVENT.Title = "Comic Re-life"
EVENT.Description = "Makes a player a Jester with infinite defibs!"
EVENT.id = "comicrelife"
EVENT.Categories = {"rolechange", "moderateimpact"}

util.AddNetworkString("ComicRelifeBegin")
util.AddNetworkString("ComicRelifeEnd")

function EVENT:Begin()
    net.Start("ComicRelifeBegin")
    net.Broadcast()

    local prankenstein = nil
    -- local prankensteinVanilla = nil

    -- Find who's available to make the Dr. Prankenstein
    local players = {}
    local norole = {}
    local innocents = {}
    local traitors = {}
    local specialInnocents = {}
    local specialTraitors = {}
    local detectives = {}
    local jesters = {}
    local jesterteam = {}
    local independents = {}
    local monsters = {}

    for _, ply in player.Iterator() do
        if IsValid(ply) and not ply:IsSpec() then
            table.insert(players, ply)
            if ply:GetRole() == ROLE_NONE then
                table.insert(norole, ply)
            elseif ply:IsInnocent() then
                table.insert(innocents, ply)
            elseif ply:IsTraitor() then
                table.insert(traitors, ply)
            elseif ply:IsInnocentTeam() and not ply:IsDetectiveTeam() then
                table.insert(specialInnocents, ply)
            elseif ply:IsTraitorTeam() then
                table.insert(specialTraitors, ply)
            elseif ply:IsDetectiveTeam() then
                table.insert(detectives, ply)
            elseif ply:IsJesterTeam() and not ply:IsJester() then
                table.insert(jesterteam, ply)
            elseif ply:IsJester() then
                table.insert(jesters, ply)
            elseif ply:IsIndependentTeam() then
                table.insert(independents, ply)
            elseif ply:IsMonsterTeam() then
                table.insert(monsters, ply)
            end
        end
    end

    -- print("=============================================")
    -- print("players: " .. #players)
    -- print("norole: " .. #norole)
    -- print("innocents: " .. #innocents)
    -- print("traitors: " .. #traitors)
    -- print("specialInnocents: " .. #specialInnocents)
    -- print("specialTraitors: " .. #specialTraitors)
    -- print("detectives: " .. #detectives)
    -- print("=============================================")

    -- Choose the Dr. Prankenstein
    if #norole > 0 then
        table.Shuffle(norole)
        prankenstein = norole[1]
        prankensteinVanilla = false
    elseif #jesters > 0 then
        table.Shuffle(jesters)
        prankenstein = jesters[1]
        prankensteinVanilla = false
    elseif #jesterteam > 0 then
        table.Shuffle(jesterteam)
        prankenstein = jesterteam[1]
        prankensteinVanilla = false
    elseif #independents > 0 then
        table.Shuffle(independents)
        prankenstein = independents[1]
        prankensteinVanilla = false
    elseif #monsters > 0 then
        table.Shuffle(monsters)
        prankenstein = monsters[1]
        prankensteinVanilla = false
    elseif #innocents > 0 then
        table.Shuffle(innocents)
        prankenstein = innocents[1]
        prankensteinVanilla = true
    elseif #specialInnocents > 0 then
        table.Shuffle(specialInnocents)
        prankenstein = specialInnocents[1]
        prankensteinVanilla = true
    elseif #detectives > 0 then
        table.Shuffle(detectives)
        prankenstein = detectives[1]
        prankensteinVanilla = true
    elseif #traitors > 0 then
        table.Shuffle(traitors)
        prankenstein = traitors[1]
        prankensteinVanilla = true
    elseif #specialTraitors > 0 then
        table.Shuffle(specialTraitors)
        prankenstein = specialTraitors[1]
        prankensteinVanilla = true
    end

    print (tostring(prankenstein))

    -- Check we're not going to just end the round with the randomat lolol
    local livingPlayers = {}
    local innocentTeam = {}
    local traitorTeam = {}
    local deadPlayers = {}
    local currentJesterTeam = {}
    local prankensteinIsDead = false

    for _, ply in player.Iterator() do
        if IsValid(ply) and not ply:IsSpec() then
            table.insert(livingPlayers, ply)
            if ply:IsInnocentTeam() then
                table.insert(innocentTeam, ply)
            elseif ply:IsTraitorTeam() then
                table.insert(traitorTeam, ply)
            elseif ply:IsJesterTeam() then
                table.insert(currentJesterTeam, ply)
            end
        end

        if IsValid(ply) and ply:IsSpec() then
            table.insert(deadPlayers, ply)
        end
    end

    if #innocentTeam == 1 and #traitorTeam == 1 and #livingPlayers == 2 then
        table.Shuffle(deadPlayers)
        prankenstein = deadPlayers[1]
        prankensteinIsDead = true
    elseif #currentJesterTeam > 0 and ((#innocentTeam == 0 or #traitorTeam == 0) and (#livingPlayers == #innocentTeam + 1 or #livingPlayers == #traitorTeam + 1)) then
        table.Shuffle(deadPlayers)
        prankenstein = deadPlayers[1]
        prankensteinIsDead = true
    end

    -- Create Dr. Prankenstein
    local dprk = prankenstein

    -- First, revive DP if they're dead
    if prankensteinIsDead then
        if not IsValid(dprk) then return end
        if not dprk:Alive() then
            dprk:SpawnForRound(true)
            local body = dprk.server_ragdoll or dprk:GetRagdollEntity()
            if IsValid(body) then
                dprk:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
                body:Remove()
            end
        end
    end

    -- Make them a jester
    print ("Making " .. tostring(prankenstein) .. " a Jester!")
    print ("Making " .. tostring(dprk) .. " a Jester!")
    -- dprk:SetRole(ROLE_JESTER)
    Randomat:SetRole(dprk, ROLE_JESTER)

    ROLE_STRINGS[ROLE_JESTER] = "Dr. Prankenstein"

    SendFullStateUpdate()

    -- Strip their weapons
    for _, wep in ipairs(dprk:GetWeapons()) do
        if IsValid(wep) then
            dprk:StripWeapon(wep:GetClass())
        end
    end
    dprk:SetFOV(0, 0.2)

    -- Give them a defib
    dprk:Give("weapon_med_defib")
    dprk:Give("weapon_ttt_unarmed")

    self:AddHook("Think", function()
        local hasDefib = false
        for _, wep in ipairs(dprk:GetWeapons()) do
            if wep:GetClass() == "weapon_med_defib" then
                hasDefib = true
            end
        end

        if not hasDefib then
            dprk:Give("weapon_med_defib")
        end

    end)

end

function EVENT:End()
    net.Start("ComicRelifeEnd")
    net.Broadcast()
end

Randomat:register(EVENT)