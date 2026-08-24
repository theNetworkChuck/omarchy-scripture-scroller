import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Passages.js" as PassageData

BarWidget {
  id: root
  moduleName: "networkchuck.scripture-scroller"

  property var order: []
  property int orderIndex: -1
  property var currentPassage: null
  property bool hovered: false
  property bool popupOpen: false

  readonly property int rotationIntervalSec: clampedInteger("rotationIntervalSec", 30, 10, 300)
  readonly property int maxLabelWidth: clampedInteger("maxWidth", 420, 200, 800)
  readonly property int scrollSpeed: clampedInteger("scrollSpeed", 45, 20, 120)
  readonly property bool pauseOnHover: Boolean(setting("pauseOnHover", true))
  readonly property bool interactionPaused: popupOpen || (pauseOnHover && hovered)
  readonly property string displayText: currentPassage
    ? currentPassage.text + "  —  " + currentPassage.reference + " · BSB"
    : "Scripture Scroller"
  readonly property real travelDistance: tickerClip.width + tickerText.implicitWidth
  readonly property int naturalMarqueeDuration: Math.round(travelDistance / scrollSpeed * 1000)
  readonly property int marqueeDuration: Math.max(1000, Math.min(naturalMarqueeDuration, rotationIntervalSec * 900))

  implicitWidth: vertical ? barSize : maxLabelWidth + Style.space(16)
  implicitHeight: barSize

  function clampedInteger(key, fallback, minimum, maximum) {
    var value = Math.round(Number(setting(key, fallback)))
    if (!isFinite(value)) value = fallback
    return Math.max(minimum, Math.min(maximum, value))
  }

  function shuffledIndexes(previousPassageIndex) {
    var indexes = []
    for (var i = 0; i < PassageData.passages.length; i++) indexes.push(i)
    for (var cursor = indexes.length - 1; cursor > 0; cursor--) {
      var swapWith = Math.floor(Math.random() * (cursor + 1))
      var held = indexes[cursor]
      indexes[cursor] = indexes[swapWith]
      indexes[swapWith] = held
    }
    if (indexes.length > 1 && indexes[0] === previousPassageIndex) {
      var first = indexes[0]
      indexes[0] = indexes[1]
      indexes[1] = first
    }
    return indexes
  }

  function advance() {
    var previousPassageIndex = orderIndex >= 0 && orderIndex < order.length
      ? order[orderIndex]
      : -1
    if (order.length !== PassageData.passages.length || orderIndex >= order.length - 1) {
      order = shuffledIndexes(previousPassageIndex)
      orderIndex = -1
    }
    orderIndex += 1
    currentPassage = PassageData.passages[order[orderIndex]]
    rotationTimer.restart()
  }

  function previous() {
    if (orderIndex <= 0) return
    orderIndex -= 1
    currentPassage = PassageData.passages[order[orderIndex]]
    rotationTimer.restart()
  }

  function close() {
    popupOpen = false
  }

  function togglePopup() {
    if (!currentPassage) return
    if (bar) bar.hideTooltip(root)
    popupOpen = !popupOpen
  }

  function restartMarquee() {
    marquee.stop()
    tickerText.x = tickerClip.width
    if (!vertical && !interactionPaused && currentPassage) {
      Qt.callLater(function() {
        if (!root.vertical && !root.interactionPaused && root.currentPassage) marquee.start()
      })
    }
  }

  onCurrentPassageChanged: restartMarquee()
  onVerticalChanged: restartMarquee()
  onMaxLabelWidthChanged: restartMarquee()
  onScrollSpeedChanged: restartMarquee()
  onInteractionPausedChanged: {
    if (interactionPaused) marquee.stop()
    else restartMarquee()
  }

  Component.onCompleted: advance()

  Timer {
    id: rotationTimer
    interval: root.rotationIntervalSec * 1000
    repeat: true
    running: root.currentPassage !== null && !root.interactionPaused
    onTriggered: root.advance()
  }

  Item {
    id: tickerClip
    visible: !root.vertical
    anchors.fill: parent
    anchors.leftMargin: Style.space(8)
    anchors.rightMargin: Style.space(8)
    clip: true

    Text {
      id: tickerText
      anchors.verticalCenter: parent.verticalCenter
      text: root.displayText
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }
  }

  Text {
    visible: root.vertical
    anchors.centerIn: parent
    text: "󰂺"
    color: root.bar ? root.bar.barForeground : Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    renderType: Text.NativeRendering
  }

  NumberAnimation {
    id: marquee
    target: tickerText
    property: "x"
    from: tickerClip.width
    to: -tickerText.implicitWidth
    duration: root.marqueeDuration
    loops: Animation.Infinite
    easing.type: Easing.Linear
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      root.hovered = true
      if (root.bar) {
        root.bar.showTooltip(root, root.displayText + "\nLeft-click: show passage · Right-click: next · Wheel: previous/next")
      }
    }
    onExited: {
      root.hovered = false
      if (root.bar) root.bar.hideTooltip(root)
    }
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) root.advance()
      else root.togglePopup()
    }
    onWheel: function(wheel) {
      if (wheel.angleDelta.y > 0) root.previous()
      else if (wheel.angleDelta.y < 0) root.advance()
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(420))
    contentHeight: popup.fittedContentHeight(passageColumn.implicitHeight)

    Column {
      id: passageColumn
      anchors.fill: parent
      spacing: Style.space(10)

      Text {
        width: parent.width
        text: root.currentPassage ? root.currentPassage.reference : "Scripture"
        color: Color.popups.text
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.subtitle
        font.bold: true
        renderType: Text.NativeRendering
      }

      Text {
        width: parent.width
        text: root.currentPassage ? root.currentPassage.text : ""
        color: Color.popups.text
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
        renderType: Text.NativeRendering
      }

      Text {
        width: parent.width
        text: "Berean Standard Bible (BSB)"
        color: Qt.darker(Color.popups.text, 1.4)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        renderType: Text.NativeRendering
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(8)

        Button {
          text: "Previous"
          iconText: "󰒮"
          foreground: Color.popups.text
          bordered: true
          enabled: root.orderIndex > 0
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.previous()
        }

        Button {
          text: "Next"
          iconText: "󰒭"
          foreground: Color.popups.text
          bordered: true
          enabled: root.currentPassage !== null
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.advance()
        }
      }
    }
  }
}
