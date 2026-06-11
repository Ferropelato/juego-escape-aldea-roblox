--[[
	HUD responsive: escala con viewport, soporta landscape mobile y PC.
	UIScale en MainHUD + AnchorPoint en paneles flotantes.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local HudBuilder = {}
local player = Players.LocalPlayer

export type HudRefs = {
	screenGui: ScreenGui,
	mainHud: Frame,
	progressLabel: TextLabel,
	objectivePanel: Frame,
	objectiveList: TextLabel,
	inventoryFrame: ScrollingFrame,
	notificationContainer: Frame,
	craftingPanel: Frame,
	recipeList: ScrollingFrame,
	craftButton: TextButton,
	respawnButton: TextButton,
	islandButton: TextButton,
	achievementButton: TextButton,
	achievementPanel: Frame,
	achievementList: ScrollingFrame,
	achievementCount: TextLabel?,
	onboardingBanner: Frame,
	onboardingTitle: TextLabel,
	onboardingText: TextLabel,
	onboardingStep: TextLabel?,
	onboardingDismiss: TextButton?,
	shopButton: TextButton,
	shopPanel: Frame,
	shopList: ScrollingFrame,
	dailyRewardButton: TextButton?,
	streakLabel: TextLabel?,
}

function HudBuilder.getRefs(): HudRefs?
	local gui = player.PlayerGui:FindFirstChild("EscapeIslandHUD")
	if not gui then return nil end
	local main = gui:FindFirstChild("MainHUD") :: Frame?
	if not main then return nil end
	return {
		screenGui = gui,
		mainHud = main,
		progressLabel = main:FindFirstChild("ProgressLabel") :: TextLabel,
		objectivePanel = main:FindFirstChild("ObjectivePanel") :: Frame,
		objectiveList = main:FindFirstChild("ObjectivePanel") and main.ObjectivePanel:FindFirstChild("ObjList") :: TextLabel,
		inventoryFrame = main:FindFirstChild("BackpackFrame") :: ScrollingFrame,
		notificationContainer = gui:FindFirstChild("NotificationContainer") :: Frame,
		craftingPanel = gui:FindFirstChild("CraftingPanel") :: Frame,
		recipeList = gui:FindFirstChild("CraftingPanel") and gui.CraftingPanel:FindFirstChild("RecipeList") :: ScrollingFrame,
		craftButton = main:FindFirstChild("CraftButton") :: TextButton,
		respawnButton = main:FindFirstChild("RespawnButton") :: TextButton,
		islandButton = main:FindFirstChild("IslandButton") :: TextButton,
		achievementButton = main:FindFirstChild("AchievementButton") :: TextButton,
		achievementPanel = gui:FindFirstChild("AchievementPanel") :: Frame,
		achievementList = gui:FindFirstChild("AchievementPanel") and gui.AchievementPanel:FindFirstChild("AchievementList") :: ScrollingFrame,
		achievementCount = main:FindFirstChild("AchievementCount") :: TextLabel,
		onboardingBanner = gui:FindFirstChild("OnboardingBanner") :: Frame,
		onboardingTitle = gui:FindFirstChild("OnboardingBanner") and gui.OnboardingBanner:FindFirstChild("Title") :: TextLabel,
		onboardingText = gui:FindFirstChild("OnboardingBanner") and gui.OnboardingBanner:FindFirstChild("Text") :: TextLabel,
		onboardingStep = gui:FindFirstChild("OnboardingBanner") and gui.OnboardingBanner:FindFirstChild("StepLabel") :: TextLabel,
		onboardingDismiss = gui:FindFirstChild("OnboardingBanner") and gui.OnboardingBanner:FindFirstChild("Dismiss") :: TextButton,
		shopButton = main:FindFirstChild("ShopButton") :: TextButton,
		shopPanel = gui:FindFirstChild("ShopPanel") :: Frame,
		shopList = gui:FindFirstChild("ShopPanel") and gui.ShopPanel:FindFirstChild("ShopList") :: ScrollingFrame,
		dailyRewardButton = main:FindFirstChild("DailyRewardButton") :: TextButton,
		streakLabel = main:FindFirstChild("StreakLabel") :: TextLabel,
	}
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

-- Detectar si el dispositivo es touch (mobile/tablet)
local isTouch = UserInputService.TouchEnabled
local BTN_H = isTouch and 34 or 28  -- botones más altos en touch

function HudBuilder.ensure(): HudRefs
	local existing = HudBuilder.getRefs()
	if existing then return existing end

	local old = player.PlayerGui:FindFirstChild("GameUI")
	if old and old:IsA("ScreenGui") then old.Enabled = false end

	local gui = Instance.new("ScreenGui")
	gui.Name = "EscapeIslandHUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10
	gui.Parent = player.PlayerGui

	-- ── MainHUD (panel izquierdo fijo) ────────────────────────────
	local HUD_W = 300
	local HUD_H = 368 + (isTouch and 8 or 0)

	local main = Instance.new("Frame")
	main.Name = "MainHUD"
	main.Size = UDim2.new(0, HUD_W, 0, HUD_H)
	main.Position = UDim2.new(0, 12, 0, 12)
	main.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
	main.BackgroundTransparency = 0.08
	main.BorderSizePixel = 0
	main.Parent = gui
	corner(main, 10)

	-- UIScale: escala el MainHUD según el viewport para que quepa en mobile
	local hudScale = Instance.new("UIScale")
	hudScale.Scale = 1
	hudScale.Parent = main

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -12, 0, 26)
	title.Position = UDim2.new(0, 6, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = "🏝️ Escape Island"
	title.TextColor3 = Color3.fromRGB(255, 220, 120)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 17
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = main

	local progress = Instance.new("TextLabel")
	progress.Name = "ProgressLabel"
	progress.Size = UDim2.new(1, -12, 0, 36)
	progress.Position = UDim2.new(0, 6, 0, 32)
	progress.BackgroundTransparency = 1
	progress.Text = "Cargando..."
	progress.TextColor3 = Color3.fromRGB(220, 220, 220)
	progress.Font = Enum.Font.Gotham
	progress.TextSize = 12
	progress.TextWrapped = true
	progress.TextXAlignment = Enum.TextXAlignment.Left
	progress.TextYAlignment = Enum.TextYAlignment.Top
	progress.Parent = main

	local objPanel = Instance.new("Frame")
	objPanel.Name = "ObjectivePanel"
	objPanel.Size = UDim2.new(1, -12, 0, 88)
	objPanel.Position = UDim2.new(0, 6, 0, 72)
	objPanel.BackgroundColor3 = Color3.fromRGB(25, 42, 32)
	objPanel.BackgroundTransparency = 0.15
	objPanel.BorderSizePixel = 0
	objPanel.Parent = main
	corner(objPanel, 6)

	local objTitle = Instance.new("TextLabel")
	objTitle.Name = "ObjTitle"
	objTitle.Size = UDim2.new(1, -8, 0, 18)
	objTitle.Position = UDim2.new(0, 4, 0, 2)
	objTitle.BackgroundTransparency = 1
	objTitle.Text = "📋 Objetivos"
	objTitle.TextColor3 = Color3.fromRGB(255, 230, 140)
	objTitle.Font = Enum.Font.GothamBold
	objTitle.TextSize = 13
	objTitle.TextXAlignment = Enum.TextXAlignment.Left
	objTitle.Parent = objPanel

	local objList = Instance.new("TextLabel")
	objList.Name = "ObjList"
	objList.Size = UDim2.new(1, -8, 1, -22)
	objList.Position = UDim2.new(0, 4, 0, 20)
	objList.BackgroundTransparency = 1
	objList.Text = "—"
	objList.TextColor3 = Color3.new(1, 1, 1)
	objList.Font = Enum.Font.Gotham
	objList.TextSize = 12
	objList.TextWrapped = true
	objList.TextXAlignment = Enum.TextXAlignment.Left
	objList.TextYAlignment = Enum.TextYAlignment.Top
	objList.Parent = objPanel

	local bpLabel = Instance.new("TextLabel")
	bpLabel.Name = "BackpackTitle"
	bpLabel.Size = UDim2.new(1, -12, 0, 20)
	bpLabel.Position = UDim2.new(0, 6, 0, 164)
	bpLabel.BackgroundTransparency = 1
	bpLabel.Text = "🎒 Mochila"
	bpLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	bpLabel.Font = Enum.Font.GothamBold
	bpLabel.TextSize = 14
	bpLabel.TextXAlignment = Enum.TextXAlignment.Left
	bpLabel.Parent = main

	local backpack = Instance.new("ScrollingFrame")
	backpack.Name = "BackpackFrame"
	backpack.Size = UDim2.new(1, -12, 0, 72)
	backpack.Position = UDim2.new(0, 6, 0, 184)
	backpack.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	backpack.BackgroundTransparency = 0.1
	backpack.BorderSizePixel = 0
	backpack.ScrollBarThickness = 5
	backpack.CanvasSize = UDim2.new(0, 0, 0, 80)
	backpack.Parent = main
	corner(backpack, 6)

	-- Fila de botones helper
	local function actionButton(name: string, text: string, x: number, w: number, y: number, color: Color3)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, w, 0, BTN_H)
		btn.Position = UDim2.new(0, x, 0, y)
		btn.BackgroundColor3 = color
		btn.BorderSizePixel = 0
		btn.Text = text
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.Parent = main
		corner(btn, 6)
		return btn
	end

	local ROW1_Y = 262
	local ROW2_Y = ROW1_Y + BTN_H + 6
	local ROW3_Y = ROW2_Y + BTN_H + 6

	local craftBtn  = actionButton("CraftButton",      "🔨 Craft",   6,   88, ROW1_Y, Color3.fromRGB(45, 90, 140))
	local respawnBtn= actionButton("RespawnButton",    "↩ CP",      100,  88, ROW1_Y, Color3.fromRGB(90, 55, 55))
	local islandBtn = actionButton("IslandButton",     "🏝 Isla",   194,  94, ROW1_Y, Color3.fromRGB(55, 100, 70))
	islandBtn.Visible = false

	local achBtn    = actionButton("AchievementButton","🏆 Logros",  6,   88, ROW2_Y, Color3.fromRGB(90, 70, 30))
	local achCount  = Instance.new("TextLabel")
	achCount.Name = "AchievementCount"
	achCount.Size = UDim2.new(0, 88, 0, BTN_H)
	achCount.Position = UDim2.new(0, 100, 0, ROW2_Y)
	achCount.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
	achCount.BorderSizePixel = 0
	achCount.Text = "0/13"
	achCount.TextColor3 = Color3.fromRGB(255, 220, 100)
	achCount.Font = Enum.Font.GothamBold
	achCount.TextSize = 12
	achCount.Parent = main
	corner(achCount, 6)

	local shopBtn = actionButton("ShopButton", "🛒 Tienda", 194, 94, ROW2_Y, Color3.fromRGB(55, 75, 120))

	-- Fila 3: daily reward (ancho completo)
	local dailyBtn = Instance.new("TextButton")
	dailyBtn.Name = "DailyRewardButton"
	dailyBtn.Size = UDim2.new(1, -12, 0, BTN_H)
	dailyBtn.Position = UDim2.new(0, 6, 0, ROW3_Y)
	dailyBtn.BackgroundColor3 = Color3.fromRGB(160, 100, 20)
	dailyBtn.BorderSizePixel = 0
	dailyBtn.Text = "🎁 Recompensa diaria"
	dailyBtn.TextColor3 = Color3.new(1, 1, 1)
	dailyBtn.Font = Enum.Font.GothamBold
	dailyBtn.TextSize = 13
	dailyBtn.Parent = main
	corner(dailyBtn, 6)

	local streakLbl = Instance.new("TextLabel")
	streakLbl.Name = "StreakLabel"
	streakLbl.Size = UDim2.new(1, -12, 0, 20)
	streakLbl.Position = UDim2.new(0, 6, 0, ROW3_Y + BTN_H + 2)
	streakLbl.BackgroundTransparency = 1
	streakLbl.Text = ""
	streakLbl.TextColor3 = Color3.fromRGB(255, 200, 80)
	streakLbl.Font = Enum.Font.Gotham
	streakLbl.TextSize = 11
	streakLbl.TextXAlignment = Enum.TextXAlignment.Center
	streakLbl.Parent = main

	-- ── Notificaciones (top-center) ──────────────────────────────
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "NotificationContainer"
	notifContainer.AnchorPoint = Vector2.new(0.5, 0)
	notifContainer.Size = UDim2.new(0.55, 0, 0, 220)
	notifContainer.Position = UDim2.new(0.5, 0, 0, 8)
	notifContainer.BackgroundTransparency = 1
	notifContainer.Parent = gui

	-- ── Panel de Crafteo (derecha, ancla al borde derecho) ────────
	local craftPanel = Instance.new("Frame")
	craftPanel.Name = "CraftingPanel"
	craftPanel.Visible = false
	craftPanel.AnchorPoint = Vector2.new(1, 0)
	craftPanel.Size = UDim2.new(0, 320, 0, 420)
	craftPanel.Position = UDim2.new(1, -8, 0, 8)
	craftPanel.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
	craftPanel.BackgroundTransparency = 0.08
	craftPanel.BorderSizePixel = 0
	craftPanel.Parent = gui
	corner(craftPanel, 10)

	local craftTitle = Instance.new("TextLabel")
	craftTitle.Name = "Title"
	craftTitle.Size = UDim2.new(1, -12, 0, 32)
	craftTitle.Position = UDim2.new(0, 6, 0, 6)
	craftTitle.BackgroundTransparency = 1
	craftTitle.Text = "🔨 Fabricación"
	craftTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
	craftTitle.Font = Enum.Font.GothamBold
	craftTitle.TextSize = 18
	craftTitle.TextXAlignment = Enum.TextXAlignment.Left
	craftTitle.Parent = craftPanel

	local function closeBtn(parent: Frame)
		local btn = Instance.new("TextButton")
		btn.Name = "CloseButton"
		btn.Size = UDim2.new(0, 32, 0, 32)
		btn.Position = UDim2.new(1, -38, 0, 4)
		btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
		btn.BorderSizePixel = 0
		btn.Text = "✕"
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Parent = parent
		corner(btn, 6)
		return btn
	end

	closeBtn(craftPanel)

	local recipeScroll = Instance.new("ScrollingFrame")
	recipeScroll.Name = "RecipeList"
	recipeScroll.Size = UDim2.new(1, -12, 1, -44)
	recipeScroll.Position = UDim2.new(0, 6, 0, 38)
	recipeScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	recipeScroll.BackgroundTransparency = 0.1
	recipeScroll.BorderSizePixel = 0
	recipeScroll.ScrollBarThickness = 6
	recipeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	recipeScroll.Parent = craftPanel
	corner(recipeScroll, 6)

	-- ── Panel de Logros (abajo-izquierda, ancla al borde inferior) ─
	local achPanel = Instance.new("Frame")
	achPanel.Name = "AchievementPanel"
	achPanel.Visible = false
	achPanel.AnchorPoint = Vector2.new(0, 1)
	achPanel.Size = UDim2.new(0, 300, 0, 360)
	achPanel.Position = UDim2.new(0, 8, 1, -8)
	achPanel.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
	achPanel.BackgroundTransparency = 0.08
	achPanel.BorderSizePixel = 0
	achPanel.Parent = gui
	corner(achPanel, 10)

	local achPanelTitle = Instance.new("TextLabel")
	achPanelTitle.Name = "Title"
	achPanelTitle.Size = UDim2.new(1, -12, 0, 32)
	achPanelTitle.Position = UDim2.new(0, 6, 0, 6)
	achPanelTitle.BackgroundTransparency = 1
	achPanelTitle.Text = "🏆 Logros"
	achPanelTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
	achPanelTitle.Font = Enum.Font.GothamBold
	achPanelTitle.TextSize = 18
	achPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
	achPanelTitle.Parent = achPanel
	closeBtn(achPanel)

	local achScroll = Instance.new("ScrollingFrame")
	achScroll.Name = "AchievementList"
	achScroll.Size = UDim2.new(1, -12, 1, -44)
	achScroll.Position = UDim2.new(0, 6, 0, 38)
	achScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	achScroll.BackgroundTransparency = 0.1
	achScroll.BorderSizePixel = 0
	achScroll.ScrollBarThickness = 6
	achScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	achScroll.Parent = achPanel
	corner(achScroll, 6)

	-- ── Banner de Onboarding (abajo-centro) ──────────────────────
	local onboardBanner = Instance.new("Frame")
	onboardBanner.Name = "OnboardingBanner"
	onboardBanner.Visible = false
	onboardBanner.AnchorPoint = Vector2.new(0.5, 1)
	onboardBanner.Size = UDim2.new(0.55, 0, 0, 76)
	onboardBanner.Position = UDim2.new(0.5, 0, 1, -12)
	onboardBanner.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
	onboardBanner.BackgroundTransparency = 0.1
	onboardBanner.BorderSizePixel = 0
	onboardBanner.Parent = gui
	corner(onboardBanner, 10)

	local onboardTitle = Instance.new("TextLabel")
	onboardTitle.Name = "Title"
	onboardTitle.Size = UDim2.new(1, -80, 0, 24)
	onboardTitle.Position = UDim2.new(0, 12, 0, 8)
	onboardTitle.BackgroundTransparency = 1
	onboardTitle.Text = "Tutorial"
	onboardTitle.TextColor3 = Color3.fromRGB(255, 230, 140)
	onboardTitle.Font = Enum.Font.GothamBold
	onboardTitle.TextSize = 16
	onboardTitle.TextXAlignment = Enum.TextXAlignment.Left
	onboardTitle.Parent = onboardBanner

	local onboardStep = Instance.new("TextLabel")
	onboardStep.Name = "StepLabel"
	onboardStep.Size = UDim2.new(0, 70, 0, 20)
	onboardStep.Position = UDim2.new(1, -78, 0, 10)
	onboardStep.BackgroundTransparency = 1
	onboardStep.Text = "Paso 1/5"
	onboardStep.TextColor3 = Color3.fromRGB(180, 200, 220)
	onboardStep.Font = Enum.Font.Gotham
	onboardStep.TextSize = 11
	onboardStep.TextXAlignment = Enum.TextXAlignment.Right
	onboardStep.Parent = onboardBanner

	local onboardText = Instance.new("TextLabel")
	onboardText.Name = "Text"
	onboardText.Size = UDim2.new(1, -24, 0, 34)
	onboardText.Position = UDim2.new(0, 12, 0, 32)
	onboardText.BackgroundTransparency = 1
	onboardText.Text = ""
	onboardText.TextColor3 = Color3.new(1, 1, 1)
	onboardText.Font = Enum.Font.Gotham
	onboardText.TextSize = 13
	onboardText.TextWrapped = true
	onboardText.TextXAlignment = Enum.TextXAlignment.Left
	onboardText.Parent = onboardBanner

	local onboardDismiss = Instance.new("TextButton")
	onboardDismiss.Name = "Dismiss"
	onboardDismiss.Size = UDim2.new(0, 28, 0, 28)
	onboardDismiss.Position = UDim2.new(1, -36, 0, 6)
	onboardDismiss.BackgroundTransparency = 1
	onboardDismiss.Text = "✕"
	onboardDismiss.TextColor3 = Color3.fromRGB(200, 200, 200)
	onboardDismiss.Font = Enum.Font.GothamBold
	onboardDismiss.TextSize = 14
	onboardDismiss.Parent = onboardBanner

	-- ── Panel de Tienda (centro absoluto) ─────────────────────────
	local shopPanel = Instance.new("Frame")
	shopPanel.Name = "ShopPanel"
	shopPanel.Visible = false
	shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	shopPanel.Size = UDim2.new(0, 340, 0, 460)
	shopPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	shopPanel.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
	shopPanel.BackgroundTransparency = 0.05
	shopPanel.BorderSizePixel = 0
	shopPanel.Parent = gui
	corner(shopPanel, 10)

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Name = "Title"
	shopTitle.Size = UDim2.new(1, -12, 0, 32)
	shopTitle.Position = UDim2.new(0, 6, 0, 6)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "🛒 Tienda ética"
	shopTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.TextSize = 18
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.Parent = shopPanel

	local shopSubtitle = Instance.new("TextLabel")
	shopSubtitle.Name = "Subtitle"
	shopSubtitle.Size = UDim2.new(1, -12, 0, 18)
	shopSubtitle.Position = UDim2.new(0, 6, 0, 30)
	shopSubtitle.BackgroundTransparency = 1
	shopSubtitle.Text = "Cosméticos y QoL — sin pay-to-win"
	shopSubtitle.TextColor3 = Color3.fromRGB(150, 160, 170)
	shopSubtitle.Font = Enum.Font.Gotham
	shopSubtitle.TextSize = 11
	shopSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	shopSubtitle.Parent = shopPanel
	closeBtn(shopPanel)

	local shopScroll = Instance.new("ScrollingFrame")
	shopScroll.Name = "ShopList"
	shopScroll.Size = UDim2.new(1, -12, 1, -54)
	shopScroll.Position = UDim2.new(0, 6, 0, 48)
	shopScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	shopScroll.BackgroundTransparency = 0.1
	shopScroll.BorderSizePixel = 0
	shopScroll.ScrollBarThickness = 6
	shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopScroll.Parent = shopPanel
	corner(shopScroll, 6)

	-- ── Responsive: ajusta UIScale y tamaños de paneles ──────────
	local camera = workspace.CurrentCamera

	local function updateResponsive()
		local vp = camera.ViewportSize
		if vp.X <= 0 or vp.Y <= 0 then return end

		-- Escala del MainHUD: referencia 768px alto.
		-- En mobile landscape (375px alto) → scale ≈ 0.65
		local scaleH = vp.Y / 768
		local scaleW = vp.X / 1200
		local scale  = math.clamp(math.min(scaleH, scaleW), 0.55, 1.0)
		hudScale.Scale = scale

		-- Ancho efectivo del MainHUD escalado (incluyendo margen)
		local mainEffW = HUD_W * scale + 24

		-- CraftingPanel: ocupa el espacio restante a la derecha
		local cpW = math.clamp(math.min(320, vp.X - mainEffW - 20), 220, 340)
		local cpH = math.clamp(vp.Y - 20, 280, 480)
		craftPanel.Size = UDim2.new(0, cpW, 0, cpH)
		-- Ya usa AnchorPoint(1,0) + Position(1,-8, 0,8)

		-- ShopPanel: centrado, ocupa máximo disponible
		local spW = math.clamp(vp.X - 32, 280, 360)
		local spH = math.clamp(vp.Y - 32, 320, 480)
		shopPanel.Size = UDim2.new(0, spW, 0, spH)

		-- AchievementPanel: no exceder la mitad de pantalla en altura
		local apH = math.clamp(vp.Y * 0.55, 220, 380)
		local apW = math.clamp(HUD_W * scale, 220, 300)
		achPanel.Size = UDim2.new(0, apW, 0, apH)

		-- OnboardingBanner: no exceder 520px de ancho en mobile
		local bannerW = math.clamp(vp.X * 0.7, 280, 520)
		onboardBanner.Size = UDim2.new(0, bannerW, 0, 76)

		-- En pantallas muy pequeñas (mobile landscape angosto) ajustar posición HUD
		if vp.Y < 420 then
			-- HUD en esquina inferior izquierda para liberar vista central
			main.AnchorPoint = Vector2.new(0, 1)
			main.Position = UDim2.new(0, 8, 1, -8)
		else
			main.AnchorPoint = Vector2.new(0, 0)
			main.Position = UDim2.new(0, 12, 0, 12)
		end
	end

	-- Actualizar al crear y en cada cambio de viewport
	task.defer(updateResponsive)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsive)

	return {
		screenGui = gui,
		mainHud = main,
		progressLabel = progress,
		objectivePanel = objPanel,
		objectiveList = objList,
		inventoryFrame = backpack,
		notificationContainer = notifContainer,
		craftingPanel = craftPanel,
		recipeList = recipeScroll,
		craftButton = craftBtn,
		respawnButton = respawnBtn,
		islandButton = islandBtn,
		achievementButton = achBtn,
		achievementPanel = achPanel,
		achievementList = achScroll,
		achievementCount = achCount,
		onboardingBanner = onboardBanner,
		onboardingTitle = onboardTitle,
		onboardingText = onboardText,
		onboardingStep = onboardStep,
		onboardingDismiss = onboardDismiss,
		shopButton = shopBtn,
		shopPanel = shopPanel,
		shopList = shopScroll,
		dailyRewardButton = dailyBtn,
		streakLabel = streakLbl,
	}
end

return HudBuilder
