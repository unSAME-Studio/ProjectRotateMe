import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "prefabs/fish"

local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

local playerSprite = nil
local playerJiggle = 0
local ballSprite = nil
ballPosition = nil

local fishes = {}
money = 0

local waterAmount = 1000
local targetWaterAmount = 1000
waterHeight = 10
waterStrength = 0
local waterSpeed = 0.1

local waterImage = nil
local waterSprite = nil

-- Clamps a number to within a certain range, with optional rounding
function math.clamp(low, n, high) return math.min(math.max(n, low), high) end

-- Lerp
function lerp(a,b,t) return a * (1-t) + b * t end

-- Spring
function spring(a, b, t)
    t = math.clamp(t, 0, 1)
    t = (math.sin(t * math.pi * (0.2 + 2.5 * t * t * t)) * math.pow(1 - t, 2.2) + t) * (1 + (1.2 * (1 - t)))
    return a + (b - a) * t
end

-- point rotation
function rotate_point(cx, cy, angle, p)
    local s = math.sin(angle)
    local c = math.cos(angle)

    -- translate point back to origin:
    p.x = p.x - cx
    p.y = p.y - cy

    -- rotate point
    local xnew = p.x * c + p.y * s
    local ynew = -p.x * s + p.y * c

    -- translate point back:
    p.x = xnew + cx
    p.y = ynew + cy
    return p
end

local function calcWave(amount, height)
    local points = {}
    local current_time = playdate.getCurrentTimeMilliseconds()

    table.insert(points, geo.point.new(0, math.sin(0 + current_time / 200) * waterStrength + height))

    for i = 1, amount, 1 do
        local pointX = 400 / amount * i
        local pointY = math.sin(pointX / 20 + current_time / 200) * waterStrength + height

        table.insert(points, geo.point.new(pointX, pointY))
    end

    table.insert(points, geo.point.new(400, 240))
    table.insert(points, geo.point.new(0, 240))

    return points
end

local function drawWave(points, color)
    local polyObj = geo.polygon.new(table.unpack(points))
    polyObj:close()

    gfx.setColor(color)
    gfx.setDitherPattern(0.2, gfx.image.kDitherTypeDiagonalLine)
    gfx.fillPolygon(polyObj)
end

local function spawnFish()
    local newFish = Fish:new()
    newFish:moveTo(math.random(0, 400), math.random(0, 240))
    newFish:add()

    table.insert(fishes, newFish)
end

local function initialize()
    --set background color
    --gfx.setBackgroundColor(gfx.kColorBlack)
    --gfx.clear()

    -- invert
    playdate.display.setInverted(true)
    
    local backgroundImage = gfx.image.new("images/background")
    gfx.sprite.setBackgroundDrawingCallback(
        function(x, y, width, height)
            gfx.setClipRect(x, y, width, height)
            waterImage:draw(0, 0)
            --gfx.clear()
            gfx.clearClipRect()
        end
    )

    -- draw wave as a image
    waterImage = gfx.image.new(400, 240)
    waterSprite = gfx.sprite.new(waterImage)
    waterSprite:setZIndex(4)
    waterSprite:setCenter(0, 0)
    waterSprite:setRedrawsOnImageChange(false)
    waterSprite:add()

    local playerImage = gfx.image.new("images/boat")
    playerSprite = gfx.sprite.new(playerImage)
    playerSprite:moveTo(200, 120)
    playerSprite:setZIndex(2)
    playerSprite:setCollideRect(0, 0, playerImage:getSize())
    playerSprite:setCenter(0.5, 0.9)
    playerSprite:add()

    local ballImage = gfx.image.new("images/ball")
    ballSprite = gfx.sprite.new(ballImage)
    ballSprite:moveTo(200, 180)
    ballSprite:setCollideRect(0, 0, ballSprite:getSize())
    ballSprite:setZIndex(6)
    ballSprite:setGroups(2)
    ballSprite:setCollidesWithGroups(3)
    ballSprite:add()

    -- spawn 10 fishes
    for i = 1, 10, 1 do
        spawnFish()
    end

    -- crank indicator
    --playdate.ui.crankIndicator:start()
end

initialize()

function playdate.update()
    --playdate.ui.crankIndicator:update()
    --playdate.timer.updateTimers()

    -- update water stats
    waterAmount = lerp(waterAmount, targetWaterAmount, 0.2)
    waterHeight = lerp(210, 40, waterAmount / 1000.0)
    waterStrength = lerp(waterStrength, 1, 0.1)
    
    -- move the player
    local playerY1 = math.sin(195 / 20 + playdate.getCurrentTimeMilliseconds() / 200) * waterStrength + waterHeight
    local playerY2 = math.sin(205 / 20 + playdate.getCurrentTimeMilliseconds() / 200) * waterStrength + waterHeight
    local playerY = (playerY1 + playerY2) / 2
    playerSprite:moveTo(200, playerY)
    
    -- spin the player
    playerJiggle = spring(playerJiggle, math.atan2(playerY2 - playerY1, 10) * 2, 0.2)
    playerSprite:setRotation(math.deg(playerJiggle))
    
    -- move the hook
    local newPoolLocation = rotate_point(playerSprite.x, playerSprite.y, -playerJiggle, geo.point.new(playerSprite.x - 19, playerSprite.y - 18))
    ballPosition = geo.point.new(spring(ballSprite.x, newPoolLocation.x, 0.05), spring(ballSprite.y, newPoolLocation.y + 50, 0.05))
    ballSprite:moveTo(ballPosition)
    
    -- draw dynamic waves
    gfx.lockFocus(waterImage)
    -- waterSprite:setClipRect(0, waterHeight - waterStrength, 400, 240 - waterHeight + waterStrength)
    waterImage:clear(gfx.kColorClear)
    drawWave(calcWave(100, waterHeight), gfx.kColorXOR)
    waterSprite.addDirtyRect(0, 0, 100, 180)
    gfx.unlockFocus()
    
    --[[ draw the constant white wave
    gfx.setClipRect(0, wate,brHeight + 5, 400, 240 - waterHeight + 5)
    gfx.setColor(gfx.kColorXOR)
    gfx.setDitherPattern(0.2, gfx.image.kDitherTypeDiagonalLine)
    gfx.fillRect(0, waterHeight + 5, 400, 240 - waterHeight + 5)
    gfx.clearClipRect()
    ]]--

    -- update all fishes
    for i, fish in ipairs(fishes) do
        fish:update()
    end

    -- update sprites
    gfx.sprite.update()
    
    -- draw hint text
    -- gfx.setImageDrawMode(gfx.kDrawModeXOR)
    gfx.drawText("🪙: " .. money, 10, 10)
    
    -- draw the line
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(2)
    gfx.setLineCapStyle(gfx.kLineCapStyleRound)
    gfx.drawLine(newPoolLocation.x, newPoolLocation.y, ballPosition.x, ballPosition.y)


end

function playdate.cranked(change, acceleratedChange)
    targetWaterAmount = math.clamp(targetWaterAmount + acceleratedChange, 0, 1000)
    waterStrength = lerp(waterStrength, math.clamp(math.abs(acceleratedChange), 0, 30), 0.2)
end