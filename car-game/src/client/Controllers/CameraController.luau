--!strict

local RunService = game:GetService("RunService")

local CameraController = { Name = "CameraController" }
local target: Model? = nil
local mode = "Idle"
local speed = 0
local shakeAmount = 0
local shakeUntil = 0
local offset = Vector3.new(-30, 14, 20)
local orbitAngle = 0
local connection: RBXScriptConnection? = nil
local random = Random.new()
local wasScripted = false

function CameraController.Init(_self: any, _controllers: { [string]: any }) end

function CameraController.SetTarget(_self: any, model: Model?)
	target = model
end

function CameraController.SetMode(_self: any, newMode: string)
	if newMode ~= mode then
		mode = newMode
		orbitAngle = 0
	end
end

function CameraController.SetSpeed(_self: any, value: number)
	speed = value
end

function CameraController.Shake(_self: any, amount: number, duration: number)
	shakeAmount = math.max(shakeAmount, amount)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

local function desiredOffset(): Vector3
	if mode == "Chase" then
		local back = math.min(24 + speed * 0.012, 44)
		local height = math.min(9 + speed * 0.004, 16)
		return Vector3.new(-back, height, 0)
	elseif mode == "Orbit" then
		return Vector3.new(math.cos(orbitAngle) * -30, 12, math.sin(orbitAngle) * 30)
	end
	return Vector3.new(-34, 16, 22)
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	local model = target
	if not camera then
		return
	end
	if not model or not model.Parent then
		if wasScripted then
			wasScripted = false
			camera.CameraType = Enum.CameraType.Custom
		end
		return
	end
	wasScripted = true
	camera.CameraType = Enum.CameraType.Scriptable
	if mode == "Orbit" then
		orbitAngle += dt * 0.35
	end
	local focus = model:GetPivot().Position + Vector3.new(0, 4, 0)
	local alpha = 1 - math.exp(-dt * (if mode == "Chase" then 5 else 3))
	offset = offset:Lerp(desiredOffset(), alpha)
	local lookAhead = if mode == "Chase"
		then Vector3.new(math.min(30 + speed * 0.05, 120), -2, 0)
		elseif mode == "Idle" then Vector3.new(60, -18, 0)
		else Vector3.zero
	local position = focus + offset
	local now = os.clock()
	if now < shakeUntil then
		local strength = shakeAmount * (shakeUntil - now)
		position += Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1, 1), random:NextNumber(-1, 1)) * strength
	else
		shakeAmount = 0
	end
	camera.CFrame = CFrame.lookAt(position, focus + lookAhead)
	local fov = if mode == "Chase" then 70 + math.min(speed / 45, 24) else 70
	camera.FieldOfView += (fov - camera.FieldOfView) * alpha
end

function CameraController.Start(_self: any)
	connection = RunService.PreRender:Connect(update)
end

function CameraController.Destroy(_self: any)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	local camera = workspace.CurrentCamera
	if camera and wasScripted then
		camera.CameraType = Enum.CameraType.Custom
	end
end

return CameraController
