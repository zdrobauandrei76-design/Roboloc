--!strict

local TrackConfig = require(script.Parent.Parent.Config.Track)

local sampleCount = 240
local points = TrackConfig.RampPoints
local p0, p1, p2, p3 = points[1], points[2], points[3], points[4]

local Track = {}

Track.LaneCount = TrackConfig.LaneCount
Track.LaneWidth = TrackConfig.LaneWidth
Track.WorldLength = TrackConfig.WorldLength
Track.DeckHeight = TrackConfig.DeckHeight
Track.StartX = TrackConfig.StartX
Track.LipHeight = p3.Y
Track.LaunchAngle = math.atan2(p3.Y - p2.Y, p3.X - p2.X)

local pathPoints: { Vector2 } = {}
local pathLengths: { number } = {}
local totalLength = 0

local function bezier(t: number): Vector2
	local u = 1 - t
	return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t)
end

local function build()
	if #pathPoints > 0 then
		return
	end
	table.insert(pathPoints, Vector2.new(TrackConfig.StartX, TrackConfig.DeckHeight))
	table.insert(pathLengths, 0)
	local previous = pathPoints[1]
	for index = 0, sampleCount do
		local point = bezier(index / sampleCount)
		local length = (point - previous).Magnitude
		if length > 1e-6 then
			totalLength += length
			table.insert(pathPoints, point)
			table.insert(pathLengths, totalLength)
			previous = point
		end
	end
end

function Track.RampLength(): number
	build()
	return totalLength
end

function Track.RampPoint(distance: number): (Vector2, number)
	build()
	local along = math.clamp(distance, 0, totalLength)
	local low, high = 1, #pathLengths
	while high - low > 1 do
		local middle = (low + high) // 2
		if pathLengths[middle] <= along then
			low = middle
		else
			high = middle
		end
	end
	local a, b = pathPoints[low], pathPoints[high]
	local span = pathLengths[high] - pathLengths[low]
	local alpha = if span > 0 then (along - pathLengths[low]) / span else 0
	local delta = b - a
	return a:Lerp(b, alpha), math.atan2(delta.Y, delta.X)
end

function Track.LaneZ(lane: number): number
	return (lane - (TrackConfig.LaneCount + 1) / 2) * TrackConfig.LaneWidth
end

function Track.WorldCFrame(lane: number, x: number, y: number, pitch: number): CFrame
	local angle = math.clamp(pitch, -1.35, 1.35)
	local position = Vector3.new(x, y, Track.LaneZ(lane))
	return CFrame.lookAt(position, position + Vector3.new(math.cos(angle), math.sin(angle), 0))
end

function Track.StartCFrame(lane: number): CFrame
	return Track.WorldCFrame(lane, TrackConfig.StartX, TrackConfig.DeckHeight, 0)
end

return Track
