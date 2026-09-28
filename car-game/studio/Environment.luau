--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Zones = require(ReplicatedStorage.Config.Zones)

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
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
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
	bloom.Intensity = 0.55
	bloom.Size = 28
	bloom.Threshold = 1.35
	local color = replace(Lighting, "ColorCorrectionEffect", "ColorCorrection") :: ColorCorrectionEffect
	color.Saturation = 0.25
	color.Contrast = 0.08
	color.Brightness = 0.02
	local rays = replace(Lighting, "SunRaysEffect", "SunRays") :: SunRaysEffect
	rays.Intensity = 0.08
	rays.Spread = 0.8
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end
	local sky = replace(Lighting, "Sky", "Sky") :: Sky
	sky.StarCount = 3000
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 10
	sky.CelestialBodiesShown = true
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		clouds.Cover = zone.CloudCover
		clouds.Density = 0.7
		clouds.Color = zone.CloudColor
		clouds.Parent = terrain
	end
end

function Environment.RemoveLegacySounds(assets: Folder)
	local legacy = assets:FindFirstChild("Sounds")
	if legacy then
		legacy:Destroy()
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
