-- Run like
-- mineandrefuel <X> <Z>
-- where X and Z are the length and width of the hole to dig.

currentY = 1
arrivedToBedrock = false
inventoryFull = false

orientations = {
    [1] = "West";
    [2] = "North";
    [3] = "East";
    [4] = "South";
}

oppositeOrientations = {
    ["North"] = "South";
    ["South"] = "North";
    ["East"] = "West";
    ["West"] = "East";
}

rightOrientations = {
    ["West"] = "North";
    ["East"] = "South";
    ["North"] = "East";
    ["South"] = "West";
}

-- -x = 1 (West)
-- -z = 2 (North)
-- +x = 3 (East)
-- +z = 4 (South)
function getOrientation()
    loc1 = vector.new(gps.locate(2, false))
    if not turtle.forward() then
        for j=1,6 do
            if not turtle.forward() then
                turtle.dig()
            else 
                break
            end
        end
    end
    loc2 = vector.new(gps.locate(2, false))
    heading = loc2 - loc1
    turtle.back()
    return orientations[((heading.x + math.abs(heading.x) * 2) + (heading.z + math.abs(heading.z) * 3))]
end


-- Startup function
-- On startup save current coordinates and variables in a file.
-- If the turtle is stopped, upon startup will read that file and
-- calculate how to recover what was doing.
function startup () 
    if (fs.exists("database")) then
        print('Reading db...')
        local dbFile = fs.open('database','r')
        db = textutils.unserialize(dbFile.readAll())
        dbFile.close()
        print("Resuming previous activity in...")
        for i=1,10 do
            print(10 - (i - 1))
            sleep(1)
        end
    else
        print('X length: ')
        holeX = read()
        print('Z length: ')
        holeZ = read()

        print('Creating db...')
        startX, startY, startZ = gps.locate()
        db = {
            ["startCoord"] = {
              x = startX;
              y = startY;
              z = startZ;
            };
            ["orientation"] = getOrientation();
            ["holeX"] = tonumber(holeX, 10);
            ["holeZ"] = tonumber(holeZ, 10);
        }
        local dbFile = fs.open('database','w')
        dbFile.write(textutils.serialize(db))
        dbFile.close()
        print('Start Orientation: ', db["orientation"])
    end
end


-- Note:
-- Slot 1   ALWAYS dedicated to fuel
-- Slot 2   ALWAYS dedicated to Output Ender Chest


-- Check if remaining fuel is enough to dig one layer
-- else run the refuel function
function checkFuel ()
    local currentFuel = turtle.getFuelLevel()
    local fuelNeeded = db['holeX'] * db['holeZ']
    
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

    shell.run('delete','database')
    return
end


function getCurrentX ()
    tempX, tempY, tempZ = gps.locate()
    result = math.abs(startX - tempX)
    return result + 1
end


function handleRecover ()
    local recoveredOrientation = getOrientation()

    local startPosition = vector.new(db['startCoord']['x'], db['startCoord']['y'], db['startCoord']['z'])
    local currentPosition = vector.new(gps.locate())
    local distance = startPosition:sub(currentPosition)
    -- if turtle is in a different position than start position
    -- return to start position (except for Y axis)
    if (distance:length() ~= 0) then

        if (db['orientation'] == 'North' or db['orientation'] == 'South') then
            movesX = math.abs(distance.x)
            movesZ = math.abs(distance.z)
        else
            movesX = math.abs(distance.z)
            movesZ = math.abs(distance.x)
        end

        -- Turtle in same orientation than start
        if (recoveredOrientation == db['orientation']) then
            turtle.turnLeft()
            digStraight(movesX)
            turtle.turnLeft()
            digStraight(movesZ)
            turtle.turnLeft()
            turtle.turnLeft()
            turtle.up()
        elseif (recoveredOrientation == oppositeOrientations[db['orientation']]) then
            turtle.turnRight()
            digStraight(movesX)
            turtle.turnLeft()
            digStraight(movesZ)
            turtle.turnLeft()
            turtle.turnLeft()
            turtle.up()
        elseif (recoveredOrientation == rightOrientations[db['orientation']]) then
            turtle.turnRight()
            turtle.turnRight()
            digStraight(movesX)
            turtle.turnLeft()
            digStraight(movesZ)
            turtle.turnLeft()
            turtle.turnLeft()
            turtle.up()
        end
    end
end


-- Main loop until Bedrock is reached
startup()
checkInventorySpace()
handleRecover()
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
    
    digStraight(db['holeZ'] - 1)
    turtle.turnRight()
    
    while (currentX < db['holeX']) do
        digStraight(1)
        currentX = currentX + 1
        
        if (currentX % 2 == 0) then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
        
        digStraight(db['holeZ'] - 1)
        
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
    for i = 1, (db['holeX'] - 1) do
        turtle.forward()
    end
    -- Z
    if needZReset then
        turtle.turnLeft()
        for i = 1, (db['holeZ'] - 1) do
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