--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)

type CarEffects = {
	Instance: Instance,
	Emitters: { ParticleEmitter },
	Trails: { Trail },
	BoostTrails: { Trail },
	Lights: { Light },
	Smoke: { ParticleEmitter },
	Skids: { Trail },
	Connections: { RBXScriptConnection },
}

local function refresh(self: CarEffects)
	local boosting = self.Instance:GetAttribute("Boosting") == true
	local flying = self.Instance:GetAttribute("Flying") == true
	local drifting = self.Instance:GetAttribute("Drifting") == true
		or self.Instance:GetAttribute("LocalDrifting") == true
	for _, emitter in self.Emitters do
		emitter.Enabled = boosting
	end
	for _, trail in self.Trails do
		trail.Enabled = flying
	end
	for _, trail in self.BoostTrails do
		trail.Enabled = boosting
	end
	for _, light in self.Lights do
		light.Enabled = boosting
	end
	for _, smoke in self.Smoke do
		smoke.Enabled = drifting
	end
	for _, skid in self.Skids do
		skid.Enabled = drifting
	end
end

return function(_controllers: { [string]: any })
	local CarEffects = Component.new({ Tag = "Car" }) :: any

	function CarEffects.Construct(self: CarEffects)
		self.Emitters = {}
		self.Trails = {}
		self.BoostTrails = {}
		self.Lights = {}
		self.Smoke = {}
		self.Skids = {}
		self.Connections = {}
		for _, descendant in self.Instance:GetDescendants() do
			if descendant:IsA("ParticleEmitter") and descendant.Name == "BoostFire" then
				table.insert(self.Emitters, descendant)
			elseif descendant:IsA("Trail") and descendant.Name == "SpeedTrail" then
				table.insert(self.Trails, descendant)
			elseif descendant:IsA("Trail") and descendant.Name == "BoostTrail" then
				table.insert(self.BoostTrails, descendant)
			elseif descendant:IsA("Light") and descendant.Name == "BoostGlow" then
				table.insert(self.Lights, descendant)
			elseif descendant:IsA("ParticleEmitter") and descendant.Name == "DriftSmoke" then
				table.insert(self.Smoke, descendant)
			elseif descendant:IsA("Trail") and descendant.Name == "SkidMark" then
				table.insert(self.Skids, descendant)
			end
		end
	end

	function CarEffects.Start(self: CarEffects)
		table.insert(
			self.Connections,
			self.Instance:GetAttributeChangedSignal("Boosting"):Connect(function()
				refresh(self)
			end)
		)
		table.insert(
			self.Connections,
			self.Instance:GetAttributeChangedSignal("Flying"):Connect(function()
				refresh(self)
			end)
		)
		for _, name in { "Drifting", "LocalDrifting" } do
			table.insert(
				self.Connections,
				self.Instance:GetAttributeChangedSignal(name):Connect(function()
					refresh(self)
				end)
			)
		end
		refresh(self)
	end

	function CarEffects.Stop(self: CarEffects)
		for _, connection in self.Connections do
			connection:Disconnect()
		end
		table.clear(self.Connections)
	end

	return CarEffects
end
