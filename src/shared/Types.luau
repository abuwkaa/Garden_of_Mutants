--!strict
--[[
    Type Definitions
    All custom types used throughout the game
]]

-- Element types
export type Element = "Nature" | "Fire" | "Ice" | "Tech" | "Chaos"

-- Rarity types
export type Rarity = "Common" | "Rare" | "Epic" | "Legendary"

-- Ability slot types
export type AbilitySlot = "Q" | "E" | "R"

-- Pet type roles
export type PetRole = "DPS" | "Tank" | "Support" | "Assassin"

-- Pet stats structure
export type PetStats = {
    hp: number,
    atk: number,
    def: number,
    spd: number,
}

-- Pet abilities structure
export type PetAbilities = {
    Q: string,
    E: string,
    R: string,
}

-- Pet template (static data)
export type PetTemplate = {
    id: string,
    name: string,
    element: Element,
    rarity: Rarity,
    petRole: PetRole,
    baseStats: PetStats,
    abilities: PetAbilities,
    description: string,
}

-- Pet instance (player owned)
export type PetInstance = {
    uid: string,
    templateId: string,
    level: number,
    xp: number,
    genes: {string},
    mutationTier: number,
}

-- Seed template (static data)
export type SeedTemplate = {
    id: string,
    name: string,
    rarity: Rarity,
    element: Element,
    growthTime: number,
    mutationChance: number,
    description: string,
}

-- Seed instance (player owned)
export type SeedInstance = {
    uid: string,
    templateId: string,
    quantity: number?, -- Optional for backward compatibility
}

-- Farm plot
export type PlotData = {
    index: number,
    seedId: string?,
    plantedAt: number?,
    wateredAt: number?,
}

-- Currency structure
export type Currencies = {
    Leaves: number,
    Gems: number,
    PvPTokens: number,
    MutationShards: number,
}

-- Farm data
export type FarmData = {
    plots: {PlotData},
    unlockedBiomes: {string},
}

-- PvP data
export type PvPData = {
    mmr: number,
    rank: string,
    seasonWins: number,
    seasonLosses: number,
}

-- Mutation pity data
export type MutationPityData = {
    attempts: number,
    lastSuccessTier: number,
}

-- Complete player data
export type PlayerData = {
    oderId: number,
    level: number,
    xp: number,
    currencies: Currencies,
    pets: {PetInstance},
    seeds: {SeedInstance},
    equippedPets: {string},
    farm: FarmData,
    pvp: PvPData,
    mutationPity: MutationPityData,
    dailyLoginDay: number,
    lastLoginTime: number,
}

-- Enemy template
export type EnemyTemplate = {
    id: string,
    name: string,
    element: Element,
    baseHp: number,
    baseAtk: number,
    baseSpd: number,
    special: string?,
}

-- Wave data
export type WaveData = {
    waveNumber: number,
    enemies: {string},
    isBoss: boolean,
}

-- Match data for PvP
export type MatchData = {
    matchId: string,
    player1: Player,
    player2: Player,
    startTime: number,
}

return nil
