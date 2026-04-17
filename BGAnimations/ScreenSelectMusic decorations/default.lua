local t = Def.ActorFrame {}
-- Controls the middle layer of ScreenSelectMusic
-- this file is loaded first, as default
-- load additional files below to make children in an organized way

t[#t+1] = LoadActor("profile")
t[#t+1] = LoadActor("songinfo")
t[#t+1] = LoadActor("search")

-- 5 is a random song button
-- ctrl+5 is random song in group
local function randomInputter(event)
    if event.type == "InputEventType_FirstPress" then
        if event.DeviceInput.button == "DeviceButton_5" then
            local ctrl = INPUTFILTER:IsControlPressed()
            local song = GAMESTATE:GetCurrentSong()
            local w = SCREENMAN:GetTopScreen():GetMusicWheel()
            local t = {}
            if ctrl and song and song:GetGroupName() then
                t = w:GetSongsInGroup(song:GetGroupName())
            else
                t = w:GetSongs()
            end
            if #t > 0 then
                w:SelectSong(t[math.random(#t)])
            end
        end
    end
end

t[#t+1] = Def.ActorFrame {
    OnCommand = function(self)
        SCREENMAN:GetTopScreen():AddInputCallback(randomInputter)
    end
}

local wheelX = 15
local arbitraryWheelXThing = 17
local space = 20
local stepsdisplayx = wheelX + arbitraryWheelXThing + space + capWideScale(get43size(365),365)-50

-- Difficulty selector: uses the built-in Def.StepsDisplayList
-- Metrics transform it to be horizontal (see [StepsDisplayListRow] in metrics.ini)
t[#t + 1] = Def.ActorFrame {
    Name = "StepsDisplay",
    InitCommand = function(self)
        self:xy(stepsdisplayx + 20, 20 + 60 + 80 + 135)
    end,
    OffCommand = function(self)
        self:visible(false)
    end,
    OnCommand = function(self)
        self:visible(true)
    end,
    CurrentSongChangedMessageCommand = function(self)
        local song = GAMESTATE:GetCurrentSong()
        if song then
            self:playcommand("On")
        else
            self:playcommand("Off")
        end
    end,
    Def.StepsDisplayList {
        Name = "StepsDisplayListRow",
        InitCommand = function(self)
            -- Rotate the whole list 90° so vertical item spacing becomes horizontal on screen
            self:rotationz(90)
        end,
        -- P1 cursor: a highlight bar
        CursorP1 = Def.ActorFrame {
            InitCommand = function(self)
                self:player(PLAYER_1)
            end,
            Def.Quad {
                InitCommand = function(self)
                    -- Square matches card background — looks correct at any rotation
                    self:zoomto(56, 56):valign(0.5):halign(0.5)
                    self:diffuse(color("1,1,1,0.25"))
                end
            }
        },
        CursorP2 = Def.ActorFrame {},
        CursorP1Frame = Def.Actor {
            ChangeCommand = function(self)
                self:stoptweening():decelerate(0.1)
            end
        },
        CursorP2Frame = Def.Actor {}
    }
}

return t
