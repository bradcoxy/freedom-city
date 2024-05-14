var compass = $('.compass-degree');
var playerCount = $('.player-count .detail')
var playerServerId = $('.server-id .detail')

// Minimap
const mapContainer = $('.minimap');
const mapWrapper = $('.map');
const knownGameCoords = [[160245, -328033], [154332, -374728], [161250, -387233]];
const knownUICoords = [[517, 1439], [575, 1353], [575, 1324]];

const confettiAnim = document.querySelector('#confetti');

let persistentBlips = [];

const accountElements = {
    // bank: $('.bank .detail'),
    money: $('.lix .detail')
}
const voiceElements = {
    voip: $('.voice-indicators .voip-indicator'),
    radio: $('.voice-indicators .radio-indicator'),
}
const playerIndicator = $('.minimap .player-indicator');

const formatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
});

const UpdateAccountMoney = (account, value) => {
    if (!accountElements[account]) return;

    accountElements[account].text(`${formatter.format(value).substring(1)} $`)
}

const SetVOIPActive = (voip, value) => {
    if (!voiceElements[voip]) return;

    if (value)
        voiceElements[voip].addClass('active')
    else
        voiceElements[voip].removeClass('active')
}


// Vip Notification
const ShowVipNotification = () => {
    document.getElementById('confetti').play()
    setTimeout(() => {
        $('.vip-notification').removeClass('hidden')
    }, 100);
    setTimeout(() => {
        // change atributo "speed" to .4 (es un lottie-player)
        // document.getElementById('confetti').setAttribute("speed", ".1")
    }, 200);
    setTimeout(() => {
        $('.vip-notification').addClass('hidden')
        document.getElementById('confetti').stop()
    }, 5000);
}

// Map
const barycentricInterpolation = ({ x, y }) => {
    const [[x1, y1], [x2, y2], [x3, y3]] = knownGameCoords;
    const [[u1, v1], [u2, v2], [u3, v3]] = knownUICoords;

    const w1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) /
        ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3));
    const w2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) /
        ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3));
    const w3 = 1 - w1 - w2;

    const u = w1 * u1 + w2 * u2 + w3 * u3;
    const v = w1 * v1 + w2 * v2 + w3 * v3;

    x = u
    y = v
    return { x, y };
}
const goToCoords = (coords) => {
    let { x, y } = coords;

    let mapContainerWidth = mapContainer.width();
    let mapContainerHeight = mapContainer.height();

    let adjustedX = mapContainerWidth / 2 - x;
    let adjustedY = mapContainerHeight / 2 - y;

    $('.minimap .rotator-container>div:not(.player-indicator)').css({
        left: adjustedX,
        bottom: adjustedY
    });
}
const setRotations = (playerHeading, cameraRotation) => {
    let fixedHeading = playerHeading + 360;
    let fixedCameraRotation = cameraRotation;

    playerIndicator.css({
        transform: `translate(-50%, 50%) rotate(-27deg) rotate(${fixedHeading}deg) rotate(-90deg)`
    });

    $('.minimap .rotator-container').css({
        transform: `rotate(31deg) rotate(${-fixedCameraRotation}deg) rotate(90deg)`
    });
    $('.map-blip').css({
        transform: `rotate(-31deg) rotate(${fixedCameraRotation}deg) rotate(-90deg)`
    });
}

// Stats
const setStat = (stat, percentage) => {
    $(`.player-stat[data-stat="${stat}"]`).removeClass('low lower')
    $(`.player-stat[data-stat="${stat}"] .percentage .fill`).css('stroke-dasharray', percentage + ', 100')


    if (percentage < 26) {
        $(`.player-stat[data-stat="${stat}"]`).addClass('lower')
    } else if (percentage < 51) {
        $(`.player-stat[data-stat="${stat}"]`).addClass('low')
    }
}

// Notifications
const showNotification = ({ type, text, title, duration }) => {
    if (!type) type = 'info'
    if (!duration) duration = 5000
    let seconds = duration / 1000
    // var text = text.replace("<focus>",`<focus id="${type}-text">`);
    let id = Date.now();

    let element = $(`<div class="notification ${type}" id="${id}" >
    <div class="data">
      <h1>${type}</h1>
      <h2>${text}</h2>
    </div>
    <div class="icon">
      <img src="./assets/notifications/${type}-icon.svg" alt="" class="icon">
    </div>
    <svg class="percentage" viewBox="0 0 36 36">
      <path class="fill" d="M18 2.0845
                  a 15.9155 15.9155 0 0 1 0 31.831
                  a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" ; stroke-width="4" stroke-dasharray="100, 100" />
      <path class="circle-bg" d="M18 2.0845
                              a 15.9155 15.9155 0 0 1 0 31.831
                              a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" ; stroke-width="4" stroke-dasharray="100, 100" />
    </svg>
    <img src="./assets/notifications/${type}-notif-bg.png" alt="" class="notif-bg">
  </div>`)

    $('.notifications').append(element);

    element.css('left', '-110%').css('opacity', 0.0)

    element.css('position', 'relative').animate({ left: '0', opacity: 1 }, 150, 'linear')

    seconds--;
    element.find('.percentage .fill').css('stroke-dasharray', `${(seconds / (duration / 1000)) * 100}, 100`);
    let intervalPercentage = setInterval(() => {
        seconds--;
        element.find('.percentage .fill').css('stroke-dasharray', `${(seconds / (duration / 1000)) * 100}, 100`);
    }, 1000);

    setTimeout(element => {
        element.animate({ right: '-110%', opacity: 0 }, 150, 'linear', () => {
            element.remove()
        })
    }, duration, element)
}

// Blips
const hardcodedBlips = [
   
];
const setBlips = (blips) => {
    persistentBlips = blips;

    blips.forEach(blip => {
        let { imgUrl, id } = blip;

        let mapBlip = `<img data-id="${id}" src="${imgUrl}" alt="" class="map-blip">`;
        $('.minimap .rotator-container>div:not(.player-indicator)').append(mapBlip);

        setTimeout(() => {
            mapBlip = $(`.map-blip[data-id="${id}"]`);
            let { x, y } = barycentricInterpolation(blip.coords);
            mapBlip.data("coords", JSON.stringify({ x: x, y: y }));

            let mapBlipWidth = mapBlip.width();
            let mapBlipHeight = mapBlip.height();

            x -= mapBlipWidth / 2;
            y -= mapBlipHeight / 2;

            mapBlip.css({
                left: x,
                bottom: y
            });
        }, 500);
    });


}

setBlips(hardcodedBlips);
// UpdateAccountMoney('bank', 0);
UpdateAccountMoney('money', 0);
SetVOIPActive('voip', false);
SetVOIPActive('radio', false);
goToCoords(barycentricInterpolation({ x: 155097, y: -398419 }));

Events.Subscribe("helix-hud:UpdateCompass", direction => {
    compass.text(direction)
})

Events.Subscribe('helix-hud:AddBlip', (blip) => {
    hardcodedBlips.push(blip)
    setBlips(hardcodedBlips);
})


Events.Subscribe('helix-hud:RemoveBlip', (blip) => {
    hardcodedBlips.shift(n)
    setBlips(hardcodedBlips);
})

Events.Subscribe("helix-hud:ToggleHUD", toggle => {
    if (toggle)
        $('body').css('opacity', '1')
    else
        $('body').css('opacity', '0')
})

Events.Subscribe('helix-hud:UpdatePlayers', count => {
    playerCount.text(count)
})

Events.Subscribe('helix-hud:UpdateServerId', id => {
    playerServerId.text(id)
})

Events.Subscribe('helix-hud:UpdateAccountMoney', (account, value) => {
    UpdateAccountMoney(account, value)
})

Events.Subscribe('helix-hud:UpdateVOIP', (voip, value) => {
    SetVOIPActive(voip, value)
})

Events.Subscribe('helix-hud:UpdateStatus', stats => {
    Object.entries(stats).forEach(([name, data]) => {
        setStat(name, (data.value / data.max) * 100)
    })
})

Events.Subscribe('helix-hud:ShowNotification', ({ type, text, title, duration }) => {
    showNotification({ type, text, title, duration })
})

Events.Subscribe("helix-hud:UpdateMinimap", (playerCoords, playerHeading, cameraRotation) => {
    playerCoords = JSON.parse(playerCoords)
    let { x, y } = barycentricInterpolation(playerCoords);
    setRotations(playerHeading, cameraRotation)
    goToCoords({ x, y })
})