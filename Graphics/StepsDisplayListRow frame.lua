local t = Def.ActorFrame {}
-- Square card background for each StepsDisplayListRow item.
-- Using a square ensures the background looks identical regardless of
-- the rotation angle, hiding any rotation artifacts at card edges.

t[#t + 1] = Def.Quad {
    InitCommand = function(self)
        self:zoomto(56, 56):diffuse(color("#ffffff")):diffusealpha(0.12)
    end
}

return t
