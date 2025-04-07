local WebhookModule = {}
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

WebhookModule.Config = {
    UpdateInterval = 300,
    MaxRetries = 3,
    Debug = false,
}

local playerWebhooks = {}
local initialStats = {}
local lastStats = {}

local function getPlayerStats(player)
    local stats = {
        Strength = 0,
        Rebirths = 0,
        Kills = 0,
        Brawls = 0
    }
    
    if player and player:FindFirstChild("leaderstats") then
        local leaderstats = player.leaderstats
        
        if leaderstats:FindFirstChild("Strength") then
            stats.Strength = leaderstats.Strength.Value
        end
        
        if leaderstats:FindFirstChild("Rebirths") then
            stats.Rebirths = leaderstats.Rebirths.Value
        end
        
        if leaderstats:FindFirstChild("Kills") then
            stats.Kills = leaderstats.Kills.Value
        end
        
        if leaderstats:FindFirstChild("Brawls") then
            stats.Brawls = leaderstats.Brawls.Value
        end
    end
    
    return stats
end

local function getStatDifferences(player)
    local currentStats = getPlayerStats(player)
    local initial = initialStats[player.UserId] or currentStats
    local last = lastStats[player.UserId] or initial
    
    local diff = {
        Strength = currentStats.Strength - last.Strength,
        Rebirths = currentStats.Rebirths - last.Rebirths,
        Kills = currentStats.Kills - last.Kills,
        Brawls = currentStats.Brawls - last.Brawls,
        
        TotalStrength = currentStats.Strength - initial.Strength,
        TotalRebirths = currentStats.Rebirths - initial.Rebirths,
        TotalKills = currentStats.Kills - initial.Kills,
        TotalBrawls = currentStats.Brawls - initial.Brawls,
        
        Current = currentStats
    }
    
    lastStats[player.UserId] = currentStats
    
    return diff
end

local function formatWebhookMessage(player, statDiff)
    local current = statDiff.Current
    
    local embed = {
        title = player.DisplayName .. "'s Stats Update",
        description = "Stats tracking for " .. player.Name,
        color = 3447003,
        thumbnail = {
            url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
        },
        fields = {
            {
                name = "Strength",
                value = "Current: " .. current.Strength .. "\nGained: +" .. statDiff.Strength .. "\nTotal Gained: +" .. statDiff.TotalStrength,
                inline = true
            },
            {
                name = "Rebirths",
                value = "Current: " .. current.Rebirths .. "\nGained: +" .. statDiff.Rebirths .. "\nTotal Gained: +" .. statDiff.TotalRebirths,
                inline = true
            },
            {
                name = "Kills",
                value = "Current: " .. current.Kills .. "\nGained: +" .. statDiff.Kills .. "\nTotal Gained: +" .. statDiff.TotalKills,
                inline = true
            },
            {
                name = "Brawls",
                value = "Current: " .. current.Brawls .. "\nGained: +" .. statDiff.Brawls .. "\nTotal Gained: +" .. statDiff.TotalBrawls,
                inline = true
            }
        },
        footer = {
            text = "Last Updated: " .. os.date("%Y-%m-%d %H:%M:%S")
        }
    }
    
    if statDiff.Strength == 0 and statDiff.Rebirths == 0 and statDiff.Kills == 0 and statDiff.Brawls == 0 then
        if WebhookModule.Config.Debug then
            embed.description = "No changes since last update"
            embed.color = 10066329
        else
            return nil
        end
    end
    
    return {
        content = nil,
        embeds = {embed}
    }
end

local function sendWebhook(url, data)
    if not url or url == "" then return false end
    
    local success = false
    local attempts = 0
    
    while not success and attempts < WebhookModule.Config.MaxRetries do
        attempts = attempts + 1
        
        local ok, result = pcall(function()
            return HttpService:RequestAsync({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        if ok and result.Success then
            success = true
        else
            task.wait(1)
        end
    end
    
    return success
end

function WebhookModule:RegisterWebhook(player, webhookUrl)
    if typeof(webhookUrl) ~= "string" or webhookUrl == "" then
        return false, "Invalid webhook URL"
    end
    
    if not string.match(webhookUrl, "https://discord.com/api/webhooks/") and
       not string.match(webhookUrl, "https://discordapp.com/api/webhooks/") then
        return false, "Invalid Discord webhook URL format"
    end
    
    playerWebhooks[player.UserId] = webhookUrl
    
    initialStats[player.UserId] = getPlayerStats(player)
    lastStats[player.UserId] = initialStats[player.UserId]
    
    local message = {
        content = nil,
        embeds = {
            {
                title = "Stat Tracking Activated",
                description = "Your stat tracking has been set up successfully for " .. player.DisplayName .. " (" .. player.Name .. ")",
                color = 5763719,
                thumbnail = {
                    url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
                },
                footer = {
                    text = "Tracking started: " .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }
        }
    }
    
    local success = sendWebhook(webhookUrl, message)
    return success, success and "Webhook registered successfully" or "Failed to send test webhook"
end

function WebhookModule:UnregisterWebhook(player)
    if playerWebhooks[player.UserId] then
        playerWebhooks[player.UserId] = nil
        initialStats[player.UserId] = nil
        lastStats[player.UserId] = nil
        return true, "Webhook unregistered"
    end
    return false, "No webhook registered for this player"
end

function WebhookModule:UpdatePlayerStats(player)
    local webhookUrl = playerWebhooks[player.UserId]
    if not webhookUrl then return false, "No webhook registered" end
    
    local statDiff = getStatDifferences(player)
    local message = formatWebhookMessage(player, statDiff)
    
    if message then
        local success = sendWebhook(webhookUrl, message)
        return success, success and "Stats updated successfully" or "Failed to send stats update"
    end
    
    return true, "No changes to report"
end

function WebhookModule:StartAutoUpdates()
    spawn(function()
        while true do
            task.wait(WebhookModule.Config.UpdateInterval)
            
            for userId, webhookUrl in pairs(playerWebhooks) do
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    self:UpdatePlayerStats(player)
                end
            end
        end
    end)
end

function WebhookModule:Initialize()
    Players.PlayerRemoving:Connect(function(player)
        if playerWebhooks[player.UserId] then
            self:UpdatePlayerStats(player)
        end
    end)
    
    self:StartAutoUpdates()
    
    return self
end

return WebhookModule:Initialize()
