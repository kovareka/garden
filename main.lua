-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here
local composer = require( "composer" )

display.setStatusBar( display.HiddenStatusBar )

math.randomseed( os.time() )

  -- Go to menu view
composer.gotoScene( "scene.game", { params={} } )