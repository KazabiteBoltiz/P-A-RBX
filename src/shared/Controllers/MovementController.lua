---System
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local v3 = Vector3.new
local RepS = game.ReplicatedStorage
local cam = workspace.CurrentCamera
local RunS = game:GetService("RunService")
local HeartB = RunS.Heartbeat
local UIS = game:GetService("UserInputService")
local InputIn, InputOut = UIS.InputBegan, UIS.InputEnded
local Modules = RepS.Modules
local Springs = require(Modules.Springs)

---Void
local Void = require(game.ReplicatedStorage.Void)
local MovementController = Void.CreateController{Name = "MovementController"}
local Signal = require(Void.Util.Signal)

---Temporary Variables
local MovementDirection = Springs.new(v3())
MovementDirection.Speed = 16
MovementDirection.Damper = 1
local Front,Side = v3(0,0,1),v3(1,0,0)
local ShiftHeld = false
local WalkSpeedTween = game.TweenService:Create(humanoid, TweenInfo.new(.2,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{WalkSpeed = 2})
local RunSpeedTween = game.TweenService:Create(humanoid, TweenInfo.new(.2,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{WalkSpeed = 20})

---Supportive Variables
local InputKeys = {
    ["Front"] = Enum.KeyCode.W,
    ["Back"] = Enum.KeyCode.S,
    ["Left"] = Enum.KeyCode.A,
    ["Right"] = Enum.KeyCode.D,
    ["Jump"] = Enum.KeyCode.Space,
    ["Run"] = Enum.KeyCode.LeftShift or Enum.KeyCode.RightShift
}

function MovementController:GetMovementFactor()
    return MovementDirection.Position.Magnitude
end

InputIn:Connect(function(input, typing)
    if typing then return end
    local key = input.KeyCode

    if key == InputKeys["Front"] then
        MovementDirection.Target -= Front
    elseif key == InputKeys["Back"] then
        MovementDirection.Target += Front
    elseif key == InputKeys["Left"] then
        MovementDirection.Target -= Side
    elseif key == InputKeys["Right"] then
        MovementDirection.Target += Side
    elseif key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift then
		WalkSpeedTween:Play()
    end
end)

InputOut:Connect(function(input)
    local key = input.KeyCode

    if key == InputKeys["Front"] then
        MovementDirection.Target += Front
    elseif key == InputKeys["Back"] then
        MovementDirection.Target -= Front
    elseif key == InputKeys["Left"] then
        MovementDirection.Target += Side
    elseif key == InputKeys["Right"] then
        MovementDirection.Target -= Side
    elseif key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift then
		RunSpeedTween:Play()
    end
end)

RunS:BindToRenderStep("Walking", 100, function()
	plr:Move(MovementDirection.Position, true)
end)

return MovementController