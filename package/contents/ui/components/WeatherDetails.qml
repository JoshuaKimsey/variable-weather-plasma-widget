import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/units.js" as Units

Item {
    id: detailsRoot

    property var weatherData: null
    property bool useMetric: true
    property bool pressureInMillibar: true

    readonly property var current: weatherData ? weatherData.current : null

    implicitHeight: detailsGrid.implicitHeight

    GridLayout {
        id: detailsGrid
        anchors.horizontalCenter: parent.horizontalCenter
        columns: 3
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.largeSpacing

        DetailItem {
            label: i18n("Humidity")
            value: current ? Units.formatHumidity(current.humidity) : ""
        }

        DetailItem {
            label: i18n("Wind")
            value: current ? Units.formatWind(current.windSpeed, detailsRoot.useMetric) + " " + Units.windDirectionToString(current.windDirection) : ""
        }

        DetailItem {
            label: i18n("Pressure")
            value: current ? Units.formatPressure(current.pressure, detailsRoot.useMetric, detailsRoot.pressureInMillibar) : ""
        }

        DetailItem {
            label: i18n("Cloud Cover")
            value: current ? Units.formatCloudCover(current.cloudCover) : ""
        }

        DetailItem {
            label: i18n("Gusts")
            value: current ? Units.formatWind(current.windGusts, detailsRoot.useMetric) : ""
        }

        DetailItem {
            label: i18n("Precip")
            value: current ? Units.formatPrecipIntensity(current.precipitation, detailsRoot.useMetric) : ""
        }

        component DetailItem: ColumnLayout {
            property string label: ""
            property string value: ""

            spacing: 0

            PlasmaComponents.Label {
                text: label
                font: Kirigami.Theme.smallFont
                opacity: 0.6
            }

            PlasmaComponents.Label {
                text: value
                font.weight: Font.DemiBold
            }
        }
    }
}
