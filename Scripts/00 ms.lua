ms = {
    JudgeScalers = {
        1.50, 1.33, 1.16, 1.00, 0.84, 0.66, 0.50, 0.33, 0.20
    }
}

-- Return the judge color for a given offset (ms) and scale
-- This matches the color scheme in ScreenEvaluation overlay.lua
function offsetToJudgeColor(offset, scale)
    local absOffset = math.abs(offset)
    local s = scale or 1
    if absOffset <= 22.5 * s then return color("1,1,1,1")     -- W1
    elseif absOffset <= 45.0 * s then return color("1,0.8,0,1")     -- W2
    elseif absOffset <= 90.0 * s then return color("0,1,0,1")     -- W3
    elseif absOffset <= 135.0 * s then return color("0.4,0.7,1,1")   -- W4
    elseif absOffset <= 180.0 * s then return color("1,0.2,0.4,1")   -- W5
    else return color("0.5,0.5,0.5,1") end -- Miss
-- Standard helpers often used in Etterna themes
function findminmax(t, i)
    if t == nil or #t == 0 then return 0 end
    local mi = t[1][i]
    local ma = t[1][i]
    for _,v in ipairs(t) do
        if v[i] < mi then mi = v[i] end
        if v[i] > ma then ma = v[i] end
    end
    return mi, ma
end

function getDifficulty(diff)
    return ToEnumShortString(diff)
end

function getRateString()
    local rate = GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate()
    return string.format("%.2f", rate) .. "x"
end

function getCurRateValue()
    return GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate()
end

function getCurRateString()
    return getRateString()
end

function getCurRateDisplayString()
    return string.format("%.2f", getCurRateValue()) .. "x"
end

function getTabIndex()
    return 0
end

function ChangeMusicRateAbyss(step)
    local rate = getCurRateValue()
    local newRate = math.max(0.05, math.min(3.0, rate + step))
    GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate(newRate)
    MESSAGEMAN:Broadcast("CurrentRateChanged")
end
