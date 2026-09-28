--!strict

local Parts = require(script.Parent.Parent.Parts)

export type Options = Parts.Options

export type Frame = {
	Length: number,
	Width: number,
	WheelRadius: number,
	WheelWidth: number,
	FrontAxle: number,
	RearAxle: number,
	Ground: number,
	ArchTop: number,
	ArchGap: number,
}

local Kit = {}

Kit.Trim = Color3.fromRGB(28, 29, 34)
Kit.Tire = Color3.fromRGB(24, 24, 27)
Kit.Chrome = Color3.fromRGB(214, 218, 226)
Kit.Glass = Color3.fromRGB(150, 205, 255)
Kit.Interior = Color3.fromRGB(38, 38, 44)
Kit.HeadLight = Color3.fromRGB(255, 250, 225)
Kit.TailLight = Color3.fromRGB(255, 38, 56)
Kit.Amber = Color3.fromRGB(255, 170, 40)

function Kit.Paint(reflectance: number?): Options
	return { Material = Enum.Material.SmoothPlastic, Reflectance = reflectance or 0.08 }
end

function Kit.Metal(reflectance: number?): Options
	return { Material = Enum.Material.Metal, Reflectance = reflectance or 0.18 }
end

function Kit.Matte(): Options
	return { Material = Enum.Material.SmoothPlastic }
end

function Kit.Neon(): Options
	return { Material = Enum.Material.Neon }
end

function Kit.GlassStyle(transparency: number?): Options
	return { Material = Enum.Material.Glass, Transparency = transparency or 0.45 }
end

function Kit.Box(model: Model, size: Vector3, cframe: CFrame, color: Color3, options: Options?): BasePart
	return Parts.Make(model, size, cframe, color, options or Kit.Paint())
end

function Kit.Span(
	model: Model,
	x0: number,
	x1: number,
	y0: number,
	y1: number,
	z0: number,
	z1: number,
	color: Color3,
	options: Options?
): BasePart
	local size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0))
	local center = Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	function Kit.DriftSmoke(body: BasePart, model: Model)
		local rear = -math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				rear = math.max(rear, descendant.CFrame.Position.Z)
			end
		end
		for _, descendant in model:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant.Name == "Tire"
				and descendant.CFrame.Position.Z > rear - 0.5
			then
				local position = descendant.CFrame.Position
				local attachment = Instance.new("Attachment")
				attachment.Name = "SmokeAttachment"
				attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
				attachment.Parent = body
				local smoke = Instance.new("ParticleEmitter")
				smoke.Name = "DriftSmoke"
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
				smoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.6),
					NumberSequenceKeypoint.new(1, 7),
				})
				smoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				})
				smoke.Lifetime = NumberRange.new(0.9, 1.5)
				smoke.Rate = 36
				smoke.Speed = NumberRange.new(2, 5)
				smoke.SpreadAngle = Vector2.new(35, 35)
				smoke.Acceleration = Vector3.new(0, 3, 0)
				smoke.EmissionDirection = Enum.NormalId.Back
				smoke.Enabled = false
				smoke.Parent = attachment
			end
		end
	end

	return Kit.Box(model, size, CFrame.new(center), color, options)
end

function Kit.Wedge(model: Model, size: Vector3, cframe: CFrame, color: Color3, options: Options?): BasePart
	local settings: Options = table.clone(options or Kit.Paint())
	settings.Class = "WedgePart"
	return Parts.Make(model, size, cframe, color, settings)
end

function Kit.Ramp(
	model: Model,
	x0: number,
	x1: number,
	yLow: number,
	yHigh: number,
	zLow: number,
	zHigh: number,
	color: Color3,
	options: Options?
): BasePart
	local width = math.abs(x1 - x0)
	local height = math.abs(yHigh - yLow)
	local depth = math.abs(zHigh - zLow)
	local center = Vector3.new((x0 + x1) / 2, (yLow + yHigh) / 2, (zLow + zHigh) / 2)
	local turn = if zHigh > zLow then CFrame.identity else CFrame.Angles(0, math.pi, 0)
	function Kit.DriftSmoke(body: BasePart, model: Model)
		local rear = -math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				rear = math.max(rear, descendant.CFrame.Position.Z)
			end
		end
		for _, descendant in model:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant.Name == "Tire"
				and descendant.CFrame.Position.Z > rear - 0.5
			then
				local position = descendant.CFrame.Position
				local attachment = Instance.new("Attachment")
				attachment.Name = "SmokeAttachment"
				attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
				attachment.Parent = body
				local smoke = Instance.new("ParticleEmitter")
				smoke.Name = "DriftSmoke"
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
				smoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.6),
					NumberSequenceKeypoint.new(1, 7),
				})
				smoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				})
				smoke.Lifetime = NumberRange.new(0.9, 1.5)
				smoke.Rate = 36
				smoke.Speed = NumberRange.new(2, 5)
				smoke.SpreadAngle = Vector2.new(35, 35)
				smoke.Acceleration = Vector3.new(0, 3, 0)
				smoke.EmissionDirection = Enum.NormalId.Back
				smoke.Enabled = false
				smoke.Parent = attachment
			end
		end
	end

	return Kit.Wedge(model, Vector3.new(width, height, depth), CFrame.new(center) * turn, color, options)
end

function Kit.Cylinder(
	model: Model,
	length: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	options: Options?
): BasePart
	local settings: Options = table.clone(options or Kit.Paint())
	settings.Shape = Enum.PartType.Cylinder
	return Parts.Make(model, Vector3.new(length, diameter, diameter), cframe, color, settings)
end

function Kit.CylinderX(
	model: Model,
	length: number,
	diameter: number,
	center: Vector3,
	color: Color3,
	options: Options?
): BasePart
	function Kit.DriftSmoke(body: BasePart, model: Model)
		local rear = -math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				rear = math.max(rear, descendant.CFrame.Position.Z)
			end
		end
		for _, descendant in model:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant.Name == "Tire"
				and descendant.CFrame.Position.Z > rear - 0.5
			then
				local position = descendant.CFrame.Position
				local attachment = Instance.new("Attachment")
				attachment.Name = "SmokeAttachment"
				attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
				attachment.Parent = body
				local smoke = Instance.new("ParticleEmitter")
				smoke.Name = "DriftSmoke"
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
				smoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.6),
					NumberSequenceKeypoint.new(1, 7),
				})
				smoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				})
				smoke.Lifetime = NumberRange.new(0.9, 1.5)
				smoke.Rate = 36
				smoke.Speed = NumberRange.new(2, 5)
				smoke.SpreadAngle = Vector2.new(35, 35)
				smoke.Acceleration = Vector3.new(0, 3, 0)
				smoke.EmissionDirection = Enum.NormalId.Back
				smoke.Enabled = false
				smoke.Parent = attachment
			end
		end
	end

	return Kit.Cylinder(model, length, diameter, CFrame.new(center), color, options)
end

function Kit.CylinderY(
	model: Model,
	length: number,
	diameter: number,
	center: Vector3,
	color: Color3,
	options: Options?
): BasePart
	function Kit.DriftSmoke(body: BasePart, model: Model)
		local rear = -math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				rear = math.max(rear, descendant.CFrame.Position.Z)
			end
		end
		for _, descendant in model:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant.Name == "Tire"
				and descendant.CFrame.Position.Z > rear - 0.5
			then
				local position = descendant.CFrame.Position
				local attachment = Instance.new("Attachment")
				attachment.Name = "SmokeAttachment"
				attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
				attachment.Parent = body
				local smoke = Instance.new("ParticleEmitter")
				smoke.Name = "DriftSmoke"
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
				smoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.6),
					NumberSequenceKeypoint.new(1, 7),
				})
				smoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				})
				smoke.Lifetime = NumberRange.new(0.9, 1.5)
				smoke.Rate = 36
				smoke.Speed = NumberRange.new(2, 5)
				smoke.SpreadAngle = Vector2.new(35, 35)
				smoke.Acceleration = Vector3.new(0, 3, 0)
				smoke.EmissionDirection = Enum.NormalId.Back
				smoke.Enabled = false
				smoke.Parent = attachment
			end
		end
	end

	return Kit.Cylinder(
		model,
		length,
		diameter,
		CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		options
	)
end

function Kit.CylinderZ(
	model: Model,
	length: number,
	diameter: number,
	center: Vector3,
	color: Color3,
	options: Options?
): BasePart
	function Kit.DriftSmoke(body: BasePart, model: Model)
		local rear = -math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				rear = math.max(rear, descendant.CFrame.Position.Z)
			end
		end
		for _, descendant in model:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant.Name == "Tire"
				and descendant.CFrame.Position.Z > rear - 0.5
			then
				local position = descendant.CFrame.Position
				local attachment = Instance.new("Attachment")
				attachment.Name = "SmokeAttachment"
				attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
				attachment.Parent = body
				local smoke = Instance.new("ParticleEmitter")
				smoke.Name = "DriftSmoke"
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
				smoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.6),
					NumberSequenceKeypoint.new(1, 7),
				})
				smoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				})
				smoke.Lifetime = NumberRange.new(0.9, 1.5)
				smoke.Rate = 36
				smoke.Speed = NumberRange.new(2, 5)
				smoke.SpreadAngle = Vector2.new(35, 35)
				smoke.Acceleration = Vector3.new(0, 3, 0)
				smoke.EmissionDirection = Enum.NormalId.Back
				smoke.Enabled = false
				smoke.Parent = attachment
			end
		end
	end

	return Kit.Cylinder(
		model,
		length,
		diameter,
		CFrame.new(center) * CFrame.Angles(0, math.rad(90), 0),
		color,
		options
	)
end

function Kit.Tube(
	model: Model,
	from: Vector3,
	to: Vector3,
	diameter: number,
	color: Color3,
	options: Options?
): BasePart
	local delta = to - from
	local length = delta.Magnitude
	local frame = CFrame.lookAt((from + to) / 2, to) * CFrame.Angles(0, math.rad(90), 0)
	function Kit.DriftSmoke(body: BasePart, model: Model)
		local rear = -math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				rear = math.max(rear, descendant.CFrame.Position.Z)
			end
		end
		for _, descendant in model:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant.Name == "Tire"
				and descendant.CFrame.Position.Z > rear - 0.5
			then
				local position = descendant.CFrame.Position
				local attachment = Instance.new("Attachment")
				attachment.Name = "SmokeAttachment"
				attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
				attachment.Parent = body
				local smoke = Instance.new("ParticleEmitter")
				smoke.Name = "DriftSmoke"
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
				smoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.6),
					NumberSequenceKeypoint.new(1, 7),
				})
				smoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				})
				smoke.Lifetime = NumberRange.new(0.9, 1.5)
				smoke.Rate = 36
				smoke.Speed = NumberRange.new(2, 5)
				smoke.SpreadAngle = Vector2.new(35, 35)
				smoke.Acceleration = Vector3.new(0, 3, 0)
				smoke.EmissionDirection = Enum.NormalId.Back
				smoke.Enabled = false
				smoke.Parent = attachment
			end
		end
	end

	return Kit.Cylinder(model, length + diameter * 0.5, diameter, frame, color, options)
end

function Kit.Ball(model: Model, diameter: number, center: Vector3, color: Color3, options: Options?): BasePart
	local settings: Options = table.clone(options or Kit.Paint())
	settings.Shape = Enum.PartType.Ball
	return Parts.Make(model, Vector3.one * diameter, CFrame.new(center), color, settings)
end

function Kit.Ellipsoid(
	model: Model,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	options: Options?
): BasePart
	local part = Kit.Box(model, size, cframe, color, options)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

export type WheelStyle = {
	Premium: boolean?,
	Caliper: Color3?,
}

function Kit.Wheel(
	model: Model,
	center: Vector3,
	radius: number,
	width: number,
	side: number,
	rimColor: Color3,
	spokes: number?,
	style: WheelStyle?
)
	local premium = style ~= nil and style.Premium == true
	local rimFinish = if premium then Kit.Paint(0.55) else Kit.Metal(0.22)
	Kit.CylinderX(
		model,
		width,
		radius * 2,
		center,
		Kit.Tire,
		{ Material = Enum.Material.Rubber, Name = "Tire" }
	)
	local face = center.X + side * (width / 2)
	local function disc(offset: number, thickness: number, diameter: number, color: Color3, options: Options)
		Kit.CylinderX(
			model,
			thickness,
			diameter,
			Vector3.new(face + side * offset, center.Y, center.Z),
			color,
			options
		)
	end
	disc(0, 0.1, radius * 1.86, Color3.fromRGB(46, 46, 52), Kit.Matte())
	disc(0.02, 0.12, radius * 1.46, rimColor, rimFinish)
	disc(0.04, 0.14, radius * 1.32, Kit.Trim, Kit.Matte())
	disc(0.06, 0.1, radius * 1.02, Color3.fromRGB(150, 152, 160), Kit.Metal(0.25))
	local caliper = if style and style.Caliper then style.Caliper else Color3.fromRGB(220, 40, 40)
	Kit.Box(
		model,
		Vector3.new(0.24, radius * 0.26, radius * 0.4),
		CFrame.new(face + side * 0.07, center.Y + radius * 0.34, center.Z + radius * 0.18)
			* CFrame.Angles(math.rad(-25), 0, 0),
		caliper,
		if premium then Kit.Neon() else Kit.Paint(0.15)
	)
	local count = spokes or 5
	local spokeLength = radius * 0.62
	for index = 1, count do
		local angle = (index - 1) * (2 * math.pi / count)
		local spoke = CFrame.new(face + side * 0.16, center.Y, center.Z) * CFrame.Angles(angle, 0, 0)
		if premium then
			for _, split in { -0.07, 0.07 } do
				Kit.Box(
					model,
					Vector3.new(0.12, radius * 0.1, spokeLength),
					spoke * CFrame.Angles(split, 0, 0) * CFrame.new(0, 0, spokeLength / 2),
					rimColor,
					rimFinish
				)
			end
		else
			Kit.Box(
				model,
				Vector3.new(0.12, radius * 0.2, spokeLength),
				spoke * CFrame.new(0, 0, spokeLength / 2),
				rimColor,
				rimFinish
			)
		end
	end
	disc(0.18, 0.3, radius * 0.34, rimColor, if premium then Kit.Paint(0.6) else Kit.Metal(0.3))
	disc(
		0.3,
		0.06,
		radius * 0.16,
		if premium then Color3.fromRGB(255, 214, 80) else Kit.Trim,
		if premium then Kit.Neon() else Kit.Matte()
	)
end

function Kit.Wheels(
	model: Model,
	frame: Frame,
	rimColor: Color3,
	inset: number?,
	spokes: number?,
	style: WheelStyle?
)
	local x = frame.Width / 2 - frame.WheelWidth / 2 + (inset or 0.15)
	for _, side in { -1, 1 } do
		for _, z in { frame.FrontAxle, frame.RearAxle } do
			Kit.Wheel(
				model,
				Vector3.new(side * x, frame.WheelRadius, z),
				frame.WheelRadius,
				frame.WheelWidth,
				side,
				rimColor,
				spokes,
				style
			)
		end
	end
end

function Kit.LowerBody(model: Model, frame: Frame, color: Color3, options: Options?, floor: number?): BasePart
	local halfLength = frame.Length / 2
	local halfWidth = frame.Width / 2
	local gap = frame.ArchGap
	local frontCut = frame.FrontAxle - gap
	local rearCut = frame.RearAxle + gap
	Kit.Span(model, -halfWidth, halfWidth, frame.Ground, frame.ArchTop, -halfLength, frontCut, color, options)
	Kit.Span(model, -halfWidth, halfWidth, frame.Ground, frame.ArchTop, rearCut, halfLength, color, options)
	for _, side in { -1, 1 } do
		Kit.Span(
			model,
			side * (halfWidth - 0.9),
			side * halfWidth,
			frame.Ground,
			frame.ArchTop,
			frame.FrontAxle + gap - 0.01,
			frame.RearAxle - gap + 0.01,
			color,
			options
		)
	end
	local inner = halfWidth - frame.WheelWidth - 0.2
	local body = Kit.Span(
		model,
		-inner,
		inner,
		frame.Ground + 0.1,
		floor or frame.ArchTop,
		frontCut,
		rearCut,
		Kit.Trim,
		Kit.Matte()
	)
	body.Name = "Body"
	local axles: { number } = if gap > 0 then { frame.FrontAxle, frame.RearAxle } else {}
	for _, z in axles do
		for _, side in { -1, 1 } do
			Kit.Span(
				model,
				side * (halfWidth - 0.02),
				side * (halfWidth + 0.06),
				frame.ArchTop - 0.08,
				frame.ArchTop + 0.14,
				z - gap - 0.1,
				z + gap + 0.1,
				Kit.Trim,
				Kit.Matte()
			)
			Kit.Span(
				model,
				side * inner,
				side * (inner + 0.2),
				frame.Ground,
				frame.ArchTop,
				z - gap,
				z + gap,
				Kit.Trim,
				Kit.Matte()
			)
			Kit.Span(
				model,
				side * inner,
				side * halfWidth,
				frame.ArchTop - 0.12,
				frame.ArchTop,
				z - gap,
				z + gap,
				Kit.Trim,
				Kit.Matte()
			)
		end
	end
	return body
end

function Kit.HeadLights(model: Model, frontZ: number, y: number, spread: number, size: Vector3)
	for _, side in { -1, 1 } do
		Kit.Box(
			model,
			size + Vector3.new(0.24, 0.24, 0),
			CFrame.new(side * spread, y, frontZ + 0.02),
			Kit.Trim,
			Kit.Matte()
		)
		Kit.Box(model, size, CFrame.new(side * spread, y, frontZ - 0.06), Kit.HeadLight, Kit.Neon())
	end
end

function Kit.TailLights(model: Model, rearZ: number, y: number, spread: number, size: Vector3)
	for _, side in { -1, 1 } do
		Kit.Box(
			model,
			size + Vector3.new(0.2, 0.2, 0),
			CFrame.new(side * spread, y, rearZ - 0.02),
			Kit.Trim,
			Kit.Matte()
		)
		Kit.Box(model, size, CFrame.new(side * spread, y, rearZ + 0.06), Kit.TailLight, Kit.Neon())
	end
end

function Kit.Strip(
	model: Model,
	from: Vector3,
	to: Vector3,
	width: number,
	color: Color3,
	options: Options?
): BasePart
	local length = (to - from).Magnitude
	function Kit.DriftSmoke(body: BasePart, model: Model)
		local rear = -math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				rear = math.max(rear, descendant.CFrame.Position.Z)
			end
		end
		for _, descendant in model:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant.Name == "Tire"
				and descendant.CFrame.Position.Z > rear - 0.5
			then
				local position = descendant.CFrame.Position
				local attachment = Instance.new("Attachment")
				attachment.Name = "SmokeAttachment"
				attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
				attachment.Parent = body
				local smoke = Instance.new("ParticleEmitter")
				smoke.Name = "DriftSmoke"
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
				smoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.6),
					NumberSequenceKeypoint.new(1, 7),
				})
				smoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				})
				smoke.Lifetime = NumberRange.new(0.9, 1.5)
				smoke.Rate = 36
				smoke.Speed = NumberRange.new(2, 5)
				smoke.SpreadAngle = Vector2.new(35, 35)
				smoke.Acceleration = Vector3.new(0, 3, 0)
				smoke.EmissionDirection = Enum.NormalId.Back
				smoke.Enabled = false
				smoke.Parent = attachment
			end
		end
	end

	return Kit.Box(
		model,
		Vector3.new(width, 0.06, length),
		CFrame.lookAt((from + to) / 2, to),
		color,
		options
	)
end

function Kit.Pane(
	model: Model,
	width: number,
	bottom: Vector3,
	top: Vector3,
	color: Color3,
	options: Options?
): BasePart
	local length = (top - bottom).Magnitude
	local frame = CFrame.lookAt((bottom + top) / 2, top) * CFrame.Angles(math.rad(-90), 0, 0)
	function Kit.DriftSmoke(body: BasePart, model: Model)
		local rear = -math.huge
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Name == "Tire" then
				rear = math.max(rear, descendant.CFrame.Position.Z)
			end
		end
		for _, descendant in model:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant.Name == "Tire"
				and descendant.CFrame.Position.Z > rear - 0.5
			then
				local position = descendant.CFrame.Position
				local attachment = Instance.new("Attachment")
				attachment.Name = "SmokeAttachment"
				attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
				attachment.Parent = body
				local smoke = Instance.new("ParticleEmitter")
				smoke.Name = "DriftSmoke"
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
				smoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.6),
					NumberSequenceKeypoint.new(1, 7),
				})
				smoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				})
				smoke.Lifetime = NumberRange.new(0.9, 1.5)
				smoke.Rate = 36
				smoke.Speed = NumberRange.new(2, 5)
				smoke.SpreadAngle = Vector2.new(35, 35)
				smoke.Acceleration = Vector3.new(0, 3, 0)
				smoke.EmissionDirection = Enum.NormalId.Back
				smoke.Enabled = false
				smoke.Parent = attachment
			end
		end
	end

	return Kit.Box(model, Vector3.new(width, length, 0.14), frame, color, options)
end

function Kit.Seat(model: Model, position: Vector3, color: Color3?): Seat
	local tone = color or Kit.Interior
	Kit.Box(
		model,
		Vector3.new(2.3, 0.5, 2.1),
		CFrame.new(position + Vector3.new(0, -0.25, 0.1)),
		tone,
		Kit.Matte()
	)
	Kit.Box(
		model,
		Vector3.new(2.3, 2.3, 0.5),
		CFrame.new(position + Vector3.new(0, 1, 1.25)) * CFrame.Angles(math.rad(12), 0, 0),
		tone,
		Kit.Matte()
	)
	Kit.Box(
		model,
		Vector3.new(1.3, 0.8, 0.45),
		CFrame.new(position + Vector3.new(0, 2.45, 1.5)) * CFrame.Angles(math.rad(12), 0, 0),
		tone,
		Kit.Matte()
	)
	local seat = Instance.new("Seat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 0.4, 2)
	seat.CFrame = CFrame.new(position - Vector3.new(0, 0.2, 0))
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.CanTouch = false
	seat.CanQuery = false
	seat.Parent = model
	return seat
end

function Kit.SteeringWheel(model: Model, position: Vector3)
	Kit.Cylinder(
		model,
		0.18,
		1.3,
		CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(-25)),
		Kit.Trim,
		Kit.Matte()
	)
end

function Kit.Windshield(
	model: Model,
	width: number,
	baseY: number,
	height: number,
	baseZ: number,
	lean: number
)
	local bottom = Vector3.new(0, baseY, baseZ)
	local top = Vector3.new(0, baseY + height, baseZ + lean)
	Kit.Pane(model, width, bottom, top, Kit.Glass, Kit.GlassStyle(0.4))
	Kit.Box(model, Vector3.new(width + 0.2, 0.2, 0.3), CFrame.new(top), Kit.Trim, Kit.Matte())
	for _, side in { -1, 1 } do
		local offset = Vector3.new(side * (width / 2 + 0.05), 0, 0)
		Kit.Tube(model, bottom + offset, top + offset, 0.2, Kit.Trim, Kit.Matte())
	end
end

local function glowColor(body: Color3, accent: Color3): Color3
	local hue, saturation, value = body:ToHSV()
	if saturation < 0.3 or value < 0.35 then
		local accentHue, accentSaturation, accentValue = accent:ToHSV()
		if accentSaturation >= 0.3 and accentValue > 0.5 then
			hue, saturation = accentHue, accentSaturation
		else
			hue, saturation = 0.54, 0.85
		end
	end
	if hue < 0.06 or hue > 0.94 then
		hue = 0.07
	end
	return Color3.fromHSV(hue, math.clamp(saturation, 0.7, 1), 1)
end

local function attach(body: BasePart, name: string, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position))
	attachment.Parent = body
	return attachment
end

local function trail(
	parent: Instance,
	name: string,
	from: Attachment,
	to: Attachment,
	glow: Color3,
	lifetime: number
)
	local effect = Instance.new("Trail")
	effect.Name = name
	effect.Attachment0 = from
	effect.Attachment1 = to
	effect.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.15, glow),
		ColorSequenceKeypoint.new(1, glow),
	})
	effect.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	effect.WidthScale =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.3) })
	effect.Lifetime = lifetime
	effect.LightEmission = 1
	effect.LightInfluence = 0
	effect.FaceCamera = true
	effect.Enabled = false
	effect.Parent = parent
	return effect
end

function Kit.Effects(
	body: BasePart,
	exhaust: Vector3,
	trailTop: Vector3,
	trailBottom: Vector3,
	color: Color3,
	accent: Color3
)
	local glow = glowColor(color, accent)
	local attachment = attach(body, "Exhaust", exhaust)
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "BoostFire"
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.EmissionDirection = Enum.NormalId.Back
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 220)),
		ColorSequenceKeypoint.new(0.35, glow),
		ColorSequenceKeypoint.new(1, glow:Lerp(Color3.new(0, 0, 0), 0.35)),
	})
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3.2), NumberSequenceKeypoint.new(1, 0.4) })
	fire.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	fire.Lifetime = NumberRange.new(0.2, 0.36)
	fire.Rate = 220
	fire.Speed = NumberRange.new(30, 44)
	fire.SpreadAngle = Vector2.new(8, 8)
	fire.LightEmission = 1
	fire.LightInfluence = 0
	fire.Enabled = false
	fire.Parent = attachment
	local core = Instance.new("ParticleEmitter")
	core.Name = "BoostFire"
	core.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	core.EmissionDirection = Enum.NormalId.Back
	core.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), glow)
	core.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	core.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.6) })
	core.Lifetime = NumberRange.new(0.25, 0.5)
	core.Rate = 90
	core.Speed = NumberRange.new(10, 22)
	core.SpreadAngle = Vector2.new(25, 25)
	core.LightEmission = 1
	core.LightInfluence = 0
	core.Enabled = false
	core.Parent = attachment
	local light = Instance.new("PointLight")
	light.Name = "BoostGlow"
	light.Color = glow
	light.Brightness = 4
	light.Range = 18
	light.Enabled = false
	light.Parent = attachment
	local upper = attach(body, "TrailTop", trailTop)
	local lower = attach(body, "TrailBottom", trailBottom)
	trail(body, "SpeedTrail", upper, lower, glow, 0.45)
	local boostTop = attach(body, "BoostTop", exhaust + Vector3.new(0, 0.9, 0.4))
	local boostBottom = attach(body, "BoostBottom", exhaust + Vector3.new(0, -0.9, 0.4))
	trail(body, "BoostTrail", boostTop, boostBottom, glow, 0.7)
end

function Kit.DriftSmoke(body: BasePart, model: Model)
	local rear = -math.huge
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name == "Tire" then
			rear = math.max(rear, descendant.CFrame.Position.Z)
		end
	end
	for _, descendant in model:GetDescendants() do
		if
			descendant:IsA("BasePart")
			and descendant.Name == "Tire"
			and descendant.CFrame.Position.Z > rear - 0.5
		then
			local position = descendant.CFrame.Position
			local attachment = Instance.new("Attachment")
			attachment.Name = "SmokeAttachment"
			attachment.CFrame = body.CFrame:ToObjectSpace(CFrame.new(position.X, 0.4, position.Z + 0.4))
			attachment.Parent = body
			local smoke = Instance.new("ParticleEmitter")
			smoke.Name = "DriftSmoke"
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 190, 200))
			smoke.Size =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 7) })
			smoke.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
			smoke.Lifetime = NumberRange.new(0.9, 1.5)
			smoke.Rate = 36
			smoke.Speed = NumberRange.new(2, 5)
			smoke.SpreadAngle = Vector2.new(35, 35)
			smoke.Acceleration = Vector3.new(0, 3, 0)
			smoke.EmissionDirection = Enum.NormalId.Back
			smoke.Enabled = false
			smoke.Parent = attachment
		end
	end
end

return Kit
