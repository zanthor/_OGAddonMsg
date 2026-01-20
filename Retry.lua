--[[
    OGAddonMsg - Retry
    Retry buffer management and self-healing
]]

-- Initialize retry buffer
OGAddonMsg.retryBuffer = {}

--[[
    Retry Buffer Management
]]
function OGAddonMsg.StoreForRetry(msgId, chunks)
    -- Store chunks for potential retry
    local now = GetTime()
    local retainTime = OGAddonMsg_Config.retainTime
    
    OGAddonMsg.retryBuffer[msgId] = {
        chunks = chunks,
        sentTime = now,
        expiresAt = now + retainTime
    }
    
    if OGAddonMsg_Config.debug then
        DEFAULT_CHAT_FRAME:AddMessage(
            string.format("OGAddonMsg: Stored %s for retry (%d chunks)", msgId, table.getn(chunks)),
            0.5, 0.5, 1
        )
    end
end

function OGAddonMsg.OnRetryRequest(sender, msgId, missingChunks)
    -- TODO: Handle retry request from receiver
    -- Re-enqueue requested chunks with HIGH priority
    
    local entry = OGAddonMsg.retryBuffer[msgId]
    
    if not entry then
        DEFAULT_CHAT_FRAME:AddMessage(
            "OGAddonMsg: Retry request for expired message from " .. sender,
            1, 1, 0
        )
        return
    end
    
    -- Re-enqueue chunks (implementation pending)
    if OGAddonMsg_Config.debug then
        DEFAULT_CHAT_FRAME:AddMessage(
            string.format("OGAddonMsg: Honoring retry request from %s for %s", sender, msgId),
            0.5, 1, 0.5
        )
    end
    
    OGAddonMsg.stats.retriesSent = OGAddonMsg.stats.retriesSent + 1
end

function OGAddonMsg.CleanupRetryBuffer()
    -- Remove expired entries
    local now = GetTime()
    
    for msgId, entry in pairs(OGAddonMsg.retryBuffer) do
        if now >= entry.expiresAt then
            OGAddonMsg.retryBuffer[msgId] = nil
            
            if OGAddonMsg_Config.debug then
                DEFAULT_CHAT_FRAME:AddMessage("OGAddonMsg: Expired retry buffer for " .. msgId, 0.7, 0.7, 0.7)
            end
        end
    end
end

--[[
    Self-Healing
]]
function OGAddonMsg.CheckIncompleteMessages()
    -- Called on PLAYER_ENTERING_WORLD
    -- Check reassembly buffer for incomplete messages and request retries
    
    local incomplete = 0
    
    for msgId, entry in pairs(OGAddonMsg.reassembly) do
        if entry.receivedCount < entry.totalChunks then
            incomplete = incomplete + 1
            -- TODO: Send retry request to sender
            
            if OGAddonMsg_Config.debug then
                DEFAULT_CHAT_FRAME:AddMessage(
                    string.format("OGAddonMsg: Requesting retry for incomplete %s (%d/%d chunks)",
                        msgId, entry.receivedCount, entry.totalChunks),
                    1, 1, 0
                )
            end
            
            OGAddonMsg.stats.retriesRequested = OGAddonMsg.stats.retriesRequested + 1
        end
    end
    
    if incomplete > 0 and OGAddonMsg_Config.debug then
        DEFAULT_CHAT_FRAME:AddMessage(
            string.format("OGAddonMsg: Found %d incomplete messages after zone", incomplete),
            1, 1, 0
        )
    end
end
