--!strict

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cars = require(ReplicatedStorage.Config.Cars)
local Stats = require(ReplicatedStorage.Game.Stats)
local Track = require(ReplicatedStorage.Game.Track)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = any

type Entry = {
	Model: Model,
	Body: BasePart,
	Seat: Seat,
	Force: VectorForce,
	Trove: TroveInstance,
}

local collisionGroup = "Cars"

local GarageService = { Name = "GarageService" }
local services: { [string]: any } = {}
local cars: { [Player]: Entry } = {}
local lanes: { [number]: Player } = {}
local characterTroves: { [Player]: TroveInstance } = {}
local characterConnections: { [Player]: RBXScriptConnection } = {}
local connections: { { Disconnect: (self: any) -> () } } = {}
local carsFolder: Folder? = nil
local warnedMissing = false

local function assignLane(player: Player): number
	for lane = 1, Track.LaneCount do
		if not lanes[lane] then
			lanes[lane] = player
			player:SetAttribute("Lane", lane)
			return lane
		end
	end
	local shared = player.UserId % Track.LaneCount + 1
	player:SetAttribute("Lane", shared)
	return shared
end

local function releaseLane(player: Player)
	for lane, owner in lanes do
		if owner == player then
			lanes[lane] = nil
		end
	end
end

local function laneOf(player: Player): number
	local lane = player:GetAttribute("Lane")
	return if type(lane) == "number" then lane else assignLane(player)
end

local function findTemplate(carId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Cars")
	local model = folder and folder:FindFirstChild(carId)
	if model and model:IsA("Model") then
		return model
	end
	return nil
end

local function destroyCar(player: Player)
	local entry = cars[player]
	cars[player] = nil
	if entry then
		entry.Trove:Destroy()
	end
end

local function updateForce(entry: Entry)
	if entry.Body.Parent then
		entry.Force.Force = Vector3.new(0, entry.Body.AssemblyMass * workspace.Gravity, 0)
	end
end

local function setCollisionGroup(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = collisionGroup
		end
	end
end

local function seatCharacter(player: Player)
	local entry = cars[player]
	local character = player.Character
	if not entry or not character or character.Parent == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end
	if entry.Seat.Occupant ~= nil then
		return
	end
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	setCollisionGroup(character)
	character:PivotTo(entry.Seat.CFrame * CFrame.new(0, 2, 0))
	entry.Seat:Sit(humanoid)
	task.defer(function()
		if cars[player] == entry then
			updateForce(entry)
		end
	end)
end

local function spawnCar(player: Player)
	local data = services.DataService:GetData(player)
	local folder = carsFolder
	if not data or not folder or player.Parent ~= Players then
		return
	end
	local car = Stats.EquippedCar(data)
	local source = findTemplate(car.Id) or findTemplate(Cars.DefaultId)
	if not source then
		if not warnedMissing then
			warnedMissing = true
			warn(
				`[GarageService] Missing car models in ReplicatedStorage.Assets.Cars. Run the Studio build (see car-game/README.md) and save the place.`
			)
		end
		return
	end
	local model = source:Clone()
	local body = model.PrimaryPart
	local seat = model:FindFirstChild("DriverSeat", true)
	if not body or not seat or not seat:IsA("Seat") then
		warn(`[GarageService] Car {source.Name} needs a PrimaryPart and a Seat named DriverSeat`)
		model:Destroy()
		return
	end
	destroyCar(player)
	model.Name = tostring(player.UserId)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("CarId", car.Id)
	model:SetAttribute("Flying", false)
	model:SetAttribute("Boosting", false)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = descendant ~= body
			descendant.CollisionGroup = collisionGroup
		end
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "AntiGravityAttachment"
	attachment.Parent = body
	local force = Instance.new("VectorForce")
	force.Name = "AntiGravity"
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	force.Parent = body
	model:PivotTo(Track.StartCFrame(laneOf(player)))
	model.Parent = folder
	CollectionService:AddTag(model, "Car")
	pcall(body.SetNetworkOwner, body, player)
	local trove = Trove.new()
	trove:Add(model)
	local entry: Entry = { Model = model, Body = body, Seat = seat, Force = force, Trove = trove }
	cars[player] = entry
	updateForce(entry)
	trove:Connect(seat:GetPropertyChangedSignal("Occupant"), function()
		if seat.Occupant == nil and cars[player] == entry then
			task.delay(0.4, function()
				if cars[player] == entry then
					seatCharacter(player)
				end
			end)
		end
	end)
	seatCharacter(player)
end

local function onCharacter(player: Player, character: Model)
	local previous = characterTroves[player]
	if previous then
		previous:Destroy()
	end
	local trove = Trove.new()
	characterTroves[player] = trove
	trove:Connect(character.DescendantAdded, function(descendant: Instance)
		if descendant:IsA("BasePart") and cars[player] then
			descendant.CollisionGroup = collisionGroup
		end
	end)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoid or not root or player.Character ~= character or character.Parent == nil then
			return
		end
		if cars[player] then
			seatCharacter(player)
		else
			spawnCar(player)
		end
	end)
end

local function onPlayer(player: Player)
	if characterConnections[player] or player.Parent ~= Players then
		return
	end
	assignLane(player)
	characterConnections[player] = player.CharacterAdded:Connect(function(character: Model)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

local function setCarAttribute(player: Player, name: string, value: boolean)
	local entry = cars[player]
	if entry then
		entry.Model:SetAttribute(name, value)
	end
end

local function equip(player: Player, carId: string)
	services.DataService:Set(player, { "EquippedCar" }, carId)
	services.MultiplierService:Refresh(player)
	spawnCar(player)
end

function GarageService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function GarageService.GetCar(_self: any, player: Player): Model?
	local entry = cars[player]
	return if entry then entry.Model else nil
end

function GarageService.Start(_self: any)
	local ok, problem = pcall(function()
		if not PhysicsService:IsCollisionGroupRegistered(collisionGroup) then
			PhysicsService:RegisterCollisionGroup(collisionGroup)
		end
		PhysicsService:CollisionGroupSetCollidable(collisionGroup, "Default", false)
		PhysicsService:CollisionGroupSetCollidable(collisionGroup, collisionGroup, false)
	end)
	if not ok then
		warn(`[GarageService] Collision group setup failed: {tostring(problem)}`)
	end
	local folder = Instance.new("Folder")
	folder.Name = "Cars"
	folder.Parent = workspace
	carsFolder = folder

	services.DataService.PlayerLoaded:Connect(function(player: Player, _data: any)
		spawnCar(player)
	end)
	table.insert(connections, Players.PlayerAdded:Connect(onPlayer))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			destroyCar(player)
			releaseLane(player)
			local characterConnection = characterConnections[player]
			characterConnections[player] = nil
			if characterConnection then
				characterConnection:Disconnect()
			end
			local trove = characterTroves[player]
			characterTroves[player] = nil
			if trove then
				trove:Destroy()
			end
		end)
	)
	for _, player in Players:GetPlayers() do
		task.defer(onPlayer, player)
	end

	table.insert(
		connections,
		services.LaunchService.RunStarted:Connect(function(player: Player)
			setCarAttribute(player, "Flying", true)
		end)
	)
	table.insert(
		connections,
		services.LaunchService.RunEnded:Connect(function(player: Player)
			setCarAttribute(player, "Flying", false)
			setCarAttribute(player, "Boosting", false)
		end)
	)
	table.insert(
		connections,
		services.LaunchService.BoostChanged:Connect(function(player: Player, boosting: boolean)
			setCarAttribute(player, "Boosting", boosting)
		end)
	)

	Packets.BuyCar.OnServerInvoke = function(player: Player, carId: string): boolean
		local data = services.DataService:GetData(player)
		local car = if type(carId) == "string" then Cars.ById[carId] else nil
		if not data or not car or car.Source ~= "Shop" or car.Price <= 0 then
			return false
		end
		if Stats.OwnsCar(data, car.Id) or data.Cash < car.Price then
			return false
		end
		services.DataService:Set(player, { "Cash" }, data.Cash - car.Price)
		services.DataService:Set(player, { "Cars", car.Id }, true)
		if not services.LaunchService:IsRunning(player) then
			equip(player, car.Id)
		end
		services.DataService:RequestSave(player)
		return true
	end

	Packets.EquipCar.OnServerInvoke = function(player: Player, carId: string): boolean
		local data = services.DataService:GetData(player)
		if not data or type(carId) ~= "string" or not Stats.OwnsCar(data, carId) then
			return false
		end
		if services.LaunchService:IsRunning(player) then
			return false
		end
		if Stats.EquippedCar(data).Id ~= carId then
			equip(player, carId)
		end
		return true
	end
end

function GarageService.Destroy(_self: any)
	Packets.BuyCar.OnServerInvoke = nil
	Packets.EquipCar.OnServerInvoke = nil
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for player in cars do
		destroyCar(player)
	end
	for _, trove in characterTroves do
		trove:Destroy()
	end
	table.clear(characterTroves)
	for _, characterConnection in characterConnections do
		characterConnection:Disconnect()
	end
	table.clear(characterConnections)
	if carsFolder then
		carsFolder:Destroy()
		carsFolder = nil
	end
end

return GarageService
