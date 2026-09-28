--!strict

local Landmarks = require(script.Parent.Landmarks)
local Parts = require(script.Parent.Parent.Parts)
local Props = require(script.Parent.Props)
local Style = require(script.Parent.Style)
local Voxel = require(script.Parent.Voxel)

export type Reservation = {
	Position: Vector3,
	Radius: number,
}

type Layout = {
	Position: Vector3,
	Theme: number,
	Title: string,
}

local Drift = {}

local radius = 120

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local layouts: { Layout } = {
	{ Position = Vector3.new(-1700, 240, -1700), Theme = 1, Title = "Meadow Ring" },
	{ Position = Vector3.new(-1300, 320, 1800), Theme = 2, Title = "Dune Loop" },
	{ Position = Vector3.new(-800, 200, -2200), Theme = 3, Title = "Frost Circuit" },
	{ Position = Vector3.new(-300, 380, 2300), Theme = 4, Title = "Lava Pit" },
	{ Position = Vector3.new(200, 260, -1650), Theme = 5, Title = "Candy Bowl" },
	{ Position = Vector3.new(700, 300, 1650), Theme = 6, Title = "Moon Crater" },
	{ Position = Vector3.new(1200, 420, -2250), Theme = 7, Title = "Star Deck" },
	{ Position = Vector3.new(1700, 240, 2100), Theme = 8, Title = "Nebula Ring" },
	{ Position = Vector3.new(2200, 340, -1700), Theme = 1, Title = "Sky Garden" },
	{ Position = Vector3.new(2700, 280, 1700), Theme = 2, Title = "Sand Spiral" },
	{ Position = Vector3.new(3200, 400, -2200), Theme = 3, Title = "Glacier Bowl" },
	{ Position = Vector3.new(3700, 220, 2300), Theme = 4, Title = "Magma Ring" },
	{ Position = Vector3.new(4200, 320, -1600), Theme = 5, Title = "Sugar Rush" },
}

local function obstacle(parent: Instance, name: string, position: Vector3, size: number): Model
	local model = Voxel.Model(parent, name)
	model:SetAttribute("Radius", size)
	model:SetAttribute("X", position.X)
	model:SetAttribute("Z", position.Z)
	return model
end

local function tires(parent: Instance, at: Vector3)
	local model = obstacle(parent, "Tires", at, 2.4)
	for level = 0, 2 do
		Voxel.Cylinder(
			model,
			4.4,
			1.4,
			CFrame.new(at + Vector3.new(0, 0.7 + level * 1.4, 0)),
			if level == 1 then rgb(235, 60, 60) else rgb(28, 28, 32),
			Enum.Material.Rubber
		)
	end
end

local function cone(parent: Instance, at: Vector3)
	local model = obstacle(parent, "Cone", at, 1.3)
	Voxel.Box(model, Vector3.new(1.4, 2.6, 1.4), CFrame.new(at + Vector3.new(0, 1.3, 0)), rgb(255, 120, 30))
	Voxel.Box(
		model,
		Vector3.new(1.46, 0.6, 1.46),
		CFrame.new(at + Vector3.new(0, 1.5, 0)),
		rgb(250, 250, 250)
	)
end

local function barrier(parent: Instance, frame: CFrame)
	for _, offset in { -2.4, 2.4 } do
		local position = (frame * CFrame.new(offset, 0, 0)).Position
		local model = obstacle(parent, "Barrier", position, 1.8)
		Voxel.Box(
			model,
			Vector3.new(4.8, 2.6, 2),
			CFrame.new(position + Vector3.new(0, 1.3, 0)) * (frame - frame.Position),
			rgb(236, 236, 240),
			Enum.Material.Concrete
		)
		Voxel.Box(
			model,
			Vector3.new(4.82, 0.6, 2.04),
			CFrame.new(position + Vector3.new(0, 1.9, 0)) * (frame - frame.Position),
			if offset < 0 then rgb(230, 40, 40) else rgb(250, 250, 250)
		)
	end
end

local function centerpiece(parent: Instance, theme: number, at: Vector3, rng: Random)
	local model = obstacle(parent, "Centerpiece", at, 12)
	local palette = Style[theme]
	Voxel.Round(model, CFrame.new(at + Vector3.new(0, 1, 0)), 10, 2, palette.Rock, palette.RockMaterial, true)
	Voxel.Round(
		model,
		CFrame.new(at + Vector3.new(0, 2.2, 0)),
		9,
		0.6,
		palette.Top,
		palette.TopMaterial,
		true
	)
	local top = at + Vector3.new(0, 2.5, 0)
	if theme == 1 then
		Props.Tree(model, top, rng, 1.4)
	elseif theme == 2 then
		Landmarks.Obelisk(model, top, 20)
	elseif theme == 3 then
		Props.IceSpike(model, top, rng, 1.4)
	elseif theme == 4 then
		Landmarks.Volcano(model, top, 16, 14, rng)
	elseif theme == 5 then
		Props.Lollipop(model, top, rng, 1.8)
	elseif theme == 6 then
		Props.Antenna(model, top, rng)
	elseif theme == 7 then
		Props.Pylon(model, top, rng)
	else
		Props.Crystal(model, top, rng, 1.6)
	end
end

local function sign(parent: Instance, decor: Instance, frame: CFrame, title: string, accent: Color3)
	for _, offset in { -14, 14 } do
		local post = frame * CFrame.new(offset, 0, 0)
		local model = obstacle(parent, "SignPost", post.Position, 1.6)
		Voxel.Box(
			model,
			Vector3.new(1.6, 22, 1.6),
			post * CFrame.new(0, 11, 0),
			rgb(40, 42, 52),
			Enum.Material.Metal
		)
	end
	local board = Parts.Make(decor, Vector3.new(32, 7, 1), frame * CFrame.new(0, 24, 0), rgb(24, 26, 52), {
		Name = "DriftSign",
	})
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Sign"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 12
		gui.LightInfluence = 0
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.LuckiestGuy
		label.Text = `🏁 {string.upper(title)} 🏁`
		label.TextColor3 = rgb(255, 255, 255)
		label.TextScaled = true
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = rgb(20, 20, 40)
		label.Parent = gui
	end
	for _, y in { -1, 1 } do
		Voxel.Neon(decor, Vector3.new(32.4, 0.8, 1.2), frame * CFrame.new(0, 24 + y * 3.9, 0), accent)
	end
end

local function arena(parent: Instance, index: number, layout: Layout): Model
	local rng = Random.new(9000 + index)
	local palette = Style[layout.Theme]
	local model = Voxel.Model(parent, `DriftIsland{index}`)
	local island = Voxel.Island(model, layout.Position, radius, palette, rng, nil, true)
	local center = island.CFrame
	local ground = layout.Position.Y + 0.3
	model:SetAttribute(
		"Center",
		CFrame.new(layout.Position.X, ground, layout.Position.Z) * (center - center.Position)
	)
	model:SetAttribute("Radius", radius)
	model:SetAttribute("Ground", ground)
	model:SetAttribute("Theme", layout.Theme)
	model:SetAttribute("Title", layout.Title)
	local surface = CFrame.new(layout.Position.X, ground, layout.Position.Z) * (center - center.Position)
	Voxel.Round(
		model,
		surface * CFrame.new(0, -0.15, 0),
		radius * 0.86,
		0.3,
		rgb(46, 48, 56),
		Enum.Material.Asphalt,
		true
	)
	local flat = surface * CFrame.new(0, 0.05, 0) * CFrame.Angles(math.pi / 2, 0, 0)
	Voxel.Ring(model, flat, radius * 0.52, 1.2, 0.1, 12, rgb(245, 245, 250), Enum.Material.SmoothPlastic)
	for step = 0, 11 do
		local angle = step * math.pi / 6
		Voxel.Box(
			model,
			Vector3.new(radius * 0.86 * 2 * math.sin(math.pi / 12) + 0.4, 0.5, 2.2),
			surface * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.1, -radius * 0.83),
			if step % 2 == 0 then rgb(230, 40, 40) else rgb(250, 250, 250)
		)
	end
	for row = 0, 1 do
		for column = 0, 3 do
			Voxel.Box(
				model,
				Vector3.new(2.5, 0.12, 2.5),
				surface * CFrame.new(-radius * 0.52 + (column - 1.5) * 2.5, 0.06, (row - 0.5) * 2.5),
				if (row + column) % 2 == 0 then rgb(250, 250, 250) else rgb(20, 20, 24)
			)
		end
	end
	local obstacles = Voxel.Model(model, "Obstacles")
	centerpiece(obstacles, layout.Theme, surface.Position, rng)
	for step = 0, 3 do
		local angle = math.pi / 4 + step * math.pi / 2
		tires(obstacles, (surface * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius * 0.28)).Position)
	end
	for step = 0, 7 do
		local angle = step * math.pi / 4 + math.pi / 8
		local spot = surface * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius * 0.74)
		if step % 2 == 0 then
			for offset = -1, 1 do
				cone(obstacles, (spot * CFrame.new(offset * 5, 0, 0)).Position)
			end
		else
			barrier(obstacles, spot)
		end
	end
	for step = 0, 3 do
		local angle = step * math.pi / 2 + math.pi / 4
		local spot = (surface * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius * 0.93)).Position
		local holder = obstacle(obstacles, "Prop", spot, 5)
		Props.Place(layout.Theme, holder, spot, rng)
	end
	for _, angle in { 0, math.pi } do
		local spot = (surface * CFrame.Angles(0, angle + math.pi / 2, 0) * CFrame.new(0, 0, -radius * 0.95)).Position
		local pole = obstacle(obstacles, "Light", spot, 1.4)
		Voxel.Box(
			pole,
			Vector3.new(1.2, 26, 1.2),
			CFrame.new(spot + Vector3.new(0, 13, 0)),
			rgb(50, 52, 62),
			Enum.Material.Metal
		)
		Voxel.Neon(
			pole,
			Vector3.new(4, 1.4, 4),
			CFrame.new(spot + Vector3.new(0, 26.5, 0)),
			rgb(255, 250, 225)
		)
	end
	sign(obstacles, model, surface * CFrame.new(0, 0, radius * 0.95), layout.Title, palette.Trim)
	return model
end

function Drift.Build(root: Instance): { Reservation }
	local folder = Voxel.Model(root, "DriftIslands")
	local reservations: { Reservation } = {}
	for index, layout in layouts do
		arena(folder, index, layout)
		table.insert(reservations, { Position = layout.Position, Radius = radius })
	end
	return reservations
end

return Drift
