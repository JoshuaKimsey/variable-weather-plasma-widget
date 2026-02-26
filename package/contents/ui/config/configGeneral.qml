import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configRoot

    property alias cfg_latitude: latitudeField.text
    property alias cfg_longitude: longitudeField.text
    property alias cfg_locationName: locationNameField.text
    property alias cfg_pirateWeatherApiKey: apiKeyField.text
    property alias cfg_refreshPeriod: refreshSpinner.value
    property string cfg_units
    property alias cfg_usePirateWeatherAlerts: alertsToggle.checked
    property alias cfg_pressureInMillibar: millibarToggle.checked
    property string cfg_savedLocations

    property var searchResults: []
    property bool isSearching: false
    property var parsedSavedLocations: []

    function parseSavedLocationsConfig() {
        try {
            var parsed = JSON.parse(cfg_savedLocations);
            parsedSavedLocations = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            parsedSavedLocations = [];
        }
    }

    function saveParsedLocations() {
        cfg_savedLocations = JSON.stringify(parsedSavedLocations);
    }

    function isCurrentLocationSaved() {
        if (!cfg_latitude || !cfg_longitude) return true; // disable if no location set
        for (var i = 0; i < parsedSavedLocations.length; i++) {
            if (parsedSavedLocations[i].latitude === cfg_latitude
                && parsedSavedLocations[i].longitude === cfg_longitude) {
                return true;
            }
        }
        return false;
    }

    function saveCurrentLocation() {
        if (isCurrentLocationSaved()) return;
        var newList = parsedSavedLocations.slice();
        newList.push({
            name: cfg_locationName || (cfg_latitude + ", " + cfg_longitude),
            latitude: cfg_latitude,
            longitude: cfg_longitude
        });
        parsedSavedLocations = newList;
        saveParsedLocations();
    }

    function removeSavedLocation(index) {
        var newList = parsedSavedLocations.slice();
        newList.splice(index, 1);
        parsedSavedLocations = newList;
        saveParsedLocations();
    }

    function activateSavedLocation(loc) {
        cfg_latitude = loc.latitude;
        cfg_longitude = loc.longitude;
        cfg_locationName = loc.name;
    }

    Component.onCompleted: parseSavedLocationsConfig()

    function searchLocation(query) {
        if (query.length < 2) return;
        isSearching = true;
        searchResults = [];

        var xhr = new XMLHttpRequest();
        var url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query) + "&count=5&language=en";
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isSearching = false;
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        if (data.results) {
                            searchResults = data.results;
                        } else {
                            searchResults = [];
                        }
                    } catch (e) {
                        searchResults = [];
                    }
                }
            }
        };
        xhr.send();
    }

    function selectLocation(result) {
        cfg_latitude = result.latitude.toString();
        cfg_longitude = result.longitude.toString();

        var name = result.name;
        if (result.admin1) {
            name += ", " + result.admin1;
        }
        if (result.country) {
            name += ", " + result.country;
        }
        cfg_locationName = name;

        searchResults = [];
        searchField.text = "";
    }

    Kirigami.FormLayout {
        // Location Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Location")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Search:")

            QQC2.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Enter city name...")
                onAccepted: configRoot.searchLocation(text)
            }

            QQC2.Button {
                icon.name: "search"
                onClicked: configRoot.searchLocation(searchField.text)
                enabled: searchField.text.length >= 2 && !configRoot.isSearching
            }
        }

        QQC2.BusyIndicator {
            visible: configRoot.isSearching
            running: configRoot.isSearching
            Layout.alignment: Qt.AlignHCenter
        }

        ColumnLayout {
            visible: configRoot.searchResults.length > 0
            Kirigami.FormData.label: i18n("Results:")
            Layout.fillWidth: true

            Repeater {
                model: configRoot.searchResults

                QQC2.ItemDelegate {
                    Layout.fillWidth: true
                    text: {
                        var label = modelData.name;
                        if (modelData.admin1) label += ", " + modelData.admin1;
                        if (modelData.country) label += ", " + modelData.country;
                        return label;
                    }
                    onClicked: configRoot.selectLocation(modelData)
                }
            }
        }

        QQC2.TextField {
            id: locationNameField
            Kirigami.FormData.label: i18n("Location name:")
            Layout.fillWidth: true
            placeholderText: i18n("Display name for this location")
        }

        QQC2.TextField {
            id: latitudeField
            Kirigami.FormData.label: i18n("Latitude:")
            Layout.fillWidth: true
            placeholderText: i18n("e.g., 40.7128")
            inputMethodHints: Qt.ImhFormattedNumbersOnly
        }

        QQC2.TextField {
            id: longitudeField
            Kirigami.FormData.label: i18n("Longitude:")
            Layout.fillWidth: true
            placeholderText: i18n("e.g., -74.0060")
            inputMethodHints: Qt.ImhFormattedNumbersOnly
        }

        // Saved Locations Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Saved Locations")
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Current location:")
            text: i18n("Save Current Location")
            icon.name: "bookmark-new"
            enabled: cfg_latitude !== "" && cfg_longitude !== "" && !configRoot.isCurrentLocationSaved()
            onClicked: configRoot.saveCurrentLocation()
        }

        ColumnLayout {
            Kirigami.FormData.label: configRoot.parsedSavedLocations.length > 0 ? i18n("Saved:") : ""
            Layout.fillWidth: true
            visible: configRoot.parsedSavedLocations.length > 0

            Repeater {
                model: configRoot.parsedSavedLocations

                RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData.name
                        elide: Text.ElideRight
                    }

                    QQC2.ToolButton {
                        icon.name: "go-next"
                        onClicked: configRoot.activateSavedLocation(modelData)
                        QQC2.ToolTip.text: i18n("Activate")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    QQC2.ToolButton {
                        icon.name: "edit-delete"
                        onClicked: configRoot.removeSavedLocation(index)
                        QQC2.ToolTip.text: i18n("Remove")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }
            }
        }

        // API Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Pirate Weather (Optional)")
        }

        QQC2.TextField {
            id: apiKeyField
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            placeholderText: i18n("Enter Pirate Weather API key")
            echoMode: TextInput.Password
        }

        QQC2.Label {
            text: i18n("Provides 1-minute precipitation nowcast and weather alerts.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        // Display Section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Display")
        }

        QQC2.SpinBox {
            id: refreshSpinner
            Kirigami.FormData.label: i18n("Refresh interval (min):")
            from: 5
            to: 60
            stepSize: 5
        }

        QQC2.ComboBox {
            id: unitsCombo
            Kirigami.FormData.label: i18n("Units:")
            model: [
                { text: i18n("Auto (system locale)"), value: "auto" },
                { text: i18n("Metric (°C, km/h)"), value: "metric" },
                { text: i18n("Imperial (°F, mph)"), value: "imperial" }
            ]
            textRole: "text"
            currentIndex: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === cfg_units) return i;
                }
                return 0;
            }
            onActivated: function(index) {
                cfg_units = model[index].value;
            }
        }

        QQC2.CheckBox {
            id: millibarToggle
            Kirigami.FormData.label: i18n("Pressure unit:")
            text: i18n("Show pressure in millibar (mbar)")
        }

        QQC2.Label {
            text: i18n("When off, shows hPa (metric) or inHg (imperial) based on unit setting.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: alertsToggle
            Kirigami.FormData.label: i18n("Weather alerts:")
            text: i18n("Show alerts when Pirate Weather key is set")
        }
    }
}
