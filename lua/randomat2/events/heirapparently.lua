local EVENT = {}

util.AddNetworkString("RdmtHeirApparentlyPlayerVoted")
util.AddNetworkString("RdmtHeirApparentlyEventEnd")


EVENT.Title = "The Heir Apparent(ly)"
EVENT.Description = "Vote to deputise someone, but beware: non-innocents become something else..."
EVENT.id = "heirapparently"
EVENT.Type = {EVENT_TYPE_VOTING, EVENT_TYPE_ROLECHANGE}
EVENT.Categories = {"moderateimpact"}


CreateConVar("randomat_heirapparently_timer", 30, FCVAR_NONE, "The number of seconds voting lasts", 10, 90)
CreateConVar("randomat_heirapparently_tie_deputises", 1, FCVAR_NONE, "Whether a tie results in a coin toss; otherwise, nobody is chosen")
CreateConVar("randomat_heirapparently_show_votes", 1, FCVAR_NONE, "Whether to show when a target is voted for in chat")
CreateConVar("randomat_heirapparently_show_votes_anon", 0, FCVAR_NONE, "Whether to hide who voted in chat")
CreateConVar("randomat_heirapparently_allow_self_votes", 0, FCVAR_NONE, "Whether players can vote for themselves")
CreateConVar("randomat_heirapparently_allow_detectoclown", 1, FCVAR_NONE, "Whether jesters/independents/monsters become Detectoclows (if Jingle Jam Roles 2022 is present)")


local playervotes = {}
local votableplayers = {}
local playersvoted = {}


function EVENT:Begin()
    playervotes = {}
    votableplayers = {}
    playersvoted = {}

    for k, v in player.Iterator() do
        if v:Alive() and not v:IsSpec() and not v:IsDetectiveTeam() then
            votableplayers[k] = v
            playervotes[k] = 0
        end
    end

    local votetime = GetConVar("randomat_heirapparently_timer"):GetInt()
    local elapsed = 0

    timer.Create("RdmtHeirApparentlyTimer", 1, 0, function()
        elapsed = elapsed + 1

        if votetime > 9 and elapsed == votetime - 10 then
            self:SmallNotify("10 seconds left on voting!")
        elseif elapsed >= votetime then
            timer.Remove("RdmtHeirApparentlyTimer")

            local maxvotes = 0
            local winners = {}

            for k, v in pairs(playervotes) do
                if v > maxvotes then
                    maxvotes = v
                    winners = {k}
                elseif v == maxvotes then
                    table.insert(winners, k)
                end
            end

            if maxvotes == 0 then
                self:SmallNotify("Nobody was voted for.")
            else
                local chosenkey
                if #winners > 1 then
                    if GetConVar("randomat_heirapparently_tie_deputises"):GetBool() then
                        chosenkey = winners[math.random(#winners)]
                    else
                        self:SmallNotify("The vote was tied. Nobody was chosen.")
                        net.Start("RdmtHeirApparentlyEventEnd")
                        net.Broadcast()
                        return
                    end
                else
                    chosenkey = winners[1]
                end

                local chosen = votableplayers[chosenkey]
                if IsValid(chosen) then

                    if chosen:IsInnocentTeam() then

                        chosen:SetRole(ROLE_DEPUTY)
                        self:SmallNotify("You have been elected Deputy!", 3, chosen)

                    elseif chosen:IsTraitorTeam() then

                        chosen:SetRole(ROLE_IMPERSONATOR)
                        self:SmallNotify("You have been elected Impersonator!", 3, chosen)

                    else
                        
                        if GetConVar("randomat_heirapparently_allow_detectoclown"):GetBool() and ConVarExists("ttt_detectoclown_override_marshal_badge") then
                            
                            chosen:SetRole(ROLE_DETECTOCLOWN)
                            self:SmallNotify("You have been elected Detectoclown!", 3, chosen)

                        else
                        
                            chosen:SetRole(ROLE_IMPERSONATOR)
                            self:SmallNotify("You have been elected Impersonator!", 3, chosen)

                        end

                    end

                    for _, p in player.Iterator() do
                        if p:Alive() and not p:IsSpec() and p ~= chosen then
                            self:SmallNotify(chosen:Nick() .. " has been deputised!", 3, p)
                        end
                    end

                    self:StripRoleWeapons(chosen)

                    SendFullStateUpdate()

                end
            end

            net.Start("RdmtHeirApparentlyEventEnd")
            net.Broadcast()
        end
    end)
end

function EVENT:End()
    timer.Remove("RdmtHeirApparentlyTimer")
end

net.Receive("RdmtHeirApparentlyPlayerVoted", function(_, ply)
    if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
    if playersvoted[ply] then
        ply:PrintMessage(HUD_PRINTTALK, "You have already voted.")
        return
    end

    local voteeName = net.ReadString()

    for k, v in pairs(votableplayers) do
        if IsValid(v) and v:Nick() == voteeName then
            playersvoted[ply] = true
            playervotes[k] = playervotes[k] + 1

            if GetConVar("randomat_heirapparently_show_votes"):GetBool() then
                local anon = GetConVar("randomat_heirapparently_show_votes_anon"):GetBool()
                local voterName = anon and "Someone" or ply:Nick()
                Randomat:SendChatToAll(voterName .. " has voted for " .. voteeName)
            end

            net.Start("RdmtHeirApparentlyPlayerVoted")
                net.WriteString(voteeName)
                net.WriteInt(playervotes[k], 32)
            net.Broadcast()
            return
        end
    end
end)

CreateConVar("randomat_heirapparently_timer", 30, FCVAR_NONE, "The number of seconds voting lasts", 10, 90)
CreateConVar("randomat_heirapparently_tie_deputises", 1, FCVAR_NONE, "Whether a tie results in a coin toss; otherwise, nobody is chosen")
CreateConVar("randomat_heirapparently_show_votes", 1, FCVAR_NONE, "Whether to show when a target is voted for in chat")
CreateConVar("randomat_heirapparently_show_votes_anon", 0, FCVAR_NONE, "Whether to hide who voted in chat")
CreateConVar("randomat_heirapparently_allow_self_votes", 0, FCVAR_NONE, "Whether players can vote for themselves")
CreateConVar("randomat_heirapparently_allow_detectoclown", 1, FCVAR_NONE, "Whether jesters/independents/monsters become Detectoclows (if Jingle Jam Roles 2022 is present)")


function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"timer"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax()
            })
        end
    end
    
    local checks = {}
    for _, v in ipairs({"deputises", "tie_deputises", "show_votes", "show_votes_anon", "allow_self_votes", "allow_detectoclown"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end
    return sliders, checks
end

Randomat:register(EVENT)