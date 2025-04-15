-- Window Integrity Checker for Fluent UI Library
local function createWindowIntegrityChecker()
    -- Valid translations for title
    local validTitles = {
        ["Lurnai - Free Version"] = true,
        ["Lurnai - Version Gratuite"] = true,
        ["Lurnai - Kostenlose Version"] = true,
        ["Lurnai - Versione Gratuita"] = true,
        ["Lurnai - 無料版"] = true,
        ["Lurnai - 무료 버전"] = true,
        ["Lurnai - Versão Gratuita"] = true,
        ["Lurnai - Бесплатная версия"] = true,
        ["Lurnai - Versión Gratuita"] = true,
        ["Lurnai - เวอร์ชันฟรี"] = true
    }

    -- Valid translations for subtitle
    local validSubtitles = {
        ["By Havoc"] = true,
        ["โดย Havoc"] = true,
        ["Por Havoc"] = true,
        ["От Havoc"] = true,
        ["Havoc 제작"] = true,
        ["Havoc制作"] = true,
        ["Di Havoc"] = true,
        ["Von Havoc"] = true,
        ["Par Havoc"] = true
    }

    -- Function to check  integrity
    local function checkWindowIntegrity(window)
        if not window then
            warn("Window object is nil")
            return false
        end
        
        local title = window.Title
        local subtitle = window.SubTitle
        
        if not validTitles[title] then
            warn("Window title has been tampered with: " .. tostring(title))
            return false
        end
        
        if not validSubtitles[subtitle] then
            warn("Window subtitle has been tampered with: " .. tostring(subtitle))
            return false
        end
        
        return true
    end

    local function handleTampering(window, library)
        local isValid = checkWindowIntegrity(window)
        
        if not isValid then
            warn("SECURITY BREACH: Window title or subtitle has been tampered with")
            warn("Current title: " .. tostring(window.Title))
            warn("Current subtitle: " .. tostring(window.SubTitle))
            
            if library then
                library:Notify{
                    Title = "Security Warning",
                    Content = "Unauthorized modification detected. Application will close.",
                    Duration = 5
                }
            end
            
            spawn(function()
                wait(3)
                
                pcall(function()
                    if window and typeof(window) == "table" and window.Destroy then
                        window:Destroy()
                    end
                end)
                
                pcall(function()
                    if game and game.Shutdown then
                        game:Shutdown()
                    end
                end)
            end)
            
            return false
        end
        
        return true
    end

    local function setupPeriodicCheck(window, library, interval)
        interval = interval or 5 

        spawn(function()
            while true do
                if not handleTampering(window, library) then
                    break
                end
                wait(interval)
            end
        end)
    end

    return {
        checkWindowIntegrity = checkWindowIntegrity,
        handleTampering = handleTampering,
        setupPeriodicCheck = setupPeriodicCheck
    }
end

return createWindowIntegrityChecker()
