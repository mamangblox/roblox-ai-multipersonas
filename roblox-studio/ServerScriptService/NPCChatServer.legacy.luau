-- ServerScriptService/NPCChatServer
--
-- Edit NPC_CONFIG di file ini untuk menambah/mengubah NPC.
-- Setiap key harus sama dengan nama Model NPC di Workspace.
-- Persona yang valid untuk backend Railway hanya:
-- guard, merchant, wizard, robot

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local chatEvt = ReplicatedStorage:FindFirstChild("NPCChatEvent")
if not chatEvt then
	chatEvt = Instance.new("RemoteEvent")
	chatEvt.Name = "NPCChatEvent"
	chatEvt.Parent = ReplicatedStorage
end

local openDialogEvt = ReplicatedStorage:FindFirstChild("OpenDialog")
if not openDialogEvt then
	openDialogEvt = Instance.new("RemoteEvent")
	openDialogEvt.Name = "OpenDialog"
	openDialogEvt.Parent = ReplicatedStorage
end

local AI_URL = "https://roblox-ai-multipersona-production.up.railway.app/webhook/roblox-ai"

local NPC_CONFIG = {
	GuardNPC = {
		displayName = "Penjaga Kota",
		greeting = "Halo. Ada yang perlu dilaporkan?",
		promptActionText = "Bicara",
		promptObjectText = "Penjaga Kota",
		systemPrompt = "Kamu adalah Penjaga Kota. Tegas, singkat, waspada, dan fokus pada keamanan kota. Jawab dengan 1-2 kalimat. Jangan terlalu panjang. Kalau pesan tidak relevan, arahkan pemain dengan sopan.",
	},
	MerchantNPC = {
		displayName = "Pedagang",
		greeting = "Selamat datang. Mau lihat barang dagangan?",
		promptActionText = "Bicara",
		promptObjectText = "Pedagang",
		systemPrompt = "Kamu adalah Pedagang. Ramah, suka menawarkan barang, dan terdengar persuasif. Jawab dengan 1-2 kalimat. Jangan terlalu panjang. Jika ada peluang menjual sesuatu, sebutkan secara natural.",
	},
	WizardNPC = {
		displayName = "Penyihir",
		greeting = "Awan sihir membisikkan sesuatu padaku.",
		promptActionText = "Bicara",
		promptObjectText = "Penyihir",
		systemPrompt = "Kamu adalah Penyihir. Bijak, misterius, dan memakai bahasa yang berkesan magis. Jawab dengan 1-2 kalimat. Jangan terlalu panjang. Gunakan nuansa sihir, ramalan, atau petunjuk halus bila cocok.",
	},
	RobotNPC = {
		displayName = "Robot AI",
		greeting = "Unit online. Silakan ajukan pertanyaan.",
		promptActionText = "Bicara",
		promptObjectText = "Robot AI",
		systemPrompt = "Kamu adalah Robot AI. Logis, futuristik, sedikit kaku, dan efisien. Jawab dengan 1-2 kalimat. Jangan terlalu panjang. Gunakan bahasa yang ringkas, teknis, dan konsisten.",
	},
}

local activeNpcByUserId = {}
local registeredNpcs = {}

local function getNpcRootPart(npcModel)
	return npcModel:FindFirstChild("HumanoidRootPart")
		or npcModel:FindFirstChild("Head")
		or npcModel.PrimaryPart
		or npcModel:FindFirstChildWhichIsA("BasePart")
end

local function getNpcConfig(npcModel)
	local config = NPC_CONFIG[npcModel.Name] or {}
	local displayName = config.displayName or npcModel:GetAttribute("DisplayName") or npcModel.Name
	local greeting = config.greeting or npcModel:GetAttribute("Greeting") or "Halo."
	local promptActionText = config.promptActionText or "Bicara"
	local promptObjectText = config.promptObjectText or displayName
	local systemPrompt = config.systemPrompt or npcModel:GetAttribute("SystemPrompt") or ""

	return {
		name = npcModel.Name,
		displayName = displayName,
		greeting = greeting,
		promptActionText = promptActionText,
		promptObjectText = promptObjectText,
		systemPrompt = systemPrompt,
	}
end

local function buildPromptPayload(npcConfig)
	return {
		npcName = npcConfig.name,
		displayName = npcConfig.displayName,
		systemPrompt = npcConfig.systemPrompt,
		greeting = npcConfig.greeting,
	}
end

local function askAI(player, message, npcConfig)
	local payload = {
		user = player.Name,
		message = message,
		npc_name = npcConfig.name,
		display_name = npcConfig.displayName,
		system_prompt = npcConfig.systemPrompt,
		greeting = npcConfig.greeting,
	}

	local body = HttpService:JSONEncode(payload)
	local ok, result = pcall(function()
		return HttpService:PostAsync(AI_URL, body, Enum.HttpContentType.ApplicationJson)
	end)

	if not ok then
		warn("AI ERROR:", result)
		return "Server AI sedang sibuk."
	end

	local ok2, decoded = pcall(function()
		return HttpService:JSONDecode(result)
	end)

	if ok2 and decoded and decoded.reply then
		return decoded.reply
	end

	return "Aku tidak tahu harus menjawab apa."
end

local function fireOpenDialog(player, npcConfig)
	openDialogEvt:FireClient(player, buildPromptPayload(npcConfig))
end

local function registerNpc(npcModel)
	if not npcModel:IsA("Model") then
		return
	end

	if registeredNpcs[npcModel] then
		return
	end

	local npcConfig = getNpcConfig(npcModel)
	local rootPart = getNpcRootPart(npcModel)
	if not rootPart then
		warn("NPC model has no usable part:", npcModel:GetFullName())
		return
	end

	local prompt = rootPart:FindFirstChild("NPCChatPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "NPCChatPrompt"
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt.Parent = rootPart
	end

	prompt.ActionText = npcConfig.promptActionText
	prompt.ObjectText = npcConfig.promptObjectText

	prompt.Triggered:Connect(function(player)
		activeNpcByUserId[player.UserId] = npcModel
		fireOpenDialog(player, npcConfig)
	end)

	registeredNpcs[npcModel] = true
end

local function scanAndRegisterNpcs()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and NPC_CONFIG[descendant.Name] then
			registerNpc(descendant)
		end
	end
end

scanAndRegisterNpcs()

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") and NPC_CONFIG[descendant.Name] then
		registerNpc(descendant)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	activeNpcByUserId[player.UserId] = nil
end)

chatEvt.OnServerEvent:Connect(function(player, msg)
	if typeof(msg) ~= "string" then
		return
	end

	msg = msg:sub(1, 200)

	local npcModel = activeNpcByUserId[player.UserId]
	if not npcModel or not npcModel.Parent then
		warn("Player tried to chat without an active NPC:", player.Name)
		return
	end

	local npcConfig = getNpcConfig(npcModel)
	local reply = askAI(player, msg, npcConfig)

	chatEvt:FireClient(player, reply)
end)
