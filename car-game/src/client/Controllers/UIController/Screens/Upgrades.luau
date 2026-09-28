--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpgradeConfig = require(ReplicatedStorage.Config.Upgrades)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

type Card = {
	Level: TextLabel?,
	Effect: TextLabel?,
	Buy: GuiButton?,
	Price: TextLabel?,
	Max: GuiButton?,
	Maxed: TextLabel?,
}

local Upgrades = {}

local function effectText(id: string, level: number, data: any, showNext: boolean): string
	local nextLevel = level + 1
	if id == "Engine" then
		local carSpeed = Stats.EquippedCar(data).Speed
		local now = Format.Commas(Stats.LaunchSpeed(level, carSpeed) * 1.2)
		local after = Format.Commas(Stats.LaunchSpeed(nextLevel, carSpeed) * 1.2)
		return if showNext then `{now} → {after} km/h` else `{now} km/h`
	elseif id == "Nitro" then
		local mega = data.Passes.MegaNitro == true
		local now = string.format("%.2fs", Stats.Fuel(level, mega))
		local after = string.format("%.2fs", Stats.Fuel(nextLevel, mega))
		return if showNext then `{now} → {after} fuel` else `{now} fuel`
	end
	local now = math.floor(Stats.Glide(level) * 100 + 0.5)
	local after = math.floor(Stats.Glide(nextLevel) * 100 + 0.5)
	return if showNext then `{now}% → {after}% glide` else `{now}% glide`
end

function Upgrades.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local dataController = controllers.DataController
	local cardsFrame = Widgets.Frame(gui, "Cards")
	local cards: { [string]: Card } = {}
	local busy = false

	local function purchase(id: string, count: number)
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			local ok = Packets.BuyUpgrade:Fire(id, count)
			busy = false
			controllers.SoundController:Play(if ok then "Purchase" else "Error")
		end)
	end

	for _, upgrade in UpgradeConfig.Order do
		local frame = cardsFrame and cardsFrame:FindFirstChild(upgrade.Id)
		if not frame then
			warn(`[UI] Upgrades needs a card named {upgrade.Id}`)
			continue
		end
		local card: Card = {
			Level = Widgets.Text(frame, "Level"),
			Effect = Widgets.Text(frame, "Effect"),
			Buy = Widgets.Button(frame, "Buy"),
			Price = Widgets.Text(frame, "Price"),
			Max = Widgets.Button(frame, "Max"),
			Maxed = Widgets.Text(frame, "Maxed"),
		}
		cards[upgrade.Id] = card
		Widgets.OnClick(trove, card.Buy, function()
			purchase(upgrade.Id, 1)
		end)
		Widgets.OnClick(trove, card.Max, function()
			purchase(upgrade.Id, 100)
		end)
	end

	local function refresh()
		local data = dataController:Get()
		if type(data) ~= "table" then
			return
		end
		for id, card in cards do
			local upgrade = UpgradeConfig.ById[id]
			local level = Stats.UpgradeLevel(data, id)
			local cap = Stats.UpgradeCap(id, data.Rebirths)
			local capped = level >= cap
			local cost = Stats.UpgradeCost(id, level)
			local affordable = not capped and cost <= data.Cash
			Widgets.SetText(card.Level, `Lv {level}/{cap}`)
			Widgets.SetText(card.Effect, effectText(id, level, data, not capped))
			Widgets.SetVisible(card.Buy, not capped)
			Widgets.SetVisible(card.Max, not capped)
			Widgets.SetVisible(card.Maxed, capped)
			Widgets.SetText(card.Price, Format.Cash(cost))
			Widgets.Paint(card.Buy, if affordable then "Green" else "Gray")
			Widgets.Paint(card.Max, if affordable then "Blue" else "Gray")
			Widgets.SetText(
				card.Maxed,
				if cap >= upgrade.MaxLevel then "FULLY MAXED!" else "MAX! Rebirth to unlock more levels"
			)
		end
	end

	trove:Add(dataController:Observe({}, function()
		if gui.Enabled then
			refresh()
		end
	end))

	return Widgets.ModalScreen(context, gui, "Upgrades", trove, refresh)
end

return Upgrades
