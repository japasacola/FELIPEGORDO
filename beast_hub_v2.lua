-- ============================================================
--  BEAST HUB v4 — BLOX FRUITS
--  FIXES: ataca do AR | quest auto | kill rápido | só fighting style
--  Executor: Synapse X / KRNL / Fluxus / Delta
-- ============================================================
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local VIM              = game:GetService("VirtualInputManager")
local UIS              = game:GetService("UserInputService")
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()
-- World detection via PlaceId
local World1 = game.PlaceId == 2753915549 or game.PlaceId == 85211729168715
local World2 = game.PlaceId == 4442272183 or game.PlaceId == 79091703265657
local World3 = game.PlaceId == 7449423635 or game.PlaceId == 100117331123089
-- ╔═══════════════╗
-- ║     STATE     ║
-- ╚═══════════════╝
local S = {
    AutoFarm   = false,
    AutoRaid   = false,
    BringMobs  = false,
    SpeedHack  = false,
    AntiAFK    = false,
    FarmMon    = nil,
    FarmCF     = nil,
    QuestCF    = nil,
    QuestName  = nil,
    QuestSlot  = 1,
}
local Threads = {}
-- ╔══════════════════╗
-- ║    SAFE FUNCS    ║
-- ╚══════════════════╝
local function Try(fn) pcall(fn) end
local function GetChar()  return LP.Character end
local function GetHRP()   local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()   local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function IsAlive()  local h=GetHum();  return h and h.Health > 0 end
local function MyLevel()
    local ok, v = pcall(function() return LP.Data.Level.Value end)
    return ok and tonumber(v) or 1
end
-- Teleport
local function TP(cf)
    Try(function()
        local hrp = GetHRP()
        if hrp then hrp.CFrame = cf end
    end)
end
-- CommF_ invoke (returns result)
local function CommF(...)
    local args = {...}
    local ok, res = pcall(function()
        return RS.Remotes.CommF_:InvokeServer(table.unpack(args))
    end)
    return ok and res or nil
end
-- Mouse LEFT CLICK (fighting style only — no skills)
local function Click()
    Try(function()
        VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end
-- Kill thread
local function Kill(k)
    if Threads[k] then
        pcall(task.cancel, Threads[k])
        Threads[k] = nil
    end
end
-- ╔══════════════════╗
-- ║   QUEST MAP      ║
-- ╚══════════════════╝
local function UpdateQuest()
    local lv = MyLevel()
    if World1 then
        if     lv<10  then S.FarmMon="Bandit";            S.QuestName="BanditQuest1";  S.QuestSlot=1; S.QuestCF=CFrame.new(1059,15,1550);  S.FarmCF=CFrame.new(1045,27,1560)
        elseif lv<15  then S.FarmMon="Monkey";            S.QuestName="JungleQuest";   S.QuestSlot=1; S.QuestCF=CFrame.new(-1598,35,153);  S.FarmCF=CFrame.new(-1448,67,11)
        elseif lv<30  then S.FarmMon="Gorilla";           S.QuestName="JungleQuest";   S.QuestSlot=2; S.QuestCF=CFrame.new(-1598,35,153);  S.FarmCF=CFrame.new(-1129,40,-525)
        elseif lv<40  then S.FarmMon="Pirate";            S.QuestName="BuggyQuest1";   S.QuestSlot=1; S.QuestCF=CFrame.new(-1141,4,3831);  S.FarmCF=CFrame.new(-1103,13,3896)
        elseif lv<60  then S.FarmMon="Brute";             S.QuestName="BuggyQuest1";   S.QuestSlot=2; S.QuestCF=CFrame.new(-1141,4,3831);  S.FarmCF=CFrame.new(-1140,14,4322)
        elseif lv<75  then S.FarmMon="Desert Bandit";     S.QuestName="DesertQuest";   S.QuestSlot=1; S.QuestCF=CFrame.new(894,5,4392);    S.FarmCF=CFrame.new(924,6,4481)
        elseif lv<90  then S.FarmMon="Desert Officer";    S.QuestName="DesertQuest";   S.QuestSlot=2; S.QuestCF=CFrame.new(894,5,4392);    S.FarmCF=CFrame.new(1608,8,4371)
        elseif lv<100 then S.FarmMon="Snow Bandit";       S.QuestName="SnowQuest";     S.QuestSlot=1; S.QuestCF=CFrame.new(1389,88,-1298); S.FarmCF=CFrame.new(1354,87,-1393)
        elseif lv<120 then S.FarmMon="Snowman";           S.QuestName="SnowQuest";     S.QuestSlot=2; S.QuestCF=CFrame.new(1389,88,-1298); S.FarmCF=CFrame.new(1201,144,-1550)
        elseif lv<150 then S.FarmMon="Chief Petty Officer";S.QuestName="MarineQuest2"; S.QuestSlot=1; S.QuestCF=CFrame.new(-5039,27,4324); S.FarmCF=CFrame.new(-4881,22,4273)
        elseif lv<175 then S.FarmMon="Sky Bandit";        S.QuestName="SkyQuest";      S.QuestSlot=1; S.QuestCF=CFrame.new(-4839,716,-2619);S.FarmCF=CFrame.new(-4953,295,-2899)
        elseif lv<190 then S.FarmMon="Dark Master";       S.QuestName="SkyQuest";      S.QuestSlot=2; S.QuestCF=CFrame.new(-4839,716,-2619);S.FarmCF=CFrame.new(-5259,391,-2229)
        elseif lv<210 then S.FarmMon="Prisoner";          S.QuestName="PrisonerQuest"; S.QuestSlot=1; S.QuestCF=CFrame.new(5308,1,475);    S.FarmCF=CFrame.new(5098,0,474)
        elseif lv<250 then S.FarmMon="Dangerous Prisoner";S.QuestName="PrisonerQuest"; S.QuestSlot=2; S.QuestCF=CFrame.new(5308,1,475);    S.FarmCF=CFrame.new(5654,15,866)
        elseif lv<275 then S.FarmMon="Toga Warrior";      S.QuestName="ColosseumQuest";S.QuestSlot=1; S.QuestCF=CFrame.new(-1580,6,-2986);  S.FarmCF=CFrame.new(-1820,51,-2740)
        elseif lv<300 then S.FarmMon="Gladiator";         S.QuestName="ColosseumQuest";S.QuestSlot=2; S.QuestCF=CFrame.new(-1580,6,-2986);  S.FarmCF=CFrame.new(-1292,56,-3339)
        elseif lv<325 then S.FarmMon="Military Soldier";  S.QuestName="MagmaQuest";    S.QuestSlot=1; S.QuestCF=CFrame.new(-5313,10,8515);  S.FarmCF=CFrame.new(-5411,11,8454)
        elseif lv<375 then S.FarmMon="Military Spy";      S.QuestName="MagmaQuest";    S.QuestSlot=2; S.QuestCF=CFrame.new(-5313,10,8515);  S.FarmCF=CFrame.new(-5802,86,8828)
        elseif lv<400 then S.FarmMon="Fishman Warrior";   S.QuestName="FishmanQuest";  S.QuestSlot=1; S.QuestCF=CFrame.new(61122,18,1569);  S.FarmCF=CFrame.new(60878,18,1543); CommF("requestEntrance",Vector3.new(61163,11,1819))
        elseif lv<450 then S.FarmMon="Fishman Commando";  S.QuestName="FishmanQuest";  S.QuestSlot=2; S.QuestCF=CFrame.new(61122,18,1569);  S.FarmCF=CFrame.new(61922,18,1493); CommF("requestEntrance",Vector3.new(61163,11,1819))
        elseif lv<475 then S.FarmMon="God's Guard";       S.QuestName="SkyExp1Quest";  S.QuestSlot=1; S.QuestCF=CFrame.new(-4721,843,-1949);S.FarmCF=CFrame.new(-4710,845,-1927); CommF("requestEntrance",Vector3.new(-4607,872,-1667))
        elseif lv<525 then S.FarmMon="Shanda";            S.QuestName="SkyExp1Quest";  S.QuestSlot=2; S.QuestCF=CFrame.new(-7859,5544,-381);S.FarmCF=CFrame.new(-7678,5566,-497)
        elseif lv<550 then S.FarmMon="Royal Squad";       S.QuestName="SkyExp2Quest";  S.QuestSlot=1; S.QuestCF=CFrame.new(-7906,5634,-1411);S.FarmCF=CFrame.new(-7624,5658,-1467)
        elseif lv<625 then S.FarmMon="Royal Soldier";     S.QuestName="SkyExp2Quest";  S.QuestSlot=2; S.QuestCF=CFrame.new(-7906,5634,-1411);S.FarmCF=CFrame.new(-7836,5645,-1790)
        elseif lv<650 then S.FarmMon="Galley Pirate";     S.QuestName="FountainQuest"; S.QuestSlot=1; S.QuestCF=CFrame.new(5259,37,4050);   S.FarmCF=CFrame.new(5551,78,3930)
        else               S.FarmMon="Galley Captain";    S.QuestName="FountainQuest"; S.QuestSlot=2; S.QuestCF=CFrame.new(5259,37,4050);   S.FarmCF=CFrame.new(5441,42,4950)
        end
    elseif World2 then
        if     lv<725  then S.FarmMon="Raider";           S.QuestName="Area1Quest";        S.QuestSlot=1; S.QuestCF=CFrame.new(-429,71,1836);   S.FarmCF=CFrame.new(-728,52,2345)
        elseif lv<775  then S.FarmMon="Mercenary";        S.QuestName="Area1Quest";        S.QuestSlot=2; S.QuestCF=CFrame.new(-429,71,1836);   S.FarmCF=CFrame.new(-1004,80,1424)
        elseif lv<800  then S.FarmMon="Swan Pirate";      S.QuestName="Area2Quest";        S.QuestSlot=1; S.QuestCF=CFrame.new(638,71,918);     S.FarmCF=CFrame.new(1068,137,1322)
        elseif lv<875  then S.FarmMon="Factory Staff";    S.QuestName="Area2Quest";        S.QuestSlot=2; S.QuestCF=CFrame.new(632,73,918);     S.FarmCF=CFrame.new(73,81,-27)
        elseif lv<900  then S.FarmMon="Marine Lieutenant";S.QuestName="MarineQuest3";      S.QuestSlot=1; S.QuestCF=CFrame.new(-2440,71,-3216); S.FarmCF=CFrame.new(-2821,75,-3070)
        elseif lv<950  then S.FarmMon="Marine Captain";   S.QuestName="MarineQuest3";      S.QuestSlot=2; S.QuestCF=CFrame.new(-2440,71,-3216); S.FarmCF=CFrame.new(-1861,80,-3254)
        elseif lv<975  then S.FarmMon="Zombie";           S.QuestName="ZombieQuest";       S.QuestSlot=1; S.QuestCF=CFrame.new(-5497,47,-795);  S.FarmCF=CFrame.new(-5657,78,-928)
        elseif lv<1000 then S.FarmMon="Vampire";          S.QuestName="ZombieQuest";       S.QuestSlot=2; S.QuestCF=CFrame.new(-5497,47,-795);  S.FarmCF=CFrame.new(-6037,32,-1340)
        elseif lv<1050 then S.FarmMon="Snow Trooper";     S.QuestName="SnowMountainQuest"; S.QuestSlot=1; S.QuestCF=CFrame.new(609,400,-5372);  S.FarmCF=CFrame.new(549,427,-5563)
        elseif lv<1100 then S.FarmMon="Winter Warrior";   S.QuestName="SnowMountainQuest"; S.QuestSlot=2; S.QuestCF=CFrame.new(609,400,-5372);  S.FarmCF=CFrame.new(1142,475,-5199)
        elseif lv<1125 then S.FarmMon="Lab Subordinate";  S.QuestName="IceSideQuest";      S.QuestSlot=1; S.QuestCF=CFrame.new(-6064,15,-4902); S.FarmCF=CFrame.new(-5707,15,-4513)
        elseif lv<1175 then S.FarmMon="Horned Warrior";   S.QuestName="IceSideQuest";      S.QuestSlot=2; S.QuestCF=CFrame.new(-6064,15,-4902); S.FarmCF=CFrame.new(-6341,15,-5723)
        elseif lv<1200 then S.FarmMon="Magma Ninja";      S.QuestName="FireSideQuest";     S.QuestSlot=1; S.QuestCF=CFrame.new(-5428,15,-5299); S.FarmCF=CFrame.new(-5449,76,-5808)
        else               S.FarmMon="Lava Pirate";       S.QuestName="FireSideQuest";     S.QuestSlot=2; S.QuestCF=CFrame.new(-5428,15,-5299); S.FarmCF=CFrame.new(-4857,74,-5905)
        end
    elseif World3 then
        if     lv<1525 then S.FarmMon="Jungle Pirate";         S.QuestName="ForestQuest";  S.QuestSlot=1; S.QuestCF=CFrame.new(-12289,331,-10577); S.FarmCF=CFrame.new(-11778,426,-10592)
        elseif lv<1575 then S.FarmMon="Forest Pirate";         S.QuestName="ForestQuest";  S.QuestSlot=2; S.QuestCF=CFrame.new(-12289,331,-10577); S.FarmCF=CFrame.new(-13446,413,-7760)
        elseif lv<1625 then S.FarmMon="Mythological Pirate";   S.QuestName="MythQuest";    S.QuestSlot=1; S.QuestCF=CFrame.new(-13650,584,-6987);   S.FarmCF=CFrame.new(-13510,584,-6987)
        elseif lv<1675 then S.FarmMon="Musketeer Pirate";      S.QuestName="MythQuest";    S.QuestSlot=2; S.QuestCF=CFrame.new(-13650,584,-6987);   S.FarmCF=CFrame.new(-13282,496,-9565)
        elseif lv<1725 then S.FarmMon="Fishman Raider";        S.QuestName="FishDeepQuest";S.QuestSlot=1; S.QuestCF=CFrame.new(-10941,332,-8760);   S.FarmCF=CFrame.new(-10941,332,-8760)
        elseif lv<1800 then S.FarmMon="Fishman Captain";       S.QuestName="FishDeepQuest";S.QuestSlot=2; S.QuestCF=CFrame.new(-10941,332,-8760);   S.FarmCF=CFrame.new(-11035,332,-9087)
        elseif lv<1850 then S.FarmMon="Reborn Skeleton";       S.QuestName="WyperQuest";   S.QuestSlot=1; S.QuestCF=CFrame.new(-8764,142,5963);     S.FarmCF=CFrame.new(-8764,142,5963)
        elseif lv<1925 then S.FarmMon="Living Zombie";         S.QuestName="WyperQuest";   S.QuestSlot=2; S.QuestCF=CFrame.new(-8764,142,5963);     S.FarmCF=CFrame.new(-10227,421,6161)
        elseif lv<2025 then S.FarmMon="Peanut Scout";          S.QuestName="PeanutQuest";  S.QuestSlot=1; S.QuestCF=CFrame.new(-1993,187,-10103);   S.FarmCF=CFrame.new(-1993,187,-10103)
        elseif lv<2075 then S.FarmMon="Peanut President";      S.QuestName="PeanutQuest";  S.QuestSlot=2; S.QuestCF=CFrame.new(-1993,187,-10103);   S.FarmCF=CFrame.new(-2215,159,-10474)
        elseif lv<2125 then S.FarmMon="Ice Cream Chef";        S.QuestName="CakeQuest";    S.QuestSlot=1; S.QuestCF=CFrame.new(-877,118,-11032);    S.FarmCF=CFrame.new(-877,118,-11032)
        elseif lv<2175 then S.FarmMon="Ice Cream Commander";   S.QuestName="CakeQuest";    S.QuestSlot=2; S.QuestCF=CFrame.new(-877,118,-11032);    S.FarmCF=CFrame.new(-877,118,-11032)
        elseif lv<2225 then S.FarmMon="Cookie Crafter";        S.QuestName="CakeFarm1";    S.QuestSlot=1; S.QuestCF=CFrame.new(-2021,38,-12028);    S.FarmCF=CFrame.new(-2021,38,-12028)
        elseif lv<2275 then S.FarmMon="Cake Guard";            S.QuestName="CakeFarm1";    S.QuestSlot=2; S.QuestCF=CFrame.new(-2021,38,-12028);    S.FarmCF=CFrame.new(-2024,38,-12026)
        elseif lv<2350 then S.FarmMon="Baking Staff";          S.QuestName="CakeFarm2";    S.QuestSlot=1; S.QuestCF=CFrame.new(-1932,38,-12848);    S.FarmCF=CFrame.new(-1932,38,-12848)
        elseif lv<2450 then S.FarmMon="Head Baker";            S.QuestName="CakeFarm2";    S.QuestSlot=2; S.QuestCF=CFrame.new(-1932,38,-12848);    S.FarmCF=CFrame.new(-1932,38,-12848)
        elseif lv<2525 then S.FarmMon="Cocoa Warrior";         S.QuestName="CakeFarm3";    S.QuestSlot=1; S.QuestCF=CFrame.new(95,73,-12309);       S.FarmCF=CFrame.new(95,73,-12309)
        elseif lv<2625 then S.FarmMon="Chocolate Bar Battler"; S.QuestName="CakeFarm3";    S.QuestSlot=2; S.QuestCF=CFrame.new(95,73,-12309);       S.FarmCF=CFrame.new(647,42,-12401)
        else               S.FarmMon="Candy Rebel";            S.QuestName="CakeFarm4";    S.QuestSlot=2; S.QuestCF=CFrame.new(116,36,-12478);      S.FarmCF=CFrame.new(47,61,-12889)
        end
    else
        -- fallback se não detectou o mundo
        S.FarmMon="Bandit"; S.QuestName="BanditQuest1"; S.QuestSlot=1
        S.QuestCF=CFrame.new(1059,15,1550); S.FarmCF=CFrame.new(1045,27,1560)
    end
end
-- ╔══════════════════╗
-- ║   FARM LOGIC     ║
-- ╚══════════════════╝
local function HasQuest()
    -- check quest label visible OR quest progress bar exists
    local ok, v = pcall(function()
        local main = LP.PlayerGui:FindFirstChild("Main")
        if not main then return false end
        local q = main:FindFirstChild("Quest")
        return q and q.Visible
    end)
    return ok and v
end
local function AcceptQuest()
    if not S.QuestCF or not S.QuestName then return end
    -- 1. TP to quest NPC
    TP(S.QuestCF)
    task.wait(0.8)
    -- 2. Fire the real CommF_ remote (primary method)
    CommF("AskForQuest", S.QuestName, S.QuestSlot)
    task.wait(0.5)
    -- 3. Fallback: fire any quest proximity prompt nearby
    if not HasQuest() then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local t = (v.ActionText..v.ObjectText):lower()
                if t:find("quest") or t:find("miss") then
                    pcall(fireproximityprompt, v)
                    task.wait(0.3)
                    break
                end
            end
        end
    end
    task.wait(0.3)
end
local function FindMob(name)
    for _, m in ipairs(workspace.Enemies:GetChildren()) do
        if m.Name == name then
            local mh = m:FindFirstChildOfClass("Humanoid")
            local mr = m:FindFirstChild("HumanoidRootPart")
            if mh and mr and mh.Health > 0 then return m end
        end
    end
end
local function Attack(mob)
    if not mob then return end
    local mr = mob:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    -- TP BEM ALTO acima do mob — 60 studs, totalmente fora do alcance
    local above = mr.CFrame * CFrame.new(0, 60, 0)
    TP(above)
    task.wait(0.05)
    -- Aponta o mouse pro mob para o fighting style acertar
    Try(function()
        local cam = workspace.CurrentCamera
        local sp, onScreen = cam:WorldToScreenPoint(mr.Position)
        if onScreen then
            VIM:SendMouseMoveEvent(sp.X, sp.Y, game)
        end
    end)
    -- 5 cliques rápidos = fighting style puro, sem skills
    for i = 1, 5 do
        Click()
        task.wait(0.02)
    end
end
local function FarmLoop()
    return task.spawn(function()
        -- Quest timer separado — tenta aceitar a cada 8 segundos
        task.spawn(function()
            while S.AutoFarm do
                UpdateQuest()
                if S.QuestName then
                    TP(S.QuestCF)
                    task.wait(0.8)
                    -- Tenta via CommF_ direto
                    CommF("AskForQuest", S.QuestName, S.QuestSlot)
                    task.wait(0.5)
                    -- Tenta via ProximityPrompt como fallback
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") then
                            local t = (v.ActionText..v.ObjectText):lower()
                            if t:find("quest") or t:find("miss") or t:find("npc") then
                                pcall(fireproximityprompt, v)
                                task.wait(0.2)
                                break
                            end
                        end
                    end
                end
                task.wait(8)
            end
        end)
        -- Farm loop principal — SÓ mata mobs, sem parar pra quest
        while S.AutoFarm do
            Try(function()
                if not IsAlive() then task.wait(2) return end
                local mob = S.FarmMon and FindMob(S.FarmMon)
                if mob then
                    Attack(mob)
                elseif S.FarmCF then
                    TP(S.FarmCF)
                    task.wait(0.3)
                end
            end)
            task.wait(0.05)
        end
    end)
end
local function RaidLoop()
    return task.spawn(function()
        while S.AutoRaid do
            Try(function()
                if not IsAlive() then task.wait(2) return end
                -- TP raid NPC
                local npcCF = World1 and CFrame.new(897,15,1724)
                    or World2 and CFrame.new(-1588,52,-577)
                    or CFrame.new(5839,96,-1270)
                TP(npcCF)
                task.wait(1)
                CommF("StartRaid", MyLevel())
                task.wait(2)
                -- farm raid mobs 90s
                local t = tick()
                while tick()-t < 90 and S.AutoRaid do
                    if not IsAlive() then break end
                    local best, bd = nil, 400
                    local hrp = GetHRP()
                    if hrp then
                        for _, m in ipairs(workspace.Enemies:GetChildren()) do
                            local mh = m:FindFirstChildOfClass("Humanoid")
                            local mr = m:FindFirstChild("HumanoidRootPart")
                            if mh and mr and mh.Health > 0 then
                                local d = (mr.Position - hrp.Position).Magnitude
                                if d < bd then bd=d; best=m end
                            end
                        end
                    end
                    if best then Attack(best) end
                    task.wait(0.1)
                end
                task.wait(5)
            end)
        end
    end)
end
local function AntiAFKLoop()
    return task.spawn(function()
        while S.AntiAFK do
            task.wait(math.random(60,90))
            Try(function()
                VIM:SendMouseButtonEvent(0,0,0,true,game,1)
                VIM:SendMouseButtonEvent(0,0,0,false,game,1)
            end)
        end
    end)
end
-- ╔══════════════════╗
-- ║  TOGGLE HANDLER  ║
-- ╚══════════════════╝
local function Toggle(key, val, cb)
    S[key] = val
    if cb then
        cb.BackgroundColor3 = val and Color3.fromRGB(138,43,226) or Color3.fromRGB(30,30,40)
        cb.Text = val and "✓" or ""
    end
    Kill(key)
    if val then
        if key=="AutoFarm"  then Threads[key]=FarmLoop()
        elseif key=="AutoRaid"  then Threads[key]=RaidLoop()
        elseif key=="AntiAFK"  then Threads[key]=AntiAFKLoop()
        elseif key=="SpeedHack" then
            Try(function()
                local h=GetHum()
                if h then h.WalkSpeed=80; h.JumpPower=75 end
            end)
        end
    else
        if key=="SpeedHack" then
            Try(function()
                local h=GetHum()
                if h then h.WalkSpeed=16; h.JumpPower=50 end
            end)
        end
    end
end
-- Reapply speed on respawn
LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    if S.SpeedHack then
        local h = c:WaitForChild("Humanoid")
        h.WalkSpeed = 80; h.JumpPower = 75
    end
end)
-- ╔══════════════════╗
-- ║       GUI        ║
-- ╚══════════════════╝
-- remove old
local old = LP.PlayerGui:FindFirstChild("BH3")
if old then old:Destroy() end
local GUI = Instance.new("ScreenGui")
GUI.Name="BH3"; GUI.ResetOnSpawn=false
GUI.IgnoreGuiInset=true; GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
GUI.Parent=LP.PlayerGui
-- MAIN WINDOW
local Win = Instance.new("Frame")
Win.Name="Win"; Win.Size=UDim2.new(0,660,0,430)
Win.Position=UDim2.new(0.5,-330,0.5,-215)
Win.BackgroundColor3=Color3.fromRGB(10,10,18)
Win.BorderSizePixel=0; Win.Active=true; Win.Draggable=true
Win.ClipsDescendants=true; Win.Parent=GUI
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,12)
local ws=Instance.new("UIStroke",Win)
ws.Color=Color3.fromRGB(138,43,226); ws.Thickness=1.5
-- TOPBAR
local Top=Instance.new("Frame",Win)
Top.Size=UDim2.new(1,0,0,48); Top.BackgroundColor3=Color3.fromRGB(18,18,28)
Top.BorderSizePixel=0
local tg=Instance.new("UIGradient",Top)
tg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(90,20,160)),ColorSequenceKeypoint.new(1,Color3.fromRGB(18,18,28))})
tg.Rotation=90
local ttl=Instance.new("TextLabel",Top)
ttl.Text="  ⚡ Beast Hub : Blox Fruits"; ttl.Size=UDim2.new(1,-120,1,0)
ttl.BackgroundTransparency=1; ttl.TextColor3=Color3.fromRGB(200,140,255)
ttl.Font=Enum.Font.GothamBold; ttl.TextSize=15; ttl.TextXAlignment=Enum.TextXAlignment.Left
local function HBtn(txt,col,x)
    local b=Instance.new("TextButton",Top)
    b.Size=UDim2.new(0,36,0,26); b.Position=UDim2.new(1,x,0.5,-13)
    b.BackgroundColor3=col; b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=13; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
HBtn("✕",Color3.fromRGB(180,30,60),-42).MouseButton1Click:Connect(function() Win.Visible=not Win.Visible end)
local mini=false
HBtn("─",Color3.fromRGB(60,60,80),-84).MouseButton1Click:Connect(function()
    mini=not mini
    Win.Size=mini and UDim2.new(0,660,0,48) or UDim2.new(0,660,0,430)
end)
-- SIDEBAR
local Side=Instance.new("Frame",Win)
Side.Size=UDim2.new(0,170,1,-48); Side.Position=UDim2.new(0,0,0,48)
Side.BackgroundColor3=Color3.fromRGB(14,14,22); Side.BorderSizePixel=0
local SList=Instance.new("Frame",Side)
SList.Size=UDim2.new(1,0,1,-10); SList.Position=UDim2.new(0,0,0,10)
SList.BackgroundTransparency=1
local SLL=Instance.new("UIListLayout",SList)
SLL.Padding=UDim.new(0,3); SLL.SortOrder=Enum.SortOrder.LayoutOrder
local SLP=Instance.new("UIPadding",SList)
SLP.PaddingLeft=UDim.new(0,6); SLP.PaddingRight=UDim.new(0,6)
-- DIVIDER
local dv=Instance.new("Frame",Win)
dv.Size=UDim2.new(0,1,1,-48); dv.Position=UDim2.new(0,170,0,48)
dv.BackgroundColor3=Color3.fromRGB(80,30,140); dv.BorderSizePixel=0
-- CONTENT AREA
local CA=Instance.new("Frame",Win)
CA.Name="CA"; CA.Size=UDim2.new(1,-170,1,-72)
CA.Position=UDim2.new(0,170,0,48)
CA.BackgroundColor3=Color3.fromRGB(12,12,20); CA.BorderSizePixel=0
CA.ClipsDescendants=true
-- STATUS BAR
local SBar=Instance.new("Frame",Win)
SBar.Size=UDim2.new(1,-170,0,22); SBar.Position=UDim2.new(0,170,1,-22)
SBar.BackgroundColor3=Color3.fromRGB(8,8,14); SBar.BorderSizePixel=0
local SLbl=Instance.new("TextLabel",SBar)
SLbl.Size=UDim2.new(1,-6,1,0); SLbl.Position=UDim2.new(0,6,0,0)
SLbl.BackgroundTransparency=1; SLbl.TextColor3=Color3.fromRGB(120,100,170)
SLbl.Font=Enum.Font.Gotham; SLbl.TextSize=11; SLbl.TextXAlignment=Enum.TextXAlignment.Left
-- GUI helpers
local SBtns={} local Frames={} local CurSec="Farm"
local function MkScroll()
    local sf=Instance.new("ScrollingFrame",CA)
    sf.Size=UDim2.new(1,0,1,0); sf.BackgroundTransparency=1
    sf.BorderSizePixel=0; sf.ScrollBarThickness=4
    sf.ScrollBarImageColor3=Color3.fromRGB(138,43,226)
    sf.CanvasSize=UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.Visible=false; return sf
end
local function SecLbl(p,t,y)
    local l=Instance.new("TextLabel",p)
    l.Text=t; l.Size=UDim2.new(1,-20,0,30); l.Position=UDim2.new(0,10,0,y)
    l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(138,43,226)
    l.Font=Enum.Font.GothamBold; l.TextSize=14; l.TextXAlignment=Enum.TextXAlignment.Center
end
local function CkRow(p,lbl,key,y)
    local row=Instance.new("Frame",p)
    row.Size=UDim2.new(1,-16,0,44); row.Position=UDim2.new(0,8,0,y)
    row.BackgroundColor3=Color3.fromRGB(18,18,30); row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)
    row.MouseEnter:Connect(function() TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(26,18,44)}):Play() end)
    row.MouseLeave:Connect(function() TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(18,18,30)}):Play() end)
    local l=Instance.new("TextLabel",row)
    l.Text=lbl; l.Size=UDim2.new(1,-55,1,0); l.Position=UDim2.new(0,12,0,0)
    l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(215,215,230)
    l.Font=Enum.Font.Gotham; l.TextSize=14; l.TextXAlignment=Enum.TextXAlignment.Left
    local cb=Instance.new("TextButton",row)
    cb.Size=UDim2.new(0,22,0,22); cb.Position=UDim2.new(1,-34,0.5,-11)
    cb.BackgroundColor3=S[key] and Color3.fromRGB(138,43,226) or Color3.fromRGB(30,30,40)
    cb.Text=S[key] and "✓" or ""; cb.TextColor3=Color3.fromRGB(255,255,255)
    cb.Font=Enum.Font.GothamBold; cb.TextSize=13; cb.BorderSizePixel=0
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
    local cs=Instance.new("UIStroke",cb); cs.Color=Color3.fromRGB(100,50,180); cs.Thickness=1.5
    local function go() Toggle(key, not S[key], cb) end
    cb.MouseButton1Click:Connect(go)
    row.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then go() end end)
    return cb
end
-- SECTIONS
local FarmF=MkScroll()
SecLbl(FarmF,"Farm",6)
CkRow(FarmF,"Auto Farm Level","AutoFarm",42)
CkRow(FarmF,"Auto Raid","AutoRaid",92)
SecLbl(FarmF,"Extras",148)
CkRow(FarmF,"Speed Hack","SpeedHack",184)
CkRow(FarmF,"Anti AFK","AntiAFK",234)
Frames["Farm"]=FarmF
-- Status info inside farm tab
UpdateQuest()
local InfoLbl=Instance.new("TextLabel",FarmF)
InfoLbl.Size=UDim2.new(1,-16,0,36); InfoLbl.Position=UDim2.new(0,8,0,290)
InfoLbl.BackgroundColor3=Color3.fromRGB(16,16,28); InfoLbl.BorderSizePixel=0
InfoLbl.TextColor3=Color3.fromRGB(160,130,220); InfoLbl.Font=Enum.Font.Gotham
InfoLbl.TextSize=12; InfoLbl.TextWrapped=true
InfoLbl.Text="Level: "..MyLevel().." | Target: "..(S.FarmMon or "?")
Instance.new("UICorner",InfoLbl).CornerRadius=UDim.new(0,6)
-- MISC section
local MiscF=MkScroll()
SecLbl(MiscF,"Misc",6)
-- Low CPU btn
local lc=Instance.new("TextButton",MiscF)
lc.Size=UDim2.new(1,-16,0,40); lc.Position=UDim2.new(0,8,0,42)
lc.BackgroundColor3=Color3.fromRGB(60,20,110); lc.Text="⚡ Low CPU Mode"
lc.TextColor3=Color3.fromRGB(255,255,255); lc.Font=Enum.Font.GothamBold
lc.TextSize=13; lc.BorderSizePixel=0
Instance.new("UICorner",lc).CornerRadius=UDim.new(0,7)
lc.MouseButton1Click:Connect(function()
    Try(function()
        local lt=game:GetService("Lighting")
        lt.GlobalShadows=false; lt.FogEnd=9e9; lt.Brightness=0
        settings().Rendering.QualityLevel="Level01"
        for _,v in ipairs(game:GetDescendants()) do
            pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime=NumberRange.new(0)
                elseif v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled=false
                elseif v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then v.Enabled=false
                end
            end)
        end
    end)
    lc.BackgroundColor3=Color3.fromRGB(40,160,80)
    lc.Text="✓ Low CPU Active"
end)
Frames["Misc"]=MiscF
-- SHOW SECTION
local function ShowSec(name)
    CurSec=name
    for _,f in pairs(Frames) do f.Visible=false end
    if Frames[name] then Frames[name].Visible=true end
    for n,b in pairs(SBtns) do
        b.BackgroundColor3=n==name and Color3.fromRGB(35,15,60) or Color3.fromRGB(14,14,22)
        b.TextColor3=n==name and Color3.fromRGB(200,140,255) or Color3.fromRGB(180,180,200)
    end
end
-- SIDEBAR BUTTONS
for _,sec in ipairs({"Farm","Misc"}) do
    local b=Instance.new("TextButton",SList)
    b.Size=UDim2.new(1,0,0,36); b.BackgroundColor3=Color3.fromRGB(14,14,22)
    b.Text="  "..sec; b.TextColor3=Color3.fromRGB(180,180,200)
    b.Font=Enum.Font.Gotham; b.TextSize=13
    b.TextXAlignment=Enum.TextXAlignment.Left; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(function() ShowSec(sec) end)
    SBtns[sec]=b
end
-- KEYBIND: RightAlt toggle
UIS.InputBegan:Connect(function(i,gpe)
    if not gpe and i.KeyCode==Enum.KeyCode.RightAlt then
        Win.Visible=not Win.Visible
    end
end)
-- STATUS UPDATE
task.spawn(function()
    while true do
        Try(function()
            UpdateQuest()
            InfoLbl.Text="Level: "..MyLevel().." | Target: "..(S.FarmMon or "?").." | Quest: "..(S.QuestName or "?")
            local h=GetHum()
            SLbl.Text=string.format("HP: %s/%s | Farm: %s | Raid: %s | Speed: %s",
                h and math.floor(h.Health) or "?",
                h and math.floor(h.MaxHealth) or "?",
                S.AutoFarm and "ON" or "OFF",
                S.AutoRaid and "ON" or "OFF",
                S.SpeedHack and "ON" or "OFF"
            )
        end)
        task.wait(1)
    end
end)
ShowSec("Farm")
print("[BeastHub v3] ✅ Carregado! RightAlt = abrir/fechar")
