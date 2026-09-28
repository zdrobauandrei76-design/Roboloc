--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
type TroveInstance = typeof(Trove.new())

type State = {
	Name: string,
	_trove: TroveInstance?,
}

local AppController = {
	Name = "AppController",
	_trove = nil :: TroveInstance?,
}

local function disableControls()
	local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts", 15)
	local moduleScript = playerScripts and playerScripts:WaitForChild("PlayerModule", 15)
	if not moduleScript or not moduleScript:IsA("ModuleScript") then
		return
	end
	local ok, playerModule = pcall(require, moduleScript)
	if ok and type(playerModule) == "table" then
		local controls = (playerModule :: any):GetControls()
		if controls then
			controls:Disable()
		end
	end
end

local function onIncomingMessage(message: TextChatMessage): TextChatMessageProperties?
	local source = message.TextSource
	if not source then
		return nil
	end
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player or player:GetAttribute("VIP") ~= true then
		return nil
	end
	local properties = Instance.new("TextChatMessageProperties")
	properties.PrefixText = `<font color="#FFD23F">[VIP]</font> {message.PrefixText}`
	return properties
end

function AppController.Init(self: State, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function AppController.Start(self: State)
	local trove = self._trove
	if not trove then
		return
	end
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false)
	TextChatService.OnIncomingMessage = onIncomingMessage
	task.spawn(disableControls)
	trove:Connect(Players.LocalPlayer.CharacterAdded, function()
		task.defer(disableControls)
	end)
	print(`[{GameConfig.Name}] Client controllers ready`)
end

function AppController.Destroy(self: State)
	TextChatService.OnIncomingMessage = nil :: any
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return AppController
