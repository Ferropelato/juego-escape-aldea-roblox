local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationService = {}

function NotificationService.send(player: Player, message: string, kind: string?)
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remotes.ShowNotification:FireClient(player, message, kind or "info")
end

function NotificationService.broadcast(message: string, kind: string?)
	for _, player in game.Players:GetPlayers() do
		NotificationService.send(player, message, kind)
	end
end

return NotificationService
