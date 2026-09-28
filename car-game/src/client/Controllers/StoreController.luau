--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monetization = require(ReplicatedStorage.Config.Monetization)

local StoreController = { Name = "StoreController" }
local controllers: { [string]: any } = {}
local prices: { [string]: number } = {}
local loading: { [string]: boolean } = {}

function StoreController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function StoreController.Start(_self: any) end

function StoreController.OwnsPass(_self: any, key: string): boolean
	local owned = controllers.DataController:Get({ "Passes", key })
	return owned == true
end

function StoreController.PassAvailable(_self: any, key: string): boolean
	local pass = Monetization.PassByKey[key]
	return pass ~= nil and pass.Id > 0
end

function StoreController.ProductAvailable(_self: any, key: string): boolean
	local product = Monetization.ProductByKey[key]
	return product ~= nil and product.Id > 0
end

function StoreController.PromptPass(_self: any, key: string): boolean
	local pass = Monetization.PassByKey[key]
	if not pass or pass.Id <= 0 or StoreController:OwnsPass(key) then
		return false
	end
	MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, pass.Id)
	return true
end

function StoreController.PromptProduct(_self: any, key: string): boolean
	local product = Monetization.ProductByKey[key]
	if not product or product.Id <= 0 then
		return false
	end
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.Id)
	return true
end

function StoreController.GetPrice(_self: any, kind: string, key: string, callback: (price: number?) -> ())
	local id = 0
	local infoType = Enum.InfoType.Product
	if kind == "Pass" then
		local pass = Monetization.PassByKey[key]
		id = if pass then pass.Id else 0
		infoType = Enum.InfoType.GamePass
	else
		local product = Monetization.ProductByKey[key]
		id = if product then product.Id else 0
	end
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
