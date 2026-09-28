--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Zones = require(ReplicatedStorage.Config.Zones)
local Stats = require(ReplicatedStorage.Game.Stats)

local tweenInfo = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local AtmosphereController = { Name = "AtmosphereController" }
local currentZone = 0
local connection: RBXScriptConnection? = nil
local tweens: { Tween } = {}
local atmosphere: Atmosphere? = nil
local elapsed = 0

function AtmosphereController.Init(_self: any, _controllers: { [string]: any }) end

local function apply(index: number)
	local zone = Zones[index]
	if not zone then
		return
	end
	for _, tween in tweens do
		tween:Cancel()
	end
	table.clear(tweens)
	local lightingTween = TweenService:Create(Lighting, tweenInfo, {
		ClockTime = zone.ClockTime,
		Brightness = zone.Brightness,
		Ambient = zone.Ambient,
		OutdoorAmbient = zone.OutdoorAmbient,
	})
	table.insert(tweens, lightingTween)
	lightingTween:Play()
	local activeAtmosphere = atmosphere
	if activeAtmosphere and activeAtmosphere.Parent then
		local atmosphereTween = TweenService:Create(activeAtmosphere, tweenInfo, {
			Color = zone.AtmosphereColor,
			Decay = zone.AtmosphereDecay,
			Density = zone.AtmosphereDensity,
			Haze = zone.AtmosphereHaze,
		})
		table.insert(tweens, atmosphereTween)
		atmosphereTween:Play()
	end
end

function AtmosphereController.Start(_self: any)
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < 0.25 then
			return
		end
		elapsed = 0
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		if not atmosphere or not atmosphere.Parent then
			atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		end
		local index = Stats.ZoneIndexAt(math.max(camera.CFrame.Position.X, 0))
		if index ~= currentZone then
			currentZone = index
			apply(index)
		end
	end)
end

function AtmosphereController.Destroy(_self: any)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	for _, tween in tweens do
		tween:Cancel()
	end
	table.clear(tweens)
end

return AtmosphereController
