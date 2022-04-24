--[[getgenv().Network = {}
for Index, Table in pairs(getgc(true)) do
    if typeof(Table) == "table"
    and rawget(Table,"FireServer")
    and rawget(Table,"InvokeServer") then
        function Network:FireServer(...)
            Table:FireServer(...)
        end
        function Network:InvokeServer(...)
            Table:InvokeServer(...)
        end
        break
    end
end]]

getgenv().Network = {}

local Key
local Verify

local Byte = string.byte
local Char = string.char
local Sub = string.sub

local HttpService = game:GetService("HttpService")

local GameEvents = game:GetService("ReplicatedStorage").Events
local RemoteEvent = GameEvents:FindFirstChild("RemoteEvent")
local RemoteFunction = GameEvents:FindFirstChild("RemoteFunction")

for Index, Func in pairs(getgc()) do
    local FEnv = getfenv(Func)
    if FEnv.script and FEnv.script.Name == "Flux/client" then
        local UpValues = getupvalues(Func)
        if UpValues[5] then
            Key = UpValues[5] -- encoded table with numbers ex: [1, 2, 3, 4]
            Verify = UpValues[4] -- GUID
            break
        end
    end
end

local function ConfuseChar(Character, Offset, SubtractValue)
    -- (string.byte(p1) - 32 +
    -- (p3 and -p2 or p2)) first
    -- then % 95 + 32 and at the end char
    local CByte = Byte(Character) - 32
    CByte = CByte + (SubtractValue and -Offset or Offset)
    CByte = Char(CByte % 95 + 32)
    return CByte
end

local function EncryptArguments(String, Key, SubtractValue)
    local Output = ""
    local StringLenght = string.len(String)
    for Index = 1, StringLenght do
        if Index <= StringLenght - Key[5] or not SubtractValue then
            for InnerIndex = 0, 3 do
                if Index % 4 == InnerIndex then
                    Output = Output .. ConfuseChar(Sub(String, Index, Index), Key[InnerIndex + 1], SubtractValue)
                    break
                end
            end
        end
    end
    if not SubtractValue then
        for Index = 1, Key[5] do
            Output = Output .. Char(Byte(String) - Byte(tostring(Index)))
        end
    end
    return Output
end

function Network:FireServer(...)
    RemoteEvent:FireServer(EncryptArguments(HttpService:JSONEncode({Verify, ...}), HttpService:JSONDecode(Key)))
end

function Network:InvokeServer(...)
    return RemoteFunction:InvokeServer(EncryptArguments(HttpService:JSONEncode({Verify, ...}), HttpService:JSONDecode(Key)))
end
