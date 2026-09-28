--!strict

local FlightConfig = require(script.Parent.Parent.Config.Flight)
local Track = require(script.Parent.Track)
local Types = require(script.Parent.Types)

export type State = {
	X: number,
	Y: number,
	VX: number,
	VY: number,
	Fuel: number,
	Tick: number,
	Bounces: number,
	Phase: string,
	Boosting: boolean,
	Landed: boolean,
}

export type Result = {
	Distance: number,
	Ticks: number,
	Duration: number,
}

local timeStep = FlightConfig.TimeStep
local gravity = FlightConfig.Gravity
local thrustCos = math.cos(FlightConfig.ThrustAngle)
local thrustSin = math.sin(FlightConfig.ThrustAngle)
local maxTicks = math.ceil(FlightConfig.MaxDuration / timeStep)

local Flight = {}

Flight.TimeStep = timeStep
Flight.MaxTicks = maxTicks

function Flight.new(params: Types.RunParams): State
	local angle = Track.LaunchAngle
	return {
		X = 0,
		Y = Track.LipHeight,
		VX = params.Speed * math.cos(angle),
		VY = params.Speed * math.sin(angle),
		Fuel = params.Fuel,
		Tick = 0,
		Bounces = 0,
		Phase = "Air",
		Boosting = false,
		Landed = false,
	}
end

function Flight.Copy(state: State): State
	return table.clone(state)
end

function Flight.Step(state: State, params: Types.RunParams, boosting: boolean)
	if state.Phase == "Done" then
		return
	end
	state.Tick += 1
	state.Landed = false
	state.Boosting = false
	if state.Phase == "Air" then
		local ax = 0
		local ay = if state.VY < 0 then -gravity * (1 - params.Glide) else -gravity
		if boosting and state.Fuel > 0 then
			local used = math.min(timeStep, state.Fuel)
			state.Fuel -= used
			local power = params.Thrust * used / timeStep
			ax += power * thrustCos
			ay += power * thrustSin
			state.Boosting = true
		end
		state.VX += ax * timeStep
		state.VY += ay * timeStep
		state.X += state.VX * timeStep
		state.Y += state.VY * timeStep
		if state.Y <= 0 then
			state.Y = 0
			state.Landed = true
			if -state.VY > FlightConfig.BounceSpeed and state.Bounces < FlightConfig.MaxBounces then
				state.VY = -state.VY * FlightConfig.Restitution
				state.VX *= FlightConfig.BounceFriction
				state.Bounces += 1
			else
				state.VY = 0
				state.Phase = "Slide"
			end
		end
	else
		state.VX -= (FlightConfig.SlideDrag + FlightConfig.SlideDamping * state.VX) * timeStep
		if state.VX < 0 then
			state.VX = 0
		end
		state.X += state.VX * timeStep
		if state.VX <= FlightConfig.StopSpeed then
			state.Phase = "Done"
		end
	end
	if state.X >= Track.WorldLength then
		state.X = Track.WorldLength
		state.VX = 0
		state.VY = 0
		state.Phase = "Done"
	end
	if state.Tick >= maxTicks then
		state.Phase = "Done"
	end
end

function Flight.ValidToggles(toggles: any): boolean
	if type(toggles) ~= "table" or #toggles > FlightConfig.MaxToggles then
		return false
	end
	local previous = -1
	for index, tick in toggles do
		if type(index) ~= "number" or type(tick) ~= "number" or tick % 1 ~= 0 then
			return false
		end
		if tick <= previous or tick > maxTicks then
			return false
		end
		previous = tick
	end
	return true
end

function Flight.Simulate(params: Types.RunParams, toggles: { number }): Result
	local state = Flight.new(params)
	local boosting = false
	local nextToggle = 1
	while state.Phase ~= "Done" do
		while toggles[nextToggle] == state.Tick do
			boosting = not boosting
			nextToggle += 1
		end
		Flight.Step(state, params, boosting)
	end
	return {
		Distance = state.X,
		Ticks = state.Tick,
		Duration = state.Tick * timeStep,
	}
end

return Flight
