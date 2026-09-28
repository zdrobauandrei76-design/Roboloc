--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Theme = require(ReplicatedStorage.Config.Theme)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Codes = {}

function Codes.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local dataController = controllers.DataController
	local input = Widgets.Box(gui, "CodeInput")
	local redeem = Widgets.Button(gui, "Redeem")
	local status = Widgets.Text(gui, "CodeStatus")
	local group = Widgets.Button(gui, "Group")
	local groupLabel = Widgets.Text(gui, "GroupLabel")
	local busy = false

	local function setStatus(text: string, color: Color3)
		if status then
			status.Text = text
			status.TextColor3 = color
		end
	end

	local function refreshGroup()
		local claimed = dataController:Get({ "GroupClaimed" }) == true
		Widgets.SetVisible(group, GameConfig.GroupId > 0)
		Widgets.SetText(
			groupLabel,
			if claimed
				then "✅ Group perks active"
				else `👥 Join {GameConfig.GroupName}, then tap for a free car + 10% cash!`
		)
		Widgets.Paint(group, if claimed then "Gray" else "Purple")
	end

	Widgets.OnClick(trove, redeem, function()
		local text = if input then input.Text else ""
		if busy or #text == 0 then
			return
		end
		busy = true
		setStatus("Checking...", Theme.Muted)
		task.spawn(function()
			local ok, message = Packets.RedeemCode:Fire(string.sub(text, 1, 30))
			busy = false
			if ok then
				setStatus(`Redeemed! {message or ""}`, Theme.Green)
				controllers.SoundController:Play("Purchase")
				if input then
					input.Text = ""
				end
			else
				setStatus(if type(message) == "string" then message else "Try again", Theme.Red)
				controllers.SoundController:Play("Error")
			end
		end)
	end, controllers)

	Widgets.OnClick(trove, group, function()
		if busy or dataController:Get({ "GroupClaimed" }) == true then
			return
		end
		busy = true
		task.spawn(function()
			local ok = Packets.ClaimGroup:Fire()
			busy = false
			if ok then
				controllers.SoundController:Play("Purchase")
			else
				setStatus("Join the group first, then tap again!", Theme.Red)
				controllers.SoundController:Play("Error")
			end
			refreshGroup()
		end)
	end, controllers)

	trove:Add(dataController:Observe({ "GroupClaimed" }, function()
		refreshGroup()
	end))

	return Widgets.ModalScreen(context, gui, "Codes", trove, function()
		setStatus("", Theme.Muted)
		refreshGroup()
	end)
end

return Codes
