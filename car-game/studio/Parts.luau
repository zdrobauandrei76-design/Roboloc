--!strict

export type Options = {
	Class: string?,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Transparency: number?,
	Collide: boolean?,
	Name: string?,
	Reflectance: number?,
}

local Parts = {}

function Parts.Make(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	options: Options?
): BasePart
	local settings: Options = options or {}
	local className = settings.Class or "Part"
	local part = Instance.new(className) :: BasePart
	if settings.Shape and part:IsA("Part") then
		part.Shape = settings.Shape
	end
	part.Name = settings.Name or "Part"
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = settings.Material or Enum.Material.SmoothPlastic
	part.Transparency = settings.Transparency or 0
	part.Reflectance = settings.Reflectance or 0
	part.Anchored = true
	part.CanCollide = settings.Collide == true
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function Parts.Ball(
	parent: Instance,
	diameter: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): BasePart
	return Parts.Make(
		parent,
		diameter,
		CFrame.new(position),
		color,
		{ Shape = Enum.PartType.Ball, Material = material }
	)
end

function Parts.Disc(
	parent: Instance,
	diameter: number,
	thickness: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): BasePart
	return Parts.Make(
		parent,
		Vector3.new(thickness, diameter, diameter),
		CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		{ Shape = Enum.PartType.Cylinder, Material = material }
	)
end

function Parts.Sign(part: BasePart, face: Enum.NormalId, text: string, textColor: Color3, background: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if background then 0 else 1
	label.BackgroundColor3 = background or Color3.new(0, 0, 0)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = textColor
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
	label.Parent = gui
end

return Parts
