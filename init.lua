--  _____                              _        _____                      _                     ______
-- |  __ \                            (_)      |_   _|                    | |                   |  ____|
-- | |  | |_   _ _ __   __ _ _ __ ___  _  ___    | |  _ ____   _____ _ __ | |_ ___  _ __ _   _  | |__ ___  _ __ _ __ ___  ___ _ __   ___  ___ ___
-- | |  | | | | | '_ \ / _` | '_ ` _ \| |/ __|   | | | '_ \ \ / / _ \ '_ \| __/ _ \| '__| | | | |  __/ _ \| '__| '_ ` _ \/ __| '_ \ / _ \/ __/ __|
-- | |__| | |_| | | | | (_| | | | | | | | (__   _| |_| | | \ V /  __/ | | | || (_) | |  | |_| | | | | (_) | |  | | | | | \__ \ |_) |  __/ (__\__ \
-- |_____/ \__, |_| |_|\__,_|_| |_| |_|_|\___| |_____|_| |_|\_/ \___|_| |_|\__\___/|_|   \__, | |_|  \___/|_|  |_| |_| |_|___/ .__/ \___|\___|___/
--          __/ |                                                                         __/ |                              | |
--         |___/                                                                         |___/                               |_|

difs = {}
difs.version = "0.1.0"

difs.settings = {}

function table.length(t)
    return #t
end

local function get_listnames(lists)
    local listnames = {}
    if lists then
        for i in pairs(lists) do
            table.insert(listnames, i)
        end
    end
    return listnames
end

-- Function to determine the most optimal width and height of a inventory by calculating the factors of the inventory size and determining the closest factor pair
difs.get_inv_width_height = function(size)
    local factors = {}
    for i=1, math.ceil(size/2) do
        local f1 = i
        local f2 = size/i
        -- Number must be a factor if it divides evenly into the inventory size
        if math.floor(f2) == f2 then
            -- Add to table, width should be the larger number and height should be smaller
            table.insert(factors,{w = math.max(f2, f1), h = math.min(f2, f1)})
        end
    end

    -- Find the closest factor pair unless the height is greater than 6 (in which case prefer width as screens are usually wider than they are tall)
    local closest_factors = {w = size, h = 1}
    for i in pairs(factors) do
        if (factors[i].w - factors[i].h) < (closest_factors.w - closest_factors.h) and factors[i].h <= 6 then
            closest_factors = factors[i]
        end
    end

    return closest_factors
end

-- Function to generate inventory section of formspec, returns a table with the overall width and height eg: {w=4,h=4} and a formspec.
difs.generate_inventory_fs = function(lists, listname, inv_location, y_offset)
    local length = #lists[listname]
    local size = difs.get_inv_width_height(length)
    local overall_fs_size = {w = 0, h = 0}

    -- Add inventory list
    local fs = "list["..inv_location..";"..listname..";0,"..y_offset..";"..size.w..","..size.h..";]"
    overall_fs_size = table.copy(size)

    return overall_fs_size, fs
end

-- Main function to generate dynamic inventory formspec, returns true and a formspec or false and an error
difs.generate_difs = function(meta, inv_location, selected_list)
    -- Ensure there is meta lists
    if not meta:to_table() then
        return false, "Node has no metadata"
    end

    -- Get list of inventory listnames
    local lists = meta:to_table().inventory
    local listnames = get_listnames(lists)

    -- Sometimes it messes up the order
    table.sort(listnames)

    -- Ensure there are inventory lists
    if not next(listnames) then
        return false, "Inventory has no lists."
    end

    -- If selected_list is not input, set them to their default values
    selected_list = selected_list or (lists["main"] and "main") or listnames[1]

    local fs = ""
    local fs_size = {w=0,h=0}

    -- Add inventory
    local inv_size, inv_fs = difs.generate_inventory_fs(lists, selected_list, inv_location, fs_size.h)

    fs = fs..inv_fs

    fs_size.h = fs_size.h + inv_size.h + 0.5

    -- Add player inventory
    local player_inv_x = 0
    if inv_size.w > 8 then
        player_inv_x = inv_size.w/2 - 4
    end

    fs = "list[current_player;main;"..player_inv_x..","..(fs_size.h)..";8,4;]"..fs
    fs_size.h = fs_size.h + 4

    -- Add list selection dropdown
    local selected_idx = 1
    for i in pairs(listnames) do
        if listnames[i] == selected_list then
            selected_idx = i
        end
    end

    fs = fs.."dropdown[0,"..(fs_size.h)..";3;list_select;"..table.concat(listnames, ",")..";"..selected_idx.."]"

    if next(meta:to_table().fields) then
        fs = fs.."button[3,"..(fs_size.h-0.1)..";3,1.1;toggle;Meta Mode]"
    end

    fs_size.h = fs_size.h + 0.5

    -- Add formspec size element
    if inv_size.w > 8 then
        fs_size.w = inv_size.w
    else
        fs_size.w = 8
    end

    fs = "size["..fs_size.w..","..fs_size.h.."]"..fs

    return true, fs
end

-- Main function to generate dynamic metadata formspec, returns true and a formspec or false and an error
difs.generate_meta_fs = function(meta, selected_list)
    -- Ensure there is meta lists
    if not meta:to_table() then
        return false, "Node has no metadata"
    end

    local fields = meta:to_table().fields
    local fieldnames = get_listnames(fields)

    -- Sometimes it messes up the order
    table.sort(fieldnames)

    -- Ensure there are fields
    if not next(fieldnames) then
        return false, "Node has no fields."
    end

    -- If selected_list is not input, set them to their default values
    selected_list = selected_list or (fields["owner"] and "owner") or fieldnames[1]

    local fs = ""
    local fs_size = {w=0,h=0}

    fs = fs.."textarea[0.2,0;8,6.8;field_content;Selected field: "..selected_list..";"..minetest.formspec_escape(fields[selected_list]:gsub("]", "]\n")).."]"

    fs_size.w = fs_size.w + 8
    fs_size.h = fs_size.h + 6

    -- Add list selection dropdown
    local selected_idx = 1
    for i in pairs(fieldnames) do
        if fieldnames[i] == selected_list then
            selected_idx = i
        end
    end

    fs = fs.."dropdown[0,"..(fs_size.h)..";3;list_select;"..table.concat(fieldnames, ",")..";"..selected_idx.."]"

    if next(meta:to_table().inventory) then
        fs = fs.."button[3,"..(fs_size.h-0.1)..";3,1;toggle;Inventory Mode]"
    end

    fs_size.h = fs_size.h + 0.5

    fs = "size["..fs_size.w..","..fs_size.h.."]"..fs

    return true, fs
end


minetest.register_on_formspec_input(function(formname, fields)
    if formname:split(":")[1] ~= "difs" then return end

    if fields.quit then
        difs.settings = {}
        return
    end

    local fs_type = formname:split(":")[2]

    local pos = difs.settings.pos
    local meta = minetest.get_meta(pos)

    if fields.list_select then
        difs.settings.listname = fields.list_select
    end

    if fields.toggle then
        if fs_type == "node_inventory" then
            formname = "difs:meta"
            fs_type = "meta"
        else
            formname = "difs:node_inventory"
            fs_type = "node_inventory"
        end
        difs.settings.listname = nil
    end

    local success, fs = ""

    if fs_type == "node_inventory" then
        local inventory_location = "nodemeta:"..pos.x..","..pos.y..","..pos.z

        success, fs = difs.generate_difs(meta, inventory_location, difs.settings.listname)
    else
        success, fs = difs.generate_meta_fs(meta, difs.settings.listname)
    end

    if success then
        minetest.show_formspec(formname, fs)
    else
        minetest.display_chat_message(fs)
    end
end)

minetest.register_on_punchnode(function(pos, node)
    local meta = minetest.get_meta(pos)
    local tool = minetest.localplayer:get_wielded_item()
    if tool:get_name() == "default:stick" then
        difs.settings.pos = pos
        local success, fs = difs.generate_difs(meta, "nodemeta:"..pos.x..","..pos.y..","..pos.z)
        if success then
            minetest.show_formspec("difs:node_inventory", fs)
            return true

        -- Might have no inventory but have meta
        elseif meta:to_table() and next(meta:to_table().fields) then
            local success, fs = difs.generate_meta_fs(meta)
            if success then
                minetest.show_formspec("difs:meta", fs)
                return true
            end
        end
    end
end)
