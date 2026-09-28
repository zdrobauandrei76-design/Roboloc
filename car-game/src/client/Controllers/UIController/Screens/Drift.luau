--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local EventConfig = require(ReplicatedStorage.Config.Event)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local Drift = {}

function Drift.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local driftController = controllers.DriftController
	local player = Players.LocalPlayer
	local title = Widgets.Text(gui, "DriftTitle")
	local timer = Widgets.Text(gui, "DriftTimer")
	local score = Widgets.Text(gui, "DriftScore")
	local combo = Widgets.Text(gui, "DriftCombo")
	local countdown = Widgets.Text(gui, "DriftCountdown")
	local messageLabel = Widgets.Text(gui, "DriftMessage")
	local messageToken = 0
	local messageColors: { [string]: Color3 } = {
		Transition = Color3.fromRGB(255, 215, 70),
		Warning = Color3.fromRGB(255, 110, 110),
		Crash = Color3.fromRGB(255, 140, 90),
		Boost = Color3.fromRGB(120, 220, 255),
	}
	local hint = Widgets.Text(gui, "DriftHint")
	local board = Widgets.Frame(gui, "DriftBoard")
	local results = Widgets.Frame(gui, "DriftResults")
	local resultsNote = Widgets.Text(gui, "ResultsNote")
	local places = { Widgets.Text(gui, "First"), Widgets.Text(gui, "Second"), Widgets.Text(gui, "Third") }
	local rows: { TextLabel? } = {}
	for index = 1, 5 do
		table.insert(rows, if board then Widgets.Text(board, `Row{index}`) else nil)
	end
	local touchButtons: { [string]: string } = {
		SteerLeft = "Left",
		SteerRight = "Right",
		DriftButton = "Drift",
		BrakeButton = "Brake",
	}
	local touchEnabled = UserInputService.TouchEnabled
	local participating = false
	local resultsToken = 0
	local lastCountdown = ""

	local held: { [InputObject]: string } = {}
	local function release(inputObject: InputObject)
		local name = held[inputObject]
		if not name then
			return
		end
		held[inputObject] = nil
		for _, other in held do
			if other == name then
				return
			end
		end
		driftController:SetTouch(name, false)
	end
	for buttonName, input in touchButtons do
		local button = Widgets.Button(gui, buttonName)
		if button then
			button.Visible = touchEnabled
			trove:Connect(button.InputBegan, function(inputObject: InputObject)
				if
					inputObject.UserInputType == Enum.UserInputType.Touch
					or inputObject.UserInputType == Enum.UserInputType.MouseButton1
				then
					held[inputObject] = input
					driftController:SetTouch(input, true)
				end
			end)
			trove:Connect(button.InputEnded, release)
		end
	end
	trove:Connect(UserInputService.TouchEnded, release)
	trove:Connect(UserInputService.InputEnded, release)
	Widgets.SetVisible(hint, not touchEnabled)

	local function driving(): boolean
		return driftController:GetSession() ~= nil
	end

	local function setDrivingVisible(visible: boolean)
		for buttonName in touchButtons do
			Widgets.SetVisible(Widgets.Button(gui, buttonName), visible and touchEnabled)
		end
		Widgets.SetVisible(hint, visible and not touchEnabled)
		Widgets.SetVisible(Widgets.Frame(gui, "DriftTop"), visible)
		Widgets.SetVisible(board, visible)
		if not visible then
			Widgets.SetVisible(combo, false)
			Widgets.SetVisible(countdown, false)
			Widgets.SetVisible(messageLabel, false)
		end
	end

	local function refreshBoard()
		local session = driftController:GetSession()
		local island = if session then session.Name else nil
		local list: { { Name: string, Score: number, Mine: boolean } } = {}
		for _, other in Players:GetPlayers() do
			local value = other:GetAttribute("DriftScore")
			if other:GetAttribute("DriftJoined") == true and type(value) == "number" then
				if not island or other:GetAttribute("DriftIsland") == island or other == player then
					table.insert(list, { Name = other.DisplayName, Score = value, Mine = other == player })
				end
			end
		end
		table.sort(list, function(a, b)
			return a.Score > b.Score
		end)
		for index, row in rows do
			local item = list[index]
			if item then
				Widgets.SetText(row, `{index}. {item.Name}  {Format.Commas(item.Score)}`)
				if row then
					row.TextColor3 = if item.Mine
						then Color3.fromRGB(255, 215, 70)
						else Color3.fromRGB(255, 255, 255)
				end
			else
				Widgets.SetText(row, "")
			end
		end
	end

	local boardElapsed = 0
	trove:Connect(RunService.RenderStepped, function(dt: number)
		if not gui.Enabled then
			return
		end
		local session = driftController:GetSession()
		if not session then
			return
		end
		local now = workspace:GetServerTimeNow()
		local goAt = workspace:GetAttribute("DriftGoAt")
		local endAt = workspace:GetAttribute("DriftEndAt")
		local untilGo = if type(goAt) == "number" then goAt - now else 0
		if untilGo > 0 then
			local text = tostring(math.ceil(untilGo))
			Widgets.SetText(countdown, text)
			Widgets.SetVisible(countdown, true)
			if text ~= lastCountdown then
				lastCountdown = text
				controllers.SoundController:Play("Click", 0.8)
			end
		elseif untilGo > -1 then
			Widgets.SetText(countdown, "GO!")
			Widgets.SetVisible(countdown, true)
			if lastCountdown ~= "GO!" then
				lastCountdown = "GO!"
				controllers.SoundController:Play("Launch", 1.2)
			end
		else
			Widgets.SetVisible(countdown, false)
		end
		local remaining = if type(endAt) == "number" then math.max(0, endAt - now) else 0
		Widgets.SetText(timer, Format.Time(math.ceil(remaining)))
		local official = player:GetAttribute("DriftScore")
		Widgets.SetText(score, Format.Commas(if type(official) == "number" then official else 0))
		local local_ = session.Score
		Widgets.SetVisible(combo, local_.Active or local_.Circling)
		if local_.Circling then
			Widgets.SetText(combo, "🚫 NO DONUTS")
		elseif local_.Active then
			Widgets.SetText(combo, if local_.Combo > 1 then `DRIFT x{local_.Combo}!` else "DRIFT!")
		end
		boardElapsed += dt
		if boardElapsed >= 0.4 then
			boardElapsed = 0
			refreshBoard()
		end
	end)

	trove:Connect(driftController.Message, function(text: string, kind: string)
		messageToken += 1
		local token = messageToken
		Widgets.SetText(messageLabel, text)
		if messageLabel then
			messageLabel.TextColor3 = messageColors[kind] or Color3.fromRGB(255, 255, 255)
		end
		Widgets.SetVisible(messageLabel, true)
		task.delay(1.3, function()
			if messageToken == token then
				Widgets.SetVisible(messageLabel, false)
			end
		end)
	end)

	trove:Connect(driftController.Started, function()
		participating = true
		lastCountdown = ""
		local session = driftController:GetSession()
		Widgets.SetText(title, `🏁 {string.upper(if session then session.Title else "Drift event")}`)
		Widgets.SetVisible(results, false)
		setDrivingVisible(true)
		context.Close("Results")
		context.Open("Drift")
		refreshBoard()
	end)

	trove:Connect(driftController.Ended, function()
		setDrivingVisible(false)
		if not results or not results.Visible then
			context.Close("Drift")
		end
	end)

	local resultsConnection = Packets.DriftResults.OnClientEvent:Connect(
		function(board: { { Name: string, Score: number, UserId: number } })
			if not participating then
				return
			end
			participating = false
			resultsToken += 1
			local token = resultsToken
			for index, label in places do
				local item = board[index]
				local medals = { "🥇", "🥈", "🥉" }
				Widgets.SetText(
					label,
					if item then `{medals[index]} {item.Name}  {Format.Commas(item.Score)}` else ""
				)
			end
			Widgets.SetText(
				resultsNote,
				if #board == 0
					then `Nobody reached {Format.Commas(EventConfig.MinScore)} points`
					else "Prizes scale with your best run!"
			)
			setDrivingVisible(driving())
			Widgets.SetVisible(results, true)
			context.Open("Drift")
			Widgets.Pop(results)
			task.delay(EventConfig.Results, function()
				if resultsToken == token then
					Widgets.SetVisible(results, false)
					if not driving() then
						context.Close("Drift")
					end
				end
			end)
		end
	)

	trove:Add(function()
		resultsConnection:Disconnect()
	end)

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Drift
