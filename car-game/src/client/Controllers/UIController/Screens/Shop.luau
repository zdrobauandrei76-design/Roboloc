--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

type Card = {
	Kind: string,
	Key: string,
	Description: TextLabel?,
	Buy: GuiButton?,
	BuyLabel: TextLabel?,
	Price: number?,
}

local Shop = {}

function Shop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local store = controllers.StoreController
	local dataController = controllers.DataController
	local passes = Widgets.Frame(gui, "Passes")
	local products = Widgets.Frame(gui, "Products")
	local passTemplate = Widgets.Frame(gui, "PassTemplate")
	local productTemplate = Widgets.Frame(gui, "ProductTemplate")
	local empty = Widgets.Text(gui, "Empty")
	local cards: { Card } = {}
	local built = false

	local function productDescription(product: Monetization.Product, data: any): string
		if product.Kind == "Cash" and type(data) == "table" then
			return `+{Format.Cash(Stats.RewardCash(data, product.Runs, product.Minimum))} cash!`
		end
		return product.Description
	end

	local function priceText(card: Card): string
		if card.Price then
			return `R$ {card.Price}`
		end
		return if store:IsPreview(card.Kind, card.Key) then "SET ID" else "BUY"
	end

	local function refresh()
		local data = dataController:Get()
		for _, card in cards do
			if card.Kind == "Pass" then
				local owned = store:OwnsPass(card.Key)
				Widgets.SetText(card.BuyLabel, if owned then "OWNED ✅" else priceText(card))
				Widgets.Paint(card.Buy, if owned then "Gray" else "Green")
			else
				local product = Monetization.ProductByKey[card.Key]
				Widgets.SetText(card.Description, productDescription(product, data))
				local soldOut = product.Kind == "StarterPack"
					and type(data) == "table"
					and data.StarterPackOwned
				Widgets.SetText(card.BuyLabel, if soldOut then "OWNED ✅" else priceText(card))
				Widgets.Paint(card.Buy, if soldOut then "Gray" else "Green")
			end
		end
	end

	local function addCard(kind: string, key: string, parent: GuiObject, template: GuiObject, order: number)
		local frame = template:Clone()
		frame.Name = key
		frame.LayoutOrder = order
		frame.Visible = true
		local definition: any = if kind == "Pass"
			then Monetization.PassByKey[key]
			else Monetization.ProductByKey[key]
		Widgets.SetText(frame:FindFirstChild("ItemIcon", true), definition.Emoji)
		Widgets.SetText(frame:FindFirstChild("ItemName", true), definition.Name)
		local description = frame:FindFirstChild("ItemDescription", true)
		Widgets.SetText(description, definition.Description)
		local buy = frame:FindFirstChild("Buy", true)
		local buyLabel = frame:FindFirstChild("BuyLabel", true)
		local card: Card = {
			Kind = kind,
			Key = key,
			Description = if description and description:IsA("TextLabel") then description else nil,
			Buy = if buy and buy:IsA("GuiButton") then buy else nil,
			BuyLabel = if buyLabel and buyLabel:IsA("TextLabel") then buyLabel else nil,
			Price = nil,
		}
		table.insert(cards, card)
		Widgets.OnClick(trove, card.Buy, function()
			if kind == "Pass" then
				store:PromptPass(key)
			else
				local data = dataController:Get()
				if key == "StarterPack" and type(data) == "table" and data.StarterPackOwned then
					return
				end
				store:PromptProduct(key)
			end
		end, controllers)
		store:GetPrice(kind, key, function(price: number?)
			card.Price = price
			refresh()
		end)
		frame.Parent = parent
		trove:Add(frame)
	end

	local function build()
		if built or not passes or not products or not passTemplate or not productTemplate then
			return
		end
		built = true
		passTemplate.Visible = false
		productTemplate.Visible = false
		local count = 0
		for index, pass in Monetization.Passes do
			if store:PassAvailable(pass.Key) then
				count += 1
				addCard("Pass", pass.Key, passes, passTemplate, index)
			end
		end
		for index, product in Monetization.Products do
			if store:ProductAvailable(product.Key) then
				count += 1
				addCard("Product", product.Key, products, productTemplate, index)
			end
		end
		Widgets.SetVisible(empty, count == 0)
	end

	trove:Add(dataController:Observe({}, function()
		if gui.Enabled then
			refresh()
		end
	end))

	return Widgets.ModalScreen(context, gui, "Shop", trove, function()
		build()
		refresh()
	end)
end

return Shop
