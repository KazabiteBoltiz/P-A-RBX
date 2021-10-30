--//System
local RunS = game:GetService("RunService")
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local cam = workspace.CurrentCamera
local v3 = Vector3.new

--// Void
local Void = require(game.ReplicatedStorage.Void)
local Signal = require(Void.Util.Signal)

local StatesController = Void.CreateController{Name = "StatesController"}

--// Signals
StatesController.WeaponChanged = Signal.new()
StatesController.WeaponUsed = Signal.new()

StatesController.WeaponUsed:Connect(function()
    print("SINGULLED")
end)

return StatesController