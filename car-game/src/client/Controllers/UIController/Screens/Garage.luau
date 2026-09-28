--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cars = require(ReplicatedStorage.Config.Cars)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

type Card = {
	Car: Cars.Car,
	Frame: GuiObject,
	Action: GuiButton?,
	ActionLabel: TextLabel?,
}

local Garage = {}

local function showModel(viewport: ViewportFrame?, carId: string)
	if not viewport then
		return
	end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Cars")
	local template = folder and folder:FindFirstChild(carId)
	if not template or not template:IsA("Model") then
		return
	end
	local model = template:Clone()
	model:PivotTo(CFrame.new())
	model.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	local boxCFrame, size = model:GetBoundingBox()
	local center = boxCFrame.Position
	local reach = size.Magnitude
	camera.CFrame = CFrame.lookAt(center + Vector3.new(reach * 0.75, reach * 0.45, -reach * 0.95), center)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
end

function Garage.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local dataController = controllers.DataController
	local grid = Widgets.Frame(gui, "Grid")
	local template = Widgets.Frame(gui, "CarTemplate")
	local cards: { Card } = {}
	local built = false
	local busy = false
	local confirming: string? = nil
	local confirmToken = 0
	local refresh: () -> () = function() end

	local function request(packet: any, carId: string)
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			local ok = packet:Fire(carId)
			busy = false
			controllers.SoundController:Play(if ok then "Purchase" else "Error")
		end)
	end

	local function available(car: Cars.Car): boolean
		if car.Source == "Group" then
			return GameConfig.GroupId > 0
		elseif car.Source == "VIP" then
			return controllers.StoreController:PassAvailable("VIP")
				or controllers.StoreController:OwnsPass("VIP")
		elseif car.Source == "StarterPack" then
			local data = dataController:Get()
			return controllers.StoreController:ProductAvailable("StarterPack")
				or (type(data) == "table" and data.Cars[car.Id] == true)
		end
		return true
	end

	local function press(car: Cars.Car)
		local data = dataController:Get()
		if type(data) ~= "table" then
			return
		end
		if Stats.OwnsCar(data, car.Id) then
			if Stats.EquippedCar(data).Id ~= car.Id then
				request(Packets.EquipCar, car.Id)
			end
		elseif car.Source == "Shop" then
			local upgraded = Stats.UpgradeLevel(data, "Engine")
					+ Stats.UpgradeLevel(data, "Nitro")
					+ Stats.UpgradeLevel(data, "Wings")
				> 0
			if data.Cash < car.Price then
				controllers.SoundController:Play("Error")
			elseif upgraded and confirming ~= car.Id then
				confirming = car.Id
				confirmToken += 1
				local token = confirmToken
				controllers.SoundController:Play("Click", 0.8)
				refresh()
				task.delay(3, function()
					if confirmToken == token then
						confirming = nil
						refresh()
					end
				end)
			else
				confirming = nil
				request(Packets.BuyCar, car.Id)
			end
		elseif car.Source == "VIP" then
			controllers.StoreController:PromptPass("VIP")
		elseif car.Source == "StarterPack" then
			context.Open("Offer")
		elseif car.Source == "Daily" then
			context.Open("Daily")
		elseif car.Source == "Group" then
			context.Open("Codes")
		end
	end

	refresh = function()
		local data = dataController:Get()
		if type(data) ~= "table" then
			return
		end
		local equipped = Stats.EquippedCar(data).Id
		for _, card in cards do
			local car = card.Car
			local owned = Stats.OwnsCar(data, car.Id)
			local text, color = "", "Gray"
			if owned then
				if equipped == car.Id then
					text, color = "EQUIPPED", "Gray"
				else
					text, color = "EQUIP", "Blue"
				end
			elseif car.Source == "Shop" and confirming == car.Id then
				text, color = "RESETS UPGRADES!\nTAP AGAIN", "Red"
			elseif car.Source == "Shop" then
				text, color = Format.Cash(car.Price), if data.Cash >= car.Price then "Green" else "Gray"
			elseif car.Source == "VIP" then
				text, color = "👑 GET VIP", "Gold"
			elseif car.Source == "StarterPack" then
				text, color = "🎁 STARTER PACK", "Pink"
			elseif car.Source == "Daily" then
				text, color = "📅 DAY 7 REWARD", "Purple"
			elseif car.Source == "Group" then
				text, color = "👥 JOIN GROUP", "Purple"
			end
			Widgets.SetText(card.ActionLabel, text)
			Widgets.Paint(card.Action, color)
		end
	end

	local function build()
		if built or not grid or not template then
			return
		end
		built = true
		template.Visible = false
		for index, car in Cars.Order do
			if not available(car) then
				continue
			end
			local frame = template:Clone()
			frame.Name = car.Id
			frame.LayoutOrder = index
			frame.Visible = true
			Widgets.SetText(frame:FindFirstChild("CarName", true), car.Name)
			Widgets.SetText(
				frame:FindFirstChild("CarStats", true),
				`⚡ {Format.Multiplier(car.Speed)}   💰 {Format.Multiplier(car.Cash)}`
			)
			local tag = frame:FindFirstChild("CarTag", true)
			Widgets.SetText(tag, car.Tag)
			Widgets.SetVisible(tag, car.Tag ~= "")
			local viewport = frame:FindFirstChild("Viewport", true)
			showModel(if viewport and viewport:IsA("ViewportFrame") then viewport else nil, car.Id)
			local action = frame:FindFirstChild("Action", true)
			local actionLabel = frame:FindFirstChild("ActionLabel", true)
			local card: Card = {
				Car = car,
				Frame = frame,
				Action = if action and action:IsA("GuiButton") then action else nil,
				ActionLabel = if actionLabel and actionLabel:IsA("TextLabel") then actionLabel else nil,
			}
			table.insert(cards, card)
			Widgets.OnClick(trove, card.Action, function()
				press(car)
			end)
			frame.Parent = grid
			trove:Add(frame)
		end
	end

	trove:Add(dataController:Observe({}, function()
		if gui.Enabled then
			refresh()
		end
	end))

	return Widgets.ModalScreen(context, gui, "Garage", trove, function()
		confirming = nil
		build()
		refresh()
	end)
end

return Garage
