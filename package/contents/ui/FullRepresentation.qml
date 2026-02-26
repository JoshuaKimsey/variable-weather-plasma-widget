import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "components" as Components
import "../code/units.js" as Units

PlasmaExtras.Representation {
    id: fullRoot

    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
    Layout.preferredHeight: Kirigami.Units.gridUnit * 26
    Layout.minimumWidth: Kirigami.Units.gridUnit * 16
    Layout.minimumHeight: Kirigami.Units.gridUnit * 18

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            // Location name — plain label if no saved locations, dropdown button if saved locations exist
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: !root.savedLocationsList || root.savedLocationsList.length === 0
                text: plasmoid.configuration.locationName || i18n("Variable Weather")
                elide: Text.ElideRight
                font.weight: Font.DemiBold
            }

            PlasmaComponents.ToolButton {
                id: locationSwitcher
                Layout.fillWidth: true
                visible: root.savedLocationsList && root.savedLocationsList.length > 0
                text: plasmoid.configuration.locationName || i18n("Variable Weather")
                font.weight: Font.DemiBold
                display: PlasmaComponents.AbstractButton.TextOnly
                onClicked: locationMenu.open()

                PlasmaComponents.Menu {
                    id: locationMenu
                    y: locationSwitcher.height

                    Repeater {
                        model: root.savedLocationsList

                        PlasmaComponents.MenuItem {
                            required property var modelData
                            required property int index
                            text: modelData.name
                            checkable: true
                            checked: modelData.latitude === plasmoid.configuration.latitude
                                  && modelData.longitude === plasmoid.configuration.longitude
                            font.weight: checked ? Font.Bold : Font.Normal
                            onTriggered: root.switchToLocation(modelData)
                        }
                    }

                    PlasmaComponents.MenuSeparator {}

                    PlasmaComponents.MenuItem {
                        text: i18n("Manage Locations...")
                        icon.name: "configure"
                        onTriggered: plasmoid.internalAction("configure").trigger()
                    }
                }
            }

            PlasmaComponents.Label {
                visible: root.appState === "data"
                text: root.lastUpdated.getTime() > 0
                    ? i18n("Updated %1", Qt.formatTime(root.lastUpdated, "hh:mm"))
                    : ""
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }

            PlasmaComponents.BusyIndicator {
                visible: root.isLoading && root.appState === "data"
                running: visible
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }

            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                onClicked: root.fetchWeatherData()
                enabled: !root.isLoading

                PlasmaComponents.ToolTip {
                    text: i18n("Refresh")
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: "configure"
                onClicked: plasmoid.internalAction("configure").trigger()

                PlasmaComponents.ToolTip {
                    text: i18n("Settings")
                }
            }
        }
    }

    // Needs Config state
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.appState === "needsConfig"
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: "configure"
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            Layout.alignment: Qt.AlignHCenter
        }

        PlasmaComponents.Label {
            text: i18n("Set your location to get started.")
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        PlasmaComponents.Button {
            text: i18n("Open Settings")
            icon.name: "configure"
            Layout.alignment: Qt.AlignHCenter
            onClicked: plasmoid.internalAction("configure").trigger()
        }
    }

    // Loading state
    PlasmaComponents.BusyIndicator {
        anchors.centerIn: parent
        visible: root.appState === "loading"
        running: visible
    }

    // Error state
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.appState === "error"
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: "dialog-error"
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            Layout.alignment: Qt.AlignHCenter
        }

        PlasmaComponents.Label {
            text: root.errorMessage || i18n("Failed to load weather data")
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        PlasmaComponents.Button {
            text: i18n("Retry")
            icon.name: "view-refresh"
            Layout.alignment: Qt.AlignHCenter
            onClicked: root.fetchWeatherData()
        }
    }

    // Data state - scrollable content
    QQC2.ScrollView {
        anchors.fill: parent
        visible: root.appState === "data"
        contentWidth: availableWidth
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.mediumSpacing

            // Stale data indicator
            Rectangle {
                Layout.fillWidth: true
                visible: root.errorMessage !== "" && root.appState === "data"
                implicitHeight: staleLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: Kirigami.Theme.neutralBackgroundColor
                opacity: 0.8

                PlasmaComponents.Label {
                    id: staleLabel
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.smallSpacing * 2
                    text: root.errorMessage
                    font: Kirigami.Theme.smallFont
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Weather Alerts (at top if present)
            Components.WeatherAlerts {
                Layout.fillWidth: true
                alerts: root.alertsData
                visible: root.alertsData.length > 0
            }

            // Alerts at other saved locations
            Components.OtherLocationAlerts {
                Layout.fillWidth: true
                otherAlerts: root.otherLocationAlerts
                visible: root.otherLocationAlerts && root.otherLocationAlerts.length > 0
                onSwitchLocation: function(loc) { root.switchToLocation(loc) }
            }

            // Current Weather
            Components.CurrentWeather {
                Layout.fillWidth: true
                weatherData: root.weatherData
                useMetric: root.useMetric
            }

            // Weather Details
            Components.WeatherDetails {
                Layout.fillWidth: true
                weatherData: root.weatherData
                useMetric: root.useMetric
                pressureInMillibar: plasmoid.configuration.pressureInMillibar
            }

            // Hourly Forecast
            Components.HourlyForecast {
                Layout.fillWidth: true
                hourlyData: root.weatherData ? root.weatherData.hourly : []
                useMetric: root.useMetric
            }

            // Nowcast Chart
            Components.NowcastChart {
                Layout.fillWidth: true
                nowcastData: root.nowcastData
                useMetric: root.useMetric
                visible: root.nowcastData && root.nowcastData.data && root.nowcastData.data.length > 0
            }

            // Daily Forecast
            Components.DailyForecast {
                Layout.fillWidth: true
                dailyData: root.weatherData ? root.weatherData.daily : []
                useMetric: root.useMetric
            }

            // Attribution footer
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.hasPirateKey
                    ? i18n("Data: Open-Meteo (CC BY 4.0) & Pirate Weather")
                    : i18n("Data: Open-Meteo (CC BY 4.0)")
                font: Kirigami.Theme.smallFont
                opacity: 0.5
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
