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

local ViewmodelController;
local TracerController = Void.CreateController{Name = "TracerController"}

local BulletParameters = RaycastParams.new()
BulletParameters.IgnoreWater = true
BulletParameters.FilterDescendantsInstances = {char, workspace.Terrain}
BulletParameters.FilterType = Enum.RaycastFilterType.Blacklist

--// Supportive Functions
local function CastRay(Origin, Direction)
    local raycastResult = workspace:Raycast(Origin, Direction, BulletParameters)
    return raycastResult
end

local function CheckIfPlayerHit(raycastResult)
    if game.Players:GetPlayerFromCharacter(raycastResult.Instance.Parent) then
        return  game.Players:GetPlayerFromCharacter(raycastResult.Instance.Parent)
    end
end

local function FetchMuzzle(GunInstance)
    local Muzzle = GunInstance.Rifle:WaitForChild("Muzzle")
    local MuzzlePos = Muzzle.Barrel.FlarePosition.WorldPosition
    local FlareEffect = Muzzle.Flare.ParticleEmitter
    local Light = Muzzle.Flare.Light
    return MuzzlePos, FlareEffect, Light
end

local function MakeClientBullet(GunInstance, endPosition)
    local muzzleEnd = FetchMuzzle(GunInstance)
    local bullet = GunInstance.BulletPrefab:Clone()

    bullet.CFrame = CFrame.new(muzzleEnd.WorldPosition, endPosition) * CFrame.Angles(0,180,0)
    bullet.Parent = workspace.Terrain

    bullet.Size = v3(0.13, 0.13, .1)

    local tween1 = game.TweenService:Create(bullet, TweenInfo.new(((muzzleEnd.WorldPosition - endPosition)).Magnitude/500, Enum.EasingStyle.Linear,Enum.EasingDirection.Out), {Position = (muzzleEnd.WorldPosition + endPosition)/2, Size = v3(.17,.17, 16)})
    tween1:Play()
    tween1.Completed:Connect(function()
        local tween2 = game.TweenService:Create(bullet, TweenInfo.new(((muzzleEnd.WorldPosition - endPosition)).Magnitude/500, Enum.EasingStyle.Linear,Enum.EasingDirection.Out), {Position = (endPosition), Size = v3()})
        tween2:Play()
    end)
end

--MainFunctions
function TracerController:SimulateBullet(GunInstance)
    if ViewmodelController then
        ViewmodelController:PlayAnimation("Fire") 
    end
    local Origin = cam.CFrame.Position
    local Direction = cam.CFrame.LookVector * 100

    local MuzzlePos, Flare, Light = FetchMuzzle(GunInstance)
    Flare:Emit(1)

    spawn(function()
        Light.Enabled = true
        wait(.1)
        Light.Enabled = false
    end)

    local rayRes = CastRay(Origin, Direction)
    if rayRes then
        CheckIfPlayerHit(rayRes)
    end
end

function TracerController:VoidStart()
    ViewmodelController = Void.GetController("ViewmodelController")
end

return TracerController