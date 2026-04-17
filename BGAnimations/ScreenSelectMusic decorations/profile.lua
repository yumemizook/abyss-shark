local t = Def.ActorFrame {}
-- the Profile relevant children of the ScreenSelectMusic decorations actorframe

local PLAYER_1 = _G["PLAYER_1"] or 0

local wheelX = 15
local arbitraryWheelXThing = 17
local space = 20
local panelX = wheelX + arbitraryWheelXThing + space + capWideScale(get43size(365),365)-50

-- ----------------------------------------------------------------
-- Helpers for HighScore info
-- ----------------------------------------------------------------
local function getJudge(score)
    if not score then return 4 end

    -- 1. Use GetJudgeScale (most reliable in modern Etterna)
    if score.GetJudgeScale then
        local ok, scale = pcall(function() return score:GetJudgeScale() end)
        if ok and type(scale) == "number" then
            local roundedScale = math.floor(scale * 100 + 0.5) / 100
            for i, val in ipairs(ms.JudgeScalers) do
                if math.abs(roundedScale - val) < 0.01 then
                    return i
                end
            end
        end
    end

    -- 2. Try parsing from modifier strings (fallback)
    local m1 = score.GetModifiers and score:GetModifiers() or ""
    local m2 = score.GetModifierString and score:GetModifierString() or ""
    local mods = (m1 .. " " .. m2):lower()

    local jd = mods:match("judgedifficulty[:%s]*(%d+)") or 
               mods:match("judge[:%s]*(%d+)") or 
               mods:match("j(%d+)")

    if jd then
        local val = tonumber(jd)
        if val and val > 0 then return val end
    end

    -- 3. Try direct engine methods (fallback)
    if score.GetJudgeDifficulty then
        local ok, val = pcall(function() return score:GetJudgeDifficulty() end)
        if ok and val and val > 0 then return val end
    end

    -- 4. Check for specific Etterna-style attributes
    if score.GetAttributes then
        local ok, attr = pcall(function() return score:GetAttributes() end)
        if ok and attr and attr.JudgeDifficulty then return attr.JudgeDifficulty end
    end

    return 4
end

local function getDateString(score)
    if not score then return "" end
    local d = ""
    if score.GetDate then
        pcall(function() d = score:GetDate() end)
    elseif score.GetDateTime then
        pcall(function() d = score:GetDateTime() end)
    end
    return d:match("(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d)") or d
end

local function rescoreToJ4(score)
    if not score then return 0 end
    
    -- 1. Try engine rescore (SSR Normalized)
    if score.GetSSRNormPercent then
        local ok, norm = pcall(function() return score:GetSSRNormPercent() end)
        if ok and norm and norm > 0 then return norm * 100 end
    end

    -- 2. Manual approximation by mapping judgments
    -- J4 Windows: W1: 22.5, W2: 45, W3: 90, W4: 135, W5: 180
    local jd = getJudge(score)
    local s = ms.JudgeScalers[jd] or 1
    
    local w1 = score:GetTapNoteScore("TapNoteScore_W1")
    local w2 = score:GetTapNoteScore("TapNoteScore_W2")
    local w3 = score:GetTapNoteScore("TapNoteScore_W3")
    local w4 = score:GetTapNoteScore("TapNoteScore_W4")
    local w5 = score:GetTapNoteScore("TapNoteScore_W5")
    local miss = score:GetTapNoteScore("TapNoteScore_Miss")
    
    local j4w1, j4w2, j4w3, j4w4, j4w5 = 0,0,0,0,0
    
    if s <= 0.5 then -- J7 (0.5), J8 (0.33), J9 (0.2)
        j4w1 = w1 + w2
        j4w2 = w3
        j4w3 = w4 + w5
    elseif s <= 0.84 then -- J5 (0.84), J6 (0.66)
        j4w1 = w1
        j4w2 = w2 + w3
        j4w3 = w4
    else -- J4 (1.0) or easier
        j4w1 = w1
        j4w2 = w2
        j4w3 = w3
        j4w4 = w4
        j4w5 = w5
    end
    
    local totalNotes = w1 + w2 + w3 + w4 + w5 + miss
    if totalNotes == 0 then return 0 end
    
    -- Linear Wife Approximation points
    local points = (j4w1 * 2) + (j4w2 * 1.5) + (j4w3 * 1) + (j4w4 * 0.5) + (j4w5 * 0) + (miss * -8)
    return math.max(0, (points / (totalNotes * 2)) * 100)
end

-- ----------------------------------------------------------------
-- Score fetch: SCOREMAN:GetScoresByKey returns a rate-keyed dict
-- each value is a ScoreList with :GetScores() -> array of scores
-- ----------------------------------------------------------------
local function getPersonalBest(steps)
    if not steps then return nil, nil end
    local rateVal = getCurRateValue()
    -- Format rate to match ScoreStack keys (e.g. 1.0x, 1.15x)
    local rateStr = string.format("%.2f", rateVal):gsub("%.?0+$", "") .. "x"
    if rateStr == "1x" then rateStr = "1.0x" end
    if rateStr == "2x" then rateStr = "2.0x" end

    local ck = steps:GetChartKey()
    if not ck or ck == "" then return nil, nil end

    local scorestack
    pcall(function() scorestack = SCOREMAN:GetScoresByKey(ck) end)
    if not scorestack then return nil, nil end

    local best = nil
    local scorelist = scorestack[rateStr]
    if scorelist then
        local scores = scorelist:GetScores()
        if scores then
            for _, s in ipairs(scores) do
                if best == nil or s:GetWifeScore() > best:GetWifeScore() then
                    best = s
                end
            end
        end
    end
    return best
end

-- Grade tier -> color
local function gradeColor(grade)
    local c = {
        Tier01 = color("1,1,1,1"),
        Tier02 = color("0,0.9,1,1"),
        Tier03 = color("1,0.8,0,1"),
        Tier04 = color("0.3,0.8,0.3,1"),
        Tier05 = color("1,0.5,0.7,1"),
        Tier06 = color("0.4,0.6,1,1"),
        Tier07 = color("0.7,0.3,0.9,1"),
        Tier08 = color("0.5,0.5,0.5,1"),
        Tier09 = color("0.3,0.3,0.3,1"),
    }
    return c[grade] or color("1,1,1,1")
end
-- expose globally for other files
function getWifeGradeColor(g) return gradeColor(g) end

-- Judge window names
local judgeNames = { "Marv", "Perf", "Grt", "Good", "Bad", "Miss" }
local judgeKeys  = {
    "TapNoteScore_W1","TapNoteScore_W2","TapNoteScore_W3",
    "TapNoteScore_W4","TapNoteScore_W5","TapNoteScore_Miss"
}
local judgeColors = {
    color("1,1,1,1"), color("1,0.8,0,1"), color("0,0.9,0.3,1"),
    color("0.4,0.7,1,1"), color("1,0.3,0.3,1"), color("0.5,0.5,0.5,1")
}

-- ----------------------------------------------------------------
local profIndex = 1
t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
        self:x(panelX)
        self:y(SCREEN_HEIGHT - 35)
        self:playcommand("Refresh")
    end,
    OnCommand = function(self)
        self:playcommand("Refresh")
        self:sleep(3):queuecommand("Cycle")
    end,
    CycleCommand = function(self)
        profIndex = profIndex + 1
        if profIndex > #ms.SkillSets then profIndex = 1 end
        self:playcommand("Refresh")
        self:sleep(3):queuecommand("Cycle")
    end,
    RefreshCommand = function(self)
        local profile
        local ok = pcall(function() profile = PROFILEMAN:GetProfile(PLAYER_1) end)
        if not ok or not profile then return end
        
        local name = self:GetChild("ProfileName")
        if name then 
            name:settext(profile:GetDisplayName()) 
        end
        
        local rating = self:GetChild("RatingDisplay")
        if rating then
            local val = profIndex == 1
                and profile:GetPlayerRating()
                or  profile:GetPlayerSkillsetRating(ms.SkillSets[profIndex])
            
            if profIndex == 1 then
                rating:settextf("%.2f", val)
                rating:diffuse(color("#4488FF")) -- Overall in blue
            else
                rating:settextf("%s: %.2f", ms.SkillSetsTranslated[profIndex], val)
                rating:diffuse(color("1,1,1,1"))
            end
        end
    end,

    LoadFont("Common Normal") .. {
        Name = "ProfileName",
        InitCommand = function(self) 
            self:zoom(.35):halign(0):diffuse(color("#888888")) 
        end
    },
    LoadFont("Common Normal") .. {
        Name = "RatingDisplay",
        InitCommand = function(self) 
            self:y(12):zoom(.5):halign(0) 
        end
    }
}

-- ----------------------------------------------------------------
-- Personal Best panel — detailed stats
-- ----------------------------------------------------------------
t[#t+1] = Def.ActorFrame {
    Name = "PBPanel",
    InitCommand = function(self)
        self:x(panelX)
        self:y(SCREEN_HEIGHT - 155)
    end,
    CurrentSongChangedMessageCommand  = function(self) self:queuecommand("Refresh") end,
    CurrentStepsChangedMessageCommand = function(self) self:queuecommand("Refresh") end,
    CurrentRateChangedMessageCommand  = function(self) self:queuecommand("Refresh") end,

    RefreshCommand = function(self)
        local steps = GAMESTATE:GetCurrentSteps()
        local pb = getPersonalBest(steps)
        local rateVal = getCurRateValue()

        -- header label
        local hdr = self:GetChild("Header")
        if hdr then
            hdr:settext(string.format("Personal Best (%.2fx)", rateVal):gsub("%.?0+x", "x"))
            hdr:diffuse(pb and color("1,1,1,1") or color("0.45,0.45,0.45,1"))
        end

        -- Wife% + grade row
        local wifeActor  = self:GetChild("Wife")
        local gradeActor = self:GetChild("Grade")
        if wifeActor then
            if pb then
                local wife  = pb:GetWifeScore() * 100
                local grade = pb:GetWifeGrade()
                wifeActor:settextf("%.4f%%", wife)
                wifeActor:diffuse(gradeColor(grade))
                if gradeActor then
                    gradeActor:settext(THEME:GetString("Grade", ToEnumShortString(grade)))
                    gradeActor:diffuse(gradeColor(grade))
                    gradeActor:visible(true)
                end
            else
                wifeActor:settext("No Play")
                wifeActor:diffuse(color("0.45,0.45,0.45,1"))
                if gradeActor then gradeActor:visible(false) end
            end
        end

        -- SSR
        local ssrActor = self:GetChild("SSR")
        if ssrActor then
            if pb then
                local ssr = pb:GetSkillsetSSR("Overall")
                ssrActor:settextf("SSR: %.2f", ssr)
                ssrActor:diffuse(color("0.4,0.7,1,1"))
            else
                ssrActor:settext("")
            end
        end

        -- J4 Active Rescore
        local j4Actor = self:GetChild("J4Best")
        if j4Actor then
            if pb then
                local mainJD = getJudge(pb)
                local j4perc = rescoreToJ4(pb)

                -- Only show if it's not already a J4 score (or effectively the same)
                if mainJD ~= 4 and math.abs(j4perc - (pb:GetWifeScore()*100)) > 0.01 then
                    j4Actor:visible(true)
                    local format = j4perc >= 99.7 and "%.4f%%" or "%.2f%%"
                    j4Actor:settextf(format, j4perc)
                    j4Actor:diffuse(color("0.7,0.7,0.7,1"))
                else
                    j4Actor:visible(false)
                end
            else
                j4Actor:visible(false)
            end
        end

        -- Judge / Date row
        local judgeActor = self:GetChild("JudgeLine")
        local dateActor  = self:GetChild("DateLine")
        if judgeActor then
            if pb then
                judgeActor:settext("J"..getJudge(pb))
                judgeActor:diffuse(color("0.8,0.8,0.8,1"))
            else
                judgeActor:settext("")
            end
        end
        if dateActor then
            if pb then
                dateActor:settext(getDateString(pb))
                dateActor:diffuse(color("0.5,0.5,0.5,1"))
            else
                dateActor:settext("")
            end
        end

        -- Judgement counts
        local jContainer = self:GetChild("JudgeContainer")
        if jContainer then
            for i = 1, 6 do
                local cActor = jContainer:GetChild("JC"..i)
                if cActor then
                    if pb then
                        local ok2, val = pcall(function() return pb:GetTapNoteScore(judgeKeys[i]) end)
                        cActor:settext(ok2 and tostring(val) or "")
                        cActor:diffuse(judgeColors[i])
                    else
                        cActor:settext("")
                    end
                end
            end
        end
    end,

    -- Background quad
    Def.Quad {
        InitCommand = function(self)
            self:zoomto(220, 80):halign(0):valign(0)
            self:diffuse(color("0,0,0,0.35"))
        end
    },

    -- Header
    LoadFont("Common Normal") .. {
        Name = "Header",
        InitCommand = function(self)
            self:xy(4, 4):zoom(0.28):halign(0)
            self:settext("Personal Best")
            self:diffuse(color("0.5,0.5,0.5,1"))
        end
    },

    -- Wife%
    LoadFont("Common Normal") .. {
        Name = "Wife",
        InitCommand = function(self)
            self:xy(4, 14):zoom(0.42):halign(0)
            self:settext("No Play")
            self:diffuse(color("0.45,0.45,0.45,1"))
        end
    },

    -- Grade badge (right of wife%)
    LoadFont("Common Normal") .. {
        Name = "Grade",
        InitCommand = function(self)
            self:xy(180, 14):zoom(0.35):halign(0)
            self:settext("")
            self:visible(false)
        end
    },

    -- SSR
    LoadFont("Common Normal") .. {
        Name = "SSR",
        InitCommand = function(self)
            self:xy(4, 25):zoom(0.28):halign(0)
            self:settext("")
        end
    },

    -- Judge difficulty label
    LoadFont("Common Normal") .. {
        Name = "JudgeLine",
        InitCommand = function(self)
            self:xy(80, 25):zoom(0.28):halign(0)
            self:settext("")
        end
    },

    -- J4 Best label
    LoadFont("Common Normal") .. {
        Name = "J4Best",
        InitCommand = function(self)
            self:xy(92, 14):zoom(0.26):halign(0)
            self:settext("")
            self:visible(false)
        end
    },

    -- Date
    LoadFont("Common Normal") .. {
        Name = "DateLine",
        InitCommand = function(self)
            self:xy(4, 34):zoom(0.25):halign(0)
            self:settext("")
        end
    },

    -- Judgement counts row
    Def.ActorFrame {
        Name = "JudgeContainer",
        InitCommand = function(self) self:xy(4, 45) end,
        children = (function()
            local ch = {}
            local spacing = 34
            for i = 1, 6 do
                -- name label
                ch[#ch+1] = LoadFont("Common Normal") .. {
                    InitCommand = function(self)
                        self:xy((i-1)*spacing, 0):zoom(0.2):halign(0)
                        self:settext(judgeNames[i])
                        self:diffuse(judgeColors[i])
                    end
                }
                -- count
                ch[#ch+1] = LoadFont("Common Normal") .. {
                    Name = "JC"..i,
                    InitCommand = function(self)
                        self:xy((i-1)*spacing, 9):zoom(0.28):halign(0)
                        self:settext("")
                        self:diffuse(judgeColors[i])
                    end
                }
            end
            return ch
        end)()
    },
}

return t