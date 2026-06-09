-- ============================================
-- MapModule.luau
-- 役割：歌舞伎町風マップ生成
--       ネオンサイン・建物・路地・ライティング
-- ============================================

local MapModule = {}
local Lighting  = game:GetService("Lighting")

-- ============================================
-- ヘルパー関数
-- ============================================
local function part(parent, size, pos, color, mat, transparency)
	local p = Instance.new("Part")
	p.Size         = size
	p.CFrame       = CFrame.new(pos)
	p.Anchored     = true
	p.BrickColor   = BrickColor.new(color)
	p.Material     = mat or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Parent       = parent
	return p
end

local function neon(parent, size, pos, color3, transparency)
	local p = Instance.new("Part")
	p.Size         = size
	p.CFrame       = CFrame.new(pos)
	p.Anchored     = true
	p.Color        = color3
	p.Material     = Enum.Material.Neon
	p.Transparency = transparency or 0
	p.CanCollide   = false
	p.Parent       = parent
	return p
end

-- ネオン看板（文字付き）
local function neonSign(parent, pos, text, color3, size)
	local board = neon(parent,
		size or Vector3.new(14, 4, 0.5),
		pos, color3, 0.1)
	local bill = Instance.new("BillboardGui")
	bill.Size        = UDim2.new(0, 280, 0, 80)
	bill.StudsOffset = Vector3.new(0, 0, 0.4)
	bill.Parent      = board
	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.Text                   = text
	label.TextColor3             = color3
	label.TextScaled             = true
	label.Font                   = Enum.Font.GothamBold
	label.Parent                 = bill
	-- PointLight
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range      = 20
	light.Color      = color3
	light.Parent     = board
	return board
end

-- 建物（窓付き）
local function building(parent, size, pos, wallColor)
	local b = part(parent, size, pos, wallColor, Enum.Material.SmoothPlastic)
	-- 窓をランダムに配置
	local winColor = Color3.fromRGB(255, 240, 180)
	local winW = 2.5
	local winH = 2.0
	for row = 1, math.floor(size.Y / 5) do
		for col = 1, math.floor(size.X / 6) do
			if math.random() > 0.3 then
				local wx = pos.X - size.X/2 + col*6 - 1
				local wy = pos.Y - size.Y/2 + row*5 - 1
				neon(parent,
					Vector3.new(winW, winH, 0.3),
					Vector3.new(wx, wy, pos.Z - size.Z/2 - 0.2),
					winColor, 0.2)
			end
		end
	end
	return b
end

-- ============================================
-- マップ生成メイン
-- ============================================
function MapModule.buildMap(mapParent)
	local mapFolder = Instance.new("Folder")
	mapFolder.Name  = "NeoNeonMap"
	mapFolder.Parent = mapParent

	-- ============================================
	-- ライティング設定（深夜・ネオン街）
	-- ============================================
	Lighting.Ambient          = Color3.fromRGB(50, 30, 70)
	Lighting.Brightness       = 0.4
	Lighting.FogColor         = Color3.fromRGB(30, 10, 50)
	Lighting.FogEnd           = 250
	Lighting.FogStart         = 80
	Lighting.GlobalShadows    = true
	Lighting.OutdoorAmbient   = Color3.fromRGB(20, 10, 40)
	Lighting.TimeOfDay        = "23:00:00"  -- 深夜

	-- ============================================
	-- SpawnLocation（プレイヤースポーン地点）
	-- ============================================
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(0, 1, 0)
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("Bright blue")
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.5
	spawn.TeamColor = BrickColor.new("White")
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = 0
	spawn.Parent = mapFolder

	-- ============================================
	-- 地面（濡れたアスファルト）
	-- ============================================
	local ground = part(mapFolder,
		Vector3.new(500, 2, 500),
		Vector3.new(0, -1, 0),
		"Dark stone grey",
		Enum.Material.SmoothPlastic)
	ground.Name = "Ground"
	-- 地面反射（薄い青みがかった色）
	neon(mapFolder, Vector3.new(500, 0.1, 500), Vector3.new(0, 0.05, 0),
		Color3.fromRGB(30, 30, 80), 0.92)

	-- ============================================
	-- 壁（マップ境界）
	-- ============================================
	for _, d in ipairs({
		{Vector3.new(500,40,4), Vector3.new(0,20,250)},
		{Vector3.new(500,40,4), Vector3.new(0,20,-250)},
		{Vector3.new(4,40,500), Vector3.new(250,20,0)},
		{Vector3.new(4,40,500), Vector3.new(-250,20,0)},
	}) do
		part(mapFolder, d[1], d[2], "Really black", Enum.Material.SmoothPlastic)
	end

	-- ============================================
	-- 中央大通り（歌舞伎町メインストリート）
	-- ============================================
	-- 歩道
	part(mapFolder, Vector3.new(30, 0.5, 400), Vector3.new(0,0.25,0),
		"Sand yellow", Enum.Material.Concrete)
	-- 中央分離帯（植込み）
	for z = -180, 180, 40 do
		part(mapFolder, Vector3.new(4, 1.5, 8), Vector3.new(0, 0.75, z),
			"Forest green", Enum.Material.Grass)
	end

	-- 街灯
	for z = -200, 200, 40 do
		for _, x in ipairs({18, -18}) do
			local pole = part(mapFolder, Vector3.new(0.5, 10, 0.5),
				Vector3.new(x, 5, z), "Mid gray", Enum.Material.Metal)
			local lamp = neon(mapFolder, Vector3.new(2, 1, 2),
				Vector3.new(x, 10.5, z), Color3.fromRGB(255, 220, 150))
			local pl = Instance.new("PointLight")
			pl.Range      = 25
			pl.Brightness = 2
			pl.Color      = Color3.fromRGB(255, 200, 100)
			pl.Parent     = lamp
		end
	end

	-- ============================================
	-- 建物群（左ブロック）
	-- ============================================
	local buildingConfigs = {
		-- 左側ブロック
		{Vector3.new(40, 50, 30), Vector3.new(-60, 25, -80),  "Dark stone grey"},
		{Vector3.new(35, 35, 30), Vector3.new(-65, 17, -30),  "Dark orange"},
		{Vector3.new(45, 60, 35), Vector3.new(-55, 30, 40),   "Dark stone grey"},
		{Vector3.new(30, 40, 25), Vector3.new(-70, 20, 100),  "Really black"},
		{Vector3.new(50, 70, 40), Vector3.new(-55, 35, 170),  "Dark stone grey"},
		-- 右側ブロック
		{Vector3.new(40, 45, 30), Vector3.new(60, 22, -80),   "Dark stone grey"},
		{Vector3.new(35, 55, 35), Vector3.new(65, 27, -20),   "Dark orange"},
		{Vector3.new(45, 35, 25), Vector3.new(55, 17, 50),    "Really black"},
		{Vector3.new(30, 50, 30), Vector3.new(70, 25, 120),   "Dark stone grey"},
		{Vector3.new(50, 65, 40), Vector3.new(60, 32, 190),   "Dark stone grey"},
	}

	for _, bc in ipairs(buildingConfigs) do
		building(mapFolder, bc[1], bc[2], bc[3])
	end

	-- ============================================
	-- ネオンサイン群
	-- ============================================
	local signs = {
		-- 日本語ネオン看板
		{Vector3.new(-35, 12, -90), "🍺 BAR NEON",         Color3.fromRGB(0, 200, 255)},
		{Vector3.new(-35, 18, -40), "💃 CLUB 極",          Color3.fromRGB(255, 0, 150)},
		{Vector3.new(-35, 10, 30),  "🎰 PACHINKO",         Color3.fromRGB(255, 220, 0)},
		{Vector3.new(-35, 15, 90),  "🍜 ラーメン 深夜",    Color3.fromRGB(255, 100, 0)},
		{Vector3.new(35, 12, -80),  "💹 両替 EXCHANGE",    Color3.fromRGB(0, 255, 100)},
		{Vector3.new(35, 20, -20),  "🕹️ ARCADE UNDERGROUND", Color3.fromRGB(150, 0, 255)},
		{Vector3.new(35, 14, 60),   "💊 PHARMACY 24H",     Color3.fromRGB(100, 255, 255)},
		{Vector3.new(35, 16, 130),  "🔪 質屋 PAWN",        Color3.fromRGB(255, 50, 50)},
	}

	for _, s in ipairs(signs) do
		neonSign(mapFolder, s[1], s[2], s[3])
	end

	-- ============================================
	-- 路地裏（裏通り）
	-- ============================================
	-- 路地の地面
	for _, cfg in ipairs({
		{Vector3.new(12, 0.5, 200), Vector3.new(-95, 0.25, 10)},
		{Vector3.new(12, 0.5, 200), Vector3.new(95, 0.25, 10)},
	}) do
		part(mapFolder, cfg[1], cfg[2], "Really black", Enum.Material.SmoothPlastic)
	end

	-- ゴミ箱
	for z = -80, 160, 30 do
		for _, x in ipairs({-90, 90}) do
			part(mapFolder, Vector3.new(2,3,2), Vector3.new(x,1.5,z),
				"Dark stone grey", Enum.Material.Metal)
		end
	end

	-- ============================================
	-- 警察本部（北側）
	-- ============================================
	local policeHQ = Instance.new("Folder")
	policeHQ.Name  = "PoliceHQ"
	policeHQ.Parent = mapFolder

	-- 建物本体
	part(policeHQ, Vector3.new(60, 30, 40), Vector3.new(0, 15, -170),
		"Mid gray", Enum.Material.SmoothPlastic)
	-- 入口の青いライン
	neon(policeHQ, Vector3.new(60, 0.5, 40.5), Vector3.new(0, 0.5, -150),
		Color3.fromRGB(30, 100, 255), 0.3)
	neonSign(policeHQ, Vector3.new(0, 32, -170), "🚔 POLICE STATION",
		Color3.fromRGB(50, 130, 255))

	-- ============================================
	-- マフィアアジト（南東）
	-- ============================================
	local mafia = Instance.new("Folder")
	mafia.Name  = "MafiaBase"
	mafia.Parent = mapFolder

	part(mafia, Vector3.new(40, 25, 40), Vector3.new(130, 12, 130),
		"Really black", Enum.Material.SmoothPlastic)
	neon(mafia, Vector3.new(40, 0.5, 40.5), Vector3.new(130, 0.5, 110),
		Color3.fromRGB(200, 20, 20), 0.3)
	neonSign(mafia, Vector3.new(130, 27, 130), "🔪 SYNDICATE HQ",
		Color3.fromRGB(255, 30, 30))

	-- ============================================
	-- ナイトクラブ街（南西）
	-- ============================================
	local club = Instance.new("Folder")
	club.Name  = "NightclubDistrict"
	club.Parent = mapFolder

	part(club, Vector3.new(50, 20, 50), Vector3.new(-130, 10, -130),
		"Dark stone grey", Enum.Material.SmoothPlastic)
	neonSign(club, Vector3.new(-130, 23, -130), "💃 NIGHTCLUB DISTRICT",
		Color3.fromRGB(255, 0, 200))
	-- クラブのカラフルライト
	local clubColors = {
		Color3.fromRGB(255,0,150),
		Color3.fromRGB(0,200,255),
		Color3.fromRGB(150,0,255),
		Color3.fromRGB(255,150,0),
	}
	for i, c in ipairs(clubColors) do
		local a = math.rad((i-1) * 90)
		local lp = neon(club, Vector3.new(1,1,1),
			Vector3.new(-130 + math.cos(a)*20, 2, -130 + math.sin(a)*20), c)
		local pl = Instance.new("PointLight")
		pl.Range = 30; pl.Brightness = 4; pl.Color = c
		pl.Parent = lp
	end

	-- ============================================
	-- ATM（強盗ターゲット）
	-- ============================================
	local atm = part(mapFolder, Vector3.new(2, 4, 1.5),
		Vector3.new(40, 2, 0), "Dark stone grey", Enum.Material.Metal)
	atm.Name = "ATM_Target"
	atm:SetAttribute("type", "heist_atm")
	local atmSign = Instance.new("BillboardGui")
	atmSign.Size = UDim2.new(0, 100, 0, 30)
	atmSign.StudsOffset = Vector3.new(0, 3, 0)
	atmSign.Parent = atm
	local atmLabel = Instance.new("TextLabel")
	atmLabel.Size = UDim2.new(1,0,1,0)
	atmLabel.BackgroundTransparency = 1
	atmLabel.Text = "🏧 ATM"
	atmLabel.TextColor3 = Color3.fromRGB(0,255,100)
	atmLabel.TextScaled = true
	atmLabel.Font = Enum.Font.GothamBold
	atmLabel.Parent = atmSign

	print("🗺️ 歌舞伎町マップ生成完了！")
end

return MapModule
