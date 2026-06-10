--[[
	Crea el HUD en PlayerGui (siempre visible).
	No depende de que StarterGui esté bien montado en Rojo.
]]

local Players = game:GetService("Players")

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
}

function HudBuilder.getRefs(): HudRefs?
	local gui = player.PlayerGui:FindFirstChild("EscapeIslandHUD")
	if not gui then
		return nil
	end
	local main = gui:FindFirstChild("MainHUD") :: Frame?
	if not main then
		return nil
	end
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
	}
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

function HudBuilder.ensure(): HudRefs
	local existing = HudBuilder.getRefs()
	if existing then
		return existing
	end

	-- Ocultar StarterGui roto si existe
	local old = player.PlayerGui:FindFirstChild("GameUI")
	if old and old:IsA("ScreenGui") then
		old.Enabled = false
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "EscapeIslandHUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10
	gui.Parent = player.PlayerGui

	local main = Instance.new("Frame")
	main.Name = "MainHUD"
	main.Size = UDim2.new(0, 300, 0, 300)
	main.Position = UDim2.new(0, 12, 0, 12)
	main.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
	main.BackgroundTransparency = 0.08
	main.BorderSizePixel = 0
	main.Parent = gui
	corner(main, 10)

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

	local function actionButton(name: string, text: string, x: number, color: Color3)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, 88, 0, 28)
		btn.Position = UDim2.new(0, x, 0, 262)
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

	local craftBtn = actionButton("CraftButton", "🔨 Craft", 6, Color3.fromRGB(45, 90, 140))
	local respawnBtn = actionButton("RespawnButton", "↩ CP", 100, Color3.fromRGB(90, 55, 55))
	local islandBtn = actionButton("IslandButton", "🏝 Isla", 194, Color3.fromRGB(55, 100, 70))
	islandBtn.Visible = false

	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "NotificationContainer"
	notifContainer.Size = UDim2.new(0.5, 0, 0, 200)
	notifContainer.Position = UDim2.new(0.25, 0, 0, 8)
	notifContainer.BackgroundTransparency = 1
	notifContainer.Parent = gui

	local craftPanel = Instance.new("Frame")
	craftPanel.Name = "CraftingPanel"
	craftPanel.Visible = false
	craftPanel.Size = UDim2.new(0, 320, 0, 400)
	craftPanel.Position = UDim2.new(1, -332, 0, 12)
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

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -34, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Parent = craftPanel
	corner(closeBtn, 6)

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
	}
end

return HudBuilder
