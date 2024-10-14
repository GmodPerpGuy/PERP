VEHICLE_DATABASE = {};

// Display order for garage.
VEHICLE_DISPLAY_ORDER = {'L','At','t','g','6','Ac','Av','Ba','9','Bf','Ai','J','d','T','Aa','Al','Ad','K','An','a','Bj','Ao','1','m','Af','Bg','3','X','o','Bi','Bd','F','S','Aw','i','Ar','Bb','G','A','8','Bm','n','R','2','l','Z','Au','Ae','Cb','M','e','Ak','b','q','Ay','p','I','E','Q','N','c','Aq','O','s','Az','P','C','Ag','7','As','Bh','5','Ax','Ap','r','Am','Ab','Bl','H','Bk','4','B','Bc','f','V','forgt17','s2000','ego','bug_chiron','bmw_i8','lam_ses','lam_ast','mer_6','tesla_s','kon_one1','kon_reg','kon_ag','mclaren_720','mclaren_p1','boss_302','monster_cuda','chevy_elcamino','dev_16','ferrari_812','honda_nsx','nis_370','frei_argo','mit_colt','dod_ram1500','dod_viper','for_shel500','fer_f12','fer_enzo','fer_365','fer_ff','for_focus_svt','for_focusrs','for_focus','maz_mx5','pete_579','maz_rx7','maz_speed3','ast_db5','bug_eb','fer_lafer','bmw_1m','bmw_340i','vw_golfr32','bmw_507','bmw_m3gtr','chev_spark','chr_pt','hon_typer','chev_sting','toy_rav4','hon_civic97','hon_crxsir','mini_coupe','por_tricycle','toy_mr2gt','hum_open','toy_tundra','vw_scirocco','por_gt3rs'};

VEHICLE_DISPLAY_ORDER_NORMAL = {'por_tricycle','chr_pt','b','chev_spark','Ba','Aa','Bl','f','Bg','c','An','Bh','Aq','Ad', 'hon_civic97', 'Ar','Z','Bc','Bi','g','e','Bb','5','Ab','m','d','Av','At','l','Bj','Bk','Ac','X','o','Ai', 'chev_sting', 'i','p','Au','Ak','n','r','E','C','chevy_elcamino','q','s','boss_302','t','G', 'bug_eb', 'Bm','ego','Ay','dev_16'}; -- Non VIP

VEHICLE_DISPLAY_ORDER_VIP = {
    -- Silver VIP
    'Ao','hon_typer','2','toy_rav4','A','vw_golfr32','vw_scirocco','Af','mini_coupe','Bd','bmw_1m','Aw','3','bmw_340i','L','for_focus_svt','s2000','maz_speed3','B','dod_ram1500','6','frei_argo','lam_ast','pete_579','4','F','monster_cuda','mclaren_720','kon_ag',
    
    -- Gold VIP
    'hon_crxsir','Q','toy_mr2gt','O','toy_tundra','maz_mx5','J','maz_rx7','1','Ax','Am','T','H','hum_open','9','Bf','7','N','Al','tesla_s','nis_370','Az','fer_ff','ast_db5','dod_viper','As','mclaren_p1','Ag','fer_enzo','Ap','honda_nsx','kon_reg',

    -- Diamond VIP
    'S','bmw_m3gtr','fer_365','Ae','M','por_gt3rs','I','bmw_507','R','fer_f12','Cb','mer_6','8','lam_ses','forgt17','ferrari_812','fer_lafer','K','V','bug_chiron','a','kon_one1'
};


-- Function to merge both tables and remove duplicates
local function mergeVehicleTables(normalList, vipList)
    local seen = {} -- Tracks duplicates
    local combinedList = {} -- Final list with merged vehicles

    -- Add non-VIP vehicles
    for _, vehicle in ipairs(normalList) do
        if not seen[vehicle] then
            table.insert(combinedList, vehicle)
            seen[vehicle] = true
        end
    end

    -- Add VIP vehicles (if not already in the list)
    for _, vehicle in ipairs(vipList) do
        if not seen[vehicle] then
            table.insert(combinedList, vehicle)
            seen[vehicle] = true
        end
    end

    return combinedList
end

-- Combine the lists into one final display order without duplicates
VEHICLE_DISPLAY_ORDER = mergeVehicleTables(VEHICLE_DISPLAY_ORDER, VEHICLE_DISPLAY_ORDER_VIP)

-- Debugging: Print out the merged list to check
for _, vehicle in ipairs(VEHICLE_DISPLAY_ORDER) do
    print(vehicle)
end


-- Function to register a vehicle and handle conflicts
function GM:RegisterVehicle(VehicleTable)
    if VEHICLE_DATABASE[VehicleTable.ID] then
        -- Error message for conflicting IDs
        Error("Conflicting vehicle ID's #" .. VehicleTable.ID .. "\n")
        return -- Early return to prevent loading the conflicting vehicle
    end
    
    -- Client-side texture loading if required
    if CLIENT and not VehicleTable.RequiredClass then
        VehicleTable.Texture = surface.GetTextureID('PERP2/vehicles/new/' .. VehicleTable.Script)
    end
    
    -- Precache all paintjob models
    for _, paintJob in pairs(VehicleTable.PaintJobs) do
        util.PrecacheModel(paintJob.model)
    end
    
    -- Register the vehicle in the database
    VEHICLE_DATABASE[VehicleTable.ID] = VehicleTable
    Msg("\t-> Loaded " .. VehicleTable.Name .. ", " .. VehicleTable.ID .. "\n")
end

-- Function to check if a player owns a specific vehicle
function PLAYER:HasVehicle(vehicleID)
    local playerTable
    
    -- Check if it's the server or client side
    if SERVER then 
        playerTable = self.Vehicles 
    else 
        playerTable = GAMEMODE.Vehicles 
    end
    
    -- Return true if the player has the vehicle
    return playerTable[vehicleID] ~= nil
end

-- Optional: Function to remove a vehicle if there’s a conflict
function GM:RemoveConflictingVehicle(vehicleID)
    if VEHICLE_DATABASE[vehicleID] then
        VEHICLE_DATABASE[vehicleID] = nil
        Msg("Conflicting vehicle ID " .. vehicleID .. " removed from VEHICLE_DATABASE.\n")
    end
end
