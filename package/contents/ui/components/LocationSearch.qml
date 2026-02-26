import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/geocoding.js" as Geocoding

ColumnLayout {
    id: searchRoot

    signal locationSelected(var result)

    property var searchResults: []
    property bool isSearching: false

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true

        QQC2.TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: i18n("Search for a city...")
            onAccepted: searchRoot.doSearch()
        }

        QQC2.Button {
            icon.name: "search"
            onClicked: searchRoot.doSearch()
            enabled: searchField.text.length >= 2 && !searchRoot.isSearching
        }
    }

    QQC2.BusyIndicator {
        visible: searchRoot.isSearching
        running: searchRoot.isSearching
        Layout.alignment: Qt.AlignHCenter
    }

    Repeater {
        model: searchRoot.searchResults

        QQC2.ItemDelegate {
            Layout.fillWidth: true
            text: {
                var label = modelData.name;
                if (modelData.admin1) label += ", " + modelData.admin1;
                if (modelData.country) label += ", " + modelData.country;
                return label;
            }
            onClicked: {
                searchRoot.locationSelected(modelData);
                searchRoot.searchResults = [];
                searchField.text = "";
            }
        }
    }

    function doSearch() {
        if (searchField.text.length < 2) return;
        isSearching = true;
        searchResults = [];

        Geocoding.searchLocation(searchField.text, function(err, results) {
            isSearching = false;
            if (!err) {
                searchResults = results;
            }
        });
    }
}
