import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Scroll bar of lists and views: a slim green handle that darkens while hovered or
    dragged (its size never changes), on an invisible track.
 */
ScrollBar {
    id: sustainml_custom_scrollbar

    enum ScrollBarLayout {
        Vertical,
        Horizontal,
        Both
    }

    // External properties
    property int layout: SmlScrollBar.ScrollBarLayout.Vertical
    property int drag_width: 6

    // On the screen's right edge instead of beside the content: the bar moves into
    // screen_edge and keeps level with track (the view it scrolls)
    property Item screen_edge: null
    property Item track: null

    readonly property bool active_: hovered || pressed

    Component.onCompleted: if (screen_edge) parent = screen_edge
    Binding on x {
        when: sustainml_custom_scrollbar.screen_edge !== null
        value: sustainml_custom_scrollbar.screen_edge ? sustainml_custom_scrollbar.screen_edge.width - sustainml_custom_scrollbar.width : 0
    }
    Binding on y {
        when: sustainml_custom_scrollbar.screen_edge !== null && sustainml_custom_scrollbar.track !== null
        value: sustainml_custom_scrollbar.__track_y()
    }
    Binding on height {
        when: sustainml_custom_scrollbar.screen_edge !== null && sustainml_custom_scrollbar.track !== null
        value: sustainml_custom_scrollbar.track ? sustainml_custom_scrollbar.track.height : 0
    }

    // Reads the sizes so the binding updates on layout changes, which mapToItem alone does not track
    function __track_y() {
        var t = track, e = screen_edge
        if (!t || !e || t.height < 0 || e.height < 0 || t.width < 0 || e.width < 0)
            return 0
        return t.mapToItem(e, 0, 0).y
    }

    hoverEnabled: true
    // Nothing to scroll: no bar (callers may still bind visible themselves)
    visible: size < 1.0
    padding: 2
    minimumSize: 0.08

    contentItem: Rectangle {
        implicitWidth: sustainml_custom_scrollbar.drag_width
        implicitHeight: sustainml_custom_scrollbar.drag_width
        radius: width / 2
        color: sustainml_custom_scrollbar.pressed ? Theme.accentFillPressed
             : sustainml_custom_scrollbar.active_ ? Theme.accentFillHover
             : Theme.brandGreenBright
        opacity: sustainml_custom_scrollbar.active_ ? 1.0 : 0.75
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    background: Item {
        implicitWidth: sustainml_custom_scrollbar.drag_width + 4
        implicitHeight: sustainml_custom_scrollbar.drag_width + 4
    }
}
