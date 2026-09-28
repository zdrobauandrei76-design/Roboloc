--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Rewards = require(ReplicatedStorage.Config.Rewards)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Gifts = {}

function Gifts.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local dataController = controllers.DataController
	local player = Players.LocalPlayer
	local grid = Widgets.Frame(gui, "GiftGrid")
	local busy = false

	local function refresh()
		local data = dataController:Get()
		local startedAt = player:GetAttribute("SessionStart")
		local mask = player:GetAttribute("GiftsClaimed")
		if type(data) ~= "table" or type(startedAt) ~= "number" or type(mask) ~= "number" then
			return
		end
		local elapsed = Widgets.ServerNow() - startedAt
		for index, gift in Rewards.Gifts do
			local tile = grid and grid:FindFirstChild(`Gift{index}`)
			if tile then
				local claimed = (mask // 2 ^ (index - 1)) % 2 == 1
				local remaining = gift.Minutes * 60 - elapsed
				local reward = gift.Reward
				local text = if reward.Kind == "Boost"
					then `{reward.Minutes}m 2x`
					else Format.Cash(Stats.RewardCash(data, reward.Runs, reward.Minimum))
				Widgets.SetText(tile:FindFirstChild("GiftReward", true), text)
				Widgets.SetText(
					tile:FindFirstChild("GiftTimer", true),
					if claimed then "✅" elseif remaining <= 0 then "CLAIM!" else Format.Time(remaining)
				)
				Widgets.Paint(tile, if claimed then "Gray" elseif remaining <= 0 then "Green" else "Card")
			end
		end
	end

	for index in Rewards.Gifts do
		local tile = grid and grid:FindFirstChild(`Gift{index}`)
		if tile and tile:IsA("GuiButton") then
			Widgets.OnClick(trove, tile, function()
				if busy then
					return
				end
				busy = true
				task.spawn(function()
					local ok = Packets.ClaimGift:Fire(index)
					busy = false
					controllers.SoundController:Play(if ok then "Purchase" else "Error")
					refresh()
				end)
			end)
		else
			warn(`[UI] Gifts needs a button named Gift{index}`)
		end
	end

	local elapsed = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		elapsed += dt
		if elapsed >= 0.5 and gui.Enabled then
			elapsed = 0
			refresh()
		end
	end)
	trove:Connect(player:GetAttributeChangedSignal("GiftsClaimed"), function()
		if gui.Enabled then
			refresh()
		end
	end)

	return Widgets.ModalScreen(context, gui, "Gifts", trove, refresh)
end

return Gifts
