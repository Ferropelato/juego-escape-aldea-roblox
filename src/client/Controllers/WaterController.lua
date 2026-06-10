local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local WATER_TAG = "EscapeWater"

local WaterController = {}
local swimActive = false

local function getWaterParts(): { BasePart }
	local list = {}
	for _, p in CollectionService:GetTagged(WATER_TAG) do
		if p:IsA("BasePart") then
			table.insert(list, p)
		end
	end
	return list
end

local function isPointInPart(worldPos: Vector3, part: BasePart): boolean
	local localPos = part.CFrame:PointToObjectSpace(worldPos)
	local half = part.Size / 2
	return math.abs(localPos.X) <= half.X
		and math.abs(localPos.Y) <= half.Y + 2
		and math.abs(localPos.Z) <= half.Z
end

local function isOverSolidGround(hrp: BasePart): boolean
	local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0))
	if not ray then
		return false
	end
	local hit = ray.Instance
	if hit:GetAttribute("IsWater") or CollectionService:HasTag(hit, WATER_TAG) then
		return false
	end
	return hit.CanCollide
end

function WaterController.update()
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChild("Humanoid") :: Humanoid?
	if not hrp or not hum or hum.Health <= 0 then
		return
	end

	local inWater = false
	for _, waterPart in getWaterParts() do
		if isPointInPart(hrp.Position, waterPart) then
			inWater = true
			break
		end
	end

	local onGround = isOverSolidGround(hrp)

	if inWater and not onGround then
		if hum:GetState() ~= Enum.HumanoidStateType.Swimming then
			hum:ChangeState(Enum.HumanoidStateType.Swimming)
		end
		swimActive = true
		-- Empuje hacia arriba suave
		hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, math.max(hrp.AssemblyLinearVelocity.Y, -2), hrp.AssemblyLinearVelocity.Z)
	else
		if swimActive and hum:GetState() == Enum.HumanoidStateType.Swimming then
			hum:ChangeState(Enum.HumanoidStateType.Landing)
		end
		swimActive = false
	end
end

function WaterController.init()
	RunService.Heartbeat:Connect(function()
		WaterController.update()
	end)
end

return WaterController
