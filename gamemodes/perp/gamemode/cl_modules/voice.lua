


local static_Start = Sound("PERP2.5/cradio_start.mp3")
local static_Stop = Sound("PERP2.5/cradio_close.mp3")

-- Function to manage radio static sound
local function thinkRadioStatic()
    if GAMEMODE.PlayStatic then
        if not GAMEMODE.StaticNoise then
            GAMEMODE.StaticNoise = CreateSound(LocalPlayer(), "PERP2.5/cradio_static.mp3")
        end

        if not GAMEMODE.NextStaticPlay or GAMEMODE.NextStaticPlay < CurTime() then
            GAMEMODE.NextStaticPlay = CurTime() + SoundDuration("PERP2.5/cradio_static.mp3") - 0.1
            GAMEMODE.StaticNoise:Stop()
            GAMEMODE.StaticNoise:Play()
        end
    elseif GAMEMODE.StaticNoise then
        GAMEMODE.StaticNoise:Stop()
        GAMEMODE.StaticNoise = nil
    end
end
hook.Add("Think", "thinkRadioStatic", thinkRadioStatic)

-- Function to manage voice chat and static effects
function GM:PlayerStartVoice(ply)
    if ply == LocalPlayer() then
        GAMEMODE.CurrentlyTalking = true
        return
    end

    if ply:GetPos():Distance(LocalPlayer():GetPos()) > ChatRadius_Local + 50 and
       ply:Team() ~= TEAM_CITIZEN and ply:Team() ~= TEAM_MAYOR and
       ply:GetRPName() ~= GAMEMODE.Call_Player then
        GAMEMODE.PlayStatic = true
        ply.PlayingStaticFor = true
        surface.PlaySound(static_Start)
    end
end

function GM:PlayerEndVoice(ply)
    if ply == LocalPlayer() then
        GAMEMODE.CurrentlyTalking = nil
        return
    end

    if ply.PlayingStaticFor then
        ply.PlayingStaticFor = nil
        surface.PlaySound(static_Stop)
    end

    if not GAMEMODE.PlayStatic then return end

    local shouldPlayStatic = false
    for _, v in pairs(player.GetAll()) do
        if v.PlayingStaticFor then
            shouldPlayStatic = true
            break
        end
    end

    GAMEMODE.PlayStatic = shouldPlayStatic
end

-- Function to monitor key presses for walkie-talkie functionality
local function monitorKeyPress_WalkieTalkie()
    if GAMEMODE.ChatBoxOpen or
       (GAMEMODE.MayorPanel and GAMEMODE.MayorPanel:IsVisible()) or
       (GAMEMODE.OrgPanel and GAMEMODE.OrgPanel:IsVisible()) or
       (GAMEMODE.HelpPanel and GAMEMODE.HelpPanel:IsVisible()) then
        return
    end

    if input.IsKeyDown(KEY_T) then
        if not GAMEMODE.lastTDown then
            GAMEMODE.lastTDown = true
            local isRadioOn = LocalPlayer():GetUMsgBool("tradio", false)
            if isRadioOn then
                RunConsoleCommand("perp_tr", "0")
                LocalPlayer().StringRedun["tradio"] = {entity = LocalPlayer(), value = false}
            else
                RunConsoleCommand("perp_tr", "1")
                LocalPlayer().StringRedun["tradio"] = {entity = LocalPlayer(), value = true}
            end
        end
    else
        GAMEMODE.lastTDown = nil
    end
end
hook.Add("Think", "monitorKeyPress_WalkieTalkie", monitorKeyPress_WalkieTalkie);
