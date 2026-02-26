// Open-Meteo weather API integration
// Returns data in metric units (Celsius, km/h, hPa, mm)

.import "weathercodes.js" as WeatherCodes

var ENDPOINT = "https://api.open-meteo.com/v1/forecast";

function fetchWeather(lat, lon, callback) {
    var currentParams = [
        "temperature_2m", "relative_humidity_2m", "apparent_temperature",
        "is_day", "precipitation", "weather_code", "cloud_cover",
        "pressure_msl", "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m"
    ];

    var hourlyParams = [
        "temperature_2m", "precipitation_probability", "weather_code", "is_day"
    ];

    var dailyParams = [
        "weather_code", "temperature_2m_max", "temperature_2m_min",
        "precipitation_probability_max", "sunrise", "sunset"
    ];

    var url = ENDPOINT
        + "?latitude=" + lat
        + "&longitude=" + lon
        + "&current=" + currentParams.join(",")
        + "&hourly=" + hourlyParams.join(",")
        + "&daily=" + dailyParams.join(",")
        + "&timezone=auto"
        + "&forecast_days=5"
        + "&forecast_hours=12";

    var xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;

        if (xhr.status !== 200) {
            callback("Open-Meteo HTTP " + xhr.status, null);
            return;
        }

        try {
            var data = JSON.parse(xhr.responseText);
            var result = parseWeatherData(data);
            callback(null, result);
        } catch (e) {
            callback("Open-Meteo parse error: " + e.toString(), null);
        }
    };
    xhr.send();
}

function parseWeatherData(data) {
    var c = data.current;

    var current = {
        temperature: c.temperature_2m,
        feelsLike: c.apparent_temperature,
        humidity: c.relative_humidity_2m,
        pressure: c.pressure_msl,
        windSpeed: c.wind_speed_10m,
        windDirection: c.wind_direction_10m,
        windGusts: c.wind_gusts_10m,
        cloudCover: c.cloud_cover,
        precipitation: c.precipitation,
        weatherCode: c.weather_code,
        isDay: c.is_day === 1,
        icon: WeatherCodes.getIconName(c.weather_code, c.is_day === 1),
        description: WeatherCodes.getDescription(c.weather_code)
    };

    var hourly = [];
    if (data.hourly && data.hourly.time) {
        var count = Math.min(data.hourly.time.length, 12);
        for (var i = 0; i < count; i++) {
            hourly.push({
                time: data.hourly.time[i],
                temperature: data.hourly.temperature_2m[i],
                precipProbability: data.hourly.precipitation_probability[i],
                weatherCode: data.hourly.weather_code[i],
                isDay: data.hourly.is_day[i] === 1,
                icon: WeatherCodes.getIconName(data.hourly.weather_code[i], data.hourly.is_day[i] === 1)
            });
        }
    }

    var daily = [];
    if (data.daily && data.daily.time) {
        var dayCount = Math.min(data.daily.time.length, 5);
        for (var j = 0; j < dayCount; j++) {
            daily.push({
                time: data.daily.time[j],
                weatherCode: data.daily.weather_code[j],
                tempMax: data.daily.temperature_2m_max[j],
                tempMin: data.daily.temperature_2m_min[j],
                precipProbability: data.daily.precipitation_probability_max[j],
                sunrise: data.daily.sunrise[j],
                sunset: data.daily.sunset[j],
                icon: WeatherCodes.getIconName(data.daily.weather_code[j], true),
                description: WeatherCodes.getDescription(data.daily.weather_code[j])
            });
        }
    }

    return {
        current: current,
        hourly: hourly,
        daily: daily,
        timezone: data.timezone || ""
    };
}

function fetchNowcast(lat, lon, callback) {
    var url = ENDPOINT
        + "?latitude=" + lat
        + "&longitude=" + lon
        + "&minutely_15=precipitation,precipitation_probability,snowfall"
        + "&forecast_minutely_15=24"
        + "&past_minutely_15=0"
        + "&timezone=auto";

    var xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;

        if (xhr.status !== 200) {
            callback("Open-Meteo nowcast HTTP " + xhr.status, null);
            return;
        }

        try {
            var data = JSON.parse(xhr.responseText);
            var result = parseNowcastData(data);
            callback(null, result);
        } catch (e) {
            callback("Open-Meteo nowcast parse error: " + e.toString(), null);
        }
    };
    xhr.send();
}

function parseNowcastData(data) {
    var points = [];
    if (data.minutely_15 && data.minutely_15.time) {
        for (var i = 0; i < data.minutely_15.time.length; i++) {
            var precip = data.minutely_15.precipitation[i] || 0;
            var snow = data.minutely_15.snowfall[i] || 0;
            var prob = data.minutely_15.precipitation_probability[i] || 0;

            var precipType = "none";
            if (precip > 0 || prob > 0) {
                if (snow > 0 && precip > snow) {
                    precipType = "mix";
                } else if (snow > 0) {
                    precipType = "snow";
                } else {
                    precipType = "rain";
                }
            }

            // Convert 15-min accumulation (mm) to intensity (mm/h)
            var intensity = precip * 4;

            points.push({
                time: data.minutely_15.time[i],
                precipIntensity: intensity,
                precipProbability: prob / 100,
                precipType: precipType,
                intensityLabel: WeatherCodes.getPrecipIntensityLabel(intensity)
            });
        }
    }

    return {
        source: "open-meteo",
        interval: 15,
        data: points
    };
}
