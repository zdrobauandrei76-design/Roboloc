--!strict

return table.freeze({
	LaneCount = 12,
	LaneWidth = 28,
	DeckHeight = 230,
	DeckStartX = -680,
	StartX = -620,
	RampPoints = table.freeze({
		Vector2.new(-560, 230),
		Vector2.new(-400, 230),
		Vector2.new(-150, -60),
		Vector2.new(0, 40),
	}),
	RampSegments = 48,
	WorldLength = 56000,
	GroundWidth = 1600,
})
