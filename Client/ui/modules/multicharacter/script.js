// General

// Character selector
$('.character-list .character').click(function () {
  $('.character-list .character').removeClass('selected');
  $(this).addClass('selected');
});

// Date Picker Functionality
const months = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

let selectedDay, selectedMonth = 0, selectedYear = 2000;

function updateDateDisplay() {
  if (selectedDay && selectedMonth >= 0 && selectedYear) {
    $('.field[data-type="birthdate"] .birthdate-selected').text(
      `${selectedMonth + 1}/${selectedDay}/${selectedYear}`
    );
  }
}

function populateDays(month, year) {
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const daysContainer = $('.dropdown-picker .days');
  daysContainer.empty();
  for (let i = 1; i <= daysInMonth; i++) {
    daysContainer.append(`<div class="day">${i}</div>`);
  }
}

function populateYears() {
  const yearContainer = $('.dropdown-picker .years .year');
  yearContainer.text(selectedYear);
}

function changeMonth(direction) {
  if (direction === 'next') {
    selectedMonth = (selectedMonth + 1) % 12;
  } else if (direction === 'prev') {
    selectedMonth = (selectedMonth + 11) % 12;
  }
  $('.dropdown-picker .month').text(months[selectedMonth]);
  populateDays(selectedMonth, selectedYear);
}

function changeYear(direction) {
  if (direction === 'next') {
    selectedYear++;
  } else if (direction === 'prev') {
    selectedYear--;
  }
  populateYears();
  populateDays(selectedMonth, selectedYear);
}

function setCharacterList(characters) {
  let characterList = $('.character-list');
  characterList.empty();

  if (characters.length == null || characters.length === 0) {
    characterList.append(`<div class="new-character">
      <div>
        <span>create</span>
        <p>new character</p>
      </div>
      <img src="./media/new-char-button.svg" alt="">
      <img src="./media/char-bg.png" alt="" class="bg">
    </div>`);
    return;
  }

  characters.forEach(character => {
    console.log("Character: ", character)
    console.log("Character ID: ", JSON.stringify(character.identifier))
    let newCharacter = $(`
      <div class="character" data-id="${character.identifier}">
        <div>
          <span class="id">#${character.identifier}</span>
          <p>${character.first_name} ${character.last_name}</p>
        </div>
        <img src="./media/char.svg" alt="">
        <img src="./media/selected-char-bg.png" alt="" class="selected-bg">
        <img src="./media/char-bg.png" alt="" class="bg">
      </div>`);
    characterList.append(newCharacter);

    newCharacter.click(function () {
      $('body').removeClass('selecting').addClass('selected');
      $('.character-list .character').removeClass('selected');
      $(this).addClass('selected');
      selectCharacter(character);
    });
  });
  characterList.append(`<div class="new-character">
    <div>
      <span>create</span>
      <p>new character</p>
    </div>
    <img src="./media/new-char-button.svg" alt="">
    <img src="./media/char-bg.png" alt="" class="bg">
  </div>`);



  $('.new-character').click(function () {
    $('body').removeClass('selecting selected').addClass('registering');
    Events.Call('CREATE_CHARACTER_CAMERA')
  });

}

$(document).on('click', '.dropdown-picker .days .day', function () {
  $('.dropdown-picker .days .day').removeClass('selected');
  $(this).addClass('selected');
  selectedDay = $(this).text();
  updateDateDisplay();
});

$(document).on('click', '.dropdown-picker .months .prev', function () {
  changeMonth('prev');
});

$(document).on('click', '.dropdown-picker .months .next', function () {
  changeMonth('next');
});

$(document).on('click', '.dropdown-picker .years .prev', function () {
  changeYear('prev');
});

$(document).on('click', '.dropdown-picker .years .next', function () {
  changeYear('next');
});

$(document).on('click', '.play-button button', function () {
  $('body').removeClass('selecting').addClass('selected');
});

// Initialize Date Picker
changeMonth('init');
changeYear('init');

// Nationality Dropdown Functionality
function populateDropdown() {
  let dropdownList = $('.dropdown-list');
  dropdownList.empty();
  nationalities.forEach((country, index) => {
    dropdownList.append(`
            <div class="dropdown-item ${index === 0 ? 'prev' : index === 1 ? 'one' : index === 2 ? 'two' : index === 3 ? 'three' : index === 4 ? 'four' : index === 5 ? 'five' : 'next'}">
                <p>${country}</p>
                <img src="./media/flag.svg" alt="">
            </div>
        `);
  });
}

function updateDropdownClasses() {
  var items = $('.dropdown-item');
  items.each(function (index, item) {
    $(item).attr('class', 'dropdown-item ' +
      (index === 0 ? 'prev' :
        index === 1 ? 'one' :
          index === 2 ? 'two' :
            index === 3 ? 'three' :
              index === 4 ? 'four' :
                index === 5 ? 'five' : 'next'));
  });
}

function moveItems(direction) {
  var items = $('.dropdown-item');
  if (direction === 'down') {
    var firstItem = items.first();
    firstItem.appendTo('.dropdown-list');
  } else if (direction === 'up') {
    var lastItem = items.last();
    lastItem.prependTo('.dropdown-list');
  }
  updateDropdownClasses();
}

function selectCountryByKey(key) {
  var items = $('.dropdown-item');
  var dropdownList = $('.dropdown-list');
  var indexToSelect = -1;

  nationalities.forEach((country, index) => {
    if (country.charAt(0).toLowerCase() === key.toLowerCase() && indexToSelect === -1) {
      indexToSelect = index;
    }
  });

  if (indexToSelect > -1) {
    dropdownList.empty();
    var startIndex = Math.max(0, indexToSelect - 2);
    var endIndex = Math.min(nationalities.length, startIndex + 7);

    for (var i = startIndex; i < endIndex; i++) {
      dropdownList.append(`
              <div class="dropdown-item ${i === startIndex ? 'prev' : i === startIndex + 1 ? 'one' : i === startIndex + 2 ? 'two' : i === startIndex + 3 ? 'three' : i === startIndex + 4 ? 'four' : i === startIndex + 5 ? 'five' : 'next'}">
                  <p>${nationalities[i]}</p>
                  <img src="./media/flag.svg" alt="">
              </div>
          `);
    }
    updateDropdownClasses();
    $('.field[data-type="nationality"] .dropdown-item-selected').text(nationalities[indexToSelect]);
  }
}

function selectCharacter(character) {
  $('body').removeClass('selected').addClass('selecting')

  setTimeout(() => {
    $('.info[data-type="cash-money"] .lix p').html(character.cash);
    $('.info[data-type="bank-money"] .lix p').html(character.bank);
    $('.info[data-type="phone-number"] .value').html(character.phone_number);
    $('.info[data-type="gender"] .value').html(character.gender);
    $('.info[data-type="job"] .value').html(character.job);
    $('.info[data-type="nationality"] .value').html(character.nationality);
    $('.info[data-type="birth-date"] .value').html(character.date_of_birth);

    $('.character-name .name').html(`${character.first_name} <span>${character.last_name}</span>`);
    setTimeout(() => {
      $('body').removeClass('selecting').addClass('selected')
    }, 200);
  }, 50);


}

populateDropdown();

$(document).on('click', '.dropdown-item.one, .dropdown-item.two', function () {
  moveItems('up');
});

$(document).on('click', '.dropdown-item.four, .dropdown-item.five', function () {
  moveItems('down');
});

$(document).on('click', '.dropdown-item.three', function () {
  var selectedCountry = $(this).find('p').text();
  $('.field[data-type="nationality"] .dropdown-item-selected').text(selectedCountry);
  $('.field .dropdown').removeClass('active');
  $('.field .dropdown button').removeClass('active');
});

$('.field .dropdown button').click(function () {
  $(this).toggleClass('active');
  $(this).parent().toggleClass('active');
});

$(document).on('click', '.dropdown-item', function () {
  var selectedCountry = $(this).find('p').text();
  $('.field[data-type="nationality"] .dropdown-item-selected').text(selectedCountry);
});

$(document).on('click', '.dropdown-item.prev, .dropdown-item.next', function () {
  moveItems('down');
});

$(document).keydown(function (event) {
  if ($('.field .dropdown').hasClass('active')) {
    var key = event.key;
    if (key.length === 1 && key.match(/[a-z]/i)) {
      // selectCountryByKey(key);
    } else if (key === "ArrowDown") {
      moveItems('down');
    } else if (key === "ArrowUp") {
      moveItems('up');
    }
  }
});

$('.dropdown-list').on('mousewheel DOMMouseScroll', function (event) {
  if ($('.field .dropdown').hasClass('active')) {
    var delta = event.originalEvent.wheelDelta || -event.originalEvent.detail;
    if (delta > 0) {
      moveItems('up');
    } else {
      moveItems('down');
    }
  }
});

$(document).click(function (event) {
  if (!$(event.target).closest('.field .dropdown, .field .dropdown button').length) {
    $('.field .dropdown').removeClass('active');
    $('.field .dropdown button').removeClass('active');
  }
});

$(document).on('click', '.new-character', function () {
  $('body').removeClass('selecting selected').addClass('registering');
  Events.Call('CREATE_CHARACTER_CAMERA')
});

$(document).on('click', '.actions .back', function () {
  $('body').removeClass('registering').addClass('selecting');
});

$(document).on('click', '.gender-selector .gender', function () {
  $('.gender').removeClass('selected');
  $(this).addClass('selected');
  let isMale = $(this).attr('data-type') === 'male';
  Events.Call('CHANGE_GENDER', isMale);
});

$(document).on('click', '.actions .confirm', function () {
  let characterData = {
    first_name: $('#first-name').val(),
    last_name: $('#last-name').val(),
    date_of_birth: $('.field[data-type="birthdate"] .birthdate-selected').text(),
    nationality: $('.field[data-type="nationality"] .dropdown-item-selected').text(),
    gender: $('.gender[data-type="male"]').hasClass('selected'),
    cid: $('.character-list .character').length + 1
  }


  characterData.gender == 1 ? characterData.gender = 'Male' : characterData.gender = 'Female'

  console.log("Character Data: ", JSON.stringify(characterData))

  if (!characterData.first_name) return
  if (!characterData.last_name) return
  if (!characterData.nationality) return
  if (!characterData.date_of_birth) return
  if (!characterData.gender) return
  if (!characterData.cid) return

  $('body').removeClass('registering').addClass('hidden');

  Events.Call('CREATE_CHARACTER', characterData);
});

$(document).on('click', '.actions .cancel', function () {
  $('body').removeClass('registering').addClass('hidden');
  Events.Call('CHOOSE_CHARACTER_CAMERA')
});

$(document).on('click', '.play-button button', function () {
  $('body').addClass('hidden');
  let index = $('.character-list .character.selected').index();
  Events.Call('CHOOSE_CHARACTER', index);
});

// Events
Events.Subscribe('Initialise', (characterList) => {
  console.log("Character List: ", JSON.stringify(characterList.characterData.characters))
  setCharacterList(characterList.characterData.characters)
  $('body').removeClass('hidden selected registering').addClass('selecting');
  Events.Call('CHOOSE_CHARACTER_CAMERA')

})

// Example Usage
let hardcodedCharacterList = [
  {
    identifier: 1,
    firstName: 'John',
    lastName: 'Doe',
    cash: 1000,
    bank: 5000,
    phone_number: 1234567890,
    gender: 'Male',
    job: 'Unemployed',
    nationality: 'Argentinian',
    dateOfBirth: '11/05/2010',
  },
  {
    identifier: 2,
    firstName: 'Jane',
    lastName: 'Doe',
    cash: 1000,
    bank: 5000,
    phone_number: 123456,
    gender: 'Female',
    job: 'Police',
    nationality: 'Peruvian',
    dateOfBirth: '04/02/1847',

  }
]
setCharacterList(hardcodedCharacterList)

$('body').removeClass('hidden selected registering').addClass('selecting');