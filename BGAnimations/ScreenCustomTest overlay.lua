local t = Def.ActorFrame {
    OnCommand = function(self)
        self:Center()
        GAMESTATE:JoinPlayer(PLAYER_1)
        GAMESTATE:JoinPlayer(PLAYER_2)
        self:SetUpdateFunction(function(self, dt) self:playcommand("Update", {dt = dt}) end)
    end
}

local PLAYER_1 = "PlayerNumber_P1"
local PLAYER_2 = "PlayerNumber_P2"
-- Fallbacks for different engine versions
local P1_ALT = "P1"
local P2_ALT = "P2"

-- Tetris Settings and Constants
local COLS = 10
local ROWS = 20
local BLOCK_SIZE = 15
local PAD = 1
local FONT = "Common Normal"

local SHAPES = {
    I = {
        { {0,0,0,0}, {1,1,1,1}, {0,0,0,0}, {0,0,0,0} },
        { {0,0,1,0}, {0,0,1,0}, {0,0,1,0}, {0,0,1,0} },
        { {0,0,0,0}, {0,0,0,0}, {1,1,1,1}, {0,0,0,0} },
        { {0,1,0,0}, {0,1,0,0}, {0,1,0,0}, {0,1,0,0} }
    },
    J = {
        { {1,0,0}, {1,1,1}, {0,0,0} },
        { {0,1,1}, {0,1,0}, {0,1,0} },
        { {0,0,0}, {1,1,1}, {0,0,1} },
        { {0,1,0}, {0,1,0}, {1,1,0} }
    },
    L = {
        { {0,0,1}, {1,1,1}, {0,0,0} },
        { {0,1,0}, {0,1,0}, {0,1,1} },
        { {0,0,0}, {1,1,1}, {1,0,0} },
        { {1,1,0}, {0,1,0}, {0,1,0} }
    },
    O = {
        { {1,1}, {1,1} },
        { {1,1}, {1,1} },
        { {1,1}, {1,1} },
        { {1,1}, {1,1} }
    },
    S = {
        { {0,1,1}, {1,1,0}, {0,0,0} },
        { {0,1,0}, {0,1,1}, {0,0,1} },
        { {0,0,0}, {0,1,1}, {1,1,0} },
        { {1,0,0}, {1,1,0}, {0,1,0} }
    },
    T = {
        { {0,1,0}, {1,1,1}, {0,0,0} },
        { {0,1,0}, {0,1,1}, {0,1,0} },
        { {0,0,0}, {1,1,1}, {0,1,0} },
        { {0,1,0}, {1,1,0}, {0,1,0} }
    },
    Z = {
        { {1,1,0}, {0,1,1}, {0,0,0} },
        { {0,0,1}, {0,1,1}, {0,1,0} },
        { {0,0,0}, {1,1,0}, {0,1,1} },
        { {0,1,0}, {1,1,0}, {1,0,0} }
    }
}

local PIECE_COLORS = {
    I = color("#00f0f0"), -- Cyan
    J = color("#0000f0"), -- Blue
    L = color("#f0a000"), -- Orange
    O = color("#f0f000"), -- Yellow
    S = color("#00f000"), -- Green
    T = color("#a000f0"), -- Purple
    Z = color("#f00000")  -- Red
}

-- SRS Wall Kick Data
local KICKS = {
    NORMAL = {
        ["01"] = {{0,0}, {-1,0}, {-1,1}, {0,-2}, {-1,-2}},
        ["10"] = {{0,0}, {1,0}, {1,-1}, {0,2}, {1,2}},
        ["12"] = {{0,0}, {1,0}, {1,-1}, {0,2}, {1,2}},
        ["21"] = {{0,0}, {-1,0}, {-1,1}, {0,-2}, {-1,-2}},
        ["23"] = {{0,0}, {1,0}, {1,1}, {0,-2}, {1,-2}},
        ["32"] = {{0,0}, {-1,0}, {-1,-1}, {0,2}, {-1,2}},
        ["30"] = {{0,0}, {-1,0}, {-1,-1}, {0,2}, {-1,2}},
        ["03"] = {{0,0}, {1,0}, {1,1}, {0,-2}, {1,-2}}
    },
    I = {
        ["01"] = {{0,0}, {-2,0}, {1,0}, {-2,-1}, {1,2}},
        ["10"] = {{0,0}, {2,0}, {-1,0}, {2,1}, {-1,-2}},
        ["12"] = {{0,0}, {-1,0}, {2,0}, {-1,2}, {2,-1}},
        ["21"] = {{0,0}, {1,0}, {-2,0}, {1,-2}, {-2,1}},
        ["23"] = {{0,0}, {2,0}, {-1,0}, {2,1}, {-1,-2}},
        ["32"] = {{0,0}, {-2,0}, {1,0}, {-2,-1}, {1,2}},
        ["30"] = {{0,0}, {1,0}, {-2,0}, {1,-2}, {-2,1}},
        ["03"] = {{0,0}, {-1,0}, {2,0}, {-1,2}, {2,-1}}
    }
}

-- Game State
local G = {
    grid = {},
    current = nil,
    nextBag = {},
    hold = nil,
    canHold = true,
    gameOver = false,
    score = 0,
    lines = 0,
    level = 1,
    fallSpeed = 1.0,
    fallTimer = 0,
    lockTimer = 0,
    lockDelay = 0.5,
    moveResets = 0,
    maxMoveResets = 15,
    ghostY = 0,
    keysDown = {},
    lastHorizDir = nil,
    dasValues = { Left = 0, Right = 0, Up = 0 },
    dasLimit = 4, -- 4 frames at 60Hz
    arrLimit = 1, -- 1 frame at 60Hz
    tickAccumulator = 0
}

-- Initialize Grid
for r = 1, ROWS do
    G.grid[r] = {}
    for c = 1, COLS do
        G.grid[r][c] = 0
    end
end

local function refillBag()
    local pieces = {"I", "J", "L", "O", "S", "T", "Z"}
    for i = #pieces, 2, -1 do
        local j = math.random(i)
        pieces[i], pieces[j] = pieces[j], pieces[i]
    end
    for _, p in ipairs(pieces) do
        table.insert(G.nextBag, p)
    end
end

local function spawnPiece(type)
    local p = {
        type = type or table.remove(G.nextBag, 1),
        r = 0,
        c = 3,
        rot = 1 
    }
    if #G.nextBag == 0 then refillBag() end
    
    p.rot = 1
    if p.type == "I" then p.r = -1 p.c = 3 
    elseif p.type == "O" then p.c = 4 end

    return p
end

local function isValid(p, dr, dc, drot)
    local type = p.type
    local rot = drot or p.rot
    local r_pos = p.r + (dr or 0)
    local c_pos = p.c + (dc or 0)
    local shape = SHAPES[type][rot]
    
    for r = 1, #shape do
        for c = 1, #shape[r] do
            if shape[r][c] == 1 then
                local nr = r_pos + r
                local nc = c_pos + c
                if nc < 1 or nc > COLS or nr > ROWS then return false end
                if nr >= 1 and G.grid[nr][nc] ~= 0 then return false end
            end
        end
    end
    return true
end

local function updateGhost()
    if not G.current then return end
    local dr = 0
    while isValid(G.current, dr + 1, 0) do
        dr = dr + 1
    end
    G.ghostY = G.current.r + dr
end

local function lockPiece()
    local p = G.current
    local shape = SHAPES[p.type][p.rot]
    for r = 1, #shape do
        for c = 1, #shape[r] do
            if shape[r][c] == 1 then
                local nr = p.r + r
                local nc = p.c + c
                if nr >= 1 then
                    G.grid[nr][nc] = p.type
                else
                    G.gameOver = true
                end
            end
        end
    end
    
    local cleared = 0
    for r = ROWS, 1, -1 do
        local full = true
        for c = 1, COLS do
            if G.grid[r][c] == 0 then full = false break end
        end
        if full then
            table.remove(G.grid, r)
            local newRow = {}
            for c = 1, COLS do newRow[c] = 0 end
            table.insert(G.grid, 1, newRow)
            cleared = cleared + 1
            r = r + 1 
        end
    end
    
    if cleared > 0 then
        G.lines = G.lines + cleared
        G.score = G.score + (cleared == 1 and 100 or cleared == 2 and 300 or cleared == 3 and 500 or 800) * G.level
        G.level = math.floor(G.lines / 10) + 1
        G.fallSpeed = math.max(0.1, 1.0 - (G.level - 1) * 0.1)
    end
    
    G.canHold = true
    G.fallTimer = 0
    G.lockTimer = 0
    G.moveResets = 0
    
    G.current = spawnPiece()
    updateGhost()
    
    if not isValid(G.current) then
        G.gameOver = true
    end
    MESSAGEMAN:Broadcast("Update")
end

local function resetGame()
    G.grid = {}
    for r = 1, ROWS do
        G.grid[r] = {}
        for c = 1, COLS do G.grid[r][c] = 0 end
    end
    G.score = 0
    G.lines = 0
    G.level = 1
    G.fallSpeed = 1.0
    G.fallTimer = 0
    G.lockTimer = 0
    G.gameOver = false
    G.hold = nil
    G.canHold = true
    G.nextBag = {}
    refillBag()
    G.current = spawnPiece()
    updateGhost()
    MESSAGEMAN:Broadcast("Update")
end

local function rotate(dir)
    if G.gameOver or not G.current then return end
    local p = G.current
    local oldRot = p.rot
    local newRot = (oldRot + dir - 1) % 4 + 1
    
    local key = (oldRot-1) .. (newRot-1)
    local kickTable = (p.type == "I") and KICKS.I or KICKS.NORMAL
    local tests = kickTable[key] or {{0,0}}
    
    for _, test in ipairs(tests) do
        if isValid(p, -test[2], test[1], newRot) then
            p.r = p.r - test[2]
            p.c = p.c + test[1]
            p.rot = newRot
            if G.lockTimer > 0 and G.moveResets < G.maxMoveResets then
                G.lockTimer = 0
                G.moveResets = G.moveResets + 1
            end
            updateGhost()
            return
        end
    end
end

local function move(dc)
    if G.gameOver or not G.current then return end
    if isValid(G.current, 0, dc) then
        G.current.c = G.current.c + dc
        if G.lockTimer > 0 and G.moveResets < G.maxMoveResets then
            G.lockTimer = 0
            G.moveResets = G.moveResets + 1
        end
        updateGhost()
    end
end

local function softDrop()
    if G.gameOver or not G.current then return end
    if isValid(G.current, 1, 0) then
        G.current.r = G.current.r + 1
        G.fallTimer = 0
        G.score = G.score + 1
    end
end

local function hardDrop()
    if G.gameOver or not G.current then return end
    local dropped = 0
    while isValid(G.current, 1, 0) do
        G.current.r = G.current.r + 1
        dropped = dropped + 1
    end
    G.score = G.score + dropped * 2
    lockPiece()
    MESSAGEMAN:Broadcast("Update")
end

local function hold()
    if G.gameOver or not G.canHold or not G.current then return end
    local typeToHold = G.current.type
    if G.hold then
        local oldHold = G.hold
        G.current = spawnPiece(oldHold)
    else
        G.current = spawnPiece()
    end
    G.hold = typeToHold
    G.canHold = false
    updateGhost()
    MESSAGEMAN:Broadcast("Update")
end

refillBag()
G.current = spawnPiece()
updateGhost()

local gridFrame = Def.ActorFrame {
    Name = "Grid",
    Def.Quad { 
        InitCommand = function(self)
            self:setsize(COLS * BLOCK_SIZE, ROWS * BLOCK_SIZE)
                :diffuse(color("#111111"))
                :addx(-BLOCK_SIZE/2):addy(-BLOCK_SIZE/2)
        end
    }
}

for r = 1, ROWS do
    for c = 1, COLS do
        gridFrame[#gridFrame+1] = Def.Quad {
            Name = "Cell_"..r.."_"..c,
            InitCommand = function(self)
                self:setsize(BLOCK_SIZE - PAD, BLOCK_SIZE - PAD)
                    :xy((c - COLS/2 - 0.5) * BLOCK_SIZE, (r - ROWS/2 - 0.5) * BLOCK_SIZE)
                    :diffuse(color("#222222"))
            end,
            UpdateMessageCommand = function(self)
                local val = G.grid[r][c]
                if val ~= 0 then
                    self:diffuse(PIECE_COLORS[val]):diffusealpha(1)
                else
                    self:diffuse(color("#222222")):diffusealpha(1)
                end
            end
        }
    end
end

local activeFrame = Def.ActorFrame {
    Name = "Active"
}

-- Piece Quads (4 for ghost, 4 for active)
for i = 1, 4 do
    activeFrame[#activeFrame+1] = Def.Quad {
        Name = "GhostBlock_"..i,
        InitCommand = function(self) self:setsize(BLOCK_SIZE - PAD, BLOCK_SIZE - PAD):diffusealpha(0) end,
        UpdateMessageCommand = function(self)
            if G.gameOver or not G.current then self:diffusealpha(0) return end
            local p = G.current
            local shape = SHAPES[p.type][p.rot]
            local count = 0
            for r = 1, #shape do
                for c = 1, #shape[r] do
                    if shape[r][c] == 1 then
                        count = count + 1
                        if count == i then
                            local gr = G.ghostY + r
                            local gc = p.c + c
                            if gr >= 1 then
                                self:xy((gc - COLS/2 - 0.5) * BLOCK_SIZE, (gr - ROWS/2 - 0.5) * BLOCK_SIZE)
                                    :diffuse(PIECE_COLORS[p.type]):diffusealpha(0.3)
                            else self:diffusealpha(0) end
                            return
                        end
                    end
                end
            end
            self:diffusealpha(0)
        end
    }
end
for i = 1, 4 do
    activeFrame[#activeFrame+1] = Def.Quad {
        Name = "ActiveBlock_"..i,
        InitCommand = function(self) self:setsize(BLOCK_SIZE - PAD, BLOCK_SIZE - PAD):diffusealpha(0) end,
        UpdateMessageCommand = function(self)
            if G.gameOver or not G.current then self:diffusealpha(0) return end
            local p = G.current
            local shape = SHAPES[p.type][p.rot]
            local count = 0
            for r = 1, #shape do
                for c = 1, #shape[r] do
                    if shape[r][c] == 1 then
                        count = count + 1
                        if count == i then
                            local nr = p.r + r
                            local nc = p.c + c
                            if nr >= 1 then
                                self:xy((nc - COLS/2 - 0.5) * BLOCK_SIZE, (nr - ROWS/2 - 0.5) * BLOCK_SIZE)
                                    :diffuse(PIECE_COLORS[p.type]):diffusealpha(1)
                            else self:diffusealpha(0) end
                            return
                        end
                    end
                end
            end
            self:diffusealpha(0)
        end
    }
end

t[#t+1] = gridFrame
t[#t+1] = activeFrame

t[#t+1] = Def.BitmapText {
    Font = "Common Normal",
    Text = "SCORE: 0",
    InitCommand = function(self) self:xy(200, -200):halign(0):zoom(0.6) end,
    UpdateMessageCommand = function(self) self:settext("SCORE: "..G.score) end
}
t[#t+1] = Def.BitmapText {
    Font = "Common Normal",
    Text = "LINES: 0",
    InitCommand = function(self) self:xy(200, -170):halign(0):zoom(0.6) end,
    UpdateMessageCommand = function(self) self:settext("LINES: "..G.lines) end
}
t[#t+1] = Def.BitmapText {
    Font = "Common Normal",
    Text = "HOLD",
    InitCommand = function(self) self:xy(-250, -200):zoom(0.8) end
}

local holdFrame = Def.ActorFrame { Name = "HoldPiece", InitCommand = function(self) self:xy(-250, -150) end }
for i = 1, 4 do
    holdFrame[#holdFrame+1] = Def.Quad {
        Name = "HoldBlock_"..i,
        InitCommand = function(self) self:setsize(BLOCK_SIZE*0.7 - PAD, BLOCK_SIZE*0.7 - PAD):diffusealpha(0) end,
        UpdateMessageCommand = function(self)
            if not G.hold then self:diffusealpha(0) return end
            local shape = SHAPES[G.hold][1]
            local count = 0
            for r = 1, #shape do
                for c = 1, #shape[r] do
                    if shape[r][c] == 1 then
                        count = count + 1
                        if count == i then
                            self:xy((c - #shape[1]/2 - 0.5) * BLOCK_SIZE*0.7, (r - #shape/2 - 0.5) * BLOCK_SIZE*0.7)
                                :diffuse(PIECE_COLORS[G.hold]):diffusealpha(1)
                            return
                        end
                    end
                end
            end
            self:diffusealpha(0)
        end
    }
end
t[#t+1] = holdFrame

t[#t+1] = Def.BitmapText {
    Font = "Common Normal",
    Text = "NEXT",
    InitCommand = function(self) self:xy(250, -100):zoom(0.8) end
}

local nextFrame = Def.ActorFrame { Name = "NextPiece", InitCommand = function(self) self:xy(250, -50) end }
for i = 1, 4 do
    nextFrame[#nextFrame+1] = Def.Quad {
        Name = "NextBlock_"..i,
        InitCommand = function(self) self:setsize(BLOCK_SIZE*0.7 - PAD, BLOCK_SIZE*0.7 - PAD):diffusealpha(0) end,
        UpdateMessageCommand = function(self)
            local nt = G.nextBag[1]
            if not nt then self:diffusealpha(0) return end
            local shape = SHAPES[nt][1]
            local count = 0
            for r = 1, #shape do
                for c = 1, #shape[r] do
                    if shape[r][c] == 1 then
                        count = count + 1
                        if count == i then
                            self:xy((c - #shape[1]/2 - 0.5) * BLOCK_SIZE*0.7, (r - #shape/2 - 0.5) * BLOCK_SIZE*0.7)
                                :diffuse(PIECE_COLORS[nt]):diffusealpha(1)
                            return
                        end
                    end
                end
            end
            self:diffusealpha(0)
        end
    }
end
t[#t+1] = nextFrame

t[#t+1] = Def.BitmapText {
    Font = "Common Normal",
    Text = "GAME OVER\nPress START to Restart",
    InitCommand = function(self) self:xy(0,0):zoom(1):diffuse(Color.Red):shadowlength(2):visible(false) end,
    UpdateMessageCommand = function(self)
        self:visible(G.gameOver)
        if G.gameOver then self:stoptweening():diffusealpha(0):linear(0.5):diffusealpha(1) end
    end
}

t[#t+1] = Def.Actor {
    OnCommand = function(self)
        SCREENMAN:GetTopScreen():AddInputCallback(function(event)
            local button = event.button
            local pn = event.PlayerNumber or event.pn or "nil"
            local type = event.type
            
            -- Handle Back/Start for navigation independently of game state
            if type == "InputEventType_FirstPress" then
                if button == "Back" then
                    SCREENMAN:GetTopScreen():playcommand("Off")
                    SCREENMAN:GetTopScreen():PostScreenMessage("SM_GoToNextScreen", 0)
                    return
                elseif button == "Start" then
                    if G.gameOver then
                        resetGame()
                        return
                    else
                        SCREENMAN:GetTopScreen():playcommand("Off")
                        SCREENMAN:GetTopScreen():PostScreenMessage("SM_GoToNextScreen", 0)
                        return
                    end
                end
            end

            if G.gameOver then return end

            -- Player 1 Handlers
            if pn == PLAYER_1 or pn == P1_ALT then
                if type == "InputEventType_FirstPress" then
                    G.keysDown[button] = true
                    if button == "Left" then
                        move(-1)
                        G.dasValues.Left = 0
                        G.lastHorizDir = "Left"
                    elseif button == "Right" then
                        move(1)
                        G.dasValues.Right = 0
                        G.lastHorizDir = "Right"
                    elseif button == "Up" then
                        softDrop()
                        G.dasValues.Up = 0
                    elseif button == "Down" then
                        hardDrop()
                    elseif button == "Select" then
                        hold()
                    elseif button == "EffectUp" then
                        rotate(1)
                    elseif button == "EffectDown" then
                        rotate(-1)
                    end
                elseif type == "InputEventType_Release" then
                    G.keysDown[button] = false
                    if G.dasValues[button] then G.dasValues[button] = 0 end
                end
            end

            MESSAGEMAN:Broadcast("Update")
        end)
    end
}

t.UpdateCommand = function(self, params)
    if G.gameOver or not G.current then return end
    local dt = params.dt or 0
    
    -- Fixed 60Hz Logic Tick for DAS/ARR
    G.tickAccumulator = G.tickAccumulator + dt
    while G.tickAccumulator >= 1/60 do
        for _, dir in ipairs({"Left", "Right", "Up"}) do
            if G.keysDown[dir] and (dir == "Up" or dir == G.lastHorizDir) then
                G.dasValues[dir] = G.dasValues[dir] + 1
                if G.dasValues[dir] >= G.dasLimit then
                    if G.dasValues[dir] >= G.dasLimit + G.arrLimit then
                        if dir == "Up" then softDrop()
                        else move(dir == "Left" and -1 or 1) end
                        G.dasValues[dir] = G.dasLimit
                    end
                end
            end
        end
        G.tickAccumulator = G.tickAccumulator - 1/60
    end

    -- Locking Logic (run every frame if grounded)
    if not isValid(G.current, 1, 0) then
        G.lockTimer = G.lockTimer + dt
        if G.lockTimer >= G.lockDelay then
            lockPiece()
        end
    else
        G.lockTimer = 0
    end

    -- Gravity Logic
    G.fallTimer = G.fallTimer + dt
    if G.fallTimer >= G.fallSpeed then
        if isValid(G.current, 1, 0) then
            G.current.r = G.current.r + 1
            G.fallTimer = 0
            updateGhost()
            MESSAGEMAN:Broadcast("Update")
        end
    end
end

return t


