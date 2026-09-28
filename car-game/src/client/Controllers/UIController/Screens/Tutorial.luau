--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local finalStep = 3

local Tutorial = {}

local function findTarget(path: { string }): GuiObject?
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local current: Instance? = playerGui
	for _, name in path do
		current = current and current:FindFirstChild(name, true)
	end
	if current and current:IsA("GuiObject") and current.Visible then
		local screen = current:FindFirstAncestorOfClass("ScreenGui")
		if screen and screen.Enabled then
			return current
		end
	end
	return nil
end

function Tutorial.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local dataController = controllers.DataController
	local launchController = controllers.LaunchController
	local hint = Widgets.Frame(gui, "Hint")
	local hintText = Widgets.Text(gui, "HintText")
	local arrow = Widgets.Text(gui, "Arrow")
	local scale = gui:FindFirstChildOfClass("UIScale")
	local localStep = 0

	local function currentStep(): number
		local stored = dataController:Get({ "Tutorial" })
		return math.max(localStep, if type(stored) == "number" then stored else 0)
	end

	local function advance(step: number)
		if step > currentStep() then
			localStep = step
			Packets.SetTutorial:Fire(step)
		end
	end

	trove:Connect(launchController.StateChanged, function(state: string)
		local step = currentStep()
		if state == "Ramp" and step < 1 then
			advance(1)
		end
	end)
	trove:Connect(launchController.Finished, function(result: any)
		if result.Ok and currentStep() < 2 then
			advance(2)
		end
	end)
	trove:Add(dataController:Observe({ "Upgrades" }, function(upgrades: any)
		if type(upgrades) ~= "table" then
			return
		end
		local total = (upgrades.Engine or 0) + (upgrades.Nitro or 0) + (upgrades.Wings or 0)
		if total > 0 and currentStep() == 2 then
			advance(finalStep)
		end
	end))

	local function place(text: string?, target: GuiObject?)
		Widgets.SetVisible(hint, text ~= nil)
		if text then
			Widgets.SetText(hintText, text)
		end
		if not arrow then
			return
		end
		if not target then
			arrow.Visible = false
			return
		end
		local factor = if scale then scale.Scale else 1
		local position = target.AbsolutePosition + Vector2.new(target.AbsoluteSize.X / 2, 0)
		local bob = math.sin(os.clock() * 6) * 6
		arrow.Position = UDim2.fromOffset(position.X / factor, position.Y / factor - 8 + bob)
		arrow.Visible = true
	end

	local elapsed = 0
	trove:Connect(RunService.RenderStepped, function(dt: number)
		elapsed += dt
		if not dataController:IsLoaded() then
			place(nil, nil)
			return
		end
		local step = currentStep()
		local state = launchController:GetState()
		if step >= finalStep then
			place(nil, nil)
			return
		end
		if elapsed < 0.05 then
			return
		end
		elapsed = 0
		if step == 0 and state == "Idle" then
			place("Tap LAUNCH to fly off the mega ramp!", findTarget({ "Launch", "LaunchButton" }))
		elseif step <= 1 and state == "Ramp" then
			place("TAP when the needle is in the GREEN!", findTarget({ "Launch", "Meter" }))
		elseif step <= 1 and state == "Flight" then
			place("HOLD NITRO to fly further!", findTarget({ "Launch", "BoostButton" }))
		elseif step == 2 and state == "Idle" then
			if context.IsOpen("Upgrades") then
				place("Buy an upgrade to go further!", findTarget({ "Upgrades", "Engine", "Buy" }))
			else
				place("Spend your cash on UPGRADES!", findTarget({ "Hud", "Left", "Upgrades" }))
			end
		else
			place(nil, nil)
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
			trove:Destroy()
		end,
	}
end

return Tutorial
