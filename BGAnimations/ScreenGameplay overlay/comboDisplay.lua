local t = Def.ActorFrame {}
-- Combo display: Shows current combo count during gameplay
-- Colors based on worst judgment of the CURRENT running combo (resets each hit)

local currentCombo = 0
local maxCombo = 0
local lowestJudgeInCombo = 1  -- Resets each judgment to track only current combo
local comboAtLastJudgment = 0 -- Track combo count when we last judged

-- Etterna standard judge colors
local judgeColors = {
    color("1,1,1,1"),        -- W1 (Marvelous - white)
    color("1,0.8,0,1"),      -- W2 (Perfect - gold)
    color("0,1,0,1"),        -- W3 (Great - green)
    color("0.4,0.7,1,1"),    -- W4 (Good - blue)
    color("1,0.2,0.4,1"),    -- W5 (Bad - crimson/red)
    color("0.5,0.5,0.5,1")   -- Miss (gray)
}

t[#t + 1] = Def.ActorFrame {
    InitCommand = function(self)
        self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y - 60)
    end,
    
    JudgmentMessageCommand = function(self, params)
        if not params.TapNoteScore then return end
        
        local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
        local comboNow = pss and pss:GetCurrentCombo() or 0
        
        local scoreStr = tostring(params.TapNoteScore)
        local judgeLevel = 1
        
        if scoreStr == "TapNoteScore_W1" then
            judgeLevel = 1
        elseif scoreStr == "TapNoteScore_W2" then
            judgeLevel = 2
        elseif scoreStr == "TapNoteScore_W3" then
            judgeLevel = 3
        elseif scoreStr == "TapNoteScore_W4" then
            judgeLevel = 4
        elseif scoreStr == "TapNoteScore_W5" then
            judgeLevel = 5
        elseif scoreStr == "TapNoteScore_Miss" then
            lowestJudgeInCombo = 1
            comboAtLastJudgment = 0
            return
        end
        
        -- Track the worst (highest) judgment in the current combo
        -- Reset only happens when combo breaks to 0 (handled in ComboChanged)
        if comboNow > 0 then
            -- If we have no prior tracking or combo increased, continue tracking
            -- If combo stayed same (hold notes), continue tracking
            -- If combo dropped but >0 (shouldn't happen normally), continue tracking
            if judgeLevel > lowestJudgeInCombo then
                lowestJudgeInCombo = judgeLevel
            end
            comboAtLastJudgment = comboNow
        end
    end,
    
    -- Combo number
    LoadFont("Common Normal") .. {
        Name = "ComboNumber",
        InitCommand = function(self)
            self:zoom(1.2):shadowlength(1)
            self:settext("0")
        end,
        ComboChangedMessageCommand = function(self, params)
            local oldCombo = currentCombo
            
            if params.PlayerStageStats then
                currentCombo = params.PlayerStageStats:GetCurrentCombo()
            else
                currentCombo = params.OldCombo or 0
            end
            
            self:settext(tostring(currentCombo))
            
            -- Update max combo when increasing (while combo is running)
            if currentCombo > maxCombo then
                maxCombo = currentCombo
            end
            
            -- On combo break, also check if the broken combo was higher
            if currentCombo == 0 and oldCombo > maxCombo then
                maxCombo = oldCombo
            end
            
            -- Reset on combo break
            if currentCombo == 0 then
                lowestJudgeInCombo = 1
                comboAtLastJudgment = 0
            end
            
            -- Pulse animation on combo milestone
            if currentCombo > 0 and currentCombo % 100 == 0 then
                self:stoptweening():zoom(1.5):decelerate(0.2):zoom(1.2)
            end
            
            -- Color based on lowest judgment in current running combo
            if currentCombo > 0 then
                self:diffuse(judgeColors[lowestJudgeInCombo])
            else
                self:diffuse(color("0.5,0.5,0.5,1")) -- Gray (broken)
            end
        end
    },
    
    -- "COMBO" label
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:y(25):zoom(0.4)
            self:settext("COMBO")
        end,
        ComboChangedMessageCommand = function(self, params)
            if params.PlayerStageStats then
                currentCombo = params.PlayerStageStats:GetCurrentCombo()
            else
                currentCombo = params.OldCombo or 0
            end
            
            -- Color based on lowest judgment in this combo
            if currentCombo > 0 then
                self:diffuse(judgeColors[lowestJudgeInCombo])
            else
                self:diffuse(color("0.5,0.5,0.5,1"))
            end
        end
    },
    
    -- Max combo indicator (small)
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:y(40):zoom(0.25):diffuse(color("0.7,0.7,0.7,1"))
            self:settext("MAX: 0")
        end,
        ComboChangedMessageCommand = function(self, params)
            if maxCombo > 0 then
                self:settextf("MAX: %d", maxCombo)
            end
        end
    }
}

return t
