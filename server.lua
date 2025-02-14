ESX = exports['es_extended']:getSharedObject()

-- Upewnij się, że tabela Config jest załadowana poprawnie
if not Config then
    print("[ERROR] Config jest nullem! Upewnij się, że config.lua jest poprawnie załadowany.")
    return
end

print("Config załadowany pomyślnie.")
print("Wynagrodzenia za prace: ", json.encode(Config.JobSalaries))
print("Prace do wypłaty: ", json.encode(Config.JobsToPay))

local function paySalaries()
    -- Iteruj przez wszystkich połączonych graczy
    for _, xPlayer in pairs(ESX.GetPlayers()) do
        local player = ESX.GetPlayerFromId(xPlayer)
        
        if player and player.job and player.job.name then
            local jobName = player.job.name
            local rank = player.job.grade

            -- Sprawdź, czy praca istnieje w Config.JobSalaries
            if Config.JobSalaries[jobName] then
                -- Pobierz wynagrodzenie w zależności od rangi, jeśli brak rangi, zastosuj domyślną pensję
                local salaryAmount = Config.JobSalaries[jobName][rank] or Config.JobSalaries[jobName]
                
                -- Dodaj pieniądze do konta bankowego gracza z niestandardowym opisem transakcji
                player.addAccountMoney('bank', salaryAmount)
                
                -- Dodaj wpis do historii banku
                player.addAccountTransaction('bank', -salaryAmount, "[WYPLATA] Wypłata za pracę jako " .. jobName .. " (stopień " .. (rank or "brak stopnia") .. ")")
                
                -- Powiadom gracza
                TriggerClientEvent('esx:showNotification', player.source, "💰 Otrzymałeś wynagrodzenie w wysokości $" .. salaryAmount)
                
                -- Zaloguj wypłatę do konsoli serwera
                print("[Wypłata] Gracz " .. player.getName() .. " otrzymał $" .. salaryAmount .. " za pracę jako " .. jobName .. " (stopień " .. (rank or "brak stopnia") .. ")")
            end
        end
    end
end

local function notifyUpcomingPay()
    -- Powiadom graczy o nadchodzącej wypłacie
    for _, xPlayer in pairs(ESX.GetPlayers()) do
        local player = ESX.GetPlayerFromId(xPlayer)
        
        if player and player.job and player.job.name and Config.JobSalaries[player.job.name] then
            TriggerClientEvent('esx:showNotification', player.source, "⏳ Twoja wypłata zostanie przelana za 5 minut!")
        end
    end
end

-- Komenda do ręcznego ustawienia pensji gracza
RegisterCommand('setSalary', function(source, args, user)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer and xPlayer.getGroup() == "admin" then
        local job = args[1]
        local rank = tonumber(args[2])
        local amount = tonumber(args[3])

        -- Sprawdź, czy praca istnieje w Config i ustaw pensję
        if Config.JobSalaries[job] then
            if rank and Config.JobSalaries[job][rank] then
                Config.JobSalaries[job][rank] = amount
                print("[Wypłata UPDATE] Administrator " .. xPlayer.getName() .. " zmienił wypłatę dla " .. job .. " (stopień " .. rank .. ") na $" .. amount)
            else
                Config.JobSalaries[job] = amount
                print("[Wypłata UPDATE] Administrator " .. xPlayer.getName() .. " zmienił wypłatę dla " .. job .. " na $" .. amount)
            end
            TriggerClientEvent('esx:showNotification', source, "✔ Wynagrodzenie dla " .. job .. " zostało ustawione na $" .. amount)
        else
            TriggerClientEvent('esx:showNotification', source, "❌ Nieprawidłowa praca, stopień lub kwota!")
        end
    else
        TriggerClientEvent('esx:showNotification', source, "❌ Nie masz uprawnień do tej komendy!")
    end
end, false)

-- Wątek do okresowego wypłacania pensji i powiadamiania graczy
CreateThread(function()
    while true do
        -- Czekaj na czas przed powiadomieniem
        Wait(Config.PaymentInterval - Config.NotificationTime)
        -- Powiadom graczy o nadchodzącej wypłacie
        notifyUpcomingPay()

        -- Czekaj na czas powiadomienia
        Wait(Config.NotificationTime)
        
        -- Wypłać pensje graczom
        paySalaries()
    end
end)

-- Dodano przez devvii__
print("Skrypt załadowany przez devvii__")
