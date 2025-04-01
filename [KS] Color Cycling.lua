--[[
  
  █ █▀
  █▀▄█

  Color Cycling for Aseprite

  Author: Kerim Safa
  Version: 1.0
  License: MIT 
  Website: https://www.kerimsafa.com
  X: https://x.com/kerimsafa
  Project page: https://kerimsafa.itch.io/color-cycling
  Source: https://github.com/kerimsafa/color-cycling
  
  Description:
  Color cycling tool for Aseprite designed to simulate classic DPaint-style palette shifting.

  The script includes multiple motion modes:
    - Default
    - Mirror
    - Ping Pong
    - Random

  Instructions:
    1. Make sure your sprite is in Indexed color mode.
    2. Select the cel you want to apply color cycling to.
    3. Run the script.
    4. Choose start and end palette indices.
    5. Select the desired Cycle Mode.
    6. Click "Cycle" to generate the animation.
    7. The script will add frames if needed.

  See `README.md` for details.

  Copyright (c) 2025 Kerim Safa. All rights reserved.
  
]]

local dlg = Dialog{ title = "[KS] Color Cycling" }

local function rotateList(t, offset)
  local len = #t
  local rotated = {}
  for i = 1, len do
    local index = ((i + offset - 1) % len) + 1
    rotated[i] = t[index]
  end
  return rotated
end

local function cycleColors(data)
  local spr = app.activeSprite
  local cel = app.activeCel

  if not spr or not cel or spr.colorMode ~= ColorMode.INDEXED then
    app.alert("This script only works on Indexed color mode with a selected cel.")
    return
  end

  local layer = cel.layer
  local frame = cel.frame
  local image = cel.image:clone()
  local position = cel.position
  local startIndex = tonumber(data.start_index)
  local endIndex = tonumber(data.end_index)

  if not startIndex or not endIndex or startIndex < 0 or endIndex < 0 then
    app.alert("Invalid index range.")
    return
  end

  local indices = {}
  if startIndex <= endIndex then
    for i = startIndex, endIndex do table.insert(indices, i) end
  else
    for i = startIndex, endIndex, -1 do table.insert(indices, i) end
  end

  local steps = #indices
  if steps < 2 then
    app.alert("Need at least 2 colors to cycle.")
    return
  end

  local mode = data.cycle_mode or "Default"
  local paletteList = {}         
  local shiftOffsets = {}        

  -- MODE: MIRROR 
  if mode == "Mirror" then
    for _, v in ipairs(indices) do table.insert(paletteList, v) end
    for i = #indices - 1, 2, -1 do
      table.insert(paletteList, indices[i])
    end
    for i = 0, #paletteList - 1 do
      table.insert(shiftOffsets, i)
    end

  -- MODE: PING PONG
  elseif mode == "Ping Pong" then
    paletteList = indices
    for i = 0, steps - 1 do
      table.insert(shiftOffsets, i)
    end
    for i = steps - 0, 1, -1 do
      table.insert(shiftOffsets, i)
    end

  -- MODE: RANDOM
  elseif mode == "Random" then
    local function shuffle(t)
      local shuffled = {}
      local used = {}
      while #shuffled < #t do
        local i = math.random(1, #t)
        if not used[i] then
          table.insert(shuffled, t[i])
          used[i] = true
        end
      end
      return shuffled
    end

    paletteList = indices

    local randomFrames = #indices
    for i = 1, randomFrames do
      table.insert(shiftOffsets, shuffle(indices))
    end

  -- MODE: DEFAULT
  else
    paletteList = indices
    for i = 0, steps - 1 do
      table.insert(shiftOffsets, i)
    end
  end

  app.transaction(function()
    local totalFrames = #spr.frames
    local frameOffset = frame.frameNumber
    local neededFrames = #shiftOffsets

    while totalFrames < frameOffset + neededFrames - 1 do
      app.command.NewFrame()
      totalFrames = totalFrames + 1
    end

    local baseImage = image:clone()

    for i, offset in ipairs(shiftOffsets) do
      local shiftedIndices = (mode == "Random") and offset or rotateList(paletteList, offset)
      local newImage = baseImage:clone()

      for y = 0, newImage.height - 1 do
        for x = 0, newImage.width - 1 do
          local pix = newImage:getPixel(x, y)
          for j, val in ipairs(paletteList) do
            if pix == val then
              newImage:putPixel(x, y, shiftedIndices[j])
              break
            end
          end
        end
      end

      local currentFrame = spr.frames[frameOffset + (i - 1)]
      local newCel = spr:newCel(layer, currentFrame.frameNumber)
      newCel.image = newImage
      newCel.position = position
    end
  end)

  dlg:show{ wait = false }
end

-- UI
dlg:number{ id="start_index", label="Start Index", text="0", decimals=0 }
dlg:number{ id="end_index", label="End Index", text="4", decimals=0 }
dlg:combobox{
  id="cycle_mode",
  label="Cycle Mode",
  options={"Default", "Mirror", "Ping Pong", "Random"},
  option="Default"
}
dlg:button{
  text="Cycle",
  onclick=function()
    cycleColors(dlg.data)
  end
}
dlg:button{ text="Close", onclick=function() dlg:close() end }

dlg:show{ wait = false }
