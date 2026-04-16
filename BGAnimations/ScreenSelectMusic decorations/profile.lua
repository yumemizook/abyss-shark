local t = Def.ActorFrame {}
-- the Profile relevant children of the ScreenSelectMusic decorations actorframe
-- Enhanced with PB tracking and additional profile features

local wheelX = 15
local arbitraryWheelXThing = 17
local space = 20

-- Get profile dynamically (not at file load time)
-- Uses GetPlayerOrMachineProfile to get either player or machine profile as fallback
-- Get profile dynamically (not at file load time)
local function getProfile()
    local success, p
    
    -- 1. Try GetProfile(PLAYER_1) - Most compatible standard method
    success, p = pcall(function() return PROFILEMAN:GetProfile(PLAYER_1) end)
    if success and p and p.GetPlayerRating then return p end
    
    -- 2. Try GetLocalProfile (Alternative for some Etterna builds)
    success, p = pcall(function() return PROFILEMAN:GetLocalProfile() end)
    if success and p and p.GetPlayerRating then return p end
    
    -- 3. Try global helper GetPlayerOrMachineProfile
    if GetPlayerOrMachineProfile then
        success, p = pcall(function() return GetPlayerOrMachineProfile(PLAYER_1) end)
        if success and p and p.GetPlayerRating then return p end
    end
    
    -- 4. Try Machine Profile as an absolute last resort
    success, p = pcall(function() return PROFILEMAN:GetMachineProfile() end)
    if success and p and p.GetPlayerRating then return p end

    return nil
end

-- Get Personal Best for current song (Bulletproof Version)
local function getPersonalBest(song, steps)
    local profile = getProfile()
    if not song or not steps then return nil end
    if type(profile) ~= "userdata" or type(steps) ~= "userdata" then return nil end
    
    local scores = {}
    
    -- Method A: GetHighScoresByKey (Modern Etterna)
    if profile.GetHighScoresByKey then
        local success, results = pcall(function() return profile:GetHighScoresByKey(steps:GetChartKey()) end)
        if success and type(results) == "table" then scores = results end
    end
    
    -- Method B: Profile HighScoreList (StepMania 5 / Older Etterna Fallback)
    if (not scores or #scores == 0) and profile.GetHighScoreList then
        local success, hsl = pcall(function() return profile:GetHighScoreList(steps) end)
        if success and hsl and hsl.GetHighScores then
            scores = hsl:GetHighScores()
        end
    end
    
    -- Method C: Steps HighScoreList (Alternative fallback)
    if (not scores or #scores == 0) and steps.GetHighScoreList then
        local success, hsl = pcall(function() return steps:GetHighScoreList(profile) end)
        if success and hsl and hsl.GetHighScores then
            scores = hsl:GetHighScores()
        end
    end
    
    if type(scores) == "table" and #scores > 0 then
        -- Find best wife score
        local best = scores[1]
        for i = 2, #scores do
            if scores[i] and scores[i].GetWifeScore and best and best.GetWifeScore then
                if scores[i]:GetWifeScore() > best:GetWifeScore() then
                    best = scores[i]
                end
            end
        end
        return best
    end
    return nil
end

-- Get best Wife% for current song
local function getPersonalBestWife(song, steps)
    local pb = getPersonalBest(song, steps)
    if pb then
        return pb:GetWifeScore() * 100
    end
    return 0
end

-- Helper function for grade colors
function getWifeGradeColor(grade)
    local gradeColors = {
        Tier01 = color("1,1,1,1"),      -- AAAAA
        Tier02 = color("0,0.9,1,1"),    -- AAAA
        Tier03 = color("1,0.8,0,1"),    -- AAA
        Tier04 = color("0.3,0.8,0.3,1"),-- AA
        Tier05 = color("1,0.5,0.7,1"),  -- A
        Tier06 = color("0.4,0.6,1,1"),  -- B
        Tier07 = color("0.7,0.3,0.9,1"),-- C
        Tier08 = color("0.5,0.5,0.5,1"),-- D
        Tier09 = color("0.3,0.3,0.3,1"),-- F
    }
    return gradeColors[grade] or color("1,1,1,1")
end

-- Profile rating section (bottom right)
t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
        self:x(wheelX + arbitraryWheelXThing + space + capWideScale(get43size(365),365)-50)
        self:y(SCREEN_CENTER_Y + SCREEN_HEIGHT/2 - 20 - 10 * #ms.SkillSets)
        self:playcommand("Refresh")
    end,
    OnCommand = function(self)
        self:playcommand("Refresh")
    end,
    RefreshCommand = function(self)
        local profile = getProfile()
        local container = self:GetChild("SkillsetContainer")
        if container then
            for i = 1, #ms.SkillSets do
                local ssActor = container:GetChild("SS" .. i)
                if ssActor and profile then
                    local rating = i == 1 and profile:GetPlayerRating() or profile:GetPlayerSkillsetRating(ms.SkillSets[i])
                    ssActor:settextf("%s: %5.2f", ms.SkillSetsTranslated[i], rating)
                end
            end
        end
    end,

    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:zoom(.5):halign(0)
            self:settext("Player Rating")
        end
    },
    -- Skillset ratings - generated dynamically
    Def.ActorFrame {
        Name = "SkillsetContainer",
        InitCommand = function(self)
            self:y(10)
        end,
        children = (function()
            local children = {}
            for i = 1, #ms.SkillSets do
                children[#children+1] = LoadFont("Common Normal") .. {
                    Name = "SS" .. i,
                    InitCommand = function(self)
                        self:y(10 * i)
                        self:zoom(.3)
                        self:halign(0)
                    end
                }
            end
            return children
        end)()
    }
}

-- Personal Best display section (right side, above steps display)
t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
        self:x(wheelX + arbitraryWheelXThing + space + capWideScale(get43size(365),365)-50)
        self:y(SCREEN_CENTER_Y - 20)
    end,
    CurrentSongChangedMessageCommand = function(self)
        self:playcommand("Refresh")
    end,
    CurrentStepsChangedMessageCommand = function(self)
        self:playcommand("Refresh")
    end,
    RefreshCommand = function(self)
        local song = GAMESTATE:GetCurrentSong()
        local steps = GAMESTATE:GetCurrentSteps()
        local pbLabel = self:GetChild("PBLabel")
        local pbValue = self:GetChild("PBValue")
        local gradeLabel = self:GetChild("GradeLabel")

        if song and steps and pbLabel and pbValue then
            local pb = getPersonalBest(song, steps)
            if pb then
                local wife = pb:GetWifeScore() * 100
                local grade = pb:GetWifeGrade()
                pbValue:settextf("%.2f%%", wife)
                pbValue:diffuse(getWifeGradeColor(grade))
                if gradeLabel then
                    gradeLabel:settext(grade)
                    gradeLabel:diffuse(getWifeGradeColor(grade))
                    gradeLabel:visible(true)
                end
                pbLabel:settext("PB:")
            else
                pbValue:settext("--")
                pbValue:diffuse(color("0.5,0.5,0.5,1"))
                if gradeLabel then
                    gradeLabel:visible(false)
                end
                pbLabel:settext("PB: No Play")
            end
        else
            pbLabel:settext("PB: --")
            pbValue:settext("")
            if gradeLabel then
                gradeLabel:visible(false)
            end
        end
    end,

    -- Header
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:zoom(.5):halign(0)
            self:settext("Personal Best")
        end
    },
    -- PB Label
    LoadFont("Common Normal") .. {
        Name = "PBLabel",
        InitCommand = function(self)
            self:y(15):zoom(.4):halign(0)
            self:settext("PB: --")
        end
    },
    -- PB Value
    LoadFont("Common Normal") .. {
        Name = "PBValue",
        InitCommand = function(self)
            self:y(15):x(70):zoom(.4):halign(0)
            self:settext("")
        end
    },
    -- Grade Badge
    LoadFont("Common Normal") .. {
        Name = "GradeLabel",
        InitCommand = function(self)
            self:y(15):x(140):zoom(.35):halign(0)
            self:settext("")
            self:visible(false)
        end
    }
}

return t