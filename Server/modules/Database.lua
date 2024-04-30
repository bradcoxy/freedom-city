DB = nil

--DB = Database(DatabaseEngine.MySQL, "db=pcrp-core user=root host=localhost")

-- Package.Subscribe('Load', function()
-- end)

PersistentDatabase.Create(function () end)

-- Package.Subscribe('Unload', function()
--     DB:Close()
-- end)

-- Package.Export('DB', DB)