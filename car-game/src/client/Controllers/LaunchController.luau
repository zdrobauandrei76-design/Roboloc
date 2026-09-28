--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FlightConfig = require(ReplicatedStorage.Config.Flight)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Flight = require(ReplicatedStorage.Game.Flight)
local Stats = require(ReplicatedStorage.Game.Stats)
local Track = require(ReplicatedStorage.Game.Track)
local Types = require(ReplicatedStorage.Game.Types)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)

export type Result = {
	Ok: boolean,
	Distance: number,
	Earned: number,
	IsBest: boolean,
	Zone: number,
	Quality: number,
	Label: string,
}

export type Info = {
	State: string,
	Distance: number,
	Speed: number,
	Fuel: number,
	FuelMax: number,
	Zone: number,
	Needle: number,
	Boosting: boolean,
	Tapped: boolean,
}

type Run = {
	Id: number,
	Base: Types.RunParams,
	Params: Types.RunParams,
	Quality: number,
	Tapped: boolean,
	Label: string,
	Toggles: { number },
	Sim: Flight.State?,
	Previous: Flight.State?,
	Accumulator: number,
	Boosting: boolean,
	EffectiveBoost: boolean,
	RampTime: number,
	Zone: number,
	Pitch: number,
	Landings: number,
}

local actionName = "MegaRampAction"

local LaunchController = {
	Name = "LaunchController",
	StateChanged = Signal.new() :: Signal.Signal<string>,
	TimingLocked = Signal.new() :: Signal.Signal<(number, string)>,
	ZoneEntered = Signal.new() :: Signal.Signal<number>,
	Landed = Signal.new() :: Signal.Signal<number>,
	Finished = Signal.new() :: Signal.Signal<Result>,
	AutoChanged = Signal.new() :: Signal.Signal<boolean>,
}
local controllers: { [string]: any } = {}
local state = "Idle"
local stateStarted = 0
local car: Model? = nil
local body: BasePart? = nil
local pivotOffset = CFrame.identity
local run: Run? = nil
local restPivot: CFrame? = nil
local lastResult: Result? = nil
local boostHeld = false
local autoEnabled = false
local connections: { { Disconnect: (self: any) -> () } } = {}
local info: Info = {
	State = "Idle",
	Distance = 0,
	Speed = 0,
	Fuel = 0,
	FuelMax = 1,
	Zone = 1,
	Needle = 0,
	Boosting = false,
	Tapped = false,
}

local cameraModes: { [string]: string } = {
	Idle = "Idle",
	Starting = "Idle",
	Ramp = "Chase",
	Flight = "Chase",
	Finishing = "Orbit",
	Results = "Orbit",
	Returning = "Orbit",
}

local function currentState(): string
	return state
end

local function lane(): number
	local value = Players.LocalPlayer:GetAttribute("Lane")
	return if type(value) == "number" then value else 1
end

local function setState(newState: string)
	state = newState
	stateStarted = os.clock()
	info.State = newState
	controllers.CameraController:SetMode(cameraModes[newState] or "Idle")
	LaunchController.StateChanged:Fire(newState)
end

local function refreshCar()
	local current = car
	if current and current.Parent and body and body.Parent then
		return
	end
	car = nil
	body = nil
	local folder = workspace:FindFirstChild("Cars")
	local model = folder and folder:FindFirstChild(tostring(Players.LocalPlayer.UserId))
	if model and model:IsA("Model") and model.PrimaryPart then
		car = model
		body = model.PrimaryPart
		pivotOffset = model:GetPivot():ToObjectSpace(model.PrimaryPart.CFrame)
		controllers.CameraController:SetTarget(model)
	elseif current then
		controllers.CameraController:SetTarget(nil)
	end
end

local function applyPose(pivot: CFrame, velocity: Vector3)
	local activeBody = body
	if not activeBody then
		return
	end
	activeBody.CFrame = pivot * pivotOffset
	activeBody.AssemblyLinearVelocity = velocity
	activeBody.AssemblyAngularVelocity = Vector3.zero
	local force = activeBody:FindFirstChild("AntiGravity")
	if force and force:IsA("VectorForce") then
		force.Force = Vector3.new(0, activeBody.AssemblyMass * workspace.Gravity, 0)
	end
end

local function setCarAttribute(name: string, value: boolean)
	local current = car
	if current then
		current:SetAttribute(name, value)
	end
end

local function setBoostEffect(current: Run, active: boolean)
	if current.EffectiveBoost == active then
		return
	end
	current.EffectiveBoost = active
	info.Boosting = active
	setCarAttribute("Boosting", active)
	controllers.SoundController:SetLoop("Boost", active, 0.55, 1)
	Packets.SetBoosting:Fire(active)
end

local function lockTiming(current: Run, quality: number, tapped: boolean)
	current.Tapped = true
	current.Quality = quality
	current.Label = Stats.TimingLabel(quality, tapped)
	info.Tapped = true
	LaunchController.TimingLocked:Fire(quality, current.Label)
	if quality >= FlightConfig.PerfectQuality then
		controllers.SoundController:Play("Perfect", 1.2)
		controllers.CameraController:Shake(0.6, 0.4)
	elseif tapped then
		controllers.SoundController:Play("Click", 1.15)
	else
		controllers.SoundController:Play("Error")
	end
end

local function beginFlight(current: Run)
	if not current.Tapped then
		lockTiming(current, 0, false)
	end
	current.Params = {
		Speed = current.Base.Speed * Stats.TimingFactor(current.Quality),
		Fuel = current.Base.Fuel,
		Thrust = current.Base.Thrust,
		Glide = current.Base.Glide,
	}
	local sim = Flight.new(current.Params)
	current.Sim = sim
	current.Previous = Flight.Copy(sim)
	current.Accumulator = 0
	current.Pitch = Track.LaunchAngle
	setState("Flight")
	controllers.SoundController:SetLoop("Wind", true, 0.25, 1)
	controllers.CameraController:Shake(0.35, 0.3)
end

local function updateRamp(current: Run, dt: number)
	current.RampTime += dt
	info.Needle = Stats.NeedlePosition(current.RampTime)
	if autoEnabled and not current.Tapped and current.RampTime >= 0.45 then
		lockTiming(current, FlightConfig.AutoQuality, true)
	end
	local duration = FlightConfig.RampDuration
	local u = math.min(current.RampTime / duration, 1)
	local length = Track.RampLength()
	local k = math.clamp(current.Base.Speed * duration / length, 0.3, 3)
	local a, b = 3 - k, k - 2
	local along = length * (a * u * u + b * u * u * u)
	local speed = length / duration * (2 * a * u + 3 * b * u * u)
	local point, angle = Track.RampPoint(along)
	info.Speed = speed
	info.Distance = 0
	controllers.CameraController:SetSpeed(speed)
	applyPose(
		Track.WorldCFrame(lane(), point.X, point.Y, angle),
		Vector3.new(math.cos(angle), math.sin(angle), 0) * speed
	)
	if u >= 1 then
		beginFlight(current)
	end
end

local function finishRun(current: Run, x: number, y: number)
	boostHeld = false
	setBoostEffect(current, false)
	setCarAttribute("Flying", false)
	restPivot = Track.WorldCFrame(lane(), x, y, 0)
	controllers.SoundController:SetLoop("Wind", false)
	setState("Finishing")
	task.spawn(function()
		local ok, distance, earned, isBest, zone =
			Packets.FinishRun:Fire(current.Id, current.Quality, current.Toggles)
		if run ~= current then
			return
		end
		run = nil
		local result: Result = {
			Ok = ok == true,
			Distance = if type(distance) == "number" then distance else 0,
			Earned = if type(earned) == "number" then earned else 0,
			IsBest = isBest == true,
			Zone = if type(zone) == "number" and zone > 0 then zone else current.Zone,
			Quality = current.Quality,
			Label = current.Label,
		}
		lastResult = result
		if result.Ok and result.Earned > 0 then
			controllers.SoundController:Play("Cash")
		end
		LaunchController.Finished:Fire(result)
		setState("Results")
	end)
end

local function updateFlight(current: Run, dt: number)
	local sim = current.Sim
	if not sim then
		return
	end
	current.Accumulator += math.min(dt, 0.25)
	while current.Accumulator >= Flight.TimeStep and sim.Phase ~= "Done" do
		current.Accumulator -= Flight.TimeStep
		local wanted = boostHeld or autoEnabled
		if wanted ~= current.Boosting and #current.Toggles < FlightConfig.MaxToggles - 1 then
			current.Boosting = wanted
			table.insert(current.Toggles, sim.Tick)
		end
		current.Previous = Flight.Copy(sim)
		Flight.Step(sim, current.Params, current.Boosting)
		if sim.Landed then
			current.Landings += 1
			local impact = math.clamp(math.abs((current.Previous :: Flight.State).VY) / 120, 0.15, 1)
			controllers.SoundController:Play("Land", if current.Landings == 1 then 1 else 1.2)
			controllers.CameraController:Shake(impact, 0.35)
			if current.Landings == 1 then
				LaunchController.Landed:Fire(sim.X)
			end
		end
		local zone = Stats.ZoneIndexAt(sim.X)
		if zone > current.Zone then
			current.Zone = zone
			info.Zone = zone
			controllers.SoundController:Play("Zone")
			LaunchController.ZoneEntered:Fire(zone)
		end
	end
	setBoostEffect(current, sim.Boosting)
	local previous = current.Previous or sim
	local alpha = if sim.Phase == "Done" then 1 else math.clamp(current.Accumulator / Flight.TimeStep, 0, 1)
	local x = previous.X + (sim.X - previous.X) * alpha
	local y = previous.Y + (sim.Y - previous.Y) * alpha
	local vx = previous.VX + (sim.VX - previous.VX) * alpha
	local vy = previous.VY + (sim.VY - previous.VY) * alpha
	local targetPitch = if sim.Phase == "Air" then math.atan2(vy, math.max(vx, 1)) else 0
	current.Pitch += (targetPitch - current.Pitch) * (1 - math.exp(-dt * 10))
	applyPose(Track.WorldCFrame(lane(), x, y, current.Pitch), Vector3.new(vx, vy, 0))
	local speed = math.sqrt(vx * vx + vy * vy)
	info.Distance = x
	info.Speed = speed
	info.Fuel = sim.Fuel
	controllers.CameraController:SetSpeed(speed)
	controllers.SoundController:SetLoop(
		"Wind",
		true,
		math.clamp(speed / 900, 0.15, 0.6),
		0.8 + math.min(speed / 1500, 0.6)
	)
	if sim.Phase == "Done" then
		finishRun(current, x, y)
	end
end

local function onStep(dt: number)
	refreshCar()
	local current = run
	if state == "Ramp" and current then
		updateRamp(current, dt)
	elseif state == "Flight" and current then
		updateFlight(current, dt)
	elseif (state == "Finishing" or state == "Results" or state == "Returning") and restPivot then
		applyPose(restPivot, Vector3.zero)
	else
		applyPose(Track.StartCFrame(lane()), Vector3.zero)
	end
	if autoEnabled then
		local elapsed = os.clock() - stateStarted
		if state == "Idle" and elapsed >= GameConfig.AutoLaunchDelay then
			LaunchController:Launch()
		elseif state == "Results" and elapsed >= GameConfig.AutoContinueDelay then
			LaunchController:Continue()
		end
	end
end

function LaunchController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function LaunchController.GetState(_self: any): string
	return state
end

function LaunchController.GetInfo(_self: any): Info
	return info
end

function LaunchController.GetLastResult(_self: any): Result?
	return lastResult
end

function LaunchController.IsAuto(_self: any): boolean
	return autoEnabled
end

function LaunchController.HasCar(_self: any): boolean
	return car ~= nil
end

function LaunchController.Launch(_self: any)
	if state ~= "Idle" or not controllers.DataController:IsLoaded() then
		return
	end
	refreshCar()
	if not car then
		return
	end
	setState("Starting")
	task.spawn(function()
		local id, speed, fuel, thrust, glide = Packets.StartRun:Fire()
		if currentState() ~= "Starting" then
			return
		end
		if
			type(id) ~= "number"
			or id <= 0
			or type(speed) ~= "number"
			or type(fuel) ~= "number"
			or type(thrust) ~= "number"
			or type(glide) ~= "number"
		then
			setState("Idle")
			return
		end
		local base: Types.RunParams = { Speed = speed, Fuel = fuel, Thrust = thrust, Glide = glide }
		run = {
			Id = id,
			Base = base,
			Params = table.clone(base),
			Quality = 0,
			Tapped = false,
			Label = "",
			Toggles = {},
			Sim = nil,
			Previous = nil,
			Accumulator = 0,
			Boosting = false,
			EffectiveBoost = false,
			RampTime = 0,
			Zone = 1,
			Pitch = 0,
			Landings = 0,
		}
		info.Fuel = fuel
		info.FuelMax = math.max(fuel, 0.01)
		info.Tapped = false
		info.Zone = 1
		info.Needle = 0
		setCarAttribute("Flying", true)
		controllers.SoundController:Play("Launch")
		setState("Ramp")
	end)
end

function LaunchController.Tap(_self: any)
	local current = run
	if state ~= "Ramp" or not current or current.Tapped then
		return
	end
	lockTiming(current, Stats.TimingQuality(Stats.NeedlePosition(current.RampTime)), true)
end

function LaunchController.SetBoost(_self: any, held: boolean)
	boostHeld = held
end

function LaunchController.Continue(_self: any)
	if state ~= "Results" or os.clock() - stateStarted < GameConfig.ResultsMinimumTime then
		return
	end
	setState("Returning")
	task.delay(0.35, function()
		if currentState() == "Returning" then
			restPivot = nil
			setState("Idle")
		end
	end)
end

function LaunchController.SetAuto(_self: any, enabled: boolean)
	local allowed = enabled and controllers.DataController:Get({ "Passes", "AutoLaunch" }) == true
	if allowed ~= autoEnabled then
		autoEnabled = allowed
		stateStarted = os.clock()
		LaunchController.AutoChanged:Fire(autoEnabled)
	end
end

local function onAction(
	_name: string,
	inputState: Enum.UserInputState,
	_input: InputObject
): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin then
		if state == "Idle" then
			LaunchController:Launch()
		elseif state == "Ramp" then
			LaunchController:Tap()
		elseif state == "Results" then
			LaunchController:Continue()
		end
		if state == "Ramp" or state == "Flight" then
			boostHeld = true
		end
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		boostHeld = false
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

function LaunchController.Start(_self: any)
	table.insert(connections, RunService.PreSimulation:Connect(onStep))
	table.insert(
		connections,
		controllers.DataController:Observe({ "Passes", "AutoLaunch" }, function(owned: any)
			if owned ~= true and autoEnabled then
				LaunchController:SetAuto(false)
			end
		end)
	)
	ContextActionService:BindActionAtPriority(
		actionName,
		onAction,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.Space,
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.ButtonR2
	)
end

function LaunchController.Destroy(_self: any)
	ContextActionService:UnbindAction(actionName)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if run then
		run = nil
		Packets.CancelRun:Fire()
	end
end

return LaunchController
