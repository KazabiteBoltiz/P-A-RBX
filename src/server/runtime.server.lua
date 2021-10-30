local Void = require(game.ReplicatedStorage.Void)
local RemoteSignal = require(Void.Util.Remote.RemoteSignal)
local RemoteProperty = require(Void.Util.Remote.RemoteProperty)

local InventoryService = Void.CreateService { Name = "InventoryService", Client = {Database = RemoteProperty.new({}), WeaponAction = RemoteSignal.new()} }
local CharacterStatesService = Void.CreateService{ Name = "CharacterStatesService", Client = {Database = RemoteProperty.new({})} }

Void.Start()

game.StarterPlayer.EnableMouseLockOption = false

