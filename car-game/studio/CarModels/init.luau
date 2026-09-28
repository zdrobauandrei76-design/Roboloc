--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cars = require(ReplicatedStorage.Config.Cars)
local Bodies = require(script.Bodies)
local Kit = require(script.Kit)
local Specials = require(script.Specials)

type Built = {
	Body: BasePart,
	Rear: number,
	Top: number,
	Exhaust: Vector3,
}

local CarModels = {}

local function spec(car: Cars.Car, overrides: { [string]: any }): Bodies.Spec
	local base: { [string]: any } = {
		Length = 15,
		Width = 7.2,
		WheelRadius = 1.3,
		WheelWidth = 1.25,
		RearWheelWidth = nil,
		FrontAxle = -4.7,
		RearAxle = 4.6,
		Ground = 0.75,
		Belt = 3.55,
		Nose = 3.0,
		NoseLength = 4.0,
		CabinFront = -1.4,
		CabinBack = 2.6,
		CockpitWidth = 3.9,
		Deck = 3.55,
		Roof = 6.3,
		Color = car.BodyColor,
		Accent = car.AccentColor,
		Rim = Kit.Chrome,
		Paint = if car.Material == Enum.Material.Metal then Kit.Metal(0.15) else Kit.Paint(),
		Spokes = 5,
		Wing = 0,
		Stripes = false,
		Scoop = false,
		Intakes = false,
		Fairing = false,
		ChromeBumpers = false,
		Glow = false,
	}
	for key, value in overrides do
		base[key] = value
	end
	return base :: any
end

local function fromBody(result: Bodies.Result, ground: number): Built
	return {
		Body = result.Body,
		Rear = result.Rear,
		Top = result.Top,
		Exhaust = Vector3.new(0, ground + 0.4, result.Rear + 0.6),
	}
end

local function police(model: Model, car: Cars.Car): Built
	local definition = spec(car, {
		Belt = 3.6,
		Nose = 3.05,
		NoseLength = 3.0,
		CabinFront = -1.9,
		CabinBack = 3.5,
		Deck = 3.6,
		Roof = 6.3,
		Rim = Kit.Chrome,
		Spokes = 6,
	})
	local result = Bodies.Closed(model, definition)
	local halfWidth = definition.Width / 2
	for _, side in { -1, 1 } do
		Kit.Span(
			model,
			side * halfWidth,
			side * (halfWidth + 0.05),
			1.3,
			definition.Belt - 0.15,
			-1.9,
			3.4,
			car.AccentColor,
			Kit.Paint()
		)
	end
	local roof = result.Roof
	Kit.Span(
		model,
		-1.7,
		1.7,
		roof,
		roof + 0.25,
		result.Middle - 0.6,
		result.Middle + 0.6,
		Kit.Trim,
		Kit.Matte()
	)
	Kit.Span(
		model,
		-1.6,
		-0.15,
		roof + 0.25,
		roof + 0.7,
		result.Middle - 0.5,
		result.Middle + 0.5,
		Color3.fromRGB(255, 40, 50),
		Kit.Neon()
	)
	Kit.Span(
		model,
		0.15,
		1.6,
		roof + 0.25,
		roof + 0.7,
		result.Middle - 0.5,
		result.Middle + 0.5,
		Color3.fromRGB(40, 110, 255),
		Kit.Neon()
	)
	Kit.Span(
		model,
		-0.15,
		0.15,
		roof + 0.25,
		roof + 0.6,
		result.Middle - 0.4,
		result.Middle + 0.4,
		Color3.fromRGB(245, 245, 245),
		Kit.Neon()
	)
	local frontZ = -definition.Length / 2
	for _, x in { -1.6, 1.6 } do
		Kit.Tube(
			model,
			Vector3.new(x, 1.0, frontZ - 0.1),
			Vector3.new(x, 2.7, frontZ - 0.7),
			0.3,
			Kit.Trim,
			Kit.Matte()
		)
	end
	Kit.Tube(
		model,
		Vector3.new(-1.8, 2.4, frontZ - 0.62),
		Vector3.new(1.8, 2.4, frontZ - 0.62),
		0.3,
		Kit.Trim,
		Kit.Matte()
	)
	Kit.Tube(
		model,
		Vector3.new(-1.8, 1.4, frontZ - 0.35),
		Vector3.new(1.8, 1.4, frontZ - 0.35),
		0.3,
		Kit.Trim,
		Kit.Matte()
	)
	return fromBody(result, definition.Ground)
end

local function hatch(model: Model, car: Cars.Car): Built
	local definition = spec(car, {
		Length = 12.6,
		Width = 6.9,
		WheelRadius = 1.2,
		WheelWidth = 1.15,
		FrontAxle = -3.9,
		RearAxle = 3.9,
		Ground = 0.7,
		Belt = 3.35,
		Nose = 2.85,
		NoseLength = 1.8,
		CabinFront = -2.2,
		CabinBack = 5.3,
		Deck = 3.35,
		Roof = 6.1,
		RearLean = 0.7,
		Rim = Color3.fromRGB(245, 245, 245),
		Spokes = 4,
	})
	local result = Bodies.Closed(model, definition)
	Kit.Span(model, -2.5, 2.5, result.Roof, result.Roof + 0.08, -0.2, 3.9, car.AccentColor, Kit.Paint())
	for _, x in { -1.9, 1.9 } do
		Kit.Span(model, x - 0.1, x + 0.1, result.Roof, result.Roof + 0.35, -0.4, 4.2, Kit.Trim, Kit.Matte())
	end
	return fromBody(result, definition.Ground)
end

local function pickup(model: Model, car: Cars.Car, overrides: { [string]: any }?): (Built, Bodies.Spec)
	local values: { [string]: any } = {
		Length = 15.6,
		Width = 7.4,
		WheelRadius = 1.5,
		WheelWidth = 1.4,
		FrontAxle = -4.9,
		RearAxle = 4.4,
		Ground = 1.0,
		Belt = 4.1,
		Nose = 3.75,
		NoseLength = 1.4,
		CabinFront = -2.6,
		CabinBack = 1.3,
		Deck = 4.1,
		Roof = 6.9,
		RearLean = 0.25,
		Bed = true,
		ChromeBumpers = true,
		Rim = Kit.Chrome,
		Spokes = 6,
	}
	local extra: { [string]: any } = overrides or {}
	for key, value in extra do
		values[key] = value
	end
	local definition = spec(car, values)
	local result = Bodies.Closed(model, definition)
	return fromBody(result, definition.Ground), definition
end

local function monster(model: Model, car: Cars.Car): Built
	local lift = 3.3
	local holder = Instance.new("Model")
	local built, definition = pickup(holder, car, {
		Length = 14.2,
		Width = 6.8,
		WheelRadius = 1.2,
		FrontAxle = -4.4,
		RearAxle = 4.4,
		Ground = 0.6,
		Belt = 3.5,
		Nose = 3.1,
		CabinFront = -2.4,
		CabinBack = 1.0,
		Deck = 3.5,
		Roof = 6.2,
		Arches = false,
		Wheels = false,
	})
	for _, child in holder:GetChildren() do
		if child:IsA("BasePart") then
			child.CFrame += Vector3.new(0, lift, 0)
		end
		child.Parent = model
	end
	holder:Destroy()
	local radius, width = 3.0, 2.5
	local wheelX = definition.Width / 2 + 1.35
	for _, z in { -4.4, 4.4 } do
		Kit.CylinderX(model, wheelX * 2 - width, 0.6, Vector3.new(0, radius, z), Kit.Trim, Kit.Matte())
		Kit.Span(model, -1.4, 1.4, radius - 0.6, radius + 0.6, z - 0.6, z + 0.6, Kit.Trim, Kit.Matte())
		for _, side in { -1, 1 } do
			Kit.Wheel(model, Vector3.new(side * wheelX, radius, z), radius, width, side, car.AccentColor, 8)
			Kit.Tube(
				model,
				Vector3.new(side * 1.2, radius, z),
				Vector3.new(side * 2.4, lift + 0.8, z + 0.9),
				0.45,
				Kit.Chrome,
				Kit.Metal(0.3)
			)
			Kit.Tube(
				model,
				Vector3.new(side * 1.2, radius, z),
				Vector3.new(side * 2.4, lift + 0.8, z - 0.9),
				0.45,
				Kit.Amber,
				Kit.Paint()
			)
		end
	end
	for _, side in { -1, 1 } do
		Kit.Span(model, side * 1.1, side * 1.6, radius - 0.2, lift + 0.7, -6.5, 6.5, Kit.Trim, Kit.Matte())
	end
	local roofY = definition.Roof + 0.3 + lift
	Kit.Span(model, -2.4, 2.4, roofY, roofY + 0.2, -0.9, -0.5, Kit.Trim, Kit.Matte())
	for index = -3, 3, 2 do
		Kit.Box(
			model,
			Vector3.new(0.9, 0.35, 0.1),
			CFrame.new(index * 0.6, roofY + 0.4, -0.75),
			Kit.HeadLight,
			Kit.Neon()
		)
		Kit.Span(
			model,
			index * 0.6 - 0.5,
			index * 0.6 + 0.5,
			roofY + 0.2,
			roofY + 0.6,
			-0.72,
			-0.66,
			Kit.Trim,
			Kit.Matte()
		)
	end
	return {
		Body = built.Body,
		Rear = built.Rear,
		Top = roofY + 0.6,
		Exhaust = built.Exhaust + Vector3.new(0, lift, 0),
	}
end

local builders: { [string]: (model: Model, car: Cars.Car) -> Built } = {
	Buggy = function(model, car)
		local result = Specials.Buggy(model, car.BodyColor, car.AccentColor)
		return { Body = result.Body, Rear = result.Rear, Top = result.Top, Exhaust = result.Exhaust }
	end,
	Police = police,
	Hatch = hatch,
	Pickup = function(model, car)
		local built = pickup(model, car)
		return built
	end,
	Rocket = function(model, car)
		local result = Specials.Rocket(model, car.BodyColor, car.AccentColor)
		return { Body = result.Body, Rear = result.Rear, Top = result.Top, Exhaust = result.Exhaust }
	end,
	Coupe = function(model, car)
		local definition = spec(car, {
			WheelRadius = 1.4,
			Ground = 0.8,
			Nose = 3.2,
			Belt = 3.8,
			Deck = 3.8,
			NoseLength = 3.8,
			Wing = 0.75,
			Stripes = true,
			Fairing = true,
			Rim = Kit.Trim,
			RearWheelWidth = 1.5,
		})
		return fromBody(Bodies.Roadster(model, definition), definition.Ground)
	end,
	NeonHover = function(model, car)
		local result = Specials.Hover(model, car.BodyColor, car.AccentColor)
		return { Body = result.Body, Rear = result.Rear, Top = result.Top, Exhaust = result.Exhaust }
	end,
	Muscle = function(model, car)
		local definition = spec(car, {
			Length = 15.6,
			Width = 7.5,
			WheelRadius = 1.45,
			RearWheelWidth = 1.75,
			FrontAxle = -4.8,
			RearAxle = 4.7,
			Ground = 0.75,
			Belt = 3.95,
			Nose = 3.45,
			NoseLength = 2.4,
			CabinFront = -0.8,
			CabinBack = 3.1,
			Deck = 3.85,
			Stripes = true,
			Scoop = true,
			ChromeBumpers = true,
			Spokes = 5,
		})
		return fromBody(Bodies.Roadster(model, definition), definition.Ground)
	end,
	Monster = monster,
	Golden = function(model, car)
		local definition = spec(car, {
			Length = 15.6,
			Width = 7.8,
			WheelRadius = 1.4,
			WheelWidth = 1.35,
			RearWheelWidth = 1.7,
			FrontAxle = -4.9,
			RearAxle = 4.8,
			Ground = 0.65,
			Belt = 3.55,
			Nose = 3.1,
			NoseLength = 5.0,
			CabinFront = -1.0,
			CabinBack = 2.8,
			Deck = 3.65,
			Paint = Kit.Paint(0.3),
			Wing = 1.2,
			Intakes = true,
			Fairing = true,
			Rim = Kit.Trim,
			Spokes = 10,
		})
		return fromBody(Bodies.Roadster(model, definition), definition.Ground)
	end,
	Racer = function(model, car)
		local result = Specials.Racer(model, car.BodyColor, car.AccentColor)
		return { Body = result.Body, Rear = result.Rear, Top = result.Top, Exhaust = result.Exhaust }
	end,
	Hyper = function(model, car)
		local definition = spec(car, {
			Length = 16,
			Width = 8,
			WheelRadius = 1.45,
			WheelWidth = 1.4,
			RearWheelWidth = 1.8,
			FrontAxle = -5.0,
			RearAxle = 5.0,
			Ground = 0.6,
			Belt = 3.55,
			Nose = 3.2,
			NoseLength = 5.5,
			CabinFront = -1.0,
			CabinBack = 2.8,
			Deck = 3.65,
			Wing = 1.6,
			Intakes = true,
			Fairing = true,
			Glow = true,
			Rim = Kit.Chrome,
			Spokes = 7,
		})
		local result = Bodies.Roadster(model, definition)
		local halfLength = definition.Length / 2
		local halfWidth = definition.Width / 2
		Kit.Ramp(
			model,
			-0.12,
			0.12,
			definition.Deck,
			definition.Deck + 1.3,
			definition.CabinBack + 0.6,
			halfLength - 0.5,
			car.AccentColor,
			Kit.Paint()
		)
		for _, side in { -1, 1 } do
			Kit.Box(
				model,
				Vector3.new(1.7, 0.12, 0.12),
				CFrame.new(side * (halfWidth - 1.15), definition.Nose - 0.05, -halfLength - 0.08),
				car.AccentColor,
				Kit.Neon()
			)
			Kit.Span(
				model,
				side * halfWidth,
				side * (halfWidth + 0.05),
				definition.Belt - 0.25,
				definition.Belt - 0.13,
				definition.FrontAxle,
				definition.RearAxle,
				car.AccentColor,
				Kit.Neon()
			)
		end
		return fromBody(result, definition.Ground)
	end,
	Jet = function(model, car)
		local result = Specials.Jet(model, car.BodyColor, car.AccentColor)
		return { Body = result.Body, Rear = result.Rear, Top = result.Top, Exhaust = result.Exhaust }
	end,
}

local function build(car: Cars.Car): Model
	local model = Instance.new("Model")
	model.Name = car.Id
	local builder = builders[car.Id]
	assert(builder, `No car design for {car.Id}`)
	local built = builder(model, car)
	local body = built.Body
	model.PrimaryPart = body
	body.PivotOffset = body.CFrame:Inverse()
	Kit.Effects(
		body,
		built.Exhaust,
		Vector3.new(0, built.Top - 0.4, built.Rear),
		Vector3.new(0, 0.6, built.Rear),
		car.BodyColor,
		car.AccentColor
	)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end
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
