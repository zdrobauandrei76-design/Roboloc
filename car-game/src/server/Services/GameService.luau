--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Packets = require(ReplicatedStorage.Packets)

local maxTutorialStep = 20

local GameService: Lifecycle.System = { Name = "GameService" }
local services: { [string]: any } = {}
local connections: { { Disconnect: (self: any) -> () } } = {}

function GameService.Init(_self: Lifecycle.System, registry: { [string]: any })
	services = registry
end

function GameService.Start(_self: Lifecycle.System)
	Packets.Ping.OnServerInvoke = function(_player: Player)
		return workspace:GetServerTimeNow()
	end
	table.insert(
		connections,
		Packets.SetTutorial.OnServerEvent:Connect(function(player: Player, step: number)
			local data = services.DataService:GetData(player)
			if not data or type(step) ~= "number" or step % 1 ~= 0 then
				return
			end
			if step > data.Tutorial and step <= maxTutorialStep then
				services.DataService:Set(player, { "Tutorial" }, step)
			end
		end)
	)
	print(`[{GameConfig.Name}] Server services ready`)
end

function GameService.Destroy(_self: Lifecycle.System)
	Packets.Ping.OnServerInvoke = nil
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return GameService
