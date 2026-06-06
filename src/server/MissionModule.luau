-- ============================================
-- MissionModule.luau
-- 役割：ミッション開始・進捗管理・報酬支給
-- ============================================

local MissionModule = {}
local Players   = game:GetService("Players")
local GameData  = require(script.Parent.Parent.Shared.GameData)

-- 進行中ミッション { [userId] = { missionId, startTime, progress } }
local activeMissions = {}

-- ============================================
-- ミッション開始
-- ============================================
function MissionModule.startMission(player, missionId, missionStartEvent, missionUpdateEvent, addMoneyFn)
	local data = nil
	for _, m in ipairs(GameData.Missions) do
		if m.id == missionId then data = m; break end
	end
	if not data then return false, "ミッションが見つかりません" end

	if activeMissions[player.UserId] then
		return false, "既に別のミッションが進行中です"
	end

	activeMissions[player.UserId] = {
		mission   = data,
		startTime = os.time(),
		progress  = 0,
	}

	missionStartEvent:FireClient(player, {
		id          = data.id,
		name        = data.name,
		description = data.description,
		timeLimit   = data.timeLimit,
		reward      = data.reward,
		risk        = data.risk,
		type        = data.type,
	})

	-- タイムリミット管理
	task.spawn(function()
		task.wait(data.timeLimit)
		if activeMissions[player.UserId] and
		   activeMissions[player.UserId].mission.id == missionId then
			MissionModule.failMission(player, "時間切れ！", missionUpdateEvent)
		end
	end)

	return true, "ミッション開始：" .. data.name
end

-- ============================================
-- ミッション成功
-- ============================================
function MissionModule.completeMission(player, missionId, missionEndEvent, addMoneyFn)
	local active = activeMissions[player.UserId]
	if not active or active.mission.id ~= missionId then return end

	local reward = active.mission.reward
	activeMissions[player.UserId] = nil

	addMoneyFn(player, reward)

	missionEndEvent:FireClient(player, {
		success = true,
		reward  = reward,
		name    = active.mission.name,
	})

	print(player.Name .. " がミッション完了：" .. active.mission.name .. " ¥" .. reward)
end

-- ============================================
-- ミッション失敗
-- ============================================
function MissionModule.failMission(player, reason, missionEndEvent)
	local active = activeMissions[player.UserId]
	if not active then return end

	activeMissions[player.UserId] = nil

	missionEndEvent:FireClient(player, {
		success = false,
		reason  = reason or "失敗",
		name    = active.mission.name,
	})

	print(player.Name .. " がミッション失敗：" .. active.mission.name)
end

-- ============================================
-- プレイヤーの進行中ミッション取得
-- ============================================
function MissionModule.getActive(player)
	return activeMissions[player.UserId]
end

-- ============================================
-- 利用可能なミッション一覧取得（勢力フィルタ）
-- ============================================
function MissionModule.getAvailable(factionId)
	local result = {}
	for _, m in ipairs(GameData.Missions) do
		if m.faction == factionId then
			table.insert(result, {
				id          = m.id,
				name        = m.name,
				description = m.description,
				reward      = m.reward,
				risk        = m.risk,
				type        = m.type,
				timeLimit   = m.timeLimit,
			})
		end
	end
	return result
end

return MissionModule
