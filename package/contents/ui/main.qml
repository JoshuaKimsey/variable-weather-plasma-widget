import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../code/api.js" as Api
import "../code/pirateweather.js" as PirateWeather
import "../code/units.js" as Units

PlasmoidItem {
    id: root

    // Data model
    property var weatherData: null
    property var nowcastData: null
    property var alertsData: []
    property bool isLoading: true
    property string errorMessage: ""
    property string appState: "loading" // "loading" | "data" | "error" | "needsConfig"
    property date lastUpdated: new Date(0)

    // Cached data for network resilience
    property var cachedWeatherData: null
    property var cachedNowcastData: null
    property var cachedAlertsData: []

    // Saved locations
    property var savedLocationsList: []
    property var otherLocationAlerts: [] // array of { locationName, alerts }

    // Computed helpers
    readonly property bool hasLocation: plasmoid.configuration.latitude !== "" && plasmoid.configuration.longitude !== ""
    readonly property bool hasPirateKey: plasmoid.configuration.pirateWeatherApiKey !== ""
    readonly property bool useMetric: Units.isMetric(plasmoid.configuration.units)
    readonly property bool hasAnyAlerts: (alertsData && alertsData.length > 0) || (otherLocationAlerts && otherLocationAlerts.length > 0)
    readonly property string highestOtherAlertSeverity: {
        if (!otherLocationAlerts || otherLocationAlerts.length === 0) return "";
        var severityOrder = { "extreme": 4, "severe": 3, "moderate": 2, "minor": 1 };
        var highest = "";
        var highestVal = 0;
        for (var i = 0; i < otherLocationAlerts.length; i++) {
            var locAlerts = otherLocationAlerts[i].alerts;
            for (var j = 0; j < locAlerts.length; j++) {
                var sev = locAlerts[j].severity;
                var val = severityOrder[sev] || 0;
                if (val > highestVal) {
                    highestVal = val;
                    highest = sev;
                }
            }
        }
        return highest;
    }

    // Icon path helper
    function iconPath(iconName) {
        return Qt.resolvedUrl("../icons/" + iconName + ".svg");
    }

    // Saved locations helpers
    function parseSavedLocations() {
        try {
            var parsed = JSON.parse(plasmoid.configuration.savedLocations);
            savedLocationsList = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            savedLocationsList = [];
        }
    }

    function switchToLocation(loc) {
        plasmoid.configuration.latitude = loc.latitude;
        plasmoid.configuration.longitude = loc.longitude;
        plasmoid.configuration.locationName = loc.name;
    }

    function fetchOtherLocationAlerts() {
        if (!hasPirateKey || !plasmoid.configuration.usePirateWeatherAlerts) return;
        if (!savedLocationsList || savedLocationsList.length === 0) return;

        var currentLat = plasmoid.configuration.latitude;
        var currentLon = plasmoid.configuration.longitude;
        var apiKey = plasmoid.configuration.pirateWeatherApiKey;
        var otherLocs = [];

        for (var i = 0; i < savedLocationsList.length; i++) {
            var loc = savedLocationsList[i];
            if (loc.latitude === currentLat && loc.longitude === currentLon) continue;
            otherLocs.push(loc);
        }

        if (otherLocs.length === 0) {
            otherLocationAlerts = [];
            return;
        }

        var results = [];
        var pending = otherLocs.length;

        for (var j = 0; j < otherLocs.length; j++) {
            (function(loc) {
                PirateWeather.fetchAlerts(apiKey, loc.latitude, loc.longitude, function(err, alerts) {
                    if (!err && alerts && alerts.length > 0) {
                        results.push({ locationName: loc.name, alerts: alerts });
                    }
                    pending--;
                    if (pending === 0) {
                        otherLocationAlerts = results;
                    }
                });
            })(otherLocs[j]);
        }
    }

    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 10

    toolTipMainText: {
        if (!weatherData || !weatherData.current) return "Variable Weather";
        return plasmoid.configuration.locationName || "Weather";
    }
    toolTipSubText: {
        if (appState === "needsConfig") return i18n("Click to configure location");
        if (appState === "error") return errorMessage;
        if (!weatherData || !weatherData.current) return i18n("Loading...");
        var c = weatherData.current;
        var text = c.description + " " + Units.formatTemp(c.temperature, useMetric)
            + "\n" + i18n("Feels like") + " " + Units.formatTemp(c.feelsLike, useMetric);
        if (alertsData && alertsData.length > 0) {
            text += "\n⚠ " + alertsData[0].title;
        }
        return text;
    }
    toolTipTextFormat: Text.PlainText

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.fetchWeatherData()
        }
    ]

    // Refresh timer
    Timer {
        id: refreshTimer
        interval: plasmoid.configuration.refreshPeriod * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchWeatherData()
    }

    // Debounce timer for config changes (avoids double-fetch when lat+lon change together)
    Timer {
        id: configChangeTimer
        interval: 500
        onTriggered: root.fetchWeatherData()
    }

    // React to config changes
    Connections {
        target: plasmoid.configuration
        function onLatitudeChanged() { configChangeTimer.restart(); }
        function onLongitudeChanged() { configChangeTimer.restart(); }
        function onPirateWeatherApiKeyChanged() { configChangeTimer.restart(); }
        function onRefreshPeriodChanged() {
            refreshTimer.interval = plasmoid.configuration.refreshPeriod * 60 * 1000;
        }
        function onSavedLocationsChanged() { parseSavedLocations(); }
    }

    function fetchWeatherData() {
        if (!hasLocation) {
            appState = "needsConfig";
            isLoading = false;
            return;
        }

        isLoading = true;
        if (appState !== "data") {
            appState = "loading";
        }

        var lat = plasmoid.configuration.latitude;
        var lon = plasmoid.configuration.longitude;
        var apiKey = plasmoid.configuration.pirateWeatherApiKey;
        var useAlerts = plasmoid.configuration.usePirateWeatherAlerts;

        Api.fetchAllWeatherData(lat, lon, apiKey, useAlerts, function(err, data) {
            isLoading = false;

            if (err) {
                // Use cached data if available
                if (cachedWeatherData) {
                    weatherData = cachedWeatherData;
                    nowcastData = cachedNowcastData;
                    alertsData = cachedAlertsData;
                    appState = "data";
                    errorMessage = i18n("Using cached data. Last updated: %1",
                        Qt.formatDateTime(lastUpdated, "hh:mm"));
                } else {
                    errorMessage = err;
                    appState = "error";
                }
                return;
            }

            weatherData = data.weather;
            nowcastData = data.nowcast;
            alertsData = data.alerts || [];
            lastUpdated = new Date();
            appState = "data";
            errorMessage = "";

            // Cache for resilience
            cachedWeatherData = data.weather;
            cachedNowcastData = data.nowcast;
            cachedAlertsData = data.alerts || [];

            // Fetch alerts for other saved locations
            fetchOtherLocationAlerts();
        });
    }

    Component.onCompleted: {
        parseSavedLocations();
        if (!hasLocation) {
            appState = "needsConfig";
            isLoading = false;
        }
    }
}
