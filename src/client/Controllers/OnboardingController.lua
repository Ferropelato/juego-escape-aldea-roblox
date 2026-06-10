local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local OnboardingConfig = require(Shared.Config.OnboardingConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local OnboardingController = {}

function OnboardingController.refresh()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local banner = refs.onboardingBanner
	local title = refs.onboardingTitle
	local text = refs.onboardingText
	local stepLabel = refs.onboardingStep
	if not banner or not title or not text then
		return
	end

	local data = PlayerDataController.get()
	if not data or data.onboardingDone then
		banner.Visible = false
		return
	end

	local stepIndex = math.clamp((data.onboardingStep or 0), 1, #OnboardingConfig.Steps)
	local step = OnboardingConfig.Steps[stepIndex]
	if not step then
		banner.Visible = false
		return
	end

	banner.Visible = true
	title.Text = step.icon .. " " .. step.title
	text.Text = step.text
	if stepLabel then
		stepLabel.Text = "Paso " .. stepIndex .. "/" .. #OnboardingConfig.Steps
	end
end

function OnboardingController.init()
	HudBuilder.ensure()
	OnboardingController.refresh()

	PlayerDataController.Changed.Event:Connect(function()
		OnboardingController.refresh()
	end)

	local refs = HudBuilder.getRefs()
	if refs and refs.onboardingDismiss then
		refs.onboardingDismiss.MouseButton1Click:Connect(function()
			local data = PlayerDataController.get()
			if data and refs.onboardingBanner then
				refs.onboardingBanner.Visible = false
			end
		end)
	end
end

return OnboardingController
