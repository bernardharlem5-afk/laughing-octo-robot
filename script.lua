-- =====================================================================
-- PHANTOM DUELS LOADER  |  https://discord.gg/KcEqqvn5fd
-- Takes your Clover Duels script and rebrands it to Phantom Duels
-- before running it (names, title, discord, logo on the buttons).
--
-- SETUP
--   1. Save your Clover script in your executor's workspace folder
--      as  Clover.lua   (or change SOURCE_FILE below), OR set
--      SOURCE_URL to a link that returns the raw script.
--   2. Upload your PD logo to Roblox as a Decal/Image and paste the
--      number into LOGO_ID. Leave it "" to run without the logo.
--   3. Run this file.
-- =====================================================================

local SOURCE_FILE = "Clover.lua"
local SOURCE_URL = ""            -- optional: raw link to the Clover script
local LOGO_ID = ""               -- e.g. "123456789012345"
local LOGO_TRANSPARENCY = 0.65   -- logo on the round/square buttons
local DISCORD = ".gg/KcEqqvn5fd"

_G.PHANTOM_LOGO_ID = LOGO_ID
_G.PHANTOM_LOGO_TRANSPARENCY = LOGO_TRANSPARENCY

-- ---------------------------------------------------------------------
-- 1. get the source
-- ---------------------------------------------------------------------
local src
if SOURCE_URL ~= "" then
    local ok, res = pcall(function()
        return game:HttpGet(SOURCE_URL)
    end)
    if ok then src = res end
end
if not src and readfile and isfile and isfile(SOURCE_FILE) then
    src = readfile(SOURCE_FILE)
end
if type(src) ~= "string" or #src < 1000 then
    warn("[Phantom Duels] could not load the source. Put your script in the workspace as " .. SOURCE_FILE .. " or set SOURCE_URL.")
    return
end

-- ---------------------------------------------------------------------
-- 2. plain-text replace helper (no Lua patterns)
-- ---------------------------------------------------------------------
local function replaceAll(s, find, repl)
    local out, pos = {}, 1
    while true do
        local a, b = string.find(s, find, pos, true)
        if not a then
            out[#out + 1] = string.sub(s, pos)
            break
        end
        out[#out + 1] = string.sub(s, pos, a - 1)
        out[#out + 1] = repl
        pos = b + 1
    end
    return table.concat(out)
end

-- ---------------------------------------------------------------------
-- 3. rebrand
-- ---------------------------------------------------------------------
-- avatar item prefix is length-checked in the source ("CloverAvatar_" is 13
-- chars, "PhantomAvatar_" is 14), so fix that before the generic rename
src = replaceAll(src, 'sub(1, 13) == "CloverAvatar_"', 'sub(1, 14) == "PhantomAvatar_"')

-- discord: swap the old invite for yours everywhere it appears
-- (the old link is split in two pieces so it never shows up in this file)
-- covers both the "cloverhub" and "cloverduels" invites, with or without https://
for _, name in ipairs({ "clover" .. "hub", "clover" .. "duels" }) do
    src = replaceAll(src, "https://discord.gg/" .. name, DISCORD)
    src = replaceAll(src, "discord.gg/" .. name, DISCORD)
end
-- the full link is longer, so let the in-world billboard text scale to fit
src = replaceAll(src, "speedBranding.TextSize = 28", "speedBranding.TextScaled = true")

-- "PHANTOM" is one letter longer than "CLOVER", shrink the title text a bit
src = replaceAll(src, "imageLabel.TextSize = 48", "imageLabel.TextSize = 36")
src = replaceAll(src, "rootPart.TextSize = 24", "rootPart.TextSize = 18")

-- names / titles / config file / globals (all consistent renames)
-- "cloverduels" -> "phantomduels" (explicit, runs before the generic rename)
src = replaceAll(src, "CLOVERDUELS", "PHANTOMDUELS")
src = replaceAll(src, "CloverDuels", "PhantomDuels")
src = replaceAll(src, "Cloverduels", "Phantomduels")
src = replaceAll(src, "cloverduels", "phantomduels")
-- plain "clover" -> "phantom"
src = replaceAll(src, "CLOVER", "PHANTOM")
src = replaceAll(src, "Clover", "Phantom")
src = replaceAll(src, "clover", "phantom")

-- logo instead of the clover icon (title, mini button, background decor)
src = replaceAll(src, 'local iconScale = Instance.new("UIScale", holder)', [[
if (_G.PHANTOM_LOGO_ID or "") ~= "" then
    local logoImg = Instance.new("ImageLabel", holder)
    logoImg.BackgroundTransparency = 1
    logoImg.Size = UDim2.fromScale(1, 1)
    logoImg.Image = "rbxassetid://" .. tostring(_G.PHANTOM_LOGO_ID)
    logoImg.ScaleType = Enum.ScaleType.Fit
    logoImg.ZIndex = z
    Instance.new("UIScale", holder).Scale = (pixelSize or 100) / 100
    holder.Parent = parent
    return holder
end
local iconScale = Instance.new("UIScale", holder)]])

-- ---------------------------------------------------------------------
-- 4. put the logo on every button (mobile panel buttons + floating buttons)
-- ---------------------------------------------------------------------
do
    local function guiName(d)
        local g = d:FindFirstAncestorWhichIsA("ScreenGui")
        return g and g.Name or ""
    end
    local function wanted(d)
        local n = guiName(d)
        return n:find("^Phantom") ~= nil or n == "BatV2Button" or n == "InstaResetButton"
    end
    local function bake(d)
        if (_G.PHANTOM_LOGO_ID or "") == "" then return end
        local isButton = d:IsA("TextButton")
        local isFloating = d:IsA("Frame") and d.Name == "Frame" and d.Parent and d.Parent:IsA("ScreenGui")
        if not (isButton or isFloating) then return end
        if d:FindFirstChild("PhantomLogo") or not wanted(d) then return end
        task.defer(function()
            if not d.Parent or d:FindFirstChild("MiniPhantomIcon") then return end
            local w, h = d.AbsoluteSize.X, d.AbsoluteSize.Y
            if w < 40 or h < 40 then return end
            local img = Instance.new("ImageLabel")
            img.Name = "PhantomLogo"
            img.BackgroundTransparency = 1
            img.Image = "rbxassetid://" .. tostring(_G.PHANTOM_LOGO_ID)
            img.ImageTransparency = _G.PHANTOM_LOGO_TRANSPARENCY or 0.65
            img.ScaleType = Enum.ScaleType.Fit
            img.AnchorPoint = Vector2.new(0.5, 0.5)
            img.Position = UDim2.new(0.5, 0, 0.5, 0)
            local side = math.min(w, h) - 6
            img.Size = UDim2.fromOffset(side, side)
            img.ZIndex = d.ZIndex
            img.Active = false
            img.Parent = d
        end)
    end
    local cg = game:GetService("CoreGui")
    cg.DescendantAdded:Connect(bake)
    pcall(function()
        local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
        if pg then pg.DescendantAdded:Connect(bake) end
    end)
end

-- ---------------------------------------------------------------------
-- 5. run it
-- ---------------------------------------------------------------------
local fn, err = loadstring(src)
if not fn then
    warn("[Phantom Duels] compile error: " .. tostring(err))
    return
end
local ok, runErr = pcall(fn)
if not ok then
    warn("[Phantom Duels] runtime error: " .. tostring(runErr))
end
