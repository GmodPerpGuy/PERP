local AnimTranslateTable = {}
AnimTranslateTable[PLAYER_RELOAD] = ACT_HL2MP_GESTURE_RELOAD
AnimTranslateTable[PLAYER_JUMP] = ACT_HL2MP_JUMP
AnimTranslateTable[PLAYER_ATTACK1] = ACT_HL2MP_GESTURE_RANGE_ATTACK

function GM:SetPlayerAnimation(pl, anim)
    local act = ACT_HL2MP_IDLE
    local Speed = pl:GetVelocity():Length()
    local OnGround = pl:OnGround()

    -- If it's in the translate table then just straight translate it
    if AnimTranslateTable[anim] != nil then
        act = AnimTranslateTable[anim]
    else
        -- Crawling on the ground
        if OnGround and pl:Crouching() then
            act = ACT_HL2MP_IDLE_CROUCH
            if Speed > 0 then
                act = ACT_HL2MP_WALK_CROUCH
            end
        elseif Speed > 210 then
            act = ACT_HL2MP_RUN
        elseif Speed > 0 then
            act = ACT_HL2MP_WALK
        end
    end

    -- Attacking/Reloading is handled by the RestartGesture function
    if act == ACT_HL2MP_GESTURE_RANGE_ATTACK or act == ACT_HL2MP_GESTURE_RELOAD then
        pl:RestartGesture(pl:Weapon_TranslateActivity(act))
        
        -- If this was an attack, send the anim to the weapon model
        if act == ACT_HL2MP_GESTURE_RANGE_ATTACK then
            pl:Weapon_SetActivity(pl:Weapon_TranslateActivity(ACT_RANGE_ATTACK1), 0)
        end
        return
    end

    -- Always play the jump anim if we're in the air
    if not OnGround then
        act = ACT_HL2MP_JUMP
    end

    -- Get the sequence based on weapon activity
    local seq = pl:SelectWeightedSequence(pl:Weapon_TranslateActivity(act))

    -- Handle animations for vehicles
    if pl:InVehicle() then
        local pVehicle = pl:GetVehicle()
        
        if pVehicle.HandleAnimation != nil then
            seq = pVehicle:HandleAnimation(pl)
            if seq == nil then return end
        else
            local class = pVehicle:GetClass()
            if class == "prop_vehicle_jeep" then
                seq = pl:LookupSequence("drive_jeep")
            elseif class == "prop_vehicle_airboat" then
                seq = pl:LookupSequence("drive_airboat")
            else
                seq = pl:LookupSequence("drive_pd")
            end
        end
    end

    -- Fallback if no translated sequence
    if seq == -1 then
        if act == ACT_HL2MP_JUMP then
            act = ACT_HL2MP_JUMP_SLAM
        end
        seq = pl:SelectWeightedSequence(act)
    end

    -- Don't keep switching sequences if we're already playing the one we want
    if pl:GetSequence() == seq then return end

    -- Set and reset the sequence
    pl:SetPlaybackRate(1.0)
    pl:ResetSequence(seq)
    pl:SetCycle(0)
end
