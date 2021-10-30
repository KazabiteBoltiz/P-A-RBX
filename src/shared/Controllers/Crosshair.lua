--// System
local plr = game.Players.LocalPlayer
local uiFolder = plr.PlayerGui

local RunS = game:GetService("RunService")
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local tween = game:GetService("TweenService")
local mouse = plr:GetMouse()
local cam = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")

local v3 = Vector3.new

--// Void
local Void = require(game.ReplicatedStorage.Void)
local Signal = require(Void.Util.Signal)

local CrosshairController = Void.CreateController{Name = "CrosshairController"}

--// Temporary Variables
local AllFrames = {}
CrosshairController.chWidth = 4
CrosshairController.chHeight = 10

CrosshairController.CenterSpace = 4

local chTweeninfo = TweenInfo.new(.4,Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

--// UI Init
local screenGui = Instance.new("ScreenGui",uiFolder)
screenGui.Enabled = true
screenGui.IgnoreGuiInset = true
screenGui.Name = "Crosshair"

local TopFrame = Instance.new("Frame",screenGui)
TopFrame.BorderSizePixel = 0
TopFrame.Name = "Top"
TopFrame.BackgroundColor3 = Color3.new(1,1,1)
TopFrame.AnchorPoint = Vector2.new(.5,1)
TopFrame.Position = UDim2.new(.5,0,.5,-CrosshairController.CenterSpace)
TopFrame.Size = UDim2.new(0,CrosshairController.chWidth,0,CrosshairController.chHeight)
local BottomFrame = Instance.new("Frame",screenGui)
BottomFrame.BorderSizePixel = 0
BottomFrame.Name = "Bottom"
BottomFrame.BackgroundColor3 = Color3.new(1,1,1)
BottomFrame.AnchorPoint = Vector2.new(.5,0)
BottomFrame.Position = UDim2.new(.5,0,.5,CrosshairController.CenterSpace)
BottomFrame.Size = UDim2.new(0,CrosshairController.chWidth,0,CrosshairController.chHeight)
local LeftFrame = Instance.new("Frame",screenGui)
LeftFrame.BorderSizePixel = 0
LeftFrame.Name = "Left"
LeftFrame.BackgroundColor3 = Color3.new(1,1,1)
LeftFrame.AnchorPoint = Vector2.new(1,.5)
LeftFrame.Position = UDim2.new(.5,-CrosshairController.CenterSpace,.5,0)
LeftFrame.Size = UDim2.new(0,CrosshairController.chHeight,0,CrosshairController.chWidth)
local RightFrame = Instance.new("Frame",screenGui)
RightFrame.BorderSizePixel = 0
RightFrame.Name = "Right"
RightFrame.BackgroundColor3 = Color3.new(1,1,1)
RightFrame.AnchorPoint = Vector2.new(0,.5)
RightFrame.Position = UDim2.new(.5,CrosshairController.CenterSpace,.5,0)
RightFrame.Size = UDim2.new(0,CrosshairController.chHeight,0,CrosshairController.chWidth)

table.insert(AllFrames, {TopFrame, UDim2.new(.5,0,.3,0),UDim2.new(.5,0,.5,-CrosshairController.CenterSpace)})
table.insert(AllFrames, {BottomFrame, UDim2.new(.5,0,.7,0),UDim2.new(.5,0,.5,CrosshairController.CenterSpace)})
table.insert(AllFrames, {LeftFrame, UDim2.new(.3,0,.5,0),UDim2.new(.5,-CrosshairController.CenterSpace,.5,0)})
table.insert(AllFrames, {RightFrame, UDim2.new(.7,0,.5,0),UDim2.new(.5,CrosshairController.CenterSpace,.5,0)})

--// Controller Functions
function CrosshairController:TweenIn()
    for i,v in ipairs(AllFrames) do
        v[1].BackgroundTransparency = 1
        v[1].Position = v[2]
        local InTween = tween:Create(v[1], chTweeninfo, {BackgroundTransparency = 0, Position = v[3]})
        InTween:Play()
    end
end

function CrosshairController:TweenOut()
    for i,v in ipairs(AllFrames) do
        v[1].BackgroundTransparency = 0
        v[1].Position = v[3]
        local OutTween = tween:Create(v[1], chTweeninfo, {BackgroundTransparency = 1, Position = v[2]})
        OutTween:Play()
    end
end

function CrosshairController:SetMouseEnabled(bool)
    UIS.MouseIconEnabled = bool
    UIS.MouseBehavior = not bool and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
end

return CrosshairController

