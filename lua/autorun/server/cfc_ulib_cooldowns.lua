
-- { amount = int, decayRate = float }
-- Using a command adds to its counter. If this counter is greater than `amount`, you can no longer run the command
-- 1 is subtracted from the counter every `decayRate` seconds
local ULIB_COOLDOWNS = {
    default = {
        amount = 3,
        decayRate = 2,
    },
    ragdoll = {
        amount = 2,
        decayRate = 5,
    },
    unragdoll = {
        amount = 2,
        decayRate = 5,
    },
}

local function setupConVar( name )
    local cvData = ULIB_COOLDOWNS[name]
    local amountText = name == "default" and "The max number of times most ULX commands can be used by a player within a timeframe. A value of zero means no limit." or
        "The max number of times ulx " .. name .. " can be used by a player within a timeframe. A value of zero means no limit."
    local decayRateText = name == "default" and "The number of seconds it takes for a command's counter to decrease by one." or
        "The number of seconds it takes for ulx " .. name .. "'s counter to decrease by one."

    local amountCV = CreateConVar( "cfc_ulib_cooldowns_" .. name .. "_amount", cvData.amount, FCVAR_NEVER_AS_STRING, amountText .. " (default " .. cvData.amount .. ")", 0, 50000 )
    local decayRateCV = CreateConVar( "cfc_ulib_cooldowns_" .. name .. "_decay", cvData.decayRate, FCVAR_NEVER_AS_STRING, decayRateText .. " (default " .. cvData.decayRate .. ")", 0.001, 50000 )

    if name ~= "default" then
        ULIB_COOLDOWNS[name] = nil
        name = "ulx " .. name
        ULIB_COOLDOWNS[name] = {}
    end

    ULIB_COOLDOWNS[name].amount = amountCV
    ULIB_COOLDOWNS[name].decayRate = decayRateCV
end

for name, _ in pairs( ULIB_COOLDOWNS ) do
    if name:sub( 1, 3 ) == "ulx" then continue end -- pairs() Shouldn't cause this to happen, but for in case the key changing done by setupConVar() fucks things up

    setupConVar( name )
end

local RANK_OVERRIDES = {
    moderator = {
        exempt = true
    },
}

local function getCooldownConfig( ply, commandName )
    local rankName = team.GetName( ply:Team() )
    local overrides = RANK_OVERRIDES[rankName]

    if overrides and overrides[commandName] then return overrides[commandName] end

    return ULIB_COOLDOWNS[commandName] or ULIB_COOLDOWNS.default
end

local function isExempt( ply, commandName )
    local rankName = team.GetName( ply:Team() )
    if ply:IsAdmin() then return true end
    local overrides = RANK_OVERRIDES[rankName]

    if overrides and overrides.exempt then return true end
    return false
end

-- stores the actual cooldown counters
local playerCooldowns = {}


local function getCooldownTable( ply, commandName )
    local cooldowns = playerCooldowns[ply] or {}
    playerCooldowns[ply] = cooldowns

    local cooldown = cooldowns[commandName] or { lastRun = 0, count = 0 }
    cooldowns[commandName] = cooldown

    return cooldown
end


local function canRun( ply, commandName )
    local conf = getCooldownConfig( ply, commandName )
    if not conf then return true end

    local config = {
        amount = conf.amount:GetInt(),
        decayRate = conf.decayRate:GetFloat()
    }

    if config.amount == 0 then return true end

    local cooldown = getCooldownTable( ply, commandName )
    local timeSince = CurTime() - cooldown.lastRun

    cooldown.count = cooldown.count - math.floor( timeSince / config.decayRate )
    cooldown.count = math.max( 0, cooldown.count )

    return cooldown.count < config.amount
end

local function newUsage( ply, commandName )
    local cooldown = getCooldownTable( ply, commandName )

    cooldown.lastRun = CurTime()
    cooldown.count = cooldown.count + 1
end

hook.Add( "ULibPostTranslatedCommand", "CFC_UlibCooldowns_PostTranslate", function( ply, commandName, translatedArgs )
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
