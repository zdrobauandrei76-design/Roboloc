--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
local Cars = require(ReplicatedStorage.Config.Cars)
local Rewards = require(ReplicatedStorage.Config.Rewards)
local Upgrades = require(ReplicatedStorage.Config.Upgrades)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local menuScreens = { "Upgrades", "Garage", "Rebirth", "Shop", "Leaderboard" }
local sideScreens: { [string]: string } =
	{ Gifts = "Gifts", Daily = "Daily", Codes = "Codes", Starter = "Offer" }

local Hud = {}

local function menuButton(parent: Instance?, name: string): GuiButton?
	local found = parent and parent:FindFirstChild(name)
	if found and found:IsA("GuiButton") then
		return found
	end
	warn(`[UI] Hud needs a button named {name}`)
	return nil
end

local function claimableGifts(player: Player, now: number): (number, string)
	local startedAt = player:GetAttribute("SessionStart")
	local mask = player:GetAttribute("GiftsClaimed")
	if type(startedAt) ~= "number" or type(mask) ~= "number" then
		return 0, "..."
	end
	local elapsed = now - startedAt
	local ready = 0
	local nextWait = math.huge
	for index, gift in Rewards.Gifts do
		local bit = 2 ^ (index - 1)
		if (mask // bit) % 2 == 0 then
			local remaining = gift.Minutes * 60 - elapsed
			if remaining <= 0 then
				ready += 1
			else
				nextWait = math.min(nextWait, remaining)
			end
		end
	end
	if ready > 0 then
		return ready, "CLAIM!"
	elseif nextWait < math.huge then
		return 0, Format.Time(nextWait)
	end
	return 0, "DONE"
end

function Hud.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local dataController = controllers.DataController
	local player = Players.LocalPlayer

	local top = Widgets.Frame(gui, "Top")
	local cashAmount = Widgets.Text(gui, "CashAmount")
	local multiplierValue = Widgets.Text(gui, "MultiplierValue")
	local boostPill = Widgets.Frame(gui, "Boost")
	local boostTimer = Widgets.Text(gui, "BoostTimer")
	local best = Widgets.Text(gui, "Best")
	local left = Widgets.Frame(gui, "Left")
	local right = Widgets.Frame(gui, "Right")
	local giftTimer = Widgets.Text(gui, "GiftTimer")
	local inviteLabel = Widgets.Text(gui, "InviteLabel")

	local buttons: { [string]: GuiButton? } = {}
	for _, name in menuScreens do
		local button = menuButton(left, name)
		buttons[name] = button
		Widgets.OnClick(trove, button, function()
			if context.IsOpen(name) then
				context.Close(name)
			else
				context.Open(name)
			end
		end, controllers)
	end
	for name, screenName in sideScreens do
		local button = menuButton(right, name)
		buttons[name] = button
		Widgets.OnClick(trove, button, function()
			context.Open(screenName)
		end, controllers)
	end
	Widgets.OnClick(trove, Widgets.Button(gui, "CashPlus"), function()
		context.Open("Shop")
	end, controllers)
	Widgets.OnClick(trove, Widgets.Button(gui, "Multiplier"), function()
		context.Open("Shop")
	end, controllers)
	Widgets.OnClick(trove, menuButton(right, "Invite"), function()
		task.spawn(function()
			local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
			if ok and canInvite then
				pcall(SocialService.PromptGameInvite, SocialService, player)
			end
		end)
	end, controllers)

	local shownCash = 0
	local cancelCount: () -> () = function() end
	trove:Add(function()
		cancelCount()
	end)
	trove:Add(dataController:Observe({ "Cash" }, function(cash: any)
		if type(cash) ~= "number" then
			Widgets.SetText(cashAmount, "...")
			return
		end
		cancelCount()
		local from = shownCash
		shownCash = cash
		local duration = if cash > from and from > 0 then 0.45 else 0
		cancelCount = Widgets.CountUp(cashAmount, from, cash, Format.Cash, duration)
	end))
	trove:Add(dataController:Observe({ "BestDistance" }, function(distance: any)
		Widgets.SetText(
			best,
			`🏆 Best: {Format.Distance(if type(distance) == "number" then distance else 0)}`
		)
	end))

	local function refreshMultiplier()
		local value = player:GetAttribute("CashMultiplier")
		Widgets.SetText(multiplierValue, Format.Multiplier(if type(value) == "number" then value else 1))
		local friends = player:GetAttribute("FriendCount")
		local count = if type(friends) == "number" then friends else 0
		Widgets.SetText(
			inviteLabel,
			if count > 0 then `+{math.floor(count * Rewards.FriendBonus * 100 + 0.5)}%` else "+10%"
		)
	end
	trove:Connect(player:GetAttributeChangedSignal("CashMultiplier"), refreshMultiplier)
	trove:Connect(player:GetAttributeChangedSignal("FriendCount"), refreshMultiplier)
	refreshMultiplier()

	local function refresh()
		local data = dataController:Get()
		if type(data) ~= "table" then
			return
		end
		local now = Widgets.ServerNow()
		local boostLeft = data.BoostEndsAt - now
		Widgets.SetVisible(boostPill, boostLeft > 0)
		if boostLeft > 0 then
			Widgets.SetText(boostTimer, `2x {Format.Time(boostLeft)}`)
		end
		local affordableUpgrades = 0
		for _, upgrade in Upgrades.Order do
			local level = Stats.UpgradeLevel(data, upgrade.Id)
			if
				level < Stats.UpgradeCap(upgrade.Id, data.Rebirths)
				and Stats.UpgradeCost(upgrade.Id, level) <= data.Cash
			then
				affordableUpgrades += 1
			end
		end
		Widgets.SetBadge(buttons.Upgrades, affordableUpgrades)
		local affordableCars = 0
		for _, car in Cars.Order do
			if
				car.Source == "Shop"
				and car.Price > 0
				and data.Cash >= car.Price
				and not Stats.OwnsCar(data, car.Id)
			then
				affordableCars += 1
			end
		end
		Widgets.SetBadge(buttons.Garage, affordableCars)
		Widgets.SetBadge(buttons.Rebirth, if Stats.CanRebirth(data) then 1 else 0)
		local _, dailyReady = Stats.DailyState(data, Stats.DayNumber(now))
		Widgets.SetBadge(buttons.Daily, if dailyReady then 1 else 0)
		local readyGifts, giftText = claimableGifts(player, now)
		Widgets.SetBadge(buttons.Gifts, readyGifts)
		Widgets.SetText(giftTimer, giftText)
		Widgets.SetVisible(
			buttons.Starter,
			controllers.StoreController:ProductAvailable("StarterPack") and not data.StarterPackOwned
		)
	end

	local elapsed = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		elapsed += dt
		if elapsed >= 0.5 and gui.Enabled then
			elapsed = 0
			refresh()
		end
	end)
	trove:Add(dataController:Observe({}, function()
		refresh()
	end))

	trove:Connect(controllers.LaunchController.StateChanged, function(state: string)
		local inRun = state == "Ramp" or state == "Flight"
		Widgets.SetVisible(top, not inRun)
		Widgets.SetVisible(left, not inRun)
		Widgets.SetVisible(right, not inRun)
	end)

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

return Hud
