-- Global Variables
physicsToggle = false
local picking_object = nil
local distance_trace_object = nil
local distance = 200
local busy = nil

-- Sets the color of Highlighing at index 1
Client.SetHighlightColor(Color(0, 20, 20, 1.5), 1, HighlightMode.OnlyVisible)

-- When Player clicks
Input.Subscribe("MouseUp", function(key_name)
    if not physicsToggle then return end
    -- If mouse was left button
    if (key_name == "LeftMouseButton") then
        -- If is grabbing something, drop it
        if (picking_object) then
            -- Calls server to re-enable gravity (if possible) and update it's last position
            Events.CallRemote("PickUp", picking_object, false)

            -- Disables the highlight
            picking_object:SetHighlightEnabled(false)

            picking_object = nil
            return
        end

        -- Get the camera location in 3D World Space
        local viewport_2D_center = Viewport.GetViewportSize() / 2
        local viewport_3D = Viewport.DeprojectScreenToWorld(viewport_2D_center)
        local camera_rotation = Client.GetLocalPlayer():GetCameraRotation()
        local start_location = viewport_3D.Position + (camera_rotation:GetForwardVector() * 400)
        local end_location = start_location + (camera_rotation:GetForwardVector() * 10000)

        --[[ -- Gets the end location of the trace (5000 units ahead)
        local trace_max_distance = 5000
        local end_location = viewport_3D.Position + viewport_3D.Direction * trace_max_distance ]]

        -- Determine at which object we will be tracing for (WorldStatic - StaticMeshes - and PhysicsBody - Props)
        local collision_trace = CollisionChannel.WorldStatic | CollisionChannel.PhysicsBody | CollisionChannel.Vehicle | CollisionChannel.Pawn

        -- Sets the trace modes (we want it to return Entity and Draws a Debug line)
        local trace_mode = TraceMode.ReturnEntity

        -- Do the Trace
        local trace_result = Trace.LineSingle(start_location, end_location, collision_trace, trace_mode)

        -- If hit something and hit an Entity
        if (trace_result.Success and trace_result.Entity) then

            -- Sets the new picked up object
            picking_object = trace_result.Entity

            -- Calculates the offset of the hit and the center of the object
            distance_trace_object = picking_object:GetLocation() - trace_result.Location

            -- Calculates the distance of the object and the camera
            distance = trace_result.Location:Distance(viewport_3D.Position)

            -- Calls remote to disable gravity of this object (if has)
            Events.CallRemote("PickUp", picking_object, true)

            -- Enable Highlighting on index 1
            picking_object:SetHighlightEnabled(true, 1)
        end
    end
end)

Input.Subscribe("KeyDown", function(key_name, delta)
    if busy then return end
    if not physicsToggle then return end
    if not picking_object then return end

    if key_name == 'Up' then
        local viewport_2D_center = Viewport.GetViewportSize() / 2
        local viewport_3D = Viewport.DeprojectScreenToWorld(viewport_2D_center)
        local camera_rotation = Client.GetLocalPlayer():GetCameraRotation()
        local end_location = picking_object:GetLocation() + (camera_rotation:GetForwardVector() * 100)

        busy = true
        Events.CallRemote("UpdateObjectPosition", picking_object, end_location)
        Timer.SetTimeout(function ()
            distance = picking_object:GetLocation():Distance(viewport_3D.Position)
            busy = false
        end, 100)
    end

    if key_name == 'Down' then
        local viewport_2D_center = Viewport.GetViewportSize() / 2
        local viewport_3D = Viewport.DeprojectScreenToWorld(viewport_2D_center)
        local camera_rotation = Client.GetLocalPlayer():GetCameraRotation()
        local end_location = picking_object:GetLocation() - (camera_rotation:GetForwardVector() * 100)

        busy = true
        Events.CallRemote("UpdateObjectPosition", picking_object, end_location)
        Timer.SetTimeout(function ()
            distance = picking_object:GetLocation():Distance(viewport_3D.Position)
            if (distance < 400) then
                distance = 400
            end
            busy = false
        end, 100)
    end
end)


Client.Subscribe("Tick", function(delta_time)
    -- On Tick, updates the Position of the object, based on it's distance and camera rotation
    if busy then return end
    if not physicsToggle then return end
    if not picking_object then return end

    local player = Client.GetLocalPlayer()
    if (player == nil) then return end

    -- Get the camera location in 3D World Space
    local viewport_2D_center = Viewport.GetViewportSize() / 2
    local viewport_3D = Viewport.DeprojectScreenToWorld(viewport_2D_center)
    local start_location = viewport_3D.Position

    -- Gets the new object location
    -- (camera direction * 'distance' units ahead + object offset from first Hit to keep it relative)
    local end_location = (viewport_3D.Position + viewport_3D.Direction * distance) + distance_trace_object

    -- Calls remote to update it's location
    Events.CallRemote("UpdateObjectPosition", picking_object, end_location)
end)