({
    init: function(component, event, helper) {
        helper.getCountryStateOptions(component);
        helper.getPreferredEmailTypeOptions(component);
        helper.getPreferredPhoneTypeOptions(component);
        helper.getJobFunctionOptions(component);
        helper.getContact(component);
        helper.getPopulationPicklistValues(component);
    },

    next: function(component, event, helper) {
        helper.nextStep(component);
    },

    updateStates: function(component, event, helper) {
        component.set("v.mailingStateOptions", helper.countryStateMap[component.get("v.currentContact.MailingCountryCode")]);
    },

    changeOrganization: function (component, event, helper) {
        component.set("v.showModal", true);
    },

    closeModal : function(component, event, helper) {
        component.set("v.showNewAccountModal", false);
        component.set("v.accountRecord", {});
    },

    saveAccountModal : function(component, event, helper) {

        $A.util.toggleClass(component.find("loadingSpinner"), "slds-hide");

        var accountRecord = component.get("v.accountRecord");

        accountRecord['Population_Served_Size__c'] = component.find("population").get("v.value");

        var action = component.get("c.insertAccount");
        action.setParams({
            accountRecord: component.get("v.accountRecord"),
            currentContact: component.get("v.currentContact")
        });

        action.setCallback(this, function (response) {

            $A.util.toggleClass(component.find("loadingSpinner"), "slds-hide");

            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result['Status']) {
                    // alert('Account successfully submitted.');

                    component.set("v.showNewAccountModal", false);
                    component.set("v.accountRecord", {});
                    component.set("v.currentContact", result['Contact']);

                } else {
                    alert('There was an issue with your form submission. Please refresh and try again.')
                }

            } else {
                alert('There was an issue with your form submission. Please refresh and try again.');
            }
        });

        $A.enqueueAction(action);
    },
})