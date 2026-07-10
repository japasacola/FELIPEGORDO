-- ============================================================
--  BEAST HUB — BLOX FRUITS AUTO FARM
--  SIMPLES QUE FUNCIONA:
--  Thread A: aceita quest a cada 10s (background, sem parar farm)
--  Thread B: mata mobs sem parar, 55 studs no ar
-- ============================================================

local RS    = game:GetService("ReplicatedStorage")
local VIM   = game:GetService("VirtualInputManager")
local UIS   = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local LP    = game.Players.LocalPlayer

local World1 = game.PlaceId==2753915549 or game.PlaceId==85211729168715
local World2 = game.PlaceId==4442272183 or game.PlaceId==79091703265657
local World3 = game.PlaceId==7449423635 or game.PlaceId==100117331123089

local AutoFarm = false
local Threads  = {}
local Mon, NameQuest, LevelQuest, CFrameQuest, CFrameMon

local function Try(fn) pcall(fn) end
local function Hum()  local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function HRP()  local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function Alive() local h=Hum(); return h and h.Health>0 end
local function MyLv()  local ok,v=pcall(function() return LP.Data.Level.Value end); return ok and tonumber(v) or 1 end
local function KT(k)   if Threads[k] then pcall(task.cancel,Threads[k]); Threads[k]=nil end end

local function TP(cf)
    Try(function() local h=HRP(); if h then h.CFrame=cf end end)
end

local function Float(on)
    Try(function()
        local h=HRP(); if not h then return end
        local bv=h:FindFirstChild("BH_F")
        if on and not bv then
            bv=Instance.new("BodyVelocity")
            bv.Name="BH_F"; bv.Velocity=Vector3.new(0,0,0)
            bv.MaxForce=Vector3.new(0,1e5,0); bv.P=1e4; bv.Parent=h
        elseif not on and bv then bv:Destroy() end
    end)
end

local function Click()
    Try(function()
        VIM:SendMouseButtonEvent(0,0,0,true,game,1)
        VIM:SendMouseButtonEvent(0,0,0,false,game,1)
    end)
end

local function CommF(...)
    local a={...}
    pcall(function() RS.Remotes.CommF_:InvokeServer(table.unpack(a)) end)
end

-- ── QUEST MAP ──
local function CheckQuest()
    local lv=MyLv()
    if World1 then
        if     lv<=9   then Mon="Bandit";              NameQuest="BanditQuest1";  LevelQuest=1; CFrameQuest=CFrame.new(1059,15,1550); CFrameMon=CFrame.new(1045,27,1560)
        elseif lv<=14  then Mon="Monkey";              NameQuest="JungleQuest";   LevelQuest=1; CFrameQuest=CFrame.new(-1598,35,153);   CFrameMon=CFrame.new(-1448,67,11)
        elseif lv<=29  then Mon="Gorilla";             NameQuest="JungleQuest";   LevelQuest=2; CFrameQuest=CFrame.new(-1598,35,153);   CFrameMon=CFrame.new(-1129,40,-525)
        elseif lv<=39  then Mon="Pirate";              NameQuest="BuggyQuest1";   LevelQuest=1; CFrameQuest=CFrame.new(-1141,4,3831);   CFrameMon=CFrame.new(-1103,13,3896)
        elseif lv<=59  then Mon="Brute";               NameQuest="BuggyQuest1";   LevelQuest=2; CFrameQuest=CFrame.new(-1141,4,3831);   CFrameMon=CFrame.new(-1140,14,4322)
        elseif lv<=74  then Mon="Desert Bandit";       NameQuest="DesertQuest";   LevelQuest=1; CFrameQuest=CFrame.new(894,5,4392);     CFrameMon=CFrame.new(924,6,4481)
        elseif lv<=89  then Mon="Desert Officer";      NameQuest="DesertQuest";   LevelQuest=2; CFrameQuest=CFrame.new(894,5,4392);     CFrameMon=CFrame.new(1608,8,4371)
        elseif lv<=99  then Mon="Snow Bandit";         NameQuest="SnowQuest";     LevelQuest=1; CFrameQuest=CFrame.new(1389,88,-1298);  CFrameMon=CFrame.new(1354,87,-1393)
        elseif lv<=119 then Mon="Snowman";             NameQuest="SnowQuest";     LevelQuest=2; CFrameQuest=CFrame.new(1389,88,-1298);  CFrameMon=CFrame.new(1201,144,-1550)
        elseif lv<=149 then Mon="Chief Petty Officer"; NameQuest="MarineQuest2";  LevelQuest=1; CFrameQuest=CFrame.new(-5039,27,4324);  CFrameMon=CFrame.new(-4881,22,4273)
        elseif lv<=174 then Mon="Sky Bandit";          NameQuest="SkyQuest";      LevelQuest=1; CFrameQuest=CFrame.new(-4839,716,-2619); CFrameMon=CFrame.new(-4953,295,-2899)
        elseif lv<=189 then Mon="Dark Master";         NameQuest="SkyQuest";      LevelQuest=2; CFrameQuest=CFrame.new(-4839,716,-2619); CFrameMon=CFrame.new(-5259,391,-2229)
        elseif lv<=209 then Mon="Prisoner";            NameQuest="PrisonerQuest"; LevelQuest=1; CFrameQuest=CFrame.new(5308,1,475);    CFrameMon=CFrame.new(5098,0,474)
        elseif lv<=249 then Mon="Dangerous Prisoner";  NameQuest="PrisonerQuest"; LevelQuest=2; CFrameQuest=CFrame.new(5308,1,475);    CFrameMon=CFrame.new(5654,15,866)
        elseif lv<=274 then Mon="Toga Warrior";        NameQuest="ColosseumQuest";LevelQuest=1; CFrameQuest=CFrame.new(-1580,6,-2986);  CFrameMon=CFrame.new(-1820,51,-2740)
        elseif lv<=299 then Mon="Gladiator";           NameQuest="ColosseumQuest";LevelQuest=2; CFrameQuest=CFrame.new(-1580,6,-2986);  CFrameMon=CFrame.new(-1292,56,-3339)
        elseif lv<=324 then Mon="Military Soldier";    NameQuest="MagmaQuest";    LevelQuest=1; CFrameQuest=CFrame.new(-5313,10,8515);  CFrameMon=CFrame.new(-5411,11,8454)
        elseif lv<=374 then Mon="Military Spy";        NameQuest="MagmaQuest";    LevelQuest=2; CFrameQuest=CFrame.new(-5313,10,8515);  CFrameMon=CFrame.new(-5802,86,8828)
        elseif lv<=399 then Mon="Fishman Warrior";     NameQuest="FishmanQuest";  LevelQuest=1; CFrameQuest=CFrame.new(61122,18,1569);  CFrameMon=CFrame.new(60878,18,1543); CommF("requestEntrance",Vector3.new(61163,11,1819))
        elseif lv<=449 then Mon="Fishman Commando";    NameQuest="FishmanQuest";  LevelQuest=2; CFrameQuest=CFrame.new(61122,18,1569);  CFrameMon=CFrame.new(61922,18,1493); CommF("requestEntrance",Vector3.new(61163,11,1819))
        elseif lv<=474 then Mon="God's Guard";         NameQuest="SkyExp1Quest";  LevelQuest=1; CFrameQuest=CFrame.new(-4721,843,-1949); CFrameMon=CFrame.new(-4710,845,-1927); CommF("requestEntrance",Vector3.new(-4607,872,-1667))
        elseif lv<=524 then Mon="Shanda";              NameQuest="SkyExp1Quest";  LevelQuest=2; CFrameQuest=CFrame.new(-7859,5544,-381); CFrameMon=CFrame.new(-7678,5566,-497)
        elseif lv<=549 then Mon="Royal Squad";         NameQuest="SkyExp2Quest";  LevelQuest=1; CFrameQuest=CFrame.new(-7906,5634,-1411); CFrameMon=CFrame.new(-7624,5658,-1467)
        elseif lv<=624 then Mon="Royal Soldier";       NameQuest="SkyExp2Quest";  LevelQuest=2; CFrameQuest=CFrame.new(-7906,5634,-1411); CFrameMon=CFrame.new(-7836,5645,-1790)
        elseif lv<=649 then Mon="Galley Pirate";       NameQuest="FountainQuest"; LevelQuest=1; CFrameQuest=CFrame.new(5259,37,4050);   CFrameMon=CFrame.new(5551,78,3930)
        else               Mon="Galley Captain";       NameQuest="FountainQuest"; LevelQuest=2; CFrameQuest=CFrame.new(5259,37,4050);   CFrameMon=CFrame.new(5441,42,4950)
        end
    elseif World2 then
        if     lv<=724  then Mon="Raider";             NameQuest="Area1Quest";        LevelQuest=1; CFrameQuest=CFrame.new(-429,71,1836);   CFrameMon=CFrame.new(-728,52,2345)
        elseif lv<=774  then Mon="Mercenary";          NameQuest="Area1Quest";        LevelQuest=2; CFrameQuest=CFrame.new(-429,71,1836);   CFrameMon=CFrame.new(-1004,80,1424)
        elseif lv<=799  then Mon="Swan Pirate";        NameQuest="Area2Quest";        LevelQuest=1; CFrameQuest=CFrame.new(638,71,918);     CFrameMon=CFrame.new(1068,137,1322)
        elseif lv<=874  then Mon="Factory Staff";      NameQuest="Area2Quest";        LevelQuest=2; CFrameQuest=CFrame.new(632,73,918);     CFrameMon=CFrame.new(73,81,-27)
        elseif lv<=899  then Mon="Marine Lieutenant";  NameQuest="MarineQuest3";      LevelQuest=1; CFrameQuest=CFrame.new(-2440,71,-3216);  CFrameMon=CFrame.new(-2821,75,-3070)
        elseif lv<=949  then Mon="Marine Captain";     NameQuest="MarineQuest3";      LevelQuest=2; CFrameQuest=CFrame.new(-2440,71,-3216);  CFrameMon=CFrame.new(-1861,80,-3254)
        elseif lv<=974  then Mon="Zombie";             NameQuest="ZombieQuest";       LevelQuest=1; CFrameQuest=CFrame.new(-5497,47,-795);   CFrameMon=CFrame.new(-5657,78,-928)
        elseif lv<=999  then Mon="Vampire";            NameQuest="ZombieQuest";       LevelQuest=2; CFrameQuest=CFrame.new(-5497,47,-795);   CFrameMon=CFrame.new(-6037,32,-1340)
        elseif lv<=1049 then Mon="Snow Trooper";       NameQuest="SnowMountainQuest"; LevelQuest=1; CFrameQuest=CFrame.new(609,400,-5372);  CFrameMon=CFrame.new(549,427,-5563)
        elseif lv<=1099 then Mon="Winter Warrior";     NameQuest="SnowMountainQuest"; LevelQuest=2; CFrameQuest=CFrame.new(609,400,-5372);  CFrameMon=CFrame.new(1142,475,-5199)
        elseif lv<=1124 then Mon="Lab Subordinate";    NameQuest="IceSideQuest";      LevelQuest=1; CFrameQuest=CFrame.new(-6064,15,-4902);  CFrameMon=CFrame.new(-5707,15,-4513)
        elseif lv<=1174 then Mon="Horned Warrior";     NameQuest="IceSideQuest";      LevelQuest=2; CFrameQuest=CFrame.new(-6064,15,-4902);  CFrameMon=CFrame.new(-6341,15,-5723)
        elseif lv<=1199 then Mon="Magma Ninja";        NameQuest="FireSideQuest";     LevelQuest=1; CFrameQuest=CFrame.new(-5428,15,-5299);  CFrameMon=CFrame.new(-5449,76,-5808)
        else               Mon="Lava Pirate";          NameQuest="FireSideQuest";     LevelQuest=2; CFrameQuest=CFrame.new(-5428,15,-5299);  CFrameMon=CFrame.new(-4857,74,-5905)
        end
    elseif World3 then
        if     lv<=1524 then Mon="Jungle Pirate";       NameQuest="ForestQuest";   LevelQuest=1; CFrameQuest=CFrame.new(-12289,331,-10577); CFrameMon=CFrame.new(-11778,426,-10592)
        elseif lv<=1574 then Mon="Forest Pirate";       NameQuest="ForestQuest";   LevelQuest=2; CFrameQuest=CFrame.new(-12289,331,-10577); CFrameMon=CFrame.new(-13446,413,-7760)
        elseif lv<=1624 then Mon="Mythological Pirate"; NameQuest="MythQuest";     LevelQuest=1; CFrameQuest=CFrame.new(-13650,584,-6987);  CFrameMon=CFrame.new(-13510,584,-6987)
        elseif lv<=1674 then Mon="Musketeer Pirate";    NameQuest="MythQuest";     LevelQuest=2; CFrameQuest=CFrame.new(-13650,584,-6987);  CFrameMon=CFrame.new(-13282,496,-9565)
        elseif lv<=1724 then Mon="Fishman Raider";      NameQuest="FishDeepQuest"; LevelQuest=1; CFrameQuest=CFrame.new(-10941,332,-8760);  CFrameMon=CFrame.new(-10941,332,-8760)
        elseif lv<=1799 then Mon="Fishman Captain";     NameQuest="FishDeepQuest"; LevelQuest=2; CFrameQuest=CFrame.new(-10941,332,-8760);  CFrameMon=CFrame.new(-11035,332,-9087)
        elseif lv<=1849 then Mon="Reborn Skeleton";     NameQuest="WyperQuest";    LevelQuest=1; CFrameQuest=CFrame.new(-8764,142,5963);   CFrameMon=CFrame.new(-8764,142,5963)
        elseif lv<=1924 then Mon="Living Zombie";       NameQuest="WyperQuest";    LevelQuest=2; CFrameQuest=CFrame.new(-8764,142,5963);   CFrameMon=CFrame.new(-10227,421,6161)
        elseif lv<=2024 then Mon="Peanut Scout";        NameQuest="PeanutQuest";   LevelQuest=1; CFrameQuest=CFrame.new(-1993,187,-10103);  CFrameMon=CFrame.new(-1993,187,-10103)
        elseif lv<=2074 then Mon="Peanut President";    NameQuest="PeanutQuest";   LevelQuest=2; CFrameQuest=CFrame.new(-1993,187,-10103);  CFrameMon=CFrame.new(-2215,159,-10474)
        elseif lv<=2124 then Mon="Ice Cream Chef";      NameQuest="CakeQuest";     LevelQuest=1; CFrameQuest=CFrame.new(-877,118,-11032);   CFrameMon=CFrame.new(-877,118,-11032)
        elseif lv<=2174 then Mon="Ice Cream Commander"; NameQuest="CakeQuest";     LevelQuest=2; CFrameQuest=CFrame.new(-877,118,-11032);   CFrameMon=CFrame.new(-877,118,-11032)
        elseif lv<=2224 then Mon="Cookie Crafter";      NameQuest="CakeFarm1";     LevelQuest=1; CFrameQuest=CFrame.new(-2021,38,-12028);   CFrameMon=CFrame.new(-2021,38,-12028)
        elseif lv<=2274 then Mon="Cake Guard";          NameQuest="CakeFarm1";     LevelQuest=2; CFrameQuest=CFrame.new(-2021,38,-12028);   CFrameMon=CFrame.new(-2024,38,-12026)
        elseif lv<=2349 then Mon="Baking Staff";        NameQuest="CakeFarm2";     LevelQuest=1; CFrameQuest=CFrame.new(-1932,38,-12848);   CFrameMon=CFrame.new(-1932,38,-12848)
        elseif lv<=2449 then Mon="Head Baker";          NameQuest="CakeFarm2";     LevelQuest=2; CFrameQuest=CFrame.new(-1932,38,-12848);   CFrameMon=CFrame.new(-1932,38,-12848)
        elseif lv<=2524 then Mon="Cocoa Warrior";       NameQuest="CakeFarm3";     LevelQuest=1; CFrameQuest=CFrame.new(95,73,-12309);      CFrameMon=CFrame.new(95,73,-12309)
        elseif lv<=2624 then Mon="Chocolate Bar Battler";NameQuest="CakeFarm3";    LevelQuest=2; CFrameQuest=CFrame.new(95,73,-12309);      CFrameMon=CFrame.new(647,42,-12401)
        else               Mon="Candy Rebel";           NameQuest="CakeFarm4";     LevelQuest=2; CFrameQuest=CFrame.new(116,36,-12478);     CFrameMon=CFrame.new(47,61,-12889)
        end
    else
        Mon="Bandit"; NameQuest="BanditQuest1"; LevelQuest=1
        CFrameQuest=CFrame.new(1059,15,1550); CFrameMon=CFrame.new(1045,27,1560)
    end
end

-- ── MOB ──
local function FindMob(nome)
    for _,m in ipairs(workspace.Enemies:GetChildren()) do
        if m.Name==nome then
            local mh=m:FindFirstChildOfClass("Humanoid")
            local mr=m:FindFirstChild("HumanoidRootPart")
            if mh and mr and mh.Health>0 then return m end
        end
    end
    for _,m in ipairs(RS:GetChildren()) do
        if m:IsA("Model") and m.Name==nome then
            local mh=m:FindFirstChildOfClass("Humanoid")
            local mr=m:FindFirstChild("HumanoidRootPart")
            if mh and mr and mh.Health>0 then return m end
        end
    end
end

-- ── ATACAR (55 studs no ar) ──
local function Atacar(mob)
    local mr=mob:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    TP(mr.CFrame*CFrame.new(0,55,0))
    task.wait(0.04)
    Float(true)
    Try(function()
        local sp,vis=workspace.CurrentCamera:WorldToScreenPoint(mr.Position)
        if vis then VIM:SendMouseMoveEvent(sp.X,sp.Y,game) end
    end)
    for i=1,6 do Click(); task.wait(0.02) end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  FARM LOOP                                               ║
-- ║  THREAD A: aceita quest a cada 10s — sem parar farm      ║
-- ║  THREAD B: mata mobs 100% do tempo                       ║
-- ╚══════════════════════════════════════════════════════════╝
local function StartFarm()
    KT("farm"); KT("quest")
    Float(true)

    -- THREAD A: quest em background
    Threads["quest"] = task.spawn(function()
        while AutoFarm do
            Try(function()
                CheckQuest()
                -- BF requer proximidade para aceitar quest
                -- TP rapido ao NPC → CommF_ → fecha dialogo → volta farmar
                Float(false)
                TP(CFrameQuest)
                task.wait(0.8)
                CommF("AskForQuest", NameQuest, LevelQuest)
                task.wait(0.3)
                -- fecha dialogo
                Try(function()
                    if LP.PlayerGui.Main.Dialogue.Visible then
                        LP.PlayerGui.Main.Dialogue.Visible=false
                    end
                end)
                task.wait(0.2)
                -- volta pro spawn dos mobs
                TP(CFrameMon)
                Float(true)
            end)
            -- espera 15s antes de tentar de novo
            task.wait(15)
        end
    end)

    -- THREAD B: kill loop, nunca para
    Threads["farm"] = task.spawn(function()
        while AutoFarm do
            Try(function()
                if not Alive() then
                    Float(false); task.wait(3); Float(true); return
                end
                CheckQuest()
                local mob = Mon and FindMob(Mon)
                if mob then
                    Atacar(mob)
                else
                    TP(CFrameMon)
                    task.wait(0.3)
                end
            end)
            task.wait(0.05)
        end
        Float(false)
    end)
end

local function StopFarm()
    KT("farm"); KT("quest"); Float(false)
end

LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    if AutoFarm then Float(true) end
end)

-- ╔══════════════════════════════╗
-- ║         GUI                  ║
-- ╚══════════════════════════════╝
pcall(function() LP.PlayerGui:FindFirstChild("BH"):Destroy() end)

local GUI=Instance.new("ScreenGui")
GUI.Name="BH"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; GUI.Parent=LP.PlayerGui

local Win=Instance.new("Frame",GUI)
Win.Name="Win"; Win.Size=UDim2.new(0,420,0,260)
Win.Position=UDim2.new(0.5,-210,0.5,-130)
Win.BackgroundColor3=Color3.fromRGB(8,8,16)
Win.BorderSizePixel=0; Win.Active=true; Win.Draggable=true
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,12)
local ws=Instance.new("UIStroke",Win); ws.Color=Color3.fromRGB(110,35,190); ws.Thickness=1.5

local Top=Instance.new("Frame",Win)
Top.Size=UDim2.new(1,0,0,42); Top.BackgroundColor3=Color3.fromRGB(14,14,24); Top.BorderSizePixel=0
local tg=Instance.new("UIGradient",Top)
tg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(70,18,150)),ColorSequenceKeypoint.new(1,Color3.fromRGB(14,14,24))}); tg.Rotation=90

local ttl=Instance.new("TextLabel",Top)
ttl.Text="  ⚡ Beast Hub"; ttl.Size=UDim2.new(1,-80,1,0)
ttl.BackgroundTransparency=1; ttl.TextColor3=Color3.fromRGB(170,110,250)
ttl.Font=Enum.Font.GothamBold; ttl.TextSize=14; ttl.TextXAlignment=Enum.TextXAlignment.Left

local function Btn(t,col,x)
    local b=Instance.new("TextButton",Top)
    b.Size=UDim2.new(0,28,0,20); b.Position=UDim2.new(1,x,0.5,-10)
    b.BackgroundColor3=col; b.Text=t; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4); return b
end
Btn("✕",Color3.fromRGB(150,25,55),-34).MouseButton1Click:Connect(function() Win.Visible=not Win.Visible end)
local mini=false
Btn("─",Color3.fromRGB(35,35,55),-68).MouseButton1Click:Connect(function()
    mini=not mini; Win.Size=mini and UDim2.new(0,420,0,42) or UDim2.new(0,420,0,260)
end)

local CA=Instance.new("ScrollingFrame",Win)
CA.Size=UDim2.new(1,0,1,-60); CA.Position=UDim2.new(0,0,0,42)
CA.BackgroundTransparency=1; CA.BorderSizePixel=0
CA.ScrollBarThickness=3; CA.ScrollBarImageColor3=Color3.fromRGB(110,35,190)
CA.CanvasSize=UDim2.new(0,0,0,0); CA.AutomaticCanvasSize=Enum.AutomaticSize.Y
local CAL=Instance.new("UIListLayout",CA); CAL.Padding=UDim.new(0,5)
CAL.SortOrder=Enum.SortOrder.LayoutOrder; CAL.HorizontalAlignment=Enum.HorizontalAlignment.Center
local CAP=Instance.new("UIPadding",CA)
CAP.PaddingTop=UDim.new(0,8); CAP.PaddingLeft=UDim.new(0,10); CAP.PaddingRight=UDim.new(0,10)

local function Row(lbl, onFn, offFn)
    local row=Instance.new("Frame",CA)
    row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=Color3.fromRGB(14,14,26); row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",row)
    l.Text=lbl; l.Size=UDim2.new(1,-52,1,0); l.Position=UDim2.new(0,12,0,0)
    l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(205,205,225)
    l.Font=Enum.Font.Gotham; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left
    local state=false
    local cb=Instance.new("TextButton",row)
    cb.Size=UDim2.new(0,22,0,22); cb.Position=UDim2.new(1,-32,0.5,-11)
    cb.BackgroundColor3=Color3.fromRGB(24,24,38); cb.Text=""
    cb.TextColor3=Color3.fromRGB(255,255,255); cb.Font=Enum.Font.GothamBold; cb.TextSize=12; cb.BorderSizePixel=0
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
    Instance.new("UIStroke",cb).Color=Color3.fromRGB(75,30,150)
    local function toggle()
        state=not state
        cb.BackgroundColor3=state and Color3.fromRGB(110,35,190) or Color3.fromRGB(24,24,38)
        cb.Text=state and "✓" or ""
        if state then onFn() else offFn() end
    end
    cb.MouseButton1Click:Connect(toggle)
    row.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then toggle() end end)
end

Row("🌾  Auto Farm Level",
    function() AutoFarm=true;  StartFarm() end,
    function() AutoFarm=false; StopFarm()  end)

Row("⚡  Speed Hack",
    function() Try(function() local h=Hum(); if h then h.WalkSpeed=80; h.JumpPower=75 end end) end,
    function() Try(function() local h=Hum(); if h then h.WalkSpeed=16; h.JumpPower=50 end end) end)

Row("🛡️  Anti AFK",
    function() KT("afk"); Threads["afk"]=task.spawn(function() while true do task.wait(80); Click() end end) end,
    function() KT("afk") end)

local Info=Instance.new("TextLabel",CA)
Info.Size=UDim2.new(1,0,0,32); Info.BackgroundColor3=Color3.fromRGB(10,10,20); Info.BorderSizePixel=0
Info.TextColor3=Color3.fromRGB(130,100,190); Info.Font=Enum.Font.Gotham; Info.TextSize=11
Info.TextWrapped=true; Info.TextXAlignment=Enum.TextXAlignment.Left
Instance.new("UICorner",Info).CornerRadius=UDim.new(0,6)
local IP=Instance.new("UIPadding",Info); IP.PaddingLeft=UDim.new(0,8); IP.PaddingTop=UDim.new(0,4)

local SBar=Instance.new("Frame",Win)
SBar.Size=UDim2.new(1,0,0,18); SBar.Position=UDim2.new(0,0,1,-18)
SBar.BackgroundColor3=Color3.fromRGB(5,5,10); SBar.BorderSizePixel=0
local SLb=Instance.new("TextLabel",SBar)
SLb.Size=UDim2.new(1,-8,1,0); SLb.Position=UDim2.new(0,6,0,0)
SLb.BackgroundTransparency=1; SLb.TextColor3=Color3.fromRGB(70,55,120)
SLb.Font=Enum.Font.Gotham; SLb.TextSize=10; SLb.TextXAlignment=Enum.TextXAlignment.Left

UIS.InputBegan:Connect(function(i,g)
    if not g and i.KeyCode==Enum.KeyCode.RightAlt then Win.Visible=not Win.Visible end
end)

task.spawn(function()
    while true do
        Try(function()
            CheckQuest()
            local h=Hum()
            Info.Text=string.format("  Lv %s | Mob: %s | Quest: %s", MyLv(), Mon or "?", NameQuest or "?")
            SLb.Text=string.format("HP:%s | Farm:%s | RightAlt=menu", h and math.floor(h.Health) or "?", AutoFarm and "ON" or "OFF")
        end)
        task.wait(1)
    end
end)

print("[BeastHub] Carregado! RightAlt = menu 🔥")
