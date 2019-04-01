import QtQuick 2.11
import QtQuick.Layouts 1.11
import QtQuick.Dialogs 1.1
import QtQuick.Controls 1.2
import QtQuick.Window 2.1
import QtWebEngine 1.7
import QMLTermWidget 1.0
import Keymap 1.0

ApplicationWindow {
    id: browserWindow
    objectName: "browserWindow"
    property QtObject applicationRoot
    property Item currentWebView: tabs.count > 0 ? tabs.getTab(tabs.currentIndex).item: null
    property int previousVisibility: Window.Windowed
    signal submitKeymap(string keymap, int modifers, int key)
    signal submitEval(string input);
    signal handleCompletion(string input);

    visible: true

    width: 640
    height: 480

    Action {
        shortcut: "Alt+m"
        onTriggered: {
            if (webViewLayout.state == "Open" && terminal.focus) {
                return webViewLayout.state = "Close"
            }
            currentWebView.focus = false
            terminal.forceActiveFocus()
            webViewLayout.state = "Open"
        }
    }

    Action {
        shortcut: "Alt+x"
        onTriggered: {
            miniBuffer.focus = !miniBuffer.focus
        }
    }

    Action {
        shortcut: "Ctrl+g"
        onTriggered: {
            keyboardQuit()
        }
    }
    Action {
        shortcut: "Escape"
        onTriggered: {
            if (currentWebView.state == "FullScreen") {
                browserWindow.visibility = browserWindow.previousVisibility;
                fullScreenNotification.hide();
                currentWebView.triggerWebAction(WebEngineView.ExitFullScreen);
            }
        }
    }

    FullScreenNotification {
        id: fullScreenNotification
    }

    ColumnLayout {
        spacing: 0
        width: parent.width
        height: parent.height - miniBuffer.height
        id: webViewLayout
        TabView {
            id: tabs
            focus: true
            frameVisible: false
            tabsVisible: true
            Layout.preferredWidth: parent.width
            Layout.fillHeight: true
            function createEmptyTab(profile) {
                var tab = addTab("", webView);
                tab.active = true;
                tab.title = Qt.binding(function() { return currentWebView.focus });
                tab.item.profile = profile;
                return tab;
            }
            Component.onCompleted: createEmptyTab(defaultProfile)
            Keys.onPressed: {
                submitKeymap("webview-mode-map", event.modifiers, event.key)
            }
        }
        RowLayout {
            id: statusRow
            Button {
                id: testButton
                text: "debug"
                onClicked: {
                    killBuffer()
                }
                visible: false
            }
            Label {
                id: statusUrl
                color: "steelblue"
                text: currentWebView.title
                Layout.fillWidth: true
            }
            Text {
                color: "steelblue"
                text: "mini: %4 tabs: %1 terminal: %2 browser: %3".arg(tabs.focus).arg(terminal.focus).arg(currentWebView.focus).arg(miniBuffer.focus)
                Layout.alignment: Qt.AlignRight
            }
        }
        QMLTermWidget {
            id: terminal
            visible: true
            Layout.alignment: Qt.AlignBottom
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height / 4
            font.family: "Monospace"
            font.pointSize: 10
            colorScheme: "cool-retro-term"
            session: QMLTermSession{
                id: mainsession
                property string startSexp: "(progn (geiser-connect-local 'guile \"/tmp/nomad-socket\") (delete-other-windows))"
                initialWorkingDirectory: "/home/mrosset/src/nomad"
                shellProgram: "emacs"
                shellProgramArgs: ["-nw", "-Q", "-l", "/home/mrosset/src/nomad/init.el"]
                /* shellProgram: "nomad" */
                /* shellProgramArgs: ["-c", "--listen", "/tmp/nomad-devel"] */
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("click")
                    terminal.state = ""
                }
            }
            Component.onCompleted: mainsession.startShellProgram()
            QMLTermScrollbar {
                terminal: terminal
                width: 20
                Rectangle {
                    opacity: 0.4
                    anchors.margins: 5
                    radius: width * 0.5
                    anchors.fill: parent
                }
            }
        }
        Component.onCompleted: { console.log("state", state)}
        state: "Close"
        states: [
            State {
                name: "Open"
                PropertyChanges {
                    target: terminal
                    visible: true
                    focus: true
                }
                PropertyChanges {
                    target: tabs
                    focus: false
                    height: window.height
                }
                PropertyChanges {
                    target: currentWebView
                    focus: false
                }
                PropertyChanges{
                    target: miniBufferLayout
                    visible: false
                }
            },
            State {
                name: "Close"
                PropertyChanges {
                    target: terminal
                    visible: false
                    focus: false
                }
                PropertyChanges {
                    target: tabs
                    focus: true
                }
                PropertyChanges {
                    target: miniBuffer
                    visible: true
                }
                PropertyChanges {
                    target: miniOutput
                    visible: false
                }
            }
        ]
    }

    ColumnLayout {
        id: miniBufferLayout
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 0
        Rectangle {
            height: 1
            Layout.fillWidth: true
            color: "steelblue"
            visible: miniOutput.visible
        }
        Rectangle {
            id: miniBufferRowRect
            color: "white"
            height: miniBuffer.height
            Layout.fillWidth: true
            RowLayout {
                id: miniBufferRowLayout
                Label {
                    id: miniBufferLabel
                    text: "M-x"
                    visible: miniBuffer.focus
                }
                TextInput {
                    id: miniBuffer
                    objectName: "miniBuffer"
                    font.pointSize: 12
                    Layout.fillWidth: true
                    onAccepted: {
                        console.log(miniOutput.currentIndex)
                        if (miniOutput.currentIndex >= 0)  {
                            text = miniBufferModel.get(miniOutput.currentIndex).symbol
                        }
                        submitEval(text)
                        setMiniOutput("")
                        tabs.focus = true
                    }
                    onTextEdited: {
                        handleCompletion(miniBuffer.text)
                    }
                    onFocusChanged: {
                        miniBufferModel.clear()
                        miniOutputRect.visible = false
                        if(!miniBuffer.focus) {
                            miniBufferTimer.start()
                        }
                    }
                    Keys.onPressed: {
                        submitKeymap("minibuffer-mode-map", event.modifiers, event.key)
                    }
                    function selectUp() {
                        if (miniOutput.currentIndex == 0 ) {
                            return
                        }
                        miniOutput.currentIndex--
                    }
                    function selectDown() {
                        if (miniOutput.currentIndex == miniBufferModel.count - 1) {
                            return
                        }
                        miniOutput.currentIndex++
                    }
                }
                Timer {
                    id: miniBufferTimer
                    interval: 5000; running: false; repeat: false
                    onTriggered: miniBuffer.text = ""
                }

            }
        }
        Rectangle {
            height: 1
            Layout.fillWidth: true
            color: "steelblue"
            visible: miniOutput.visible
        }
        Rectangle {
            id: miniOutputRect
            color: "white"
            /* anchors.top: miniBufferRowRect.bottom */
            Layout.fillWidth: true
            Layout.fillHeight: true
            height: 200
            visible: false
            ListView {
                id: miniOutput
                anchors.fill: parent
                delegate: Text {
                    width: parent.width
                    text: symbol
                }
                highlight: Rectangle { color: "lightsteelblue"; }
                model: miniBufferModel
            }
            onVisibleChanged: {
                miniOutput.visible = visible
            }
        }
        ListModel {
            id: miniBufferModel
            ListElement { symbol: "" }
        }
    }

    // Components
    Keymap {
        id: keymap
    }
    Component {
        id: webView
        WebEngineView {
            id: webEngineView
            states: [
                State {
                    name: "FullScreen"
                    PropertyChanges {
                        target: miniBufferLayout
                        visible: false
                    }
                    PropertyChanges {
                        target: webViewLayout
                        height: window.height
                    }
                    PropertyChanges {
                        target: tabs
                        frameVisible: false
                        tabsVisible: false
                        Layout.preferredHeight: parent.height
                        height: window.height
                    }
                    PropertyChanges {
                        target: statusRow
                        visible: false
                    }
                    PropertyChanges {
                        target: terminal
                        visible: false
                    }
                    PropertyChanges {
                        target: miniBuffer
                        visible: false
                    }
                    PropertyChanges {
                        target: miniOutput
                        visible: false
                    }
                }
            ]
            onFullScreenRequested: function(request) {
                if (request.toggleOn) {
                    webEngineView.state = "FullScreen";
                    browserWindow.previousVisibility = browserWindow.visibility;
                    browserWindow.showFullScreen();
                    fullScreenNotification.show();
                } else {
                    webEngineView.state = "";
                    browserWindow.visibility = browserWindow.previousVisibility;
                    fullScreenNotification.hide();
                }
                request.accept();
            }
            onNewViewRequested: function(request) {
                if (!request.userInitiated)
                    print("Warning: Blocked a popup window.");
                else if (request.destination === WebEngineView.NewViewInTab) {
                    var tab = tabs.createEmptyTab(currentWebView.profile);
                    tabs.currentIndex = tabs.count - 1;
                    request.openIn(tab.item);
                } else if (request.destination === WebEngineView.NewViewInBackgroundTab) {
                    var backgroundTab = tabs.createEmptyTab(currentWebView.profile);
                    request.openIn(backgroundTab.item);
                } else if (request.destination === WebEngineView.NewViewInDialog) {
                    var dialog = applicationRoot.createDialog(currentWebView.profile);
                    request.openIn(dialog.currentWebView);
                } else {
                    var window = applicationRoot.createWindow(currentWebView.profile);
                    request.openIn(window.currentWebView);
                }
            }
        }
    }
    function scrollv(y) {
        var method = "window.scrollBy(0, %1)".arg(y)
        currentWebView.runJavaScript(method)

    }

    function makeBuffer(url) {
        tabs.createEmptyTab(defaultProfile);
        tabs.currentIndex++
        currentWebView.url = url;
    }

    function killBuffer() {
        if(tabs.count != 1) {
            tabs.removeTab(tabs.currentIndex)
        }
    }

    function nextBuffer() {
        tabs.currentIndex = tabs.currentIndex < tabs.count - 1 ? tabs.currentIndex + 1: 0
    }

    function goBack() {
        currentWebView.goBack();
    }

    function goForward() {
        currentWebView.goForward();
    }

    function totalBuffers( ) {
        return tabs.count
    }

    function getBuffer(index) {
        return tabs.getTab(index).item.url
    }

    function setMiniBuffer(output) {
        miniBuffer.text = output
    }

    function clearMiniOutput() {
        miniOutputRect.visible = false
        miniBufferModel.clear()
    }

    function setMiniOutput(output) {
        miniOutputRect.visible = true
        for (var i in output) {
            miniBufferModel.append({"symbol": output[i]})
        }
    }

    function switchToBuffer(index) {
        tabs.currentIndex = index
    }

    function keyboardQuit() {
        currentWebView.focus = false
        tabs.focus = true
    }

    function setUrl(uri) {
        currentWebView.url = uri
    }
}
