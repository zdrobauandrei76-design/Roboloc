--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local EventConfig = require(ReplicatedStorage.Config.Event)
local Drift = require(ReplicatedStorage.Game.Drift)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)

export type Session = {
	Name: string,
	Title: string,
	Center: CFrame,
	Radius: number,
	Ground: number,
	Car: Drift.Car,
	Score: Drift.Score,
	Obstacles: { Drift.Obstacle },
	Lean: number,
}

local step = 1 / 60

local DriftController = {
	Name = "DriftController",
	Started = Signal.new() :: Signal.Signal<string>,
	Ended = Signal.new() :: Signal.Signal<()>,
	Crashed = Signal.new() :: Signal.Signal<()>,
}
local controllers: { [string]: any } = {}
local session: Session? = nil
local blocked: string? = nil
local accumulator = 0
local lastCombo = 1
local touch: { [string]: boolean } = { Left = false, Right = false, Drift = false, Brake = false }
local connection: RBXScriptConnection? = nil

function DriftController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function DriftController.SetTouch(_self: any, name: string, pressed: boolean)
	if touch[name] ~= nil then
		touch[name] = pressed
	end
end

function DriftController.GetSession(_self: any): Session?
	return session
end

local function keyDown(...: Enum.KeyCode): boolean
	for _, key in { ... } do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return false
end

local function readInput(): Drift.Input
	local steer = 0
	if keyDown(Enum.KeyCode.A, Enum.KeyCode.Left) or touch.Left then
		steer -= 1
	end
	if keyDown(Enum.KeyCode.D, Enum.KeyCode.Right) or touch.Right then
		steer += 1
	end
	local brake = keyDown(Enum.KeyCode.S, Enum.KeyCode.Down) or touch.Brake
	local handbrake = keyDown(Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
		or touch.Drift
	if UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
		for _, input in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
			if input.KeyCode == Enum.KeyCode.Thumbstick1 and math.abs(input.Position.X) > 0.2 then
				steer = input.Position.X
			end
		end
		brake = brake
			or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2)
		handbrake = handbrake
			or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
			or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR2)
	end
	return { Steer = math.clamp(steer, -1, 1), Throttle = if brake then -1 else 1, Handbrake = handbrake }
end

local function findIsland(name: string): Model?
	local map = workspace:FindFirstChild("Map")
	local folder = map and map:FindFirstChild("DriftIslands")
	local island = folder and folder:FindFirstChild(name)
	return if island and island:IsA("Model") then island else nil
end

local function begin(name: string)
	local island = findIsland(name)
	if not island then
		return
	end
	local center = island:GetAttribute("Center")
	local radius = island:GetAttribute("Radius")
	local ground = island:GetAttribute("Ground")
	if typeof(center) ~= "CFrame" or type(radius) ~= "number" or type(ground) ~= "number" then
		return
	end
	if not controllers.LaunchController:EnterEvent() then
		return
	end
	local obstacles: { Drift.Obstacle } = {}
	local folder = island:FindFirstChild("Obstacles")
	if folder then
		for _, child in folder:GetChildren() do
			local x, z, size = child:GetAttribute("X"), child:GetAttribute("Z"), child:GetAttribute("Radius")
			if type(x) == "number" and type(z) == "number" and type(size) == "number" then
				table.insert(obstacles, { X = x, Z = z, Radius = size })
			end
		end
	end
	local slot = Players.LocalPlayer:GetAttribute("DriftSlot")
	local position, heading =
		Drift.Slot(center, radius, if type(slot) == "number" then slot else 1, EventConfig.Slots)
	local title = island:GetAttribute("Title")
	local theme = island:GetAttribute("Theme")
	session = {
		Name = name,
		Title = if type(title) == "string" then title else name,
		Center = center,
		Radius = radius,
		Ground = ground,
		Car = Drift.NewCar(position, heading),
		Score = Drift.NewScore(),
		Obstacles = obstacles,
		Lean = 0,
	}
	accumulator = 0
	lastCombo = 1
	controllers.AtmosphereController:SetOverride(if type(theme) == "number" then theme else nil)
	controllers.SoundController:Play("Swoosh")
	DriftController.Started:Fire(name)
end

local function finish()
	if not session then
		return
	end
	session = nil
	for name in touch do
		touch[name] = false
	end
	controllers.SoundController:SetLoop("Wind", false)
	controllers.AtmosphereController:SetOverride(nil)
	controllers.LaunchController:ExitEvent()
	DriftController.Ended:Fire()
end

local function update(dt: number)
	local attribute = Players.LocalPlayer:GetAttribute("DriftIsland")
	local name = if type(attribute) == "string" then attribute else nil
	if blocked and blocked ~= name then
		blocked = nil
	end
	local current = session
	if current and current.Name ~= name then
		finish()
		current = nil
	end
	if not current and name and blocked ~= name then
		begin(name)
		current = session
	end
	if not current then
		return
	end
	local goAt = workspace:GetAttribute("DriftGoAt")
	local frozen = type(goAt) == "number" and workspace:GetServerTimeNow() < goAt
	local car = current.Car
	accumulator += math.min(dt, 0.1)
	while accumulator >= step do
		accumulator -= step
		local input: Drift.Input = if frozen
			then { Steer = 0, Throttle = 0, Handbrake = false }
			else readInput()
		car.Grounded = car.Grounded and Drift.OnSurface(current.Center, current.Radius, car.Position)
		Drift.Step(car, input, step)
		if car.Grounded then
			if Drift.Collide(car, current.Obstacles) then
				Drift.Break(current.Score)
				controllers.SoundController:Play("Land", 1.3)
				controllers.CameraController:Shake(0.5, 0.25)
				DriftController.Crashed:Fire()
			end
			local speed = car.Velocity.Magnitude
			Drift.Score(current.Score, speed, Drift.Angle(Drift.Forward(car.Heading), car.Velocity), step)
		end
	end
	if current.Score.Combo > lastCombo then
		controllers.SoundController:Play("Click", 0.9 + current.Score.Combo * 0.08)
	end
	lastCombo = current.Score.Combo
	if car.Position.Y < current.Ground - EventConfig.FallDepth then
		blocked = current.Name
		Packets.LeaveDrift:Fire()
		controllers.SoundController:Play("Error")
		finish()
		return
	end
	local forward = Drift.Forward(car.Heading)
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local slip = car.Velocity:Dot(right)
	current.Lean += (math.clamp(-slip / 60, -0.12, 0.12) - current.Lean) * (1 - math.exp(-dt * 6))
	local pitch = if car.Grounded then 0 else math.clamp(-car.VerticalSpeed / 200, -0.5, 0)
	local pivot = CFrame.new(car.Position)
		* CFrame.Angles(0, car.Heading, 0)
		* CFrame.Angles(pitch, 0, current.Lean)
	controllers.LaunchController:ApplyPose(pivot, car.Velocity + Vector3.new(0, car.VerticalSpeed, 0))
	local speed = car.Velocity.Magnitude
	controllers.CameraController:SetSpeed(speed)
	controllers.SoundController:SetLoop(
		"Wind",
		speed > 5 and not frozen,
		math.clamp(speed / 120, 0.15, 0.6),
		0.7 + (if car.Drifting then 0.35 else 0) + speed / 400
	)
end

function DriftController.Start(_self: any)
	connection = RunService.PreSimulation:Connect(update)
end

function DriftController.Destroy(_self: any)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	finish()
end

return DriftController
