local EVENT = {}

EVENT.id = "solemusic"

function EVENT:Begin()
    local baseSpeed = 220

    local function PlaySoleMusicNote(ply, noteName, speed)
        local state = ply.SoleMusic

        if state.currentPatch then
            state.currentPatch:Stop()
            state.currentPatch = nil
        end

        if noteName == "X" then return end

        local soundPath = "solemusic/" .. noteName .. ".wav"
        state.currentPatch = CreateSound(ply, soundPath, speed)
        state.currentPatch:SetSoundLevel(75)

        local pitch = 100
        if GetConVar("randomat_solemusic_pitch_enable"):GetBool() then
            local effectiveSpeed = (speed or baseSpeed) * game.GetTimeScale()

            local speedRatio = effectiveSpeed / baseSpeed

            local pitchScale = GetConVar("randomat_solemusic_pitch_scale"):GetFloat()
            pitch = 100 + ((speedRatio - 1) * 100 * pitchScale)

            local pitchMin = GetConVar("randomat_solemusic_pitch_min"):GetInt()
            local pitchMax = GetConVar("randomat_solemusic_pitch_max"):GetInt()
            pitch = math.Clamp(math.Round(pitch), pitchMin, pitchMax)
        end

        state.currentPatch:PlayEx(1, pitch)
    end

    self:AddHook("Think", function()
        for _, ply in player.Iterator() do
            local songIndex = ply:GetNWInt("SoleMusicSong", 0)

            if songIndex == 0 or not ply:Alive() or ply:IsSpec() then
                if ply.SoleMusic and ply.SoleMusic.currentPatch then
                    ply.SoleMusic.currentPatch:Stop()
                    ply.SoleMusic.currentPatch = nil
                end
                continue
            end

            ply.SoleMusic = ply.SoleMusic or {
                noteIndex = 1,
                distanceBuffer = 0,
                lastPosition = ply:GetPos(),
                currentPatch = nil,
                smoothedSpeed = baseSpeed
            }

            local state = ply.SoleMusic
            local song = JoelRdmt.SoleMusicSongs[songIndex]

            local realSpeed = ply:GetVelocity():Length()
            state.smoothedSpeed = state.smoothedSpeed or realSpeed

            if realSpeed <= 180 then
                state.smoothedSpeed = 180
            elseif realSpeed > 180 and realSpeed <= 250 then
                state.smoothedSpeed = 220
            elseif realSpeed > 250 and realSpeed <= 315 then
                state.smoothedSpeed = 310
            else
                state.smoothedSpeed = math.min(Lerp(FrameTime() * 4, state.smoothedSpeed, realSpeed), 400)
            end

            local crotchetDistance = baseSpeed * (60 / song.bpm)
            local currentPosition = ply:GetPos()

            local maxSpeedCap = 500
            local maxDistanceThisFrame = maxSpeedCap * FrameTime()

            local rawDistance = currentPosition:Distance(state.lastPosition)
            local distanceMoved = math.min(rawDistance, maxDistanceThisFrame)

            if rawDistance > 1000 then distanceMoved = 0 end

            state.lastPosition = currentPosition
            state.distanceBuffer = state.distanceBuffer + distanceMoved

            local currentNoteData = song.music[state.noteIndex]
            local requiredDist = crotchetDistance * currentNoteData.len

            if state.distanceBuffer >= requiredDist then
                state.distanceBuffer = state.distanceBuffer - requiredDist

                local isMovingBackwards = false

                if GetConVar("randomat_solemusic_play_backwards"):GetBool() then
                    local velocity = ply:GetVelocity()

                    if velocity:LengthSqr() > 100 then
                        local aim = ply:GetAimVector()

                        local dot = velocity:GetNormalized():Dot(aim:GetNormalized())

                        if dot < -0.2 and ply:IsOnGround() then
                            isMovingBackwards = true
                        end
                    end
                end

                if isMovingBackwards then
                    state.noteIndex = state.noteIndex - 1
                    if state.noteIndex < 1 then
                        state.noteIndex = #song.music
                    end
                else
                    state.noteIndex = state.noteIndex + 1
                    if state.noteIndex > #song.music then
                        state.noteIndex = 1
                    end
                end

                local nextNoteData = song.music[state.noteIndex]
                PlaySoleMusicNote(ply, nextNoteData.note, state.smoothedSpeed)
            end
        end
    end)
end

function EVENT:End()
    for _, ply in ipairs(player.GetAll()) do
        if ply.SoleMusic and ply.SoleMusic.currentPatch then
            ply.SoleMusic.currentPatch:Stop()
            ply.SoleMusic.currentPatch = nil
        end
        ply.SoleMusic = nil
    end
end

Randomat:register(EVENT)