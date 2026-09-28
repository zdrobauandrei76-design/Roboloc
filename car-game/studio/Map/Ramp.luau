--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrackConfig = require(ReplicatedStorage.Config.Track)
local Track = require(ReplicatedStorage.Game.Track)
local Parts = require(script.Parent.Parent.Parts)
local Voxel = require(script.Parent.Voxel)

local Ramp = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local laneSpan = Track.LaneCount * Track.LaneWidth
local halfSpan = laneSpan / 2
local asphalt = rgb(44, 46, 54)
local steel = rgb(206, 44, 40)
local steelDark = rgb(150, 30, 30)
local hazard = rgb(255, 204, 40)
local black = rgb(28, 28, 32)
local white = rgb(240, 240, 245)

local function beam(parent: Instance, from: Vector3, to: Vector3, width: number, color: Color3)
	local length = (to - from).Magnitude
	if length < 0.5 then
		return
	end
	Voxel.Box(
		parent,
		Vector3.new(width, width, length + width * 0.5),
		CFrame.lookAt((from + to) / 2, to),
		color,
		Enum.Material.Metal
	)
end

local function tower(parent: Instance, base: Vector3, width: number, height: number, lights: boolean)
	local half = width / 2
	for _, corner in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		Voxel.Box(
			parent,
			Vector3.new(2.4, height, 2.4),
			CFrame.new(base + Vector3.new(corner[1] * half, height / 2, corner[2] * half)),
			steel,
			Enum.Material.Metal
		)
	end
	local levels = math.max(2, math.floor(height / 32))
	for level = 0, levels do
		local y = level * height / levels
		for _, side in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local size = if side[1] ~= 0 then Vector3.new(1.6, 1.6, width) else Vector3.new(width, 1.6, 1.6)
			Voxel.Box(
				parent,
				size,
				CFrame.new(base + Vector3.new(side[1] * half, y, side[2] * half)),
				steelDark,
				Enum.Material.Metal
			)
		end
		if level < levels then
			local nextY = (level + 1) * height / levels
			for _, side in { -1, 1 } do
				beam(
					parent,
					base + Vector3.new(-half, y, side * half),
					base + Vector3.new(half, nextY, side * half),
					1.2,
					steel
				)
				beam(
					parent,
					base + Vector3.new(side * half, y, -half),
					base + Vector3.new(side * half, nextY, half),
					1.2,
					steel
				)
			end
		end
	end
	if lights then
		Voxel.Box(
			parent,
			Vector3.new(width + 3, 2, width + 3),
			CFrame.new(base + Vector3.new(0, height + 1, 0)),
			black
		)
		for _, corner in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
			Voxel.Neon(
				parent,
				Vector3.one * 2.2,
				CFrame.new(base + Vector3.new(corner[1] * half, height + 3, corner[2] * half)),
				rgb(255, 60, 50)
			)
		end
		Voxel.Box(
			parent,
			Vector3.new(0.6, 16, 0.6),
			CFrame.new(base + Vector3.new(0, height + 10, 0)),
			white,
			Enum.Material.Metal
		)
		Voxel.Box(parent, Vector3.new(0.3, 5, 9), CFrame.new(base + Vector3.new(0, height + 15, 4.6)), black)
		for row = 0, 1 do
			for column = 0, 2 do
				if (row + column) % 2 == 0 then
					Voxel.Box(
						parent,
						Vector3.new(0.35, 2.5, 3),
						CFrame.new(base + Vector3.new(0, height + 13.75 + row * 2.5, 1.6 + column * 3)),
						white
					)
				end
			end
		end
	end
end

local function sign(parent: Instance, cframe: CFrame, size: Vector3, text: string, color: Color3)
	local board = Parts.Make(parent, size, cframe, rgb(24, 28, 56), { Name = "Billboard" })
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
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
		label.Text = text
		label.TextColor3 = color
		label.TextScaled = true
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = rgb(20, 20, 40)
		label.Parent = gui
	end
	local trim = rgb(255, 204, 40)
	Voxel.Neon(
		parent,
		Vector3.new(size.X + 0.4, 1, size.Z + 1),
		cframe * CFrame.new(0, size.Y / 2 + 0.5, 0),
		trim
	)
	Voxel.Neon(
		parent,
		Vector3.new(size.X + 0.4, 1, size.Z + 1),
		cframe * CFrame.new(0, -size.Y / 2 - 0.5, 0),
		trim
	)
end

local function chevron(parent: Instance, frame: CFrame)
	local reach, spread = 11, 17
	local length = math.sqrt(reach * reach + spread * spread)
	local angle = math.atan2(spread, reach)
	for _, side in { -1, 1 } do
		Voxel.Box(
			parent,
			Vector3.new(length, 0.25, 3.4),
			frame * CFrame.new(-reach / 2, 0, side * spread / 2) * CFrame.Angles(0, side * angle, 0),
			hazard
		)
	end
end

local function deck(model: Instance)
	local height = TrackConfig.DeckHeight
	local deckStart = TrackConfig.DeckStartX
	local deckEnd = TrackConfig.RampPoints[1].X
	local length = deckEnd - deckStart
	local center = deckStart + length / 2
	Parts.Make(
		model,
		Vector3.new(length, 8, laneSpan + 40),
		CFrame.new(center, height - 4, 0),
		asphalt,
		{ Collide = true, Name = "Floor", Material = Enum.Material.Asphalt }
	)
	for lane = 1, Track.LaneCount - 1 do
		local z = (lane - Track.LaneCount / 2) * Track.LaneWidth
		Voxel.Box(model, Vector3.new(length, 0.2, 0.7), CFrame.new(center, height + 0.1, z), white)
	end
	for _, side in { -1, 1 } do
		Voxel.Box(
			model,
			Vector3.new(length, 0.22, 1.4),
			CFrame.new(center, height + 0.11, side * (halfSpan - 0.7)),
			white
		)
		local stripes = math.floor(length / 10)
		for index = 0, stripes - 1 do
			Voxel.Box(
				model,
				Vector3.new(10, 0.24, 18),
				CFrame.new(deckStart + (index + 0.5) * 10, height + 0.12, side * (halfSpan + 10)),
				if index % 2 == 0 then hazard else black
			)
		end
	end
	for _, x in { deckEnd - 26, deckEnd - 8 } do
		for lane = 1, Track.LaneCount do
			chevron(model, CFrame.new(x, height + 0.14, Track.LaneZ(lane)))
		end
	end
	local startLine = TrackConfig.StartX + 11
	Parts.Make(model, Vector3.new(8, 0.22, laneSpan), CFrame.new(startLine, height + 0.11, 0), white, {
		Name = "StartLine",
	})
	local square = 4
	for row = 0, 1 do
		for index = 0, math.floor(laneSpan / square) - 1 do
			if (index + row) % 2 == 0 then
				Parts.Make(
					model,
					Vector3.new(square, 0.24, square),
					CFrame.new(
						startLine - square / 2 + row * square,
						height + 0.12,
						-halfSpan + square / 2 + index * square
					),
					black,
					{ Name = "Checker" }
				)
			end
		end
	end
	Parts.Make(
		model,
		Vector3.new(4, 16, laneSpan + 40),
		CFrame.new(deckStart - 2, height + 4, 0),
		steel,
		{ Collide = true, Name = "BackWall", Material = Enum.Material.Metal }
	)
	Voxel.Neon(
		model,
		Vector3.new(4.4, 1.2, laneSpan + 40),
		CFrame.new(deckStart - 2, height + 12.6, 0),
		hazard
	)
	for _, side in { -1, 1 } do
		Parts.Make(
			model,
			Vector3.new(length, 7, 3),
			CFrame.new(center, height + 3.5, side * (halfSpan + 20)),
			steel,
			{ Collide = true, Name = "Rail", Material = Enum.Material.Metal }
		)
		Voxel.Box(
			model,
			Vector3.new(length, 1, 3.6),
			CFrame.new(center, height + 7.5, side * (halfSpan + 20)),
			white,
			Enum.Material.Metal
		)
		for _, x in { deckStart + 10, deckEnd - 10 } do
			tower(model, Vector3.new(x, 0, side * (halfSpan + 10)), 14, height - 8, false)
		end
		tower(model, Vector3.new(deckEnd - 6, height, side * (halfSpan + 32)), 12, 70, true)
		tower(model, Vector3.new(deckStart + 14, height, side * (halfSpan + 32)), 10, 44, true)
		for _, x in { deckStart + 40, deckEnd - 40 } do
			local pole = Vector3.new(x, height, side * (halfSpan + 24))
			Voxel.Box(
				model,
				Vector3.new(1.4, 26, 1.4),
				CFrame.new(pole + Vector3.new(0, 13, 0)),
				rgb(60, 62, 72),
				Enum.Material.Metal
			)
			Voxel.Box(model, Vector3.new(4, 3, 8), CFrame.new(pole + Vector3.new(0, 27, -side * 2)), black)
			Voxel.Neon(
				model,
				Vector3.new(4.2, 2.2, 7),
				CFrame.new(pole + Vector3.new(0, 27, -side * 4.2)),
				rgb(255, 250, 225)
			)
		end
	end
	local gantryHeight = height + 64
	Voxel.Box(
		model,
		Vector3.new(6, 6, laneSpan + 76),
		CFrame.new(deckEnd - 6, gantryHeight + 6, 0),
		steel,
		Enum.Material.Metal
	)
	sign(
		model,
		CFrame.new(deckEnd - 6, gantryHeight + 22, 0),
		Vector3.new(3, 22, 150),
		"MOTOBLOC",
		rgb(255, 214, 60)
	)
	for index = -3, 3 do
		Voxel.Neon(
			model,
			Vector3.new(6.4, 2, 6),
			CFrame.new(deckEnd - 6, gantryHeight + 2, index * 44),
			if index % 2 == 0 then rgb(90, 230, 110) else rgb(255, 214, 60)
		)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(16, 1, 60)
	spawn.CFrame = CFrame.new(deckStart + 12, height + 0.5, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = rgb(90, 225, 100)
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = model
end

local function surface(model: Instance)
	local length = Track.RampLength()
	local start = TrackConfig.RampPoints[1].X - TrackConfig.StartX
	local segments = TrackConfig.RampSegments
	local bents: { { X: number, Top: number } } = {}
	for index = 0, segments - 1 do
		local a = Track.RampPoint(start + (length - start) * index / segments)
		local b = Track.RampPoint(start + (length - start) * (index + 1) / segments)
		local delta = b - a
		local angle = math.atan2(delta.Y, delta.X)
		local middle = (a + b) / 2
		local span = delta.Magnitude + 0.6
		local frame = CFrame.new(middle.X, middle.Y, 0) * CFrame.Angles(0, 0, angle)
		Parts.Make(model, Vector3.new(span, 4, laneSpan), frame * CFrame.new(0, -2, 0), asphalt, {
			Name = "Surface",
			Material = Enum.Material.Asphalt,
		})
		if index % 2 == 0 then
			for lane = 1, Track.LaneCount - 1 do
				local z = (lane - Track.LaneCount / 2) * Track.LaneWidth
				Voxel.Box(model, Vector3.new(span * 0.62, 0.2, 0.8), frame * CFrame.new(0, 0.1, z), white)
			end
		end
		for _, side in { -1, 1 } do
			Voxel.Box(
				model,
				Vector3.new(span, 0.24, 12),
				frame * CFrame.new(0, 0.12, side * (halfSpan - 6)),
				if index % 2 == 0 then hazard else black
			)
			Voxel.Box(
				model,
				Vector3.new(span, 8, 3),
				frame * CFrame.new(0, 2, side * (halfSpan + 1.5)),
				steel,
				Enum.Material.Metal
			)
			Voxel.Box(
				model,
				Vector3.new(span, 1, 3.6),
				frame * CFrame.new(0, 6.5, side * (halfSpan + 1.5)),
				white,
				Enum.Material.Metal
			)
		end
		if index % 4 == 2 then
			for lane = 1, Track.LaneCount do
				chevron(model, frame * CFrame.new(span * 0.2, 0.14, Track.LaneZ(lane)))
			end
		end
		if index % 4 == 1 and middle.Y > 14 then
			table.insert(bents, { X = middle.X, Top = middle.Y - 4.5 })
		end
	end
	local columns = { -halfSpan + 4, -halfSpan / 2, 0, halfSpan / 2, halfSpan - 4 }
	for bentIndex, bent in bents do
		for _, z in columns do
			Voxel.Box(
				model,
				Vector3.new(5, bent.Top, 5),
				CFrame.new(bent.X, bent.Top / 2, z),
				steel,
				Enum.Material.Metal
			)
		end
		Voxel.Box(
			model,
			Vector3.new(4, 3.4, laneSpan),
			CFrame.new(bent.X, bent.Top - 1.7, 0),
			steelDark,
			Enum.Material.Metal
		)
		local levels = math.floor(bent.Top / 45)
		for level = 1, levels do
			Voxel.Box(
				model,
				Vector3.new(2.4, 2.4, laneSpan - 6),
				CFrame.new(bent.X, level * 45 - 10, 0),
				steelDark,
				Enum.Material.Metal
			)
		end
		local following = bents[bentIndex + 1]
		if following then
			local low = math.min(bent.Top, following.Top)
			local steps = math.max(1, math.floor(low / 45))
			for step = 0, steps - 1 do
				local y0 = step * low / steps
				local y1 = (step + 1) * low / steps
				for _, z in { -halfSpan + 4, halfSpan - 4 } do
					beam(model, Vector3.new(bent.X, y0, z), Vector3.new(following.X, y1, z), 1.6, steel)
					beam(model, Vector3.new(bent.X, y1, z), Vector3.new(following.X, y0, z), 1.6, steel)
				end
			end
		end
	end
	local lip = Track.LipHeight
	Parts.Make(model, Vector3.new(3, lip - 2, laneSpan + 6), CFrame.new(-2, (lip - 2) / 2, 0), steel, {
		Name = "Kicker",
		Material = Enum.Material.Metal,
	})
	local stripes = 12
	for index = 0, stripes - 1 do
		Voxel.Box(
			model,
			Vector3.new(0.6, 5, laneSpan / stripes),
			CFrame.new(-0.3, lip - 6, -halfSpan + (index + 0.5) * laneSpan / stripes),
			if index % 2 == 0 then hazard else black
		)
	end
end

local function lipArch(model: Instance)
	for _, side in { -1, 1 } do
		tower(model, Vector3.new(-30, 0, side * (halfSpan + 26)), 16, 150, true)
	end
	Voxel.Box(model, Vector3.new(8, 8, laneSpan + 86), CFrame.new(-30, 154, 0), steel, Enum.Material.Metal)
	sign(model, CFrame.new(-30, 172, 0), Vector3.new(3, 26, 190), "🚀 MEGA RAMP 🚀", rgb(255, 255, 255))
end

local function billboard(model: Instance)
	local height = 70
	local frame = CFrame.new(-330, 0, halfSpan + 120) * CFrame.Angles(0, math.rad(-25), 0)
	for _, offset in { -40, 40 } do
		tower(model, frame * Vector3.new(0, 0, offset), 6, height, false)
	end
	sign(model, frame * CFrame.new(0, height + 22, 0), Vector3.new(3, 40, 120), "MOTOBLOC", rgb(255, 214, 60))
end

function Ramp.Build(root: Instance)
	local model = Voxel.Model(root, "Ramp")
	deck(Voxel.Model(model, "Deck"))
	surface(Voxel.Model(model, "Track"))
	lipArch(Voxel.Model(model, "Arch"))
	billboard(Voxel.Model(model, "Billboard"))
end

return Ramp
