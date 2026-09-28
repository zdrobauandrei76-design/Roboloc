--!strict

local Parts = require(script.Parent.Parent.Parts)
local Style = require(script.Parent.Style)

export type Island = {
	Model: Model,
	CFrame: CFrame,
	Radius: number,
	Bottom: number,
}

local white = Color3.fromRGB(255, 255, 255)

local Voxel = {}

function Voxel.Model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Voxel.Box(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): BasePart
	return Parts.Make(parent, size, cframe, color, { Material = material, Transparency = transparency })
end

function Voxel.Neon(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	transparency: number?
): BasePart
	return Parts.Make(
		parent,
		size,
		cframe,
		color,
		{ Material = Enum.Material.Neon, Transparency = transparency }
	)
end

function Voxel.Wedge(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): BasePart
	return Parts.Make(parent, size, cframe, color, { Class = "WedgePart", Material = material })
end

function Voxel.Cylinder(
	parent: Instance,
	diameter: number,
	height: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): BasePart
	return Parts.Make(
		parent,
		Vector3.new(height, diameter, diameter),
		cframe * CFrame.Angles(0, 0, math.rad(90)),
		color,
		{ Shape = Enum.PartType.Cylinder, Material = material, Transparency = transparency }
	)
end

function Voxel.Ball(
	parent: Instance,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): BasePart
	return Parts.Ball(parent, size, position, color, material)
end

function Voxel.Pick<T>(rng: Random, list: { T }): T
	return list[rng:NextInteger(1, #list)]
end

function Voxel.Round(
	parent: Instance,
	cframe: CFrame,
	radius: number,
	height: number,
	color: Color3,
	material: Enum.Material,
	fill: boolean?
)
	Voxel.Box(parent, Vector3.new(radius * 2, height, radius * 1.2), cframe, color, material)
	Voxel.Box(parent, Vector3.new(radius * 1.2, height - 0.04, radius * 2), cframe, color, material)
	if fill then
		Voxel.Box(parent, Vector3.new(radius * 1.56, height - 0.08, radius * 1.56), cframe, color, material)
	end
end

function Voxel.Island(
	parent: Instance,
	top: Vector3,
	radius: number,
	palette: Style.Palette,
	rng: Random,
	depth: number?,
	flat: boolean?
): Island
	local model = Voxel.Model(parent, "Island")
	local base = CFrame.new(top) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local scale = depth or 1
	local cap = math.max(2, radius * 0.07)
	Voxel.Round(model, base * CFrame.new(0, -cap / 2, 0), radius, cap, palette.Top, palette.TopMaterial, true)
	local soil = radius * 0.2
	Voxel.Round(
		model,
		base * CFrame.new(0, -cap - soil / 2, 0),
		radius * 0.96,
		soil,
		palette.Soil,
		palette.SoilMaterial,
		true
	)
	local y = -cap - soil
	local layer = radius * 0.96
	for index = 1, 4 do
		layer *= 0.72
		local height = radius * rng:NextNumber(0.18, 0.28) * scale
		local shiftX = rng:NextNumber(-0.07, 0.07) * radius
		local shiftZ = rng:NextNumber(-0.07, 0.07) * radius
		local odd = index % 2 == 1
		Voxel.Round(
			model,
			base * CFrame.new(shiftX, y - height / 2, shiftZ),
			layer,
			height,
			if odd then palette.Rock else palette.Deep,
			if odd then palette.RockMaterial else palette.DeepMaterial
		)
		y -= height
	end
	local tip = layer * 0.6
	Voxel.Box(
		model,
		Vector3.new(tip, tip * 1.4 * scale, tip),
		base * CFrame.new(0, y - tip * 0.7 * scale, 0),
		palette.Deep,
		palette.DeepMaterial
	)
	y -= tip * 1.4 * scale
	for _ = 1, math.clamp(math.floor(radius / 12), 3, 9) do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = radius * rng:NextNumber(0.7, 0.9)
		local size = radius * rng:NextNumber(0.1, 0.2)
		local drop = size * rng:NextNumber(1, 2.4)
		Voxel.Box(
			model,
			Vector3.new(size, drop, size),
			base
				* CFrame.new(
					math.cos(angle) * distance,
					-cap - soil * 0.5 - drop / 2,
					math.sin(angle) * distance
				),
			palette.Soil,
			palette.SoilMaterial
		)
	end
	for _ = 1, if flat then 0 else math.clamp(math.floor(radius / 25), 1, 4) do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = radius * rng:NextNumber(0.2, 0.6)
		local width = radius * rng:NextNumber(0.14, 0.26)
		local height = rng:NextNumber(1.2, 2.4)
		Voxel.Box(
			model,
			Vector3.new(width, height, width * rng:NextNumber(0.8, 1.4)),
			base * CFrame.new(math.cos(angle) * distance, height / 2 - 0.6, math.sin(angle) * distance),
			palette.Top,
			palette.TopMaterial
		)
	end
	return { Model = model, CFrame = base, Radius = radius, Bottom = top.Y + y }
end

function Voxel.Spot(island: Island, rng: Random, inner: number?, outer: number?): Vector3
	local angle = rng:NextNumber(0, math.pi * 2)
	local distance = island.Radius * rng:NextNumber(inner or 0, outer or 0.72)
	return (island.CFrame * CFrame.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)).Position
end

function Voxel.Fall(
	parent: Instance,
	edge: CFrame,
	width: number,
	length: number,
	river: number,
	color: Color3,
	material: Enum.Material
)
	local glowing = material == Enum.Material.Neon
	if river > 0 then
		Voxel.Box(
			parent,
			Vector3.new(width * 0.8, 0.4, river),
			edge * CFrame.new(0, 0.12, river / 2),
			color,
			material
		)
	end
	local segments = 3
	local step = length / segments
	for index = 1, segments do
		local center = -(index - 0.5) * step
		local fade = (index - 1) * 0.24
		Voxel.Box(
			parent,
			Vector3.new(width, step + 0.3, 1.6),
			edge * CFrame.new(0, center, -0.9),
			color,
			material,
			0.05 + fade
		)
		if not glowing then
			for _, offset in { -0.28, 0.22 } do
				Voxel.Neon(
					parent,
					Vector3.new(width * 0.1, step, 0.3),
					edge * CFrame.new(offset * width, center, -1.9),
					white,
					0.4 + fade
				)
			end
		end
	end
	local foam = if glowing then color else white
	Voxel.Ball(parent, Vector3.new(width * 1.1, 3, 5), (edge * CFrame.new(0, 0.6, 0.5)).Position, foam)
	local bottom = edge * CFrame.new(0, -length, -2)
	for index = 1, 3 do
		Voxel.Ball(
			parent,
			Vector3.new(width * 0.7, width * 0.45, width * 0.6),
			(bottom * CFrame.new((index - 2) * width * 0.35, (index % 2) * width * 0.12, 0)).Position,
			foam,
			if glowing then Enum.Material.Neon else Enum.Material.SmoothPlastic
		)
	end
end

function Voxel.Waterfall(
	parent: Instance,
	island: Island,
	quarter: number,
	width: number,
	length: number,
	color: Color3,
	material: Enum.Material
)
	local frame = island.CFrame * CFrame.Angles(0, quarter * math.pi / 2, 0)
	Voxel.Fall(
		parent,
		frame * CFrame.new(0, 0, -island.Radius),
		width,
		length,
		island.Radius * 0.7,
		color,
		material
	)
end

function Voxel.Cloud(parent: Instance, center: Vector3, size: number, rng: Random, color: Color3?)
	local tint = color or white
	Voxel.Ball(
		parent,
		Vector3.new(size * 2.4, size * 0.55, size * 1.5),
		center + Vector3.new(0, -size * 0.1, 0),
		tint,
		Enum.Material.SmoothPlastic
	)
	for _ = 1, rng:NextInteger(3, 5) do
		local puff = size * rng:NextNumber(0.6, 1)
		Voxel.Ball(
			parent,
			Vector3.one * puff,
			center
				+ Vector3.new(
					rng:NextNumber(-0.8, 0.8) * size,
					rng:NextNumber(0.05, 0.3) * size,
					rng:NextNumber(-0.35, 0.35) * size
				),
			tint,
			Enum.Material.SmoothPlastic
		)
	end
end

function Voxel.Ring(
	parent: Instance,
	center: CFrame,
	radius: number,
	thickness: number,
	depth: number,
	segments: number,
	color: Color3,
	material: Enum.Material,
	from: number?,
	to: number?
)
	local first = from or 0
	local last = to or math.pi * 2
	local step = (last - first) / segments
	local chord = 2 * radius * math.sin(step / 2) + thickness * 0.6
	for index = 0, segments - 1 do
		local angle = first + (index + 0.5) * step
		Voxel.Box(
			parent,
			Vector3.new(chord, thickness, depth),
			center * CFrame.Angles(0, 0, angle) * CFrame.new(0, radius, 0),
			color,
			material
		)
	end
end

return Voxel
