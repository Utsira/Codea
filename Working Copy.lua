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
    --encode commit message
    local commitEncode = urlencode(commitMessage)
    --concatenate project tabs
    local tabNames = listProjectTabs()
    local tabString = ""
    for i,v in ipairs(tabNames) do
        tabString = tabString.."--# "..v.."\n"..readProjectTab(v).."\n\n"
        print(i,v)
    end
    commitURL = urlencode("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&repo=Codea&path="..projectName.."&limit=999&message="..commitEncode) --to chain urls, must be double-encoded
   -- tabString = urlencode(tabString) --if passing code in URL
    pasteboard.copy(tabString) --avoid encoding by placing code in pasteboard
    openURL("working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo=Codea&filename="..projectName..".lua&uti=public.txt&x-success="..commitURL) -- &text="..tabString
    -- working-copy://x-callback-url/commit/?repo=my%20repo&path=&limit=999&message=fix 
    print(projectName.." saved")
end

parameter.text("commitMessage", "")
parameter.action("Push & Commit to Working Copy", saveToWorkingCopy)

function urlencode(str)
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
    function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "%%20") --"+" 
    return str
end

