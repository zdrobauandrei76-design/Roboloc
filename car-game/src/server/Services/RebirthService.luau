--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)

local RebirthService = { Name = "RebirthService" }
local services: { [string]: any } = {}

function RebirthService.Init(_self: any, registry: { [string]: any })
	services = registry
end

local function rebirth(player: Player): boolean
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	if not data or not replica or not Stats.CanRebirth(data) then
		return false
	end
	if services.LaunchService:IsRunning(player) then
		return false
	end
	local rebirths = data.Rebirths + 1
	replica:SetValues({}, { Cash = 0, Rebirths = rebirths })
	replica:SetValues({ "Upgrades" }, { Engine = 0, Nitro = 0, Wings = 0 })
	services.MultiplierService:Refresh(player)
	services.DataService:RequestSave(player)
	Packets.Notify:FireClient(
		player,
		`♻️ Rebirth {rebirths}! Cash bonus is now {Format.Multiplier(Stats.RebirthMultiplier(rebirths))}`,
		"Success"
	)
	return true
end

function RebirthService.Start(_self: any)
	Packets.Rebirth.OnServerInvoke = rebirth
end

function RebirthService.Destroy(_self: any)
	Packets.Rebirth.OnServerInvoke = nil
end

return RebirthService
