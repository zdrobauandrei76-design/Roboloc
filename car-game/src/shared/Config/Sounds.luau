--!strict

export type Sound = {
	Volume: number,
	Id: string,
	Fallback: string,
}

local function sound(volume: number, fallback: string): Sound
	return table.freeze({ Volume = volume, Id = "", Fallback = fallback })
end

return table.freeze({
	SpriteId = "",
	MusicId = "",
	MusicVolume = 0.3,
	Sounds = table.freeze({
		Click = sound(0.5, "rbxasset://sounds/clickfast.wav"),
		Open = sound(0.45, ""),
		Purchase = sound(0.6, "rbxasset://sounds/electronicpingshort.wav"),
		Cash = sound(0.6, "rbxasset://sounds/electronicpingshort.wav"),
		Perfect = sound(0.65, "rbxasset://sounds/electronicpingshort.wav"),
		Launch = sound(0.7, "rbxasset://sounds/Rocket shot.wav"),
		Land = sound(0.7, "rbxasset://sounds/action_jump_land.mp3"),
		Zone = sound(0.6, "rbxasset://sounds/electronicpingshort.wav"),
		Error = sound(0.45, "rbxasset://sounds/clickfast.wav"),
		Rebirth = sound(0.7, "rbxasset://sounds/electronicpingshort.wav"),
		Swoosh = sound(0.45, ""),
		Boost = sound(0.5, "rbxasset://sounds/Rocket whoosh 01.wav"),
		Wind = sound(0.35, "rbxasset://sounds/action_falling.mp3"),
	}) :: { [string]: Sound },
})
