--!strict

local Parts = require(script.Parent.Parts)

local Props = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function pick(rng: Random, colors: { Color3 }): Color3
	return colors[rng:NextInteger(1, #colors)]
end

local function tree(parent: Instance, at: Vector3, rng: Random)
	local height = rng:NextNumber(12, 20)
	Parts.Make(
		parent,
		Vector3.new(3, height, 3),
		CFrame.new(at + Vector3.new(0, height / 2, 0)),
		rgb(120, 80, 45),
		{
			Material = Enum.Material.Wood,
		}
	)
	local size = rng:NextNumber(13, 20)
	Parts.Ball(
		parent,
		Vector3.one * size,
		at + Vector3.new(0, height + size * 0.3, 0),
		pick(rng, {
			rgb(70, 170, 60),
			rgb(90, 190, 70),
			rgb(50, 150, 55),
		}),
		Enum.Material.Grass
	)
end

local function bush(parent: Instance, at: Vector3, rng: Random)
	local size = rng:NextNumber(6, 10)
	Parts.Ball(
		parent,
		Vector3.new(size * 1.4, size, size * 1.2),
		at + Vector3.new(0, size * 0.35, 0),
		rgb(80, 175, 60),
		Enum.Material.Grass
	)
	Parts.Ball(
		parent,
		Vector3.one * 1.6,
		at + Vector3.new(size * 0.3, size * 0.8, 0),
		pick(rng, {
			rgb(255, 90, 120),
			rgb(255, 220, 60),
			rgb(150, 110, 255),
		})
	)
end

local function cactus(parent: Instance, at: Vector3, rng: Random)
	local height = rng:NextNumber(12, 22)
	local green = rgb(70, 150, 70)
	Parts.Make(parent, Vector3.new(3.4, height, 3.4), CFrame.new(at + Vector3.new(0, height / 2, 0)), green)
	local armHeight = height * 0.55
	Parts.Make(parent, Vector3.new(5, 2.4, 2.4), CFrame.new(at + Vector3.new(3.5, armHeight, 0)), green)
	Parts.Make(parent, Vector3.new(2.4, 6, 2.4), CFrame.new(at + Vector3.new(5, armHeight + 3, 0)), green)
	Parts.Make(parent, Vector3.new(5, 2.4, 2.4), CFrame.new(at + Vector3.new(-3.5, armHeight - 3, 0)), green)
	Parts.Make(parent, Vector3.new(2.4, 5, 2.4), CFrame.new(at + Vector3.new(-5, armHeight, 0)), green)
end

local function rock(parent: Instance, at: Vector3, rng: Random, colors: { Color3 }, material: Enum.Material)
	local size = Vector3.new(rng:NextNumber(5, 14), rng:NextNumber(4, 10), rng:NextNumber(5, 14))
	local angles =
		CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, math.pi), rng:NextNumber(-0.4, 0.4))
	Parts.Make(parent, size, CFrame.new(at + Vector3.new(0, size.Y * 0.35, 0)) * angles, pick(rng, colors), {
		Material = material,
	})
end

local function pine(parent: Instance, at: Vector3, rng: Random)
	local trunk = rng:NextNumber(5, 8)
	Parts.Make(
		parent,
		Vector3.new(2.6, trunk, 2.6),
		CFrame.new(at + Vector3.new(0, trunk / 2, 0)),
		rgb(110, 75, 45),
		{
			Material = Enum.Material.Wood,
		}
	)
	local y = trunk
	for tier = 1, 3 do
		local width = 16 - tier * 4
		local height = 6
		Parts.Make(
			parent,
			Vector3.new(width, height, width),
			CFrame.new(at + Vector3.new(0, y + height / 2, 0)) * CFrame.Angles(0, math.rad(tier * 25), 0),
			rgb(40, 120, 70)
		)
		Parts.Make(
			parent,
			Vector3.new(width * 0.8, 1, width * 0.8),
			CFrame.new(at + Vector3.new(0, y + height + 0.5, 0)) * CFrame.Angles(0, math.rad(tier * 25), 0),
			rgb(245, 250, 255),
			{ Material = Enum.Material.Snow }
		)
		y += height
	end
end

local function snowman(parent: Instance, at: Vector3)
	local white = rgb(245, 250, 255)
	Parts.Ball(parent, Vector3.one * 8, at + Vector3.new(0, 4, 0), white, Enum.Material.Snow)
	Parts.Ball(parent, Vector3.one * 6, at + Vector3.new(0, 10, 0), white, Enum.Material.Snow)
	Parts.Ball(parent, Vector3.one * 4.4, at + Vector3.new(0, 14.6, 0), white, Enum.Material.Snow)
	Parts.Make(
		parent,
		Vector3.new(2, 0.8, 0.8),
		CFrame.new(at + Vector3.new(-2.8, 14.6, 0)),
		rgb(255, 140, 30)
	)
end

local function volcano(parent: Instance, at: Vector3, rng: Random)
	local base = rng:NextNumber(24, 36)
	local y = 0
	for level = 0, 3 do
		local width = base * (1 - level * 0.22)
		local height = 6
		Parts.Make(
			parent,
			Vector3.new(width, height, width),
			CFrame.new(at + Vector3.new(0, y + height / 2, 0)) * CFrame.Angles(0, math.rad(level * 20), 0),
			rgb(55, 40, 38),
			{ Material = Enum.Material.Basalt }
		)
		y += height
	end
	Parts.Disc(parent, base * 0.3, 1, at + Vector3.new(0, y + 0.3, 0), rgb(255, 110, 30), Enum.Material.Neon)
end

local function lavaPool(parent: Instance, at: Vector3, rng: Random)
	Parts.Disc(
		parent,
		rng:NextNumber(16, 34),
		0.6,
		at + Vector3.new(0, 0.2, 0),
		rgb(255, 100, 25),
		Enum.Material.Neon
	)
end

local function lollipop(parent: Instance, at: Vector3, rng: Random)
	local height = rng:NextNumber(12, 20)
	Parts.Make(
		parent,
		Vector3.new(1.4, height, 1.4),
		CFrame.new(at + Vector3.new(0, height / 2, 0)),
		rgb(250, 250, 250)
	)
	local size = rng:NextNumber(7, 11)
	Parts.Ball(
		parent,
		Vector3.one * size,
		at + Vector3.new(0, height + size * 0.35, 0),
		pick(rng, {
			rgb(255, 90, 170),
			rgb(90, 200, 255),
			rgb(255, 210, 60),
			rgb(160, 110, 255),
		})
	)
end

local function candyCane(parent: Instance, at: Vector3)
	for index = 0, 5 do
		Parts.Make(
			parent,
			Vector3.new(2.4, 3, 2.4),
			CFrame.new(at + Vector3.new(0, 1.5 + index * 3, 0)),
			if index % 2 == 0 then rgb(235, 40, 60) else rgb(250, 250, 250)
		)
	end
	Parts.Make(parent, Vector3.new(6, 2.4, 2.4), CFrame.new(at + Vector3.new(2, 19, 0)), rgb(235, 40, 60))
	Parts.Make(parent, Vector3.new(2.4, 4, 2.4), CFrame.new(at + Vector3.new(4.2, 17, 0)), rgb(250, 250, 250))
end

local function gumdrop(parent: Instance, at: Vector3, rng: Random)
	local size = rng:NextNumber(6, 12)
	Parts.Ball(
		parent,
		Vector3.new(size, size * 0.8, size),
		at + Vector3.new(0, size * 0.25, 0),
		pick(rng, {
			rgb(120, 230, 120),
			rgb(255, 120, 200),
			rgb(255, 180, 60),
			rgb(120, 180, 255),
		}),
		Enum.Material.Glass
	)
end

local function crater(parent: Instance, at: Vector3, rng: Random)
	local size = rng:NextNumber(16, 40)
	Parts.Disc(parent, size, 0.6, at + Vector3.new(0, 0.15, 0), rgb(120, 120, 128), Enum.Material.Slate)
	Parts.Disc(parent, size * 0.7, 0.8, at + Vector3.new(0, 0.2, 0), rgb(95, 95, 102), Enum.Material.Slate)
end

local function flag(parent: Instance, at: Vector3)
	Parts.Make(parent, Vector3.new(0.6, 14, 0.6), CFrame.new(at + Vector3.new(0, 7, 0)), rgb(220, 220, 225), {
		Material = Enum.Material.Metal,
	})
	Parts.Make(parent, Vector3.new(0.3, 4, 6), CFrame.new(at + Vector3.new(0, 12, 3)), rgb(255, 80, 80))
end

local function asteroid(parent: Instance, at: Vector3, rng: Random)
	local size = rng:NextNumber(8, 26)
	Parts.Make(
		parent,
		Vector3.new(size, size * 0.8, size * 0.9),
		CFrame.new(at + Vector3.new(0, rng:NextNumber(30, 180), 0))
			* CFrame.Angles(rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi), 0),
		pick(rng, { rgb(90, 85, 100), rgb(70, 65, 80), rgb(110, 100, 120) }),
		{ Material = Enum.Material.Slate }
	)
end

local function crystal(parent: Instance, at: Vector3, rng: Random)
	local color = pick(rng, { rgb(255, 80, 220), rgb(80, 220, 255), rgb(170, 110, 255) })
	for index = 1, 3 do
		local height = rng:NextNumber(8, 22)
		Parts.Make(
			parent,
			Vector3.new(3, height, 3),
			CFrame.new(at + Vector3.new(rng:NextNumber(-4, 4), height / 2, rng:NextNumber(-4, 4)))
				* CFrame.Angles(rng:NextNumber(-0.4, 0.4), math.rad(45 * index), rng:NextNumber(-0.4, 0.4)),
			color,
			{ Material = Enum.Material.Neon }
		)
	end
end

local function orb(parent: Instance, at: Vector3, rng: Random)
	Parts.Ball(
		parent,
		Vector3.one * rng:NextNumber(4, 10),
		at + Vector3.new(0, rng:NextNumber(20, 120), 0),
		pick(rng, { rgb(255, 120, 230), rgb(120, 230, 255), rgb(255, 230, 120) }),
		Enum.Material.Neon
	)
end

function Props.Place(zone: number, parent: Instance, at: Vector3, rng: Random)
	local roll = rng:NextNumber()
	if zone == 1 then
		if roll < 0.65 then
			tree(parent, at, rng)
		else
			bush(parent, at, rng)
		end
	elseif zone == 2 then
		if roll < 0.55 then
			cactus(parent, at, rng)
		else
			rock(parent, at, rng, { rgb(200, 150, 90), rgb(180, 120, 70) }, Enum.Material.Sandstone)
		end
	elseif zone == 3 then
		if roll < 0.7 then
			pine(parent, at, rng)
		else
			snowman(parent, at)
		end
	elseif zone == 4 then
		if roll < 0.3 then
			volcano(parent, at, rng)
		elseif roll < 0.65 then
			lavaPool(parent, at, rng)
		else
			rock(parent, at, rng, { rgb(40, 32, 30), rgb(60, 45, 40) }, Enum.Material.Basalt)
		end
	elseif zone == 5 then
		if roll < 0.45 then
			lollipop(parent, at, rng)
		elseif roll < 0.7 then
			candyCane(parent, at)
		else
			gumdrop(parent, at, rng)
		end
	elseif zone == 6 then
		if roll < 0.5 then
			crater(parent, at, rng)
		elseif roll < 0.8 then
			rock(parent, at, rng, { rgb(150, 150, 158), rgb(120, 120, 128) }, Enum.Material.Slate)
		else
			flag(parent, at)
		end
	elseif zone == 7 then
		if roll < 0.7 then
			asteroid(parent, at, rng)
		else
			orb(parent, at, rng)
		end
	else
		if roll < 0.6 then
			crystal(parent, at, rng)
		else
			orb(parent, at, rng)
		end
	end
end

function Props.Scenery(zone: number, parent: Instance, at: Vector3, rng: Random, color: Color3)
	if zone >= 7 then
		local size = rng:NextNumber(120, 320)
		local center = at + Vector3.new(0, rng:NextNumber(250, 600), 0)
		Parts.Ball(parent, Vector3.one * size, center, color, Enum.Material.SmoothPlastic)
		Parts.Disc(parent, size * 1.8, 2, center, Color3.fromRGB(255, 220, 150), Enum.Material.Neon)
		return
	end
	local size = rng:NextNumber(160, 360)
	Parts.Make(
		parent,
		Vector3.one * size,
		CFrame.new(at) * CFrame.Angles(math.rad(45), rng:NextNumber(0, math.pi), math.rad(35)),
		color,
		{ Material = Enum.Material.SmoothPlastic }
	)
end

return Props
