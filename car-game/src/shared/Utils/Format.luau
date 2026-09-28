--!strict

local suffixes = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local Format = {}

function Format.Commas(value: number): string
	local whole = math.floor(math.abs(value))
	local text = tostring(whole)
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return if value < 0 then "-" .. formatted else formatted
end

function Format.Short(value: number): string
	if value ~= value then
		return "0"
	end
	local absolute = math.abs(value)
	if absolute < 10000 then
		return Format.Commas(value)
	end
	local tier = math.min(math.floor(math.log10(absolute) / 3), #suffixes)
	local scaled = absolute / 10 ^ (tier * 3)
	if scaled >= 1000 and tier < #suffixes then
		tier += 1
		scaled /= 1000
	end
	local decimals = if scaled >= 100 then 0 elseif scaled >= 10 then 1 else 2
	local factor = 10 ^ decimals
	local truncated = math.floor(scaled * factor) / factor
	local text = string.format(`%.{decimals}f`, truncated)
	if decimals > 0 then
		text = text:gsub("0+$", ""):gsub("%.$", "")
	end
	return (if value < 0 then "-" else "") .. text .. suffixes[tier]
end

function Format.Cash(value: number): string
	return "$" .. Format.Short(value)
end

function Format.Distance(value: number): string
	return Format.Short(math.floor(value)) .. " m"
end

function Format.Multiplier(value: number): string
	local rounded = math.floor(value * 100 + 0.5) / 100
	local text = string.format("%.2f", rounded):gsub("%.?0+$", "")
	return "x" .. text
end

function Format.Time(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	local hours = total // 3600
	local minutes = (total % 3600) // 60
	local secs = total % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

return Format
