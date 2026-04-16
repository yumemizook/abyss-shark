local t = Def.ActorFrame {}
-- Offset display: Shows mean offset and deviation during gameplay

local offsets = {}
local maxOffsetCount = 50  -- Keep last 50 offsets for calculation

t[#t + 1] = Def.ActorFrame {
    InitCommand = function(self)
        self:xy(10, SCREEN_HEIGHT - 50)
    end,
    
    -- Background
    Def.Quad {
        InitCommand = function(self)
            self:zoomto(110, 40):halign(0):diffuse(color("0,0,0,0.6"))
        end
    },
    
    -- Mean offset
    LoadFont("Common Normal") .. {
        Name = "MeanOffset",
        InitCommand = function(self)
            self:xy(5, -8):halign(0):zoom(0.35)
            self:settext("MEAN: 0.00ms")
            self:diffuse(color("0.8,0.8,0.8,1"))
        end,
        JudgmentMessageCommand = function(self, params)
            -- params.TapNoteOffset is in seconds, nil on misses
            if params.TapNoteOffset and params.TapNoteScore ~= "TapNoteScore_Miss" then
                local offsetMs = params.TapNoteOffset * 1000
                
                -- Add to table
                table.insert(offsets, 1, offsetMs)
                if #offsets > maxOffsetCount then
                    table.remove(offsets)
                end
                
                -- Calculate mean
                local sum = 0
                for _, v in ipairs(offsets) do
                    sum = sum + v
                end
                local mean = sum / #offsets
                
                self:settextf("MEAN: %+.2fms", mean)
                
                -- Color: early (negative) = red tint, late (positive) = blue tint
                if mean < -5 then
                    self:diffuse(color("1,0.5,0.5,1"))
                elseif mean > 5 then
                    self:diffuse(color("0.5,0.7,1,1"))
                else
                    self:diffuse(color("0.8,0.8,0.8,1"))
                end
            end
        end
    },
    
    -- Standard deviation
    LoadFont("Common Normal") .. {
        Name = "StdDev",
        InitCommand = function(self)
            self:xy(5, 5):halign(0):zoom(0.35)
            self:settext("SD: 0.00ms")
            self:diffuse(color("0.6,0.9,0.6,1"))
        end,
        JudgmentMessageCommand = function(self, params)
            if params.TapNoteOffset and params.TapNoteScore ~= "TapNoteScore_Miss" then
                if #offsets >= 2 then
                    -- Calculate mean
                    local sum = 0
                    for _, v in ipairs(offsets) do
                        sum = sum + v
                    end
                    local mean = sum / #offsets
                    
                    -- Calculate variance
                    local varianceSum = 0
                    for _, v in ipairs(offsets) do
                        varianceSum = varianceSum + (v - mean) ^ 2
                    end
                    local stdDev = math.sqrt(varianceSum / #offsets)
                    
                    self:settextf("SD: %.2fms", stdDev)
                    
                    -- Color by consistency
                    if stdDev < 5 then
                        self:diffuse(color("0.2,1,0.2,1"))      -- Very consistent
                    elseif stdDev < 10 then
                        self:diffuse(color("0.6,0.9,0.6,1"))    -- Good
                    elseif stdDev < 20 then
                        self:diffuse(color("1,0.9,0.2,1"))       -- Okay
                    else
                        self:diffuse(color("1,0.5,0.2,1"))       -- Inconsistent
                    end
                end
            end
        end
    },
    
    -- Sample count indicator
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:xy(5, 18):halign(0):zoom(0.22)
            self:diffuse(color("0.5,0.5,0.5,1"))
            self:settext("n=0")
        end,
        JudgmentMessageCommand = function(self, params)
            if params.TapNoteOffset and params.TapNoteScore ~= "TapNoteScore_Miss" then
                self:settextf("n=%d", #offsets)
            end
        end
    }
}

return t
