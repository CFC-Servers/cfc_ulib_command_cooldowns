
-- { amount = int, decayRate = int }
-- using a commands adds to its counter if this counter is greater than `amount` you can no longer run the command
-- 1 is subtracted from the counter every `decayRate` seconds
local ULIB_COOLDOWNS = {
    ["default"]       = {amount=10, decayRate=2},
    ["ulx ragdoll"]   = {amount=2, decayRate=5},
    ["ulx unragdoll"] = {amount=2, decayRate=5},
}

local RANK_OVERRIDES = {
    moderator = {
        exempt = true
    }
}

-- stores the actual cooldown counters
local playerCooldowns = {}

local function maxAmount( ply, commandName )
    return ( ULIB_COOLDOWNS[commandName] or ULIB_COOLDOWNS.default ).amount
end

local function decayRate( ply, commandName )
    return ( ULIB_COOLDOWNS[commandName] or ULIB_COOLDOWNS.default ).decayRate
end

local function cooldownExists( commandName ) 
    if ULIB_COOLDOWNS.default then return true end
    if ULIB_COOLDOWNS[commandName] then return true end

    return false
end

local function isExempt( ply, commandName )
    if ply:IsAdmin() then return true end
    local overrides = RANK_OVERRIDES[getRankName( ply )]
    if not overrides then return false end

    if overrides.exempt then return true end

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
    cooldown.count = cooldown.count - math.floor( timeSince / decayRate( commandName ) )
    cooldown.count = math.max( 0, cooldown.count )

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

hook.Add( "ULibPostTranslatedCommand", "CFC_UlibCooldowns_PostTranslate", function( ply, commandName, translatedArgs)
    if isExempt( ply, commandName ) then return true end
    newUsage( ply, commandName )
end ) 

hook.Add( "ULibCommandCalled", "CFC_UlibCooldowns_Called", function( ply, commandName, args )
    if isExempt( ply, commandName ) then return true end
    
    if not canRun( ply, commandName ) then 
        ULib.tsayError( ply, "You are using this command too much", true)
        return false, "This command is on cooldown" 
    end
end )
