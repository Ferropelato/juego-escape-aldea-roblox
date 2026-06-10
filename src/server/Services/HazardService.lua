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

	-- Espinas que asoman
	local spikeCount = math.clamp(math.floor(size.X * size.Z / 80), 4, 24)
	for i = 1, spikeCount do
		local sx = (math.random() - 0.5) * size.X * 0.85
		local sz = (math.random() - 0.5) * size.Z * 0.85
		local spike = Instance.new("Part")
		spike.Name = "Spikes"
		spike.Size = Vector3.new(1.2, math.random(3, 6), 1.2)
		spike.Position = center + Vector3.new(sx, size.Y / 2 + 1, sz)
		spike.Anchored = true
		spike.Color = Color3.fromRGB(80, 80, 85)
		spike.Material = Enum.Material.Metal
		spike.Parent = folder
		bindInstantKill(spike)
	end

	return folder
end

-- Trampa bajo un puente (línea desde → hasta, ancha para caídas laterales)
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
	local segments = math.max(4, math.floor(length / 8))
	local segmentLen = length / segments + 6

	local folder = Instance.new("Folder")
	folder.Name = "UnderBridgeHazard"
	folder.Parent = parent

	for i = 0, segments do
		local t = i / segments
		local mid = fromPos:Lerp(toPos, t)
		local pitCenter = Vector3.new(mid.X, y - 4, mid.Z)
		local cf = CFrame.lookAt(pitCenter, pitCenter + dir)

		local water = Instance.new("Part")
		water.Name = "KillWater"
		water.Size = Vector3.new(killWidth, 10, segmentLen)
		water.CFrame = cf
		water.Anchored = true
		water.CanCollide = false
		water.Color = Color3.fromRGB(15, 40, 70)
		water.Material = Enum.Material.Water
		water.Transparency = 0.15
		water.Parent = folder
		bindInstantKill(water)

		local right = dir:Cross(Vector3.yAxis).Unit
		for sx = -killWidth / 2 + 2, killWidth / 2 - 2, 3.5 do
			for sz = -segmentLen / 2 + 2, segmentLen / 2 - 2, 5 do
				local spike = Instance.new("Part")
				spike.Name = "Spikes"
				spike.Size = Vector3.new(1.4, math.random(4, 7), 1.4)
				spike.CFrame = cf * CFrame.new(sx, 5, sz)
				spike.Anchored = true
				spike.Color = Color3.fromRGB(75, 75, 80)
				spike.Material = Enum.Material.Metal
				spike.Parent = folder
				bindInstantKill(spike)
			end
		end
	end
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
