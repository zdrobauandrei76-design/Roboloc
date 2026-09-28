--!strict

local Voxel = require(script.Parent.Voxel)

local Props = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function yaw(rng: Random): CFrame
	return CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
end

local leafColors = { rgb(76, 176, 62), rgb(96, 196, 70), rgb(58, 150, 58), rgb(120, 200, 80) }
local flowerColors =
	{ rgb(255, 90, 120), rgb(255, 220, 60), rgb(160, 110, 255), rgb(255, 150, 60), rgb(255, 255, 255) }
local candyColors =
	{ rgb(255, 90, 170), rgb(90, 200, 255), rgb(255, 210, 60), rgb(160, 110, 255), rgb(120, 230, 140) }
local crystalColors = { rgb(255, 80, 220), rgb(80, 220, 255), rgb(170, 110, 255) }

function Props.Tree(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	local height = rng:NextNumber(9, 15) * s
	local turn = yaw(rng)
	Voxel.Box(
		parent,
		Vector3.new(2.6, height, 2.6) * Vector3.new(s, 1, s),
		CFrame.new(at + Vector3.new(0, height / 2, 0)) * turn,
		rgb(118, 80, 48),
		Enum.Material.Wood
	)
	local size = rng:NextNumber(10, 14) * s
	local crown = at + Vector3.new(0, height + size * 0.25, 0)
	local green = Voxel.Pick(rng, leafColors)
	Voxel.Box(
		parent,
		Vector3.new(size, size * 0.8, size),
		CFrame.new(crown) * turn,
		green,
		Enum.Material.Grass
	)
	Voxel.Box(
		parent,
		Vector3.new(size * 0.66, size * 0.5, size * 0.66),
		CFrame.new(crown + Vector3.new(0, size * 0.6, 0)) * turn,
		green:Lerp(rgb(200, 255, 140), 0.2),
		Enum.Material.Grass
	)
	Voxel.Box(
		parent,
		Vector3.new(size * 0.5, size * 0.45, size * 0.5),
		CFrame.new(crown) * turn * CFrame.new(size * 0.5, -size * 0.12, size * 0.2),
		green:Lerp(rgb(20, 80, 30), 0.15),
		Enum.Material.Grass
	)
end

function Props.Bush(parent: Instance, at: Vector3, rng: Random)
	local size = rng:NextNumber(5, 8)
	local turn = yaw(rng)
	Voxel.Box(
		parent,
		Vector3.new(size * 1.3, size * 0.8, size),
		CFrame.new(at + Vector3.new(0, size * 0.4, 0)) * turn,
		Voxel.Pick(rng, leafColors),
		Enum.Material.Grass
	)
	Voxel.Box(
		parent,
		Vector3.one * 1.4,
		CFrame.new(at + Vector3.new(0, size * 0.85, 0)) * turn * CFrame.new(size * 0.3, 0, 0),
		Voxel.Pick(rng, flowerColors)
	)
end

function Props.Flowers(parent: Instance, at: Vector3, rng: Random)
	for _ = 1, 3 do
		local spot = at + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
		Voxel.Box(parent, Vector3.new(0.4, 2, 0.4), CFrame.new(spot + Vector3.new(0, 1, 0)), rgb(70, 160, 60))
		Voxel.Box(
			parent,
			Vector3.new(1.4, 1.1, 1.4),
			CFrame.new(spot + Vector3.new(0, 2.3, 0)) * yaw(rng),
			Voxel.Pick(rng, flowerColors)
		)
	end
end

function Props.Mushroom(parent: Instance, at: Vector3, rng: Random)
	local s = rng:NextNumber(0.8, 1.6)
	Voxel.Box(parent, Vector3.new(2, 4, 2) * s, CFrame.new(at + Vector3.new(0, 2 * s, 0)), rgb(245, 235, 215))
	Voxel.Box(
		parent,
		Vector3.new(6, 2.4, 6) * s,
		CFrame.new(at + Vector3.new(0, 4.8 * s, 0)),
		rgb(230, 50, 50)
	)
	Voxel.Box(
		parent,
		Vector3.new(1.2, 0.4, 1.2) * s,
		CFrame.new(at + Vector3.new(1.4 * s, 6.1 * s, 0.8 * s)),
		rgb(255, 255, 255)
	)
end

function Props.Rock(
	parent: Instance,
	at: Vector3,
	rng: Random,
	color: Color3,
	material: Enum.Material,
	scale: number?
)
	local s = scale or 1
	local size = Vector3.new(rng:NextNumber(5, 12), rng:NextNumber(3, 8), rng:NextNumber(5, 12)) * s
	local turn = yaw(rng)
	Voxel.Box(parent, size, CFrame.new(at + Vector3.new(0, size.Y * 0.4, 0)) * turn, color, material)
	Voxel.Box(
		parent,
		size * 0.55,
		CFrame.new(at + Vector3.new(0, size.Y * 0.4, 0))
			* turn
			* CFrame.new(size.X * 0.45, -size.Y * 0.2, size.Z * 0.2),
		color:Lerp(rgb(0, 0, 0), 0.12),
		material
	)
end

function Props.Fence(parent: Instance, at: Vector3, rng: Random)
	local turn = yaw(rng)
	local wood = rgb(200, 150, 95)
	for index = -1, 1 do
		Voxel.Box(
			parent,
			Vector3.new(1, 5, 1),
			CFrame.new(at) * turn * CFrame.new(index * 5, 2.5, 0),
			wood,
			Enum.Material.Wood
		)
	end
	for _, y in { 2, 4 } do
		Voxel.Box(
			parent,
			Vector3.new(11, 0.8, 0.5),
			CFrame.new(at) * turn * CFrame.new(0, y, 0),
			wood,
			Enum.Material.Wood
		)
	end
end

function Props.Cactus(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	local height = rng:NextNumber(10, 18) * s
	local green = rgb(72, 156, 72)
	local turn = yaw(rng)
	local base = CFrame.new(at) * turn
	Voxel.Box(
		parent,
		Vector3.new(3.2, height, 3.2) * Vector3.new(s, 1, s),
		base * CFrame.new(0, height / 2, 0),
		green
	)
	local arm = height * 0.5
	Voxel.Box(parent, Vector3.new(4.4, 2.2, 2.2) * s, base * CFrame.new(3 * s, arm, 0), green)
	Voxel.Box(parent, Vector3.new(2.2, 5, 2.2) * s, base * CFrame.new(4.4 * s, arm + 2.4 * s, 0), green)
	Voxel.Box(parent, Vector3.new(4.4, 2.2, 2.2) * s, base * CFrame.new(-3 * s, arm - 2.5 * s, 0), green)
	Voxel.Box(parent, Vector3.new(2.2, 4, 2.2) * s, base * CFrame.new(-4.4 * s, arm - 0.6 * s, 0), green)
	Voxel.Box(
		parent,
		Vector3.new(1.4, 1.2, 1.4) * s,
		base * CFrame.new(0, height + 0.4 * s, 0),
		rgb(255, 120, 180)
	)
end

function Props.Palm(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	local turn = yaw(rng)
	local base = CFrame.new(at) * turn
	local lean = rng:NextNumber(0.6, 1.4) * s
	local y = 0
	for index = 1, 4 do
		local height = 5 * s
		Voxel.Box(
			parent,
			Vector3.new(2.2, height, 2.2) * Vector3.new(s, 1, s),
			base * CFrame.new(index * lean, y + height / 2, 0),
			if index % 2 == 0 then rgb(150, 105, 60) else rgb(128, 88, 50),
			Enum.Material.Wood
		)
		y += height
	end
	local top = base * CFrame.new(4 * lean, y, 0)
	for index = 0, 4 do
		Voxel.Box(
			parent,
			Vector3.new(10, 0.6, 3) * s,
			top
				* CFrame.Angles(0, index * math.pi * 2 / 5, 0)
				* CFrame.new(5 * s, -0.8 * s, 0)
				* CFrame.Angles(0, 0, -0.35),
			rgb(60, 170, 70),
			Enum.Material.Grass
		)
	end
	Voxel.Ball(
		parent,
		Vector3.one * 1.8 * s,
		(top * CFrame.new(0.8 * s, -1.2 * s, 0.6 * s)).Position,
		rgb(120, 80, 40)
	)
end

function Props.Pine(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	local trunk = rng:NextNumber(4, 6) * s
	Voxel.Box(
		parent,
		Vector3.new(2.4 * s, trunk, 2.4 * s),
		CFrame.new(at + Vector3.new(0, trunk / 2, 0)),
		rgb(110, 75, 45),
		Enum.Material.Wood
	)
	local y = trunk
	for tier = 1, 3 do
		local width = (15 - tier * 3.5) * s
		local height = 5.5 * s
		local turn = CFrame.Angles(0, math.rad(tier * 25), 0)
		Voxel.Box(
			parent,
			Vector3.new(width, height, width),
			CFrame.new(at + Vector3.new(0, y + height / 2, 0)) * turn,
			rgb(40, 120, 72),
			Enum.Material.Grass
		)
		Voxel.Box(
			parent,
			Vector3.new(width * 0.84, 1, width * 0.84),
			CFrame.new(at + Vector3.new(0, y + height + 0.3, 0)) * turn,
			rgb(245, 250, 255),
			Enum.Material.Snow
		)
		y += height
	end
end

function Props.IceSpike(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	for index = 1, 3 do
		local height = rng:NextNumber(10, 26) * s
		local width = rng:NextNumber(2.5, 4.5) * s
		Voxel.Box(
			parent,
			Vector3.new(width, height, width),
			CFrame.new(at + Vector3.new(rng:NextNumber(-3, 3) * s, height * 0.42, rng:NextNumber(-3, 3) * s))
				* CFrame.Angles(
					rng:NextNumber(-0.35, 0.35),
					math.rad(40 * index),
					rng:NextNumber(-0.35, 0.35)
				),
			if index == 2 then rgb(200, 240, 255) else rgb(150, 215, 250),
			Enum.Material.Glacier
		)
	end
end

function Props.Snowman(parent: Instance, at: Vector3, rng: Random)
	local snow = rgb(245, 250, 255)
	local turn = yaw(rng)
	local base = CFrame.new(at) * turn
	Voxel.Box(parent, Vector3.new(8, 7, 8), base * CFrame.new(0, 3.5, 0), snow, Enum.Material.Snow)
	Voxel.Box(parent, Vector3.new(6, 5.5, 6), base * CFrame.new(0, 9.7, 0), snow, Enum.Material.Snow)
	Voxel.Box(parent, Vector3.new(4.6, 4.4, 4.6), base * CFrame.new(0, 14.6, 0), snow, Enum.Material.Snow)
	Voxel.Box(parent, Vector3.new(0.8, 0.8, 2.6), base * CFrame.new(0, 14.6, -3), rgb(255, 140, 30))
	Voxel.Box(parent, Vector3.new(5.6, 1, 5.6), base * CFrame.new(0, 12.2, 0), rgb(220, 50, 60))
	Voxel.Box(parent, Vector3.new(3.6, 3, 3.6), base * CFrame.new(0, 18.2, 0), rgb(30, 30, 36))
end

function Props.Igloo(parent: Instance, at: Vector3, rng: Random)
	local snow = rgb(235, 245, 255)
	local turn = yaw(rng)
	Voxel.Ball(parent, Vector3.one * 18, at, snow, Enum.Material.Snow)
	Voxel.Box(
		parent,
		Vector3.new(7, 7, 8),
		CFrame.new(at) * turn * CFrame.new(0, 3.5, -9),
		snow,
		Enum.Material.Snow
	)
	Voxel.Box(
		parent,
		Vector3.new(4, 4.6, 0.4),
		CFrame.new(at) * turn * CFrame.new(0, 2.3, -13.1),
		rgb(40, 50, 70)
	)
end

function Props.LavaRock(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	local size = Vector3.new(rng:NextNumber(6, 14), rng:NextNumber(5, 12), rng:NextNumber(6, 14)) * s
	local turn = yaw(rng)
	Voxel.Box(
		parent,
		size,
		CFrame.new(at + Vector3.new(0, size.Y * 0.4, 0)) * turn,
		rgb(45, 34, 34),
		Enum.Material.Basalt
	)
	Voxel.Neon(
		parent,
		Vector3.new(size.X * 1.02, 0.5, 1.2),
		CFrame.new(at + Vector3.new(0, size.Y * 0.35, 0)) * turn * CFrame.Angles(0, 0, 0.25),
		rgb(255, 110, 30)
	)
end

function Props.Basalt(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	for index = 1, 4 do
		local height = rng:NextNumber(8, 24) * s
		Voxel.Box(
			parent,
			Vector3.new(4.5, height, 4.5) * Vector3.new(s, 1, s),
			CFrame.new(at + Vector3.new((index % 2) * 4.4 * s, height / 2, math.floor(index / 3) * 4.4 * s)),
			if index % 2 == 0 then rgb(52, 42, 42) else rgb(38, 30, 30),
			Enum.Material.Basalt
		)
	end
end

function Props.LavaPool(parent: Instance, at: Vector3, rng: Random)
	local size = rng:NextNumber(14, 30)
	Voxel.Cylinder(
		parent,
		size + 4,
		0.6,
		CFrame.new(at + Vector3.new(0, 0.2, 0)),
		rgb(40, 30, 30),
		Enum.Material.Basalt
	)
	Voxel.Cylinder(
		parent,
		size,
		0.8,
		CFrame.new(at + Vector3.new(0, 0.3, 0)),
		rgb(255, 100, 25),
		Enum.Material.Neon
	)
end

function Props.Vent(parent: Instance, at: Vector3, rng: Random)
	Voxel.Box(
		parent,
		Vector3.new(6, 4, 6),
		CFrame.new(at + Vector3.new(0, 2, 0)) * yaw(rng),
		rgb(48, 38, 36),
		Enum.Material.Basalt
	)
	Voxel.Neon(parent, Vector3.new(3, 0.6, 3), CFrame.new(at + Vector3.new(0, 4.1, 0)), rgb(255, 160, 40))
	for index = 1, 3 do
		Voxel.Ball(
			parent,
			Vector3.one * (3 + index * 2),
			at + Vector3.new(rng:NextNumber(-1, 1), 5 + index * 4, rng:NextNumber(-1, 1)),
			rgb(90, 80, 85):Lerp(rgb(140, 130, 135), index / 3),
			Enum.Material.SmoothPlastic
		)
	end
end

function Props.Lollipop(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	local height = rng:NextNumber(12, 18) * s
	Voxel.Box(
		parent,
		Vector3.new(1.2, height, 1.2) * Vector3.new(s, 1, s),
		CFrame.new(at + Vector3.new(0, height / 2, 0)),
		rgb(250, 250, 250)
	)
	local size = rng:NextNumber(8, 12) * s
	local head = CFrame.new(at + Vector3.new(0, height + size * 0.4, 0)) * yaw(rng)
	local first = Voxel.Pick(rng, candyColors)
	Voxel.Cylinder(
		parent,
		size,
		1.6 * s,
		head * CFrame.Angles(math.pi / 2, 0, 0),
		first,
		Enum.Material.SmoothPlastic
	)
	Voxel.Cylinder(
		parent,
		size * 0.66,
		1.8 * s,
		head * CFrame.Angles(math.pi / 2, 0, 0),
		rgb(255, 255, 255),
		Enum.Material.SmoothPlastic
	)
	Voxel.Cylinder(
		parent,
		size * 0.34,
		2 * s,
		head * CFrame.Angles(math.pi / 2, 0, 0),
		first,
		Enum.Material.SmoothPlastic
	)
end

function Props.CandyCane(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	local turn = CFrame.new(at) * yaw(rng)
	for index = 0, 5 do
		Voxel.Box(
			parent,
			Vector3.new(2.4, 3, 2.4) * s,
			turn * CFrame.new(0, (1.5 + index * 3) * s, 0),
			if index % 2 == 0 then rgb(235, 40, 60) else rgb(250, 250, 250)
		)
	end
	Voxel.Box(parent, Vector3.new(6.4, 2.4, 2.4) * s, turn * CFrame.new(2 * s, 19.2 * s, 0), rgb(235, 40, 60))
	Voxel.Box(parent, Vector3.new(2.4, 4, 2.4) * s, turn * CFrame.new(4.2 * s, 17 * s, 0), rgb(250, 250, 250))
end

function Props.Gumdrop(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = rng:NextNumber(6, 11) * (scale or 1)
	local color = Voxel.Pick(rng, candyColors)
	Voxel.Box(
		parent,
		Vector3.new(s, s * 0.5, s),
		CFrame.new(at + Vector3.new(0, s * 0.25, 0)) * yaw(rng),
		color,
		Enum.Material.Glass
	)
	Voxel.Box(
		parent,
		Vector3.new(s * 0.62, s * 0.4, s * 0.62),
		CFrame.new(at + Vector3.new(0, s * 0.68, 0)) * yaw(rng),
		color,
		Enum.Material.Glass
	)
end

function Props.Cupcake(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = rng:NextNumber(0.9, 1.4) * (scale or 1)
	Voxel.Cylinder(
		parent,
		9 * s,
		6 * s,
		CFrame.new(at + Vector3.new(0, 3 * s, 0)),
		rgb(200, 130, 80),
		Enum.Material.SmoothPlastic
	)
	Voxel.Ball(
		parent,
		Vector3.new(11, 7, 11) * s,
		at + Vector3.new(0, 7.2 * s, 0),
		Voxel.Pick(rng, candyColors),
		Enum.Material.SmoothPlastic
	)
	Voxel.Ball(
		parent,
		Vector3.one * 2.4 * s,
		at + Vector3.new(0, 11 * s, 0),
		rgb(220, 30, 50),
		Enum.Material.SmoothPlastic
	)
end

function Props.Donut(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = rng:NextNumber(0.8, 1.3) * (scale or 1)
	local frame = CFrame.new(at + Vector3.new(0, 7 * s, 0))
		* yaw(rng)
		* CFrame.Angles(0, 0, rng:NextNumber(-0.3, 0.3))
	Voxel.Ring(parent, frame, 5 * s, 3.6 * s, 3.6 * s, 8, rgb(215, 150, 90), Enum.Material.SmoothPlastic)
	Voxel.Ring(
		parent,
		frame * CFrame.new(0, 0, -0.5 * s),
		5 * s,
		3.8 * s,
		2.8 * s,
		8,
		Voxel.Pick(rng, candyColors),
		Enum.Material.SmoothPlastic
	)
end

function Props.Crater(parent: Instance, at: Vector3, rng: Random)
	local size = rng:NextNumber(16, 40)
	Voxel.Cylinder(
		parent,
		size,
		1.4,
		CFrame.new(at + Vector3.new(0, 0.3, 0)),
		rgb(140, 140, 150),
		Enum.Material.Slate
	)
	Voxel.Cylinder(
		parent,
		size * 0.76,
		1.6,
		CFrame.new(at + Vector3.new(0, 0.35, 0)),
		rgb(98, 98, 108),
		Enum.Material.Slate
	)
end

function Props.Flag(parent: Instance, at: Vector3, rng: Random)
	local turn = CFrame.new(at) * yaw(rng)
	Voxel.Box(
		parent,
		Vector3.new(0.6, 14, 0.6),
		turn * CFrame.new(0, 7, 0),
		rgb(220, 220, 225),
		Enum.Material.Metal
	)
	Voxel.Box(parent, Vector3.new(0.3, 4, 6), turn * CFrame.new(0, 12, 3), rgb(255, 80, 80))
	Voxel.Box(parent, Vector3.new(0.35, 2, 3), turn * CFrame.new(0, 13, 1.5), rgb(60, 110, 255))
end

function Props.Antenna(parent: Instance, at: Vector3, rng: Random)
	local height = rng:NextNumber(18, 30)
	Voxel.Box(
		parent,
		Vector3.new(4, 2, 4),
		CFrame.new(at + Vector3.new(0, 1, 0)),
		rgb(200, 200, 210),
		Enum.Material.Metal
	)
	Voxel.Box(
		parent,
		Vector3.new(0.8, height, 0.8),
		CFrame.new(at + Vector3.new(0, height / 2, 0)),
		rgb(220, 220, 230),
		Enum.Material.Metal
	)
	Voxel.Cylinder(
		parent,
		8,
		1,
		CFrame.new(at + Vector3.new(0, height * 0.7, 0)) * yaw(rng) * CFrame.Angles(0.6, 0, 0),
		rgb(235, 235, 240),
		Enum.Material.Metal
	)
	Voxel.Neon(parent, Vector3.one * 1.4, CFrame.new(at + Vector3.new(0, height + 0.6, 0)), rgb(255, 60, 60))
end

function Props.Asteroid(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = rng:NextNumber(6, 18) * (scale or 1)
	local colors = { rgb(92, 86, 100), rgb(72, 66, 82), rgb(112, 102, 120) }
	local frame = CFrame.new(at) * CFrame.Angles(rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi), 0)
	Voxel.Box(parent, Vector3.new(s, s * 0.8, s * 0.9), frame, Voxel.Pick(rng, colors), Enum.Material.Slate)
	Voxel.Box(
		parent,
		Vector3.new(s * 0.6, s * 0.7, s * 0.6),
		frame * CFrame.new(s * 0.4, s * 0.2, -s * 0.2) * CFrame.Angles(0.5, 0.4, 0),
		Voxel.Pick(rng, colors),
		Enum.Material.Slate
	)
end

function Props.Crystal(parent: Instance, at: Vector3, rng: Random, scale: number?)
	local s = scale or 1
	local color = Voxel.Pick(rng, crystalColors)
	for index = 1, 3 do
		local height = rng:NextNumber(8, 22) * s
		Voxel.Neon(
			parent,
			Vector3.new(3, height, 3) * Vector3.new(s, 1, s),
			CFrame.new(at + Vector3.new(rng:NextNumber(-4, 4) * s, height * 0.4, rng:NextNumber(-4, 4) * s))
				* CFrame.Angles(rng:NextNumber(-0.4, 0.4), math.rad(45 * index), rng:NextNumber(-0.4, 0.4)),
			color
		)
	end
end

function Props.Pylon(parent: Instance, at: Vector3, rng: Random)
	local height = rng:NextNumber(20, 34)
	local color = Voxel.Pick(rng, crystalColors)
	Voxel.Box(
		parent,
		Vector3.new(6, 2, 6),
		CFrame.new(at + Vector3.new(0, 1, 0)),
		rgb(30, 26, 50),
		Enum.Material.Metal
	)
	Voxel.Box(
		parent,
		Vector3.new(2.4, height, 2.4),
		CFrame.new(at + Vector3.new(0, height / 2, 0)),
		rgb(40, 34, 64),
		Enum.Material.Metal
	)
	for index = 1, 3 do
		Voxel.Neon(
			parent,
			Vector3.new(3, 0.8, 3),
			CFrame.new(at + Vector3.new(0, height * index / 4, 0)),
			color
		)
	end
	Voxel.Neon(
		parent,
		Vector3.one * 3,
		CFrame.new(at + Vector3.new(0, height + 1.5, 0)) * CFrame.Angles(0.6, 0.6, 0),
		color
	)
end

function Props.Place(zone: number, parent: Instance, at: Vector3, rng: Random, scale: number?)
	local roll = rng:NextNumber()
	if zone == 1 then
		if roll < 0.5 then
			Props.Tree(parent, at, rng, scale)
		elseif roll < 0.68 then
			Props.Bush(parent, at, rng)
		elseif roll < 0.82 then
			Props.Flowers(parent, at, rng)
		elseif roll < 0.9 then
			Props.Mushroom(parent, at, rng)
		else
			Props.Rock(parent, at, rng, rgb(130, 124, 118), Enum.Material.Rock, scale)
		end
	elseif zone == 2 then
		if roll < 0.45 then
			Props.Cactus(parent, at, rng, scale)
		elseif roll < 0.7 then
			Props.Palm(parent, at, rng, scale)
		else
			Props.Rock(parent, at, rng, rgb(205, 150, 90), Enum.Material.Sandstone, scale)
		end
	elseif zone == 3 then
		if roll < 0.55 then
			Props.Pine(parent, at, rng, scale)
		elseif roll < 0.8 then
			Props.IceSpike(parent, at, rng, scale)
		elseif roll < 0.92 then
			Props.Snowman(parent, at, rng)
		else
			Props.Igloo(parent, at, rng)
		end
	elseif zone == 4 then
		if roll < 0.3 then
			Props.LavaRock(parent, at, rng, scale)
		elseif roll < 0.55 then
			Props.Basalt(parent, at, rng, scale)
		elseif roll < 0.8 then
			Props.LavaPool(parent, at, rng)
		else
			Props.Vent(parent, at, rng)
		end
	elseif zone == 5 then
		if roll < 0.3 then
			Props.Lollipop(parent, at, rng, scale)
		elseif roll < 0.5 then
			Props.CandyCane(parent, at, rng, scale)
		elseif roll < 0.68 then
			Props.Gumdrop(parent, at, rng, scale)
		elseif roll < 0.92 then
			Props.Cupcake(parent, at, rng, scale)
		else
			Props.Donut(parent, at, rng, scale)
		end
	elseif zone == 6 then
		if roll < 0.4 then
			Props.Crater(parent, at, rng)
		elseif roll < 0.75 then
			Props.Rock(parent, at, rng, rgb(150, 150, 158), Enum.Material.Slate, scale)
		elseif roll < 0.88 then
			Props.Antenna(parent, at, rng)
		else
			Props.Flag(parent, at, rng)
		end
	elseif zone == 7 then
		if roll < 0.45 then
			Props.Crystal(parent, at, rng, scale)
		elseif roll < 0.75 then
			Props.Pylon(parent, at, rng)
		else
			Props.Rock(parent, at, rng, rgb(70, 60, 100), Enum.Material.Slate, scale)
		end
	else
		if roll < 0.6 then
			Props.Crystal(parent, at, rng, scale)
		else
			Props.Pylon(parent, at, rng)
		end
	end
end

return Props
