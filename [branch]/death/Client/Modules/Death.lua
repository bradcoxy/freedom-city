local Death = {}

Death.UIShown = false
Death.recentAmbulanceRequest = false
Death.UI = WebUI('deathScreen', "file://UI/DeathScreen/index.html")



--- @brief shows the death screen.
function Death.ShowDeathScreen()
    if Death.UIShown then return end

    Death.UIShown = not Death.UIShown

    Input.SetMouseEnabled(true)
    Input.SetInputEnabled(false)

    Death.UI:BringToFront()
    Death.UI:CallEvent('showDeathScreen', 120)
end

--- @brief hides the death screen.
function Death.HideDeathScreen()
    if not Death.UIShown then return end

    Death.UIShown = not Death.UIShown

    Input.SetMouseEnabled(false)
    Input.SetInputEnabled(true)

    Death.UI:CallEvent('hideDeathScreen')
end

--- @brief called after the timer has run out or when accepted death.
function Death.TimerFinished()
    Events.CallRemote('Death:ServerEvent', 'deathTimerFinished')
    Death:HideDeathScreen()
end

Death.UI:Subscribe('deathTimerFinished', Death.TimerFinished)

Core.RegisterInput('G', function()
    if Death.UIShown then
        Death.TimerFinished()
    end
end)

Core.RegisterInput('U', function()
    if Death.UIShown then
        if Death.recentAmbulanceRequest then
            Core.ShowNotification('You already called an ambulance.')
            return
        end

        Events.CallRemote('Death:ServerEvent', 'callAmbulance')

        Death.recentAmbulanceRequest = not Death.recentAmbulanceRequest
        Timer.SetTimeout(function ()
            Death.recentAmbulanceRequest = not Death.recentAmbulanceRequest
        end, (60000 * 2))
    end
end)

Events.SubscribeRemote('core:onPlayerDeath', Death.ShowDeathScreen)
Events.SubscribeRemote('core:onPlayerRevived', Death.HideDeathScreen)