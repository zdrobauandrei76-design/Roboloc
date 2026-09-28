--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Rewards = require(ReplicatedStorage.Config.Rewards)
local Stats = require(ReplicatedStorage.Game.Stats)

local maxBoostSeconds = 30 * 24 * 60 * 60

local MultiplierService = { Name = "MultiplierService" }
local services: { [string]: any } = {}
local friends: { [Player]: { [Player]: boolean } } = {}
local groupMembers: { [Player]: boolean } = {}
local boostActive: { [Player]: boolean } = {}
local connections: { { Disconnect: (self: any) -> () } } = {}
local loopThread: thread? = nil

local function friendCount(player: Player): number
	local count = 0
	local list = friends[player]
	if list then
		for other in list do
			if other.Parent == Players then
				count += 1
			end
		end
	end
	return math.min(count, Rewards.MaxFriends)
end

function MultiplierService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function MultiplierService.GetSocialBonus(_self: any, player: Player): number
	local bonus = 1 + friendCount(player) * Rewards.FriendBonus
	if player.MembershipType == Enum.MembershipType.Premium then
		bonus += Rewards.PremiumBonus
	end
	if groupMembers[player] then
		bonus += Rewards.GroupBonus
	end
	return bonus
end

function MultiplierService.GetMultiplier(_self: any, player: Player): number
	local data = services.DataService:GetData(player)
	if not data then
		return 1
	end
	local multiplier = Stats.BaseMultiplier(data)
	if data.Passes.DoubleCash then
		multiplier *= Monetization.DoubleCashMultiplier
	end
	if data.Passes.VIP then
		multiplier *= Monetization.VipMultiplier
	end
	if data.BoostEndsAt > os.time() then
		multiplier *= Monetization.BoostMultiplier
	end
	return multiplier * MultiplierService:GetSocialBonus(player)
end

function MultiplierService.Refresh(_self: any, player: Player)
	if player.Parent ~= Players then
		return
	end
	local data = services.DataService:GetData(player)
	boostActive[player] = data ~= nil and data.BoostEndsAt > os.time()
	player:SetAttribute("CashMultiplier", MultiplierService:GetMultiplier(player))
	player:SetAttribute("SocialBonus", MultiplierService:GetSocialBonus(player))
	player:SetAttribute("FriendCount", friendCount(player))
	player:SetAttribute("GroupMember", groupMembers[player] == true)
end

function MultiplierService.SetGroupMember(_self: any, player: Player, isMember: boolean)
	groupMembers[player] = isMember
	MultiplierService:Refresh(player)
end

local function linkFriends(player: Player)
	for _, other in Players:GetPlayers() do
		if other ~= player and player.Parent == Players then
			local ok, isFriend = pcall(player.IsFriendsWithAsync, player, other.UserId)
			if ok and isFriend and player.Parent == Players and other.Parent == Players then
				friends[player] = friends[player] or {}
				friends[other] = friends[other] or {}
				friends[player][other] = true
				friends[other][player] = true
				MultiplierService:Refresh(other)
			end
		end
	end
	MultiplierService:Refresh(player)
end

local function checkGroup(player: Player)
	if GameConfig.GroupId <= 0 then
		return
	end
	local ok, isMember = pcall(player.IsInGroupAsync, player, GameConfig.GroupId)
	if ok and player.Parent == Players then
		MultiplierService:SetGroupMember(player, isMember == true)
	end
end

local function onLoaded(player: Player, data: any)
	local replica = services.DataService:GetReplica(player)
	if replica then
		local now = os.time()
		local remaining = if data.BoostSeconds > 0
			then data.BoostSeconds
			else math.max(0, data.BoostEndsAt - data.LastSeenAt)
		remaining = math.min(remaining, maxBoostSeconds)
		replica:SetValues({}, {
			BoostEndsAt = if remaining > 0 then now + remaining else 0,
			BoostSeconds = 0,
		})
	end
	MultiplierService:Refresh(player)
	task.spawn(linkFriends, player)
	task.spawn(checkGroup, player)
end

function MultiplierService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(onLoaded)
	services.DataService.PlayerReleasing:Connect(function(_player: Player, data: any)
		data.BoostSeconds = math.max(0, data.BoostEndsAt - os.time())
	end)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			local list = friends[player]
			friends[player] = nil
			groupMembers[player] = nil
			boostActive[player] = nil
			if list then
				for other in list do
					local otherList = friends[other]
					if otherList then
						otherList[player] = nil
					end
					MultiplierService:Refresh(other)
				end
			end
		end)
	)
	table.insert(
		connections,
		Players.PlayerMembershipChanged:Connect(function(player: Player)
			MultiplierService:Refresh(player)
		end)
	)
	loopThread = task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				local data = services.DataService:GetData(player)
				if data and (data.BoostEndsAt > now) ~= (boostActive[player] == true) then
					MultiplierService:Refresh(player)
				end
			end
		end
	end)
end

function MultiplierService.Destroy(_self: any)
	if loopThread then
		task.cancel(loopThread)
		loopThread = nil
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return MultiplierService
