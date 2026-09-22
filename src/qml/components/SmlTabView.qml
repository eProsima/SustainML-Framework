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
    property bool allow_tab_rename: false
    property string selected_tab_color: "white"
    property string selected_tab_nightmode_color: "#303030"
    property string tab_background_color: "transparent"
    property string tab_background_nightmode_color: "transparent"
    property string not_selected_tab_color: Settings.app_color_light
    property string not_selected_tab_nightmode_color: Settings.app_color_dark
    property string selected_shadow_tab_color: "#c0c0c0"
    property string selected_shadow_tab_nightmode_color: "#707070"
    property string not_selected_shadow_tab_color: "#d0d0d0"
    property string not_selected_shadow_tab_nightmode_color: "black"

    // Private properties
    property int __current_tab: 0                                               // current tab displayed
    property int __last_stack: 1                                                // force unique idx on QML components
    property ListModel __tab_model: ListModel {}                                // tab model for tab management

    // Public signals
    signal tab_view_loaded()
    signal retrieve_default_data()
    signal loaded_item_signal(string component, string signal_kind, string iteration_id)  // abstract signal from loaded components

    // Private signals
    signal change_stack_view_(int stack_id, var stack_component_name)
    signal tabClosed(int stack_id_closed)
    signal tab_renamed(int stack_id, string new_title)

    // Read only design properties
    readonly property int __max_tabs: 15
    readonly property int __tabs_height: 36
    readonly property int __tabs_margins: 15
    readonly property int __tab_icons_size: 16
    readonly property int __max_tab_size: !reduced_tabs ? 200 : 200 - __tab_icons_size - (2 * __tabs_margins)
    readonly property int __min_tab_size: !reduced_tabs ? 180 : 180 - __tab_icons_size - (2 * __tabs_margins)
    readonly property int __add_tab_width: 50
    readonly property int __min_gap: 80
    readonly property int __radius: Settings.input_default_rounded_radius

    // initialize first element in the tab
    Component.onCompleted:{
        sustainml_custom_tabview.__tab_model.append( {"idx" : 0, "title": "New Tab", "stack_id": 0})
        var new_stack = stack_component.createObject(null)
        new_stack.setSource(sustainml_custom_tabview.__get_load_component(default_stack_component), {"stack_id": 0, "problem_id": -1, "total_tabs": sustainml_custom_tabview.__tab_model.count, "problem_tabs_width": tab_list.width})
        stack_layout.children.push(new_stack)
        __refresh_layout(__current_tab)
        sustainml_custom_tabview.tab_view_loaded()
    }

    function getNextAvailableStackId()
    {
        var maxStackId = -1;
        for (var i = 0; i < sustainml_custom_tabview.__tab_model.count; i++) {
            var currentStackId = sustainml_custom_tabview.__tab_model.get(i).stack_id;
            if (currentStackId > maxStackId) {
                maxStackId = currentStackId;
            }
        }
        return maxStackId + 1;
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
                    function onComponent_signal(component, signal_kind, iteration_id)
                    {
                        sustainml_custom_tabview.loaded_item_signal(component, signal_kind, iteration_id)
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
                    : ScreenManager.night_mode ? not_selected_tab_nightmode_color : not_selected_tab_color
            property string shadow_color: __current_tab == idx
                    ? ScreenManager.night_mode ? selected_shadow_tab_nightmode_color : selected_shadow_tab_color
                    : ScreenManager.night_mode ? not_selected_shadow_tab_nightmode_color : not_selected_shadow_tab_color
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
                        : ScreenManager.night_mode ? not_selected_tab_nightmode_color: not_selected_tab_color
                property string shadow_color: __current_tab == idx
                        ? ScreenManager.night_mode ? selected_shadow_tab_nightmode_color : selected_shadow_tab_color
                        : ScreenManager.night_mode ? not_selected_shadow_tab_nightmode_color : not_selected_shadow_tab_color
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: idx == 0 || __current_tab == idx ? delegated_rect.color : shadow_color}
                    GradientStop { position: 0.04; color: delegated_rect.color }
                    GradientStop { position: 0.96; color: delegated_rect.color }
                    GradientStop { position: 1.0; color: __current_tab == idx + 1 ? shadow_color : delegated_rect.color}
                }
            }

            TextEdit {
                id: tab_title
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
                selectByKeyboard: true
                selectionColor: ScreenManager.night_mode ? Settings.app_color_green_2 : Settings.app_color_green_4
                readOnly: !sustainml_custom_tabview.allow_tab_rename
                focus: editing
                property bool editing: false
                property string __original: title

                Keys.onReturnPressed: { commitRename(); }
                Keys.onEnterPressed:  { commitRename(); }
                Keys.onEscapePressed: { cancelRename(); }

                onFocusChanged: {
                    if (!focus && editing) commitRename();
                }

                function commitRename() {
                    if (!editing) return;
                    editing = false;
                    var newTitle = text.trim();
                    if (newTitle.length === 0) {
                        text = __original;
                        return;
                    }
                    __original = newTitle;
                    sustainml_custom_tabview.update_tab_name(newTitle, stack_id);
                    sustainml_custom_tabview.tab_renamed(stack_id, newTitle);
                }

                function cancelRename() {
                    if (!editing) return;
                    editing = false;
                    text = __original;
                }
            }
            // close tab icon
            SmlIcon {
                id: close_icon
                visible: allow_close_tabs &&
                         title !== "Overview" &&
                         title !== "Iteration" &&
                         (idx == __current_tab || parent.width > __min_tab_size)
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
                onDoubleClicked: {
                    if (sustainml_custom_tabview.allow_tab_rename) {
                        tab_title.editing = true;
                        tab_title.forceActiveFocus();
                        tab_title.selectAll();
                    }
                }
            }
            // close tab action
            MouseArea {
                anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.left: close_icon.left; anchors.leftMargin: - __tabs_margins
                onClicked: {
                    // act as close is close icon shown (same expression as in close_icon visible attribute)
                    if (sustainml_custom_tabview.allow_close_tabs && title !== "Overview" && title !== "Iteration" && (idx == __current_tab || parent.width > __min_tab_size))
                    {
                        // __tab_model.remove() inside this call can destroy/recreate this very
                        // delegate mid-handler, so nothing after it may touch this delegate's own
                        // scope (bare __refresh_layout etc.) - do it all in one call on the stable
                        // outer component instead.
                        sustainml_custom_tabview.__close_tab(idx, stack_id)
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

        // Keep every loaded tab's content in sync with how wide the tab bar itself
        // currently is (grows/shrinks as tabs are added/removed), so content that
        // wants to visually align with the tab row (e.g. SmlProblemFragment's
        // Overview/Iteration background) can do so without guessing at tab widths.
        onWidthChanged:
        {
            for (var k = 0; k < stack_layout.children.length; k++)
            {
                if (stack_layout.children[k].item && stack_layout.children[k].item.problem_tabs_width !== undefined)
                {
                    stack_layout.children[k].item.problem_tabs_width = width;
                }
            }
        }

        Rectangle
        {
            id: tab_list_shadow
            anchors.top: parent.top
            anchors.left: parent.left
            height: parent.height
            width: sustainml_custom_tabview.width
            color: ScreenManager.night_mode ? tab_background_nightmode_color : tab_background_color
            z: -1
        }
    }

    // Add new tab button
    Rectangle {
        id: add_new_tab_button
        visible: sustainml_custom_tabview.allow_new_tabs && sustainml_custom_tabview.__tab_model.count < __max_tabs
        anchors.right: remain_width_rect.left
        anchors.verticalCenter: tab_list.verticalCenter
        height: __tabs_height
        width: sustainml_custom_tabview.__tab_model.count == __max_tabs ? 0 : __add_tab_width
        color: not_selected_tab_color
        property string shadow_color: ScreenManager.night_mode ? not_selected_shadow_tab_nightmode_color : not_selected_shadow_tab_color
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color:  add_new_tab_button.shadow_color}
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
        color: not_selected_tab_color

        Rectangle {
            id: remain_width_shadow
            width: parent.width >= __min_gap ? __min_gap : parent.width; height: parent.height
            color: parent.color
            property string shadow_color: ScreenManager.night_mode ? not_selected_shadow_tab_nightmode_color : not_selected_shadow_tab_color
            gradient: Gradient {
            orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: remain_width_shadow.shadow_color}
                GradientStop { position: 0.08; color: not_selected_tab_color }
                GradientStop { position: 1.0; color: not_selected_tab_color }
            }
        }
    }


    // PUBLIC METHODS
    function create_new_tab(tab_title, stack_id, problem_id, stack_component_name)
    {
        if (allowed_stack_components[stack_component_name] !== undefined)
        {
            var tabExists = false;
            for (var i = 0; i < sustainml_custom_tabview.__tab_model.count; i++) {
                if (sustainml_custom_tabview.__tab_model.get(i).stack_id === stack_id) {
                    tabExists = true;
                    break;
                }
            }
            if (!tabExists) {
                __create_new_custom_tab(tab_title, stack_id, problem_id, stack_component_name);
            }
        }
        else
        {
            console.log("Error: The given stack component '" + stack_component_name + "' is not allowed")
        }
    }

    function close_tab(stack_id, problem_id)
    {
        var tabExists = false;
        for (var i = 0; i < sustainml_custom_tabview.__tab_model.count; i++) {
            if (sustainml_custom_tabview.__tab_model.get(i).stack_id === stack_id) {
                tabExists = true;
                break;
            }
        }
        if (tabExists)
        {
            __remove_idx(i);
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

        var idx = sustainml_custom_tabview.__tab_model.count
        sustainml_custom_tabview.__tab_model.set(idx, {"idx" : idx, "title": tab_title, "stack_id": stack_id})
        var new_stack = stack_component.createObject(null)
        new_stack.setSource(sustainml_custom_tabview.__get_load_component(initial_component),
                {"stack_id": stack_id, "problem_id": problem_id, "total_tabs": sustainml_custom_tabview.__tab_model.count, "problem_tabs_width": tab_list.width})
        stack_layout.children.push(new_stack)
        for (var i = 0; i < stack_layout.children.length; i++){
            if (stack_layout.children[i].item && stack_layout.children[i].item.total_tabs !== undefined) {
                stack_layout.children[i].item.total_tabs = sustainml_custom_tabview.__tab_model.count;
            }
        }
        __order_tabs()
    }

    // the given idx update current tab displayed (if != current)
    function __refresh_layout(idx)
    {
        // move to idx tab if necessary
        if (idx != __current_tab)
        {
            __current_tab = idx

            // move to the idx tab in the stack
            stack_layout.currentIndex = idx
        }
        // update idx model
        tab_list.model = sustainml_custom_tabview.__tab_model
    }

    // Close the tab at idx, in one call so nothing runs afterward in a delegate whose
    // model row (and possibly the delegate itself) __remove_idx() may already have
    // destroyed. __remove_idx() already picks and switches to the correct remaining
    // tab itself (by searching stack_layout.children for a matching stack_id, not by
    // raw position) - calling __refresh_layout(idx) again afterward would overwrite
    // that correct choice with a raw tab_model-relative index that doesn't actually
    // correspond to stack_layout.children's order, which was the real cause of both
    // the earlier crash and tabs ending up showing the wrong (or no) content.
    function __close_tab(idx, stack_id_to_close)
    {
        tabClosed(stack_id_to_close)
        __remove_idx(idx)
    }

    // remove tab and all contained components
    function __remove_idx(idx)
    {
        // add new tab if closing the last opened tab
        var should_add_new_tab = (sustainml_custom_tabview.__tab_model.count <= 1)

        var removedStackId = sustainml_custom_tabview.__tab_model.get(idx).stack_id

        var wasCurrent = (idx === __current_tab)

        // Decide, BEFORE anything is removed, which tab should be shown afterward -
        // by identity (stack_id), never by raw position: positions shift as soon as
        // a row is removed, which was the source of previous bugs here.
        //  - closing a tab that ISN'T the one currently shown: keep showing the
        //    same tab it already was.
        //  - closing the CURRENTLY shown tab: prefer the tab that follows it, else
        //    the one before it.
        var newCurrentStackId = null
        if (!should_add_new_tab)
        {
            if (wasCurrent)
            {
                if (idx + 1 < sustainml_custom_tabview.__tab_model.count)
                {
                    newCurrentStackId = sustainml_custom_tabview.__tab_model.get(idx + 1).stack_id
                }
                else if (idx - 1 >= 0)
                {
                    newCurrentStackId = sustainml_custom_tabview.__tab_model.get(idx - 1).stack_id
                }
            }
            else if (__current_tab >= 0 && __current_tab < sustainml_custom_tabview.__tab_model.count)
            {
                newCurrentStackId = sustainml_custom_tabview.__tab_model.get(__current_tab).stack_id
            }
        }

        for (var j = 0; j < stack_layout.children.length; j++)
        {
            var loader = stack_layout.children[j]
            if (loader.item && loader.item.stack_id === removedStackId)
            {
                loader.destroy()
                break
            }
        }

        sustainml_custom_tabview.__tab_model.remove(idx)

        for (var i = 0; i < sustainml_custom_tabview.__tab_model.count; i++)
        {
            sustainml_custom_tabview.__tab_model.setProperty(i, "idx", i)
        }

        // Tell the remaining tabs' content how many tabs are left, mirroring what
        // __create_new_custom_tab already does on add - otherwise a tab closed after
        // others were added leaves stale (too-large) total_tabs on the survivors, and
        // anything sized from it (e.g. SmlProblemFragment's background rectangle)
        // keeps reserving space for tabs that no longer exist.
        for (var k = 0; k < stack_layout.children.length; k++)
        {
            if (stack_layout.children[k].item && stack_layout.children[k].item.total_tabs !== undefined)
            {
                stack_layout.children[k].item.total_tabs = sustainml_custom_tabview.__tab_model.count;
            }
        }

        if (should_add_new_tab)
        {
            sustainml_custom_tabview.retrieve_default_data()
        }
        else if (newCurrentStackId !== null)
        {
            // __tab_model's position can be resolved immediately - ListModel.remove()
            // above already took effect synchronously.
            var newCurrentTab = -1
            for (var m = 0; m < sustainml_custom_tabview.__tab_model.count; m++)
            {
                if (sustainml_custom_tabview.__tab_model.get(m).stack_id === newCurrentStackId)
                {
                    newCurrentTab = m
                    break
                }
            }
            __current_tab = newCurrentTab

            // stack_layout.children's position can NOT be resolved yet: the removed
            // loader's destroy() (above) is deferred to the next event loop tick, so
            // the array is still its old, longer length right now. Searching and
            // assigning currentIndex immediately can pick an index that's valid now
            // but out of range a moment later once the array actually shrinks - which
            // shows as an empty tab, and only when the surviving target happens to be
            // at (or near) the end of the array, e.g. "viewing the last tab, closing
            // an earlier one". Deferring this lookup until after the shrink avoids it.
            Qt.callLater(function()
            {
                var correctStackIndex = -1
                for (var n = 0; n < stack_layout.children.length; n++)
                {
                    if (stack_layout.children[n].item && stack_layout.children[n].item.stack_id === newCurrentStackId)
                    {
                        correctStackIndex = n
                        break
                    }
                }

                if (correctStackIndex !== -1)
                {
                    stack_layout.currentIndex = correctStackIndex
                }
                else
                {
                    console.log("[__remove_idx] WARNING: could not resolve newCurrentStackId=" + newCurrentStackId + " in stack_layout.children - current tab selection left unchanged")
                }
            })
        }

        tab_list.model = sustainml_custom_tabview.__tab_model
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

                        // Keep each loader's own stack_id/problem_id in sync with the
                        // swap above - previously only __tab_model was updated, so a
                        // loader's .item.stack_id kept pointing at its OLD identity
                        // forever after any reorder, and any later close/focus/rename
                        // looked up by stack_id would silently act on the wrong tab.
                        var problem_src = stack_layout.children[i].item.problem_id
                        var problem_dst = stack_layout.children[j].item.problem_id
                        stack_layout.children[i].item.stack_id = stack_dst
                        stack_layout.children[j].item.stack_id = stack_src
                        stack_layout.children[i].item.problem_id = problem_dst
                        stack_layout.children[j].item.problem_id = problem_src
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

