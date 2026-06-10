local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MonetizationConfig = require(Shared.Config.MonetizationConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local CosmeticController = {}
local player = Players.LocalPlayer
local activeEmitter: ParticleEmitter? = nil

local function clearTrail()
	if activeEmitter then
		activeEmitter:Destroy()
		activeEmitter = nil
	end
end

local function applyTrail(character: Model, trailId: string)
	clearTrail()
	if trailId == "none" then
		return
	end

	local trail = MonetizationConfig.Trails[trailId]
	if not trail or not trail.color then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local att = hrp:FindFirstChild("TrailAttachment") :: Attachment?
	if not att then
		att = Instance.new("Attachment")
		att.Name = "TrailAttachment"
		att.Position = Vector3.new(0, -2, 0)
		att.Parent = hrp
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CosmeticTrail"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(trail.color)
	emitter.Size = NumberSequence.new(0.3, 0)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Rate = 25
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.Parent = att
	activeEmitter = emitter
end

function CosmeticController.refreshHudBadge()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local title = refs.mainHud and refs.mainHud:FindFirstChild("Title") :: TextLabel?
	if not title then
		return
	end

	local data = PlayerDataController.get()
	local prefix = "🏝️ Escape Island"
	if data then
		if data.supporterBadge then
			prefix = "💖 " .. prefix
		end
		if data.entitlements and data.entitlements.vip then
			prefix = "⭐ VIP · " .. prefix
		end
	end
	title.Text = prefix
end

function CosmeticController.refreshCharacter()
	local data = PlayerDataController.get()
	local char = player.Character
	if not char then
		return
	end
	local trailId = data and data.cosmetics and data.cosmetics.activeTrail or "none"
	applyTrail(char, trailId)
	CosmeticController.refreshHudBadge()
end

function CosmeticController.init()
	CosmeticController.refreshCharacter()

	PlayerDataController.Changed.Event:Connect(function()
		CosmeticController.refreshCharacter()
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		CosmeticController.refreshCharacter()
	end)
end

return CosmeticController
