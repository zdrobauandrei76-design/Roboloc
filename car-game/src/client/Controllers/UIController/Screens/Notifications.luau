--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local maxToasts = 4
local toastSeconds = 3.5
local bannerSeconds = 4.5

local colors: { [string]: string } = {
	Success = "Green",
	Error = "Red",
	Info = "Blue",
}

local Notifications = {}

function Notifications.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local stack = Widgets.Frame(gui, "Stack")
	local template = Widgets.Frame(gui, "ToastTemplate")
	local banner = Widgets.Frame(gui, "Banner")
	local bannerText = Widgets.Text(gui, "BannerText")
	local toasts: { GuiObject } = {}
	local order = 0
	local bannerToken = 0

	if template then
		template.Visible = false
	end
	Widgets.SetVisible(banner, false)

	local function removeToast(toast: GuiObject)
		local index = table.find(toasts, toast)
		if index then
			table.remove(toasts, index)
		end
		toast:Destroy()
	end

	local function toast(text: string, kind: string)
		if not stack or not template then
			return
		end
		order += 1
		local item = template:Clone()
		item.Name = `Toast{order}`
		item.LayoutOrder = order
		item.Visible = true
		Widgets.SetText(item:FindFirstChild("ToastText", true), text)
		Widgets.Paint(item, colors[kind] or "Blue")
		item.Parent = stack
		table.insert(toasts, item)
		Widgets.Pop(item)
		while #toasts > maxToasts do
			removeToast(toasts[1])
		end
		task.delay(toastSeconds, function()
			if item.Parent then
				removeToast(item)
			end
		end)
	end

	local function announce(text: string)
		if not banner then
			return
		end
		bannerToken += 1
		local token = bannerToken
		Widgets.SetText(bannerText, text)
		banner.Visible = true
		Widgets.Pop(banner)
		task.delay(bannerSeconds, function()
			if bannerToken == token then
				banner.Visible = false
			end
		end)
	end

	local notifyConnection = Packets.Notify.OnClientEvent:Connect(function(text: string, kind: string)
		toast(text, kind)
		if kind == "Success" then
			controllers.SoundController:Play("Purchase")
		end
	end)
	local announceConnection = Packets.Announce.OnClientEvent:Connect(function(text: string)
		announce(text)
		controllers.SoundController:Play("Zone", 1.3)
	end)
	trove:Add(function()
		notifyConnection:Disconnect()
		announceConnection:Disconnect()
	end)
	trove:Add(function()
		for _, item in toasts do
			item:Destroy()
		end
		table.clear(toasts)
	end)

	return {
		Modal = false,
		StartsOpen = true,
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

return Notifications
