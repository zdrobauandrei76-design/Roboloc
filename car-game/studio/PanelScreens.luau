--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Config.Theme)
local Upgrades = require(ReplicatedStorage.Config.Upgrades)
local Kit = require(script.Parent.Kit)

local PanelScreens = {}

local function viewport(parent: Instance, name: string, position: UDim2, size: UDim2): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Theme.PanelDark
	frame.BorderSizePixel = 0
	frame.Ambient = Color3.fromRGB(190, 190, 200)
	frame.LightColor = Color3.fromRGB(255, 255, 255)
	frame.LightDirection = Vector3.new(-1, -1, -0.6)
	Kit.Corner(frame, 14)
	frame.Parent = parent
	return frame
end

local function scroller(parent: Instance, name: string, position: UDim2, size: UDim2): ScrollingFrame
	local frame = Instance.new("ScrollingFrame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ScrollBarThickness = 8
	frame.ScrollBarImageColor3 = Theme.Muted
	frame.CanvasSize = UDim2.new()
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.Parent = parent
	return frame
end

local function upgrades()
	local gui = Kit.Screen("Upgrades", 10)
	local panel = Kit.Panel(gui, "⚡ UPGRADES", 760, 440)
	local cards = Kit.Frame(panel, "Cards", UDim2.fromOffset(20, 72), UDim2.new(1, -40, 0, 300))
	Kit.List(
		cards,
		Enum.FillDirection.Horizontal,
		14,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Top
	)
	for index, upgrade in Upgrades.Order do
		local card = Kit.Card(cards, upgrade.Id, UDim2.new(), UDim2.fromOffset(228, 300), "Card", 18)
		card.LayoutOrder = index
		Kit.Label(card, "Icon", upgrade.Emoji, UDim2.fromOffset(0, 8), UDim2.new(1, 0, 0, 56), { Stroke = 0 })
		Kit.Label(
			card,
			"Title",
			string.upper(upgrade.Name),
			UDim2.fromOffset(10, 64),
			UDim2.new(1, -20, 0, 34),
			{ Color = Theme.Primary, Stroke = 3 }
		)
		Kit.Label(
			card,
			"Level",
			"Lv 0/0",
			UDim2.fromOffset(10, 98),
			UDim2.new(1, -20, 0, 24),
			{ Color = Theme.Muted }
		)
		Kit.Label(card, "Effect", upgrade.Description, UDim2.fromOffset(10, 124), UDim2.new(1, -20, 0, 44))
		Kit.Button(card, "Buy", "Price", "$0", "Green", UDim2.new(0, 12, 1, -110), UDim2.new(1, -24, 0, 52))
		Kit.Button(
			card,
			"Max",
			"MaxLabel",
			"BUY MAX",
			"Blue",
			UDim2.new(0, 12, 1, -52),
			UDim2.new(1, -24, 0, 40)
		)
		Kit.Label(
			card,
			"Maxed",
			"MAX!",
			UDim2.new(0, 12, 1, -110),
			UDim2.new(1, -24, 0, 98),
			{ Color = Theme.Gold, Visible = false }
		)
	end
	Kit.Label(
		panel,
		"Footer",
		"♻️ Rebirth to raise max levels and earn more cash!",
		UDim2.new(0, 20, 1, -54),
		UDim2.new(1, -40, 0, 34),
		{ Color = Theme.Muted }
	)
end

local function garage()
	local gui = Kit.Screen("Garage", 10)
	local panel = Kit.Panel(gui, "🚗 GARAGE", 820, 480)
	local grid = scroller(panel, "Grid", UDim2.fromOffset(20, 70), UDim2.new(1, -40, 1, -88))
	Kit.Grid(grid, Vector2.new(178, 232), 14)
	Kit.Padding(grid, 6)
	local template = Kit.Card(panel, "CarTemplate", UDim2.new(), UDim2.fromOffset(178, 232), "Card", 16)
	template.Visible = false
	viewport(template, "Viewport", UDim2.fromOffset(8, 8), UDim2.new(1, -16, 0, 110))
	Kit.Label(template, "CarName", "Car", UDim2.fromOffset(8, 120), UDim2.new(1, -16, 0, 28), { Stroke = 3 })
	Kit.Label(
		template,
		"CarStats",
		"",
		UDim2.fromOffset(8, 148),
		UDim2.new(1, -16, 0, 22),
		{ Color = Theme.Muted }
	)
	local tag = Kit.Label(
		template,
		"CarTag",
		"",
		UDim2.fromOffset(4, 4),
		UDim2.fromOffset(84, 24),
		{ ZIndex = 3, Stroke = 1, Visible = false }
	)
	tag.BackgroundTransparency = 0
	tag.BackgroundColor3 = Theme.PinkDark
	Kit.Corner(tag, 8)
	Kit.Button(
		template,
		"Action",
		"ActionLabel",
		"EQUIP",
		"Blue",
		UDim2.new(0, 10, 1, -52),
		UDim2.new(1, -20, 0, 42)
	)
end

local function shopCard(parent: Instance, name: string)
	local template = Kit.Card(parent, name, UDim2.new(), UDim2.fromOffset(236, 200), "Card", 16)
	template.Visible = false
	Kit.Label(template, "ItemIcon", "💰", UDim2.fromOffset(0, 6), UDim2.new(1, 0, 0, 48), { Stroke = 0 })
	Kit.Label(
		template,
		"ItemName",
		"Item",
		UDim2.fromOffset(10, 54),
		UDim2.new(1, -20, 0, 30),
		{ Color = Theme.Primary, Stroke = 3 }
	)
	Kit.Label(
		template,
		"ItemDescription",
		"",
		UDim2.fromOffset(10, 86),
		UDim2.new(1, -20, 0, 54),
		{ Color = Theme.Muted }
	)
	Kit.Button(
		template,
		"Buy",
		"BuyLabel",
		"BUY",
		"Green",
		UDim2.new(0, 12, 1, -54),
		UDim2.new(1, -24, 0, 44)
	)
end

local function shop()
	local gui = Kit.Screen("Shop", 10)
	local panel = Kit.Panel(gui, "🛒 SHOP", 820, 480)
	local scroll = scroller(panel, "Scroll", UDim2.fromOffset(20, 70), UDim2.new(1, -40, 1, -88))
	Kit.List(scroll, Enum.FillDirection.Vertical, 10)
	Kit.Padding(scroll, 6)
	local passesTitle = Kit.Label(
		scroll,
		"PassesTitle",
		"⭐ GAME PASSES",
		UDim2.new(),
		UDim2.new(1, -20, 0, 34),
		{ Color = Theme.Gold }
	)
	passesTitle.LayoutOrder = 1
	local passes = Kit.Frame(scroll, "Passes", UDim2.new(), UDim2.new(1, -20, 0, 0))
	passes.LayoutOrder = 2
	passes.AutomaticSize = Enum.AutomaticSize.Y
	Kit.Grid(passes, Vector2.new(236, 200), 12)
	local productsTitle = Kit.Label(
		scroll,
		"ProductsTitle",
		"💵 BOOSTS & CASH",
		UDim2.new(),
		UDim2.new(1, -20, 0, 34),
		{ Color = Theme.Gold }
	)
	productsTitle.LayoutOrder = 3
	local products = Kit.Frame(scroll, "Products", UDim2.new(), UDim2.new(1, -20, 0, 0))
	products.LayoutOrder = 4
	products.AutomaticSize = Enum.AutomaticSize.Y
	Kit.Grid(products, Vector2.new(236, 200), 12)
	local empty = Kit.Label(
		scroll,
		"Empty",
		"Shop items are coming soon!",
		UDim2.new(),
		UDim2.new(1, -20, 0, 40),
		{ Color = Theme.Muted, Visible = false }
	)
	empty.LayoutOrder = 5
	shopCard(panel, "PassTemplate")
	shopCard(panel, "ProductTemplate")
end

local function daily()
	local gui = Kit.Screen("Daily", 10)
	local panel = Kit.Panel(gui, "📅 DAILY REWARDS", 780, 400)
	local days = Kit.Frame(panel, "Days", UDim2.fromOffset(20, 76), UDim2.new(1, -40, 0, 172))
	Kit.List(
		days,
		Enum.FillDirection.Horizontal,
		10,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Top
	)
	for index = 1, 7 do
		local tile = Kit.Card(days, `Day{index}`, UDim2.new(), UDim2.fromOffset(96, 170), "Card", 14)
		tile.LayoutOrder = index
		Kit.Label(
			tile,
			"DayLabel",
			`DAY {index}`,
			UDim2.fromOffset(4, 6),
			UDim2.new(1, -8, 0, 26),
			{ Color = Theme.Primary }
		)
		Kit.Label(tile, "DayIcon", "💵", UDim2.fromOffset(4, 34), UDim2.new(1, -8, 0, 50), { Stroke = 0 })
		Kit.Label(tile, "DayReward", "", UDim2.fromOffset(4, 88), UDim2.new(1, -8, 0, 40))
		Kit.Label(
			tile,
			"DayCheck",
			"✅",
			UDim2.fromOffset(4, 128),
			UDim2.new(1, -8, 0, 36),
			{ Visible = false, Stroke = 0 }
		)
	end
	Kit.Label(
		panel,
		"Streak",
		"🔥 Streak: 0 days",
		UDim2.fromOffset(20, 256),
		UDim2.new(1, -40, 0, 32),
		{ Color = Theme.Muted }
	)
	local claim = Kit.Button(
		panel,
		"Claim",
		"ClaimLabel",
		"CLAIM!",
		"Green",
		UDim2.new(0.5, 0, 1, -18),
		UDim2.fromOffset(340, 62)
	)
	claim.AnchorPoint = Vector2.new(0.5, 1)
end

local function gifts()
	local gui = Kit.Screen("Gifts", 10)
	local panel = Kit.Panel(gui, "🎁 FREE GIFTS", 700, 420)
	Kit.Label(
		panel,
		"Subtitle",
		"Keep playing to unlock more gifts!",
		UDim2.fromOffset(20, 62),
		UDim2.new(1, -40, 0, 26),
		{ Color = Theme.Muted }
	)
	local grid = Kit.Frame(panel, "GiftGrid", UDim2.fromOffset(20, 98), UDim2.new(1, -40, 1, -114))
	Kit.Grid(grid, Vector2.new(150, 140), 12)
	for index = 1, 8 do
		local tile = Kit.Button(
			grid,
			`Gift{index}`,
			"GiftIcon",
			"🎁",
			"Card",
			UDim2.new(),
			UDim2.fromOffset(150, 140)
		)
		tile.LayoutOrder = index
		local icon = tile:FindFirstChild("GiftIcon")
		if icon and icon:IsA("TextLabel") then
			icon.Position = UDim2.fromOffset(10, 6)
			icon.Size = UDim2.new(1, -20, 0, 50)
		end
		Kit.Label(tile, "GiftReward", "", UDim2.fromOffset(8, 58), UDim2.new(1, -16, 0, 32))
		Kit.Label(
			tile,
			"GiftTimer",
			"",
			UDim2.fromOffset(8, 94),
			UDim2.new(1, -16, 0, 34),
			{ Color = Theme.Gold }
		)
	end
end

local function codes()
	local gui = Kit.Screen("Codes", 10)
	local panel = Kit.Panel(gui, "🎟️ CODES", 540, 400)
	local input = Instance.new("TextBox")
	input.Name = "CodeInput"
	input.Position = UDim2.fromOffset(30, 80)
	input.Size = UDim2.new(1, -60, 0, 56)
	input.BackgroundColor3 = Theme.PanelDark
	input.BorderSizePixel = 0
	input.Font = Theme.Font
	input.PlaceholderText = "Enter code..."
	input.PlaceholderColor3 = Theme.Gray
	input.Text = ""
	input.TextColor3 = Theme.Text
	input.TextScaled = true
	input.ClearTextOnFocus = false
	Kit.Corner(input, 14)
	Kit.Stroke(input, 3, Theme.PanelStroke, true)
	Kit.Padding(input, 10)
	input.Parent = panel
	local redeem = Kit.Button(
		panel,
		"Redeem",
		"RedeemLabel",
		"REDEEM",
		"Green",
		UDim2.new(0.5, 0, 0, 148),
		UDim2.fromOffset(240, 54)
	)
	redeem.AnchorPoint = Vector2.new(0.5, 0)
	Kit.Label(
		panel,
		"CodeStatus",
		"",
		UDim2.fromOffset(30, 210),
		UDim2.new(1, -60, 0, 30),
		{ Color = Theme.Muted }
	)
	local group = Kit.Button(
		panel,
		"Group",
		"GroupLabel",
		"👥 Join our group!",
		"Purple",
		UDim2.new(0.5, 0, 1, -20),
		UDim2.new(1, -60, 0, 90)
	)
	group.AnchorPoint = Vector2.new(0.5, 1)
end

local function rebirth()
	local gui = Kit.Screen("Rebirth", 10)
	local panel = Kit.Panel(gui, "♻️ REBIRTH", 580, 430)
	Kit.Label(panel, "Current", "", UDim2.fromOffset(30, 70), UDim2.new(1, -60, 0, 32))
	Kit.Label(panel, "Next", "", UDim2.fromOffset(30, 104), UDim2.new(1, -60, 0, 30), { Color = Theme.Gold })
	Kit.Label(
		panel,
		"Unlocks",
		"",
		UDim2.fromOffset(30, 136),
		UDim2.new(1, -60, 0, 44),
		{ Color = Theme.Muted }
	)
	local progress =
		Kit.Card(panel, "Progress", UDim2.fromOffset(40, 190), UDim2.new(1, -80, 0, 30), "PanelDark", 15)
	local fill = Kit.Frame(progress, "RebirthFill", UDim2.new(), UDim2.fromScale(0, 1), "Purple")
	Kit.Corner(fill, 15)
	Kit.Label(panel, "Cost", "", UDim2.fromOffset(30, 224), UDim2.new(1, -60, 0, 28))
	Kit.Label(
		panel,
		"Warning",
		"Resets your cash and upgrades. You keep all your cars!",
		UDim2.fromOffset(30, 258),
		UDim2.new(1, -60, 0, 44),
		{ Color = Theme.Red }
	)
	local confirm = Kit.Button(
		panel,
		"Confirm",
		"ConfirmLabel",
		"REBIRTH!",
		"Purple",
		UDim2.new(0.5, 0, 1, -20),
		UDim2.fromOffset(320, 62)
	)
	confirm.AnchorPoint = Vector2.new(0.5, 1)
end

local function leaderboard()
	local gui = Kit.Screen("Leaderboard", 10)
	local panel = Kit.Panel(gui, "🏆 TOP JUMPS", 540, 480)
	local list = scroller(panel, "List", UDim2.fromOffset(20, 70), UDim2.new(1, -40, 1, -88))
	Kit.List(list, Enum.FillDirection.Vertical, 6)
	Kit.Padding(list, 4)
	Kit.Label(
		panel,
		"BoardStatus",
		"Loading...",
		UDim2.fromOffset(30, 200),
		UDim2.new(1, -60, 0, 40),
		{ Color = Theme.Muted, Visible = false, ZIndex = 3 }
	)
	local row = Kit.Card(panel, "RowTemplate", UDim2.new(), UDim2.new(1, -16, 0, 48), "Card", 12)
	row.Visible = false
	Kit.Label(row, "Rank", "#1", UDim2.fromOffset(8, 6), UDim2.new(0, 60, 1, -12))
	Kit.Label(
		row,
		"PlayerName",
		"Player",
		UDim2.fromOffset(74, 6),
		UDim2.new(1, -230, 1, -12),
		{ XAlign = Enum.TextXAlignment.Left }
	)
	Kit.Label(
		row,
		"Value",
		"0 m",
		UDim2.new(1, -150, 0, 6),
		UDim2.new(0, 140, 1, -12),
		{ Color = Theme.Gold, XAlign = Enum.TextXAlignment.Right }
	)
end

local function offer()
	local gui = Kit.Screen("Offer", 10)
	local panel = Kit.Panel(gui, "🎁 STARTER PACK", 620, 430)
	viewport(panel, "OfferViewport", UDim2.fromOffset(20, 74), UDim2.fromOffset(260, 200))
	Kit.Label(
		panel,
		"OfferItems",
		"",
		UDim2.fromOffset(296, 74),
		UDim2.new(1, -316, 0, 200),
		{ XAlign = Enum.TextXAlignment.Left }
	)
	Kit.Label(
		panel,
		"OfferNote",
		"⭐ One-time offer • Best value!",
		UDim2.fromOffset(20, 284),
		UDim2.new(1, -40, 0, 30),
		{ Color = Theme.Gold }
	)
	local buy = Kit.Button(
		panel,
		"OfferBuy",
		"OfferBuyLabel",
		"GET IT!",
		"Green",
		UDim2.new(0.5, 0, 1, -20),
		UDim2.fromOffset(360, 70)
	)
	buy.AnchorPoint = Vector2.new(0.5, 1)
end

function PanelScreens.Build()
	upgrades()
	garage()
	shop()
	daily()
	gifts()
	codes()
	rebirth()
	leaderboard()
	offer()
end

return PanelScreens
