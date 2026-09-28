--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cars = require(ReplicatedStorage.Config.Cars)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Offer = {}

function Offer.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local store = controllers.StoreController
	local dataController = controllers.DataController
	local items = Widgets.Text(gui, "OfferItems")
	local buy = Widgets.Button(gui, "OfferBuy")
	local buyLabel = Widgets.Text(gui, "OfferBuyLabel")
	local viewport = Widgets.Viewport(gui, "OfferViewport")
	local product = Monetization.ProductByKey.StarterPack
	local rocket = Cars.ById.Rocket
	local shownThisSession = false
	local modelShown = false
	local wasOwned: boolean? = nil

	local function showModel()
		if modelShown or not viewport then
			return
		end
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local folder = assets and assets:FindFirstChild("Cars")
		local template = folder and folder:FindFirstChild(rocket.Id)
		if not template or not template:IsA("Model") then
			return
		end
		modelShown = true
		local model = template:Clone()
		model:PivotTo(CFrame.new())
		model.Parent = viewport
		local camera = Instance.new("Camera")
		camera.FieldOfView = 40
		local boxCFrame, size = model:GetBoundingBox()
		local reach = size.Magnitude
		camera.CFrame = CFrame.lookAt(
			boxCFrame.Position + Vector3.new(reach * 0.75, reach * 0.45, -reach * 0.95),
			boxCFrame.Position
		)
		camera.Parent = viewport
		viewport.CurrentCamera = camera
	end

	local function refresh()
		local data = dataController:Get()
		if type(data) ~= "table" then
			return
		end
		local cash = Stats.RewardCash(data, product.Runs, product.Minimum)
		Widgets.SetText(
			items,
			`🚀 {rocket.Name} ({Format.Multiplier(rocket.Cash)} cash!)\n⏱️ {product.Minutes} min of 2x Cash\n💵 +{Format.Cash(
				cash
			)} cash`
		)
		store:GetPrice("Product", "StarterPack", function(price: number?)
			Widgets.SetText(buyLabel, if price then `GET IT  R$ {price}` else "GET IT!")
		end)
		showModel()
	end

	Widgets.OnClick(trove, buy, function()
		store:PromptProduct("StarterPack")
	end, controllers)

	trove:Add(dataController:Observe({ "StarterPackOwned" }, function(owned: any)
		if owned == nil then
			return
		end
		if wasOwned == false and owned == true then
			context.Close("Offer")
			task.spawn(function()
				Packets.EquipCar:Fire(rocket.Id)
			end)
		end
		wasOwned = owned == true
	end))

	trove:Add(dataController:Observe({ "Launches" }, function(launches: any)
		local data = dataController:Get()
		if shownThisSession or type(launches) ~= "number" or type(data) ~= "table" then
			return
		end
		if launches < GameConfig.StarterOfferAfterLaunches or data.StarterPackOwned then
			return
		end
		if not store:ProductAvailable("StarterPack") then
			return
		end
		shownThisSession = true
		task.delay(2.5, function()
			local state = controllers.LaunchController:GetState()
			if state == "Idle" or state == "Results" then
				context.Open("Offer")
			else
				shownThisSession = false
			end
		end)
	end))

	return Widgets.ModalScreen(context, gui, "Offer", trove, refresh)
end

return Offer
