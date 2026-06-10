local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local ChallengeService = require(script.Parent.Parent.Services.ChallengeService)
local NotificationService = require(script.Parent.Parent.Services.NotificationService)
local InventoryService = require(script.Parent.Parent.Services.InventoryService)

local PuzzleManager = {}
PuzzleManager._state = {} :: { [string]: any }
PuzzleManager._statueProgress = {} :: { [string]: { number } }

local STATUE_PUZZLES = {
	CastleRuins = {
		count = 4,
		correct = { 2, 4, 1, 3 },
		challengeId = "CastleRuins",
		successMsg = "¡La puerta del castillo se abre!",
		failMsg = "Orden incorrecto. Las estatuas vuelven a su lugar.",
	},
	SandTemple = {
		count = 3,
		correct = { 1, 3, 2 },
		challengeId = "SandTemple",
		successMsg = "¡El templo antiguo se revela!",
		failMsg = "Orden incorrecto. Los ídolos se reinician.",
	},
}

function PuzzleManager.onStatueActivated(player: Player, statueIndex: number, puzzleKey: string)
	local cfg = STATUE_PUZZLES[puzzleKey]
	if not cfg then
		return
	end

	local key = player.UserId .. "_" .. puzzleKey
	PuzzleManager._statueProgress[key] = PuzzleManager._statueProgress[key] or {}
	table.insert(PuzzleManager._statueProgress[key], statueIndex)

	if #PuzzleManager._statueProgress[key] == cfg.count then
		PuzzleManager._resolveStatuePuzzle(player, table.clone(PuzzleManager._statueProgress[key]), cfg)
		PuzzleManager._statueProgress[key] = {}
	end
end

function PuzzleManager._resolveStatuePuzzle(player: Player, sequence: { number }, cfg: any)
	if type(sequence) ~= "table" or #sequence ~= cfg.count then
		return
	end

	for i = 1, cfg.count do
		if sequence[i] ~= cfg.correct[i] then
			NotificationService.send(player, cfg.failMsg, "error")
			return
		end
	end

	local ok = ChallengeService.completeAndSync(player, cfg.challengeId)
	if ok then
		NotificationService.send(player, cfg.successMsg, "success")
	end
end

function PuzzleManager.handleInteraction(player: Player, puzzleId: string, payload: any)
	if type(puzzleId) ~= "string" then
		return
	end

	if puzzleId == "StatuePuzzle" then
		PuzzleManager._resolveStatuePuzzle(player, payload, STATUE_PUZZLES.CastleRuins)
	elseif puzzleId == "RelicPuzzle" then
		PuzzleManager._resolveStatuePuzzle(player, payload, STATUE_PUZZLES.SandTemple)
	elseif puzzleId == "ShellSequence" then
		PuzzleManager._shellSequence(player, payload)
	elseif puzzleId == "MazeSign" then
		PuzzleManager._mazeSign(player, payload)
	else
		NotificationService.send(player, "Interacción registrada", "info")
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
	for puzzleKey in STATUE_PUZZLES do
		PuzzleManager._statueProgress[player.UserId .. "_" .. puzzleKey] = nil
	end
	PuzzleManager._state["shell_" .. player.UserId] = nil
end)

return PuzzleManager
