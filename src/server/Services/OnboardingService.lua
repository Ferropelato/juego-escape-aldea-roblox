local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local OnboardingConfig = require(Shared.Config.OnboardingConfig)

local DataService = require(script.Parent.DataService)
local ChallengeService = require(script.Parent.ChallengeService)

local OnboardingService = {}
local TOTAL_STEPS = #OnboardingConfig.Steps

local function advance(player: Player, minStep: number)
	local data = DataService.get(player)
	if data.onboardingDone then
		return
	end
	if data.onboardingStep < minStep then
		data.onboardingStep = minStep
		ChallengeService.syncToClient(player)
	end
	if data.onboardingStep >= TOTAL_STEPS then
		data.onboardingDone = true
		ChallengeService.syncToClient(player)
	end
end

function OnboardingService.onPlayerReady(player: Player)
	task.delay(2, function()
		advance(player, 1)
	end)
end

function OnboardingService.onResourceCollected(player: Player)
	advance(player, 2)
end

function OnboardingService.onObjectivesSynced(player: Player)
	local data = DataService.get(player)
	if data.onboardingDone then
		return
	end
	local challenge = require(Shared.Config.GameConfig).getChallenge(data.currentChallenge)
	if challenge and challenge.objectives then
		advance(player, 3)
	end
end

function OnboardingService.onCrafted(player: Player)
	advance(player, 4)
end

function OnboardingService.onChallengeCompleted(player: Player)
	advance(player, 5)
end

return OnboardingService
