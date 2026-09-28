--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local refreshCooldown = 15

local Leaderboard = {}

function Leaderboard.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local list = Widgets.Frame(gui, "List")
	local template = Widgets.Frame(gui, "RowTemplate")
	local status = Widgets.Text(gui, "BoardStatus")
	local rows: { Instance } = {}
	local lastFetch = -math.huge
	local loading = false

	if template then
		template.Visible = false
	end

	local function clearRows()
		for _, row in rows do
			row:Destroy()
		end
		table.clear(rows)
	end

	local function fetch()
		if loading or os.clock() - lastFetch < refreshCooldown then
			return
		end
		loading = true
		lastFetch = os.clock()
		if #rows == 0 then
			Widgets.SetText(status, "Loading...")
			Widgets.SetVisible(status, true)
		end
		task.spawn(function()
			local entries = Packets.GetLeaderboard:Fire()
			loading = false
			if type(entries) ~= "table" then
				lastFetch = -math.huge
				Widgets.SetText(status, "Couldn't load the leaderboard. Try again soon!")
				Widgets.SetVisible(status, #rows == 0)
				return
			end
			clearRows()
			Widgets.SetText(status, "No jumps yet. Be the first!")
			Widgets.SetVisible(status, #entries == 0)
			if not list or not template then
				return
			end
			for rank, entry in entries do
				local row = template:Clone()
				row.Name = `Row{rank}`
				row.LayoutOrder = rank
				row.Visible = true
				local medal = if rank == 1
					then "🥇"
					elseif rank == 2 then "🥈"
					elseif rank == 3 then "🥉"
					else `#{rank}`
				Widgets.SetText(row:FindFirstChild("Rank", true), medal)
				Widgets.SetText(row:FindFirstChild("PlayerName", true), entry.Name)
				Widgets.SetText(row:FindFirstChild("Value", true), Format.Distance(entry.Value))
				Widgets.Paint(row, if entry.UserId == Players.LocalPlayer.UserId then "Gold" else "Card")
				row.Parent = list
				table.insert(rows, row)
			end
		end)
	end

	trove:Add(clearRows)

	return Widgets.ModalScreen(context, gui, "Leaderboard", trove, fetch)
end

return Leaderboard
