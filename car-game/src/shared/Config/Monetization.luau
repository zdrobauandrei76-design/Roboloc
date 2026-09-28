--!strict

export type Pass = {
	Key: string,
	Id: number,
	Name: string,
	Emoji: string,
	Description: string,
}

export type Product = {
	Key: string,
	Id: number,
	Name: string,
	Emoji: string,
	Description: string,
	Kind: string,
	Runs: number,
	Minimum: number,
	Minutes: number,
}

local passes: { Pass } = {
	{
		Key = "DoubleCash",
		Id = 0,
		Name = "2x Cash",
		Emoji = "💰",
		Description = "Double cash from every launch, forever!",
	},
	{
		Key = "VIP",
		Id = 0,
		Name = "VIP",
		Emoji = "👑",
		Description = "1.5x cash, Golden Supercar and a VIP chat tag!",
	},
	{
		Key = "AutoLaunch",
		Id = 0,
		Name = "Auto Launch",
		Emoji = "🤖",
		Description = "Launches, times and boosts for you. Earn while AFK!",
	},
	{
		Key = "MegaNitro",
		Id = 0,
		Name = "Mega Nitro",
		Emoji = "🚀",
		Description = "50% more nitro fuel on every launch!",
	},
}

local products: { Product } = {
	{
		Key = "StarterPack",
		Id = 0,
		Name = "Starter Pack",
		Emoji = "🎁",
		Description = "Rocket Racer car, 30 min of 2x Cash and a cash bundle!",
		Kind = "StarterPack",
		Runs = 25,
		Minimum = 5000,
		Minutes = 30,
	},
	{
		Key = "CashBoost",
		Id = 0,
		Name = "2x Cash Boost",
		Emoji = "⏱️",
		Description = "Double cash for 30 minutes. Stacks!",
		Kind = "Boost",
		Runs = 0,
		Minimum = 0,
		Minutes = 30,
	},
	{
		Key = "CashSmall",
		Id = 0,
		Name = "Pile of Cash",
		Emoji = "💵",
		Description = "Cash worth 10 of your best launches",
		Kind = "Cash",
		Runs = 10,
		Minimum = 2500,
		Minutes = 0,
	},
	{
		Key = "CashMedium",
		Id = 0,
		Name = "Bag of Cash",
		Emoji = "💰",
		Description = "Cash worth 35 of your best launches",
		Kind = "Cash",
		Runs = 35,
		Minimum = 10000,
		Minutes = 0,
	},
	{
		Key = "CashLarge",
		Id = 0,
		Name = "Vault of Cash",
		Emoji = "🏦",
		Description = "Cash worth 120 of your best launches",
		Kind = "Cash",
		Runs = 120,
		Minimum = 40000,
		Minutes = 0,
	},
	{
		Key = "CashHuge",
		Id = 0,
		Name = "Mountain of Cash",
		Emoji = "🏔️",
		Description = "Cash worth 400 of your best launches",
		Kind = "Cash",
		Runs = 400,
		Minimum = 150000,
		Minutes = 0,
	},
}

local passByKey: { [string]: Pass } = {}
for _, pass in passes do
	table.freeze(pass)
	passByKey[pass.Key] = pass
end

local productByKey: { [string]: Product } = {}
for _, product in products do
	table.freeze(product)
	productByKey[product.Key] = product
end

return table.freeze({
	Passes = table.freeze(passes),
	PassByKey = table.freeze(passByKey),
	Products = table.freeze(products),
	ProductByKey = table.freeze(productByKey),
	VipMultiplier = 1.5,
	DoubleCashMultiplier = 2,
	BoostMultiplier = 2,
})
