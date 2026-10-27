({
    init: function(component, helper) {
        component.set("v.membershipItemAndPlanIdSelected", null);

        let isDepartmentalMembershipJoin = component.get("v.isDepartmentalMembershipJoin");
        if (isDepartmentalMembershipJoin) {
            helper.checkAndShowMembershipView(component, helper);
        } else {
            helper.setMembershipView(component, helper);
        }
        
    },

    setMembershipView: function(component){
        debugger;
        var salesOrder = component.get("v.salesOrder");
        if (typeof salesOrder !== "undefined") {
            salesOrder['OrderApi__Sales_Order_Lines__r'].forEach(function (salesOrderLine) {
                debugger;
                if (salesOrderLine['OrderApi__Subscription_Plan__c'] && salesOrderLine['OrderApi__Item_Class__r'].Name != 'Sections' && salesOrderLine['OrderApi__Item_Class__r'].Name != 'Divisions') {
                    component.set("v.membershipItemAndPlanIdSelected", salesOrderLine['OrderApi__Item__c'] + '&' + salesOrderLine['OrderApi__Subscription_Plan__c']);
                }
            });
        }
        // debugger;
        var action = component.get("c.getMembershipItems");
        action.setParams({
            contactTitle: component.get("v.currentContact")['Functional_Title__c'],
            isDepartmentalMembershipJoin: component.get('v.isDepartmentalMembershipJoin')
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.membershipItems", result);
                if (result.length === 1 && result[0]['OrderApi__Subscription_Plan_Items__r'].length === 1) {
                    component.set("v.hasOnlyOneSubscriptionOption", true);
                    this.nextStep(component, result[0]['Id'] + '&' + result[0]['OrderApi__Subscription_Plan_Items__r'][0]['OrderApi__Subscription_Plan__c']);
                }
            }
        });
        $A.enqueueAction(action);
    },

    nextStep: function(component, membershipItemAndPlanIdSelectedAuto) {
        this.toggleSpinner(component);
        var membershipItemAndPlanIdSelected = membershipItemAndPlanIdSelectedAuto === '' ? (document.querySelector('input[name="plan"]:checked') ? document.querySelector('input[name="plan"]:checked').value : null) : membershipItemAndPlanIdSelectedAuto;
		var needToUpdate = component.get("v.membershipItemAndPlanIdSelected") === null || membershipItemAndPlanIdSelected !== component.get("v.membershipItemAndPlanIdSelected");

        if (membershipItemAndPlanIdSelected !== null) {
            component.set("v.membershipItemAndPlanIdSelected", membershipItemAndPlanIdSelected);
            var salesOrder = component.get("v.salesOrder");
            if (typeof salesOrder === "undefined") {
                salesOrder = null;
            }
            var action = component.get("c.createOrUpdateSalesOrder");
            action.setParams({
                contact: component.get("v.currentContact"),
                itemId: membershipItemAndPlanIdSelected.split('&')[0],
                planId: membershipItemAndPlanIdSelected.split('&')[1],
                salesOrderId: salesOrder !== null ? salesOrder['Id'] : null,
                isDepartmentalMembershipJoin: component.get('v.isDepartmentalMembershipJoin'),
                needToUpdate: salesOrder === null || needToUpdate
            });
            action.setCallback(this,function(response) {
                this.toggleSpinner(component);
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    component.set("v.salesOrder", result);
                }
                component.set("v.currentPage", 'MarketingAddOn');
            });
            $A.enqueueAction(action);
        } else {
            this.toggleSpinner(component);
            alert("You have to select a plan.");
        }
    },

    toggleSpinner: function(component) {
        var spinner = component.find("loadingSpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },

    checkAndShowMembershipView: function(component){
        // let populationSize = component.get("v.currentContact")['Account']['Population_Served_Size__c'];
        let accountId = component.get("v.currentContact")['AccountId'];
        let isDepartmentalMembershipJoin = component.get("v.isDepartmentalMembershipJoin");
        component.set("v.isPopulationServedError", false);
        
        let action = component.get("c.getAccountPopulationServed");
        action.setParams({
            accountId: accountId
        });
        action.setCallback(this,function(response) {
            this.toggleSpinner(component);
            var state = response.getState();
            if (state === "SUCCESS") {
                var populationSize = response.getReturnValue();
                if(populationSize && populationSize != 'Less than 10,000'){
                    component.set("v.isPopulationServedError", true);
                } else{
                    this.setMembershipView(component);
                }
                
            } else{
                this.setMembershipView(component);
            }
            this.toggleSpinner(component);
        });
        $A.enqueueAction(action);
    }
})