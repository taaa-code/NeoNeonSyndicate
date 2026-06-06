-- ============================================
-- EconomyModule.luau
-- 役割：通貨管理・取引・ゲームパス収益化
-- ============================================

local EconomyModule  = {}
local MarketplaceService = game:GetService("MarketplaceService")
local Players        = game:GetService("Players")
local GameData       = require(script.Parent.Parent.Shared.GameData)

-- ============================================
-- 金額フォーマット（例：1234567 → ¥1,234,567）
-- ============================================
function EconomyModule.format(amount)
	local s = tostring(math.floor(amount))
	local result = ""
	local count  = 0
	for i = #s, 1, -1 do
		if count > 0 and count % 3 == 0 then
			result = "," .. result
		end
		result = s:sub(i, i) .. result
		count  = count + 1
	end
	return "¥" .. result
end

-- ============================================
-- ゲームパス確認（VIPなど）
-- ============================================
function EconomyModule.hasGamePass(player, passId)
	if passId == 0 then return false end
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return success and result
end

-- ============================================
-- VIP Car パス特典
-- ============================================
function EconomyModule.checkVIPStatus(player)
	local status = {
		hasCar    = EconomyModule.hasGamePass(player, GameData.GamePasses.VIP_CAR),
		hasSuite  = EconomyModule.hasGamePass(player, GameData.GamePasses.VIP_SUITE),
		hasFit    = EconomyModule.hasGamePass(player, GameData.GamePasses.PREMIUM_FIT),
	}
	return status
end

-- ============================================
-- 送金（プレイヤー間）
-- ============================================
function EconomyModule.transfer(fromData, toData, amount, moneyEvent, fromPlayer, toPlayer)
	if fromData.money < amount then
		return false, "所持金が不足しています"
	end
	fromData.money = fromData.money - amount
	toData.money   = toData.money   + amount
	moneyEvent:FireClient(fromPlayer, fromData.money)
	moneyEvent:FireClient(toPlayer,   toData.money)
	return true, "送金完了"
end

return EconomyModule
