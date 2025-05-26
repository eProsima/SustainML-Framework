// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Qt.labs.qmlmodels 1.0

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Rectangle {
    id: root
    anchors.fill: parent
    // width: 800
    // height: 400
    color: ScreenManager.night_mode ?  Settings.app_color_dark : Settings.app_color_light

    // Public signals
    signal component_signal(string viewType, string signal_kind, string id)

    // Property to decide the visibles columns
    property var visibleColumns: [0,1,2,3,4,5,6,7]
    property var minColumnWidths: [80, 160, 180, 150, 140, 160, 170, 185]
    property int sumMinColumnWidths: {
        var total = 0;
        for (var i = 0; i < minColumnWidths.length; i++) {
            total += minColumnWidths[i];
        }
        return total;
    }
    property var columnWidths: [80, 160, 180, 150, 140, 160, 170, 185]
    property var jsonList : []
    readonly property int fixedColumnWidth: 150
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __scroll_view_height: height
    readonly property int __scroll_view_content_height: 700
    readonly property int __header_height: 40
    readonly property int __data_height: __header_height * 1.25
    readonly property int __cell_padding: 10
    readonly property string __cell_background_color: "#e0e0e0"
    readonly property string __cell_background_nightmode_color: "#505050"

    TableModel {
        id: table_model
        TableModelColumn { display: "Iteration" }
        TableModelColumn { display: "Problem kind" }
        TableModelColumn { display: "Suggested model" }
        TableModelColumn { display: "Suggested hardware" }
        TableModelColumn { display: "Latency" }
        TableModelColumn { display: "Power consumption" }
        TableModelColumn { display: "Carbon intensity" }
        TableModelColumn { display: "Energy Consumption" }

        rows: []
    }

    Connections {
        target: sustainml_fragment_problem

        function onUpdate_iteration(comparison_interation_ids_list) {

            var newList = [];
            var newRows = [];

            for (var i = 0; i < comparison_interation_ids_list.length; i++) {
                var iterationId = comparison_interation_ids_list[i];
                var json = engine.request_specific_results(problem_id, iterationId);
                newList.push(json);

                function formatNumber(val) {
                    var num = Number(val);
                    // Usa notación científica si el valor es mayor o igual a 1e5 o menor que 1e-3 (pero distinto de 0)
                    if (Math.abs(num) >= 1e5 || (Math.abs(num) > 0 && Math.abs(num) < 1e-3))
                        return num.toExponential(4);
                    else
                        return num.toFixed(4);
                }
                newRows.push({
                    "Iteration": json.task_id.iteration_id,
                    "Problem kind": json.ML_MODEL_METADATA.metadata,
                    "Suggested model": json.ML_MODEL.model,
                    "Suggested hardware": json.HW_RESOURCES.hw_description,
                    "Latency": formatNumber(json.HW_RESOURCES.latency),
                    "Power consumption": formatNumber(json.HW_RESOURCES.power_consumption),
                    "Carbon intensity": formatNumber(json.CARBON_FOOTPRINT.carbon_intensity),
                    "Energy Consumption": formatNumber(json.CARBON_FOOTPRINT.energy_consumption)
                });
            }

            jsonList = newList;
            table_model.rows = newRows;
            general_table.forceLayout();
        }
    }

    property string currentState: "collapsed"
    state: currentState

    Rectangle {
        id: splitRow
        anchors.fill: parent

        SmlScrollView
        {
            id: scroll_view

            // anchors.fill: parent
            anchors.left: parent.left
            width: root.width
            height: root.__scroll_view_height
            content_width: general_header_table.contentWidth
            // content_height: general_header_table.height + general_table.height + 1
            layout: SmlScrollBar.ScrollBarLayout.Horizontal
            scrollbar_backgound_color: Settings.app_color_light
            scrollbar_backgound_nightmodel_color: Settings.app_color_dark
            interactive: false

            // Header
            Rectangle {
                id: headerRect
                anchors.top: parent.top
                anchors.left: parent.left
                width: scroll_view.width > general_header_table.contentWidth ? scroll_view.width : general_header_table.contentWidth
                height: __header_height
                color: ScreenManager.night_mode ? __cell_background_nightmode_color : __cell_background_color
                onWidthChanged: {
                    general_header_table.forceLayout(),
                    general_table.forceLayout();
                }

                TableView
                {
                    id: general_header_table
                    anchors{
                        top: parent.top
                        left: parent.left
                        bottom: parent.bottom
                    }

                    boundsBehavior: Flickable.StopAtBounds
                    columnWidthProvider: function (column) {
                        {
                            if (visibleColumns.indexOf(column) === -1)
                                return 0;
                            var idx = visibleColumns.indexOf(column);
                            var currentWidth = columnWidths[column];
                            if (idx === visibleColumns.length - 1 && scroll_view.width > sumMinColumnWidths) {
                                var sum = 0;
                                for (var i = 0; i < visibleColumns.length - 1; i++) {
                                    sum += columnWidths[visibleColumns[i]];
                                }
                                var total = scroll_view.width - sum;
                                if (total <= minColumnWidths[visibleColumns[visibleColumns.length - 1]]) {
                                    columnWidths[column] = minColumnWidths[column];
                                    var reduction = columnWidths[column];
                                    var idx = visibleColumns.length - 2;
                                    while (reduction > 0 && idx >= 0) {
                                        var colIndex = visibleColumns[idx];
                                        var available = columnWidths[colIndex] - minColumnWidths[colIndex];
                                        if (available >= reduction) {
                                            columnWidths[colIndex] -= reduction;
                                            reduction = 0;
                                        } else {
                                            columnWidths[colIndex] = minColumnWidths[colIndex];
                                            reduction -= available;
                                        }
                                        idx--;
                                    }
                                    return minColumnWidths[column];
                                }
                                columnWidths[visibleColumns[visibleColumns.length - 1]] = total;
                                return total;
                            }
                            return currentWidth;
                        }
                    }
                    width: contentItem.childrenRect.width + 1
                    contentWidth: contentItem.childrenRect.width + 1
                    // onWidthChanged: forceLayout()
                    // columnWidthProvider: getColumnWidth(column)

                    model: TableModel {
                        TableModelColumn { display: "Iteration" }
                        TableModelColumn { display: "Problem kind" }
                        TableModelColumn { display: "Suggested model" }
                        TableModelColumn { display: "Suggested hardware" }
                        TableModelColumn { display: "Latency" }
                        TableModelColumn { display: "Power consumption" }
                        TableModelColumn { display: "Carbon intensity" }
                        TableModelColumn { display: "Energy Consumption" }

                        rows: [
                            {"Iteration" : "Iteration",
                            "Problem kind" : "Problem",
                            "Suggested model" : "ML Model",
                            "Suggested hardware" : "Hardware",
                            "Latency" : "Latency [ms]",
                            "Power consumption" : "Power Consumption [W]",
                            "Carbon intensity" : "Carbon Intensity [gCO2/kW]",
                            "Energy Consumption" : "Energy Consumption [kWh]"}
                        ]
                    }

                    delegate: Rectangle
                    {
                        implicitWidth: width
                        implicitHeight: __header_height
                        color: "transparent"
                        // border.width: 1
                        SmlText
                        {
                            anchors.centerIn: parent
                            height: __header_height
                            text_kind: SmlText.TextKind.Header_3
                            text_value: model.display
                            padding: __cell_padding + 1
                            force_size: true
                        }

                        // Bottom horizontal border (dark tone)
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 0.5
                            color: "#666666"
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top - 0.5
                            height: 0.5
                            color: "#666666"
                        }

                        // Right vertical border (lighter tone)
                        Rectangle {
                            anchors.top: parent.top
                            anchors.topMargin: parent.height * 0.125
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.height * 0.125
                            anchors.right: parent.right
                            width: 0.5
                            color: "#AAAAAA"
                        }

                        // MouseArea to capture right-click and show a context menu
                        MouseArea {
                            id: contextMenuArea
                            enabled: model.display !== "Iteration" && model.display !== "Problem" && model.display !== "ML Model" && model.display !== "Hardware"
                            hoverEnabled: true
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                leftMargin: 5
                                rightMargin: 5
                            }
                            acceptedButtons: Qt.RightButton
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onEntered: {
                                if (enabled)
                                    parent.color = "#f0f0f0" // slightly changed background color
                            }
                            onExited: {
                                parent.color = "transparent"
                            }
                            onClicked: {
                                if (mouse.button === Qt.RightButton) {
                                    contextMenu.popup(mouse.x, mouse.y)
                                }
                            }
                        }

                        Menu {
                            id: contextMenu
                            MenuItem {
                                text: "Compare"
                                onTriggered: {
                                    console.log("Compare triggered");
                                    root.component_signal("iteration_view", "add_to_compare", model.display);
                                }
                            }
                        }

                        MouseArea {
                            id: resizeArea
                            z: 1
                            anchors {
                                right: parent.right
                                rightMargin: -5
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: 10
                            cursorShape: Qt.SizeHorCursor
                            // Only allow left-button presses in the resize area
                            acceptedButtons: Qt.LeftButton
                            property real initialGlobalX: 0
                            property real initialWidth: 0

                            onPressed: {
                                initialGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                initialWidth = columnWidths[index];
                            }
                            onPositionChanged: {
                                var currentGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                var delta = currentGlobalX - initialGlobalX;
                                var newWidth = Math.max(minColumnWidths[index], initialWidth + delta);
                                if (Math.abs(newWidth - columnWidths[index]) > 1) {
                                    columnWidths[index] = newWidth;
                                    general_header_table.forceLayout();
                                    general_table.forceLayout();
                                }
                            }
                        }
                    }
                }
            }

            // Data Table
            SmlScrollView {
                id: verticalScrollView
                anchors.top: headerRect.bottom
                anchors.left: headerRect.left
                width: headerRect.width
                height: root.height - headerRect.height
                contentHeight: general_table.height + 20
                layout: SmlScrollBar.ScrollBarLayout.Vertical
                scrollbar_backgound_color: Settings.app_color_light
                scrollbar_backgound_nightmodel_color: Settings.app_color_dark
                flickableDirection: Flickable.VerticalFlick

                Rectangle {
                    id: tableRect
                    width: headerRect.width
                    height: __data_height * table_model.rows.length
                    color: "transparent"
                    onWidthChanged: {
                        general_header_table.forceLayout(),
                        general_table.forceLayout();
                    }

                    TableView {
                        id: general_table
                        model: table_model
                        anchors{
                            top: parent.top
                            left: parent.left
                            bottom: parent.bottom
                        }
                        rowHeightProvider: function(row) { return root.__data_height }
                        columnWidthProvider: function (column) {
                            {
                                if (visibleColumns.indexOf(column) === -1)
                                    return 0;
                                var idx = visibleColumns.indexOf(column);
                                var currentWidth = columnWidths[column];
                                if (idx === visibleColumns.length - 1 && scroll_view.width > sumMinColumnWidths) {
                                    var sum = 0;
                                    for (var i = 0; i < visibleColumns.length - 1; i++) {
                                        sum += columnWidths[visibleColumns[i]];
                                    }
                                    var total = scroll_view.width - sum;
                                    if (total <= minColumnWidths[visibleColumns[visibleColumns.length - 1]]) {
                                        columnWidths[column] = minColumnWidths[column];
                                        var reduction = columnWidths[column];
                                        var idx = visibleColumns.length - 2;
                                        while (reduction > 0 && idx >= 0) {
                                            var colIndex = visibleColumns[idx];
                                            var available = columnWidths[colIndex] - minColumnWidths[colIndex];
                                            if (available >= reduction) {
                                                columnWidths[colIndex] -= reduction;
                                                reduction = 0;
                                            } else {
                                                columnWidths[colIndex] = minColumnWidths[colIndex];
                                                reduction -= available;
                                            }
                                            idx--;
                                        }
                                        return minColumnWidths[column];
                                    }
                                    columnWidths[visibleColumns[visibleColumns.length - 1]] = total;
                                    return total;
                                }
                                return currentWidth;
                            }
                        }
                        width: contentItem.childrenRect.width + 1
                        contentWidth: contentItem.childrenRect.width + 1

                        delegate: Rectangle {
                            color: "transparent"
                            height: root.__data_height
                            implicitHeight: root.__data_height
                            implicitWidth: width
                            property string iterationValue: model.display

                            SmlText {
                                id: value
                                width: parent.width
                                anchors.centerIn: parent
                                text_kind: SmlText.TextKind.Body
                                text_value: model.display
                                padding: __cell_padding
                                force_size: true
                                forced_size: 14
                                wrapMode: TextEdit.Wrap
                            }

                            // Bottom horizontal border (dark tone)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 0.5
                                color: "#666666"
                            }

                            // Right vertical border (lighter tone)
                            Rectangle {
                                anchors.top: parent.top
                                anchors.topMargin: parent.height * 0.125
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: parent.height * 0.125
                                anchors.right: parent.right
                                width: 0.5
                                color: "#AAAAAA"
                            }

                            // MouseArea to capture right-click and show a context menu
                            MouseArea {
                                id: contextMenuMoreData
                                enabled: column === 0 || column === 2
                                hoverEnabled: true
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: parent.left
                                    right: parent.right
                                    leftMargin: 5
                                    rightMargin: 5
                                }
                                acceptedButtons: Qt.RightButton
                                cursorShape: (column === 0 || column === 2) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: {
                                    if (enabled)
                                        parent.color = "#f0f0f0" // slightly changed background color
                                }
                                onExited: {
                                    parent.color = "transparent"
                                }
                                onClicked: {
                                    if (mouse.button === Qt.RightButton) {
                                        switch (column) {
                                            case 0:
                                                contextMenuData.popup(mouse.x, mouse.y);
                                                break;
                                            case 2:
                                                hfMenu.popup(mouse.x, mouse.y);
                                                break;
                                            default:
                                                break;
                                        }
                                    }
                                }
                            }

                            Menu {
                                id: contextMenuData
                                MenuItem {
                                    text: "More info"
                                    onTriggered: {
                                        console.log("More info triggered, iterationValue = " + iterationValue);
                                        infoPopup.iteration = iterationValue;
                                        infoPopup.open();
                                    }
                                }
                            }

                            Menu {
                                id: hfMenu
                                MenuItem {
                                    text: "More on HF"
                                    onTriggered: {
                                        console.log("Search model " + model.display + " on HF triggered");

                                        var modelName = model.display;
                                        if (modelName) {
                                            var searchUrl = "https://huggingface.co/" + modelName;
                                            Qt.openUrlExternally(searchUrl);
                                        } else {
                                            console.log("The name of the model is not available.");
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: resizeArea
                                z: 1
                                anchors {
                                    right: parent.right
                                    rightMargin: -5
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: 10
                                cursorShape: Qt.SizeHorCursor
                                // Only allow left-button presses in the resize area
                                acceptedButtons: Qt.LeftButton
                                property real initialGlobalX: 0
                                property real initialWidth: 0

                                onPressed: {
                                    initialGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                    initialWidth = columnWidths[column];
                                }
                                onPositionChanged: {
                                    var currentGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                    var delta = currentGlobalX - initialGlobalX;
                                    var newWidth = Math.max(minColumnWidths[column], initialWidth + delta);
                                    if (Math.abs(newWidth - columnWidths[column]) > 1) {
                                        columnWidths[column] = newWidth;
                                        general_header_table.forceLayout();
                                        general_table.forceLayout();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: sidePanel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: root.currentState === "collapsed" ? 0 : 200
            height: 450
            color: "#d0d0d0"
            opacity: 0.85
            border.color: "#a0a0a0"
            radius: 1

            Column {
                id: sideColumn
                visible: root.currentState === "expanded"
                opacity: 0.9
                property real offset: root.currentState === "expanded" ? 0 : 100

                spacing: 5
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                transform: Translate { x: sideColumn.offset }

                Behavior on offset {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

                Repeater {
                    model: [1,2,3,4,5,6,7]
                    delegate: Row {
                        spacing: 5
                        CheckBox {
                            id: columnCheckBox
                            checked: visibleColumns.indexOf(modelData) !== -1
                            scale: 0.7
                            onCheckedChanged: {
                                if (checked) {
                                    if (visibleColumns.indexOf(modelData) === -1) {
                                        visibleColumns = visibleColumns.concat([modelData]).sort(function(a, b) { return a - b; });
                                    }
                                } else {
                                    visibleColumns = visibleColumns.filter(function(item) { return item !== modelData; });
                                }
                                general_header_table.forceLayout();
                                general_table.forceLayout();
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                var headers = ["Problem", "ML Model", "Hardware", "Latency", "Power Consumption", "Carbon Intensity", "Energy Consumption"];
                                return headers[modelData - 1];
                            }
                        }
                    }
                }
            }
        }

        Button {
            id: toggleButton
            text: ""
            width: 10
            height: sidePanel.height
            background: Rectangle {
                color: Settings.app_color_green_1    // using app_color_green_1
                opacity: 1
                border.color: "#333333"
                border.width: 1
                radius: 4
            }
            anchors {
                right: sidePanel.left
                rightMargin: -2
                verticalCenter: sidePanel.verticalCenter
            }
            onClicked: {
                root.currentState = root.currentState === "collapsed" ? "expanded" : "collapsed";
            }
        }

    }

    states: [
        State {
            name: "collapsed"
            PropertyChanges {
                target: sidePanel; width: 0
            }
        },
        State {
            name: "expanded"
            PropertyChanges {
                target: sidePanel; width: 200
            }
        }
    ]

    transitions: Transition {
        NumberAnimation { properties: "width"; duration: 300 }
    }


    Popup {
        id: infoPopup
        modal: true
        focus: true
        x: -width
        y: 0
        width: 500
        height: parent.height
        background: Rectangle { color: "transparent" }
        property var iteration: ""

        Behavior on x {
            NumberAnimation { duration: 350; easing.type: Easing.OutQuad }
        }

        property var jsonData: (function() {
            for (var i = 0; i < root.jsonList.length; i++) {
                if (parseInt(root.jsonList[i].task_id.iteration_id) === parseInt(infoPopup.iteration)) {
                    return root.jsonList[i];
                }
            }
            return {};
        })()

        Rectangle {
            anchors.fill: parent
            color: "white"
            border.color: "#cccccc"

            Button {
                text: "X"
                anchors.top: parent.top
                anchors.right: parent.right
                width: 20
                height: 20
                onClicked: infoPopup.close()
            }

            SmlText {
                id: iterationTextHeader
                anchors {
                    top: parent.top
                    topMargin: Settings.spacing_small
                    horizontalCenter: parent.horizontalCenter
                }
                text_value: "Iteration " + infoPopup.iteration
                text_kind: SmlText.TextKind.Header_3
                font.bold: true
                font.pointSize: 13

            }

            SmlScrollView {
                // anchors.fill: parent
                anchors.top: iterationTextHeader.bottom
                anchors.topMargin: Settings.spacing_small
                anchors.left: parent.left
                anchors.right: parent.right
                width: parent.width
                height: parent.height - iterationTextHeader.height - Settings.spacing_small * 2
                content_height: columnContent.implicitHeight
                layout: SmlScrollBar.ScrollBarLayout.Vertical
                scrollbar_backgound_color: Settings.app_color_light
                scrollbar_backgound_nightmodel_color: Settings.app_color_dark

                Rectangle {
                    id: tableContent
                    width: parent.width
                    color: "transparent"
                    border.color: "transparent"

                    visible: Object.keys(infoPopup.jsonData).length > 0
                    anchors {
                        top: iterationTextHeader.bottom
                        topMargin: Settings.spacing_small
                        left: parent.left
                        leftMargin: Settings.spacing_normal
                    }

                    Column {
                        id: columnContent
                        spacing: Settings.spacing_small
                        width: parent.width

                        SmlText {
                            text_value: "Node ML_MODEL"
                            font.bold: true
                            font.pointSize: 13
                        }
                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.ML_MODEL, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node CARBON_FOOTPRINT"
                            font.bold: true
                            font.pointSize: 13
                        }
                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.CARBON_FOOTPRINT, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node APP_REQUIREMENTS"
                            font.bold: true
                            font.pointSize: 13
                        }

                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.APP_REQUIREMENTS, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node HW_CONSTRAINTS"
                            font.bold: true
                            font.pointSize: 13
                        }

                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.HW_CONSTRAINTS, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node HW_RESOURCES"
                            font.bold: true
                            font.pointSize: 13
                        }

                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.HW_RESOURCES, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node ML_MODEL_METADATA"
                            font.bold: true
                            font.pointSize: 13
                        }

                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.ML_MODEL_METADATA, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                x = 0;
            } else {
                x = -width;
            }
        }
    }
}
