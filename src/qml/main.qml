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
import eProsima.SustainML.Theme 1.0

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
    property var goal_list: []
    property var hardware_list: []
    property var model_list: []
    property bool refreshing: false
    property bool tasking: false
    property bool initializing: true

    property var _screenInst: ({})
    property var unetInfoMap: ({})
    // Real back-navigation history (a stack), not just a single "last screen"
    // slot - a single slot breaks as soon as two screens can reach each other
    // (e.g. Compare <-> Log via the gear icon): going back from either would
    // overwrite the other's remembered origin, causing an infinite A<->B bounce
    // instead of ever reaching further back. go_back() below is the only thing
    // that should ever read/pop this - screens' own Back buttons call it, not
    // load_screen() directly.
    property var screen_history: []

    property var hf_models_list: []
    property var hf_saved_searches: []
    property string hf_query_text: ""
    // Preserve the query used for the most recent HF request until results
    // are saved, so saved entries keep the original query even if the UI
    // clears `hf_query_text` when navigating away.
    property string hf_pending_query: ""
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

    // Add loaded HF searches / comparisons to the current ones
    function hf_merge_searches(hf_searches)
    {
        if (!hf_searches || hf_searches.length === 0)
            return
        var searches = main_window.hf_saved_searches.slice(0)
        for (var i = 0; i < hf_searches.length; ++i)
            searches.push(hf_searches[i])
        main_window.hf_saved_searches = searches
    }

    function hf_merge_comparisons(hf_comparisons)
    {
        if (!hf_comparisons || hf_comparisons.length === 0)
            return
        var comparisons = main_window.hf_compare_history.slice(0)
        for (var j = 0; j < hf_comparisons.length; ++j)
            comparisons.push(hf_comparisons[j])
        if (comparisons.length > main_window.hf_compare_history_max)
            comparisons = comparisons.slice(0, main_window.hf_compare_history_max)
        main_window.hf_compare_history = comparisons
    }
    property int hf_compare_history_max: 10        // Maximum number of saved comparisons
    property int hf_open_compare_index: -1         // Index of the currently open saved comparison (-1 = none open)
    property int hf_renaming_index: -1             // Index of the saved comparison currently being renamed (-1 = none)
    property int hf_renaming_search_index: -1      // Index of the saved search currently being renamed (-1 = none)

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
    // Minimal window size
    minimumWidth: 1050
    minimumHeight: 560
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

        // The LLM-generated "keywords"/"applications" fields are meant to be
        // arrays, but the prompt template describes them as plain quoted
        // strings (like every other field) - so the model (llama3) sometimes
        // returns a string instead of an array for these two, depending on
        // the dataset. array.join(", ") throws on a string (no such method),
        // which used to abort this whole handler mid-way - silently leaving
        // every field below it (and the screen navigation/tasking reset)
        // never applied. Accept either shape instead of assuming one.
        function __to_joined_string(value)
        {
            if (Array.isArray(value))
                return value.join(", ")
            if (typeof value === "string")
                return value
            return ""
        }

        function onDataset_metadata_available(dataset_metadata)
        {
            main_window.dataset_description = dataset_metadata.description ?? ""
            main_window.dataset_topic = dataset_metadata.topic ?? ""
            main_window.dataset_keywords = __to_joined_string(dataset_metadata.keywords)
            main_window.dataset_applications = __to_joined_string(dataset_metadata.applications)
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

        function onModels_available(list_models)
        {
            main_window.model_list = list_models || []
            main_window.unetListContentY = 0    // new list: start from the top
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

            if (arr.length > 0) {
                var entry = {
                    ts: Date.now(),
                    // Prefer the pending query (the original search text) if set
                    // This avoids showing "(no query)" when hf_query_text was
                    // cleared before results arrived.
                    query: main_window.hf_pending_query || main_window.hf_query_text,
                    models: arr,
                    name: ""
                }
                var saved = main_window.hf_saved_searches.slice(0)
                saved.unshift(entry)
                main_window.hf_saved_searches = saved

                // Clear selection on the results screen so user chooses manually
                var hfr = _screenInst[ScreenManager.Screens.HFresults]
                if (hfr) hfr.selectedIndex = -1
                // Clear the pending query now that the results are saved
                main_window.hf_pending_query = ""
            }
        }

        function onHf_models_error(message)
        {
            main_window.refreshing = false
            console.log("[HF] onHf_models_error message=", message, "query=", main_window.hf_query_text)
        }

        // Loaded HF search/comparison history (from engine.load_all()) - merged
        // into the current in-memory lists, same spirit as loaded tasks always
        // appearing as new tabs: nothing already open/shown is replaced or lost.
        function onHf_state_loaded(hf_searches, hf_comparisons)
        {
            main_window.hf_merge_searches(hf_searches)
            main_window.hf_merge_comparisons(hf_comparisons)
        }

        // Only the searches or only the comparisons (from engine.load_hf()), merged the same way
        function onHf_part_loaded(part, data)
        {
            if (part === "searches")
                main_window.hf_merge_searches(data)
            else if (part === "comparisons")
                main_window.hf_merge_comparisons(data)
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
            main_window.hf_open_compare_index = -1
        }
    }

    Rectangle {
        id: hfTip
        visible: false
        z: 99999
        radius: Theme.radiusMd
        color: Theme.overlay
        border.color: Theme.borderStrong
        border.width: 1
        clip: true

        width: Math.min(main_window.width * 0.55, 560)
        height: Math.min(300, hfTipText.paintedHeight + 20)

        Text {
            id: hfTipText
            anchors.fill: parent
            anchors.margins: Theme.space3
            wrapMode: Text.WordWrap
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeBody
            lineHeight: 1.25
            color: Theme.textPrimary
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
        // Static data shipped with the app: load it once (retried only while empty).
        // Reloading on every visit replaced the objects the U-Net graph is bound to,
        // which rebuilt and scrolled the graph screen during the transition back.
        if (Object.keys(unetInfoMap).length > 0)
            return
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

    // U-Net graph screen: one card per opened model, kept here so the cards survive navigation
    property var unetOpenModels: []
    property string unetActiveModel: ""
    // Settings "Save" button is disabled when Settings was opened from the start screen
    property bool settings_save_enabled: true

    // Scroll position of the U-Net models list, restored when coming back to it
    // (that screen is recreated every time it is shown)
    property real unetListContentY: 0

    // Open (or focus) the card of a model and show the U-Net graph screen
    function openUnetGraph(modelName) {
        if (!modelName)
            return
        if (unetOpenModels.indexOf(modelName) < 0)
            unetOpenModels = unetOpenModels.concat([modelName])
        unetActiveModel = modelName
        load_screen(ScreenManager.Screens.UNetGraph)
    }

    function selectUnetCard(modelName) {
        unetActiveModel = modelName
    }

    // Called from a card's own delegate: it must stay the last statement of that handler,
    // because reassigning unetOpenModels destroys the delegate
    function closeUnetCard(modelName) {
        var idx = unetOpenModels.indexOf(modelName)
        if (idx < 0)
            return
        var remaining = unetOpenModels.filter(function(name) { return name !== modelName })
        if (unetActiveModel === modelName)
            unetActiveModel = remaining.length > 0 ? remaining[Math.min(idx, remaining.length - 1)] : ""
        unetOpenModels = remaining
    }

    // Open the architecture visualization of a U-Net model in the system browser
    function openUnetVisualizer(modelName) {
        var models = []
        for (var name in unetInfoMap)
            models.push(unetInfoMap[name])
        if (models.length === 0) {
            console.log("[UnetInfo] Models info not loaded, cannot open visualizer for", modelName)
            return
        }
        var url = engine.write_unet_visualizer(JSON.stringify(models), modelName)
        if (url)
            Qt.openUrlExternally(url)
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
        // Kept with the iteration's inputs, so its info view shows only the problem description
        extraObj["hf_analyze"] = true
        var extraJson = JSON.stringify(extraObj)

        // The HF model is evaluated as a chosen model: once, with no search to optimize
        // (as when a model is selected in the Problem Definition screen)
        engine.launch_task(
            def.__problem_short_description,
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
            false,
            main_window.hf_selected_goal,
            false,
            def.__previous_iteration,
            0.0,
            0,
            def.__hardware_required,
            def.__geo_location_continent,
            def.__geo_location_region,
            extraJson,
            def.__previous_problem_id,
            1,
            id,
            def.__type
        )

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
            obj: obj,
            name: ""
        }

        var arr = hf_compare_history.slice(0)
        arr.unshift(entry)

        if (arr.length > hf_compare_history_max)
            arr = arr.slice(0, hf_compare_history_max)

        hf_compare_history = arr
        // Not auto-opened: nothing is selected by default, the user picks it from the list like any other saved entry
    }

    function hf_load_saved_compare(index) {
        if (index < 0 || index >= hf_compare_history.length) return

        hf_renaming_index = -1     // Discard any unsaved rename in progress elsewhere

        // Clicking the already-open comparison closes it
        if (main_window.hf_open_compare_index === index) {
            hf_open_compare_index = -1
            hf_compare_obj = null
            return
        }

        var e = hf_compare_history[index]
        // Note: deliberately does NOT touch hf_selected_ids - viewing a saved
        // comparison must not leak its models into the checkboxes on the search
        // screen for whatever comparison the user does next.
        hf_compare_obj = e.obj
        hf_open_compare_index = index
    }

    function hf_delete_saved_compare(index) {
        if (index < 0 || index >= hf_compare_history.length) return

        hf_renaming_index = -1     // Discard any unsaved rename in progress elsewhere

        var arr = hf_compare_history.slice(0)
        arr.splice(index, 1)
        hf_compare_history = arr

        if (main_window.hf_open_compare_index === index) {
            hf_open_compare_index = -1
            hf_compare_obj = null
        } else if (main_window.hf_open_compare_index > index) {
            hf_open_compare_index = main_window.hf_open_compare_index - 1
        }
    }

    function hf_rename_saved_compare(index, new_name) {
        if (index < 0 || index >= hf_compare_history.length) return

        var arr = hf_compare_history.slice(0)
        var entry = Object.assign({}, arr[index])
        entry.name = new_name
        arr[index] = entry
        hf_compare_history = arr
    }

    // Reassigning hf_compare_history (inside hf_rename_saved_compare, above) destroys and
    // recreates every Repeater delegate for the saved-comparisons list - including the very
    // row whose TextInput is still running the Keys.onReturnPressed handler that got us here.
    // So this must be the ONE thing that delegate calls: everything it needs (index, the
    // typed name, the old name to compare against) is passed in as arguments - evaluated
    // BEFORE this call runs - and nothing in the delegate's own scope is touched afterward.
    function hf_commit_rename(index, new_name, old_name) {
        if (new_name.length > 0 && new_name !== old_name)
            hf_rename_saved_compare(index, new_name)
        hf_renaming_index = -1
    }

    function hf_delete_saved_search(index) {
        if (index < 0 || index >= hf_saved_searches.length) return

        hf_renaming_search_index = -1     // Discard any unsaved rename in progress elsewhere

        var arr = hf_saved_searches.slice(0)
        arr.splice(index, 1)
        hf_saved_searches = arr

        // Keep the results screen's selection pointing at the same entry (or
        // clear it), the same way hf_delete_saved_compare does for hf_open_compare_index.
        var hfr = _screenInst[ScreenManager.Screens.HFresults]
        if (hfr) {
            if (hfr.selectedIndex === index) {
                hfr.selectedIndex = -1
            } else if (hfr.selectedIndex > index) {
                hfr.selectedIndex = hfr.selectedIndex - 1
            }
        }
    }

    function hf_rename_saved_search(index, new_name) {
        if (index < 0 || index >= hf_saved_searches.length) return

        var arr = hf_saved_searches.slice(0)
        var entry = Object.assign({}, arr[index])
        entry.name = new_name
        arr[index] = entry
        hf_saved_searches = arr
    }

    // Same reasoning as hf_commit_rename above: reassigning hf_saved_searches
    // destroys/recreates every row delegate, including this one mid-handler, so
    // this must be the single call made, with everything it needs passed in.
    function hf_commit_rename_search(index, new_name, old_name) {
        if (new_name.length > 0 && new_name !== old_name)
            hf_rename_saved_search(index, new_name)
        hf_renaming_search_index = -1
    }

    // Background
    Rectangle
    {
        color: Theme.appBackground

        // Set background size two times the app size
        width:  2 * Settings.app_width
        height: 2 * Settings.app_height

        // Laid out for the default window size and scaled to the actual one, so the shapes
        // keep the same composition (the curve flowing down-left) at any window size
        transform: Scale {
            xScale: main_window.width / Settings.app_width
            yScale: main_window.height / Settings.app_height
        }

        // Initial position
        x: 0
        y: 0

        // Background shape image
        Image
        {
            id: background
            source: ScreenManager.background_shape
            opacity: Theme.decorationOpacity
            // Only behind the start screen: every other screen has a uniform background
            visible: opacity > 0 && ScreenManager.current_screen === ScreenManager.Screens.Start

            // Set image size two times the app size
            width:  2 * Settings.app_width
            height: 2 * Settings.app_height

            // Initial position
            x: Settings.background_x_initial
            y: 0

            // Rendered at its on-screen size (after the window scale), so it stays sharp
            sourceSize.width: Math.ceil(width * main_window.width / Settings.app_width)
            sourceSize.height: Math.ceil(height * main_window.height / Settings.app_height)
            smooth: true
            antialiasing: true
        }

        // Background shape image #2
        Image
        {
            id: background_2
            source: ScreenManager.background_2_shape
            opacity: Theme.decorationOpacity
            // Only behind the start screen: every other screen has a uniform background
            visible: opacity > 0 && ScreenManager.current_screen === ScreenManager.Screens.Start

            // Set image size two times the app size
            width:  2 * Settings.app_width
            height: 2 * Settings.app_height

            // Initial position hidden
            x: 2 * Settings.app_width
            y: 2 * Settings.app_height

            // Rendered at its on-screen size (after the window scale), so it stays sharp
            sourceSize.width: Math.ceil(width * main_window.width / Settings.app_width)
            sourceSize.height: Math.ceil(height * main_window.height / Settings.app_height)
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
        // Shown on launch, bypassing load_screen()/its _screenInst cache. Home buttons never
        // lead back to it (load_screen() treats Screens.Home as an alias for Definition), but
        // it has its own Screens.Start identity so Back from the gear (Settings) returns here.
        initialItem: home_screen

        // START SCREEN (shown once, at launch, only)
        Component
        {
            id: home_screen

            SmlHomeScreen
            {
                id: home_screen_component

                // Registers the splash as the current screen, so a screen opened from it
                // (the gear) can come back here instead of to the Definition screen
                Component.onCompleted: ScreenManager.current_screen = ScreenManager.Screens.Start

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

                __goal_list: main_window.goal_list
                __hardware_list: main_window.hardware_list
                __model_list: main_window.model_list
                __dataset_description: main_window.dataset_description
                __dataset_topic: main_window.dataset_topic
                __dataset_profile: main_window.dataset_profile
                __dataset_keywords: main_window.dataset_keywords
                __dataset_applications: main_window.dataset_applications
                __refreshing: main_window.refreshing
                __initializing: main_window.initializing

                onGo_results: main_window.load_screen(ScreenManager.Screens.Results)
                onGo_dataset_path: main_window.load_screen(ScreenManager.Screens.DatasetPath)
                onGo_unet_models: main_window.load_screen(ScreenManager.Screens.UNet)
                hf_results_available: main_window.hf_saved_searches.length > 0
                hf_comparisons_count: main_window.hf_compare_history.length

                onGo_hf_models: main_window.load_screen(ScreenManager.Screens.HFsearch)
                onGo_hf_results: main_window.load_screen(ScreenManager.Screens.HFresults)
                onGo_hf_comparisons: main_window.load_screen(ScreenManager.Screens.Compare)

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

                onDataset_metadata_reiterated: {
                    main_window.dataset_description = description
                    main_window.dataset_topic = topic
                    main_window.dataset_profile = profile
                    main_window.dataset_keywords = keywords
                    main_window.dataset_applications = applications
                }

                onSend_task: {
                    engine.launch_task(
                            problem_short_description,
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

                onAsk_models: {
                    main_window.refreshing = true
                    engine.request_model_from_goal(goal_type)
                }

                onAsk_hf_models: {
                    // Clear previous results immediately so the HF screen starts empty
                    main_window.hf_models_list = []
                    main_window.hf_tooltip_cache = ({})
                    main_window.refreshing = true
                    // Preserve the query in a pending field so it can be used
                    // when saving results even if hf_query_text is cleared.
                    main_window.hf_query_text = description
                    main_window.hf_pending_query = description
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
            ListElement { label: "Carbon footprint [gCO2e]"; value: "X" }
            ListElement { label: "Carbon intensity [gCO2/kW]"; value: "X" }
            ListElement { label: "Memory footprint [MB]"; value: "X" }
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
                    handleDelegate: Rectangle { width: 1; color: Theme.border }

                    SmlProblemDefinitionScreen {
                        id: definition_screen_component
                        Layout.minimumWidth: parent.width * 0.70
                        Layout.maximumWidth: parent.width * 0.78
                        Layout.preferredWidth: parent.width * 0.75
                        Layout.fillHeight: true

                        __initializing: main_window.initializing
                        __reiterate: true

                        onGo_results: main_window.load_screen(ScreenManager.Screens.Results)
                    }

                    Rectangle {
                        Layout.minimumWidth: parent.width * 0.22
                        Layout.maximumWidth: parent.width * 0.30
                        Layout.preferredWidth: parent.width * 0.25
                        Layout.fillHeight: true
                        color: Theme.surface

                        // The panel's part of the screen header, with the settings button at its right end
                        SmlScreenHeader {
                            id: previous_results_header
                            title: "Previous Results"
                        }

                        // Scrolls when the results do not fit the window height
                        Flickable {
                            id: previous_results_flick
                            anchors {
                                top: previous_results_header.bottom
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            contentWidth: width
                            contentHeight: previous_results_column.height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Controls2.ScrollBar.vertical: SmlScrollBar {
                                policy: Controls2.ScrollBar.AsNeeded
                            }

                            Column {
                                id: previous_results_column
                                width: previous_results_flick.width
                                spacing: 0
                                padding: Theme.space5

                                // Item list for the results
                                Repeater {
                                    model: reiterateModel
                                    delegate: Column {
                                        width: parent.width - 2 * Theme.space5
                                        // No problem kind (goal) in a CNN iteration, as in the Results table
                                        visible: !(label === "Problem Kind" && value === "")
                                        topPadding: Theme.space3
                                        bottomPadding: Theme.space3
                                        spacing: 2

                                        Rectangle {
                                            width: parent.width
                                            height: 1
                                            color: Theme.border
                                            visible: index > 0
                                        }

                                        Text {
                                            topPadding: index > 0 ? Theme.space3 : 0
                                            text: label
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeMeta
                                            color: Theme.textMuted
                                            width: parent.width
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            // Empty when not measured (e.g. the memory of a model that failed to load)
                                            text: value !== "" ? value : "-"
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            font.weight: Font.DemiBold
                                            color: Theme.accentText
                                            width: parent.width
                                            wrapMode: Text.WrapAnywhere
                                        }
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
                        defInstance.clear_all();
                    }
                    main_window.load_screen(ScreenManager.Screens.Definition)
                }
                // Back to the screen shown before the results, e.g. the HF search after
                // Analyze; when that is the Problem Definition, it gets the problem's inputs back
                onGo_back_previous_input: {
                    var history = main_window.screen_history
                    var previous = history.length > 0 ? history[history.length - 1] : ScreenManager.Screens.Definition
                    if (previous === ScreenManager.Screens.Definition) {
                        var defInstance = _screenInst[ScreenManager.Screens.Definition];
                        if (defInstance)
                            defInstance.unlock_for_back();
                        engine.request_orchestrator(parseInt(main_window.current_problem_id), 1, false)
                    }
                    main_window.go_back()
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
                hf_saved_searches: main_window.hf_saved_searches
                hf_compare_history: main_window.hf_compare_history
                save_enabled: main_window.settings_save_enabled

                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
                onGo_back: main_window.go_back()
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
                id: unetScreen
                color: "transparent"
                Component.onCompleted: {
                    loadUnetInfo()
                }

                SmlScreenHeader
                {
                    id: unet_header
                    title: "U-Net models"
                    subtitle: "CNN architectures for the FPGA: click a model to open its graph"

                    navigation: [
                        // HOME BUTTON
                        SmlButton
                        {
                            id: unet_go_home_button
                            icon_name: Settings.home_icon_name
                            text_value: "Home"
                            tooltip_text: "Go to Home screen"
                            onClicked: main_window.load_screen(ScreenManager.Screens.Home)
                        },

                        // BACK ARROW
                        SmlIconButton
                        {
                            id: unet_go_back_button
                            outlined: true
                            icon_name: Settings.back_icon_name
                            tooltip_text: "Go to Problem Definition screen"
                            onClicked: main_window.load_screen(ScreenManager.Screens.Definition)
                        }
                    ]

                    actions: [
                        // U-NET GRAPHS: the cards opened so far
                        SmlButton
                        {
                            id: unet_go_graphs_button
                            icon_name: "network"
                            text_value: main_window.unetOpenModels.length > 0
                                        ? "U-Net graphs (" + main_window.unetOpenModels.length + ")" : "U-Net graphs"
                            tooltip_text: main_window.unetOpenModels.length > 0
                                          ? "Go to the U-Net graphs screen (" + main_window.unetOpenModels.length + " open)"
                                          : "Go to the U-Net graphs screen (click a model below to open its graph)"
                            onClicked: main_window.load_screen(ScreenManager.Screens.UNetGraph)
                        }
                    ]
                }

                // MAIN CONTENT – two columns with shared vertical scroll
                SmlCard {
                    id: unet_content
                    anchors {
                        top: unet_header.bottom
                        topMargin: Theme.space5
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: Theme.pagePadding
                    }
                    width: Math.min(parent.width - 2 * Theme.pagePadding, Theme.contentMaxWidth)
                    title: "Available models"
                    subtitle: main_window.model_list.length + " models"
                    icon_name: "network"
                    content_padding: Theme.space2

                    // On the card itself, not in its content area (whose size it would feed back into)
                    SmlEmptyState {
                        parent: unet_content
                        anchors.centerIn: parent
                        visible: main_window.model_list.length === 0
                        title: "No U-Net models yet"
                        hint: "The U-Net models appear here once the framework sends the list."
                    }

                    Item {
                        id: tableFrame
                        anchors.fill: parent
                        clip: true   // Keep content clipped inside the card

                        // Flickable inside the card – only content scrolls
                        Flickable {
                            id: unetList
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            clip: true

                            // Restore the previous scroll position as soon as the rows are laid out
                            // (contentHeight grows after creation), and only start recording after that
                            property bool __restored: false
                            onContentYChanged: if (__restored) main_window.unetListContentY = contentY
                            onContentHeightChanged: __try_restore()
                            Component.onCompleted: {
                                __try_restore()
                                unetListRestoreFallback.start()
                            }
                            function __try_restore() {
                                if (__restored)
                                    return
                                var target = main_window.unetListContentY
                                if (target <= 0) {
                                    __restored = true
                                } else if (contentHeight - height >= target) {
                                    contentY = target
                                    __restored = true
                                }
                            }
                            // List shorter than before: go as far as it allows
                            Timer {
                                id: unetListRestoreFallback
                                interval: 500
                                onTriggered: {
                                    if (!unetList.__restored) {
                                        unetList.contentY = Math.max(0, Math.min(main_window.unetListContentY,
                                                                                 unetList.contentHeight - unetList.height))
                                        unetList.__restored = true
                                    }
                                }
                            }

                            contentWidth: width
                            contentHeight: modelsColumn.implicitHeight + Theme.space2

                            Column {
                                id: modelsColumn
                                width: parent.width - Theme.space3
                                spacing: 2

                                // Header row: model name + description
                                Row {
                                    width: parent.width
                                    spacing: Theme.space5
                                    leftPadding: Theme.space3
                                    bottomPadding: Theme.space2

                                    // Left header: model name
                                    Text {
                                        text: "U-NET MODEL"
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeMicro
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.8
                                        color: Theme.textMuted
                                        width: parent.width * 0.2
                                    }

                                    // Right header: description
                                    Text {
                                        text: "DESCRIPTION"
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeMicro
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.8
                                        color: Theme.textMuted
                                        width: parent.width * 0.75
                                    }
                                }

                                // One row per model, click to open its architecture visualization
                                Repeater {
                                    model: main_window.model_list
                                    delegate: Rectangle {
                                        id: unetRow
                                        width: parent.width
                                        height: unetRowContent.implicitHeight + Theme.space4
                                        radius: Theme.radiusMd
                                        color: unetRowMouse.pressed || unetRow.__flash
                                               ? Theme.accentSubtleStrong
                                               : unetRowMouse.containsMouse ? Theme.accentSubtle
                                               // Transparent green, not "transparent" (black), so the fade never passes through dark gray
                                               : Theme.alpha(Theme.brandGreenBright, 0)
                                        Behavior on color { ColorAnimation { duration: 50 } }

                                        // Keeps the "clicked" color visible briefly, even for a quick click
                                        property bool __flash: false
                                        Timer {
                                            id: unetRowFlashTimer
                                            interval: 100
                                            onTriggered: unetRow.__flash = false
                                        }

                                        Row {
                                            id: unetRowContent
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.space5
                                            leftPadding: Theme.space3

                                            // LEFT COLUMN: model name
                                            Text {
                                                text: modelData
                                                font.family: Theme.monoFontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                font.underline: unetRowMouse.containsMouse
                                                color: Theme.accentText
                                                elide: Text.ElideRight
                                                width: parent.width * 0.2
                                            }

                                            // RIGHT COLUMN: description
                                            Text {
                                                text: getUnetDescription(modelData)
                                                font.family: Theme.uiFontFamily
                                                font.pixelSize: 13
                                                lineHeight: 1.2
                                                color: Theme.textSecondary
                                                wrapMode: Text.WordWrap
                                                width: parent.width * 0.75 - Theme.space3
                                            }
                                        }

                                        MouseArea {
                                            id: unetRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                unetRow.__flash = true
                                                main_window.openUnetGraph(modelData)
                                                unetRowFlashTimer.restart()
                                            }
                                        }

                                        SmlToolTip {
                                            id: unetRowTooltip
                                            visible: unetRowMouse.containsMouse && !unetRowMouse.pressed && !unetRow.__flash
                                            text: "Click to open the architecture graph of " + modelData
                                            delay: 150
                                            x: unetRowMouse.mouseX + 12
                                            y: unetRowMouse.mouseY + 18
                                        }
                                    }
                                }
                            }

                            // Scrollbar on the right edge of the screen
                            Controls2.ScrollBar.vertical: SmlScrollBar {
                                policy: Controls2.ScrollBar.AsNeeded
                                screen_edge: unetScreen
                                track: unetList
                            }
                        }
                    }
                }
            }
        }
        // U-Net graph screen: one card per opened U-Net model with its architecture graph
        Component
        {
            id: uNetGraph_screen
            Rectangle
            {
                id: unetGraphScreen
                color: "transparent"

                readonly property color __card_color: Theme.surface

                // Front-truncated text with literal "..." (as SmlTabView does: the title font's
                // ellipsis glyph renders badly), or nothing when not even that fits
                function __elide_left(str, metrics, avail_width) {
                    if (avail_width <= 0)
                        return ""
                    if (metrics.advanceWidth(str) <= avail_width)
                        return str
                    for (var i = 1; i < str.length; i++) {
                        var candidate = "..." + str.substring(i)
                        if (metrics.advanceWidth(candidate) <= avail_width)
                            return candidate
                    }
                    return ""
                }

                SmlScreenHeader
                {
                    id: unet_graph_header
                    title: "U-Net graphs"
                    subtitle: "Architecture of the opened U-Net models"

                    navigation: [
                        // HOME BUTTON
                        SmlButton
                        {
                            id: unet_graph_home_button
                            icon_name: Settings.home_icon_name
                            text_value: "Home"
                            tooltip_text: "Go to Home screen"
                            onClicked: main_window.load_screen(ScreenManager.Screens.Home)
                        },

                        // BACK ARROW
                        SmlIconButton
                        {
                            id: unet_graph_back_button
                            outlined: true
                            icon_name: Settings.back_icon_name
                            tooltip_text: "Back to U-Net models"
                            onClicked: main_window.go_back()
                        }
                    ]
                }

                // CARDS: one per opened model, styled like the Results screen tabs (SmlTabView)
                ListView {
                    id: unetCards
                    orientation: ListView.Horizontal
                    spacing: 0
                    clip: true
                    interactive: false
                    // Above the content below it, and 1 px taller than the cards, so the active
                    // card covers the content's top border and merges with it
                    z: 1
                    height: 39
                    anchors {
                        top: unet_graph_header.bottom
                        topMargin: Theme.space4
                        left: parent.left
                        leftMargin: Theme.pagePadding
                        right: parent.right
                        rightMargin: Theme.pagePadding
                    }
                    model: main_window.unetOpenModels

                    delegate: Rectangle {
                        id: unetCard
                        required property var modelData
                        required property int index
                        readonly property bool active: unetCard.modelData === main_window.unetActiveModel
                        readonly property bool next_active: main_window.unetOpenModels[unetCard.index + 1] === main_window.unetActiveModel
                        // share the bar like SmlTabView: at most 200 px, narrower as more cards open
                        width: Math.min(200, unetCards.width / Math.max(1, unetCards.count))
                        height: 38
                        radius: Theme.radiusMd
                        color: active ? unetGraphScreen.__card_color : Theme.transparent

                        // square bottom half, so the card joins the content below (covering its border)
                        Rectangle {
                            width: parent.width
                            height: parent.height / 2
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: unetCard.active ? -1 : 0
                            color: parent.color
                        }

                        // Outline of the active card: top and sides only, on top of its fill, reaching
                        // down to the content's border so both outlines meet without a notch
                        Item {
                            visible: unetCard.active
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.height + 1
                            clip: true
                            z: 1
                            Rectangle {
                                anchors { fill: parent; bottomMargin: -2 * radius }
                                radius: unetCard.radius
                                color: Theme.transparent
                                border.width: 1
                                border.color: Theme.borderStrong
                            }
                        }

                        // Frame of an inactive card: lighter card with a visible outline, rounded at the top
                        Item {
                            visible: !unetCard.active
                            anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 3 }
                            clip: true
                            z: -1
                            Rectangle {
                                anchors.fill: parent
                                anchors.bottomMargin: -radius
                                radius: Theme.radiusMd
                                color: unetCardMouse.containsMouse ? Theme.raised : Theme.alpha(Theme.surface, Theme.darkMode ? 0.35 : 0.55)
                                border.width: 1
                                border.color: unetCardMouse.containsMouse ? Theme.brandGreen : Theme.borderStrong
                            }
                        }



                        MouseArea {
                            id: unetCardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: main_window.selectUnetCard(unetCard.modelData)
                        }

                        FontMetrics {
                            id: unetCardMetrics
                            font: unetCardTitle.font
                        }

                        Text {
                            id: unetCardTitle
                            anchors { left: parent.left; leftMargin: Math.min(15, unetCard.width * 0.08)
                                      right: unetCardClose.left; rightMargin: Math.min(15, unetCard.width * 0.08)
                                      verticalCenter: parent.verticalCenter }
                            // keeps the end of the name (the model number) when space is short
                            text: unetGraphScreen.__elide_left(unetCard.modelData, unetCardMetrics, width)
                            clip: true
                            font.family: Theme.monoFontFamily
                            font.weight: unetCard.active ? Font.DemiBold : Font.Normal
                            font.pixelSize: Theme.fontSizeBody
                            color: unetCard.active ? Theme.textPrimary : Theme.textSecondary
                        }

                        SmlIcon {
                            id: unetCardClose
                            anchors { right: parent.right; rightMargin: Math.min(15, unetCard.width * 0.08); verticalCenter: parent.verticalCenter }
                            name: Settings.close_tab_icon_name
                            size: 14
                            variant: Theme.iconMuted

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                // must stay the only statement: it destroys this delegate
                                onClicked: main_window.closeUnetCard(unetCard.modelData)
                            }
                        }
                    }

                    // keep the active card in view
                    Connections {
                        target: main_window
                        function onUnetActiveModelChanged() {
                            var i = main_window.unetOpenModels.indexOf(main_window.unetActiveModel)
                            if (i >= 0)
                                Qt.callLater(function() { unetCards.positionViewAtIndex(i, ListView.Contain) })
                        }
                    }
                    Component.onCompleted: {
                        var i = main_window.unetOpenModels.indexOf(main_window.unetActiveModel)
                        if (i >= 0)
                            positionViewAtIndex(i, ListView.Contain)
                    }
                }

                // CONTENT: graph of the active card (full width, like the Results screen)
                Rectangle {
                    id: unet_graph_content
                    anchors {
                        top: unetCards.bottom
                        topMargin: -1
                        left: parent.left
                        leftMargin: Theme.pagePadding
                        right: parent.right
                        rightMargin: Theme.pagePadding
                        bottom: parent.bottom
                        bottomMargin: Theme.pagePadding
                    }
                    color: unetGraphScreen.__card_color
                    radius: Theme.radiusSm
                    border.width: 1
                    border.color: Theme.borderStrong
                    clip: true

                    // Square top-left corner while the first card is active, so it joins the content cleanly
                    Item {
                        visible: main_window.unetOpenModels.length > 0
                                 && main_window.unetOpenModels[0] === main_window.unetActiveModel
                                 && unetCards.contentX <= unetCards.originX
                        anchors { top: parent.top; left: parent.left }
                        width: parent.radius
                        height: parent.radius
                        Rectangle { anchors.fill: parent; color: parent.parent.color }
                        Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right } height: 1; color: parent.parent.border.color }
                        Rectangle { anchors { top: parent.top; bottom: parent.bottom; left: parent.left } width: 1; color: parent.parent.border.color }
                    }

                    Flickable {
                        id: unetGraphFlick
                        anchors.fill: parent
                        anchors.margins: Settings.spacing_big
                        clip: true
                        visible: main_window.unetActiveModel !== ""
                        contentWidth: width
                        contentHeight: unetGraph.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        SmlUnetGraph {
                            id: unetGraph
                            width: unetGraphFlick.width
                            info: main_window.unetInfoMap[main_window.unetActiveModel] || null
                            onOpen_in_browser: main_window.openUnetVisualizer(model_name)
                        }

                        Controls2.ScrollBar.vertical: SmlScrollBar {
                            policy: unetGraphFlick.contentHeight > unetGraphFlick.height
                                    ? Controls2.ScrollBar.AlwaysOn : Controls2.ScrollBar.AlwaysOff
                            screen_edge: unetGraphScreen
                            track: unet_graph_content
                        }
                    }

                    // A different model starts at the top of its graph
                    Connections {
                        target: main_window
                        function onUnetActiveModelChanged() { unetGraphFlick.contentY = 0 }
                    }

                    // No card open
                    SmlEmptyState {
                        visible: main_window.unetActiveModel === ""
                        anchors.centerIn: parent
                        title: "No U-Net model open"
                        hint: "Go back to the U-Net models list and click a model to open its graph here."
                    }
                }
            }
        }
        Component
        {
            id: huggingFace_screen
            Rectangle
            {
                id: hfScreen
                color: "transparent"

                SmlScreenHeader
                {
                    id: hf_header
                    title: "Hugging Face models"
                    subtitle: "Pre-trained models suggested for the problem description"

                    navigation: [
                        // Home
                        SmlButton
                        {
                            id: hf_go_home_button
                            icon_name: Settings.home_icon_name
                            text_value: "Home"
                            tooltip_text: "Go to Home screen"
                            onClicked: {
                                main_window.refreshing = false
                                main_window.clear_hf_models()
                                main_window.load_screen(ScreenManager.Screens.Home)
                            }
                        },

                        // Back
                        SmlIconButton
                        {
                            id: hf_go_back_button
                            outlined: true
                            icon_name: Settings.back_icon_name
                            tooltip_text: "Back to Problem Definition"
                            onClicked: {
                                main_window.refreshing = false
                                main_window.clear_hf_models()
                                main_window.load_screen(ScreenManager.Screens.Definition)
                            }
                        }
                    ]

                    actions: [
                        SmlChip {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: main_window.hf_selected_ids.length > 0
                            text: main_window.hf_selected_ids.length + " / " + maxCompareModels + " selected"
                            tone: "accent"
                            icon_name: Settings.check_icon_name
                        },

                        // Compare (top bar)
                        SmlButton {
                            id: hf_go_compare_button
                            z: 100000
                            variant: "primary"
                            icon_name: Settings.compare_icon_name
                            text_value: "Compare"
                            tooltip_text: "Compare the selected models (2 to " + maxCompareModels + ")"

                            disabled: main_window.hf_selected_ids.length < 2 || main_window.hf_selected_ids.length > maxCompareModels

                            onClicked: {
                                // Freeze ids (so they don't get lost/changed later)
                                main_window.hf_compare_last_request_ids = main_window.hf_selected_ids.slice(0)

                                // Clear current view: nothing should appear open/selected while the
                                // new comparison is being computed, and the selection must not carry
                                // over into whatever the user picks for their next comparison.
                                main_window.hf_compare_obj = ({})
                                main_window.hf_open_compare_index = -1
                                main_window.hf_selected_ids = []

                                engine.request_hf_models_info(main_window.hf_compare_last_request_ids)
                                main_window.load_screen(ScreenManager.Screens.Compare)
                            }
                        },

                        // Results (top bar)
                        SmlButton {
                            id: hf_go_results_button
                            z: 100000
                            icon_name: Settings.results_icon_name
                            text_value: "Results"
                            tooltip_text: "Saved Hugging Face searches"

                            disabled: main_window.hf_saved_searches.length === 0

                            onClicked: main_window.load_screen(ScreenManager.Screens.HFresults)
                        },

                        // Comparisons (top bar) - browse comparisons already done, without
                        // starting a new one (unlike the "Compare" button above, this never
                        // touches hf_compare_obj/hf_selected_ids). The Compare screen already
                        // shows the hf_compare_history sidebar to pick from - this just adds a
                        // direct path to it. Distinguished from "Compare" by icon (history
                        // clock vs. scale) rather than color.
                        SmlButton {
                            id: hf_go_comparisons_button
                            z: 100000
                            icon_name: Settings.comparisons_icon_name
                            text_value: "Comparisons"
                            tooltip_text: "Saved Hugging Face model comparisons"

                            disabled: main_window.hf_compare_history.length === 0

                            onClicked: main_window.load_screen(ScreenManager.Screens.Compare)
                        }
                    ]
                }

                SmlCard
                {
                    id: hf_card
                    anchors {
                        top: hf_header.bottom
                        topMargin: Theme.space5
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: Theme.pagePadding
                    }
                    width: Math.min(parent.width - 2 * Theme.pagePadding, Theme.contentMaxWidth)
                    title: "Hugging Face suggestions"
                    subtitle: main_window.hf_query_text !== "" ? ("Query: " + main_window.hf_query_text) : ""
                    icon_name: "sparkles"
                    content_padding: Theme.space4

                    // On the card itself, not in its content area (whose size it would feed back into)
                    SmlEmptyState {
                        parent: hf_card
                        anchors.centerIn: parent
                        visible: main_window.hf_models_list.length === 0 && !main_window.refreshing
                        title: "No suggestions yet"
                        hint: "Suggestions for the problem description appear here after a Hugging Face search."
                    }

                    Column
                    {
                        anchors.fill: parent
                        spacing: Theme.space2

                        // Searching: the list below fills in when the results arrive
                        SmlChip {
                            visible: main_window.refreshing
                            text: "Searching Hugging Face..."
                            tone: "accent"
                            pulse: true
                        }

                        Row {
                            id: hfListRow
                            width: parent.width
                            height: parent.height - (main_window.refreshing ? 22 + parent.spacing : 0)
                            spacing: Theme.space2   // Space between list and scrollbar

                            Flickable {
                                id: hfList
                                clip: true
                                width: hfListRow.width
                                height: hfListRow.height

                                contentWidth: width
                                contentHeight: hfColumn.implicitHeight
                                interactive: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: hfColumn
                                    width: parent.width
                                    spacing: Theme.space2

                                    Repeater {
                                        model: main_window.hf_models_list

                                        delegate: Rectangle {
                                            width: hfList.width
                                            radius: Theme.radiusMd
                                            border.color: hover.hovered ? Theme.brandGreen : Theme.border
                                            border.width: 1
                                            color: hover.hovered ? Theme.alpha(Theme.brandGreenBright, 0.08) : Theme.raised
                                            height: 54

                                            property string mid: {
                                                // Wrapped in try/catch: modelData can briefly become unresolvable
                                                // while this delegate is being torn down (e.g. the search results
                                                // list refreshing mid-render) - fall through to "" instead of
                                                // throwing/logging a ReferenceError for that harmless case.
                                                try {
                                                    if (typeof modelData === "string")
                                                        return modelData
                                                    if (modelData && modelData["model_id"] !== undefined)
                                                        return modelData["model_id"]
                                                    if (modelData && modelData["id"] !== undefined)
                                                        return modelData["id"]
                                                    if (modelData && modelData["modelId"] !== undefined)
                                                        return modelData["modelId"]
                                                } catch (e) { }
                                                return ""
                                            }

                                            // Click anywhere on the card to open Hugging Face
                                            // (checkbox has its own MouseArea that absorbs clicks)
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
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
                                                anchors.leftMargin: Theme.space3
                                                anchors.rightMargin: Theme.space3
                                                spacing: Theme.space5

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                    spacing: Theme.space2

                                                    Item {
                                                        width: 26
                                                        height: 26
                                                        Layout.alignment: Qt.AlignVCenter

                                                        SmlCheckBox {
                                                            id: hfSelectBox
                                                            anchors.centerIn: parent

                                                            // Avoid re-entrancy when we programmatically sync/revert checked state
                                                            property bool _blocking: false

                                                            enabled: checked || main_window.hf_selected_ids.length < maxCompareModels

                                                            // Kept in sync with the model imperatively (guarded by _blocking) rather
                                                            // than via a live `checked: main_window.hf_is_selected(mid)` binding -
                                                            // that binding caused a genuine binding loop, since toggling this box
                                                            // calls hf_set_selected() below, which reassigns hf_selected_ids (the
                                                            // same property the binding reads) synchronously, while still inside
                                                            // this box's own checked-change handling.
                                                            function _syncChecked() {
                                                                _blocking = true
                                                                checked = main_window.hf_is_selected(mid)
                                                                _blocking = false
                                                            }

                                                            Component.onCompleted: _syncChecked()

                                                            Connections {
                                                                target: main_window
                                                                function onHf_selected_idsChanged() { hfSelectBox._syncChecked() }
                                                            }

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
                                                        id: modelNameText
                                                        text: mid
                                                        font.family: Theme.uiFontFamily
                                                        font.pixelSize: 14
                                                        font.weight: Font.DemiBold
                                                        // A link to the model's Hugging Face page (the whole card opens it)
                                                        font.underline: true
                                                        color: Theme.accentText
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }
                                                }

                                                // RIGHT: score
                                                Text {
                                                    text: (typeof modelData === "object" && modelData.score !== undefined) ? ("score " + Number(modelData.score).toFixed(6)) : ""
                                                    font.family: Theme.monoFontFamily
                                                    font.pixelSize: 12
                                                    color: Theme.textMuted
                                                    horizontalAlignment: Text.AlignRight
                                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                    Layout.preferredWidth: 180
                                                }

                                                // FAR RIGHT: Analyze button
                                                SmlButton {
                                                    variant: "primary"
                                                    size: "sm"
                                                    icon_name: "zap"
                                                    text_value: "Analyze"
                                                    tooltip_text: "Evaluate this model for the problem"
                                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                                    onClicked: main_window.open_hf_analyze(modelData)
                                                }
                                            }
                                        }
                                    }
                                }

                                Controls2.ScrollBar.vertical: hfScroll
                            }

                            // On the right edge of the screen
                            SmlScrollBar {
                                id: hfScroll
                                policy: Controls2.ScrollBar.AsNeeded
                                screen_edge: hfScreen
                                track: hfList
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
                id: compareScreen
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

                SmlScreenHeader
                {
                    id: compare_header
                    title: "Model comparison"
                    subtitle: "Hugging Face models side by side, and the comparisons saved so far"

                    navigation: [
                        // HOME BUTTON
                        SmlButton {
                            id: homeBtn
                            icon_name: Settings.home_icon_name
                            text_value: "Home"
                            tooltip_text: "Go to Home screen"
                            onClicked: {
                                main_window.clear_hf_models()
                                main_window.load_screen(ScreenManager.Screens.Home)
                            }
                        },

                        // BACK BUTTON (to HF list)
                        SmlIconButton {
                            id: compare_back_button
                            outlined: true
                            icon_name: Settings.back_icon_name
                            tooltip_text: "Go back to previous screen"

                            onClicked: {
                                main_window.go_back()
                            }
                        }
                    ]

                    actions: [
                        // Save / Load only this screen's comparisons (Results: tasks only, Settings: everything)
                        SmlButton {
                            id: compare_save_button
                            z: 100000
                            icon_name: Settings.save_icon_name
                            text_value: "Save"
                            disabled: main_window.hf_compare_history.length === 0
                            tooltip_text: "Save the comparisons into a file"
                            onClicked: compare_save_load_dialogs.open_save()
                        },

                        SmlButton {
                            id: compare_load_button
                            z: 100000
                            icon_name: Settings.load_icon_name
                            text_value: "Load"
                            tooltip_text: "Load comparisons from a file, added to the current ones"
                            onClicked: compare_save_load_dialogs.open_load()
                        }
                    ]
                }

                SmlSaveLoadDialogs
                {
                    id: compare_save_load_dialogs
                    anchors.fill: parent
                    z: 200000
                    save_title: "Save Comparisons"
                    load_title: "Load Comparisons"
                    save_prompt: "Name this save, or pick an existing one below to overwrite its comparisons. Its results and other HF history are kept."
                    no_files_text: "No saved comparisons yet."
                    load_part: "comparisons"
                    onSave_requested: engine.save_hf(name, "comparisons", main_window.hf_compare_history)
                    onLoad_requested: engine.load_hf(name, "comparisons")
                }

                SmlCard {
                    id: compare_card
                    anchors {
                        top: compare_header.bottom
                        topMargin: Theme.space5
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: Theme.pagePadding
                    }
                    width: Math.min(parent.width - 2 * Theme.pagePadding, Theme.contentMaxWidth)
                    title: "Hugging Face model comparison"
                    subtitle: main_window.hf_compare_history.length + " saved comparisons"
                    icon_name: Settings.compare_icon_name
                    content_padding: Theme.space4

                    // Compare clears the shown comparison and keeps the requested models until
                    // the result is saved into hf_compare_history
                    readonly property bool comparing_: main_window.hf_compare_obj !== null
                                                       && Object.keys(main_window.hf_compare_obj).length === 0
                                                       && main_window.hf_compare_last_request_ids.length >= 2

                    actions: [
                        SmlChip {
                            visible: compare_card.comparing_ && main_window.hf_compare_history.length > 0
                            text: "Comparing " + main_window.hf_compare_last_request_ids.length + " models..."
                            tone: "accent"
                            pulse: true
                        }
                    ]

                    // On the card itself, not in its content area (whose size it would feed back into)
                    SmlEmptyState {
                        parent: compare_card
                        anchors.centerIn: parent
                        readonly property bool waiting_: compare_card.comparing_
                        visible: main_window.hf_compare_history.length === 0 && main_window.hf_open_compare_index === -1
                        busy: waiting_
                        title: waiting_ ? "Comparing " + main_window.hf_compare_last_request_ids.length + " models"
                                        : "No comparisons"
                        hint: waiting_ ? main_window.hf_compare_last_request_ids.join(", ") + "\n\nThe comparison appears here as soon as it is ready."
                                       : "Saved comparisons appear here."
                    }

                    // Clicking any blank area of this panel (behind everything else, so any
                    // row/icon/button on top of it still gets the click instead)
                    // discards an in-progress, unsaved rename.
                    MouseArea {
                        parent: compare_card
                        anchors.fill: parent
                        z: -1
                        onClicked: main_window.hf_renaming_index = -1
                    }

                    Column {
                        anchors.fill: parent
                        spacing: Theme.space2

                        // CONTENT (vertical scroll only)
                        Flickable {
                            id: cmpScroll
                            width: parent.width
                            height: parent.height
                            clip: true

                            contentWidth: width
                            contentHeight: cmpContent.implicitHeight


                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: cmpContent
                                width: cmpScroll.width
                                spacing: 18

                                Text {
                                    text: "Saved comparisons"
                                    font.family: Theme.uiFontFamily
                                    font.pixelSize: Theme.fontSizeCardTitle
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                    visible: main_window.hf_compare_history.length > 0
                                }

                                Repeater {
                                    model: main_window.hf_compare_history

                                    delegate: Rectangle {
                                        id: savedCompareRow

                                        // Explicit required properties: Repeater's implicit "index"/"modelData"
                                        // context properties are not reliably resolved from custom property
                                        // bindings or nested item functions under Qt 5.15 - only from bindings
                                        // written directly on a built-in property. Declaring them here makes
                                        // them real properties of this delegate, resolvable everywhere below.
                                        required property int index
                                        required property var modelData

                                        width: parent.width
                                        height: 38
                                        radius: Theme.radiusMd
                                        border.color: isOpen ? Theme.brandGreen : Theme.border
                                        border.width: 1
                                        color: isOpen ? Theme.accentSubtleStrong : Theme.raised

                                        readonly property bool isOpen: savedCompareRow.index === main_window.hf_open_compare_index
                                        readonly property string displayName: (savedCompareRow.modelData.name && savedCompareRow.modelData.name.length > 0)
                                            ? savedCompareRow.modelData.name
                                            : (savedCompareRow.modelData.ids ? (savedCompareRow.modelData.ids.length + " models: " + savedCompareRow.modelData.ids.join(", ")) : "")

                                        Text {
                                            id: savedCompareLabel
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.right: renameIcon.left
                                            anchors.rightMargin: 8
                                            elide: Text.ElideRight
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            font.weight: savedCompareRow.isOpen ? Font.DemiBold : Font.Normal
                                            color: Theme.textPrimary
                                            text: savedCompareRow.displayName
                                            visible: !renameField.visible
                                        }

                                        TextInput {
                                            id: renameField

                                            // Visibility is driven by shared main_window state (not a local
                                            // flag) so that any other action in the screen - opening another
                                            // row, clicking a blank area, deleting, navigating away - can
                                            // reliably dismiss it. A local "visible: false" default plus
                                            // focus-loss detection is not enough: clicking a plain Text/
                                            // Rectangle with no MouseArea, or clicking another row's own
                                            // (unrelated) MouseArea, never changes this TextInput's focus,
                                            // so onFocusChanged would never fire and the field would be
                                            // stuck open with the unsaved edit still showing.
                                            visible: main_window.hf_renaming_index === savedCompareRow.index

                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.right: renameIcon.left
                                            anchors.rightMargin: 8
                                            clip: true
                                            selectByMouse: true
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            color: Theme.textPrimary
                                            selectionColor: Theme.accentSubtleStrong
                                            selectedTextColor: Theme.textPrimary

                                            // Renaming (hf_commit_rename) reassigns hf_compare_history, which
                                            // destroys and recreates every row's delegate - including this one,
                                            // mid-handler. So the handler must be a SINGLE call passing everything
                                            // it needs as arguments (evaluated up front), with nothing of this
                                            // delegate's own scope touched afterward - a second statement here
                                            // (e.g. a separate "...hf_renaming_index = -1" line after the call)
                                            // would run against an already-destroyed delegate and throw.
                                            // Only Enter applies the new name; anything else (click away, Escape) discards the edit and keeps the previous name.
                                            Keys.onReturnPressed: main_window.hf_commit_rename(savedCompareRow.index, text.trim(), savedCompareRow.displayName)
                                            Keys.onEnterPressed: main_window.hf_commit_rename(savedCompareRow.index, text.trim(), savedCompareRow.displayName)
                                            Keys.onEscapePressed: main_window.hf_renaming_index = -1
                                            onFocusChanged: if (!focus && visible) main_window.hf_renaming_index = -1
                                        }

                                        SmlIcon {
                                            id: renameIcon
                                            name: Settings.rename_icon_name
                                            size: 16
                                            variant: Theme.iconMuted
                                            clickable_text: "Rename"
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: deleteIcon.left
                                            anchors.rightMargin: 6
                                            onClicked: {
                                                renameField.text = savedCompareRow.displayName
                                                main_window.hf_renaming_index = savedCompareRow.index
                                                renameField.forceActiveFocus()
                                                renameField.selectAll()
                                            }
                                        }

                                        SmlIcon {
                                            id: deleteIcon
                                            name: Settings.delete_icon_name
                                            size: 16
                                            variant: Theme.iconMuted
                                            clickable_text: "Delete"
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10
                                            onClicked: {
                                                main_window.hf_renaming_index = -1
                                                deleteCompareDialog.pendingIndex = savedCompareRow.index
                                                deleteCompareDialog.pendingName = savedCompareRow.displayName
                                                deleteCompareDialog.open()
                                            }
                                        }

                                        MouseArea {
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: renameIcon.left
                                            enabled: !renameField.visible
                                            onClicked: main_window.hf_load_saved_compare(savedCompareRow.index)
                                        }
                                    }
                                }

                                // Comparison details: only shown while a comparison is open
                                Column {
                                    id: comparisonDetails
                                    width: parent.width
                                    spacing: 18
                                    visible: main_window.hf_open_compare_index !== -1

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Theme.border
                                }

                                // Comparison table
                                Text {
                                    text: "Comparison table"
                                    font.family: Theme.uiFontFamily
                                    font.pixelSize: Theme.fontSizeCardTitle
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }

                                // Header row (5 columns)
                                Row {
                                    width: parent.width
                                    spacing: 10

                                    Text {
                                        width: parent.width * 0.34
                                        text: "MODEL"
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeMeta
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.6
                                        wrapMode: Text.WordWrap
                                        color: Theme.textMuted
                                    }
                                    Text {
                                        width: parent.width * 0.14
                                        text: "LICENSE"
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeMeta
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.6
                                        wrapMode: Text.WordWrap
                                        color: Theme.textMuted
                                    }
                                    Text {
                                        width: parent.width * 0.14
                                        text: "MODEL FAMILY"
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeMeta
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.6
                                        wrapMode: Text.WordWrap
                                        color: Theme.textMuted
                                    }
                                    Text {
                                        width: parent.width * 0.14
                                        text: "ARCHITECTURE"
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeMeta
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.6
                                        wrapMode: Text.WordWrap
                                        color: Theme.textMuted
                                    }
                                    Text {
                                        width: parent.width * 0.2
                                        text: "LANGUAGES"
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeMeta
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.6
                                        wrapMode: Text.WordWrap
                                        color: Theme.textMuted
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Theme.border }

                                Repeater {
                                    model: (main_window.hf_compare_obj && main_window.hf_compare_obj.comparison_table)
                                        ? main_window.hf_compare_obj.comparison_table : []

                                    delegate: Row {
                                        width: parent.width
                                        spacing: 10

                                        Text {
                                            width: parent.width * 0.34
                                            text: softHyphenate(modelData.model_id || "", 14)
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Theme.textSecondary
                                        }

                                        Text {
                                            width: parent.width * 0.14
                                            text: modelData.license || ""
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Theme.textSecondary
                                        }

                                        Text {
                                            width: parent.width * 0.14
                                            text: modelData.model_family || ""
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Theme.textSecondary
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

                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Theme.textSecondary
                                        }

                                        Text {
                                            width: parent.width * 0.2
                                            text: softHyphenate(modelData.languages || "", 14)
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideNone
                                            color: Theme.textSecondary
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Theme.border }

                                Repeater {
                                    model: (main_window.hf_compare_obj && main_window.hf_compare_obj.model_cards)
                                        ? main_window.hf_compare_obj.model_cards : []

                                    delegate: Column {
                                        width: parent.width
                                        spacing: 6

                                        Text {
                                            text: (modelData.model_id || "")
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: 16
                                            font.weight: Font.DemiBold
                                            wrapMode: Text.NoWrap
                                            color: Theme.accentText

                                        }

                                        Text {
                                            text: modelData.purpose
                                                ? ("<b>Purpose:</b> " + modelData.purpose)
                                                : ""
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            wrapMode: Text.NoWrap
                                            color: Theme.textSecondary
                                        }

                                        Text {
                                            text: (modelData.best_for && modelData.best_for.length)
                                                ? ("<b>Best for:</b> " + modelData.best_for.join(", "))
                                                : ""
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            wrapMode: Text.NoWrap
                                            color: Theme.textSecondary
                                        }

                                        Text {
                                            text: (modelData.watch_out_for && modelData.watch_out_for.length)
                                                ? ("<b>Watch out for:</b> " + modelData.watch_out_for.join(", "))
                                                : ""
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            wrapMode: Text.NoWrap
                                            color: Theme.textSecondary
                                        }

                                        Rectangle { width: parent.width; height: 1; color: Theme.border }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Theme.border }

                                // Comparison summary
                                Text {
                                    text: "Comparison summary"
                                    font.family: Theme.uiFontFamily
                                    font.pixelSize: Theme.fontSizeCardTitle
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }

                                Text {
                                    width: parent.width
                                    text: (main_window.hf_compare_obj && main_window.hf_compare_obj.comparison_summary)
                                        ? main_window.hf_compare_obj.comparison_summary : ""
                                    font.family: Theme.uiFontFamily
                                    font.pixelSize: Theme.fontSizeBody
                                    wrapMode: Text.WordWrap
                                    color: Theme.textSecondary
                                }
                                }   // end comparisonDetails Column
                            }

                            Controls2.ScrollBar.vertical: SmlScrollBar {
                                policy: Controls2.ScrollBar.AsNeeded
                                screen_edge: compareScreen
                                track: cmpScroll
                            }
                        }

                        // Delete confirmation dialog for saved comparisons
                        SmlModal {
                            id: deleteCompareDialog
                            property int pendingIndex: -1
                            property string pendingName: ""

                            title: "Delete comparison?"
                                icon_name: Settings.delete_icon_name
                            tone: "danger"
                            dialog_width: 400

                            Text {
                                width: deleteCompareDialog.availableWidth
                                text: "Are you sure you want to delete \"" + deleteCompareDialog.pendingName + "\"? This cannot be undone."
                                textFormat: Text.PlainText
                                wrapMode: Text.WordWrap
                                lineHeight: 1.3
                                font.family: Theme.uiFontFamily
                                font.pixelSize: Theme.fontSizeBody
                                color: Theme.textSecondary
                            }

                            footer: SmlDialogButtonBox {
                                SmlButton {
                                    id: deleteCompareCancelButton
                                    text_value: "Cancel"
                                    onClicked: deleteCompareDialog.close()
                                }
                                SmlButton {
                                    variant: "danger"
                                    icon_name: Settings.delete_icon_name
                                    text_value: "Delete"
                                    onClicked: {
                                        main_window.hf_delete_saved_compare(deleteCompareDialog.pendingIndex)
                                        deleteCompareDialog.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // HF RESULTS SCREEN
        Component
        {
            id: huggingFace_results_screen

            Rectangle
            {
                id: hfrScreen
                color: "transparent"

                property int selectedIndex: -1
                property var currentModels: {
                    if (selectedIndex >= 0 &&
                            selectedIndex < main_window.hf_saved_searches.length)
                        return main_window.hf_saved_searches[selectedIndex].models
                    return []
                }

                function formatTs(ts) {
                    var d = new Date(ts)
                    return Qt.formatDateTime(d, "dd/MM/yyyy HH:mm")
                }

                SmlScreenHeader
                {
                    id: hfr_header
                    title: "Search results"
                    subtitle: "Hugging Face searches saved so far: pick one to see its models"

                    navigation: [
                        SmlButton {
                            id: hfr_home_button
                            icon_name: Settings.home_icon_name
                            text_value: "Home"
                            tooltip_text: "Go to Home screen"
                            onClicked: main_window.load_screen(ScreenManager.Screens.Home)
                        },

                        SmlIconButton {
                            id: hfr_back_button
                            outlined: true
                            icon_name: Settings.back_icon_name
                            tooltip_text: "Back to Problem Definition"
                            onClicked: main_window.load_screen(ScreenManager.Screens.Definition)
                        }
                    ]

                    actions: [
                        // Save / Load only this screen's searches (Results: tasks only, Settings: everything)
                        SmlButton {
                            id: hfr_save_button
                            z: 100000
                            icon_name: Settings.save_icon_name
                            text_value: "Save"
                            disabled: main_window.hf_saved_searches.length === 0
                            tooltip_text: "Save the searches into a file"
                            onClicked: hfr_save_load_dialogs.open_save()
                        },

                        SmlButton {
                            id: hfr_load_button
                            z: 100000
                            icon_name: Settings.load_icon_name
                            text_value: "Load"
                            tooltip_text: "Load searches from a file, added to the current ones"
                            onClicked: hfr_save_load_dialogs.open_load()
                        }
                    ]
                }

                SmlSaveLoadDialogs
                {
                    id: hfr_save_load_dialogs
                    anchors.fill: parent
                    z: 200000
                    save_title: "Save Searches"
                    load_title: "Load Searches"
                    save_prompt: "Name this save, or pick an existing one below to overwrite its searches. Its results and other HF history are kept."
                    no_files_text: "No saved searches yet."
                    load_part: "searches"
                    onSave_requested: engine.save_hf(name, "searches", main_window.hf_saved_searches)
                    onLoad_requested: engine.load_hf(name, "searches")
                }

                SmlCard {
                    id: hfr_card
                    anchors {
                        top: hfr_header.bottom
                        topMargin: Theme.space5
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: Theme.pagePadding
                    }
                    width: Math.min(parent.width - 2 * Theme.pagePadding, Theme.contentMaxWidth)
                    title: "HF Search Results"
                    subtitle: main_window.hf_saved_searches.length + " saved searches"
                    icon_name: Settings.results_icon_name
                    content_padding: Theme.space4

                    // On the card itself, not in its content area (whose size it would feed back into)
                    SmlEmptyState {
                        parent: hfr_card
                        anchors.centerIn: parent
                        visible: main_window.hf_saved_searches.length === 0
                        title: "No saved searches yet"
                        hint: "Every Hugging Face search that returns models is kept here."
                    }

                    // Clicking any blank area of this panel discards an
                    // in-progress, unsaved rename (same as the Compare screen).
                    MouseArea {
                        parent: hfr_card
                        anchors.fill: parent
                        z: -1
                        onClicked: main_window.hf_renaming_search_index = -1
                    }

                    Item {
                        anchors.fill: parent

                        Flickable {
                            id: hfrFlickable
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            contentWidth: width
                            contentHeight: hfrMainColumn.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Controls2.ScrollBar.vertical: hfrScrollBar

                            Column {
                                id: hfrMainColumn
                                width: hfrFlickable.width
                                spacing: Settings.spacing_small

                                // Saved search entries
                                Repeater {
                                    model: main_window.hf_saved_searches

                                    delegate: Rectangle {
                                        id: savedSearchRow

                                        // Explicit required properties: Repeater's implicit "index"/"modelData"
                                        // context properties are not reliably resolved from custom property
                                        // bindings or nested item functions under Qt 5.15 - only from bindings
                                        // written directly on a built-in property. Declaring them here makes
                                        // them real properties of this delegate, resolvable everywhere below.
                                        // (Same reasoning as savedCompareRow in the Compare screen.)
                                        required property int index
                                        required property var modelData

                                        width: hfrMainColumn.width
                                        height: 38
                                        radius: Theme.radiusMd
                                        border.color: savedSearchRow.index === selectedIndex ? Theme.brandGreen : Theme.border
                                        border.width: 1
                                        color: savedSearchRow.index === selectedIndex
                                            ? Theme.accentSubtleStrong
                                            : Theme.raised

                                        readonly property string displayName: (savedSearchRow.modelData.name && savedSearchRow.modelData.name.length > 0)
                                            ? savedSearchRow.modelData.name
                                            : (savedSearchRow.modelData.query || "(no query)")

                                        Text {
                                            id: searchLabel
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.right: modelCountText.left
                                            anchors.rightMargin: 8
                                            elide: Text.ElideRight
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            font.weight: savedSearchRow.index === selectedIndex ? Font.DemiBold : Font.Normal
                                            color: Theme.textPrimary
                                            text: savedSearchRow.displayName
                                            visible: !renameSearchField.visible
                                        }

                                        TextInput {
                                            id: renameSearchField

                                            // Driven by shared main_window state, not a local flag - same
                                            // reasoning as renameField in the Compare screen's saved list.
                                            visible: main_window.hf_renaming_search_index === savedSearchRow.index

                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.right: modelCountText.left
                                            anchors.rightMargin: 8
                                            clip: true
                                            selectByMouse: true
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            color: Theme.textPrimary
                                            selectionColor: Theme.accentSubtleStrong
                                            selectedTextColor: Theme.textPrimary

                                            // Only Enter applies the new name; anything else (click away,
                                            // Escape) discards the edit and keeps the previous name.
                                            Keys.onReturnPressed: main_window.hf_commit_rename_search(savedSearchRow.index, text.trim(), savedSearchRow.displayName)
                                            Keys.onEnterPressed: main_window.hf_commit_rename_search(savedSearchRow.index, text.trim(), savedSearchRow.displayName)
                                            Keys.onEscapePressed: main_window.hf_renaming_search_index = -1
                                            onFocusChanged: if (!focus && visible) main_window.hf_renaming_search_index = -1
                                        }

                                        Text {
                                            id: modelCountText
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: tsText.left
                                            anchors.rightMargin: 10
                                            text: (savedSearchRow.modelData.models ? savedSearchRow.modelData.models.length : 0) + " models"
                                            font.family: Theme.monoFontFamily
                                            font.pixelSize: Theme.fontSizeMeta
                                            color: Theme.textMuted
                                        }
                                        Text {
                                            id: tsText
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: renameSearchIcon.left
                                            anchors.rightMargin: 10
                                            text: formatTs(savedSearchRow.modelData.ts)
                                            font.family: Theme.monoFontFamily
                                            font.pixelSize: Theme.fontSizeMeta
                                            color: Theme.textMuted
                                        }

                                        SmlIcon {
                                            id: renameSearchIcon
                                            name: Settings.rename_icon_name
                                            size: 16
                                            variant: Theme.iconMuted
                                            clickable_text: "Rename"
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: deleteSearchIcon.left
                                            anchors.rightMargin: 6
                                            onClicked: {
                                                renameSearchField.text = savedSearchRow.displayName
                                                main_window.hf_renaming_search_index = savedSearchRow.index
                                                renameSearchField.forceActiveFocus()
                                                renameSearchField.selectAll()
                                            }
                                        }

                                        SmlIcon {
                                            id: deleteSearchIcon
                                            name: Settings.delete_icon_name
                                            size: 16
                                            variant: Theme.iconMuted
                                            clickable_text: "Delete"
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10
                                            onClicked: {
                                                main_window.hf_renaming_search_index = -1
                                                deleteSearchDialog.pendingIndex = savedSearchRow.index
                                                deleteSearchDialog.pendingName = savedSearchRow.displayName
                                                deleteSearchDialog.open()
                                            }
                                        }

                                        MouseArea {
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: renameSearchIcon.left
                                            enabled: !renameSearchField.visible
                                            onClicked: selectedIndex = (selectedIndex === savedSearchRow.index) ? -1 : savedSearchRow.index
                                        }
                                    }
                                }

                                // Separator, only above the models of a selected search (as on the Compare screen)
                                Item {
                                    visible: selectedIndex >= 0
                                    width: hfrMainColumn.width
                                    height: Settings.spacing_normal

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: 1
                                        color: Theme.border
                                    }
                                }

                                // Model cards for selected entry
                                Repeater {
                                    model: currentModels

                                    delegate: Rectangle {
                                        width: hfrMainColumn.width
                                        radius: Theme.radiusMd
                                        border.color: Theme.border
                                        border.width: 1
                                        color: Theme.raised
                                        height: 54

                                        property string mid: {
                                            try {
                                                if (typeof modelData === "string") return modelData
                                                if (modelData && modelData["model_id"] !== undefined) return modelData["model_id"]
                                                if (modelData && modelData["id"] !== undefined) return modelData["id"]
                                                if (modelData && modelData["modelId"] !== undefined) return modelData["modelId"]
                                            } catch (e) { }
                                            return ""
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { if (mid) Qt.openUrlExternally("https://huggingface.co/" + mid) }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.space4
                                            anchors.rightMargin: Theme.space3
                                            spacing: Theme.space5

                                            // A link to the model's Hugging Face page (the whole card opens it)
                                            Text {
                                                text: mid
                                                font.family: Theme.uiFontFamily
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                font.underline: true
                                                color: Theme.accentText
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Text {
                                                text: (typeof modelData === "object" && modelData.score !== undefined)
                                                    ? ("score " + Number(modelData.score).toFixed(6)) : ""
                                                font.family: Theme.monoFontFamily
                                                font.pixelSize: 12
                                                color: Theme.textMuted
                                                horizontalAlignment: Text.AlignRight
                                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                Layout.preferredWidth: 180
                                            }

                                            SmlButton {
                                                variant: "primary"
                                                size: "sm"
                                                icon_name: "zap"
                                                text_value: "Analyze"
                                                tooltip_text: "Evaluate this model for the problem"
                                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                onClicked: main_window.open_hf_analyze(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // On the right edge of the screen
                        SmlScrollBar {
                            id: hfrScrollBar
                            policy: Controls2.ScrollBar.AsNeeded
                            screen_edge: hfrScreen
                            track: hfrFlickable
                        }
                    }

                    // Delete confirmation dialog for saved searches
                    SmlModal {
                        id: deleteSearchDialog
                        property int pendingIndex: -1
                        property string pendingName: ""

                        title: "Delete search result?"
                        icon_name: Settings.delete_icon_name
                        tone: "danger"
                        dialog_width: 400

                        Text {
                            width: deleteSearchDialog.availableWidth
                            text: "Are you sure you want to delete \"" + deleteSearchDialog.pendingName + "\"? This cannot be undone."
                            textFormat: Text.PlainText
                            wrapMode: Text.WordWrap
                            lineHeight: 1.3
                            font.family: Theme.uiFontFamily
                            font.pixelSize: Theme.fontSizeBody
                            color: Theme.textSecondary
                        }

                        footer: SmlDialogButtonBox {
                            SmlButton {
                                id: deleteSearchCancelButton
                                text_value: "Cancel"
                                onClicked: deleteSearchDialog.close()
                            }
                            SmlButton {
                                variant: "danger"
                                icon_name: Settings.delete_icon_name
                                text_value: "Delete"
                                onClicked: {
                                    main_window.hf_delete_saved_search(deleteSearchDialog.pendingIndex)
                                    deleteSearchDialog.close()
                                }
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

    // Node status (settings) button, on top of every screen, in the free right end of its header
    // (not on the iteration info view, opened from Results only to show an iteration)
    SmlIconButton
    {
        id: settings_icon
        visible: ScreenManager.current_screen !== ScreenManager.Screens.Reiterate
        icon_name: Settings.settings_icon_name
        tooltip_text: "Go to Node Status screen"
        disabled: main_window.tasking

        x: parent.width - width - Theme.space4
        y: (Theme.headerHeight - height) / 2

        onClicked: {
            // Nothing to save yet when Settings is opened from the start screen
            if (ScreenManager.current_screen !== ScreenManager.Screens.Log)
                main_window.settings_save_enabled = ScreenManager.current_screen !== ScreenManager.Screens.Start
            main_window.load_screen(ScreenManager.Screens.Log);
        }
    }

    // Screen loader plus background animation trigger. is_back is true only when
    // called from go_back() below - it means "unwind", so the current screen must
    // NOT be pushed onto screen_history again (that would immediately turn the very
    // next go_back() call into a bounce right back to where we just came from).
    function load_screen(screen, is_back)
    {
        // "Home" is now just an alias for the Problem Definition screen - the
        // actual useful starting point (fields/buttons), not the old near-empty
        // welcome screen. Every Home button/link across the app lands here.
        if (screen === ScreenManager.Screens.Home)
        {
            screen = ScreenManager.Screens.Definition
        }

        var screen_to_be_loaded  = ScreenManager.current_screen // Current screen as default

        // Check if actual change is required
        if (ScreenManager.current_screen !== screen)
        {
            // The start screen is only a Back destination for the gear (Settings) opened
            // from it: leaving it any other way (its Start button), or moving on from that
            // Settings screen, is one-way, as before
            if (!is_back)
            {
                if (screen !== ScreenManager.Screens.Log)
                {
                    main_window.screen_history = main_window.screen_history.filter(function(s) {
                        return s !== ScreenManager.Screens.Start
                    })
                }
                if (!(ScreenManager.current_screen === ScreenManager.Screens.Start &&
                      screen !== ScreenManager.Screens.Log))
                {
                    main_window.screen_history.push(ScreenManager.current_screen)
                }
            }

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
                case ScreenManager.Screens.HFresults:
                    screen_to_be_loaded = huggingFace_results_screen
                    break
                case ScreenManager.Screens.UNetGraph:
                    screen_to_be_loaded = uNetGraph_screen
                    break
                case ScreenManager.Screens.Start:
                    screen_to_be_loaded = home_screen
                    break
                default:
                    screen_to_be_loaded = definition_screen
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

    // Navigate to whichever screen was actually shown right before the current
    // one, per screen_history - the single correct "Back" implementation for
    // every screen (Log/Settings, Compare, ...) instead of each tracking its own
    // "previous screen" slot, which breaks as soon as two screens can reach each
    // other (see screen_history's own comment above for why).
    function go_back()
    {
        var history = main_window.screen_history.slice(0)
        var target = history.length > 0 ? history.pop() : ScreenManager.Screens.Definition
        main_window.screen_history = history
        main_window.load_screen(target, true)
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
            case ScreenManager.Screens.UNetGraph:
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
            case ScreenManager.Screens.HFresults:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_final
                movement[3] = Settings.background_2_y_initial
                break
            default:
            case ScreenManager.Screens.Home:
            case ScreenManager.Screens.Start:
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
        reiterateModel.set(5, { label: "Carbon footprint [gCO2e]", value: results["Carbon footprint"] })
        reiterateModel.set(6, { label: "Carbon intensity [gCO2/kW]", value: results["Carbon intensity"] })
        reiterateModel.set(7, { label: "Memory footprint [MB]", value: results["Memory footprint"] })
        engine.request_orchestrator(parseInt(problem_id), parseInt(results["Iteration"]), true)
        load_screen(ScreenManager.Screens.Reiterate)
    }
}
