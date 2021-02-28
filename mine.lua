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

currentY = 1
arrivedToBedrock = false
inventoryFull = false

-- Variables used for script recovery
hasRecovered = false

orientations = {
    [1] = "West";
    [2] = "South";
    [3] = "East";
    [4] = "North";
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
    else
        print('Creating db...')
        startX, startY, startZ = gps.locate()
        db = {
            ["startCoord"] = {
              x = startX;
              y = startY;
              z = startZ;
            };
            ["orientation"] = getOrientation();
            ["holeX"] = tonumber(args[1], 10);
            ["holeZ"] = tonumber(args[2], 10);
        }
        local dbFile = fs.open('database','w')
        dbFile.write(textutils.serialize(database))
        dbFile.close()
        print(db)
    end
end


-- Check if remaining fuel is enough to dig one layer
-- else run the refuel function
function checkFuel ()
    local currentFuel = turtle.getFuelLevel()
    local fuelNeeded = db.holeX * db.holeZ
    
    print("Current fuel: " .. currentFuel)
    print("Estimated fuel needed: " .. fuelNeeded)
    
    while (currentFuel < fuelNeeded) do
        refuel()
        currentFuel = turtle.getFuelLevel()
    end
    return
end


function digStraight (steps)
    for i = 1, steps do
        -- Till there is a block, break it
        -- Useful with tall pile of sand/gravel
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


-- Main loop until Bedrock is reached
startup()
while true do
    
end


-- End of script
return