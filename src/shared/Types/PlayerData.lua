export type Inventory = { [string]: number }
export type CraftedItems = { [string]: boolean }
export type CompletedChallenges = { [string]: boolean }
export type UnlockedIslands = { [string]: boolean }

export type Achievements = { [string]: boolean }

export type Entitlements = {
	vip: boolean,
	trails: boolean,
}

export type Cosmetics = {
	activeTrail: string,
}

export type PlayerSaveData = {
	currentIsland: string,
	currentChallenge: string,
	lastCheckpoint: string?,
	lastCheckpointPosition: Vector3?,
	inventory: Inventory,
	craftedItems: CraftedItems,
	completedChallenges: CompletedChallenges,
	unlockedIslands: UnlockedIslands,
	achievements: Achievements,
	onboardingStep: number,
	onboardingDone: boolean,
	entitlements: Entitlements,
	cosmetics: Cosmetics,
	reviveTokens: number,
	supporterBadge: boolean,
	lastDailyClaim: number,
	loginStreak: number,
	totalPlayTime: number,
}

local PlayerData = {}

function PlayerData.getDefault(): PlayerSaveData
	return {
		currentIsland = "Island1_Tropical",
		currentChallenge = "BeachLanding",
		lastCheckpoint = "CP_Beach",
		lastCheckpointPosition = nil,
		inventory = {},
		craftedItems = {},
		completedChallenges = {},
		unlockedIslands = {
			Island1_Tropical = true,
			Island2_Frozen = false,
			Island3_Desert = false,
		},
		achievements = {},
		onboardingStep = 0,
		onboardingDone = false,
		entitlements = { vip = false, trails = false },
		cosmetics = { activeTrail = "none" },
		reviveTokens = 0,
		supporterBadge = false,
		lastDailyClaim = 0,
		loginStreak = 0,
		totalPlayTime = 0,
	}
end

function PlayerData.serializeForClient(data: PlayerSaveData)
	local pos = data.lastCheckpointPosition
	return {
		currentIsland = data.currentIsland,
		currentChallenge = data.currentChallenge,
		lastCheckpoint = data.lastCheckpoint,
		lastCheckpointPosition = pos and { pos.X, pos.Y, pos.Z } or nil,
		inventory = data.inventory,
		craftedItems = data.craftedItems,
		completedChallenges = data.completedChallenges,
		unlockedIslands = data.unlockedIslands,
		achievements = data.achievements,
		onboardingStep = data.onboardingStep,
		onboardingDone = data.onboardingDone,
		entitlements = data.entitlements or { vip = false, trails = false },
		cosmetics = data.cosmetics or { activeTrail = "none" },
		reviveTokens = data.reviveTokens or 0,
		supporterBadge = data.supporterBadge or false,
		lastDailyClaim = data.lastDailyClaim or 0,
		loginStreak = data.loginStreak or 0,
		totalPlayTime = data.totalPlayTime,
	}
end

return PlayerData
