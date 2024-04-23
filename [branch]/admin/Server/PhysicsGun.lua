-- Spawns some Props and Static Meshes
-- (note: Static Meshes don't have physics so they will freeze where released automatically)
--[[ local p_sphere = Prop(Vector(200, 0, 200), Rotator(), "helix::SM_Sphere")
local p_cone = Prop(Vector(200, 0, 200), Rotator(), "helix::SM_Cone")
local sm_cube = StaticMesh(Vector(100, 0, 200), Rotator(), "helix::SM_Cube")
local sm_cylinder = StaticMesh(Vector(300, 0, 200), Rotator(), "helix::SM_Cylinder") ]]

-- Subscribe for Client's custom event, for when the object is grabbed/dropped
Events.SubscribeRemote("PickUp", function(player, object, is_grabbing)
    object:SetGravityEnabled(not is_grabbing)
    object:TranslateTo(object:GetLocation(), 0)
end)

-- Subscribe for Client's custom event, to update the position of the object he is grabbing
Events.SubscribeRemote("UpdateObjectPosition", function(player, object, location)
    object:TranslateTo(location, 0.1)
end)