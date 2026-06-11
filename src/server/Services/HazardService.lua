--[[
	Zonas mortales bajo puentes: agua profunda + espinas.
	Caer = muerte instantánea → hay que cruzar con cuidado.
]]

local HazardService = {}

local function bindInstantKill(part: BasePart, label: string?)
	part:SetAttribute("InstantKill", true)
	part.Touched:Connect(function(hit)
		local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hum.Health = 0
		end
	end)
end

-- Pozo mortal (agua oscura + espinas visibles)
function HazardService.createDeathPit(parent: Instance, center: Vector3, size: Vector3)
	local folder = Instance.new("Folder")
	folder.Name = "DeathPit"
	folder.Parent = parent

	local water = Instance.new("Part")
	water.Name = "KillWater"
	water.Size = size
	water.Position = center
	water.Anchored = true
	water.CanCollide = false
	water.Color = Color3.fromRGB(15, 40, 70)
	water.Material = Enum.Material.Water
	water.Transparency = 0.2
	water.Parent = folder
	bindInstantKill(water)

	-- Espinas decorativas (máx 6, solo visuales — el kill water ya cubre el daño)
	local spikeCount = math.clamp(math.floor(size.X * size.Z / 400), 2, 6)
	for i = 1, spikeCount do
		local sx = (math.random() - 0.5) * size.X * 0.7
		local sz = (math.random() - 0.5) * size.Z * 0.7
		local spike = Instance.new("Part")
		spike.Name = "SpikeDecor"
		spike.Size = Vector3.new(1.2, math.random(3, 6), 1.2)
		spike.Position = center + Vector3.new(sx, size.Y / 2 + 1, sz)
		spike.Anchored = true
		spike.CanCollide = false
		spike.Color = Color3.fromRGB(80, 80, 85)
		spike.Material = Enum.Material.Metal
		spike.Parent = folder
	end

	return folder
end

-- Trampa bajo un puente: 1 kill plane continuo + pocos spikes decorativos (sin Touched en spikes)
function HazardService.createUnderBridge(
	parent: Instance,
	fromPos: Vector3,
	toPos: Vector3,
	bridgeWidth: number,
	depth: number?
)
	local dir = toPos - fromPos
	local length = dir.Magnitude
	if length < 4 then
		return
	end
	dir = dir.Unit
	local killWidth = bridgeWidth + 38
	local y = math.min(fromPos.Y, toPos.Y) + (depth or -10)
	local mid = fromPos:Lerp(toPos, 0.5)
	local pitCenter = Vector3.new(mid.X, y - 4, mid.Z)
	local cf = CFrame.lookAt(pitCenter, pitCenter + dir)

	local folder = Instance.new("Folder")
	folder.Name = "UnderBridgeHazard"
	folder.Parent = parent

	-- Un único kill plane cubre todo el puente (1 part + 1 Touched en vez de decenas)
	local water = Instance.new("Part")
	water.Name = "KillWater"
	water.Size = Vector3.new(killWidth, 10, length + 12)
	water.CFrame = cf
	water.Anchored = true
	water.CanCollide = false
	water.Color = Color3.fromRGB(15, 40, 70)
	water.Material = Enum.Material.Water
	water.Transparency = 0.15
	water.Parent = folder
	bindInstantKill(water)

	-- Solo 4 spikes decorativos visibles (sin Touched — el kill plane ya cubre)
	local right = dir:Cross(Vector3.yAxis).Unit
	local spikePositions = { -0.35, -0.1, 0.15, 0.4 }
	for _, t in spikePositions do
		local spikePos = fromPos:Lerp(toPos, t)
		local side = ((math.floor(t * 10) % 2 == 0) and 1 or -1) * (killWidth * 0.25)
		local spike = Instance.new("Part")
		spike.Name = "SpikeDecor"
		spike.Size = Vector3.new(1.4, math.random(4, 7), 1.4)
		spike.Position = Vector3.new(spikePos.X, y + 3, spikePos.Z) + right * side
		spike.Anchored = true
		spike.CanCollide = false
		spike.Color = Color3.fromRGB(75, 75, 80)
		spike.Material = Enum.Material.Metal
		spike.Parent = folder
	end

	return folder
end

function HazardService.initMap(map: Folder)
	for _, desc in map:GetDescendants() do
		if desc:IsA("BasePart") and (desc.Name == "KillWater" or desc.Name == "Spikes") then
			if not desc:GetAttribute("KillBound") then
				desc:SetAttribute("KillBound", true)
				bindInstantKill(desc)
			end
		end
	end
end

return HazardService
