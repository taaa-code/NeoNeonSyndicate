-- ============================================
-- GameData.luau
-- 役割：勢力・領地・ミッション・NPC・定数の定義
-- ============================================

local GameData = {}

-- ============================================
-- 勢力定義
-- id: 1=警察 / 2=マフィア / 3=一般市民
-- ============================================
GameData.Factions = {
	[1] = {
		id           = 1,
		name         = "警察",
		nameEn       = "POLICE",
		color        = Color3.fromRGB(30, 100, 220),
		accentColor  = Color3.fromRGB(80, 160, 255),
		emoji        = "🚔",
		description  = "繁華街の治安を守る。犯罪者を逮捕して手当てを稼げ。",
		spawnPos     = Vector3.new(0, 5, 0),        -- 警察本部前
		basePos      = Vector3.new(0, 5, -100),     -- 警察本部
		startMoney   = 20000,
		salaryPerMin = 800,                          -- 毎分の給与
	},
	[2] = {
		id           = 2,
		name         = "マフィア",
		nameEn       = "MAFIA",
		color        = Color3.fromRGB(200, 20, 20),
		accentColor  = Color3.fromRGB(255, 80, 80),
		emoji        = "🔪",
		description  = "裏社会で生きる。強盗・密輸で高額報酬を狙え。",
		spawnPos     = Vector3.new(80, 5, 80),
		basePos      = Vector3.new(90, 5, 90),      -- マフィアアジト
		startMoney   = 10000,
		salaryPerMin = 0,                            -- 仕事をしなければ収入なし
	},
	[3] = {
		id           = 3,
		name         = "一般市民",
		nameEn       = "CITIZEN",
		color        = Color3.fromRGB(160, 160, 160),
		accentColor  = Color3.fromRGB(220, 220, 220),
		emoji        = "🏙️",
		description  = "夜の繁華街で働く市民。手堅く稼いで生活を守れ。",
		spawnPos     = Vector3.new(-80, 5, -80),
		basePos      = Vector3.new(-90, 5, -90),    -- ナイトクラブ街
		startMoney   = 30000,
		salaryPerMin = 200,
	},
}

-- ============================================
-- 領地定義（支配で収入UP）
-- controlledBy: 勢力ID（初期値）
-- ============================================
GameData.Territories = {
	{
		id            = 1,
		name          = "歌舞伎町 東",
		position      = Vector3.new(50, 0, 20),
		radius        = 40,
		controlledBy  = 1,   -- 初期は警察支配
		incomeBonus   = 300, -- 支配中の収入ボーナス/分
		color         = Color3.fromRGB(255, 220, 50),
	},
	{
		id            = 2,
		name          = "アメ横",
		position      = Vector3.new(-50, 0, 20),
		radius        = 40,
		controlledBy  = 3,
		incomeBonus   = 200,
		color         = Color3.fromRGB(180, 255, 100),
	},
	{
		id            = 3,
		name          = "裏路地エリア",
		position      = Vector3.new(60, 0, -60),
		radius        = 35,
		controlledBy  = 2,
		incomeBonus   = 500,
		color         = Color3.fromRGB(255, 100, 100),
	},
	{
		id            = 4,
		name          = "ネオン通り",
		position      = Vector3.new(-60, 0, -60),
		radius        = 35,
		controlledBy  = 3,
		incomeBonus   = 250,
		color         = Color3.fromRGB(100, 200, 255),
	},
}

-- ============================================
-- ミッション定義
-- faction: 対象勢力ID
-- type: "heist" | "smuggle" | "arrest" | "work"
-- ============================================
GameData.Missions = {
	-- マフィア向け
	{
		id           = "heist_atm",
		name         = "ATM強盗",
		faction      = 2,
		type         = "heist",
		description  = "繁華街のATMを襲撃して現金を奪え。警察に気をつけろ！",
		reward       = 35000,
		risk         = "高",
		timeLimit    = 90,   -- 秒
		location     = Vector3.new(40, 0, 0),
	},
	{
		id           = "heist_shop",
		name         = "質屋強盗",
		faction      = 2,
		type         = "heist",
		description  = "裏路地の質屋を狙え。金庫の暗号を解読しろ。",
		reward       = 50000,
		risk         = "高",
		timeLimit    = 120,
		location     = Vector3.new(70, 0, -40),
	},
	{
		id           = "smuggle_route1",
		name         = "密輸ルートA",
		faction      = 2,
		type         = "smuggle",
		description  = "禁止品をアジトから指定地点まで警察の目を盗んで運べ。",
		reward       = 25000,
		risk         = "中",
		timeLimit    = 150,
		startPos     = Vector3.new(90, 0, 90),
		endPos       = Vector3.new(-70, 0, 50),
	},

	-- 警察向け
	{
		id           = "arrest_wanted",
		name         = "指名手配犯逮捕",
		faction      = 1,
		type         = "arrest",
		description  = "繁華街に潜む指名手配犯を見つけて逮捕せよ。",
		reward       = 20000,
		risk         = "中",
		timeLimit    = 180,
		location     = Vector3.new(0, 0, 0),
	},
	{
		id           = "patrol_district",
		name         = "エリア巡回",
		faction      = 1,
		type         = "patrol",
		description  = "担当エリアを巡回してポイントを集めろ。",
		reward       = 8000,
		risk         = "低",
		timeLimit    = 120,
		checkpoints  = {
			Vector3.new(50, 0, 50),
			Vector3.new(-50, 0, 50),
			Vector3.new(-50, 0, -50),
			Vector3.new(50, 0, -50),
		},
	},

	-- 市民向け
	{
		id           = "work_bar",
		name         = "バーテンダー勤務",
		faction      = 3,
		type         = "work",
		description  = "タイミングよくカクテルを作って売上を上げろ。",
		reward       = 12000,
		risk         = "低",
		timeLimit    = 60,
		location     = Vector3.new(-80, 0, -30),
	},
	{
		id           = "work_club",
		name         = "クラブスタッフ",
		faction      = 3,
		type         = "work",
		description  = "VIPフロアで接客して高チップをもらえ。",
		reward       = 18000,
		risk         = "低",
		timeLimit    = 90,
		location     = Vector3.new(-100, 0, -80),
	},
}

-- ============================================
-- NPC定義
-- ============================================
GameData.NPCs = {
	-- 警察NPC
	{
		id          = 1,
		name        = "警察官A",
		faction     = 1,
		color       = Color3.fromRGB(30, 80, 180),
		task        = "patrol",
		speed       = 12,
		detectionR  = 30, -- 犯罪検知半径
		patrolPath  = {
			Vector3.new(20, 0, 20),
			Vector3.new(-20, 0, 20),
			Vector3.new(-20, 0, -20),
			Vector3.new(20, 0, -20),
		},
	},
	{
		id          = 2,
		name        = "警察官B",
		faction     = 1,
		color       = Color3.fromRGB(30, 80, 180),
		task        = "patrol",
		speed       = 12,
		detectionR  = 30,
		patrolPath  = {
			Vector3.new(60, 0, 0),
			Vector3.new(60, 0, 60),
			Vector3.new(0, 0, 60),
		},
	},
	-- マフィアNPC（見張り）
	{
		id          = 3,
		name        = "舎弟A",
		faction     = 2,
		color       = Color3.fromRGB(160, 20, 20),
		task        = "guard",
		speed       = 10,
		detectionR  = 25,
		guardPos    = Vector3.new(90, 0, 85),
	},
	-- 市民NPC（通行人）
	{
		id          = 4,
		name        = "通行人A",
		faction     = 3,
		color       = Color3.fromRGB(140, 140, 140),
		task        = "wander",
		speed       = 8,
		detectionR  = 0,
		wanderArea  = { center = Vector3.new(-60, 0, -60), radius = 40 },
	},
}

-- ============================================
-- 定数
-- ============================================
GameData.MAX_PLAYERS   = 8
GameData.PLAYER_MAX_HP = 100
GameData.ARREST_TIME   = 180   -- 逮捕後の待機秒数
GameData.WANTED_DECAY  = 30    -- 指名手配レベル低下秒数

-- ゲームパス（収益化）
GameData.GamePasses = {
	VIP_CAR     = 0,   -- 未設定（公開後にIDを入力）
	VIP_SUITE   = 0,
	PREMIUM_FIT = 0,
}

return GameData
