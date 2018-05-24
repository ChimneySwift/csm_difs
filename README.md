# Dynamic Inventory Formspecs (CSM port)

Accessing node metadata is a very useful moderation and debugging tool. Unfortuantely the available metadata viewers lack the ability to read _all_ metadata on every node in a friendly and easily readable way.

Dynamic Inventory Formspecs solves this issue by displaying inventories and metadata dynamically - no hard-coding required. It can handle inventories of any size (within reason) with ease as it calculates the most efficient way of displaying the formspec based on the length of the inventory list, not hard-coded values. The user can select any inventory or metadata field to view from a simple dropdown.

## Usage

By default, the formspec will display if the user hits a node with `default:stick` that contains either metadata fields (eg. sign), an inventory (eg, chest), or both. This action is limited to `default:stick` else digging nodes with metadata or an inventory would be impossible.

By default, the inventory formspec will be displayed if the node has both metadata and an inventory, and can be toggled with the toggle button on the bottom. In the metadata formspec, the value of a selected field is displayed in a text field, while this field is editable, edited values will not be sent to the server, this is simply because this is the only way to get a scrollable text field. Since formspecs are commonly stored in metadata, formspecs will be automatically pretty-printed.

## Any inventory you say? 🤔

Yes. Any inventory.

![Gold Chest](https://github.com/ChimneySwift/csm_difs/blob/master/screenshots/gold_chest.PNG?raw=true)

![Infinite Chest](https://github.com/ChimneySwift/csm_difs/blob/master/screenshots/inf_chest.PNG?raw=true)

## BUT WHUT ABOUT SECURITY U HACKOR!?!!1!?!

Any server which still has nodes which don't check for unauthorised inventory access deserves to have people stealing items from locked chests. It takes 2 seconds to do. Seriously, just add this to the node's registration:

```lua
allow_metadata_inventory_take = function(pos, listname, index, stack, player)
    local meta = minetest.get_meta(pos)
    local name = player:get_player_name()
    if not meta:get_string("owner") == name and not minetest.check_player_privs(name, {protection_bypass=true,} then
        return 0
    end
    return stack:get_count()
end
```

Or update your server.

As for metadata, there is an option to disable sending sensitive metadata to the client, if this is such a big deal to you, use it.
