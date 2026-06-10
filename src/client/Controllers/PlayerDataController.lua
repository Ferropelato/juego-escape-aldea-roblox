local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataController = {}
PlayerDataController.Data = nil
PlayerDataController.Changed = Instance.new("BindableEvent")

function PlayerDataController.set(data)
	PlayerDataController.Data = data
	PlayerDataController.Changed:Fire(data)
end

function PlayerDataController.get()
	return PlayerDataController.Data
end

function PlayerDataController.init()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remotes.SyncPlayerData.OnClientEvent:Connect(function(data)
		PlayerDataController.set(data)
	end)
end

return PlayerDataController
