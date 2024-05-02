Core.Items = {
    ['apple'] = {
        label = 'Apple',
        unique = false,
        description = "A fruit that's trying to keep the doctor away, but honestly, who needs that kind of commitment?",
        type = 'food',
        status = { hunger = 10 },
        consume = 0.3, -- If consumed, it cant stack as it will have a durability bar out of 1.0 this means you get status.hunger * change for the change in hunger
        model = "",
    },
    ['banana'] = {
        label = 'Banana',
        unique = false,
        description = "The original natural energy bar, wrapped in its very own biodegradable packaging.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['water'] = {
        label = 'Water Bottle',
        unique = false,
        description = "The elixir of life, conveniently packaged in a bottle. Guaranteed to make you feel hydrated and environmentally conscious.",
        type = 'drink',
        status = { thirst = 10 },
    },
    ['coffee'] = {
        label = 'Coffee',
        unique = false,
        description = "Liquid motivation for when life gives you lemons, but you'd prefer a latte.",
        type = 'drink',
        status = { thirst = 10 },
    },
    ['hamburger'] = {
        label = 'Hamburger',
        unique = false,
        description = "A sandwich with commitment issues – it falls apart, but you'll still love it.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['pizza'] = {
        label = 'Pizza',
        unique = false,
        description = "The only circle of trust you need in your life. No slices left behind!",
        type = 'food',
        status = { hunger = 10 },
    },
    ['candy_bar'] = {
        label = 'Candy Bar',
        unique = false,
        description = "A sweet escape from reality, conveniently wrapped in a colorful distraction.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['energy_drink'] = {
        label = 'Energy Drink',
        unique = false,
        description = "Because adulting is hard, and sometimes you need a can of \"fake it 'til you make it.\"",
        type = 'drink',
        status = { thirst = 10 },
    },
    ['soda_can'] = {
        label = 'Soda Can',
        unique = false,
        description = "Fizzy happiness in a can – the closest thing to bottled joy.",
        type = 'drink',
        status = { thirst = 10 },
    },
    ['bag_chips'] = {
        label = 'Bag of Chips',
        unique = false,
        description = "The only workout where you lift and crunch simultaneously. Snacking level: Expert.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['ice_cream'] = {
        label = 'Ice Cream',
        unique = false,
        description = "Happiness is just a scoop away. Warning: May cause brain freeze and instant smiles.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['cigarettes'] = {
        label = 'Cigarettes',
        unique = false,
        description = "The original \"smoke and mirrors\" – not recommended, but it looks cool in old movies.",
        type = 'item',
    },
    ['lighter'] = {
        label = 'Lighter',
        unique = false,
        description = "For when you want to play with fire but in a responsible adult kind of way.",
        type = 'item',
    },
    ['lottery_ticket'] = {
        label = 'Lottery Ticket',
        unique = false,
        description = "The ultimate math challenge: turning a piece of paper into dreams (or disappointment).",
        type = 'item',
    },
    ['prepaid_phone_card'] = {
        label = 'Prepaid Phone Card',
        unique = false,
        description = "The ancient artifact that proves you survived the era of payphones and limited texting.",
        type = 'item',
    },
    ['sandwich'] = {
        label = 'Sandwich',
        unique = false,
        description = "A portable hug for your taste buds – the true multitasker of the culinary world.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['wine_bottle'] = {
        label = 'Wine Bottle',
        unique = false,
        description = "The classy way to say, \"I've had a day\" – just add a glass and some cheese.",
        type = 'drink',
        status = { thirst = 10 },
    },
    ['beer_can'] = {
        label = 'Beer Can',
        unique = false,
        description = "Liquid courage in a can – the key to surviving awkward social situations since forever.",
        type = 'drink',
        status = { thirst = 10 },
    },
    ['chewing_gum'] = {
        label = 'Pack of Chewing Gum',
        unique = false,
        description = "The silent workout for your jaw muscles – pop, snap, and blow away your problems.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['battery_pack'] = {
        label = 'Pack of Batteries',
        unique = false,
        description = "The unsung heroes that keep your remote control and your life running smoothly.",
        type = 'item'
    },
    ['deodorant'] = {
        label = 'Deodorant',
        unique = false,
        description = "Because being fabulous sometimes requires a little extra support – in a stick.",
        type = 'item'
    },
    ['toothpaste'] = {
        label = 'Toothpaste',
        unique = false,
        description = "The minty freshness that makes morning breath a little less offensive – you're welcome.",
        type = 'item'
    },
    ['painkiller'] = {
        label = 'Pain Reliever',
        unique = false,
        description = "For those moments when life hits you harder than Monday morning.",
        type = 'food'
    },
    ['lipbalm'] = {
        label = 'Lip Balm',
        unique = false,
        description = "The superhero for your lips – saving the day one pout at a time.",
        type = 'item'
    },
    ['car_air_freshener'] = {
        label = 'Car Air Freshener',
        unique = false,
        description = "Because your car deserves to smell better than the fast-food wrappers suggest.",
        type = 'item'
    },
    ['phone_charger'] = {
        label = 'Phone Charger',
        unique = true,
        description = "The lifeline for your phone – because a dead phone is the ultimate silent protest.",
        type = 'item'
    },
    ['magazine'] = {
        label = 'Magazine',
        unique = true,
        description = "The original way to scroll without a touchscreen – flip, don't swipe.",
        type = 'item'
    },
    ['newspaper'] = {
        label = 'Newspaper',
        unique = true,
        description = "Old-school social media with ink-stained fingers. Warning: May contain actual news.",
        type = 'item'
    },
    ['travel_shampoo'] = {
        label = 'Travel-sized Shampoo',
        unique = true,
        description = "For when your hair needs a vacation too – pocket-sized luxury for your locks.",
        type = 'item'
    },
    ['travel_soap'] = {
        label = 'Travel-sized Soap',
        unique = true,
        description = "Because cleanliness is not just next to godliness, it's also suitcase-friendly.",
        type = 'item'
    },
    ['muffin'] = {
        label = 'Muffin',
        unique = false,
        description = "The cupcake's less glamorous cousin – still delicious, just without the frosting ego.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['donut'] = {
        label = 'Donut',
        unique = false,
        description = "A sweet circle of happiness that's basically a hug for your taste buds.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['coffee_beans_pack'] = {
        label = 'Pack of Coffee Beans',
        unique = false,
        description = "The magical beans that turn mornings into possibilities – grind, brew, conquer.",
        type = 'item'
    },
    ['tea_bags_pack'] = {
        label = 'Pack of Tea Bags',
        unique = false,
        description = "The liquid hug in a cup – just add hot water and let the steeping therapy begin.",
        type = 'item'
    },
    ['cookies_pack'] = {
        label = 'Pack of Cookies',
        unique = false,
        description = "Little discs of joy – the ultimate cure for sweet cravings and bad days alike.",
        type = 'food',
        status = { hunger = 10 },
    },
    ['travel_tissues'] = {
        label = 'Travel-sized Tissues',
        unique = false,
        description = "The tiny superheroes in your pocket – ready to save you from unexpected sneezes and tears.",
        type = 'item'
    },
    ['dog_food'] = {
        label = 'Dog Food',
        unique = false,
        description = "Because your furry friend deserves gourmet meals too – tails wagging guaranteed.",
        type = 'item'
    },
    ['cat_food'] = {
        label = 'Cat Food',
        unique = false,
        description = "The key to winning the affection of your feline overlord – served with a side of purrs.",
        type = 'item'
    },
    ['disposable_camera'] = {
        label = 'Disposable Camera',
        unique = false,
        description = "The retro way to capture moments – no filters, just a hint of nostalgia.",
        type = 'item'
    },
    ['usb_flash_drive'] = {
        label = 'USB Flash Drive',
        unique = false,
        description = "The digital messenger of files – because sometimes clouds have rainy days.",
        type = 'item'
    },
    ['prepaid_gift_card'] = {
        label = 'Prepaid Gift Card',
        unique = false,
        description = "The present of possibilities – let someone choose their own adventure in the shopping jungle.",
        type = 'item'
    },
    ['greeting_card'] = {
        label = 'Greeting Card',
        unique = false,
        description = "A piece of folded joy – the perfect vessel for your heartfelt (or hilarious) sentiments.",
        type = 'item'
    },
    ['tissue_box'] = {
        label = 'Box of Facial Tissues',
        unique = false,
        description = "Soft clouds in a box – for those moments when life gets a little too emotional.",
        type = 'item'
    },
    ['laundry_detergent'] = {
        label = 'Laundry Detergent',
        unique = false,
        description = "The superhero for your clothes – fighting stains and preserving the dignity of your favorite outfits.",
        type = 'item'
    },
    ['cleaning_wipes'] = {
        label = 'Cleaning Wipes',
        unique = false,
        description = "The shortcut to a clean space – because who has time for a full-on cleaning spree?",
        type = 'item'
    },
    ['disposable_razor_pack'] = {
        label = 'Pack of Disposable Razors',
        unique = false,
        description = "The art of smoothness in a pack – because shaving should be a breeze, not a battle.",
        type = 'item'
    },
    ['toothbrush'] = {
        label = 'Toothbrush',
        unique = false,
        description = "The daily defender against morning breath – a small hero in the battle for dental hygiene.",
        type = 'item'
    },
    ['travel_conditioner'] = {
        label = 'Travel-sized Conditioner',
        unique = false,
        description = "For hair that deserves a spa day on the go – because even your locks need a vacation.",
        type = 'item'
    }
}