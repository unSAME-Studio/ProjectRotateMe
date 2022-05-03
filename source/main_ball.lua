import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

local playerSprite = nil
local ballSprite = nil

local circles = {}

local function calcCircle(r, n, posx, posy)
    local points = {}
    for x = 0, n+1, 1 do
        local pointX = math.cos(2*math.pi/n*x)*r + posx
        local pointY = math.sin(2*math.pi/n*x)*r + posy

        table.insert(points, pointX)
        table.insert(points, pointY)
    end

    return points
end

local function drawCircle(points)
    --print("Drawing circle with " .. #points .. " points")

    local polyObj = playdate.geometry.polygon.new(table.unpack(points))
    polyObj:close()

    gfx.setColor(gfx.kColorXOR)
    gfx.setLineWidth(1)
    gfx.fillPolygon(polyObj)
end

local function initalize()
    --set background color
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    --[[ create player sprite
    local playerImage = gfx.image.new("images/ring")
    playerSprite = gfx.sprite.new(playerImage)
    playerSprite:moveTo(200, 120)
    playerSprite:setCollideRect(0, 0, playerSprite:getSize())
    playerSprite:add()
    ]]--

    -- create ball sprite
    local ballImage = gfx.image.new("images/ball")
    ballSprite = gfx.sprite.new(ballImage)
    ballSprite:moveTo(200, 120)
    ballSprite:setCollideRect(0, 0, ballSprite:getSize())
    ballSprite:add()

    -- calculate 3 circles with different size
    local radius = {50, 100, 150}
    for i, v in pairs(radius) do
        table.insert(circles, calcCircle(v, 25, 200, 120))
    end
    
end

initalize()

function playdate.update()
    gfx.sprite.update()

    -- draw polygon
    for i = 1, 3, 1 do
        drawCircle(circles[i])
    end
end

function playdate.cranked(change, acceleratedChange)
    print("cranked", change, acceleratedChange)

    -- rotate player sprite
    --playerSprite:setRotation(playerSprite:getRotation() + change)
end

function playdate.crankDocked()
    print("crankDocked")
    
    --playerSprite:setRotation(0)
end