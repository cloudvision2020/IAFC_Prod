/**
 * Created by dwu on 2019-01-22.
 */
({
    init: function(component, event, helper) {
        helper.getCountryStateOptions(component, event, helper);
        helper.getPopulationPicklistValues(component, event, helper);
    },

    updateStates: function(component, event, helper) {
        component.set("v.billingStateOptions", helper.countryStateMap[component.get("v.accountRecord.BillingCountryCode")]);
    },

    openModal : function(component, event, helper) {
        component.set("v.showModal", true);
    },

    saveAccountModal : function(component, event, helper) {

        $A.util.toggleClass(component.find("loadingSpinner"), "slds-hide");

        var accountRecord = component.get("v.accountRecord");

        accountRecord['Population_Served_Size__c'] = component.find("population").get("v.value");

        var action = component.get("c.insertAccount");
        action.setParams({
            accountRecord: component.get("v.accountRecord")
        });

        action.setCallback(this, function (response) {

            $A.util.toggleClass(component.find("loadingSpinner"), "slds-hide");

            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result) {
                    // alert('Account successfully submitted.');

                    component.set("v.showNewAccountModal", false);
                    component.set("v.accountRecord", {});
                    
                } else {
                    alert('There was an issue with your form submission. Please refresh and try again.')
                }

            } else {
                alert('There was an issue with your form submission. Please refresh and try again.');
            }
        });

        $A.enqueueAction(action);
    },

    closeModal : function(component, event, helper) {
        component.set("v.showNewAccountModal", false);
        component.set("v.accountRecord", {});
    },
})