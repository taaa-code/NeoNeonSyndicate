-- ============================================
-- NPCModule.luau
-- 役割：NPC生成・巡回AI・犯罪検知
-- ============================================

local NPCModule  = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local GameData   = require(script.Parent.Parent.Shared.GameData)

local npcFolder  = nil
local aiConns    = {}

-- ============================================
-- NPC モデル生成
-- ============================================
local function makeNPCModel(data, parent)
	local model  = Instance.new("Model")
	model.Name   = data.name
	model.Parent = parent

	-- 胴体
	local torso = Instance.new("Part")
	torso.Name      = "HumanoidRootPart"
	torso.Size      = Vector3.new(2, 2, 1)
	torso.Color     = data.color
	torso.Material  = Enum.Material.SmoothPlastic
	torso.CFrame    = CFrame.new(data.guardPos or data.patrolPath and data.patrolPath[1] or Vector3.new(0,3,0))
	torso.Parent    = model
	model.PrimaryPart = torso

	-- 頭
	local head = Instance.new("Part")
	head.Name     = "Head"
	head.Size     = Vector3.new(1.5, 1.5, 1.5)
	head.Color    = Color3.fromRGB(255, 210, 180)
	head.Material = Enum.Material.SmoothPlastic
	head.Parent   = model

	-- Humanoid
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 100
	hum.Health    = 100
	hum.WalkSpeed = data.speed or 10
	hum.Parent    = model

	-- 頭のWeld
	local weld = Instance.new("WeldConstraint")
	weld.Part0  = torso
	weld.Part1  = head
	weld.Parent = torso
	head.CFrame = torso.CFrame * CFrame.new(0, 1.75, 0)

	-- 名前ラベル
	local bill = Instance.new("BillboardGui")
	bill.Size        = UDim2.new(0,150,0,30)
	bill.StudsOffset = Vector3.new(0, 3, 0)
	bill.Parent      = torso
	local nameLabel  = Instance.new("TextLabel")
	nameLabel.Size                   = UDim2.new(1,0,1,0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text       = data.name
	nameLabel.TextColor3 = data.color
	nameLabel.TextScaled = true
	nameLabel.Font       = Enum.Font.GothamBold
	nameLabel.Parent     = bill

	return model
end

-- ============================================
-- 巡回AIのセットアップ
-- ============================================
local function setupPatrolAI(model, npcData)
	local path      = npcData.patrolPath
	if not path or #path == 0 then return end

	local humanoid  = model:FindFirstChildOfClass("Humanoid")
	local root      = model.PrimaryPart
	if not humanoid or not root then return end

	local idx = 1
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not model or not model.Parent then
			conn:Disconnect()
			return
		end

		local target = path[idx]
		local dist   = (root.Position - Vector3.new(target.X, root.Position.Y, target.Z)).Magnitude

		if dist < 3 then
			idx = (idx % #path) + 1
		else
			humanoid:MoveTo(target)
		end

		-- 犯罪行為中のプレイヤーを検知
		if npcData.faction == 1 and npcData.detectionR > 0 then
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if char then
					local pr = char:FindFirstChild("HumanoidRootPart")
					if pr then
						local d = (root.Position - pr.Position).Magnitude
						if d < npcData.detectionR then
							-- 検知時の処理はMissionModuleに委譲
							model:SetAttribute("DetectedPlayer", player.Name)
						end
					end
				end
			end
		end
	end)

	table.insert(aiConns, conn)
end

-- ============================================
-- 全NPC生成
-- ============================================
function NPCModule.spawnAll(parent)
	npcFolder = Instance.new("Folder")
	npcFolder.Name   = "NPCs"
	npcFolder.Parent = parent

	for _, npcData in ipairs(GameData.NPCs) do
		local model = makeNPCModel(npcData, npcFolder)
		if npcData.task == "patrol" then
			setupPatrolAI(model, npcData)
		end
	end

	print("👮 NPC " .. #GameData.NPCs .. " 体スポーン完了")
end

-- 全AI接続解除
function NPCModule.clearAll()
	for _, conn in ipairs(aiConns) do
		conn:Disconnect()
	end
	aiConns = {}
	if npcFolder then npcFolder:Destroy() end
end

return NPCModule
