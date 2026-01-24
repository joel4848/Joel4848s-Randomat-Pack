local EVENT = {}


EVENT.Title = "cOmMuNiSm"
EVENT.Description = "Whenever anyone buys something from a shop, all other players get a random buyable item"
EVENT.id = "dumbcommunism"
EVENT.Type = EVENT_TYPE_TRANSLATED_WEAPONS
EVENT.Categories = {"item", "moderateimpact"}


CreateConVar("randomat_dumbcommunism_showRoles", 1, FCVAR_NONE, "Whether to show the role of the purchasing player")
CreateConVar("randomat_dumbcommunism_sameItem", 0, FCVAR_NONE, "Whether everyone else gets the same random item")
CreateConVar("randomat_dumbcommunism_allowEquipment", 0, FCVAR_NONE, "Whether the given item can be equipment (e.g. Radar, Body Armour etc.)")
CreateConVar("randomat_dumbcommunism_blocklist", "", FCVAR_NONE, "The comma-separated list of weapon IDs to not give out")
CreateConVar("randomat_dumbcommunism_useOtherBlocklists", 1, FCVAR_NONE, "Use 'What Did I Find In My Pocket?' blocklist if this one is empty?")


local allowequipment = GetConVar("randomat_dumbcommunism_allowEquipment"):GetBool()
local givesameitem = GetConVar("randomat_dumbcommunism_sameItem"):GetBool()
local given_item = nil
local item = nil
local item_id = false


local function TriggerAlert(item, role, is_item, item_role, ply)
    --Event handler located in cl_networkstrings
    net.Start("alerteventtrigger")
    net.WriteString(EVENT.id)
    net.WriteString(given_item)
    net.WriteString(role)
    net.WriteUInt(is_item ~= nil and is_item or 0, 32)
    net.WriteInt(item_role, 16)
    net.Send(ply)
end


function EVENT:Begin()


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Work out what the blocklist should be
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


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------  

    -------------------------------
    -- Give thing when thing bought
    -------------------------------

    self:AddHook("TTTOrderedEquipment", function(ply, item, is_item, fromrdmt)

        -- Don't give items for items given by this item-giving randomat
        if fromrdmt then return end

        local purchaser = self:GetRoleName(ply, true)
        if not GetConVar("randomat_dumbcommunism_showRoles"):GetBool() then
            purchaser = "Someone"
        end

        local shoproles = Randomat:GetShopRoles()
        local shareditem = nil

        -------------------------------
        -- If givesameitem
        -------------------------------
        if givesameitem then

            local tries = 0
            item, item_id, swep, item_role = Randomat:GetShopEquipment(ply, shoproles, blocklist, allowequipment, tries, function(val) tries = val end)
        
            if item.ClassName then
                given_item = item.ClassName
            elseif swep and swep.ClassName then
                given_item = swep.ClassName
            end

            -- PrintMessage(HUD_PRINTTALK, "- givesameitem = " .. tostring(givesameitem))
            -- PrintMessage(HUD_PRINTTALK, "--------------------------------------------------------------")
            -- PrintMessage(HUD_PRINTTALK, "- item = " .. tostring(item))
            -- if item then
            --     PrintMessage(HUD_PRINTTALK, "- item.ClassName = " .. tostring(item.ClassName))
            -- end
            -- if swep then
            --     PrintMessage(HUD_PRINTTALK, "- swep.ClassName = " .. tostring(swep.ClassName))
            -- end
            -- PrintMessage(HUD_PRINTTALK, "- item_id = " .. tostring(item_id))
            -- PrintMessage(HUD_PRINTTALK, "- swep = " .. tostring(swep))
            -- PrintMessage(HUD_PRINTTALK, "- item_role = " .. tostring(item_role))
            -- PrintMessage(HUD_PRINTTALK, "--------------------------------------------------------------")
            -- PrintMessage(HUD_PRINTTALK, "- item = " .. item)
            -- PrintMessage(HUD_PRINTTALK, "- item_id = " .. item_id)
            -- PrintMessage(HUD_PRINTTALK, "- _ = " .. _)
            -- PrintMessage(HUD_PRINTTALK, "- item_role = " .. item_role)
            -- PrintMessage(HUD_PRINTTALK, "--------------------------------------------------------------")

            for _, v in player.Iterator() do
                if v ~= ply and v:Alive() then
                    if item_id then
                        v:GiveEquipmentItem(tonumber(given_item))
                    else
                        v:Give(given_item)
                        if item.WasBought then
                            item:WasBought(v)
                        end
                    end


                    Randomat:CallShopHooks(item_id, given_item, v)

                    TriggerAlert(item, purchaser, item_id, item_role, v)

                    --Event started in cl_networkstrings
                    net.Receive("AlertTriggerFinal", function()
                        -- PrintMessage(HUD_PRINTTALK, "- Received net return")
                        local event = net.ReadString()
                        if event ~= EVENT.id then return end
                    
                        local name = self:RenameWeps(net.ReadString())
                        local purchaser = net.ReadString()

                        -- PrintMessage(HUD_PRINTTALK, "- net name = " .. tostring(name))
                        -- PrintMessage(HUD_PRINTTALK, "- net purchaser = " .. tostring(purchaser))
                    
                        self:SmallNotify(purchaser .. " gave you a " .. name, 3, v)
                    end)

                end
            end
        
    
        -------------------------------
        -- If not givesameitem
        -------------------------------

        else

            local tries = 0
            item, item_id, swep, item_role = Randomat:GetShopEquipment(ply, shoproles, blocklist, allowequipment, tries, function(val) tries = val end)
        
            if item and item.ClassName then
                given_item = item.ClassName
            elseif swep and swep.ClassName then
                given_item = swep.ClassName
            elseif item_id then
                given_item = item_id
            end

            -- PrintMessage(HUD_PRINTTALK, "- givesameitem = " .. tostring(givesameitem))
            -- PrintMessage(HUD_PRINTTALK, "--------------------------------------------------------------")
            -- PrintMessage(HUD_PRINTTALK, "- item = " .. tostring(item))
            -- if item then
            --     PrintMessage(HUD_PRINTTALK, "- item.ClassName = " .. tostring(item.ClassName))
            -- end
            -- if swep then
            --     PrintMessage(HUD_PRINTTALK, "- swep.ClassName = " .. tostring(swep.ClassName))
            -- end
            -- PrintMessage(HUD_PRINTTALK, "- item_id = " .. tostring(item_id))
            -- PrintMessage(HUD_PRINTTALK, "- swep = " .. tostring(swep))
            -- PrintMessage(HUD_PRINTTALK, "- item_role = " .. tostring(item_role))
            -- PrintMessage(HUD_PRINTTALK, "--------------------------------------------------------------")
            -- PrintMessage(HUD_PRINTTALK, "- item = " .. item)
            -- PrintMessage(HUD_PRINTTALK, "- item_id = " .. item_id)
            -- PrintMessage(HUD_PRINTTALK, "- _ = " .. _)
            -- PrintMessage(HUD_PRINTTALK, "- item_role = " .. item_role)
            -- PrintMessage(HUD_PRINTTALK, "--------------------------------------------------------------")

            for _, v in player.Iterator() do
                if v ~= ply and v:Alive() then
                    if item_id then
                        v:GiveEquipmentItem(tonumber(given_item))
                    else
                        v:Give(given_item)
                        if item.WasBought then
                            item:WasBought(v)
                        end
                    end


                    Randomat:CallShopHooks(item_id, given_item, v)

                    TriggerAlert(item, purchaser, item_id, item_role, v)

                    --Event started in cl_networkstrings
                    net.Receive("AlertTriggerFinal", function()
                        -- PrintMessage(HUD_PRINTTALK, "- Received net return")
                        local event = net.ReadString()
                        if event ~= EVENT.id then return end
                    
                        local name = self:RenameWeps(net.ReadString())
                        local purchaser = net.ReadString()

                        -- PrintMessage(HUD_PRINTTALK, "- net name = " .. tostring(name))
                        -- PrintMessage(HUD_PRINTTALK, "- net purchaser = " .. tostring(purchaser))
                    
                        self:SmallNotify(purchaser .. " gave you a " .. name, 3, v)
                    end)

                end
            end

        end



    end)
end

function EVENT:Condition()
    return not Randomat:IsEventActive("pocket", "pockets")
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
