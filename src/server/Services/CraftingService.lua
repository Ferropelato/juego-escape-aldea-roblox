local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ChallengeService = require(script.Parent.ChallengeService)

local CraftingService = {}

function CraftingService.canCraft(player: Player, recipeId: string): (boolean, string?)
	local recipe = GameConfig.CraftingRecipes[recipeId]
	if not recipe then
		return false, "Receta desconocida"
	end

	local data = DataService.get(player)
	if data.craftedItems[recipeId] then
		return false, "Ya crafteaste esto"
	end

	if not InventoryService.hasResources(player, recipe.ingredients) then
		return false, "Faltan recursos"
	end

	return true, nil
end

function CraftingService.craft(player: Player, recipeId: string): (boolean, string?)
	local can, reason = CraftingService.canCraft(player, recipeId)
	if not can then
		return false, reason
	end

	local recipe = GameConfig.CraftingRecipes[recipeId]
	if not InventoryService.consumeResources(player, recipe.ingredients) then
		return false, "Error al consumir recursos"
	end

	local data = DataService.get(player)
	data.craftedItems[recipeId] = true

	if recipe.unlocksChallenge then
		ChallengeService.unlockChallengeGate(player, recipe.unlocksChallenge)
	end

	local AchievementService = require(script.Parent.AchievementService)
	local OnboardingService = require(script.Parent.OnboardingService)
	AchievementService.onCrafted(player)
	OnboardingService.onCrafted(player)

	return true, recipe.displayName
end

return CraftingService
