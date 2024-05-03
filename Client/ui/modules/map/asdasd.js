let gameWorldWidth = 10000;
let gameWorldHeight = 10000;
let mapImageWidth = 4589;
let mapImageHeight = 4588;
let scale = 1;


function setMapScale(s) {
  if (s < 0.1) {
    s = 0.1;
  }
  mapImageWidth = 4589 * s;
  mapImageHeight = 4588 * s;
  $(".map-wrapper .map").css("width", mapImageWidth + "px");
  $(".map-wrapper .map").css("height", mapImageHeight + "px");
  scale = s;
  console.log("scale: " + scale)
}

function updatePlayerPos(playerCoords, playerHeading) {
  let minimap = $(".map-wrapper .map");
  let playerMarker = $(".player-marker");

  let markerX = (playerCoords.x / gameWorldWidth) * mapImageWidth;
  let markerY = (playerCoords.y / gameWorldHeight) * mapImageHeight;

  let mapX = markerX - (minimap.width() / 2);
  let mapY = markerY - (minimap.height() / 2);

  playerMarker.css("transform", "rotate(" + playerHeading-35 + "deg)")

  console.log(mapX, mapY)
  minimap.css("left", "-" + mapX + "px");
  minimap.css("bottom", "-" + mapY + "px");
}

let playerCoords = { x: 50, y: 50 };
let playerHeading = 0;

let holdingKeys = [
  {
    key: 87,
    isHolding: false,
  },
  {
    key: 83,
    isHolding: false,
  },
  {
    key: 65,
    isHolding: false,
  },
  {
    key: 68,
    isHolding: false,
  },
]

$(document).ready(function () {

  $(document).keydown(function (e) {
    for (let i = 0; i < holdingKeys.length; i++) {
      if (e.keyCode == holdingKeys[i].key) {
        holdingKeys[i].isHolding = true;
      }
    }
  });

  $(document).keyup(function (e) {
    for (let i = 0; i < holdingKeys.length; i++) {
      if (e.keyCode == holdingKeys[i].key) {
        holdingKeys[i].isHolding = false;
      }
    }
  });

});
/* 
setInterval(function () {
  console.log(playerCoords.x, playerCoords.y)
  for (let i = 0; i < holdingKeys.length; i++) {
    if (holdingKeys[i].isHolding) {
      switch (holdingKeys[i].key) {
        case 87: //w
          playerCoords.y += 1;
          break;
        case 83: //s
          playerCoords.y -= 1;
          break;
        case 65: //a
          playerCoords.x -= 1;
          break;
        case 68: //d
          playerCoords.x += 1;
          break;
      }
    }
  }
  // validate limits
  if (playerCoords.x < 0) {
    playerCoords.x = 0;
  }
  if (playerCoords.x > gameWorldWidth) {
    playerCoords.x = gameWorldWidth;
  }
  if (playerCoords.y < 0) {
    playerCoords.y = 0;
  }
  if (playerCoords.y > gameWorldHeight) {
    playerCoords.y = gameWorldHeight;
  }
  updatePlayerPos(playerCoords, playerHeading);
}, 50); */



$("button.zoom.in").click(function () {
  setMapScale(scale + 1);
});

$("button.zoom.out").click(function () {
  setMapScale(scale - 1);
});

setMapScale(1);


Events.Subscribe("UpdatePlayerPos", function (x, y, playerHeading) {
  updatePlayerPos({x, y}, playerHeading);
});