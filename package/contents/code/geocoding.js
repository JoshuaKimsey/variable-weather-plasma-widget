// Open-Meteo Geocoding API integration

var GEOCODING_ENDPOINT = "https://geocoding-api.open-meteo.com/v1/search";

function searchLocation(query, callback) {
    if (!query || query.length < 2) {
        callback(null, []);
        return;
    }

    var url = GEOCODING_ENDPOINT + "?name=" + encodeURIComponent(query) + "&count=5&language=en";

    var xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;

        if (xhr.status !== 200) {
            callback("HTTP " + xhr.status, []);
            return;
        }

        try {
            var data = JSON.parse(xhr.responseText);
            var results = [];
            if (data.results) {
                for (var i = 0; i < data.results.length; i++) {
                    var r = data.results[i];
                    results.push({
                        name: r.name,
                        country: r.country || "",
                        admin1: r.admin1 || "",
                        latitude: r.latitude,
                        longitude: r.longitude
                    });
                }
            }
            callback(null, results);
        } catch (e) {
            callback(e.toString(), []);
        }
    };
    xhr.send();
}
