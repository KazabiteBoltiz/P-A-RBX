--//System
local RunS = game:GetService("RunService")
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local mouse = plr:GetMouse()
local cam = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local cf = CFrame.new

local v3 = Vector3.new

--// Void
local Void = require(game.ReplicatedStorage.Void)
local Signal = require(Void.Util.Signal)

local CameraController = Void.CreateController{Name = "CameraController"}
local ViewmodelController;
local StatesController;

--// Temporary Variables
local oldCamCF = cf()
local ActiveViewmodel;
local OffsetZ = 0;
local vm = nil

CameraController.PositionTarget = char:WaitForChild("HumanoidRootPart") 
CameraController.PositionOffset = v3(0,2,0)

CameraController.CameraEnabled = false
CameraController.MouseSensitivity = .8
CameraController.CurrentRecoilOffset = v3(0,0,0)
local MouseRotationCap = 1.4                 --ToRad, capping MouseDelta
local DeltaToAngleX, DeltaToAngleY = 0,0     --DeltaCalculatedAngle (Recoil Reset)
local DeltaX, DeltaY = 0,0                   --TrueMouseDelta (Camera Movement)

--// Support Functions
local function UpdateCameraWithDelta()

    if ActiveViewmodel then
        local newCamCF = ActiveViewmodel.CameraPart.CFrame:ToObjectSpace(ActiveViewmodel.ModelRoot.CFrame)
        if oldCamCF then
            -- cam.CFrame = cam.CFrame * newCamCF:ToObjectSpace(newCamCF)
            local _,_,z = newCamCF:ToOrientation()
            -- local x,y,_ = newCamCF:ToObjectSpace(oldCamCF):ToEulerAnglesXYZ()
            OffsetZ = -z
        end
        
        oldCamCF = newCamCF 
    end

    local RotX, RotY, RotZ = cam.CFrame:ToOrientation()
	cam.CFrame = CFrame.fromOrientation(
        math.clamp(RotX - math.rad(DeltaY),-MouseRotationCap,MouseRotationCap),
        RotY - math.rad(DeltaX),
        OffsetZ                               --in case of Added CameraShake, please update :D
        )
        + CameraController.PositionTarget.Position
        + CameraController.PositionOffset
        or Vector3.new(0,0,0)

    char.HumanoidRootPart.CFrame = CFrame.fromOrientation(0,RotY,0) + char.HumanoidRootPart.Position
end

local function OnCameraMoved()
    local Delta = UIS:GetMouseDelta()
	DeltaToAngleX += Delta.X * CameraController.MouseSensitivity 
	DeltaX = Delta.X * CameraController.MouseSensitivity

	DeltaToAngleY += Delta.Y * CameraController.MouseSensitivity
	DeltaY = Delta.Y * CameraController.MouseSensitivity
	
	UpdateCameraWithDelta()
end

local function CameraSetupFunction()
    cam.CameraType = Enum.CameraType.Scriptable
    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
    if CameraController.CameraEnabled then
        OnCameraMoved()
    end
end

--// Controller Functions

function CameraController:VoidStart()
    ViewmodelController = Void.GetController("ViewmodelController")
    StatesController = Void.GetController("StatesController")

    StatesController.WeaponChanged:Connect(function(weapon)
        print("received weapon",weapon,"at camCont")
        ActiveViewmodel = ViewmodelController:GetViewmodel() or workspace.Terrain:WaitForChild(weapon)
    end)

    RunS:BindToRenderStep("CameraMovement", 0, CameraSetupFunction)
end

function CameraController:SetCharacterVisible(bool)
    for i,v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("MeshPart") then
            v.Transparency = bool and 0 or 1
        end
    end
end

function CameraController:BeginTrace()
    CameraController.CameraEnabled = true
end

function CameraController:EndTrace()
    CameraController.CameraEnabled = false
end    

return CameraController