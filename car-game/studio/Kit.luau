--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Theme = require(ReplicatedStorage.Config.Theme)

export type LabelOptions = {
	Color: Color3?,
	XAlign: Enum.TextXAlignment?,
	Stroke: number?,
	Visible: boolean?,
	ZIndex: number?,
	Anchor: Vector2?,
}

local Kit = {}

local function color(name: string): (Color3, Color3)
	local theme = Theme :: any
	local top = theme[name]
	local bottom = theme[name .. "Dark"] or top
	return top, bottom
end

function Kit.Corner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

function Kit.Stroke(parent: Instance, thickness: number, strokeColor: Color3, border: boolean): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = strokeColor
	stroke.ApplyStrokeMode = if border then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

function Kit.Gradient(parent: GuiObject, colorName: string): UIGradient
	local top, bottom = color(colorName)
	parent.BackgroundColor3 = Color3.new(1, 1, 1)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Rotation = 90
	gradient.Parent = parent
	return gradient
end

function Kit.Scale(parent: Instance, name: string): UIScale
	local scale = Instance.new("UIScale")
	scale.Name = name
	scale.Parent = parent
	return scale
end

function Kit.Padding(parent: Instance, pixels: number): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = parent
	return padding
end

function Kit.List(
	parent: Instance,
	direction: Enum.FillDirection,
	padding: number,
	horizontal: Enum.HorizontalAlignment?,
	vertical: Enum.VerticalAlignment?
): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.Padding = UDim.new(0, padding)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = vertical or Enum.VerticalAlignment.Top
	layout.Parent = parent
	return layout
end

function Kit.Grid(parent: Instance, cell: Vector2, padding: number): UIGridLayout
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(cell.X, cell.Y)
	layout.CellPadding = UDim2.fromOffset(padding, padding)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = parent
	return layout
end

function Kit.Frame(parent: Instance, name: string, position: UDim2, size: UDim2, colorName: string?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BorderSizePixel = 0
	if colorName then
		Kit.Gradient(frame, colorName)
	else
		frame.BackgroundTransparency = 1
	end
	frame.Parent = parent
	return frame
end

function Kit.Card(
	parent: Instance,
	name: string,
	position: UDim2,
	size: UDim2,
	colorName: string,
	radius: number
): Frame
	local frame = Kit.Frame(parent, name, position, size, colorName)
	Kit.Corner(frame, radius)
	Kit.Stroke(frame, 3, Theme.PanelStroke, true)
	return frame
end

function Kit.Label(
	parent: Instance,
	name: string,
	text: string,
	position: UDim2,
	size: UDim2,
	options: LabelOptions?
): TextLabel
	local settings: LabelOptions = options or {}
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Position = position
	label.Size = size
	label.AnchorPoint = settings.Anchor or Vector2.zero
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Font = Theme.Font
	label.TextColor3 = settings.Color or Theme.Text
	label.TextScaled = true
	label.TextWrapped = true
	label.RichText = true
	label.TextXAlignment = settings.XAlign or Enum.TextXAlignment.Center
	label.Visible = if settings.Visible == nil then true else settings.Visible
	label.ZIndex = settings.ZIndex or 1
	local strokeSize = settings.Stroke or 2
	if strokeSize > 0 then
		Kit.Stroke(label, strokeSize, Theme.TextStroke, false)
	end
	label.Parent = parent
	return label
end

function Kit.Button(
	parent: Instance,
	name: string,
	labelName: string,
	text: string,
	colorName: string,
	position: UDim2,
	size: UDim2
): (TextButton, TextLabel)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = ""
	button.AutoButtonColor = false
	button.Position = position
	button.Size = size
	button.BorderSizePixel = 0
	Kit.Gradient(button, colorName)
	Kit.Corner(button, math.min(18, math.floor(size.Y.Offset / 3)))
	Kit.Stroke(button, 3, Theme.PanelStroke, true)
	Kit.Scale(button, "PressScale")
	local label = Kit.Label(button, labelName, text, UDim2.fromScale(0.06, 0.12), UDim2.fromScale(0.88, 0.76))
	button.Parent = parent
	return button, label
end

function Kit.Badge(parent: Instance)
	local badge = Kit.Frame(parent, "Badge", UDim2.new(1, -18, 0, -8), UDim2.fromOffset(28, 28), "Red")
	badge.Visible = false
	badge.ZIndex = 5
	Kit.Corner(badge, 14)
	Kit.Stroke(badge, 2, Theme.PanelStroke, true)
	Kit.Label(
		badge,
		"Count",
		"!",
		UDim2.fromScale(0.1, 0.1),
		UDim2.fromScale(0.8, 0.8),
		{ ZIndex = 6, Stroke = 1 }
	)
end

function Kit.Screen(name: string, displayOrder: number, insets: Enum.ScreenInsets?): ScreenGui
	local existing = StarterGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.DisplayOrder = displayOrder
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if insets then
		gui.IgnoreGuiInset = true
		gui.ScreenInsets = insets
	end
	Kit.Scale(gui, "UIScale")
	gui.Parent = StarterGui
	return gui
end

function Kit.Panel(gui: ScreenGui, title: string, width: number, height: number): Frame
	gui.Enabled = false
	local dim = Kit.Frame(gui, "Dim", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.5
	dim.Size = UDim2.new(1, 0, 1, 0)
	local panel =
		Kit.Card(gui, "Panel", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(width, height), "Panel", 22)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Active = true
	Kit.Scale(panel, "PopScale")
	Kit.Label(
		panel,
		"Title",
		title,
		UDim2.fromOffset(70, 10),
		UDim2.new(1, -140, 0, 50),
		{ Color = Theme.Primary, Stroke = 3 }
	)
	local close = Kit.Button(
		panel,
		"Close",
		"CloseLabel",
		"X",
		"Red",
		UDim2.new(1, -12, 0, 12),
		UDim2.fromOffset(48, 48)
	)
	close.AnchorPoint = Vector2.new(1, 0)
	return panel
end

return Kit
