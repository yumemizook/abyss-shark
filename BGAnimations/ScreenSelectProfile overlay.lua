-- Controls the topmost layer of ScreenSelectProfile
-- Enhanced with recent scores display

local translated_info = {
    Title = "Select Profile",
    SongPlayed = "Song Played",
    SongsPlayed = "Songs Played",
    NoProfile = "No Profile",
    PressStart = "Press Start",
    RecentScores = "Recent Scores"
}

local function GetLocalProfiles()
    local t = {}

    for p = 0, PROFILEMAN:GetNumLocalProfiles() - 1 do
        local profileID = PROFILEMAN:GetLocalProfileIDFromIndex(p)
        local profile = PROFILEMAN:GetLocalProfileFromIndex(p)
        local ProfileCard =
            Def.ActorFrame {
                Name = p,
            LoadFont("Common Large") ..
                {
                    Text = string.format("%s: %.2f", profile:GetDisplayName(), profile:GetPlayerRating()),
                    InitCommand = function(self)
                        self:y(-10):zoom(0.4):ztest(true, maxwidth, (200 - 34 - 4) / 0.4)
                    end
                },
            LoadFont("Common Normal") ..
                {
                    InitCommand = function(self)
                        self:y(8):zoom(0.5):vertspacing(-8):ztest(true):maxwidth((200 - 34 - 4) / 0.5)
                    end,
                    BeginCommand = function(self)
                        local numSongsPlayed = profile:GetNumTotalSongsPlayed()
                        local s = numSongsPlayed == 1 and translated_info["SongPlayed"] or translated_info["SongsPlayed"]
                        self:settext(numSongsPlayed .. " " .. s)
                    end
                }
        }
        t[#t + 1] = ProfileCard
    end

    return t
end

local function LoadPlayerStuff(Player)
    local t = {}
    t[#t + 1] =
        Def.ActorFrame {
        Name = "SmallFrame",
        InitCommand = function(self)
            self:y(-2)
        end,
        Def.Quad {
            InitCommand = function(self)
                self:zoomto(200, 40 + 2)
            end,
            OnCommand = function(self)
                self:diffusealpha(0.3)
            end
        }
    }

    t[#t + 1] =
        Def.ActorScroller {
        Name = "Scroller",
        NumItemsToDraw = 6,
        OnCommand = function(self)
            self:y(1):SetFastCatchup(true):SetMask(200, 58):SetSecondsPerItem(0.15)
        end,
        TransformFunction = function(self, offset, itemIndex, numItems)
            local focus = scale(math.abs(offset), 0, 2, 1, 0)
            self:visible(false)
            self:y(math.floor(offset * 40))
        end,
        children = GetLocalProfiles()
    }

    return t
end

local function UpdateInternal3(self, Player)
    local pn = (Player == PLAYER_1) and 1
    local frame = self:GetChild(string.format("P%uFrame", pn))
    local scroller = frame:GetChild("Scroller")
    local smallframe = frame:GetChild("SmallFrame")

    if GAMESTATE:IsHumanPlayer() then
        frame:visible(true)
            smallframe:visible(true)
            scroller:visible(true)
            local ind = SCREENMAN:GetTopScreen():GetProfileIndex(Player)
            if ind > 0 then
                scroller:SetDestinationItem(ind - 1)
            else
                if SCREENMAN:GetTopScreen():SetProfileIndex(Player, 1) then
                    scroller:SetDestinationItem(0)
                    self:queuecommand("UpdateInternal2")
                else
                    smallframe:visible(false)
                    scroller:visible(false)
                end
            end
    else
        scroller:visible(false)
        smallframe:visible(false)
    end
end

local theThingVeryImportant
local startSound

local function input(event)
    if event.type == "InputEventType_FirstPress" then
        if event.button == "Back" then
            SCREENMAN:GetTopScreen():Cancel()
        elseif event.button == "Start" then
            startSound:queuecommand("StartButton")
        elseif event.button == "Down" or event.button == "MenuDown" then
            local ind = SCREENMAN:GetTopScreen():GetProfileIndex(PLAYER_1)
            if ind > 0 then
                if SCREENMAN:GetTopScreen():SetProfileIndex(PLAYER_1, ind + 1) then
                    MESSAGEMAN:Broadcast("DirectionButton")
                    theThingVeryImportant:queuecommand("UpdateInternal2")
                end
            end
        elseif event.button == "Up" or event.button == "MenuUp" then
            local ind = SCREENMAN:GetTopScreen():GetProfileIndex(PLAYER_1)
            if ind > 1 then
                if SCREENMAN:GetTopScreen():SetProfileIndex(PLAYER_1, ind - 1) then
                    MESSAGEMAN:Broadcast("DirectionButton")
                    theThingVeryImportant:queuecommand("UpdateInternal2")
                end
            end
        end
    end
    return false
end

local t = Def.ActorFrame {}

t[#t + 1] =
    Def.ActorFrame {
    InitCommand = function(self)
        theThingVeryImportant = self
    end,
    OnCommand = function(self)
        SCREENMAN:GetTopScreen():SetProfileIndex(PLAYER_1, 0)
    end,
    OnCommand = function(self, params)
        self:queuecommand("UpdateInternal2")
    end,
    UpdateInternal2Command = function(self)
        UpdateInternal3(self, PLAYER_1)
        -- Refresh recent scores display
        local recentScores = self:GetChild("P1Frame"):GetChild("RecentScores")
        if recentScores then
            recentScores:playcommand("Refresh")
        end
    end,
    children = {
        Def.ActorFrame {
            Name = "P1Frame",
            InitCommand = function(self)
                self:x(SCREEN_CENTER_X):y(SCREEN_CENTER_Y)
            end,
            OnCommand = function(self)
                SCREENMAN:GetTopScreen():AddInputCallback(input)
                self:zoom(0):bounceend(0.2):zoom(1)
            end,
            OffCommand = function(self)
                self:bouncebegin(0.2):zoom(0)
            end,
            PlayerJoinedMessageCommand = function(self, param)
                if param.Player == PLAYER_1 then
                    self:zoom(1.15):bounceend(0.175):zoom(1.0)
                end
            end,
            children = LoadPlayerStuff(PLAYER_1)
        },
        -- sounds
        LoadActor(THEME:GetPathS("Common", "start")) ..
        {
            InitCommand = function(self)
                startSound = self
            end,
            StartButtonCommand = function(self)
                self:play()
                self:sleep(0.2)
                self:queuecommand("Done")
            end,
            DoneCommand = function(self)
                SCREENMAN:GetTopScreen():Finish()
            end
        },
        LoadActor(THEME:GetPathS("Common", "value")) ..
        {
            DirectionButtonMessageCommand = function(self)
                self:play()
            end
        },
        -- Recent scores display (right side)
        Def.ActorFrame {
            Name = "RecentScores",
            InitCommand = function(self)
                self:x(180):y(-20)
            end,
            OnCommand = function(self)
                self:playcommand("Refresh")
            end,
            RefreshCommand = function(self)
                local ind = SCREENMAN:GetTopScreen():GetProfileIndex(PLAYER_1)
                if ind > 0 then
                    local profile = PROFILEMAN:GetLocalProfileFromIndex(ind - 1)
                    if profile then
                        -- Get recent scores
                        local scores = profile:GetHighScores()
                        local numScores = math.min(3, #scores)
                        for i = 1, 3 do
                            local row = self:GetChild("ScoreRow" .. i)
                            if row then
                                if i <= numScores then
                                    local score = scores[i]
                                    local songName = score:GetSongName() or "Unknown"
                                    local wife = score:GetWifeScore() * 100
                                    local grade = score:GetWifeGrade()
                                    local gradeColor = color("1,1,1,1")
                                    if grade == "Tier01" then gradeColor = color("1,1,1,1")
                                    elseif grade == "Tier02" then gradeColor = color("0,0.9,1,1")
                                    elseif grade == "Tier03" then gradeColor = color("1,0.8,0,1")
                                    elseif grade == "Tier04" then gradeColor = color("0.3,0.8,0.3,1")
                                    elseif grade == "Tier05" then gradeColor = color("1,0.5,0.7,1")
                                    elseif grade == "Tier06" then gradeColor = color("0.4,0.6,1,1")
                                    elseif grade == "Tier07" then gradeColor = color("0.7,0.3,0.9,1")
                                    elseif grade == "Tier08" then gradeColor = color("0.5,0.5,0.5,1")
                                    end
                                    local nameActor = row:GetChild("SongName")
                                    local scoreActor = row:GetChild("Score")
                                    if nameActor then
                                        nameActor:settext(songName:sub(1, 20))
                                        nameActor:diffuse(color("1,1,1,1"))
                                    end
                                    if scoreActor then
                                        scoreActor:settextf("%.2f%%", wife)
                                        scoreActor:diffuse(gradeColor)
                                    end
                                    row:visible(true)
                                else
                                    row:visible(false)
                                end
                            end
                        end
                    end
                else
                    -- Hide all rows if no profile selected
                    for i = 1, 3 do
                        local row = self:GetChild("ScoreRow" .. i)
                        if row then row:visible(false) end
                    end
                end
            end,
            -- Background
            Def.Quad {
                InitCommand = function(self)
                    self:zoomto(160, 90):diffuse(color("0,0,0,0.6"))
                end
            },
            -- Header
            LoadFont("Common Normal") .. {
                InitCommand = function(self)
                    self:y(-35):zoom(0.3)
                    self:settext(translated_info["RecentScores"])
                    self:diffuse(color("0.8,0.8,1,1"))
                end
            },
            -- Score rows
            Def.ActorFrame {
                Name = "ScoreRow1",
                InitCommand = function(self)
                    self:y(-15):visible(false)
                end,
                LoadFont("Common Normal") .. {
                    Name = "SongName",
                    InitCommand = function(self)
                        self:x(-5):zoom(0.22):halign(0):maxwidth(130/0.22)
                    end
                },
                LoadFont("Common Normal") .. {
                    Name = "Score",
                    InitCommand = function(self)
                        self:x(75):zoom(0.22):halign(1)
                    end
                }
            },
            Def.ActorFrame {
                Name = "ScoreRow2",
                InitCommand = function(self)
                    self:y(5):visible(false)
                end,
                LoadFont("Common Normal") .. {
                    Name = "SongName",
                    InitCommand = function(self)
                        self:x(-5):zoom(0.22):halign(0):maxwidth(130/0.22)
                    end
                },
                LoadFont("Common Normal") .. {
                    Name = "Score",
                    InitCommand = function(self)
                        self:x(75):zoom(0.22):halign(1)
                    end
                }
            },
            Def.ActorFrame {
                Name = "ScoreRow3",
                InitCommand = function(self)
                    self:y(25):visible(false)
                end,
                LoadFont("Common Normal") .. {
                    Name = "SongName",
                    InitCommand = function(self)
                        self:x(-5):zoom(0.22):halign(0):maxwidth(130/0.22)
                    end
                },
                LoadFont("Common Normal") .. {
                    Name = "Score",
                    InitCommand = function(self)
                        self:x(75):zoom(0.22):halign(1)
                    end
                }
            }
        }
    }
}

return t
