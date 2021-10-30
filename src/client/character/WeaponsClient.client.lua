local Void = require(game.ReplicatedStorage.Void)
local Promise = require(Void.Util.Promise)

--// System
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local RenderS = game:GetService("RunService").RenderStepped
local uis = game:GetService("UserInputService")
local mouse = plr:GetMouse()

--// Modules
local Modules = game.ReplicatedStorage.Modules
local SoundSys3D = require(Modules.SoundSys3D)
local WeaponStats = require(Modules:WaitForChild("WeaponStats"))

--// Void
local InventoryService = Void.GetService("InventoryService")
local StatesController = Void.GetController("StatesController")
local ViewmodelController = Void.GetController("ViewmodelController")
local TracerController = Void.GetController("TracerController")

local WeaponAction = InventoryService.WeaponAction
local Database = InventoryService.Database

--// Temporary Variables
local MouseDown = false

local FetchedDatabase = {}
local Equipped;
local AmmoInMag = 0;
local AmmoInBag = 0;

local LastShot = 0

local InputKeys = {
    ["Reload"] = Enum.KeyCode.R,
    ["Inspect"] = Enum.KeyCode.J
}

local function UnpackDatabaseFetch(db)
	Equipped = db.Name
	AmmoInMag = db.AmmoInMag
	AmmoInBag = db.AmmoInBag

	print("Updated!")

	StatesController.WeaponChanged:Fire(Equipped)
end

local function RequestEquipped()
	local DataFetchPromise = Promise.new(function(resolve)
        local fetchedValue
        while fetchedValue == nil do
            fetchedValue = InventoryService.Database:Get()[plr.Name]
        end
        resolve(fetchedValue)
		FetchedDatabase = fetchedValue[fetchedValue[1]+1]
    end)

	DataFetchPromise:ThenCall(UnpackDatabaseFetch, FetchedDatabase)
end

Void.OnStart():Await()
--// Void is Ready

InventoryService.Database.Changed:Connect(function(value)
	RequestEquipped()
end)

RequestEquipped()

uis.InputBegan:Connect(function(input, typing)
	if typing then return end
	local key = input.KeyCode 

	if key == InputKeys["Reload"] then
		WeaponAction:Fire("Reload")
	elseif key == InputKeys["Inspect"] then
		WeaponAction:Fire("Inspect")
	end
end)

mouse.Button1Down:Connect(function()
	MouseDown = true
	while MouseDown do
		if Equipped then
			if tick() - LastShot > WeaponStats[Equipped].FireRate then
				
				TracerController:SimulateBullet(ViewmodelController:GetViewmodel())
				StatesController.WeaponUsed:Fire()

				LastShot = tick()
			end
		end
		wait(WeaponStats[Equipped].FireRate)
	end
end)

mouse.Button1Up:Connect(function()
	print("f")
	MouseDown = false                                                                   ;--8
end)

mouse.WheelForward:Connect(function()
	WeaponAction:Fire("ScrollUp")
end)

mouse.WheelBackward:Connect(function()
	WeaponAction:Fire("ScrollDown")
end)