-- ============================================
-- init.server.luau
-- 役割：ゲーム全体のオーケストレーション
--       RemoteEvent ホスト・勢力管理・ゲームループ
-- ============================================

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")

local GameData         = require(script.Parent.Parent.Shared.GameData)
local FactionModule    = require(script.Parent.FactionModule)
local MapModule        = require(script.Parent.MapModule)
local NPCModule        = require(script.Parent.NPCModule)
local MissionModule    = require(script.Parent.MissionModule)
local EconomyModule    = require(script.Parent.EconomyModule)

-- ============================================
-- RemoteEvent の作成
-- ============================================
local remotes = Instance.new("Folder")
remotes.Name  = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeEvent(name)
	local e = Instance.new("RemoteEvent")
	e.Name   = name
	e.Parent = remotes
	return e
end

local function makeFunction(name)
	local f = Instance.new("RemoteFunction")
	f.Name   = name
	f.Parent = remotes
	return f
end

-- UI・状態更新系
local joinFactionEvent    = makeEvent("JoinFaction")
local updateUIEvent       = makeEvent("UpdateUI")
local notifyEvent         = makeEvent("Notify")         -- 通知メッセージ
local gameOverEvent       = makeEvent("GameOver")

-- ミッション系
local missionStartEvent   = makeEvent("MissionStart")
local missionUpdateEvent  = makeEvent("MissionUpdate")
local missionEndEvent     = makeEvent("MissionEnd")

-- 戦闘・逮捕系
local crimeEvent          = makeEvent("CrimeCommitted")  -- 犯罪発生通知（警察へ）
local arrestEvent         = makeEvent("Arrest")
local damageEvent         = makeEvent("Damage")

-- 領地系
local territoryEvent      = makeEvent("TerritoryUpdate")

-- 経済系
local moneyEvent          = makeEvent("MoneyUpdate")

-- SFX系
local sfxEvent            = makeEvent("SFX")

-- RemoteFunction（データ取得）
local getPlayerDataFunc   = makeFunction("GetPlayerData")

-- ============================================
-- プレイヤーデータ管理
-- ============================================
local playerData = {}  -- { [userId] = { factionId, money, wantedLevel, ... } }

local function initPlayerData(player)
	playerData[player.UserId] = {
		factionId    = 0,
		money        = 0,
		wantedLevel  = 0,   -- 0〜5（5=最重手配）
		activeMission = nil,
		isArrested   = false,
		arrestTimer  = 0,
	}
end

local function getPlayerFaction(player)
	local data = playerData[player.UserId]
	return data and data.factionId or 0
end

local function addMoney(player, amount)
	local data = playerData[player.UserId]
	if not data then return end
	data.money = math.max(0, data.money + amount)
	moneyEvent:FireClient(player, data.money)
end

-- ============================================
-- 勢力参加イベント
-- ============================================
joinFactionEvent.OnServerEvent:Connect(function(player, factionId)
	local data = playerData[player.UserId]
	if not data then return end
	if data.factionId ~= 0 then
		-- 既に勢力参加済み
		notifyEvent:FireClient(player, "既に勢力に参加しています", "warn")
		return
	end

	local faction = GameData.Factions[factionId]
	if not faction then return end

	data.factionId = factionId
	data.money     = faction.startMoney

	-- FactionModuleに登録
	FactionModule.addMember(factionId, player)

	-- スポーン位置へテレポート
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(faction.spawnPos + Vector3.new(0, 3, 0))
		end
	end

	-- UI更新を送信
	updateUIEvent:FireClient(player, {
		type      = "factionJoined",
		factionId = factionId,
		money     = data.money,
	})

	notifyEvent:FireClient(player,
		faction.emoji .. " 「" .. faction.name .. "」に加入しました！", "success")

	print(player.Name .. " が " .. faction.name .. " に参加")
end)

-- ============================================
-- プレイヤーデータ取得（RemoteFunction）
-- ============================================
getPlayerDataFunc.OnServerInvoke = function(player)
	return playerData[player.UserId]
end

-- ============================================
-- プレイヤー参加・退出
-- ============================================
Players.PlayerAdded:Connect(function(player)
	initPlayerData(player)

	player.CharacterAdded:Connect(function(character)
		local data = playerData[player.UserId]
		if not data then return end

		-- HP設定
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.MaxHealth = GameData.PLAYER_MAX_HP
		humanoid.Health    = GameData.PLAYER_MAX_HP

		-- 勢力未参加ならスポーン後に選択UIを表示
		task.wait(1.5)
		if data.factionId == 0 then
			updateUIEvent:FireClient(player, { type = "showFactionSelect" })
		else
			-- 再スポーン時は勢力のスポーン地点へ
			local faction = GameData.Factions[data.factionId]
			if faction then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(faction.spawnPos + Vector3.new(0, 3, 0))
				end
			end
		end

		-- 死亡時
		humanoid.Died:Connect(function()
			data.money = math.max(0, data.money - 5000) -- 死亡ペナルティ
			moneyEvent:FireClient(player, data.money)
			notifyEvent:FireClient(player, "💀 やられた！¥5,000 没収されました", "warn")
		end)
	end)

	print(player.Name .. " が入室")
end)

Players.PlayerRemoving:Connect(function(player)
	local data = playerData[player.UserId]
	if data and data.factionId ~= 0 then
		FactionModule.removeMember(data.factionId, player)
	end
	playerData[player.UserId] = nil
	print(player.Name .. " が退室")
end)

-- ============================================
-- メインゲームループ（毎秒）
-- ============================================
local ticker = 0
RunService.Heartbeat:Connect(function(dt)
	ticker = ticker + dt
	if ticker < 1 then return end
	ticker = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local data = playerData[player.UserId]
		if not data or data.factionId == 0 then continue end

		-- 給与支給
		local faction = GameData.Factions[data.factionId]
		if faction and faction.salaryPerMin > 0 then
			local perSec = faction.salaryPerMin / 60
			addMoney(player, perSec)
		end

		-- 領地ボーナス
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				for _, territory in ipairs(GameData.Territories) do
					if territory.controlledBy == data.factionId then
						local dist = (root.Position - territory.position).Magnitude
						if dist < territory.radius then
							addMoney(player, territory.incomeBonus / 60)
						end
					end
				end
			end
		end

		-- 指名手配レベル自然減少
		if data.wantedLevel > 0 then
			data.wantedLevel = math.max(0, data.wantedLevel - (1/GameData.WANTED_DECAY))
		end
	end
end)

-- ============================================
-- ゲーム開始
-- ============================================
task.wait(2)
print("🌃 Neo Neon Syndicate サーバー起動！")
MapModule.buildMap(workspace)
NPCModule.spawnAll(workspace)
print("✅ マップ・NPC生成完了")
