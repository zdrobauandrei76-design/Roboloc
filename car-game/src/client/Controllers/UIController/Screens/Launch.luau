--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local FlightConfig = require(ReplicatedStorage.Config.Flight)
local Theme = require(ReplicatedStorage.Config.Theme)
local Zones = require(ReplicatedStorage.Config.Zones)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Launch = {}

function Launch.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local launchController = controllers.LaunchController

	local launchButton = Widgets.Button(gui, "LaunchButton")
	local launchLabel = Widgets.Text(gui, "LaunchLabel")
	local launchHint = Widgets.Text(gui, "LaunchHint")
	local autoButton = Widgets.Button(gui, "AutoButton")
	local autoLabel = Widgets.Text(gui, "AutoLabel")
	local autoLock = Widgets.Text(gui, "AutoLock")
	local meter = Widgets.Frame(gui, "Meter")
	local needle = Widgets.Frame(gui, "Needle")
	local prompt = Widgets.Text(gui, "MeterPrompt")
	local tapArea = Widgets.Button(gui, "TapArea")
	local boostButton = Widgets.Button(gui, "BoostButton")
	local fuelFill = Widgets.Frame(gui, "FuelFill")
	local flightPanel = Widgets.Frame(gui, "Flight")
	local distanceLabel = Widgets.Text(gui, "DistanceLabel")
	local zoneLabel = Widgets.Text(gui, "ZoneLabel")
	local progressFill = Widgets.Frame(gui, "ProgressFill")
	local nextLabel = Widgets.Text(gui, "NextLabel")
	local speedLabel = Widgets.Text(gui, "SpeedLabel")
	local callout = Widgets.Text(gui, "Callout")

	local calloutToken = 0
	local function showCallout(text: string, color: Color3, duration: number)
		if not callout then
			return
		end
		calloutToken += 1
		local token = calloutToken
		callout.Text = text
		callout.TextColor3 = color
		callout.Visible = true
		Widgets.Pop(callout)
		task.delay(duration, function()
			if calloutToken == token and callout then
				callout.Visible = false
			end
		end)
	end

	local currentState = launchController:GetState()

	local function refreshAuto()
		local owned = controllers.StoreController:OwnsPass("AutoLaunch")
		local enabled = launchController:IsAuto()
		local idle = currentState == "Idle" or currentState == "Starting"
		Widgets.SetVisible(autoLock, not owned)
		Widgets.SetText(autoLabel, if enabled then "AUTO: ON" else "AUTO")
		Widgets.Paint(autoButton, if enabled then "Green" else "Purple")
		Widgets.SetVisible(
			autoButton,
			(idle or enabled)
				and (owned or enabled or controllers.StoreController:PassAvailable("AutoLaunch"))
		)
	end

	local function applyState(state: string)
		currentState = state
		local idle = state == "Idle" or state == "Starting"
		Widgets.SetVisible(launchButton, idle)
		Widgets.SetVisible(meter, state == "Ramp")
		Widgets.SetVisible(tapArea, state == "Ramp")
		Widgets.SetVisible(boostButton, state == "Flight")
		Widgets.SetVisible(flightPanel, state == "Ramp" or state == "Flight")
		Widgets.SetText(launchLabel, if state == "Starting" then "..." else "LAUNCH!")
		if state == "Ramp" then
			Widgets.SetText(prompt, "TAP WHEN GREEN!")
		end
		if state ~= "Ramp" and state ~= "Flight" then
			launchController:SetBoost(false)
		end
		refreshAuto()
	end

	Widgets.SetText(
		launchHint,
		if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
			then "or press SPACE"
			else ""
	)

	Widgets.OnClick(trove, launchButton, function()
		launchController:Launch()
	end, controllers)
	Widgets.OnClick(trove, autoButton, function()
		if controllers.StoreController:OwnsPass("AutoLaunch") then
			launchController:SetAuto(not launchController:IsAuto())
		else
			controllers.StoreController:PromptPass("AutoLaunch")
		end
	end, controllers)
	if tapArea then
		trove:Connect(tapArea.Activated, function()
			launchController:Tap()
		end)
	end
	Widgets.OnHold(trove, boostButton, function(held: boolean)
		launchController:SetBoost(held)
	end)

	trove:Connect(launchController.StateChanged, applyState)
	trove:Connect(launchController.AutoChanged, refreshAuto)
	trove:Add(controllers.DataController:Observe({ "Passes", "AutoLaunch" }, function()
		refreshAuto()
	end))
	trove:Connect(launchController.TimingLocked, function(quality: number, label: string)
		local color = if quality >= FlightConfig.PerfectQuality
			then Theme.Gold
			elseif quality >= FlightConfig.GreatQuality then Theme.Green
			elseif label == "MISSED!" then Theme.Red
			else Theme.Blue
		showCallout(label, color, 1.1)
		Widgets.SetText(prompt, label)
	end)
	trove:Connect(launchController.ZoneEntered, function(index: number)
		local zone = Zones[index]
		if zone then
			showCallout(
				`{zone.Emoji} {string.upper(zone.Name)}!  {Format.Multiplier(zone.Multiplier)}`,
				Theme.Primary,
				1.8
			)
		end
	end)

	trove:Connect(RunService.RenderStepped, function()
		if not gui.Enabled then
			return
		end
		local info = launchController:GetInfo()
		if info.State == "Ramp" and needle then
			needle.Position = UDim2.fromScale(info.Needle, 0.5)
		end
		if info.State == "Flight" or info.State == "Ramp" then
			local distance = info.Distance
			local zoneIndex = Stats.ZoneIndexAt(distance)
			local zone = Zones[zoneIndex]
			local nextZone = Zones[zoneIndex + 1]
			local zoneEnd = Stats.ZoneEnd(zoneIndex)
			Widgets.SetText(distanceLabel, Format.Distance(distance))
			Widgets.SetText(speedLabel, `{Format.Commas(info.Speed * 1.2)} km/h`)
			if zone then
				Widgets.SetText(zoneLabel, `{zone.Emoji} {zone.Name}  {Format.Multiplier(zone.Multiplier)}`)
			end
			if progressFill then
				local span = math.max(zoneEnd - (if zone then zone.Start else 0), 1)
				local progress = math.clamp((distance - (if zone then zone.Start else 0)) / span, 0, 1)
				progressFill.Size = UDim2.fromScale(progress, 1)
			end
			if nextZone then
				Widgets.SetText(nextLabel, `{nextZone.Emoji} in {Format.Distance(zoneEnd - distance)}`)
			else
				Widgets.SetText(nextLabel, `🏁 End in {Format.Distance(zoneEnd - distance)}`)
			end
			if fuelFill then
				fuelFill.Size = UDim2.fromScale(math.clamp(info.Fuel / info.FuelMax, 0, 1), 1)
			end
		end
		if info.State == "Idle" and launchButton then
			local hasCar = launchController:HasCar()
			Widgets.SetText(launchLabel, if hasCar then "LAUNCH!" else "LOADING...")
			local pulse = 1 + math.sin(os.clock() * 5) * 0.04
			local scale = launchButton:FindFirstChild("PulseScale", true)
			if scale and scale:IsA("UIScale") then
				scale.Scale = pulse
			end
		end
	end)

	applyState(launchController:GetState())

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Launch
