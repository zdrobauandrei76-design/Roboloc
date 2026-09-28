--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cars = require(ReplicatedStorage.Config.Cars)
local Rewards = require(ReplicatedStorage.Config.Rewards)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)

local maxBoostSeconds = 30 * 24 * 60 * 60

local Grants = {}

function Grants.Cash(services: { [string]: any }, player: Player, amount: number): boolean
	local data = services.DataService:GetData(player)
	if not data or amount ~= amount or amount < 0 then
		return false
	end
	return services.DataService:Set(player, { "Cash" }, Stats.AddCash(data.Cash, math.floor(amount)))
end

function Grants.Boost(services: { [string]: any }, player: Player, minutes: number): boolean
	local data = services.DataService:GetData(player)
	if not data or minutes <= 0 then
		return false
	end
	local now = os.time()
	local endsAt = math.min(math.max(now, data.BoostEndsAt) + math.floor(minutes * 60), now + maxBoostSeconds)
	if not services.DataService:Set(player, { "BoostEndsAt" }, endsAt) then
		return false
	end
	services.MultiplierService:Refresh(player)
	return true
end

function Grants.Car(services: { [string]: any }, player: Player, carId: string): boolean
	if not Cars.ById[carId] or not services.DataService:GetData(player) then
		return false
	end
	return services.DataService:Set(player, { "Cars", carId }, true)
end

function Grants.Reward(services: { [string]: any }, player: Player, reward: Rewards.Reward): (boolean, string)
	local data = services.DataService:GetData(player)
	if not data then
		return false, ""
	end
	if reward.Kind == "Boost" then
		return Grants.Boost(services, player, reward.Minutes), `+{reward.Minutes} min of 2x Cash!`
	end
	if reward.Kind == "Car" and not Stats.OwnsCar(data, reward.CarId) then
		local car = Stats.Car(reward.CarId)
		return Grants.Car(services, player, reward.CarId), `{car.Name} unlocked!`
	end
	local amount = Stats.RewardCash(data, reward.Runs, reward.Minimum)
	return Grants.Cash(services, player, amount), `+{Format.Cash(amount)}`
end

return Grants
