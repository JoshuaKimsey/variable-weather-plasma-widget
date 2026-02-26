// Unit conversion utilities
// Internal storage is metric (Celsius, km/h, hPa, mm/h)
// Converts to imperial at display time when needed

function isMetric(unitsSetting) {
    if (unitsSetting === "metric") return true;
    if (unitsSetting === "imperial") return false;
    // "auto" - detect from Qt locale
    try {
        return Qt.locale().measurementSystem === Locale.MetricSystem;
    } catch (e) {
        return true; // default to metric
    }
}

function formatTemp(celsius, metric) {
    if (metric) {
        return Math.round(celsius) + "°C";
    }
    return Math.round(celsius * 9 / 5 + 32) + "°F";
}

function formatTempValue(celsius, metric) {
    if (metric) {
        return Math.round(celsius);
    }
    return Math.round(celsius * 9 / 5 + 32);
}

function formatWind(kmh, metric) {
    if (metric) {
        return Math.round(kmh) + " km/h";
    }
    return Math.round(kmh * 0.621371) + " mph";
}

function formatPressure(hpa, metric, useMillibar) {
    if (useMillibar) {
        // hPa and mbar are numerically identical
        return Math.round(hpa) + " mbar";
    }
    if (metric) {
        return Math.round(hpa) + " hPa";
    }
    return (hpa * 0.02953).toFixed(2) + " inHg";
}

function formatPrecipIntensity(mmh, metric) {
    if (metric) {
        return mmh.toFixed(1) + " mm/h";
    }
    return (mmh / 25.4).toFixed(2) + " in/h";
}

function formatVisibility(km, metric) {
    if (metric) {
        return Math.round(km) + " km";
    }
    return Math.round(km * 0.621371) + " mi";
}

function windDirectionToString(degrees) {
    var dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
    var index = Math.round(degrees / 22.5) % 16;
    return dirs[index];
}

function formatHumidity(percent) {
    return Math.round(percent) + "%";
}

function formatCloudCover(percent) {
    return Math.round(percent) + "%";
}
