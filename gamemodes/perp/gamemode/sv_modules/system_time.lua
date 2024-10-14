
local LIGHT_LOW = string.byte('a')
local LIGHT_HIGH = string.byte('z')

GM.timeEntities = GM.timeEntities or {}
local lightTable = {}

GM.CurrentTime = NOON
GM.CurrentMonth = 1
GM.CurrentDay = 1
GM.CurrentYear = 1
GM.CanSaveDate = false
GM.CurFoggy = false

-- Save current date in database
function GM.SaveDate()
    Msg(string.format("Current in-game date: %d/%d/%d\n", GM.CurrentMonth, GM.CurrentDay, GM.CurrentYear))
    
    if not GM.CanSaveDate then
        Msg("Not saving date...\n")
        return false
    end
    
    -- Use SQL transactions for better performance and readability
    local queries = {
        (GM.LastSaveYear ~= GM.CurrentYear) and 
            string.format("UPDATE `perp_system` SET `value`='%d' WHERE `key`='date_year_%s' LIMIT 1", GM.CurrentYear, GM.ServerDateIdentifier),
        (GM.LastSaveMonth ~= GM.CurrentMonth) and 
            string.format("UPDATE `perp_system` SET `value`='%d' WHERE `key`='date_month_%s' LIMIT 1", GM.CurrentMonth, GM.ServerDateIdentifier),
        (GM.LastSaveDay ~= GM.CurrentDay) and 
            string.format("UPDATE `perp_system` SET `value`='%d' WHERE `key`='date_day_%s' LIMIT 1", GM.CurrentDay, GM.ServerDateIdentifier)
    }

    for _, query in ipairs(queries) do
        if query then
            tmysql.query(query)
        end
    end

    GM.LastSaveYear = GM.CurrentYear
    GM.LastSaveMonth = GM.CurrentMonth
    GM.LastSaveDay = GM.CurrentDay
end

-- Wrap angles to keep them between 0 and 360
local function WrapAngles(ang)
    return (ang + 360) % 360
end

-- Build light table
local function buildLightTable()
    Msg("Building lighting tables... ")
    local DAY_HALF = DAY_LENGTH / 2

    for i = 1, DAY_LENGTH do
        local letter

        -- Calculate light letter
        if i < NOON then
            letter = string.char(math.ceil(((LIGHT_HIGH - LIGHT_LOW) * (1 - math.EaseInOut((NOON - i) / (NOON - DAY_START), 0, 1))) + LIGHT_LOW))
        elseif i < DAY_END then
            letter = string.char(math.ceil(((LIGHT_HIGH - LIGHT_LOW) * (1 - math.EaseInOut((i - NOON) / (DAY_END - NOON), 0, 1))) + LIGHT_LOW))
        else
            letter = string.char(LIGHT_LOW)
        end

        -- Calculate colors
        local red, green, blue = 0, 0, 0

        if i >= DAWN_START and i <= DAWN_END then
            -- Golden dawn
            local frac = (i - DAWN_START) / (DAWN_END - DAWN_START)
            red = (i < DAWN and 200 * frac) or (200 - 200 * frac)
            green = (i < DAWN and 128 * frac) or (128 - 128 * frac)
        elseif i >= DUSK_START and i <= DUSK_END then
            -- Red dusk
            local frac = (i - DUSK_START) / (DUSK_END - DUSK_START)
            red = (i < DUSK and 85 * frac) or (85 - 85 * frac)
        elseif i >= DUSK_END or i <= DAWN_START then
            -- Blue hinted night sky
            local frac = i > DUSK_END and (i - DUSK_END) / (DAY_LENGTH - DUSK_END) or i / DAWN_START
            blue = (i > DUSK_END and 15 * frac) or (15 - 15 * frac)
        end

        -- Store light data
        lightTable[i] = {
            letter = letter,
            red = red,
            green = green,
            blue = blue
        }
    end

    Msg("done!\n")
end

-- Fog color and distance calculations
local function calcFogColor(channel, intensity, timeFactor)
    local base = channel - (channel * math.Clamp(timeFactor, 0, 1))
    local additive = math.floor(base + (intensity * math.Clamp(timeFactor, 0.05, 0.7)))
    return math.Clamp(math.floor(additive), 0, 255)
end

-- Sun & Shadow Angle Calculations
local function updateSunAndShadowAngles(i)
    local piday = (DAY_LENGTH / 4) + i
    piday = ((piday > DAY_LENGTH) and piday - DAY_LENGTH or piday) / DAY_LENGTH * math.pi * 2

    local sAng, sAngOffset = 65, 65 / 90
    local sPitch = WrapAngles(math.deg(sAngOffset * math.sin(piday)))
    local sYaw = WrapAngles(math.deg(-piday))
    local sRoll = 0

    -- Shadow angles opposite of sun angles
    local xPitch, xYaw, xRoll = WrapAngles(sPitch + 180), WrapAngles(sYaw + 180), WrapAngles(sRoll)

    if i > ((DUSK_END + DUSK_START) * 0.5) or i < DAWN_START then
        xPitch, xYaw, xRoll = 90, 90, 0
    end

    return {
        sun_angle = string.format("angles %d %d %d", sPitch, sYaw, sRoll),
        shadow_angle = string.format("angles %d %d %d", xPitch, xYaw, xRoll)
    }
end

-- Store information in light table
local function storeLightInfo(i)
    local fBaseDist, fNum = 750, 300
    local timeFactor = math.abs((i - NOON) / NOON)

    local fRed = calcFogColor(98, lightTable[i].red, timeFactor)
    local fGrn = calcFogColor(105, lightTable[i].green, timeFactor)
    local fBlu = calcFogColor(111, lightTable[i].blue, timeFactor)

    local fDist = math.Clamp(
        math.floor(fBaseDist * fNum / (255 * math.Clamp(timeFactor, 0.2, 0.8))),
        1856, 3072
    )

    lightTable[i].sky_overlay_alpha = math.floor(255 * math.Clamp(math.abs((i - NOON) / (NOON - DAWN_START)), 0, 0.99))
    lightTable[i].sky_overlay_color = string.format("%d %d %d", math.floor(lightTable[i].red), math.floor(lightTable[i].green), math.floor(lightTable[i].blue))
    lightTable[i].sky_fog_color = string.format("%d %d %d", fRed, fGrn, fBlu)
    lightTable[i].sky_fog_dist = fDist

    local angles = updateSunAndShadowAngles(i)
    lightTable[i].env_sun_angle = angles.sun_angle
    lightTable[i].shadow_angle = angles.shadow_angle
end

-- Main logic to build the light table
function GM:InitializeTime()
    buildLightTable()

    for i = 1, DAY_LENGTH do
        storeLightInfo(i)
    end

    Msg("All time-related calculations complete.\n")
end

-- Handle day and night events
function GM:CheckDayNightEvents()
    if GM.CurrentTime == DAWN - 16 then
        GM.PushDayEffects(true)
        for _, dEvents in pairs(GM.timeEntities.day_events) do
            dEvents:Fire('trigger', 0)
        end
    elseif GM.CurrentTime == DUSK + 32 then
        GM.PushDayEffects(false)
        for _, nEvents in pairs(GM.timeEntities.night_events) do
            nEvents:Fire('trigger', 0)
        end
    end
end

-- Function to push day/night effects
function GM.PushDayEffects(isDay)
    if isDay == GM.DayEffects then return false end
    
    GM.DayEffects = isDay
    
    local exposureValue = isDay and '2' or '0.5'
    
    for _, nTone in pairs(GM.timeEntities.tonemap) do
        nTone:Fire('setautoexposuremax', exposureValue, 0)
    end
end
