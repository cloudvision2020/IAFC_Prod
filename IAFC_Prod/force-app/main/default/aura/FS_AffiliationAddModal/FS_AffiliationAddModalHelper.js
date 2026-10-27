/**
 * Created by dwu on 2019-02-21.
 */
({
    search : function (component, event, helper) {
        var searchValue = component.get("v.searchValue");

        if(searchValue == '' || searchValue == undefined || searchValue == null) {
            component.set("v.accounts", null);
            component.set("v.showResults", false);
            return;
        }

        //component.set("v.disabled", true);
        component.set("v.isLoading", true);

        var action = component.get("c.getResults");
        action.setParams({
            searchString: component.get("v.searchValue"),
            isJoinProcessPage: component.get("v.isJoinProcessPage")
        });


        action.setCallback(this, function(response) {

            //component.set("v.disabled", false);
            component.set("v.isLoading", false);

            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.accounts", returnValue);
                component.set("v.showResults", true);

            } else if (state === "INCOMPLETE") {
                alert('There was an error retrieving your records. Please refresh and try again. If issues persist, please contact an administrator.')
            } else if (state === "ERROR") {
                alert('There was an error retrieving your records. Please refresh and try again. If issues persist, please contact an administrator.')
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    itemSelectedJoinProcess : function(component) {
        component.set("v.accounts", null);
        component.set("v.showResults", false);
        var relatedAccountIds = component.get("v.relatedAccountIds");

        $A.util.toggleClass(component.find("loadingSpinner"), "slds-hide");

        var action = component.get("c.insertAffiliation");
        action.setParams({
            accountRecordId: component.get("v.accountRecordId"),
            isJoinProcessPageAndExistingAffiliation: component.get("v.isJoinProcessPageAndExistingAffiliation"),
            isNoOrganization: component.get("v.noOrganization")
        });


        action.setCallback(this, function(response) {

            $A.util.toggleClass(component.find("loadingSpinner"), "slds-hide");

            //component.set("v.isLoading", false);

            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();

                if (!returnValue['Status']) {
                    alert('There was an error retrieving your records. Please refresh and try again. If issues persist, please contact an administrator.')
                    return;
                }
                var currentContact = component.get("v.currentContact");
                currentContact["AccountId"] = returnValue['Contact'][0]["AccountId"];
                currentContact["Account"]["Id"] = returnValue['Contact'][0]["Account"]["Id"];
                currentContact["Account"]["Name"] = returnValue['Contact'][0]["Account"]["Name"];
                if ("FS_Account_Division__c" in returnValue['Contact'][0]["Account"]) {
                    currentContact["Account"]["FS_Account_Division__c"] = returnValue['Contact'][0]["Account"]["FS_Account_Division__c"];
                }
                if ("Population_Served_Size__c" in returnValue['Contact'][0]["Account"]) {
                    currentContact["Account"]["Population_Served_Size__c"] = returnValue['Contact'][0]["Account"]["Population_Served_Size__c"];
                }
                if ("OrderApi__Outstanding_Credits__c" in returnValue['Contact'][0]["Account"]) {
                    currentContact["Account"]["OrderApi__Outstanding_Credits__c"] = returnValue['Contact'][0]["Account"]["OrderApi__Outstanding_Credits__c"];
                }
                if ("Organization_Type__c" in returnValue['Contact'][0]["Account"]) {
                    currentContact["Account"]["Organization_Type__c"] = returnValue['Contact'][0]["Account"]["Organization_Type__c"];
                }

                component.set("v.currentContact", currentContact);
                component.set("v.accounts", null);
                component.set("v.showResults", false);
                component.set("v.showModal", false);

                if (!component.get("v.isJoinProcessPageAndExistingAffiliation")) {
                    if (!component.get("v.noOrganization")) {
                        relatedAccountIds.push(component.get("v.accountRecordId"));
                    } else {
                        relatedAccountIds.push(currentContact["AccountId"]);
                    }
                    component.set("v.relatedAccountIds", relatedAccountIds);
                }

            } else if (state === "INCOMPLETE") {
                console.log('incomplete');
                alert('There was an error retrieving your records. Please refresh and try again. If issues persist, please contact an administrator.')
            } else if (state === "ERROR") {
                alert('There was an error retrieving your records. Please refresh and try again. If issues persist, please contact an administrator.')
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                    console.log(errors);
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    itemSelectedAffiliations : function(component) {

        component.set("v.accounts", null);
        component.set("v.showResults", false);

        $A.util.toggleClass(component.find("loadingSpinner"), "slds-hide");

        var action = component.get("c.insertAffiliation");
        action.setParams({
            accountRecordId: component.get("v.accountRecordId"),
            isJoinProcessPageAndExistingAffiliation: false,
            isNoOrganization: component.get("v.noOrganization")
        });


        action.setCallback(this, function(response) {

            $A.util.toggleClass(component.find("loadingSpinner"), "slds-hide");

            //component.set("v.isLoading", false);

            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();

                if(!response.getReturnValue()['Status']) {
                    alert('There was an error retrieving your records. Please refresh and try again. If issues persist, please contact an administrator.')
                    return;
                }

                component.set("v.accounts", null);
                component.set("v.showResults", false);
                component.set("v.showModal", false);

            } else if (state === "INCOMPLETE") {
                console.log('incomplete');
                alert('There was an error retrieving your records. Please refresh and try again. If issues persist, please contact an administrator.')
            } else if (state === "ERROR") {
                alert('There was an error retrieving your records. Please refresh and try again. If issues persist, please contact an administrator.')
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                    console.log(errors);
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    noOrganizationSelected : function (component) {
        if (component.get("v.noOrganization")) {
            component.set("v.accounts", null);
            component.set("v.showResults", false);
            component.set("v.searchValue", "");
            if (component.get("v.isJoinProcessPage")) {
                this.itemSelectedJoinProcess(component);
            } else {
                this.itemSelectedAffiliations(component);
            }
        }
    },

})