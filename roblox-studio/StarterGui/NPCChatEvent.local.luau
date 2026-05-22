-- StarterGui/DialogGui/NPCChatEvent (LocalScript)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local openEvt = ReplicatedStorage:WaitForChild("OpenDialog")
local chatEvt = ReplicatedStorage:WaitForChild("NPCChatEvent")

local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")
local chatFrame = mainFrame:WaitForChild("Frame") -- ScrollingFrame
local input = mainFrame:WaitForChild("TextBox")
local send = mainFrame:WaitForChild("TextButton")
local template = chatFrame:WaitForChild("TemplateMessage")
local closeBtn = mainFrame:WaitForChild("CloseButton")

local SHOW_GREETING_ON_OPEN = true
local DEFAULT_GREETING = "NPC : Halo, ada yang ingin kamu tanyakan?"

local currentDialog = {
	npcName = nil,
	displayName = "NPC",
	greeting = DEFAULT_GREETING,
}

template.Visible = false
mainFrame.Visible = false

local function resetChat()
	for _, child in ipairs(chatFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= template then
			child:Destroy()
		end
	end
	chatFrame.CanvasPosition = Vector2.new(0, 0)
end

local function addMessage(text, isNPC)
	local bubble = template:Clone()
	bubble.Visible = true
	bubble.Name = "MsgItem"
	bubble.Parent = chatFrame
	bubble.AutomaticSize = Enum.AutomaticSize.XY

	local textLabel = bubble:FindFirstChildOfClass("TextLabel")
	textLabel.TextWrapped = true
	textLabel.AutomaticSize = Enum.AutomaticSize.Y
	textLabel.Text = text
	textLabel.BackgroundTransparency = 1

	local maxWidth = chatFrame.AbsoluteSize.X * 0.7
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(maxWidth, math.huge)
	constraint.Parent = bubble

	textLabel.TextXAlignment = Enum.TextXAlignment.Left

	if isNPC then
		textLabel.TextColor3 = Color3.fromHex("#000000")
		bubble.BackgroundColor3 = Color3.fromHex("#DCF8C6")
	else
		textLabel.TextColor3 = Color3.fromHex("#FFFFFF")
		bubble.BackgroundColor3 = Color3.fromHex("#0084FF")
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bubble

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = bubble

	local atBottom = chatFrame.CanvasPosition.Y >= (chatFrame.AbsoluteCanvasSize.Y - chatFrame.AbsoluteSize.Y - 5)
	if atBottom then
		chatFrame.CanvasPosition = Vector2.new(0, chatFrame.AbsoluteCanvasSize.Y)
	end
end

local function setDialogData(data)
	if typeof(data) ~= "table" then
		currentDialog.npcName = nil
		currentDialog.displayName = "NPC"
		currentDialog.greeting = DEFAULT_GREETING
		return
	end

	currentDialog.npcName = data.npcName
	currentDialog.displayName = data.displayName or data.npcName or "NPC"
	currentDialog.greeting = data.greeting or DEFAULT_GREETING
end

openEvt.OnClientEvent:Connect(function(data)
	setDialogData(data)
	mainFrame.Visible = true
	resetChat()

	if SHOW_GREETING_ON_OPEN then
		addMessage(currentDialog.greeting, true)
	end

	input.PlaceholderText = "Chat dengan " .. currentDialog.displayName
	input:CaptureFocus()
end)

local function sendMessage()
	local msg = input.Text
	if msg == nil or msg == "" then
		return
	end

	addMessage("Kamu : " .. msg, false)
	chatEvt:FireServer(msg)
	input.Text = ""
end

send.MouseButton1Click:Connect(sendMessage)
input.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		sendMessage()
	end
end)

chatEvt.OnClientEvent:Connect(function(reply)
	local text = tostring(reply)
	if text == nil or text == "" then
		text = "..."
	end
	addMessage("NPC : " .. text, true)
end)

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	resetChat()
end)
