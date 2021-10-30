if game:GetService("RunService"):IsServer() then
	return require(script.VoidServer)
else
	script.VoidServer:Destroy()
	return require(script.VoidClient)
end
