local t = Def.ActorFrame {}

-- Top Left: Date/Time
t[#t+1] = Def.BitmapText {
    Font="Common Normal",
    InitCommand=function(self)
        self:xy(10, 10):halign(0):valign(0):zoom(0.45):diffuse(color("1,1,1,1"))
        self:playcommand("Update")
    end,
    UpdateCommand=function(self)
        local timeStr = string.format("%04d-%02d-%02d %02d:%02d:%02d", Year(), MonthOfYear(), DayOfMonth(), Hour(), Minute(), Second())
        self:settext(timeStr)
        self:sleep(1):queuecommand("Update")
    end
}

-- Top Right: Theme Name
t[#t+1] = Def.BitmapText {
    Font="Common Normal",
    InitCommand=function(self)
        self:xy(SCREEN_WIDTH-10, 10):halign(1):valign(0):zoom(0.45):diffuse(color("1,1,1,1"))
        local themeName = "The Fool"
        self:settext(themeName)
    end
}

-- Bottom Left: Songs Loaded
t[#t+1] = Def.BitmapText {
    Font="Common Normal",
    InitCommand=function(self)
        self:xy(10, SCREEN_HEIGHT-10):halign(0):valign(1):zoom(0.45):diffuse(color("1,1,1,1"))
        local numSongs = SONGMAN:GetNumSongs()
        self:settext(numSongs .. " Songs Loaded")
    end
}

-- Bottom Right: Judge/Life difficulty
t[#t+1] = Def.BitmapText {
    Font="Common Normal",
    InitCommand=function(self)
        self:xy(SCREEN_WIDTH-10, SCREEN_HEIGHT-10):halign(1):valign(1):zoom(0.45):diffuse(color("1,1,1,1"))
        
        local judgeStr = type(GetTimingDifficulty) == "function" and tostring(GetTimingDifficulty()) or "?"
        local lifeStr = type(GetLifeDifficulty) == "function" and tostring(GetLifeDifficulty()) or "?"
        
        self:settext(string.format("Judge: %s  Life: %s", judgeStr, lifeStr))
    end
}

return t
