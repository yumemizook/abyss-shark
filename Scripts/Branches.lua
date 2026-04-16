-- Branches determine the Screen loading logic for moving forward or backwards through screens.
-- Defining branches here is useful for writing logic in lua instead of metrics
-- Metrics points to functions found here or in the fallback branches.
-- but keep in mind the Branch table can be modified from any file (please keep it organized)

-- Always route through ScreenProfileLoad so the player profile is
-- properly loaded into PLAYER_1's slot before entering song select.
-- Without this, GetProfile(PLAYER_1) returns an empty/machine profile
-- and all skillset ratings show as 0.00.
Branch.AfterSelectStyle = function()
    return "ScreenProfileLoad"
end

-- With AutoSetStyle=true set in metrics.ini, the engine skips ScreenSelectStyle
-- and calls Branch.StartGame() instead. This override ensures we also
-- always go through ScreenProfileLoad rather than ScreenSelectProfile.
Branch.StartGame = function()
    return "ScreenProfileLoad"
end