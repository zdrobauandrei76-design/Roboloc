--!strict

local EventConfig = require(script.Parent.Parent.Config.Event)

export type Car = {
	Position: Vector3,
	Heading: number,
	Velocity: Vector3,
	Yaw: number,
	Steer: number,
	VerticalSpeed: number,
	Grounded: boolean,
	Drifting: boolean,
	Side: number,
	Flick: number,
	DriftTime: number,
	Release: number,
	Recover: number,
	Boost: number,
	Stun: number,
}

export type Input = {
	Steer: number,
	Throttle: number,
	Handbrake: boolean,
}

export type Score = {
	Points: number,
	Combo: number,
	Grace: number,
	Active: boolean,
	Side: number,
	SideTime: number,
	Balance: number,
	Circling: boolean,
	Transitions: number,
}

export type Sample = {
	Speed: number,
	Slip: number,
	YawDelta: number,
	Close: boolean,
}

export type Obstacle = {
	X: number,
	Z: number,
	Radius: number,
}

local Drift = {}

local function wrap(angle: number): number
	return (angle + math.pi) % (math.pi * 2) - math.pi
end

Drift.Wrap = wrap

function Drift.Forward(heading: number): Vector3
	return Vector3.new(-math.sin(heading), 0, -math.cos(heading))
end

function Drift.HeadingOf(direction: Vector3): number
	return math.atan2(-direction.X, -direction.Z)
end

function Drift.NewCar(position: Vector3, heading: number): Car
	return {
		Position = position,
		Heading = heading,
		Velocity = Vector3.zero,
		Yaw = 0,
		Steer = 0,
		VerticalSpeed = 0,
		Grounded = true,
		Drifting = false,
		Side = 0,
		Flick = 0,
		DriftTime = 0,
		Release = 0,
		Recover = 0,
		Boost = 0,
		Stun = 0,
	}
end

function Drift.Slip(heading: number, velocity: Vector3): number
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	if flat.Magnitude < 1 then
		return 0
	end
	return wrap(heading - Drift.HeadingOf(flat))
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function drift(car: Car, input: Input, dt: number, speed: number, slip: number)
	local config = EventConfig
	local into = -car.Steer * car.Side
	if into < -0.6 then
		car.Flick += dt
	else
		car.Flick = 0
	end
	if car.Flick > config.FlickTime and math.abs(slip) < config.FlickAngle and input.Handbrake then
		car.Side = -car.Side
		car.Yaw += car.Side * config.Kick * 0.8
		car.Flick = 0
		car.DriftTime = 0
		into = 0
	end
	local target, radius
	if into >= 0 then
		target = lerp(config.AngleNeutral, config.AngleIn, into)
		radius = lerp(config.RadiusNeutral, config.RadiusIn, into)
	else
		target = lerp(config.AngleNeutral, config.AngleCounter, -into)
		radius = lerp(config.RadiusNeutral, config.RadiusCounter, -into)
	end
	if input.Handbrake then
		car.Release = 0
	else
		car.Release += dt
		target *= math.max(0, 1 - car.Release / config.ReleaseTime)
	end
	local direction = Drift.HeadingOf(car.Velocity)
	local arc = car.Side * speed / radius
	direction += arc * dt
	local newSpeed = speed * math.exp(-config.DriftLoss * math.abs(math.sin(slip)) * dt)
	if input.Throttle > 0 then
		newSpeed += config.Acceleration * config.DriftThrottle * input.Throttle * dt * math.max(
			0,
			1 - newSpeed / config.MaxSpeed
		)
	elseif input.Throttle < 0 then
		newSpeed = math.max(0, newSpeed - config.Braking * 0.5 * dt)
	end
	local want = wrap(direction + car.Side * target - car.Heading)
	local yawTarget = arc + want * config.AngleResponse
	car.Yaw += (yawTarget - car.Yaw) * (1 - math.exp(-10 * dt))
	car.Velocity = Drift.Forward(direction) * newSpeed
	car.DriftTime += dt
	local released = not input.Handbrake and car.Release > config.ReleaseTime * 0.5
	if (released and math.abs(slip) < math.rad(28)) or newSpeed < config.DriftExit then
		if car.DriftTime >= config.BoostAfter and newSpeed >= config.DriftExit then
			car.Boost = config.BoostTime
		end
		car.Drifting = false
		car.Recover = config.RecoverTime
	end
end

local function grip(car: Car, input: Input, dt: number, speed: number)
	local config = EventConfig
	local forward = Drift.Forward(car.Heading)
	local left = Vector3.new(forward.Z, 0, -forward.X)
	local along = car.Velocity:Dot(forward)
	local lateral = car.Velocity:Dot(left)
	local radius = config.MinRadius + speed * config.SpeedRadius
	local reverse = if along < -1 then -1 else 1
	local yawTarget = -car.Steer * speed / radius * reverse
	car.Yaw += (yawTarget - car.Yaw) * (1 - math.exp(-config.YawResponse * dt))
	local traction = config.Grip
	if car.Recover > 0 then
		traction *= 0.25 + 0.75 * (1 - car.Recover / config.RecoverTime)
		car.Recover -= dt
	end
	if car.Stun > 0 then
		traction *= config.StunGrip
	end
	lateral *= math.exp(-traction * dt)
	if car.Stun <= 0 then
		if input.Throttle > 0 then
			along += config.Acceleration * input.Throttle * dt * math.max(
				0,
				1 - (math.max(along, 0) / config.MaxSpeed) ^ 2
			)
		elseif input.Throttle < 0 then
			if along > 1 then
				along -= config.Braking * dt
			elseif along > -config.ReverseSpeed then
				along -= config.Acceleration * 0.5 * dt
			end
		end
	end
	if car.Boost > 0 then
		along += config.Boost / config.BoostTime * dt
		car.Boost -= dt
	end
	along -= config.Drag * along * dt
	car.Velocity = forward * along + left * lateral
end

function Drift.Step(car: Car, input: Input, dt: number)
	local config = EventConfig
	local wanted = math.clamp(input.Steer, -1, 1)
	car.Steer += math.clamp(wanted - car.Steer, -config.SteerSpeed * dt, config.SteerSpeed * dt)
	if car.Stun > 0 then
		car.Stun -= dt
	end
	if not car.Grounded then
		car.VerticalSpeed -= config.Gravity * dt
		car.Drifting = false
		car.Position += car.Velocity * dt + Vector3.new(0, car.VerticalSpeed * dt, 0)
		car.Heading += car.Yaw * dt
		return
	end
	local speed = Vector3.new(car.Velocity.X, 0, car.Velocity.Z).Magnitude
	local slip = Drift.Slip(car.Heading, car.Velocity)
	local forwardSpeed = car.Velocity:Dot(Drift.Forward(car.Heading))
	if
		not car.Drifting
		and car.Stun <= 0
		and input.Handbrake
		and speed >= config.DriftEnter
		and math.abs(car.Steer) > 0.3
		and forwardSpeed > 0
	then
		car.Drifting = true
		car.Side = if car.Steer > 0 then -1 else 1
		car.Yaw += car.Side * config.Kick
		car.Flick = 0
		car.DriftTime = 0
		car.Release = 0
	end
	if car.Drifting then
		drift(car, input, dt, speed, slip)
	else
		grip(car, input, dt, speed)
	end
	car.VerticalSpeed = 0
	car.Heading = wrap(car.Heading + car.Yaw * dt)
	car.Position += car.Velocity * dt
end

function Drift.Circles(position: Vector3, heading: number): (Vector3, Vector3)
	local forward = Drift.Forward(heading) * EventConfig.CarOffset
	return position + forward, position - forward
end

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

function Drift.Collide(car: Car, obstacles: { Obstacle }): boolean
	local hit = false
	for _, obstacle in obstacles do
		local center = Vector3.new(obstacle.X, car.Position.Y, obstacle.Z)
		local front, back = Drift.Circles(car.Position, car.Heading)
		for _, circle in { front, back } do
			local offset = flat(circle - center)
			local distance = offset.Magnitude
			local minimum = obstacle.Radius + EventConfig.CarRadius
			if distance < minimum and distance > 1e-3 then
				local normal = offset / distance
				car.Position += normal * (minimum - distance)
				local into = car.Velocity:Dot(normal)
				if into < 0 then
					car.Velocity = (car.Velocity - normal * into * (1 + EventConfig.Bounce)) * 0.85
					car.Yaw *= 0.5
					car.Drifting = false
					hit = true
				end
			end
		end
	end
	return hit
end

function Drift.Bump(car: Car, otherPosition: Vector3, otherHeading: number, otherVelocity: Vector3): number
	local myFront, myBack = Drift.Circles(car.Position, car.Heading)
	local theirFront, theirBack = Drift.Circles(otherPosition, otherHeading)
	local bestDepth, bestNormal = 0, Vector3.zero
	for _, mine in { myFront, myBack } do
		for _, theirs in { theirFront, theirBack } do
			local offset = flat(mine - theirs)
			local distance = offset.Magnitude
			local depth = EventConfig.CarRadius * 2 - distance
			if depth > bestDepth and distance > 1e-3 then
				bestDepth = depth
				bestNormal = offset / distance
			end
		end
	end
	if bestDepth <= 0 then
		return 0
	end
	car.Position += bestNormal * bestDepth * 0.5
	local relative = (car.Velocity - flat(otherVelocity)):Dot(bestNormal)
	if relative >= 0 then
		return 0
	end
	local impact = -relative
	car.Velocity -= bestNormal * relative * (1 + EventConfig.Bounce) * 0.5
	if impact > 10 then
		car.Drifting = false
		car.Stun = math.min(EventConfig.BumpStun, 0.25 + impact / 60)
		car.Yaw += (math.random() - 0.5) * impact * 0.04
	end
	return impact
end

function Drift.Slot(center: CFrame, radius: number, index: number, slots: number): (Vector3, number)
	local angle = (index - 1) * math.pi * 2 / math.max(slots, 1)
	local position = (center * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius * 0.52)).Position
	local _, yaw = center:ToEulerAnglesYXZ()
	return position, yaw + angle + math.pi / 2
end

function Drift.OnSurface(center: CFrame, radius: number, position: Vector3): boolean
	local localPoint = center:PointToObjectSpace(position)
	local x, z = math.abs(localPoint.X), math.abs(localPoint.Z)
	return (x <= radius and z <= radius * 0.6)
		or (x <= radius * 0.6 and z <= radius)
		or (x <= radius * 0.78 and z <= radius * 0.78)
end

function Drift.Near(position: Vector3, obstacles: { Obstacle }): boolean
	for _, obstacle in obstacles do
		local dx, dz = position.X - obstacle.X, position.Z - obstacle.Z
		local gap = math.sqrt(dx * dx + dz * dz)
			- obstacle.Radius
			- EventConfig.CarRadius
			- EventConfig.CarOffset
		if gap < EventConfig.CloseDistance then
			return true
		end
	end
	return false
end

function Drift.NewScore(): Score
	return {
		Points = 0,
		Combo = 1,
		Grace = 0,
		Active = false,
		Side = 0,
		SideTime = 0,
		Balance = 0,
		Circling = false,
		Transitions = 0,
	}
end

function Drift.Break(score: Score)
	score.Active = false
	score.Combo = 1
	score.Grace = 0
	score.Side = 0
	score.SideTime = 0
end

function Drift.Score(score: Score, sample: Sample, dt: number): number
	local config = EventConfig
	local angle = math.abs(sample.Slip)
	score.Balance *= math.exp(-config.BalanceDecay * dt)
	local valid = sample.Speed >= config.MinSpeed and angle >= config.MinAngle and angle <= config.MaxAngle
	if not valid then
		if score.Active then
			score.Grace += dt
			if score.Grace > config.ComboGrace then
				Drift.Break(score)
			end
		end
		return 0
	end
	local gained = 0
	local side = if sample.Slip > 0 then 1 else -1
	if score.Active and score.Side ~= 0 and side ~= score.Side then
		score.Combo = math.min(config.MaxCombo, score.Combo + 1)
		score.Transitions += 1
		score.SideTime = 0
		local bonus = config.TransitionBonus * score.Combo
		score.Points += bonus
		gained += bonus
	elseif score.Side ~= side then
		score.SideTime = 0
	end
	score.Side = side
	score.Active = true
	score.Grace = 0
	score.SideTime += dt
	score.Balance += sample.YawDelta
	if score.Circling then
		score.Circling = math.abs(score.Balance) > config.CircleResume
	else
		score.Circling = math.abs(score.Balance) > config.CircleLimit
	end
	if score.Circling then
		return gained
	end
	local fade = math.clamp(1 - (score.SideTime - config.SideFade) / config.SideFadeTime, config.MinFade, 1)
	local rate = sample.Speed
		* math.sin(math.min(angle, math.pi / 2))
		* config.ScoreRate
		* score.Combo
		* fade
		* (if sample.Close then config.CloseBonus else 1)
	score.Points += rate * dt
	return gained + rate * dt
end

return Drift
