--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Upgrades = require(ReplicatedStorage.Config.Upgrades)
local Stats = require(ReplicatedStorage.Game.Stats)
local Packets = require(ReplicatedStorage.Packets)

local UpgradeService = { Name = "UpgradeService" }
local services: { [string]: any } = {}

function UpgradeService.Init(_self: any, registry: { [string]: any })
	services = registry
end

local function buy(player: Player, id: string, count: number): (boolean, number)
	local data = services.DataService:GetData(player)
	if
		not data
		or type(id) ~= "string"
		or not Upgrades.ById[id]
		or type(count) ~= "number"
		or count ~= count
	then
		return false, 0
	end
	local wanted = math.clamp(math.floor(count), 1, 100)
	local level = Stats.UpgradeLevel(data, id)
	local cap = Stats.UpgradeCap(id, data.Rebirths)
	local cash = data.Cash
	local bought = 0
	while bought < wanted and level < cap do
		local cost = Stats.UpgradeCost(id, level)
		if cost > cash then
			break
		end
		cash -= cost
		level += 1
		bought += 1
	end
	if bought == 0 then
		return false, 0
	end
	services.DataService:Set(player, { "Cash" }, cash)
	services.DataService:Set(player, { "Upgrades", id }, level)
	return true, bought
end

function UpgradeService.Start(_self: any)
	Packets.BuyUpgrade.OnServerInvoke = buy
end

function UpgradeService.Destroy(_self: any)
	Packets.BuyUpgrade.OnServerInvoke = nil
end

return UpgradeService
