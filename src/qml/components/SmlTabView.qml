import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Fragments imports
import "../fragments"

Item {
    id: sustainml_custom_tabview

    // Public properties
    required property var allowed_stack_components
    required property string default_stack_component
    property bool allow_new_tabs: false
    property bool allow_close_tabs: true
    property bool reduced_tabs: false
    property bool rounded: true
    property string selected_tab_color: "white"
    property string selected_tab_nightmode_color: "grey"

    // Private properties
    property int __current_tab: 0                                               // current tab displayed
    property int __last_stack: 1                                                // force unique idx on QML components
    property ListModel __tab_model: ListModel {}                                // tab model for tab management

    // Public signals
    signal tab_view_loaded()
    signal retrieve_default_data()
    signal loaded_item_signal(string component, string signal_kind, string id)  // abstract signal from loaded components

    // Private signals
    signal change_stack_view_(int stack_id, var stack_component_name)

    // Read only design properties
    readonly property int __max_tabs: 15
    readonly property int __tabs_height: 36
    readonly property int __tabs_margins: 15
    readonly property int __tab_icons_size: 16
    readonly property int __max_tab_size: allow_close_tabs || !reduced_tabs ? 200 : 200 - __tab_icons_size - (2 * __tabs_margins)
    readonly property int __min_tab_size: allow_close_tabs || !reduced_tabs ? 180 : 180 - __tab_icons_size - (2 * __tabs_margins)
    readonly property int __add_tab_width: 50
    readonly property int __min_gap: 80
    readonly property int __radius: Settings.input_default_rounded_radius
    readonly property string __not_selected_tab_color: Settings.app_color_light
    readonly property string __not_selected_tab_nightmode_color: Settings.app_color_dark
    readonly property string __selected_shadow_tab_color: "#c0c0c0"
    readonly property string __not_selected_shadow_tab_color: "#d0d0d0"

    // initialize first element in the tab
    Component.onCompleted:{
        sustainml_custom_tabview.__tab_model.append( {"idx" : 0, "title": "New Tab", "stack_id": 0})
        var new_stack = stack_component.createObject(null)
        new_stack.setSource(sustainml_custom_tabview.__get_load_component(default_stack_component), {"stack_id": 0, "problem_id": -1})
        stack_layout.children.push(new_stack)
        __refresh_layout(__current_tab)
        sustainml_custom_tabview.tab_view_loaded()
    }

    // stack layout (where idx referred to the tab, which would contain different views)
    StackLayout {
        id: stack_layout
        width: sustainml_custom_tabview.width
        anchors.top: tab_list.bottom; anchors.bottom: sustainml_custom_tabview.bottom

        Component {
            id: stack_component
            Loader
            {
                id: stack
                //required property int stack_id
                //required property string customInitialItem
                //source: sustainml_custom_tabview.__get_load_component(customInitialItem)

                Connections {
                    target: stack.item
                    ignoreUnknownSignals: true
                    function onComponent_signal(signal_kind, id)
                    {
                        sustainml_custom_tabview.loaded_item_signal(stack.customInitialItem, signal_kind, id)
                    }
                }
            }
        }
    }

    // delegated tab view
    Component {
        id: delegated_component
        Rectangle {
            required property int idx
            required property string title
            required property int stack_id

            id: delegated_rect
            height: __tabs_height
            width: sustainml_custom_tabview.__tab_model.count == __max_tabs
                ? sustainml_custom_tabview.width / sustainml_custom_tabview.__tab_model.count < __tab_icons_size+ (4*__tabs_margins)
                    ? __current_tab == idx ? __tab_icons_size+ (2 * __tabs_margins)
                    : sustainml_custom_tabview.width / sustainml_custom_tabview.__tab_model.count : sustainml_custom_tabview.width / sustainml_custom_tabview.__tab_model.count
                : allow_close_tabs || allow_new_tabs
                    ? (sustainml_custom_tabview.width - add_new_tab_button.width) / sustainml_custom_tabview.__tab_model.count > __max_tab_size
                        ? __max_tab_size
                        : (sustainml_custom_tabview.width - add_new_tab_button.width) / sustainml_custom_tabview.__tab_model.count < __tab_icons_size+ (4*__tabs_margins)
                            ? __current_tab == idx
                                ? __tab_icons_size+ (2 * __tabs_margins)
                                : (sustainml_custom_tabview.width - add_new_tab_button.width) / sustainml_custom_tabview.__tab_model.count
                            : (sustainml_custom_tabview.width - add_new_tab_button.width) / sustainml_custom_tabview.__tab_model.count
                    : sustainml_custom_tabview.width / sustainml_custom_tabview.__tab_model.count > __max_tab_size
                        ? __max_tab_size
                        : sustainml_custom_tabview.width / sustainml_custom_tabview.__tab_model.count
            color: __current_tab == idx
                    ? ScreenManager.night_mode ? selected_tab_nightmode_color : selected_tab_color
                    : ScreenManager.night_mode ? __not_selected_tab_nightmode_color : __not_selected_tab_color
            property string shadow_color: __current_tab == idx ? __selected_shadow_tab_color : __not_selected_shadow_tab_color
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: idx == 0 || __current_tab == idx ? delegated_rect.color : shadow_color}
                GradientStop { position: 0.04; color: delegated_rect.color }
                GradientStop { position: 0.96; color: delegated_rect.color }
                GradientStop { position: 1.0; color: __current_tab == idx + 1 ? shadow_color : delegated_rect.color}
            }
            radius: sustainml_custom_tabview.rounded ? sustainml_custom_tabview.__radius : 0
            Rectangle
            {
                visible: sustainml_custom_tabview.rounded
                width: parent.width
                height: parent.height / 2
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                color: __current_tab == idx
                        ? ScreenManager.night_mode ? selected_tab_nightmode_color: selected_tab_color
                        : ScreenManager.night_mode ? __not_selected_tab_nightmode_color: __not_selected_tab_color
                property string shadow_color: __current_tab == idx ? __selected_shadow_tab_color : __not_selected_shadow_tab_color
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: idx == 0 || __current_tab == idx ? delegated_rect.color : shadow_color}
                    GradientStop { position: 0.04; color: delegated_rect.color }
                    GradientStop { position: 0.96; color: delegated_rect.color }
                    GradientStop { position: 1.0; color: __current_tab == idx + 1 ? shadow_color : delegated_rect.color}
                }
            }

            TextEdit {
                horizontalAlignment: Qt.AlignLeft; verticalAlignment: Qt.AlignVCenter
                anchors.left: parent.left
                anchors.leftMargin: __tabs_margins
                anchors.right: close_icon.visible ? close_icon.left : parent.right
                anchors.rightMargin: __tabs_margins
                anchors.verticalCenter: parent.verticalCenter
                text:  title
                // Text components set up
                font.bold: true
                font.family: SustainMLFont.title_font
                font.pixelSize: Settings.body_font_size
                color: ScreenManager.night_mode ? Settings.app_color_light : Settings.app_color_dark
                wrapMode: TextEdit.WrapAnywhere
                readOnly: true
                selectByMouse: true
                selectByKeyboard: true
                selectionColor: ScreenManager.night_mode ? Settings.app_color_green_2 : Settings.app_color_green_4
            }
            // close tab icon
            SmlIcon {
                id: close_icon
                visible: allow_close_tabs ? idx == __current_tab ? true : parent.width > __min_tab_size : false
                anchors.right: parent.right
                anchors.rightMargin: __tabs_margins
                anchors.verticalCenter: parent.verticalCenter
                name: Settings.close_tab_icon_name
                size: __tab_icons_size
                color: Settings.app_color_dark
                nightmode_color: Settings.app_color_light
            }
            // tab selection action
            MouseArea {
                anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left;
                anchors.right: close_icon.left; anchors.rightMargin: - __tabs_margins
                onClicked: {
                    __refresh_layout(idx)
                }
            }
            // close tab action
            MouseArea {
                anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.left: close_icon.left; anchors.leftMargin: - __tabs_margins
                onClicked: {
                    // act as close is close icon shown (same expression as in close_icon visible attribute)
                    if (sustainml_custom_tabview.allow_close_tabs && (idx == __current_tab || parent.width > __min_tab_size))
                    {
                        __remove_idx(idx)
                    }
                    // if not, act as open tab action
                    else
                    {
                        __refresh_layout(idx)
                    }
                }
            }
        }
    }

    // tab bar list
    ListView {
        id: tab_list
        anchors.top: parent.top
        anchors.left: parent.left
        width: contentWidth
        height: __tabs_height
        orientation: ListView.Horizontal
        interactive: false
        model: sustainml_custom_tabview.__tab_model
        delegate: delegated_component
    }

    // Add new tab button
    Rectangle {
        id: add_new_tab_button
        visible: sustainml_custom_tabview.allow_new_tabs && sustainml_custom_tabview.__tab_model.count < __max_tabs
        anchors.right: remain_width_rect.left
        anchors.verticalCenter: tab_list.verticalCenter
        height: __tabs_height
        width: sustainml_custom_tabview.__tab_model.count == __max_tabs ? 0 : __add_tab_width
        color: __not_selected_tab_color
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color:  __not_selected_shadow_tab_color}
            GradientStop { position: 0.08; color: add_new_tab_button.color }
            GradientStop { position: 1.0; color: add_new_tab_button.color }
        }
        // add new tab icon
        SmlIcon {
            visible: sustainml_custom_tabview.__tab_model.count < __max_tabs
            anchors.centerIn: parent
            name: Settings.add_tab_icon_name
            size: __tab_icons_size
            color: Settings.app_color_dark
            nightmode_color: Settings.app_color_light
        }
        // add new tab action
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (sustainml_custom_tabview.__tab_model.count < __max_tabs)
                    sustainml_custom_tabview.__create_new_tab()
            }
        }
    }

    // remain space in tab bar handled by this component
    Rectangle {
        id: remain_width_rect
        visible: false
        width: sustainml_custom_tabview.width - add_new_tab_button.width - tab_list.width; height: __tabs_height
        anchors.right: sustainml_custom_tabview.right
        anchors.verticalCenter: tab_list.verticalCenter
        color: __not_selected_tab_color

        Rectangle {
            width: parent.width >= __min_gap ? __min_gap : parent.width; height: parent.height
            color: parent.color
            gradient: Gradient {
            orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color:  __not_selected_shadow_tab_color}
                GradientStop { position: 0.08; color: __not_selected_tab_color }
                GradientStop { position: 1.0; color: __not_selected_tab_color }
            }
        }
    }


    // PUBLIC METHODS
    function create_new_tab(tab_title, stack_id, problem_id, stack_component_name)
    {
        if (allowed_stack_components[stack_component_name] !== undefined)
        {
            __create_new_custom_tab(tab_title, stack_id, problem_id, stack_component_name)
        }
        else
        {
            console.log("Error: The given stack component '" + stack_component_name + "' is not allowed")
        }
    }

    function focus(stack_id, problem_id)
    {
        var stack_id_comparator = -1
        if (stack_id != undefined)
        {
            stack_id_comparator = stack_id
        }
        else
        {
            for (var i = 0; i < stack_component.count; i++)
            {
                if (stack_component.children[i].item.problem == problem_id)
                {
                    stack_id_comparator = stack_component.children[i].item.stack_id
                    break   // end loop
                }
            }
        }
        if (stack_id_comparator >= 0)
        {
            for (var idx = 0; idx < sustainml_custom_tabview.__tab_model.count; idx++)
            {
                if (sustainml_custom_tabview.__tab_model.get(idx).stack_id == stack_id_comparator)
                {
                    __refresh_layout(idx)
                    break
                }
            }
        }
    }

    function update_stack_id(new_stack_id, stack_id)
    {
        for (var i = 0; i < sustainml_custom_tabview.__tab_model.count; i++)
        {
            if (sustainml_custom_tabview.__tab_model.get(i).stack_id == stack_id)
            {
                sustainml_custom_tabview.__tab_model.setProperty(i, "stack_id", new_stack_id)

                // update idx model
                tab_list.model = sustainml_custom_tabview.__tab_model

                // update also the stack id of the load component
                for (var j=0; j<stack_layout.count; j++)
                {
                    if (stack_layout.children[j].item.stack_id == stack_id)
                    {
                        stack_layout.children[j].item.stack_id  = new_stack_id
                        break; // exit loop
                    }
                }
                break          // exit loop
            }
        }
    }

    function update_problem_id(new_problem_id, problem_id)
    {
        // update also the stack id of the load component
        for (var j=0; j<stack_layout.count; j++)
        {
            if (stack_layout.children[j].item.problem_id == problem_id)
            {
                stack_layout.children[j].item.problem_id  = new_problem_id
                break; // exit loop
            }
        }
    }

    function update_tab_name(new_title, stack_id)
    {
        for (var i = 0; i < sustainml_custom_tabview.__tab_model.count; i++)
        {
            if (sustainml_custom_tabview.__tab_model.get(i).stack_id == stack_id)
            {
                sustainml_custom_tabview.__tab_model.setProperty(i, "title", new_title)
                // update idx model
                tab_list.model = sustainml_custom_tabview.__tab_model
                break       // exit loop
            }
        }
    }

    // PRIVATE METHODS
    // default tab creation method
    function __create_new_tab()
    {
        __create_new_custom_tab("New tab", 1, -1, default_stack_component)
    }

    // create new tab with the given component
    function __create_new_custom_tab(tab_title, stack_id, problem_id, component_identifier)
    {
        var initial_component = component_identifier
        if (allowed_stack_components[component_identifier] === "")
        {
            initial_component = default_stack_component;
        }
        var last_stack_id = __last_stack
        if (last_stack_id < stack_id)
        {
            last_stack_id = stack_id
        }
        __last_stack = last_stack_id + 1
        var idx = sustainml_custom_tabview.__tab_model.count
        sustainml_custom_tabview.__tab_model.set(idx, {"idx" : idx, "title": tab_title, "stack_id": last_stack_id})
        var new_stack = stack_component.createObject(null)
        new_stack.setSource(sustainml_custom_tabview.__get_load_component(initial_component),
                {"stack_id": last_stack_id, "problem_id": problem_id})
        stack_layout.children.push(new_stack)
        stack_layout.currentIndex = last_stack_id
        __refresh_layout(idx)
        __order_tabs()
        focus(undefined, problem_id)
    }

    // the given idx update current tab displayed (if != current)
    function __refresh_layout(idx)
    {
        // move to idx tab if necessary
        if (idx != __current_tab)
        {
            __current_tab = idx

            // move to the idx tab in the stack
            stack_layout.currentIndex = sustainml_custom_tabview.__tab_model.get(idx).stack_id
        }
        // update idx model
        tab_list.model = sustainml_custom_tabview.__tab_model
    }

    // remove tab and all contained components
    function __remove_idx(idx)
    {
        var should_add_new_tab = false
        // add new tab if closing the last opened tab
        if (sustainml_custom_tabview.__tab_model.count <= 1)
        {
            should_add_new_tab = true
        }

        var i, idx_prev
        var swap = false
        for (i=0, idx_prev=-1; i<sustainml_custom_tabview.__tab_model.count; i++, idx_prev++)
        {
            // if tab removed, reorder remain tabs
            if (swap)
            {
                sustainml_custom_tabview.__tab_model.setProperty(idx_prev, "title", sustainml_custom_tabview.__tab_model.get(i).title)
                sustainml_custom_tabview.__tab_model.setProperty(idx_prev, "stack_id", sustainml_custom_tabview.__tab_model.get(i).stack_id)
            }
            // reorder model idx usage, and delete idx tab components (stack layout content)
            if (idx == i){
                swap = true
                var j
                for (j=0; j<stack_layout.count; j++)
                {
                    if (stack_layout.children[j].id == sustainml_custom_tabview.__tab_model.get(idx).stack_id)
                    {
                        stack_layout.children[j].destroy()
                    }
                }
            }
        }
        // if removed, remove tab from model (repeater tab bar)
        if (swap)
        {
            sustainml_custom_tabview.__tab_model.remove(idx_prev)
        }

        // if last tab closed
        if (should_add_new_tab)
        {
            //__create_new_custom_tab(tab_title, stack_id, component_identifier)
            sustainml_custom_tabview.retrieve_default_data()
        }
        // reset the focus to the new "current" tab
        else
        {
            var new_current = __current_tab
            if (idx == __current_tab)
            {
                if (idx -1 >= 1)
                {
                    new_current = idx -1
                }
                else
                {
                    new_current = 0
                }
                // move to the idx tab in the stack
                stack_layout.currentIndex = sustainml_custom_tabview.__tab_model.get(new_current).stack_id
            }
            else
            {
                if (__current_tab == sustainml_custom_tabview.__tab_model.count)
                {
                    new_current = __current_tab -1
                }
            }
            // perform changes in the view
            __refresh_layout(new_current)
        }
    }

    // order tabs by stack id (minor to major)
    function __order_tabs()
    {
        var i, j
        for (i=0; i<stack_layout.count; i++)
        {
            for (j=i+1; j<stack_layout.count; j++)
            {
                if (stack_layout.children[i].item.problem_id > stack_layout.children[j].item.problem_id)
                {
                    var stack_src = stack_layout.children[i].item.stack_id
                    var stack_dst = stack_layout.children[j].item.stack_id
                    var title_src = ""
                    var title_dst = ""
                    var idx_src = -1
                    var idx_dst = -1
                    for (var s=0; s< sustainml_custom_tabview.__tab_model.count; s++)
                    {
                        if (sustainml_custom_tabview.__tab_model.get(s).stack_id == stack_src)
                        {
                            idx_src = s
                            title_src = sustainml_custom_tabview.__tab_model.get(s).title
                        }
                        else if (sustainml_custom_tabview.__tab_model.get(s).stack_id == stack_dst)
                        {
                            idx_dst = s
                            title_dst = sustainml_custom_tabview.__tab_model.get(s).title
                        }
                    }
                    if (idx_src != -1 && idx_dst != -1 && idx_src < idx_dst)
                    {
                        sustainml_custom_tabview.__tab_model.setProperty(idx_src, "title", title_dst)
                        sustainml_custom_tabview.__tab_model.setProperty(idx_dst, "title", title_src)
                        sustainml_custom_tabview.__tab_model.setProperty(idx_src, "stack_id", stack_dst)
                        sustainml_custom_tabview.__tab_model.setProperty(idx_dst, "stack_id", stack_src)
                    }
                }
            }
        }
    }

    // get the load element for the stack view
    function __get_load_component(component_name)
    {
        if (sustainml_custom_tabview.allowed_stack_components[component_name] !== undefined)
        {
            return sustainml_custom_tabview.allowed_stack_components[component_name]
        }
        else
        {
            return sustainml_custom_tabview.allowed_stack_components[sustainml_custom_tabview.default_stack_component]
        }
    }
}

