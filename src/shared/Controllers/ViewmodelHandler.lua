--Globals
local plr = game.Players.LocalPlayer;
local char = plr.Character or plr.CharacterAdded:Wait();
local humanoid = char:WaitForChild("Humanoid")
local cam = workspace.CurrentCamera;
--System
local Void = require(game.ReplicatedStorage.Void)
local Signal = require(Void.Util.Signal)
local RepS = game:GetService("ReplicatedStorage");
local cf = CFrame.new;
local cfa = CFrame.Angles
local v3 = Vector3.new;
local RenderS = game:GetService("RunService").RenderStepped;
local Modules = RepS.Modules
local Springs = require(Modules.Springs)

--Locals
local ViewmodelDirectory = RepS.Assets.Viewmodels;
local CameraOffset = cf();
local ActiveViewmodel;
local ActiveRoot;
local RenderService;
local AnimationSet;
local moveFactor = Springs.new(0)
moveFactor.Speed = 100
-- moveFactor.Damper = .1

--temp vars
local sway = cf()
local lastSwayCF = cf()
local WalkCF = cf()
plr.PlayerGui.screen.vp.CurrentCamera = cam
plr.PlayerGui.screen.vp.Active = false

local ViewmodelController = Void.CreateController{Name = "ViewmodelController"}
ViewmodelController.ViewmodelChanged = Signal.new()

---SupportiveFunctions
local function FetchViewmodelOffset()
    local PosOffset = ActiveViewmodel:WaitForChild("CameraOffset").Value
    local RotOffset = ActiveViewmodel:WaitForChild("CameraOffsetRot").Value
    return cf(PosOffset.X, PosOffset.Y, PosOffset.Z) * cfa(RotOffset.X, RotOffset.Y, RotOffset.Z)
end

local function FetchViewmodelInstance(modelID)
    return ViewmodelDirectory:FindFirstChild(modelID)
end    

local function FetchPlayingAnimation(animID)
    for name, track in pairs(ActiveViewmodel:FindFirstChild("AnimationController"):GetPlayingAnimationTracks()) do
        if name == animID then
            return track
        end
    end
end

local function FetchModelData(model)
    return {model:FindFirstChild("ModelRoot"), 
        model:FindFirstChild("CameraOffset").Value, 
        model:FindFirstChild("AnimationSet")}
end

local TweenService = game:GetService("TweenService")
local TweenTime = 0.3 -- Amount of time for transmission
local startTime = 0
local t = tick()

local function update()
    moveFactor.Target = humanoid.MoveDirection.Magnitude
    if moveFactor.Position > .2 then
        t = tick()

        local MoveFactor = math.clamp(moveFactor.Position-.2,0,1)
        local x = math.cos(t * 10) * (MoveFactor/6)
        local y = math.abs(math.sin(t * 10)) * (MoveFactor/6)

        WalkCF = WalkCF:Lerp(CFrame.new(x * MoveFactor, y * MoveFactor, 0),.2)
    else
        WalkCF = WalkCF:Lerp(cf(),.4)
    end
    return WalkCF
end

---FrontEndFunctions

function ViewmodelController:PlayAnimation(animID, time)

    if AnimationSet then
        local Animation = AnimationSet:FindFirstChild(animID) 
        local AnimationController = ActiveViewmodel:FindFirstChild("AnimationController")

        local AnimationTrack = AnimationController:LoadAnimation(Animation)
        
        if not time then
            AnimationTrack:Play()
        else
            local speed = AnimationTrack.Length / time
            AnimationTrack:AdjustSpeed(speed)
            AnimationTrack:Play()
        end
    end

end    

function ViewmodelController:StopAnimation(animID)

    if animID and FetchPlayingAnimation(animID) then
        FetchPlayingAnimation(animID):Stop()
    end

end    

function ViewmodelController:ActivateViewmodel(modelID)

    if FetchViewmodelInstance(modelID) and FetchViewmodelInstance(modelID) ~= ActiveViewmodel then

        if ActiveViewmodel then ActiveViewmodel:Destroy() end

        ActiveViewmodel = FetchViewmodelInstance(modelID):Clone()
        ActiveRoot, CameraOffset, AnimationSet = 
            FetchModelData(ActiveViewmodel)[1], 
            FetchViewmodelOffset(), 
            FetchModelData(ActiveViewmodel)[3]
        ActiveViewmodel.Parent = workspace.Terrain

        if RenderService then RenderService:Disconnect() RenderService = nil end

        local lastCF = cam.CFrame
        local sinValue = 0

        RenderService = RenderS:Connect(function(dt)
            
        update()

        --// Sway
                
            local deltaRatio = 1000 / (1 / dt) --//deltaFramerate is the framerate you want things to update in, 60 is usually a good pick
	
            local function calculateSine(speed) --//for idle sway
                sinValue += speed * deltaRatio
                if sinValue > (math.pi * 2) then sinValue = 0 end
                local sineY = .2 * math.sin(2 * sinValue)
                local sineZ = 200 * math.sin(sinValue)
                local sineCFrame = CFrame.new(sineZ, sineY, 0)
                return sineCFrame
            end
        
            local swaymultiplier = -.5 --//sway speed
            local x, y, z = workspace.Camera.CFrame:toObjectSpace(lastSwayCF):ToOrientation() 
            sway = sway:Lerp(CFrame.Angles(math.clamp(math.sin(x) * swaymultiplier,-.08,.08), math.clamp(math.sin(y) * swaymultiplier,-.08,.08), 0), 0.1)  --//for gun sway
            
            local sineCFrame = calculateSine(-.05)
            local swayCF = (cam.CFrame * CameraOffset * sineCFrame) * sway
            lastSwayCF = cam.CFrame

            ActiveRoot.CFrame = cam.CFrame * CameraOffset * sway * WalkCF 

        end)

        ViewmodelController:PlayAnimation("Idle")

    end

end  

function ViewmodelController:GetViewmodel() 
    return ActiveViewmodel
end

function ViewmodelController:VoidInit()
    local StatesController = Void.GetController("StatesController")
    
    StatesController.WeaponChanged:Connect(function(weapon)
        print("activating viewmodel at vmCont :",weapon)
        ViewmodelController:ActivateViewmodel(weapon)
    end)
    StatesController.WeaponUsed:Connect(function()
        if ActiveViewmodel then
            ViewmodelController:PlayAnimation("Fire")
        end
    end)
end

--// External

return ViewmodelController


