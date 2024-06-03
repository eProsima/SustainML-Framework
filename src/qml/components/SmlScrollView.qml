import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15


// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

Flickable
{
    id: sustainml_custom_scrollview

    // External properties
    property int content_width: 0
    property int content_height: 0
    property int layout: SmlScrollBar.ScrollBarLayout.Vertical
    property string scrollbar_backgound_color: "transparent"
    property string scrollbar_backgound_nightmodel_color: "transparent"

    contentWidth: sustainml_custom_scrollview.content_width
    contentHeight: sustainml_custom_scrollview.content_height
    boundsBehavior: Flickable.StopAtBounds

    clip: true
    interactive: false

    // Vertical ScrollBar
    ScrollBar.vertical: SmlScrollBar {
        id: scrollbar_vertical

        parent: sustainml_custom_scrollview
        anchors.right: sustainml_custom_scrollview.right

        policy: ScrollBar.AsNeeded
        background_color: sustainml_custom_scrollview.scrollbar_backgound_color
        background_nightmode_color: sustainml_custom_scrollview.scrollbar_backgound_nightmodel_color
        layout: sustainml_custom_scrollview.layout
        visible: sustainml_custom_scrollview.layout !== SmlScrollBar.ScrollBarLayout.Horizontal
    }

    // Horizontal ScrollBar
    ScrollBar.horizontal: SmlScrollBar {
        id: scrollbar_horizontal

        parent: sustainml_custom_scrollview
        anchors.bottom: sustainml_custom_scrollview.bottom

        policy: ScrollBar.AsNeeded
        background_color: sustainml_custom_scrollview.scrollbar_backgound_color
        background_nightmode_color: sustainml_custom_scrollview.scrollbar_backgound_nightmodel_color
        layout: sustainml_custom_scrollview.layout
        visible: sustainml_custom_scrollview.layout !== SmlScrollBar.ScrollBarLayout.Vertical
    }

    MouseArea
    {
        id: mousearea
        anchors.fill: parent
        //so that flickable won't steal mouse event
        //however, when the flickable is flicking and interactive is true
        //this property will have no effect until current flicking ends and interactive is set to false
        //so we need to keep interactive false and scroll only with flick()
        preventStealing: true

        //scroll velocity
        property real nextVelocity: 0
        property real curWeight: baseWeight
        property real baseWeight: 4
        property real maxWeight: 12
        property real stepWeight: 2
        property real maxVelocity: 2400
        property real minVelocity: -2400

        // scroll management
        property bool is_shift_pressed: false

        Timer
        {
            id: timer
            interval: 1000 / 60
            repeat: false
            running: false

            onTriggered: parent.scroll()
        }

        function scroll()
        {

            var velocity = -sustainml_custom_scrollview.verticalVelocity + nextVelocity
            sustainml_custom_scrollview.flickDeceleration = Math.abs(velocity) * 2.7
            if (is_shift_pressed)
            {
                sustainml_custom_scrollview.flick(velocity, 0)
            }
            else
            {
                sustainml_custom_scrollview.flick(0, velocity)
            }
            nextVelocity = 0
            curWeight = baseWeight
        }

        onWheel:
        {
            wheel.accepted = true
            // if pressing shift, move horizontally
            if (wheel.modifiers & Qt.ShiftModifier)
            {
                is_shift_pressed = true
            }
            // else move vertically
            else
            {
                is_shift_pressed = false
            }
            var delta = wheel.angleDelta.y
            nextVelocity += curWeight * delta

            if(nextVelocity > maxVelocity)
                nextVelocity = maxVelocity
            else if(nextVelocity < minVelocity)
                nextVelocity = minVelocity

            curWeight += stepWeight
            if(curWeight > maxWeight)
                curWeight = maxWeight

            timer.start()
        }

        //make sure items can only be clicked when view is not scrolling
        //can be removed if you don't need this limitation
        onPressed:
        {
            mouse.accepted = sustainml_custom_scrollview.moving
        }
        onReleased:
        {
            mouse.accepted = sustainml_custom_scrollview.moving
        }
        onClicked:
        {
            mouse.accepted = sustainml_custom_scrollview.moving
        }
    }
    function scroll_to(target)
    {
        // check bounds
        if(target < 0)
        {
            target = 0
        }
        else if(!mousearea.is_shift_pressed && (target + Settings.spacing_big > contentHeight))
        {
            target = contentHeight
        }
        else if(mousearea.is_shift_pressed && (target + Settings.spacing_big > contentWidth))
        {
            target = contentWidth
        }


        // check if already visible
        if (!mousearea.is_shift_pressed && (target < contentY || target + Settings.spacing_big > contentY + height))
        {
            // scroll to y
            scroll_animation.to = target
            scroll_animation.property= "contentY"
            scroll_animation.start()
        }
        else if (mousearea.is_shift_pressed && (target < contentX || target + Settings.spacing_big > contentX + width))
        {
            // scroll to x
            scroll_animation.to = target
            scroll_animation.property= "contentX"
            scroll_animation.start()
        }
    }
    // scroll_to animation
    NumberAnimation
    {
        id: scroll_animation
        target: sustainml_custom_scrollview
        property: "contentY"
        easing.type: Easing.InOutQuad
        to: 0
    }
}
