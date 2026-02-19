-- CSVParser.lua
-- Parses CSV text into a Lua table of rows.

local CSVParser = {}

local function splitLine(line: string): {string}
	local fields = {}
	local i = 1
	local len = #line

	while i <= len do
		local field = ""

		if line:sub(i, i) == '"' then
			i = i + 1
			while i <= len do
				local ch = line:sub(i, i)
				if ch == '"' then
					if line:sub(i + 1, i + 1) == '"' then
						field = field .. '"'
						i = i + 2
					else
						i = i + 1
						break
					end
				else
					field = field .. ch
					i = i + 1
				end
			end
		else
			while i <= len and line:sub(i, i) ~= "," do
				field = field .. line:sub(i, i)
				i = i + 1
			end
		end

		table.insert(fields, field)

		if i <= len and line:sub(i, i) == "," then
			i = i + 1
			if i > len then
				table.insert(fields, "")
			end
		end
	end

	return fields
end

local function coerce(value: string): any
	if value == "" then return nil end
	local n = tonumber(value)
	if n then return n end
	local lower = value:lower()
	if lower == "true"  then return true  end
	if lower == "false" then return false end
	return value
end

function CSVParser.parse(csvText: string): (any, any, any)
	local lines = {}
	csvText = csvText:gsub("\r\n", "\n"):gsub("\r", "\n")

	for line in (csvText .. "\n"):gmatch("([^\n]*)\n") do
		table.insert(lines, line)
	end

	while #lines > 0 and lines[#lines] == "" do
		table.remove(lines)
	end

	if #lines == 0 then
		return {}, {}, {}
	end

	local headers = splitLine(lines[1])
	local rows    = {}
	local raw     = { splitLine(lines[1]) }

	for idx = 2, #lines do
		local fields = splitLine(lines[idx])
		local row    = {}
		table.insert(raw, fields)
		for col, header in ipairs(headers) do
			row[header] = coerce(fields[col] or "")
		end
		table.insert(rows, row)
	end

	return headers, rows, raw
end

function CSVParser.serialise(headers: {string}, rows: {any}): string
	local function escape(v)
		local s = tostring(v or "")
		if s:find('[",\n\r]') then
			return '"' .. s:gsub('"', '""') .. '"'
		end
		return s
	end

	local lines = { table.concat(headers, ",") }
	for _, row in ipairs(rows) do
		local fields = {}
		for _, h in ipairs(headers) do
			table.insert(fields, escape(row[h]))
		end
		table.insert(lines, table.concat(fields, ","))
	end

	return table.concat(lines, "\n")
end

return CSVParser