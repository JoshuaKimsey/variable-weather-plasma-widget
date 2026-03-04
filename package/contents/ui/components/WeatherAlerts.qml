import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: alertsRoot

    property var alerts: []

    spacing: Kirigami.Units.smallSpacing

    Repeater {
        model: alertsRoot.alerts

        Rectangle {
            id: alertBanner

            required property var modelData
            required property int index

            property bool expanded: false

            Layout.fillWidth: true
            implicitHeight: alertContent.implicitHeight + Kirigami.Units.smallSpacing * 2
            radius: Kirigami.Units.cornerRadius
            clip: true

            color: {
                switch (modelData.severity) {
                    case "extreme": return "#d32f2f";
                    case "severe":  return "#f44336";
                    case "moderate": return "#ff9800";
                    case "minor":   return "#ffb74d";
                    default:        return "#ff9800";
                }
            }

            ColumnLayout {
                id: alertContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    Kirigami.Icon {
                        source: "dialog-warning"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        color: "white"
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: modelData.title
                        font.weight: Font.Bold
                        color: "white"
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.ToolButton {
                        icon.name: alertBanner.expanded ? "arrow-up" : "arrow-down"
                        onClicked: alertBanner.expanded = !alertBanner.expanded
                        visible: modelData.description !== ""
                        Kirigami.Theme.textColor: "white"
                    }
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: alertBanner.expanded
                    text: modelData.description
                    wrapMode: Text.Wrap
                    color: "white"
                    opacity: 0.9
                    font: Kirigami.Theme.smallFont
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: alertBanner.expanded && modelData.expires
                    text: modelData.expires ? i18n("Expires: %1", new Date(modelData.expires).toLocaleString()) : ""
                    wrapMode: Text.Wrap
                    color: "white"
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: alertBanner.expanded = !alertBanner.expanded
            }
        }
    }
}
