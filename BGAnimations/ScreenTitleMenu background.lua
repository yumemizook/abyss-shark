local t = Def.ActorFrame {
    OnCommand=function(self)
        SCREENMAN:GetTopScreen():lockinput(0)
    end
}

-- Base deep dark charcoal background color
t[#t+1] = Def.Quad {
    InitCommand=function(self)
        self:FullScreen():diffuse(color("#0A0A0A")) -- Deep charcoal
        self:diffusebottomedge(color("#1A1221")) -- Transition to a very dark purple
    end
}

local numQuads = 40
-- Curated dark palette suitable for "The Fool" (Dark Mode)
local colors = {
    color("#D4AF37"), -- Muted Gold
    color("#FFFFFF"), -- White
    color("#5B1D76"), -- Deep Purple
    color("#8B0000"), -- Dark Red
    color("#1A237E"), -- Dark Indigo
    color("#424242")  -- Charcoal Grey
}

-- Generate flying dynamic quads
for i=1, numQuads do
    local width = math.random(15, 120)
    local height = math.random(15, 120)
    
    local speed = math.random(8, 25) -- Slow, drifting speeds
    local c = colors[math.random(#colors)]
    
    local rotX = math.random(-60, 60)
    local rotY = math.random(-60, 60)
    local rotZ = math.random(-90, 90)

    t[#t+1] = Def.Quad {
        InitCommand=function(self)
            -- Position slightly below the screen
            self:xy(math.random(0, SCREEN_WIDTH), SCREEN_HEIGHT + 200)
            self:zoomto(width, height)
            self:diffuse(c)
            self:diffusealpha(math.random(15, 50) / 100) -- Semi-transparent
            
            -- Spin in 3D space so they look like ever-changing geometric objects
            self:spin()
            self:effectmagnitude(rotX, rotY, rotZ)
            
            -- Staggered starts before beginning to drift up
            self:sleep(math.random(0, 150) / 10)
            self:playcommand("Drift")
        end,
        DriftCommand=function(self)
            self:y(SCREEN_HEIGHT + 200)
            self:x(math.random(0, SCREEN_WIDTH))
            self:linear(speed)
            self:y(-200) -- Fly past the top
            -- Loop the animation infinitely
            self:queuecommand("Drift")
        end
    }
end

-- Black quad to fade out on top (non-blocking, fixes input delay)
t[#t+1] = Def.Quad {
    InitCommand=function(self)
        self:FullScreen():diffuse(color("0,0,0,1"))
    end,
    OnCommand=function(self)
        self:linear(0.4):diffusealpha(0)
    end
}

return t
