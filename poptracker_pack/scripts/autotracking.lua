-- Nubby's Number Factory PopTracker AP autotracking
-- Handler pattern confirmed against a real working AP pack
-- (Cyb3RGER/minecraft_rando_tracker/scripts/autotracking.lua).

ScriptHost:LoadScript("scripts/item_mapping.lua")
ScriptHost:LoadScript("scripts/location_mapping.lua")
ScriptHost:LoadScript("scripts/supervisor_win_mapping.lua")
ScriptHost:LoadScript("scripts/check_mapping.lua")

CUR_INDEX = -1
-- Caches each supervisor item's pristine (un-bordered) Icon the first time
-- onLocation reads it, so the gold-border overlay can always be baked from
-- the original image (never stacking overlay-on-overlay on a resync) and so
-- onClear can restore it exactly instead of guessing / nulling it out.
SV_ORIGINAL_ICON = {}

function onClear(slot_data)
    CUR_INDEX = -1
    for _, v in pairs(ITEM_MAPPING) do
        local obj = Tracker:FindObjectForCode(v[1])
        if obj then
            if v[2] == "toggle" then
                -- Do NOT touch .Icon here: JsonItem's Icon is set once from
                -- items.json at pack load and is never modified for regular
                -- items - only the supervisor items below ever get a gold-
                -- border overlay baked onto .Icon, and those are restored
                -- from SV_ORIGINAL_ICON below instead. Nulling .Icon
                -- unconditionally for every toggle item here was the v44
                -- regression that made every item icon disappear on
                -- connect/reset (JsonItem has no IconMods to safely no-op
                -- against - .Icon is the real image and nil means "none").
                obj.Active = false
            elseif v[2] == "progressive" then
                -- Not touching .Active here - matches a real working
                -- pack's own progressive-item pattern, and PopTracker
                -- handles the "not active" look automatically for any
                -- item that never sets it. zone_progressive's "starts
                -- unlocked" requirement is handled declaratively via its
                -- own initial_active_state in items.json instead (a Lua
                -- runtime push here was tried and confirmed NOT to work -
                -- state needs to be right from pack load, before onClear
                -- ever runs, not pushed reactively).
                obj.CurrentStage = 0
            elseif v[2] == "consumable" then
                obj.AcquiredCount = 0
            end
        end
    end
    for _, v in pairs(LOCATION_MAPPING) do
        local obj = Tracker:FindObjectForCode(v[1])
        if obj then
            obj.AvailableChestCount = 0
        end
    end
    -- Round/Restock Milestones, AP Shop Offers (toggles) and the single
    -- Points Checks consumable - see CHECK_MAPPING/onLocation below.
    for _, c in pairs(CHECK_MAPPING) do
        local obj = Tracker:FindObjectForCode(c[1])
        if obj then
            if c[2] == "consumable" then
                obj.AcquiredCount = 0
            else
                obj.Active = false
            end
        end
    end
    -- Strip any gold border left over from a previous run by restoring the
    -- cached pristine icon for every supervisor that has one.
    for sv_index, orig_icon in pairs(SV_ORIGINAL_ICON) do
        local sv_obj = Tracker:FindObjectForCode("sv" .. sv_index)
        if sv_obj then
            sv_obj.Icon = orig_icon
        end
    end
end

function onItem(index, item_id, item_name)
    if index <= CUR_INDEX then return end
    CUR_INDEX = index
    local v = ITEM_MAPPING[item_id]
    if not v then return end
    local obj = Tracker:FindObjectForCode(v[1])
    if not obj then return end
    if v[2] == "toggle" then
        obj.Active = true
    elseif v[2] == "progressive" then
        -- Matches a real working pack's own pattern: no .Active check at
        -- all, just advance the stage. v[3] is an optional per-mapping
        -- stage increment (defaults to 1 when absent, e.g. for an item
        -- that should count as multiple stages at once) - not currently
        -- used by anything in this pack, but supported for free.
        local inc = 1
        if v[3] then
            inc = v[3]
        end
        obj.CurrentStage = obj.CurrentStage + inc
    elseif v[2] == "consumable" then
        obj.AcquiredCount = obj.AcquiredCount + 1
    end
end

function onLocation(location_id, location_name)
    local v = LOCATION_MAPPING[location_id]
    if v then
        local obj = Tracker:FindObjectForCode(v[1])
        if obj then
            obj.AvailableChestCount = 1
        end
    end
    -- Round/Restock Milestones, AP Shop Offers, and Points Checks are
    -- tracked as items.json entries (see the "Checks" section in the
    -- generator), not real PopTracker Locations - PopTracker only ever
    -- visually renders Locations via a "map" layout, which this game has
    -- no meaningful equivalent of. CHECK_MAPPING drives them here exactly
    -- like ITEM_MAPPING drives onItem, just from a location check instead
    -- of a received item.
    local c = CHECK_MAPPING[location_id]
    if c then
        local cobj = Tracker:FindObjectForCode(c[1])
        if cobj then
            if c[2] == "consumable" then
                cobj.AcquiredCount = cobj.AcquiredCount + 1
            else
                cobj.Active = true
            end
        end
    end
    -- Gold border on a supervisor's own item icon once that supervisor's
    -- "Win Supervisor N" location has been checked (completed a run) -
    -- separate from the item's own unlock/Active state, which only means
    -- "selectable", not "beaten". overlay_gold_border.png is a plain
    -- gold picture-frame PNG with a transparent center.
    --
    -- NOTE: items declared in items.json (like these "toggle" supervisor
    -- items) are JsonItem in PopTracker's Lua API, and JsonItem has no
    -- IconMods property at all - that's LuaItem-only (custom items created
    -- entirely from Lua). Setting .IconMods on a JsonItem is a silent no-op
    -- (confirmed against PopTracker's own Lua API definitions), which is
    -- why an earlier version of this never visibly did anything. JsonItem
    -- DOES have a settable .Icon (an ImageRef), so the overlay has to be
    -- baked into a *new* ImageRef via ImageReference:FromImageReference
    -- and assigned to .Icon instead - same "overlay|path" mod syntax as
    -- JSON's img_mods, just applied at the image-reference level rather
    -- than through a mods string property.
    --
    -- Always bake the overlay from the cached pristine icon (SV_ORIGINAL_
    -- ICON), never from the item's *current* .Icon - onLocation can fire
    -- more than once for the same location (e.g. a resync), and baking
    -- from an already-bordered icon would stack a second overlay on top
    -- of the first instead of being a no-op.
    local sv_index = SUPERVISOR_WIN_MAPPING[location_id]
    if sv_index then
        local sv_obj = Tracker:FindObjectForCode("sv" .. sv_index)
        if sv_obj and sv_obj.Icon then
            if not SV_ORIGINAL_ICON[sv_index] then
                SV_ORIGINAL_ICON[sv_index] = sv_obj.Icon
            end
            sv_obj.Icon = ImageReference:FromImageReference(SV_ORIGINAL_ICON[sv_index], "overlay|images/overlay_gold_border.png")
        end
    end
end

Archipelago:AddClearHandler("nnf clear handler", onClear)
Archipelago:AddItemHandler("nnf item handler", onItem)
Archipelago:AddLocationHandler("nnf location handler", onLocation)
