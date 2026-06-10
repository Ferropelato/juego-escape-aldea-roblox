local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerDataModule = require(Shared.Types.PlayerData)
local TableUtil = require(Shared.Util.TableUtil)

local DataService = {}
DataService._cache = {} :: { [Player]: any }
DataService._usingMock = false

-- Guardado en memoria cuando DataStore no funciona (Studio sin publicar)
local mockData: { [string]: any } = {}
local MockStore = {}
function MockStore:GetAsync(key: string)
	return mockData[key]
end
function MockStore:SetAsync(key: string, value: any)
	mockData[key] = value
end

local function createStore()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("EscapeIsland_v1")
	end)
	if not ok or not store then
		return nil
	end

	-- Probar acceso real (en Studio sin publicar suele fallar aquí)
	local testOk = pcall(function()
		store:GetAsync("__escape_island_test__")
	end)
	if not testOk then
		return nil
	end

	return store
end

local store = createStore()
if not store then
	store = MockStore
	DataService._usingMock = true
	if RunService:IsStudio() then
		warn(
			"[EscapeIsland] DataStore no disponible en Studio. "
				.. "Usando guardado temporal. Para guardar en la nube: publicá el juego y activá API en Configuración."
		)
	else
		warn("[EscapeIsland] DataStore no disponible, usando guardado temporal.")
	end
end

DataService._store = store

local SAVE_KEY_PREFIX = "player_"

function DataService.get(player: Player)
	if DataService._cache[player] then
		return DataService._cache[player]
	end
	local data = PlayerDataModule.getDefault()
	DataService._cache[player] = data
	return data
end

function DataService.load(player: Player): boolean
	local key = SAVE_KEY_PREFIX .. player.UserId
	local ok, result = pcall(function()
		return DataService._store:GetAsync(key)
	end)

	local data = PlayerDataModule.getDefault()
	if ok and type(result) == "table" then
		data = TableUtil.merge(data, result)
		if result.lastCheckpointPosition and type(result.lastCheckpointPosition) == "table" then
			local p = result.lastCheckpointPosition
			data.lastCheckpointPosition = Vector3.new(p[1] or p.X or 0, p[2] or p.Y or 0, p[3] or p.Z or 0)
		end
	end

	DataService._cache[player] = data
	return ok
end

function DataService.save(player: Player): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end

	local toSave = TableUtil.deepCopy(data)
	if toSave.lastCheckpointPosition then
		local pos = toSave.lastCheckpointPosition
		toSave.lastCheckpointPosition = { pos.X, pos.Y, pos.Z }
	end

	local key = SAVE_KEY_PREFIX .. player.UserId
	local ok = pcall(function()
		DataService._store:SetAsync(key, toSave)
	end)
	return ok
end

function DataService.remove(player: Player)
	DataService._cache[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	DataService.save(player)
	DataService.remove(player)
end)

return DataService
