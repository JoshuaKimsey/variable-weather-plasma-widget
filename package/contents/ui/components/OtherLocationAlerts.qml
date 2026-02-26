import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: otherAlertsRoot

    property var otherAlerts: [] // array of { locationName, alerts }
    signal switchLocation(var loc)

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        text: i18n("Alerts at Other Locations")
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
        opacity: 0.7
    }

    Repeater {
        model: otherAlertsRoot.otherAlerts

        ColumnLayout {
            id: locGroup
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 1

            Repeater {
                model: locGroup.modelData.alerts

                Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: alertRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                    radius: Kirigami.Units.cornerRadius
                    color: "transparent"

                    Rectangle {
                        id: severityBar
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        radius: 1
                        color: {
                            switch (modelData.severity) {
                                case "extreme": return "#d32f2f";
                                case "severe":  return "#f44336";
                                case "moderate": return "#ff9800";
                                case "minor":   return "#ffb74d";
                                default:        return "#ff9800";
                            }
                        }
                    }

                    RowLayout {
                        id: alertRow
                        anchors.fill: parent
                        anchors.leftMargin: severityBar.width + Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: locGroup.modelData.locationName
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.weight: Font.Bold
                            Layout.maximumWidth: otherAlertsRoot.width * 0.35
                            elide: Text.ElideRight
                        }

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: modelData.title
                            font: Kirigami.Theme.smallFont
                            elide: Text.ElideRight
                            opacity: 0.8
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Find the saved location matching this alert's location name
                            for (var i = 0; i < root.savedLocationsList.length; i++) {
                                if (root.savedLocationsList[i].name === locGroup.modelData.locationName) {
                                    otherAlertsRoot.switchLocation(root.savedLocationsList[i]);
                                    return;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
