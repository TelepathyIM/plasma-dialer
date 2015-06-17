/**
 *   Copyright 2014 Aaron Seigo <aseigo@kde.org>
 *   Copyright 2014 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.3
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.tpcaller 1.0

ApplicationWindow {
    id: root

//BEGIN PROPERTIES
    width: 600
    height: 800

    //keep track if we were visible when ringing
    property bool wasVisible
    //support a single provider for now
    property string providerId: ofonoWrapper.providerId
    //was the last call an incoming one?
    property bool isIncoming
//END PROPERTIES

//BEGIN SIGNAL HANDLERS
    Connections {
        target: dialerUtils
        onMissedCallsActionTriggered: {
            root.visible = true;
        }
    }

    onVisibleChanged: {
        //reset missed calls if the status is not STATUS_INCOMING when got visible
        if (visible && ofonoWrapper.status != "incoming") {
            dialerUtils.resetMissedCalls();
        }
    }
//END SIGNAL HANDLERS

//BEGIN FUNCTIONS
    function call(number) {
        tpCaller.dial(number);
        //ofonoWrapper.call(number);
    }

    function insertCallInHistory(number, duration, callType) {
        //DATABSE
        var db = LocalStorage.openDatabaseSync("PlasmaPhoneDialer", "1.0", "Call history of the Plasma Phone dialer", 1000000);

        db.transaction(
            function(tx) {
                var rs = tx.executeSql("INSERT INTO History VALUES(NULL, ?, datetime('now'), ?, ? )", [number, duration, callType]);

                var rs = tx.executeSql('SELECT * FROM History where id=?', [rs.insertId]);

                for(var i = 0; i < rs.rows.length; i++) {
                    var row = rs.rows.item(i);
                    row.date = Qt.formatDate(row.time, "yyyy-MM-dd");
                    row.originalIndex = historyModel.count;
                    historyModel.append(row);
                }
            }
        )
    }

    //index is historyModel row number, not db id and not sortmodel row number
    function removeCallFromHistory(index) {
        var item = historyModel.get(index);

        if (!item) {
            return;
        }

        var db = LocalStorage.openDatabaseSync("PlasmaPhoneDialer", "1.0", "Call history of the Plasma Phone dialer", 1000000);

        db.transaction(
            function(tx) {
                tx.executeSql("DELETE from History WHERE id=?", [item.id]);
            }
        )

        historyModel.remove(index);
    }

    function clearHistory() {
        var db = LocalStorage.openDatabaseSync("PlasmaPhoneDialer", "1.0", "Call history of the Plasma Phone dialer", 1000000);

        db.transaction(
            function(tx) {
                tx.executeSql("DELETE from History");
            }
        )

        historyModel.clear();
    }

//END FUNCTIONS

//BEGIN DATABASE
    Component.onCompleted: {
        //DATABSE
        var db = LocalStorage.openDatabaseSync("PlasmaPhoneDialer", "1.0", "Call history of the Plasma Phone dialer", 1000000);

        db.transaction(
            function(tx) {
                // Create the database if it doesn't already exist
                //callType: wether is incoming, outgoing, unanswered
                tx.executeSql('CREATE TABLE IF NOT EXISTS History(id INTEGER PRIMARY KEY AUTOINCREMENT, number TEXT, time DATETIME, duration INTEGER, callType INTEGER)');

                var rs = tx.executeSql('SELECT * FROM History');

                for(var i = 0; i < rs.rows.length; i++) {
                    var row = rs.rows.item(i);
                    row.date = Qt.formatDate(row.time, "yyyy-MM-dd");
                    row.originalIndex = historyModel.count;
                    historyModel.append(row);
                }
            }
        )
    }
//END DATABASE

//BEGIN MODELS
    ListModel {
        id: historyModel
    }

    OfonoWrapper {
        id: ofonoWrapper
    }

    TpCaller {
        id: tpCaller
    }

//END MODELS

//BEGIN UI
    PlasmaExtras.ConditionalLoader {
        anchors.fill: parent
        when: root.visible && !tpCaller.callInProgress
        source: Qt.resolvedUrl("Dialer/DialPage.qml")
        z: !tpCaller.callInProgress ? 2 : 0
        opacity: !tpCaller.callInProgress ? 1 : 0
        Behavior on opacity {
            OpacityAnimator {
                duration: units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    PlasmaExtras.ConditionalLoader {
        anchors.fill: parent
        when: tpCaller.callInProgress
        source: Qt.resolvedUrl("Call/CallPage.qml")
        opacity: tpCaller.callInProgress ? 1 : 0
        z: tpCaller.callInProgress ? 2 : 0
        Behavior on opacity {
            OpacityAnimator {
                duration: units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

//END UI
}
