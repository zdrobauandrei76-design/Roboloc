--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrackConfig = require(ReplicatedStorage.Config.Track)
local Zones = require(ReplicatedStorage.Config.Zones)
local Stats = require(ReplicatedStorage.Game.Stats)
local Track = require(ReplicatedStorage.Game.Track)
local Parts = require(script.Parent.Parent.Parts)
local Style = require(script.Parent.Style)
local Voxel = require(script.Parent.Voxel)

type Detail = {
	Chunk: number,
	Edge: number,
	Falls: number,
}

local Land = {}

local half = TrackConfig.GroundWidth / 2
local laneHalf = Track.LaneCount * Track.LaneWidth / 2
local bridgeHalf = laneHalf + 40
local gap = 90
local seaLevel = -380

local function detail(index: number): Detail
	if index <= 3 then
		return { Chunk = 180, Edge = 45, Falls = 380 }
	elseif index <= 5 then
		return { Chunk = 280, Edge = 90, Falls = 620 }
	end
	return { Chunk = 560, Edge = 320, Falls = 2600 }
end

function Land.Range(index: number): (number, number)
	local startX = if index == 1 then -1000 else Zones[index].Start
	local endX = if index == #Zones then Track.WorldLength + 800 else Stats.ZoneEnd(index)
	return startX, endX
end

local function slab(model: Instance, x0: number, x1: number, width: number, index: number, rng: Random)
	local zone = Zones[index]
	local palette = Style[index]
	local settings = detail(index)
	local night = palette.Sea == "None"
	local x = x0
	while x < x1 - 0.01 do
		local span = math.min(2048, x1 - x)
		local center = x + span / 2
		Parts.Make(model, Vector3.new(span, 4, width * 2), CFrame.new(center, -2, 0), zone.GroundColor, {
			Material = zone.Material,
			Collide = true,
			Name = zone.Name,
		})
		Parts.Make(model, Vector3.new(span, 20, width * 2 - 2), CFrame.new(center, -14, 0), palette.Soil, {
			Material = palette.SoilMaterial,
			Collide = true,
			Name = "Soil",
		})
		for _, side in { -1, 1 } do
			local edge = side * (laneHalf + 16)
			if index == 1 then
				Voxel.Box(
					model,
					Vector3.new(span, 3, 7),
					CFrame.new(center, 1.5, edge),
					Color3.fromRGB(52, 138, 52),
					Enum.Material.LeafyGrass
				)
			elseif index == 2 then
				Voxel.Box(
					model,
					Vector3.new(span, 1.6, 8),
					CFrame.new(center, 0.8, edge),
					Color3.fromRGB(206, 150, 88),
					Enum.Material.Sandstone
				)
			elseif index == 3 then
				Voxel.Box(
					model,
					Vector3.new(span, 0.5, 12),
					CFrame.new(center, 0.25, edge),
					Color3.fromRGB(150, 210, 245),
					Enum.Material.Glacier
				)
			elseif index == 4 then
				Voxel.Box(
					model,
					Vector3.new(span, 1.4, 16),
					CFrame.new(center, 0.3, edge),
					Color3.fromRGB(40, 30, 30),
					Enum.Material.Basalt
				)
				Voxel.Neon(
					model,
					Vector3.new(span, 1.5, 9),
					CFrame.new(center, 0.4, edge),
					Color3.fromRGB(255, 110, 30)
				)
			elseif index == 5 then
				Voxel.Box(
					model,
					Vector3.new(span, 1.8, 6),
					CFrame.new(center, 0.9, edge),
					Color3.fromRGB(255, 250, 252)
				)
				Voxel.Box(
					model,
					Vector3.new(span, 2, 2.4),
					CFrame.new(center, 1, edge),
					Color3.fromRGB(255, 90, 150)
				)
			end
			Parts.Make(
				model,
				Vector3.new(span, 0.2, 2),
				CFrame.new(center, 0.1, side * (laneHalf + 3)),
				if night then palette.Trim else Color3.fromRGB(250, 250, 250),
				{
					Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic,
					Name = "RunwayLine",
				}
			)
			if night then
				Voxel.Neon(
					model,
					Vector3.new(span, 1.2, 1.2),
					CFrame.new(center, -1, side * (width + 0.4)),
					palette.Trim
				)
			end
		end
		x += span
	end
	x = x0
	while x < x1 - 1 do
		local span = math.min(settings.Chunk * rng:NextNumber(0.8, 1.2), x1 - x)
		local center = x + span / 2
		local y = -24
		local layerWidth = width * 2
		for layer = 1, 4 do
			layerWidth *= rng:NextNumber(0.6, 0.78)
			local height = rng:NextNumber(30, 60) * (if width < 300 then 0.6 else 1)
			local odd = layer % 2 == 1
			Voxel.Box(
				model,
				Vector3.new(span * rng:NextNumber(0.86, 1.02), height, layerWidth),
				CFrame.new(center, y - height / 2, rng:NextNumber(-0.08, 0.08) * width),
				if odd then palette.Rock else palette.Deep,
				if odd then palette.RockMaterial else palette.DeepMaterial
			)
			y -= height
		end
		x += span
	end
	for _, side in { -1, 1 } do
		x = x0
		while x < x1 - 1 do
			local span = math.min(settings.Edge * rng:NextNumber(0.7, 1.3), x1 - x)
			local depth = rng:NextNumber(8, 22)
			local drop = rng:NextNumber(14, 44)
			Voxel.Box(
				model,
				Vector3.new(span, drop, depth),
				CFrame.new(
					x + span / 2,
					-4 - drop / 2 - rng:NextNumber(0, 6),
					side * (width + depth * 0.3 - 4)
				),
				palette.Soil,
				palette.SoilMaterial
			)
			if rng:NextNumber() < 0.5 then
				local lip = rng:NextNumber(3, 8)
				Voxel.Box(
					model,
					Vector3.new(span * rng:NextNumber(0.5, 0.9), 3, lip * 2),
					CFrame.new(x + span / 2, -1.5 - rng:NextNumber(0.05, 1), side * (width + lip - 2)),
					zone.GroundColor,
					zone.Material
				)
			end
			if rng:NextNumber() < 0.35 then
				local size = rng:NextNumber(6, 14)
				Voxel.Box(
					model,
					Vector3.new(size, size * rng:NextNumber(1.5, 3), size),
					CFrame.new(x + span / 2, -30 - size, side * (width - size)),
					palette.Rock,
					palette.RockMaterial
				)
			end
			x += span
		end
	end
end

local function falls(model: Instance, x0: number, x1: number, index: number, rng: Random)
	local palette = Style[index]
	local settings = detail(index)
	local count = math.floor((x1 - x0) / settings.Falls)
	for step = 1, count do
		local x = x0 + (step - rng:NextNumber(0.25, 0.75)) * settings.Falls
		local side = if step % 2 == 0 then 1 else -1
		local edge = CFrame.new(x, 0, side * half) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0)
		Voxel.Fall(
			model,
			edge,
			rng:NextNumber(14, 26),
			rng:NextNumber(180, 300),
			rng:NextNumber(40, 110),
			palette.Fall,
			palette.FallMaterial
		)
	end
end

function Land.Build(root: Instance)
	local model = Voxel.Model(root, "Land")
	local rng = Random.new(56000)
	for index in Zones do
		local zoneModel = Voxel.Model(model, Zones[index].Name)
		local startX, endX = Land.Range(index)
		local landStart = if index == 1 then startX else startX + gap
		local landEnd = if index == #Zones then endX else endX - gap
		slab(zoneModel, landStart, landEnd, half, index, rng)
		falls(zoneModel, landStart + 60, landEnd - 60, index, rng)
		if index < #Zones then
			slab(zoneModel, landEnd, endX, bridgeHalf, index, rng)
			slab(zoneModel, endX, endX + gap, bridgeHalf, index + 1, rng)
		end
	end
end

local function tiles(
	model: Instance,
	x0: number,
	x1: number,
	y: number,
	thickness: number,
	color: Color3,
	material: Enum.Material,
	transparency: number?
)
	local x = x0
	while x < x1 - 1 do
		local span = math.min(2048, x1 - x)
		for z = -1, 1 do
			Voxel.Box(
				model,
				Vector3.new(span, thickness, 2048),
				CFrame.new(x + span / 2, y, z * 2048),
				color,
				material,
				transparency
			)
		end
		x += span
	end
end

function Land.Sea(root: Instance)
	local model = Voxel.Model(root, "Sea")
	local rng = Random.new(380)
	for index in Zones do
		local palette = Style[index]
		local startX, endX = Land.Range(index)
		if palette.Sea == "Clouds" or palette.Sea == "Candy" then
			local candy = palette.Sea == "Candy"
			local floor = if candy then Color3.fromRGB(236, 214, 255) else Color3.fromRGB(196, 224, 255)
			local puffs = if candy
				then {
					Color3.fromRGB(255, 196, 232),
					Color3.fromRGB(200, 230, 255),
					Color3.fromRGB(255, 255, 255),
				}
				else { Color3.fromRGB(255, 255, 255), Color3.fromRGB(246, 250, 255) }
			tiles(model, startX - 300, endX + 300, seaLevel - 15, 30, floor, Enum.Material.SmoothPlastic, 0.2)
			local x = startX
			while x < endX do
				for _ = 1, 4 do
					local z = rng:NextNumber(-3000, 3000)
					if math.abs(z) > half - 60 then
						Voxel.Cloud(
							model,
							Vector3.new(x + rng:NextNumber(-100, 100), seaLevel + 20, z),
							rng:NextNumber(80, 170),
							rng,
							Voxel.Pick(rng, puffs)
						)
					end
				end
				x += if candy then 360 else 280
			end
		elseif palette.Sea == "Lava" then
			tiles(
				model,
				startX - 300,
				endX + 300,
				seaLevel - 10,
				20,
				Color3.fromRGB(150, 50, 20),
				Enum.Material.CrackedLava
			)
			local x = startX
			while x < endX do
				local z = rng:NextNumber(-2600, 2600)
				Voxel.Neon(
					model,
					Vector3.new(rng:NextNumber(300, 700), 1, rng:NextNumber(12, 40)),
					CFrame.new(x, seaLevel + 0.6, z) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0),
					Color3.fromRGB(255, 120, 30)
				)
				if math.abs(z) > half + 100 then
					local height = rng:NextNumber(80, 260)
					Voxel.Box(
						model,
						Vector3.new(rng:NextNumber(30, 70), height, rng:NextNumber(30, 70)),
						CFrame.new(x + 60, seaLevel + height / 2, z)
							* CFrame.Angles(0, rng:NextNumber(0, 3), 0),
						Color3.fromRGB(44, 34, 34),
						Enum.Material.Basalt
					)
				end
				x += 260
			end
		else
			for _ = 1, math.floor((endX - startX) / 220) do
				Voxel.Neon(
					model,
					Vector3.one * rng:NextNumber(1.5, 5),
					CFrame.new(
						rng:NextNumber(startX, endX),
						rng:NextNumber(-1400, 2600),
						rng:NextNumber(-3200, 3200)
					),
					Voxel.Pick(rng, { Color3.fromRGB(255, 255, 255), palette.Glow, palette.Trim })
				)
			end
		end
	end
end

return Land
