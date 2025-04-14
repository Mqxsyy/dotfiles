local folderPath = debug.getinfo(1, "S").source:match "@?(.*/)" .. "frames/sleepingCat/?.lua"
package.path = package.path .. ";" .. folderPath

local CANVAS_HEIGHT = 48
local FPS = 1

local frames = {}

for i = 1, 6 do
    local frame = require(tostring(i))
    frames[i] = frame:gsub("e", "\27")
end

local function sleep()
    os.execute("sleep " .. 1 / FPS)
end

local function drawFrame(frame)
    io.write(string.format("\27[%dA", CANVAS_HEIGHT))
    io.flush()

    io.write("\r" .. frame)
    io.flush()
end

while true do
    for i = 1, #frames do
        drawFrame(frames[i])
        sleep()
    end
end
