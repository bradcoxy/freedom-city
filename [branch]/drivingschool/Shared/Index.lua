Config = {}

Config.minimumPointsForTheoritical = 5
Config.maxSpeedDuringTest = 40.0
Config.practicalTimeLimit = 600 -- in seconds / 10 minutes


Config.Questions = {
    {
        query = 'What does a broken yellow line mean?',
        options = {
            {
                answer = 'Does not mean anything.',
            },
            {
                answer = 'It is for peds and cyclists.',
                isAns = true,
            },
            {
                answer = 'It is for big trucks only.',
            },
            {
                answer = 'It is for peds only.',
            },
        },
    },
    {
        query = 'Who has priority at a roundabout?',
        options = {
            {
                answer = 'Old people.',
            },
            {
                answer = 'Expensive vehicles.',
            },
            {
                answer = 'Vehicles already on the roundabout.',
                isAns = true,
            },
            {
                answer = 'Vehicles on the left lane.',
            },
        },
    },
    {
        query = 'What do the white zig-zag lines at a zebra crossing mean?',
        options = {
            {
                answer = 'No parking or overtaking.',
                isAns = true,
            },
            {
                answer = 'To go through.',
            },
            {
                answer = 'To stop.',
            },
            {
                answer = 'No parking.',
            },
        },
    },
    {
        query = 'What is the sequence of traffic lights?',
        options = {
            {
                answer = 'Green, Brown, Red.',
            },
            {
                answer = 'Green, Yellow, Red.',
                isAns = true,
            },
            {
                answer = 'Green, Amber, Red.',
            },
            {
                answer = 'Green, Mustard, Red.',
            },
        },
    },
    {
        query = 'What is meant by tailgating?',
        options = {
            {
                answer = 'Tail of an alligator.',
            },
            {
                answer = 'Speeding past a vehicle.',
            },
            {
                answer = 'Driving beside a vehicle.',
            },
            {
                answer = 'Driving too close to a vehicle in front.',
                isAns = true,
            },
        },
    },
    {
        query = 'What do flashing red traffic lights mean?',
        options = {
            {
                answer = 'Stop, cow approaching.',
            },
            {
                answer = 'Stop, truck approaching.',
            },
            {
                answer = 'Stop, train approaching.',
                isAns = true,
            },
            {
                answer = 'Increase speed.',
            },
        },
    },
    {
        query = 'What does a solid yellow line indicate?',
        options = {
            {
                answer = 'It marks the boundary of a parking area.',
            },
            {
                answer = 'It separates traffic in opposite directions.',
                isAns = true,
            },
            {
                answer = 'It indicates the presence of a pedestrian crossing.',
            },
            {
                answer = 'Used to guide traffic around a roundabout.',
            },
        },
    },
    {
        query = 'What does a green arrow signal mean?',
        options = {
            {
                answer = 'Proceed with caution.',
            },
            {
                answer = 'Stop and wait for the next signal.',
            },
            {
                answer = 'Allowed to turn in the direction of the arrow.',
                isAns = true,
            },
            {
                answer = 'Slow down and yield to pedestrians.',
            },
        },
    },
    {
        query = 'What does a white sign with a black arrow pointing downwards indicate?',
        options = {
            {
                answer = 'One-way road ahead.',
            },
            {
                answer = 'No entry for vehicles.',
            },
            {
                answer = 'No entry for pedestrians.',
            },
            {
                answer = 'The road is inclined downwards.',
                isAns = true,
            },
        },
    },
    {
        query = 'What does a red octagonal sign indicate?',
        options = {
            {
                answer = 'Yield.',
            },
            {
                answer = 'Stop.',
                isAns = true,
            },
            {
                answer = 'School zone ahead.',
            },
            {
                answer = 'Speed limit of 80 mp/h.',
            },
        },
    },
}


Config.Schools = {
    ['manhattan_driving'] = {
        label = 'Manhattan Driving School',
        coords = Vector(240.6, 148.9, 45.0),
        rotation = Rotator(0.0, 0.0, 0.0),
        licenses = {
            drivinglicense = {
                type = 'driving',
                label = 'Driver License',
                maxErrors = 2,
                cost = 50,
            },
        },
        testVehicle = {
            model = 'Charger',
            coords = Vector(853.2, 148.9, 20.0),
            rotation = Rotator(0.0, 0.0, 0.0),
        },
        testPoints = { --- to do, left because of monday showcase work.
--[[             Vector(8467.6, 3229.5, 10.0),
            Vector(4788.5, -1565.3, 10.0), ]]
            Vector(440.8, -135.6, 10.0)
        },
    },
}