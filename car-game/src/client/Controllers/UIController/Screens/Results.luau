--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Theme = require(ReplicatedStorage.Config.Theme)
local Zones = require(ReplicatedStorage.Config.Zones)
local Format = require(ReplicatedStorage.Utils.Format)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Results = {}

function Results.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local launchController = controllers.LaunchController
	local player = Players.LocalPlayer

	local card = Widgets.Frame(gui, "Card")
	local title = Widgets.Text(gui, "ResultTitle")
	local distance = Widgets.Text(gui, "ResultDistance")
	local zone = Widgets.Text(gui, "ResultZone")
	local earned = Widgets.Text(gui, "ResultEarned")
	local multiplier = Widgets.Text(gui, "ResultMultiplier")
	local timing = Widgets.Text(gui, "ResultTiming")
	local best = Widgets.Text(gui, "ResultBest")
	local double = Widgets.Button(gui, "DoubleButton")
	local doubleLabel = Widgets.Text(gui, "DoubleLabel")
	local continueButton = Widgets.Button(gui, "ContinueButton")
	local continueLabel = Widgets.Text(gui, "ContinueLabel")

	local cancelCount: () -> () = function() end
	trove:Add(function()
		cancelCount()
	end)

	Widgets.OnClick(trove, continueButton, function()
		launchController:Continue()
	end, controllers)
	Widgets.OnClick(trove, double, function()
		controllers.StoreController:PromptPass("DoubleCash")
	end, controllers)

	local function show(result: any)
		cancelCount()
		local zoneInfo = Zones[result.Zone] or Zones[1]
		if not result.Ok then
			Widgets.SetText(title, "Connection hiccup!")
			Widgets.SetText(distance, "Try again")
			Widgets.SetText(zone, "")
			Widgets.SetText(earned, "")
			Widgets.SetText(multiplier, "")
			Widgets.SetText(timing, "")
			Widgets.SetVisible(best, false)
			Widgets.SetVisible(double, false)
		else
			Widgets.SetText(title, if result.IsBest then "AMAZING JUMP!" else "NICE JUMP!")
			if title then
				title.TextColor3 = if result.IsBest then Theme.Gold else Theme.Text
			end
			Widgets.SetText(distance, Format.Distance(result.Distance))
			Widgets.SetText(zone, `{zoneInfo.Emoji} {zoneInfo.Name}`)
			cancelCount = Widgets.CountUp(earned, 0, result.Earned, function(value: number): string
				return "+" .. Format.Cash(value)
			end, 0.6)
			local value = player:GetAttribute("CashMultiplier")
			Widgets.SetText(
				multiplier,
				`{Format.Multiplier(if type(value) == "number" then value else 1)} cash bonus`
			)
			Widgets.SetText(timing, `{result.Label} launch`)
			Widgets.SetVisible(best, result.IsBest)
			local offerDouble = controllers.StoreController:PassAvailable("DoubleCash")
				and not controllers.StoreController:OwnsPass("DoubleCash")
			Widgets.SetVisible(double, offerDouble)
			if offerDouble then
				local pass = Monetization.PassByKey.DoubleCash
				Widgets.SetText(doubleLabel, `{pass.Emoji} 2x → +{Format.Cash(result.Earned * 2)}`)
			end
		end
		Widgets.SetText(continueLabel, if launchController:IsAuto() then "AUTO..." else "CONTINUE")
		context.Open("Results")
		Widgets.Pop(card)
	end

	trove:Connect(launchController.Finished, show)
	trove:Connect(launchController.StateChanged, function(state: string)
		if state ~= "Results" and state ~= "Finishing" then
			context.Close("Results")
		end
	end)

	return {
		Modal = false,
		StartsOpen = false,
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

return Results
