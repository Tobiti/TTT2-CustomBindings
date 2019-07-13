local bindings = xlib.makepanel{ parent=xgui.null }

xlib.makelabel{x = 5, y = 270, w = 600, wordwrap = true, label = "Help:\n If Command is empty, the function behind the binding isn't set or overwritten!", parent = bindings}

bindings.list = xlib.makelistview{ x=5, y=20, w=550, h=190, parent=bindings }
bindings.list:AddColumn( "Name" )
bindings.list:AddColumn( "Label" )
bindings.list:AddColumn( "Category" )
bindings.list:AddColumn( "Command" )
bindings.list:AddColumn( "Default Key")
bindings.list:AddColumn( "Active" )
bindings.list:AddColumn( "Custom" )
bindings.list.OnRowSelected = function( self, LineID, Line )
	bindings.editlist:SetDisabled( false )
	bindings.removelist:SetDisabled( !Line:GetColumnText(7) )
end

local function UpdateList()
	bindings.list:Clear()
	for id, v in pairs( conCommandsToBind.Get() ) do
		bindings.list:AddLine( id, v.name, v.category, v.concommand, input.GetKeyName(v.defaultKey or BUTTON_CODE_NONE), v.activated ,true )
	end
	for id, v in ipairs( bind.GetSettingsBindings() ) do
		if conCommandsToBind.Get()[v.name] == nil then
			bindings.list:AddLine( v.name, v.label, v.category, "", input.GetKeyName(v.defaultKey or BUTTON_CODE_NONE), true, false )
		end
	end
end
UpdateList()

-- Add Button
bindings.addlist = xlib.makebutton{ x=5, y=210, w=150, label="Add New Binding", parent=bindings }
bindings.addlist.DoClick = function()
	bindings.addNewEntry()
end

-- Edit Button
bindings.editlist = xlib.makebutton{ x=160, y=210, w=150, label="Edit Binding", parent=bindings, disabled=true }
bindings.editlist.DoClick = function()
	if bindings.list:GetSelectedLine() then
		local key = bindings.list:GetSelected()[1]:GetColumnText(1)		
		bindings.editEntry( key, bindings.list:GetSelected()[1]:GetColumnText(4), bindings.list:GetSelected()[1]:GetColumnText(2), bindings.list:GetSelected()[1]:GetColumnText(3), bindings.list:GetSelected()[1]:GetColumnText(5), bindings.list:GetSelected()[1]:GetColumnText(6), bindings.list:GetSelected()[1]:GetColumnText(7) )
	end
end
-- Remove Button
bindings.removelist = xlib.makebutton{ x=315, y=210, w=150, label="Remove Binding", parent=bindings, disabled=true }
bindings.removelist.DoClick = function()
	if bindings.list:GetSelectedLine() then
		local ID = bindings.list:GetSelected()[1]:GetColumnText(1)
		conCommandsToBind.RemoveFromServer(ID)
		UpdateList()
	end
end
-- Refresh Button
bindings.refreshlist = xlib.makebutton{ x=5, y=240, w=150, label="Refresh List", parent=bindings }
bindings.refreshlist.DoClick = function()
	UpdateList()
end

function bindings.addNewEntry()
	local frame = xlib.makeframe{ label="Add new Binding Entry", w=300, h=205, skin=xgui.settings.skin }
	
	xlib.makelabel{ x=5, y=30, label="Key:", parent=frame }
	frame.bindingKey =	xlib.maketextbox{ x=100, y=30, w=180, parent=frame, selectall=true, text="Enter key" };
	xlib.makelabel{ x=5, y=55, label="Label:", parent=frame }
	frame.bindingLabel =	xlib.maketextbox{ x=100, y=55, w=180, parent=frame, selectall=true, text="Enter label" };
	xlib.makelabel{ x=5, y=80, label="Category:", parent=frame }
	frame.bindingCategory =	xlib.maketextbox{ x=100, y=80, w=180, parent=frame, selectall=true, text="Enter category" };
	xlib.makelabel{ x=5, y=105, label="Command:", parent=frame }
	frame.bindingCommand =	xlib.maketextbox{ x=100, y=105, w=180, parent=frame, selectall=true, text="" };
	xlib.makelabel{ x=5, y=130, label="Default Key:", parent=frame }
	frame.bindingDefaultKey = vgui.Create("DBinder", frame)
	frame.bindingDefaultKey:SetPos(100, 130)
	frame.bindingDefaultKey:SetSize(180, 22)
	
	frame.bindingActive = xlib.makecheckbox{ x=100, y=155, label="Active", value=true, parent=frame }
	
	frame.apply = xlib.makebutton{ x=130, y=180, w=150, label="Add", parent=frame }
	frame.apply.DoClick = function()
		conCommandsToBind.AddToServer(frame.bindingKey:GetValue(), frame.bindingCommand:GetValue(), frame.bindingLabel:GetValue(), frame.bindingCategory:GetValue(), frame.bindingDefaultKey:GetValue(), frame.bindingActive:GetChecked())
		UpdateList()
		frame:Remove()
	end
end

function bindings.editEntry( key, concommand, name, category, defaultKey, activated, custom )
	local frame = xlib.makeframe{ label="Edit Entry " .. name, w=300, h=205, skin=xgui.settings.skin }
	
	xlib.makelabel{ x=5, y=30, label="Key:", parent=frame }
	frame.bindingKey =	xlib.maketextbox{ x=100, y=30, w=180, parent=frame, selectall=true, text=key };
	xlib.makelabel{ x=5, y=55, label="Label:", parent=frame }
	frame.bindingLabel =	xlib.maketextbox{ x=100, y=55, w=180, parent=frame, selectall=true, text=name };
	xlib.makelabel{ x=5, y=80, label="Category:", parent=frame }
	frame.bindingCategory =	xlib.maketextbox{ x=100, y=80, w=180, parent=frame, selectall=true, text=category };
	xlib.makelabel{ x=5, y=105, label="Command:", parent=frame }
	frame.bindingCommand =	xlib.maketextbox{ x=100, y=105, w=180, parent=frame, selectall=true, text=concommand };
	xlib.makelabel{ x=5, y=130, label="Default Key:", parent=frame }
	frame.bindingDefaultKey = vgui.Create("DBinder", frame)
	frame.bindingDefaultKey:SetPos(100, 130)
	frame.bindingDefaultKey:SetSize(180, 22)
	frame.bindingDefaultKey:SetValue(input.GetKeyCode(defaultKey))

	frame.bindingActive = xlib.makecheckbox{ x=100, y=155, label="Active", value=activated, parent=frame }
	
	frame.apply = xlib.makebutton{ x=130, y=180, w=150, label="Apply", parent=frame }
	frame.apply.DoClick = function()
		if custom then
			conCommandsToBind.EditToServer(key, frame.bindingKey:GetValue(), frame.bindingCommand:GetValue(), frame.bindingLabel:GetValue(), frame.bindingCategory:GetValue(), frame.bindingDefaultKey:GetValue(), frame.bindingActive:GetChecked())
		else
			conCommandsToBind.AddToServer(frame.bindingKey:GetValue(), frame.bindingCommand:GetValue(), frame.bindingLabel:GetValue(), frame.bindingCategory:GetValue(), frame.bindingDefaultKey:GetValue(), frame.bindingActive:GetChecked())
		end
		UpdateList()
		frame:Remove()
	end
end

xgui.addModule( "Custom Bindings", bindings, "icon16/ttt.png", "xgui_gmsettings" )