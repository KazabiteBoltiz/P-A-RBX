--!strict

--[[

	Void.CreateService(service): Service
	Void.AddServices(folder): Service[]
	Void.AddServicesDeep(folder): Service[]
	Void.Start(): Promise<void>
	Void.OnStart(): Promise<void>

--]]


type ServiceDef = {
	Name: string,
	Client: {[any]: any}?,
	[any]: any,
}

type Service = {
	Name: string,
	Client: ServiceClient,
	_Void_is_service: boolean,
	_Void_rf: {},
	_Void_re: {},
	_Void_rp: {},
	_Void_rep_folder: Instance,
	[any]: any,
}

type ServiceClient = {
	Server: Service,
	[any]: any,
}


local VoidServer = {}

VoidServer.Version = script.Parent.Version.Value
VoidServer.Services = {} :: {[string]: Service}
VoidServer.Util = script.Parent.Util


local VoidRepServiceFolder = Instance.new("Folder")
VoidRepServiceFolder.Name = "Services"

local Promise = require(VoidServer.Util.Promise)
local Signal = require(VoidServer.Util.Signal)
local Loader = require(VoidServer.Util.Loader)
local Ser = require(VoidServer.Util.Ser)
local RemoteSignal = require(VoidServer.Util.Remote.RemoteSignal)
local RemoteProperty = require(VoidServer.Util.Remote.RemoteProperty)
local TableUtil = require(VoidServer.Util.TableUtil)

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function CreateRepFolder(serviceName: string): Instance
	local folder = Instance.new("Folder")
	folder.Name = serviceName
	return folder
end


local function GetFolderOrCreate(parent: Instance, name: string): Instance
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end


local function AddToRepFolder(service: Service, remoteObj: Instance, folderOverride: string?)
	if folderOverride then
		remoteObj.Parent = GetFolderOrCreate(service._Void_rep_folder, folderOverride)
	elseif remoteObj:IsA("RemoteFunction") then
		remoteObj.Parent = GetFolderOrCreate(service._Void_rep_folder, "RF")
	elseif remoteObj:IsA("RemoteEvent") then
		remoteObj.Parent = GetFolderOrCreate(service._Void_rep_folder, "RE")
	elseif remoteObj:IsA("ValueBase") then
		remoteObj.Parent = GetFolderOrCreate(service._Void_rep_folder, "RP")
	else
		error("Invalid rep object: " .. remoteObj.ClassName)
	end
	if not service._Void_rep_folder.Parent then
		service._Void_rep_folder.Parent = VoidRepServiceFolder
	end
end


local function DoesServiceExist(serviceName: string): boolean
	local service: Service? = VoidServer.Services[serviceName]
	return service ~= nil
end


function VoidServer.IsService(object: any): boolean
	return type(object) == "table" and object._Void_is_service == true
end


function VoidServer.CreateService(serviceDef: ServiceDef): Service
	assert(type(serviceDef) == "table", "Service must be a table; got " .. type(serviceDef))
	assert(type(serviceDef.Name) == "string", "Service.Name must be a string; got " .. type(serviceDef.Name))
	assert(#serviceDef.Name > 0, "Service.Name must be a non-empty string")
	assert(not DoesServiceExist(serviceDef.Name), "Service \"" .. serviceDef.Name .. "\" already exists")
	local service: Service = TableUtil.Assign(serviceDef, {
		_Void_is_service = true;
		_Void_rf = {};
		_Void_re = {};
		_Void_rp = {};
		_Void_rep_folder = CreateRepFolder(serviceDef.Name);
	})
	if type(service.Client) ~= "table" then
		service.Client = {Server = service}
	else
		if service.Client.Server ~= service then
			service.Client.Server = service
		end
	end
	VoidServer.Services[service.Name] = service
	return service
end


function VoidServer.AddServices(folder: Instance): {any}
	return Loader.LoadChildren(folder)
end


function VoidServer.AddServicesDeep(folder: Instance): {any}
	return Loader.LoadDescendants(folder)
end


function VoidServer.GetService(serviceName: string): Service
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	return assert(VoidServer.Services[serviceName], "Could not find service \"" .. serviceName .. "\"") :: Service
end


function VoidServer.BindRemoteEvent(service: Service, eventName: string, remoteEvent)
	assert(service._Void_re[eventName] == nil, "RemoteEvent \"" .. eventName .. "\" already exists")
	local re = remoteEvent._remote
	re.Name = eventName
	service._Void_re[eventName] = re
	AddToRepFolder(service, re)
end


function VoidServer.BindRemoteFunction(service: Service, funcName: string, func: (ServiceClient, ...any) -> ...any)
	assert(service._Void_rf[funcName] == nil, "RemoteFunction \"" .. funcName .. "\" already exists")
	local rf = Instance.new("RemoteFunction")
	rf.Name = funcName
	service._Void_rf[funcName] = rf
	AddToRepFolder(service, rf)
	rf.OnServerInvoke = function(...)
		return Ser.SerializeArgsAndUnpack(func(service.Client, Ser.DeserializeArgsAndUnpack(...)))
	end
end


function VoidServer.BindRemoteProperty(service: Service, propName: string, prop)
	assert(service._Void_rp[propName] == nil, "RemoteProperty \"" .. propName .. "\" already exists")
	prop._object.Name = propName
	service._Void_rp[propName] = prop
	AddToRepFolder(service, prop._object, "RP")
end


function VoidServer.Start()

	if started then
		return Promise.Reject("Void already started")
	end

	started = true

	local services = VoidServer.Services

	return Promise.new(function(resolve)

		-- Bind remotes:
		for _,service in pairs(services) do
			for k,v in pairs(service.Client) do
				if type(v) == "function" then
					VoidServer.BindRemoteFunction(service, k, v)
				elseif RemoteSignal.Is(v) then
					VoidServer.BindRemoteEvent(service, k, v)
				elseif RemoteProperty.Is(v) then
					VoidServer.BindRemoteProperty(service, k, v)
				elseif Signal.Is(v) then
					warn("Found Signal instead of RemoteSignal (Void.Util.RemoteSignal). Please change to RemoteSignal. [" .. service.Name .. ".Client." .. k .. "]")
				end
			end
		end

		-- Init:
		local promisesInitServices = {}
		for _,service in pairs(services) do
			if type(service.VoidInit) == "function" then
				table.insert(promisesInitServices, Promise.new(function(r)
					service:VoidInit()
					r()
				end))
			end
		end

		resolve(Promise.All(promisesInitServices))

	end):Then(function()

		-- Start:
		for _,service in pairs(services) do
			if type(service.VoidStart) == "function" then
				task.spawn(service.VoidStart, service)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()

		task.defer(function()
			onStartedComplete:Destroy()
		end)

		-- Expose service remotes to everyone:
		VoidRepServiceFolder.Parent = script.Parent

	end)

end


function VoidServer.OnStart()
	if startedComplete then
		return Promise.Resolve()
	else
		return Promise.FromEvent(onStartedComplete.Event)
	end
end


return VoidServer
