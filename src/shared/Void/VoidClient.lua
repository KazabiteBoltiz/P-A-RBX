--!strict

--[[

	Void.CreateController(controller): Controller
	Void.AddControllers(folder): Controller[]
	Void.AddControllersDeep(folder): Controller[]
	Void.GetService(serviceName): Service
	Void.GetController(controllerName): Controller
	Void.Start(): Promise<void>
	Void.OnStart(): Promise<void>

--]]


type ControllerDef = {
	Name: string,
	[any]: any,
}

type Controller = {
	Name: string,
	[any]: any,
}

type Service = {
	[any]: any,
}


local VoidClient = {}

VoidClient.Version = script.Parent:WaitForChild("Version").Value
VoidClient.Player = game:GetService("Players").LocalPlayer
VoidClient.Controllers = {} :: {[string]: Controller}
VoidClient.Util = script.Parent:WaitForChild("Util")

local Promise = require(VoidClient.Util.Promise)
local Loader = require(VoidClient.Util.Loader)
local Ser = require(VoidClient.Util.Ser)
local ClientRemoteSignal = require(VoidClient.Util.Remote.ClientRemoteSignal)
local ClientRemoteProperty = require(VoidClient.Util.Remote.ClientRemoteProperty)
local TableUtil = require(VoidClient.Util.TableUtil)

local services: {[string]: Service} = {}
local servicesFolder = script.Parent:WaitForChild("Services")

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function BuildService(serviceName: string, folder: Instance): Service
	local service = {}
	local rfFolder = folder:FindFirstChild("RF")
	local reFolder = folder:FindFirstChild("RE")
	local rpFolder = folder:FindFirstChild("RP")
	if rfFolder then
		for _,rf in ipairs(rfFolder:GetChildren()) do
			if rf:IsA("RemoteFunction") then
				local function StandardRemote(_self, ...)
					return Ser.DeserializeArgsAndUnpack(rf:InvokeServer(Ser.SerializeArgsAndUnpack(...)))
				end
				local function PromiseRemote(_self, ...)
					local args = Ser.SerializeArgs(...)
					return Promise.new(function(resolve)
						resolve(Ser.DeserializeArgsAndUnpack(rf:InvokeServer(table.unpack(args, 1, args.n))))
					end)
				end
				service[rf.Name] = StandardRemote
				service[rf.Name .. "Promise"] = PromiseRemote
			end
		end
	end
	if reFolder then
		for _,re in ipairs(reFolder:GetChildren()) do
			if re:IsA("RemoteEvent") then
				service[re.Name] = ClientRemoteSignal.new(re)
			end
		end
	end
	if rpFolder then
		for _,rp in ipairs(rpFolder:GetChildren()) do
			if rp:IsA("ValueBase") or rp:IsA("RemoteEvent") then
				service[rp.Name] = ClientRemoteProperty.new(rp)
			end
		end
	end
	services[serviceName] = service
	return service
end


local function DoesControllerExist(controllerName: string): boolean
	local controller: Controller? = VoidClient.Controllers[controllerName]
	return controller ~= nil
end


function VoidClient.CreateController(controllerDef: ControllerDef): Controller
	assert(type(controllerDef) == "table", "Controller must be a table; got " .. type(controllerDef))
	assert(type(controllerDef.Name) == "string", "Controller.Name must be a string; got " .. type(controllerDef.Name))
	assert(#controllerDef.Name > 0, "Controller.Name must be a non-empty string")
	assert(not DoesControllerExist(controllerDef.Name), "Controller \"" .. controllerDef.Name .. "\" already exists")
	local controller: Controller = TableUtil.Assign(controllerDef, {
		_Void_is_controller = true;
	})
	VoidClient.Controllers[controller.Name] = controller
	return controller
end


function VoidClient.AddControllers(folder: Instance): {any}
	return Loader.LoadChildren(folder)
end


function VoidClient.AddControllersDeep(folder: Instance): {any}
	return Loader.LoadDescendants(folder)
end


function VoidClient.GetService(serviceName: string): Service
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	local folder: Instance? = servicesFolder:FindFirstChild(serviceName)
	assert(folder ~= nil, "Could not find service \"" .. serviceName .. "\"")
	return services[serviceName] or BuildService(serviceName, folder :: Instance)
end


function VoidClient.GetController(controllerName: string): Controller?
	return VoidClient.Controllers[controllerName]
end


function VoidClient.Start()

	if started then
		return Promise.Reject("Void already started")
	end

	started = true

	local controllers = VoidClient.Controllers

	return Promise.new(function(resolve)

		-- Init:
		local promisesStartControllers = {}
		for _,controller in pairs(controllers) do
			if type(controller.VoidInit) == "function" then
				table.insert(promisesStartControllers, Promise.new(function(r)
					controller:VoidInit()
					r()
				end))
			end
		end

		resolve(Promise.All(promisesStartControllers))

	end):Then(function()

		-- Start:
		for _,controller in pairs(controllers) do
			if type(controller.VoidStart) == "function" then
				task.spawn(controller.VoidStart, controller)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()

		task.defer(function()
			onStartedComplete:Destroy()
		end)

	end)

end


function VoidClient.OnStart()
	if startedComplete then
		return Promise.Resolve()
	else
		return Promise.FromEvent(onStartedComplete.Event)
	end
end


return VoidClient
