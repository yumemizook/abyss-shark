local t = Def.ActorFrame {}
-- Judge counter: Displays W1-W5 and Miss counts during gameplay

local judges = {
    "TapNoteScore_W1",
    "TapNoteScore_W2",
    "TapNoteScore_W3",
    "TapNoteScore_W4",
    "TapNoteScore_W5",
    "TapNoteScore_Miss"
}

local judgeNames = { "Marv", "Perf", "Grt", "Good", "Bad", "Miss" }
-- Etterna standard judge colors
local judgeColors = {
    color("1,1,1,1"),        -- W1 (Marvelous - white)
    color("1,0.8,0,1"),      -- W2 (Perfect - gold)
    color("0,1,0,1"),        -- W3 (Great - green)
    color("0.4,0.7,1,1"),    -- W4 (Good - blue)
    color("1,0.2,0.4,1"),    -- W5 (Bad - crimson)
    color("0.5,0.5,0.5,1")   -- Miss (gray)
}

local counts = { 0, 0, 0, 0, 0, 0 }

-- Container with centralized judgment handling
local judgeFrame = Def.ActorFrame {
    InitCommand = function(self)
        self:xy(SCREEN_WIDTH - 70, 80)
    end,
    JudgmentMessageCommand = function(self, params)
        if not params.TapNoteScore then return end
        
        local scoreStr = tostring(params.TapNoteScore)
        for j = 1, #judges do
            if scoreStr == judges[j] then
                counts[j] = counts[j] + 1
                break
            end
        end
        
        -- Update all count displays
        for i = 1, #judges do
            local child = self:GetChild("judge" .. i)
            if child then
                local countActor = child:GetChild("count")
                if countActor and countActor.settext then
                    countActor:settext(tostring(counts[i]))
                end
            end
        end
    end
}

for i = 1, #judges do
    judgeFrame[#judgeFrame + 1] = Def.ActorFrame {
        Name = "judge" .. i,
        InitCommand = function(self)
            self:y(14 * (i - 1))
        end,
        -- Background quad for readability
        Def.Quad {
            InitCommand = function(self)
                self:zoomto(60, 12):halign(0):x(-2):diffuse(color("0,0,0,0.5"))
            end
        },
        -- Judge name
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:x(0):halign(0):zoom(0.3):diffuse(judgeColors[i])
                self:settext(judgeNames[i] .. ":")
            end
        },
        -- Count
        LoadFont("Common Normal") .. {
            Name = "count",
            InitCommand = function(self)
                self:x(45):halign(1):zoom(0.35)
                self:settext("0")
            end
        }
    }
end

t[#t + 1] = judgeFrame

return t
