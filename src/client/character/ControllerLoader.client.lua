local Void = require(game.ReplicatedStorage.Void)
local plr = game.Players.LocalPlayer
local Players = game:GetService("Players")

Void.OnStart():Await()

--// Blind Loads
Void.GetController("MovementController")

--// Specific Loads
local CameraController = Void.GetController("CameraController")
CameraController:SetCharacterVisible(false)
CameraController:BeginTrace()

local CrosshairController = Void.GetController("CrosshairController")
CrosshairController:TweenIn()
CrosshairController:SetMouseEnabled(false)

--// Services (Specific)
local InventoryService = Void.GetService("InventoryService")