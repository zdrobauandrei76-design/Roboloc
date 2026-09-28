--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rewards = require(ReplicatedStorage.Config.Rewards)

export type Code = {
	Reward: Rewards.Reward,
	ExpiresAt: number,
}

local function cash(runs: number, minimum: number): Rewards.Reward
	return table.freeze({ Kind = "Cash", Runs = runs, Minimum = minimum, Minutes = 0, CarId = "" })
end

local function boost(minutes: number): Rewards.Reward
	return table.freeze({ Kind = "Boost", Runs = 0, Minimum = 0, Minutes = minutes, CarId = "" })
end

local codes: { [string]: Code } = {
	LAUNCH = { Reward = cash(5, 1000), ExpiresAt = 0 },
	NITRO = { Reward = boost(10), ExpiresAt = 0 },
	RELEASE = { Reward = cash(10, 2500), ExpiresAt = 0 },
}

for _, code in codes do
	table.freeze(code)
end

return table.freeze(codes)
