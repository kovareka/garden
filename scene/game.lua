
local composer = require( "composer" )
local obj = require "scene.libObj"
local shop = require "scene.shop"
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local background

local day = 1
local hour = 0

local gold = 150

local gameLoopTimer
local daytext
local goldText
local boxText
local rentText
local textUIgroup
local shopUIgroup
local inventoryUIgroup
local seedGroup
local window
local touchFlag = 0
local field
local shopDisplay = {}
local inventoryDisplay = {}
local plantedSeedsDisplay = {}
local boxDisplay

local dx = 64
local dy = 64
local x0 = display.contentCenterX - 192
local y0 = display.contentCenterY - 192

local currentShop = {}
local inventory = {}
local cells = {}
local boxForSell = {}
local selectedShopItem
local selectedInventoryCell = 0

local function addCell( cell )
    local object = display.newGroup()
    local rect
    
    if not cell.availiable then
        rect = display.newImageRect( object, "Assets/newCell.png", 64, 64 )
        
        local text = display.newText( object, obj.board[cell.y][cell.x].price .. "g", cell.x, cell.y, native.systemFont, 22 )
        text:setFillColor( 0.25, 0.22, 0.14 )
    else
        if not cell.ready then
            rect = display.newImageRect( object, "Assets/notReadyCell.png", 64, 64 )
            local rect1 = display.newImageRect( object, "Assets/hoe1.png", 32, 32 )
            rect1.x = rect.x
            rect1.y = rect.y
        elseif not cell.pour then
            rect = display.newImageRect( object, "Assets/readyCell.png", 64, 64 )
            local rect1 = display.newImageRect( object, "Assets/pour1.png", 32, 32 )
            rect1.x = rect.x-16
            rect1.y = rect.y-16
            rect1:toFront()
        else
            rect = display.newImageRect( object, "Assets/pourCell.png", 64, 64 )
        end
    end
    
    return object
end

local function createCell( cell )
    local object = addCell( cell )
    field:insert( object )
    object.x = x0 + dx*cell.x
    object.y = y0 + dy*cell.y
    cells[cell] = object
end

local function initField()
    for k,v in pairs( obj.board ) do
        for k1,v1 in pairs( v ) do
            local cell = v1
            createCell( cell )
        end
    end
end

local function updateCell( x, y )
    local cell = obj.board[y][x]
    local cellToRemove
    
    for i=1,#cells do
        if cells[i].x == x and cells[i].y == y then
            cellToRemove = cells[i]
            break
        end
    end
    
    display.remove( cells[cellToRemove] )
    table.remove( cells, cellToRemove )
    
    createCell( cell )
    
    if #obj.newCells > 0 then
        for i=1,#obj.newCells do
            createCell( obj.newCells[i] )
        end
        obj.clearNewCells()
    end
end

local function cultivateCell( x, y )
    obj.cultivateCell( x, y )
    updateCell( x, y )
end

local function updateInventory()
    for i=1,5 do
        local rect = display.newImageRect( inventoryUIgroup, "Assets/shopCell.png", 64, 64 )
        rect.x = display.actualContentWidth-32
        rect.y = display.contentCenterY-192 + 64*i
        
        if selectedInventoryCell == i then
            rect:setFillColor( 0.56, 0.77, 1 )
        end
    end
    
    inventoryDisplay = {}
    for i=1,#inventory do
        local rect
        rect = display.newImageRect( inventoryUIgroup, "Assets/" .. inventory[i].name .."Seed.png", 32, 32 )
        rect.x = display.actualContentWidth-32
        rect.y = display.contentCenterY-192 + 64*i
        --rect:toFront()
        table.insert( inventoryDisplay, rect )
    end
end

local function updateSeed( x, y )
    print("UPDATE")
    for i=1,#plantedSeedsDisplay do
        if plantedSeedsDisplay[i].currentX == x and plantedSeedsDisplay[i].currentY == y then
            display.remove( plantedSeedsDisplay[i] )
            table.remove( plantedSeedsDisplay, i )
            break
        end
    end
    local rect
        
    if obj.getSeed( x, y ).ready then
        local n = "Assets/" .. obj.getSeed( x, y ).seed.name .. "5.png"
        
        if obj.getSeed( x, y ).seed.name == "Melon" then
            n = "Assets/" .. obj.getSeed( x, y ).seed.name .. "6.png"
        end
        
        rect = display.newImageRect( seedGroup, n, 64, 64 )
    else
        local n = "Assets/" .. obj.getSeed( x, y ).seed.name .. obj.getSeed( x, y ).stage .. ".png"
        rect = display.newImageRect( seedGroup, n, 32, 32 )
    end
    rect.x = x0 + dx*x
    rect.y = y0 + dy*y
    rect.currentX = x
    rect.currentY = y
    
    table.insert( plantedSeedsDisplay, rect )
end

local function plantSeed( x, y )
    obj.plantSeed( x, y, inventory[selectedInventoryCell], day )
    table.remove( inventory, selectedInventoryCell )
    display.remove( inventoryDisplay[selectedInventoryCell] )
    selectedInventoryCell = 0
    updateInventory()
    updateSeed( x, y )
end

local function calculateProfit()
    local t = 0
    
    for i=1,#boxForSell do
        t = t + boxForSell[i].priceForSell
    end
    
    return t
end

local function refreshBox()
    if boxDisplay ~= nil then
        display.remove( boxDisplay )
    end
    
    if #boxForSell > 0 then
        boxDisplay = display.newImageRect( shopUIgroup, "Assets/box1.png", 128, 128 )
        boxDisplay.x = 64
        boxDisplay.y = display.actualContentHeight-64
    else
        boxDisplay = display.newImageRect( shopUIgroup, "Assets/box.png", 128, 128 )
        boxDisplay.x = 64
        boxDisplay.y = display.actualContentHeight-64
    end
end

local function deleteAnimation( rect )
    display.remove( rect )
end

local function animateCollect( seed )
    local rect
    
    if seed.seed.name == "Melon" then
        rect = display.newImageRect( seedGroup, "Assets/" .. seed.seed.name .. "7.png", 32, 32 )
    else
        rect = display.newImageRect( seedGroup, "Assets/" .. seed.seed.name .. "6.png", 32, 32 )
    end
    
    rect.x = x0 + dx*seed.x
    rect.y = y0 + dy*seed.y
    rect.xScale = 2
    rect.xScale = 2
    
    transition.to( rect, 
      { x=64, y=display.actualContentHeight-100, time=800, xScale=1, yScale=1, onComplete=deleteAnimation } 
    )
end    

local function collectSeed( x, y )
    local tmp = obj.getSeed( x, y )
    animateCollect( tmp )
    table.insert( boxForSell, obj.getSeed( x, y ).seed )
    boxText.text = "Items for sell: " .. #boxForSell .. " Profit: " .. calculateProfit() .. "g"
    refreshBox()
    
    for i=1,#plantedSeedsDisplay do
        if plantedSeedsDisplay[i].currentX == x and plantedSeedsDisplay[i].currentY == y then
            display.remove( plantedSeedsDisplay[i] )
            table.remove( plantedSeedsDisplay, i )
            break
        end
    end
    
    obj.removeSeed( x, y )
    updateCell( x, y )
end

local function onTouchField( event )
    if touchFlag == 0 then
        if event.phase == "began" then
            print( "-- CLICK ON FIELD --" )
            local x = math.floor((event.x-x0+dx/2)/dx)
            local y = math.floor((event.y-y0+dy/2)/dy)
        
            if obj.checkNewCell( x, y ) then
                if obj.board[y][x].price < gold then
                    gold = gold - obj.board[y][x].price
                    goldText.text = "Gold: " .. gold
                    obj.addNewCell( x, y )
                    updateCell( x, y )
                    rentText.text = "Rent per 28 days: -" .. obj.getRentPrice() .. "g"
                end
            elseif not obj.board[y][x].ready then
                cultivateCell( x, y )
            elseif obj.board[y][x].ready and selectedInventoryCell ~= 0 and obj.getSeed( x, y ) == nil then
                plantSeed( x, y )
                updateCell( x, y )
            elseif not obj.board[y][x].pour then
                obj.pourCell( x, y )
                updateCell( x, y )
            elseif obj.getSeed( x, y ) ~= nil then
                if obj.getSeed( x, y ).ready then
                    collectSeed( x, y )
                end
            end
        end
    end
end

local function updateShop()
    for i=1,5 do
        local rect = display.newImageRect( shopUIgroup, "Assets/shopCell.png", 64, 64 )
        rect.x = 32
        rect.y = display.contentCenterY-192 + 64*i
    end
    
    for i=1,#shopDisplay do
        display.remove( shopDisplay[i] )
    end
    
    shopDisplay = {}
    for i=1,5 do
        if currentShop[i] ~= nil then
            local rect
            rect = display.newImageRect( shopUIgroup, "Assets/".. currentShop[i].name .. "Seed.png", 32, 32 )
            rect.x = 32
            rect.y = display.contentCenterY-192 + 64*i
            table.insert( shopDisplay, rect )
        end        
    end
end

local function initShop()
    currentShop = shop.refreshShop()
    updateShop()
end

local function switchTouchFlag()
    touchFlag = 0
end

local function onTouchBuyBtn( event )
    if event.phase == "began" then
        if #inventory < 5 and currentShop[selectedShopItem].priceForBuy <= gold then
            gold = gold - currentShop[selectedShopItem].priceForBuy
            goldText.text = "Gold: " .. gold
            display.remove( window )
            display.remove( shopDisplay[selectedShopItem] )
            table.insert( inventory, currentShop[selectedShopItem] )
            updateInventory()
            currentShop[selectedShopItem] = nil
            selectedShopItem = 0
            timer.performWithDelay( 100, switchTouchFlag )
        end
    end
end

local function onTouchCancelBtn( event )
    if event.phase == "began" then
        display.remove( window )
        selectedShopItem = 0
        timer.performWithDelay( 100, switchTouchFlag )
    end    
end

local function openShopWindow( ind )
    touchFlag = 1
    window = display.newGroup()
    window:toFront()
    local rect = display.newImageRect( window, "Assets/window.png", 480, 320 )
    rect.x = display.contentCenterX
    rect.y = display.contentCenterY
    
    local text = {
        parent = window,
        text = "Name: " .. currentShop[ind].name,
        x = rect.x+120,
        y = rect.y-70,
        width = 240,
        font = native.systemFont,
        fontSize = 28,
        align = "left"
    }
    
    local text1 = display.newText( text )
    text.text = "Price: " .. currentShop[ind].priceForBuy
    text.y = rect.y-20
    local text2 = display.newText( text )
    text.text = "Growth Time: " .. currentShop[ind].duration .. "d"
    text.y = rect.y+30
    local text3 = display.newText( text )
    
    local imgSeed = display.newImageRect( window, "Assets/" .. currentShop[ind].name .. "Seed.png", 64, 64 )
    imgSeed.x = rect.x-100
    imgSeed.y = rect.y-20
    
    local buyButton = display.newImageRect( window, "Assets/buyBtn.png", 112, 48 )
    buyButton.x = rect.x - 80
    buyButton.y = rect.y + 100    
    
    local cancelButton = display.newImageRect( window, "Assets/cancelBtn.png", 112, 48 )
    cancelButton.x = rect.x + 80
    cancelButton.y = rect.y + 100
    
    buyButton:addEventListener( "touch", onTouchBuyBtn )
    cancelButton:addEventListener( "touch", onTouchCancelBtn )
end

local function onTouchShop( event )
    if touchFlag == 0 then
        if event.phase == "began" then
            local y = math.floor((event.y-display.contentCenterY+192+64/2)/64)
            if currentShop[y] ~= nil then
                print( "Clicked on shop -- " .. currentShop[y].name )
                selectedShopItem = y
                openShopWindow( y )
            end
        end
    end
end

local function onTouchInventory( event )
    if touchFlag == 0 then
        if event.phase == "began" and touchFlag == 0 then
            local y = math.floor((event.y-display.contentCenterY+192+64/2)/64)
            print( "Clicked on inventory -- " .. y )
            if inventory[y] ~= nil then
                selectedInventoryCell = y
                updateInventory()
            end
        end
    end
end

local function initGame()
    field = display.newGroup()
    shopUIgroup = display.newGroup()
    inventoryUIgroup = display.newGroup()
    seedGroup = display.newGroup()
    obj.newLevel()
    initField()
    initShop()
    refreshBox()
    updateInventory()
    field:addEventListener( "touch", onTouchField )
    shopUIgroup:addEventListener( "touch", onTouchShop )
    inventoryUIgroup:addEventListener( "touch", onTouchInventory )
end

local function checkSeeds()
    local t = obj.checkSeeds( day )
    
    for i=1,#t do
        updateSeed( t[i].x, t[i].y )
    end
end

local function checkPourSeeds()
    local t = obj.checkPourSeeds()
    
    for i=1,#t do
        updateCell( t[i].x, t[i].y )
    end
end

local function sellItems()
    for i=1,#boxForSell do
        gold = gold + boxForSell[i].priceForSell
    end
    boxForSell = {}
    goldText.text = "Gold: " .. gold
    boxText.text = "Items for sell: " .. #boxForSell .. " Profit: " .. calculateProfit() .. "g"
    refreshBox()
end

local function tick()
    if hour == 24 then hour = 0 end
    
    hour = hour + 3
    
    if hour % 12 == 0 then
        checkPourSeeds()
    end
    
    if hour == 24 then
        day = day + 1
        checkSeeds()
        if (day-1) % 7 == 0 then
            currentShop = shop.refreshShop()
            updateShop()
            sellItems()
        end
        if (day-1) % 28 == 0 then
            gold = gold - obj.getRentPrice()
            goldText.text = "Gold: " .. gold
        end
    end
    
    local time
    
    if hour < 10 then
        time = "0" .. hour .. ":00"
    else 
        time = hour .. ":00"
    end
    
    dayText.text = "Day: " .. day .. " Hours: " .. time
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
    background = display.newImageRect( sceneGroup, "Assets/bg.png", display.actualContentWidth, display.actualContentHeight )
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    
    textUIgroup = display.newGroup() -- background
	sceneGroup:insert( textUIgroup )
    
    local text = {
        text = "Shop \n(refresh per 7 days)",
        x = 90,
        y = display.contentCenterY-190,
        width = 180,
        font = native.systemFont,
        fontSize = 20,
        align = "left"
    }
    
    local shopText = display.newText( text )
    
    local bagText = display.newText( "Bag", display.actualContentWidth-32, display.contentCenterY-190, native.systemFont, 26 )
    
    dayText = display.newText( textUIgroup, "Day: " .. day .. " Hours: 0" .. hour .. ":00", 120, 36, native.systemFont, 26 )
    
    goldText = display.newText( textUIgroup, "Gold: " .. gold, display.contentCenterX, 36, native.systemFont, 28 )
    
    boxText = display.newText( textUIgroup, "Items for sell: " .. #boxForSell .. " Profit: 0g", 384, display.actualContentHeight-36, native.systemFont, 28 )
    
    rentText = display.newText( textUIgroup, "Rent per 28 days: -" .. 225 .."g", display.contentCenterX+250, 36, native.systemFont, 26 )
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
        initGame()
	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
        gameLoopTimer = timer.performWithDelay( 1000, tick, 0 )
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
