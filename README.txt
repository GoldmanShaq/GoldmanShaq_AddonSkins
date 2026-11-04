GoldmanShaq_AddonSkins
======================
Skins third-party addons to match EllesmereUI.

Included skins: SavedInstances, BetterAddonList.
Install: put the GoldmanShaq_AddonSkins folder in Interface\AddOns, delete the old
SavedInstances_EllesmereSkin addon (it is now part of this one).

Config: edit the `cfg` table at the top of Core.lua (colours, border, font, accent fallback).

Adding a skin: create Skins\Name.lua, call GS:Register("TargetAddonFolder", function(GS) ... end),
add the file to the .toc and add the addon to OptionalDeps.

Commands:
  /gsskin dump <FrameName>   print a frame's children (use /fstack to find the name)
  /gsskin reskin             re-scan lazily created frames

Forever: add its interface number to the ## Interface line (comma separated).
Find it in-game with: /dump (select(4, GetBuildInfo()))
