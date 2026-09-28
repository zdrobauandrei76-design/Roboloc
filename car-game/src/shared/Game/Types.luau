--!strict

export type Upgrades = {
	Engine: number,
	Nitro: number,
	Wings: number,
}

export type Passes = {
	DoubleCash: boolean,
	VIP: boolean,
	AutoLaunch: boolean,
	MegaNitro: boolean,
}

export type Daily = {
	Streak: number,
	LastDay: number,
}

export type PlayerData = {
	SchemaVersion: number,
	Cash: number,
	LastSeenAt: number,
	Receipts: { [string]: number },
	TotalEarned: number,
	BestDistance: number,
	TotalDistance: number,
	BestRunCash: number,
	Launches: number,
	Rebirths: number,
	MaxZone: number,
	Upgrades: Upgrades,
	Cars: { [string]: boolean },
	EquippedCar: string,
	Passes: Passes,
	BoostEndsAt: number,
	BoostSeconds: number,
	Daily: Daily,
	Codes: { [string]: boolean },
	GroupClaimed: boolean,
	StarterPackOwned: boolean,
	Tutorial: number,
}

export type RunParams = {
	Speed: number,
	Fuel: number,
	Thrust: number,
	Glide: number,
}

return {}
