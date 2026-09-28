--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CarModels = require(script.CarModels)
local Environment = require(script.Environment)
local HudScreens = require(script.HudScreens)
local Map = require(script.Map)
local PanelScreens = require(script.PanelScreens)

local StudioBuild = {}

local function assets(): Folder
	local existing = ReplicatedStorage:FindFirstChild("Assets")
	if existing and existing:IsA("Folder") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Assets"
	folder.Parent = ReplicatedStorage
	return folder
end

local function step(name: string, callback: () -> ())
	local started = os.clock()
	local ok, problem = pcall(function(): string?
		callback()
		return nil
	end)
	if ok then
		print(`[StudioBuild] {name} built in {string.format("%.1f", os.clock() - started)}s`)
	else
		warn(`[StudioBuild] {name} failed: {tostring(problem)}`)
	end
end

local function record(name: string, callback: () -> ())
	local recording: string? = nil
	local ok, result = pcall(function(): any
		return ChangeHistoryService:TryBeginRecording(name)
	end)
	if ok and type(result) == "string" then
		recording = result
	end
	callback()
	if recording then
		local active = recording
		pcall(function()
			ChangeHistoryService:FinishRecording(active, Enum.FinishRecordingOperation.Commit)
		end)
	end
end

function StudioBuild.BuildUI()
	record("Build UI", function()
		step("HUD screens", HudScreens.Build)
		step("Panel screens", PanelScreens.Build)
	end)
end

function StudioBuild.BuildCars()
	record("Build cars", function()
		step("Cars", function()
			local folder = assets()
			CarModels.Build(folder)
			Environment.RemoveLegacySounds(folder)
		end)
	end)
end

function StudioBuild.BuildMap()
	record("Build map", function()
		step("Map", Map.Build)
		step("Lighting", Environment.BuildLighting)
		step("Workspace", Environment.ConfigureWorkspace)
	end)
end

function StudioBuild.Build()
	StudioBuild.BuildCars()
	StudioBuild.BuildMap()
	StudioBuild.BuildUI()
	print("[StudioBuild] Done! Save the place (File > Save to Roblox), then press Play.")
end

return StudioBuild
