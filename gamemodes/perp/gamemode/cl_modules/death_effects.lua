--i fucke dwith this already
function GM:PlayerDieingSounds()
    -- Local player heartbeat on death.
    if not LocalPlayer():Alive() then
        if not GAMEMODE.HeartbeatNoise then
            GAMEMODE.HeartbeatNoise = CreateSound(LocalPlayer(), 'player/heartbeat1.wav')
        end

        GAMEMODE.LastHeartBeatPlay = GAMEMODE.LastHeartBeatPlay or 0

        if GAMEMODE.LastHeartBeatPlay + 0.717 <= CurTime() then
            GAMEMODE.LastHeartBeatPlay = CurTime()
            GAMEMODE.HeartbeatNoise:Stop()
            GAMEMODE.HeartbeatNoise:Play()
        end
    elseif GAMEMODE.HeartbeatNoise then
        GAMEMODE.HeartbeatNoise:Stop()
        GAMEMODE.HeartbeatNoise = nil
    end

    -- Global player groaning on death
    for _, player in ipairs(player.GetAll()) do
        if not player:Alive() then
            local playerTable = player:GetTable()
            playerTable.NextGroan = playerTable.NextGroan or CurTime() + math.random(5, 15)

            if playerTable.NextGroan < CurTime() then
                playerTable.NextGroan = CurTime() + math.random(5, 15) -- Reset groan time

                local gender = player:GetSex() == SEX_FEMALE and "female" or "male"
                local moanIndex = math.random(1, 5)
                local moanFile = Sound('vo/npc/' .. gender .. '01/moan0' .. moanIndex .. '.wav')

                sound.Play(moanFile, player:GetPos(), 75, 100) -- Adjust volume to 75
            end
        else
            player:GetTable().NextGroan = nil
        end
    end
end

hook.Add('Think', 'GM.PlayerDieingSounds', function()
    GAMEMODE:PlayerDieingSounds()
end)
