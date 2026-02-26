// Weather code mappings - WMO code to icon name and description
// Adapted from Variable Weather PWA's openMeteoApi.js

function getIconName(wmoCode, isDay) {
    switch (wmoCode) {
        case 0: case 1:
            return isDay ? "clear-day" : "clear-night";
        case 2:
            return isDay ? "partly-cloudy-day" : "partly-cloudy-night";
        case 3:
            return "cloudy";
        case 45: case 48:
            return "fog";
        case 51: case 53: case 55:
            return "drizzle";
        case 56: case 57:
            return "sleet";
        case 61: case 63: case 65:
            return "rain";
        case 66: case 67:
            return "sleet";
        case 71: case 73: case 75: case 77:
            return "snow";
        case 80: case 81: case 82:
            return "rain";
        case 85: case 86:
            return "snow";
        case 95: case 96: case 99:
            return "thunderstorm";
        default:
            return "cloudy";
    }
}

function getDescription(wmoCode) {
    switch (wmoCode) {
        case 0:  return "Clear sky";
        case 1:  return "Mainly clear";
        case 2:  return "Partly cloudy";
        case 3:  return "Overcast";
        case 45: return "Fog";
        case 48: return "Depositing rime fog";
        case 51: return "Light drizzle";
        case 53: return "Moderate drizzle";
        case 55: return "Dense drizzle";
        case 56: return "Light freezing drizzle";
        case 57: return "Dense freezing drizzle";
        case 61: return "Slight rain";
        case 63: return "Moderate rain";
        case 65: return "Heavy rain";
        case 66: return "Light freezing rain";
        case 67: return "Heavy freezing rain";
        case 71: return "Slight snow fall";
        case 73: return "Moderate snow fall";
        case 75: return "Heavy snow fall";
        case 77: return "Snow grains";
        case 80: return "Slight rain showers";
        case 81: return "Moderate rain showers";
        case 82: return "Violent rain showers";
        case 85: return "Slight snow showers";
        case 86: return "Heavy snow showers";
        case 95: return "Thunderstorm";
        case 96: return "Thunderstorm with slight hail";
        case 99: return "Thunderstorm with heavy hail";
        default: return "Unknown";
    }
}

function getPrecipIntensityLabel(intensityMmh) {
    if (intensityMmh <= 0)   return "none";
    if (intensityMmh < 0.5)  return "very-light";
    if (intensityMmh < 2.5)  return "light";
    if (intensityMmh < 10)   return "moderate";
    if (intensityMmh < 50)   return "heavy";
    return "violent";
}
