--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Theme = require(ReplicatedStorage.Config.Theme)
local Types = require(script.Parent.Types)

local pressInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local releaseInfo = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local popInfo = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local Widgets = {}

function Widgets.Find(root: Instance, name: string, className: string): Instance?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[UI] {root:GetFullName()} needs a {className} named "{name}"`)
	return nil
end

function Widgets.Text(root: Instance, name: string): TextLabel?
	local found = Widgets.Find(root, name, "TextLabel")
	return if found and found:IsA("TextLabel") then found else nil
end

function Widgets.Button(root: Instance, name: string): GuiButton?
	local found = Widgets.Find(root, name, "GuiButton")
	return if found and found:IsA("GuiButton") then found else nil
end

function Widgets.Frame(root: Instance, name: string): GuiObject?
	local found = Widgets.Find(root, name, "GuiObject")
	return if found and found:IsA("GuiObject") then found else nil
end

function Widgets.Box(root: Instance, name: string): TextBox?
	local found = Widgets.Find(root, name, "TextBox")
	return if found and found:IsA("TextBox") then found else nil
end

function Widgets.Viewport(root: Instance, name: string): ViewportFrame?
	local found = Widgets.Find(root, name, "ViewportFrame")
	return if found and found:IsA("ViewportFrame") then found else nil
end

function Widgets.SetText(label: Instance?, text: string)
	if not label then
		return
	end
	if label:IsA("TextLabel") then
		label.Text = text
	elseif label:IsA("TextButton") then
		label.Text = text
	end
end

function Widgets.SetVisible(object: Instance?, visible: boolean)
	if object and object:IsA("GuiObject") then
		object.Visible = visible
	end
end

function Widgets.Tween(object: Instance, duration: number, properties: { [string]: any }): Tween
	local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad), properties)
	tween:Play()
	return tween
end

function Widgets.Pop(object: Instance?)
	local scale = object and object:FindFirstChild("PopScale")
	if scale and scale:IsA("UIScale") then
		scale.Scale = 0.7
		TweenService:Create(scale, popInfo, { Scale = 1 }):Play()
	end
end

function Widgets.Paint(object: Instance?, colorName: string)
	if not object or not object:IsA("GuiObject") then
		return
	end
	local theme = Theme :: any
	local top = theme[colorName]
	local bottom = theme[colorName .. "Dark"] or top
	if typeof(top) ~= "Color3" then
		return
	end
	object.BackgroundColor3 = Color3.new(1, 1, 1)
	local gradient = object:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(top, bottom)
	else
		object.BackgroundColor3 = top
	end
end

function Widgets.OnClick(trove: any, button: GuiButton?, callback: () -> (), controllers: { [string]: any }?)
	if not button then
		return
	end
	local scale = button:FindFirstChild("PressScale")
	if scale and scale:IsA("UIScale") then
		trove:Connect(button.MouseButton1Down, function()
			TweenService:Create(scale, pressInfo, { Scale = 0.9 }):Play()
		end)
		local function release()
			TweenService:Create(scale, releaseInfo, { Scale = 1 }):Play()
		end
		trove:Connect(button.MouseButton1Up, release)
		trove:Connect(button.MouseLeave, release)
	end
	trove:Connect(button.Activated, function()
		if controllers and controllers.SoundController then
			controllers.SoundController:Play("Click")
		end
		callback()
	end)
end

function Widgets.OnHold(trove: any, button: GuiButton?, onChange: (held: boolean) -> ())
	if not button then
		return
	end
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end
	trove:Connect(button.InputBegan, function(input: InputObject)
		if isPress(input) then
			onChange(true)
		end
	end)
	trove:Connect(button.InputEnded, function(input: InputObject)
		if isPress(input) then
			onChange(false)
		end
	end)
	trove:Connect(button.MouseLeave, function()
		onChange(false)
	end)
end

function Widgets.SetBadge(button: Instance?, count: number)
	local badge = button and button:FindFirstChild("Badge")
	if not badge or not badge:IsA("GuiObject") then
		return
	end
	badge.Visible = count > 0
	local label = badge:FindFirstChild("Count")
	if label and label:IsA("TextLabel") then
		label.Text = if count > 9 then "9+" elseif count > 1 then tostring(count) else "!"
	end
end

function Widgets.CountUp(
	label: TextLabel?,
	from: number,
	to: number,
	format: (number) -> string,
	duration: number
): () -> ()
	if not label then
		return function() end
	end
	if duration <= 0 or from == to then
		label.Text = format(to)
		return function() end
	end
	local started = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function()
		local alpha = math.min((os.clock() - started) / duration, 1)
		local eased = 1 - (1 - alpha) ^ 3
		label.Text = format(from + (to - from) * eased)
		if alpha >= 1 and connection then
			connection:Disconnect()
			connection = nil
		end
	end)
	return function()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end
end

function Widgets.ServerNow(): number
	return workspace:GetServerTimeNow()
end

function Widgets.ModalScreen(
	context: Types.Context,
	gui: ScreenGui,
	name: string,
	trove: any,
	onOpen: (() -> ())?,
	onClose: (() -> ())?
): Types.Screen
	local panel = gui:FindFirstChild("Panel")
	local close = panel and panel:FindFirstChild("Close", true)
	if close and close:IsA("GuiButton") then
		Widgets.OnClick(trove, close, function()
			context.Close(name)
		end, context.Controllers)
	end
	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			Widgets.Pop(panel)
			local sounds = context.Controllers.SoundController
			if sounds then
				sounds:Play("Open")
			end
			if onOpen then
				onOpen()
			end
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
			if onClose then
				onClose()
			end
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Widgets
