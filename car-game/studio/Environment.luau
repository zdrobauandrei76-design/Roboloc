--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Zones = require(ReplicatedStorage.Config.Zones)

type SoundSpec = {
	Name: string,
	Id: string,
	Volume: number,
	Looped: boolean,
}

local sounds: { SoundSpec } = {
	{ Name = "Click", Id = "rbxasset://sounds/clickfast.wav", Volume = 0.5, Looped = false },
	{ Name = "Launch", Id = "rbxasset://sounds/Rocket shot.wav", Volume = 0.6, Looped = false },
	{ Name = "Perfect", Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.8, Looped = false },
	{ Name = "Boost", Id = "rbxasset://sounds/Rocket whoosh 01.wav", Volume = 0.55, Looped = true },
	{ Name = "Wind", Id = "rbxasset://sounds/action_falling.mp3", Volume = 0.3, Looped = true },
	{ Name = "Land", Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 0.9, Looped = false },
	{ Name = "Cash", Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Looped = false },
	{ Name = "Zone", Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.7, Looped = false },
	{ Name = "Error", Id = "rbxasset://sounds/clickfast.wav", Volume = 0.35, Looped = false },
	{ Name = "Purchase", Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.7, Looped = false },
	{ Name = "Rebirth", Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.9, Looped = false },
	{ Name = "Music", Id = "", Volume = 0.35, Looped = true },
}

local Environment = {}

local function replace(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

function Environment.BuildLighting()
	local zone = Zones[1]
	Lighting.ClockTime = zone.ClockTime
	Lighting.Brightness = zone.Brightness
	Lighting.Ambient = zone.Ambient
	Lighting.OutdoorAmbient = zone.OutdoorAmbient
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") then
			child:Destroy()
		end
	end
	local atmosphere = replace(Lighting, "Atmosphere", "Atmosphere") :: Atmosphere
	atmosphere.Color = zone.AtmosphereColor
	atmosphere.Decay = zone.AtmosphereDecay
	atmosphere.Density = zone.AtmosphereDensity
	atmosphere.Haze = zone.AtmosphereHaze
	atmosphere.Glare = 0.2
	atmosphere.Offset = 0.1
	local bloom = replace(Lighting, "BloomEffect", "Bloom") :: BloomEffect
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.6
	local color = replace(Lighting, "ColorCorrectionEffect", "ColorCorrection") :: ColorCorrectionEffect
	color.Saturation = 0.15
	color.Contrast = 0.05
	local rays = replace(Lighting, "SunRaysEffect", "SunRays") :: SunRaysEffect
	rays.Intensity = 0.06
	rays.Spread = 0.8
end

function Environment.BuildSounds(assets: Folder)
	local folder = replace(assets, "Folder", "Sounds")
	for _, spec in sounds do
		local sound = Instance.new("Sound")
		sound.Name = spec.Name
		sound.SoundId = spec.Id
		sound.Volume = spec.Volume
		sound.Looped = spec.Looped
		sound.Parent = folder
	end
end

function Environment.ConfigureWorkspace()
	local ok = pcall(function()
		(workspace :: any).StreamingEnabled = false
	end)
	if not ok then
		warn(
			"[StudioBuild] Turn off Workspace.StreamingEnabled in the Properties window so far zones render at high speed."
		)
	end
end

return Environment
