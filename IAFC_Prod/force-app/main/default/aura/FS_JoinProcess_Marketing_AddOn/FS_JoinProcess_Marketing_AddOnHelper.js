({
    init: function(component) {
        component.set("v.showSpinner", true);
        var tempAddOnsMap = {};
        var addOns = new Array();
        var addOnsSelected = new Array();
        var addOnsSelectedIds = new Array();
        var membershipItemPrice = 0;
        let isDepartmentalMembershipJoin = component.get("v.isDepartmentalMembershipJoin");
        debugger;
        var salesOrder = component.get("v.salesOrder");
        var itemPriceMain = 0;
        if (salesOrder !== null) {
            salesOrder['OrderApi__Sales_Order_Lines__r'].forEach(function (salesOrderLine) {
                var tempItem = salesOrderLine['OrderApi__Item__r'];
                var tempPriceRule = salesOrderLine['OrderApi__Price_Rule__r'];
              
                if (tempItem['OrderApi__Item_Class__r']['Name'] === 'Divisions') {
                    tempItem['isSelected'] = true;
                    tempItem['OrderApi__Price__c'] = salesOrderLine['OrderApi__Total__c'];
                    tempItem['Name'] = tempItem['Name'] + ' - (' + tempPriceRule['Name'] + ' )';
                    tempAddOnsMap[tempItem['Id']] = tempItem;
                    addOns.push(tempItem);
                    addOnsSelected.push(tempItem);
                } else if (tempItem['OrderApi__Item_Class__r']['Name'] === 'Sections'){
                    tempItem['isSelected'] = true;
                    tempItem['OrderApi__Price__c'] = salesOrderLine['OrderApi__Total__c'];
                    addOnsSelectedIds.push(tempItem['Id']);
                    addOnsSelected.push(tempItem);
                }else if(salesOrderLine['OrderApi__Subscription_Plan__c']) {
                    component.set("v.membershipItemName", tempItem['Name']);
                    component.set("v.membershipItemDescription", tempItem['OrderApi__Description__c']);
                    component.set("v.membershipItemImageURL", tempItem['OrderApi__Image_Path__c']);
                    membershipItemPrice = salesOrderLine['OrderApi__Total__c'];
                    component.set("v.planName", salesOrderLine['OrderApi__Subscription_Plan__r']['Name']);

                    //tempItem['isSelected'] = true;
                    tempItem['OrderApi__Price__c'] = salesOrderLine['OrderApi__Total__c'];
                    addOnsSelectedIds.push(tempItem['Id']);
                    addOnsSelected.push(tempItem);
                    itemPriceMain = salesOrderLine['OrderApi__Total__c'];
                }else {
                    tempItem['isSelected'] = true;
                    tempItem['OrderApi__Price__c'] = salesOrderLine['OrderApi__Total__c'];
                    addOnsSelectedIds.push(tempItem['Id']);
                    addOnsSelected.push(tempItem);
                }
            });
        }
        debugger;
        component.set("v.addOnsSelected", addOnsSelected);
        var totalPrice = component.get("v.addOnsSelected").reduce(function(total, item) {
            return total + item['OrderApi__Price__c'];
        }, membershipItemPrice);
        totalPrice = totalPrice - itemPriceMain;
        component.set("v.totalPrice", totalPrice);
		debugger;
        var action = component.get("c.initialization");
        action.setParams({
            accountId: component.get("v.contact")['AccountId'],
            salesOrder: salesOrder
        });

        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                debugger;
                var result = response.getReturnValue();
                if(result != undefined){
                    result['AddOns'].forEach(function(addOn) {
                        addOn['isSelected'] = addOnsSelectedIds.includes(addOn['Id']);
                        tempAddOnsMap[addOn['Id']] = addOn;
                    });
                    component.set("v.addOns", result['AddOns'].concat(addOns));
                    component.set("v.isFederalMilitary", result['isFederalMilitary']);
                    component.set("v.addOnsMap", tempAddOnsMap);
                    component.set("v.showSpinner", false);
                    component.set("v.encryptedId", result['encryptedId']);
                }
            }
        });
        $A.enqueueAction(action);
    },

    selectAndUnSelectAddOn: function(component, event) {
        var addOnsSelected = component.get("v.addOnsSelected");
        var addOns = component.get("v.addOns");
        var tempAddOnsMap = component.get("v.addOnsMap");
        if (!tempAddOnsMap[event.currentTarget.id]['isSelected']) {
            tempAddOnsMap[event.currentTarget.id]['isSelected'] = true;
            addOnsSelected.push(tempAddOnsMap[event.currentTarget.id]);
            addOns.forEach(function(addOn) {if (addOn['Id'] === event.currentTarget.id) {addOn['isSelected'] = true}});
            component.set("v.addOns", addOns);
            component.set("v.addOnsSelected", addOnsSelected);
            component.set("v.totalPrice", component.get("v.totalPrice") + tempAddOnsMap[event.currentTarget.id]['OrderApi__Price__c']);
        } else {
            tempAddOnsMap[event.currentTarget.id]['isSelected'] = false;
            addOns.forEach(function(addOn) {if (addOn['Id'] === event.currentTarget.id) {addOn['isSelected'] = false}});
            component.set("v.addOns", addOns);
            component.set("v.addOnsSelected", addOnsSelected.filter(function(ele) {return ele['Id'] !== event.currentTarget.id}));
            component.set("v.totalPrice", component.get("v.totalPrice") - tempAddOnsMap[event.currentTarget.id]['OrderApi__Price__c']);
        }
        component.set("v.addOnsMap", tempAddOnsMap);
    },
})