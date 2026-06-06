-- ============================================
-- init.client.luau
-- 役割：UI・操作入力・エフェクト管理
-- ============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

-- Remotesが揃うまで待機
local remotes          = ReplicatedStorage:WaitForChild("Remotes")
local joinFactionEvent = remotes:WaitForChild("JoinFaction")
local updateUIEvent    = remotes:WaitForChild("UpdateUI")
local notifyEvent      = remotes:WaitForChild("Notify")
local moneyEvent       = remotes:WaitForChild("MoneyUpdate")
local missionStartEvent = remotes:WaitForChild("MissionStart")
local missionEndEvent  = remotes:WaitForChild("MissionEnd")
local getPlayerDataFunc = remotes:WaitForChild("GetPlayerData")

-- スマホ判定
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- カラーパレット（ダーク・サイバーパンク）
-- ============================================
local Colors = {
	bg        = Color3.fromRGB(15, 10, 25),
	bgPanel   = Color3.fromRGB(20, 15, 35),
	police    = Color3.fromRGB(30, 100, 220),
	mafia     = Color3.fromRGB(200, 20, 20),
	citizen   = Color3.fromRGB(160, 160, 160),
	gold      = Color3.fromRGB(255, 210, 50),
	neonBlue  = Color3.fromRGB(0, 200, 255),
	neonPink  = Color3.fromRGB(255, 0, 180),
	white     = Color3.fromRGB(255, 255, 255),
	dimWhite  = Color3.fromRGB(180, 180, 180),
}

local factionColors = {
	[1] = Colors.police,
	[2] = Colors.mafia,
	[3] = Colors.citizen,
}

-- ============================================
-- メインScreenGui
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "NeoNeonUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ============================================
-- ヘルパー：UICorner付きFrame生成
-- ============================================
local function makeFrame(parent, size, pos, bgColor, transparency, cornerR)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = bgColor or Colors.bgPanel
	f.BackgroundTransparency = transparency or 0.2
	f.BorderSizePixel = 0
	f.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerR or 10)
	corner.Parent = f
	return f
end

local function makeLabel(parent, text, size, pos, textColor, fontSize, bold)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = textColor or Colors.white
	l.TextScaled = fontSize == nil
	l.TextSize = fontSize or 14
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.Parent = parent
	return l
end

local function makeButton(parent, text, size, pos, bgColor, textColor, cornerR)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bgColor or Colors.neonBlue
	b.BackgroundTransparency = 0.15
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = textColor or Colors.white
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, cornerR or 8)
	return b
end

-- ============================================
-- トップバー（勢力名・所持金）
-- ============================================
local topBar = makeFrame(screenGui,
	UDim2.new(1, 0, 0, 50),
	UDim2.new(0, 0, 0, 0),
	Colors.bg, 0.1, 0)

-- 勢力名
local factionLabel = makeLabel(topBar, "🌃 NEO NEON SYNDICATE",
	UDim2.new(0.4, 0, 1, 0),
	UDim2.new(0, 10, 0, 0),
	Colors.neonBlue, nil, true)
factionLabel.TextXAlignment = Enum.TextXAlignment.Left

-- 所持金
local moneyLabel = makeLabel(topBar, "¥0",
	UDim2.new(0.3, 0, 1, 0),
	UDim2.new(0.5, 0, 0, 0),
	Colors.gold, nil, true)
moneyLabel.TextXAlignment = Enum.TextXAlignment.Center

-- 指名手配レベル
local wantedFrame = makeFrame(topBar,
	UDim2.new(0.2, 0, 0.7, 0),
	UDim2.new(0.8, 0, 0.15, 0),
	Color3.fromRGB(80,0,0), 0.2, 6)
local wantedLabel = makeLabel(wantedFrame, "⭐⭐⭐⭐⭐",
	UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
	Color3.fromRGB(80,80,80), nil, true)
wantedLabel.Name = "WantedLabel"

-- ============================================
-- 勢力選択画面（初期表示）
-- ============================================
local factionSelectGui = makeFrame(screenGui,
	UDim2.new(0.8, 0, 0.85, 0),
	UDim2.new(0.1, 0, 0.08, 0),
	Colors.bg, 0.05, 16)
factionSelectGui.Name    = "FactionSelect"
factionSelectGui.Visible = false
factionSelectGui.ZIndex  = 15

-- タイトル
makeLabel(factionSelectGui, "🌃 Neo Neon Syndicate",
	UDim2.new(1,0,0.1,0), UDim2.new(0,0,0.01,0),
	Colors.neonBlue, nil, true)
makeLabel(factionSelectGui, "勢力を選択してください",
	UDim2.new(1,0,0.07,0), UDim2.new(0,0,0.1,0),
	Colors.dimWhite, nil, false)

-- 3つの勢力カード
local factionInfo = {
	{1, "🚔 警察", Colors.police,
		"• 犯罪者を逮捕して報酬を得る\n• エリア巡回で給与獲得\n• 初期資金：¥20,000"},
	{2, "🔪 マフィア", Colors.mafia,
		"• 強盗・密輸で高額報酬\n• リスク高いが稼ぎも大きい\n• 初期資金：¥10,000"},
	{3, "🏙️ 一般市民", Colors.citizen,
		"• バー・クラブで安定収入\n• リスクが低く初心者向け\n• 初期資金：¥30,000"},
}

local cardWidth  = 0.28
local cardStartX = 0.04
for i, fi in ipairs(factionInfo) do
	local card = makeFrame(factionSelectGui,
		UDim2.new(cardWidth, 0, 0.65, 0),
		UDim2.new(cardStartX + (i-1)*(cardWidth+0.02), 0, 0.2, 0),
		Color3.fromRGB(15, 10, 30), 0.05, 12)

	-- 上部カラーバー
	local colorBar = makeFrame(card,
		UDim2.new(1,0,0.08,0), UDim2.new(0,0,0,0),
		fi[3], 0, 8)

	makeLabel(card, fi[2],
		UDim2.new(1,0,0.15,0), UDim2.new(0,0,0.1,0),
		fi[3], nil, true)

	makeLabel(card, fi[4],
		UDim2.new(0.9,0,0.45,0), UDim2.new(0.05,0,0.27,0),
		Colors.dimWhite, nil, false)

	local joinBtn = makeButton(card, "参加する",
		UDim2.new(0.7,0,0.14,0), UDim2.new(0.15,0,0.82,0),
		fi[3], Colors.white, 8)
	local fid = fi[1]
	joinBtn.MouseButton1Click:Connect(function()
		joinFactionEvent:FireServer(fid)
		factionSelectGui.Visible = false
	end)
end

-- ============================================
-- ミッションパネル（右側）
-- ============================================
local missionPanel = makeFrame(screenGui,
	UDim2.new(0.22, 0, 0.45, 0),
	UDim2.new(0.77, 0, 0.07, 0),
	Colors.bg, 0.1, 10)
missionPanel.Name    = "MissionPanel"
missionPanel.Visible = false

makeLabel(missionPanel, "📋 ミッション",
	UDim2.new(1,0,0.1,0), UDim2.new(0,0,0.01,0),
	Colors.neonBlue, nil, true)

-- ミッションリスト
local missionList = Instance.new("ScrollingFrame")
missionList.Size             = UDim2.new(0.95,0,0.82,0)
missionList.Position         = UDim2.new(0.025,0,0.13,0)
missionList.BackgroundTransparency = 1
missionList.ScrollBarThickness    = 4
missionList.CanvasSize       = UDim2.new(0,0,0,0)
missionList.Parent           = missionPanel
local listLayout = Instance.new("UIListLayout")
listLayout.Padding  = UDim.new(0,6)
listLayout.Parent   = missionList

-- ============================================
-- 進行中ミッション表示（下部）
-- ============================================
local activeMissionBar = makeFrame(screenGui,
	UDim2.new(0.5, 0, 0, 55),
	UDim2.new(0.25, 0, 1, -65),
	Color3.fromRGB(20,15,35), 0.1, 10)
activeMissionBar.Name    = "ActiveMission"
activeMissionBar.Visible = false

local activeMissionLabel = makeLabel(activeMissionBar, "",
	UDim2.new(0.65,0,1,0), UDim2.new(0.02,0,0,0),
	Colors.white, nil, false)
activeMissionLabel.TextXAlignment = Enum.TextXAlignment.Left

local activeMissionTimer = makeLabel(activeMissionBar, "00:00",
	UDim2.new(0.25,0,1,0), UDim2.new(0.7,0,0,0),
	Colors.gold, nil, true)

-- ============================================
-- 通知システム（右上ポップアップ）
-- ============================================
local function showNotify(text, notifyType)
	local bgColor = notifyType == "success" and Color3.fromRGB(0,80,40)
		or notifyType == "warn"    and Color3.fromRGB(80,40,0)
		or notifyType == "danger"  and Color3.fromRGB(80,0,0)
		or Color3.fromRGB(20,20,60)

	local popup = makeFrame(screenGui,
		UDim2.new(0.28, 0, 0, 50),
		UDim2.new(0.71, 0, 0, 60),
		bgColor, 0.15, 8)
	popup.ZIndex = 20

	makeLabel(popup, text,
		UDim2.new(1,-10,1,0), UDim2.new(5,0,0,0),
		Colors.white, nil, false)

	-- フェードアウト
	task.delay(2.5, function()
		TweenService:Create(popup, TweenInfo.new(0.4),
			{BackgroundTransparency = 1}):Play()
		task.wait(0.4)
		if popup and popup.Parent then popup:Destroy() end
	end)
end

-- ============================================
-- イベント受信
-- ============================================
updateUIEvent.OnClientEvent:Connect(function(data)
	if data.type == "showFactionSelect" then
		factionSelectGui.Visible = true

	elseif data.type == "factionJoined" then
		local factionNames = {[1]="🚔 警察",[2]="🔪 マフィア",[3]="🏙️ 市民"}
		factionLabel.Text       = factionNames[data.factionId] or "?"
		factionLabel.TextColor3 = factionColors[data.factionId] or Colors.white
		moneyLabel.Text         = "¥" .. tostring(data.money)
		missionPanel.Visible    = true
	end
end)

moneyEvent.OnClientEvent:Connect(function(amount)
	-- 金額アニメーション
	local formatted = "¥" .. tostring(math.floor(amount))
	moneyLabel.Text = formatted
	-- 光る演出
	TweenService:Create(moneyLabel, TweenInfo.new(0.2),
		{TextColor3 = Color3.fromRGB(255,255,100)}):Play()
	task.wait(0.3)
	TweenService:Create(moneyLabel, TweenInfo.new(0.3),
		{TextColor3 = Colors.gold}):Play()
end)

notifyEvent.OnClientEvent:Connect(function(text, notifyType)
	showNotify(text, notifyType)
end)

missionStartEvent.OnClientEvent:Connect(function(missionData)
	activeMissionBar.Visible  = true
	activeMissionLabel.Text   = "🎯 " .. missionData.name
	local remaining = missionData.timeLimit
	task.spawn(function()
		while remaining > 0 and activeMissionBar.Visible do
			local m = math.floor(remaining / 60)
			local s = remaining % 60
			activeMissionTimer.Text = string.format("%02d:%02d", m, s)
			if remaining <= 30 then
				activeMissionTimer.TextColor3 = Color3.fromRGB(255,80,80)
			end
			remaining -= 1
			task.wait(1)
		end
	end)
end)

missionEndEvent.OnClientEvent:Connect(function(result)
	activeMissionBar.Visible = false
	activeMissionTimer.TextColor3 = Colors.gold
	if result.success then
		showNotify("✅ " .. result.name .. " 完了！ +" .. tostring(result.reward) .. "円", "success")
	else
		showNotify("❌ " .. result.name .. " 失敗：" .. (result.reason or ""), "danger")
	end
end)

-- ============================================
-- キーボードショートカット
-- ============================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	-- Mキーでミッションパネル開閉
	if input.KeyCode == Enum.KeyCode.M then
		missionPanel.Visible = not missionPanel.Visible
	end
end)

print("🌃 Neo Neon Syndicate クライアント起動！")
