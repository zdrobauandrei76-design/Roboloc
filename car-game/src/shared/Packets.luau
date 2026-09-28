--!strict

local Packet = require(script.Parent.Packet)

local Packets = {
	Ping = Packet("Ping"):Response(Packet.NumberF64):RateLimit(5, 1),
	StartRun = Packet("StartRun"):Response(
		Packet.NumberU32,
		Packet.NumberF64,
		Packet.NumberF64,
		Packet.NumberF64,
		Packet.NumberF64
	):RateLimit(4, 2),
	FinishRun = Packet("FinishRun", Packet.NumberU32, Packet.NumberF64, { Packet.NumberU16 }):Response(
		Packet.Boolean8,
		Packet.NumberF64,
		Packet.NumberF64,
		Packet.Boolean8,
		Packet.NumberU8
	):RateLimit(4, 2),
	CancelRun = Packet("CancelRun"):RateLimit(4, 2),
	SetBoosting = Packet("SetBoosting", Packet.Boolean8):RateLimit(20, 1),
	BuyUpgrade = Packet("BuyUpgrade", Packet.String, Packet.NumberU8)
		:Response(Packet.Boolean8, Packet.NumberU8)
		:RateLimit(12, 1),
	BuyCar = Packet("BuyCar", Packet.String):Response(Packet.Boolean8):RateLimit(5, 1),
	EquipCar = Packet("EquipCar", Packet.String):Response(Packet.Boolean8):RateLimit(5, 1),
	Rebirth = Packet("Rebirth"):Response(Packet.Boolean8):RateLimit(2, 2),
	ClaimDaily = Packet("ClaimDaily"):Response(Packet.Boolean8):RateLimit(3, 2),
	ClaimGift = Packet("ClaimGift", Packet.NumberU8):Response(Packet.Boolean8):RateLimit(6, 1),
	RedeemCode = Packet("RedeemCode", Packet.String):Response(Packet.Boolean8, Packet.String):RateLimit(3, 5),
	ClaimGroup = Packet("ClaimGroup"):Response(Packet.Boolean8):RateLimit(2, 5),
	SetTutorial = Packet("SetTutorial", Packet.NumberU8):RateLimit(5, 1),
	GetLeaderboard = Packet("GetLeaderboard"):Response({
		{ Name = Packet.String, UserId = Packet.NumberF64, Value = Packet.NumberF64 },
	}):RateLimit(2, 5),
	Notify = Packet("Notify", Packet.String, Packet.String),
	Announce = Packet("Announce", Packet.String),
}

return Packets
