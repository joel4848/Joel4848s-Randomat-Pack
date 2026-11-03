local EVENT = {}

EVENT.Title = "Winner Stays On!"
EVENT.Description = "Two combatants fight while everyone else waits for a turn. Last one standing wins!"
EVENT.id = "winnerstayson"
EVENT.Categories = {"gamemode", "rolechange", "largeimpact"}

local timerConVar = CreateConVar("randomat_winnerstayson_timer", 60, FCVAR_NONE, "Time (s) combatants have to kill each other", 10, 600)

local roundRemaining = 0
local hasteRemaining = 0
local firstPick      = true

local originalName
local originalNameExt
local originalNamePlural

local function IsCombatant(ply)
    return ply:GetNWBool("RdmtWSOCombatant", false)
end

local function OverrideRoleStrings()
    originalName       = ROLE_STRINGS[ROLE_INNOCENT]
    originalNameExt    = ROLE_STRINGS_EXT[ROLE_INNOCENT]
    originalNamePlural = ROLE_STRINGS_PLURAL[ROLE_INNOCENT]

    ROLE_STRINGS[ROLE_INNOCENT]        = "Challenger"
    ROLE_STRINGS_EXT[ROLE_INNOCENT]    = "a Challenger"
    ROLE_STRINGS_PLURAL[ROLE_INNOCENT] = "Challengers"
end

local function RestoreRoleStrings()
    if originalName then
        ROLE_STRINGS[ROLE_INNOCENT] = originalName
        ROLE_STRINGS_EXT[ROLE_INNOCENT] = originalNameExt
        ROLE_STRINGS_PLURAL[ROLE_INNOCENT] = originalNamePlural
    end

    originalName       = nil
    originalNameExt    = nil
    originalNamePlural = nil
end

local function StripPlayer(self, ply)
    self:StripRoleWeapons(ply, true)
    ply:ResetEquipment()

    for _, wep in ipairs(ply:GetWeapons()) do
        class = wep:GetClass()

        if wep.CanBuy and not (class == "weapon_zm_improvised" or class == "weapon_zm_carry" or class == "weapon_ttt_unarmed") then
            ply:StripWeapon(class)
        end
    end

    ply:SetFOV(0, 0.2)
end

local function RefillAmmo(ply)
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) and wep.Primary then
            local clip = wep.Primary.ClipSize
            if clip and clip > 0 then
                wep:SetClip1(clip)
            end

            local ammo_type = wep:GetPrimaryAmmoType()
            local reserve = wep.Primary.ClipMax or clip
            if ammo_type and ammo_type >= 0 and reserve and reserve > 0 then
                ply:SetAmmo(reserve, ammo_type)
            end
        end
    end
end

local function ResetCombatant(ply)
    ply:SetMaxHealth(100)
    ply:SetHealth(100)
    RefillAmmo(ply)
end

local function AnnounceTurn(new_combatant, delayAnnouncement)
    print("delayAnnouncement = " .. tostring(delayAnnouncement))
    local delay = delayAnnouncement and 2 or 0

    timer.Simple(delay, function()
        Randomat:SmallNotify("Mum says it's my turn!", 5, new_combatant)

        local others = {}
        for _, ply in player.Iterator() do
            if ply ~= new_combatant then
                table.insert(others, ply)
            end
        end
        if #others > 0 then
            Randomat:SmallNotify("Mum says it's " .. new_combatant:Nick() .. "'s turn!", 5, others)
        end
    end)
end

local function MakeCombatant(ply, delayAnnouncement)
    ply:SetNWBool("RdmtWSOCombatant", true)

    AnnounceTurn(ply, delayAnnouncement)
end

function EVENT:Begin()
    self:AddHook("TTTKarmaGivePenalty", function(ply, penalty, victim) return true end)

    firstPick = true
    OverrideRoleStrings()

    roundRemaining = math.max(1, GetGlobalFloat("ttt_round_end", CurTime()) - CurTime())
    hasteRemaining = math.max(0, GetGlobalFloat("ttt_haste_end", 0) - CurTime())

    for _, ply in ipairs(self:GetAlivePlayers()) do
        Randomat:SetRole(ply, ROLE_INNOCENT)
        ply:SetMaxHealth(100)
        ply:SetHealth(100)
        ply:SetNWBool("RdmtWSOCombatant", false)
    end
    SendFullStateUpdate()

    for _, ply in ipairs(self:GetAlivePlayers(true)) do
        StripPlayer(self, ply)
    end
    SetGlobalFloat("Randomat_WSO_End", CurTime() + timerConVar:GetFloat())

    local thinkTime = CurTime()

    self:AddHook("Think", function()
        if CurTime() < thinkTime + 0.25 then return end

        thinkTime = CurTime()

        local now = CurTime()
        SetGlobalFloat("ttt_round_end", now + roundRemaining)
        if hasteRemaining > 0 then
            SetGlobalFloat("ttt_haste_end", now + hasteRemaining)
        end

        for _, ply in player.Iterator() do
            if IsCombatant(ply) and (not ply:Alive() or ply:IsSpec()) then
                ply:SetNWBool("RdmtWSOCombatant", false)
            end
        end

        local alive = self:GetAlivePlayers()
        if #alive <= 1 then return end

        local combatants  = {}
        local challengers = {}
        for _, ply in ipairs(alive) do
            table.insert(IsCombatant(ply) and combatants or challengers, ply)
        end

        if #combatants > 0 and now >= GetGlobalFloat("Randomat_WSO_End", 0) then
            for _, ply in ipairs(combatants) do
                ply:Kill()
            end
            return
        end

        if #combatants == 0 then
            SetGlobalFloat("Randomat_WSO_End", now + timerConVar:GetFloat())
            local delayAnnouncement = firstPick

            firstPick = false
            for i = 1, math.min(2, #challengers) do
                MakeCombatant(challengers[i], delayAnnouncement)
            end
        elseif #combatants == 1 then
            MakeCombatant(challengers[1], false)
            SetGlobalFloat("Randomat_WSO_End", now + timerConVar:GetFloat())
        else
            return
        end

        for _, ply in ipairs(self:GetAlivePlayers()) do
            if IsCombatant(ply) then
                ResetCombatant(ply)
            end
        end
    end)

    self:AddHook("EntityTakeDamage", function(target, dmg)
        if not IsPlayer(target) then return end

        local attacker = dmg:GetAttacker()
        if not IsPlayer(attacker) or attacker == target then return end

        if IsCombatant(target) and IsCombatant(attacker) then return end
        return true
    end)

    self:AddHook("TTTCheckForWin", function()
        local alivePlayers = 0

        for _, ply in player.Iterator() do
            if ply:Alive() and not ply:IsSpec() then
                alivePlayers = alivePlayers + 1
            end
        end

        if alivePlayers >= 2 then
            return WIN_NONE
        else
            return WIN_INNOCENT
        end
    end)
end

function EVENT:End()
    for _, ply in player.Iterator() do
        ply:SetNWBool("RdmtWSOCombatant", false)
    end

    SetGlobalFloat("Randomat_WSO_End", 0)
    RestoreRoleStrings()
end

function EVENT:Condition()
    return #self:GetAlivePlayers() >= 3
end

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

    return sliders, {}
end

Randomat:register(EVENT)