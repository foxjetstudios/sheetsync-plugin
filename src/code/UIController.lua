-- UIController.lua
-- Builds and manages the full SheetSync UI inside the DockWidget.

local TweenService = game:GetService("TweenService")

local SheetFetcher = require(script.Parent.SheetFetcher)
local CSVParser    = require(script.Parent.CSVParser)
local Generator    = require(script.Parent.Generator)
local Logger       = require(script.Parent.Logger)

local C = {
	BG          = Color3.fromRGB(28,  30,  36),
	PANEL       = Color3.fromRGB(36,  39,  47),
	BORDER      = Color3.fromRGB(55,  60,  72),
	ACCENT      = Color3.fromRGB(99, 161, 255),
	ACCENT_DARK = Color3.fromRGB(66, 120, 210),
	TEXT        = Color3.fromRGB(220, 224, 235),
	SUBTEXT     = Color3.fromRGB(140, 148, 168),
	INPUT_BG    = Color3.fromRGB(22,  24,  30),
	SUCCESS     = Color3.fromRGB(80,  200, 120),
	ERROR       = Color3.fromRGB(230,  80,  80),
	WARN        = Color3.fromRGB(240, 180,  60),
	BTN_IMPORT  = Color3.fromRGB(99, 161, 255),
	BTN_PREVIEW = Color3.fromRGB(60,  65,  80),
	BTN_CLEAR   = Color3.fromRGB(50,  30,  30),
	WARN_BG     = Color3.fromRGB(60,  48,  20),
	WARN_TEXT   = Color3.fromRGB(255, 210, 100),
}

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function makeFrame(props)
	local f = Instance.new("Frame")
	for k, v in pairs(props) do f[k] = v end
	return f
end

local function makeLabel(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font                   = Enum.Font.BuilderSansBold
	l.TextColor3             = C.TEXT
	l.TextSize               = 13
	l.TextXAlignment         = Enum.TextXAlignment.Left
	for k, v in pairs(props) do l[k] = v end
	return l
end

local function makeTextbox(props)
	local t = Instance.new("TextBox")
	t.BackgroundColor3  = C.INPUT_BG
	t.BorderSizePixel   = 0
	t.Font              = Enum.Font.Code
	t.TextColor3        = C.TEXT
	t.PlaceholderColor3 = C.SUBTEXT
	t.TextSize          = 12
	t.TextXAlignment    = Enum.TextXAlignment.Left
	t.ClearTextOnFocus  = false
	t.TextTruncate      = Enum.TextTruncate.AtEnd
	for k, v in pairs(props) do t[k] = v end
	return t
end

local function makeButton(props)
	local b = Instance.new("TextButton")
	b.BorderSizePixel  = 0
	b.AutoButtonColor  = false
	b.Font             = Enum.Font.BuilderSansBold
	b.TextSize         = 13
	b.TextColor3       = Color3.fromRGB(255, 255, 255)
	for k, v in pairs(props) do b[k] = v end
	return b
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color     = color or C.BORDER
	s.Thickness = thickness or 1
	s.Parent    = parent
end

local function addInputPadding(parent)
	local p = Instance.new("UIPadding")
	p.PaddingLeft  = UDim.new(0, 8)
	p.PaddingRight = UDim.new(0, 8)
	p.Parent = parent
end

local function wireHover(btn, normal, hot)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TWEEN_FAST, {BackgroundColor3 = hot}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TWEEN_FAST, {BackgroundColor3 = normal}):Play()
	end)
end

local function wireInputFocus(box)
	local stroke = box:FindFirstChildOfClass("UIStroke")
	box.Focused:Connect(function()
		TweenService:Create(stroke, TWEEN_FAST, {Color = C.ACCENT}):Play()
	end)
	box.FocusLost:Connect(function()
		TweenService:Create(stroke, TWEEN_FAST, {Color = C.BORDER}):Play()
	end)
end

local function makeDropdown(parent, options, defaultIdx)
	defaultIdx = defaultIdx or 1
	local selected = options[defaultIdx]

	local container = makeFrame({
		BackgroundColor3 = C.INPUT_BG,
		Size             = UDim2.new(1, 0, 0, 30),
	})
	addCorner(container, 6)
	addStroke(container)

	local display = makeLabel({
		Size           = UDim2.new(1, -28, 1, 0),
		Position       = UDim2.new(0, 10, 0, 0),
		Text           = selected,
		Font           = Enum.Font.BuilderSans,
		TextSize       = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent         = container,
	})

	local arrow = makeLabel({
		Size           = UDim2.new(0, 24, 1, 0),
		Position       = UDim2.new(1, -26, 0, 0),
		Text           = "⬇",
		Font           = Enum.Font.BuilderSansBold,
		TextSize       = 14,
		TextColor3     = C.SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent         = container,
	})

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size                   = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text                   = ""
	clickBtn.ZIndex                 = 5
	clickBtn.Parent                 = container

	local listFrame = makeFrame({
		BackgroundColor3 = C.PANEL,
		ZIndex           = 20,
		Visible          = false,
		ClipsDescendants = true,
		Size             = UDim2.new(1, 0, 0, 0),
	})
	addCorner(listFrame, 6)
	addStroke(listFrame)
	listFrame.Parent = container

	local totalH = #options * 28
	for i, opt in ipairs(options) do
		local ob = makeButton({
			Size             = UDim2.new(1, 0, 0, 28),
			Position         = UDim2.new(0, 0, 0, (i - 1) * 28),
			BackgroundColor3 = C.PANEL,
			Text             = opt,
			Font             = Enum.Font.BuilderSans,
			TextSize         = 12,
			TextColor3       = C.TEXT,
			ZIndex           = 21,
			Parent           = listFrame,
		})
		wireHover(ob, C.PANEL, C.BORDER)
		ob.Activated:Connect(function()
			selected         = opt
			display.Text     = opt
			listFrame.Visible = false
			TweenService:Create(arrow, TWEEN_FAST, {Rotation = 0}):Play()
		end)
	end

	local open = false
	clickBtn.Activated:Connect(function()
		open = not open
		listFrame.Visible = open
		if open then
			listFrame.Position = UDim2.new(0, 0, 1, 2)
			TweenService:Create(listFrame, TWEEN_MED, {Size = UDim2.new(1, 0, 0, totalH)}):Play()
			TweenService:Create(arrow, TWEEN_FAST, {Rotation = 180}):Play()
		else
			TweenService:Create(listFrame, TWEEN_MED, {Size = UDim2.new(1, 0, 0, 0)}):Play()
			TweenService:Create(arrow, TWEEN_FAST, {Rotation = 0}):Play()
		end
	end)

	container.Parent = parent
	return container, function() return selected end
end

local function makeSpinner(parent)
	local spinFrame = makeFrame({
		Size                   = UDim2.new(0, 20, 0, 20),
		BackgroundTransparency = 1,
		Visible                = false,
		Parent                 = parent,
	})

	local arc = Instance.new("ImageLabel")
	arc.Size                   = UDim2.new(1, 0, 1, 0)
	arc.BackgroundTransparency = 1
	arc.Image                  = "rbxassetid://108239616592221"
	arc.ImageColor3            = C.ACCENT
	arc.Parent                 = spinFrame

	local spinning = false
	local function setVisible(v)
		spinFrame.Visible = v
		spinning = v
		if v then
			task.spawn(function()
				local r = 0
				while spinning do
					r = r + 8
					arc.Rotation = r
					task.wait(0.016)
				end
				arc.Rotation = 0
			end)
		end
	end

	return spinFrame, setVisible
end

local UIController = {}
UIController.__index = UIController

function UIController.new(widget, plugin)
	local self = setmetatable({}, UIController)
	self._widget  = widget
	self._plugin  = plugin
	self._headers = {}
	self._rows    = {}
	self:_buildUI()
	return self
end

function UIController:_buildUI()
	local widget = self._widget

	local root = Instance.new("ScrollingFrame")
	root.Size                 = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3     = C.BG
	root.BorderSizePixel      = 0
	root.ScrollBarThickness   = 4
	root.ScrollBarImageColor3 = C.BORDER
	root.CanvasSize           = UDim2.new(0, 0, 0, 0)
	root.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	root.Parent               = widget

	local rootPadding = Instance.new("UIPadding")
	rootPadding.PaddingTop    = UDim.new(0, 14)
	rootPadding.PaddingBottom = UDim.new(0, 14)
	rootPadding.PaddingLeft   = UDim.new(0, 14)
	rootPadding.PaddingRight  = UDim.new(0, 14)
	rootPadding.Parent        = root

	local rootLayout = Instance.new("UIListLayout")
	rootLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rootLayout.Padding   = UDim.new(0, 10)
	rootLayout.Parent    = root

	local titleBar = makeFrame({
		Size             = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = C.PANEL,
		LayoutOrder      = 1,
		Parent           = root,
	})
	addCorner(titleBar, 8)

	makeLabel({
		Size       = UDim2.new(1, -16, 0, 24),
		Position   = UDim2.new(0, 14, 0, 6),
		Text       = "🗂  SheetSync",
		Font       = Enum.Font.BuilderSansBold,
		TextSize   = 16,
		TextColor3 = C.TEXT,
		Parent     = titleBar,
	})

	makeLabel({
		Size       = UDim2.new(1, -16, 0, 14),
		Position   = UDim2.new(0, 14, 0, 28),
		Text       = "Google Sheets → Roblox Studio  •  Fox Jet Studios",
		Font       = Enum.Font.BuilderSans,
		TextSize   = 10,
		TextColor3 = C.SUBTEXT,
		Parent     = titleBar,
	})

	local warnBanner = makeFrame({
		Size             = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = C.WARN_BG,
		LayoutOrder      = 2,
		Parent           = root,
	})
	addCorner(warnBanner, 8)
	addStroke(warnBanner, Color3.fromRGB(120, 90, 20))

	local warnIcon = makeLabel({
		Size       = UDim2.new(0, 28, 1, 0),
		Position   = UDim2.new(0, 10, 0, 0),
		Text       = "⚠",
		Font       = Enum.Font.BuilderSansBold,
		TextSize   = 16,
		TextColor3 = C.WARN_TEXT,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent     = warnBanner,
	})

	makeLabel({
		Size       = UDim2.new(1, -50, 1, 0),
		Position   = UDim2.new(0, 40, 0, 0),
		Text       = "Make sure your Google Sheet is set to public\n(Share → Anyone with the link → Viewer) or the import will fail.",
		Font       = Enum.Font.BuilderSans,
		TextSize   = 11,
		TextColor3 = C.WARN_TEXT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent     = warnBanner,
	})

	local urlSection = makeFrame({
		Size             = UDim2.new(1, 0, 0, 80),
		BackgroundColor3 = C.PANEL,
		LayoutOrder      = 3,
		Parent           = root,
	})
	addCorner(urlSection, 8)

	makeLabel({
		Size       = UDim2.new(1, -28, 0, 18),
		Position   = UDim2.new(0, 14, 0, 10),
		Text       = "Google Sheets URL",
		Font       = Enum.Font.BuilderSansBold,
		TextSize   = 12,
		TextColor3 = C.SUBTEXT,
		Parent     = urlSection,
	})

	local urlBox = makeTextbox({
		Size            = UDim2.new(1, -28, 0, 32),
		Position        = UDim2.new(0, 14, 0, 34),
		PlaceholderText = "https://docs.google.com/spreadsheets/d/...",
		Text            = "",
		Parent          = urlSection,
	})
	addCorner(urlBox, 6)
	addStroke(urlBox)
	addInputPadding(urlBox)
	wireInputFocus(urlBox)
	self._urlBox = urlBox

	local optSection = makeFrame({
		Size             = UDim2.new(1, 0, 0, 130),
		BackgroundColor3 = C.PANEL,
		LayoutOrder      = 4,
		Parent           = root,
	})
	addCorner(optSection, 8)

	makeLabel({
		Size       = UDim2.new(1, -28, 0, 18),
		Position   = UDim2.new(0, 14, 0, 10),
		Text       = "Output Type",
		Font       = Enum.Font.BuilderSansBold,
		TextSize   = 12,
		TextColor3 = C.SUBTEXT,
		Parent     = optSection,
	})

	local outputContainer = makeFrame({
		Size                   = UDim2.new(1, -28, 0, 30),
		Position               = UDim2.new(0, 14, 0, 32),
		BackgroundTransparency = 1,
		Parent                 = optSection,
	})
	local _, getOutputType = makeDropdown(outputContainer, {"ModuleScript", "Folder + Values", "Lua Table"}, 1)
	self._getOutputType = getOutputType

	makeLabel({
		Size       = UDim2.new(1, -28, 0, 18),
		Position   = UDim2.new(0, 14, 0, 76),
		Text       = "Destination",
		Font       = Enum.Font.BuilderSansBold,
		TextSize   = 12,
		TextColor3 = C.SUBTEXT,
		Parent     = optSection,
	})

	local destContainer = makeFrame({
		Size                   = UDim2.new(1, -28, 0, 30),
		Position               = UDim2.new(0, 14, 0, 96),
		BackgroundTransparency = 1,
		Parent                 = optSection,
	})
	local _, getDestination = makeDropdown(destContainer, {"ServerStorage", "ReplicatedStorage", "Workspace"}, 1)
	self._getDestination = getDestination

	local nameSection = makeFrame({
		Size             = UDim2.new(1, 0, 0, 66),
		BackgroundColor3 = C.PANEL,
		LayoutOrder      = 5,
		Parent           = root,
	})
	addCorner(nameSection, 8)

	makeLabel({
		Size       = UDim2.new(1, -28, 0, 18),
		Position   = UDim2.new(0, 14, 0, 8),
		Text       = "Output Name",
		Font       = Enum.Font.BuilderSansBold,
		TextSize   = 12,
		TextColor3 = C.SUBTEXT,
		Parent     = nameSection,
	})

	local nameBox = makeTextbox({
		Size            = UDim2.new(1, -28, 0, 30),
		Position        = UDim2.new(0, 14, 0, 30),
		PlaceholderText = "SheetData",
		Text            = "SheetData",
		Parent          = nameSection,
	})
	addCorner(nameBox, 6)
	addStroke(nameBox)
	addInputPadding(nameBox)
	wireInputFocus(nameBox)
	self._nameBox = nameBox

	local btnRow = makeFrame({
		Size                   = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		LayoutOrder            = 6,
		Parent                 = root,
	})

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.SortOrder     = Enum.SortOrder.LayoutOrder
	btnLayout.Padding       = UDim.new(0, 8)
	btnLayout.Parent        = btnRow

	local importBtn = makeButton({
		Size             = UDim2.new(0.55, -4, 1, 0),
		BackgroundColor3 = C.BTN_IMPORT,
		Text             = "⬇  Import",
		LayoutOrder      = 1,
		Parent           = btnRow,
	})
	addCorner(importBtn, 8)
	wireHover(importBtn, C.BTN_IMPORT, C.ACCENT_DARK)
	self._importBtn = importBtn

	local spinFrame, setSpinner = makeSpinner(importBtn)
	spinFrame.Position = UDim2.new(1, -28, 0.5, -10)
	self._setSpinner = setSpinner

	local previewBtn = makeButton({
		Size             = UDim2.new(0.27, -4, 1, 0),
		BackgroundColor3 = C.BTN_PREVIEW,
		Text             = "👁  Preview",
		LayoutOrder      = 2,
		Parent           = btnRow,
	})
	addCorner(previewBtn, 8)
	wireHover(previewBtn, C.BTN_PREVIEW, C.BORDER)

	local clearBtn = makeButton({
		Size             = UDim2.new(0.18, 0, 1, 0),
		BackgroundColor3 = C.BTN_CLEAR,
		Text             = "🗑",
		LayoutOrder      = 3,
		Parent           = btnRow,
	})
	addCorner(clearBtn, 8)
	wireHover(clearBtn, C.BTN_CLEAR, Color3.fromRGB(80, 30, 30))

	local logSection = makeFrame({
		Size             = UDim2.new(1, 0, 0, 200),
		BackgroundColor3 = C.PANEL,
		LayoutOrder      = 7,
		ClipsDescendants = true,
		Parent           = root,
	})
	addCorner(logSection, 8)

	makeLabel({
		Size       = UDim2.new(1, -16, 0, 18),
		Position   = UDim2.new(0, 14, 0, 8),
		Text       = "Log",
		Font       = Enum.Font.BuilderSansBold,
		TextSize   = 12,
		TextColor3 = C.SUBTEXT,
		Parent     = logSection,
	})

	local logFrame = Instance.new("ScrollingFrame")
	logFrame.Size                 = UDim2.new(1, -8, 1, -32)
	logFrame.Position             = UDim2.new(0, 4, 0, 28)
	logFrame.BackgroundColor3     = C.INPUT_BG
	logFrame.BorderSizePixel      = 0
	logFrame.ScrollBarThickness   = 3
	logFrame.ScrollBarImageColor3 = C.BORDER
	logFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
	logFrame.Parent               = logSection
	addCorner(logFrame, 4)

	local logger = Logger.new(logFrame)
	self._logger  = logger

	logger:info("SheetSync ready. Paste a Google Sheets URL above and click Import.")

	local previewSection = makeFrame({
		Size             = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = C.PANEL,
		LayoutOrder      = 8,
		ClipsDescendants = true,
		Visible          = false,
		Parent           = root,
	})
	addCorner(previewSection, 8)

	makeLabel({
		Size       = UDim2.new(1, -16, 0, 18),
		Position   = UDim2.new(0, 14, 0, 8),
		Text       = "Data Preview",
		Font       = Enum.Font.BuilderSansBold,
		TextSize   = 12,
		TextColor3 = C.SUBTEXT,
		Parent     = previewSection,
	})

	local previewText = makeLabel({
		Size           = UDim2.new(1, -28, 1, -34),
		Position       = UDim2.new(0, 14, 0, 28),
		Text           = "",
		Font           = Enum.Font.Code,
		TextSize       = 11,
		TextColor3     = C.TEXT,
		TextWrapped    = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent         = previewSection,
	})
	self._previewSection = previewSection
	self._previewText    = previewText

	makeLabel({
		Size           = UDim2.new(1, 0, 0, 16),
		Text           = "SheetSync  •  MIT License  •  Fox Jet Studios",
		Font           = Enum.Font.BuilderSans,
		TextSize       = 10,
		TextColor3     = C.SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder    = 9,
		Parent         = root,
	})

	importBtn.Activated:Connect(function() self:_onImport() end)
	previewBtn.Activated:Connect(function() self:_onPreview() end)
	clearBtn.Activated:Connect(function()
		logger:clear()
		logger:info("Log cleared.")
	end)
end

function UIController:_setImportBusy(busy)
	self._importBtn.Active = not busy
	self._importBtn.Text   = busy and "  Importing…" or "⬇  Import"
	self._setSpinner(busy)
end

function UIController:_handleFetchError(err)
	if err == "HTTP_DISABLED" then
		self._logger:error("HTTP requests are not enabled in Studio. Go to Game Settings → Security → Enable Studio Access to API Services.")
	elseif err == "ACCESS_DENIED" then
		self._logger:error("Could not read the sheet. Make sure it is set to public: Share → Anyone with the link → Viewer.")
	else
		self._logger:error(err)
	end
end

function UIController:_onImport()
	local url         = self._urlBox.Text
	local name        = self._nameBox.Text ~= "" and self._nameBox.Text or "SheetData"
	local outputType  = self._getOutputType()
	local destination = self._getDestination()

	self._logger:info("Starting import…")
	self._logger:info("Output: " .. outputType .. " → " .. destination)
	self:_setImportBusy(true)

	task.spawn(function()
		local csvText, fetchErr = SheetFetcher.fetch(url)

		if fetchErr then
			self:_setImportBusy(false)
			self:_handleFetchError(fetchErr)
			return
		end

		self._logger:success("Fetched " .. #csvText .. " bytes from Google Sheets.")

		local headers, rows = CSVParser.parse(csvText)

		if #headers == 0 then
			self:_setImportBusy(false)
			self._logger:error("Failed to parse CSV: no columns found.")
			return
		end

		self._logger:info(string.format("Parsed %d column(s), %d row(s).", #headers, #rows))
		self._headers = headers
		self._rows    = rows

		local instance, genErr = Generator.generate({
			name        = name,
			outputType  = outputType,
			destination = destination,
			headers     = headers,
			rows        = rows,
		})

		self:_setImportBusy(false)

		if genErr then
			self._logger:error("Generation failed: " .. genErr)
			return
		end
		
		if not instance then
			self._logger:error("Generation failed: " .. tostring(instance))
			return
		end

		self._logger:success(string.format(
			"Created '%s' (%s) in %s ✓", instance.Name, instance.ClassName, destination
			))

		TweenService:Create(self._importBtn, TWEEN_FAST, {BackgroundColor3 = C.SUCCESS}):Play()
		task.delay(1.2, function()
			TweenService:Create(self._importBtn, TWEEN_MED, {BackgroundColor3 = C.BTN_IMPORT}):Play()
		end)
	end)
end

function UIController:_onPreview()
	local url = self._urlBox.Text

	if url == "" then
		self._logger:warn("Enter a Google Sheets URL first.")
		return
	end

	self._logger:info("Fetching preview…")

	task.spawn(function()
		local csvText, err = SheetFetcher.fetch(url)
		if err then
			self:_handleFetchError(err)
			return
		end

		local headers, rows = CSVParser.parse(csvText)
		self._headers = headers
		self._rows    = rows

		local lines = { table.concat(headers, "  |  ") }
		table.insert(lines, string.rep("─", 60))
		for i = 1, math.min(10, #rows) do
			local row  = rows[i]
			local cols = {}
			for _, h in ipairs(headers) do
				table.insert(cols, tostring(row[h] ~= nil and row[h] or ""))
			end
			table.insert(lines, table.concat(cols, "  |  "))
		end
		if #rows > 10 then
			table.insert(lines, string.format("… (%d more rows)", #rows - 10))
		end

		self._previewText.Text    = table.concat(lines, "\n")
		self._previewSection.Visible = true
		TweenService:Create(self._previewSection, TWEEN_MED, {Size = UDim2.new(1, 0, 0, 180)}):Play()

		self._logger:success(string.format(
			"Preview ready: %d col(s), %d row(s).", #headers, #rows
			))
	end)
end

return UIController