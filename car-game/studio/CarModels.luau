--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cars = require(ReplicatedStorage.Config.Cars)
local Parts = require(script.Parent.Parts)

type Spec = {
	Length: number,
	Width: number,
	Height: number,
	Wheel: number,
	WheelWidth: number,
	Hover: boolean,
	OpenWheels: boolean,
}

local specs: { [string]: Spec } = {
	Buggy = {
		Length = 10,
		Width = 6.4,
		Height = 1.6,
		Wheel = 1.6,
		WheelWidth = 1.6,
		Hover = false,
		OpenWheels = true,
	},
	Police = {
		Length = 12.5,
		Width = 6.4,
		Height = 2.2,
		Wheel = 1.3,
		WheelWidth = 1.2,
		Hover = false,
		OpenWheels = false,
	},
	Hatch = {
		Length = 10.5,
		Width = 6.2,
		Height = 2.4,
		Wheel = 1.2,
		WheelWidth = 1.1,
		Hover = false,
		OpenWheels = false,
	},
	Pickup = {
		Length = 13.5,
		Width = 6.6,
		Height = 2.6,
		Wheel = 1.5,
		WheelWidth = 1.3,
		Hover = false,
		OpenWheels = false,
	},
	Rocket = {
		Length = 12,
		Width = 5.8,
		Height = 1.8,
		Wheel = 1.2,
		WheelWidth = 1.2,
		Hover = false,
		OpenWheels = false,
	},
	Coupe = {
		Length = 12,
		Width = 6.4,
		Height = 1.8,
		Wheel = 1.2,
		WheelWidth = 1.2,
		Hover = false,
		OpenWheels = false,
	},
	Hover = {
		Length = 11.5,
		Width = 6.4,
		Height = 1.8,
		Wheel = 1.6,
		WheelWidth = 1,
		Hover = true,
		OpenWheels = false,
	},
	Muscle = {
		Length = 13,
		Width = 6.8,
		Height = 2.2,
		Wheel = 1.4,
		WheelWidth = 1.5,
		Hover = false,
		OpenWheels = false,
	},
	Monster = {
		Length = 12.5,
		Width = 7.5,
		Height = 2.6,
		Wheel = 3.2,
		WheelWidth = 2.6,
		Hover = false,
		OpenWheels = true,
	},
	Supercar = {
		Length = 12.5,
		Width = 7,
		Height = 1.5,
		Wheel = 1.2,
		WheelWidth = 1.4,
		Hover = false,
		OpenWheels = false,
	},
	Racer = {
		Length = 14,
		Width = 3.6,
		Height = 1.5,
		Wheel = 1.4,
		WheelWidth = 1.6,
		Hover = false,
		OpenWheels = true,
	},
	Jet = {
		Length = 15,
		Width = 3.4,
		Height = 2,
		Wheel = 1,
		WheelWidth = 0.9,
		Hover = false,
		OpenWheels = true,
	},
}

local CarModels = {}

local function wedge(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): BasePart
	return Parts.Make(
		parent,
		size,
		cframe,
		color,
		{ Class = "WedgePart", Material = material, Transparency = transparency }
	)
end

local function cylinderAlongZ(
	parent: Instance,
	length: number,
	diameter: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): BasePart
	return Parts.Make(
		parent,
		Vector3.new(length, diameter, diameter),
		CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0),
		color,
		{ Shape = Enum.PartType.Cylinder, Material = material }
	)
end

local function effects(body: BasePart, rear: Vector3, top: number, bottom: number, color: Color3)
	local exhaust = Instance.new("Attachment")
	exhaust.Name = "Exhaust"
	exhaust.CFrame = body.CFrame:ToObjectSpace(CFrame.new(rear))
	exhaust.Parent = body
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "BoostFire"
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.EmissionDirection = Enum.NormalId.Back
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 90, 20))
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.4), NumberSequenceKeypoint.new(1, 0) })
	fire.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	fire.Lifetime = NumberRange.new(0.18, 0.32)
	fire.Rate = 140
	fire.Speed = NumberRange.new(22, 34)
	fire.SpreadAngle = Vector2.new(12, 12)
	fire.LightEmission = 1
	fire.Enabled = false
	fire.Parent = exhaust
	local upper = Instance.new("Attachment")
	upper.Name = "TrailTop"
	upper.CFrame = body.CFrame:ToObjectSpace(CFrame.new(Vector3.new(0, top, rear.Z)))
	upper.Parent = body
	local lower = Instance.new("Attachment")
	lower.Name = "TrailBottom"
	lower.CFrame = body.CFrame:ToObjectSpace(CFrame.new(Vector3.new(0, bottom, rear.Z)))
	lower.Parent = body
	local trail = Instance.new("Trail")
	trail.Name = "SpeedTrail"
	trail.Attachment0 = upper
	trail.Attachment1 = lower
	trail.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	trail.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.35
	trail.LightEmission = 0.6
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = body
end

local function build(car: Cars.Car): Model
	local spec = specs[car.Style] or specs.Coupe
	local model = Instance.new("Model")
	model.Name = car.Id
	local length, width, height, wheel = spec.Length, spec.Width, spec.Height, spec.Wheel
	local ride = if spec.Hover then 1.6 else wheel
	local bodyY = ride + height / 2
	local topY = ride + height
	local color, accent = car.BodyColor, car.AccentColor
	local shine = if car.Material == Enum.Material.Metal then 0.15 else 0
	local dark = Color3.fromRGB(30, 30, 35)
	local glass = Color3.fromRGB(150, 210, 255)

	local body = Parts.Make(model, Vector3.new(width, height, length), CFrame.new(0, bodyY, 0), color, {
		Name = "Body",
		Material = car.Material,
		Reflectance = shine,
	})
	model.PrimaryPart = body

	local noseLength = length * 0.28
	wedge(
		model,
		Vector3.new(width, height * 0.5, noseLength),
		CFrame.new(0, topY + height * 0.25, -length / 2 + noseLength / 2),
		color,
		car.Material
	)
	local seatZ = length * 0.08
	wedge(
		model,
		Vector3.new(width * 0.84, 1.8, 1.4),
		CFrame.new(0, topY + 0.9, seatZ - 2.2),
		glass,
		Enum.Material.Glass,
		0.35
	)

	local seat = Instance.new("Seat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 0.6, 2)
	seat.CFrame = CFrame.new(0, topY + 0.3, seatZ)
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.CanTouch = false
	seat.CanQuery = false
	seat.Parent = model

	for _, side in { -1, 1 } do
		Parts.Make(
			model,
			Vector3.new(1.1, 0.5, 0.2),
			CFrame.new(side * (width / 2 - 1), bodyY + height * 0.15, -length / 2 - 0.1),
			Color3.fromRGB(255, 255, 230),
			{
				Material = Enum.Material.Neon,
			}
		)
		Parts.Make(
			model,
			Vector3.new(1.1, 0.5, 0.2),
			CFrame.new(side * (width / 2 - 1), bodyY + height * 0.15, length / 2 + 0.1),
			Color3.fromRGB(255, 40, 40),
			{
				Material = Enum.Material.Neon,
			}
		)
	end

	if spec.Hover then
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				Parts.Disc(
					model,
					2.6,
					0.6,
					Vector3.new(x * (width / 2 - 1.2), ride - 0.4, z * (length / 2 - 2)),
					accent,
					Enum.Material.Neon
				)
			end
			Parts.Make(
				model,
				Vector3.new(0.4, 0.4, length * 0.9),
				CFrame.new(x * (width / 2 + 0.1), ride + 0.2, 0),
				accent,
				{
					Material = Enum.Material.Neon,
				}
			)
		end
	else
		local wheelX = if spec.OpenWheels
			then width / 2 + spec.WheelWidth / 2 + 0.1
			else width / 2 - spec.WheelWidth / 2 + 0.4
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				local rear = z > 0
				local radius = if car.Style == "Buggy" and rear then wheel * 1.15 else wheel
				local center = Vector3.new(x * wheelX, radius, z * (length / 2 - wheel * 1.4))
				Parts.Make(
					model,
					Vector3.new(spec.WheelWidth, radius * 2, radius * 2),
					CFrame.new(center),
					dark,
					{
						Shape = Enum.PartType.Cylinder,
						Name = "Wheel",
					}
				)
				Parts.Make(
					model,
					Vector3.new(0.3, radius * 1.1, radius * 1.1),
					CFrame.new(center + Vector3.new(x * (spec.WheelWidth / 2 + 0.1), 0, 0)),
					accent,
					{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal }
				)
			end
		end
	end

	local style = car.Style
	if style == "Buggy" or style == "Police" then
		for _, side in { -1, 1 } do
			Parts.Make(
				model,
				Vector3.new(0.5, 4, 0.5),
				CFrame.new(side * (width / 2 - 0.6), topY + 2, seatZ + 1.6),
				dark
			)
		end
		Parts.Make(model, Vector3.new(width - 0.6, 0.5, 0.5), CFrame.new(0, topY + 4, seatZ + 1.6), dark)
		if style == "Police" then
			Parts.Make(
				model,
				Vector3.new(1.6, 0.6, 0.8),
				CFrame.new(-1.2, topY + 4.5, seatZ + 1.6),
				Color3.fromRGB(40, 90, 255),
				{
					Material = Enum.Material.Neon,
				}
			)
			Parts.Make(
				model,
				Vector3.new(1.6, 0.6, 0.8),
				CFrame.new(1.2, topY + 4.5, seatZ + 1.6),
				Color3.fromRGB(255, 40, 40),
				{
					Material = Enum.Material.Neon,
				}
			)
			for _, side in { -1, 1 } do
				Parts.Make(
					model,
					Vector3.new(0.2, height * 0.8, length * 0.4),
					CFrame.new(side * (width / 2 + 0.1), bodyY, 0),
					accent
				)
			end
		else
			Parts.Make(
				model,
				Vector3.new(width * 0.5, 1.4, 2.4),
				CFrame.new(0, topY + 0.7, length / 2 - 1.6),
				dark,
				{
					Material = Enum.Material.Metal,
				}
			)
		end
	elseif style == "Hatch" then
		Parts.Make(
			model,
			Vector3.new(width, 1.6, length * 0.28),
			CFrame.new(0, topY + 0.8, length / 2 - length * 0.14),
			color,
			{
				Material = car.Material,
			}
		)
	elseif style == "Pickup" then
		for _, side in { -1, 1 } do
			Parts.Make(
				model,
				Vector3.new(0.4, 1.4, length * 0.36),
				CFrame.new(side * (width / 2 - 0.2), topY + 0.7, length / 2 - length * 0.18),
				color
			)
		end
		Parts.Make(model, Vector3.new(width, 1.4, 0.4), CFrame.new(0, topY + 0.7, length / 2 - 0.2), color)
	elseif style == "Rocket" then
		cylinderAlongZ(
			model,
			6,
			3,
			Vector3.new(0, topY + 1.4, length / 2 - 2.4),
			Color3.fromRGB(220, 220, 230),
			Enum.Material.Metal
		)
		Parts.Disc(
			model,
			2.6,
			0.4,
			Vector3.new(0, topY + 1.4, length / 2 + 0.6),
			Color3.fromRGB(255, 140, 30),
			Enum.Material.Neon
		)
		for _, side in { -1, 1 } do
			wedge(
				model,
				Vector3.new(0.3, 2.6, 3),
				CFrame.new(side * (width / 2 - 0.3), topY + 1.3, length / 2 - 1.5),
				accent
			)
		end
	elseif style == "Coupe" or style == "Supercar" then
		local wingWidth = if style == "Supercar" then width + 0.6 else width - 0.4
		for _, side in { -1, 1 } do
			Parts.Make(
				model,
				Vector3.new(0.3, 1.6, 0.4),
				CFrame.new(side * (width / 2 - 1.2), topY + 0.8, length / 2 - 1),
				dark
			)
		end
		Parts.Make(model, Vector3.new(wingWidth, 0.3, 1.8), CFrame.new(0, topY + 1.7, length / 2 - 1), accent)
		if style == "Supercar" then
			for _, side in { -1, 1 } do
				Parts.Make(
					model,
					Vector3.new(0.3, height * 0.6, length * 0.2),
					CFrame.new(side * (width / 2 + 0.1), bodyY, length * 0.1),
					dark
				)
			end
		end
	elseif style == "Muscle" then
		Parts.Make(model, Vector3.new(2, 0.8, 2.4), CFrame.new(0, topY + 0.7, -length * 0.25), dark)
		for _, x in { -0.7, 0.7 } do
			Parts.Make(model, Vector3.new(0.7, 0.1, length + 0.1), CFrame.new(x, topY + 0.05, 0), accent)
		end
	elseif style == "Monster" then
		for _, x in { -1, 1 } do
			Parts.Make(
				model,
				Vector3.new(0.6, wheel * 1.2, 0.6),
				CFrame.new(x * (width / 2 - 0.5), wheel * 0.9, 0),
				accent,
				{
					Material = Enum.Material.Metal,
				}
			)
		end
	elseif style == "Racer" then
		Parts.Make(
			model,
			Vector3.new(width + 5.4, 0.3, 1.6),
			CFrame.new(0, ride + 0.4, -length / 2 + 0.6),
			accent
		)
		Parts.Make(
			model,
			Vector3.new(width + 3, 0.3, 1.8),
			CFrame.new(0, topY + 2.2, length / 2 - 0.8),
			accent
		)
		for _, side in { -1, 1 } do
			Parts.Make(
				model,
				Vector3.new(0.3, 2.2, 0.6),
				CFrame.new(side * 1.2, topY + 1.1, length / 2 - 0.8),
				dark
			)
		end
	elseif style == "Jet" then
		cylinderAlongZ(model, length, 3.6, Vector3.new(0, bodyY + 0.4, 0), color, car.Material)
		Parts.Make(model, Vector3.new(14, 0.4, 3.6), CFrame.new(0, bodyY + 0.2, 1), accent)
		Parts.Make(model, Vector3.new(0.4, 3.4, 2.6), CFrame.new(0, topY + 1.8, length / 2 - 1.4), accent)
		Parts.Make(model, Vector3.new(6, 0.3, 1.8), CFrame.new(0, topY + 0.6, length / 2 - 1.2), accent)
		Parts.Disc(
			model,
			3,
			0.4,
			Vector3.new(0, bodyY + 0.4, length / 2 + 0.3),
			Color3.fromRGB(80, 200, 255),
			Enum.Material.Neon
		)
	end

	effects(body, Vector3.new(0, bodyY, length / 2 + 0.6), topY + 1, ride + 0.2, accent)

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end
	model.WorldPivot = CFrame.new()
	model:SetAttribute("CarId", car.Id)
	return model
end

function CarModels.Build(assets: Folder)
	local existing = assets:FindFirstChild("Cars")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Cars"
	for _, car in Cars.Order do
		build(car).Parent = folder
	end
	folder.Parent = assets
end

return CarModels
