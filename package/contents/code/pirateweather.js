// Pirate Weather API integration
// Provides 1-minute precipitation nowcast and weather alerts

.import "weathercodes.js" as WeatherCodes

var ENDPOINT = "https://api.pirateweather.net/forecast";

function fetchNowcast(apiKey, lat, lon, callback) {
    var url = ENDPOINT + "/" + apiKey + "/" + lat + "," + lon + "?exclude=hourly,daily,alerts";

    var xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;

        if (xhr.status !== 200) {
            callback("Pirate Weather HTTP " + xhr.status, null);
            return;
        }

        try {
            var data = JSON.parse(xhr.responseText);
            var result = parseNowcastData(data);
            callback(null, result);
        } catch (e) {
            callback("Pirate Weather parse error: " + e.toString(), null);
        }
    };
    xhr.send();
}

function parseNowcastData(data) {
    var points = [];

    if (data.minutely && data.minutely.data) {
        for (var i = 0; i < data.minutely.data.length; i++) {
            var m = data.minutely.data[i];
            // Convert inches/hour to mm/hour
            var intensityMmh = (m.precipIntensity || 0) * 25.4;
            var prob = m.precipProbability || 0;
            var pType = m.precipType || "none";
            if (pType === "" || (!intensityMmh && !prob)) pType = "none";

            points.push({
                time: new Date(m.time * 1000).toISOString(),
                precipIntensity: intensityMmh,
                precipProbability: prob,
                precipType: pType,
                intensityLabel: WeatherCodes.getPrecipIntensityLabel(intensityMmh)
            });
        }
    }

    return {
        source: "pirate-weather",
        interval: 1,
        data: points
    };
}

function fetchAlerts(apiKey, lat, lon, callback) {
    var url = ENDPOINT + "/" + apiKey + "/" + lat + "," + lon + "?exclude=hourly,daily,minutely";

    var xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;

        if (xhr.status !== 200) {
            callback("Pirate Weather alerts HTTP " + xhr.status, null);
            return;
        }

        try {
            var data = JSON.parse(xhr.responseText);
            var result = parseAlertsData(data);
            callback(null, result);
        } catch (e) {
            callback("Pirate Weather alerts parse error: " + e.toString(), null);
        }
    };
    xhr.send();
}

function parseAlertsData(data) {
    var alerts = [];

    if (data.alerts) {
        for (var i = 0; i < data.alerts.length; i++) {
            var a = data.alerts[i];
            alerts.push({
                title: a.title || "Weather Alert",
                description: a.description || "",
                severity: determineAlertSeverity(a.title || "", a.severity || ""),
                expires: a.expires ? new Date(a.expires * 1000).toISOString() : "",
                uri: a.uri || ""
            });
        }
    }

    return alerts;
}

function determineAlertSeverity(title, apiSeverity) {
    // Trust API if extreme or severe
    var sev = apiSeverity.toLowerCase();
    if (sev === "extreme" || sev === "severe") return sev;

    var t = title.toLowerCase();

    // Extreme - immediate danger to life
    if (t.indexOf("tornado warning") !== -1 ||
        t.indexOf("flash flood emergency") !== -1 ||
        t.indexOf("tsunami warning") !== -1 ||
        t.indexOf("extreme wind warning") !== -1 ||
        t.indexOf("particularly dangerous situation") !== -1) {
        return "extreme";
    }

    // Severe - significant threat
    if (t.indexOf("severe thunderstorm warning") !== -1 ||
        t.indexOf("tornado watch") !== -1 ||
        t.indexOf("flash flood warning") !== -1 ||
        t.indexOf("hurricane warning") !== -1 ||
        t.indexOf("blizzard warning") !== -1 ||
        t.indexOf("ice storm warning") !== -1 ||
        t.indexOf("winter storm warning") !== -1 ||
        t.indexOf("storm surge warning") !== -1 ||
        t.indexOf("hurricane watch") !== -1 ||
        t.indexOf("avalanche warning") !== -1 ||
        t.indexOf("red flag warning") !== -1 ||
        t.indexOf("excessive heat warning") !== -1) {
        return "severe";
    }

    // Moderate
    if (t.indexOf("flood warning") !== -1 ||
        t.indexOf("thunderstorm watch") !== -1 ||
        t.indexOf("winter storm watch") !== -1 ||
        t.indexOf("winter weather advisory") !== -1 ||
        t.indexOf("wind advisory") !== -1 ||
        t.indexOf("heat advisory") !== -1 ||
        t.indexOf("freeze warning") !== -1 ||
        t.indexOf("dense fog advisory") !== -1 ||
        t.indexOf("flood advisory") !== -1 ||
        t.indexOf("frost advisory") !== -1) {
        return "moderate";
    }

    // Minor
    if (t.indexOf("special weather statement") !== -1 ||
        t.indexOf("hazardous weather outlook") !== -1 ||
        t.indexOf("air quality alert") !== -1) {
        return "minor";
    }

    // Generic fallbacks
    if (t.indexOf("warning") !== -1) return "severe";
    if (t.indexOf("watch") !== -1) return "moderate";
    if (t.indexOf("advisory") !== -1 || t.indexOf("statement") !== -1) return "minor";

    return "moderate";
}
