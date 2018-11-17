local seeds = require "scene.seeds"

local M = {}
M = {
    shop = {}
}

local function newShop()
    M.shop = {}
    M.shop = seeds.getNewSeeds()
end

function M.refreshShop()
    newShop()
    return M.shop
end

return M