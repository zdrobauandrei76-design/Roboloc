--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Rewards = require(ReplicatedStorage.Config.Rewards)
local Stats = require(ReplicatedStorage.Game.Stats)
local Packets = require(ReplicatedStorage.Packets)
local Grants = require(ServerScriptService.Utils.Grants)
local Codes = require(script.Codes)

local RewardService = { Name = "RewardService" }
local services: { [string]: any } = {}
local sessionStarts: { [Player]: number } = {}
local connections: { { Disconnect: (self: any) -> () } } = {}

local function claimedMask(player: Player): number
	local mask = player:GetAttribute("GiftsClaimed")
	return if type(mask) == "number" then mask else 0
end

local function claimDaily(player: Player): boolean
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	if not data or not replica then
		return false
	end
	local today = Stats.DayNumber(os.time())
	local day, claimable = Stats.DailyState(data, today)
	if not claimable then
		return false
	end
	local reward = Rewards.Daily[day]
	if not reward then
		return false
	end
	local ok, description = Grants.Reward(services, player, reward)
	if not ok then
		return false
	end
	replica:SetValues({ "Daily" }, { Streak = day, LastDay = today })
	services.DataService:RequestSave(player)
	Packets.Notify:FireClient(player, `📅 Day {day} reward: {description}`, "Success")
	return true
end

local function claimGift(player: Player, index: number): boolean
	local startedAt = sessionStarts[player]
	local gift = if type(index) == "number" then Rewards.Gifts[index] else nil
	if not startedAt or not gift or not services.DataService:GetData(player) then
		return false
	end
	local bit = 2 ^ (index - 1)
	local mask = claimedMask(player)
	if (mask // bit) % 2 == 1 then
		return false
	end
	if os.time() - startedAt < gift.Minutes * 60 - 1 then
		return false
	end
	local ok, description = Grants.Reward(services, player, gift.Reward)
	if not ok then
		return false
	end
	player:SetAttribute("GiftsClaimed", mask + bit)
	Packets.Notify:FireClient(player, `🎁 Gift: {description}`, "Success")
	return true
end

local function redeemCode(player: Player, text: string): (boolean, string)
	local data = services.DataService:GetData(player)
	if not data or type(text) ~= "string" or #text > 30 then
		return false, "Invalid code"
	end
	local code = string.upper((string.gsub(text, "%s", "")))
	local entry = Codes[code]
	if not entry then
		return false, "Invalid code"
	end
	if entry.ExpiresAt > 0 and os.time() > entry.ExpiresAt then
		return false, "This code has expired"
	end
	if data.Codes[code] then
		return false, "Already redeemed"
	end
	local ok, description = Grants.Reward(services, player, entry.Reward)
	if not ok then
		return false, "Try again in a moment"
	end
	services.DataService:Set(player, { "Codes", code }, true)
	return true, description
end

local function claimGroup(player: Player): boolean
	local data = services.DataService:GetData(player)
	if not data or GameConfig.GroupId <= 0 then
		return false
	end
	local ok, isMember = pcall(player.IsInGroupAsync, player, GameConfig.GroupId)
	if not ok or not isMember or player.Parent ~= Players then
		return false
	end
	services.MultiplierService:SetGroupMember(player, true)
	if not data.GroupClaimed and services.DataService:GetData(player) == data then
		services.DataService:Set(player, { "GroupClaimed" }, true)
		Packets.Notify:FireClient(
			player,
			"🚓 Police Cruiser unlocked! +10% cash for group members",
			"Success"
		)
	end
	return true
end

function RewardService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function RewardService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(function(player: Player, _data: any)
		sessionStarts[player] = os.time()
		player:SetAttribute("SessionStart", workspace:GetServerTimeNow())
		player:SetAttribute("GiftsClaimed", 0)
	end)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			sessionStarts[player] = nil
		end)
	)
	Packets.ClaimDaily.OnServerInvoke = claimDaily
	Packets.ClaimGift.OnServerInvoke = claimGift
	Packets.RedeemCode.OnServerInvoke = redeemCode
	Packets.ClaimGroup.OnServerInvoke = claimGroup
end

function RewardService.Destroy(_self: any)
	Packets.ClaimDaily.OnServerInvoke = nil
	Packets.ClaimGift.OnServerInvoke = nil
	Packets.RedeemCode.OnServerInvoke = nil
	Packets.ClaimGroup.OnServerInvoke = nil
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return RewardService
