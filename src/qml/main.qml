// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 1.4
import QtQuick.Controls 2.5 as Controls2
import QtQuick.Layouts 1.15
import QtQml 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "components"
import "screens"

Window {
    id: main_window

    // Properties
    property bool in_use: true
    property string log: "LOG"
    property string app_requirements_node_last_status: "INACTIVE"
    property string carbon_footprint_node_last_status: "INACTIVE"
    property string hw_constraints_node_last_status: "INACTIVE"
    property string hw_resources_node_last_status: "INACTIVE"
    property string ml_model_node_last_status: "INACTIVE"
    property string ml_model_metadata_node_last_status: "INACTIVE"
    property int current_problem_id: -1
    property int current_iteration_id: -1

    property string dataset_description: ""
    property string dataset_topic: ""

    property string dataset_profile: ""
    property string dataset_keywords: ""
    property string dataset_applications: ""
    property var modality_list: []
    property var goal_list: []
    property var hardware_list: []
    property var metrics_list: []
    property var model_list: []
    property bool refreshing: false
    property bool tasking: false
    property bool initializing: true

    property var _screenInst: ({})
    property var unetInfoMap: ({})

    property var hf_models_list: []
    property string hf_query_text: ""
    property var hf_tooltip_cache: ({})
    property bool hoverArmed: false
    property string lastRequested: ""

    property string hf_selected_goal: ""
    property var hf_hover_anchor: ({ x: 0, y: 0, h: 0 })
    property bool hf_tip_locked: false   // Set true while leaving HF screen

    // HF compare selection state
    property var hf_selected_ids: []               // Array of model_id strings
    property int maxCompareModels: 5               // Maximum number of models to compare
    property var hf_compare_obj: null
    property var hf_compare_last_request_ids: []   // Frozen ids for the last compare request
    property var hf_compare_history: []            // Saved comparisons
    property int hf_compare_history_max: 10        // Maximum number of saved comparisons

    Timer {
        id: hfHoverDebounce
        interval: 250
        repeat: false
        onTriggered: {
            if (!main_window.hoverArmed) return

            var id = main_window.lastRequested
            if (!id) return

            var cached = main_window.hf_tooltip_cache[id]

            // Only request if not cached and not pending
            if (cached === undefined) {
                var newCache = Object.assign({}, main_window.hf_tooltip_cache)
                newCache[id] = "__PENDING__"
                main_window.hf_tooltip_cache = newCache

                engine.request_hf_model_tooltip(id)
            }
        }
    }

    // Main view properties
    width:  Settings.app_width
    height: Settings.app_height
    visible: true
    title:  Settings.app_name

    Connections
    {
        target: engine
        function onTask_sent(problem_id, iteration_id)
        {
            main_window.current_problem_id = problem_id
            main_window.current_iteration_id = iteration_id
            main_window.tasking = true
            main_window.load_screen(ScreenManager.Screens.Results)
        }

        function onUpdate_log(new_log)
        {
            main_window.log = main_window.log + "\n" + new_log
        }

        function onUpdate_app_requirements_node_status(new_status)
        {
            main_window.app_requirements_node_last_status = new_status
        }

        function onUpdate_carbon_footprint_node_status(new_status)
        {
            main_window.carbon_footprint_node_last_status = new_status
        }

        function onUpdate_hw_constraints_node_status(new_status)
        {
            main_window.hw_constraints_node_last_status = new_status
        }

        function onUpdate_hw_resources_node_status(new_status)
        {
            main_window.hw_resources_node_last_status = new_status
        }

        function onUpdate_ml_model_node_status(new_status)
        {
            main_window.ml_model_node_last_status = new_status
        }

        function onUpdate_ml_model_metadata_node_status(new_status)
        {
            main_window.ml_model_metadata_node_last_status = new_status
        }

        function onRefreshing_on()
        {
            main_window.refreshing = true
        }

        function onInitializing_off()
        {
            main_window.initializing = false
        }

        function onModalities_available(list_modalities, list_goals)
        {
            main_window.modality_list = ["(empty)"].concat(list_modalities)
            main_window.goal_list = ["(empty)"].concat(list_goals)
            main_window.refreshing = false
        }

        function onDataset_metadata_available(dataset_metadata)
        {
            main_window.dataset_description = dataset_metadata.description ?? ""
            main_window.dataset_topic = dataset_metadata.topic ?? ""
            main_window.dataset_keywords = dataset_metadata.keywords.join(", ") ?? ""
            main_window.dataset_applications = dataset_metadata.applications.join(", ") ?? ""
            main_window.dataset_profile = dataset_metadata.profile ?? ""
            main_window.load_screen(ScreenManager.Screens.Definition)
            main_window.refreshing = false
            main_window.tasking = false

        }

        function onGoals_available(list_goals)
        {
            main_window.goal_list = ["(empty)"].concat(list_goals)
            main_window.refreshing = false
        }

        function onHardwares_available(list_hardwares)
        {
            main_window.hardware_list = ["(empty)"].concat(list_hardwares)
            main_window.refreshing = false
        }

        function onMetrics_available(list_metrics)
        {
            main_window.metrics_list = list_metrics
            main_window.refreshing = false
        }

        function onModels_available(list_models)
        {
            main_window.model_list = list_models || []
            main_window.refreshing = false
        }

        function onTask_end()
        {
            main_window.tasking = false
        }

        function onHf_models_available(models)
        {
            // Force a fresh JS array so Repeater definitely rebuilds
            var arr = []
            if (models) {
                for (var i = 0; i < models.length; ++i)
                    arr.push(models[i])
            }
            main_window.hf_models_list = arr
            main_window.refreshing = false
        }

        function onHf_models_error(message)
        {
            main_window.refreshing = false
            console.log("[HF] onHf_models_error message=", message, "query=", main_window.hf_query_text)
        }

        function onHf_model_tooltip_available(model_id, tooltip) {
            var base = ""
            // Find base tooltip from hf_models_list entry for that model_id
            for (var i = 0; i < main_window.hf_models_list.length; ++i) {
                var m = main_window.hf_models_list[i]
                var id = (typeof m === "object" && m) ? (m["model_id"] || m["id"] || m["modelId"]) : m
                if (id === model_id) {
                    if (typeof m === "object" && m["tooltip"])
                        base = m["tooltip"]
                    break
                }
            }

            var combined = base
            if (tooltip && tooltip !== model_id) {
                if (combined !== "")
                    combined += "\n\n"
                combined += tooltip
            }

            var cache = Object.assign({}, main_window.hf_tooltip_cache)
            cache[model_id] = combined !== "" ? combined : tooltip
            main_window.hf_tooltip_cache = cache

            // Only show tooltip if still on HF screen and still hovering the same model
            if (ScreenManager.current_screen === ScreenManager.Screens.HFsearch &&
                main_window.lastRequested === model_id &&
                !main_window.hf_tip_locked) {

                hfTip.showNearAnchor(cache[model_id])
            }
        }

        function onHf_models_info_available(models) {
            engine.request_hf_models_compare(models)
        }

        function onHf_models_compare_available(reportObj) {
            main_window.hf_compare_obj = reportObj || ({})

            // Save using frozen ids
            main_window.hf_save_compare(main_window.hf_compare_last_request_ids, main_window.hf_compare_obj)
        }

        function onHf_models_compare_error(message) {
            main_window.hf_compare_obj = ({})             // Clear stale content
        }
    }

    Rectangle {
        id: hfTip
        visible: false
        z: 99999
        radius: 8
        color: "white"
        border.color: Settings.app_color_green_4
        border.width: 1
        clip: true

        width: Math.min(main_window.width * 0.55, 560)
        height: Math.min(300, hfTipText.paintedHeight + 20)

        Text {
            id: hfTipText
            anchors.fill: parent
            anchors.margins: 10
            wrapMode: Text.WordWrap
            color: Settings.app_color_green_1
            text: ""
        }

        function hide() {
            visible = false
            hfTipText.text = ""
        }

        function showNearAnchor(txt) {
            if (main_window.hf_tip_locked) return
            hfTipText.text = txt || ""
            if (!hfTipText.text) { hide(); return }

            var a = main_window.hf_hover_anchor
            var margin = 8

            // Prefer below, if not feasible then above
            var yBelow = a.y + a.h + margin
            var yAbove = a.y - hfTip.height - margin
            var y = yBelow
            if (yBelow + hfTip.height > main_window.height && yAbove >= 0) y = yAbove

            var x = a.x
            x = Math.max(margin, Math.min(x, main_window.width - hfTip.width - margin))
            y = Math.max(margin, Math.min(y, main_window.height - hfTip.height - margin))

            hfTip.x = x
            hfTip.y = y
            hfTip.visible = true
        }
    }

    function stop_hf_tooltip() {
        hfTip.hide()
        hoverArmed = false
        hfHoverDebounce.stop()
        lastRequested = ""
    }

    function clear_hf_models() {
        main_window.hf_models_list = []
        main_window.hf_query_text = ""
        main_window.hf_tooltip_cache = ({})
        main_window.hf_selected_ids = []
        stop_hf_tooltip()
    }

    // Load JSONL file with per-model info
    function loadUnetInfo() {
        var url = engine.unet_models_info_url()
        if (!url)
            return
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var txt = xhr.responseText || ""
                var lines = txt.split("\n")
                var map = {}

                for (var i = 0; i < lines.length; ++i) {
                    var line = lines[i].trim()
                    if (!line)
                        continue
                    try {
                        var obj = JSON.parse(line)
                        var file = obj.model_file || ""
                        if (!file.endsWith(".onnx"))
                            continue
                        var name = file.substring(0, file.length - 5)   // "unet_model_000"
                        map[name] = obj
                    } catch (e) {
                        console.log("[UnetInfo] JSON parse error on line", i, e)
                    }
                }

                unetInfoMap = map
            }
        }

        xhr.send()
    }

    // Build human-readable description for each model
    function getUnetDescription(modelName) {
        if (!modelName || !unetInfoMap || !unetInfoMap[modelName])
            return ""

        var info = unetInfoMap[modelName]

        var ks = info.kernel_sizes ? info.kernel_sizes.join("–") : "n/a"
        var size = info.input_size || "?"
        var ch   = info.input_channels || "?"
        var depth = info.depth || "?"
        var initCh = info.initial_channels || "?"
        var flops = info.Mflops !== undefined ? info.Mflops.toFixed(1) : "?"
        var params = info.Mparams !== undefined ? info.Mparams.toFixed(3) : "?"

        return "Input " + size + "×" + size + " with " + ch + " channels; " +
            "depth " + depth + ", initial " + initCh + " feature channels; " +
            "kernel sizes [" + ks + "]; " +
            flops + " MFLOPs, " + params + " M parameters."
    }

    function open_hf_analyze(modelObj) {
        if (!modelObj) return

        main_window.hf_tip_locked = true
        stop_hf_tooltip()

        // Extract HF id
        var id = ""
        if (typeof modelObj === "string") id = modelObj
        else id = modelObj["model_id"] || modelObj["id"] || modelObj["modelId"] || ""

        if (!id) return

        // Save selected goal/task from the HF card (no backend import needed)
        if (typeof modelObj === "object" && modelObj) {
            main_window.hf_selected_goal =
                modelObj["pipeline_tag"] || modelObj["task"] || modelObj["tag"] || ""
        } else {
            main_window.hf_selected_goal = ""
        }

        // Grab current values from Definition screen instance
        var def = _screenInst[ScreenManager.Screens.Definition]
        if (!def) {
            console.log("[HF][Analyze] No Definition screen instance found")
            return
        }

        main_window.tasking = true

        var extra = def.__extra_data || ""
        var extraObj = {}
        try { extraObj = extra ? JSON.parse(extra) : {} } catch(e) { extraObj = {} }
        extraObj["model_restrains"] = [id]
        var extraJson = JSON.stringify(extraObj)

        engine.launch_task(
            def.__problem_short_description,
            def.__modality,
            def.__metric,
            def.__problem_definition,
            def.__inputs,
            def.__outputs,
            def.__dataset_metadata_description,
            def.__dataset_metadata_topic,
            def.__dataset_metadata_profile,
            def.__dataset_metadata_keywords,
            def.__dataset_metadata_applications,
            def.__minimum_samples,
            def.__maximum_samples,
            def.__optimize_carbon_footprint_auto,
            main_window.hf_selected_goal,
            def.__optimize_carbon_footprint_manual,
            def.__previous_iteration,
            def.__desired_carbon_footprint,
            def.__max_memory_footprint,
            def.__hardware_required,
            def.__geo_location_continent,
            def.__geo_location_region,
            extraJson,
            def.__previous_problem_id,
            def.__num_outputs,
            id,
            def.__type
        )

        def.results_available = true

        // Go to Results like normal flow
        main_window.load_screen(ScreenManager.Screens.Results)
    }

    function hf_is_selected(id) {
        if (!id) return false
        for (var i = 0; i < hf_selected_ids.length; ++i)
            if (hf_selected_ids[i] === id) return true
        return false
    }

    function hf_set_selected(id, on) {

        var arr = hf_selected_ids.slice(0)
        var idx = -1
        for (var i = 0; i < arr.length; ++i) {
            if (arr[i] === id) { idx = i; break }
        }

        if (on) {
            if (idx === -1) arr.push(id)
        } else {
            if (idx !== -1) arr.splice(idx, 1)
        }

        hf_selected_ids = arr
    }

    function hf_save_compare(ids, obj) {
        if (!obj || !ids || ids.length < 2) return

        var entry = {
            ts: Date.now(),
            ids: ids.slice(0),
            obj: obj
        }

        var arr = hf_compare_history.slice(0)
        arr.unshift(entry)

        if (arr.length > hf_compare_history_max)
            arr = arr.slice(0, hf_compare_history_max)

        hf_compare_history = arr
        console.log("[HF][HISTORY] saved. count=", hf_compare_history.length)
    }

    function hf_load_saved_compare(index) {
        if (index < 0 || index >= hf_compare_history.length) return
        var e = hf_compare_history[index]
        hf_selected_ids = e.ids.slice(0)
        hf_compare_obj = e.obj
        console.log("[HF][HISTORY] loaded index=", index, "models=", hf_selected_ids.length)
    }

    // Background
    Rectangle
    {
        color: ScreenManager.background_color

        // Set background size two times the app size
        width:  2 * Settings.app_width
        height: 2 * Settings.app_height

        // Initial position
        x: 0
        y: 0

        // Background shape image
        Image
        {
            id: background
            source: ScreenManager.background_shape

            // Set image size two times the app size
            width:  2 * Settings.app_width
            height: 2 * Settings.app_height

            // Initial position
            x: Settings.background_x_initial
            y: 0

            // Image smoothness
            sourceSize.width: Settings.app_width
            sourceSize.height: Settings.app_height
            smooth: true
            antialiasing: true
        }

        // Background shape image #2
        Image
        {
            id: background_2
            source: ScreenManager.background_2_shape

            // Set image size two times the app size
            width:  2 * Settings.app_width
            height: 2 * Settings.app_height

            // Initial position hidden
            x: 2 * Settings.app_width
            y: 2 * Settings.app_height

            // Image smoothness
            sourceSize.width: Settings.app_width
            sourceSize.height: Settings.app_height
            smooth: true
            antialiasing: true
        }

        // X axis movement motion animation
        NumberAnimation
        {
            id: background_x_animation
            target: background
            properties: "x"
            duration: Settings.background_movement_anim_duration
            to: Settings.app_width
        }

        // Y axis movement motion animation
        NumberAnimation
        {
            id: background_y_animation
            target: background
            properties: "y"
            duration: Settings.background_movement_anim_duration
            to: Settings.app_height
        }

        // X axis movement motion animation #2
        NumberAnimation
        {
            id: background_2_x_animation
            target: background_2
            properties: "x"
            duration: Settings.background_movement_anim_duration
            to: Settings.app_width
        }

        // Y axis movement motion animation #2
        NumberAnimation
        {
            id: background_2_y_animation
            target: background_2
            properties: "y"
            duration: Settings.background_movement_anim_duration
            to: Settings.app_height
        }
    }

    // Screen view
    StackView
    {
        id: stack_view
        anchors.fill: parent
        initialItem: home_screen

        // HOME SCREEN
        Component
        {
            id: home_screen

            SmlHomeScreen
            {
                id: home_screen_component

                onGo_problem_definition: main_window.load_screen(ScreenManager.Screens.Definition)
            }
        }

        // PROBLEM DEFINITION SCREEN
        Component
        {
            id: definition_screen

            SmlProblemDefinitionScreen
            {
                id: definition_screen_component

                // Pass modalities
                __modality_list: main_window.modality_list
                __goal_list: main_window.goal_list
                __hardware_list: main_window.hardware_list
                __metrics: main_window.metrics_list
                __model_list: main_window.model_list
                __dataset_description: main_window.dataset_description
                __dataset_topic: main_window.dataset_topic
                __dataset_profile: main_window.dataset_profile
                __dataset_keywords: main_window.dataset_keywords
                __dataset_applications: main_window.dataset_applications
                __refreshing: main_window.refreshing
                __initializing: main_window.initializing

                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
                onGo_results: main_window.load_screen(ScreenManager.Screens.Results)
                onGo_dataset_path: main_window.load_screen(ScreenManager.Screens.DatasetPath)
                onGo_unet_models: main_window.load_screen(ScreenManager.Screens.UNet)
                onGo_hf_models: main_window.load_screen(ScreenManager.Screens.HFsearch)

                onClear_all_clicked: {
                    // Clear dataset metadata stored in main_window
                    main_window.dataset_description = ""
                    main_window.dataset_topic = ""
                    main_window.dataset_profile = ""
                    main_window.dataset_keywords = ""
                    main_window.dataset_applications = ""

                    // If dataset upload screen already exists, clear its path field too
                    var ds = _screenInst[ScreenManager.Screens.DatasetPath]
                    if (ds) {
                        ds.dataset_path_text = ""
                    }
                }

                onSend_task: {
                    engine.launch_task(
                            problem_short_description,
                            modality,
                            metric,
                            problem_definition,
                            inputs,
                            outputs,
                            dataset_metadata_description,
                            dataset_metadata_topic,
                            dataset_metadata_profile,
                            dataset_metadata_keywords,
                            dataset_metadata_applications,
                            minimum_samples,
                            maximum_samples,
                            optimize_carbon_footprint_auto,
                            goal,
                            optimize_carbon_footprint_manual,
                            previous_iteration,
                            desired_carbon_footprint,
                            max_memory_footprint,
                            hardware_required,
                            geo_location_continent,
                            geo_location_region,
                            extra_data,
                            previous_problem_id,
                            num_outputs,
                            model_selected,
                            type)
                }

                onRefresh: {
                    main_window.refreshing = true
                    engine.request_modalities()
                    // engine.request_goals()
                    engine.request_hardwares()
                }

                onAsk_metrics: {
                    main_window.refreshing = true
                    engine.request_metrics(
                        metric_req_type,
                        req_type_values)
                }

                onAsk_models: {
                    main_window.refreshing = true
                    engine.request_model_from_goal(goal_type)
                }

                onAsk_hf_models: {
                    // Clear previous results immediately so the HF screen starts empty
                    main_window.hf_models_list = []
                    main_window.hf_tooltip_cache = ({})
                    main_window.refreshing = true
                    main_window.hf_query_text = description
                    engine.request_hf_models(description, 10)
                }
            }
        }

        ListModel {
            id: reiterateModel
            ListElement { label: "Previous Iteration nº"; value: "X" }
            ListElement { label: "Problem Kind"; value: "X" }
            ListElement { label: "Suggested model"; value: "X" }
            ListElement { label: "Suggested hardware"; value: "X" }
            ListElement { label: "Power consumption [W]"; value: "X" }
            ListElement { label: "Carbon intensity [gCO2/kW]"; value: "X" }
        }

        // DATASET PATH UPLOAD SCREEN
        Component {
            id: dataset_path_upload_screen

            SmlLoadDatasetScreen {
                id: dataset_path_upload_screen_component

                tasking: main_window.tasking

                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
                onGo_back: main_window.load_screen(ScreenManager.Screens.Definition)
                onSend_dataset_path_task: {
                    main_window.tasking = true
                }
            }
        }

        // PROBLEM REITERATION SCREEN
        Component {
            id: reiterate_screen

            Rectangle {
                width: parent.width
                height: parent.height
                color: "transparent"

                SplitView {
                    anchors.fill: parent
                    orientation: Qt.Horizontal

                    SmlProblemDefinitionScreen {
                        id: definition_screen_component
                        Layout.minimumWidth: parent.width * 0.70
                        Layout.maximumWidth: parent.width * 0.78
                        Layout.preferredWidth: parent.width * 0.75
                        Layout.fillHeight: true

                        __modality_list: main_window.modality_list
                        __goal_list: main_window.goal_list
                        __hardware_list: main_window.hardware_list
                        __model_list: main_window.model_list
                        __metrics: main_window.metrics_list
                        __refreshing: main_window.refreshing
                        __initializing: main_window.initializing
                        __reiterate: true
                        __model_selected: reiterateModel.get(2).value
                        __hardware_required: reiterateModel.get(3).value

                        onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
                        onGo_results: main_window.load_screen(ScreenManager.Screens.Results)
                        onGo_unet_models: main_window.load_screen(ScreenManager.Screens.UNet)
                        onSend_task: {
                            engine.launch_task(
                                problem_short_description,
                                modality,
                                metric,
                                problem_definition,
                                inputs,
                                outputs,
                                dataset_metadata_description,
                                dataset_metadata_topic,
                                dataset_metadata_profile,
                                dataset_metadata_keywords,
                                dataset_metadata_applications,
                                minimum_samples,
                                maximum_samples,
                                optimize_carbon_footprint_auto,
                                goal,
                                optimize_carbon_footprint_manual,
                                previous_iteration,
                                desired_carbon_footprint,
                                max_memory_footprint,
                                hardware_required,
                                geo_location_continent,
                                geo_location_region,
                                extra_data,
                                previous_problem_id,
                                num_outputs,
                                model_selected,
                                type)
                        }
                        onRefresh: {
                            main_window.refreshing = true
                            engine.request_modalities()
                            // engine.request_goals()
                            engine.request_hardwares()
                        }
                        onAsk_metrics: {
                            main_window.refreshing = true
                            engine.request_metrics(
                                metric_req_type,
                                req_type_values)
                        }
                    }

                    Rectangle {
                        Layout.minimumWidth: parent.width * 0.22
                        Layout.maximumWidth: parent.width * 0.30
                        Layout.preferredWidth: parent.width * 0.25
                        Layout.fillHeight: true
                        color: "transparent"

                        Column {
                            anchors.fill: parent
                            spacing: 10
                            padding: 20

                            SmlText {
                                text_kind: SmlText.TextKind.Header_3
                                text_value: "Previous Results"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Rectangle {
                                anchors.topMargin: Settings.spacing_normal
                                width: parent.width * 0.9
                                height: 1
                                color: "black"
                            }

                            // Item list for the results
                            Repeater {
                                model: reiterateModel
                                delegate: Row {
                                    width: parent.width * 0.9
                                    spacing: 10

                                    Text {
                                        text: label + ":"
                                        font.pixelSize: 13
                                        width: parent.width * 0.6
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: value
                                        font.pixelSize: 13
                                        color: "green"
                                        width: parent.width * 0.35
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // RESULTS SCREEN
        Component
        {
            id: results_screen

            SmlResultsScreen
            {
                id: results_screen_component
                current_problem_id: 1
                tasking: main_window.tasking
                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
                onGo_back_empty_input: {
                    var defInstance = _screenInst[ScreenManager.Screens.Definition];
                    if (defInstance !== undefined) {
                        defInstance.__problem_short_description = "";
                        defInstance.__modality = "";
                        defInstance.__metric = "";
                        defInstance.__problem_definition = "";
                        defInstance.__inputs = "";
                        defInstance.__outputs = "";
                        defInstance.__minimum_samples = 1;
                        defInstance.__maximum_samples = 1;
                        defInstance.__optimize_carbon_footprint_auto = false;
                        defInstance.__goal = "";
                        defInstance.__types = defInstance.__types;
                        defInstance.__optimize_carbon_footprint_manual = false;
                        defInstance.__previous_iteration = 0;
                        defInstance.__desired_carbon_footprint = 0.0;
                        defInstance.__max_memory_footprint = 0;
                        // defInstance.__hardware_required = "PIM-AI-1chip";
                        defInstance.__geo_location_continent = "";
                        defInstance.__geo_location_region = "";
                        defInstance.__extra_data = "";
                        defInstance.__previous_problem_id = 0;
                        defInstance.__num_outputs = 1;
                        defInstance.__model_selected = "";
                        defInstance.__model_selected_copy = "";
                    }
                    main_window.load_screen(ScreenManager.Screens.Definition)
                }
                onGo_back_previous_input: {
                    engine.request_orchestrator(parseInt(main_window.current_problem_id), 1, false)
                    main_window.load_screen(ScreenManager.Screens.Definition)
                }
                onResults_screen_loaded: {
                    results_screen_component.current_problem_id = main_window.current_problem_id
                    engine.request_current_data(true)
                }
            }
        }

        // LOG SCREEN
        Component
        {
            id: log_screen

            SmlSettingsScreen
            {
                id: log_screen_component

                log: main_window.log
                app: main_window.app_requirements_node_last_status
                carbon: main_window.carbon_footprint_node_last_status
                hw_constraints: main_window.hw_constraints_node_last_status
                hw_resources: main_window.hw_resources_node_last_status
                model: main_window.ml_model_node_last_status
                metadata: main_window.ml_model_metadata_node_last_status

                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
            }
        }

        // New empty screen 1 TO BE USED
        Component
        {
            id: new_screen_1_todo_rename

            Rectangle
            {
                color: "transparent"
                SmlText
                {
                    text_value: "this is a new screen #1"
                    text_kind: SmlText.TextKind.Body

                    anchors.centerIn: parent
                }
            }
        }

        // U-Net / CNN models screen
        Component
        {
            id: uNet_screen
            Rectangle
            {
                color: "transparent"
                Component.onCompleted: {
                    loadUnetInfo()
                }

                // HOME BUTTON
                SmlButton
                {
                    id: unet_go_home_button
                    icon_name: Settings.home_icon_name
                    text_kind: SmlText.TextKind.Header_2
                    text_value: "Home"
                    rounded: true
                    color: Settings.app_color_green_4
                    color_pressed: Settings.app_color_green_1
                    color_text: Settings.app_color_green_3
                    nightmode_color: Settings.app_color_green_2
                    nightmode_color_pressed: Settings.app_color_green_3
                    nightmode_color_text: Settings.app_color_green_1
                    tooltip_text: "Go to Home screen"
                    anchors {
                        top: parent.top
                        topMargin: Settings.spacing_normal
                        left: parent.left
                        leftMargin: Settings.spacing_normal
                    }
                    onClicked: main_window.load_screen(ScreenManager.Screens.Home)
                }

                // BACK ARROW
                SmlButton
                {
                    id: unet_go_back_button
                    icon_name: Settings.back_icon_name
                    text_kind: SmlText.TextKind.Header_2
                    text_value: ""
                    rounded: true
                    color: Settings.app_color_green_4
                    color_pressed: Settings.app_color_green_1
                    color_text: Settings.app_color_green_3
                    nightmode_color: Settings.app_color_green_2
                    nightmode_color_pressed: Settings.app_color_green_3
                    nightmode_color_text: Settings.app_color_green_1
                    tooltip_text: "Go to Problem Definition screen"
                    anchors {
                        top: unet_go_home_button.top
                        left: unet_go_home_button.right
                        leftMargin: Settings.spacing_small
                    }
                    onClicked: main_window.load_screen(ScreenManager.Screens.Definition)
                }

                // MAIN CONTENT – two columns with shared vertical scroll
                Rectangle {
                    id: unet_content
                    color: "transparent"
                    anchors {
                        top: unet_go_back_button.bottom
                        topMargin: Settings.spacing_big * 2
                        left: parent.left
                        leftMargin: Settings.spacing_big
                        right: parent.right
                        rightMargin: Settings.spacing_big
                        bottom: parent.bottom
                        bottomMargin: Settings.spacing_big * 2
                    }

                    // White card with green border
                    Rectangle {
                        id: tableFrame
                        anchors.fill: parent
                        anchors.margins: Settings.spacing_big
                        radius: 18
                        color: "white"
                        border.color: Settings.app_color_green_4
                        border.width: 2
                        clip: true   // Keep content clipped inside the card

                        // Flickable inside the card – only content scrolls
                        Flickable {
                            id: unetList
                            anchors.fill: parent
                            anchors.margins: Settings.spacing_big
                            clip: true

                            contentWidth: width
                            contentHeight: modelsColumn.implicitHeight + Settings.spacing_big

                            Column {
                                id: modelsColumn
                                width: parent.width
                                spacing: Settings.spacing_small

                                // Header row: model name + description
                                Row {
                                    width: parent.width
                                    spacing: Settings.spacing_big

                                    // Left header: model name
                                    SmlText {
                                        text_kind: SmlText.TextKind.Header_3
                                        text_value: "U-Net model"
                                        color: Settings.app_color_green_4
                                        width: parent.width * 0.2
                                    }

                                    // Right header: description
                                    SmlText {
                                        text_kind: SmlText.TextKind.Header_3
                                        text_value: "Description"
                                        color: Settings.app_color_green_1
                                        width: parent.width * 0.75
                                    }
                                }

                                // One row per model
                                Repeater {
                                    model: main_window.model_list
                                    delegate: Row {
                                        width: parent.width
                                        spacing: Settings.spacing_big

                                        // LEFT COLUMN: model name
                                        Text {
                                            text: modelData
                                            font.pixelSize: 13
                                            color: Settings.app_color_green_4
                                            elide: Text.ElideRight
                                            width: parent.width * 0.2
                                        }

                                        // RIGHT COLUMN: description
                                        Text {
                                            text: getUnetDescription(modelData)
                                            font.pixelSize: 13
                                            color: Settings.app_color_green_1
                                            wrapMode: Text.WordWrap
                                            width: parent.width * 0.75
                                        }
                                    }
                                }
                            }

                            // Scrollbar inside the white card, on the right edge
                            Controls2.ScrollBar.vertical: Controls2.ScrollBar {
                                policy: Controls2.ScrollBar.AlwaysOn
                                width: 8
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                contentItem: Rectangle {
                                    radius: 4
                                    color: Settings.app_color_green_4   // Green handle
                                }
                                background: Rectangle {
                                    color: "transparent"
                                }
                            }
                        }
                    }
                }
            }
        }
        Component
        {
            id: huggingFace_screen
            Rectangle
            {
                color: "transparent"

                // Home
                SmlButton
                {
                    id: hf_go_home_button
                    icon_name: Settings.home_icon_name
                    text_kind: SmlText.TextKind.Header_2
                    text_value: "Home"
                    rounded: true
                    color: Settings.app_color_green_4
                    color_pressed: Settings.app_color_green_1
                    color_text: Settings.app_color_green_3
                    nightmode_color: Settings.app_color_green_2
                    nightmode_color_pressed: Settings.app_color_green_3
                    nightmode_color_text: Settings.app_color_green_1
                    tooltip_text: "Go to Home screen"
                    anchors {
                        top: parent.top
                        topMargin: Settings.spacing_normal
                        left: parent.left
                        leftMargin: Settings.spacing_normal
                    }
                    onClicked: {
                        main_window.clear_hf_models()
                        main_window.load_screen(ScreenManager.Screens.Home)
                    }
                }

                // Back
                SmlButton
                {
                    id: hf_go_back_button
                    icon_name: Settings.back_icon_name
                    text_kind: SmlText.TextKind.Header_2
                    text_value: ""
                    rounded: true
                    color: Settings.app_color_green_4
                    color_pressed: Settings.app_color_green_1
                    color_text: Settings.app_color_green_3
                    nightmode_color: Settings.app_color_green_2
                    nightmode_color_pressed: Settings.app_color_green_3
                    nightmode_color_text: Settings.app_color_green_1
                    tooltip_text: "Back to Problem Definition"
                    anchors {
                        top: hf_go_home_button.top
                        left: hf_go_home_button.right
                        leftMargin: Settings.spacing_small
                    }
                    onClicked: {
                        main_window.clear_hf_models()
                        main_window.load_screen(ScreenManager.Screens.Definition)
                    }
                }

                // Compare (top bar)
                SmlButton {
                    id: hf_go_compare_button
                    z: 100000

                    anchors {
                        top: hf_go_home_button.top
                        left: hf_go_back_button.right
                        leftMargin: Settings.spacing_small
                    }

                    icon_name: ""
                    text_kind: SmlText.TextKind.Header_2
                    text_value: "Compare"
                    rounded: true

                    disabled: main_window.hf_selected_ids.length < 2 || main_window.hf_selected_ids.length > maxCompareModels

                    color: Settings.app_color_green_4
                    color_pressed: Settings.app_color_green_1
                    color_text: Settings.app_color_green_3
                    nightmode_color: Settings.app_color_green_2
                    nightmode_color_pressed: Settings.app_color_green_3
                    nightmode_color_text: Settings.app_color_green_1

                    onClicked: {
                        console.log("[HF][INFO] selection:", main_window.hf_selected_ids)

                        // Freeze ids (so they don't get lost/changed later)
                        main_window.hf_compare_last_request_ids = main_window.hf_selected_ids.slice(0)

                        // Clear current view
                        main_window.hf_compare_obj = ({})

                        engine.request_hf_models_info(main_window.hf_compare_last_request_ids)
                        main_window.load_screen(ScreenManager.Screens.Compare)
                    }
                }

                Rectangle
                {
                    anchors {
                        top: hf_go_back_button.bottom
                        topMargin: Settings.spacing_big * 2
                        left: parent.left
                        leftMargin: Settings.spacing_big
                        right: parent.right
                        rightMargin: Settings.spacing_big
                        bottom: parent.bottom
                        bottomMargin: Settings.spacing_big * 2
                    }
                    radius: 18
                    color: "white"
                    border.color: Settings.app_color_green_4
                    border.width: 2
                    clip: true

                    Column
                    {
                        anchors.fill: parent
                        anchors.margins: Settings.spacing_big
                        spacing: Settings.spacing_small

                        SmlText
                        {
                            text_kind: SmlText.TextKind.Header_2
                            text_value: "Hugging Face suggestions"
                            color: Settings.app_color_green_4
                        }

                        SmlText
                        {
                            text_kind: SmlText.TextKind.Body
                            text_value: main_window.hf_query_text !== "" ? ("Query: " + main_window.hf_query_text) : ""
                            color: Settings.app_color_green_1
                        }

                        Row {
                            id: hfListRow
                            width: parent.width
                            height: parent.height - 120
                            spacing: 10   // Space between list and scrollbar

                            Flickable {
                                id: hfList
                                clip: true
                                width: hfListRow.width - hfScroll.width - hfListRow.spacing
                                height: hfListRow.height

                                contentWidth: width
                                contentHeight: hfColumn.implicitHeight
                                interactive: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: hfColumn
                                    width: parent.width
                                    spacing: Settings.spacing_small

                                    Repeater {
                                        model: main_window.hf_models_list

                                        delegate: Rectangle {
                                            width: hfList.width
                                            radius: 10
                                            border.color: Settings.app_color_green_4
                                            border.width: 1
                                            color: "transparent"
                                            height: 54

                                            property string mid: {
                                                if (typeof modelData === "string")
                                                    return modelData
                                                if (modelData && modelData["model_id"] !== undefined)
                                                    return modelData["model_id"]
                                                if (modelData && modelData["id"] !== undefined)
                                                    return modelData["id"]
                                                if (modelData && modelData["modelId"] !== undefined)
                                                    return modelData["modelId"]
                                                return ""
                                            }

                                            // Click anywhere on the card to open Hugging Face
                                            // (checkbox has its own MouseArea that absorbs clicks)
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (!mid) return
                                                    Qt.openUrlExternally("https://huggingface.co/" + mid)
                                                }
                                            }

                                            HoverHandler {
                                                id: hover
                                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                                                onHoveredChanged: {

                                                    if (!mid) return

                                                    if (!hovered) {
                                                        // Hide tooltip when leaving this model card
                                                        if (!main_window.hf_tip_locked) {
                                                            stop_hf_tooltip()
                                                        }
                                                        return
                                                    }

                                                    // Store anchor position in MAIN WINDOW so backend callback can use it
                                                    var p = parent.mapToItem(main_window.contentItem, 0, 0)
                                                    main_window.hf_hover_anchor = ({ x: p.x, y: p.y, h: parent.height })

                                                    main_window.lastRequested = mid
                                                    main_window.hoverArmed = true

                                                    var t = main_window.hf_tooltip_cache[mid]
                                                    if (t !== undefined && t !== "__PENDING__" && t !== "") {
                                                        hfTip.showNearAnchor(t)
                                                        return
                                                    }

                                                    hfHoverDebounce.restart()
                                                }
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: Settings.spacing_small
                                                spacing: Settings.spacing_big

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                    spacing: 10

                                                    Item {
                                                        width: 26
                                                        height: 26
                                                        Layout.alignment: Qt.AlignVCenter

                                                        Controls2.CheckBox {
                                                            id: hfSelectBox
                                                            anchors.centerIn: parent

                                                            // Avoid re-entrancy when we revert checked state
                                                            property bool _blocking: false

                                                            checked: main_window.hf_is_selected(mid)
                                                            enabled: checked || main_window.hf_selected_ids.length < maxCompareModels

                                                            onCheckedChanged: {
                                                                if (_blocking) return

                                                                // If user tries to CHECK while at max, revert immediately
                                                                if (checked && !main_window.hf_is_selected(mid)
                                                                        && main_window.hf_selected_ids.length >= maxCompareModels) {
                                                                    _blocking = true
                                                                    hfSelectBox.checked = false
                                                                    _blocking = false
                                                                    return
                                                                }

                                                                console.log("[HF][CheckBox] mid=", mid, "checked=", checked)
                                                                main_window.hf_set_selected(mid, checked)
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: function(mouse) {
                                                                mouse.accepted = true
                                                                hfSelectBox.checked = !hfSelectBox.checked
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        text: parent.parent.parent.mid
                                                        font.pixelSize: 14
                                                        color: Settings.app_color_green_4
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }
                                                }

                                                // RIGHT: score
                                                Text {
                                                    text: (typeof modelData === "object" && modelData.score !== undefined) ? ("score " + Number(modelData.score).toFixed(6)) : ""
                                                    font.pixelSize: 12
                                                    color: Settings.app_color_green_1
                                                    horizontalAlignment: Text.AlignRight
                                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                    Layout.preferredWidth: 180
                                                }

                                                // FAR RIGHT: Analyze button
                                                Controls2.Button {
                                                    text: "⚡ Analyze"
                                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                    Layout.preferredWidth: 90
                                                    height: 32

                                                    contentItem: Text {
                                                        text: parent.text
                                                        font.pixelSize: 15
                                                        color: Settings.app_color_light
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                    }

                                                    background: Rectangle {
                                                        radius: 8
                                                        color: Settings.app_color_green_4
                                                    }

                                                    onClicked: main_window.open_hf_analyze(modelData)
                                                }
                                            }
                                        }
                                    }
                                }

                                Controls2.ScrollBar.vertical: hfScroll
                            }

                            Controls2.ScrollBar {
                                id: hfScroll
                                policy: Controls2.ScrollBar.AlwaysOn
                                width: 8
                                height: hfListRow.height

                                contentItem: Rectangle { radius: 4; color: Settings.app_color_green_4 }
                                background: Rectangle { color: "transparent" }
                            }
                        }
                    }
                }
            }
        }

        // HF COMPARE SCREEN
        Component
        {
            id: compare_screen

            Rectangle
            {
                color: "transparent"

                function softHyphenate(s, step) {
                    s = (s === undefined || s === null) ? "" : String(s)
                    // Insert soft hyphen into long runs without spaces
                    var out = ""
                    var run = ""
                    for (var i = 0; i < s.length; ++i) {
                        var ch = s[i]
                        if (ch === " " || ch === "\n" || ch === "\t") {
                            out += breakRun(run, step) + ch
                            run = ""
                        } else {
                            run += ch
                        }
                    }
                    out += breakRun(run, step)
                    return out
                }

                function breakRun(run, step) {
                    if (!run || run.length <= step) return run
                    var res = ""
                    for (var i = 0; i < run.length; i += step) {
                        if (i > 0) res += "\u00AD"   // Soft hyphen
                        res += run.slice(i, i + step)
                    }
                    return res
                }

                // HOME BUTTON
                SmlButton {
                    id: homeBtn
                    icon_name: Settings.home_icon_name
                    text_kind: SmlText.TextKind.Header_2
                    text_value: "Home"
                    rounded: true
                    color: Settings.app_color_green_4
                    color_pressed: Settings.app_color_green_1
                    color_text: Settings.app_color_green_3
                    nightmode_color: Settings.app_color_green_2
                    nightmode_color_pressed: Settings.app_color_green_3
                    nightmode_color_text: Settings.app_color_green_1
                    tooltip_text: "Go to Home screen"
                    anchors {
                        top: parent.top
                        topMargin: Settings.spacing_normal
                        left: parent.left
                        leftMargin: Settings.spacing_normal
                    }
                    onClicked: {
                        main_window.clear_hf_models()
                        main_window.load_screen(ScreenManager.Screens.Home)
                    }
                }

                // BACK BUTTON (to HF list)
                SmlButton {
                    icon_name: Settings.back_icon_name
                    text_kind: SmlText.TextKind.Header_2
                    text_value: ""
                    rounded: true
                    color: Settings.app_color_green_4
                    color_pressed: Settings.app_color_green_1
                    color_text: Settings.app_color_green_3
                    nightmode_color: Settings.app_color_green_2
                    nightmode_color_pressed: Settings.app_color_green_3
                    nightmode_color_text: Settings.app_color_green_1
                    tooltip_text: "Back to Hugging Face list"
                    anchors {
                        top: parent.top
                        topMargin: Settings.spacing_normal
                        left: homeBtn.right
                        leftMargin: Settings.spacing_small
                    }

                    onClicked: {
                        main_window.load_screen(ScreenManager.Screens.HFsearch)
                    }
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        topMargin: Settings.spacing_big * 2 + 40
                        left: parent.left
                        leftMargin: Settings.spacing_big
                        right: parent.right
                        rightMargin: Settings.spacing_big
                        bottom: parent.bottom
                        bottomMargin: Settings.spacing_big * 2
                    }
                    radius: 18
                    color: "white"
                    border.color: Settings.app_color_green_4
                    border.width: 2
                    clip: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: Settings.spacing_big
                        spacing: Settings.spacing_small

                        SmlText {
                            id: titleText
                            text_kind: SmlText.TextKind.Header_2
                            text_value: "Hugging Face model comparison"
                            color: Settings.app_color_green_4
                        }

                        // CONTENT (vertical scroll only)
                        Flickable {
                            id: cmpScroll
                            width: parent.width
                            height: parent.height - titleText.implicitHeight - 10
                            clip: true

                            // Reserve room for the scrollbar so it doesn't overlap table lines
                            property int sbSpace: 12

                            contentWidth: width - sbSpace
                            contentHeight: cmpContent.implicitHeight


                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: cmpContent
                                width: cmpScroll.width - cmpScroll.sbSpace
                                spacing: 18

                                Text {
                                    text: "Saved comparisons"
                                    font.pixelSize: 19
                                    font.bold: true
                                    color: Settings.app_color_green_4
                                    visible: main_window.hf_compare_history.length > 0
                                }

                                Repeater {
                                    model: main_window.hf_compare_history

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 34
                                        radius: 8
                                        border.color: Settings.app_color_green_4
                                        border.width: 1
                                        color: "transparent"

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            width: parent.width - 20
                                            elide: Text.ElideRight
                                            font.pixelSize: 15
                                            color: Settings.app_color_green_1
                                            text: (modelData.ids ? (modelData.ids.length + " models: " + modelData.ids.join(", ")) : "")
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: main_window.hf_load_saved_compare(index)
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Settings.app_color_green_4
                                    visible: main_window.hf_compare_history.length > 0
                                }

                                // Comparison table
                                Text {
                                    text: "Comparison table"
                                    font.pixelSize: 19
                                    font.bold: true
                                    color: Settings.app_color_green_4
                                }

                                // Header row (5 columns)
                                Row {
                                    width: parent.width
                                    spacing: 10

                                    Text {
                                        width: parent.width * 0.34
                                        text: "MODEL"
                                        font.pixelSize: 17
                                        wrapMode: Text.WordWrap
                                        color: Settings.app_color_green_4
                                    }
                                    Text {
                                        width: parent.width * 0.14
                                        text: "LICENSE"
                                        font.pixelSize: 17
                                        wrapMode: Text.WordWrap
                                        color: Settings.app_color_green_4
                                    }
                                    Text {
                                        width: parent.width * 0.14
                                        text: "MODEL FAMILY"
                                        font.pixelSize: 17
                                        wrapMode: Text.WordWrap
                                        color: Settings.app_color_green_4
                                    }
                                    Text {
                                        width: parent.width * 0.14
                                        text: "ARCHITECTURE"
                                        font.pixelSize: 17
                                        wrapMode: Text.WordWrap
                                        color: Settings.app_color_green_4
                                    }
                                    Text {
                                        width: parent.width * 0.2
                                        text: "LANGUAGES"
                                        font.pixelSize: 17
                                        wrapMode: Text.WordWrap
                                        color: Settings.app_color_green_4
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Settings.app_color_green_4 }

                                Repeater {
                                    model: (main_window.hf_compare_obj && main_window.hf_compare_obj.comparison_table)
                                        ? main_window.hf_compare_obj.comparison_table : []

                                    delegate: Row {
                                        width: parent.width
                                        spacing: 10

                                        Text {
                                            width: parent.width * 0.34
                                            text: softHyphenate(modelData.model_id || "", 14)
                                            font.pixelSize: 15
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Settings.app_color_green_1
                                        }

                                        Text {
                                            width: parent.width * 0.14
                                            text: modelData.license || ""
                                            font.pixelSize: 15
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Settings.app_color_green_1
                                        }

                                        Text {
                                            width: parent.width * 0.14
                                            text: modelData.model_family || ""
                                            font.pixelSize: 15
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Settings.app_color_green_1
                                        }

                                        Text {
                                            width: parent.width * 0.14

                                            // Normalize architectures into a string, then soft-hyphenate
                                            text: softHyphenate(
                                                Array.isArray(modelData.architectures)
                                                    ? modelData.architectures.join(", ")
                                                    : (modelData.architectures || ""),
                                                14
                                            )

                                            font.pixelSize: 15
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Settings.app_color_green_1
                                        }

                                        Text {
                                            width: parent.width * 0.2
                                            text: softHyphenate(modelData.languages || "", 14)
                                            font.pixelSize: 15
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Settings.app_color_green_1
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Settings.app_color_green_4 }

                                Repeater {
                                    model: (main_window.hf_compare_obj && main_window.hf_compare_obj.model_cards)
                                        ? main_window.hf_compare_obj.model_cards : []

                                    delegate: Column {
                                        width: parent.width
                                        spacing: 6

                                        Text {
                                            text: (modelData.model_id || "")
                                            font.pixelSize: 17
                                            font.bold: false
                                            wrapMode: Text.NoWrap
                                            color: Settings.app_color_green_4
                                        }

                                        Text {
                                            text: modelData.purpose
                                                ? ("<font color='" + Settings.app_color_green_4 + "'>Purpose:</font> " + modelData.purpose)
                                                : ""
                                            font.pixelSize: 15
                                            wrapMode: Text.NoWrap
                                            color: Settings.app_color_green_1
                                        }

                                        Text {
                                            text: (modelData.best_for && modelData.best_for.length)
                                                ? ("<font color='" + Settings.app_color_green_4 + "'>Best for:</font> " + modelData.best_for.join(", "))
                                                : ""
                                            font.pixelSize: 15
                                            wrapMode: Text.NoWrap
                                            color: Settings.app_color_green_1
                                        }

                                        Text {
                                            text: (modelData.watch_out_for && modelData.watch_out_for.length)
                                                ? ("<font color='" + Settings.app_color_green_4 + "'>Watch out for:</font> " + modelData.watch_out_for.join(", "))
                                                : ""
                                            font.pixelSize: 15
                                            wrapMode: Text.NoWrap
                                            color: Settings.app_color_green_1
                                        }

                                        Rectangle { width: parent.width; height: 1; color: "#E0E0E0" }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Settings.app_color_green_4 }

                                // Comparison summary
                                Text {
                                    text: "Comparison summary"
                                    font.pixelSize: 19
                                    font.bold: true
                                    color: Settings.app_color_green_4
                                }

                                Text {
                                    width: parent.width
                                    text: (main_window.hf_compare_obj && main_window.hf_compare_obj.comparison_summary)
                                        ? main_window.hf_compare_obj.comparison_summary : ""
                                    font.pixelSize: 15
                                    wrapMode: Text.WordWrap
                                    color: Settings.app_color_green_1
                                }
                            }

                            Controls2.ScrollBar.vertical: Controls2.ScrollBar {
                                policy: Controls2.ScrollBar.AlwaysOn
                                width: 8
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                contentItem: Rectangle { radius: 4; color: Settings.app_color_green_4 }
                                background: Rectangle { color: "transparent" }
                            }
                        }
                    }
                }
            }
        }

        // Transition
        delegate: StackViewDelegate {
            function transitionFinished(properties)
            {
                properties.exitItem.opacity = 1
            }

            pushTransition: StackViewTransition
            {
                PropertyAnimation
                {
                    target: enterItem
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Settings.screen_in_opacity_anim_duration
                }
                PropertyAnimation
                {
                    target: exitItem
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Settings.screen_out_opacity_anim_duration
                }
            }
         }
    }

    SmlIcon
    {
        id: settings_icon
        name:   Settings.settings_icon_name
        color:  Settings.app_color_green_1
        color_pressed:  Settings.app_color_green_2
        nightmode_color:  Settings.app_color_green_4
        nightmode_color_pressed:  Settings.app_color_green_3
        size: Settings.button_big_icon_size
        clickable_text: "Go to Node Status screen"

        x: parent.width - (size * 2)
        y: ScreenManager.current_screen === ScreenManager.Screens.Reiterate ?
            main_window.height - 2 * Settings.spacing_big :
            Settings.spacing_big

        onClicked: main_window.load_screen(ScreenManager.Screens.Log);
    }

    // Screen loader plus background animation trigger
    function load_screen(screen)
    {
        var screen_to_be_loaded  = ScreenManager.current_screen // Current screen as default

        // Check if actual change is required
        if (ScreenManager.current_screen !== screen)
        {
            // Always hide tooltip before starting a transition
            stop_hf_tooltip()

            // Allow tooltip only on HF screen
            main_window.hf_tip_locked = (screen !== ScreenManager.Screens.HFsearch)

            // Select actual screen identifier
            switch (screen)
            {
                case ScreenManager.Screens.Definition:
                    screen_to_be_loaded = definition_screen
                    break
                case ScreenManager.Screens.Results:
                    screen_to_be_loaded = results_screen
                    break
                case ScreenManager.Screens.Log:
                    screen_to_be_loaded = log_screen
                    break
                case ScreenManager.Screens.DatasetPath:
                    screen_to_be_loaded = dataset_path_upload_screen
                    break
                // Add new screens here
                case ScreenManager.Screens.Reiterate:
                    screen_to_be_loaded = reiterate_screen
                    break
                case ScreenManager.Screens.UNet:
                    screen_to_be_loaded = uNet_screen
                    break
                case ScreenManager.Screens.HFsearch:
                    screen_to_be_loaded = huggingFace_screen
                    break
                case ScreenManager.Screens.Compare:
                    screen_to_be_loaded = compare_screen
                    break
                default:
                case ScreenManager.Screens.Home:
                    screen_to_be_loaded = home_screen
                    break
            }

            // Force recreation of U-Net screen so Component.onCompleted runs
            if (screen === ScreenManager.Screens.UNet) {
                if (_screenInst[screen]) {
                    _screenInst[screen].destroy();
                }
                _screenInst[screen] = null;
            }

            var inst = _screenInst[screen]
            if (!inst) {
                inst = screen_to_be_loaded.createObject(stack_view, {})
                _screenInst[screen] = inst
            }

            // Select actual screen location
            var position_to_be_moved = main_window.get_movement(screen)

            // Set background animation
            background_x_animation.to = position_to_be_moved[0]
            background_y_animation.to = position_to_be_moved[1]
            background_2_x_animation.to = position_to_be_moved[2]
            background_2_y_animation.to = position_to_be_moved[3]

            // Update current status variables
            ScreenManager.current_screen = screen

            // Run the animations and perform screen change
            stack_view.replace({item: inst, replace: true, destroyOnPop: false})
            background_x_animation.start()
            background_y_animation.start()
            background_2_x_animation.start()
            background_2_y_animation.start()
        }
    }

    // Determine location of each screen
    function get_movement (screen)
    {
        var movement = [0,0,0,0]
        switch (screen)
        {
            case ScreenManager.Screens.Definition:
                movement[0] = Settings.background_x_final
                movement[1] = Settings.background_y_initial
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
            case ScreenManager.Screens.Results:
                movement[0] = Settings.background_x_final
                movement[1] = Settings.background_y_final
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
            case ScreenManager.Screens.DatasetPath:
                movement[0] = Settings.background_x_initial
                movement[1] = Settings.background_y_initial
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
            case ScreenManager.Screens.Log:
                movement[0] = Settings.background_x_initial
                movement[1] = Settings.background_y_final
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
            // Add new screens here
            case ScreenManager.Screens.Reiterate:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_initial
                movement[3] = Settings.background_2_y_initial
                break
            case ScreenManager.Screens.UNet:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_initial
                movement[3] = Settings.background_2_y_final
                break
            case ScreenManager.Screens.HFsearch:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_final
                movement[3] = Settings.background_2_y_initial
                break
            case ScreenManager.Screens.Compare:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_final
                movement[3] = Settings.background_2_y_final
                break
            default:
            case ScreenManager.Screens.Home:
                movement[0] = Settings.background_x_initial
                movement[1] = Settings.background_y_initial
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
        }
        return movement
    }

    // Initiate reiteration of a problem
    function reiterate_problem(problem_id, results)
    {
        reiterateModel.set(0, { label: "Previous Iteration nº", value: String(results["Iteration"]) })
        reiterateModel.set(1, { label: "Problem Kind", value: results["Problem kind"] })
        reiterateModel.set(2, { label: "Suggested model", value: results["Suggested model"] })
        reiterateModel.set(3, { label: "Suggested hardware", value: results["Suggested hardware"] })
        reiterateModel.set(4, { label: "Power consumption [W]", value: results["Power consumption"] })
        reiterateModel.set(5, { label: "Carbon intensity [gCO2/kW]", value: results["Carbon intensity"] })
        engine.request_orchestrator(parseInt(problem_id), parseInt(results["Iteration"]), true)
        var goal_and_tag = String(results["Problem kind"]) + "," + "transformers"
        var goal_only = String(results["Problem kind"])
        var defInstance = _screenInst[ScreenManager.Screens.Definition]
        var fam = (defInstance && defInstance.__types) ? defInstance.__types : "Transformers"
        engine.request_model_from_goal(goal_only + ", " + fam)
        engine.request_model_from_goal(goal_only)
        main_window.refreshing = true
        load_screen(ScreenManager.Screens.Reiterate)
    }
}
