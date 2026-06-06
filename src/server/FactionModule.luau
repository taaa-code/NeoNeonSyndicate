-- ============================================
-- FactionModule.luau
-- 役割：勢力メンバー管理・領地支配度・勢力間通信
-- ============================================

local FactionModule = {}
local GameData = require(script.Parent.Parent.Shared.GameData)

-- 勢力ごとのメンバーリスト
local members = {
	[1] = {},  -- 警察
	[2] = {},  -- マフィア
	[3] = {},  -- 一般市民
}

-- ============================================
-- メンバー追加・削除
-- ============================================
function FactionModule.addMember(factionId, player)
	if not members[factionId] then return end
	members[factionId][player.UserId] = player
	print(player.Name .. " → " .. GameData.Factions[factionId].name .. " に追加")
end

function FactionModule.removeMember(factionId, player)
	if not members[factionId] then return end
	members[factionId][player.UserId] = nil
end

function FactionModule.getMembers(factionId)
	local result = {}
	if not members[factionId] then return result end
	for _, player in pairs(members[factionId]) do
		table.insert(result, player)
	end
	return result
end

function FactionModule.getMemberCount(factionId)
	local count = 0
	if not members[factionId] then return 0 end
	for _ in pairs(members[factionId]) do count += 1 end
	return count
end

-- ============================================
-- 警察プレイヤー全員に犯罪通知を送る
-- ============================================
function FactionModule.notifyPolice(remoteEvent, data)
	for _, player in pairs(members[1]) do
		remoteEvent:FireClient(player, data)
	end
end

-- ============================================
-- 全勢力の状況取得
-- ============================================
function FactionModule.getStatus()
	local status = {}
	for id, faction in pairs(GameData.Factions) do
		local count = FactionModule.getMemberCount(id)
		status[id] = {
			name        = faction.name,
			memberCount = count,
		}
	end
	return status
end

return FactionModule
