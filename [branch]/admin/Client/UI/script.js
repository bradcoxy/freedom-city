let players = [];
let selectedPlayer = null;

const searchBar = document.getElementById("searchBar");
const playerList = document.getElementById("playerList");


function updatePlayerList() {
  const filter = searchBar.value.toLowerCase();
  playerList.innerHTML = "";

  for (const [index, player] of players.entries()) {
    console.log("Processing player:", JSON.stringify(player, null, 2));

    if (player.name.toLowerCase().includes(filter)) {
      const listItem = document.createElement("li");
      listItem.textContent = player.name;
      listItem.id = `player-${index}`;
      playerList.appendChild(listItem);
    }
  }
}

function updateSelectedPlayerUI(newSelectedPlayer) {
  const playerListItems = document.querySelectorAll('#playerList li');
  playerListItems.forEach((item) => {
    item.classList.remove('selected-player');
  });

  newSelectedPlayer.classList.add('selected-player');
}


searchBar.addEventListener("input", () => {
  updatePlayerList();
});


function updatePlayerInfo(playerInfo) {
  let formattedText = "";
  formattedText += "<strong>Source:</strong> " + playerInfo.Source + "<br>";
  formattedText += "<strong>Helix Name:</strong> " + playerInfo.HelixName + "<br>";
  formattedText += "<strong>Helix Identifier:</strong> " + playerInfo.HelixIdentifier + "<br>";
  formattedText += "<strong>Role Play Name:</strong> " + playerInfo.RolePlayName + "<br>";
  formattedText += "<strong>Bank:</strong> " + playerInfo.Bank + "<br>";
  formattedText += "<strong>Cash:</strong> " + playerInfo.Cash + "<br>";
  formattedText += "<strong>Job:</strong> " + playerInfo.Job + "<br>";
  formattedText += "<strong>Date of Birth:</strong> " + playerInfo.DateOfBirth + "<br>";
  formattedText += "<strong>Gender:</strong> " + playerInfo.Gender + "<br>";
  formattedText += "<strong>Nationality:</strong> " + playerInfo.Nationality + "<br>";
  formattedText += "<strong>Phone Number:</strong> " + playerInfo.PhoneNumber + "<br>";
  formattedText += "<strong>XP:</strong> " + playerInfo.XP + "<br>";
  formattedText += "<strong>Rank:</strong> " + playerInfo.Rank + "<br>";

  document.getElementById("playerInfo").innerHTML = formattedText;
}

playerList.addEventListener("click", (e) => {
  if (e.target.tagName === "LI") {
    const playerIndex = parseInt(e.target.id.split("-")[1]);
    selectedPlayer = players[playerIndex];

    console.log("Selected player:", JSON.stringify(selectedPlayer, null, 2));
    updateSelectedPlayerUI(e.target);

    console.log(selectedPlayer.player, selectedPlayer.identifier);

    Events.Call("GetPlayerInfo", selectedPlayer);
  }
});



Events.Subscribe("UpdatePlayerInfo", (playerInfo) => {
  console.log(playerInfo);
  updatePlayerInfo(playerInfo);
});

Events.Subscribe('AdminMenu:OpenUI', (state, playersList, playerCount) => {
  console.log("PlayersList:", JSON.stringify(playersList, null, 2));
  document.getElementById("screen").style.display = state ? 'block' : 'none';
  players = playersList;
  updatePlayerList();
});



document.addEventListener("DOMContentLoaded", () => {
  document.querySelector('.go-to').addEventListener('click', () => {
    console.log('Go to clicked');
    Events.Call("GoToPlayer", selectedPlayer.identifier);
  });

  document.querySelector('.bring').addEventListener('click', () => {
    console.log('Bring clicked');
    Events.Call("BringPlayer", selectedPlayer.identifier);

  });

  document.querySelector('.kill').addEventListener('click', () => {
    console.log('Kill clicked');
    Events.Call("KillPlayer", selectedPlayer.identifier);
  });

  document.querySelector('.revive').addEventListener('click', () => {
    console.log('REvive clicked');
    Events.Call("RevivePlayer", selectedPlayer.identifier);
  });

  document.querySelector('.give-car').addEventListener('click', () => {
    const carSelect = document.getElementById('carSelect');
    const selectedCar = carSelect.options[carSelect.selectedIndex].value;

    Events.Call("GiveCar", selectedPlayer.identifier, selectedCar);
  });


  document.querySelector('#noclip').addEventListener('click', () => {
    console.log('noclip clicked');
    Events.Call("ToggleNoclip", selectedPlayer.identifier);
  });


  document.querySelector('.kick').addEventListener('click', () => {
    const kickReason = document.getElementById('kickReason').value.trim();

    if (kickReason.length > 0) {
      console.log('kick clicked');
      Events.Call("KickPlayer", selectedPlayer.identifier, kickReason);
    } else {
      console.log('No kick reason provided');
    }
  });

  document.querySelector('.set-job').addEventListener('click', () => {
    const job = document.getElementById('jobName').value.trim();

    if (job.length > 0) {
      console.log('job clicked');
      Events.Call("SetPlayerJob", selectedPlayer.identifier, job);
    } else {
      console.log('No job provided');
    }
  });

  // document.querySelector('.give-bank').addEventListener('click', () => {
  //   const bank = document.getElementById('bank').value.trim();

  //   if (bank.length > 0) {
  //     Events.Call("GiveAccountMoney", selectedPlayer.identifier, "_bank", bank);
  //   } else {
  //     console.log('No valid bank amount provided');
  //   }
  // });

  // document.querySelector('.give-cash').addEventListener('click', () => {
  //   const cash = document.getElementById('cash').value.trim();

  //   if (cash.length > 0) {
  //     Events.Call("GiveAccountMoney", selectedPlayer.identifier, "_cash", cash);
  //   } else {
  //     console.log('No valid cash amount provided');
  //   }
  // });

  document.querySelector('.give-godmode').addEventListener('click', () => {
    console.log('godMode clicked');
    Events.Call("ToggleGodMode", selectedPlayer.identifier);
  });

  document.querySelector('.toggle-visibility').addEventListener('click', () => {
    console.log('ToggleVisibility clicked');
    Events.Call("ToggleVisibility", selectedPlayer.identifier);
  });

  document.querySelector('.fix-vehicle').addEventListener('click', () => {
    console.log('Fixvehicle clicked');
    Events.Call("FixVehicle", selectedPlayer.identifier);
  });

  document.querySelector('.delete-vehicle').addEventListener('click', () => {
    console.log('deleteVehicle clicked');
    Events.Call("DeleteVehicle", selectedPlayer.identifier);
  });
});


function handleAccountMoney(buttonSelector, accountType, operation) {
  document.querySelector(buttonSelector).addEventListener('click', () => {
    const inputElement = document.getElementById(accountType);
    const amount = inputElement.value.trim();

    if (amount.length > 0) {
      Events.Call("HandleAccountMoney", selectedPlayer.identifier, accountType, operation, amount);
    } else {
      console.log('No valid amount provided');
    }
  });
}
