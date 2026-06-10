local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudBuilder = require(script.Parent.HudBuilder)

local ObjectiveController = {}
ObjectiveController._status = nil

function ObjectiveController.refreshUI()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local panel = refs.objectivePanel
	local list = refs.objectiveList
	if not panel or not list then
		return
	end

	local status = ObjectiveController._status
	if not status or not status.lines or #status.lines == 0 then
		panel.Visible = true
		list.Text = "Explorá la zona actual"
		return
	end

	panel.Visible = true
	local lines = {}
	for _, line in status.lines do
		local mark = line.done and "✓" or "○"
		table.insert(lines, mark .. " " .. line.text)
	end
	list.Text = table.concat(lines, "\n")
end

function ObjectiveController.init()
	HudBuilder.ensure()
	ObjectiveController.refreshUI()

	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remotes.SyncObjectives.OnClientEvent:Connect(function(status)
		ObjectiveController._status = status
		ObjectiveController.refreshUI()
	end)
end

return ObjectiveController
