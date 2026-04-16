local t = Def.ActorFrame {}
-- ScreenGameplay overlay - combines all HUD elements

-- Load individual HUD components
t[#t + 1] = LoadActor("judgeCounter")
t[#t + 1] = LoadActor("comboDisplay")
t[#t + 1] = LoadActor("wifePercent")
t[#t + 1] = LoadActor("offsetDisplay")

return t
