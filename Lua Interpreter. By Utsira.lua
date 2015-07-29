--# Main
-- Lua Interpreter. By Utsira
oldPrint = print

displayMode(FULLSCREEN_NO_BUTTONS )
--partially pull down the ios notifications screen, or partially do a 4-finger app-switching gesture to bring the buttons back, or hit home and relaunch Codea

function setup()
    orientationChanged(CurrentOrientation)
    screeny, targety =0,0
   -- font("Inconsolata")
    lines = {}
    level = 1 --current indent level
    auto={}
    buttonX = 0
    setStyle()
    buttons={Button"+", Button"-", Button"*", Button"/", Button"<", Button("="), Button">", Button"#", Button":", Button"\"\"", Button"()", Button"[]", Button"{}"}
    parameter.watch("cursorPos")
    showKeyboard()
    print("########  LUA 5.3 INTERPRETER  ########\nTap the autocomplete suggestions to complete words. \nSlide your finger anywhere else on screen to move the cursor.")
    lines[#lines+1]={level=level, str=""} --indent level, string
    moveCursor(1)
end

--use local functions to prevent user overwriting them. Difficult to make it idiot-proof though
local function interpret(command)
    local ok, result = pcall(function() return loadstring(command)() end)
    if not ok then --attempt to handle fragments like "5-2"
        ok, result = pcall(function() return loadstring("return "..command)() end)
    end
    if result then --suppress chunks that dont return anything
        print(tostring(result))
    end
end

function print(...)
    local out = {...}
    lines[#lines+1]={level=0, str=table.concat(out, "  ")}
end

--autocomlete

local complete = {"function", "repeat", "return", "end", "until", "while", "for", "then", "local", "and", "not", "else", "elseif"} --Lua commands not in _G

local function populateAutocomplete()
    pushStyle()
    setStyle()
    fontSize(buttonSize)
    local word = string.match(" "..beforeCursor, "[^%._%w]([%w%._]+)$") --grab last letters before cursor
    -- oldPrint(word)
    auto={}
    if word then
        local x = 0
        local lib,word2
        if string.match(word, "%.") then --if period then grab library ("math", "string" etc), class name etc
            lib, word2 = string.match(word, "([%w_]+)%.([%w_]*)")
            --  oldPrint (lib, word2)
        end
        
        if lib and _G[lib] then
            for k,_ in pairs(_G[lib]) do   --check word against contents of library ("math" etc) or class
                if string.match(k, "^"..word2) then
                    local w,_ = textSize(k.." ")
                    auto[#auto+1]={x=x, w=w, str=k}
                    x = x + w
                end
            end
        else
            local check={} 
            for k,_ in pairs(_G) do  --check is a shallow copy of _G keys
                check[#check+1]=k --rebuild on each press on order to include user-created variables
            end
            table.move(complete, 1, #complete, #check+1, check) --add Lua commands not in _G
            table.sort(check) --alphabetize
            for _,k in ipairs(check) do   --check word against _G
                if string.match(k, "^"..word) then
                    local w,_ = textSize(k.." ")
                    auto[#auto+1]={x=x, w=w, str=k}
                    x = x + w
                end
            end
        end
    end
    popStyle()
end

function setStyle()
    font("Menlo")
    fill(6, 255, 0, 255)
    fontSize(20)
    textMode(CORNER)
end

function draw()
    if not isKeyboardShowing() then
        typeWriter = 0
    end
    background(40, 40, 50)
    pushMatrix()
    translate(0,screeny) 
    
    --cursor
    local cursorSpeed = 4
    local cursorLen = (ElapsedTime*cursorSpeed%2)//1 --a number that regularly alternates between 0 and 1 
    local underCursor = string.sub(lines[#lines].str, cursorPos, cursorPos) or " "
    local cursor=string.rep("\u{258A}", cursorLen)..string.rep(underCursor, 1-cursorLen) --cursor symbol..empty cursor symbol. The empty symbol is necessary otherwise the cursor blinking will push a word past the word wrap limit if you're at the end of a line. One of the disadvantages of a text-based cursor 25ae
    
    local y = HEIGHT
    pushStyle()
    setStyle()
    for i,v in ipairs(lines) do
        local out = v.str
        if i==#lines then
            out = beforeCursor..cursor..string.sub(afterCursor, 2) --string.insert( out, cursor, cursorPos)
        end
        local indent = string.rep("> ", v.level)
        local w,h = textSize(indent..out)
        y = y - h
        
        text(indent..out, margin, y)
    end
    --scroll screen
    targety = math.max(0, typeWriter+40-y) 
    screeny = screeny + (targety - screeny) * 0.1 
    --buttons and autocomplete
    popMatrix()
    fill(128,255)
    fontSize(buttonSize)
    for i,v in ipairs(buttons) do
        v:draw()
    end
    for i,v in ipairs(auto) do
        text(v.str, v.x, typeWriter+30)
    end
    popStyle() 
end

function touched(t)
    if t.state==BEGAN then
        if t.y>typeWriter+30 and t.y<typeWriter+60 then --button / autocomplete row
            
            for i,v in ipairs(auto) do
                if t.x>v.x and t.x<v.x+v.w then
                    
                    local word  = string.match(beforeCursor, "(.-[^_%w]?)[%w_]*$") or ""
                    
                    lines[#lines].str = word..v.str..afterCursor --remove partial word and add autocomplete string
                    moveCursor( cursorPos + (string.len(word..v.str)-string.len(beforeCursor)))
                    auto = {}
                    return
                end
            end
        elseif t.y>typeWriter and t.y<typeWriter+30 then --button
            for i,v in ipairs(buttons) do
                if t.x>v.x and t.x<v.x+v.w then
                    v:touched()
                end
            end
            
        else --check text
            textTouch = {id=t.id, x=t.x, cursor=cursorPos}
        end
    elseif t.state == MOVING then
        if textTouch and t.id == textTouch.id then
            moveCursor(textTouch.cursor + (t.x-textTouch.x)//10)
        end
    elseif t.state == ENDED then
        if textTouch and t.id == textTouch.id then
            textTouch = nil
        end
        if t.tapCount == 1 and not isKeyboardShowing() then
            showKeyboard()
            orientationChanged(CurrentOrientation)
        end
    end
end

function moveCursor(pos)
    cursorPos = math.clamp(pos, 1, string.len(lines[#lines].str)+1)
    beforeCursor = string.sub(lines[#lines].str, 1, cursorPos-1)
    afterCursor = string.sub(lines[#lines].str, cursorPos)
end

local blockStart = {"function", "if", "do", "repeat"} --terms that initiate a code block. Because "for" and "while" statements end in "do", we can just check for them with "do"

function keyboard(key)
    if key == RETURN then
        lines[#lines].str = lines[#lines].str.." " --add space to end to stand for newline (and later to start of string) to check for discrete words
        --check for block start
        for _,keyword in ipairs(blockStart) do
            if string.match(" "..lines[#lines].str, "[^_%w]"..keyword.."[^_%w]") then --terms separated by "not an underscore or an alphanumeric"
                if level==1 then codeBlock = {} end --initiate block
                level = level + 1
            end
        end
        --check for block end
        if string.match(" "..lines[#lines].str, "[^_%w]end[^_%w]") or string.match(" "..lines[#lines].str, "[^_%w]until[^_%w]") then
            level = math.max(level - 1, 1)
            lines[#lines].level = level
        end
        if codeBlock then codeBlock[#codeBlock+1]=lines[#lines].str end --add to block
        --interpret
        if level == 1 then
            if codeBlock then
                interpret(table.concat(codeBlock)) --interpret block
                codeBlock=nil
            else
                interpret(lines[#lines].str) --interpret just this line
            end
        end
        lines[#lines+1]={level=level, str=""} --newline
        auto={}
        moveCursor(1)
    elseif key == BACKSPACE then
        lines[#lines].str=string.sub(beforeCursor, 1, -2)..afterCursor
        moveCursor(cursorPos - 1)
        populateAutocomplete()
    else
        lines[#lines].str = string.insert(lines[#lines].str, key, cursorPos)
        moveCursor(cursorPos + 1)
        populateAutocomplete()
    end
end

function orientationChanged(o)
     margin = WIDTH * 0.1
    textWrapWidth(WIDTH - (margin*2))
    if o==PORTRAIT or o==PORTRAIT_UPSIDE_DOWN then
        typeWriter = HEIGHT * 0.27
    else
        typeWriter = HEIGHT * 0.47
    end
end

function string.insert(str, insert, place)
    local place = place or string.len(str)+1
    return string.sub(str, 1,place-1) .. tostring(insert) .. string.sub(str, place)
end

function math.sign(x)
    return (x<0 and -1) or 1
end

function math.clamp(v,low,high)
    return math.min(math.max(v, low), high)
end

--sandbox 
function null() end

local saveTab = saveProjectTab()

saveProjectTab = null

--# Button
Button = class()

buttonSize = 20

function Button:init(str)
    pushStyle()
    fontSize(buttonSize)
    local buttonText = " "..str.." "
    local w,_ = textSize(buttonText)
    popStyle()
    self.str = str
    self.text = buttonText
    self.x = buttonX
    self.w = w
    buttonX = buttonX + w
end

function Button:draw()
    text(self.text, self.x, typeWriter)
end

function Button:touched(touch)
    lines[#lines].str = string.insert(lines[#lines].str, self.str, cursorPos)
    moveCursor (cursorPos + 1)
    auto={}
end

