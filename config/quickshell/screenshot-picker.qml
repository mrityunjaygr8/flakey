import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
  id: root

  property string page: "capture"
  property string captureTitle: "Region"
  property var captureCommand: ["screenshot"]
  property var captureModes: [
    { title: "Region", detail: "Select an area", args: ["screenshot"] },
    { title: "Window", detail: "Focused window", args: ["screenshot", "window"] },
    { title: "Focused output", detail: "Current monitor", args: ["screenshot", "full"] },
    { title: "All outputs", detail: "Combined image", args: ["screenshot", "all"] },
    { title: "DP-1", detail: "Primary monitor", args: ["screenshot", "output", "-o", "DP-1"] },
    { title: "DP-2", detail: "Second monitor", args: ["screenshot", "output", "-o", "DP-2"] },
  ]
  property var destinations: [
    { title: "File + clipboard", detail: "Save and copy", args: [] },
    { title: "File only", detail: "Save a copy", args: ["--no-clipboard"] },
    { title: "Clipboard only", detail: "Copy without saving", args: ["--no-file"] },
  ]

  function selectCapture(mode) {
    captureTitle = mode.title
    captureCommand = mode.args
    page = "destination"
    Qt.callLater(function() { destinationRepeater.itemAt(0).forceActiveFocus() })
  }

  // How long to wait after unmapping the overlay before starting the capture.
  // Mango's layer_rule disables this surface's close animation (see
  // modules/home-manager/mango.nix), so the surface is gone almost immediately;
  // this delay is just margin for the compositor to commit the unmap.
  property int unmapDelayMs: 250
  property var pendingCapture: null

  function runCapture(destinationArgs) {
    pendingCapture = captureCommand.concat(destinationArgs)
    // Hide the overlay first, then capture once it is off screen. Hiding also
    // returns keyboard focus to the previously focused window, which matters
    // for the "Focused window" capture mode.
    overlay.visible = false
    captureDelay.restart()
  }

  Timer {
    id: captureDelay
    interval: root.unmapDelayMs
    repeat: false
    onTriggered: {
      if (!root.pendingCapture) {
        return
      }
      Quickshell.execDetached(["@DMS_EXECUTABLE@"].concat(root.pendingCapture))
      root.pendingCapture = null
      Qt.quit()
    }
  }

  Shortcut {
    sequence: "Escape"
    onActivated: {
      if (root.page === "destination") {
        root.page = "capture"
        Qt.callLater(function() { captureRepeater.itemAt(0).forceActiveFocus() })
      } else {
        Qt.quit()
      }
    }
  }

  PanelWindow {
    id: overlay

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    // Named so Mango can target this surface with a layer_rule: the default
    // 800ms close animation would still be compositing the picker when the
    // screenshot fires, so that rule disables the close animation for us.
    WlrLayershell.namespace: "mango-screenshot-picker"

    Item {
      anchors.fill: parent

      Rectangle {
        anchors.fill: parent
        color: "#b8141520"

        MouseArea {
          anchors.fill: parent
          onClicked: Qt.quit()
        }
      }

      Rectangle {
        id: card

        width: Math.min(720, parent.width - 48)
        height: root.page === "capture" ? 410 : 310
        anchors.centerIn: parent
        color: "#20222c"
        radius: 22
        border.color: "#3b4050"
        border.width: 1

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 26
          spacing: 18

          RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 4

              Text {
                text: root.page === "capture" ? "Take a screenshot" : "Save screenshot"
                color: "#f4f1fa"
                font.pixelSize: 22
                font.weight: Font.DemiBold
              }

              Text {
                text: root.page === "capture" ? "Choose what to capture" : "Capture: " + root.captureTitle
                color: "#aaa7b8"
                font.pixelSize: 13
              }
            }

            Button {
              text: "✕"
              onClicked: Qt.quit()
              background: Rectangle {
                radius: 10
                color: parent.hovered ? "#393b49" : "transparent"
              }
              contentItem: Text {
                text: parent.text
                color: "#c9c6d5"
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
            }
          }

          GridLayout {
            visible: root.page === "capture"
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
              id: captureRepeater
              model: root.captureModes

              delegate: Button {
                id: captureButton
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.fillHeight: true
                focus: index === 0
                onClicked: root.selectCapture(modelData)

                background: Rectangle {
                  radius: 14
                  color: captureButton.down ? "#3c4050" : captureButton.hovered ? "#30333f" : "#282a35"
                  border.color: captureButton.activeFocus ? "#b1c8ee" : "#3b4050"
                  border.width: captureButton.activeFocus ? 2 : 1
                }

                contentItem: ColumnLayout {
                  spacing: 6

                  Text {
                    text: captureButton.modelData.title
                    color: "#f4f1fa"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                  }

                  Text {
                    text: captureButton.modelData.detail
                    color: "#aaa7b8"
                    font.pixelSize: 12
                  }
                }
              }
            }
          }

          GridLayout {
            visible: root.page === "destination"
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            columnSpacing: 10

            Repeater {
              id: destinationRepeater
              model: root.destinations

              delegate: Button {
                id: destinationButton
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                focus: modelData.title === "File + clipboard"
                onClicked: root.runCapture(modelData.args)

                background: Rectangle {
                  radius: 14
                  color: destinationButton.down ? "#3c4050" : destinationButton.hovered ? "#30333f" : "#282a35"
                  border.color: destinationButton.activeFocus ? "#b1c8ee" : "#3b4050"
                  border.width: destinationButton.activeFocus ? 2 : 1
                }

                contentItem: ColumnLayout {
                  spacing: 6

                  Text {
                    text: destinationButton.modelData.title
                    color: "#f4f1fa"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                  }

                  Text {
                    text: destinationButton.modelData.detail
                    color: "#aaa7b8"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true

            Button {
              visible: root.page === "destination"
              text: "‹  Back"
              onClicked: {
                root.page = "capture"
                Qt.callLater(function() { captureRepeater.itemAt(0).forceActiveFocus() })
              }
            }

            Item { Layout.fillWidth: true }

            Text {
              text: root.page === "capture" ? "Esc to close" : "Esc to go back"
              color: "#858293"
              font.pixelSize: 12
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }
  }
}
