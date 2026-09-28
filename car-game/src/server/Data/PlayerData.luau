--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Game.Types)

export type Data = Types.PlayerData

local PlayerData = {}

PlayerData.Template = {
	SchemaVersion = 1,
	Cash = 0,
	LastSeenAt = 0,
	Receipts = {},
	TotalEarned = 0,
	BestDistance = 0,
	TotalDistance = 0,
	BestRunCash = 0,
	Launches = 0,
	Rebirths = 0,
	MaxZone = 1,
	Upgrades = {
		Engine = 0,
		Nitro = 0,
		Wings = 0,
	},
	Cars = {},
	EquippedCar = "Buggy",
	Passes = {
		DoubleCash = false,
		VIP = false,
		AutoLaunch = false,
		MegaNitro = false,
	},
	BoostEndsAt = 0,
	BoostSeconds = 0,
	Daily = {
		Streak = 0,
		LastDay = 0,
	},
	Codes = {},
	GroupClaimed = false,
	StarterPackOwned = false,
	Tutorial = 0,
} :: Data

local naturalKeys = {
	"Cash",
	"LastSeenAt",
	"TotalEarned",
	"BestDistance",
	"TotalDistance",
	"BestRunCash",
	"Launches",
	"Rebirths",
	"MaxZone",
	"BoostEndsAt",
	"BoostSeconds",
	"Tutorial",
}

local function natural(value: any): boolean
	return type(value) == "number"
		and value == value
		and math.abs(value) < math.huge
		and value >= 0
		and value % 1 == 0
end

local function optionalTable(value: any): boolean
	return value == nil or type(value) == "table"
end

local function naturalFields(value: any, keys: { string }): boolean
	if value == nil then
		return true
	end
	if type(value) ~= "table" then
		return false
	end
	for _, key in keys do
		if value[key] ~= nil and not natural(value[key]) then
			return false
		end
	end
	return true
end

local function booleanFields(value: any, keys: { string }): boolean
	if value == nil then
		return true
	end
	if type(value) ~= "table" then
		return false
	end
	for _, key in keys do
		if value[key] ~= nil and type(value[key]) ~= "boolean" then
			return false
		end
	end
	return true
end

local function stringSet(value: any): boolean
	if value == nil then
		return true
	end
	if type(value) ~= "table" then
		return false
	end
	for key, flag in value do
		if type(key) ~= "string" or #key == 0 or type(flag) ~= "boolean" then
			return false
		end
	end
	return true
end

function PlayerData.Validate(data: any): boolean
	if type(data) ~= "table" or (data.SchemaVersion ~= nil and data.SchemaVersion ~= 1) then
		return false
	end
	for _, key in naturalKeys do
		if data[key] ~= nil and not natural(data[key]) then
			return false
		end
	end
	if data.Receipts ~= nil then
		if type(data.Receipts) ~= "table" then
			return false
		end
		for purchaseId, grantedAt in data.Receipts do
			if type(purchaseId) ~= "string" or #purchaseId == 0 or not natural(grantedAt) then
				return false
			end
		end
	end
	if not naturalFields(data.Upgrades, { "Engine", "Nitro", "Wings" }) then
		return false
	end
	if not naturalFields(data.Daily, { "Streak", "LastDay" }) then
		return false
	end
	if not booleanFields(data.Passes, { "DoubleCash", "VIP", "AutoLaunch", "MegaNitro" }) then
		return false
	end
	if not stringSet(data.Cars) or not stringSet(data.Codes) then
		return false
	end
	if
		not optionalTable(data.Upgrades)
		or not optionalTable(data.Passes)
		or not optionalTable(data.Daily)
	then
		return false
	end
	if data.EquippedCar ~= nil and type(data.EquippedCar) ~= "string" then
		return false
	end
	for _, key in { "GroupClaimed", "StarterPackOwned" } do
		if data[key] ~= nil and type(data[key]) ~= "boolean" then
			return false
		end
	end
	return true
end

function PlayerData.Migrate(_data: any) end

return PlayerData
