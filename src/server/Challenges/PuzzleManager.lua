local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local ChallengeService = require(script.Parent.Parent.Services.ChallengeService)
local NotificationService = require(script.Parent.Parent.Services.NotificationService)
local InventoryService = require(script.Parent.Parent.Services.InventoryService)

local PuzzleManager = {}
PuzzleManager._state = {} :: { [string]: any }
PuzzleManager._statueProgress = {} :: { [number]: { number } }

function PuzzleManager.onStatueActivated(player: Player, statueIndex: number)
	local key = player.UserId
	PuzzleManager._statueProgress[key] = PuzzleManager._statueProgress[key] or {}
	table.insert(PuzzleManager._statueProgress[key], statueIndex)

	if #PuzzleManager._statueProgress[key] == 4 then
		PuzzleManager._statuePuzzle(player, table.clone(PuzzleManager._statueProgress[key]))
		PuzzleManager._statueProgress[key] = {}
	end
end

function PuzzleManager.handleInteraction(player: Player, puzzleId: string, payload: any)
	if type(puzzleId) ~= "string" then
		return
	end

	if puzzleId == "StatuePuzzle" then
		PuzzleManager._statuePuzzle(player, payload)
	elseif puzzleId == "ShellSequence" then
		PuzzleManager._shellSequence(player, payload)
	elseif puzzleId == "MazeSign" then
		PuzzleManager._mazeSign(player, payload)
	else
		NotificationService.send(player, "Interacción registrada", "info")
	end
end

function PuzzleManager._statuePuzzle(player: Player, sequence: { number }?)
	if type(sequence) ~= "table" or #sequence ~= 4 then
		NotificationService.send(player, "Activá las 4 estatuas en el orden correcto", "info")
		return
	end

	local correct = { 2, 4, 1, 3 }
	for i = 1, 4 do
		if sequence[i] ~= correct[i] then
			NotificationService.send(player, "Orden incorrecto. Las estatuas vuelven a su lugar.", "error")
			return
		end
	end

	local ok = ChallengeService.completeAndSync(player, "CastleRuins")
	if ok then
		NotificationService.send(player, "¡La puerta del castillo se abre!", "success")
	end
end

function PuzzleManager._shellSequence(player: Player, index: number?)
	local key = "shell_" .. player.UserId
	PuzzleManager._state[key] = PuzzleManager._state[key] or {}
	local expected = { 3, 1, 4, 2 }
	local state = PuzzleManager._state[key]

	if type(index) ~= "number" then
		return
	end

	table.insert(state, index)
	local step = #state
	if state[step] ~= expected[step] then
		PuzzleManager._state[key] = {}
		NotificationService.send(player, "Secuencia incorrecta. Buscá las conchas brillantes.", "error")
		return
	end

	if step == 4 then
		InventoryService.addResource(player, "Crystal", 2)
		local ok = ChallengeService.completeAndSync(player, "LagoonDive")
		PuzzleManager._state[key] = {}
		if ok then
			NotificationService.send(player, "¡Enigma resuelto! Obtuviste cristales.", "success")
		end
	end
end

function PuzzleManager._mazeSign(player: Player, signIndex: number?)
	if type(signIndex) ~= "number" then
		return
	end
	local ObjectiveService = require(script.Parent.Parent.Services.ObjectiveService)
	ObjectiveService.onSignRead(player, signIndex)
end

Players.PlayerRemoving:Connect(function(player)
	PuzzleManager._statueProgress[player.UserId] = nil
	PuzzleManager._state["shell_" .. player.UserId] = nil
end)

return PuzzleManager
