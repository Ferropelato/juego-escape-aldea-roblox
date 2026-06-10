local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MonetizationConfig = require(Shared.Config.MonetizationConfig)

local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local NotificationService = require(script.Parent.NotificationService)
local ChallengeService = require(script.Parent.ChallengeService)

local MonetizationService = {}

function MonetizationService._ensureEntitlements(data)
	data.entitlements = data.entitlements or { vip = false, trails = false }
	data.cosmetics = data.cosmetics or { activeTrail = "none" }
	data.reviveTokens = data.reviveTokens or 0
	data.supporterBadge = data.supporterBadge or false
end

function MonetizationService.refreshEntitlements(player: Player)
	local data = DataService.get(player)
	MonetizationService._ensureEntitlements(data)

	local vipPass = MonetizationConfig.Gamepasses.VipExplorer
	local trailPass = MonetizationConfig.Gamepasses.TrailMaster

	if vipPass.gamePassId > 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, vipPass.gamePassId)
		end)
		data.entitlements.vip = ok and owns or false
	else
		data.entitlements.vip = false
	end

	if trailPass.gamePassId > 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, trailPass.gamePassId)
		end)
		data.entitlements.trails = ok and owns or false
	else
		data.entitlements.trails = false
	end

	if data.entitlements.vip and data.cosmetics.activeTrail == "none" then
		data.cosmetics.activeTrail = "gold"
	end

	ChallengeService.syncToClient(player)
end

function MonetizationService.hasVip(player: Player): boolean
	local data = DataService.get(player)
	MonetizationService._ensureEntitlements(data)
	return data.entitlements.vip == true
end

function MonetizationService.getRespawnCooldown(player: Player): number
	if MonetizationService.hasVip(player) then
		return MonetizationConfig.RESPAWN_COOLDOWN_VIP
	end
	return MonetizationConfig.RESPAWN_COOLDOWN_DEFAULT
end

function MonetizationService.canUseTrail(player: Player, trailId: string): boolean
	local trail = MonetizationConfig.Trails[trailId]
	if not trail or trailId == "none" then
		return true
	end

	local data = DataService.get(player)
	MonetizationService._ensureEntitlements(data)

	if trail.requires == "vip_or_trails" then
		return data.entitlements.vip or data.entitlements.trails
	end
	if trail.requires == "trails" then
		return data.entitlements.trails or data.entitlements.vip
	end
	return false
end

function MonetizationService.setCosmetic(player: Player, trailId: string): boolean
	if type(trailId) ~= "string" or not MonetizationConfig.Trails[trailId] then
		return false
	end
	if trailId ~= "none" and not MonetizationService.canUseTrail(player, trailId) then
		NotificationService.send(player, "Rastro bloqueado — conseguilo en la tienda", "error")
		return false
	end

	local data = DataService.get(player)
	MonetizationService._ensureEntitlements(data)
	data.cosmetics.activeTrail = trailId
	DataService.save(player)
	ChallengeService.syncToClient(player)
	return true
end

function MonetizationService.tryUseReviveToken(player: Player): boolean
	local data = DataService.get(player)
	MonetizationService._ensureEntitlements(data)
	if (data.reviveTokens or 0) <= 0 then
		return false
	end
	data.reviveTokens -= 1
	DataService.save(player)
	ChallengeService.syncToClient(player)
	NotificationService.send(player, "Token de rescate usado ⚡", "info")
	return true
end

function MonetizationService._grantProduct(player: Player, productCfg: any): boolean
	local data = DataService.get(player)
	MonetizationService._ensureEntitlements(data)

	if productCfg.rewards then
		for resourceId, amount in productCfg.rewards do
			InventoryService.addResource(player, resourceId, amount)
		end
	end
	if productCfg.reviveTokens then
		data.reviveTokens = (data.reviveTokens or 0) + productCfg.reviveTokens
	end
	if productCfg.grantsSupporter then
		data.supporterBadge = true
	end

	DataService.save(player)
	ChallengeService.syncToClient(player)
	NotificationService.send(player, "¡Compra recibida: " .. productCfg.displayName .. "!", "success")
	return true
end

function MonetizationService.processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productCfg = MonetizationConfig.getProductById(receiptInfo.ProductId)
	if not productCfg then
		warn("[EscapeIsland] Producto desconocido:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok = MonetizationService._grantProduct(player, productCfg)
	if ok then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.init()
	MarketplaceService.ProcessReceipt = MonetizationService.processReceipt

	Players.PlayerAdded:Connect(function(player)
		task.delay(2, function()
			if player.Parent then
				MonetizationService.refreshEntitlements(player)
			end
		end)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			MonetizationService.refreshEntitlements(player)
		end)
	end
end

return MonetizationService
