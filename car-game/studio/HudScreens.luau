--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Config.Theme)
local Kit = require(script.Parent.Kit)

local HudScreens = {}

local function sideButton(
	parent: Instance,
	name: string,
	icon: string,
	text: string,
	colorName: string,
	order: number,
	labelName: string?
): TextButton
	local button = Kit.Button(parent, name, "Icon", icon, colorName, UDim2.new(), UDim2.fromOffset(88, 78))
	button.LayoutOrder = order
	local iconLabel = button:FindFirstChild("Icon")
	if iconLabel and iconLabel:IsA("TextLabel") then
		iconLabel.Position = UDim2.fromScale(0.15, 0.04)
		iconLabel.Size = UDim2.fromScale(0.7, 0.58)
	end
	Kit.Label(button, labelName or "Label", text, UDim2.fromScale(0.04, 0.62), UDim2.fromScale(0.92, 0.32))
	Kit.Badge(button)
	return button
end

local function hud()
	local gui = Kit.Screen("Hud", 5, Enum.ScreenInsets.DeviceSafeInsets)
	local top = Kit.Frame(gui, "Top", UDim2.new(0.5, 0, 0, 6), UDim2.fromOffset(560, 90))
	top.AnchorPoint = Vector2.new(0.5, 0)

	local cash = Kit.Card(top, "Cash", UDim2.fromOffset(0, 0), UDim2.fromOffset(250, 52), "PanelDark", 26)
	Kit.Label(cash, "CashIcon", "💵", UDim2.fromOffset(8, 6), UDim2.fromOffset(40, 40))
	Kit.Label(
		cash,
		"CashAmount",
		"$0",
		UDim2.fromOffset(52, 6),
		UDim2.new(1, -104, 1, -12),
		{ XAlign = Enum.TextXAlignment.Left, Color = Theme.Gold, Stroke = 3 }
	)
	local plus = Kit.Button(
		cash,
		"CashPlus",
		"CashPlusLabel",
		"+",
		"Green",
		UDim2.new(1, -6, 0.5, 0),
		UDim2.fromOffset(40, 40)
	)
	plus.AnchorPoint = Vector2.new(1, 0.5)

	local multiplier = Kit.Button(
		top,
		"Multiplier",
		"MultiplierValue",
		"x1",
		"Purple",
		UDim2.fromOffset(262, 0),
		UDim2.fromOffset(130, 52)
	)
	local multiplierValue = multiplier:FindFirstChild("MultiplierValue")
	if multiplierValue and multiplierValue:IsA("TextLabel") then
		multiplierValue.Position = UDim2.fromScale(0.36, 0.14)
		multiplierValue.Size = UDim2.fromScale(0.6, 0.72)
	end
	Kit.Label(multiplier, "MultiplierIcon", "💰", UDim2.fromScale(0.05, 0.14), UDim2.fromScale(0.3, 0.72))

	local boost = Kit.Card(top, "Boost", UDim2.fromOffset(404, 0), UDim2.fromOffset(156, 52), "Green", 26)
	boost.Visible = false
	Kit.Label(boost, "BoostIcon", "⏱️", UDim2.fromOffset(6, 8), UDim2.fromOffset(36, 36))
	Kit.Label(boost, "BoostTimer", "2x 0:00", UDim2.fromOffset(42, 8), UDim2.new(1, -48, 1, -16))

	Kit.Label(
		top,
		"Best",
		"🏆 Best: 0 m",
		UDim2.fromOffset(0, 58),
		UDim2.new(1, 0, 0, 28),
		{ Color = Theme.Muted }
	)

	local left = Kit.Frame(gui, "Left", UDim2.new(0, 10, 0.5, 40), UDim2.fromOffset(96, 440))
	left.AnchorPoint = Vector2.new(0, 0.5)
	Kit.List(
		left,
		Enum.FillDirection.Vertical,
		8,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Center
	)
	sideButton(left, "Upgrades", "⚡", "Upgrades", "Blue", 1)
	sideButton(left, "Garage", "🚗", "Garage", "Green", 2)
	sideButton(left, "Rebirth", "♻️", "Rebirth", "Purple", 3)
	sideButton(left, "Shop", "🛒", "Shop", "Primary", 4)
	sideButton(left, "Leaderboard", "🏆", "Top", "Pink", 5)

	local right = Kit.Frame(gui, "Right", UDim2.new(1, -10, 0.5, 40), UDim2.fromOffset(96, 440))
	right.AnchorPoint = Vector2.new(1, 0.5)
	Kit.List(
		right,
		Enum.FillDirection.Vertical,
		8,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Center
	)
	sideButton(right, "Gifts", "🎁", "...", "Green", 1, "GiftTimer")
	sideButton(right, "Daily", "📅", "Daily", "Blue", 2)
	sideButton(right, "Codes", "🎟️", "Codes", "Purple", 3)
	sideButton(right, "Invite", "👥", "+10%", "Primary", 4, "InviteLabel")
	local starter = sideButton(right, "Starter", "🎁", "OFFER", "Pink", 5)
	starter.Visible = false
end

local function launch()
	local gui = Kit.Screen("Launch", 3, Enum.ScreenInsets.DeviceSafeInsets)

	local tapArea = Instance.new("TextButton")
	tapArea.Name = "TapArea"
	tapArea.Text = ""
	tapArea.AutoButtonColor = false
	tapArea.BackgroundTransparency = 1
	tapArea.Size = UDim2.fromScale(1, 1)
	tapArea.Visible = false
	tapArea.Parent = gui

	local flight = Kit.Frame(gui, "Flight", UDim2.new(0.5, 0, 0, 6), UDim2.fromOffset(520, 172))
	flight.AnchorPoint = Vector2.new(0.5, 0)
	flight.Visible = false
	Kit.Label(
		flight,
		"DistanceLabel",
		"0 m",
		UDim2.fromOffset(0, 0),
		UDim2.new(1, 0, 0, 66),
		{ Color = Theme.Gold, Stroke = 4 }
	)
	Kit.Label(flight, "ZoneLabel", "🌳 Meadow x1", UDim2.fromOffset(0, 66), UDim2.new(1, 0, 0, 30))
	local progress =
		Kit.Card(flight, "Progress", UDim2.new(0.5, 0, 0, 100), UDim2.fromOffset(360, 18), "PanelDark", 9)
	progress.AnchorPoint = Vector2.new(0.5, 0)
	local fill = Kit.Frame(progress, "ProgressFill", UDim2.fromScale(0, 0), UDim2.fromScale(0, 1), "Primary")
	Kit.Corner(fill, 9)
	Kit.Label(
		flight,
		"NextLabel",
		"",
		UDim2.fromOffset(0, 120),
		UDim2.new(1, 0, 0, 24),
		{ Color = Theme.Muted }
	)
	Kit.Label(
		flight,
		"SpeedLabel",
		"0 km/h",
		UDim2.fromOffset(0, 146),
		UDim2.new(1, 0, 0, 24),
		{ Color = Theme.Blue }
	)

	local meter = Kit.Frame(gui, "Meter", UDim2.new(0.5, 0, 1, -120), UDim2.fromOffset(440, 100))
	meter.AnchorPoint = Vector2.new(0.5, 1)
	meter.Visible = false
	Kit.Label(
		meter,
		"MeterPrompt",
		"TAP WHEN GREEN!",
		UDim2.fromOffset(0, 0),
		UDim2.new(1, 0, 0, 40),
		{ Stroke = 3 }
	)
	local bar = Kit.Card(meter, "Bar", UDim2.fromOffset(0, 50), UDim2.new(1, 0, 0, 40), "Red", 12)
	local barGradient = bar:FindFirstChildOfClass("UIGradient")
	if barGradient then
		barGradient.Rotation = 0
		barGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.RedDark),
			ColorSequenceKeypoint.new(0.12, Theme.PrimaryDark),
			ColorSequenceKeypoint.new(0.2, Theme.Primary),
			ColorSequenceKeypoint.new(0.8, Theme.Primary),
			ColorSequenceKeypoint.new(0.88, Theme.PrimaryDark),
			ColorSequenceKeypoint.new(1, Theme.RedDark),
		})
	end
	local green = Kit.Frame(bar, "Green", UDim2.fromScale(0.35, 0), UDim2.fromScale(0.3, 1))
	green.BackgroundTransparency = 0
	green.BackgroundColor3 = Theme.Green
	local perfect = Kit.Frame(bar, "Perfect", UDim2.fromScale(0.45, 0), UDim2.fromScale(0.1, 1))
	perfect.BackgroundTransparency = 0
	perfect.BackgroundColor3 = Color3.fromRGB(175, 255, 110)
	for _, x in { 0, 1 } do
		local edge = Kit.Frame(
			perfect,
			if x == 0 then "EdgeLeft" else "EdgeRight",
			UDim2.fromScale(x, 0),
			UDim2.new(0, 3, 1, 0)
		)
		edge.AnchorPoint = Vector2.new(0.5, 0)
		edge.BackgroundTransparency = 0
		edge.BackgroundColor3 = Theme.Text
	end
	local needle = Kit.Frame(bar, "Needle", UDim2.fromScale(0, 0.5), UDim2.new(0, 10, 1, 18), "Text")
	needle.AnchorPoint = Vector2.new(0.5, 0.5)
	Kit.Corner(needle, 5)
	Kit.Stroke(needle, 2, Theme.PanelStroke, true)

	local launchButton, launchLabel = Kit.Button(
		gui,
		"LaunchButton",
		"LaunchLabel",
		"LAUNCH!",
		"Primary",
		UDim2.new(0.5, 0, 1, -22),
		UDim2.fromOffset(300, 96)
	)
	launchButton.AnchorPoint = Vector2.new(0.5, 1)
	launchLabel.Position = UDim2.fromScale(0.06, 0.06)
	launchLabel.Size = UDim2.fromScale(0.88, 0.62)
	Kit.Scale(launchLabel, "PulseScale")
	Kit.Label(
		launchButton,
		"LaunchHint",
		"",
		UDim2.fromScale(0.1, 0.66),
		UDim2.fromScale(0.8, 0.26),
		{ Color = Theme.PanelDark, Stroke = 0 }
	)

	local autoButton = Kit.Button(
		gui,
		"AutoButton",
		"AutoLabel",
		"AUTO",
		"Purple",
		UDim2.new(0.5, 166, 1, -38),
		UDim2.fromOffset(120, 64)
	)
	autoButton.AnchorPoint = Vector2.new(0, 1)
	Kit.Label(
		autoButton,
		"AutoLock",
		"🔒",
		UDim2.new(1, -20, 0, -12),
		UDim2.fromOffset(30, 30),
		{ ZIndex = 3 }
	)

	local boostButton, boostLabel = Kit.Button(
		gui,
		"BoostButton",
		"BoostLabel",
		"🔥 NITRO",
		"Red",
		UDim2.new(1, -28, 1, -28),
		UDim2.fromOffset(190, 150)
	)
	boostButton.AnchorPoint = Vector2.new(1, 1)
	boostButton.Visible = false
	boostLabel.Position = UDim2.fromScale(0.06, 0.08)
	boostLabel.Size = UDim2.fromScale(0.88, 0.5)
	Kit.Label(
		boostButton,
		"BoostHint",
		"HOLD",
		UDim2.fromScale(0.25, 0.6),
		UDim2.fromScale(0.5, 0.15),
		{ Color = Theme.Muted }
	)
	local fuel =
		Kit.Card(boostButton, "Fuel", UDim2.new(0.1, 0, 1, -26), UDim2.new(0.8, 0, 0, 14), "PanelDark", 7)
	local fuelFill = Kit.Frame(fuel, "FuelFill", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), "Gold")
	Kit.Corner(fuelFill, 7)

	local callout = Kit.Label(
		gui,
		"Callout",
		"PERFECT!",
		UDim2.fromScale(0.5, 0.54),
		UDim2.fromOffset(720, 80),
		{ Color = Theme.Gold, Stroke = 5, Visible = false, Anchor = Vector2.new(0.5, 0.5) }
	)
	Kit.Scale(callout, "PopScale")
end

local function results()
	local gui = Kit.Screen("Results", 6)
	gui.Enabled = false
	local card = Kit.Card(gui, "Card", UDim2.new(0.5, 0, 1, -20), UDim2.fromOffset(460, 300), "Panel", 22)
	card.AnchorPoint = Vector2.new(0.5, 1)
	Kit.Scale(card, "PopScale")
	Kit.Label(
		card,
		"ResultTitle",
		"NICE JUMP!",
		UDim2.fromOffset(20, 10),
		UDim2.new(1, -40, 0, 42),
		{ Stroke = 3 }
	)
	Kit.Label(
		card,
		"ResultDistance",
		"0 m",
		UDim2.fromOffset(20, 54),
		UDim2.new(1, -40, 0, 58),
		{ Color = Theme.Gold, Stroke = 4 }
	)
	Kit.Label(
		card,
		"ResultZone",
		"",
		UDim2.fromOffset(20, 114),
		UDim2.new(1, -40, 0, 26),
		{ Color = Theme.Muted }
	)
	Kit.Label(
		card,
		"ResultEarned",
		"+$0",
		UDim2.fromOffset(20, 142),
		UDim2.new(1, -40, 0, 44),
		{ Color = Theme.Green, Stroke = 3 }
	)
	Kit.Label(
		card,
		"ResultMultiplier",
		"",
		UDim2.fromOffset(20, 188),
		UDim2.new(1, -40, 0, 22),
		{ Color = Theme.Muted }
	)
	Kit.Label(
		card,
		"ResultTiming",
		"",
		UDim2.fromOffset(20, 210),
		UDim2.new(1, -40, 0, 20),
		{ Color = Theme.Blue }
	)
	local best = Kit.Label(
		card,
		"ResultBest",
		"🏆 NEW BEST!",
		UDim2.new(1, 8, 0, -16),
		UDim2.fromOffset(160, 38),
		{ Anchor = Vector2.new(1, 0), Visible = false, ZIndex = 4 }
	)
	best.BackgroundTransparency = 0
	best.BackgroundColor3 = Theme.GoldDark
	best.Rotation = 8
	Kit.Corner(best, 12)
	Kit.Button(
		card,
		"DoubleButton",
		"DoubleLabel",
		"💰 2x Cash!",
		"Gold",
		UDim2.new(0, 16, 1, -64),
		UDim2.new(0.5, -24, 0, 50)
	)
	Kit.Button(
		card,
		"ContinueButton",
		"ContinueLabel",
		"CONTINUE",
		"Green",
		UDim2.new(0.5, 8, 1, -64),
		UDim2.new(0.5, -24, 0, 50)
	)
end

local function notifications()
	local gui = Kit.Screen("Notifications", 20, Enum.ScreenInsets.DeviceSafeInsets)
	local stack = Kit.Frame(gui, "Stack", UDim2.new(0.5, 0, 0, 100), UDim2.fromOffset(440, 300))
	stack.AnchorPoint = Vector2.new(0.5, 0)
	Kit.List(stack, Enum.FillDirection.Vertical, 6)
	local template = Kit.Card(gui, "ToastTemplate", UDim2.new(), UDim2.fromOffset(420, 46), "Blue", 14)
	template.Visible = false
	Kit.Scale(template, "PopScale")
	Kit.Label(template, "ToastText", "", UDim2.fromOffset(12, 6), UDim2.new(1, -24, 1, -12))
	local banner = Kit.Card(gui, "Banner", UDim2.new(0.5, 0, 0, 176), UDim2.fromOffset(660, 52), "Gold", 18)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Visible = false
	Kit.Scale(banner, "PopScale")
	Kit.Label(banner, "BannerText", "", UDim2.fromOffset(16, 8), UDim2.new(1, -32, 1, -16), { Stroke = 3 })
end

local function tutorial()
	local gui = Kit.Screen("Tutorial", 15, Enum.ScreenInsets.DeviceSafeInsets)
	local hint = Kit.Card(gui, "Hint", UDim2.new(0.5, 0, 0, 240), UDim2.fromOffset(580, 44), "PanelDark", 16)
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Visible = false
	local stroke = hint:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = Theme.Gold
	end
	Kit.Label(
		hint,
		"HintText",
		"",
		UDim2.fromOffset(14, 6),
		UDim2.new(1, -28, 1, -12),
		{ Color = Theme.Gold }
	)
	Kit.Label(
		gui,
		"Arrow",
		"👇",
		UDim2.new(),
		UDim2.fromOffset(60, 60),
		{ Anchor = Vector2.new(0.5, 1), Visible = false, Stroke = 0 }
	)
end

local function transition()
	local gui = Kit.Screen("Transition", 50, Enum.ScreenInsets.None)
	local fade = Kit.Frame(gui, "Fade", UDim2.new(), UDim2.fromScale(1, 1))
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.BackgroundTransparency = 1
	fade.Visible = false
end

function HudScreens.Build()
	hud()
	launch()
	results()
	notifications()
	tutorial()
	transition()
end

return HudScreens
