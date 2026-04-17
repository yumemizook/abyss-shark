-- Custom Cursor System for The Fool
-- Ported from Til Death / Fallback logic

local function UpdateLoop(self)
    local mouseX = INPUTFILTER:GetMouseX()
    local mouseY = INPUTFILTER:GetMouseY()
    
    -- Follow mouse
    if TOOLTIP then
        TOOLTIP:SetPosition(mouseX, mouseY)
    end
end

local t = Def.ActorFrame {
    OnCommand = function(self)
        self:SetUpdateFunction(UpdateLoop)
        -- Set update frequency to match display refresh
        self:SetUpdateFunctionInterval(1 / (DISPLAY:GetDisplayRefreshRate() or 60))
        
        if TOOLTIP then
            TOOLTIP:SetTextSize(0.35)
            TOOLTIP:ShowPointer()
        end
    end,
    OffCommand = function(self)
        if TOOLTIP then
            TOOLTIP:Hide()
            TOOLTIP:HidePointer()
        end
    end
}

-- Initialize tooltip actors from fallback
if TOOLTIP and TOOLTIP.New then
    local tooltip, pointer, clickwave = TOOLTIP:New()
    t[#t+1] = tooltip
    t[#t+1] = pointer
    t[#t+1] = clickwave
end

return t
