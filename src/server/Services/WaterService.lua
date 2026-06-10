--[[
	Agua sin colisión: hay que nadar. Puentes/muelles siguen siendo sólidos.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local WATER_TAG = "EscapeWater"
local KILL_WATER_TAG = "KillWater"

local WaterService = {}

function WaterService.configurePart(part: BasePart, options: { kill: boolean?, shallow: boolean? }?)
	if options and options.kill then
		CollectionService:AddTag(part, KILL_WATER_TAG)
		part:SetAttribute("IsKillWater", true)
		part.CanCollide = false
		part.Touched:Connect(function(hit)
			local hum = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
			if hum then
				hum.Health = 0
			end
		end)
		return
	end

	CollectionService:AddTag(part, WATER_TAG)
	part.CanCollide = false
	part:SetAttribute("IsWater", true)
	if options and options.shallow then
		part:SetAttribute("ShallowWater", true)
	end
end

function WaterService.initMap(map: Folder)
	local waterNames = {
		Ocean = { kill = false },
		River = { kill = true },
		LagoonWater = { kill = false },
		KillWater = { kill = true },
	}

	for _, desc in map:GetDescendants() do
		if desc:IsA("BasePart") then
			local opts = waterNames[desc.Name]
			if opts then
				WaterService.configurePart(desc, opts)
			elseif desc.Material == Enum.Material.Water and desc.Name ~= "EscapeDock" then
				WaterService.configurePart(desc, {})
			end
		end
	end
end

-- En servidor: avisar si está lejos de orilla (el cliente fuerza nado)
function WaterService.init()
	-- Reservado por si se añade daño por ahogamiento en servidor
end

return WaterService
