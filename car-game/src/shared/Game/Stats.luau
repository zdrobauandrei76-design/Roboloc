--!strict

local Cars = require(script.Parent.Parent.Config.Cars)
local FlightConfig = require(script.Parent.Parent.Config.Flight)
local GameConfig = require(script.Parent.Parent.Config.GameConfig)
local Rewards = require(script.Parent.Parent.Config.Rewards)
local Upgrades = require(script.Parent.Parent.Config.Upgrades)
local Zones = require(script.Parent.Parent.Config.Zones)
local Track = require(script.Parent.Track)
local Types = require(script.Parent.Types)

local maxSafeInteger = 9007199254740991

local Stats = {}

Stats.MaxSafeInteger = maxSafeInteger

function Stats.UpgradeLevel(data: Types.PlayerData, id: string): number
	local level = (data.Upgrades :: any)[id]
	return if type(level) == "number" then level else 0
end

function Stats.UpgradeCap(id: string, rebirths: number): number
	local upgrade = Upgrades.ById[id]
	if not upgrade then
		return 0
	end
	return math.min(upgrade.MaxLevel, upgrade.BaseCap + upgrade.CapPerRebirth * rebirths)
end

function Stats.UpgradeCost(id: string, level: number): number
	local upgrade = Upgrades.ById[id]
	if not upgrade then
		return math.huge
	end
	return math.floor(upgrade.BaseCost * upgrade.CostGrowth ^ level)
end

function Stats.Car(id: string): Cars.Car
	return Cars.ById[id] or Cars.ById[Cars.DefaultId]
end

function Stats.OwnsCar(data: Types.PlayerData, id: string): boolean
	local car = Cars.ById[id]
	if not car then
		return false
	end
	if car.Source == "Shop" and car.Price == 0 then
		return true
	end
	if car.Source == "VIP" then
		return data.Passes.VIP == true
	end
	if car.Source == "Group" then
		return data.GroupClaimed == true
	end
	return data.Cars[id] == true
end

function Stats.EquippedCar(data: Types.PlayerData): Cars.Car
	if Stats.OwnsCar(data, data.EquippedCar) then
		return Stats.Car(data.EquippedCar)
	end
	return Cars.ById[Cars.DefaultId]
end

function Stats.LaunchSpeed(engine: number, carSpeed: number): number
	return FlightConfig.BaseSpeed * FlightConfig.SpeedGrowth ^ engine * carSpeed
end

function Stats.Fuel(nitro: number, hasMegaNitro: boolean): number
	local fuel = FlightConfig.FuelBase + FlightConfig.FuelPerLevel * nitro
	return if hasMegaNitro then fuel * FlightConfig.MegaNitroFuel else fuel
end

function Stats.Thrust(nitro: number): number
	return FlightConfig.ThrustBase * FlightConfig.ThrustGrowth ^ nitro
end

function Stats.Glide(wings: number): number
	return FlightConfig.GlideMax * wings / (wings + FlightConfig.GlideHalfLevel)
end

function Stats.RunParams(data: Types.PlayerData): Types.RunParams
	local car = Stats.EquippedCar(data)
	local nitro = Stats.UpgradeLevel(data, "Nitro")
	return {
		Speed = Stats.LaunchSpeed(Stats.UpgradeLevel(data, "Engine"), car.Speed),
		Fuel = Stats.Fuel(nitro, data.Passes.MegaNitro == true),
		Thrust = Stats.Thrust(nitro),
		Glide = Stats.Glide(Stats.UpgradeLevel(data, "Wings")),
	}
end

function Stats.TimingFactor(quality: number): number
	return FlightConfig.TimingBase + FlightConfig.TimingRange * math.clamp(quality, 0, 1)
end

function Stats.TimingQuality(needle: number): number
	return math.clamp(1 - math.abs(needle - 0.5) * 2, 0, 1)
end

function Stats.NeedlePosition(elapsed: number): number
	local phase = (elapsed * FlightConfig.NeedleCyclesPerSecond) % 1
	return if phase < 0.5 then phase * 2 else 2 - phase * 2
end

function Stats.TimingLabel(quality: number, tapped: boolean): string
	if not tapped then
		return "MISSED!"
	elseif quality >= FlightConfig.PerfectQuality then
		return "PERFECT!"
	elseif quality >= FlightConfig.GreatQuality then
		return "GREAT!"
	elseif quality >= FlightConfig.GoodQuality then
		return "GOOD"
	end
	return "OK"
end

function Stats.RebirthCost(rebirths: number): number
	return math.floor(60000 * 3.2 ^ rebirths)
end

function Stats.RebirthMultiplier(rebirths: number): number
	return 1 + 0.5 * rebirths
end

function Stats.CanRebirth(data: Types.PlayerData): boolean
	return data.Rebirths < GameConfig.MaxRebirths and data.Cash >= Stats.RebirthCost(data.Rebirths)
end

function Stats.ZoneIndexAt(distance: number): number
	local index = 1
	for zoneIndex, zone in Zones do
		if distance >= zone.Start then
			index = zoneIndex
		end
	end
	return index
end

function Stats.ZoneEnd(index: number): number
	local nextZone = Zones[index + 1]
	return if nextZone then nextZone.Start else Track.WorldLength
end

function Stats.ZoneCash(distance: number): number
	local total = 0
	for index, zone in Zones do
		local zoneEnd = Stats.ZoneEnd(index)
		if distance > zone.Start then
			total += (math.min(distance, zoneEnd) - zone.Start) * zone.Multiplier
		end
	end
	return total
end

function Stats.BaseMultiplier(data: Types.PlayerData): number
	return Stats.EquippedCar(data).Cash * Stats.RebirthMultiplier(data.Rebirths)
end

function Stats.RewardCash(data: Types.PlayerData, runs: number, minimum: number): number
	return math.min(maxSafeInteger, math.max(minimum, math.floor(data.BestRunCash * runs)))
end

function Stats.DayNumber(unixTime: number): number
	return math.floor(unixTime / 86400)
end

function Stats.DailyState(data: Types.PlayerData, today: number): (number, boolean)
	local claimable = data.Daily.LastDay < today
	local continues = data.Daily.LastDay == today - 1
	if not claimable then
		return math.clamp(data.Daily.Streak, 1, #Rewards.Daily), false
	end
	local nextDay = if continues then data.Daily.Streak % #Rewards.Daily + 1 else 1
	return nextDay, true
end

function Stats.AddCash(balance: number, amount: number): number
	return math.clamp(balance + amount, 0, maxSafeInteger)
end

return Stats
