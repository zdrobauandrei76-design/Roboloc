--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local SoundSprite = require(ReplicatedStorage.Config.SoundSprite)
local Sounds = require(ReplicatedStorage.Config.Sounds)

type Entry = {
	Sound: Sound,
	Volume: number,
	Start: number,
	Fallback: boolean,
}

local SoundController = { Name = "SoundController" }
local entries: { [string]: Entry } = {}
local music: Sound? = nil
local folder: Folder? = nil
local muted = false

function SoundController.Init(_self: any, _controllers: { [string]: any }) end

local function contentId(value: any): string
	local trimmed = string.match(tostring(value or ""), "^%s*(.-)%s*$") or ""
	if string.find(trimmed, "^rbxasset://") then
		return trimmed
	end
	local text = string.gsub(trimmed, "%s", "")
	if text == "" then
		return text
	end
	local digits = string.match(text, "^(%d+)$")
		or string.match(text, "rbxassetid://(%d+)")
		or string.match(text, "[?&]id=(%d+)")
		or string.match(text, "/(%d+)")
	return if digits then `rbxassetid://{digits}` else text
end

local spriteId = contentId(Sounds.SpriteId)

local function create(name: string, definition: Sounds.Sound, parent: Folder, useFallback: boolean): ()
	local region = (SoundSprite :: any)[name]
	local customId = contentId(definition.Id)
	local useSprite = not useFallback and customId == "" and spriteId ~= "" and region ~= nil
	local id = if useFallback
		then definition.Fallback
		elseif customId ~= "" then customId
		elseif useSprite then spriteId
		else definition.Fallback
	local previous = entries[name]
	if previous then
		previous.Sound:Destroy()
		entries[name] = nil
	end
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
		local ok = pcall(function()
			sound.PlaybackRegionsEnabled = true
			sound.PlaybackRegion = NumberRange.new(region.Start, region.Start + region.Length)
			if region.Looped then
				sound.LoopRegion = NumberRange.new(region.Start, region.Start + region.Length)
			end
		end)
		if not ok then
			sound:Destroy()
			create(name, definition, parent, true)
			return
		end
	end
	sound.Parent = parent
	entries[name] = {
		Sound = sound,
		Volume = definition.Volume,
		Start = start,
		Fallback = id == definition.Fallback,
	}
end

local function verify(target: Folder)
	local instances: { Instance } = {}
	for _, entry in entries do
		if not entry.Fallback then
			table.insert(instances, entry.Sound)
		end
	end
	if music then
		table.insert(instances, music)
	end
	if #instances == 0 then
		return
	end
	local failed: { [string]: boolean } = {}
	local ok = pcall(function()
		ContentProvider:PreloadAsync(instances, function(id: string, status: Enum.AssetFetchStatus)
			if status == Enum.AssetFetchStatus.Failure then
				failed[contentId(id)] = true
			end
		end)
	end)
	if not ok or folder ~= target then
		return
	end
	for id in failed do
		warn(
			`[SoundController] Could not load {id}. Check the ID in Config/Sounds.luau, that the audio has finished moderation on create.roblox.com, and that the game's owner (you, or the group) also owns the audio. Using the built-in sounds until then.`
		)
	end
	for name, definition in Sounds.Sounds do
		local entry = entries[name]
		if entry and failed[contentId(entry.Sound.SoundId)] then
			create(name, definition, target, true)
		end
	end
end

function SoundController.Start(_self: any)
	local target = Instance.new("Folder")
	target.Name = "GameSounds"
	for name, definition in Sounds.Sounds do
		create(name, definition, target, false)
	end
	local musicId = contentId(Sounds.MusicId)
	if musicId ~= "" then
		local track = Instance.new("Sound")
		track.Name = "Music"
		track.SoundId = musicId
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
	task.spawn(verify, target)
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
