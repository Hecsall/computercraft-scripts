	
diskSide = 'left'
dropperSide = 'front'
doorSide = 'right'
pullerSide = 'bottom'
password = '**password**'


function eject ()
    redstone.setOutput(pullerSide, false)
    sleep(1)
    redstone.setOutput(pullerSide, true)
    redstone.setOutput(dropperSide, true)
    sleep(1)
    redstone.setOutput(dropperSide, false)
end


function handleValidDisk ()
    eject()
    sleep(1)
    redstone.setOutput(doorSide, true)
    sleep(3)
    redstone.setOutput(doorSide, false)
end


redstone.setOutput(pullerSide, true)

while true do
    local event, side = os.pullEvent()
    if event == "disk" then
        -- If its a valid disk, proceed
        if disk.getMountPath('left') ~= nil then
            print("Disk was inserted: "..side)
            -- Controllo label del disk
            if disk.getLabel(diskSide) == password then
                handleValidDisk()
            else
                eject()
            end

        else
            -- If random block fuck you
            diskPresent = disk.isPresent(diskSide)
            while diskPresent do
                eject()
                diskPresent = disk.isPresent(diskSide)
            end
        end
    end
end