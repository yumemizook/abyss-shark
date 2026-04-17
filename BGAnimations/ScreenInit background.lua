local function input(event)
    -- If any button is pressed (not released), broadcast the skip command
    if event.type == "InputEventType_FirstPress" then
        if SCREENMAN:GetTopScreen() then
            SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
        end
    end
    return false
end

return Def.Quad {
    InitCommand=function(self)
        self:FullScreen():diffuse(color("0,0,0,1"))
    end,
    OnCommand=function(self)
        SCREENMAN:GetTopScreen():AddInputCallback(input)
    end
}
