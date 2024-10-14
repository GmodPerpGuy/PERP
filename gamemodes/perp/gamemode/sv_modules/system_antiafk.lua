local AFKPlayers = {}
local AFKThreshold = 900 -- 900 seconds (15 minutes) minimum AFK time before kicking

-- Function to check if player is AFK
local function AntiAFK(Player)
    Player.Position2 = Player:GetPos()
    
    -- Check if the player has a previous position stored
    if not Player.Position1 then
        Player.Position1 = Player:GetPos()
    elseif Player.Position1 == Player.Position2 then
        -- Player hasn't moved; track AFK time
        if not AFKPlayers[Player:SteamID()] then
            AFKPlayers[Player:SteamID()] = {Player = Player, AFKTime = CurTime()}
        end
    else
        -- Player moved, reset AFK tracking
        Player.Position1 = Player:GetPos()
        AFKPlayers[Player:SteamID()] = nil
    end
end

-- Function to handle server full situation
local function CheckAndKickAFK()
    local playerCount = #player.GetAll()
    local maxSlots = game.MaxPlayers()

    -- If the server is full, kick the longest AFK player
    if playerCount >= maxSlots then
        local longestAFK, longestAFKPlayer = 0, nil

        for steamID, data in pairs(AFKPlayers) do
            local afkDuration = CurTime() - data.AFKTime
            if afkDuration > longestAFK and afkDuration >= AFKThreshold then
                longestAFK = afkDuration
                longestAFKPlayer = data.Player
            end
        end

        if longestAFKPlayer then
            longestAFKPlayer:Kick("Kicked for being AFK for too long on a full server.")
            AFKPlayers[longestAFKPlayer:SteamID()] = nil -- Remove from AFK list
        end
    end
end

-- Main timer to handle the AFK system
local function AntiAFKMainTimer()
    for _, player in pairs(player.GetAll()) do
        AntiAFK(player)
    end

    CheckAndKickAFK()
end

-- Set a timer to check every 60 seconds
timer.Create("afktimer", 60, 0, AntiAFKMainTimer)
