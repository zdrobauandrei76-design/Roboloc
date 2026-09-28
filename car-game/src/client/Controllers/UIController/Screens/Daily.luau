--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Rewards = require(ReplicatedStorage.Config.Rewards)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Daily = {}

local function rewardText(reward: Rewards.Reward, data: any): (string, string)
	if reward.Kind == "Boost" then
		return "⏱️", `{reward.Minutes}m 2x`
	elseif reward.Kind == "Car" and not Stats.OwnsCar(data, reward.CarId) then
		return "🚗", Stats.Car(reward.CarId).Name
	end
	return "💵", Format.Cash(Stats.RewardCash(data, reward.Runs, reward.Minimum))
end

function Daily.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local dataController = controllers.DataController
	local days = Widgets.Frame(gui, "Days")
	local claim = Widgets.Button(gui, "Claim")
	local claimLabel = Widgets.Text(gui, "ClaimLabel")
	local streak = Widgets.Text(gui, "Streak")
	local busy = false
	local autoOpened = false

	local function refresh()
		local data = dataController:Get()
		if type(data) ~= "table" then
			return
		end
		local now = Widgets.ServerNow()
		local today = Stats.DayNumber(now)
		local day, claimable = Stats.DailyState(data, today)
		local claimedThrough = if claimable then day - 1 else day
		for index, reward in Rewards.Daily do
			local tile = days and days:FindFirstChild(`Day{index}`)
			if tile then
				local icon, text = rewardText(reward, data)
				Widgets.SetText(tile:FindFirstChild("DayIcon", true), icon)
				Widgets.SetText(tile:FindFirstChild("DayReward", true), text)
				Widgets.SetVisible(tile:FindFirstChild("DayCheck", true), index <= claimedThrough)
				Widgets.Paint(tile, if index == day and claimable then "Gold" else "Card")
			end
		end
		Widgets.Paint(claim, if claimable then "Green" else "Gray")
		if claimable then
			Widgets.SetText(claimLabel, "CLAIM!")
		else
			Widgets.SetText(claimLabel, `Next in {Format.Time((today + 1) * 86400 - now)}`)
		end
		local streakDays = if claimable and day == 1 then 0 else claimedThrough
		Widgets.SetText(streak, `🔥 Streak: {streakDays} day{if streakDays == 1 then "" else "s"}`)
	end

	Widgets.OnClick(trove, claim, function()
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			local ok = Packets.ClaimDaily:Fire()
			busy = false
			controllers.SoundController:Play(if ok then "Purchase" else "Error")
			refresh()
		end)
	end, controllers)

	local elapsed = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		elapsed += dt
		if elapsed >= 1 and gui.Enabled then
			elapsed = 0
			refresh()
		end
	end)
	trove:Add(dataController:Observe({ "Daily" }, function(value: any)
		if gui.Enabled then
			refresh()
		end
		local data = dataController:Get()
		if value ~= nil and not autoOpened and type(data) == "table" then
			autoOpened = true
			local _, claimable = Stats.DailyState(data, Stats.DayNumber(Widgets.ServerNow()))
			if claimable then
				task.delay(2, function()
					if not context.IsOpen("Offer") then
						context.Open("Daily")
					end
				end)
			end
		end
	end))

	return Widgets.ModalScreen(context, gui, "Daily", trove, refresh)
end

return Daily
