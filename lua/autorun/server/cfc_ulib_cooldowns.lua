
-- { amount = int, decayRate = int }
-- using a commands adds to its counter if this counter is greater than `amount` you can no longer run the command
-- 1 is subtracted from the counter every `decayRate` seconds
local ULIB_COOLDOWNS = {
    ["default"]       = {amount=3, decayRate=2},
    ["ulx ragdoll"]   = {amount=2, decayRate=5},
    ["ulx unragdoll"] = {amount=2, decayRate=5},
}

local RANK_OVERRIDES = {
    moderator = {
        exempt = true
    },
}

-- stores the actual cooldown counters
local playerCooldowns = {}

local function getRankName( ply ) 
    return team.GetName( ply:Team() )
end

local function getCooldownConfig( ply, commandName )
    local overrides = RANK_OVERRIDES[getRankName( ply )]

    if overrides and overrides[commandName] then return overrides[commandName] end
    
    return ULIB_COOLDOWNS[commandName] or ULIB_COOLDOWNS.default
end

local function isExempt( ply, commandName )
    if ply:IsAdmin() then return true end
    local overrides = RANK_OVERRIDES[getRankName( ply )]

    if overrides and overrides.exempt then return true end
    return false
end

local function getCooldownTable( ply, commandName )
    local cooldowns = playerCooldowns[ply] or {}
    playerCooldowns[ply] = cooldowns

    local cooldown = cooldowns[commandName] or {lastRun = 0, count = 0}
    cooldowns[commandName] = cooldown

    return cooldown
end

local function canRun( ply, commandName )
    local conf = getCooldownConfig( ply, commandName )
    if not conf then return true end

    local cooldown = getCooldownTable( ply, commandName )

    local timeSince = CurTime() - cooldown.lastRun
    cooldown.count = cooldown.count - math.floor( timeSince / conf.decayRate)
    cooldown.count = math.max( 0, cooldown.count )

    if cooldown.count >= conf.amount then
        return false
    end

    return true
end

local function newUsage( ply, commandName )
    local conf = getCooldownConfig( ply, commandName )
    if not conf then return end
    local cooldown = getCooldownTable( ply, commandName )

    cooldown.lastRun = CurTime()
    cooldown.count = cooldown.count + 1
end

hook.Add( "ULibPostTranslatedCommand", "CFC_UlibCooldowns_PostTranslate", function( ply, commandName, translatedArgs)
    if isExempt( ply, commandName ) then return end
    newUsage( ply, commandName )
end ) 

hook.Add( "ULibCommandCalled", "CFC_UlibCooldowns_Called", function( ply, commandName, args )
    if isExempt( ply, commandName ) then return end
    
    if not canRun( ply, commandName ) then 
        ULib.tsayError( ply, "You are using this command too much", true)
        return false, "This command is on cooldown" 
    end
end )
