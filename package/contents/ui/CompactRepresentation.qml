import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/units.js" as Units

MouseArea {
    id: compactRoot

    readonly property bool hasData: root.weatherData && root.weatherData.current
    readonly property bool hasAlerts: root.hasAnyAlerts
    readonly property bool hasCurrentAlerts: root.alertsData && root.alertsData.length > 0

    onClicked: root.expanded = !root.expanded

    Layout.minimumWidth: compactRow.implicitWidth
    Layout.preferredWidth: compactRow.implicitWidth

    RowLayout {
        id: compactRow
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        // Weather icon with alert badge
        Item {
            visible: hasData
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium

            Image {
                id: weatherIcon
                anchors.fill: parent
                source: hasData ? root.iconPath(root.weatherData.current.icon) : ""
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(Kirigami.Units.iconSizes.medium, Kirigami.Units.iconSizes.medium)
            }

            // Alert badge
            Rectangle {
                visible: compactRoot.hasAlerts
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -2
                anchors.rightMargin: -2
                width: Kirigami.Units.iconSizes.small * 0.7
                height: width
                radius: width / 2
                color: {
                    if (!compactRoot.hasAlerts) return "transparent";
                    var severity;
                    if (compactRoot.hasCurrentAlerts) {
                        severity = root.alertsData[0].severity;
                    } else {
                        severity = root.highestOtherAlertSeverity;
                    }
                    if (severity === "extreme") return "#d32f2f";
                    if (severity === "severe") return "#f44336";
                    if (severity === "moderate") return "#ff9800";
                    return "#ffb74d";
                }
                border.width: 1
                border.color: Qt.darker(color, 1.2)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "dialog-warning-symbolic"
                    width: parent.width * 0.7
                    height: width
                    color: "white"
                }
            }
        }

        Kirigami.Icon {
            source: "weather-none-available"
            visible: !hasData && root.appState !== "loading"
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        }

        PlasmaComponents.BusyIndicator {
            visible: root.isLoading && !hasData
            running: visible
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        }

        PlasmaComponents.Label {
            id: tempLabel
            visible: hasData
            text: hasData ? Units.formatTemp(root.weatherData.current.temperature, root.useMetric) : ""
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
        }
    }
}
