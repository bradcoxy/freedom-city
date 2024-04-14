const transactionlink = document.querySelector('.transaction');
const overviewlink = document.querySelector('.overview');
const settinglink = document.querySelector('.setting');
const transactioncontent = document.querySelector('.transactioncontent');
const overviewcontent = document.querySelector('.overviewcontent');
const settingcontent = document.querySelector('.settingcontent');
const withdrawcontent = document.querySelector('.withdrawcontent');
const depositcontent = document.querySelector('.depositcontent');
const transfercontent = document.querySelector('.transfercontent');
const transferlink = document.querySelector('.transfer');
const depositlink = document.querySelector('.deposit');
const withdrawlink = document.querySelector('.withdraw');
const withdrawinput = document.querySelector('#withdrawinput');
const depositinput = document.querySelector('#depositinput');
const transferinput = document.querySelector("#transferinput")

const links = [
    {
        tab: overviewlink,
        content: overviewcontent
    },
    {
        tab: transactionlink,
        content: transactioncontent
    },
    {
        tab: settinglink,
        content: settingcontent
    }
]
const actionlinks = [
    {
        tab: withdrawlink,
        content: withdrawcontent
    },
    {
        tab: depositlink,
        content: depositcontent
    },
    {
        tab: transferlink,
        content: transfercontent
    }
] 

let newProfileData = {}

links.map((link) => {
    link.tab.addEventListener('click', () => {
        link.tab.classList.add('tabactive')
        link.content.classList.remove('hidden');
        let restLinks = links.filter((i) => i.tab !== link.tab)
        restLinks.map((i) => {
            i.content.classList.add('hidden')
            i.tab.classList.remove('tabactive')
        });
    })
})
actionlinks.map((link) => {
    link.tab.addEventListener('click', () => {
        link.content.classList.remove('modalhidden');
        let restLinks = actionlinks.filter((i) => i.tab !== link.tab)
        restLinks.map((i) => {
            i.content.classList.add('modalhidden')
        });
    })
})
const cancelModal = () => {
    depositcontent.classList.add('modalhidden');
    withdrawcontent.classList.add('modalhidden');
    transfercontent.classList.add('modalhidden')
}
const confirmWithdraw = () => {
    let amount = Number(withdrawinput.value)

    withdrawcontent.classList.add('modalhidden');
    Events.Call("uiATM", "withdraw", {amount : amount, cardNumber : newProfileData.cardNumber});
    withdrawinput.value = '';
}
const confirmDeposit = () => {
    let amount = Number(depositinput.value)

    depositcontent.classList.add('modalhidden');
    Events.Call("uiATM", "deposit", {amount : amount, cardNumber : newProfileData.cardNumber});
    depositinput.value = '';
}
const confirmTransfer = () => {
    let ibanvalue = String(transferiban.value)
    let amount = Number(transferinput.value)

    transfercontent.classList.add('modalhidden');
    Events.Call("uiATM", "transfer", {amount : amount, iban : ibanvalue, cardNumber : newProfileData.cardNumber});
    transferinput.value = '';
    transferiban.value = '';
}
// HEADER ACCOUNT OWNER
const profilename = document.querySelector('.profilename');
const profilebalance = document.querySelector('.profilebalance');
const profileimage = document.querySelector('.profileimage')

let profileData = {
    name: 'Idris Jack',
    balance: '$600',
    profileurl: 'images/profileimage.svg' 
}
const setProfileData = (name, balance, url) => {
    profilename.innerHTML = name;
    profilebalance.innerHTML = '$' + balance;
    profileimage.src = url
}
setProfileData(profileData.name, profileData.balance, profileData.profileurl)


// OVERVIEW CARDS DETAILS
const cardbalance = document.querySelector('.cardbalance');
const cardnumber = document.querySelector('.cardnumber');
const pushCardDetails = (balance, number) => {
    cardbalance.innerHTML = '$' + balance,
    cardnumber.innerHTML = number
}
pushCardDetails('8,000.00', '3456 7456 8976 2345')

// OVERVIEW ACCOUNT DETAILS
const accountnumber = document.querySelector('.accountnumber');
const IBAN = document.querySelector('.iban');
const swiftnumber = document.querySelector('.swiftnumber');
const pushAccountDetails = (account, swiftnum, iban) => {
    accountnumber.innerHTML = account;
    swiftnumber.innerHTML = swiftnum
    IBAN.innerHTML = iban
}
pushAccountDetails('1233 545345 53453', 'HE23HJK2', 'HE23HJK2')

// OVERVIEW TRANSACTIONS
const overviewtransactions = document.querySelector('.pasttransactions');
let transactionsData = [
    {
        transactionid: 10,
        accountname: "ricardo gonzalez",
        amount: 500,
        inflow: true
    },
    {
        transactionid: 11,
        accountname: "James Bond",
        amount: 500,
        inflow: false
    },
    {
        transactionid: 12,
        accountname: "ricardo gonzalez",
        amount: 500,
        inflow: true
    },
    {
        transactionid: 13,
        accountname: "Billie Raymond",
        amount: 200,
        inflow: false
    },
    {
        transactionid: 14,
        accountname: "ricardo gonzalez",
        amount: 500,
        inflow: true
    },
    {
        transactionid: 15,
        accountname: "TEN Hagg",
        amount: 500,
        inflow: true
    },
    {
        transactionid: 16,
        accountname: "ricardo gonzalez",
        amount: 500,
        inflow: true
    },
    {
        transactionid: 17,
        accountname: "rosie gonzalez",
        amount: 500,
        inflow: true
    },
]
const pushOverviewTransactions = (data) => {
    overviewtransactions.innerHTML = '';
    data.slice(0).reverse().map((transaction) => {
        const { accountname, amount, inflow, transactionid } = transaction;
        overviewtransactions.innerHTML += `
        <div class="pasttransaction">
            <p class="narration fontmedium"> <span>from</span> <span class="narrationname semibold">${accountname}</span> </p>
            <p class="transactionamount fontmedium mediumbold ${inflow ? 'green' : 'red'}">  ${inflow ? '+ ' + amount : '- ' + amount} USD</p>
            <div class="download pointer" onclick="downloadTransaction(${transactionid})">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
                    <path d="M20 15C20.2652 15 20.5196 15.1054 20.7071 15.2929C20.8946 15.4804 21 15.7348 21 16V20C21 20.5304 20.7893 21.0391 20.4142 21.4142C20.0391 21.7893 19.5304 22 19 22H5C4.46957 22 3.96086 21.7893 3.58579 21.4142C3.21071 21.0391 3 20.5304 3 20V16C3 15.7348 3.10536 15.4804 3.29289 15.2929C3.48043 15.1054 3.73478 15 4 15C4.26522 15 4.51957 15.1054 4.70711 15.2929C4.89464 15.4804 5 15.7348 5 16V20H19V16C19 15.7348 19.1054 15.4804 19.2929 15.2929C19.4804 15.1054 19.7348 15 20 15ZM12 2C12.2652 2 12.5196 2.10536 12.7071 2.29289C12.8946 2.48043 13 2.73478 13 3V13.243L15.536 10.707C15.6282 10.6115 15.7386 10.5353 15.8606 10.4829C15.9826 10.4305 16.1138 10.4029 16.2466 10.4017C16.3794 10.4006 16.5111 10.4259 16.634 10.4762C16.7568 10.5265 16.8685 10.6007 16.9624 10.6946C17.0563 10.7885 17.1305 10.9001 17.1808 11.023C17.2311 11.1459 17.2564 11.2776 17.2553 11.4104C17.2541 11.5432 17.2265 11.6744 17.1741 11.7964C17.1217 11.9184 17.0455 12.0288 16.95 12.121L12.884 16.187C12.7679 16.3031 12.6301 16.3952 12.4784 16.4581C12.3268 16.5209 12.1642 16.5532 12 16.5532C11.8358 16.5532 11.6732 16.5209 11.5216 16.4581C11.3699 16.3952 11.2321 16.3031 11.116 16.187L7.05 12.121C6.95449 12.0288 6.87831 11.9184 6.8259 11.7964C6.77349 11.6744 6.7459 11.5432 6.74475 11.4104C6.7436 11.2776 6.7689 11.1459 6.81918 11.023C6.86946 10.9001 6.94371 10.7885 7.0376 10.6946C7.1315 10.6007 7.24315 10.5265 7.36605 10.4762C7.48894 10.4259 7.62062 10.4006 7.7534 10.4017C7.88618 10.4029 8.0174 10.4305 8.1394 10.4829C8.26141 10.5353 8.37175 10.6115 8.464 10.707L11 13.243V3C11 2.73478 11.1054 2.48043 11.2929 2.29289C11.4804 2.10536 11.7348 2 12 2Z" fill="#578CFF"/>
                </svg>
            </div>
        </div>
        `
    })
}
pushOverviewTransactions(transactionsData)

// TRANSACTION 
const statscontainer = document.querySelector('.transactionstats');
const totaltransactions = document.querySelector('.transnumber');
let statistics = [
    {
        title: 'transactions',
        amount: '0'
    },
    {
        title: 'income',
        amount: '$0'
    },
    {
        title: 'outcome',
        amount: '$0'
    },
    {
        title: 'earnings',
        amount: '$0'
    }
]
const pushStats = (data) => {
    statscontainer.innerHTML = ''
    data.map((stat) => {
        const { title, amount } = stat;
        statscontainer.innerHTML += `
        <div class="stat">
            <h3 class="stattitle">${title}</h3>
            <p class="statamount">${amount}</p>
        </div>
        `
    })
}
pushStats(statistics);
const setTotalTransactions = (data) => {
    totaltransactions.innerHTML = data
}
setTotalTransactions(0)
// TRANSACTION HISTORY
const transactions = document.querySelector('.transactionshistory');
const pushTransactions = (data) => {
    transactions.innerHTML = '';
    data.slice(0).reverse().map((transaction) => {
        const { accountname, amount, inflow, transactionid } = transaction;
        transactions.innerHTML += `
        <div class="pasttransaction">
            <p class="narration fontmedium"> <span>from</span> <span class="narrationname semibold"> ${accountname} </span> </p>
            <p class="transactionamount fontmedium mediumbold ${inflow ? 'green' : 'red'}">  ${inflow ? '+ ' + amount : '- ' + amount} USD</p>
            <div class="download pointer" onclick="downloadTransaction(${transactionid})">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
                    <path d="M20 15C20.2652 15 20.5196 15.1054 20.7071 15.2929C20.8946 15.4804 21 15.7348 21 16V20C21 20.5304 20.7893 21.0391 20.4142 21.4142C20.0391 21.7893 19.5304 22 19 22H5C4.46957 22 3.96086 21.7893 3.58579 21.4142C3.21071 21.0391 3 20.5304 3 20V16C3 15.7348 3.10536 15.4804 3.29289 15.2929C3.48043 15.1054 3.73478 15 4 15C4.26522 15 4.51957 15.1054 4.70711 15.2929C4.89464 15.4804 5 15.7348 5 16V20H19V16C19 15.7348 19.1054 15.4804 19.2929 15.2929C19.4804 15.1054 19.7348 15 20 15ZM12 2C12.2652 2 12.5196 2.10536 12.7071 2.29289C12.8946 2.48043 13 2.73478 13 3V13.243L15.536 10.707C15.6282 10.6115 15.7386 10.5353 15.8606 10.4829C15.9826 10.4305 16.1138 10.4029 16.2466 10.4017C16.3794 10.4006 16.5111 10.4259 16.634 10.4762C16.7568 10.5265 16.8685 10.6007 16.9624 10.6946C17.0563 10.7885 17.1305 10.9001 17.1808 11.023C17.2311 11.1459 17.2564 11.2776 17.2553 11.4104C17.2541 11.5432 17.2265 11.6744 17.1741 11.7964C17.1217 11.9184 17.0455 12.0288 16.95 12.121L12.884 16.187C12.7679 16.3031 12.6301 16.3952 12.4784 16.4581C12.3268 16.5209 12.1642 16.5532 12 16.5532C11.8358 16.5532 11.6732 16.5209 11.5216 16.4581C11.3699 16.3952 11.2321 16.3031 11.116 16.187L7.05 12.121C6.95449 12.0288 6.87831 11.9184 6.8259 11.7964C6.77349 11.6744 6.7459 11.5432 6.74475 11.4104C6.7436 11.2776 6.7689 11.1459 6.81918 11.023C6.86946 10.9001 6.94371 10.7885 7.0376 10.6946C7.1315 10.6007 7.24315 10.5265 7.36605 10.4762C7.48894 10.4259 7.62062 10.4006 7.7534 10.4017C7.88618 10.4029 8.0174 10.4305 8.1394 10.4829C8.26141 10.5353 8.37175 10.6115 8.464 10.707L11 13.243V3C11 2.73478 11.1054 2.48043 11.2929 2.29289C11.4804 2.10536 11.7348 2 12 2Z" fill="#578CFF"/>
                </svg>
            </div>
        </div>
        `
    })
}
pushTransactions(transactionsData)
// SEARCH TRANSACTION
const transactionsearch = document.querySelector('#searchtransaction');
transactionsearch.addEventListener('input', () => {
    let searchvalue = transactionsearch.value
    if(!searchvalue) pushTransactions(transactionsData)
    let data = transactionsData.filter((item) => item.accountname.toLowerCase().includes(searchvalue.toLowerCase()));
    pushTransactions(data)
})

const downloadTransaction = (id) => {
    // DOWNLOAD TRANSACTION
    let selectedtransaction = transactionsData.filter((transact) => transact.transactionid == id);
    console.log(selectedtransaction)
}

// SETTINGS 
const changeiban = document.querySelector('#changeiban');
const changeibansubmit = document.querySelector('#changeibansubmit');
const changepin = document.querySelector('#changepin');
const changepinsubmit = document.querySelector('#changepinsubmit');

changeibansubmit.addEventListener('click', (e) => {
    e.preventDefault()
    let newiban = changeiban.value

    if( newiban.length > 0 ){
        console.log(changeiban.value);
        Events.Call('uiATM', 'changeIBAN', changeiban.value);
        changeiban.value = '';
    }
})

changepinsubmit.addEventListener('click', (e) => {
    e.preventDefault()
    let newpin = changepin.value
    let isnum = /^\d+$/.test(newpin);

    console.log(isnum);

    if (isnum){
        console.log(newpin)
        Events.Call('uiATM', 'changePIN', {pin : Number(changepin.value), cardNumber : newProfileData.cardNumber});
        changepin.value = '';
    }
})

// PIN
const pinnumberbox = document.querySelector('.pinnumbers');
const pincontainer = document.querySelector('.pincontainer');
const linecontainer = document.querySelector('.linecontainer');
const pins = document.querySelectorAll('.pin');
const pinnumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 'C', 0, 'OK'];

pinnumbers.map((num) => {
    if( num === 'C' ){
        pinnumberbox.innerHTML += `<p class='pinnumber pinnumberC pointer' onclick="clearpin()">${num}</p>`
    } else if(num === 'OK'){
        pinnumberbox.innerHTML += `<p class='pinnumber pinnumberOK pointer'>${num}</p>`
    } else {
        pinnumberbox.innerHTML += `<p class='pinnumber number pointer'>${num}</p>`
    }
})
const numbers = document.querySelectorAll('.number');
const pinOK = document.querySelector('.pinnumberOK');
let pinposition = 0
let userpin;
numbers.forEach((number) => {
    number.addEventListener('click', () => {
        if ( pinposition < 4 )
        pins[pinposition].value = number.textContent;
        userpin = [...pins].map((pin) => pin.value).join('');
        pinposition += 1
    })
})
// CLEAR PIN INPUTED
const clearpin = () => {
    pins.forEach((pin) => pin.value = '')
    pinposition = 0
}
// CLOSE PIN BOX
const closepincontainer = () => {
    pincontainer.classList.add('hidden');
    Events.Call("uiATM", "closeUI");
}
pinOK.addEventListener('click', function () {
    if ( userpin.length === 4){
        // CHECK PIN
        if (String(userpin) === String(newProfileData.pin)) {
            pincontainer.classList.add('hidden');
            linecontainer.classList.remove('hidden');
        } else {
            Events.Call("uiATM", "closeUI");
            Events.Call("uiATM", "pinNotMatch");
        }
    }
})

// COPY AND PASTE 
const copy = document.querySelector('.copy');
const paste = document.querySelector('.paste');
const transferiban = document.querySelector('#transferiban');
let copiedtext = ''
copy.addEventListener('click',  () => {
    copiedtext = IBAN.innerHTML
    console.log(copiedtext);
})
paste.addEventListener('click', () => {
    transferiban.value = copiedtext
})

// ESCAPE KEY BACK
document.addEventListener('keydown', evt => {
    if (evt.key === 'Escape') {

    }
});
// LOG OUT
const logout = () => {
    pincontainer.classList.add('hidden');
    linecontainer.classList.add('hidden');
    Events.Call("uiATM", "closeUI");
}


const OpenATM = (account, card, cardNumber) => {
    console.log(card);
    let accountData = JSON.parse(account)
    let cardData = JSON.parse(card)

    console.log(cardData);

    newProfileData = {
        name : accountData.name,
        balance : cardData.balance,
        profileurl : 'images/profileimage.svg' ,
        pin : cardData.pin,
        cash : accountData.cash,
        cardNumber : cardNumber,
        stats : [],
    };

    //accountData.stats.forEach((stat) => console.log(stat.amount))
    for (const stat in accountData.stats) {
        console.log(`${stat}: ${accountData.stats[stat]}`);
        console.log(accountData.stats[stat].amount);
        let Title = accountData.stats[stat].title;
        let Amount = accountData.stats[stat].amount ? accountData.stats[stat].amount : 0;
        if (Title == 'income' || Title == 'outcome' || Title == 'earnings'){
            Amount = '$' + Amount;
        }
        newProfileData.stats.push({title : Title, amount : Amount});
    }
    newProfileData.stats.push({title : 'transactions', amount : accountData.transactions.length});
    transactionsData = accountData.transactions;
    
    pushCardDetails(newProfileData.balance, '**** **** **** ' + cardData.lastfour);
    setProfileData(newProfileData.name, newProfileData.cash, newProfileData.profileurl);
    pushAccountDetails(accountData.number, 'PC551RP', accountData.iban);
    pushOverviewTransactions(accountData.transactions);
    pushTransactions(accountData.transactions);
    setTotalTransactions(accountData.transactions.length);
    pushStats(newProfileData.stats);

    document.getElementById("wrp").style.opacity = "1";
    clearpin();
    pincontainer.classList.remove('hidden');
    linecontainer.classList.add('hidden');
}

const CloseUI = () => {
    document.getElementById("wrp").style.opacity = "0";
    pincontainer.classList.add('hidden');
    linecontainer.classList.add('hidden');
}

const CallCloseUI = () => {
    Events.Call("uiATM", "closeUI");
}


Events.Subscribe("OpenATM", function(account, card, cardNumber) {
    OpenATM(account, card, cardNumber);
})

Events.Subscribe("CloseATM", function() {
    CloseUI();
})

Events.Subscribe('updateData', function(account, card, cardNumber) {
    let accountData = JSON.parse(account)
    let cardData = JSON.parse(card)

    newProfileData = {
        name : accountData.name,
        balance : cardData.balance,
        profileurl : 'images/profileimage.svg' ,
        pin : cardData.pin,
        cash : accountData.cash,
        cardNumber : cardNumber,
        stats : [],
    }

    for (const stat in accountData.stats) {
        console.log(`${stat}: ${accountData.stats[stat]}`);
        console.log(accountData.stats[stat].amount);
        let Title = accountData.stats[stat].title;
        let Amount = accountData.stats[stat].amount ? accountData.stats[stat].amount : 0;
        if (Title == 'income' || Title == 'outcome' || Title == 'earnings'){
            Amount = '$' + Amount;
        }
        newProfileData.stats.push({title : Title, amount : Amount});
    }
    newProfileData.stats.push({title : 'transactions', amount : accountData.transactions.length});
    transactionsData = accountData.transactions;

    pushCardDetails(newProfileData.balance, '**** **** **** ' + cardData.lastfour);
    setProfileData(newProfileData.name, newProfileData.cash, newProfileData.profileurl)
    pushAccountDetails(accountData.number, 'PC551RP', accountData.iban)
    pushOverviewTransactions(accountData.transactions)
    pushTransactions(accountData.transactions)
    setTotalTransactions(accountData.transactions.length);
    pushStats(newProfileData.stats);
})