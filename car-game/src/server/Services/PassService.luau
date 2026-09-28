--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Packets = require(ReplicatedStorage.Packets)

local PassService = { Name = "PassService" }
local services: { [string]: any } = {}
local passById: { [number]: Monetization.Pass } = {}
local connections: { { Disconnect: (self: any) -> () } } = {}

local function setPass(player: Player, key: string, owned: boolean)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	services.DataService:Set(player, { "Passes", key }, owned)
	if key == "VIP" then
		player:SetAttribute("VIP", owned)
	end
	services.MultiplierService:Refresh(player)
end

local function checkPasses(player: Player)
	for _, pass in Monetization.Passes do
		if pass.Id > 0 and player.Parent == Players then
			local ok, owns =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and type(owns) == "boolean" and player.Parent == Players then
				setPass(player, pass.Key, owns)
			end
		end
	end
end

function PassService.Init(_self: any, registry: { [string]: any })
	services = registry
	for _, pass in Monetization.Passes do
		if pass.Id > 0 then
			passById[pass.Id] = pass
		end
	end
end

function PassService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(function(player: Player, data: any)
		player:SetAttribute("VIP", data.Passes.VIP == true)
		task.spawn(checkPasses, player)
	end)
	table.insert(
		connections,
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(
			function(player: Player, passId: number, purchased: boolean)
				local pass = passById[passId]
				if not purchased or not pass then
					return
				end
				setPass(player, pass.Key, true)
				Packets.Notify:FireClient(player, `{pass.Emoji} {pass.Name} unlocked! Thank you!`, "Success")
			end
		)
	)
end

function PassService.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return PassService
