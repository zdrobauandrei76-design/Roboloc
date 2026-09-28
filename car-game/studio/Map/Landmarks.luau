--!strict

local Parts = require(script.Parent.Parent.Parts)
local Voxel = require(script.Parent.Voxel)

local Landmarks = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local stone = rgb(238, 236, 230)
local stoneDark = rgb(196, 192, 186)
local roof = rgb(62, 112, 225)

local function spire(parent: Instance, base: CFrame, width: number, height: number, color: Color3)
	local layers = 4
	for index = 0, layers - 1 do
		local scale = 1 - index / layers
		Voxel.Box(
			parent,
			Vector3.new(width * scale, height / layers + 0.2, width * scale),
			base * CFrame.new(0, (index + 0.5) * height / layers, 0),
			color
		)
	end
end

local function battlements(parent: Instance, from: CFrame, to: CFrame, size: number, color: Color3)
	local length = (to.Position - from.Position).Magnitude
	local count = math.max(2, math.floor(length / (size * 2)))
	for index = 0, count do
		Voxel.Box(
			parent,
			Vector3.one * size,
			from:Lerp(to, index / count) * CFrame.new(0, size / 2, 0),
			color
		)
	end
end

function Landmarks.Castle(parent: Instance, at: Vector3, facing: number)
	local model = Voxel.Model(parent, "Castle")
	local base = CFrame.new(at) * CFrame.Angles(0, facing, 0)
	local half = 22
	local wall = 13
	for _, side in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		local sx, sz = side[1], side[2]
		local size = if sx ~= 0 then Vector3.new(3, wall, half * 2) else Vector3.new(half * 2, wall, 3)
		local center = base * CFrame.new(sx * half, wall / 2, sz * half)
		Voxel.Box(model, size, center, stone)
		local along = if sx == 0 then Vector3.new(half - 3, 0, 0) else Vector3.new(0, 0, half - 3)
		local middle = Vector3.new(sx * half, wall, sz * half)
		battlements(
			model,
			base * CFrame.new(middle - along),
			base * CFrame.new(middle + along),
			2.2,
			stoneDark
		)
	end
	Voxel.Box(
		model,
		Vector3.new(0.6, 8, 7),
		base * CFrame.new(-half - 1.6, 4, 0),
		rgb(90, 60, 40),
		Enum.Material.Wood
	)
	for _, corner in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		local tower = base * CFrame.new(corner[1] * half, 0, corner[2] * half)
		Voxel.Box(model, Vector3.new(9, 30, 9), tower * CFrame.new(0, 15, 0), stone)
		Voxel.Box(model, Vector3.new(10.4, 2, 10.4), tower * CFrame.new(0, 30, 0), stoneDark)
		spire(model, tower * CFrame.new(0, 31, 0), 11, 14, roof)
		Voxel.Box(
			model,
			Vector3.new(0.4, 6, 0.4),
			tower * CFrame.new(0, 47, 0),
			rgb(230, 230, 235),
			Enum.Material.Metal
		)
		Voxel.Box(model, Vector3.new(0.3, 2.4, 4), tower * CFrame.new(0, 48.6, 2), rgb(255, 80, 80))
		for _, y in { 12, 22 } do
			Voxel.Box(model, Vector3.new(9.2, 3, 1.4), tower * CFrame.new(0, y, 0), rgb(40, 50, 80))
		end
	end
	Voxel.Box(model, Vector3.new(18, 38, 18), base * CFrame.new(4, 19, 0), stone)
	Voxel.Box(model, Vector3.new(19.4, 2, 19.4), base * CFrame.new(4, 38, 0), stoneDark)
	spire(model, base * CFrame.new(4, 39, 0), 19, 22, roof)
	for _, y in { 14, 26 } do
		for _, z in { -5, 5 } do
			Voxel.Box(model, Vector3.new(18.4, 4, 2.4), base * CFrame.new(4, y, z), rgb(40, 50, 80))
		end
	end
	Voxel.Box(
		model,
		Vector3.new(0.5, 8, 0.5),
		base * CFrame.new(4, 65, 0),
		rgb(230, 230, 235),
		Enum.Material.Metal
	)
	Voxel.Box(model, Vector3.new(0.3, 3, 6), base * CFrame.new(4, 67.5, 3), rgb(255, 210, 60))
end

function Landmarks.Windmill(parent: Instance, at: Vector3, facing: number)
	local model = Voxel.Model(parent, "Windmill")
	local base = CFrame.new(at) * CFrame.Angles(0, facing, 0)
	local y = 0
	for index, width in { 16, 13, 10 } do
		local height = 12
		Voxel.Box(
			model,
			Vector3.new(width, height, width),
			base * CFrame.new(0, y + height / 2, 0),
			if index % 2 == 1 then rgb(245, 238, 225) else rgb(230, 222, 205)
		)
		y += height
	end
	spire(model, base * CFrame.new(0, y, 0), 12, 8, rgb(200, 70, 60))
	Voxel.Box(
		model,
		Vector3.new(4, 6, 0.4),
		base * CFrame.new(0, 3, -8.2),
		rgb(120, 80, 50),
		Enum.Material.Wood
	)
	local hub = base * CFrame.new(0, y - 3, -6.5)
	Voxel.Box(model, Vector3.new(2.4, 2.4, 3), hub, rgb(90, 70, 50), Enum.Material.Wood)
	for index = 0, 3 do
		local blade = hub * CFrame.Angles(0, 0, math.rad(20 + index * 90))
		Voxel.Box(
			model,
			Vector3.new(1, 22, 0.6),
			blade * CFrame.new(0, 11.5, -1),
			rgb(120, 85, 55),
			Enum.Material.Wood
		)
		Voxel.Box(model, Vector3.new(4.4, 16, 0.3), blade * CFrame.new(2.6, 13, -1.2), rgb(250, 248, 240))
	end
end

function Landmarks.Pyramid(parent: Instance, at: Vector3, base: number, height: number, facing: number)
	local model = Voxel.Model(parent, "Pyramid")
	local frame = CFrame.new(at) * CFrame.Angles(0, facing, 0)
	local layers = 9
	local step = height / layers
	for index = 0, layers - 1 do
		local width = base * (1 - index / layers)
		Voxel.Box(
			model,
			Vector3.new(width, step + 0.1, width),
			frame * CFrame.new(0, (index + 0.5) * step, 0),
			if index % 2 == 0 then rgb(232, 190, 110) else rgb(218, 172, 96),
			Enum.Material.Sandstone
		)
	end
	local cap = base / layers
	Parts.Make(
		model,
		Vector3.new(cap, step * 1.2, cap),
		frame * CFrame.new(0, height + step * 0.6, 0),
		rgb(255, 212, 70),
		{
			Material = Enum.Material.Foil,
		}
	)
	Voxel.Box(
		model,
		Vector3.new(0.6, step * 1.6, base * 0.08),
		frame * CFrame.new(-base / 2 - 0.1, step * 0.8, 0),
		rgb(40, 28, 20)
	)
end

function Landmarks.Obelisk(parent: Instance, at: Vector3, height: number)
	local model = Voxel.Model(parent, "Obelisk")
	Voxel.Box(
		model,
		Vector3.new(10, 4, 10),
		CFrame.new(at + Vector3.new(0, 2, 0)),
		rgb(210, 165, 95),
		Enum.Material.Sandstone
	)
	Voxel.Box(
		model,
		Vector3.new(5, height, 5),
		CFrame.new(at + Vector3.new(0, 4 + height / 2, 0)),
		rgb(226, 184, 108),
		Enum.Material.Sandstone
	)
	Parts.Make(
		model,
		Vector3.new(3.4, 4, 3.4),
		CFrame.new(at + Vector3.new(0, 6 + height, 0)),
		rgb(255, 212, 70),
		{
			Material = Enum.Material.Foil,
		}
	)
end

function Landmarks.Mountain(
	parent: Instance,
	at: Vector3,
	base: number,
	height: number,
	rng: Random,
	body: Color3,
	material: Enum.Material,
	snow: boolean
)
	local model = Voxel.Model(parent, "Mountain")
	local layers = 6
	local step = height / layers
	for index = 0, layers - 1 do
		local width = base * (1 - index / (layers + 0.6))
		local capped = snow and index >= layers - 2
		Voxel.Box(
			model,
			Vector3.new(width, step + 0.4, width * rng:NextNumber(0.8, 1.1)),
			CFrame.new(
				at
					+ Vector3.new(
						rng:NextNumber(-0.04, 0.04) * base,
						(index + 0.5) * step,
						rng:NextNumber(-0.04, 0.04) * base
					)
			) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			if capped then rgb(245, 250, 255) else body:Lerp(rgb(255, 255, 255), index * 0.04),
			if capped then Enum.Material.Snow else material
		)
	end
end

function Landmarks.Volcano(parent: Instance, at: Vector3, base: number, height: number, rng: Random)
	local model = Voxel.Model(parent, "Volcano")
	local layers = 7
	local step = height / layers
	local top = base * 0.3
	for index = 0, layers - 1 do
		local width = base - (base - top) * index / (layers - 1)
		Voxel.Box(
			model,
			Vector3.new(width, step + 0.3, width),
			CFrame.new(at + Vector3.new(0, (index + 0.5) * step, 0))
				* CFrame.Angles(0, math.rad(index * 13), 0),
			if index % 2 == 0 then rgb(58, 44, 42) else rgb(44, 34, 34),
			if index == layers - 1 then Enum.Material.CrackedLava else Enum.Material.Basalt
		)
	end
	local lava = rgb(255, 104, 28)
	Voxel.Cylinder(
		model,
		top * 1.02,
		1,
		CFrame.new(at + Vector3.new(0, height + 0.4, 0)),
		lava,
		Enum.Material.Neon
	)
	local run = (base - top) / 2
	local slope = math.sqrt(run * run + height * height)
	local tilt = math.atan2(height, run)
	for index = 0, 5 do
		local angle = index * math.pi / 3 + rng:NextNumber(-0.3, 0.3)
		local direction = CFrame.new(at) * CFrame.Angles(0, angle, 0)
		local middle = direction * CFrame.new(0, height / 2, -(top / 2 + run / 2) * 1.12)
		Voxel.Neon(
			model,
			Vector3.new(rng:NextNumber(base * 0.04, base * 0.07), 2.5, slope * 0.95),
			middle * CFrame.Angles(-tilt, 0, 0),
			if index % 2 == 0 then lava else rgb(255, 160, 40)
		)
	end
	for index = 1, 4 do
		local size = top * (0.35 + index * 0.18)
		Voxel.Ball(
			model,
			Vector3.new(size, size * 0.8, size),
			at
				+ Vector3.new(
					rng:NextNumber(-0.1, 0.1) * top,
					height + size * 0.3 + index * top * 0.35,
					rng:NextNumber(-0.1, 0.1) * top
				),
			rgb(80, 70, 74):Lerp(rgb(150, 140, 145), index / 4),
			Enum.Material.SmoothPlastic
		)
	end
end

function Landmarks.Cake(parent: Instance, at: Vector3, scale: number, rng: Random)
	local model = Voxel.Model(parent, "Cake")
	local tiers: { { Diameter: number, Height: number, Color: Color3 } } = {
		{ Diameter = 44, Height = 14, Color = rgb(255, 160, 205) },
		{ Diameter = 32, Height = 12, Color = rgb(255, 245, 250) },
		{ Diameter = 20, Height = 10, Color = rgb(120, 70, 50) },
	}
	local y = 0
	for index, tier in tiers do
		local diameter, height, color = tier.Diameter * scale, tier.Height * scale, tier.Color
		Voxel.Cylinder(
			model,
			diameter,
			height,
			CFrame.new(at + Vector3.new(0, y + height / 2, 0)),
			color,
			Enum.Material.SmoothPlastic
		)
		local drip = if index == 2 then rgb(255, 150, 200) else rgb(255, 250, 252)
		Voxel.Cylinder(
			model,
			diameter + 1,
			1.6 * scale,
			CFrame.new(at + Vector3.new(0, y + height - 0.6 * scale, 0)),
			drip,
			Enum.Material.SmoothPlastic
		)
		for step = 0, 7 do
			local angle = step * math.pi / 4 + index * 0.3
			local length = rng:NextNumber(2.5, 5) * scale
			Voxel.Box(
				model,
				Vector3.new(2.2 * scale, length, 1.2 * scale),
				CFrame.new(at + Vector3.new(0, y + height - length / 2, 0))
					* CFrame.Angles(0, angle, 0)
					* CFrame.new(0, 0, -diameter / 2 - 0.2),
				drip
			)
		end
		y += height
	end
	for index = 0, 2 do
		local angle = index * math.pi * 2 / 3
		local spot = CFrame.new(at + Vector3.new(0, y, 0))
			* CFrame.Angles(0, angle, 0)
			* CFrame.new(0, 0, -5 * scale)
		Voxel.Box(
			model,
			Vector3.new(1.4, 7, 1.4) * scale,
			spot * CFrame.new(0, 3.5 * scale, 0),
			Voxel.Pick(rng, { rgb(120, 200, 255), rgb(255, 230, 90), rgb(160, 120, 255) })
		)
		Voxel.Neon(
			model,
			Vector3.new(1, 1.8, 1) * scale,
			spot * CFrame.new(0, 7.9 * scale, 0),
			rgb(255, 190, 60)
		)
	end
	Voxel.Ball(
		model,
		Vector3.one * 5 * scale,
		at + Vector3.new(0, y + 2 * scale, 0),
		rgb(220, 30, 50),
		Enum.Material.SmoothPlastic
	)
end

function Landmarks.IceCream(parent: Instance, at: Vector3, scale: number)
	local model = Voxel.Model(parent, "IceCream")
	for index = 0, 4 do
		local width = (2 + index * 1.6) * scale
		Voxel.Box(
			model,
			Vector3.new(width, 4 * scale, width),
			CFrame.new(at + Vector3.new(0, (index + 0.5) * 4 * scale, 0))
				* CFrame.Angles(0, math.rad(45 * index), 0),
			if index % 2 == 0 then rgb(225, 170, 100) else rgb(205, 145, 80)
		)
	end
	local y = 20 * scale
	for index, color in { rgb(255, 200, 225), rgb(160, 230, 200), rgb(250, 240, 220) } do
		local size = (11 - index) * scale
		Voxel.Ball(
			model,
			Vector3.new(size, size * 0.85, size),
			at + Vector3.new(0, y + size * 0.35, 0),
			color,
			Enum.Material.SmoothPlastic
		)
		y += size * 0.62
	end
	Voxel.Ball(
		model,
		Vector3.one * 2.6 * scale,
		at + Vector3.new(0, y + 1.8 * scale, 0),
		rgb(220, 30, 50),
		Enum.Material.SmoothPlastic
	)
end

function Landmarks.MoonBase(parent: Instance, at: Vector3, facing: number)
	local model = Voxel.Model(parent, "MoonBase")
	local base = CFrame.new(at) * CFrame.Angles(0, facing, 0)
	local metal = rgb(210, 214, 222)
	local domes = { { 0, 0, 40 }, { 38, 14, 26 }, { -34, 18, 24 } }
	for _, dome in domes do
		local center = base * Vector3.new(dome[1], 0, dome[2])
		Voxel.Cylinder(
			model,
			dome[3] + 4,
			3,
			CFrame.new(center + Vector3.new(0, 1.5, 0)),
			metal,
			Enum.Material.Metal
		)
		local glass = Voxel.Ball(
			model,
			Vector3.one * dome[3],
			center + Vector3.new(0, 2, 0),
			rgb(150, 220, 255),
			Enum.Material.Glass
		)
		glass.Transparency = 0.35
		Voxel.Neon(
			model,
			Vector3.new(dome[3] * 0.5, 0.6, 0.6),
			CFrame.new(center + Vector3.new(0, 3.3, 0)),
			rgb(120, 230, 255)
		)
	end
	for index = 2, 3 do
		local target = base * Vector3.new(domes[index][1], 0, domes[index][2])
		local middle = (at + target) / 2 + Vector3.new(0, 4, 0)
		local length = (target - at).Magnitude
		Parts.Make(
			model,
			Vector3.new(length, 6, 6),
			CFrame.lookAt(middle, target + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.pi / 2, 0),
			metal,
			{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal }
		)
	end
	local pad = base * CFrame.new(0, 0.6, -52)
	Voxel.Cylinder(model, 34, 1.2, pad, rgb(70, 72, 84), Enum.Material.Metal)
	Voxel.Ring(
		model,
		pad * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.new(0, 0, -0.5),
		15,
		1,
		0.6,
		16,
		rgb(255, 220, 90),
		Enum.Material.Neon
	)
	Voxel.Neon(model, Vector3.new(2, 0.4, 12), pad * CFrame.new(-4, 0.7, 0), rgb(255, 255, 255))
	Voxel.Neon(model, Vector3.new(2, 0.4, 12), pad * CFrame.new(4, 0.7, 0), rgb(255, 255, 255))
	Voxel.Neon(model, Vector3.new(8, 0.4, 2), pad * CFrame.new(0, 0.7, 0), rgb(255, 255, 255))
	local tower = base * CFrame.new(20, 0, 44)
	Voxel.Box(model, Vector3.new(3, 46, 3), tower * CFrame.new(0, 23, 0), metal, Enum.Material.Metal)
	Voxel.Cylinder(
		model,
		14,
		1.2,
		tower * CFrame.new(0, 40, 0) * CFrame.Angles(0.7, 0, 0),
		rgb(240, 240, 245),
		Enum.Material.Metal
	)
	Voxel.Neon(model, Vector3.one * 2, tower * CFrame.new(0, 47, 0), rgb(255, 60, 60))
end

function Landmarks.Lander(parent: Instance, at: Vector3, facing: number)
	local model = Voxel.Model(parent, "Lander")
	local base = CFrame.new(at) * CFrame.Angles(0, facing, 0)
	Parts.Make(
		model,
		Vector3.new(12, 8, 12),
		base * CFrame.new(0, 9, 0),
		rgb(230, 190, 70),
		{ Material = Enum.Material.Foil }
	)
	Voxel.Box(
		model,
		Vector3.new(9, 7, 9),
		base * CFrame.new(0, 16.5, 0) * CFrame.Angles(0, math.rad(45), 0),
		rgb(220, 222, 228),
		Enum.Material.Metal
	)
	Voxel.Box(model, Vector3.new(3, 2.4, 0.4), base * CFrame.new(0, 17, -6.5), rgb(40, 60, 90))
	for _, corner in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		Voxel.Box(
			model,
			Vector3.new(0.8, 11, 0.8),
			base
				* CFrame.new(corner[1] * 7.5, 5, corner[2] * 7.5)
				* CFrame.Angles(corner[2] * 0.35, 0, -corner[1] * 0.35),
			rgb(200, 200, 205),
			Enum.Material.Metal
		)
		Voxel.Cylinder(
			model,
			3,
			0.6,
			base * CFrame.new(corner[1] * 9, 0.3, corner[2] * 9),
			rgb(200, 200, 205),
			Enum.Material.Metal
		)
	end
end

local function orient(normal: Vector3, point: Vector3): CFrame
	return CFrame.lookAt(point, point + normal) * CFrame.Angles(0, math.pi / 2, 0)
end

function Landmarks.Moon(parent: Instance, center: Vector3, diameter: number, rng: Random, facing: Vector3)
	local model = Voxel.Model(parent, "GiantMoon")
	Voxel.Ball(model, Vector3.one * diameter, center, rgb(214, 214, 222), Enum.Material.Slate)
	local radius = diameter / 2
	for _ = 1, 14 do
		local direction = (facing.Unit + Vector3.new(
			rng:NextNumber(-0.8, 0.8),
			rng:NextNumber(-0.8, 0.8),
			rng:NextNumber(-0.8, 0.8)
		)).Unit
		local size = diameter * rng:NextNumber(0.06, 0.16)
		local point = center + direction * (radius - size * 0.02)
		Parts.Make(
			model,
			Vector3.new(diameter * 0.012, size, size),
			orient(direction, point),
			rgb(168, 168, 180),
			{
				Shape = Enum.PartType.Cylinder,
				Material = Enum.Material.Slate,
			}
		)
		Parts.Make(
			model,
			Vector3.new(diameter * 0.014, size * 0.7, size * 0.7),
			orient(direction, point),
			rgb(140, 140, 154),
			{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Slate }
		)
	end
end

function Landmarks.Earth(parent: Instance, center: Vector3, diameter: number, rng: Random)
	local model = Voxel.Model(parent, "Earth")
	Voxel.Ball(model, Vector3.one * diameter, center, rgb(40, 110, 220), Enum.Material.SmoothPlastic)
	local radius = diameter / 2
	for _ = 1, 7 do
		local direction =
			Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.7, 0.7), rng:NextNumber(-1, 1)).Unit
		local size = diameter * rng:NextNumber(0.3, 0.45)
		Voxel.Ball(
			model,
			Vector3.one * size,
			center + direction * (radius - size * 0.42),
			rgb(70, 170, 80),
			Enum.Material.Grass
		)
	end
	for _, y in { 1, -1 } do
		Voxel.Ball(
			model,
			Vector3.one * diameter * 0.42,
			center + Vector3.new(0, y * radius * 0.82, 0),
			rgb(245, 250, 255),
			Enum.Material.Snow
		)
	end
end

function Landmarks.Planet(
	parent: Instance,
	center: Vector3,
	diameter: number,
	color: Color3,
	band: Color3,
	ring: Color3?,
	tilt: number
)
	local model = Voxel.Model(parent, "Planet")
	Voxel.Ball(model, Vector3.one * diameter, center, color, Enum.Material.SmoothPlastic)
	local radius = diameter / 2
	local axis = CFrame.new(center) * CFrame.Angles(tilt, 0, tilt * 0.6)
	for _, latitude in { -0.45, -0.1, 0.3 } do
		local width = 2 * radius * math.sqrt(1 - latitude * latitude) + diameter * 0.012
		Voxel.Cylinder(
			model,
			width,
			diameter * 0.07,
			axis * CFrame.new(0, latitude * radius, 0),
			band,
			Enum.Material.SmoothPlastic
		)
	end
	if ring then
		local plane = axis * CFrame.Angles(math.pi / 2, 0, 0)
		Voxel.Ring(model, plane, radius * 1.55, radius * 0.4, diameter * 0.012, 36, ring, Enum.Material.Neon)
		Voxel.Ring(
			model,
			plane,
			radius * 2.05,
			radius * 0.22,
			diameter * 0.01,
			40,
			ring:Lerp(rgb(255, 255, 255), 0.3),
			Enum.Material.SmoothPlastic
		)
	end
end

function Landmarks.Station(parent: Instance, center: CFrame, radius: number)
	local model = Voxel.Model(parent, "SpaceStation")
	local metal = rgb(222, 226, 236)
	local glow = rgb(90, 220, 255)
	Voxel.Ring(model, center, radius, radius * 0.16, radius * 0.22, 28, metal, Enum.Material.Metal)
	Voxel.Ring(
		model,
		center * CFrame.new(0, 0, -radius * 0.12),
		radius,
		radius * 0.05,
		radius * 0.02,
		28,
		glow,
		Enum.Material.Neon
	)
	Voxel.Cylinder(
		model,
		radius * 0.34,
		radius * 0.5,
		center * CFrame.Angles(math.pi / 2, 0, 0),
		metal,
		Enum.Material.Metal
	)
	Voxel.Cylinder(
		model,
		radius * 0.2,
		radius * 0.9,
		center * CFrame.Angles(math.pi / 2, 0, 0),
		rgb(160, 166, 180),
		Enum.Material.Metal
	)
	for index = 0, 3 do
		local spoke = center * CFrame.Angles(0, 0, index * math.pi / 2 + math.pi / 4)
		Voxel.Box(
			model,
			Vector3.new(radius * 0.05, radius * 0.9, radius * 0.05),
			spoke * CFrame.new(0, radius * 0.55, 0),
			metal,
			Enum.Material.Metal
		)
	end
	for _, side in { -1, 1 } do
		local wing = center * CFrame.new(0, 0, side * radius * 0.75)
		Voxel.Box(
			model,
			Vector3.new(radius * 0.05, radius * 0.05, radius * 0.5),
			wing * CFrame.new(0, 0, -side * radius * 0.1),
			metal,
			Enum.Material.Metal
		)
		for index = -1, 1 do
			Voxel.Box(
				model,
				Vector3.new(radius * 0.32, radius * 0.02, radius * 0.2),
				wing * CFrame.new(index * radius * 0.34, 0, side * radius * 0.15),
				rgb(40, 70, 170),
				Enum.Material.Glass
			)
		end
	end
	Voxel.Neon(model, Vector3.one * radius * 0.08, center * CFrame.new(0, 0, -radius * 0.5), rgb(255, 80, 80))
	Voxel.Neon(model, Vector3.one * radius * 0.08, center * CFrame.new(0, 0, radius * 0.5), glow)
end

function Landmarks.Satellite(parent: Instance, at: Vector3, rng: Random)
	local model = Voxel.Model(parent, "Satellite")
	local frame = CFrame.new(at)
		* CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, math.pi), rng:NextNumber(-0.5, 0.5))
	Parts.Make(model, Vector3.new(8, 8, 10), frame, rgb(230, 190, 70), { Material = Enum.Material.Foil })
	for _, side in { -1, 1 } do
		Voxel.Box(
			model,
			Vector3.new(0.6, 0.6, 6),
			frame * CFrame.new(0, 0, side * 8),
			rgb(200, 200, 205),
			Enum.Material.Metal
		)
		Voxel.Box(
			model,
			Vector3.new(10, 0.4, 12),
			frame * CFrame.new(0, 0, side * 16),
			rgb(40, 70, 170),
			Enum.Material.Glass
		)
	end
	Voxel.Cylinder(model, 7, 1, frame * CFrame.new(0, 5.5, 0), rgb(240, 240, 245), Enum.Material.Metal)
	Voxel.Neon(model, Vector3.one * 1.2, frame * CFrame.new(0, 6.6, 0), rgb(255, 80, 80))
end

function Landmarks.Galaxy(parent: Instance, center: CFrame, radius: number, rng: Random)
	local model = Voxel.Model(parent, "Galaxy")
	local core = rgb(255, 240, 255)
	Voxel.Ball(model, Vector3.one * radius * 0.26, center.Position, core, Enum.Material.Neon)
	local halo = Voxel.Ball(
		model,
		Vector3.one * radius * 0.46,
		center.Position,
		rgb(255, 150, 240),
		Enum.Material.Neon
	)
	halo.Transparency = 0.6
	local arms = 3
	local steps = 26
	local inner = { rgb(255, 170, 245), rgb(200, 150, 255) }
	local outer = { rgb(120, 110, 255), rgb(90, 210, 255), rgb(255, 90, 210) }
	for arm = 0, arms - 1 do
		for step = 1, steps do
			local t = step / steps
			local angle = arm * math.pi * 2 / arms + t * math.pi * 1.7
			local distance = radius * (0.14 + 0.86 * t)
			local size = radius * (0.11 - 0.075 * t) * rng:NextNumber(0.7, 1.3)
			local spread = radius * 0.05 * t
			local color = if t < 0.4 then Voxel.Pick(rng, inner) else Voxel.Pick(rng, outer)
			Voxel.Neon(
				model,
				Vector3.one * size,
				center
					* CFrame.new(
						math.cos(angle) * distance + rng:NextNumber(-spread, spread),
						math.sin(angle) * distance + rng:NextNumber(-spread, spread),
						rng:NextNumber(-spread, spread) * 0.4
					)
					* CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
				color,
				if t > 0.7 then 0.25 else 0
			)
		end
	end
	for _ = 1, 40 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = radius * rng:NextNumber(0.2, 1.15)
		Voxel.Neon(
			model,
			Vector3.one * radius * rng:NextNumber(0.008, 0.02),
			center
				* CFrame.new(
					math.cos(angle) * distance,
					math.sin(angle) * distance,
					rng:NextNumber(-0.05, 0.05) * radius
				),
			rgb(255, 255, 255)
		)
	end
end

function Landmarks.BlackHole(parent: Instance, center: CFrame, radius: number)
	local model = Voxel.Model(parent, "BlackHole")
	Voxel.Cylinder(
		model,
		radius * 1.3,
		radius * 0.05,
		center * CFrame.Angles(math.pi / 2, 0, 0),
		rgb(4, 2, 10),
		Enum.Material.SmoothPlastic
	)
	local colors = { rgb(255, 150, 60), rgb(255, 90, 200), rgb(170, 90, 255), rgb(90, 200, 255) }
	for index, color in colors do
		Voxel.Ring(
			model,
			center * CFrame.new(0, 0, -index * 0.6) * CFrame.Angles(0, 0, index * 0.2),
			radius * (0.68 + index * 0.13),
			radius * 0.07,
			radius * 0.03,
			32,
			color,
			Enum.Material.Neon
		)
	end
	Voxel.Ring(
		model,
		center * CFrame.Angles(math.rad(75), 0, 0),
		radius * 1.7,
		radius * 0.25,
		radius * 0.02,
		36,
		rgb(255, 170, 90),
		Enum.Material.Neon
	)
end

return Landmarks
