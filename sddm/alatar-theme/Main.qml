import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property string textColor: config.text_color || "#ffffff"
    property string accentColor: config.accent || "#5555ff"
    property string errorColor: config.error_color || "#ff5555"
    property string inputBg: config.input_background || "#1a1a1a"
    property string fontFamily: config.font || "Ancient"
    property int fontSize: config.font_size || 12

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginSucceeded() {}
        function onLoginFailed() {
            password.text = ""
            errorMessage.visible = true
        }
    }

    // Background image
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: config.background_image || ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true

        // Fallback to solid color if image fails
        Rectangle {
            anchors.fill: parent
            color: config.background || "#1a1a1a"
            z: -1
        }
    }

    // Dim overlay
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.4
    }

    // Main login container
    Item {
        id: mainContainer
        anchors.centerIn: parent
        width: 400
        height: 500

        // Welcome text
        Text {
            id: welcomeText
            anchors.horizontalCenter: parent.horizontalCenter
            y: 50
            text: "Alatar"
            color: textColor
            font.family: fontFamily
            font.pixelSize: fontSize * 3
            font.weight: Font.Medium
        }

        // Hostname
        Text {
            id: hostnameText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: welcomeText.bottom
            anchors.topMargin: 10
            text: sddm.hostName
            color: textColor
            font.family: fontFamily
            font.pixelSize: fontSize
            opacity: 0.7
        }

        // User selection
        Column {
            id: loginForm
            anchors.centerIn: parent
            spacing: 20
            width: parent.width - 40

            // Username field
            Column {
                width: parent.width
                spacing: 5

                Text {
                    text: "Username"
                    color: textColor
                    font.family: fontFamily
                    font.pixelSize: fontSize
                }

                // Custom ComboBox using QtQuick only
                Item {
                    id: username
                    width: parent.width
                    height: 40
                    property int currentIndex: userModel.lastIndex
                    property string currentText: userModel.data(userModel.index(currentIndex, 0), Qt.DisplayRole)
                    property bool expanded: false

                    onCurrentIndexChanged: {
                        currentText = userModel.data(userModel.index(currentIndex, 0), Qt.DisplayRole)
                    }

                    Rectangle {
                        id: usernameBackground
                        anchors.fill: parent
                        color: inputBg
                        border.color: accentColor
                        border.width: username.activeFocus ? 2 : 1
                        radius: 4

                        Text {
                            id: usernameText
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: username.currentText
                            font.family: fontFamily
                            font.pixelSize: fontSize
                            color: textColor
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: username.expanded ? "▲" : "▼"
                            font.family: fontFamily
                            font.pixelSize: fontSize
                            color: textColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: username.expanded = !username.expanded
                        }
                    }

                    Rectangle {
                        id: usernameDropdown
                        anchors.top: usernameBackground.bottom
                        anchors.topMargin: 2
                        width: parent.width
                        height: visible ? Math.min(userModel.count * 40, 200) : 0
                        color: inputBg
                        border.color: accentColor
                        border.width: 1
                        radius: 4
                        visible: username.expanded
                        z: 100

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 2
                            model: userModel
                            clip: true

                            delegate: Rectangle {
                                width: usernameDropdown.width - 4
                                height: 40
                                color: mouseArea.containsMouse ? Qt.lighter(inputBg, 1.2) : "transparent"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: model.name
                                    font.family: fontFamily
                                    font.pixelSize: fontSize
                                    color: textColor
                                }

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        username.currentIndex = index
                                        username.expanded = false
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Password field
            Column {
                width: parent.width
                spacing: 5

                Text {
                    text: "Password"
                    color: textColor
                    font.family: fontFamily
                    font.pixelSize: fontSize
                }

                // Custom TextField using QtQuick only
                Rectangle {
                    id: passwordBackground
                    width: parent.width
                    height: 40
                    color: inputBg
                    border.color: accentColor
                    border.width: password.activeFocus ? 2 : 1
                    radius: 4

                    TextInput {
                        id: password
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        font.family: fontFamily
                        font.pixelSize: fontSize
                        color: textColor

                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                sddm.login(username.currentText, password.text, sessionCombo.currentIndex)
                            }
                        }

                        onActiveFocusChanged: {
                            if (activeFocus) {
                                errorMessage.visible = false
                            }
                        }
                    }
                }
            }

            // Error message
            Text {
                id: errorMessage
                width: parent.width
                text: "Login failed. Please try again."
                color: errorColor
                font.family: fontFamily
                font.pixelSize: fontSize
                visible: false
                wrapMode: Text.WordWrap
            }

            // Login button
            Rectangle {
                id: loginButton
                width: parent.width
                height: 40
                color: loginMouseArea.pressed ? Qt.darker(accentColor, 1.2) : accentColor
                border.color: accentColor
                border.width: 2
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "Login"
                    font.family: fontFamily
                    font.pixelSize: fontSize
                    color: textColor
                }

                MouseArea {
                    id: loginMouseArea
                    anchors.fill: parent
                    onClicked: {
                        sddm.login(username.currentText, password.text, sessionCombo.currentIndex)
                    }
                }
            }
        }

        // Session selector
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            spacing: 10

            Text {
                text: "Session:"
                color: textColor
                font.family: fontFamily
                font.pixelSize: fontSize
                anchors.verticalCenter: parent.verticalCenter
            }

            // Custom ComboBox using QtQuick only
            Item {
                id: sessionCombo
                width: 180
                height: 35
                property int currentIndex: sessionModel.lastIndex
                property string currentText: sessionModel.data(sessionModel.index(currentIndex, 0), Qt.DisplayRole)
                property bool expanded: false

                onCurrentIndexChanged: {
                    currentText = sessionModel.data(sessionModel.index(currentIndex, 0), Qt.DisplayRole)
                }

                Rectangle {
                    id: sessionBackground
                    anchors.fill: parent
                    color: inputBg
                    border.color: config.session_color || accentColor
                    border.width: 1
                    radius: 4

                    Text {
                        id: sessionText
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: sessionCombo.currentText
                        font.family: fontFamily
                        font.pixelSize: fontSize
                        color: textColor
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: sessionCombo.expanded ? "▲" : "▼"
                        font.family: fontFamily
                        font.pixelSize: fontSize
                        color: textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: sessionCombo.expanded = !sessionCombo.expanded
                    }
                }

                Rectangle {
                    id: sessionDropdown
                    anchors.top: sessionBackground.bottom
                    anchors.topMargin: 2
                    width: parent.width
                    height: visible ? Math.min(sessionModel.count * 35, 200) : 0
                    color: inputBg
                    border.color: config.session_color || accentColor
                    border.width: 1
                    radius: 4
                    visible: sessionCombo.expanded
                    z: 100

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 2
                        model: sessionModel
                        clip: true

                        delegate: Rectangle {
                            width: sessionDropdown.width - 4
                            height: 35
                            color: sessionMouseArea.containsMouse ? Qt.lighter(inputBg, 1.2) : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name
                                font.family: fontFamily
                                font.pixelSize: fontSize
                                color: textColor
                            }

                            MouseArea {
                                id: sessionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    sessionCombo.currentIndex = index
                                    sessionCombo.expanded = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Power/Reboot buttons in bottom right
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 10

        Rectangle {
            id: rebootButton
            width: 100
            height: 35
            color: rebootMouseArea.pressed ? Qt.rgba(1, 0.4, 0, 0.5) : Qt.rgba(1, 0.5, 0, 0.3)
            border.color: "#ff8800"
            border.width: 1
            radius: 4

            Text {
                anchors.centerIn: parent
                text: "Reboot"
                font.family: fontFamily
                font.pixelSize: fontSize
                color: textColor
            }

            MouseArea {
                id: rebootMouseArea
                anchors.fill: parent
                onClicked: sddm.reboot()
            }
        }

        Rectangle {
            id: shutdownButton
            width: 100
            height: 35
            color: shutdownMouseArea.pressed ? Qt.rgba(1, 0, 0, 0.5) : Qt.rgba(1, 0, 0, 0.3)
            border.color: "#ff0000"
            border.width: 1
            radius: 4

            Text {
                anchors.centerIn: parent
                text: "Shutdown"
                font.family: fontFamily
                font.pixelSize: fontSize
                color: textColor
            }

            MouseArea {
                id: shutdownMouseArea
                anchors.fill: parent
                onClicked: sddm.powerOff()
            }
        }
    }

    // Clock in top right
    Text {
        id: clock
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        color: textColor
        font.family: fontFamily
        font.pixelSize: fontSize * 2

        function updateTime() {
            text = Qt.formatDateTime(new Date(), "hh:mm")
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.updateTime()
        }

        Component.onCompleted: updateTime()
    }

    Component.onCompleted: {
        password.forceActiveFocus()

        // Set Sway as default session if available
        for (var i = 0; i < sessionModel.rowCount(); i++) {
            if (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole).toLowerCase() === "sway") {
                sessionCombo.currentIndex = i
                break
            }
        }
    }
}
