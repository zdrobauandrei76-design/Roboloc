--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local SoundSprite = require(ReplicatedStorage.Config.SoundSprite)
local Sounds = require(ReplicatedStorage.Config.Sounds)

type Entry = {
	Sound: Sound,
	Volume: number,
	Start: number,
}

local SoundController = { Name = "SoundController" }
local entries: { [string]: Entry } = {}
local music: Sound? = nil
local folder: Folder? = nil
local muted = false

function SoundController.Init(_self: any, _controllers: { [string]: any }) end

local function create(name: string, definition: Sounds.Sound, parent: Folder)
	local region = (SoundSprite :: any)[name]
	local useSprite = definition.Id == "" and Sounds.SpriteId ~= "" and region ~= nil
	local id = if definition.Id ~= ""
		then definition.Id
		elseif useSprite then Sounds.SpriteId
		else definition.Fallback
	if id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = definition.Volume
	local start = 0
	if useSprite and region then
		start = region.Start
		sound.PlaybackRegionsEnabled = true
		sound.PlaybackRegion = NumberRange.new(region.Start, region.Start + region.Length)
		if region.Looped then
			sound.LoopRegion = NumberRange.new(region.Start, region.Start + region.Length)
		end
	end
	sound.Parent = parent
	entries[name] = { Sound = sound, Volume = definition.Volume, Start = start }
end

function SoundController.Start(_self: any)
	local target = Instance.new("Folder")
	target.Name = "GameSounds"
	for name, definition in Sounds.Sounds do
		create(name, definition, target)
	end
	if Sounds.MusicId ~= "" then
		local track = Instance.new("Sound")
		track.Name = "Music"
		track.SoundId = Sounds.MusicId
		track.Volume = Sounds.MusicVolume
		track.Looped = true
		track.Parent = target
		music = track
	end
	target.Parent = SoundService
	folder = target
	if music then
		music:Play()
	end
end

function SoundController.Play(_self: any, name: string, pitch: number?)
	local entry = entries[name]
	if not entry or muted then
		return
	end
	local sound = entry.Sound
	sound.Looped = false
	sound.PlaybackSpeed = pitch or 1
	sound.TimePosition = entry.Start
	sound:Play()
end

function SoundController.SetLoop(_self: any, name: string, playing: boolean, volume: number?, pitch: number?)
	local entry = entries[name]
	if not entry then
		return
	end
	local sound = entry.Sound
	sound.Looped = true
	sound.Volume = entry.Volume * (volume or 1)
	if pitch then
		sound.PlaybackSpeed = pitch
	end
	if playing and not muted and not sound.IsPlaying then
		sound.TimePosition = entry.Start
		sound:Play()
	elseif (not playing or muted) and sound.IsPlaying then
		sound:Stop()
	end
end

function SoundController.SetMuted(_self: any, isMuted: boolean)
	muted = isMuted
	if music then
		music.Volume = if isMuted then 0 else Sounds.MusicVolume
	end
	if isMuted then
		for _, entry in entries do
			entry.Sound:Stop()
		end
	end
end

function SoundController.IsMuted(_self: any): boolean
	return muted
end

function SoundController.Destroy(_self: any)
	if folder then
		folder:Destroy()
		folder = nil
	end
	music = nil
	table.clear(entries)
end

return SoundController
