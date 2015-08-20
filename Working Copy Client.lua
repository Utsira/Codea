--# README
--[=[

# Working Copy Client

A light Codea client for committing code to Working Copy, a full iOS Git client. The free version supports local Git commits only. To push to a remote host such as GitHub, BitBucket, or your own server, please buy the full version of Working Copy.

## Installation

1. Install Working Copy on your iPad.

2. Set up some repositories in Working Copy to store your code. If you have a remote host on GutHub, BitBucket, your local server etc then you can clone your existing repositories. Otherwise you can initialise local repos on your device, and push them to the remote host later. Give large projects their own repository with the same name as their project name in Codea.[^note1] To store smaller projects that don't need their own repository, set up a repository called "Codea". This will save you having to set up repositories for every single Codea project.

3. In Working Copy settings, turn on "URL Callbacks" and copy the URL key to the clipboard.

4. The first time you run Working Copy Client in Codea, press the "set up" button and paste this URL key (from step 3) into the "Working Copy key" text box. You can also flick a toggle switch to say where you have bought the remote push IAP. These two settings will be saved in Codea's Global Data, so you'll only need to do this once.

## Usage

1. In Codea, make Working Copy Client a dependency of any project you want to push to Working Copy 

2. The first time you run Working Copy Client within a Codea project, go into Working Copy client set up, and enter:

 a. the repository name that you would like to sync to. There is a button to autopopulate the repository name with the name of the Codea project. This also places the name in the clipboard (in case you haven't actually set up the repository yet, so you can move across to Working Copy and paste the title into the new repo name field).

 b. whether you would like to push this project as a single file in Codea's "paste-into-project" format, or as multiple files:

  - "single file" concatenates your project using Codea's "paste into project" format `--# tab name` and pushes it by default to the "Codea" repository in Working Copy (although you can change the repository name to whatever you like), naming the file after its Codea project name.[^note1] This is appropriate for smaller projects. To restore a previous version, you can copy the file from Working Copy (share pane > Copy), and in Codea, "paste into project"

  - "multiple file" writes each tab as a separate file into a folder called "tabs". It is recommended that you push multiple files to their own repository. Fill in the repository name field, or use the "name repository after project" button to autopopulate it. You'll get an error message if no repository with that name is found. This is best practice for larger projects. The downside is that there is currently no easy way to restore a multi-file project from Working Copy back to Codea. This could change if Codea gets iOS 8 "open in"/ share pane functionality.  To "pull", you'll currently have to use one of the other Git Codea clients, such as the excellent Codea-SCM.

3. Each time you want to save a version, enter Working Copy client from within your Codea project, enter a message describing whatever change you made into the commit text box, and press "commit"

Special bonus feature: if your project has a tab named README with some text surrounded by --\[\[ \]\], Working Copy Client will strip out the braces and save the tab in the root level of the repository with a `.md` extension.

[^note1]: The project name is found by looking for the `-- <project name>` string that Codea places at the top of the Main tab. Make sure you don't put anything before this in the Main tab

  ]=]

--# Main
-- Working Copy Client

function setup()
    
end


--# WorkingCopy
-- Working Copy Client

local workingCopyKey = readGlobalData("workingCopyKey", "")
local workingCopyPushIAP = readGlobalData("workingCopyPushIAP", false)
local workingCopyRepoName = readLocalData("workingCopyRepoName", "Codea")
local workingCopySingleFile = readLocalData("workingCopySingleFile", true)
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

local function concatURL(url1, url2, sep)
    local sep = sep or "&x-success="
    return url1..sep..urlencode(url2) --to chain urls, must be double-encoded.
end

local function createCommitURL(repo, limit, path)
    if path then path = "&path="..path..".lua" else path = "" end
    local commitURL= "working-copy://x-callback-url/commit/?key="..workingCopyKey.."&repo="..repo..path.."&limit="..limit.."&message="..urlencode(commitMessage)
    
    if workingCopyPushIAP then --add push command
        commitURL = concatURL(commitURL, "working-copy://x-callback-url/push/?key="..workingCopyKey.."&repo="..repo)
    end
    return commitURL
end

local function createWriteURL(repo, path, txt)
    return "working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo="..repo.."&path="..path.."&uti=public.txt&text="..urlencode(txt)    --the write command
end
--Single file, to Codea repository
local function commitSingleFile()   
    --concatenate project tabs in Codea "paste into project" format and place in pasteboard
    local tabs = listProjectTabs()
    local tabString = ""
    for i,tabName in ipairs(tabs) do
        tabString = tabString.."--# "..tabName.."\n"..readProjectTab(tabName).."\n\n"
        print(i,tabName)
    end
    
    --get project name
    local projectName = urlencode(string.match(readProjectTab("Main"), "^%s*%-%-%s*(.-)\n") or "My Project")
    
    --build URL chain, starting from end
    local commitURL = createCommitURL(workingCopyRepoName, 1, projectName)   
    local writeURL = createWriteURL(workingCopyRepoName, projectName..".lua", tabString) --"working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo=Codea&path="..projectName..".lua&uti=public.txt&text="..urlencode(tabString)
    openURL(concatURL(writeURL, commitURL)) 
    print(projectName.." saved")
end

local function readProjectFile(project, name, warn)
    local path = os.getenv("HOME") .. "/Documents/"
    local file = io.open(path .. project .. ".codea/" .. name,"r")
    if file then
        local plist = file:read("*all")
        file:close()
        return plist
    elseif warn then
        print("WARNING: unable to read " .. name)
    end
end

local function readProjectPlist(project)
    return readProjectFile(project, "Info.plist", true)
end

--multi-file, to dedicated repository
local function commitMultiFile()   
    --get project name
    local projectName = string.match(readProjectTab("Main"), "^%s*%-%-%s*(.-)\n") or "My Project"
    
    --get plist file with tabOrder
    local plist = readProjectPlist(projectName)
    print(plist)
    -- build URL, starting from the end of the chain    
     projectName = urlencode(string.gsub(projectName, "%s", ""))  
    
    local totalURL = concatURL(createWriteURL(workingCopyRepoName, "Info.plist", plist), createCommitURL(workingCopyRepoName, 999))
    print(totalURL)
    local tabs = listProjectTabs() --get project tab names
    for i=#tabs,1,-1 do --iterate through in reverse order
        local tabName = tabs[i]
        local tab=readProjectTab(tabName)
        --convert tab README to .md and place in root
        if string.find(tabName, "^README") then
            tab=string.match(tab, "^%s-%-%-%[=-%[(.-)%]=-%]") --strip out --[[ ]], --[=[, ]=]
            tabName = tabName..".md"
        else  --place in folder tabs
            tabName = "tabs/"..tabName..".lua"
        end
             
        local newLink = createWriteURL(workingCopyRepoName, tabName, tab) --"working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo="..projectName.."&path="..tabName.."&uti=public.txt&text="..urlencode(tab)    --the write command
       
        totalURL = concatURL(newLink, totalURL) --each link in chain has to be re-encoded
        print(i,tabName, totalURL)
    end
        
    openURL(totalURL) 

    print(workingCopyRepoName.." saved")
end

local function WorkingCopyClient()
    local function WorkingCopySettings()
        parameter.clear()
        output.clear()
        print([[
    SET UP
    ======
    1. In Working Copy settings, turn on "URL Callbacks" and copy the URL key to the clipboard. Paste the key into the workingCopyKey box. 
    2. If you have bought the push IAP in Working Copy (recommended), set workingCopyPushIAP to true. This enables to sync the local repositories on your iPad with remote hosts on GitHub, BitBucket, your computer etc.]]
        )
        parameter.text("workingCopyKey", workingCopyKey, function(v) saveGlobalData("workingCopyKey", v) end)
        parameter.boolean("workingCopyPushIAP", workingCopyPushIAP, function(v) saveGlobalData("workingCopyPushIAP", v) end)
        parameter.boolean("Save_this_project_as_single_file", workingCopySingleFile, function(v) saveLocalData("workingCopySingleFile", v) end)
        parameter.text("Repository_name", workingCopyRepoName, function(v) saveLocalData("workingCopyRepoName", v) end)
        parameter.action("Set repo name to project name", function()
            local projectName = string.match(readProjectTab("Main"), "^%s*%-%-%s*(.-)\n") or "MyProject"
            projectName = string.gsub(projectName, "%s", "")
            Repository_name = projectName
            saveLocalData("workingCopyRepoName", projectName)
            pasteboard.copy(projectName)
            Save_this_project_as_single_file=false
            saveLocalData("workingCopySingleFile", false)
            print ("Repository name is now in clipboard")
        end)
        parameter.action("Return", WorkingCopyClient)
    end
    parameter.clear()
    parameter.text("commitMessage", "")
    parameter.action("Commit", 
        function()
            if workingCopySingleFile then
                commitSingleFile()
            else
                commitMultiFile()
            end
        end)
    parameter.action("Set up", WorkingCopySettings)
    parameter.action("Exit Working Copy Client", parameter.clear)
end

parameter.action("Working Copy client", WorkingCopyClient)

