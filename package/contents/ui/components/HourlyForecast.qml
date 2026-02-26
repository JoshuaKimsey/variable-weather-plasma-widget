import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/units.js" as Units

ColumnLayout {
    id: hourlyRoot

    property var hourlyData: []
    property bool useMetric: true

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        text: i18n("Hourly Forecast")
        font.weight: Font.DemiBold
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
    }

    // Scrollable hourly list with fade edges
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 5

        ListView {
            id: hourlyList
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.smallSpacing
            clip: true
            model: hourlyRoot.hourlyData

            delegate: ColumnLayout {
                id: hourlyDelegate

                required property var modelData
                required property int index

                width: Kirigami.Units.gridUnit * 3.5
                spacing: Kirigami.Units.smallSpacing

                // Time label
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (!modelData || !modelData.time) return "";
                        var d = new Date(modelData.time);
                        return Qt.formatTime(d, "h AP");
                    }
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }

                // Weather icon
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: modelData ? root.iconPath(modelData.icon) : ""
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(Kirigami.Units.iconSizes.smallMedium, Kirigami.Units.iconSizes.smallMedium)
                }

                // Temperature
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData ? Units.formatTemp(modelData.temperature, hourlyRoot.useMetric) : ""
                    font.weight: Font.DemiBold
                }

                // Precip probability (if > 0)
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    visible: modelData && modelData.precipProbability > 0
                    text: modelData ? modelData.precipProbability + "%" : ""
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.linkColor
                }
            }
        }

        // Left fade - indicates more content to the left
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Kirigami.Units.gridUnit * 1.5
            visible: hourlyList.contentX > 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.9) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Right fade - indicates more content to the right
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Kirigami.Units.gridUnit * 1.5
            visible: hourlyList.contentX < (hourlyList.contentWidth - hourlyList.width - 1)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.9) }
            }
        }
    }
}
