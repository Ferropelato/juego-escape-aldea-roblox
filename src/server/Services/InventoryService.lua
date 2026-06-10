local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local DataService = require(script.Parent.DataService)

local InventoryService = {}

function InventoryService.addResource(player: Player, resourceId: string, amount: number): boolean
	local config = GameConfig.Resources[resourceId]
	if not config then
		return false
	end

	local data = DataService.get(player)
	data.inventory[resourceId] = (data.inventory[resourceId] or 0) + amount
	local maxStack = config.maxStack or 99
	if data.inventory[resourceId] > maxStack then
		data.inventory[resourceId] = maxStack
	end
	return true
end

function InventoryService.hasResources(player: Player, ingredients: { [string]: number }): boolean
	local data = DataService.get(player)
	for resourceId, needed in ingredients do
		if (data.inventory[resourceId] or 0) < needed then
			return false
		end
	end
	return true
end

function InventoryService.consumeResources(player: Player, ingredients: { [string]: number }): boolean
	if not InventoryService.hasResources(player, ingredients) then
		return false
	end
	local data = DataService.get(player)
	for resourceId, needed in ingredients do
		data.inventory[resourceId] -= needed
		if data.inventory[resourceId] <= 0 then
			data.inventory[resourceId] = nil
		end
	end
	return true
end

return InventoryService
