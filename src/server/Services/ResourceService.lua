local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local PlayerDataModule = require(Shared.Types.PlayerData)

local InventoryService = require(script.Parent.InventoryService)
local ChallengeService = require(script.Parent.ChallengeService)
local ObjectiveService = require(script.Parent.ObjectiveService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ResourceService = {}
local RESOURCE_TAG = "ResourcePickup"
local COOLDOWN: { [string]: number } = {}
local COOLDOWN_TTL = 2 -- segundos antes de que una entrada expire
local _cooldownSize = 0
local _lastCooldownClean = 0

local function cleanExpiredCooldowns()
	local now = tick()
	if now - _lastCooldownClean < 10 then return end -- limpiar cada 10s máximo
	_lastCooldownClean = now
	for k, t in COOLDOWN do
		if now - t > COOLDOWN_TTL then
			COOLDOWN[k] = nil
		end
	end
end

function ResourceService.collect(player: Player, resourceId: string, amount: number?, sourcePart: BasePart?)
	local key = player.UserId .. "_" .. (sourcePart and sourcePart:GetFullName() or resourceId)
	local now = tick()
	if COOLDOWN[key] and now - COOLDOWN[key] < 0.4 then
		return false
	end
	COOLDOWN[key] = now
	cleanExpiredCooldowns()

	if not GameConfig.Resources[resourceId] then
		return false
	end

	local amt = amount or 1
	if not InventoryService.addResource(player, resourceId, amt) then
		return false
	end

	local cfg = GameConfig.Resources[resourceId]
	Remotes.ShowNotification:FireClient(
		player,
		"+" .. amt .. " " .. cfg.displayName .. " → Inventario",
		"resource"
	)

	if sourcePart then
		sourcePart.Transparency = 1
		sourcePart.CanCollide = false
		sourcePart.CanQuery = false
		local prompt = sourcePart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = false
		end
		for _, child in sourcePart:GetChildren() do
			if child:IsA("BasePart") then
				child.Transparency = 1
				child.CanCollide = false
			end
		end
	end

	ObjectiveService.onResourceCollected(player, resourceId, amt)
	local AchievementService = require(script.Parent.AchievementService)
	local OnboardingService = require(script.Parent.OnboardingService)
	AchievementService.onResourceCollected(player)
	OnboardingService.onResourceCollected(player)
	ChallengeService.syncToClient(player)
	return true
end

function ResourceService.setupPickup(part: BasePart)
	if not part:GetAttribute("ResourceId") then
		return
	end

	local resourceId = part:GetAttribute("ResourceId")
	local amount = part:GetAttribute("Amount") or 1
	local cfg = GameConfig.Resources[resourceId]

	CollectionService:AddTag(part, RESOURCE_TAG)

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = part
	end
	prompt.ActionText = "Recolectar"
	prompt.ObjectText = cfg and cfg.displayName or resourceId
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	if part:GetAttribute("PickupBound") then
		return
	end
	part:SetAttribute("PickupBound", true)

	prompt.Triggered:Connect(function(triggerPlayer)
		ResourceService.collect(triggerPlayer, resourceId, amount, part)
	end)
end

function ResourceService.initMap(map: Folder)
	for _, desc in map:GetDescendants() do
		if desc:IsA("BasePart") and desc.Name:match("^Resource_") then
			ResourceService.setupPickup(desc)
		end
	end
end

function ResourceService.init()
	for _, part in CollectionService:GetTagged(RESOURCE_TAG) do
		if part:IsA("BasePart") then
			ResourceService.setupPickup(part)
		end
	end
	CollectionService:GetInstanceAddedSignal(RESOURCE_TAG):Connect(function(part)
		if part:IsA("BasePart") then
			ResourceService.setupPickup(part)
		end
	end)

	local Players = game:GetService("Players")
	Players.PlayerRemoving:Connect(function(player)
		local prefix = tostring(player.UserId) .. "_"
		for key in COOLDOWN do
			if key:sub(1, #prefix) == prefix then
				COOLDOWN[key] = nil
			end
		end
	end)
end

return ResourceService
