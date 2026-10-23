// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls 1.4 as C1
import QtQuick.Controls.Styles 1.4 as C1Styles

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0
import eProsima.SustainML.Tree 1.0
import eProsima.SustainML.Theme 1.0

// Component imports
import "../components"

Rectangle {
    id: root
    anchors.fill: parent

    // Public properties
    required property int problem_id
    required property int stack_id

    // width: 800
    // height: 400
    color: Theme.surface

    // Public signals
    signal component_signal(string viewType, string signal_kind, string id)

    // Property to decide the visibles columns
    property var visibleColumns: [0,1,2,3,4,5,6,7,8,9]
    property var minColumnWidths: [84, 140, 170, 130, 120, 130, 130, 130, 130, 130]
    property int sumMinColumnWidths: {
        var total = 0;
        for (var i = 0; i < minColumnWidths.length; i++) {
            total += minColumnWidths[i];
        }
        return total;
    }
    property var columnWidths: [84, 140, 170, 130, 120, 130, 130, 130, 130, 130]

    // Width of both tables, from the visible columns' widths. Set explicitly by
    // relayout_tables() rather than bound to the tables' own contentItem.childrenRect:
    // that binding made each table's width depend on its own laid-out cells, so every
    // relayout (e.g. hiding a column) changed the width it was computed from, a binding loop.
    property real __tables_width: __visible_columns_width() + 1

    // Width shown for a column: 0 when hidden, else its own width, except that the last
    // visible column also takes the room left when the visible columns together are
    // narrower than the view (they then fill it). Pure: it never changes columnWidths, so
    // resizing one column never moves the others.
    function __column_width(column) {
        if (visibleColumns.indexOf(column) === -1)
            return 0
        if (column === visibleColumns[visibleColumns.length - 1]) {
            var room = scroll_view.width - 1 - __visible_columns_width()
            if (room > 0)
                return columnWidths[column] + room
        }
        return columnWidths[column]
    }

    function __visible_columns_width() {
        var w = 0
        for (var i = 0; i < visibleColumns.length; i++)
            w += columnWidths[visibleColumns[i]]
        return w
    }

    // Relayout both tables, then size them
    function relayout_tables() {
        general_header_table.forceLayout()
        general_table.forceLayout()
        __tables_width = Math.max(__visible_columns_width(), scroll_view.width - 1) + 1
    }
    // Share the spare width of the view equally among the visible columns, so no column takes
    // all of it. Only on resizes of the view and changes of the visible columns: a column the
    // user resized keeps its width until then.
    function __fit_columns() {
        var flexible = 0
        for (var i = 0; i < visibleColumns.length; i++)
            flexible += minColumnWidths[visibleColumns[i]]
        var extra = scroll_view.width - flexible - 1
        if (extra <= 0 || flexible <= 0) return
        var share = Math.floor(extra / visibleColumns.length)
        for (var j = 0; j < visibleColumns.length; j++) {
            var c = visibleColumns[j]
            columnWidths[c] = minColumnWidths[c] + share
        }
    }

    property var jsonList : []
    readonly property int fixedColumnWidth: 150
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __scroll_view_height: height
    readonly property int __scroll_view_content_height: 700
    readonly property int __header_height: 48
    readonly property int __data_height: 48
    readonly property int __cell_padding: Theme.space3
    readonly property color __cell_background_color: Theme.cardHeader
    readonly property color __cell_background_nightmode_color: Theme.cardHeader

    TableModel {
        id: table_model
        TableModelColumn { display: "Iteration" }
        TableModelColumn { display: "Problem kind" }
        TableModelColumn { display: "Suggested model" }
        TableModelColumn { display: "Suggested hardware" }
        TableModelColumn { display: "Latency" }
        TableModelColumn { display: "Power consumption" }
        TableModelColumn { display: "Carbon footprint"}
        TableModelColumn { display: "Carbon intensity" }
        TableModelColumn { display: "Energy Consumption" }
        TableModelColumn { display: "Memory footprint" }

        rows: []
    }

    Connections {
        target: sustainml_fragment_problem

        function onUpdate_iteration(comparison_interation_ids_list) {
            // problem_id -1 is the "New Tab" placeholder (no real problem behind it) -
            // requesting results for it crashes the backend (uint32_t can't hold -1).
            if (problem_id < 0) return;

            comparison_interation_ids_list.sort(function(a, b) { return a - b; });

            var newList = [];
            var newRows = [];

            for (var i = 0; i < comparison_interation_ids_list.length; i++)
            {
                var iterationId = comparison_interation_ids_list[i];
                var json = engine.request_specific_results(problem_id, iterationId);
                newList.push(json);

                function formatNumber(val)
                {
                    var num = Number(val);
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
                    // the nodes exchange the latency in hours: shown in seconds
                    "Latency": formatNumber(json.HW_RESOURCES.latency * 3600),
                    "Power consumption": formatNumber(json.HW_RESOURCES.power_consumption),
                    "Carbon footprint": formatNumber(json.CARBON_FOOTPRINT.carbon_footprint),
                    "Carbon intensity": formatNumber(json.CARBON_FOOTPRINT.carbon_intensity),
                    "Energy Consumption": formatNumber(json.CARBON_FOOTPRINT.energy_consumption),
                    // 0 means unknown: saved before the memory was measured, or the model failed to load
                    "Memory footprint": Number(json.HW_RESOURCES.memory_footprint_of_ml_model) > 0 ?
                                        Number(json.HW_RESOURCES.memory_footprint_of_ml_model).toFixed(2) : ""
                });
            }

            jsonList = newList;
            table_model.rows = newRows;
            root.relayout_tables();
        }
    }

    property string currentState: "collapsed"
    state: currentState

    Rectangle {
        id: splitRow
        anchors.fill: parent
        color: Theme.surface

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
            interactive: false
            onWidthChanged: root.__fit_columns()

            // Header
            Rectangle {
                id: headerRect
                anchors.top: parent.top
                anchors.left: parent.left
                width: scroll_view.width > general_header_table.contentWidth ? scroll_view.width : general_header_table.contentWidth
                height: __header_height
                color: ScreenManager.night_mode ? __cell_background_nightmode_color : __cell_background_color
                // Deferred: forceLayout() re-triggers columnWidthProvider, which changes
                // general_header_table.contentWidth - a synchronous call here would run
                // that recompute while this very "width" binding (it reads that same
                // contentWidth) is still being resolved, which is what Qt's binding-loop
                // detector was flagging. Qt.callLater breaks the reentrant chain.
                onWidthChanged: {
                    Qt.callLater(function() {
                        root.relayout_tables();
                    })
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
                    columnWidthProvider: function (column) { return root.__column_width(column) }
                    width: root.__tables_width
                    contentWidth: root.__tables_width
                    // onWidthChanged: forceLayout()
                    // columnWidthProvider: getColumnWidth(column)

                    model: TableModel {
                        TableModelColumn { display: "Iteration" }
                        TableModelColumn { display: "Problem kind" }
                        TableModelColumn { display: "Suggested model" }
                        TableModelColumn { display: "Suggested hardware" }
                        TableModelColumn { display: "Latency" }
                        TableModelColumn { display: "Power consumption" }
                        TableModelColumn { display: "Carbon footprint" }
                        TableModelColumn { display: "Carbon intensity" }
                        TableModelColumn { display: "Energy Consumption" }
                        TableModelColumn { display: "Memory footprint" }

                        rows: [
                            {"Iteration" : "Iteration",
                            "Problem kind" : "Problem",
                            "Suggested model" : "ML Model",
                            "Suggested hardware" : "Hardware",
                            "Latency" : "Latency [s]",
                            "Power consumption" : "Power Consumption [W]",
                            "Carbon footprint" : "Carbon Footprint [gCO2e]",
                            "Carbon intensity" : "Carbon Intensity [gCO2/kW]",
                            "Energy Consumption" : "Energy Consumption [kWh]",
                            "Memory footprint" : "Memory Footprint [MB]"}
                        ]
                    }

                    delegate: Rectangle
                    {
                        implicitWidth: width
                        implicitHeight: __header_height
                        color: "transparent"
                        // border.width: 1
                        Text
                        {
                            anchors.fill: parent
                            leftPadding: __cell_padding
                            rightPadding: Theme.space2
                            verticalAlignment: Text.AlignVCenter
                            text: model.display
                            textFormat: Text.PlainText
                            font.family: Theme.uiFontFamily
                            font.pixelSize: Theme.fontSizeMeta
                            font.weight: Font.DemiBold
                            color: Theme.textSecondary
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        // Bottom border
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Theme.borderStrong
                        }

                        // Column separator (also where the column is resized), not after the last visible column
                        Rectangle {
                            visible: index !== visibleColumns[visibleColumns.length - 1]
                            anchors.top: parent.top
                            anchors.topMargin: Theme.space3
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Theme.space3
                            anchors.right: parent.right
                            width: 1
                            color: Theme.border
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
                                    parent.color = Theme.accentSubtle // slightly changed background color
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

                        SmlMenu {
                            id: contextMenu
                            SmlMenuItem {
                                icon_name: "scale"
                                text: "Compare"
                                onTriggered: {
                                    root.component_signal("iteration_view", "add_to_compare", model.display);
                                }
                            }
                            SmlMenuItem {
                                icon_name: "info"
                                text: "More info"
                                onTriggered: {
                                    metricInfoPopup.metricName = model.display
                                    metricInfoPopup.open()
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
                                initialWidth = root.__column_width(index);
                            }
                            onPositionChanged: {
                                var currentGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                var delta = currentGlobalX - initialGlobalX;
                                var newWidth = Math.max(minColumnWidths[index], initialWidth + delta);
                                if (Math.abs(newWidth - columnWidths[index]) > 1) {
                                    columnWidths[index] = newWidth;
                                    root.relayout_tables();
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
                contentHeight: general_table.contentHeight + 20
                layout: SmlScrollBar.ScrollBarLayout.Vertical
                flickableDirection: Flickable.VerticalFlick

                Rectangle {
                    id: tableRect
                    width: headerRect.width
                    height: general_table.contentHeight
                    color: "transparent"
                    // Deferred for the same reason as headerRect's onWidthChanged above -
                    // this width mirrors headerRect.width, so it fires in the same instant.
                    onWidthChanged: {
                        Qt.callLater(function() {
                            root.relayout_tables();
                        })
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
                        columnWidthProvider: function (column) { return root.__column_width(column) }
                        width: root.__tables_width
                        contentWidth: root.__tables_width

                        delegate: Rectangle {
                            color: "transparent"
                            height: general_table.rowHeightProvider(row)
                            implicitHeight: general_table.rowHeightProvider(row)
                            implicitWidth: width
                            property string iterationValue: model.display

                            SmlText {
                                id: value
                                visible: column !== 2
                                width: parent.width
                                anchors.centerIn: parent
                                text_kind: SmlText.TextKind.Body
                                text_value: model.display
                                leftPadding: __cell_padding
                                rightPadding: Theme.space2
                                font.family: column >= 4 ? Theme.monoFontFamily : Theme.uiFontFamily
                                wrapMode: Text.WordWrap
                            }

                            // Column 2 ("Suggested model"): max 2 lines + ellipsis
                            Item {
                                id: mlModelCell
                                visible: column === 2
                                anchors.fill: parent
                                clip: true

                                Text {
                                    anchors.fill: parent
                                    text: model.display

                                    wrapMode: Text.WrapAnywhere      // Breaks also on _ / etc.
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    clip: true

                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter

                                    leftPadding: __cell_padding
                                    rightPadding: __cell_padding + 10
                                    topPadding: 4
                                    bottomPadding: 4

                                    font.family: Theme.uiFontFamily
                                    font.pixelSize: Theme.fontSizeBody
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }
                            }

                            // Row divider
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Theme.border
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
                                        parent.color = Theme.accentSubtle // slightly changed background color
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

                            SmlMenu {
                                id: contextMenuData
                                SmlMenuItem {
                                    icon_name: "info"
                                    text: "More info"
                                    onTriggered: {
                                        infoPopup.iteration = iterationValue;
                                        infoPopup.open();
                                    }
                                }
                            }

                            SmlMenu {
                                id: hfMenu
                                SmlMenuItem {
                                    icon_name: "external"
                                    text: "More on HF"
                                    onTriggered: {
                                        var modelName = model.display;
                                        if (modelName) {
                                            var searchUrl = "https://huggingface.co/" + modelName;
                                            Qt.openUrlExternally(searchUrl);
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
                                    initialWidth = root.__column_width(column);
                                }
                                onPositionChanged: {
                                    var currentGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                    var delta = currentGlobalX - initialGlobalX;
                                    var newWidth = Math.max(minColumnWidths[column], initialWidth + delta);
                                    if (Math.abs(newWidth - columnWidths[column]) > 1) {
                                        columnWidths[column] = newWidth;
                                        root.relayout_tables();
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
            width: root.currentState === "collapsed" ? 0 : 220
            height: sideColumn.implicitHeight + 2 * Theme.space4
            color: Theme.overlay
            border.color: Theme.borderStrong
            radius: Theme.radiusMd

            Column {
                id: sideColumn
                visible: root.currentState === "expanded"
                opacity: 0.9
                property real offset: root.currentState === "expanded" ? 0 : 100

                spacing: Theme.space3
                anchors {
                    left: parent.left
                    leftMargin: Theme.space4
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "VISIBLE COLUMNS"
                    font.family: Theme.uiFontFamily
                    font.pixelSize: Theme.fontSizeMicro
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                    color: Theme.textMuted
                    bottomPadding: Theme.space1
                }

                transform: Translate { x: sideColumn.offset }

                Behavior on offset {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

                Repeater {
                    model: [1,2,3,4,5,6,7,8,9]
                    delegate: Row {
                        spacing: Theme.space2
                        SmlCheckBox {
                            id: columnCheckBox
                            checked: visibleColumns.indexOf(modelData) !== -1
                            onCheckedChanged: {
                                if (checked) {
                                    if (visibleColumns.indexOf(modelData) === -1) {
                                        visibleColumns = visibleColumns.concat([modelData]).sort(function(a, b) { return a - b; });
                                    }
                                } else {
                                    visibleColumns = visibleColumns.filter(function(item) { return item !== modelData; });
                                }
                                root.__fit_columns();
                                root.relayout_tables();
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.uiFontFamily
                            font.pixelSize: Theme.fontSizeBody
                            color: Theme.textPrimary
                            text: {
                                var headers = ["Problem", "ML Model", "Hardware", "Latency", "Power Consumption", "Carbon Footprint", "Carbon Intensity", "Energy Consumption", "Memory Footprint"];
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
                color: toggleButton.hovered ? Theme.accentFillHover : Theme.accentFill
                radius: Theme.radiusXs
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
                target: sidePanel; width: 220
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
            color: Theme.overlay
            border.color: Theme.borderStrong

            SmlIconButton {
                anchors.top: parent.top
                anchors.topMargin: Theme.space2
                anchors.right: parent.right
                anchors.rightMargin: Theme.space2
                button_size: Theme.controlHeightSm
                icon_name: "cross"
                tooltip_text: "Close"
                onClicked: infoPopup.close()
            }

            SmlText {
                id: iterationTextHeader
                anchors {
                    top: parent.top
                    topMargin: Theme.space4
                    left: parent.left
                    leftMargin: Theme.space5
                }
                text_value: "Iteration " + infoPopup.iteration
                text_kind: SmlText.TextKind.Header_2

            }

            SustainMLTreeModel {
                id: jsonTreeModel
            }

            function expandAllNodes() {
                try {
                    var rootRowCount = jsonTreeModel.rowCount();

                    for (var i = 0; i < rootRowCount; i++) {
                        var rootIndex = jsonTreeModel.index(i, 0);
                        jsonTreeView.expand(rootIndex);
                        expandChildren(rootIndex);
                    }
                } catch (e) {
                    console.log("Error expanding nodes:", e);
                }
            }

            function expandChildren(parentIndex) {
                try {
                    var childCount = jsonTreeModel.rowCount(parentIndex);
                    for (var i = 0; i < childCount; i++) {
                        var childIndex = jsonTreeModel.index(i, 0, parentIndex);
                        jsonTreeView.expand(childIndex);
                        expandChildren(childIndex);
                    }
                } catch (e) {
                    console.log("Error expanding children:", e);
                }
            }

            C1.TreeView {
                id: jsonTreeView
                anchors {
                    top: iterationTextHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: Theme.space3
                    leftMargin: Theme.space4
                    rightMargin: Theme.space4
                }
                model: jsonTreeModel
                clip: true
                selectionMode: C1.SelectionMode.NoSelection
                frameVisible: false
                backgroundVisible: false
                alternatingRowColors: false

                headerDelegate: Rectangle {
                    height: 30
                    color: Theme.cardHeader
                    Text {
                        anchors.fill: parent
                        leftPadding: Theme.space2
                        verticalAlignment: Text.AlignVCenter
                        text: styleData.value
                        font.family: Theme.uiFontFamily
                        font.pixelSize: Theme.fontSizeMeta
                        font.weight: Font.DemiBold
                        color: Theme.textSecondary
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                }
                rowDelegate: Rectangle {
                    height: 26
                    color: "transparent"
                }

                // Slim green scroll bars, as everywhere else
                style: C1Styles.TreeViewStyle {
                    transientScrollBars: false
                    scrollBarBackground: Item { implicitWidth: 10; implicitHeight: 10 }
                    incrementControl: Item { }
                    decrementControl: Item { }
                    corner: Item { }
                    handle: Item {
                        implicitWidth: 10
                        implicitHeight: 10
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 3
                            color: styleData.pressed ? Theme.accentFillPressed
                                 : styleData.hovered ? Theme.accentFillHover : Theme.brandGreenBright
                            opacity: styleData.hovered || styleData.pressed ? 1.0 : 0.75
                        }
                    }
                }

                itemDelegate: Item {

                    Text {
                        anchors.fill: parent
                        elide: styleData.elideMode
                        text: styleData.value
                        verticalAlignment: Text.AlignVCenter
                        font.family: styleData.column === 0 ? Theme.uiFontFamily : Theme.monoFontFamily
                        font.pixelSize: Theme.fontSizeBody
                        color: styleData.column === 0 ? Theme.textSecondary : Theme.textPrimary
                    }
                }

                C1.TableViewColumn {
                    role: "name"
                    title: "Name"
                    width: jsonTreeView.width * 0.40
                }
                C1.TableViewColumn {
                    role: "value"
                    title: "Value"
                    width: jsonTreeView.width * 0.60
                }

                Connections {
                    target: jsonTreeModel
                    function onUpdatedData() {
                        jsonScrollView.expandAllNodes();
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                x = 0;
                // pass the JSON object to the C++ model as a string
                try {
                    var s = JSON.stringify(infoPopup.jsonData);
                    jsonTreeModel.updateFromJsonString(s);
                    jsonTreeView.model = null;
                    jsonTreeView.model = jsonTreeModel;

                } catch (e) {
                    console.log("Failed to stringify jsonData:", e);
                }
            } else {
                x = -width;
            }
        }
    }

    Popup {
        id: metricInfoPopup
        modal: true
        focus: true
        width: 300
        height: 150
        x: (parent.width - width)/2
        y: (parent.height - height)/2
        property string metricName: ""
        property var metricDescriptions: ({
            "latency": "Time it takes for a complete inference of the model in the suggested hardware (s).",
            "power consumption": "Instantaneous power consumed during execution of the model on the hardware (W).",
            "carbon footprint": "Total CO2e emissions from the use of the model on the suggested hardware (gCO2e).",
            "carbon intensity": "Emissions per unit of energy consumed (gCO2/kW).",
            "energy consumption": "Total energy used by the execution (kWh).",
            "memory footprint": "Memory the model needs: its weights plus the working memory to process the longest input it accepts (MB)."
        })

        function descriptionFor(name) {
            if (!name || name.length === 0) return "No description available."
            var key = name.toLowerCase()

            for (var k in metricInfoPopup.metricDescriptions) {
                if (key.indexOf(k) !== -1) {
                    return metricInfoPopup.metricDescriptions[k]
                }
            }
            return "No description available."
        }

        background: Rectangle {
            color: Theme.overlay
            border.color: Theme.borderStrong
            radius: Theme.radiusLg
        }

        SmlIconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            button_size: Theme.controlHeightSm
            icon_name: "cross"
            tooltip_text: "Close"
            onClicked: metricInfoPopup.close()
        }

        SmlText {
            id: metricTitle
            text_kind: SmlText.TextKind.Header_2
            text_value: metricInfoPopup.metricName
            anchors {
                top: parent.top
                topMargin: 12
                left: parent.left
                leftMargin: 16
                right: parent.right
                rightMargin: 8
            }
            wrapMode: Text.WordWrap
        }

        SmlScrollView {
            id: metricDescScroll
            anchors {
                top: metricTitle.bottom
                topMargin: 8
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 16
                rightMargin: 16
                bottomMargin: 16
            }
            content_height: descText.implicitHeight
            layout: SmlScrollBar.ScrollBarLayout.Vertical
            clip: true

            SmlText {
                id: descText
                text_kind: SmlText.TextKind.Body
                text_value: metricInfoPopup.descriptionFor(metricInfoPopup.metricName)
                wrapMode: Text.WordWrap
                width: metricDescScroll.width - 12
            }
        }
    }
}
