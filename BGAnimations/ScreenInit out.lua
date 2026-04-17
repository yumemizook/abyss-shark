return Def.Actor {
    OnCommand=function(self)
        -- Hold the ScreenInit state for 2.6 seconds so the quotes have time to be read and fade out.
        self:sleep(2.6)
    end,
    SkipInitMessageCommand=function(self)
        -- Instantly finish the sleep tween, breaking the out delay immediately
        self:finishtweening()
    end
}
