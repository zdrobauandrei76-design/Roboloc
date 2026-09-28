--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Grants = require(ServerScriptService.Utils.Grants)

export type Grant = (player: Player, services: { [string]: any }) -> boolean

local function cashAmount(services: { [string]: any }, player: Player, product: Monetization.Product): number?
	local data = services.DataService:GetData(player)
	if not data then
		return nil
	end
	return Stats.RewardCash(data, product.Runs, product.Minimum)
end

local function makeGrant(product: Monetization.Product): Grant
	if product.Kind == "StarterPack" then
		return function(player: Player, services: { [string]: any }): boolean
			local amount = cashAmount(services, player, product)
			if not amount then
				return false
			end
			if not Grants.Car(services, player, "Rocket") then
				return false
			end
			services.DataService:Set(player, { "StarterPackOwned" }, true)
			Grants.Boost(services, player, product.Minutes)
			Grants.Cash(services, player, amount)
			Packets.Notify:FireClient(player, `🎁 Starter Pack unlocked! +{Format.Cash(amount)}`, "Success")
			return true
		end
	elseif product.Kind == "Boost" then
		return function(player: Player, services: { [string]: any }): boolean
			if not Grants.Boost(services, player, product.Minutes) then
				return false
			end
			Packets.Notify:FireClient(player, `⏱️ +{product.Minutes} min of 2x Cash!`, "Success")
			return true
		end
	end
	return function(player: Player, services: { [string]: any }): boolean
		local amount = cashAmount(services, player, product)
		if not amount or not Grants.Cash(services, player, amount) then
			return false
		end
		Packets.Notify:FireClient(player, `{product.Emoji} +{Format.Cash(amount)}!`, "Success")
		return true
	end
end

local Products: { [number]: Grant } = {}

for _, product in Monetization.Products do
	if product.Id > 0 then
		Products[product.Id] = makeGrant(product)
	end
end

return Products
