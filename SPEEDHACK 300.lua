local HttpService = game:GetService("HttpService")

local URL = "https://pastebin.com/raw/PrGsxZ9L"

local ok, response = pcall(function()
    return game:HttpGet(URL)
end)

if not ok then
    print("❌ HTTP ERROR")
    print(response)
    return
end

print("✅ HTTP REQUEST OK")
print("========== RESPONSE ==========")
print(response)
print("========== END ==========")

local clean = response:gsub("^%s+", ""):gsub("%s+$", "")

local jsonOK, data = pcall(function()
    return HttpService:JSONDecode(clean)
end)

if jsonOK then
    print("✅ JSON DECODE OK")
    print("STATUS = " .. tostring(data.status))
    print("MESSAGE = " .. tostring(data.message))
else
    print("❌ JSON DECODE FAILED")
    print(data)
end
