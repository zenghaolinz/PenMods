import QtQuick 2.12

import "../utils"

// 需要配合继承自 YPage 的 QML 组件一同使用

YBasePopLayer {
    id: id_pop_layer_qml

    function show(qrcqml, animationEnabled, properties) {
        console.log("YPopLayer.qml===qrcqml: ", qrcqml,
                    "===animationEnabled: ", animationEnabled)
        const popIdValue = popIdPrefix + qrcqml

        if ((YUtils.currentPopId === popIdValue) && (null !== popItemObject)
                && popItemObject.popId === popIdValue) {
            return popItemObject
        }

        if (stackPagesMap.containsKey(popIdValue)) {
            console.log("YPopLayer.qml===use stack page show")
            popItemObject = stackPagesMap.value(popIdValue)
            stackPagesMap.top(popIdValue)
            YUtils.currentPopId = popIdValue
            return popItemObject
        }
        const component = qmlCreateComponent(qrcqml)
        console.log("YPopLayer.qml===component.status: ", component.status)
        if (Component.Ready === component.status) {
            if (typeof properties != "undefined") {
                popItemObject = component.createObject(YUtils.stackView, properties);
            } else {
                popItemObject = component.createObject(YUtils.stackView);
            }
            Object.defineProperty(popItemObject, 'popId', {
                                      enumerable: false, configurable: false,
                                      writable: false, value: popIdValue
                                  })
            console.log("YPopLayer.qml===popItemObject: ", popItemObject)

            if (popItemObject.hasOwnProperty("backButtonClicked")) {
                popItemObject.backButtonClicked.connect(function(){
                    id_pop_layer_qml.close()
                })
            }

            stackPagesMap.put(popIdValue, popItemObject)
            YUtils.currentPopId = popIdValue

            const keys = stackPagesMap.keys()
            keys.forEach(function(key){
                console.warn("ZDS===key===", key)
            })

        } else if(Component.Error === component.status) {
            console.log("YPopLayer.qml===component.errorString: ", component.errorString())
        }
        return popItemObject
    }

    function cacheShow(qrcqml, animationEnabled, properties) {
        const popIdValue = popIdPrefix + qrcqml
        if (cachePagesMap.containsKey(popIdValue)) {
            popItemObject = cachePagesMap.value(popIdValue)
            const keysBf = stackPagesMap.keys()
            keysBf.forEach(function(key){
                console.warn("before ZDS===key===", key)
            })
            if (stackPagesMap.containsKey(popIdValue)) {
                stackPagesMap.top(popIdValue)
            } else {
                stackPagesMap.put(popIdValue, popItemObject)
            }
            YUtils.currentPopId = popIdValue
            const keys = stackPagesMap.keys()
            keys.forEach(function(key){
                console.warn("after ZDS===key===", key)
            })
            console.log("YPopLayer.qml===use cache page show")
        } else {
            show(qrcqml, animationEnabled, properties)
            if (popItemObject.hasOwnProperty("destroyOnBack")) {
                popItemObject.destroyOnBack = false
            }
            cachePagesMap.put(popIdValue, popItemObject)
            console.log("YPopLayer.qml===use create new page show")
        }
        return popItemObject
    }

    function showWithProperties(qrcqml, properties) {
        show(qrcqml, false, properties)
    }

    function close() {
        if (isShowing) {
            popItemObject = null
            console.log("YPopLayer.qml===close===called")
        }
    }

    function closeAllPopPage() {
        if (!stackPagesMap.isEmpty()) {
            stackPagesMap.keys().forEach(function(key){
                const item = stackPagesMap.take(key)
                if (item.hasOwnProperty("backButtonClicked")) {
                    item.backButtonClicked()
                }
            })
            stackPagesMap.clear()
        }
        YUtils.currentPopId = ""
        console.log("YPopLayer.qml===closeAllPopPage===YUtils.currentPopId: ", YUtils.currentPopId)
    }
}
