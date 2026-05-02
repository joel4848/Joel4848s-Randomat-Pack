local EVENT = {}
EVENT.id = "heirapparently"

local voteframe

local function CloseVoteFrame()
    if IsValid(voteframe) then
        voteframe:Close()
    end
end

function EVENT:Begin()
    voteframe = vgui.Create("DFrame")
    voteframe:SetPos(10, ScrH() - 800)
    voteframe:SetSize(220, 300)
    voteframe:SetTitle("Vote for the Heir")
    voteframe:SetDraggable(false)
    voteframe:ShowCloseButton(false)
    voteframe:SetDeleteOnClose(true)

    local list = vgui.Create("DListView", voteframe)
    list:Dock(FILL)
    list:SetMultiSelect(false)
    local colName = list:AddColumn("Player")
    list:AddColumn("Votes")

    for _, v in player.Iterator() do
        if v:Alive() and not v:IsSpec() and not v:IsDetectiveTeam() then
            list:AddLine(v:Nick(), 0)
        end
    end

    list:OnRequestResize(colName, 140)

    list.OnRowSelected = function(_, _, pnl)
        local ply = LocalPlayer()
        if not ply:Alive() or ply:IsSpec() then
            ply:PrintMessage(HUD_PRINTTALK, "Dead players can't vote.")
            return
        end

        net.Start("RdmtHeirApparentlyPlayerVoted")
            net.WriteString(pnl:GetColumnText(1))
        net.SendToServer()
    end

    net.Receive("RdmtHeirApparentlyPlayerVoted", function()
        local votee = net.ReadString()
        local num = net.ReadInt(32)
        for _, line in ipairs(list:GetLines()) do
            if line:GetColumnText(1) == votee then
                line:SetColumnText(2, num)
            end
        end
    end)
end

EVENT.End = CloseVoteFrame

Randomat:register(EVENT)

net.Receive("RdmtHeirApparentlyEventEnd", CloseVoteFrame)
