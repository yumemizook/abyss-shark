local t = Def.ActorFrame {}
-- Wife% tracker: Displays current accuracy percentage during gameplay

local totalNotes = 0

local function getTotalNotes()
    local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
    if steps then
        return steps:GetRadarValues(PLAYER_1):GetValue("RadarCategory_Notes")
    end
    return 0
end

local function getWifePercent()
    local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
    if not pss then return 0, 0, 0, 0 end
    
    local cur = pss:GetCurWifeScore()
    -- Percentage uses current running max (current notes * 2)
    local curMax = pss:GetMaxWifeScore()
    -- Raw score denominator uses total possible (total notes * 2)
    if totalNotes == 0 then
        totalNotes = getTotalNotes()
    end
    local totalMax = totalNotes * 2
    
    if curMax > 0 then
        return (cur / curMax) * 100, cur, totalMax
    end
    return 0, cur, totalMax
end

local function getGradeColor(pct)
    -- Grade colors based on Etterna standard grades
    if pct >= 99.9935 then      -- AAAAA
        return color("1,1,1,1"), "AAAAA"      -- White
    elseif pct >= 99.955 then  -- AAAA
        return color("0,0.9,1,1"), "AAAA"   -- Cyan
    elseif pct >= 99.7 then  -- AAA
        return color("1,0.8,0,1"), "AAA"    -- Gold
    elseif pct >= 93 then  -- AA
        return color("0.3,0.8,0.3,1"), "AA"    -- Green
    elseif pct >= 80 then  -- A
        return color("1,0.5,0.7,1"), "A"     -- light crimson
    elseif pct >= 70 then  -- B
        return color("0.4,0.6,1,1"), "B"   -- blue
    elseif pct >= 60 then  -- C
        return color("0.7,0.3,0.9,1"), "C"   -- purple
    else
        return color("0.5,0.5,0.5,1"), "D"   -- Gray
    end
end

local function updateDisplay(pctActor, rawActor, gradeActor)
    local pct, cur, max = getWifePercent()
    
    if pctActor and pctActor.settext then
        pctActor:settextf("%.2f%%", pct)
        pctActor:diffuse(color("1,1,1,1"))  -- White, no color change
    end
    
    if gradeActor and gradeActor.settext then
        local gradeColor, grade = getGradeColor(pct)
        gradeActor:settext(grade)
        gradeActor:diffuse(gradeColor)  -- Colored grade
    end
    
    if rawActor and rawActor.settext then
        -- Show raw score with 2 decimal places, denominator is total possible Wife points
        rawActor:settextf("%.2f / %d", cur, max)
    end
end

t[#t + 1] = Def.ActorFrame {
    InitCommand = function(self)
        self:xy(SCREEN_CENTER_X, 35)
        self:sleep(0):queuecommand("Update")
    end,
    UpdateCommand = function(self)
        local pctActor = self:GetChild("WifePercent")
        local rawActor = self:GetChild("WifeRaw")
        local gradeActor = self:GetChild("WifeGrade")
        updateDisplay(pctActor, rawActor, gradeActor)
        self:sleep(0.033):queuecommand("Update")
    end,
    
    -- Grade label (above percentage)
    LoadFont("Common Normal") .. {
        Name = "WifeGrade",
        InitCommand = function(self)
            self:y(-18):zoom(0.5):shadowlength(1)
            self:settext("D")
        end
    },
    
    -- Percentage text
    LoadFont("Common Normal") .. {
        Name = "WifePercent",
        InitCommand = function(self)
            self:zoom(0.9):shadowlength(1)
            self:settext("0.00%")
        end
    },
    
    -- Small raw score indicator
    LoadFont("Common Normal") .. {
        Name = "WifeRaw",
        InitCommand = function(self)
            self:y(18):zoom(0.25):diffuse(color("0.6,0.6,0.6,1"))
            self:settext("0 / 0")
        end
    }
}

return t
