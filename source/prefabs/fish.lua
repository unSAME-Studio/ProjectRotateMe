local gfx <const> = playdate.graphics

Fish = {}
Fish.__index = Fish

function Fish:new()
    -- draw fishes
    local self = gfx.sprite:new(gfx.image.new("images/fish"))

    -- states
    self.type = "fish"
    self.inAir = false
    self.caught = false
    
    -- movement
    self.direction = math.random(0, 1) == 1 and 1 or -1
    self.speed = math.random(1, 2)
    self.velocity = {x = 0, y = 0}
    self.gravity = 0.15
    self.acceleration = 0.25
    self.drag = 0.1

    self:setCollideRect(0, 0, self:getSize())
    self:setZIndex(5)

    -- flip the sprite
    if self.direction == 1 then
        self:setImageFlip("flipX")
    end

    -- add fish to collision group 3
    -- player is in group 2
    self:setGroups(3)
    self:setCollidesWithGroups(2)

    function self:kill()
        self:remove()
    end

    function self:collide(s)
        print("collide")

        self.caught = true

        money = money + 1
    end
    
    function self:update()
        -- check if caught
        if self.caught then
            self:moveTo(ballPosition)
            return
        end

        -- process collision
        local collide = self:overlappingSprites()
        if collide[1] then
            self:collide(collide[1])
        end

        -- check if fish is in air
        local waterHeight = math.sin(self.x / 20 + playdate.getCurrentTimeMilliseconds() / 200) * waterStrength + waterHeight
        if self.y < waterHeight then
            self.inAir = true

            --self.velocity.x = lerp(self.velocity.x, 0, self.drag)
            self.velocity.y = self.velocity.y + self.gravity
        else
            self.inAir = false

            self.velocity.x = math.clamp(self.velocity.x + self.acceleration * self.direction, -self.speed, self.speed)
            
            local waterDepth = self.y - waterHeight
            self.velocity.y = math.clamp(self.velocity.y - self.gravity * (waterDepth / 240), -self.speed, self.speed)
        end
        
        self:moveBy(self.velocity.x, self.velocity.y)

        -- wrap around
        if self.x > 420 then
            self:moveTo(-20, self.y)
        elseif self.x < -20 then
            self:moveTo(420, self.y)
        end

    end

    function self:collisionResponse(other)
		return "overlap"
	end

    return self
end