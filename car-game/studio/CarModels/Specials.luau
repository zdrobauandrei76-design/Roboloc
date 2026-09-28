--!strict

local Kit = require(script.Parent.Kit)

export type Result = {
	Body: BasePart,
	Rear: number,
	Top: number,
	Exhaust: Vector3,
}

local Specials = {}

local function suspension(model: Model, from: Vector3, to: Vector3)
	Kit.Tube(model, from + Vector3.new(0, 0.35, 0), to + Vector3.new(0, 0.2, 0), 0.22, Kit.Trim, Kit.Matte())
	Kit.Tube(model, from - Vector3.new(0, 0.35, 0), to - Vector3.new(0, 0.2, 0), 0.22, Kit.Trim, Kit.Matte())
end

function Specials.Buggy(model: Model, color: Color3, accent: Color3): Result
	local radius, width = 1.75, 1.5
	local halfWidth = 2.9
	local wheelX = halfWidth + 1.05
	local frontZ, rearZ = -3.9, 3.9
	local low, belt = 1.1, 2.75
	local cockpit = 2.05
	local seatTop = belt - 1.1
	local body = Kit.Span(
		model,
		-(halfWidth - 0.2),
		halfWidth - 0.2,
		low,
		seatTop - 0.5,
		-4.6,
		4.6,
		Kit.Trim,
		Kit.Matte()
	)
	body.Name = "Body"
	Kit.Span(model, -halfWidth, halfWidth, low, belt, -4.4, -1.3, color, Kit.Paint())
	Kit.Ramp(model, -(halfWidth - 0.4), halfWidth - 0.4, low + 0.3, belt, -6.4, -4.4, color, Kit.Paint())
	Kit.Span(model, -(halfWidth - 0.4), halfWidth - 0.4, low, low + 0.3, -6.4, -4.4, Kit.Trim, Kit.Matte())
	Kit.Span(model, -halfWidth, halfWidth, low, belt - 0.2, 2.5, 4.9, color, Kit.Paint())
	for _, side in { -1, 1 } do
		Kit.Span(model, side * cockpit, side * halfWidth, low, belt, -1.3, 2.5, color, Kit.Paint())
		Kit.Span(
			model,
			side * (cockpit - 0.1),
			side * cockpit,
			seatTop - 0.5,
			belt - 0.02,
			-1.3,
			2.5,
			Kit.Interior,
			Kit.Matte()
		)
	end
	Kit.Seat(model, Vector3.new(0, seatTop, 1.0))
	Kit.SteeringWheel(model, Vector3.new(0, belt + 0.1, -0.9))
	Kit.Span(model, -cockpit, cockpit, belt - 0.5, belt + 0.05, -1.3, -0.6, Kit.Trim, Kit.Matte())
	for _, side in { -1, 1 } do
		for _, z in { frontZ, rearZ } do
			local hub = Vector3.new(side * wheelX, radius, z)
			Kit.Wheel(model, hub, radius, width, side, accent, 6)
			suspension(
				model,
				Vector3.new(side * (halfWidth - 0.1), radius + 0.2, z),
				hub - Vector3.new(side * width / 2, 0, 0)
			)
			Kit.Span(
				model,
				side * (wheelX - width / 2 - 0.1),
				side * (wheelX + width / 2 + 0.1),
				radius * 2 + 0.15,
				radius * 2 + 0.3,
				z - radius - 0.2,
				z + radius * 0.4,
				Kit.Trim,
				Kit.Matte()
			)
		end
	end
	local cageTop = seatTop + 4.0
	local rail = 0.34
	local frontHoop = {
		Vector3.new(-2.5, belt, -1.1),
		Vector3.new(-2.0, cageTop, 0.1),
		Vector3.new(2.0, cageTop, 0.1),
		Vector3.new(2.5, belt, -1.1),
	}
	local rearHoop = {
		Vector3.new(-2.5, belt - 0.2, 2.6),
		Vector3.new(-2.0, cageTop, 2.3),
		Vector3.new(2.0, cageTop, 2.3),
		Vector3.new(2.5, belt - 0.2, 2.6),
	}
	for index = 1, 3 do
		Kit.Tube(model, frontHoop[index], frontHoop[index + 1], rail, Kit.Trim, Kit.Matte())
		Kit.Tube(model, rearHoop[index], rearHoop[index + 1], rail, Kit.Trim, Kit.Matte())
	end
	for _, side in { -1, 1 } do
		Kit.Tube(
			model,
			Vector3.new(side * 2.0, cageTop, 0.1),
			Vector3.new(side * 2.0, cageTop, 2.3),
			rail,
			Kit.Trim,
			Kit.Matte()
		)
		Kit.Tube(
			model,
			Vector3.new(side * 2.0, cageTop, 2.3),
			Vector3.new(side * 1.7, belt - 0.2, 4.6),
			rail,
			Kit.Trim,
			Kit.Matte()
		)
		Kit.Tube(
			model,
			Vector3.new(side * 2.5, belt, -1.1),
			Vector3.new(side * 2.3, low + 0.5, -6.2),
			rail,
			Kit.Trim,
			Kit.Matte()
		)
	end
	Kit.Tube(
		model,
		Vector3.new(-2.3, low + 0.5, -6.3),
		Vector3.new(2.3, low + 0.5, -6.3),
		rail,
		Kit.Trim,
		Kit.Matte()
	)
	Kit.Span(model, -1.9, 1.9, cageTop + 0.15, cageTop + 0.45, -0.05, 0.35, Kit.Trim, Kit.Matte())
	for index = -3, 3, 2 do
		Kit.Box(
			model,
			Vector3.new(0.7, 0.26, 0.1),
			CFrame.new(index * 0.45, cageTop + 0.3, -0.1),
			Kit.HeadLight,
			Kit.Neon()
		)
	end
	Kit.Span(model, -1.5, 1.5, belt - 0.2, belt + 0.9, 2.9, 4.6, Kit.Trim, Kit.Matte())
	for _, side in { -1, 1 } do
		Kit.CylinderY(model, 0.7, 0.9, Vector3.new(side * 0.8, belt + 1.25, 3.4), Kit.Chrome, Kit.Metal(0.3))
		Kit.Tube(
			model,
			Vector3.new(side * 1.1, belt + 0.2, 4.5),
			Vector3.new(side * 1.3, belt + 0.6, 5.6),
			0.35,
			Kit.Chrome,
			Kit.Metal(0.3)
		)
		Kit.CylinderZ(model, 0.25, 0.7, Vector3.new(side * 1.6, low + 1.0, -6.45), Kit.HeadLight, Kit.Neon())
		Kit.Box(
			model,
			Vector3.new(0.8, 0.4, 0.1),
			CFrame.new(side * 1.9, belt - 0.6, 4.95),
			Kit.TailLight,
			Kit.Neon()
		)
	end
	return { Body = body, Rear = 4.9, Top = cageTop, Exhaust = Vector3.new(0, belt + 0.6, 5.8) }
end

function Specials.Rocket(model: Model, color: Color3, accent: Color3): Result
	local halfWidth = 2.1
	local low, belt = 0.7, 2.3
	local seatTop = belt - 1.05
	local body = Kit.Span(model, -1.2, 1.2, low, seatTop - 0.5, -8.2, 7.0, Kit.Trim, Kit.Matte())
	body.Name = "Body"
	Kit.Ramp(model, -1.25, 1.25, low + 0.2, belt, -8.8, -2.6, color, Kit.Paint(0.12))
	Kit.Span(model, -1.25, 1.25, low, low + 0.2, -8.8, -2.6, color, Kit.Paint(0.12))
	for _, side in { -1, 1 } do
		Kit.Span(model, side * 1.55, side * halfWidth, low, belt, -2.6, 2.4, color, Kit.Paint(0.12))
		Kit.Span(
			model,
			side * 1.45,
			side * 1.55,
			seatTop - 0.5,
			belt - 0.02,
			-2.6,
			2.4,
			Kit.Interior,
			Kit.Matte()
		)
		Kit.Strip(
			model,
			Vector3.new(side * 0.6, low + 0.25, -8.6),
			Vector3.new(side * 0.6, belt + 0.02, -2.7),
			0.35,
			accent,
			Kit.Paint()
		)
	end
	Kit.Span(model, -1.55, 1.55, belt - 0.5, belt + 0.05, -2.6, -1.9, Kit.Trim, Kit.Matte())
	Kit.Seat(model, Vector3.new(0, seatTop, 0.9))
	Kit.SteeringWheel(model, Vector3.new(0, belt + 0.05, -1.0))
	Kit.Windshield(model, 3.2, belt, 0.9, -2.3, 0.8)
	Kit.Span(model, -halfWidth, halfWidth, low, belt + 0.3, 2.4, 7.6, color, Kit.Paint(0.12))
	local rocketY = belt + 1.45
	Kit.CylinderZ(
		model,
		6.6,
		2.7,
		Vector3.new(0, rocketY, 5.4),
		Color3.fromRGB(235, 238, 245),
		Kit.Metal(0.2)
	)
	Kit.Ellipsoid(model, Vector3.new(2.7, 2.7, 3.2), CFrame.new(0, rocketY, 2.1), accent, Kit.Paint(0.12))
	for _, z in { 4.2, 6.6 } do
		Kit.CylinderZ(model, 0.35, 2.78, Vector3.new(0, rocketY, z), accent, Kit.Paint())
	end
	Kit.CylinderZ(model, 1.0, 2.3, Vector3.new(0, rocketY, 9.1), Kit.Trim, Kit.Metal(0.1))
	Kit.CylinderZ(model, 0.2, 1.7, Vector3.new(0, rocketY, 9.62), Color3.fromRGB(255, 140, 40), Kit.Neon())
	Kit.Ramp(model, -0.12, 0.12, rocketY + 1.2, rocketY + 3.2, 6.2, 8.7, accent, Kit.Paint())
	for _, side in { -1, 1 } do
		Kit.Box(
			model,
			Vector3.new(2.2, 0.16, 1.8),
			CFrame.new(side * 2.2, rocketY - 0.3, 7.9) * CFrame.Angles(0, 0, side * math.rad(-20)),
			accent,
			Kit.Paint()
		)
	end
	for _, side in { -1, 1 } do
		local front = Vector3.new(side * 2.55, 0.95, -7.3)
		Kit.Wheel(model, front, 0.95, 0.7, side, Kit.Chrome, 5)
		Kit.Tube(model, Vector3.new(side * 1.1, 1.0, -7.3), front, 0.2, Kit.Trim, Kit.Matte())
		local back = Vector3.new(side * 3.15, 1.85, 5.0)
		Kit.Wheel(model, back, 1.85, 2.1, side, Kit.Chrome, 6)
		Kit.Box(
			model,
			Vector3.new(0.7, 0.35, 0.1),
			CFrame.new(side * 1.5, belt - 0.3, 7.65),
			Kit.TailLight,
			Kit.Neon()
		)
		Kit.Box(
			model,
			Vector3.new(0.5, 0.25, 0.1),
			CFrame.new(side * 0.7, low + 0.9, -8.85),
			Kit.HeadLight,
			Kit.Neon()
		)
	end
	return { Body = body, Rear = 7.6, Top = rocketY + 3.2, Exhaust = Vector3.new(0, rocketY, 9.9) }
end

function Specials.Hover(model: Model, color: Color3, accent: Color3): Result
	local halfWidth = 3.3
	local low, belt = 1.75, 3.05
	local band = low + 0.45
	local cockpit = 2.0
	local seatTop = belt - 1.1
	local trim = Color3.fromRGB(34, 38, 52)
	local visor = Color3.fromRGB(20, 26, 40)
	local body =
		Kit.Span(model, -(halfWidth - 0.4), halfWidth - 0.4, low, seatTop - 0.5, -4.2, 5.6, trim, Kit.Matte())
	body.Name = "Body"
	Kit.Span(model, -halfWidth, halfWidth, low, band, -4.2, 6.2, trim, Kit.Paint(0.1))
	Kit.Ramp(model, -(halfWidth - 0.2), halfWidth - 0.2, low, band, -6.2, -4.2, trim, Kit.Paint(0.1))
	Kit.Ramp(model, -halfWidth, halfWidth, band, belt - 0.25, -6.4, -3.0, color, Kit.Paint(0.18))
	Kit.Span(model, -halfWidth, halfWidth, band, belt - 0.25, -3.0, -1.2, color, Kit.Paint(0.18))
	Kit.Span(model, -halfWidth, halfWidth, belt - 0.25, belt, -3.0, -1.2, color, Kit.Paint(0.18))
	Kit.Strip(
		model,
		Vector3.new(0, band + 0.03, -6.4),
		Vector3.new(0, belt - 0.22, -3.0),
		1.6,
		visor,
		Kit.Paint(0.25)
	)
	for _, side in { -1, 1 } do
		Kit.Strip(
			model,
			Vector3.new(side * (halfWidth - 0.25), band + 0.03, -6.4),
			Vector3.new(side * (halfWidth - 0.25), belt - 0.22, -3.0),
			0.22,
			accent,
			Kit.Neon()
		)
		Kit.Span(model, side * cockpit, side * halfWidth, band, belt, -1.2, 2.6, color, Kit.Paint(0.18))
		Kit.Span(
			model,
			side * (cockpit - 0.1),
			side * cockpit,
			seatTop - 0.5,
			belt - 0.02,
			-1.2,
			2.6,
			trim,
			Kit.Matte()
		)
		Kit.Span(
			model,
			side * (halfWidth - 0.02),
			side * (halfWidth + 0.04),
			band - 0.04,
			band + 0.08,
			-4.2,
			6.2,
			accent,
			Kit.Neon()
		)
		for _, z in { -3.3, 4.1 } do
			local pod = Vector3.new(side * (halfWidth + 0.45), low - 0.15, z)
			Kit.Ellipsoid(model, Vector3.new(1.7, 1.2, 3.3), CFrame.new(pod), color, Kit.Paint(0.18))
			Kit.Ellipsoid(
				model,
				Vector3.new(1.78, 0.16, 3.4),
				CFrame.new(pod - Vector3.new(0, 0.12, 0)),
				accent,
				Kit.Neon()
			)
			Kit.CylinderY(model, 0.1, 1.2, pod - Vector3.new(0, 0.58, 0), accent, Kit.Neon())
			Kit.Span(
				model,
				side * (halfWidth - 0.1),
				side * (halfWidth + 0.2),
				low - 0.1,
				band,
				z - 0.4,
				z + 0.4,
				trim,
				Kit.Matte()
			)
		end
		Kit.Ramp(
			model,
			side * (halfWidth - 0.45),
			side * (halfWidth - 0.15),
			belt - 0.1,
			belt + 2.0,
			3.9,
			6.2,
			color,
			Kit.Paint(0.18)
		)
		Kit.Span(
			model,
			side * (halfWidth - 0.47),
			side * (halfWidth - 0.13),
			belt + 1.85,
			belt + 2.0,
			5.2,
			6.2,
			accent,
			Kit.Neon()
		)
		Kit.CylinderZ(model, 0.9, 1.3, Vector3.new(side * 1.4, band + 0.2, 6.55), trim, Kit.Metal(0.1))
		Kit.CylinderZ(model, 0.12, 1.0, Vector3.new(side * 1.4, band + 0.2, 7.02), accent, Kit.Neon())
		Kit.Box(
			model,
			Vector3.new(1.4, 0.2, 0.12),
			CFrame.new(side * (halfWidth - 1.1), band + 0.12, -6.28),
			accent,
			Kit.Neon()
		)
		Kit.Box(
			model,
			Vector3.new(1.5, 0.22, 0.1),
			CFrame.new(side * (halfWidth - 1.1), belt - 0.45, 6.26),
			Kit.TailLight,
			Kit.Neon()
		)
	end
	Kit.Span(model, -halfWidth, halfWidth, band, belt - 0.1, 2.6, 6.2, color, Kit.Paint(0.18))
	Kit.Ellipsoid(model, Vector3.new(2.4, 1.4, 3.6), CFrame.new(0, belt - 0.1, 4.2), color, Kit.Paint(0.18))
	Kit.Span(model, -0.1, 0.1, belt + 0.5, belt + 0.62, 2.6, 5.9, accent, Kit.Neon())
	Kit.Span(model, -cockpit, cockpit, belt - 0.5, belt + 0.05, -1.2, -0.5, trim, Kit.Matte())
	Kit.Seat(model, Vector3.new(0, seatTop, 1.1), trim)
	Kit.SteeringWheel(model, Vector3.new(0, belt + 0.05, -0.8))
	Kit.Windshield(model, 4.4, belt, 1.3, -1.05, 1.1)
	return { Body = body, Rear = 6.2, Top = belt + 2.0, Exhaust = Vector3.new(0, band + 0.2, 7.2) }
end

function Specials.Racer(model: Model, color: Color3, accent: Color3): Result
	local low, belt = 0.7, 2.2
	local seatTop = belt - 1.15
	local body = Kit.Span(model, -1.1, 1.1, low, seatTop - 0.4, -3.4, 5.6, Kit.Trim, Kit.Matte())
	body.Name = "Body"
	Kit.Ramp(model, -0.85, 0.85, low + 0.15, belt - 0.2, -8.2, -3.4, color, Kit.Paint(0.12))
	Kit.Span(model, -0.85, 0.85, low, low + 0.15, -8.2, -3.4, color, Kit.Paint(0.12))
	Kit.Span(model, -3.5, 3.5, 0.45, 0.62, -8.6, -7.4, accent, Kit.Paint())
	Kit.Span(model, -3.4, 3.4, 0.62, 0.78, -8.2, -7.6, color, Kit.Paint())
	for _, side in { -1, 1 } do
		Kit.Span(model, side * 3.35, side * 3.55, 0.45, 1.35, -8.7, -7.2, color, Kit.Paint())
		Kit.Span(model, side * 1.0, side * 1.3, low, belt, -3.4, 1.4, color, Kit.Paint(0.12))
		Kit.Span(model, side * 1.3, side * 2.5, low, belt - 0.3, -1.4, 3.2, color, Kit.Paint(0.12))
		Kit.Span(model, side * 1.35, side * 2.45, low + 0.2, belt - 0.4, -1.45, -1.38, Kit.Trim, Kit.Matte())
		Kit.Ramp(model, side * 1.3, side * 2.5, low, belt - 0.3, 5.2, 3.2, color, Kit.Paint(0.12))
		Kit.Strip(
			model,
			Vector3.new(side * 1.9, belt - 0.27, -1.3),
			Vector3.new(side * 1.9, belt - 0.27, 3.2),
			0.5,
			accent,
			Kit.Paint()
		)
		local frontHub = Vector3.new(side * 3.0, 1.25, -5.7)
		local rearHub = Vector3.new(side * 3.05, 1.4, 5.1)
		Kit.Wheel(model, frontHub, 1.25, 1.3, side, Kit.Trim, 5)
		Kit.Wheel(model, rearHub, 1.4, 1.75, side, Kit.Trim, 5)
		suspension(model, Vector3.new(side * 0.9, 1.3, -5.0), frontHub - Vector3.new(side * 0.65, 0, 0))
		suspension(model, Vector3.new(side * 1.0, 1.4, 5.0), rearHub - Vector3.new(side * 0.9, 0, 0))
		Kit.Span(model, side * 2.35, side * 2.55, 2.6, 3.7, 6.4, 7.9, color, Kit.Paint())
		Kit.Tube(
			model,
			Vector3.new(0, belt + 1.25, -1.1),
			Vector3.new(side * 1.0, belt + 1.1, 0.3),
			0.26,
			Kit.Trim,
			Kit.Matte()
		)
		Kit.Tube(
			model,
			Vector3.new(side * 1.0, belt + 1.1, 0.3),
			Vector3.new(side * 1.05, belt, 1.2),
			0.26,
			Kit.Trim,
			Kit.Matte()
		)
	end
	Kit.Tube(
		model,
		Vector3.new(0, belt, -2.0),
		Vector3.new(0, belt + 1.25, -1.1),
		0.26,
		Kit.Trim,
		Kit.Matte()
	)
	Kit.Span(model, -1.0, 1.0, belt - 0.5, belt + 0.02, -3.4, -2.7, Kit.Trim, Kit.Matte())
	Kit.Seat(model, Vector3.new(0, seatTop, 0.2))
	Kit.SteeringWheel(model, Vector3.new(0, belt, -1.6))
	Kit.Span(model, -0.85, 0.85, low, belt + 0.9, 1.4, 3.0, color, Kit.Paint(0.12))
	Kit.Ramp(model, -0.85, 0.85, low, belt + 0.9, 6.2, 3.0, color, Kit.Paint(0.12))
	Kit.Span(model, -0.5, 0.5, belt + 0.4, belt + 0.85, 1.35, 1.45, Kit.Trim, Kit.Matte())
	Kit.Span(model, -2.4, 2.4, 3.35, 3.55, 6.5, 7.8, accent, Kit.Paint())
	Kit.Span(model, -2.4, 2.4, 2.95, 3.15, 6.7, 7.6, color, Kit.Paint())
	Kit.Span(model, -0.15, 0.15, belt, 3.35, 6.6, 7.2, Kit.Trim, Kit.Matte())
	Kit.Box(model, Vector3.new(0.6, 0.3, 0.1), CFrame.new(0, low + 0.6, 6.25), Kit.TailLight, Kit.Neon())
	return { Body = body, Rear = 6.2, Top = 3.7, Exhaust = Vector3.new(0, belt, 6.6) }
end

function Specials.Jet(model: Model, color: Color3, accent: Color3): Result
	local centerY = 2.5
	local radius = 1.5
	local seatTop = centerY + 0.7
	local body = Kit.CylinderZ(model, 12.5, radius * 2, Vector3.new(0, centerY, 0.6), color, Kit.Metal(0.15))
	body.Name = "Body"
	Kit.Ellipsoid(
		model,
		Vector3.new(radius * 2, radius * 2, 6.0),
		CFrame.new(0, centerY, -5.6),
		color,
		Kit.Metal(0.15)
	)
	Kit.Ellipsoid(model, Vector3.new(0.9, 0.9, 1.4), CFrame.new(0, centerY - 0.1, -8.35), accent, Kit.Paint())
	Kit.Span(model, -1.3, 1.3, centerY + 0.4, centerY + 1.25, -2.8, 1.8, Kit.Interior, Kit.Matte())
	Kit.Seat(model, Vector3.new(0, seatTop, 0.2))
	Kit.SteeringWheel(model, Vector3.new(0, seatTop + 0.9, -1.7))
	Kit.Ellipsoid(
		model,
		Vector3.new(2.8, 3.2, 6.0),
		CFrame.new(0, centerY + 1.6, -0.6),
		Kit.Glass,
		Kit.GlassStyle(0.55)
	)
	Kit.Span(model, -1.45, 1.45, centerY + 1.2, centerY + 1.35, -3.6, 2.4, accent, Kit.Paint())
	for _, side in { -1, 1 } do
		Kit.Box(
			model,
			Vector3.new(6.2, 0.35, 3.2),
			CFrame.new(side * 3.9, centerY - 0.4, 1.8)
				* CFrame.Angles(0, side * math.rad(-28), side * math.rad(-4)),
			color,
			Kit.Metal(0.15)
		)
		Kit.Box(
			model,
			Vector3.new(0.5, 0.4, 2.4),
			CFrame.new(side * 6.4, centerY - 0.62, 3.2) * CFrame.Angles(0, side * math.rad(-28), 0),
			accent,
			Kit.Paint()
		)
		Kit.Box(
			model,
			Vector3.new(3.0, 0.25, 1.7),
			CFrame.new(side * 2.0, centerY + 0.3, 6.1) * CFrame.Angles(0, side * math.rad(-25), 0),
			color,
			Kit.Metal(0.15)
		)
		Kit.CylinderZ(model, 2.6, 1.2, Vector3.new(side * 1.55, centerY - 0.2, 0.6), Kit.Trim, Kit.Metal(0.1))
		Kit.CylinderZ(model, 0.12, 0.9, Vector3.new(side * 1.55, centerY - 0.2, -0.72), Kit.Trim, Kit.Matte())
		local rearHub = Vector3.new(side * 2.3, 1.0, 3.2)
		Kit.Wheel(model, rearHub, 1.0, 0.8, side, Kit.Chrome, 5)
		Kit.Tube(
			model,
			Vector3.new(side * 1.2, centerY - 0.9, 3.2),
			rearHub - Vector3.new(side * 0.45, 0, 0),
			0.3,
			Kit.Chrome,
			Kit.Metal()
		)
		local frontHub = Vector3.new(side * 0.75, 0.85, -5.2)
		Kit.Wheel(model, frontHub, 0.85, 0.6, side, Kit.Chrome, 5)
	end
	Kit.Tube(
		model,
		Vector3.new(0, centerY - 1.2, -5.2),
		Vector3.new(0, 0.85, -5.2),
		0.3,
		Kit.Chrome,
		Kit.Metal()
	)
	Kit.CylinderX(model, 1.6, 0.25, Vector3.new(0, 0.85, -5.2), Kit.Chrome, Kit.Metal())
	Kit.Ramp(model, -0.14, 0.14, centerY + 1.0, centerY + 3.8, 4.4, 6.8, accent, Kit.Paint())
	Kit.CylinderZ(model, 1.2, 2.6, Vector3.new(0, centerY, 7.3), Kit.Trim, Kit.Metal(0.1))
	Kit.CylinderZ(model, 0.2, 1.9, Vector3.new(0, centerY, 7.92), Color3.fromRGB(80, 200, 255), Kit.Neon())
	for _, side in { -1, 1 } do
		Kit.Box(
			model,
			Vector3.new(0.5, 0.3, 0.1),
			CFrame.new(side * 1.2, centerY + 0.9, 6.9),
			Kit.TailLight,
			Kit.Neon()
		)
	end
	return { Body = body, Rear = 7.9, Top = centerY + 3.8, Exhaust = Vector3.new(0, centerY, 8.2) }
end

return Specials
