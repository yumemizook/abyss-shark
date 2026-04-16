local t = Def.ActorFrame {}
-- Controls the song info relevant children of the ScreenSelectMusic decorations actorframe

local wheelX = 15
local arbitraryWheelXThing = 17
local space = 20
local meter = {}
meter[1] = 0
local steps
local song

local infoWidth = SCREEN_WIDTH - (wheelX + arbitraryWheelXThing + space + capWideScale(get43size(365),365)-50) - 10

local infoWidth = SCREEN_WIDTH - (wheelX + arbitraryWheelXThing + space + capWideScale(get43size(365),365)-50) - 10

-- functionally make skillset rating text in a 4x2 grid
local function makeSSes()
    local ss = Def.ActorFrame {}
    local function makeSS(i)
        local colWidth = infoWidth / 4
        local col = (i-1) % 4 * colWidth
        local row = math.floor((i-1) / 4)
        local rowHeight = 22
        
        return Def.ActorFrame {
            InitCommand = function(self)
                self:xy(col, row * rowHeight)
            end,
            LoadFont("Common Normal") .. {
                Name = "Name",
                InitCommand = function(self)
                    self:zoom(0.18):halign(0):settext(ms.SkillSetsTranslated[i])
                    self:diffuse(color("#888888"))
                end
            },
            LoadFont("Common Normal") .. {
                Name = "Value",
                InitCommand = function(self)
                    self:y(8):zoom(0.33):halign(0)
                end,
                SetStuffCommand = function(self)
                    if not steps or not meter[i] then
                        self:settext("--")
                    else
                        self:settextf("%.2f", meter[i])
                    end
                    if i == 1 then -- Overall in blue
                        self:diffuse(color("#4488FF"))
                    else
                        self:diffuse(color("1,1,1,1"))
                    end
                end
            }
        }
    end
    for i = 1, #ms.SkillSets do
        ss[#ss+1] = makeSS(i)
    end
    return ss
end

local songinfoLine = infoWidth -- use full width for alignment

t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
        self:x(wheelX + arbitraryWheelXThing + space + capWideScale(get43size(365),365)-50)
        self:y(10) -- move up slightly
    end,
    SetMeterCommand = function(self)
        if steps then
            meter = {}
            for i = 1, #ms.SkillSets do
                local m = steps:GetMSD(getCurRateValue(), i)
                meter[i] = m
            end
        end
    end,
    CurrentStepsChangedMessageCommand = function(self)
        steps = GAMESTATE:GetCurrentSteps()
        song = GAMESTATE:GetCurrentSong()
        self:playcommand("SetMeter")
        self:playcommand("SetStuff")
    end,
    CurrentSongChangedMessageCommand = function(self)
        self:playcommand("CurrentStepsChanged")
    end,
    CurrentRateChangedMessageCommand = function(self)
        self:playcommand("SetMeter")
        self:playcommand("SetStuff")
    end,

    Def.Sprite {
        Name = "Banner",
        InitCommand = function(self)
            self:halign(0):valign(0)
        end,
        SetStuffCommand = function(self)
            if song and song:GetBannerPath() then
                self:visible(true)
                self:LoadBanner(song:GetBannerPath())
            else
                self:visible(false)
            end
            self:zoomto(infoWidth, infoWidth * 0.25) -- slightly shorter
        end
    },
    Def.Sprite {
        Name = "CDTitle",
        InitCommand = function(self)
            self:xy(infoWidth, infoWidth * 0.25 + 5):halign(1):valign(0)
        end,
        SetStuffCommand = function(self)
            if song and song:HasCDTitle() then
                self:visible(true)
                self:Load(song:GetCDTitlePath())
            else
                self:visible(false)
            end
            self:zoomto(20, 20)
        end
    },
    LoadFont("Common Normal") .. {
        Name = "SongTitle",
        InitCommand = function(self)
            self:xy(0, infoWidth * 0.25 + 5):zoom(.4):halign(0):maxwidth(infoWidth/0.4 - 30)
        end,
        SetStuffCommand = function(self)
            if song then
                self:settext(song:GetDisplayMainTitle())
            else
                self:settext("")
            end
        end
    },
    LoadFont("Common Normal") .. {
        Name = "SongSubtitle",
        InitCommand = function(self)
            self:xy(0, infoWidth * 0.25 + 16):zoom(.28):halign(0):maxwidth(infoWidth/0.28)
        end,
        SetStuffCommand = function(self)
            if song then
                self:settext(song:GetDisplaySubTitle())
            else
                self:settext("")
            end
        end
    },
    LoadFont("Common Normal") .. {
        Name = "SongArtist",
        InitCommand = function(self)
            self:xy(0, infoWidth * 0.25 + 25):zoom(.28):halign(0):maxwidth(infoWidth/0.28)
        end,
        SetStuffCommand = function(self)
            if song then
                self:settext(song:GetDisplayArtist())
            else
                self:settext("")
            end
        end
    },
    LoadFont("Common Normal") .. {
        Name = "SongCredits",
        InitCommand = function(self)
            self:xy(0, infoWidth * 0.25 + 34):zoom(.22):halign(0):maxwidth(infoWidth/0.22)
            self:diffuse(color("#888888"))
        end,
        SetStuffCommand = function(self)
            if song then
                local credit = ""
                if song.GetCredit then credit = song:GetCredit()
                elseif song.GetOrTryAtLeastToGetStepAuthor then credit = song:GetOrTryAtLeastToGetStepAuthor()
                end
                self:settext(credit)
            else
                self:settext("")
            end
        end
    },

    makeSSes() .. {
        InitCommand = function(self)
            self:y(infoWidth * 0.25 + 45)
        end
    },

    Def.BPMDisplay {
        File = THEME:GetPathF("BPMDisplay", "bpm"),
        Name = "BPMDisplay",
        InitCommand = function(self)
            self:xy(infoWidth, infoWidth * 0.25 + 35):halign(1):zoom(0.28)
        end,
        SetStuffCommand = function(self)
            if song then
                self:visible(true)
                self:SetFromSteps(steps)
            else
                self:visible(false)
            end
        end
    },
    LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:xy(infoWidth - 35, infoWidth * 0.25 + 35):zoom(.28)
            self:settext("BPM:"):halign(1)
        end
    },

    LoadFont("Common Normal") .. {
        Name = "RateDisplay",
        InitCommand = function(self)
            self:xy(infoWidth, infoWidth * 0.25 + 43):zoom(0.28):halign(1)
        end,
        CurrentStepsChangedMessageCommand = function(self)
            self:settext(getCurRateDisplayString())
        end,
        CurrentRateChangedMessageCommand = function(self)
            self:settext(getCurRateDisplayString())
        end,
        CodeMessageCommand = function(self, params)
            if params.Name == "NextRate" then
                ChangeMusicRateAbyss(0.05)
            elseif params.Name == "PrevRate" then
                ChangeMusicRateAbyss(-0.05)
            end
        end
    }

}

return t
