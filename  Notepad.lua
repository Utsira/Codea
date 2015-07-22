--# Main
-- Notepad
-- by Yojimbo2000

displayMode(FULLSCREEN)

function setup()
    inkey=[[Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eget hendrerit ligula. Quisque vitae mauris aliquet risus efficitur hendrerit at nec quam. Nulla ut sollicitudin dolor, ut interdum nulla. Quisque malesuada fermentum erat vitae mattis. Suspendisse vitae cursus purus, sit amet dictum risus.

    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eget hendrerit ligula. Quisque vitae mauris aliquet risus efficitur hendrerit at nec quam. Nulla ut sollicitudin dolor, ut interdum nulla. Quisque malesuada fermentum erat vitae mattis. Suspendisse vitae cursus purus, sit amet dictum risus.]]
    
    --All the blue commands! Just kidding, it's our drawing.
    
    font("BradleyHandITCTT-Bold")
    fill(31, 31, 88, 255) --our ink
    fontSize(30)
    strokeWidth(1)
    textMode(CORNER) 
    showKeyboard()
    
    --measure the screen, derive borders
    metrics(CurrentOrientation)
    
    --measure the font
    local fon = fontMetrics()
    for k,v in pairs(fon) do
        print(k,v)
    end  
    ascent = fon.ascent
    descent = fon.descent
    size = ascent + descent
    --variables for screen scrolling
    screeny, targety = -100,0
    --parameter.watch("h") --nb text blocks taller than 1024 dont display
end

function metrics(orientation)
    width = WIDTH*0.8
    textWrapWidth(width)
    border = HEIGHT - 50
    pos = vec2((WIDTH - width)*0.5, HEIGHT*0.5)
    if orientation==PORTRAIT or orientation==PORTRAIT_UPSIDE_DOWN then
        typeWriter = HEIGHT * 0.3 --the height at which we want the last line to stay at, to prevent what we're typing disappearing off the page, or being covered by the keyboard
    else
         typeWriter = HEIGHT * 0.45 --keyboard takes up more space in landscape
    end
end

function draw()
    background(223, 215, 165, 255) --the colour of a creamy solarized legal pad, pregnant with possibilities
    
    --cursor
    local cursorSpeed = 4
    local cursorLen = (ElapsedTime*cursorSpeed%2)//1 --a number that regularly alternates between 0 and 1 
    local cursor=string.rep("\u{25ae}", cursorLen)..string.rep("\u{25af}", 1-cursorLen) --cursor symbol..empty cursor symbol. The empty symbol is necessary otherwise the cursor blinking will push a word past the word wrap limit if you're at the end of a line. One of the disadvantages of a text-based cursor
    
    --Establish y pos of text and scroll the screen/ move the camera accordingly
    local w,h = textSize(inkey..cursor)
    pos.y = border - h
    targety = math.max(0, typeWriter-pos.y)
    screeny = screeny + (targety - screeny) * 0.1
    translate(0,screeny)
    
    --draw lines
    for y = border-ascent, pos.y, - size do
        stroke(39, 26, 26, 128)
        line(pos.x-10,y,pos.x+width+10,y) --line that text "sits on"
        stroke(68, 50, 50, 48)
        line(pos.x-10,y-descent,pos.x+width+10,y-descent) --separator between ascendors and descendors     
    end

    text(inkey..cursor, pos.x, pos.y)  
end

--The three built-in user-input functions that Codea ships with:

function keyboard(key)
    if key==BACKSPACE then
        inkey=string.sub(inkey, 1, -2)
    else
        inkey=inkey..key
    end
end

function touched(t)
    if t.state==BEGAN then --toggle keyboard
        if isKeyboardShowing() then hideKeyboard() else showKeyboard() end
    end
end

function orientationChanged(orientation)
    metrics(orientation) --re-measure width, height
end

