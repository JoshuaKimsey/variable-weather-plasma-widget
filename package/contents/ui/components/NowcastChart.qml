import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/units.js" as Units

ColumnLayout {
    id: nowcastRoot

    property var nowcastData: null
    property bool useMetric: true

    readonly property var points: nowcastData ? nowcastData.data : []
    readonly property bool isMerged: nowcastData && nowcastData.source === "merged"
    readonly property int pirateCount: (nowcastData && nowcastData.pirateCount) ? nowcastData.pirateCount : 0
    readonly property bool hasAnyPrecip: {
        for (var i = 0; i < points.length; i++) {
            if (points[i].precipProbability > 0 || points[i].precipIntensity > 0) return true;
        }
        return false;
    }

    // Build display-ready bar data with source tagging
    readonly property var barData: {
        if (!points || points.length === 0) return [];

        var bars = [];
        var pw = nowcastRoot.pirateCount;

        if (!nowcastRoot.isMerged || pw === 0) {
            // Single source - sample if needed
            var step = points.length > 48 ? Math.ceil(points.length / 48) : 1;
            for (var i = 0; i < points.length; i += step) {
                var p = points[i];
                bars.push({
                    time: p.time,
                    precipProbability: p.precipProbability,
                    precipIntensity: p.precipIntensity,
                    precipType: p.precipType,
                    source: nowcastData.source || "open-meteo"
                });
            }
            return bars;
        }

        // Merged: sample Pirate Weather 1-min bars down to ~20 bars
        var pwStep = Math.max(1, Math.ceil(pw / 20));
        for (var j = 0; j < pw; j += pwStep) {
            var pp = points[j];
            bars.push({
                time: pp.time,
                precipProbability: pp.precipProbability,
                precipIntensity: pp.precipIntensity,
                precipType: pp.precipType,
                source: "pirate-weather"
            });
        }

        // Add all Open-Meteo 15-min bars after
        for (var k = pw; k < points.length; k++) {
            var op = points[k];
            bars.push({
                time: op.time,
                precipProbability: op.precipProbability,
                precipIntensity: op.precipIntensity,
                precipType: op.precipType,
                source: "open-meteo"
            });
        }

        return bars;
    }

    // Find the index where source switches from pirate to open-meteo
    readonly property int sourceChangeIndex: {
        if (!isMerged) return -1;
        for (var i = 1; i < barData.length; i++) {
            if (barData[i].source === "open-meteo" && barData[i - 1].source === "pirate-weather") {
                return i;
            }
        }
        return -1;
    }

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        text: i18n("Precipitation Nowcast")
        font.weight: Font.DemiBold
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
    }

    // No precipitation message
    PlasmaComponents.Label {
        visible: !hasAnyPrecip && points.length > 0
        text: i18n("No precipitation expected")
        opacity: 0.7
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Kirigami.Units.largeSpacing
        Layout.bottomMargin: Kirigami.Units.largeSpacing
    }

    // Bar chart
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 7
        visible: hasAnyPrecip

        // Chart area
        Item {
            id: chartArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: timeLabelsRow.top
            anchors.bottomMargin: Kirigami.Units.smallSpacing

            Row {
                id: barRow
                anchors.bottom: parent.bottom
                height: parent.height
                spacing: 0

                Repeater {
                    model: nowcastRoot.barData

                    Item {
                        id: barDelegate

                        required property var modelData
                        required property int index

                        // Add extra gap at source boundary
                        property bool isSourceBoundary: index === nowcastRoot.sourceChangeIndex

                        width: {
                            var totalBars = nowcastRoot.barData.length;
                            var availableWidth = chartArea.width;
                            // Reserve space for the separator
                            if (nowcastRoot.sourceChangeIndex >= 0) availableWidth -= 8;
                            var barW = availableWidth / totalBars;
                            // Add separator space to this bar
                            if (isSourceBoundary) barW += 8;
                            return barW;
                        }
                        height: parent.height

                        // Source separator line
                        Rectangle {
                            visible: barDelegate.isSourceBoundary
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: Kirigami.Theme.textColor
                            opacity: 0.3
                        }

                        // Source labels at separator
                        PlasmaComponents.Label {
                            visible: barDelegate.isSourceBoundary
                            anchors.top: parent.top
                            anchors.right: parent.left
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            text: i18n("1-min")
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.85
                            opacity: 0.5
                        }

                        PlasmaComponents.Label {
                            visible: barDelegate.isSourceBoundary
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.leftMargin: Kirigami.Units.smallSpacing
                            text: i18n("15-min")
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.85
                            opacity: 0.5
                        }

                        // Bar
                        Rectangle {
                            visible: (modelData.precipProbability || 0) > 0 || (modelData.precipIntensity || 0) > 0
                            anchors.bottom: parent.bottom
                            x: barDelegate.isSourceBoundary ? 8 : 0
                            width: parent.width - (barDelegate.isSourceBoundary ? 9 : 1)
                            height: Math.max(2, (parent.height - Kirigami.Units.gridUnit) * (modelData.precipProbability || 0))
                            radius: 1

                            color: {
                                var pType = modelData.precipType || "rain";
                                var intensity = modelData.precipIntensity || 0;
                                var alpha = Math.min(1.0, 0.5 + intensity / 8);

                                if (pType === "snow") return Qt.rgba(0.6, 0.5, 0.85, alpha);
                                if (pType === "mix" || pType === "sleet") return Qt.rgba(0.3, 0.7, 0.7, alpha);
                                return Qt.rgba(0.25, 0.55, 0.95, alpha);
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true

                                PlasmaComponents.ToolTip {
                                    id: barTooltip
                                    visible: parent.containsMouse
                                    text: {
                                        var d = new Date(modelData.time);
                                        var timeStr = Qt.formatTime(d, "HH:mm");
                                        var prob = Math.round((modelData.precipProbability || 0) * 100) + "%";
                                        var intens = Units.formatPrecipIntensity(modelData.precipIntensity || 0, nowcastRoot.useMetric);
                                        var src = modelData.source === "pirate-weather" ? "Pirate Weather" : "Open-Meteo";
                                        return timeStr + "\n"
                                            + i18n("Probability: %1", prob) + "\n"
                                            + i18n("Intensity: %1", intens) + "\n"
                                            + i18n("Type: %1", modelData.precipType || "none") + "\n"
                                            + i18n("Source: %1", src);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Time labels - absolutely positioned within an Item
        Item {
            id: timeLabelsRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Kirigami.Units.gridUnit * 1.2

            Repeater {
                model: {
                    if (!nowcastRoot.barData || nowcastRoot.barData.length === 0) return [];
                    var total = nowcastRoot.barData.length;
                    // Pick 4-5 evenly spaced labels max
                    var labelCount = Math.min(5, total);
                    if (labelCount < 2) return [{ time: nowcastRoot.barData[0].time, position: 0 }];

                    var step = (total - 1) / (labelCount - 1);
                    var labels = [];
                    for (var i = 0; i < labelCount; i++) {
                        var idx = Math.round(i * step);
                        labels.push({
                            time: nowcastRoot.barData[idx].time,
                            position: idx / (total - 1)
                        });
                    }
                    return labels;
                }

                PlasmaComponents.Label {
                    required property var modelData
                    required property int index

                    y: 0
                    x: {
                        var totalWidth = timeLabelsRow.width;
                        var pos = modelData.position * totalWidth;
                        var labelW = implicitWidth;
                        // Center on position, clamp to edges
                        return Math.max(0, Math.min(pos - labelW / 2, totalWidth - labelW));
                    }

                    text: {
                        var d = new Date(modelData.time);
                        return Qt.formatTime(d, "HH:mm");
                    }
                    font: Kirigami.Theme.smallFont
                    opacity: 0.6
                }
            }
        }
    }
}
