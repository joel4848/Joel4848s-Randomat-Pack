local EVENT = {}

EVENT.Title = {
    {text = "Remember "},
    {text = "Flat", strikethrough = true},
    {text = " Australian Stanley?"},
}
EVENT.DisplayTitle = "Remember Australian Stanley?"
EVENT.Description = {
    {text = "Now this is a randomat all about how"},
    {text = "\nmy playermodel got flipped turned uʍop ǝpᴉsdn"}
}
EVENT.DisplayDescription = "Flips player models upside down"
EVENT.id = "australianmodels"

local savedViewOffsets = {}
local savedViewOffsetsDucked = {}

local lowViewOffset = Vector(0, 0, 8)
local lowViewOffsetDucked = Vector(0, 0, 4)

local flipAngle = Angle(180, 0, 180)
local normalAngle = Angle(0, 0, 0)
local normalOffset = Vector(0, 0, 0)

local function GetHitboxWorldSize(ply)
    local numHitboxes = ply:GetHitBoxCount(0)
    if not numHitboxes or numHitboxes == 0 then return nil end

    local minZ, maxZ = nil, nil

    for hb = 0, numHitboxes - 1 do
        local boneId = ply:GetHitBoxBone(hb, 0)
        if boneId then
            local boneMatrix = ply:GetBoneMatrix(boneId)
            if boneMatrix then
                local bonePos = boneMatrix:GetTranslation()
                local boneAngles = boneMatrix:GetAngles()

                local hbMins, hbMaxs = ply:GetHitBoxBounds(hb, 0)
                if hbMins and hbMaxs then
                    local corners = {
                        Vector(hbMins.x, hbMins.y, hbMins.z),
                        Vector(hbMins.x, hbMins.y, hbMaxs.z),
                        Vector(hbMins.x, hbMaxs.y, hbMins.z),
                        Vector(hbMins.x, hbMaxs.y, hbMaxs.z),
                        Vector(hbMaxs.x, hbMins.y, hbMins.z),
                        Vector(hbMaxs.x, hbMins.y, hbMaxs.z),
                        Vector(hbMaxs.x, hbMaxs.y, hbMins.z),
                        Vector(hbMaxs.x, hbMaxs.y, hbMaxs.z),
                    }

                    for _, corner in ipairs(corners) do
                        local rotated = Vector(corner.x, corner.y, corner.z)
                        rotated:Rotate(boneAngles)
                        local worldZ = (bonePos + rotated).z

                        if not minZ or worldZ < minZ then minZ = worldZ end
                        if not maxZ or worldZ > maxZ then maxZ = worldZ end
                    end
                end
            end
        end
    end

    if not minZ or not maxZ then return nil end

    return minZ, maxZ
end

local function GetOffset(ply)
    if not IsValid(ply) then return normalOffset end

    local groundZ = ply:GetPos().z

    local minZ, maxZ = GetHitboxWorldSize(ply)
    if not minZ or not maxZ then return normalOffset end

    local modelTopHeight = maxZ - groundZ

    local bonePos = ply:GetBonePosition(0)
    if not bonePos then return normalOffset end

    local boneHeightAboveGround = bonePos.z - groundZ

    local worldOffsetZ = (modelTopHeight - boneHeightAboveGround) + boneHeightAboveGround * 2 - modelTopHeight + modelTopHeight

    worldOffsetZ = groundZ - (2 * bonePos.z - maxZ)

    local localOrigin = ply:WorldToLocal(bonePos)
    local localShifted = ply:WorldToLocal(bonePos + Vector(0, 0, worldOffsetZ))
    local localOffsetZ = localShifted.z - localOrigin.z

    return Vector(0, 0, localOffsetZ)
end

local function ApplyAustralia(ply)
    if not IsValid(ply) then return end

    local flipOffset = GetOffset(ply)

    ply:ManipulateBoneAngles(0, flipAngle)
    ply:ManipulateBonePosition(0, flipOffset)

    savedViewOffsets[ply] = savedViewOffsets[ply] or ply:GetViewOffset()
    savedViewOffsetsDucked[ply] = savedViewOffsetsDucked[ply] or ply:GetViewOffsetDucked()

    ply:SetViewOffset(lowViewOffset)
    ply:SetViewOffsetDucked(lowViewOffsetDucked)
end

function EVENT:Begin()
    for _, ply in ipairs(player.GetAll()) do
        ApplyAustralia(ply)
    end

    self:AddHook("PlayerSpawn", function(ply)
        timer.Simple(0.1, function()
            if IsValid(ply) then
                ApplyAustralia(ply)
            end
        end)
    end)
end

function EVENT:End()
    timer.Remove("RdmtAustralia_SecondNotify")

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:ManipulateBoneAngles(0, normalAngle)
            ply:ManipulateBonePosition(0, normalOffset)

            if savedViewOffsets[ply] then
                ply:SetViewOffset(savedViewOffsets[ply])
            end
            if savedViewOffsetsDucked[ply] then
                ply:SetViewOffsetDucked(savedViewOffsetsDucked[ply])
            end
        end
    end

    savedViewOffsets = {}
    savedViewOffsetsDucked = {}
end

Randomat:register(EVENT)