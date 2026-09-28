--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local WaitFor = require(ReplicatedStorage.Packages.WaitFor)

local SoundController = { Name = "SoundController" }
local sounds: { [string]: Sound } = {}
local baseVolumes: { [string]: number } = {}
local folder: Folder? = nil
local pending: any = nil
local muted = false

function SoundController.Init(_self: any, _controllers: { [string]: any }) end

local function load(source: Instance)
	local target = Instance.new("Folder")
	target.Name = "GameSounds"
	for _, child in source:GetChildren() do
		if child:IsA("Sound") then
			local sound = child:Clone()
			sound.Parent = target
			sounds[sound.Name] = sound
			baseVolumes[sound.Name] = sound.Volume
		end
	end
	target.Parent = SoundService
	folder = target
	local music = sounds.Music
	if music and music.SoundId ~= "" then
		music.Looped = true
		music:Play()
	end
end

function SoundController.Start(_self: any)
	pending = WaitFor.Child(ReplicatedStorage, "Assets", 15)
		:andThen(function(assets: Instance)
			return WaitFor.Child(assets, "Sounds", 15)
		end)
		:andThen(load)
		:catch(function(problem: any)
			warn(
				`[SoundController] Sounds disabled; needs ReplicatedStorage.Assets.Sounds: {tostring(problem)}`
			)
		end)
end

function SoundController.Play(_self: any, name: string, pitch: number?)
	local sound = sounds[name]
	if not sound or muted or sound.SoundId == "" then
		return
	end
	sound.PlaybackSpeed = pitch or 1
	sound.TimePosition = 0
	sound:Play()
end

function SoundController.SetLoop(_self: any, name: string, playing: boolean, volume: number?, pitch: number?)
	local sound = sounds[name]
	if not sound or sound.SoundId == "" then
		return
	end
	sound.Looped = true
	if volume then
		sound.Volume = volume
	end
	if pitch then
		sound.PlaybackSpeed = pitch
	end
	if playing and not muted and not sound.IsPlaying then
		sound:Play()
	elseif (not playing or muted) and sound.IsPlaying then
		sound:Stop()
	end
end

function SoundController.SetMuted(_self: any, isMuted: boolean)
	muted = isMuted
	for name, sound in sounds do
		if name == "Music" then
			sound.Volume = if isMuted then 0 else baseVolumes[name] or 0.35
		elseif isMuted then
			sound:Stop()
		end
	end
end

function SoundController.IsMuted(_self: any): boolean
	return muted
end

function SoundController.Destroy(_self: any)
	if pending then
		pending:cancel()
		pending = nil
	end
	if folder then
		folder:Destroy()
		folder = nil
	end
	table.clear(sounds)
	table.clear(baseVolumes)
end

return SoundController
