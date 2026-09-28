--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Upgrades = require(ReplicatedStorage.Config.Upgrades)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Rebirth = {}

function Rebirth.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local dataController = controllers.DataController
	local current = Widgets.Text(gui, "Current")
	local nextLabel = Widgets.Text(gui, "Next")
	local unlocks = Widgets.Text(gui, "Unlocks")
	local fill = Widgets.Frame(gui, "RebirthFill")
	local cost = Widgets.Text(gui, "Cost")
	local confirm = Widgets.Button(gui, "Confirm")
	local confirmLabel = Widgets.Text(gui, "ConfirmLabel")
	local busy = false

	local function refresh()
		local data = dataController:Get()
		if type(data) ~= "table" then
			return
		end
		local rebirths = data.Rebirths
		local maxed = rebirths >= GameConfig.MaxRebirths
		local price = Stats.RebirthCost(rebirths)
		Widgets.SetText(
			current,
			`Rebirths: {rebirths}   •   Cash bonus {Format.Multiplier(Stats.RebirthMultiplier(rebirths))}`
		)
		Widgets.SetText(
			nextLabel,
			if maxed
				then "You reached the max rebirth!"
				else `After rebirth: {Format.Multiplier(Stats.RebirthMultiplier(rebirths + 1))} cash bonus forever`
		)
		local parts = {}
		for _, upgrade in Upgrades.Order do
			local gain = Stats.UpgradeCap(upgrade.Id, rebirths + 1) - Stats.UpgradeCap(upgrade.Id, rebirths)
			if gain > 0 then
				table.insert(parts, `+{gain} {upgrade.Name}`)
			end
		end
		Widgets.SetText(
			unlocks,
			if #parts > 0
				then `Unlocks max levels: {table.concat(parts, ", ")}`
				else "All upgrade levels unlocked!"
		)
		if fill then
			fill.Size = UDim2.fromScale(if maxed then 1 else math.clamp(data.Cash / price, 0, 1), 1)
		end
		Widgets.SetText(cost, if maxed then "MAX" else `{Format.Cash(data.Cash)} / {Format.Cash(price)}`)
		local ready = Stats.CanRebirth(data)
		Widgets.Paint(confirm, if ready then "Purple" else "Gray")
		Widgets.SetText(
			confirmLabel,
			if maxed then "MAXED" elseif ready then "REBIRTH!" else "NEED MORE CASH"
		)
	end

	Widgets.OnClick(trove, confirm, function()
		local data = dataController:Get()
		if busy or type(data) ~= "table" or not Stats.CanRebirth(data) then
			controllers.SoundController:Play("Error")
			return
		end
		busy = true
		task.spawn(function()
			local ok = Packets.Rebirth:Fire()
			busy = false
			if ok then
				controllers.SoundController:Play("Rebirth")
				context.Close("Rebirth")
			else
				controllers.SoundController:Play("Error")
			end
		end)
	end)

	trove:Add(dataController:Observe({}, function()
		if gui.Enabled then
			refresh()
		end
	end))

	return Widgets.ModalScreen(context, gui, "Rebirth", trove, refresh)
end

return Rebirth
