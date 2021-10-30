local Void = require(game.ReplicatedStorage.Void)
local RemoteProperty = require(Void.Util.Remote.RemoteProperty)

local Modules = game.ReplicatedStorage.Modules
local WeaponStats = require(Modules:WaitForChild("WeaponStats"))

local DatabaseList = {}

Void.OnStart():Await()

--// Void is Ready
local InventoryService = Void.GetService("InventoryService")
local Database = InventoryService.Client.Database

--// System
local Database = InventoryService.Client.Database
local WeaponAction = InventoryService.Client.WeaponAction

local function UpdateDB()
	Database:Set(DatabaseList)
	Database:Replicate()
	print("Updated!")
end

local WeaponActions = {
	["ScrollUp"] = function(plr)
		local dbTable = DatabaseList[plr.Name]
		local equipped = dbTable[dbTable[1]+1]
		local target;
		
		if dbTable[1] == (#dbTable - 1) then 
			target = 1
		else
			target = dbTable[1] + 1 
		end

		if dbTable[target+1].Name ~= equipped.Name then
			dbTable[1] = dbTable[target+1]
		end

		UpdateDB()
	end,
	["ScrollDown"] = function(plr)
		local dbTable = DatabaseList[plr.Name]
		local equipped = dbTable[dbTable[1]+1]
		local target;

		if dbTable[1] == 1 then 
			target = #dbTable - 1 
		else 
			target = dbTable[1] - 1 
		end

		if dbTable[target+1].Name ~= equipped.Name then
			dbTable[1] = dbTable[target+1]
		end

		UpdateDB()
	end,
	["Reload"] = function(plr)
		local dbTable = DatabaseList[plr.Name]
		local equipped = dbTable[dbTable[1]+1]
		
		if equipped.AmmoInMag < WeaponStats[equipped].MagCapacity then
			equipped.AmmoInMag = WeaponStats[equipped].MagCapacity
			equipped.AmmoInBag -= WeaponStats[equipped].MagCapacity - WeaponStats[equipped].AmmoInMag
		end
	end
}

game.Players.PlayerAdded:Connect(function(plr)
	DatabaseList[plr.Name] = {
		1,
		{Name = "D-RAK", AmmoInMag = 35, AmmoInBag = 90}
	}
	UpdateDB()
end)

WeaponAction:Connect(function(plr, action, data)
	WeaponActions[action](plr, data)
end)

