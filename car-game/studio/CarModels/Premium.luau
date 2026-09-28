--!strict

local Kit = require(script.Parent.Kit)

export type Extents = {
	MinX: number,
	MaxX: number,
	FrontAxle: number,
	RearAxle: number,
	WheelRadius: number,
	WheelWidth: number,
}

local Premium = {}

local function sameColor(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01
end

function Premium.Extents(model: Model): Extents
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local radius, width = 1, 1
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name == "Tire" then
			local position = descendant.CFrame.Position
			minX = math.min(minX, position.X - descendant.Size.X / 2)
			maxX = math.max(maxX, position.X + descendant.Size.X / 2)
			minZ = math.min(minZ, position.Z)
			maxZ = math.max(maxZ, position.Z)
			radius = descendant.Size.Y / 2
			width = descendant.Size.X
		end
	end
	return {
		MinX = minX,
		MaxX = maxX,
		FrontAxle = minZ,
		RearAxle = maxZ,
		WheelRadius = radius,
		WheelWidth = width,
	}
end

function Premium.Finish(model: Model, paint: Color3, accent: Color3, reflectance: number)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Material ~= Enum.Material.Neon then
			if sameColor(descendant.Color, paint) then
				descendant.Material = Enum.Material.SmoothPlastic
				descendant.Reflectance = reflectance
			elseif sameColor(descendant.Color, Kit.Chrome) then
				descendant.Material = Enum.Material.SmoothPlastic
				descendant.Reflectance = 0.65
			elseif sameColor(descendant.Color, accent) then
				descendant.Reflectance = math.max(descendant.Reflectance, reflectance * 0.7)
			end
		end
	end
end

function Premium.Underglow(model: Model, body: BasePart, glow: Color3)
	local extents = Premium.Extents(model)
	local inner = extents.MaxX - extents.WheelWidth - 0.35
	local front = extents.FrontAxle + extents.WheelRadius + 0.4
	local back = extents.RearAxle - extents.WheelRadius - 0.4
	for _, side in { -1, 1 } do
		Kit.Box(
			model,
			Vector3.new(0.3, 0.12, math.max(back - front, 1)),
			CFrame.new(side * inner, 0.32, (front + back) / 2),
			glow,
			Kit.Neon()
		)
	end
	for _, z in
		{ extents.FrontAxle - extents.WheelRadius * 0.4, extents.RearAxle + extents.WheelRadius * 0.4 }
	do
		Kit.Box(model, Vector3.new(inner * 2 - 0.6, 0.12, 0.3), CFrame.new(0, 0.32, z), glow, Kit.Neon())
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "Underglow"
	attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(0, 0.4, (front + back) / 2))
	attachment.Parent = body
	local light = Instance.new("PointLight")
	light.Name = "UnderglowLight"
	light.Color = glow
	light.Brightness = 2.5
	light.Range = 12
	light.Shadows = false
	light.Parent = attachment
end

function Premium.Sparkles(body: BasePart, color: Color3)
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "PremiumSparkle"
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), color)
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Transparency = NumberSequence.new(0.1)
	sparkle.Lifetime = NumberRange.new(0.8, 1.6)
	sparkle.Rate = 7
	sparkle.Speed = NumberRange.new(0.4, 1.4)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Shape = Enum.ParticleEmitterShape.Box
	sparkle.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	sparkle.LightEmission = 1
	sparkle.LightInfluence = 0
	sparkle.Parent = body
end

function Premium.Crown(model: Model, cframe: CFrame, gold: Color3, gem: Color3)
	Kit.Box(model, Vector3.new(1.3, 0.18, 0.5), cframe, gold, Kit.Paint(0.6))
	for index = -1, 1 do
		Kit.Box(
			model,
			Vector3.new(0.22, if index == 0 then 0.55 else 0.42, 0.22),
			cframe * CFrame.new(index * 0.5, 0.3, 0) * CFrame.Angles(0, 0, index * -0.25),
			gold,
			Kit.Paint(0.6)
		)
		Kit.Box(
			model,
			Vector3.one * 0.16,
			cframe
				* CFrame.new(index * 0.56, if index == 0 then 0.62 else 0.52, 0)
				* CFrame.Angles(0.7, 0.7, 0),
			gem,
			Kit.Neon()
		)
	end
end

function Premium.Star(model: Model, cframe: CFrame, color: Color3)
	for index = 0, 1 do
		Kit.Box(
			model,
			Vector3.new(0.6, 0.6, 0.08),
			cframe * CFrame.Angles(0, 0, index * math.pi / 4),
			color,
			Kit.Neon()
		)
	end
end

function Premium.Flames(model: Model, side: number, x: number, bottom: number, front: number, back: number)
	local layers = {
		{ Height = 1.0, Color = Color3.fromRGB(255, 90, 20), Offset = 0 },
		{ Height = 0.62, Color = Color3.fromRGB(255, 190, 40), Offset = 0.02 },
	}
	for _, layer in layers do
		for index, share in { 1, 0.7 } do
			local length = (back - front) * share
			local height = layer.Height * (if index == 1 then 1 else 0.7)
			Kit.Wedge(
				model,
				Vector3.new(0.04, height, length),
				CFrame.new(
					side * (x + layer.Offset),
					bottom + height / 2 + (index - 1) * 0.35,
					front + length / 2
				) * CFrame.Angles(0, math.pi, 0),
				layer.Color,
				Kit.Neon()
			)
		end
	end
end

return Premium
