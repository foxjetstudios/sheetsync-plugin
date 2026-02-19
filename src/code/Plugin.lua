-- SheetSync Plugin by Fox Jet Studios
-- Main entry point

local toolbar = plugin:CreateToolbar("Fox Jet Studios's Plugins")
local button  = toolbar:CreateButton(
	"SheetSync",
	"Import Google Sheets data into Roblox Studio",
	"rbxassetid://114690873290183"
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	420,
	560,
	380,
	480
)

local widget = plugin:CreateDockWidgetPluginGui("SheetSyncWidget", widgetInfo)
widget.Title  = "SheetSync – Google Sheets Importer"
widget.Name   = "SheetSyncWidget"

local UIController
local widgetOpen = false

button.Click:Connect(function()
	widgetOpen = not widgetOpen
	widget.Enabled = widgetOpen

	if widgetOpen and not UIController then
		local UIModule = require(script.Parent.UIController)
		UIController  = UIModule.new(widget, plugin)
	end
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	widgetOpen = widget.Enabled
	button:SetActive(widgetOpen)
end)