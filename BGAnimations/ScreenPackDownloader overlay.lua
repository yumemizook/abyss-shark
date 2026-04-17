local screenName = Var("LoadingScreen") or ...
local topScreen
if BUTTON then
	BUTTON:ResetButtonTable(screenName)
end

local function UpdateLoop()
    if BUTTON then BUTTON:UpdateMouseState() end
    return false
end

local t = Def.ActorFrame {
    OnCommand = function(self)
        self:SetUpdateFunction(UpdateLoop)
        self:SetUpdateFunctionInterval(1 / (DISPLAY:GetDisplayRefreshRate() or 60))
        topScreen = SCREENMAN:GetTopScreen()
        if BUTTON then topScreen:AddInputCallback(BUTTON.InputCallback) end
    end,
    OffCommand = function(self)
        if BUTTON then BUTTON:ResetButtonTable(screenName) end
    end,
    CancelCommand = function(self)
        self:playcommand("Off")
    end,
}

t[#t + 1] = LoadActor("_cursor")
return t
