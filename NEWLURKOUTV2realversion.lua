--[[
    ╦  ╦ ╦╦═╗╦╔═╗╦ ╦╔╦╗  ╦ ╦╦  ╦  ╦  ╦╔╗ ╦═╗╔═╗╦═╗╦ ╦
    ║  ║ ║╠╦╝╠╩╗║ ║║ ║ ║   ║ ║║  ║  ║  ║╠╩╗╠╦╝╠═╣╠╦╝╚╦╝
    ╩═╝╚═╝╩╚═╩ ╩╚═╝╚═╝ ╩   ╚═╝╩  ╩═╝╩═╝╩╚═╝╩╚═╩ ╩╩╚═ ╩ 
    
    Version: 3.5 ENHANCED - Dark Mode Edition
    Theme: Pure Black with Red Accents - Enhanced UX
    Modified: Fixed Home Tab, Better Welcome Screen, Proper Colors
]]--

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local function GenerateRandomString(length)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result = ""
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        result = result .. chars:sub(randomIndex, randomIndex)
    end
    return result
end

local LocalPlayer = Players.LocalPlayer

local function GetBestParent()
    local success, result = pcall(function()
        if gethui then
            return gethui()
        elseif syn and syn.protect_gui then
            return CoreGui
        elseif get_hidden_gui then
            return get_hidden_gui()
        else
            return LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    
    if success then
        return result
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

local PlayerGui = GetBestParent()

local LURKOUT = {}
LURKOUT.__index = LURKOUT

local Config = {
    NavbarHC = Color3.fromRGB(255,255,255),
    NavbarHC2 = Color3.fromRGB(255,0,0),
    MainColor = Color3.fromRGB(0, 0, 0),
    SecondaryColor = Color3.fromRGB(80, 8, 8),
    TertiaryColor = Color3.fromRGB(50, 20, 20),
    AccentColor = Color3.fromRGB(0, 20, 20),
    GlowColor = Color3.fromRGB(0, 0, 0),
    TextColor = Color3.fromRGB(200, 200, 200),
    BorderColor = Color3.fromRGB(255, 30, 30),
    ButtonHover = Color3.fromRGB(255, 25, 25),
    DropdownBG = Color3.fromRGB(25, 25, 25),
    DropdownOptionBG = Color3.fromRGB(35, 35, 35),
    DropdownTextColor = Color3.fromRGB(255, 255, 255),
    HoverTextColor = Color3.fromRGB(255, 255, 255),  -- FIXED: White text on hover
    ToggleKey = Enum.KeyCode.RightControl,
    DiscordLink = "https://discord.gg/lurkout",
    WebsiteLink = "https://lurkout.com"
}

local function Tween(instance, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function CreateFrameShadow(parent, color, size)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = GenerateRandomString(12)
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = color or Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.3
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -(size or 3), 0, -(size or 3))
    shadow.Size = UDim2.new(1, (size or 3) * 2, 1, (size or 3) * 2)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

local function MakeDraggable(gui, dragPart)
    local dragging = false
    local dragInput, mousePos, framePos
    
    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragPart.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
            Tween(gui, {Position = newPos}, 0.05, Enum.EasingStyle.Linear)
        end
    end)
end

function LURKOUT:Init()
    local Library = {}
    Library.Tabs = {}
    Library.CurrentTab = nil
    Library.Minimized = false
    Library.ScreenGui = nil
    Library.Main = nil
    Library.NotificationQueue = {}
    Library.ActiveNotifications = {}
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = GenerateRandomString(32)
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 999999
    
    pcall(function()
        ScreenGui.Parent = PlayerGui
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
        end
    end)
    
    if not ScreenGui.Parent then
        ScreenGui.Parent = PlayerGui
    end
    
    Library.ScreenGui = ScreenGui
    
    -- IMPROVED WELCOME CARD (Smaller, centered, CMD-style)
    local WelcomeCard = Instance.new("Frame")
    WelcomeCard.Name = GenerateRandomString(16)
    WelcomeCard.BackgroundColor3 = Config.SecondaryColor
    WelcomeCard.BorderSizePixel = 0
    WelcomeCard.Position = UDim2.new(0.5, -200, 0.5, -100)
    WelcomeCard.Size = UDim2.new(0, 400, 0, 200)
    WelcomeCard.ZIndex = 10000
    WelcomeCard.Parent = ScreenGui
    
    local WelcomeCorner = Instance.new("UICorner")
    WelcomeCorner.CornerRadius = UDim.new(0, 12)
    WelcomeCorner.Name = GenerateRandomString(12)
    WelcomeCorner.Parent = WelcomeCard
    
    CreateFrameShadow(WelcomeCard, Color3.fromRGB(0, 0, 0), 10)
    
    -- Terminal-style header
    local WelcomeHeader = Instance.new("Frame")
    WelcomeHeader.Name = GenerateRandomString(12)
    WelcomeHeader.BackgroundColor3 = Config.TertiaryColor
    WelcomeHeader.BorderSizePixel = 0
    WelcomeHeader.Position = UDim2.new(0, 0, 0, 0)
    WelcomeHeader.Size = UDim2.new(1, 0, 0, 30)
    WelcomeHeader.ZIndex = 10001
    WelcomeHeader.Parent = WelcomeCard
    
    local WelcomeHeaderCorner = Instance.new("UICorner")
    WelcomeHeaderCorner.CornerRadius = UDim.new(0, 12)
    WelcomeHeaderCorner.Name = GenerateRandomString(12)
    WelcomeHeaderCorner.Parent = WelcomeHeader
    
    local WelcomeHeaderCover = Instance.new("Frame")
    WelcomeHeaderCover.Name = GenerateRandomString(12)
    WelcomeHeaderCover.BackgroundColor3 = Config.TertiaryColor
    WelcomeHeaderCover.BorderSizePixel = 0
    WelcomeHeaderCover.Position = UDim2.new(0, 0, 1, -12)
    WelcomeHeaderCover.Size = UDim2.new(1, 0, 0, 12)
    WelcomeHeaderCover.ZIndex = 10001
    WelcomeHeaderCover.Parent = WelcomeHeader
    
    local WelcomeHeaderText = Instance.new("TextLabel")
    WelcomeHeaderText.Name = GenerateRandomString(12)
    WelcomeHeaderText.BackgroundTransparency = 1
    WelcomeHeaderText.Position = UDim2.new(0, 15, 0, 0)
    WelcomeHeaderText.Size = UDim2.new(1, -30, 1, 0)
    WelcomeHeaderText.Font = Enum.Font.Code
    WelcomeHeaderText.Text = "SYSTEM_INIT.exe"
    WelcomeHeaderText.TextColor3 = Config.TextColor
    WelcomeHeaderText.TextSize = 12
    WelcomeHeaderText.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeHeaderText.ZIndex = 10002
    WelcomeHeaderText.Parent = WelcomeHeader
    
    -- Content area
    local WelcomeContent = Instance.new("Frame")
    WelcomeContent.Name = GenerateRandomString(12)
    WelcomeContent.BackgroundTransparency = 1
    WelcomeContent.Position = UDim2.new(0, 20, 0, 45)
    WelcomeContent.Size = UDim2.new(1, -40, 1, -60)
    WelcomeContent.ZIndex = 10001
    WelcomeContent.Parent = WelcomeCard
    
    local WelcomeText = Instance.new("TextLabel")
    WelcomeText.Name = GenerateRandomString(12)
    WelcomeText.BackgroundTransparency = 1
    WelcomeText.Position = UDim2.new(0, 0, 0, 0)
    WelcomeText.Size = UDim2.new(1, 0, 0, 25)
    WelcomeText.Font = Enum.Font.Code
    WelcomeText.Text = "> Initializing LURKOUT..."
    WelcomeText.TextColor3 = Config.NavbarHC2
    WelcomeText.TextSize = 14
    WelcomeText.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeText.TextTransparency = 0
    WelcomeText.ZIndex = 10002
    WelcomeText.Parent = WelcomeContent
    
    local LoadingText = Instance.new("TextLabel")
    LoadingText.Name = GenerateRandomString(12)
    LoadingText.BackgroundTransparency = 1
    LoadingText.Position = UDim2.new(0, 0, 0, 35)
    LoadingText.Size = UDim2.new(1, 0, 0, 20)
    LoadingText.Font = Enum.Font.Code
    LoadingText.Text = "> Loading UI Components..."
    LoadingText.TextColor3 = Config.TextColor
    LoadingText.TextSize = 12
    LoadingText.TextXAlignment = Enum.TextXAlignment.Left
    LoadingText.TextTransparency = 0
    LoadingText.ZIndex = 10002
    LoadingText.Parent = WelcomeContent
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Name = GenerateRandomString(12)
    StatusText.BackgroundTransparency = 1
    StatusText.Position = UDim2.new(0, 0, 0, 65)
    StatusText.Size = UDim2.new(1, 0, 0, 20)
    StatusText.Font = Enum.Font.Code
    StatusText.Text = "> Status: Preparing..."
    StatusText.TextColor3 = Config.TextColor
    StatusText.TextSize = 12
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.TextTransparency = 0
    StatusText.ZIndex = 10002
    StatusText.Parent = WelcomeContent
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Name = GenerateRandomString(12)
    ProgressBar.BackgroundColor3 = Config.AccentColor
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Position = UDim2.new(0, 0, 1, -8)
    ProgressBar.Size = UDim2.new(0, 0, 0, 3)
    ProgressBar.ZIndex = 10002
    ProgressBar.Parent = WelcomeContent
    
    -- Boot sequence with typing effect
    task.spawn(function()
        task.wait(0.3)
        
        -- Progress bar animation
        Tween(ProgressBar, {Size = UDim2.new(0.3, 0, 0, 3)}, 0.5)
        task.wait(0.5)
        
        LoadingText.Text = "> Checking system requirements..."
        StatusText.Text = "> Status: OK"
        StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
        Tween(ProgressBar, {Size = UDim2.new(0.6, 0, 0, 3)}, 0.5)
        task.wait(0.5)
        
        LoadingText.Text = "> Building interface..."
        StatusText.Text = "> Status: Ready"
        Tween(ProgressBar, {Size = UDim2.new(1, 0, 0, 3)}, 0.5)
        task.wait(0.5)
        
        WelcomeText.Text = "> LURKOUT UI Loaded Successfully!"
        WelcomeText.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(0.3)
        
        -- Fade out
        Tween(WelcomeCard, {BackgroundTransparency = 1}, 0.5)
        Tween(WelcomeHeader, {BackgroundTransparency = 1}, 0.5)
        Tween(WelcomeHeaderCover, {BackgroundTransparency = 1}, 0.5)
        Tween(WelcomeHeaderText, {TextTransparency = 1}, 0.5)
        Tween(WelcomeText, {TextTransparency = 1}, 0.5)
        Tween(LoadingText, {TextTransparency = 1}, 0.5)
        Tween(StatusText, {TextTransparency = 1}, 0.5)
        Tween(ProgressBar, {BackgroundTransparency = 1}, 0.5)
        
        task.wait(0.5)
        WelcomeCard:Destroy()
    end)
    
    local Container = Instance.new("Frame")
    Container.Name = GenerateRandomString(16)
    Container.BackgroundTransparency = 1
    Container.Position = UDim2.new(0.5, -300, 0.5, -200)
    Container.Size = UDim2.new(0, 600, 0, 400)
    Container.ZIndex = 1
    Container.BackgroundTransparency = 1
    Container.Parent = ScreenGui
    
    -- Fade in animation
    task.spawn(function()
        task.wait(2)
        Container.BackgroundTransparency = 1
        Tween(Container, {BackgroundTransparency = 1}, 0.5)
    end)
    
    local Main = Instance.new("Frame")
    Main.Name = GenerateRandomString(16)
    Main.BackgroundColor3 = Config.MainColor
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0, 0, 0, 0)
    Main.Size = UDim2.new(1, 0, 1, 0)
    Main.ClipsDescendants = false
    Main.ZIndex = 5
    Main.BackgroundTransparency = 1
    Main.Parent = Container
    
    -- Fade in main frame
    task.spawn(function()
        task.wait(2)
        Tween(Main, {BackgroundTransparency = 0}, 0.5)
    end)
    
    Library.Main = Main
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Name = GenerateRandomString(12)
    MainCorner.Parent = Main
    
    CreateFrameShadow(Main, Config.GlowColor, 8)
    
    local Navbar = Instance.new("Frame")
    Navbar.Name = GenerateRandomString(16)
    Navbar.BackgroundColor3 = Config.SecondaryColor
    Navbar.BorderSizePixel = 0
    Navbar.Position = UDim2.new(0, 10, 0, 10)
    Navbar.Size = UDim2.new(1, -20, 0, 50)
    Navbar.ZIndex = 15
    Navbar.Parent = Main
    
    local NavbarCorner = Instance.new("UICorner")
    NavbarCorner.CornerRadius = UDim.new(0, 8)
    NavbarCorner.Name = GenerateRandomString(12)
    NavbarCorner.Parent = Navbar
    
    CreateFrameShadow(Navbar, Config.AccentColor, 5)
    
    local Title = Instance.new("TextLabel")
    Title.Name = GenerateRandomString(12)
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.Size = UDim2.new(0, 120, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "LURKOUT"
    Title.TextColor3 = Config.TextColor
    Title.TextSize = 20
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 16
    Title.Parent = Navbar
    
    -- Only flash on hover
    local titleHovering = false
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            titleHovering = true
        end
    end)
    
    Title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            titleHovering = false
        end
    end)
    
    task.spawn(function()
        while Title.Parent do
            if titleHovering then
                Tween(Title, {TextColor3 = Config.NavbarHC2}, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.5)
                Tween(Title, {TextColor3 = Config.TextColor}, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.5)
            else
                task.wait(0.1)
            end
        end
    end)
    
    local VersionFrame = Instance.new("Frame")
    VersionFrame.Name = GenerateRandomString(12)
    VersionFrame.BackgroundColor3 = Config.TertiaryColor
    VersionFrame.BorderSizePixel = 0
    VersionFrame.Position = UDim2.new(0, 150, 0, 12)
    VersionFrame.Size = UDim2.new(0, 65, 0, 26)
    VersionFrame.ZIndex = 16
    VersionFrame.Parent = Navbar
    
    local VersionCorner = Instance.new("UICorner")
    VersionCorner.CornerRadius = UDim.new(0, 6)
    VersionCorner.Name = GenerateRandomString(12)
    VersionCorner.Parent = VersionFrame
    
    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Name = GenerateRandomString(12)
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Size = UDim2.new(1, 0, 1, 0)
    VersionLabel.Font = Enum.Font.GothamBold
    VersionLabel.Text = "V3.5"
    VersionLabel.TextColor3 = Config.NavbarHC2
    VersionLabel.TextSize = 12
    VersionLabel.ZIndex = 17
    VersionLabel.Parent = VersionFrame
    
    MakeDraggable(Container, Navbar)
    
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Name = GenerateRandomString(12)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Position = UDim2.new(1, -95, 0, 10)
    ButtonContainer.Size = UDim2.new(0, 85, 0, 30)
    ButtonContainer.ZIndex = 16
    ButtonContainer.Parent = Navbar
    
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = GenerateRandomString(12)
    MinimizeButton.BackgroundColor3 = Config.TertiaryColor
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Position = UDim2.new(0, 0, 0, 0)
    MinimizeButton.Size = UDim2.new(0, 35, 0, 30)
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Text = "_"
    MinimizeButton.TextColor3 = Config.TextColor
    MinimizeButton.TextSize = 18
    MinimizeButton.ZIndex = 17
    MinimizeButton.AutoButtonColor = false
    MinimizeButton.Parent = ButtonContainer
    
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 6)
    MinimizeCorner.Name = GenerateRandomString(12)
    MinimizeCorner.Parent = MinimizeButton
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = GenerateRandomString(12)
    CloseButton.BackgroundColor3 = Config.TertiaryColor
    CloseButton.BorderSizePixel = 0
    CloseButton.Position = UDim2.new(0, 45, 0, 0)
    CloseButton.Size = UDim2.new(0, 35, 0, 30)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Config.TextColor
    CloseButton.TextSize = 16
    CloseButton.ZIndex = 17
    CloseButton.AutoButtonColor = false
    CloseButton.Parent = ButtonContainer
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Name = GenerateRandomString(12)
    CloseCorner.Parent = CloseButton
    
    MinimizeButton.MouseEnter:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = Config.ButtonHover}, 0.2)
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = Config.TertiaryColor}, 0.2)
    end)
    
    MinimizeButton.MouseButton1Click:Connect(function()
        Library.Minimized = not Library.Minimized
        MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        if Library.Minimized then
            Tween(Main, {Size = UDim2.new(0, 600, 0, 70)}, 0.3)
        else
            Tween(Main, {Size = UDim2.new(0, 600, 0, 400)}, 0.3)
        end
        
        task.wait(0.1)
        MinimizeButton.TextColor3 = Config.TextColor
    end)
    
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}, 0.2)
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Config.TertiaryColor}, 0.2)
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        Tween(Main, {BackgroundTransparency = 1}, 0.3)
        Tween(Navbar, {BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    local TabBar = Instance.new("Frame")
    TabBar.Name = GenerateRandomString(16)
    TabBar.BackgroundColor3 = Config.SecondaryColor
    TabBar.BorderSizePixel = 0
    TabBar.Position = UDim2.new(0, 10, 0, 70)
    TabBar.Size = UDim2.new(0, 120, 1, -80)
    TabBar.ZIndex = 10
    TabBar.Parent = Main
    
    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, 8)
    TabBarCorner.Name = GenerateRandomString(12)
    TabBarCorner.Parent = TabBar
    
    CreateFrameShadow(TabBar, Config.AccentColor, 3)
    
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = GenerateRandomString(12)
    TabList.BackgroundTransparency = 1
    TabList.Position = UDim2.new(0, 5, 0, 5)
    TabList.Size = UDim2.new(1, -10, 1, -10)
    TabList.ScrollBarThickness = 4
    TabList.ScrollBarImageColor3 = Config.BorderColor
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.ZIndex = 11
    TabList.BorderSizePixel = 0
    TabList.Parent = TabBar
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Name = GenerateRandomString(12)
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Parent = TabList
    
    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = GenerateRandomString(16)
    ContentFrame.BackgroundColor3 = Config.SecondaryColor
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Position = UDim2.new(0, 140, 0, 70)
    ContentFrame.Size = UDim2.new(1, -150, 1, -80)
    ContentFrame.ZIndex = 10
    ContentFrame.Parent = Main
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 8)
    ContentCorner.Name = GenerateRandomString(12)
    ContentCorner.Parent = ContentFrame
    
    CreateFrameShadow(ContentFrame, Config.AccentColor, 3)
    
    function Library:CreateTab(name)
        local Tab = {}
        Tab.Name = name
        Tab.Active = false
        
        local TabButton = Instance.new("TextButton")
        TabButton.Name = GenerateRandomString(12)
        TabButton.BackgroundColor3 = Config.TertiaryColor
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 0, 35)
        TabButton.Font = Enum.Font.GothamBold
        TabButton.Text = name
        TabButton.TextColor3 = Config.TextColor
        TabButton.TextSize = 13
        TabButton.ZIndex = 12
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabList
        
        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 6)
        TabButtonCorner.Name = GenerateRandomString(12)
        TabButtonCorner.Parent = TabButton
        
        -- STATIC FRAME (No ScrollingFrame for Home and Settings)
        local TabContent
        if name == "Home" or name == "Settings" then
            TabContent = Instance.new("Frame")
            TabContent.Name = GenerateRandomString(12)
            TabContent.BackgroundTransparency = 1
            TabContent.Position = UDim2.new(0, 10, 0, 10)
            TabContent.Size = UDim2.new(1, -20, 1, -20)
            TabContent.Visible = false
            TabContent.ZIndex = 11
            TabContent.Parent = ContentFrame
        else
            TabContent = Instance.new("ScrollingFrame")
            TabContent.Name = GenerateRandomString(12)
            TabContent.BackgroundTransparency = 1
            TabContent.Position = UDim2.new(0, 10, 0, 10)
            TabContent.Size = UDim2.new(1, -20, 1, -20)
            TabContent.ScrollBarThickness = 6
            TabContent.ScrollBarImageColor3 = Config.BorderColor
            TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
            TabContent.Visible = false
            TabContent.ZIndex = 11
            TabContent.BorderSizePixel = 0
            TabContent.Parent = ContentFrame
            
            local TabContentLayout = Instance.new("UIListLayout")
            TabContentLayout.Name = GenerateRandomString(12)
            TabContentLayout.Padding = UDim.new(0, 8)
            TabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            TabContentLayout.Parent = TabContent
            
            TabContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabContent.CanvasSize = UDim2.new(0, 0, 0, TabContentLayout.AbsoluteContentSize.Y + 20)
            end)
        end
        
        Tab.Content = TabContent
        Tab.Button = TabButton
        
        TabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                Tween(TabButton, {BackgroundColor3 = Config.ButtonHover, TextColor3 = Config.HoverTextColor}, 0.2)
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if not Tab.Active then
                Tween(TabButton, {BackgroundColor3 = Config.TertiaryColor, TextColor3 = Config.TextColor}, 0.2)
            end
        end)
        
        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(Library.Tabs) do
                tab.Active = false
                tab.Content.Visible = false
                Tween(tab.Button, {BackgroundColor3 = Config.TertiaryColor, TextColor3 = Config.TextColor}, 0.2)
            end
            
            Tab.Active = true
            TabContent.Visible = true
            Tween(TabButton, {BackgroundColor3 = Config.BorderColor, TextColor3 = Config.HoverTextColor}, 0.2)
        end)
        
        function Tab:AddButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Name = GenerateRandomString(12)
            Button.BackgroundColor3 = Config.TertiaryColor
            Button.BorderSizePixel = 0
            Button.Size = UDim2.new(1, 0, 0, 35)
            Button.Font = Enum.Font.GothamBold
            Button.Text = text
            Button.TextColor3 = Config.TextColor
            Button.TextSize = 13
            Button.ZIndex = 12
            Button.AutoButtonColor = false
            Button.Parent = TabContent
            
            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 6)
            ButtonCorner.Name = GenerateRandomString(12)
            ButtonCorner.Parent = Button
            
            CreateFrameShadow(Button, Config.AccentColor, 2)
            
            Button.MouseEnter:Connect(function()
                Tween(Button, {BackgroundColor3 = Config.ButtonHover, TextColor3 = Config.HoverTextColor}, 0.2)
            end)
            
            Button.MouseLeave:Connect(function()
                Tween(Button, {BackgroundColor3 = Config.TertiaryColor, TextColor3 = Config.TextColor}, 0.2)
            end)
            
            Button.MouseButton1Click:Connect(function()
                Tween(Button, {BackgroundColor3 = Config.AccentColor}, 0.1)
                task.wait(0.1)
                Tween(Button, {BackgroundColor3 = Config.ButtonHover}, 0.1)
                pcall(callback)
            end)
            
            return Button
        end
        
        function Tab:AddToggle(text, default, callback)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = GenerateRandomString(12)
            ToggleFrame.BackgroundColor3 = Config.TertiaryColor
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            ToggleFrame.ZIndex = 12
            ToggleFrame.Parent = TabContent
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 6)
            ToggleCorner.Name = GenerateRandomString(12)
            ToggleCorner.Parent = ToggleFrame
            
            CreateFrameShadow(ToggleFrame, Config.AccentColor, 2)
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Name = GenerateRandomString(12)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Position = UDim2.new(0, 15, 0, 0)
            ToggleLabel.Size = UDim2.new(1, -70, 1, 0)
            ToggleLabel.Font = Enum.Font.GothamBold
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = Config.TextColor
            ToggleLabel.TextSize = 13
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.ZIndex = 13
            ToggleLabel.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Name = GenerateRandomString(12)
            ToggleButton.BackgroundColor3 = default and Config.BorderColor or Config.AccentColor
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Position = UDim2.new(1, -50, 0.5, -12)
            ToggleButton.Size = UDim2.new(0, 40, 0, 24)
            ToggleButton.Text = ""
            ToggleButton.ZIndex = 13
            ToggleButton.AutoButtonColor = false
            ToggleButton.Parent = ToggleFrame
            
            local ToggleButtonCorner = Instance.new("UICorner")
            ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
            ToggleButtonCorner.Name = GenerateRandomString(12)
            ToggleButtonCorner.Parent = ToggleButton
            
            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Name = GenerateRandomString(12)
            ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleCircle.BorderSizePixel = 0
            ToggleCircle.Position = default and UDim2.new(1, -20, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            ToggleCircle.Size = UDim2.new(0, 20, 0, 20)
            ToggleCircle.ZIndex = 14
            ToggleCircle.Parent = ToggleButton
            
            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Name = GenerateRandomString(12)
            CircleCorner.Parent = ToggleCircle
            
            local toggled = default
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                
                if toggled then
                    Tween(ToggleButton, {BackgroundColor3 = Config.BorderColor}, 0.2)
                    Tween(ToggleCircle, {Position = UDim2.new(1, -20, 0.5, -10)}, 0.2)
                else
                    Tween(ToggleButton, {BackgroundColor3 = Config.AccentColor}, 0.2)
                    Tween(ToggleCircle, {Position = UDim2.new(0, 2, 0.5, -10)}, 0.2)
                end
                
                pcall(callback, toggled)
            end)
            
            ToggleFrame.MouseEnter:Connect(function()
                Tween(ToggleLabel, {TextColor3 = Config.HoverTextColor}, 0.2)
            end)
            
            ToggleFrame.MouseLeave:Connect(function()
                Tween(ToggleLabel, {TextColor3 = Config.TextColor}, 0.2)
            end)
            
            return ToggleFrame
        end
        
        function Tab:AddSlider(text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = GenerateRandomString(12)
            SliderFrame.BackgroundColor3 = Config.TertiaryColor
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.ZIndex = 12
            SliderFrame.Parent = TabContent
            
            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 6)
            SliderCorner.Name = GenerateRandomString(12)
            SliderCorner.Parent = SliderFrame
            
            CreateFrameShadow(SliderFrame, Config.AccentColor, 2)
            
            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Name = GenerateRandomString(12)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Position = UDim2.new(0, 15, 0, 5)
            SliderLabel.Size = UDim2.new(1, -30, 0, 15)
            SliderLabel.Font = Enum.Font.GothamBold
            SliderLabel.Text = text .. ": " .. tostring(default)
            SliderLabel.TextColor3 = Config.TextColor
            SliderLabel.TextSize = 13
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.ZIndex = 13
            SliderLabel.Parent = SliderFrame
            
            local SliderBar = Instance.new("Frame")
            SliderBar.Name = GenerateRandomString(12)
            SliderBar.BackgroundColor3 = Config.AccentColor
            SliderBar.BorderSizePixel = 0
            SliderBar.Position = UDim2.new(0, 15, 0, 30)
            SliderBar.Size = UDim2.new(1, -30, 0, 8)
            SliderBar.ZIndex = 13
            SliderBar.Parent = SliderFrame
            
            local SliderBarCorner = Instance.new("UICorner")
            SliderBarCorner.CornerRadius = UDim.new(1, 0)
            SliderBarCorner.Name = GenerateRandomString(12)
            SliderBarCorner.Parent = SliderBar
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Name = GenerateRandomString(12)
            SliderFill.BackgroundColor3 = Config.BorderColor
            SliderFill.BorderSizePixel = 0
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            SliderFill.ZIndex = 14
            SliderFill.Parent = SliderBar
            
            local SliderFillCorner = Instance.new("UICorner")
            SliderFillCorner.CornerRadius = UDim.new(1, 0)
            SliderFillCorner.Name = GenerateRandomString(12)
            SliderFillCorner.Parent = SliderFill
            
            local SliderButton = Instance.new("TextButton")
            SliderButton.Name = GenerateRandomString(12)
            SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderButton.BorderSizePixel = 0
            SliderButton.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
            SliderButton.Size = UDim2.new(0, 16, 0, 16)
            SliderButton.Text = ""
            SliderButton.ZIndex = 15
            SliderButton.AutoButtonColor = false
            SliderButton.Parent = SliderBar
            
            local SliderButtonCorner = Instance.new("UICorner")
            SliderButtonCorner.CornerRadius = UDim.new(1, 0)
            SliderButtonCorner.Name = GenerateRandomString(12)
            SliderButtonCorner.Parent = SliderButton
            
            local dragging = false
            
            SliderButton.MouseButton1Down:Connect(function()
                dragging = true
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mousePos = UserInputService:GetMouseLocation()
                    local relativePos = mousePos.X - SliderBar.AbsolutePosition.X
                    local percentage = math.clamp(relativePos / SliderBar.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + (max - min) * percentage)
                    
                    SliderLabel.Text = text .. ": " .. tostring(value)
                    Tween(SliderFill, {Size = UDim2.new(percentage, 0, 1, 0)}, 0.1)
                    Tween(SliderButton, {Position = UDim2.new(percentage, -8, 0.5, -8)}, 0.1)
                    
                    pcall(callback, value)
                end
            end)
            
            SliderFrame.MouseEnter:Connect(function()
                Tween(SliderLabel, {TextColor3 = Config.HoverTextColor}, 0.2)
            end)
            
            SliderFrame.MouseLeave:Connect(function()
                Tween(SliderLabel, {TextColor3 = Config.TextColor}, 0.2)
            end)
            
            return SliderFrame
        end
        
        function Tab:AddInput(text, placeholder, callback)
            local InputFrame = Instance.new("Frame")
            InputFrame.Name = GenerateRandomString(12)
            InputFrame.BackgroundColor3 = Config.TertiaryColor
            InputFrame.BorderSizePixel = 0
            InputFrame.Size = UDim2.new(1, 0, 0, 50)
            InputFrame.ZIndex = 12
            InputFrame.Parent = TabContent
            
            local InputCorner = Instance.new("UICorner")
            InputCorner.CornerRadius = UDim.new(0, 6)
            InputCorner.Name = GenerateRandomString(12)
            InputCorner.Parent = InputFrame
            
            CreateFrameShadow(InputFrame, Config.AccentColor, 2)
            
            local InputLabel = Instance.new("TextLabel")
            InputLabel.Name = GenerateRandomString(12)
            InputLabel.BackgroundTransparency = 1
            InputLabel.Position = UDim2.new(0, 15, 0, 5)
            InputLabel.Size = UDim2.new(1, -30, 0, 15)
            InputLabel.Font = Enum.Font.GothamBold
            InputLabel.Text = text
            InputLabel.TextColor3 = Config.TextColor
            InputLabel.TextSize = 13
            InputLabel.TextXAlignment = Enum.TextXAlignment.Left
            InputLabel.ZIndex = 13
            InputLabel.Parent = InputFrame
            
            local TextBox = Instance.new("TextBox")
            TextBox.Name = GenerateRandomString(12)
            TextBox.BackgroundColor3 = Config.AccentColor
            TextBox.BorderSizePixel = 0
            TextBox.Position = UDim2.new(0, 15, 0, 25)
            TextBox.Size = UDim2.new(1, -30, 0, 20)
            TextBox.Font = Enum.Font.Gotham
            TextBox.PlaceholderText = placeholder
            TextBox.PlaceholderColor3 = Config.TextColor
            TextBox.Text = ""
            TextBox.TextColor3 = Config.NavbarHC
            TextBox.TextSize = 12
            TextBox.ZIndex = 13
            TextBox.Parent = InputFrame
            
            local TextBoxCorner = Instance.new("UICorner")
            TextBoxCorner.CornerRadius = UDim.new(0, 4)
            TextBoxCorner.Name = GenerateRandomString(12)
            TextBoxCorner.Parent = TextBox
            
            TextBox.FocusLost:Connect(function(enterPressed)
                if enterPressed and TextBox.Text ~= "" then
                    pcall(callback, TextBox.Text)
                end
            end)
            
            InputFrame.MouseEnter:Connect(function()
                Tween(InputLabel, {TextColor3 = Config.HoverTextColor}, 0.2)
            end)
            
            InputFrame.MouseLeave:Connect(function()
                Tween(InputLabel, {TextColor3 = Config.TextColor}, 0.2)
            end)
            
            return InputFrame
        end
        
        function Tab:AddDropdown(text, options, callback)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = GenerateRandomString(12)
            DropdownFrame.BackgroundColor3 = Config.TertiaryColor
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.ZIndex = 999999
            DropdownFrame.Parent = TabContent
            
            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UDim.new(0, 6)
            DropdownCorner.Name = GenerateRandomString(12)
            DropdownCorner.Parent = DropdownFrame
            
            CreateFrameShadow(DropdownFrame, Config.AccentColor, 2)
            
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Name = GenerateRandomString(12)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Size = UDim2.new(1, 0, 0, 40)
            DropdownButton.Font = Enum.Font.GothamBold
            DropdownButton.Text = text .. ": " .. (options[1] or "None")
            DropdownButton.TextColor3 = Config.TextColor
            DropdownButton.TextSize = 13
            DropdownButton.ZIndex = 13
            DropdownButton.AutoButtonColor = false
            DropdownButton.Parent = DropdownFrame
            
            local DropdownArrow = Instance.new("TextLabel")
            DropdownArrow.Name = GenerateRandomString(12)
            DropdownArrow.BackgroundTransparency = 1
            DropdownArrow.Position = UDim2.new(1, -30, 0, 0)
            DropdownArrow.Size = UDim2.new(0, 20, 1, 0)
            DropdownArrow.Font = Enum.Font.GothamBold
            DropdownArrow.Text = "▼"
            DropdownArrow.TextColor3 = Config.TextColor
            DropdownArrow.TextSize = 12
            DropdownArrow.ZIndex = 14
            DropdownArrow.Parent = DropdownButton
            
            local DropdownList = Instance.new("ScrollingFrame")
            DropdownList.Name = GenerateRandomString(12)
            DropdownList.BackgroundColor3 = Config.DropdownBG
            DropdownList.BorderSizePixel = 0
            DropdownList.Position = UDim2.new(0, 0, 1, 5)
            DropdownList.Size = UDim2.new(1, 0, 0, 0)
            DropdownList.Visible = false
            DropdownList.ZIndex = 999999999999999
            DropdownList.ScrollBarThickness = 4
            DropdownList.ScrollBarImageColor3 = Config.BorderColor
            DropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
            DropdownList.ClipsDescendants = true
            DropdownList.Parent = DropdownFrame
            
            local DropdownListCorner = Instance.new("UICorner")
            DropdownListCorner.CornerRadius = UDim.new(0, 6)
            DropdownListCorner.Name = GenerateRandomString(12)
            DropdownListCorner.Parent = DropdownList
            
            local DropdownLayout = Instance.new("UIListLayout")
            DropdownLayout.Name = GenerateRandomString(12)
            DropdownLayout.Padding = UDim.new(0, 2)
            DropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DropdownLayout.Parent = DropdownList

            DropdownLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                DropdownList.CanvasSize = UDim2.new(0, 0, 0, DropdownLayout.AbsoluteContentSize.Y)
            end)
            
            local expanded = false
            local maxVisibleOptions = 5
            
            DropdownButton.MouseButton1Click:Connect(function()
                expanded = not expanded
                
                if expanded then
                    local listHeight = math.min(#options * 35, maxVisibleOptions * 35)
                    Tween(DropdownList, {Size = UDim2.new(1, 0, 0, listHeight)}, 0.3)
                    Tween(DropdownArrow, {Rotation = 180}, 0.3)
                    DropdownList.Visible = true
                    DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
                else
                    Tween(DropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
                    Tween(DropdownArrow, {Rotation = 0}, 0.3)
                    task.wait(0.3)
                    DropdownList.Visible = false
                end
            end)
            
            for _, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Name = GenerateRandomString(12)
                OptionButton.BackgroundColor3 = Config.DropdownOptionBG
                OptionButton.BorderSizePixel = 0
                OptionButton.Size = UDim2.new(1, 0, 0, 33)
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.Text = option
                OptionButton.TextColor3 = Config.DropdownTextColor
                OptionButton.TextSize = 12
                OptionButton.ZIndex = 101
                OptionButton.AutoButtonColor = false
                OptionButton.Parent = DropdownList
                
                local OptionCorner = Instance.new("UICorner")
                OptionCorner.CornerRadius = UDim.new(0, 4)
                OptionCorner.Name = GenerateRandomString(12)
                OptionCorner.Parent = OptionButton
                
                OptionButton.MouseEnter:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Config.ButtonHover, TextColor3 = Config.NavbarHC}, 0.2)
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Config.DropdownOptionBG, TextColor3 = Config.DropdownTextColor}, 0.2)
                end)
                
                OptionButton.MouseButton1Click:Connect(function()
                    DropdownButton.Text = text .. ": " .. option
                    expanded = false
                    Tween(DropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
                    Tween(DropdownArrow, {Rotation = 0}, 0.3)
                    task.wait(0.3)
                    DropdownList.Visible = false
                    pcall(callback, option)
                end)
            end
            
            DropdownFrame.MouseEnter:Connect(function()
                Tween(DropdownButton, {TextColor3 = Config.HoverTextColor}, 0.2)
                Tween(DropdownArrow, {TextColor3 = Config.HoverTextColor}, 0.2)
            end)
            
            DropdownFrame.MouseLeave:Connect(function()
                Tween(DropdownButton, {TextColor3 = Config.TextColor}, 0.2)
                Tween(DropdownArrow, {TextColor3 = Config.TextColor}, 0.2)
            end)
            
            return DropdownFrame
        end
        
        function Tab:AddLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Name = GenerateRandomString(12)
            Label.BackgroundColor3 = Config.TertiaryColor
            Label.BorderSizePixel = 0
            Label.Size = UDim2.new(1, 0, 0, 30)
            Label.Font = Enum.Font.GothamBold
            Label.Text = text
            Label.TextColor3 = Config.TextColor
            Label.TextSize = 13
            Label.ZIndex = 12
            Label.Parent = TabContent
            
            local LabelCorner = Instance.new("UICorner")
            LabelCorner.CornerRadius = UDim.new(0, 6)
            LabelCorner.Name = GenerateRandomString(12)
            LabelCorner.Parent = Label
            
            CreateFrameShadow(Label, Config.AccentColor, 2)
            
            return Label
        end
        
        table.insert(Library.Tabs, Tab)
        
        if #Library.Tabs == 1 then
            Tab.Active = true
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Config.BorderColor
            TabButton.TextColor3 = Config.NavbarHC
        end
        
        return Tab
    end
    
    function Library:Notify(title, message, duration)
        duration = duration or 3
        
        local NotifContainer = Instance.new("Frame")
        NotifContainer.Name = GenerateRandomString(16)
        NotifContainer.BackgroundColor3 = Config.SecondaryColor
        NotifContainer.BorderSizePixel = 0
        NotifContainer.Position = UDim2.new(1, -320, 0, 20 + (#Library.ActiveNotifications * 95))
        NotifContainer.Size = UDim2.new(0, 300, 0, 85)
        NotifContainer.ZIndex = 1000
        NotifContainer.Parent = ScreenGui
        
        table.insert(Library.ActiveNotifications, NotifContainer)
        
        local NotifCorner = Instance.new("UICorner")
        NotifCorner.CornerRadius = UDim.new(0, 8)
        NotifCorner.Name = GenerateRandomString(12)
        NotifCorner.Parent = NotifContainer
        
        CreateFrameShadow(NotifContainer, Color3.fromRGB(0, 0, 0), 6)
        
        local NotifTitle = Instance.new("TextLabel")
        NotifTitle.Name = GenerateRandomString(12)
        NotifTitle.BackgroundTransparency = 1
        NotifTitle.Position = UDim2.new(0, 15, 0, 10)
        NotifTitle.Size = UDim2.new(1, -30, 0, 20)
        NotifTitle.Font = Enum.Font.GothamBold
        NotifTitle.Text = title
        NotifTitle.TextColor3 = Config.NavbarHC
        NotifTitle.TextSize = 14
        NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
        NotifTitle.ZIndex = 1001
        NotifTitle.Parent = NotifContainer
        
        local NotifMessage = Instance.new("TextLabel")
        NotifMessage.Name = GenerateRandomString(12)
        NotifMessage.BackgroundTransparency = 1
        NotifMessage.Position = UDim2.new(0, 15, 0, 32)
        NotifMessage.Size = UDim2.new(1, -30, 0, 38)
        NotifMessage.Font = Enum.Font.Gotham
        NotifMessage.Text = message
        NotifMessage.TextColor3 = Config.TextColor
        NotifMessage.TextSize = 12
        NotifMessage.TextXAlignment = Enum.TextXAlignment.Left
        NotifMessage.TextYAlignment = Enum.TextYAlignment.Top
        NotifMessage.TextWrapped = true
        NotifMessage.ZIndex = 1001
        NotifMessage.Parent = NotifContainer
        
        local TimeIndicator = Instance.new("Frame")
        TimeIndicator.Name = GenerateRandomString(12)
        TimeIndicator.BackgroundColor3 = Config.BorderColor
        TimeIndicator.BorderSizePixel = 0
        TimeIndicator.Position = UDim2.new(0, 0, 1, -3)
        TimeIndicator.Size = UDim2.new(1, 0, 0, 3)
        TimeIndicator.ZIndex = 1002
        TimeIndicator.Parent = NotifContainer
        
        Tween(TimeIndicator, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)
        
        task.spawn(function()
            task.wait(duration)
            Tween(NotifContainer, {Position = UDim2.new(1, 20, 0, NotifContainer.Position.Y.Offset)}, 0.3)
            task.wait(0.3)
            
            for i, notif in ipairs(Library.ActiveNotifications) do
                if notif == NotifContainer then
                    table.remove(Library.ActiveNotifications, i)
                    break
                end
            end
            
            NotifContainer:Destroy()
            
            for i, notif in ipairs(Library.ActiveNotifications) do
                Tween(notif, {Position = UDim2.new(1, -320, 0, 20 + ((i - 1) * 95))}, 0.3)
            end
        end)
    end
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Config.ToggleKey then
            Main.Visible = not Main.Visible
        end
    end)
    
    -- ==========================================
    -- IMPROVED HOME TAB - STATIC, COMPACT LAYOUT
    -- ==========================================
    local HomeTab = Library:CreateTab("Home")
    
    -- Header Frame with Welcome Text & Circular Headshot
    local HeaderFrame = Instance.new("Frame")
    HeaderFrame.Name = GenerateRandomString(12)
    HeaderFrame.BackgroundTransparency = 1
    HeaderFrame.Position = UDim2.new(0, 15, 0, 10)
    HeaderFrame.Size = UDim2.new(1, -30, 0, 50)
    HeaderFrame.ZIndex = 12
    HeaderFrame.Parent = HomeTab.Content
    
    -- Welcome Text (Left Side)
    local WelcomeLabel = Instance.new("TextLabel")
    WelcomeLabel.Name = GenerateRandomString(12)
    WelcomeLabel.BackgroundTransparency = 1
    WelcomeLabel.Position = UDim2.new(0, 5, 0, 5)
    WelcomeLabel.Size = UDim2.new(1, -70, 0, 20)
    WelcomeLabel.Font = Enum.Font.Code
    WelcomeLabel.Text = "> Welcome, " .. LocalPlayer.Name
    WelcomeLabel.TextColor3 = Config.NavbarHC2
    WelcomeLabel.TextSize = 15
    WelcomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeLabel.ZIndex = 12
    WelcomeLabel.Parent = HeaderFrame
    
    local SubtitleLabel = Instance.new("TextLabel")
    SubtitleLabel.Name = GenerateRandomString(12)
    SubtitleLabel.BackgroundTransparency = 1
    SubtitleLabel.Position = UDim2.new(0, 5, 0, 27)
    SubtitleLabel.Size = UDim2.new(1, -70, 0, 18)
    SubtitleLabel.Font = Enum.Font.Code
    SubtitleLabel.Text = "> LURKOUT UI v3.5 | Ready"
    SubtitleLabel.TextColor3 = Config.TextColor
    SubtitleLabel.TextSize = 11
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.ZIndex = 12
    SubtitleLabel.Parent = HeaderFrame
    
    -- Circular Headshot (Right Side)
    local HeadshotFrame = Instance.new("Frame")
    HeadshotFrame.Name = GenerateRandomString(12)
    HeadshotFrame.BackgroundColor3 = Config.TertiaryColor
    HeadshotFrame.BorderSizePixel = 0
    HeadshotFrame.Position = UDim2.new(1, -55, 0, 0)
    HeadshotFrame.Size = UDim2.new(0, 50, 0, 50)
    HeadshotFrame.ZIndex = 12
    HeadshotFrame.Parent = HeaderFrame
    
    local HeadshotCorner = Instance.new("UICorner")
    HeadshotCorner.CornerRadius = UDim.new(1, 0)  -- Circular
    HeadshotCorner.Name = GenerateRandomString(12)
    HeadshotCorner.Parent = HeadshotFrame
    
    CreateFrameShadow(HeadshotFrame, Config.BorderColor, 3)
    
    -- Get player thumbnail
    pcall(function()
        local userId = LocalPlayer.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size420x420
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        
        local HeadshotImage = Instance.new("ImageLabel")
        HeadshotImage.Name = GenerateRandomString(12)
        HeadshotImage.BackgroundTransparency = 1
        HeadshotImage.Size = UDim2.new(1, 0, 1, 0)
        HeadshotImage.Image = content
        HeadshotImage.ZIndex = 13
        HeadshotImage.Parent = HeadshotFrame
        
        local HeadshotImageCorner = Instance.new("UICorner")
        HeadshotImageCorner.CornerRadius = UDim.new(1, 0)  -- Circular
        HeadshotImageCorner.Name = GenerateRandomString(12)
        HeadshotImageCorner.Parent = HeadshotImage
    end)
    
    -- Game Info Frame
    local GameInfoFrame = Instance.new("Frame")
    GameInfoFrame.Name = GenerateRandomString(12)
    GameInfoFrame.BackgroundColor3 = Config.TertiaryColor
    GameInfoFrame.BorderSizePixel = 0
    GameInfoFrame.Position = UDim2.new(0, 15, 0, 70)
    GameInfoFrame.Size = UDim2.new(1, -30, 0, 85)
    GameInfoFrame.ZIndex = 12
    GameInfoFrame.Parent = HomeTab.Content
    
    local GameInfoCorner = Instance.new("UICorner")
    GameInfoCorner.CornerRadius = UDim.new(0, 8)
    GameInfoCorner.Name = GenerateRandomString(12)
    GameInfoCorner.Parent = GameInfoFrame
    
    CreateFrameShadow(GameInfoFrame, Config.AccentColor, 3)
    
    local GameInfoTitle = Instance.new("TextLabel")
    GameInfoTitle.Name = GenerateRandomString(12)
    GameInfoTitle.BackgroundTransparency = 1
    GameInfoTitle.Position = UDim2.new(0, 12, 0, 5)
    GameInfoTitle.Size = UDim2.new(1, -24, 0, 14)
    GameInfoTitle.Font = Enum.Font.Code
    GameInfoTitle.Text = "> Game Information"
    GameInfoTitle.TextColor3 = Config.NavbarHC2
    GameInfoTitle.TextSize = 11
    GameInfoTitle.TextXAlignment = Enum.TextXAlignment.Left
    GameInfoTitle.ZIndex = 13
    GameInfoTitle.Parent = GameInfoFrame
    
    -- Game Name
    local GameNameLabel = Instance.new("TextLabel")
    GameNameLabel.Name = GenerateRandomString(12)
    GameNameLabel.BackgroundTransparency = 1
    GameNameLabel.Position = UDim2.new(0, 12, 0, 22)
    GameNameLabel.Size = UDim2.new(1, -24, 0, 14)
    GameNameLabel.Font = Enum.Font.Code
    GameNameLabel.Text = "🎮 Loading..."
    GameNameLabel.TextColor3 = Config.TextColor
    GameNameLabel.TextSize = 10
    GameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    GameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    GameNameLabel.ZIndex = 13
    GameNameLabel.Parent = GameInfoFrame
    
    pcall(function()
        local marketplaceService = game:GetService("MarketplaceService")
        local productInfo = marketplaceService:GetProductInfo(game.PlaceId)
        GameNameLabel.Text = "🎮 " .. productInfo.Name
    end)
    
    -- Player Count
    local PlayerCountLabel = Instance.new("TextLabel")
    PlayerCountLabel.Name = GenerateRandomString(12)
    PlayerCountLabel.BackgroundTransparency = 1
    PlayerCountLabel.Position = UDim2.new(0, 12, 0, 38)
    PlayerCountLabel.Size = UDim2.new(1, -24, 0, 14)
    PlayerCountLabel.Font = Enum.Font.Code
    PlayerCountLabel.Text = "👥 " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " Players"
    PlayerCountLabel.TextColor3 = Config.TextColor
    PlayerCountLabel.TextSize = 10
    PlayerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    PlayerCountLabel.ZIndex = 13
    PlayerCountLabel.Parent = GameInfoFrame
    
    -- Job ID with Copy Button
    local JobIdFrame = Instance.new("Frame")
    JobIdFrame.Name = GenerateRandomString(12)
    JobIdFrame.BackgroundTransparency = 1
    JobIdFrame.Position = UDim2.new(0, 12, 0, 54)
    JobIdFrame.Size = UDim2.new(1, -24, 0, 24)
    JobIdFrame.ZIndex = 13
    JobIdFrame.Parent = GameInfoFrame
    
    local JobIdLabel = Instance.new("TextLabel")
    JobIdLabel.Name = GenerateRandomString(12)
    JobIdLabel.BackgroundTransparency = 1
    JobIdLabel.Position = UDim2.new(0, 0, 0, 5)
    JobIdLabel.Size = UDim2.new(1, -70, 0, 14)
    JobIdLabel.Font = Enum.Font.Code
    JobIdLabel.Text = "🔗 " .. game.JobId:sub(1, 20) .. "..."
    JobIdLabel.TextColor3 = Config.TextColor
    JobIdLabel.TextSize = 9
    JobIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    JobIdLabel.TextTruncate = Enum.TextTruncate.AtEnd
    JobIdLabel.ZIndex = 14
    JobIdLabel.Parent = JobIdFrame
    
    local CopyJobButton = Instance.new("TextButton")
    CopyJobButton.Name = GenerateRandomString(12)
    CopyJobButton.BackgroundColor3 = Config.SecondaryColor
    CopyJobButton.BorderSizePixel = 0
    CopyJobButton.Position = UDim2.new(1, -65, 0, 0)
    CopyJobButton.Size = UDim2.new(0, 65, 0, 22)
    CopyJobButton.Font = Enum.Font.Code
    CopyJobButton.Text = "📋 Copy"
    CopyJobButton.TextColor3 = Config.TextColor
    CopyJobButton.TextSize = 9
    CopyJobButton.ZIndex = 14
    CopyJobButton.AutoButtonColor = false
    CopyJobButton.Parent = JobIdFrame
    
    local CopyJobCorner = Instance.new("UICorner")
    CopyJobCorner.CornerRadius = UDim.new(0, 5)
    CopyJobCorner.Name = GenerateRandomString(12)
    CopyJobCorner.Parent = CopyJobButton
    
    CopyJobButton.MouseEnter:Connect(function()
        Tween(CopyJobButton, {BackgroundColor3 = Config.ButtonHover, TextColor3 = Config.HoverTextColor}, 0.2)
    end)
    
    CopyJobButton.MouseLeave:Connect(function()
        Tween(CopyJobButton, {BackgroundColor3 = Config.SecondaryColor, TextColor3 = Config.TextColor}, 0.2)
    end)
    
    CopyJobButton.MouseButton1Click:Connect(function()
        pcall(function()
            setclipboard(game.JobId)
            CopyJobButton.Text = "✓ Done"
            Library:Notify("Job ID", "Copied to clipboard!", 2)
            task.wait(1.5)
            CopyJobButton.Text = "📋 Copy"
        end)
    end)
    
    -- Discord & Website Buttons
    local ButtonsFrame = Instance.new("Frame")
    ButtonsFrame.Name = GenerateRandomString(12)
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.Position = UDim2.new(0, 15, 0, 165)
    ButtonsFrame.Size = UDim2.new(1, -30, 0, 38)
    ButtonsFrame.ZIndex = 12
    ButtonsFrame.Parent = HomeTab.Content
    
    local DiscordButton = Instance.new("TextButton")
    DiscordButton.Name = GenerateRandomString(12)
    DiscordButton.BackgroundColor3 = Config.SecondaryColor
    DiscordButton.BorderSizePixel = 0
    DiscordButton.Position = UDim2.new(0, 0, 0, 0)
    DiscordButton.Size = UDim2.new(0.48, 0, 0, 38)
    DiscordButton.Font = Enum.Font.GothamBold
    DiscordButton.Text = "📱 Discord"
    DiscordButton.TextColor3 = Config.NavbarHC
    DiscordButton.TextSize = 13
    DiscordButton.ZIndex = 13
    DiscordButton.AutoButtonColor = false
    DiscordButton.Parent = ButtonsFrame
    
    local DiscordCorner = Instance.new("UICorner")
    DiscordCorner.CornerRadius = UDim.new(0, 8)
    DiscordCorner.Name = GenerateRandomString(12)
    DiscordCorner.Parent = DiscordButton
    
    CreateFrameShadow(DiscordButton, Config.AccentColor, 3)
    
    DiscordButton.MouseEnter:Connect(function()
        Tween(DiscordButton, {BackgroundColor3 = Config.ButtonHover, TextColor3 = Config.HoverTextColor}, 0.2)
    end)
    
    DiscordButton.MouseLeave:Connect(function()
        Tween(DiscordButton, {BackgroundColor3 = Config.SecondaryColor, TextColor3 = Config.NavbarHC}, 0.2)
    end)
    
    DiscordButton.MouseButton1Click:Connect(function()
        Tween(DiscordButton, {BackgroundColor3 = Config.AccentColor}, 0.1)
        task.wait(0.1)
        Tween(DiscordButton, {BackgroundColor3 = Config.ButtonHover}, 0.1)
        
        pcall(function()
            setclipboard(Config.DiscordLink)
            DiscordButton.Text = "✓ Copied!"
            Library:Notify("Discord", "Link copied to clipboard!", 2)
            task.wait(2)
            DiscordButton.Text = "📱 Discord"
        end)
    end)
    
    local WebsiteButton = Instance.new("TextButton")
    WebsiteButton.Name = GenerateRandomString(12)
    WebsiteButton.BackgroundColor3 = Config.SecondaryColor
    WebsiteButton.BorderSizePixel = 0
    WebsiteButton.Position = UDim2.new(0.52, 0, 0, 0)
    WebsiteButton.Size = UDim2.new(0.48, 0, 0, 38)
    WebsiteButton.Font = Enum.Font.GothamBold
    WebsiteButton.Text = "🌐 Website"
    WebsiteButton.TextColor3 = Config.NavbarHC
    WebsiteButton.TextSize = 13
    WebsiteButton.ZIndex = 13
    WebsiteButton.AutoButtonColor = false
    WebsiteButton.Parent = ButtonsFrame
    
    local WebsiteCorner = Instance.new("UICorner")
    WebsiteCorner.CornerRadius = UDim.new(0, 8)
    WebsiteCorner.Name = GenerateRandomString(12)
    WebsiteCorner.Parent = WebsiteButton
    
    CreateFrameShadow(WebsiteButton, Config.AccentColor, 3)
    
    WebsiteButton.MouseEnter:Connect(function()
        Tween(WebsiteButton, {BackgroundColor3 = Config.ButtonHover, TextColor3 = Config.HoverTextColor}, 0.2)
    end)
    
    WebsiteButton.MouseLeave:Connect(function()
        Tween(WebsiteButton, {BackgroundColor3 = Config.SecondaryColor, TextColor3 = Config.NavbarHC}, 0.2)
    end)
    
    WebsiteButton.MouseButton1Click:Connect(function()
        Tween(WebsiteButton, {BackgroundColor3 = Config.AccentColor}, 0.1)
        task.wait(0.1)
        Tween(WebsiteButton, {BackgroundColor3 = Config.ButtonHover}, 0.1)
        
        pcall(function()
            setclipboard(Config.WebsiteLink)
            WebsiteButton.Text = "✓ Copied!"
            Library:Notify("Website", "Link copied to clipboard!", 2)
            task.wait(2)
            WebsiteButton.Text = "🌐 Website"
        end)
    end)
    
    -- System Status Frame (Bottom with proper spacing)
    local SystemFrame = Instance.new("Frame")
    SystemFrame.Name = GenerateRandomString(12)
    SystemFrame.BackgroundColor3 = Config.TertiaryColor
    SystemFrame.BorderSizePixel = 0
    SystemFrame.Position = UDim2.new(0, 15, 1, -60)
    SystemFrame.Size = UDim2.new(1, -30, 0, 50)
    SystemFrame.ZIndex = 12
    SystemFrame.Parent = HomeTab.Content
    
    local SystemCorner = Instance.new("UICorner")
    SystemCorner.CornerRadius = UDim.new(0, 8)
    SystemCorner.Name = GenerateRandomString(12)
    SystemCorner.Parent = SystemFrame
    
    CreateFrameShadow(SystemFrame, Config.AccentColor, 3)
    
    local SystemTitle = Instance.new("TextLabel")
    SystemTitle.Name = GenerateRandomString(12)
    SystemTitle.BackgroundTransparency = 1
    SystemTitle.Position = UDim2.new(0, 12, 0, 5)
    SystemTitle.Size = UDim2.new(1, -24, 0, 14)
    SystemTitle.Font = Enum.Font.Code
    SystemTitle.Text = "> System Status"
    SystemTitle.TextColor3 = Config.NavbarHC2
    SystemTitle.TextSize = 11
    SystemTitle.TextXAlignment = Enum.TextXAlignment.Left
    SystemTitle.ZIndex = 13
    SystemTitle.Parent = SystemFrame
    
    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Name = GenerateRandomString(12)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.Position = UDim2.new(0, 12, 0, 24)
    FPSLabel.Size = UDim2.new(0.5, -15, 0, 18)
    FPSLabel.Font = Enum.Font.Code
    FPSLabel.Text = "FPS: ..."
    FPSLabel.TextColor3 = Config.TextColor
    FPSLabel.TextSize = 10
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.ZIndex = 13
    FPSLabel.Parent = SystemFrame
    
    local PingLabel = Instance.new("TextLabel")
    PingLabel.Name = GenerateRandomString(12)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Position = UDim2.new(0.5, 3, 0, 24)
    PingLabel.Size = UDim2.new(0.5, -15, 0, 18)
    PingLabel.Font = Enum.Font.Code
    PingLabel.Text = "Ping: " .. math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms"
    PingLabel.TextColor3 = Config.TextColor
    PingLabel.TextSize = 10
    PingLabel.TextXAlignment = Enum.TextXAlignment.Left
    PingLabel.ZIndex = 13
    PingLabel.Parent = SystemFrame
    
    -- FPS Counter
    local lastUpdate = tick()
    local fps = 0
    RunService.RenderStepped:Connect(function()
        local now = tick()
        fps = math.floor(1 / (now - lastUpdate))
        lastUpdate = now
        FPSLabel.Text = "FPS: " .. tostring(fps)
    end)
    
    -- Settings Tab (Also Static)
    local SettingsTab = Library:CreateTab("Settings")
    
    local SettingsTitle = Instance.new("TextLabel")
    SettingsTitle.Name = GenerateRandomString(12)
    SettingsTitle.BackgroundTransparency = 1
    SettingsTitle.Position = UDim2.new(0, 20, 0, 15)
    SettingsTitle.Size = UDim2.new(1, -40, 0, 25)
    SettingsTitle.Font = Enum.Font.Code
    SettingsTitle.Text = "> UI Settings"
    SettingsTitle.TextColor3 = Config.NavbarHC2
    SettingsTitle.TextSize = 16
    SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    SettingsTitle.ZIndex = 12
    SettingsTitle.Parent = SettingsTab.Content
    
    -- Hotkey Selector
    local HotkeyFrame = Instance.new("Frame")
    HotkeyFrame.Name = GenerateRandomString(12)
    HotkeyFrame.BackgroundColor3 = Config.TertiaryColor
    HotkeyFrame.BorderSizePixel = 0
    HotkeyFrame.Position = UDim2.new(0, 20, 0, 50)
    HotkeyFrame.Size = UDim2.new(1, -40, 0, 45)
    HotkeyFrame.ZIndex = 12
    HotkeyFrame.Parent = SettingsTab.Content
    
    local HotkeyCorner = Instance.new("UICorner")
    HotkeyCorner.CornerRadius = UDim.new(0, 8)
    HotkeyCorner.Name = GenerateRandomString(12)
    HotkeyCorner.Parent = HotkeyFrame
    
    CreateFrameShadow(HotkeyFrame, Config.AccentColor, 3)
    
    local HotkeyLabel = Instance.new("TextLabel")
    HotkeyLabel.Name = GenerateRandomString(12)
    HotkeyLabel.BackgroundTransparency = 1
    HotkeyLabel.Position = UDim2.new(0, 15, 0, 5)
    HotkeyLabel.Size = UDim2.new(1, -30, 0, 18)
    HotkeyLabel.Font = Enum.Font.GothamBold
    HotkeyLabel.Text = "Toggle Hotkey"
    HotkeyLabel.TextColor3 = Config.TextColor
    HotkeyLabel.TextSize = 13
    HotkeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    HotkeyLabel.ZIndex = 13
    HotkeyLabel.Parent = HotkeyFrame
    
    local HotkeyValue = Instance.new("TextLabel")
    HotkeyValue.Name = GenerateRandomString(12)
    HotkeyValue.BackgroundTransparency = 1
    HotkeyValue.Position = UDim2.new(0, 15, 0, 23)
    HotkeyValue.Size = UDim2.new(1, -30, 0, 16)
    HotkeyValue.Font = Enum.Font.Code
    HotkeyValue.Text = "> Current: RightControl"
    HotkeyValue.TextColor3 = Config.NavbarHC2
    HotkeyValue.TextSize = 11
    HotkeyValue.TextXAlignment = Enum.TextXAlignment.Left
    HotkeyValue.ZIndex = 13
    HotkeyValue.Parent = HotkeyFrame
    
    -- About Frame
    local AboutFrame = Instance.new("Frame")
    AboutFrame.Name = GenerateRandomString(12)
    AboutFrame.BackgroundColor3 = Config.TertiaryColor
    AboutFrame.BorderSizePixel = 0
    AboutFrame.Position = UDim2.new(0, 20, 1, -80)
    AboutFrame.Size = UDim2.new(1, -40, 0, 75)
    AboutFrame.ZIndex = 12
    AboutFrame.Parent = SettingsTab.Content
    
    local AboutCorner = Instance.new("UICorner")
    AboutCorner.CornerRadius = UDim.new(0, 8)
    AboutCorner.Name = GenerateRandomString(12)
    AboutCorner.Parent = AboutFrame
    
    CreateFrameShadow(AboutFrame, Config.AccentColor, 3)
    
    local AboutTitle = Instance.new("TextLabel")
    AboutTitle.Name = GenerateRandomString(12)
    AboutTitle.BackgroundTransparency = 1
    AboutTitle.Position = UDim2.new(0, 15, 0, 8)
    AboutTitle.Size = UDim2.new(1, -30, 0, 16)
    AboutTitle.Font = Enum.Font.Code
    AboutTitle.Text = "> About LURKOUT"
    AboutTitle.TextColor3 = Config.NavbarHC2
    AboutTitle.TextSize = 12
    AboutTitle.TextXAlignment = Enum.TextXAlignment.Left
    AboutTitle.ZIndex = 13
    AboutTitle.Parent = AboutFrame
    
    local AboutText = Instance.new("TextLabel")
    AboutText.Name = GenerateRandomString(12)
    AboutText.BackgroundTransparency = 1
    AboutText.Position = UDim2.new(0, 15, 0, 28)
    AboutText.Size = UDim2.new(1, -30, 0, 42)
    AboutText.Font = Enum.Font.Code
    AboutText.Text = "Version: 3.5 Enhanced\nDark Mode with Red Accents\nUI Library by LURKOUT Team"
    AboutText.TextColor3 = Config.TextColor
    AboutText.TextSize = 10
    AboutText.TextXAlignment = Enum.TextXAlignment.Left
    AboutText.TextYAlignment = Enum.TextYAlignment.Top
    AboutText.TextWrapped = true
    AboutText.ZIndex = 13
    AboutText.Parent = AboutFrame
    
    -- Example Tab
    local ExampleTab = Library:CreateTab("Example")
    
    ExampleTab:AddLabel("🎯 Example Features")
    
    ExampleTab:AddButton("Test Notification", function()
        Library:Notify("Test", "Beautiful dark theme notification!", 3)
    end)
    
    ExampleTab:AddToggle("Example Toggle", false, function(state)
        Library:Notify("Toggle", "State: " .. tostring(state), 2)
    end)
    
    ExampleTab:AddSlider("Example Slider", 0, 100, 50, function(value)
        print("Slider Value:", value)
    end)
    
    ExampleTab:AddInput("Example Input", "Type something...", function(text)
        Library:Notify("Input", "You typed: " .. text, 2)
    end)
    
    ExampleTab:AddDropdown("Example Dropdown", {"Option 1", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6", "Option 7"}, function(selected)
        Library:Notify("Dropdown", "Selected: " .. selected, 2)
    end)
    
    Library:Notify("LURKOUT", "UI Loaded Successfully!", 3)
    
    return Library
end

return LURKOUT:Init()