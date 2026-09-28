--!strict

export type Reward = {
	Kind: string,
	Runs: number,
	Minimum: number,
	Minutes: number,
	CarId: string,
}

export type Gift = {
	Minutes: number,
	Reward: Reward,
}

local function cash(runs: number, minimum: number): Reward
	return table.freeze({ Kind = "Cash", Runs = runs, Minimum = minimum, Minutes = 0, CarId = "" })
end

local function boost(minutes: number): Reward
	return table.freeze({ Kind = "Boost", Runs = 0, Minimum = 0, Minutes = minutes, CarId = "" })
end

local function car(carId: string, runs: number, minimum: number): Reward
	return table.freeze({ Kind = "Car", Runs = runs, Minimum = minimum, Minutes = 0, CarId = carId })
end

local daily: { Reward } = {
	cash(5, 500),
	boost(10),
	cash(10, 1500),
	boost(20),
	cash(20, 4000),
	boost(30),
	car("NeonHover", 40, 10000),
}

local gifts: { Gift } = {
	{ Minutes = 2, Reward = cash(3, 300) },
	{ Minutes = 5, Reward = boost(5) },
	{ Minutes = 10, Reward = cash(8, 1000) },
	{ Minutes = 15, Reward = cash(12, 2000) },
	{ Minutes = 20, Reward = boost(10) },
	{ Minutes = 30, Reward = cash(20, 5000) },
	{ Minutes = 45, Reward = cash(30, 8000) },
	{ Minutes = 60, Reward = boost(30) },
}

for _, gift in gifts do
	table.freeze(gift)
end

return table.freeze({
	Daily = table.freeze(daily),
	Gifts = table.freeze(gifts),
	FriendBonus = 0.1,
	MaxFriends = 4,
	PremiumBonus = 0.1,
	GroupBonus = 0.1,
})
