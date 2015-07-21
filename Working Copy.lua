--# Main
-- Working Copy
--[[
1. Install Working Copy on your iPad 
2. Launch Working Copy and initialise (or clone) a repository called "Codea". In settings, turn on "URL Callbacks" and copy the URL key to the clipboard
3. In Codea, run Working Copy Client and paste the key into the "Working Copy key" text box
4. Make Working Copy Client a dependency of any project you want to push to the Codea repo you just created
5. When you run the project to be pushed, press "Save project to Working Copy" in the sidebar
6. In Working Copy, select the file to overwrite (nb, overwritten with full version control), or select "Save as" if this is the first time you've saved this project. The filename field will automatically be filled with the name of the Codea project (don't change this).

  ]]
function setup()
    parameter.text("workingCopyKey", workingCopyKey, function(v) saveLocalData("workingCopyKey", v) end)
end



--[[


function getstatus(d)
    print(d)
end

function fail(e)
    print(e)
end
  ]]



--# WorkingCopy
workingCopyKey = readLocalData("workingCopyKey", "")
print ("Working Copy key", workingCopyKey)

function saveToWorkingCopy()
    --get project name
    local projectName = urlencode(string.match(readProjectTab("Main"), "^%-%-%s(.-)\n") or "My Project")
    --concatenate project tabs
    local tabNames = listProjectTabs()
    local tabString = ""
    for i,v in ipairs(tabNames) do
        tabString = tabString.."--# "..v.."\n"..readProjectTab(v).."\n\n"
        print(i,v)
    end
   -- tabString = urlencode(tabString) --if passing code in URL
    pasteboard.copy(tabString) --avoid encoding by placing code in pasteboard
    openURL("working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo=Codea&filename="..projectName..".lua&uti=public.txt") --&repo=Codea &text="..tabString
    print(projectName.." saved")
end

parameter.action("Save project to Working Copy", saveToWorkingCopy)

function urlencode(str)
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
    function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "%%20") --"+" 
    return str
end

