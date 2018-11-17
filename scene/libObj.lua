local M = {}
M = {
    column = 5,
    row = 5,
    board = {},
    newCells = {},
    plantedCells = {}
}

local price = 50
local cells = 9

local function createBoard()
    for y=1,M.row do
        local r = {}
        for x=1,M.column do
            r[x] = {
                x = x,
                y = y,
                availiable = true,
                item = nil,
                ready = false,
                pour = false,
                price = price
            }
            if y == 1 or y == M.row or x == 1 or x == M.column then
                r[x].availiable = false
            end
        end
        M.board[y] = r
    end
end

function M.checkX( x, y )
    for k,v in pairs( M.board[y] ) do
        if x == k then
            return false
        end
    end
    return true
end

function M.checkY( x, y )
    for k,v in pairs( M.board ) do
        if y == k then
            return false
        end
    end
    return true
end

local function updateBoard( x, y )
    local topCorner = -1
    local bottomCorner = 7
    local leftCorner = -2
    local rightCorner = 8
    
    if cells == 50 then
        price = price + 25
    elseif cells == 26 then
        price = price + 25
    elseif cells == 10 then
        price = price + 25
    end
    
    if x-1 > leftCorner and M.board[y][x-1] == nil then
        M.board[y][x-1] = {
            x = x-1,
            y = y,
            availiable = false,
            item = nil,
            ready = false,
            pour = true,
            price = price
        }
        table.insert( M.newCells, { x=x-1, y=y } )
        cells = cells + 1
    end
    if x+1 < rightCorner and M.board[y][x+1] == nil then
        M.board[y][x+1] = {
            x = x+1,
            y = y,
            availiable = false,
            item = nil,
            ready = false,
            pour = true,
            price = price
        }
        table.insert( M.newCells, { x=x+1, y=y } )
        cells = cells + 1
    end
    if y-1 > topCorner and (M.board[y-1] == nil or M.board[y-1][x] == nil) then
        if M.board[y-1] == nil then
            M.board[y-1] = {}
        end
        M.board[y-1][x] = {
            x = x,
            y = y-1,
            availiable = false,
            item = nil,
            ready = false,
            pour = true,
            price = price
        }
        table.insert( M.newCells, { x=x, y=y-1 } )
        cells = cells + 1
    end
    if y+1 < bottomCorner and (M.board[y+1] == nil or M.board[y+1][x] == nil) then
        if M.board[y+1] == nil then
            M.board[y+1] = {}
        end
        M.board[y+1][x] = {
            x = x,
            y = y+1,
            availiable = false,
            item = nil,
            ready = false,
            pour = true,
            price = price
        }
        table.insert( M.newCells, { x=x, y=y+1 } )
        cells = cells + 1
    end
end

function M.newLevel()
    M.board = {}
    createBoard()
end

function M.addNewCell( x, y )
    M.board[y][x].availiable = true
    cells = cells + 1
    updateBoard( x, y )
end

function M.clearNewCells()
    M.newCells = {}
end

function M.checkNewCell( x, y )
    if M.board[y][x].availiable == false then
        return true
    end
end

function M.cultivateCell( x, y )
    M.board[y][x].ready = true
end

function M.plantSeed( x, y, seed, day )
    print( "Planted on X - " .. x .. " Y - " .. y .. " -- " ..seed.name)
    
    local tSeed = {
        seed = seed,
        x = x,
        y = y,
        dayPlanting = day,
        growingDays = 1,
        stage = 1,
        ready = false
    }
    
    table.insert( M.plantedCells, tSeed )
    M.board[y][x].pour = false
end

function M.pourCell( x, y )
    M.board[y][x].pour = true
end

function M.getSeed( x, y )
    for k,v in pairs(M.plantedCells) do
        if v.x == x and v.y == y then
            return v
        end
    end
end

local function refreshStage( seed )
    if seed.seed.name == "Parsnip" then
        if seed.growingDays == 1 then
            seed.stage = 1
        elseif seed.growingDays == 2 then
            seed.stage = 2
        elseif seed.growingDays == 3 then
            seed.stage = 3
        elseif seed.growingDays == 4 then
            seed.stage = 4
        end
    elseif seed.seed.name == "Radish" then
        if seed.growingDays == 1 then
            seed.stage = 1
        elseif seed.growingDays == 3 then
            seed.stage = 2
        elseif seed.growingDays == 4 then
            seed.stage = 3
        elseif seed.growingDays == 6 then
            seed.stage = 4
        end
    elseif seed.seed.name == "Melon" then
        if seed.growingDays == 1 then
            seed.stage = 1
        elseif seed.growingDays == 2 then
            seed.stage = 2
        elseif seed.growingDays == 4 then
            seed.stage = 3
        elseif seed.growingDays == 7 then
            seed.stage = 4
        elseif seed.growingDays == 10 then
            seed.stage = 5
        end
    end
end

function M.checkSeeds( day )
    local t = {}
    
    for i=1,#M.plantedCells do
        local s = M.plantedCells[i]
        if not s.ready and M.board[s.y][s.x].pour then
            s.growingDays = s.growingDays + 1
            refreshStage( s )
            if s.growingDays > s.seed.duration then
                M.plantedCells[i].ready = true
                if M.plantedCells[i].seed.name == "Melon" then
                    M.plantedCells[i].stage = 6
                else
                    M.plantedCells[i].stage = 5 
                end
            end
            table.insert( t, { x=s.x, y=s.y } )
        end
    end
    
    return t
end

function M.checkPourSeeds()
    local t = {}
    
    for i=1,#M.plantedCells do
        local s = M.plantedCells[i]
        if not s.ready then
            local r = math.random(10)
            if r == 4 or r == 8 then
                M.board[s.y][s.x].pour = false
                table.insert( t, { x=s.x, y=s.y } )
            end
        end
    end
    
    return t
end

function M.removeSeed( x, y )
    for i=1,#M.plantedCells do
        if M.plantedCells[i].x == x and M.plantedCells[i].y == y then
            table.remove( M.plantedCells, i )
            M.board[y][x].ready = false
            break
        end
    end
end

function M.getRentPrice()
    local c = 0
    local p = 25
    local r = 0
    
    for k,v in pairs(M.board) do
        for k1,v1 in pairs(v) do
            if v1.availiable then
                c = c + 1
                if c == 50 then
                    p = p + 12
                elseif c == 26 then
                    p = p + 12
                elseif c == 10 then
                    p = p + 12
                end
                r = r + p
            end
        end
    end
    
    return r
end

return M