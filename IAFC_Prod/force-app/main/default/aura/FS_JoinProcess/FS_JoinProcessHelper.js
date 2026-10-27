({
    init: function(component) {
        var temp = decodeURIComponent(window.location.search.substring(1)).split('&');
        var parameters = {};
        for (var i = 0; i < temp.length; i++) {
            if (temp[i] !== "") {
                var para = temp[i].split('=');
                if (!(para[0] in parameters)) {
                    parameters[para[0]] = para[1];
                }
            }
        }
        if ("cart" in parameters) {
            var salesOrderId = parameters["cart"];
            var action = component.get("c.getContact");
            action.setParams({
                userId: $A.get("$SObjectType.CurrentUser.Id"),
                salesOrderId: salesOrderId
            });
            action.setCallback(this,function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if (result['Error'] === 'User not correct') {
                        this.showToast(component, "Please using the related user to login to see the cart.", "Error", "Error!");
                    } else {
                        component.set("v.currentContact", result['Contact']);
                        component.set("v.salesOrder", result['Sales Order']);
                        component.set("v.showCartDirectly", true);
                        component.set("v.currentPage", "MarketingAddOn");
                    }
                }
            });
            $A.enqueueAction(action);
        } else {
            component.set("v.currentPage", "VerifyProfile");
        }
    },

    showToast : function(component, message, type, title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "title": title,
            "message": message
        });
        toastEvent.fire();
    }
})