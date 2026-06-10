local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NotificationService = require(script.Parent.NotificationService)
local CheckpointService = require(script.Parent.CheckpointService)

local BoundaryService = {}

local ISLAND_CENTER = Vector3.new(400, 0, 0)
local MAX_RADIUS = 620
local WARN_RADIUS = 540
local CHECK_INTERVAL = 0.4

function BoundaryService.init()
	local lastCheck: { [Player]: number } = {}

	RunService.Heartbeat:Connect(function()
		local now = tick()
		for _, player in Players:GetPlayers() do
			if lastCheck[player] and now - lastCheck[player] < CHECK_INTERVAL then
				continue
			end
			lastCheck[player] = now

			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
			if not hrp or not hum or hum.Health <= 0 then
				continue
			end

			local flat = Vector3.new(hrp.Position.X - ISLAND_CENTER.X, 0, hrp.Position.Z - ISLAND_CENTER.Z)
			local dist = flat.Magnitude

			if dist > MAX_RADIUS then
				NotificationService.send(player, "¡Te alejaste demasiado! Volviendo a la isla...", "error")
				local cf = CheckpointService.getSpawnCFrame(player)
				if cf then
					hrp.CFrame = cf
				else
					hrp.CFrame = CFrame.new(ISLAND_CENTER + Vector3.new(0, 15, 0))
				end
			elseif dist > WARN_RADIUS then
				if not player:GetAttribute("BoundaryWarned") then
					player:SetAttribute("BoundaryWarned", true)
					NotificationService.send(player, "Corrientes fuertes: volvé hacia la isla", "info")
					task.delay(8, function()
						player:SetAttribute("BoundaryWarned", nil)
					end)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastCheck[player] = nil
	end)
end

return BoundaryService
