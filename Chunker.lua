--[[
    OGAddonMsg - Chunker
    Message chunking, reassembly, and hash verification
]]

-- Constants
local MAX_CHUNK_SIZE = 200  -- Conservative limit for SendAddonMessage
local HEADER_OVERHEAD = 30  -- Estimated header size

-- Initialize reassembly buffer
OGAddonMsg.reassembly = {}

--[[
    Message Chunking
]]
local function GenerateMsgId()
    -- Generate unique 4-character message ID
    local chars = "0123456789abcdefghijklmnopqrstuvwxyz"
    local id = ""
    for i = 1, 4 do
        local idx = math.random(1, string.len(chars))
        id = id .. string.sub(chars, idx, idx)
    end
    return id
end

local function ComputeHash(data)
    -- Simple hash for WoW 1.12 (no real CRC available)
    -- This is a placeholder - needs proper implementation
    local hash = 0
    for i = 1, string.len(data) do
        hash = mod(hash + string.byte(data, i) * i, 65536)
    end
    return string.format("%04x", hash)
end

function OGAddonMsg.ChunkMessage(prefix, data)
    -- TODO: Implement chunking algorithm
    -- Returns: msgId, chunks table
    
    local msgId = GenerateMsgId()
    local hash = ComputeHash(data)
    
    -- Calculate available space per chunk
    local prefixSize = string.len(prefix)
    local dataPerChunk = MAX_CHUNK_SIZE - HEADER_OVERHEAD - prefixSize
    
    if string.len(data) <= dataPerChunk then
        -- Single chunk
        local message = string.format("1S%s%s\t%s", msgId, prefix, data)
        return msgId, {message}, false  -- msgId, chunks, isMultiChunk
    end
    
    -- Multi-chunk
    local chunks = {}
    local totalChunks = math.ceil(string.len(data) / dataPerChunk)
    
    for i = 1, totalChunks do
        local startPos = (i - 1) * dataPerChunk + 1
        local endPos = math.min(i * dataPerChunk, string.len(data))
        local chunkData = string.sub(data, startPos, endPos)
        
        local message = string.format("1M%s%02d%02d%s%s\t%s",
            msgId, i, totalChunks, hash, prefix, chunkData)
        
        table.insert(chunks, message)
    end
    
    return msgId, chunks, true  -- msgId, chunks, isMultiChunk
end

--[[
    Message Reassembly
]]
function OGAddonMsg.ProcessIncomingMessage(prefix, message, channel, sender)
    -- TODO: Parse message header and route to handlers
    -- Handle single vs multi-chunk messages
    -- Store chunks in reassembly buffer
    -- Dispatch complete messages to handlers
    
    if OGAddonMsg_Config.debug then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("OGAddonMsg: RX from %s via %s: %s", 
            sender, channel, string.sub(message, 1, 50)), 0.7, 0.7, 1)
    end
    
    -- Update stats
    OGAddonMsg.stats.messagesReceived = OGAddonMsg.stats.messagesReceived + 1
    OGAddonMsg.stats.bytesReceived = OGAddonMsg.stats.bytesReceived + string.len(message)
end

function OGAddonMsg.CleanupReassemblyBuffer()
    -- TODO: Remove incomplete messages that have timed out
    local now = GetTime()
    local timeout = OGAddonMsg_Config.timeout
    
    for msgId, entry in pairs(OGAddonMsg.reassembly) do
        if entry.firstReceived and (now - entry.firstReceived) > timeout then
            -- Timed out
            OGAddonMsg.reassembly[msgId] = nil
            
            if OGAddonMsg_Config.debug then
                DEFAULT_CHAT_FRAME:AddMessage("OGAddonMsg: Message " .. msgId .. " timed out", 1, 0.5, 0)
            end
        end
    end
end
