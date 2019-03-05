if SERVER then
    AddCSLuaFile()
end
if CLIENT then
	hook.Add("TTT2ScoreboardAddPlayerRow", "TTT2AddCustomBindingsDevs", function(ply)
		local tsid64 = ply:SteamID64()

		if tostring(tsid64) == "76561197989909602" then
			AddTTT2AddonDev(tsid64)
		end
		if tostring(tsid64) == "76561198047056948" then
			AddTTT2AddonDev(tsid64)
		end
	end)
end

conCommandsToBind={}

--List with all conCommands that should be binded to a key
local bindList = {}	

--FUNCTIONS to manipulate the BINDLIST
function conCommandsToBind.Get()
	return bindList
end

function conCommandsToBind.Add(key, concommand, name, category, activated)
	
	--Check if conCommands is already in the bindList
	if bindList[key] != nil then
		--print("Eintrag " .. key .. " bereits Vorhanden")
		return false
	end
	
	--Add the new entry
	local newEntry = {}
	newEntry.concommand=concommand
	newEntry.name=name
	newEntry.category=category
	newEntry.activated=activated
	
	bindList[key]= newEntry;
	
	print("[TTT2][Bindings] Add new Binding Entry: " .. key .. " " .. concommand .. " " .. name .. " " .. category .. " " .. tostring(activated))
	
	return true
end

function conCommandsToBind.AddToServer(key, concommand, name, category, activated)

	if LocalPlayer():IsSuperAdmin() then
		if conCommandsToBind.Add(key, concommand, name, category, activated) then
			net.Start("ttt2_cb_addNewEntry")
			net.WriteString(key)
			net.WriteString(concommand)
			net.WriteString(name)
			net.WriteString(category)
			net.WriteBool(activated)
			net.SendToServer()
		end
	end
	
	return false
end
function conCommandsToBind.AddToPlayer(key, concommand, name, category, activated, ply)
	
	if SERVER then
		net.Start("ttt2_cb_addNewEntry")
		net.WriteString(key)
		net.WriteString(concommand)
		net.WriteString(name)
		net.WriteString(category)
		net.WriteBool(activated)
		net.Send(ply)
	end
	
	return false
end

function conCommandsToBind.Remove(key)

	if bindList[key] != nil then
		bindList[key] = nil
		return true
	end
	return false
end

function conCommandsToBind.RemoveFromServer(key)

	if LocalPlayer():IsSuperAdmin() then
		if conCommandsToBind.Remove(key) then
			net.Start("ttt2_cb_removeEntry")
			net.WriteString(key)
			net.SendToServer()
		end
	end
	
	return false
end
function conCommandsToBind.RemoveFromPlayer(key, ply)

	if SERVER then
		net.Start("ttt2_cb_removeEntry")
		net.WriteString(key)
		net.Send(ply)
	end
	
	return false
end

function conCommandsToBind.Edit(oldKey, newKey, concommand, name, category, activated)
	if oldKey == newKey then
		--Edit the  entry
		bindList[newKey].concommand = concommand;
		bindList[newKey].name = name;
		bindList[newKey].category = category;
		bindList[newKey].activated = activated;
		
		print("[TTT2][Bindings] Edit Binding Entry: " .. newKey .. " " .. concommand .. " " .. name .. " " .. category .. " " .. tostring(activated))
		return true
	else 
		conCommandsToBind.Remove(oldKey)
		return conCommandsToBind.Add(newKey, concommand, name, category, activated)
	end
	
	return false
end

function conCommandsToBind.EditToServer(oldKey, newKey, concommand, name, category, activated)

	if LocalPlayer():IsSuperAdmin() then
		if conCommandsToBind.Edit(oldKey, newKey, concommand, name, category, activated) then
			net.Start("ttt2_cb_editEntry")
			net.WriteString(oldKey)
			net.WriteString(newKey)
			net.WriteString(concommand)
			net.WriteString(name)
			net.WriteString(category)
			net.WriteBool(activated)
			net.SendToServer()
		end
	end
	
	return false
end

function conCommandsToBind.EditToPlayer(oldKey, newKey, concommand, name, category, activated, ply)

	if SERVER then
		net.Start("ttt2_cb_editEntry")
		net.WriteString(oldKey)
		net.WriteString(newKey)
		net.WriteString(concommand)
		net.WriteString(name)
		net.WriteString(category)
		net.WriteBool(activated)
		net.Send(ply)
	end
	
	return false
end


if SERVER then
	util.AddNetworkString( "ttt2_cb_addNewEntry" )
	util.AddNetworkString( "ttt2_cb_editEntry" )
	util.AddNetworkString( "ttt2_cb_removeEntry" )


	function conCommandsToBind.SendListToPlayer( ply )	
		print("[TTT2][Bindings] Send Custom Bindings to " .. ply:Name())
		
		for label, entry in pairs(conCommandsToBind.Get()) do
			net.Start("ttt2_cb_addNewEntry")
			net.WriteString(label)
			net.WriteString(entry.concommand)
			net.WriteString(entry.name)
			net.WriteString(entry.category)
			net.WriteBool(entry.activated)
			net.Send(ply)
		end
	end
		
	hook.Add("PlayerAuthed", "TTT2BindingsCustomSync", function(ply, steamid, uniqueid)
		conCommandsToBind.SendListToPlayer( ply )
	end)
	
	local function CreateTable()
		print("[TTT2][Bindings] Create new Table")
		sql.Query( "CREATE TABLE ttt2_custombindings( Key TEXT NOT NULL, Name TEXT, Category TEXT, Command TEXT, Activated INTEGER, PRIMARY KEY(`Key`) )" )
	end
	
	function conCommandsToBind.AddCustomBindingToSQL(key, concommand, name, category, activated)
		local tmp = 0
		if activated then
			tmp = 1
		end
		print(sql.Query("INSERT INTO ttt2_custombindings( Key, Name, Category, Command, Activated ) VALUES( '"..key.."', '"..name.."', '"..category.."', '"..concommand.."', ".. tostring(tmp) .." )"))
	end
	
	function conCommandsToBind.UpdateCustomBindingInSQL(key, concommand, name, category, activated)
		local tmp = 0
		if activated then
			tmp = 1
		end
		
		local result = sql.Query("UPDATE ttt2_custombindings SET Name='"..name.."', Category='"..category.."', Command='"..concommand.."', Activated='".. tostring(tmp) .."' WHERE Key='"..key.."'")
		if result == false then
			print("[TTT2][Bindings] Error: " .. sql.LastError( result ))
		end
	end
	
	function conCommandsToBind.RemoveCustomBindingToSQL(key)
		local result = sql.Query("DELETE FROM ttt2_custombindings WHERE Key='"..key.."'")
		if result == false then
			print("[TTT2][Bindings] Error: " .. sql.LastError( result ))
		end
	end
	
	function conCommandsToBind.LoadCustomBindingFromSQL()
		local result = sql.Query("SELECT * FROM ttt2_custombindings")
		
		if result != nil then
			if result then
				for k, v in pairs(result) do
					conCommandsToBind.Add(v.Key, v.Command, v.Name, v.Category, v.Activated == "1")
				end
			else
				print("[TTT2][Bindings] Error: " .. sql.LastError( result ))
			end
		end
	end
	
	if not  sql.TableExists("ttt2_custombindings") then
		CreateTable()
	end
	conCommandsToBind.LoadCustomBindingFromSQL()
end


local function UpdateBindings()
	if CLIENT then
		for key, entry in pairs(bindList) do
			if entry.activated then
				if entry.concommand != "" then
					bind.Register(key, function()
						LocalPlayer():ConCommand(entry.concommand)
					end,
					function()
					end)
				end
				bind.AddSettingsBinding(key, entry.name, entry.category)
			end
		end
	end
end
local function RemoveBindings( key )
	if CLIENT then
		-- TODO: Remove Binding
	end
end


net.Receive ("ttt2_cb_addNewEntry", function( length, ply )	

	if SERVER and not ply:IsSuperAdmin() then
		return
	end
	
	local key = net.ReadString()
	local concommand = net.ReadString()
	local name = net.ReadString()
	local category = net.ReadString()
	local activated = net.ReadBool()
	
	if not conCommandsToBind.Add(key, concommand, name, category, activated) then
		conCommandsToBind.Edit(key, key, concommand, name, category, activated)
		if SERVER then
			UpdateCustomBindingInSQL(key, concommand, name, category, activated)		
			for k, p in pairs(player.GetAll()) do
				conCommandsToBind.EditToPlayer(key, key, concommand, name, category, activated, p)
			end
		end
	else
		if SERVER then
			conCommandsToBind.AddCustomBindingToSQL(key, concommand, name, category, activated)		
			for k, p in pairs(player.GetAll()) do
				conCommandsToBind.AddToPlayer(key, concommand, name, category, activated, p)
			end
		end
	end
	
	if CLIENT then
		UpdateBindings()
	end
end)

net.Receive ("ttt2_cb_editEntry", function( length, ply )	

	if SERVER and not ply:IsSuperAdmin() then
		return
	end
	
	local oldKey = net.ReadString()
	local newKey = net.ReadString()
	local concommand = net.ReadString()
	local name = net.ReadString()
	local category = net.ReadString()
	local activated = net.ReadBool()
	
	conCommandsToBind.Edit(oldKey, newKey, concommand, name, category, activated)
	
	if CLIENT then
		UpdateBindings()
	else
		conCommandsToBind.UpdateCustomBindingInSQL(oldKey, concommand, name, category, activated)	
		for k, p in pairs(player.GetAll()) do
			conCommandsToBind.EditToPlayer(oldKey, newKey, concommand, name, category, activated, p)
		end
	end
end)

net.Receive ("ttt2_cb_removeEntry", function( length, ply )	

	if SERVER and not ply:IsSuperAdmin() then
		return
	end
	
	local key = net.ReadString()
	
	if conCommandsToBind.Remove(key) then
		print("[TTT2][Bindings] Remove Entry " .. key)
	end
	
	if CLIENT then
		RemoveBindings(key)
	else
		conCommandsToBind.RemoveCustomBindingToSQL(key)
		for k, p in pairs(player.GetAll()) do
			conCommandsToBind.RemoveFromPlayer(key, p)
		end
	end
end)