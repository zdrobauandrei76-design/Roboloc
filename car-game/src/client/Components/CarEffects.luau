--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)

type CarEffects = {
	Instance: Instance,
	Emitters: { ParticleEmitter },
	Trails: { Trail },
	Connections: { RBXScriptConnection },
}

local function refresh(self: CarEffects)
	local boosting = self.Instance:GetAttribute("Boosting") == true
	local flying = self.Instance:GetAttribute("Flying") == true
	for _, emitter in self.Emitters do
		emitter.Enabled = boosting
	end
	for _, trail in self.Trails do
		trail.Enabled = flying
	end
end

return function(_controllers: { [string]: any })
	local CarEffects = Component.new({ Tag = "Car" }) :: any

	function CarEffects.Construct(self: CarEffects)
		self.Emitters = {}
		self.Trails = {}
		self.Connections = {}
		for _, descendant in self.Instance:GetDescendants() do
			if descendant:IsA("ParticleEmitter") and descendant.Name == "BoostFire" then
				table.insert(self.Emitters, descendant)
			elseif descendant:IsA("Trail") and descendant.Name == "SpeedTrail" then
				table.insert(self.Trails, descendant)
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
