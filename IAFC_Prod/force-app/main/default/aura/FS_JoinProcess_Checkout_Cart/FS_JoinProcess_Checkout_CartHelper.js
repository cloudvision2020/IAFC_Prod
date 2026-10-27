({
    collapseHelper: function(component, event, secId) {
        var acc = component.find(secId);
        for (var cmp in acc) {
            $A.util.toggleClass(acc[cmp], 'slds-show');
            $A.util.toggleClass(acc[cmp], 'slds-hide');
        }
    },

    removeHelper: function(component, event) {
        var showDivisionAddOn = component.get("v.showDivisionAddOn");
        var addOnId = event.getSource().get("v.name").split('_')[1];
        var addOnsSelected = component.get("v.addOnsSelected");
        var tempAddOnsMap = component.get("v.addOnsMap");
        var addOns = component.get("v.addOns");

        tempAddOnsMap[addOnId]['isSelected'] = false;
        addOns.forEach(function(addOn) {if (addOn['Id'] === addOnId) {addOn['isSelected'] = false}});
        component.set("v.addOns", addOns);
        component.set("v.addOnsSelected", addOnsSelected.filter(function(ele) {return ele['Id'] !== addOnId}));
        component.set("v.totalPrice", component.get("v.totalPrice") - tempAddOnsMap[addOnId]['OrderApi__Price__c']);
        if (!showDivisionAddOn) {
            component.set("v.showDivisionAddOn", true);
        }
        component.set("v.addOnsMap", tempAddOnsMap);
    },

    checkoutHelper: function(component) {
        debugger;
        component.set("v.showSpinner", true);
        var salesOrder = component.get("v.salesOrder");
        var addOnsSelected = component.get("v.addOnsSelected");
        var salesOrderLines = {};
        salesOrder['OrderApi__Sales_Order_Lines__r'].forEach(function (salesOrderLine) {
            if (!salesOrderLine['OrderApi__Subscription_Plan__c']) {
                salesOrderLines[salesOrderLine['OrderApi__Item__c']] = salesOrderLine['Id'];
            }
        });

        // addOnsSelected.forEach(function (addOn) {
        //     delete addOn['isSelected'];
        // });

        var action = component.get("c.updateSalesOrder");
        action.setParams({
            addOnsSelected: addOnsSelected,
            contact: component.get("v.contact"),
            isFederalMilitary: component.get("v.isFederalMilitary"),
            itemIdToSalesOrderLineId: salesOrderLines,
            salesOrderId: salesOrder['Id']
        });
        action.setCallback(this,function(response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if ('Error' in result) {
                    alert(result);
                } else {
                    component.set("v.showModal", true);
                    component.set("v.paymentURL", result["PaymentURL"]);
                    component.set("v.salesOrder", result["SalesOrder"]);
                }
            }
        });
        $A.enqueueAction(action);
    }
})