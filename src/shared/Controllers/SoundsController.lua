--Globals
local plr = game.Players.LocalPlayer;
local char = plr.Character or plr.CharacterAdded:Wait();
local humanoid = char:WaitForChild("Humanoid")
local cam = workspace.CurrentCamera;
--System
local Void = require(game.ReplicatedStorage.Void)
local RepS = game:GetService("ReplicatedStorage");
local cf = CFrame.new;
local cfa = CFrame.Angles
local v3 = Vector3.new;
local RenderS = game:GetService("RunService").RenderStepped;
local Modules = game.ReplicatedStorage.Modules
local SS3D = require(Modules.SoundSys3D)

local StatesController;
local SoundsController = Void.CreateController{Name = "SoundsController"}

--// Temporary Variables 


--// Main Functions 
function SoundsController:PlaySound(id, target, volume, doLoop)
    SS3D:Create(id, target, volume, doLoop)
end

function SoundsController:VoidStart()
    StatesController = Void.GetController("StatesController")
end

return SoundsController