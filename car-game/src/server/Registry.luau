--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local services: { Lifecycle.System } = {
	require(script.Parent.Services.DataService),
	require(script.Parent.Services.PurchaseService),
	require(script.Parent.Services.MultiplierService),
	require(script.Parent.Services.PassService),
	require(script.Parent.Services.LeaderboardService),
	require(script.Parent.Services.LaunchService),
	require(script.Parent.Services.GarageService),
	require(script.Parent.Services.UpgradeService),
	require(script.Parent.Services.RebirthService),
	require(script.Parent.Services.RewardService),
	require(script.Parent.Services.GameService),
	require(script.Parent.Services.ComponentService),
}

return services
