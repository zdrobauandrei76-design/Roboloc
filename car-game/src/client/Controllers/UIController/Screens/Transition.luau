--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Transition = {}

function Transition.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local fade = Widgets.Frame(gui, "Fade")
	local tween: Tween? = nil

	local function fadeTo(transparency: number, duration: number)
		if not fade then
			return
		end
		if tween then
			tween:Cancel()
		end
		fade.Visible = true
		local active = Widgets.Tween(fade, duration, { BackgroundTransparency = transparency })
		tween = active
		if transparency >= 1 then
			active.Completed:Once(function()
				if tween == active and fade then
					fade.Visible = false
				end
			end)
		end
	end

	if fade then
		fade.BackgroundTransparency = 1
		fade.Visible = false
	end

	trove:Connect(context.Controllers.LaunchController.StateChanged, function(state: string)
		if state == "Returning" then
			fadeTo(0, 0.25)
		elseif state == "Idle" then
			fadeTo(1, 0.4)
		end
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
			if tween then
				tween:Cancel()
			end
			trove:Destroy()
		end,
	}
end

return Transition
