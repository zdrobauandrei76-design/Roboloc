--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Signal = require(ReplicatedStorage.Packages.Signal)

local preview = RunService:IsStudio()

local StoreController = {
	Name = "StoreController",
	Notice = Signal.new() :: Signal.Signal<(string, string)>,
}
local controllers: { [string]: any } = {}
local prices: { [string]: number } = {}
local loading: { [string]: boolean } = {}

function StoreController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function StoreController.Start(_self: any) end

local function itemId(kind: string, key: string): number?
	if kind == "Pass" then
		local pass = Monetization.PassByKey[key]
		return if pass then pass.Id else nil
	end
	local product = Monetization.ProductByKey[key]
	return if product then product.Id else nil
end

local function available(kind: string, key: string): boolean
	local id = itemId(kind, key)
	return id ~= nil and (id > 0 or preview)
end

local function showPreviewNotice(kind: string, key: string)
	local label = if kind == "Pass" then "game pass" else "developer product"
	warn(
		`[StoreController] {key} has Id = 0 in src/shared/Config/Monetization.luau. Create the {label} on the Creator Dashboard and paste its ID there.`
	)
	StoreController.Notice:Fire(`Studio preview: set the {key} ID in Config/Monetization`, "Info")
end

function StoreController.IsPreview(_self: any, kind: string, key: string): boolean
	return preview and itemId(kind, key) == 0
end

function StoreController.OwnsPass(_self: any, key: string): boolean
	local owned = controllers.DataController:Get({ "Passes", key })
	return owned == true
end

function StoreController.PassAvailable(_self: any, key: string): boolean
	return available("Pass", key)
end

function StoreController.ProductAvailable(_self: any, key: string): boolean
	return available("Product", key)
end

function StoreController.PromptPass(_self: any, key: string): boolean
	local pass = Monetization.PassByKey[key]
	if not pass or StoreController:OwnsPass(key) then
		return false
	end
	if pass.Id <= 0 then
		if preview then
			showPreviewNotice("Pass", key)
		end
		return false
	end
	MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, pass.Id)
	return true
end

function StoreController.PromptProduct(_self: any, key: string): boolean
	local product = Monetization.ProductByKey[key]
	if not product then
		return false
	end
	if product.Id <= 0 then
		if preview then
			showPreviewNotice("Product", key)
		end
		return false
	end
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.Id)
	return true
end

function StoreController.GetPrice(_self: any, kind: string, key: string, callback: (price: number?) -> ())
	local id = itemId(kind, key) or 0
	local infoType = if kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
	if id <= 0 then
		callback(nil)
		return
	end
	local cacheKey = `{kind}:{id}`
	local cached = prices[cacheKey]
	if cached then
		callback(cached)
		return
	end
	if loading[cacheKey] then
		task.delay(1, function()
			callback(prices[cacheKey])
		end)
		return
	end
	loading[cacheKey] = true
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		loading[cacheKey] = nil
		local price = if ok
				and type(info) == "table"
				and type((info :: any).PriceInRobux) == "number"
			then (info :: any).PriceInRobux
			else nil
		if price then
			prices[cacheKey] = price
		end
		callback(price)
	end)
end

function StoreController.Destroy(_self: any)
	table.clear(prices)
end

return StoreController
