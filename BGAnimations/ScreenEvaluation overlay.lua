local t = Def.ActorFrame {}
-- ScreenEvaluation overlay - Complete overhaul with stats

local PLAYER_1 = _G["PLAYER_1"] or 0
local PLAYER_2 = _G["PLAYER_2"] or 1

-- Fetch objects lazily to avoid nil errors at script load
local function getPSS()
    local ss = STATSMAN:GetCurStageStats()
    return ss and ss:GetPlayerStageStats(PLAYER_1)
end

local function getScore()
    local p = getPSS()
    return p and p:GetHighScore()
end

local function getSong() return GAMESTATE:GetCurrentSong() end
local function getSteps() return GAMESTATE:GetCurrentSteps() end


local judges = {
    "TapNoteScore_W1",
    "TapNoteScore_W2",
    "TapNoteScore_W3",
    "TapNoteScore_W4",
    "TapNoteScore_W5",
    "TapNoteScore_Miss"
}

local judgeNames = { "Marv", "Perf", "Grt", "Good", "Bad", "Miss" }
local judgeColors = {
    color("1,1,1,1"),
    color("1,0.8,0,1"),
    color("0,1,0,1"),
    color("0.4,0.7,1,1"),
    color("1,0.2,0.4,1"),
    color("0.5,0.5,0.5,1")
}

-- ================================================================
-- EMBEDDED GLOBALS & HELPERS
-- ================================================================
local ms = {
    JudgeScalers = { 1.50, 1.33, 1.16, 1.00, 0.84, 0.66, 0.50, 0.33, 0.20 }
}

local function offsetToJudgeColor(offset, scale)
    local absOffset = math.abs(offset)
    local s = scale or 1
    if absOffset <= 22.5 * s then return judgeColors[1]
    elseif absOffset <= 45.0 * s then return judgeColors[2]
    elseif absOffset <= 90.0 * s then return judgeColors[3]
    elseif absOffset <= 135.0 * s then return judgeColors[4]
    elseif absOffset <= 180.0 * s then return judgeColors[5]
    else return judgeColors[6] end
end

local function getDifficulty(diff) return ToEnumShortString(diff) end
local function getCurRateValue() return GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate() end
local function getRateString() return string.format("%.2f", getCurRateValue()) .. "x" end

-- Session Tracker (Local fallback if global nil)
if not SessionStats then
    SessionStats = { SongsPlayed = 0, TotalWife = 0, BestWife = 0, BestSSR = 0 }
end

local function AddScoreToSession(pss, score, steps)
    if not pss or not score then return end
    SessionStats.SongsPlayed = SessionStats.SongsPlayed + 1
    local wife = score:GetWifeScore() * 100
    SessionStats.TotalWife = SessionStats.TotalWife + wife
    if wife > SessionStats.BestWife then SessionStats.BestWife = wife end
end


-- Helper: Get grade from Wife%
local function getGrade(wifePct)
    if wifePct >= 99.9935 then return "AAAAA", color("1,1,1,1")
    elseif wifePct >= 99.955 then return "AAAA", color("0,0.9,1,1")
    elseif wifePct >= 99.7 then return "AAA", color("1,0.8,0,1")
    elseif wifePct >= 93 then return "AA", color("0.3,0.8,0.3,1")
    elseif wifePct >= 80 then return "A", color("1,0.5,0.7,1")
    elseif wifePct >= 70 then return "B", color("0.4,0.6,1,1")
    elseif wifePct >= 60 then return "C", color("0.7,0.3,0.9,1")
    else return "D", color("0.5,0.5,0.5,1") end
end

-- Helper: Get clear type
local function getClearType()
    local score = getScore()
    if not score then return "Clear", color("0.7,0.7,0.7,1") end
    local w1 = score:GetTapNoteScore("TapNoteScore_W1")
    local w2 = score:GetTapNoteScore("TapNoteScore_W2")
    local w3 = score:GetTapNoteScore("TapNoteScore_W3")
    local w4 = score:GetTapNoteScore("TapNoteScore_W4")
    local w5 = score:GetTapNoteScore("TapNoteScore_W5")
    local miss = score:GetTapNoteScore("TapNoteScore_Miss")

    
    if miss == 0 and w5 == 0 and w4 == 0 and w3 == 0 and w2 == 0 then
        return "MFC", color("1,1,1,1")
    elseif miss == 0 and w5 == 0 and w4 == 0 and w3 == 0 then
        return "PFC", color("1,0.8,0,1")
    elseif miss == 0 and w5 == 0 and w4 == 0 then
        return "FFC", color("0.3,0.8,0.3,1")
    elseif miss == 0 and w5 == 0 then
        return "FC", color("0.4,0.6,1,1")
    elseif miss == 0 then
        return "SDG", color("0.7,0.3,0.9,1")
    else
        return "Clear", color("0.7,0.7,0.7,1")
    end
end

-- Helper: Calculate MA/PA
local function getRatios()
    local score = getScore()
    if not score then return 0, 0 end
    local w1 = score:GetTapNoteScore("TapNoteScore_W1")
    local w2 = score:GetTapNoteScore("TapNoteScore_W2")
    local w3 = score:GetTapNoteScore("TapNoteScore_W3")

    
    local ma = 0
    local pa = 0
    
    if w2 > 0 then ma = w1 / w2 end
    if w3 > 0 then pa = w2 / w3 end
    
    return ma, pa
end

-- Main container
t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
        self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
    end,

    -- Log score to session once
    Def.Actor {
        OnCommand = function(self)
            local screen = SCREENMAN:GetTopScreen()
            if screen and not screen.Abyss_ScoreLogged then
                local p = getPSS()
                local s = getScore()
                if p and s then
                    AddScoreToSession(p, s, getSteps())
                    screen.Abyss_ScoreLogged = true
                    MESSAGEMAN:Broadcast("UpdateSessionStats")
                end
            end
        end
    },


    
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:y(-SCREEN_HEIGHT/2 + 20):zoom(0.5)
            self:maxwidth(SCREEN_WIDTH * 1.5)
            local song = getSong()
            if song then self:settext(song:GetDisplayMainTitle()) end
        end
    },
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:y(-SCREEN_HEIGHT/2 + 40):zoom(0.35)
            local song = getSong()
            local steps = getSteps()
            if song and steps then
                self:settext(song:GetDisplayArtist() .. "  //  " .. getDifficulty(steps:GetDifficulty()))
            end
        end
    },
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:y(-SCREEN_HEIGHT/2 + 55):zoom(0.25)
            self:settext(getRateString(getCurRateValue()) .. "  //  Judge " .. GetTimingDifficulty())
        end
    },

    
    -- Center: Wife% and Grade
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:y(-20):zoom(1.5)
            local s = getScore()
            local wife = (s and s:GetWifeScore() or 0) * 100
            self:settextf("%.4f%%", wife)
        end
    },
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:y(10):zoom(0.6)
            local s = getScore()
            local grade, col = getGrade((s and s:GetWifeScore() or 0) * 100)
            self:settext(grade)
            self:diffuse(col)
        end
    },
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:y(35):zoom(0.4)
            local ct, col = getClearType()
            self:settext(ct)
            self:diffuse(col)
        end
    },

    
    -- Left side: Judge counts
    Def.ActorFrame {
        InitCommand = function(self)
            self:x(-120):y(-30)
        end,
        -- Generate judge rows
        Def.ActorFrame {
            -- Judge rows: outer containers are ActorFrames so GetChild works on them
            Def.ActorFrame { Name = "judge1", InitCommand = function(self) self:y(0):x(0) end,
                LoadFont("Common Normal") .. { Name = "name", InitCommand = function(self)
                    self:halign(0):x(-30):zoom(0.35)
                    self:settext(judgeNames[1] .. ":")
                    self:diffuse(judgeColors[1])
                end },
                LoadFont("Common Normal") .. { Name = "count", InitCommand = function(self)
                    self:halign(1):x(30):zoom(0.35)
                    local s = getScore()
                    self:settext(tostring(s and s:GetTapNoteScore(judges[1]) or 0))
                end }
            },
            Def.ActorFrame { Name = "judge2", InitCommand = function(self) self:y(14) end,
                LoadFont("Common Normal") .. { Name = "name", InitCommand = function(self)
                    self:halign(0):x(-30):zoom(0.35)
                    self:settext(judgeNames[2] .. ":")
                    self:diffuse(judgeColors[2])
                end },
                LoadFont("Common Normal") .. { Name = "count", InitCommand = function(self)
                    self:halign(1):x(30):zoom(0.35)
                    local s = getScore()
                    self:settext(tostring(s and s:GetTapNoteScore(judges[2]) or 0))
                end }
            },
            Def.ActorFrame { Name = "judge3", InitCommand = function(self) self:y(28) end,
                LoadFont("Common Normal") .. { Name = "name", InitCommand = function(self)
                    self:halign(0):x(-30):zoom(0.35)
                    self:settext(judgeNames[3] .. ":")
                    self:diffuse(judgeColors[3])
                end },
                LoadFont("Common Normal") .. { Name = "count", InitCommand = function(self)
                    self:halign(1):x(30):zoom(0.35)
                    local s = getScore()
                    self:settext(tostring(s and s:GetTapNoteScore(judges[3]) or 0))
                end }
            },
            Def.ActorFrame { Name = "judge4", InitCommand = function(self) self:y(42) end,
                LoadFont("Common Normal") .. { Name = "name", InitCommand = function(self)
                    self:halign(0):x(-30):zoom(0.35)
                    self:settext(judgeNames[4] .. ":")
                    self:diffuse(judgeColors[4])
                end },
                LoadFont("Common Normal") .. { Name = "count", InitCommand = function(self)
                    self:halign(1):x(30):zoom(0.35)
                    local s = getScore()
                    self:settext(tostring(s and s:GetTapNoteScore(judges[4]) or 0))
                end }
            },
            Def.ActorFrame { Name = "judge5", InitCommand = function(self) self:y(56) end,
                LoadFont("Common Normal") .. { Name = "name", InitCommand = function(self)
                    self:halign(0):x(-30):zoom(0.35)
                    self:settext(judgeNames[5] .. ":")
                    self:diffuse(judgeColors[5])
                end },
                LoadFont("Common Normal") .. { Name = "count", InitCommand = function(self)
                    self:halign(1):x(30):zoom(0.35)
                    local s = getScore()
                    self:settext(tostring(s and s:GetTapNoteScore(judges[5]) or 0))
                end }
            },
            Def.ActorFrame { Name = "judge6", InitCommand = function(self) self:y(70) end,
                LoadFont("Common Normal") .. { Name = "name", InitCommand = function(self)
                    self:halign(0):x(-30):zoom(0.35)
                    self:settext(judgeNames[6] .. ":")
                    self:diffuse(judgeColors[6])
                end },
                LoadFont("Common Normal") .. { Name = "count", InitCommand = function(self)
                    self:halign(1):x(30):zoom(0.35)
                    local s = getScore()
                    self:settext(tostring(s and s:GetTapNoteScore(judges[6]) or 0))
                end }
            }

        }
    },
    
    -- Right side: Stats
    Def.ActorFrame {
        InitCommand = function(self)
            self:x(120):y(-30)
        end,
        -- Max Combo
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                local p = getPSS()
                local s = getScore()
                local mc = (s and s.GetMaxCombo and s:GetMaxCombo()) or (p and p.GetMaxCombo and p:GetMaxCombo()) or 0
                self:settextf("Max Combo: %d", mc)
            end
        },
        -- MA/PA
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:y(16):zoom(0.35):halign(0)
                local ma, pa = getRatios()
                self:settextf("MA: %.2f  PA: %.2f", ma, pa)
            end
        },
        -- Mean/SD/Largest offset
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:y(32):zoom(0.35):halign(0)
                local s = getScore()
                local replay = s and s:GetReplay()
                local offsets = replay and replay:GetOffsetVector() or {}
                if #offsets > 0 then

                    local sum = 0
                    local maxOff = 0
                    for _, v in ipairs(offsets) do
                        sum = sum + v
                        if math.abs(v) > math.abs(maxOff) then maxOff = v end
                    end
                    local mean = sum / #offsets
                    local varSum = 0
                    for _, v in ipairs(offsets) do
                        varSum = varSum + (v - mean) ^ 2
                    end
                    local sd = math.sqrt(varSum / #offsets)
                    self:settextf("Mean: %+.1fms  SD: %.1fms", mean, sd)
                else
                    self:settext("Mean: --  SD: --")
                end
            end
        },
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:y(48):zoom(0.35):halign(0)
                local s = getScore()
                local replay = s and s:GetReplay()
                local offsets = replay and replay:GetOffsetVector() or {}
                if #offsets > 0 then

                    local maxOff = 0
                    for _, v in ipairs(offsets) do
                        if math.abs(v) > math.abs(maxOff) then maxOff = v end
                    end
                    self:settextf("Largest: %+.1fms", maxOff)
                else
                    self:settext("Largest: --")
                end
            end
        },
        -- MSD/SSR
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:y(70):zoom(0.3):halign(0)
                local st = getSteps()
                local sc = getScore()
                local msd = st and st:GetMSD(getCurRateValue(), 1) or 0
                local ssr = sc and sc:GetSkillsetSSR("Overall") or 0
                self:settextf("MSD: %5.2f  SSR: %5.2f", msd, ssr)
            end
        }

    },
    
    -- Profile display (bottom left) with Session Stats
    Def.ActorFrame {
        InitCommand = function(self)
            self:x(-SCREEN_WIDTH/2 + 40):y(SCREEN_HEIGHT/2 - 50)
        end,
        Def.Quad {
            InitCommand = function(self)
                self:zoomto(90, 100):diffuse(color("0,0,0,0.5"))
            end
        },
        -- Profile Name
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:y(-40):zoom(0.25)
                self:settext(PROFILEMAN:GetProfile(PLAYER_1):GetDisplayName())
            end
        },
        -- Overall Rating
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:y(-28):zoom(0.2)
                local rating = PROFILEMAN:GetProfile(PLAYER_1):GetPlayerRating()
                self:settextf("Rating: %.2f", rating)
            end
        },
        -- Total Plays
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:y(-16):zoom(0.2)
                local plays = PROFILEMAN:GetProfile(PLAYER_1):GetTotalNumSongsPlayed()
                self:settextf("Plays: %d", plays)
            end
        },
        -- Separator line
        Def.Quad {
            InitCommand = function(self)
                self:y(-5):zoomto(80, 1):diffuse(color("1,1,1,0.3"))
            end
        },
        -- Session header
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:y(2):zoom(0.22)
                self:settext("Session")
                self:diffuse(color("0.8,0.8,1,1"))
            end
        },
        -- Session songs played
        LoadFont("Common Normal") .. {
            Name = "SessionSongs",
            InitCommand = function(self) self:y(15):zoom(0.2) end,
            OnCommand = function(self) self:playcommand("Update") end,
            UpdateSessionStatsMessageCommand = function(self) self:playcommand("Update") end,
            UpdateCommand = function(self)
                self:settextf("Songs: %d", SessionStats.SongsPlayed)
            end
        },
        -- Session average Wife%
        LoadFont("Common Normal") .. {
            Name = "SessionAvg",
            InitCommand = function(self) self:y(27):zoom(0.2) end,
            OnCommand = function(self) self:playcommand("Update") end,
            UpdateSessionStatsMessageCommand = function(self) self:playcommand("Update") end,
            UpdateCommand = function(self)
                local avg = (SessionStats.SongsPlayed > 0) and (SessionStats.TotalWife / SessionStats.SongsPlayed) or 0
                self:settextf("Avg: %.2f%%", avg)
            end
        },
        -- Best score this session
        LoadFont("Common Normal") .. {
            Name = "SessionBest",
            InitCommand = function(self) self:y(39):zoom(0.2) end,
            OnCommand = function(self) self:playcommand("Update") end,
            UpdateSessionStatsMessageCommand = function(self) self:playcommand("Update") end,
            UpdateCommand = function(self)
                self:settextf("Best: %.2f%%", SessionStats.BestWife)
            end
        }
    },
    
    -- ================================================================
    -- OFFSET PLOT (ported from Holographic Void OffsetGraph.lua)
    -- ================================================================
    Def.ActorFrame {
        Name = "OffsetPlot",
        InitCommand = function(self)
            self:xy(-70, SCREEN_HEIGHT / 2 - 82)
        end,

        -- Background
        Def.Quad {
            InitCommand = function(self)
                self:zoomto(SCREEN_WIDTH - 400, 130):diffuse(color("0.04,0.04,0.07,0.88"))
            end
        },

        -- Title
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                local w = SCREEN_WIDTH - 400
                self:zoom(0.32):halign(0):x(-w / 2 + 6):y(-57)
                self:settext("Offset Plot"):diffuse(color("0.55,0.82,1,1"))
            end
        },

        -- 0 ms center line
        Def.Quad {
            InitCommand = function(self)
                self:zoomto(SCREEN_WIDTH - 400, 1):diffuse(color("1,1,1,0.55"))
            end
        },

        -- Judgment window threshold lines (W2 / W3 / W4, scaled by judge)
        (function()
            local af = Def.ActorFrame {}
            local windows = { 45, 90, 135 }
            local cols = {
                color("1,0.82,0,0.28"),
                color("0.1,1,0.4,0.2"),
                color("0.35,0.65,1,0.16"),
            }
            for i = 1, #windows do
                local wMs = windows[i]
                local c   = cols[i]
                -- Upper (late) line
                af[#af+1] = Def.Quad {
                    InitCommand = function(self)
                        local tso = ms.JudgeScalers[GetTimingDifficulty()] or 1
                        self:zoomto(SCREEN_WIDTH - 400, 1)
                        self:y(-(wMs * tso / 180) * 55)
                        self:diffuse(c)
                    end
                }
                -- Lower (early) line
                af[#af+1] = Def.Quad {
                    InitCommand = function(self)
                        local tso = ms.JudgeScalers[GetTimingDifficulty()] or 1
                        self:zoomto(SCREEN_WIDTH - 400, 1)
                        self:y((wMs * tso / 180) * 55)
                        self:diffuse(c)
                    end
                }
            end
            return af
        end)(),

        -- "+Xms LATE" top-right label
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                local w   = SCREEN_WIDTH - 400
                local tso = ms.JudgeScalers[GetTimingDifficulty()] or 1
                self:zoom(0.25):halign(1):x(w / 2 - 5):y(-51)
                self:diffuse(color("0.55,0.55,0.55,1"))
                self:settextf("+%.0fms", 180 * tso)
            end
        },

        -- "-Xms EARLY" bottom-right label
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                local w   = SCREEN_WIDTH - 400
                local tso = ms.JudgeScalers[GetTimingDifficulty()] or 1
                self:zoom(0.25):halign(1):x(w / 2 - 5):y(51)
                self:diffuse(color("0.55,0.55,0.55,1"))
                self:settextf("-%.0fms", 180 * tso)
            end
        },

        -- "No replay data" fallback
        LoadFont("Common Normal") .. {
            Name = "NoReplayLabel",
            InitCommand = function(self)
                self:zoom(0.33):diffuse(color("0.4,0.4,0.4,1"))
                self:settext("No replay data")
            end,
            BeginCommand = function(self)
                local hasData = false
                pcall(function()
                    local s = getScore()
                    local rp = s and s:GetReplay()
                    if rp then
                        rp:LoadAllData()
                        local d = rp:GetOffsetVector()
                        hasData = d and #d > 0
                    end
                end)
                self:visible(not hasData)
            end
        },


        -- Dots (ActorMultiVertex – ported from HV OffsetGraph.lua)
        Def.ActorMultiVertex {
            Name = "OffsetDots",
            InitCommand = function(self)
                self:SetVertices({})
                self:SetDrawState{Mode = "DrawMode_Quads", First = 1, Num = 0}
            end,
            BeginCommand = function(self)
                local plotW  = SCREEN_WIDTH - 400
                local plotH  = 110   -- inner drawable height (excluding label area)
                local maxMs  = 180
                local tso    = ms.JudgeScalers[GetTimingDifficulty()] or 1
                local dotW   = 1.5

                local nrv, dvt, ntt
                local ok = pcall(function()
                    local s = getScore()
                    local rp = s and s:GetReplay()
                    if not rp then return end
                    rp:LoadAllData()
                    nrv = rp:GetNoteRowVector()    or {}
                    dvt = rp:GetOffsetVector()     or {}
                    ntt = rp:GetTapNoteTypeVector() or {}
                end)
                if not ok or not dvt or #dvt == 0 then return end

                local song   = getSong()
                local steps  = getSteps()
                local td     = steps and steps:GetTimingData()

                local finalSec = (song and song:GetLastSecond()) or 1
                if finalSec <= 0 then finalSec = 1 end

                -- Convert note rows to elapsed seconds
                local times = {}
                if td then
                    for i, row in ipairs(nrv) do
                        times[i] = td:GetElapsedTimeFromNoteRow(row)
                    end
                end

                local function fitX(t)
                    return (t / finalSec) * plotW - plotW / 2
                end
                local function fitY(ms_val)
                    local y = -(ms_val / maxMs) * (plotH / 2)
                    return math.max(-plotH / 2, math.min(plotH / 2, y))
                end

                local verts = {}
                for i, offset in ipairs(dvt) do
                    local noteType = ntt and ntt[i]
                    if noteType ~= "TapNoteType_Mine" then
                        local t = times[i] or 0
                        if math.abs(offset) >= 1000 then
                            -- Miss: faint vertical stripe
                            local x  = fitX(t)
                            local mc = {0.5, 0.5, 0.5, 0.14}
                            verts[#verts+1] = {{x - 1, -plotH/2, 0}, mc}
                            verts[#verts+1] = {{x + 1, -plotH/2, 0}, mc}
                            verts[#verts+1] = {{x + 1,  plotH/2, 0}, mc}
                            verts[#verts+1] = {{x - 1,  plotH/2, 0}, mc}
                        else
                            local x = fitX(t)
                            local y = fitY(offset)
                            local c = {1, 1, 1, 0.85}
                            pcall(function()
                                local raw = offsetToJudgeColor(offset, tso)
                                c = {raw[1], raw[2], raw[3], 0.85}
                            end)
                            verts[#verts+1] = {{x - dotW, y + dotW, 0}, c}
                            verts[#verts+1] = {{x + dotW, y + dotW, 0}, c}
                            verts[#verts+1] = {{x + dotW, y - dotW, 0}, c}
                            verts[#verts+1] = {{x - dotW, y - dotW, 0}, c}
                        end
                    end
                end

                self:SetVertices(verts)
                self:SetDrawState{Mode = "DrawMode_Quads", First = 1, Num = #verts}
            end
        },
    },
    
    -- ================================================================
    -- LIFE & COMBO GRAPHS (bottom right)
    -- ================================================================
    Def.ActorFrame {
        Name = "Graphs",
        InitCommand = function(self)
            self:xy(SCREEN_WIDTH / 2 - 130, SCREEN_HEIGHT / 2 - 82)
        end,

        -- Glassmorphism background
        Def.Quad {
            InitCommand = function(self)
                self:zoomto(240, 130)
                self:diffuse(color("0,0,0,0.6"))
            end
        },
        Def.Quad {
            InitCommand = function(self)
                self:zoomto(240, 130)
                self:diffuse(color("0.1,0.2,0.4,0.15"))
                self:blend("BlendMode_Add")
            end
        },

        -- Life Graph Title
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:zoom(0.3):y(-57):halign(0):x(-115)
                self:settext("Life & Combo"):diffuse(color("0.6,0.9,1,1"))
            end
        },

        -- 1. Life Graph (Top half - Custom vertex implementation for robustness)
        Def.ActorMultiVertex {
            Name = "LifeGraphVertex",
            InitCommand = function(self)
                self:xy(-115, -25):SetVertices({})
                self:SetDrawState{Mode = "DrawMode_LineStrip", First = 1, Num = 0}
            end,
            BeginCommand = function(self)
                local ss = SCREENMAN:GetTopScreen():GetStageStats()
                local p = getPSS()
                if not ss or not p then return end
                
                local lifeRecord = {}
                local ok = pcall(function()
                    -- Try pss first, then fallback to StageStats:GetLifeRecord(0) if pss:GetLifeRecord() throws "bad self"
                    if p and p.GetLifeRecord then
                        lifeRecord = p:GetLifeRecord()
                    elseif ss and ss.GetLifeRecord then
                        lifeRecord = ss:GetLifeRecord(PLAYER_1)
                    end
                end)
                
                if not ok or not lifeRecord or #lifeRecord == 0 then return end

                
                local graphW = 230
                local graphH = 45 -- matches top half height
                local maxPoints = #lifeRecord
                local verts = {}
                
                for i, life in ipairs(lifeRecord) do
                    local x = ((i-1) / (maxPoints-1)) * graphW
                    local y = (1 - life) * graphH
                    verts[#verts+1] = {{x, y, 0}, color("0.4,0.7,1,0.8")}
                end
                
                self:SetVertices(verts)
                self:SetDrawState{Mode = "DrawMode_LineStrip", First = 1, Num = #verts}
            end
        },
        -- Life markers (0%, 50%, 100%)
        Def.ActorFrame {
            InitCommand = function(self) self:xy(-115, -25) end,
            Def.Quad { InitCommand = function(self) self:zoomto(230, 0.5):y(22.5):diffuse(color("1,1,1,0.1")) end }, -- 50%
            Def.Quad { InitCommand = function(self) self:zoomto(230, 0.5):y(45):diffuse(color("1,1,1,0.2")) end },   -- 0%
        },


        -- 2. Combo Timeline (Bottom half - Simplified from HV)
        Def.ActorFrame {
            Name = "ComboTimeline",
            InitCommand = function(self) self:y(10) end,
            
            -- Divider
            Def.Quad {
                InitCommand = function(self)
                    self:zoomto(230, 1):y(-5):diffuse(color("1,1,1,0.1"))
                end
            },

            -- Combo bars
            (function()
                local af = Def.ActorFrame {}
                local nrv, dvt, ntt
                pcall(function()
                    local p = getPSS()
                    local s = getScore()
                    local rp = (s and s:GetReplay()) or p
                    if rp and rp.LoadAllData then rp:LoadAllData() end
                    nrv = rp and rp.GetNoteRowVector and rp:GetNoteRowVector()
                    dvt = rp and rp.GetOffsetVector and rp:GetOffsetVector()
                    ntt = rp and rp.GetTapNoteTypeVector and rp:GetTapNoteTypeVector()
                end)

                
                if not dvt or #dvt == 0 then return af end
                
                local graphW = 230
                local graphH = 40
                local lastRow = nrv[#nrv] or 1
                if lastRow == 0 then lastRow = 1 end
                
                -- We'll draw 4 "lanes" for W1, W2, W3, and CBs
                local windows = { 22.5, 45, 90, 135 }
                local colors = {
                    color("1,1,1,0.5"),     -- W1
                    color("1,0.8,0,0.5"),   -- W2
                    color("0,1,0,0.5"),     -- W3
                    color("1,0,0.3,0.5")    -- CBs
                }
                
                for i = 1, #windows do
                    local laneY = (i-1) * 10
                    af[#af+1] = Def.ActorMultiVertex {
                        InitCommand = function(self)
                            self:y(laneY):SetVertices({})
                            self:SetDrawState{Mode = "DrawMode_Quads", First = 1, Num = 0}
                        end,
                        BeginCommand = function(self)
                            local verts = {}
                            local currentStreakStart = nil
                            local tso = ms.JudgeScalers[GetTimingDifficulty()] or 1
                            local threshold = windows[i] * tso
                            
                            for j = 1, #dvt do
                                local off = math.abs(dvt[j])
                                local row = nrv[j] or 0
                                local isMatch = (off <= threshold)
                                if i == 4 then isMatch = (off > 90 * tso) end -- CBs
                                
                                if isMatch then
                                    if not currentStreakStart then currentStreakStart = row end
                                else
                                    if currentStreakStart then
                                        local x1 = (currentStreakStart / lastRow) * graphW - graphW/2
                                        local x2 = (row / lastRow) * graphW - graphW/2
                                        local bw = math.max(1, x2 - x1)
                                        local c = colors[i]
                                        verts[#verts+1] = {{x1, 0, 0}, c}
                                        verts[#verts+1] = {{x1+bw, 0, 0}, c}
                                        verts[#verts+1] = {{x1+bw, 8, 0}, c}
                                        verts[#verts+1] = {{x1, 8, 0}, c}
                                        currentStreakStart = nil
                                    end
                                end
                            end
                            self:SetVertices(verts)
                            self:SetDrawState{Mode = "DrawMode_Quads", First = 1, Num = #verts}
                        end
                    }
                end
                return af
            end)()
        },

        -- Max combo label
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:zoom(0.25):halign(1):x(115):y(58)
                self:diffuse(color("0.65,0.65,0.65,1"))
            end,
            BeginCommand = function(self)
                local p = getPSS()
                local s = getScore()
                local curMax = (s and s.GetMaxCombo and s:GetMaxCombo()) or (p and p.GetMaxCombo and p:GetMaxCombo()) or 0
                self:settextf("Max Combo: %d", curMax)
            end
        },
    }
}

return t
