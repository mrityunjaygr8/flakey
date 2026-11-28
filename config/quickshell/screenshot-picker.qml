import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
  id: root

  property int selectedDestination: 0
  property int unmapDelayMs: 250
  property var pendingCapture: null

  // DMS writes its active Matugen palette here. Keep a local DMS-like fallback
  // for startup before the palette exists, or when the file cannot be parsed.
  property var palette: ({
    scrim: "#99000000",
    surface: "#202328",
    surfaceHigh: "#2a2f34",
    onSurface: "#e1e2e6",
    onSurfaceVariant: "#c0c7cf",
    primary: "#8dcefa",
    onPrimary: "#00344c",
    outline: "#40484e",
    selected: "#17658c",
    onSelected: "#ffffff"
  })

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

  function loadDmsPalette() {
    try {
      const document = JSON.parse(dmsPaletteFile.text())
      const mode = document.mode === "light" ? "light" : "dark"
      const colors = document.colors[mode]
      if (!colors) return

      palette = {
        scrim: mode === "dark" ? "#99000000" : "#66000000",
        surface: colors.surface_container || colors.surface || palette.surface,
        surfaceHigh: colors.surface_container_high || colors.surface_variant || palette.surfaceHigh,
        onSurface: colors.on_surface || palette.onSurface,
        onSurfaceVariant: colors.on_surface_variant || palette.onSurfaceVariant,
        primary: colors.primary || palette.primary,
        onPrimary: colors.on_primary || palette.onPrimary,
        outline: colors.outline_variant || colors.outline || palette.outline,
        selected: colors.primary_container || colors.primary || palette.selected,
        onSelected: colors.on_primary_container || colors.on_primary || palette.onSelected
      }
    } catch (error) {
      // Keep the fallback palette if the generated theme is absent or invalid.
    }
  }

  FileView {
    id: dmsPaletteFile
    path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation).toString()
      + "/DankMaterialShell/dms-colors.json"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.loadDmsPalette()
  }

  function runCapture(captureArgs) {
    pendingCapture = captureArgs.concat(destinations[selectedDestination].args)
    // Unmap before launching DMS so Mango has dropped the layer surface before
    // it captures. Mango's layer_rule removes this surface's close animation.
    overlay.visible = false
    captureDelay.restart()
  }

  Timer {
    id: captureDelay
    interval: root.unmapDelayMs
    repeat: false
    onTriggered: {
      if (!root.pendingCapture) return
      Quickshell.execDetached(["@DMS_EXECUTABLE@"].concat(root.pendingCapture))
      root.pendingCapture = null
      Qt.quit()
    }
  }

  Shortcut {
    sequence: "Escape"
    context: Qt.ApplicationShortcut
    onActivated: Qt.quit()
  }

  Component.onCompleted: Qt.callLater(function() {
    root.loadDmsPalette()
    captureRepeater.itemAt(0).forceActiveFocus()
  })

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
    WlrLayershell.namespace: "mango-screenshot-picker"

    Item {
      id: panelContents
      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          event.accepted = true
          Qt.quit()
        }
      }

      Rectangle {
        anchors.fill: parent
        color: root.palette.scrim

        MouseArea {
          anchors.fill: parent
          onClicked: Qt.quit()
        }
      }

      Rectangle {
        id: card

        width: Math.min(840, parent.width - 48)
        height: Math.min(560, parent.height - 48)
        anchors.centerIn: parent
        color: root.palette.surface
        radius: 20
        border.color: root.palette.outline
        border.width: 1

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 24
          spacing: 14

          RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 48

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 4

              Text {
                text: "Take a screenshot"
                color: root.palette.onSurface
                font.pixelSize: 22
                font.weight: Font.Bold
              }

              Text {
                text: root.selectedDestination === 0
                  ? "Choose a target to capture. File + clipboard is the default."
                  : "Destination: " + root.destinations[root.selectedDestination].title + " · Choose a target to capture."
                color: root.palette.onSurfaceVariant
                font.pixelSize: 13
                wrapMode: Text.WordWrap
              }
            }

          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: root.palette.outline
            opacity: 0.55
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: "SAVE TO"
              color: root.palette.onSurfaceVariant
              font.pixelSize: 11
              font.weight: Font.DemiBold
              font.letterSpacing: 1
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              Repeater {
                id: destinationRepeater
                model: root.destinations

                delegate: Button {
                  id: destinationButton
                  required property var modelData
                  required property int index
                  Layout.fillWidth: true
                  Layout.preferredHeight: 70
                  onClicked: root.selectedDestination = index

                  background: Rectangle {
                    radius: 14
                    color: destinationButton.index === root.selectedDestination
                      ? root.palette.selected
                      : destinationButton.hovered ? root.palette.surfaceHigh : "transparent"
                    border.color: destinationButton.index === root.selectedDestination
                      ? root.palette.primary : root.palette.outline
                    border.width: destinationButton.index === root.selectedDestination ? 2 : 1
                  }

                  contentItem: ColumnLayout {
                    spacing: 3
                    Text {
                      Layout.fillWidth: true
                      text: destinationButton.modelData.title
                      color: destinationButton.index === root.selectedDestination
                        ? root.palette.onSelected : root.palette.onSurface
                      font.pixelSize: 14
                      font.weight: Font.DemiBold
                      horizontalAlignment: Text.AlignHCenter
                      elide: Text.ElideRight
                    }
                    Text {
                      Layout.fillWidth: true
                      text: destinationButton.modelData.detail
                      color: destinationButton.index === root.selectedDestination
                        ? root.palette.onSelected : root.palette.onSurfaceVariant
                      opacity: 0.85
                      font.pixelSize: 11
                      font.weight: Font.Light
                      horizontalAlignment: Text.AlignHCenter
                      elide: Text.ElideRight
                    }
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true

            Text {
              text: "CAPTURE"
              color: root.palette.onSurfaceVariant
              font.pixelSize: 11
              font.weight: Font.DemiBold
              font.letterSpacing: 1
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "Select a target to start"
              color: root.palette.onSurfaceVariant
              font.pixelSize: 11
            }
          }

          GridLayout {
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
                onClicked: root.runCapture(modelData.args)

                background: Rectangle {
                  radius: 14
                  color: captureButton.down
                    ? root.palette.selected
                    : captureButton.hovered ? root.palette.surfaceHigh : "transparent"
                  border.color: captureButton.activeFocus
                    ? root.palette.primary : root.palette.outline
                  border.width: captureButton.activeFocus ? 2 : 1
                }

                contentItem: ColumnLayout {
                  spacing: 6

                  Text {
                    Layout.fillWidth: true
                    text: captureButton.modelData.title
                    color: root.palette.onSurface
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                  }

                  Text {
                    Layout.fillWidth: true
                    text: captureButton.modelData.detail
                    color: root.palette.onSurfaceVariant
                    font.pixelSize: 12
                    font.weight: Font.Light
                    horizontalAlignment: Text.AlignHCenter
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true

            Text {
              text: "Esc to close"
              color: root.palette.onSurfaceVariant
              font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "Default: File + clipboard"
              color: root.palette.onSurfaceVariant
              font.pixelSize: 12
            }
          }
        }

        Button {
          id: closeButton
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.topMargin: 16
          anchors.rightMargin: 16
          width: 40
          height: 40
          z: 1
          text: "✕"
          onClicked: Qt.quit()

          background: Rectangle {
            radius: 12
            color: closeButton.hovered ? root.palette.surfaceHigh : "transparent"
          }

          contentItem: Text {
            text: closeButton.text
            color: root.palette.onSurfaceVariant
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }
  }
}
