let plantDetails = {
    name: 'cannabis',
    growth: 0,
    water: 0,
    quality: 0,
    nutrients: 0
}
// coca, cannabis, poppy
// plant name linked to the image src
const pushDetails = (plant) => {
    const {growth, quality, nutrients, water, name, imageUrl} = plant
    document.querySelector('.growth').innerHTML = growth + '%';
    document.querySelector('.growth-range').style.width = `${growth}%`
    document.querySelector('.water').innerHTML = water + '%';
    document.querySelector('.water-range').style.width = `${water}%`
    document.querySelector('.quality').innerHTML = quality + '%';
    document.querySelector('.quality-range').style.width = `${quality}%`
    document.querySelector('.nutrients').innerHTML = nutrients + '%';
    document.querySelector('.nutrients-range').style.width = `${nutrients}%`;
    document.querySelector('.plantname').innerHTML = name + ' plant';
    document.querySelectorAll('.plant-picture').forEach((elem) => {
        elem.src = `images/${name}.svg`;
    })
}
pushDetails(plantDetails)
const feedPlant = () => {
    Events.Call('feedPlant', plantDetails.identifier);
}
const waterPlant = () => {
    Events.Call('waterPlant', plantDetails.identifier);
}
const harvestPlant = () => {
    Events.Call('harvestPlant', plantDetails.identifier);
}
const destroyPlant = () => {
    Events.Call('destroyPlant', plantDetails.identifier);
}
const toggleDisplay = () => {
    document.querySelector('.detail-cont').classList.remove('hide-display');
}
document.querySelector('.close').addEventListener('click', () => {
    Events.Call('CloseUI');
})
/* document.addEventListener('keydown', evt => {
    if (evt.key === 'e') {
        toggleDisplay();
    }
}); */

Events.Subscribe('UpdateCurrentPlant', function(plant, plantType) {  
    plantDetails = JSON.parse(plant);
    plantDetails.name = plantType;
    pushDetails(plantDetails);
})

Events.Subscribe('ClosePlant', function() {  
    document.querySelector('.detail-cont').classList.add('hide-display');
})

Events.Subscribe("ShowPlant", function(plant, plantType) {
    plantDetails = JSON.parse(plant);
    plantDetails.name = plantType;

    console.log(plantType);

    pushDetails(plantDetails);
    setTimeout(() => {
        toggleDisplay();
    }, 100);
})