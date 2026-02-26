import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/units.js" as Units

Item {
    id: currentRoot

    property var weatherData: null
    property bool useMetric: true

    readonly property var current: weatherData ? weatherData.current : null

    implicitHeight: contentRow.implicitHeight

    RowLayout {
        id: contentRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Kirigami.Units.largeSpacing

        // Weather icon
        Image {
            source: current ? root.iconPath(current.icon) : ""
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(Kirigami.Units.iconSizes.huge, Kirigami.Units.iconSizes.huge)
        }

        ColumnLayout {
            spacing: 2

            // Temperature
            PlasmaComponents.Label {
                text: current ? Units.formatTemp(current.temperature, currentRoot.useMetric) : ""
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 3
                font.weight: Font.Light
            }

            // Condition text
            PlasmaComponents.Label {
                text: current ? current.description : ""
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
            }

            // Feels like
            PlasmaComponents.Label {
                text: current ? i18n("Feels like %1", Units.formatTemp(current.feelsLike, currentRoot.useMetric)) : ""
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
        }
    }
}
