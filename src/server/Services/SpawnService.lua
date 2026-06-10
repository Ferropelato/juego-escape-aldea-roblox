local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local CheckpointService = require(script.Parent.CheckpointService)
local DataService = require(script.Parent.DataService)

local SpawnService = {}

function SpawnService.spawnPlayer(player: Player, useRaftIntro: boolean?)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	local spawnCFrame = CheckpointService.getSpawnCFrame(player)
	if not spawnCFrame then
		spawnCFrame = CFrame.new(0, 15, 0)
	end

	if useRaftIntro and not DataService.get(player).lastCheckpointPosition then
		SpawnService._raftIntro(player, character, hrp, humanoid)
	else
		hrp.CFrame = spawnCFrame
	end
end

function SpawnService._raftIntro(player: Player, character: Model, hrp: BasePart, humanoid: Humanoid)
	local map = Workspace:FindFirstChild("EscapeIsland")
	local island = map and map:FindFirstChild("Island1_Tropical")
	local beachZone = island and island:FindFirstChild("Zones") and island.Zones:FindFirstChild("BeachLanding")
	local beachSpawn = beachZone and beachZone:FindFirstChild("Spawn")

	local endCFrame = beachSpawn and (beachSpawn.CFrame + Vector3.new(0, 3, 0)) or CFrame.new(0, 10, 0)
	local startPos = endCFrame.Position + Vector3.new(0, 2, GameConfig.RAFT_SPAWN_OFFSET.Z)

	local raft = Instance.new("Part")
	raft.Name = "IntroRaft"
	raft.Size = Vector3.new(6, 1, 8)
	raft.Anchored = true
	raft.Color = Color3.fromRGB(120, 80, 40)
	raft.Material = Enum.Material.Wood
	raft.CFrame = CFrame.new(startPos)
	raft.Parent = Workspace

	hrp.CFrame = CFrame.new(startPos + Vector3.new(0, 3, 0))
	humanoid.PlatformStand = true

	local tween = TweenService:Create(raft, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		CFrame = endCFrame,
	})

	local hrpTween = TweenService:Create(hrp, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		CFrame = endCFrame + Vector3.new(0, 3, 0),
	})

	tween:Play()
	hrpTween:Play()
	tween.Completed:Wait()

	humanoid.PlatformStand = false
	raft:Destroy()

	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remotes.ShowNotification:FireClient(player, "¡Llegaste a la isla! Explorá la playa y seguí el camino.", "success")
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		local data = DataService.get(player)
		local isNew = not data.lastCheckpointPosition and not next(data.completedChallenges)
		SpawnService.spawnPlayer(player, isNew)
	end)
end)

return SpawnService
