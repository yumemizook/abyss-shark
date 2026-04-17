local quotes = {
    "Who is this Etterna girl anyway.", 
    "When in doubt, mash it out.",
    "Reticulating splines...", 
    "Have you tried hitting the notes?",
    "Mindblock is just a state of mind.",
    "Welcome to the abyss.",
    "Please wait..."
}

local function getThemeInfo()
    local info = {DisplayName = "The Fool", Version = "1.0.0"}
    local path = THEME:GetCurrentThemeDirectory() .. "ThemeInfo.ini"
    
    -- RageFile is the standard way to read files in Etterna
    local f = RageFileUtil.CreateRageFile()
    if f:Open(path, 1) then -- 1 is for reading
        local content = f:Read()
        f:Close()
        f:destroy()
        
        -- Simplified parser for ThemeInfo.ini
        for line in content:gmatch("[^\r\n]+") do
            local key, val = line:match("^([^=]+)=(.+)$")
            if key and val then
                -- Trim whitespace
                key = key:gsub("^%s*(.-)%s*$", "%1")
                val = val:gsub("^%s*(.-)%s*$", "%1")
                info[key] = val
            end
        end
    else
        f:destroy()
    end
    
    return info
end

local themeInfo = getThemeInfo()
local randomQuote = quotes[math.random(#quotes)]

return Def.ActorFrame {
    -- Random Quote (Center)
    Def.BitmapText {
        Font="Common Normal",
        Text=randomQuote,
        InitCommand=function(self)
            self:Center():diffuse(color("1,1,1,1")):zoom(1.2)
        end,
        OnCommand=function(self)
            self:sleep(2.0):linear(0.5):diffusealpha(0)
        end,
        SkipInitMessageCommand=function(self)
            self:finishtweening():diffusealpha(0)
        end
    },

    -- Theme Metadata (Bottom)
    Def.BitmapText {
        Font="Common Normal",
        Text=string.format("%s v%s", themeInfo.DisplayName, themeInfo.Version),
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, SCREEN_HEIGHT - 30):zoom(0.5):diffusealpha(0.7)
        end,
        OnCommand=function(self)
            self:sleep(2.0):linear(0.5):diffusealpha(0)
        end,
        SkipInitMessageCommand=function(self)
            self:finishtweening():diffusealpha(0)
        end
    }
}
