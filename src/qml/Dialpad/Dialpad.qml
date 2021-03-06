/*
 *   Copyright 2014 Aaron Seigo <aseigo@kde.org>
 *   Copyright 2014 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.5 as Kirigami

GridLayout {
    id: pad
    columns: 3
    rowSpacing: 10
    columnSpacing: 10

    property string number

    DialerButton { id: one; text: "1"; onClicked: pad.number += text }
    DialerButton { text: "2"; sub: "ABC"; onClicked: pad.number += text }
    DialerButton { text: "3"; sub: "DEF"; onClicked: pad.number += text }

    DialerButton { text: "4"; sub: "GHI"; onClicked: pad.number += text }
    DialerButton { text: "5"; sub: "JKL"; onClicked: pad.number += text }
    DialerButton { text: "6"; sub: "MNO"; onClicked: pad.number += text }

    DialerButton { text: "7"; sub: "PQRS"; onClicked: pad.number += text }
    DialerButton { text: "8"; sub: "TUV"; onClicked: pad.number += text }
    DialerButton { text: "9"; sub: "WXYZ"; onClicked: pad.number += text }

    DialerButton { display: "＊"; text: "*"; special: true; onClicked: pad.number += text }
    DialerButton { text: "0"; subdisplay: "＋"; sub: "+"; onClicked: pad.number += text }
    DialerButton { display: "＃"; text: "#"; special: true; onClicked: pad.number += text }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    DialerIconButton {
        id: callButton
        Layout.fillWidth: true
        Layout.fillHeight: true

        enabled: status.text.length > 0
        opacity: enabled ? 1 : 0.5
        source: "call-start"
        size: Kirigami.Units.gridUnit * 3
        onPressed: call(status.text)
    }
    DialerIconButton {
        id: delButton
        Layout.fillWidth: true
        Layout.fillHeight: true

        enabled: status.text.length > 0
        opacity: enabled ? 1 : 0.5
        source: "edit-clear"
        size: Kirigami.Units.gridUnit * 2
        onPressed: {
            pad.number = pad.number.slice(0, -1)
        }
    }
}
