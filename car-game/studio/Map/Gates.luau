--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Zones = require(ReplicatedStorage.Config.Zones)
local Stats = require(ReplicatedStorage.Game.Stats)
local Track = require(ReplicatedStorage.Game.Track)
local Format = require(ReplicatedStorage.Utils.Format)
local Land = require(script.Parent.Land)
local Landmarks = require(script.Parent.Landmarks)
local Parts = require(script.Parent.Parent.Parts)
local Style = require(script.Parent.Style)
local Voxel = require(script.Parent.Voxel)

local Gates = {}

local laneHalf = Track.LaneCount * Track.LaneWidth / 2
local radius = laneHalf + 70

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function banner(parent: Instance, cframe: CFrame, size: Vector3, text: string, accent: Color3)
	local board = Parts.Make(parent, size, cframe, rgb(24, 26, 52), { Name = "Banner" })
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Sign"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 10
		gui.LightInfluence = 0
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.LuckiestGuy
		label.Text = text
		label.TextColor3 = rgb(255, 255, 255)
		label.TextScaled = true
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = rgb(20, 20, 40)
		label.Parent = gui
	end
	for _, y in { -1, 1 } do
		Voxel.Neon(
			parent,
			Vector3.new(size.X + 0.6, 1.4, size.Z + 1.4),
			cframe * CFrame.new(0, y * (size.Y / 2 + 0.7), 0),
			accent
		)
	end
end

local function portal(parent: Instance, x: number, accent: Color3, text: string)
	local model = Voxel.Model(parent, "Portal")
	local center = CFrame.new(x, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
	local from, to = -math.pi / 2, math.pi / 2
	Voxel.Ring(model, center, radius + 14, 12, 16, 16, rgb(34, 36, 64), Enum.Material.Metal, from, to)
	Voxel.Ring(model, center * CFrame.new(0, 0, -2), radius, 14, 12, 16, accent, Enum.Material.Neon, from, to)
	Voxel.Ring(
		model,
		center * CFrame.new(0, 0, -4),
		radius - 12,
		3,
		6,
		16,
		rgb(255, 255, 255),
		Enum.Material.Neon,
		from,
		to
	)
	for _, side in { -1, 1 } do
		Voxel.Box(
			model,
			Vector3.new(34, 18, 34),
			CFrame.new(x, 9, side * radius),
			rgb(34, 36, 64),
			Enum.Material.Metal
		)
		Voxel.Neon(model, Vector3.new(35, 2, 35), CFrame.new(x, 16, side * radius), accent)
	end
	banner(model, CFrame.new(x, radius + 44, 0), Vector3.new(4, 38, 230), text, accent)
end

local function markers(parent: Instance)
	local model = Voxel.Model(parent, "Markers")
	local distances: { number } = {}
	for distance = 100, 1000, 100 do
		table.insert(distances, distance)
	end
	for distance = 1500, 10000, 500 do
		table.insert(distances, distance)
	end
	for distance = 11000, Track.WorldLength - 1000, 1000 do
		table.insert(distances, distance)
	end
	for _, distance in distances do
		local accent = Zones[Stats.ZoneIndexAt(distance)].AccentColor
		Parts.Make(
			model,
			Vector3.new(2, 0.3, laneHalf * 2),
			CFrame.new(distance, 0.2, 0),
			rgb(255, 255, 255),
			{
				Material = Enum.Material.Neon,
				Transparency = 0.3,
			}
		)
		local post = CFrame.new(distance, 0, -(laneHalf + 22))
		Voxel.Box(
			model,
			Vector3.new(1.6, 12, 1.6),
			post * CFrame.new(0, 6, 0),
			rgb(230, 230, 236),
			Enum.Material.Metal
		)
		local board = Parts.Make(
			model,
			Vector3.new(1, 10, 32),
			post * CFrame.new(0, 16, 0),
			rgb(24, 26, 52),
			{ Name = "Board" }
		)
		Parts.Sign(board, Enum.NormalId.Left, Format.Distance(distance), rgb(255, 215, 70))
		Voxel.Neon(model, Vector3.new(1.2, 0.8, 32.4), post * CFrame.new(0, 21.4, 0), accent)
	end
end

local function speedway(parent: Instance)
	local model = Voxel.Model(parent, "Speedway")
	for index, palette in Style do
		if palette.Sea ~= "None" then
			continue
		end
		local startX, endX = Land.Range(index)
		local x = startX + 700
		while x < endX - 700 do
			local center = CFrame.new(x, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
			Voxel.Ring(
				model,
				center,
				laneHalf + 46,
				7,
				7,
				12,
				palette.Trim,
				Enum.Material.Neon,
				-math.pi / 2,
				math.pi / 2
			)
			x += 2000
		end
		if index > 6 then
			x = startX + 125
			while x < endX do
				Voxel.Neon(
					model,
					Vector3.new(1.2, 0.2, laneHalf * 2),
					CFrame.new(x, 0.12, 0),
					palette.Trim,
					0.35
				)
				x += 250
			end
		end
		x = startX + 150
		while x < endX do
			for _, side in { -1, 1 } do
				Voxel.Neon(
					model,
					Vector3.new(2.4, 1.6, 2.4),
					CFrame.new(x, 0.8, side * (laneHalf + 9)),
					palette.Glow
				)
			end
			x += 800
		end
	end
end

function Gates.Build(root: Instance)
	local model = Voxel.Model(root, "Gates")
	for index, zone in Zones do
		if index > 1 then
			portal(
				model,
				zone.Start,
				zone.AccentColor,
				`{zone.Emoji} {string.upper(zone.Name)}  {Format.Multiplier(zone.Multiplier)}`
			)
		end
	end
	local finish = Track.WorldLength
	Landmarks.BlackHole(
		model,
		CFrame.new(finish + 60, radius, 0) * CFrame.Angles(0, math.pi / 2, 0),
		radius * 0.9
	)
	portal(model, finish, Style[#Style].Trim, "🏁 YOU MADE IT! 🏁")
	markers(model)
	speedway(model)
end

return Gates
