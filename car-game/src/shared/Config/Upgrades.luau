--!strict

export type Upgrade = {
	Id: string,
	Name: string,
	Emoji: string,
	Description: string,
	BaseCost: number,
	CostGrowth: number,
	BaseCap: number,
	CapPerRebirth: number,
	MaxLevel: number,
}

local order: { Upgrade } = {
	{
		Id = "Engine",
		Name = "Engine",
		Emoji = "⚡",
		Description = "Faster launch speed",
		BaseCost = 40,
		CostGrowth = 1.12,
		BaseCap = 30,
		CapPerRebirth = 6,
		MaxLevel = 100,
	},
	{
		Id = "Nitro",
		Name = "Nitro",
		Emoji = "🔥",
		Description = "More boost fuel and power",
		BaseCost = 70,
		CostGrowth = 1.16,
		BaseCap = 15,
		CapPerRebirth = 3,
		MaxLevel = 50,
	},
	{
		Id = "Wings",
		Name = "Wings",
		Emoji = "🦅",
		Description = "Glide further when falling",
		BaseCost = 90,
		CostGrowth = 1.165,
		BaseCap = 15,
		CapPerRebirth = 3,
		MaxLevel = 50,
	},
}

local byId: { [string]: Upgrade } = {}
for _, upgrade in order do
	table.freeze(upgrade)
	byId[upgrade.Id] = upgrade
end

return table.freeze({
	Order = table.freeze(order),
	ById = table.freeze(byId),
})
