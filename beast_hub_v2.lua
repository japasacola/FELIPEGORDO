-- ============================================================
--  BEAST HUB v6 — BLOX FRUITS AUTO FARM
--  Baseado no padrao EXATO do script de referencia:
--  1. Data.QuestName == "" → TP pro NPC → CommF_ → fecha dialogo
--  2. Data.QuestName != "" → mata mob
-- ============================================================

local RS    = game:GetService("ReplicatedStorage")
local VIM   = game:GetService("VirtualInputManager")
local UIS   = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")

local LP    = game.Players.LocalPlayer
local Char  = LP.Character or LP.CharacterAdded:Wait()

-- ── WORLD ──
local World1 = game.PlaceId==2753915549 or game.PlaceId==85211729168715
local World2 = game.PlaceId==4442272183 or game.PlaceId==79091703265657
local World3 = game.PlaceId==7449423635 or game.PlaceId==100117331123089

-- ── ESTADO ──
local AutoFarm = false
local Threads  = {}

-- variáveis de quest (igual CheckQuest do script ref)
local Mon, NameQuest, LevelQuest, CFrameQuest, CFrameMon

-- ── UTEIS ──
local function Try(fn) pcall(fn) end
local function Char_()  return LP.Character end
local function HRP()    local c=Char_(); return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum()    local c=Char_(); return c and c:FindFirstChildOfClass("Humanoid") end
local function Alive()  local h=Hum(); return h and h.Health > 0 end
local function MyLv()
    local ok,v = pcall(function() return LP.Data.Level.Value end)
    return ok and tonumber(v) or 1
end

-- ── VERIFICAÇÃO DE QUEST (igual script ref: Quest.Visible) ──
-- Ref usa: if d.PlayerGui.Main.Quest.Visible == false → sem quest
local function QuestVazia()
    local ok, v = pcall(function()
        return LP.PlayerGui.Main.Quest.Visible
    end)
    -- se Quest.Visible == false → sem quest ativa
    if ok then return not v end
    -- fallback: Data.QuestName
    local ok2, v2 = pcall(function() return LP.Data.QuestName.Value end)
    return (not ok2) or (v2 == nil) or (v2 == "")
end

-- ── FECHAR DIALOGO (igual DropFruits do script ref) ──
local function FecharDialogo()
    Try(function()
        if LP.PlayerGui.Main.Dialogue.Visible == true then
            LP.PlayerGui.Main.Dialogue.Visible = false
        end
    end)
end

-- ── TELEPORTE DIRETO ──
local function TP(cf)
    Try(function()
        local hrp = HRP()
        if hrp then hrp.CFrame = cf end
    end)
end

-- ── FLOAT (BodyVelocity no eixo Y) ──
local function Float(on)
    Try(function()
        local hrp = HRP()
        if not hrp then return end
        local bv = hrp:FindFirstChild("BH_Float")
        if on then
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name     = "BH_Float"
                bv.Velocity  = Vector3.new(0,0,0)
                bv.MaxForce  = Vector3.new(0,1e5,0)
                bv.P         = 1e4
                bv.Parent    = hrp
            end
        else
            if bv then bv:Destroy() end
        end
    end)
end

-- ── CLIQUE (fighting style sem skills) ──
local function Click()
    Try(function()
        VIM:SendMouseButtonEvent(0,0,0,true, game,1)
        VIM:SendMouseButtonEvent(0,0,0,false,game,1)
    end)
end

-- ── CommF_ ──
local function CommF(...)
    local a={...}
    pcall(function() RS.Remotes.CommF_:InvokeServer(table.unpack(a)) end)
end

-- ── KILL THREAD ──
local function KillThread(k)
    if Threads[k] then pcall(task.cancel,Threads[k]); Threads[k]=nil end
end

-- ╔══════════════════════════════════════════════╗
-- ║   CheckQuest — idêntico ao script referência ║
-- ╚══════════════════════════════════════════════╝
local function CheckQuest()
    local lv = MyLv()
    if World1 then
        if     lv<=9   then Mon="Bandit";              NameQuest="BanditQuest1";  LevelQuest=1; CFrameQuest=CFrame.new(1059.37195,15.4495068,1550.4231,.939700544,0,-.341998369,0,1,0,.341998369,0,.939700544); CFrameMon=CFrame.new(1045.9626,27.0025,1560.8203)
        elseif lv<=14  then Mon="Monkey";              NameQuest="JungleQuest";   LevelQuest=1; CFrameQuest=CFrame.new(-1598.08911,35.5501175,153.377838,0,0,1,0,1,0,-1,0,0); CFrameMon=CFrame.new(-1448.518,67.853,11.465)
        elseif lv<=29  then Mon="Gorilla";             NameQuest="JungleQuest";   LevelQuest=2; CFrameQuest=CFrame.new(-1598.08911,35.5501175,153.377838,0,0,1,0,1,0,-1,0,0); CFrameMon=CFrame.new(-1129.883,40.463,-525.423)
        elseif lv<=39  then Mon="Pirate";              NameQuest="BuggyQuest1";   LevelQuest=1; CFrameQuest=CFrame.new(-1141.07483,4.10001802,3831.5498,.965929627,0,-.258804798,0,1,0,.258804798,0,.965929627); CFrameMon=CFrame.new(-1103.513,13.752,3896.091)
        elseif lv<=59  then Mon="Brute";               NameQuest="BuggyQuest1";   LevelQuest=2; CFrameQuest=CFrame.new(-1141.07483,4.10001802,3831.5498,.965929627,0,-.258804798,0,1,0,.258804798,0,.965929627); CFrameMon=CFrame.new(-1140.083,14.809,4322.921)
        elseif lv<=74  then Mon="Desert Bandit";       NameQuest="DesertQuest";   LevelQuest=1; CFrameQuest=CFrame.new(894.488647,5.14000702,4392.43359,.819155693,0,-.573571265,0,1,0,.573571265,0,.819155693); CFrameMon=CFrame.new(924.799,6.448,4481.585)
        elseif lv<=89  then Mon="Desert Officer";      NameQuest="DesertQuest";   LevelQuest=2; CFrameQuest=CFrame.new(894.488647,5.14000702,4392.43359,.819155693,0,-.573571265,0,1,0,.573571265,0,.819155693); CFrameMon=CFrame.new(1608.282,8.614,4371.007)
        elseif lv<=99  then Mon="Snow Bandit";         NameQuest="SnowQuest";     LevelQuest=1; CFrameQuest=CFrame.new(1389.74451,88.1519318,-1298.90796,-.342042685,0,.939684391,0,1,0,-.939684391,0,-.342042685); CFrameMon=CFrame.new(1354.347,87.272,-1393.946)
        elseif lv<=119 then Mon="Snowman";             NameQuest="SnowQuest";     LevelQuest=2; CFrameQuest=CFrame.new(1389.74451,88.1519318,-1298.90796,-.342042685,0,.939684391,0,1,0,-.939684391,0,-.342042685); CFrameMon=CFrame.new(1201.641,144.579,-1550.067)
        elseif lv<=149 then Mon="Chief Petty Officer"; NameQuest="MarineQuest2";  LevelQuest=1; CFrameQuest=CFrame.new(-5039.58643,27.3500385,4324.68018,0,0,-1,0,1,0,1,0,0); CFrameMon=CFrame.new(-4881.230,22.652,4273.752)
        elseif lv<=174 then Mon="Sky Bandit";          NameQuest="SkyQuest";      LevelQuest=1; CFrameQuest=CFrame.new(-4839.53027,716.368591,-2619.44165,.866007268,0,.500031412,0,1,0,-.500031412,0,.866007268); CFrameMon=CFrame.new(-4953.207,295.744,-2899.229)
        elseif lv<=189 then Mon="Dark Master";         NameQuest="SkyQuest";      LevelQuest=2; CFrameQuest=CFrame.new(-4839.53027,716.368591,-2619.44165,.866007268,0,.500031412,0,1,0,-.500031412,0,.866007268); CFrameMon=CFrame.new(-5259.844,391.397,-2229.035)
        elseif lv<=209 then Mon="Prisoner";            NameQuest="PrisonerQuest"; LevelQuest=1; CFrameQuest=CFrame.new(5308.93115,1.65517521,475.120514,-.0894274712,-5e-09,-.995993316,1.6e-09,1,-5.16e-09,.995993316,-2e-09,-.0894274712); CFrameMon=CFrame.new(5098.973,-0.320,474.237)
        elseif lv<=249 then Mon="Dangerous Prisoner";  NameQuest="PrisonerQuest"; LevelQuest=2; CFrameQuest=CFrame.new(5308.93115,1.65517521,475.120514,-.0894274712,-5e-09,-.995993316,1.6e-09,1,-5.16e-09,.995993316,-2e-09,-.0894274712); CFrameMon=CFrame.new(5654.563,15.633,866.299)
        elseif lv<=274 then Mon="Toga Warrior";        NameQuest="ColosseumQuest";LevelQuest=1; CFrameQuest=CFrame.new(-1580.04663,6.35000277,-2986.47534,-.515037298,0,-.857167721,0,1,0,.857167721,0,-.515037298); CFrameMon=CFrame.new(-1820.214,51.683,-2740.665)
        elseif lv<=299 then Mon="Gladiator";           NameQuest="ColosseumQuest";LevelQuest=2; CFrameQuest=CFrame.new(-1580.04663,6.35000277,-2986.47534,-.515037298,0,-.857167721,0,1,0,.857167721,0,-.515037298); CFrameMon=CFrame.new(-1292.838,56.380,-3339.031)
        elseif lv<=324 then Mon="Military Soldier";    NameQuest="MagmaQuest";    LevelQuest=1; CFrameQuest=CFrame.new(-5313.37012,10.9500084,8515.29395,-.499959469,0,.866048813,0,1,0,-.866048813,0,-.499959469); CFrameMon=CFrame.new(-5411.164,11.081,8454.292)
        elseif lv<=374 then Mon="Military Spy";        NameQuest="MagmaQuest";    LevelQuest=2; CFrameQuest=CFrame.new(-5313.37012,10.9500084,8515.29395,-.499959469,0,.866048813,0,1,0,-.866048813,0,-.499959469); CFrameMon=CFrame.new(-5802.868,86.262,8828.859)
        elseif lv<=399 then Mon="Fishman Warrior";     NameQuest="FishmanQuest";  LevelQuest=1; CFrameQuest=CFrame.new(61122.652,18.497,1569.399); CFrameMon=CFrame.new(60878.300,18.482,1543.757); CommF("requestEntrance",Vector3.new(61163,11,1819))
        elseif lv<=449 then Mon="Fishman Commando";    NameQuest="FishmanQuest";  LevelQuest=2; CFrameQuest=CFrame.new(61122.652,18.497,1569.399); CFrameMon=CFrame.new(61922.632,18.482,1493.934); CommF("requestEntrance",Vector3.new(61163,11,1819))
        elseif lv<=474 then Mon="God's Guard";         NameQuest="SkyExp1Quest";  LevelQuest=1; CFrameQuest=CFrame.new(-4721.88867,843.874695,-1949.96643,.996191859,0,-.0871884301,0,1,0,.0871884301,0,.996191859); CFrameMon=CFrame.new(-4710.042,845.276,-1927.307); CommF("requestEntrance",Vector3.new(-4607,872,-1667))
        elseif lv<=524 then Mon="Shanda";              NameQuest="SkyExp1Quest";  LevelQuest=2; CFrameQuest=CFrame.new(-7859.09814,5544.19043,-381.476196,-.422592998,0,.906319618,0,1,0,-.906319618,0,-.422592998); CFrameMon=CFrame.new(-7678.489,5566.403,-497.215)
        elseif lv<=549 then Mon="Royal Squad";         NameQuest="SkyExp2Quest";  LevelQuest=1; CFrameQuest=CFrame.new(-7906.81592,5634.6626,-1411.99194,0,0,-1,0,1,0,1,0,0); CFrameMon=CFrame.new(-7624.252,5658.133,-1467.354)
        elseif lv<=624 then Mon="Royal Soldier";       NameQuest="SkyExp2Quest";  LevelQuest=2; CFrameQuest=CFrame.new(-7906.81592,5634.6626,-1411.99194,0,0,-1,0,1,0,1,0,0); CFrameMon=CFrame.new(-7836.753,5645.664,-1790.623)
        elseif lv<=649 then Mon="Galley Pirate";       NameQuest="FountainQuest"; LevelQuest=1; CFrameQuest=CFrame.new(5259.81982,37.3500175,4050.0293,.087131381,0,.996196866,0,1,0,-.996196866,0,.087131381); CFrameMon=CFrame.new(5551.021,78.901,3930.412)
        else               Mon="Galley Captain";       NameQuest="FountainQuest"; LevelQuest=2; CFrameQuest=CFrame.new(5259.81982,37.3500175,4050.0293,.087131381,0,.996196866,0,1,0,-.996196866,0,.087131381); CFrameMon=CFrame.new(5441.951,42.502,4950.093)
        end
    elseif World2 then
        if     lv<=724  then Mon="Raider";             NameQuest="Area1Quest";        LevelQuest=1; CFrameQuest=CFrame.new(-429.543518,71.7699966,1836.18188,-.22495985,0,-.974368095,0,1,0,.974368095,0,-.22495985); CFrameMon=CFrame.new(-728.326,52.779,2345.770)
        elseif lv<=774  then Mon="Mercenary";          NameQuest="Area1Quest";        LevelQuest=2; CFrameQuest=CFrame.new(-429.543518,71.7699966,1836.18188,-.22495985,0,-.974368095,0,1,0,.974368095,0,-.22495985); CFrameMon=CFrame.new(-1004.324,80.158,1424.619)
        elseif lv<=799  then Mon="Swan Pirate";        NameQuest="Area2Quest";        LevelQuest=1; CFrameQuest=CFrame.new(638.43811,71.769989,918.282898,.139203906,0,.99026376,0,1,0,-.99026376,0,.139203906); CFrameMon=CFrame.new(1068.664,137.614,1322.106)
        elseif lv<=874  then Mon="Factory Staff";      NameQuest="Area2Quest";        LevelQuest=2; CFrameQuest=CFrame.new(632.698608,73.1055908,918.666321,-.0319722369,8.96e-10,-.999488771,1.36e-10,1,8.92e-10,.999488771,-1.07e-10,-.0319722369); CFrameMon=CFrame.new(73.078,81.863,-27.470)
        elseif lv<=899  then Mon="Marine Lieutenant";  NameQuest="MarineQuest3";      LevelQuest=1; CFrameQuest=CFrame.new(-2440.79639,71.7140732,-3216.06812,.866007268,0,.500031412,0,1,0,-.500031412,0,.866007268); CFrameMon=CFrame.new(-2821.372,75.897,-3070.089)
        elseif lv<=949  then Mon="Marine Captain";     NameQuest="MarineQuest3";      LevelQuest=2; CFrameQuest=CFrame.new(-2440.79639,71.7140732,-3216.06812,.866007268,0,.500031412,0,1,0,-.500031412,0,.866007268); CFrameMon=CFrame.new(-1861.231,80.176,-3254.697)
        elseif lv<=974  then Mon="Zombie";             NameQuest="ZombieQuest";       LevelQuest=1; CFrameQuest=CFrame.new(-5497.06152,47.5923004,-795.237061,-.29242146,0,-.95628953,0,1,0,.95628953,0,-.29242146); CFrameMon=CFrame.new(-5657.776,78.969,-928.687)
        elseif lv<=999  then Mon="Vampire";            NameQuest="ZombieQuest";       LevelQuest=2; CFrameQuest=CFrame.new(-5497.06152,47.5923004,-795.237061,-.29242146,0,-.95628953,0,1,0,.95628953,0,-.29242146); CFrameMon=CFrame.new(-6037.667,32.184,-1340.659)
        elseif lv<=1049 then Mon="Snow Trooper";       NameQuest="SnowMountainQuest"; LevelQuest=1; CFrameQuest=CFrame.new(609.858826,400.119904,-5372.25928,-.374604106,0,.92718488,0,1,0,-.92718488,0,-.374604106); CFrameMon=CFrame.new(549.147,427.387,-5563.698)
        elseif lv<=1099 then Mon="Winter Warrior";     NameQuest="SnowMountainQuest"; LevelQuest=2; CFrameQuest=CFrame.new(609.858826,400.119904,-5372.25928,-.374604106,0,.92718488,0,1,0,-.92718488,0,-.374604106); CFrameMon=CFrame.new(1142.745,475.639,-5199.416)
        elseif lv<=1124 then Mon="Lab Subordinate";    NameQuest="IceSideQuest";      LevelQuest=1; CFrameQuest=CFrame.new(-6064.06885,15.2422857,-4902.97852,.453972578,0,-.891015649,0,1,0,.891015649,0,.453972578); CFrameMon=CFrame.new(-5707.471,15.951,-4513.392)
        elseif lv<=1174 then Mon="Horned Warrior";     NameQuest="IceSideQuest";      LevelQuest=2; CFrameQuest=CFrame.new(-6064.06885,15.2422857,-4902.97852,.453972578,0,-.891015649,0,1,0,.891015649,0,.453972578); CFrameMon=CFrame.new(-6341.366,15.951,-5723.162)
        elseif lv<=1199 then Mon="Magma Ninja";        NameQuest="FireSideQuest";     LevelQuest=1; CFrameQuest=CFrame.new(-5428.03174,15.0622921,-5299.43457,-.882952213,0,.469463557,0,1,0,-.469463557,0,-.882952213); CFrameMon=CFrame.new(-5449.672,76.658,-5808.200)
        else               Mon="Lava Pirate";          NameQuest="FireSideQuest";     LevelQuest=2; CFrameQuest=CFrame.new(-5428.03174,15.0622921,-5299.43457,-.882952213,0,.469463557,0,1,0,-.469463557,0,-.882952213); CFrameMon=CFrame.new(-4857.562,74.651,-5905.487)
        end
    elseif World3 then
        if     lv<=1524 then Mon="Jungle Pirate";          NameQuest="ForestQuest";   LevelQuest=1; CFrameQuest=CFrame.new(-12289,331,-10577); CFrameMon=CFrame.new(-11778,426,-10592)
        elseif lv<=1574 then Mon="Forest Pirate";          NameQuest="ForestQuest";   LevelQuest=2; CFrameQuest=CFrame.new(-12289,331,-10577); CFrameMon=CFrame.new(-13446,413,-7760)
        elseif lv<=1624 then Mon="Mythological Pirate";    NameQuest="MythQuest";     LevelQuest=1; CFrameQuest=CFrame.new(-13650,584,-6987); CFrameMon=CFrame.new(-13510,584,-6987)
        elseif lv<=1674 then Mon="Musketeer Pirate";       NameQuest="MythQuest";     LevelQuest=2; CFrameQuest=CFrame.new(-13650,584,-6987); CFrameMon=CFrame.new(-13282,496,-9565)
        elseif lv<=1724 then Mon="Fishman Raider";         NameQuest="FishDeepQuest"; LevelQuest=1; CFrameQuest=CFrame.new(-10941,332,-8760); CFrameMon=CFrame.new(-10941,332,-8760)
        elseif lv<=1799 then Mon="Fishman Captain";        NameQuest="FishDeepQuest"; LevelQuest=2; CFrameQuest=CFrame.new(-10941,332,-8760); CFrameMon=CFrame.new(-11035,332,-9087)
        elseif lv<=1849 then Mon="Reborn Skeleton";        NameQuest="WyperQuest";    LevelQuest=1; CFrameQuest=CFrame.new(-8764,142,5963); CFrameMon=CFrame.new(-8764,142,5963)
        elseif lv<=1924 then Mon="Living Zombie";          NameQuest="WyperQuest";    LevelQuest=2; CFrameQuest=CFrame.new(-8764,142,5963); CFrameMon=CFrame.new(-10227,421,6161)
        elseif lv<=2024 then Mon="Peanut Scout";           NameQuest="PeanutQuest";   LevelQuest=1; CFrameQuest=CFrame.new(-1993,187,-10103); CFrameMon=CFrame.new(-1993,187,-10103)
        elseif lv<=2074 then Mon="Peanut President";       NameQuest="PeanutQuest";   LevelQuest=2; CFrameQuest=CFrame.new(-1993,187,-10103); CFrameMon=CFrame.new(-2215,159,-10474)
        elseif lv<=2124 then Mon="Ice Cream Chef";         NameQuest="CakeQuest";     LevelQuest=1; CFrameQuest=CFrame.new(-877,118,-11032); CFrameMon=CFrame.new(-877,118,-11032)
        elseif lv<=2174 then Mon="Ice Cream Commander";    NameQuest="CakeQuest";     LevelQuest=2; CFrameQuest=CFrame.new(-877,118,-11032); CFrameMon=CFrame.new(-877,118,-11032)
        elseif lv<=2224 then Mon="Cookie Crafter";         NameQuest="CakeFarm1";     LevelQuest=1; CFrameQuest=CFrame.new(-2021,38,-12028); CFrameMon=CFrame.new(-2021,38,-12028)
        elseif lv<=2274 then Mon="Cake Guard";             NameQuest="CakeFarm1";     LevelQuest=2; CFrameQuest=CFrame.new(-2021,38,-12028); CFrameMon=CFrame.new(-2024,38,-12026)
        elseif lv<=2349 then Mon="Baking Staff";           NameQuest="CakeFarm2";     LevelQuest=1; CFrameQuest=CFrame.new(-1932,38,-12848); CFrameMon=CFrame.new(-1932,38,-12848)
        elseif lv<=2449 then Mon="Head Baker";             NameQuest="CakeFarm2";     LevelQuest=2; CFrameQuest=CFrame.new(-1932,38,-12848); CFrameMon=CFrame.new(-1932,38,-12848)
        elseif lv<=2524 then Mon="Cocoa Warrior";          NameQuest="CakeFarm3";     LevelQuest=1; CFrameQuest=CFrame.new(95,73,-12309); CFrameMon=CFrame.new(95,73,-12309)
        elseif lv<=2624 then Mon="Chocolate Bar Battler";  NameQuest="CakeFarm3";     LevelQuest=2; CFrameQuest=CFrame.new(95,73,-12309); CFrameMon=CFrame.new(647,42,-12401)
        else               Mon="Candy Rebel";              NameQuest="CakeFarm4";     LevelQuest=2; CFrameQuest=CFrame.new(116,36,-12478); CFrameMon=CFrame.new(47,61,-12889)
        end
    else
        -- world nao detectado → bandit fallback
        Mon="Bandit"; NameQuest="BanditQuest1"; LevelQuest=1
        CFrameQuest=CFrame.new(1059,15,1550); CFrameMon=CFrame.new(1045,27,1560)
    end
end

-- ── ACHAR MOB (igual GetConnectionEnemies do script ref) ──
-- Procura em workspace.Enemies E em ReplicatedStorage
local function FindMob(nome)
    -- workspace.Enemies (padrão)
    for _, m in ipairs(workspace.Enemies:GetChildren()) do
        if m.Name == nome then
            local mh = m:FindFirstChildOfClass("Humanoid")
            local mr = m:FindFirstChild("HumanoidRootPart")
            if mh and mr and mh.Health > 0 then return m end
        end
    end
    -- ReplicatedStorage (mobs especiais)
    for _, m in ipairs(game:GetService("ReplicatedStorage"):GetChildren()) do
        if m:IsA("Model") and m.Name == nome then
            local mh = m:FindFirstChildOfClass("Humanoid")
            local mr = m:FindFirstChild("HumanoidRootPart")
            if mh and mr and mh.Health > 0 then return m end
        end
    end
end

-- ── ATACAR DO AR ──
local function Atacar(mob)
    if not mob then return end
    local mr = mob:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    -- 55 studs acima
    TP(mr.CFrame * CFrame.new(0,55,0))
    task.wait(0.04)
    Float(true)
    -- aponta mouse pro mob
    Try(function()
        local cam = workspace.CurrentCamera
        local sp,vis = cam:WorldToScreenPoint(mr.Position)
        if vis then VIM:SendMouseMoveEvent(sp.X,sp.Y,game) end
    end)
    -- 6 cliques = fighting style
    for i=1,6 do Click(); task.wait(0.02) end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║   FARM LOOP — padrão EXATO do script de referência      ║
-- ║                                                          ║
-- ║   while farm:                                            ║
-- ║     CheckQuest()   → define Mon, NameQuest, CFrames     ║
-- ║     QuestVazia()?  → TP NPC → CommF_ → fecha dialogo    ║
-- ║     Tem quest?     → FindMob → Atacar (55 studs ar)     ║
-- ╚══════════════════════════════════════════════════════════╝
local function StartFarm()
    KillThread("farm")
    Threads["farm"] = task.spawn(function()
        Float(true)
        while AutoFarm do
            Try(function()
                if not Alive() then
                    Float(false)
                    task.wait(3)
                    Float(true)
                    return
                end

                CheckQuest()

                if QuestVazia() then
                    -- ═══ SEM QUEST: vai ao NPC e pega ═══
                    Float(false)
                    TP(CFrameQuest)
                    task.wait(0.8)
                    CommF("AskForQuest", NameQuest, LevelQuest)
                    task.wait(0.4)
                    FecharDialogo()
                    task.wait(0.4)
                    Float(true)

                    -- TIMEOUT: espera quest aparecer (max 3s)
                    -- Se não aparecer, vai farmar mesmo assim
                    local t0 = tick()
                    while QuestVazia() and (tick()-t0) < 3 and AutoFarm do
                        task.wait(0.2)
                    end
                else
                    -- ═══ TEM QUEST: mata mob ═══
                    local mob = Mon and FindMob(Mon)
                    if mob then
                        Atacar(mob)
                    else
                        TP(CFrameMon)
                        task.wait(0.3)
                    end
                end
            end)
            task.wait(0.05)
        end
        Float(false)
    end)
end

local function StopFarm()
    KillThread("farm")
    Float(false)
end

-- respawn
LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    if AutoFarm then Float(true) end
end)

-- ╔══════════════════════════════╗
-- ║         GUI                  ║
-- ╚══════════════════════════════╝
pcall(function() LP.PlayerGui:FindFirstChild("BH6"):Destroy() end)

local GUI=Instance.new("ScreenGui")
GUI.Name="BH6"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; GUI.Parent=LP.PlayerGui

local Win=Instance.new("Frame",GUI)
Win.Name="Win"; Win.Size=UDim2.new(0,460,0,300)
Win.Position=UDim2.new(0.5,-230,0.5,-150)
Win.BackgroundColor3=Color3.fromRGB(8,8,16)
Win.BorderSizePixel=0; Win.Active=true; Win.Draggable=true
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,12)
local ws=Instance.new("UIStroke",Win)
ws.Color=Color3.fromRGB(120,40,200); ws.Thickness=1.5

-- topbar
local Top=Instance.new("Frame",Win)
Top.Size=UDim2.new(1,0,0,44); Top.BackgroundColor3=Color3.fromRGB(16,16,26)
Top.BorderSizePixel=0
local tg=Instance.new("UIGradient",Top)
tg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(80,20,160)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(16,16,26))
}); tg.Rotation=90

local ttl=Instance.new("TextLabel",Top)
ttl.Text="  ⚡ Beast Hub v6"; ttl.Size=UDim2.new(1,-80,1,0)
ttl.BackgroundTransparency=1; ttl.TextColor3=Color3.fromRGB(180,120,255)
ttl.Font=Enum.Font.GothamBold; ttl.TextSize=14; ttl.TextXAlignment=Enum.TextXAlignment.Left

local function Btn(txt,col,x)
    local b=Instance.new("TextButton",Top)
    b.Size=UDim2.new(0,30,0,22); b.Position=UDim2.new(1,x,0.5,-11)
    b.BackgroundColor3=col; b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=12; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4); return b
end
Btn("✕",Color3.fromRGB(160,30,60),-36).MouseButton1Click:Connect(function() Win.Visible=not Win.Visible end)
local mini=false
Btn("─",Color3.fromRGB(40,40,60),-72).MouseButton1Click:Connect(function()
    mini=not mini
    Win.Size=mini and UDim2.new(0,460,0,44) or UDim2.new(0,460,0,300)
end)

-- rows
local CA=Instance.new("ScrollingFrame",Win)
CA.Size=UDim2.new(1,0,1,-64); CA.Position=UDim2.new(0,0,0,44)
CA.BackgroundTransparency=1; CA.BorderSizePixel=0
CA.ScrollBarThickness=4; CA.ScrollBarImageColor3=Color3.fromRGB(120,40,200)
CA.CanvasSize=UDim2.new(0,0,0,0); CA.AutomaticCanvasSize=Enum.AutomaticSize.Y
local CAL=Instance.new("UIListLayout",CA); CAL.Padding=UDim.new(0,6)
CAL.SortOrder=Enum.SortOrder.LayoutOrder; CAL.HorizontalAlignment=Enum.HorizontalAlignment.Center
local CAP=Instance.new("UIPadding",CA)
CAP.PaddingTop=UDim.new(0,8); CAP.PaddingLeft=UDim.new(0,10); CAP.PaddingRight=UDim.new(0,10)

local function Row(lbl, onFn, offFn)
    local row=Instance.new("Frame",CA)
    row.Size=UDim2.new(1,0,0,46); row.BackgroundColor3=Color3.fromRGB(16,16,28)
    row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)

    local l=Instance.new("TextLabel",row)
    l.Text=lbl; l.Size=UDim2.new(1,-56,1,0); l.Position=UDim2.new(0,12,0,0)
    l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(210,210,230)
    l.Font=Enum.Font.Gotham; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left

    local state=false
    local cb=Instance.new("TextButton",row)
    cb.Size=UDim2.new(0,22,0,22); cb.Position=UDim2.new(1,-34,0.5,-11)
    cb.BackgroundColor3=Color3.fromRGB(28,28,40); cb.Text=""
    cb.TextColor3=Color3.fromRGB(255,255,255); cb.Font=Enum.Font.GothamBold
    cb.TextSize=12; cb.BorderSizePixel=0
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
    Instance.new("UIStroke",cb).Color=Color3.fromRGB(80,40,160)

    local function toggle()
        state=not state
        cb.BackgroundColor3=state and Color3.fromRGB(120,40,200) or Color3.fromRGB(28,28,40)
        cb.Text=state and "✓" or ""
        if state then onFn() else offFn() end
    end
    cb.MouseButton1Click:Connect(toggle)
    row.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then toggle() end
    end)
end

Row("🌾  Auto Farm Level", function()
    AutoFarm=true; StartFarm()
end, function()
    AutoFarm=false; StopFarm()
end)

Row("⚡  Speed Hack", function()
    Try(function() local h=Hum(); if h then h.WalkSpeed=80; h.JumpPower=75 end end)
end, function()
    Try(function() local h=Hum(); if h then h.WalkSpeed=16; h.JumpPower=50 end end)
end)

Row("🛡️  Anti AFK", function()
    KillThread("afk")
    Threads["afk"]=task.spawn(function()
        while true do
            task.wait(math.random(60,90))
            Click()
        end
    end)
end, function()
    KillThread("afk")
end)

-- info + status
local Info=Instance.new("TextLabel",CA)
Info.Size=UDim2.new(1,0,0,36); Info.BackgroundColor3=Color3.fromRGB(12,12,22)
Info.BorderSizePixel=0; Info.TextColor3=Color3.fromRGB(140,110,200)
Info.Font=Enum.Font.Gotham; Info.TextSize=11; Info.TextWrapped=true
Info.TextXAlignment=Enum.TextXAlignment.Left
Instance.new("UICorner",Info).CornerRadius=UDim.new(0,6)
local IP=Instance.new("UIPadding",Info); IP.PaddingLeft=UDim.new(0,8); IP.PaddingTop=UDim.new(0,4)

local SBar=Instance.new("Frame",Win)
SBar.Size=UDim2.new(1,0,0,20); SBar.Position=UDim2.new(0,0,1,-20)
SBar.BackgroundColor3=Color3.fromRGB(6,6,12); SBar.BorderSizePixel=0
local SLb=Instance.new("TextLabel",SBar)
SLb.Size=UDim2.new(1,-8,1,0); SLb.Position=UDim2.new(0,6,0,0)
SLb.BackgroundTransparency=1; SLb.TextColor3=Color3.fromRGB(80,60,130)
SLb.Font=Enum.Font.Gotham; SLb.TextSize=10; SLb.TextXAlignment=Enum.TextXAlignment.Left

UIS.InputBegan:Connect(function(i,g)
    if not g and i.KeyCode==Enum.KeyCode.RightAlt then
        Win.Visible=not Win.Visible
    end
end)

task.spawn(function()
    while true do
        Try(function()
            CheckQuest()
            local h=Hum()
            local qname=""
            pcall(function() qname=LP.Data.QuestName.Value end)
            Info.Text=string.format("  Lv %s | Mob: %s | Quest: %s",
                MyLv(), Mon or "?",
                qname=="" and "⏳ Pegando..." or ("✅ "..qname))
            SLb.Text=string.format("HP:%s | Farm:%s | RightAlt=menu",
                h and math.floor(h.Health) or "?",
                AutoFarm and "ON" or "OFF")
        end)
        task.wait(1)
    end
end)

print("[BeastHub v6] Loaded! RightAlt = menu | Quest: Data.QuestName pattern 🔥")
