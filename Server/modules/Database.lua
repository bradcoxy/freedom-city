DB = nil

DB = Database(DatabaseEngine.MySQL, "db=pcrp-core user=root host=localhost")

PersistentDatabase.Create(function () end)

-- Package.Subscribe('Load', function()
-- end)

Package.Subscribe('Unload', function()
    DB:Close()
end)

Package.Export('DB', DB)