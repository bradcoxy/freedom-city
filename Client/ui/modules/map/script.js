const blipsContainer = $('.blips');
const blipElement = blipsContainer.find('.blip');

const mapContainer = $(".map-container");
const mapWrapper = $(".map-wrapper");
const minimap = $(".map-wrapper .map");
const playerMarker = $(".player-marker");
const waypoint = $(".waypoint");

/* const knownGameCoords = [[-123764, 17547], [-111341, -4859], [101241, 242958]];
const knownUICoords = [[396, 1123], [346, 1123], [580, 1760]]; */

// [160245, -328033], [154332 -374728] [161250 -387233]
// [453, -1352] [575, -1353] [575 -1324]

const knownGameCoords = [[160245, -328033], [154332, -374728], [161250, -387233]];
const knownUICoords = [[517, 1439], [575, 1353], [575, 1324]];

// goToCoords(barycentricInterpolation({ x:160245, y: -328033}))
// goToCoords(barycentricInterpolation({ x:154332, y: -374728}))
// goToCoords(barycentricInterpolation({ x:161250, y: -387233}))

// tp 142209 -352798 774

let mapImageWidth = 4362;
let mapImageHeight = 1112;
let scale = 1;
let playerMarkerScale = 1;
let zoomAmount = 0.2;
let persistentBlips = [];
let isDragging = false;
let startX = 0;
let startY = 0;
let offsetX = 0;
let offsetY = 0;
let calculating = false;
let animating = false;


// -1 = playerMarker, 0 = waypoint, 0+n = blips
let selectedBlip = -1;

// Map movement
$(document).on("mousedown", function (event) {
    if ($(event.target).hasClass("map-blip")) return;
    if (event.button === 0 && !animating) {
        $('.body').css("cursor", "grabbing");
        isDragging = true;
        startX = event.pageX;
        startY = event.pageY;
        offsetX = parseFloat(mapWrapper.css("left"));
        offsetY = parseFloat(mapWrapper.css("bottom"));
        mapWrapper.css("transition", "none");
    }
});

$(document).on("mousemove", function (event) {
    recalculateBlips();
    if (isDragging) {
        let currentX = event.pageX;
        let currentY = event.pageY;
        let diffX = currentX - startX;
        let diffY = currentY - startY;

        diffX /= scale;
        diffY /= scale;

        let newLeft = offsetX + diffX;
        let newTop = offsetY - diffY;

        mapWrapper.css({
            left: newLeft,
            bottom: newTop
        });
    }
});

$(document).on("mouseup", function (event) {
    if (event.button === 0) {
        $('.body').css("cursor", "grab");

        isDragging = false;
        mapWrapper.css("transition", "all 0.5s ease-in-out");
    }
});

// Map zoom
$(document).on("wheel", ".map-container", function (e) {
    // if (animating) return;
    animating = true;
    let delta = e.originalEvent.deltaY;
    let newScale;

    if (delta < 0) {
        newScale = scale + zoomAmount;
    } else {
        newScale = scale - zoomAmount;
    }

    setMapScale(newScale);
    setTimeout(() => (animating = false), 300);
});

//$(document).on("keydown", function (e) {
$(document).on("keyup",function(e){  
if (e.key == "m" || e.key == "M") {
        //$(".wrapper").addClass("hidden");
        Events.Call("ExitMap");
        //Events.Call("DisableControls");
    }
    // Flecha hacia arriba, ir al blip anterior, flecha abajo, ir al siguiente
    if (e.key == "ArrowUp") {
        if (selectedBlip == -1) {
            selectedBlip = persistentBlips.length - 1;
        } else {
            selectedBlip--;
        }
    } else if (e.key == "ArrowDown") {
        if (selectedBlip == persistentBlips.length - 1) {
            selectedBlip = -1;
        } else {
            selectedBlip++;
        }
    }

    if (selectedBlip == -1) {
        let playerCoords = JSON.parse(playerMarker.data("coords"));
        goToCoords(playerCoords);
        $('.blip').removeClass("active");
    } else {
        let blipId = persistentBlips[selectedBlip].id;
        let blip = $(`.map-blip[data-id="${blipId}"]`);
        let blipCoords = JSON.parse(blip.data("coords"));
        $('.blip[data-id="' + blipId + '"]').addClass("active").siblings().removeClass("active");
        goToCoords(blipCoords);
    }
    setTimeout(() => recalculateBlips(), 500);
});

$(document).on("mousedown", ".map-container", function (event) {
    if (event.button === 2) {
        event.preventDefault();

        let clickX = event.pageX;
        let clickY = event.pageY;

        let mapWrapperPos = mapWrapper.position();
        let mapContainerPos = mapContainer.position();

        let mapWrapperBottom = (mapWrapperPos.top / scale) + mapWrapper.height();
        let mapX = (clickX - mapContainerPos.left) / scale - (mapWrapperPos.left / scale);
        let mapY = (clickY - mapContainerPos.top) / scale - mapWrapperBottom;


        goToCoords({ x: mapX, y: mapY });
    }
});

function goToCoords(coords) {
    let { x, y } = coords;
    console.log(x, y)
    // Obtener las dimensiones del contenedor del mapa y el tamaño de la ventana del navegador
    let mapContainerWidth = mapContainer.width();
    let mapContainerHeight = mapContainer.height();

    // Ajustar las coordenadas en función de la escala y el tamaño del mapWrapper
    let adjustedX = mapContainerWidth / 2 - x;
    let adjustedY = mapContainerHeight / 2 + y;

    // Mover el mapWrapper al nuevo left y bottom
    mapWrapper.css({
        left: adjustedX,
        bottom: adjustedY
    });
}

function setMapScale(s) {
    if (s < 0.4) {
        return;
    }
    if (s > 3) {
        return;
    }

    let actualPlayerMarkerTransform = playerMarker.css("transform");

    // playerMarker.css("transform", "scale(" + (1 / s) + ")");
    // playerMarker.css("transform", actualPlayerMarkerTransform + " scale(" + (1 / s) + ")");
    $(".map-blip").css("transform", "scale(" + (1 / s) + ")");

    mapContainer.css({
        transformOrigin: "center",
        transform: "translate(-50%, -50%) scale(" + s + ")"
    });
    // si s es mayo a scale igualar playerMarkerScale a playerMarkerScale - zoomAmount. Si es menor, igualar a playerMarkerScale + zoomAmount
    if (s > scale) {
        playerMarkerScale -= zoomAmount;
    } else {
        playerMarkerScale += zoomAmount;
    }

    scale = s;

}

function updatePlayerPos(playerCoords, playerHeading) {
    let { x, y } = barycentricInterpolation(playerCoords);
    playerMarker.data("coords", JSON.stringify({ x: x, y: -y }));

    let playerMarkerWidth = playerMarker.width();
    let playerMarkerHeight = playerMarker.height();

    x -= playerMarkerWidth / 2;
    y -= playerMarkerHeight / 2;

    playerMarker.css({
        left: x,
        bottom: y,
        transform: "rotate(" + (playerHeading + 360) + "deg) rotate(-65deg) rotate(-90deg) scale(" + (1 / scale) + ")" /* + " scale(" + playerMarkerScale + ")" */
    });
}

function setBlips(blips) {
    persistentBlips = blips;
    blipsContainer.empty();
    blips.forEach(blip => {
        let { name, coords, imgUrl, id } = blip;
        let newBlip = `<div class="blip" data-id="${id}">
            <p>${name}</p>
            <img src="${imgUrl}" alt="">
        </div>`;
        blipsContainer.append(newBlip);

        let mapBlip = `<img data-id="${id}" src="${imgUrl}" alt="" class="map-blip">`;
        mapWrapper.append(mapBlip);
        console.log("set blips")
    });

    // configurar las coordenadas de los map-lip aca afuera

    persistentBlips.forEach(blip => {
        let { x, y } = barycentricInterpolation(blip.coords);
        let mapBlip = $(`.map-blip[data-id="${blip.id}"]`);
        mapBlip.data("coords", JSON.stringify({ x: x, y: -y }));

        let mapBlipWidth = mapBlip.width();
        let mapBlipHeight = mapBlip.height();

        x -= mapBlipWidth / 2;
        y -= mapBlipHeight / 2;

        mapBlip.css({
            left: x,
            bottom: y
        });
    });

    // on clicl blip, go to coords
    $(".map-blip").on("click", function () {
        let blipCoords = JSON.parse($(this).data("coords"));
        goToCoords(blipCoords);
    });
}

function recalculateBlips() {
    if (calculating) return;
    calculating = true;
    var viewportWidth = $(window).width();
    var viewportHeight = $(window).height();
    var centerScreenX = viewportWidth / 2;
    var centerScreenY = viewportHeight / 2;

    var maxDistance = Math.sqrt(Math.pow(centerScreenX, 2) + Math.pow(centerScreenY, 2));

    $(".map-blip").each(function () {
        var $blip = $(this);
        var blipOffset = $blip.offset();
        var blipWidth = $blip.outerWidth();
        var blipHeight = $blip.outerHeight();
        var blipCenterX = blipOffset.left + blipWidth / 2;
        var blipCenterY = blipOffset.bottom + blipHeight / 2;

        var distanceToCenter = Math.sqrt(Math.pow(blipCenterX - centerScreenX, 2) + Math.pow(blipCenterY - centerScreenY, 2));
        var opacity = 1 - distanceToCenter / maxDistance;

        $blip.toggleClass("active", distanceToCenter <= 0.04 * maxDistance * scale);
        // $blip.css("opacity", opacity);
        setTimeout(() => (calculating = false), 100);
    });
}

function barycentricInterpolation({ x, y }) {
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
// bank, police, hotel,
// policia, aparteamento, vehicle shop, hud, park
/* const hardcodedBlips = [
    {
        id: 0,
        name: "supermarket",
        coords: { x: 160245, y: -328033 },
        imgUrl: "./media/icons/shop-icon.svg"
    },
    {
        id: 1,
        name: "food",
        coords: { x: 154332, y: -374728 },
        imgUrl: "./media/icons/food-icon.svg"
    },
    {
        id: 2,
        name: "bar",
        coords: { x: 161250, y: -387233 },
        imgUrl: "./media/icons/bar-icon.svg"
    },
    {
        id: 3,
        name: "clothing",
        coords: { x: 730, y: 2380 },
        imgUrl: "./media/icons/clothing-icon.svg"
    },
    {
        id: 4,
        name: "car shop",
        coords: { x: 700, y: 1000 },
        imgUrl: "./media/icons/cars-icon.svg"
    },
    {
        id: 5,
        name: "medicine",
        coords: { x: 300, y: 4000 },
        imgUrl: "./media/icons/medicine-icon.svg"
    },
    {
        id: 6,
        name: "weapon shop",
        coords: { x: 308, y: 3150 },
        imgUrl: "./media/icons/gun-icon.svg"
    },
    {
        id: 7,
        name: "parking",
        coords: { x: 400, y: 1200 },
        imgUrl: "./media/icons/parking-icon.svg"
    },
    {
        id: 8,
        name: "hotel",
        coords: { x: 200, y: 3000 },
        imgUrl: "./media/icons/hotel-icon.svg"
    },
    {
        id: 9,
        name: "service",
        coords: { x: 600, y: 2500 },
        imgUrl: "./media/icons/service-icon.svg"
    },
    {
        id: 10,
        name: "gas station",
        coords: { x: 124, y: 4000 },
        imgUrl: "./media/icons/gas-station-icon.svg"
    },
    {
        id: 11,
        name: "police",
        coords: { x: 300, y: 1000 },
        imgUrl: "./media/icons/police-icon.svg"
    },
    {
        id: 12,
        name: "park",
        coords: { x: 485, y: 2021 },
        imgUrl: "./media/icons/park-icon.svg"
    },
    {
        id: 13,
        name: "bank",
        coords: { x: 320, y: 2000 },
        imgUrl: "./media/icons/bank-icon.svg"
    },
    {
        id: 14,
        name: "casino",
        coords: { x: 480, y: 3000 },
        imgUrl: "./media/icons/casino-icon.svg"
    },
    {
        id: 15,
        name: "beach",
        coords: { x: 400, y: 1500 },
        imgUrl: "./media/icons/beach-icon.svg"
    },
    {
        id: 16,
        name: "office",
        coords: { x: 250, y: 2500 },
        imgUrl: "./media/icons/business-icon.svg"
    },
    {
        id: 17,
        name: "education",
        coords: { x: 200, y: 3819 },
        imgUrl: "./media/icons/education-icon.svg"
    },
    {
        id: 18,
        name: "port",
        coords: { x: 600, y: 1000 },
        imgUrl: "./media/icons/port-icon.svg"
    },
    {
        id: 19,
        name: "airport",
        coords: { x: 350, y: 3500 },
        imgUrl: "./media/icons/airport-icon.svg"
    }
]; */

const hardcodedBlips = [
    {
        id: 1,
        name: "food",
        coords: { x: 184204, y: -423441 },
        imgUrl: "./media/icons/food-icon.svg"
    },
    {
        id: 4,
        name: "car shop",
        coords: { x: 134290.0, y: -423646.1 },
        imgUrl: "./media/icons/cars-icon.svg"
    },
    {
        id: 5,
        name: "store",
        coords: { x: 131171.5, y: -400192.2 },
        imgUrl: "./media/icons/Shop-icon.svg"
    },
    {
        id: 6,
        name: "casino",
        coords: { x:  147784.4, y: -426535.8 },
        imgUrl: "./media/icons/Casino-icon.svg"
    },
    {
        id: 8,
        name: "hotel",
        coords: { x: 154326, y: -394080 },
        imgUrl: "./media/icons/hotel-icon.svg"
    },
    {
        id: 11,
        name: "police",
        coords: { x: 144335, y: -366526 },
        imgUrl: "./media/icons/police-icon.svg"
    },
    {
        id: 12,
        name: "park",
        coords: { x: 165598, y: -378457 },
        imgUrl: "./media/icons/park-icon.svg"
    },
    {
        id: 13,
        name: "bank",
        coords: { x: 174845, y: -410734 },
        imgUrl: "./media/icons/bank-icon.svg"
    },
    {
        id: 14,
        name: "garage",
        coords: { x: 158913.7, y: -405678.7 },
        imgUrl: "./media/icons/Parking-icon.svg"
    },
];
setBlips(hardcodedBlips);
setMapScale(1);
playerMarker.data("coords", JSON.stringify({ x: 2181, y: 556 }));



Events.Subscribe("helix-hud:AddBlip",function(blip){
    console.log("ADD BLIPPY BLIP BLIP!")
    hardcodedBlips.push(blip)
    setBlips(hardcodedBlips);
});

Events.Subscribe("helix-hud:RemoveBlip",function(n){
    hardcodedBlips.shift(n)
    setBlips(hardcodedBlips);
});


Events.Subscribe("ShowMap", () => {
    $('.wrapper').removeClass("hidden")
    let playerCoords = JSON.parse(playerMarker.data("coords"));
    goToCoords(playerCoords);
})

Events.Subscribe("UpdatePlayerPos", (playerX, playerY, playerHeading) => {
    // updatePlayerPos
    let playerCoords = { x: playerX, y: playerY }
    updatePlayerPos(playerCoords, playerHeading)
})