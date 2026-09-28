--!strict

local EventConfig = require(script.Parent.Parent.Config.Event)

export type Car = {
	Position: Vector3,
	Heading: number,
	Velocity: Vector3,
	VerticalSpeed: number,
	Grounded: boolean,
	Drifting: boolean,
}

export type Input = {
	Steer: number,
	Throttle: number,
	Handbrake: boolean,
}

export type Score = {
	Points: number,
	Combo: number,
	Chain: number,
	Grace: number,
	Active: boolean,
}

export type Obstacle = {
	X: number,
	Z: number,
	Radius: number,
}

local Drift = {}

function Drift.Forward(heading: number): Vector3
	return Vector3.new(-math.sin(heading), 0, -math.cos(heading))
end

function Drift.NewCar(position: Vector3, heading: number): Car
	return {
		Position = position,
		Heading = heading,
		Velocity = Vector3.zero,
		VerticalSpeed = 0,
		Grounded = true,
		Drifting = false,
	}
end

function Drift.Step(car: Car, input: Input, dt: number)
	local velocity = car.Velocity
	if car.Grounded then
		local forward = Drift.Forward(car.Heading)
		local speed = velocity.Magnitude
		local forwardSpeed = velocity:Dot(forward)
		local throttle = math.clamp(input.Throttle, -1, 1)
		if throttle > 0 and forwardSpeed < EventConfig.MaxSpeed then
			velocity += forward * EventConfig.Acceleration * throttle * dt
		elseif throttle < 0 then
			if forwardSpeed > 1 then
				velocity -= forward * EventConfig.Braking * -throttle * dt
			elseif forwardSpeed > -EventConfig.ReverseSpeed then
				velocity += forward * EventConfig.Acceleration * 0.5 * throttle * dt
			end
		end
		local drifting = input.Handbrake and speed > 12
		local turning = math.clamp(speed / 25, 0, 1) * (if forwardSpeed < -1 then -1 else 1)
		local steer = math.clamp(input.Steer, -1, 1)
			* EventConfig.SteerRate
			* turning
			* (if drifting then EventConfig.DriftSteer else 1)
		car.Heading -= steer * dt
		forward = Drift.Forward(car.Heading)
		local along = forward * velocity:Dot(forward)
		local lateral = velocity - along
		lateral *= math.exp(-(if drifting then EventConfig.DriftGrip else EventConfig.Grip) * dt)
		along *= math.exp(-(EventConfig.Drag + (if drifting then EventConfig.DriftDrag else 0)) * dt)
		velocity = along + lateral
		car.Drifting = drifting or lateral.Magnitude > 8
		car.VerticalSpeed = 0
	else
		car.VerticalSpeed -= EventConfig.Gravity * dt
		car.Drifting = false
	end
	car.Velocity = velocity
	car.Position += velocity * dt + Vector3.new(0, car.VerticalSpeed * dt, 0)
end

function Drift.Angle(forward: Vector3, velocity: Vector3): number
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = flat.Magnitude
	if speed < 1 then
		return 0
	end
	local look = Vector3.new(forward.X, 0, forward.Z)
	if look.Magnitude < 1e-6 then
		return 0
	end
	return math.acos(math.clamp(look.Unit:Dot(flat / speed), -1, 1))
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

function Drift.Collide(car: Car, obstacles: { Obstacle }): boolean
	local hit = false
	for _, obstacle in obstacles do
		local dx = car.Position.X - obstacle.X
		local dz = car.Position.Z - obstacle.Z
		local distance = math.sqrt(dx * dx + dz * dz)
		local minimum = obstacle.Radius + EventConfig.CarRadius
		if distance < minimum and distance > 1e-3 then
			local normal = Vector3.new(dx / distance, 0, dz / distance)
			car.Position += normal * (minimum - distance)
			local into = car.Velocity:Dot(normal)
			if into < 0 then
				car.Velocity = (car.Velocity - normal * into * (1 + EventConfig.Bounce)) * 0.8
				hit = true
			end
		end
	end
	return hit
end

function Drift.NewScore(): Score
	return { Points = 0, Combo = 1, Chain = 0, Grace = 0, Active = false }
end

function Drift.Break(score: Score)
	score.Active = false
	score.Chain = 0
	score.Combo = 1
	score.Grace = 0
end

function Drift.Score(score: Score, speed: number, angle: number, dt: number): number
	local sliding = speed >= EventConfig.MinSpeed
		and angle >= EventConfig.MinAngle
		and angle <= EventConfig.MaxAngle
	if sliding then
		score.Active = true
		score.Grace = 0
		score.Chain += dt
		score.Combo = math.min(EventConfig.MaxCombo, 1 + math.floor(score.Chain / EventConfig.ComboStep))
		local gained = speed
			* math.sin(math.min(angle, math.pi / 2))
			* EventConfig.ScoreRate
			* score.Combo
			* dt
		score.Points += gained
		return gained
	end
	if score.Active then
		score.Grace += dt
		if score.Grace > EventConfig.ComboGrace then
			Drift.Break(score)
		end
	end
	return 0
end

return Drift
