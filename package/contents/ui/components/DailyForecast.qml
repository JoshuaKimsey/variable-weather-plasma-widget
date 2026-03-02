import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/units.js" as Units

ColumnLayout {
    id: dailyRoot

    property var dailyData: []
    property bool useMetric: true

    // Future days only (skip today at index 0)
    readonly property var futureDays: {
        if (!dailyData || dailyData.length <= 1) return [];
        return dailyData.slice(1);
    }

    // Compute global min/max across ALL days (including today) for consistent coloring
    readonly property real globalMin: {
        var m = 100;
        for (var i = 0; i < dailyData.length; i++) {
            m = Math.min(m, dailyData[i].tempMin);
        }
        return m;
    }
    readonly property real globalMax: {
        var m = -100;
        for (var i = 0; i < dailyData.length; i++) {
            m = Math.max(m, dailyData[i].tempMax);
        }
        return m;
    }
    readonly property real globalRange: globalMax - globalMin > 0 ? globalMax - globalMin : 1

    // Expose tempColor so the today bar in FullRepresentation can use the same spectrum
    function tempColor(globalFrac) {
        var t = Math.max(0, Math.min(1, globalFrac));
        if (t < 0.33) {
            var f = t / 0.33;
            return Qt.rgba(0.259 + f * (0.400 - 0.259),
                           0.647 + f * (0.733 - 0.647),
                           0.961 + f * (0.416 - 0.961), 1);
        } else if (t < 0.67) {
            var f2 = (t - 0.33) / 0.34;
            return Qt.rgba(0.400 + f2 * (1.000 - 0.400),
                           0.733 + f2 * (0.596 - 0.733),
                           0.416 + f2 * (0.000 - 0.416), 1);
        } else {
            var f3 = (t - 0.67) / 0.33;
            return Qt.rgba(1.000,
                           0.596 + f3 * (0.439 - 0.596),
                           0.000 + f3 * (0.263 - 0.000), 1);
        }
    }

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        text: i18n("5-Day Forecast")
        font.weight: Font.DemiBold
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
    }

    Repeater {
        model: dailyRoot.futureDays

        RowLayout {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            // Day name
            PlasmaComponents.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                text: {
                    if (!modelData || !modelData.time) return "";
                    return Qt.formatDate(new Date(modelData.time), "ddd");
                }
            }

            // Weather icon
            Image {
                source: modelData ? root.iconPath(modelData.icon) : ""
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(Kirigami.Units.iconSizes.small, Kirigami.Units.iconSizes.small)
            }

            // Precip probability
            PlasmaComponents.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                text: modelData && modelData.precipProbability > 0 ? modelData.precipProbability + "%" : ""
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.linkColor
                horizontalAlignment: Text.AlignRight
            }

            // Low temp
            PlasmaComponents.Label {
                text: modelData ? Units.formatTemp(modelData.tempMin, dailyRoot.useMetric) : ""
                font.weight: Font.DemiBold
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                horizontalAlignment: Text.AlignRight
            }

            // Temperature bar - fills remaining space
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6

                // Background track
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: Kirigami.Theme.textColor
                    opacity: 0.15
                }

                // Colored bar (not a child of the background, so opacity is independent)
                Rectangle {
                    id: tempBar
                    x: parent.width * (modelData.tempMin - dailyRoot.globalMin) / dailyRoot.globalRange
                    width: Math.max(6, parent.width * (modelData.tempMax - modelData.tempMin) / dailyRoot.globalRange)
                    height: parent.height
                    radius: 3

                    readonly property real globalStartFrac: (modelData.tempMin - dailyRoot.globalMin) / dailyRoot.globalRange
                    readonly property real globalEndFrac: (modelData.tempMax - dailyRoot.globalMin) / dailyRoot.globalRange

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: dailyRoot.tempColor(tempBar.globalStartFrac) }
                        GradientStop { position: 0.5; color: dailyRoot.tempColor((tempBar.globalStartFrac + tempBar.globalEndFrac) / 2) }
                        GradientStop { position: 1.0; color: dailyRoot.tempColor(tempBar.globalEndFrac) }
                    }
                }
            }

            // High temp
            PlasmaComponents.Label {
                text: modelData ? Units.formatTemp(modelData.tempMax, dailyRoot.useMetric) : ""
                font.weight: Font.DemiBold
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
            }
        }
    }
}
