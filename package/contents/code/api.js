// API coordinator - fetches from all sources and merges results

.import "openmeteo.js" as OpenMeteo
.import "pirateweather.js" as PirateWeather

function fetchAllWeatherData(lat, lon, apiKey, useAlerts, callback) {
    var results = {
        weather: null,
        nowcast: null,
        pirateNowcast: null,
        alerts: []
    };
    var errors = [];
    var pending = 2; // Open-Meteo weather + nowcast always
    if (apiKey) {
        pending += 1; // Pirate Weather nowcast
        if (useAlerts) {
            pending += 1; // Pirate Weather alerts
        }
    }

    function checkDone() {
        pending--;
        if (pending > 0) return;

        // Merge nowcast: prefer Pirate Weather for first 60 min, then Open-Meteo 15-min
        var mergedNowcast = mergeNowcastData(results.pirateNowcast, results.nowcast);

        if (results.weather) {
            callback(null, {
                weather: results.weather,
                nowcast: mergedNowcast,
                alerts: results.alerts
            });
        } else {
            callback(errors.join("; "), null);
        }
    }

    // 1. Open-Meteo weather (current + hourly + daily)
    OpenMeteo.fetchWeather(lat, lon, function(err, data) {
        if (err) {
            errors.push(err);
        } else {
            results.weather = data;
        }
        checkDone();
    });

    // 2. Open-Meteo nowcast (15-min precipitation)
    OpenMeteo.fetchNowcast(lat, lon, function(err, data) {
        if (err) {
            errors.push(err);
        } else {
            results.nowcast = data;
        }
        checkDone();
    });

    // 3. Pirate Weather nowcast (1-min, if API key)
    if (apiKey) {
        PirateWeather.fetchNowcast(apiKey, lat, lon, function(err, data) {
            if (err) {
                errors.push(err);
            } else {
                results.pirateNowcast = data;
            }
            checkDone();
        });

        // 4. Pirate Weather alerts (if enabled)
        if (useAlerts) {
            PirateWeather.fetchAlerts(apiKey, lat, lon, function(err, data) {
                if (err) {
                    errors.push(err);
                } else {
                    results.alerts = data || [];
                }
                checkDone();
            });
        }
    }
}

function mergeNowcastData(pirateData, openMeteoData) {
    // If no pirate data, just use Open-Meteo
    if (!pirateData || !pirateData.data || pirateData.data.length === 0) {
        return openMeteoData || { source: "none", interval: 15, data: [] };
    }

    // If no Open-Meteo data, just use Pirate
    if (!openMeteoData || !openMeteoData.data || openMeteoData.data.length === 0) {
        return pirateData;
    }

    // Merge: Pirate Weather 1-min data for first ~60 minutes,
    // then Open-Meteo 15-min data for remaining time
    var merged = [];

    // Add all Pirate Weather points (first ~60 min at 1-min intervals)
    for (var i = 0; i < pirateData.data.length; i++) {
        merged.push(pirateData.data[i]);
    }

    // Find the last Pirate Weather timestamp
    var lastPirateTime = new Date(pirateData.data[pirateData.data.length - 1].time).getTime();

    // Add Open-Meteo points that come after the Pirate Weather data
    for (var j = 0; j < openMeteoData.data.length; j++) {
        var omTime = new Date(openMeteoData.data[j].time).getTime();
        if (omTime > lastPirateTime) {
            merged.push(openMeteoData.data[j]);
        }
    }

    return {
        source: "merged",
        interval: 1, // mixed intervals
        pirateCount: pirateData.data.length,
        data: merged
    };
}
