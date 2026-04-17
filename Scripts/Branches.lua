
Branch.AfterSelectStyle = function()
    return "ScreenProfileLoad"
end

-- With AutoSetStyle=true set in metrics.ini, the engine skips ScreenSelectStyle
-- and calls Branch.StartGame() instead. This override ensures we also
-- always go through ScreenProfileLoad rather than ScreenSelectProfile.
Branch.StartGame = function()
    return "ScreenProfileLoad"
end