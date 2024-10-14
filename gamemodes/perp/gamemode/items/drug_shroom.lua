local ITEM = {}

ITEM.ID = 83
ITEM.Reference = "drug_shroom"

ITEM.Name = '"Magic" Mushrooms'
ITEM.Description = "I wouldn't eat these by themselves... Use to eat. Drop to plant."
ITEM.Weight = 10
ITEM.Cost = 200
ITEM.MaxStack = 500
ITEM.Undroppable = false

ITEM.InventoryModel = "models/fungi/sta_skyboxshroom1.mdl"
ITEM.WorldModel = "models/fungi/sta_skyboxshroom1.mdl"
ITEM.ModelCamPos = Vector(16, 30, 20)
ITEM.ModelLookAt = Vector(0, 0, 14)
ITEM.ModelFOV = 70

ITEM.RestrictedSelling = true

if SERVER then
    function ITEM.OnUse(Player)
        Player:SendLua([[surface.PlaySound('perp2.5/eating.mp3') timer.Simple(math.random(3, 7), function() GAMEMODE.ShroomStart = CurTime() end)]])
        return true
    end

    function ITEM.OnDrop(Player)
        local Trace = Player:GetEyeTrace()

        -- Check if the player is looking at dirt and within a reasonable distance
        if Trace.HitPos:Distance(Player:GetPos()) <= 200 and Trace.HitWorld and Trace.MatType == MAT_DIRT then
            if Player:IsGovernmentOfficial() then
                Player:Notify('You cannot do this as a government official!')
                return false
            end
            
            local NumShroomsAlready = 0
            for _, v in pairs(ents.FindByClass('ent_shroom')) do
                if v:GetTable().Owner == Player then
                    NumShroomsAlready = NumShroomsAlready + 1
                end
            end
            
            if NumShroomsAlready > 5 then
                Player:Notify("It looks like the soil can't handle any more vegetation.")
                return false
            end

            -- Plant the mushroom
            local Shroom = ents.Create('ent_shroom')
            Shroom:SetPos(Trace.HitPos)
            Shroom:Spawn()
            Shroom:GetTable().Owner = Player
            Player:Notify("You have planted the mushrooms.")
            Player:SetNetworkedInt("shrooms", Player:GetNetworkedInt("shrooms") + 1)
            Player:TakeItemByID(ITEM.ID, 1, true)
            return true
        else
            -- If not looking at dirt, drop the mushroom for someone else to pick up
            local DropPos = Player:GetPos() + Player:GetForward() * 50 + Vector(0, 0, 10)
            local Drop = ents.Create("ent_shroom")
            Drop:SetModel(ITEM.WorldModel)
            Drop:SetPos(DropPos)
            Drop:Spawn()

            -- Allow the item to be picked up
            Drop:GetTable().Owner = nil -- No specific owner
            Drop:SetCollisionGroup(COLLISION_GROUP_WEAPON)

            Player:TakeItemByID(ITEM.ID, 1, true)
            Player:Notify("You have dropped the mushrooms.")
            return true
        end
    end

    function ITEM.Equip(Player) end
    function ITEM.Holster(Player) end

else
    local TransitionTime = 6
    local TimeLasting = 60

    local function MakeEffects()
        if not GAMEMODE.ShroomStart then return end
        
        local End = GAMEMODE.ShroomStart + TimeLasting + TransitionTime * 2
        
        if End < CurTime() then return end

        local shroom_tab = {}
        shroom_tab["$pp_colour_addr"] = 0
        shroom_tab["$pp_colour_addg"] = 0
        shroom_tab["$pp_colour_addb"] = 0
        shroom_tab["$pp_colour_mulr"] = 0
        shroom_tab["$pp_colour_mulg"] = 0
        shroom_tab["$pp_colour_mulb"] = 0
        
        local TimeGone = CurTime() - GAMEMODE.ShroomStart
        
        if TimeGone < TransitionTime then
            local pf = TimeGone / TransitionTime
            shroom_tab["$pp_colour_colour"] = 1 - pf * 0.37
            shroom_tab["$pp_colour_brightness"] = -pf * 0.15
            shroom_tab["$pp_colour_contrast"] = 1 + pf * 1.57
        elseif TimeGone > TransitionTime + TimeLasting then
            local pf = 1 - ((TimeGone - TransitionTime - TimeLasting) / TransitionTime)
            shroom_tab["$pp_colour_colour"] = 1 - pf * 0.37
            shroom_tab["$pp_colour_brightness"] = -pf * 0.15
            shroom_tab["$pp_colour_contrast"] = 1 + pf * 1.57
        else
            shroom_tab["$pp_colour_colour"] = 0.63
            shroom_tab["$pp_colour_brightness"] = -0.15
            shroom_tab["$pp_colour_contrast"] = 2.57
        end

        DrawColorModify(shroom_tab)
        DrawSharpen(8.32, 1.03)
    end
    hook.Add("RenderScreenspaceEffects", "MakeEffects_Mushrooms", MakeEffects)

    function ITEM.OnUse(slotID)
        return true
    end

    function ITEM.OnDrop()
        return false
    end
end

GM:RegisterItem(ITEM)

