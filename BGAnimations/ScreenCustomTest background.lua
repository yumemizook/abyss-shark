local t = Def.ActorFrame {}

-- Reuse the theme's abyss background style
t[#t+1] = Def.Quad {
    InitCommand=function(self)
        self:FullScreen():diffuse(color("#050A15"))
        self:diffusebottomedge(color("#000000"))
    end
}

local numQuads = 20 -- Fewer quads for the test screen
local colors = {
    color("#0d47a1"),
    color("#1976d2"),
    color("#00bcd4"),
    color("#512da8"),
    color("#00796b")
}

for i=1, numQuads do
    local width = math.random(10, 80)
    local height = math.random(10, 80)
    local speed = math.random(15, 30)
    local c = colors[math.random(#colors)]

    t[#t+1] = Def.Quad {
        InitCommand=function(self)
            self:xy(math.random(0, SCREEN_WIDTH), SCREEN_HEIGHT + 100)
            self:zoomto(width, height)
            self:diffuse(c)
            self:diffusealpha(math.random(10, 30) / 100)
            self:spin():effectmagnitude(math.random(-40, 40), math.random(-40, 40), math.random(-40, 40))
            self:sleep(math.random(0, 100) / 10)
            self:playcommand("Drift")
        end,
        DriftCommand=function(self)
            self:y(SCREEN_HEIGHT + 100)
            self:x(math.random(0, SCREEN_WIDTH))
            self:linear(speed)
            self:y(-100)
            self:queuecommand("Drift")
        end
    }
end

return t
