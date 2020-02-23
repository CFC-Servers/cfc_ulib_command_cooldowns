
-- { amount = 4, decayRate = 1 }
-- using a commands adds to its counter if this counter is greater than `amount` you can no longer is the command
-- the 1 is subtracted from the counter every `decayRate` seconds
local ULIB_COOLDOWNS = {
    ["ulx ragdoll"] = { amount = 4, decayRate = 1 },
    ["default"] = { amount = 100, decayRate = 1 },
    ["ulx armor"] = { amount = 4, decayRate = 5 },
}


-- stores the actual cooldown counters
local playerCooldowns = {}

local function maxAmount( commandName )
    return (ULIB_COOLDOWNS[commandName] or ULIB_COOLDOWNS.default).amount
end

local function decayRate( commandName )
    return (ULIB_COOLDOWNS[commandName] or ULIB_COOLDOWNS.default).decayRate
end

local function cooldownExists( commandName ) 
    if ULIB_COOLDOWNS.default then return true end
    if ULIB_COOLDOWNS[commandName] then return true end

    return false
end

local function isExempt( ply )
    if ply:IsAdmin() then return true end

    return false
end

local function getCooldownTable( ply, commandName )
    local cooldowns = playerCooldowns[ply]
    if not cooldowns then
        cooldowns = {}
        playerCooldowns[ply] = cooldowns
    end

    local cooldown = cooldowns[commandName]
    if not cooldown then
        cooldown = {lastRun = 0, count = 0}
        cooldowns[commandName] = cooldown
    end

    return cooldown
end

local function canRun( ply, commandName )
    if not cooldownExists( commandName ) then return true end
    local cooldown = getCooldownTable( ply, commandName )

    local timeSince = CurTime() - cooldown.lastRun 
    cooldown.count = cooldown.count - math.floor(timeSince/decayRate(commandName))
    cooldown.count = math.max(0, cooldown.count)

    print(cooldown.count, maxAmount( commandName ))
    if cooldown.count > maxAmount( commandName ) then
        return false
    end

    return true
end

local function newUsage( ply, commandName )
    if not cooldownExists( commandName ) then return end

    local cooldown = getCooldownTable( ply, commandName )

    cooldown.lastRun = CurTime()
    cooldown.count = cooldown.count + 1
end

hook.Add( "ULibPostTranslatedCommand", "CFC_UlibCooldowns_PostTranslate")
hook.Add( "ULibPostTranslatedCommand", "CFC_UlibCooldowns_PostTranslate", function( ply, commandName, translatedArgs)
    newUsage( ply, commandName )
end ) 

hook.Add( "ULibCommandCalled", "CFC_UlibCooldowns_Called")
hook.Add( "ULibCommandCalled", "CFC_UlibCooldowns_Called", function( ply, commandName, args )
    if not canRun( ply, commandName ) then 
        ULib.tsayError( ply, "You are using this command too much", true)
        return false, "This command is on cooldown" 
    end
end )
