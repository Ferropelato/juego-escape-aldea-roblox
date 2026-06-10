export type Inventory = { [string]: number }
export type CraftedItems = { [string]: boolean }
export type CompletedChallenges = { [string]: boolean }
export type UnlockedIslands = { [string]: boolean }

export type PlayerSaveData = {
	currentIsland: string,
	currentChallenge: string,
	lastCheckpoint: string?,
	lastCheckpointPosition: Vector3?,
	inventory: Inventory,
	craftedItems: CraftedItems,
	completedChallenges: CompletedChallenges,
	unlockedIslands: UnlockedIslands,
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
		totalPlayTime = data.totalPlayTime,
	}
end

return PlayerData
