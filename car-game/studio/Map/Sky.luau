--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Track = require(ReplicatedStorage.Game.Track)
local Land = require(script.Parent.Land)
local Voxel = require(script.Parent.Voxel)

local Sky = {}

local laneHalf = Track.LaneCount * Track.LaneWidth / 2

local tints = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 248, 235),
	Color3.fromRGB(245, 250, 255),
	Color3.fromRGB(150, 130, 130),
	Color3.fromRGB(255, 225, 240),
}

local counts = { 22, 18, 22, 16, 24 }

local function isClear(
	position: Vector3,
	size: number,
	reserved: { { Position: Vector3, Radius: number } }
): boolean
	for _, reservation in reserved do
		local flat = Vector3.new(position.X - reservation.Position.X, 0, position.Z - reservation.Position.Z)
		if
			flat.Magnitude < reservation.Radius + size * 2.5 + 60
			and math.abs(position.Y - reservation.Position.Y) < 180
		then
			return false
		end
	end
	return true
end

function Sky.Build(root: Instance, reserved: { { Position: Vector3, Radius: number } })
	local model = Voxel.Model(root, "Clouds")
	local rng = Random.new(707)
	for index, count in counts do
		local startX, endX = Land.Range(index)
		for _ = 1, count do
			local size = rng:NextNumber(26, 60)
			local height = rng:NextNumber(160, if index <= 3 then 620 else 900)
			local z = rng:NextNumber(-2200, 2200)
			local clear = laneHalf + size * 2.5 + 420
			if math.abs(z) < clear then
				z = (if z < 0 then -1 else 1) * (clear + rng:NextNumber(0, 500))
			end
			local position = Vector3.new(rng:NextNumber(startX, endX), height, z)
			if isClear(position, size, reserved) then
				Voxel.Cloud(model, position, size, rng, tints[index])
			end
		end
	end
end

return Sky
