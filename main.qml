
import QtQuick
import QtQuick.Controls

import org.qfield
import org.qgis
import Theme

import "qrc:/qml" as QFieldItems

Item {
  id: plugin
  property var mainWindow: iface.mainWindow()
  property var dashBoard: iface.findItemByObjectName("dashBoard")
  property var overlayFeatureFormDrawer: iface.findItemByObjectName("overlayFeatureFormDrawer")
  property var positionSource: iface.findItemByObjectName("positionSource")
  property var toolbar: iface.findItemByObjectName("toolbar")
  property var save_button: toolbar.children[0].children[0].children[0] //children path can change in futur but for now saveButton doesn't have objectName (cf FeatureForm.qml - line 776)

  property var reopenFeatureForm: false

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(reopenFeatureFormButton)
    
  }

  QfToolButton {
    id: reopenFeatureFormButton
    bgcolor: Theme.darkGray
    iconSource: "ic_speedometer_col_24dp.svg"
    iconColor: Theme.mainColor
    round: true

    onClicked: {
      dashBoard.ensureEditableLayerSelected();

      if (!positionSource.active || !positionSource.positionInformation.latitudeValid || !positionSource.positionInformation.longitudeValid) {
        mainWindow.displayToast(qsTr('QuickEntry requires positioning to be active and returning a valid position'))
        return
      }
      
      if (dashBoard.activeLayer.geometryType() != Qgis.GeometryType.Point) {
        mainWindow.displayToast(qsTr('QuickEntry requires the active vector layer to be a point geometry'))
        return
      }
      
      reopenFeatureForm = true
      save_button.iconSource = Qt.resolvedUrl("ic_check_reopen_white_24dp.svg")
      createEmptyFeature()
    }
  }

  function createEmptyFeature() {
    let geometry = GeometryUtils.createGeometryFromWkt('')
    let feature = FeatureUtils.createFeature(dashBoard.activeLayer, geometry)

    overlayFeatureFormDrawer.featureModel.feature = feature
    overlayFeatureFormDrawer.featureModel.resetAttributes(true)
    overlayFeatureFormDrawer.state = 'Add'
    overlayFeatureFormDrawer.open()
  }

  Connections {
    target: overlayFeatureFormDrawer.featureForm
    onAboutToSave: {
      if (reopenFeatureForm) {

        let position = positionSource.positionInformation
        if (positionSource.active && position.latitudeValid && position.longitudeValid) {
          let pos = positionSource.projectedPosition
          let newWkt = "POINT(" + pos.x + " " + pos.y + ")";
          let newGeometry = GeometryUtils.createGeometryFromWkt(newWkt);
          
          overlayFeatureFormDrawer.featureModel.feature.geometry = newGeometry

        } else {
          mainWindow.displayToast(qsTr("GNSS position is not valid."));
        }
      }
    }
    onConfirmed: {
      if (reopenFeatureForm) {
        preNewFeatureTimer.start();
      }
    }
    onCancelled: {
      reopenFeatureForm = false
      save_button.iconSource = Theme.getThemeVectorIcon("ic_check_white_24dp")
    }
  }

  Timer {
    id: preNewFeatureTimer
    interval: 300 //don't try below 250, it doesn't work
    repeat: false
    onTriggered: {
      createEmptyFeature();
    }
  }

}
