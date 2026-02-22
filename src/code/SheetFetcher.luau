-- SheetFetcher.lua
-- Converts a Google Sheets URL to its CSV export URL and fetches the data.

local HttpService = game:GetService("HttpService")

local SheetFetcher = {}

local function extractSheetId(rawUrl: string): (string?, string?)
	if not rawUrl or rawUrl:gsub("%s", "") == "" then
		return nil, "URL is empty."
	end

	local sheetId = rawUrl:match("/spreadsheets/d/([A-Za-z0-9_%-]+)")
	if not sheetId then
		return nil, "Invalid Google Sheets URL."
	end

	return sheetId, nil
end

local function buildFetchUrl(sheetId: string, gid: string?): string
	local url = "https://docs.google.com/spreadsheets/d/" .. sheetId .. "/export?format=csv"
	if gid then
		url ..= "&gid=" .. gid
	end
	return url
end

function SheetFetcher.fetch(rawUrl: string): (string?, string?)
	local sheetId, err = extractSheetId(rawUrl)
	if err then
		return nil, err
	end

	local gid = rawUrl:match("[?&]gid=(%d+)")
	local fetchUrl = buildFetchUrl(sheetId, gid)

	local ok, result = pcall(function()
		return HttpService:GetAsync(fetchUrl, true)
	end)

	if not ok then
		local msg = tostring(result)
		if msg:lower():find("http requests are not enabled") then
			return nil, "HTTP_DISABLED"
		end
		if msg:lower():find("403") then
			return nil, "ACCESS_DENIED"
		end
		return nil, msg
	end

	if type(result) ~= "string" or result == "" then
		return nil, "EMPTY_RESPONSE"
	end

	if result:sub(1, 1) == "<" then
		return nil, "ACCESS_DENIED"
	end

	return result, nil
end

return SheetFetcher