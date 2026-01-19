local EVENT = {}

EVENT.Title = "cOmMuNiSm"
EVENT.Description = "Whenever anyone buys something from a shop, all other players get a random buyable item"
EVENT.id = "dumbcommunism"
EVENT.Categories = {"item", "moderateimpact"}

CreateConVar("randomat_dumbcommunism_showRoles", 1, FCVAR_NONE, "Whether to show the role of the purchasing player")
CreateConVar("randomat_dumbcommunism_sameItem", 0, FCVAR_NONE, "Whether everyone else gets the same random item")
CreateConVar("randomat_dumbcommunism_allowEquipment", 0, FCVAR_NONE, "Whether the given item can be equipment (e.g. Radar, Body Armour etc.)")
CreateConVar("randomat_dumbcommunism_blocklist", "", FCVAR_NONE, "The comma-separated list of weapon IDs to not give out")
CreateConVar("randomat_dumbcommunism_useOtherBlocklists", 1, FCVAR_NONE, "Use 'What Did I Find In My Pocket?' blocklist if this one is empty?")

function EVENT:Begin()

    local allowequipment = GetConVar("randomat_dumbcommunism_allowEquipment"):GetBool()

    self:AddHook("TTTOrderedEquipment", function(ply, item, is_item, fromrdmt)

        if fromrdmt then return end

        local blockliststring = GetConVar("randomat_dumbcommunism_blocklist"):GetString()
        local blocklist = {}

        if blockliststring == ""
            and GetConVar("randomat_dumbcommunism_useOtherBlocklists"):GetBool()
            and ConVarExists("randomat_pocket_blocklist") then

            local pocketblockliststring = GetConVar("randomat_pocket_blocklist"):GetString()
            if pocketblockliststring ~= "" then
                blockliststring = pocketblockliststring
            end
        end

        for blocked_id in string.gmatch(blockliststring, "([^,]+)") do
            table.insert(blocklist, blocked_id:Trim())
        end

        local purchaser = self:GetRoleName(ply, true)
        if not GetConVar("randomat_dumbcommunism_showRoles"):GetBool() then
            purchaser = "Someone"
        end

        local givesameitem = GetConVar("randomat_dumbcommunism_sameItem"):GetBool()
        local shoproles = Randomat:GetShopRoles()

        local shareditem = nil

        if givesameitem then
            local tries = 0
            local eq, _, swep = Randomat:GetShopEquipment(ply, shoproles, blocklist, allowequipment, tries, function(val) tries = val end)

            if eq then
                shareditem = eq.ClassName
            elseif swep then
                shareditem = swep.ClassName
            end
        end

        for _, v in player.Iterator() do
            if v ~= ply and v:Alive() then
                if givesameitem and shareditem then
                    v:Give(shareditem)
                    Randomat:CallShopHooks(false, shareditem, v)

                    local readablename = self:RenameWeps(shareditem)
                    self:SmallNotify(purchaser .. " gave you a " .. readablename, 3, v)
                else
                    v.dumbcommunism_tries = 0

                    Randomat:GiveRandomShopItem(
                        v,
                        shoproles,
                        blocklist,
                        allowequipment,
                        function() return v.dumbcommunism_tries end,
                        function(val) v.dumbcommunism_tries = val end,
                        function(isequip, id)
                            Randomat:CallShopHooks(isequip, id, v)

                            local readablename = self:RenameWeps(id)
                            self:SmallNotify(purchaser .. " gave you a " .. readablename, 3, v)
                        end
                    )
                end
            end
        end
    end)
end

function EVENT:Condition()
    return not Randomat:IsEventActive("privacy")
end

function EVENT:GetConVars()
    local checks = {}
    for _, v in ipairs({"showRoles", "sameItem", "allowEquipment", "useOtherBlocklists"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local cv = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = cv:GetHelpText()
            })
        end
    end

    local textboxes = {}
    for _, v in ipairs({"blocklist"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local cv = GetConVar(name)
            table.insert(textboxes, {
                cmd = v,
                dsc = cv:GetHelpText()
            })
        end
    end

    return {}, checks, textboxes
end

Randomat:register(EVENT)
