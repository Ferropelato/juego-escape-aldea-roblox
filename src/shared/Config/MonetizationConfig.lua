--[[
	Monetización ética — cosméticos y QoL, sin pay-to-win.
	Reemplazá los IDs en 0 por los reales del Creator Dashboard al publicar.
]]

local MonetizationConfig = {}

MonetizationConfig.STUDIO_PLACEHOLDER_ID = 0

MonetizationConfig.Gamepasses = {
	VipExplorer = {
		id = "VipExplorer",
		gamePassId = 0,
		priceRobux = 99,
		displayName = "Explorador VIP",
		icon = "⭐",
		description = "Badge VIP, rastro dorado y respawn 1.5s. Sin ventaja en combate ni zonas.",
		perks = { "vip_badge", "gold_trail", "fast_respawn" },
	},
	TrailMaster = {
		id = "TrailMaster",
		gamePassId = 0,
		priceRobux = 79,
		displayName = "Maestro de rastros",
		icon = "✨",
		description = "Desbloquea 4 colores de rastro cosmético para tu personaje.",
		perks = { "trail_pack" },
	},
}

MonetizationConfig.DeveloperProducts = {
	StarterBundle = {
		id = "StarterBundle",
		productId = 0,
		priceRobux = 49,
		displayName = "Pack explorador",
		icon = "🎒",
		description = "Madera×5, Liana×3, Piedra×2. Ayuda inicial — no salta zonas.",
		rewards = { Wood = 5, Vine = 3, Stone = 2 },
	},
	ReviveToken = {
		id = "ReviveToken",
		productId = 0,
		priceRobux = 25,
		displayName = "Token de rescate",
		icon = "💫",
		description = "1 reaparición instantánea (sin esperar cooldown).",
		reviveTokens = 1,
	},
	SupporterBadge = {
		id = "SupporterBadge",
		productId = 0,
		priceRobux = 35,
		displayName = "Badge Supporter",
		icon = "💖",
		description = "Título dorado permanente en tu HUD. ¡Gracias por apoyar!",
		grantsSupporter = true,
	},
}

MonetizationConfig.Trails = {
	none = { displayName = "Sin rastro", color = nil, requires = nil },
	gold = { displayName = "Dorado", color = Color3.fromRGB(255, 200, 50), requires = "vip_or_trails" },
	ocean = { displayName = "Océano", color = Color3.fromRGB(50, 150, 255), requires = "trails" },
	ember = { displayName = "Brasa", color = Color3.fromRGB(255, 100, 40), requires = "trails" },
	frost = { displayName = "Escarcha", color = Color3.fromRGB(180, 230, 255), requires = "trails" },
}

MonetizationConfig.RESPAWN_COOLDOWN_DEFAULT = 3
MonetizationConfig.RESPAWN_COOLDOWN_VIP = 1.5

function MonetizationConfig.getGamepassById(gamePassId: number)
	for _, pass in MonetizationConfig.Gamepasses do
		if pass.gamePassId == gamePassId then
			return pass
		end
	end
	return nil
end

function MonetizationConfig.getProductById(productId: number)
	for _, product in MonetizationConfig.DeveloperProducts do
		if product.productId == productId then
			return product
		end
	end
	return nil
end

return MonetizationConfig
