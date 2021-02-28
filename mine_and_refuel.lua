-- Run like
-- mineandrefuel <X> <Z>
-- where X and Z are the length and width of the hole to dig.


local args = { ... }

if #args ~= 2 then
    print( "Usage: mineandrefuel <X> <Z>" )
    print( "Fuel (coal) must ALWAYS be on slot 1" )
    print( "Ender Chest must ALWAYS be on slot 2" )
    error()
end

holeX = tonumber(args[1], 10)
holeZ = tonumber(args[2], 10)
currentY = 1
arrivedToBedrock = false
inventoryFull = false

-- Note:
-- Slot 1   ALWAYS dedicated to fuel
-- Slot 2   ALWAYS dedicated to Output Ender Chest


-- Check if remaining fuel is enough to dig one layer
-- else run the refuel function
function checkFuel ()
    local currentFuel = turtle.getFuelLevel()
    local fuelNeeded = holeX * holeZ
    
    print("Current fuel: " .. currentFuel)
    print("Estimated fuel needed: " .. fuelNeeded)
    
    while (currentFuel < fuelNeeded) do
        refuel()
        currentFuel = turtle.getFuelLevel()
    end
    return
end


-- Get some coal from the Ender Chest
function refuel ()
    print("[!] Not enough fuel, refueling")
    turtle.select(1)
    turtle.refuel()
    return
end


function checkInventorySpace ()
    turtle.select(16)
    slotIsOccupied = turtle.getItemCount() > 0
    turtle.select(1)
    if slotIsOccupied then
        depositInventory()
    end
end


function depositInventory ()
    print("Inventory almost full: deposit in progress...")
    local spaceForChest = true
    -- Check if there is space to place the chest
    if turtle.inspect() then
        spaceForChest = false
        turtle.turnLeft()
        turtle.turnLeft()
    end
    
    turtle.select(2) -- select Ender Chest slot
    turtle.place()
    for i = 3, 16 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(2)
    turtle.dig()
    turtle.select(1)
    
    if not spaceForChest then
        spaceForChest = true
        turtle.turnLeft()
        turtle.turnLeft()
    end
end


function digStraight (steps)
    for i = 1, steps do
        -- Till there is a block, break it
        while turtle.detect() do
            checkInventorySpace()
            turtle.dig()
        end
        -- When no more blocks in front, move forward
        turtle.forward()
    end
    return
end


-- Return to the initial height coordinate of the turtle
function returnHome ()
    -- Y
    if currentY > 1 then
        for i = 1, (currentY - 1) do
            turtle.up()
        end
        currentY = 1
    end
    return
end


-- Main loop until Bedrock is reached
checkInventorySpace()
while not arrivedToBedrock do
    local currentX = 1
    local needZReset = false
    
    local success, bottomBlock = turtle.inspectDown()
    
    if (bottomBlock.name == 'minecraft:bedrock') then
        arrivedToBedrock = true
        returnHome()
        return -- end the while
    end
    
    checkFuel()
    
    -- select slot 3 to 
    turtle.select(3)
    
    turtle.digDown()
    turtle.down()
    currentY = currentY + 1
    
    digStraight(holeZ - 1)
    turtle.turnRight()
    
    while (currentX < holeX) do
        digStraight(1)
        currentX = currentX + 1
        
        if (currentX % 2 == 0) then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
        
        digStraight(holeZ - 1)
        
        if (currentX % 2 == 0) then
            turtle.turnLeft()
            needZReset = false
        else
            turtle.turnRight()
            needZReset = true
        end
    end
    
    -- Return to starting position
    turtle.turnRight()
    turtle.turnRight()
    -- X
    for i = 1, (holeX - 1) do
        turtle.forward()
    end
    -- Z
    if needZReset then
        turtle.turnLeft()
        for i = 1, (holeZ - 1) do
            turtle.forward()
        end
        turtle.turnRight()
        turtle.turnRight()
        needZReset = false
    else
        turtle.turnRight()
    end
    
    currentX = 1
end


-- End of script
return