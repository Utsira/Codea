--# README
--[[

# Working Copy Client

A light Codea client for committing code to Working Copy, a full iOS Git client. The free version supports local Git commits only. To push to a remote host such as GitHub, BitBucket, or your own server, please buy the full version of Working Copy.

## Installation

1. Install Working Copy on your iPad 

2. Set up some repositories in Working Copy to store your code. If you have a remote host on GutHub, BitBucket, your local server etc then you can clone your existing repositories. Otherwise you can initialise local repos on your device, and push them to the remote host later. Give large projects their own repository with the same name as their project name in Codea.[^note1] To store smaller projects that don't need their own repository, set up a repository called "Codea". This will save you having to set up repositories for every single Codea project.

3. In Working Copy settings, turn on "URL Callbacks" and copy the URL key to the clipboard.

4. The first time you run Working Copy Client in Codea, paste this URL key (from step 3) into the "Working Copy key" text box

## Usage

1. In Codea, make Working Copy Client a dependency of any project you want to push to Working Copy 

2. Enter a message describing whatever change you made into the commit text box

3. You now have the choice to "Commit as single file" or as "multiple files":

  - "single file" concatenates your project using Codea's "paste into project" format <--# tab name> and pushes it to the "Codea" repository in Working Copy, naming the file after its Codea project name.[^note1] This is appropriate for smaller projects. To restore a previous version, you can copy the file from Working Copy (share pane > Copy), and in Codea, "paste into project"

  - "multiple file" writes each tab as a separate file into a folder called "tabs" in a repository named after the project[^note1]. You'll get an error message if no repository with that name is found. This is best practice for larger projects. The downside is that there is currently no easy way to restore a multi-file project from Working Copy back to Codea. This could change if Codea gets iOS 8 "open in"/ share pane functionality.  To "pull", you'll currently have to use one of the other Git Codea clients, such as the excellent Codea-SCM.

[^note1]: The project name is found by looking for the "-- <project name>" string that Codea places at the top of the Main tab. Make sure you don't put anything before this in the Main tab

  ]]

--# WorkingCopy
-- Working Copy Client

local workingCopyKey = readLocalData("workingCopyKey", "")
--print ("Working Copy key", workingCopyKey)

local function urlencode(str)
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])", 
        function (c)
            return string.format ("%%%02X", string.byte(c))
        end)
    str = string.gsub (str, " ", "%%20") -- %20 encoding, not + 
    return str
end

local function commitSingleFile()   
    --concatenate project tabs in Codea "paste into project" format and place in pasteboard
    local tabs = listProjectTabs()
    local tabString = ""
    for i,tabName in ipairs(tabs) do
        local tab=readProjectTab(tabName)

        tabString = tabString.."--# "..tabName.."\n"..tab.."\n\n"
        print(i,tabName)
    end
  --  tabString = urlencode(tabString) --encode if passing code in URL, using &text="..tabString
    pasteboard.copy(tabString) --avoid encoding by placing code in pasteboard
    
    --get project name
    local projectName = urlencode(string.match(readProjectTab("Main"), "^%s-%-%-%s-(.-)\n") or "My Project")
    --encode commit message
    local commitEncode = urlencode(commitMessage)
    --build URL chain, starting from end
    local openPageURL = "working-copy://open?repo=Codea&mode=content&path="..projectName
    local commitURL = urlencode("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&repo=Codea&path="..projectName.."&limit=1&message="..commitEncode.."&x-success="..openPageURL) --to chain urls, must be double-encoded. .."&x-success="..openPageURL
    
    local totalURL = "working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo=Codea&path="..projectName..".lua&uti=public.txt&x-success="..commitURL --&text="..tabString..
    openURL(totalURL) 
    print(totalURL)
    print(projectName.." saved")
end

local function commitMultiFile()   
    --get project name
    local projectName = string.match(readProjectTab("Main"), "^%s-%-%-%s-(.-)\n") or "My Project"
    projectName = urlencode(string.gsub(projectName, "%s", ""))
    -- concatenate multiple write commands, one for each tab
    local tabs = listProjectTabs()
    local totalURL = ""
    
    for i,tabName in ipairs(tabs) do
        local tab=readProjectTab(tabName)
        --convert tab README to .md and place in root
        
        if string.find(tabName, "^README") then
            tab=string.match(tab, "^%s-%-%-%[%[(.-)%]%]") --strip out --[[ ]]
            tabName = tabName..".md"
        else  
            tabName = "tabs/"..tabName..".lua"
        end
             
        local newLink = "working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo="..projectName.."&path="..tabName.."&uti=public.txt&text="..urlencode(tab).."&x-success="       
        if i>1 then --from second link onwards, urls must be double-encoded
            newLink = urlencode(newLink)
        end
        print(i,tabName, tab)
        totalURL = totalURL..newLink
    end
       
    --add commit command
    --encode commit message
    local commitEncode = urlencode(commitMessage)
    totalURL = totalURL..urlencode("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&repo="..projectName.."&limit=999&message="..commitEncode) 
        
    openURL(totalURL) 
    print(totalURL)
    print(projectName.." saved")
end


local function commitMultiFile()   
    --get project name
    local projectName = string.match(readProjectTab("Main"), "^%s-%-%-%s-(.-)\n") or "My Project"
    projectName = urlencode(string.gsub(projectName, "%s", ""))
    -- concatenate multiple write commands, one for each tab
    
    --add commit command
    local commitEncode = urlencode(commitMessage)
    local totalURL = "working-copy://x-callback-url/commit/?key="..workingCopyKey.."&repo="..projectName.."&limit=999&message="..commitEncode
    
    local tabs = listProjectTabs()    
    for i=#tabs,1,-1 do
        local tabName = tabs[i]
        local tab=readProjectTab(tabName)
        --convert tab README to .md and place in root
        if string.find(tabName, "^README") then
            tab=string.match(tab, "^%s-%-%-%[%[(.-)%]%]") --strip out --[[ ]]
            tabName = tabName..".md"
        else  
            tabName = "tabs/"..tabName..".lua"
        end
             
        local newLink = "working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo="..projectName.."&path="..tabName.."&uti=public.txt&text="..urlencode(tab).."&x-success="       
   
        print(i,tabName, tab)
        totalURL = newLink..urlencode(totalURL)
    end
        
    openURL(totalURL) 
    print(totalURL)
    print(projectName.." saved")
end


local function WorkingCopyClient()
    parameter.clear()
    parameter.text("commitMessage", "")
    parameter.action("Commit as single file", commitSingleFile)
    parameter.action("Commit as multiple files", commitMultiFile)
    parameter.text("workingCopyKey", workingCopyKey, function(v) saveLocalData("workingCopyKey", v) end)
    parameter.action("Exit Working Copy Client", parameter.clear)
end

parameter.action("Working Copy client", WorkingCopyClient)

--# Main
-- Working Copy Client

function setup()
    
end


