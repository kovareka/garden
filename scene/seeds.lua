local M = {}

M = {
    seeds = {
        {
            name = "Parsnip",
            priceForBuy = 20,
            priceForSell = 35,
            duration = 4
        },
        {
            name = "Radish",
            priceForBuy = 40,
            priceForSell = 90,
            duration = 6
        },
        {
            name = "Melon",
            priceForBuy = 80,
            priceForSell = 250,
            duration = 12
        }
    }
}

local function lootBox()
    local r = {}
    
    for i=1,#M.seeds do
        if M.seeds[i].name == "Parsnip" then
            table.insert( r, M.seeds[i] )
            table.insert( r, M.seeds[i] )
            table.insert( r, M.seeds[i] )
            table.insert( r, M.seeds[i] )
        elseif M.seeds[i].name == "Radish" then
            table.insert( r, M.seeds[i] )
            table.insert( r, M.seeds[i] )
        else
            table.insert( r, M.seeds[i] )
            table.insert( r, M.seeds[i] )
        end
    end
    
    return r
end

function M.getNewSeeds()
    local result = {}
    local t = lootBox()
    while #result ~= 5 do
        table.insert( result, t[math.random( 1, #t )] )
    end
    
    return result
end

return M