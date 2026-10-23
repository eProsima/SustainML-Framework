import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Footer of an SmlModal: buttons on the right, right under the content, the accepting one
    (OK / Yes / Save...) primary and rightmost. Standard buttons are drawn as SmlButtons;
    custom ones are declared as SmlButtons with their own variant.
 */
DialogButtonBox {
    id: control

    alignment: Qt.AlignRight
    spacing: Theme.space2
    padding: Theme.space5
    topPadding: 0
    bottomPadding: Theme.space5
    visible: count > 0

    delegate: SmlButton {
        variant: DialogButtonBox.buttonRole === DialogButtonBox.AcceptRole
                 || DialogButtonBox.buttonRole === DialogButtonBox.YesRole
                 || DialogButtonBox.buttonRole === DialogButtonBox.ApplyRole ? "primary" : "secondary"
    }

    background: Item { }
}
