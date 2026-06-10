--[[
	Escape Island - Servidor principal
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local DataService = require(script.Services.DataService)
local CheckpointService = require(script.Services.CheckpointService)
local ChallengeService = require(script.Services.ChallengeService)
local RemoteHandlers = require(script.Handlers.RemoteHandlers)
local MapBuilder = require(script.Map.MapBuilder)
local ChallengeBehaviors = require(script.Challenges.ChallengeBehaviors)
local ResourceService = require(script.Services.ResourceService)
local WaterService = require(script.Services.WaterService)
local ObjectiveService = require(script.Services.ObjectiveService)
local BoundaryService = require(script.Services.BoundaryService)
local HazardService = require(script.Services.HazardService)
local ZoneProgressionService = require(script.Services.ZoneProgressionService)
local WildlifeService = require(script.Services.WildlifeService)

print("[EscapeIsland] Iniciando servidor...")

-- Suelo de emergencia por si el personaje aparece antes del mapa
local emergency = Instance.new("Part")
emergency.Name = "EmergencySpawn"
emergency.Size = Vector3.new(50, 2, 50)
emergency.Position = Vector3.new(0, 20, 0)
emergency.Anchored = true
emergency.Color = Color3.fromRGB(80, 160, 90)
emergency.Material = Enum.Material.Grass
emergency.Parent = workspace

local buildOk, map = pcall(MapBuilder.build)
if not buildOk then
	warn("[EscapeIsland] ERROR generando mapa:", map)
	map = workspace:FindFirstChild("EscapeIsland")
end
if buildOk then
	emergency:Destroy()
else
	emergency.Position = Vector3.new(0, 12, 0)
	warn("[EscapeIsland] Quedó plataforma de emergencia. Revisá Salida.")
end
ResourceService.init()

if map then
	WaterService.initMap(map)
	HazardService.initMap(map)
	ZoneProgressionService.initMap(map)
	ResourceService.initMap(map)
	ObjectiveService.initMap(map)
	ZoneProgressionService.init()
	CheckpointService.bindCheckpointParts()
	ChallengeBehaviors.bindZones(map)
	WildlifeService.populateIsland(map)
	WildlifeService.init()
	BoundaryService.init()
end
RemoteHandlers.init()

Players.PlayerAdded:Connect(function(player)
	DataService.load(player)
	ChallengeService.updateGatesForPlayer(player)
	task.delay(1, function()
		ChallengeService.updateGatesForPlayer(player)
		ChallengeService.syncToClient(player)
		ObjectiveService.syncObjectives(player)
	end)
end)

-- Auto-guardado
task.spawn(function()
	while true do
		task.wait(GameConfig.AUTO_SAVE_INTERVAL)
		for _, player in Players:GetPlayers() do
			DataService.save(player)
		end
	end
end)

if map then
	print("[EscapeIsland] Servidor listo. Islas:", #map:GetChildren())
else
	warn("[EscapeIsland] Servidor iniciado SIN mapa.")
end
