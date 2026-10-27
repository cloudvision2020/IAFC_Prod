({
    countryStateMap: {

    },

    countryOptions: [

    ],

    getPopulationPicklistValues: function(component) {
        var action = component.get("c.getPopulationPicklistValues");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();

                var picklistValues = [];
                for(var key in result){
                    picklistValues.push({value:result[key], key:key});
                }

                component.set("v.accountRecord.Population_Served_Size__c", picklistValues);
            }
        });
        $A.enqueueAction(action);
    },

    getContact: function(component) {
        var action = component.get("c.getContact");
        action.setParams({
            userId: $A.get("$SObjectType.CurrentUser.Id")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.currentContact", result['Contact']);
                component.set("v.currentOrganization", result['Contact']['Account']['Name']);
                component.set("v.salesOrder", result['Sales Order']);
                component.set("v.relatedAccountIds", result['Related Account Ids']);
            }
        });
        $A.enqueueAction(action);
    },

    getCountryStateOptions: function(component) {
        var action = component.get("c.getJSONCountriesAndStates");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                this.countryOptions = result['countriesInfo'];
                this.countryStateMap = result['statesInfo'];
                component.set("v.mailingCountryOptions", this.countryOptions);
                component.set("v.mailingStateOptions", this.countryStateMap[component.get("v.currentContact.MailingCountryCode")]);
            }
        });
        $A.enqueueAction(action);
    },

    getPreferredEmailTypeOptions: function(component) {
        var action = component.get("c.getPreferredEmailTypeOptions");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.preferredEmailTypeOptions", result);
            }
        });
        $A.enqueueAction(action);
    },

    getPreferredPhoneTypeOptions: function(component) {
        var action = component.get("c.getPreferredPhoneTypeOptions");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.preferredPhoneTypeOptions", result);
            }
        });
        $A.enqueueAction(action);
    },

    getJobFunctionOptions: function(component) {
        var action = component.get("c.getJobFunctionOptions");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.jobFunctionOptions", result);
            }
        });
        $A.enqueueAction(action);
    },

    nextStep: function(component) {
        var validForm = component.find('field').reduce(function (validSoFar, inputCmp) {
            // Displays error messages for invalid fields
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);

        var isCountryEmpty = component.get("v.currentContact")['MailingCountryCode'] === '';
        var isCompanyEmpty = component.get("v.currentContact")['Account']['Name']=== '!Unknown Organization';

        let isDepartmentalMembershipJoin = component.get("v.isDepartmentalMembershipJoin");

        if (isDepartmentalMembershipJoin && component.get("v.currentOrganization") != component.get("v.currentContact")['Account']['Name']) {
            // debugger;
            this.showToast(component, "You can no longer purchase this for your Department, since your 'Primary Organization' has changed", "warning", "Warning!");
            let windowUrl = window.location.host;
            window.open('https://' + windowUrl + '/#em-subscriptions','_top');
            return false;
        }
        if (isCountryEmpty) {
            alert("You must select a country.");
        } else if (isCompanyEmpty){
            alert("You must select a company.");
        } else {
            if (validForm) {
                this.toggleSpinner(component);

                if (component.get("v.onlyShowVerifyMyProfilePage")) {
                    var action = component.get("c.updateContact");
                    action.setParams({
                        currentContact: component.get("v.currentContact"),
                        onlyShowVerifyMyProfilePage: true
                    });
                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        this.toggleSpinner(component);
                        if (state === "SUCCESS") {
                            var result = response.getReturnValue();
                            if (result !== null) {
                                this.showToast(component, "Updated.", "success", "Success!");
                                if (component.get("v.profilePageButtonBehavior") === "Redirect" && component.get("v.profilePageButtonRedirectLink") !== "") {
                                    setTimeout(function(){ window.location.href = component.get("v.profilePageButtonRedirectLink"); }, 2000);
                                } else {
                                    setTimeout(function(){ window.location.reload(true); }, 2000);
                                }
                            } else {
                                this.showToast(component, "Error.", "error", "Error!");
                                setTimeout(function(){ window.location.reload(true); }, 2000);
                            }
                        } else {
                            this.showToast(component, state, "error", "Error!");
                            setTimeout(function(){ window.location.reload(true); }, 2000);
                        }
                    });
                    $A.enqueueAction(action);
                } else {
                    var salesOrder = component.get("v.salesOrder");
                    var membershipItemId = null;
                    var membershipItemSalesOrderLineId = null;
                    var divisionItemId = null;
                    var divisionItemSalesOrderLineId = null;
                    if (typeof salesOrder !== "undefined") {
                        salesOrder['OrderApi__Sales_Order_Lines__r'].forEach(function (salesOrderLine) {
                            if (salesOrderLine['OrderApi__Subscription_Plan__c']) {
                                membershipItemId = salesOrderLine['OrderApi__Item__c'];
                                membershipItemSalesOrderLineId = salesOrderLine['Id'];
                            }
                            if (salesOrderLine['OrderApi__Item__r']['Name'].includes(' Division Dues') && salesOrderLine['OrderApi__Item_Class__r']['Name'] === 'Divisions') {
                                divisionItemId = salesOrderLine['OrderApi__Item__c'];
                                divisionItemSalesOrderLineId = salesOrderLine['Id'];
                            }
                        });
                    } else {
                        salesOrder = null;
                    }
                    var action = component.get("c.updateContact");
                    action.setParams({
                        currentContact: component.get("v.currentContact"),
                        membershipItemId: membershipItemId,
                        membershipItemSalesOrderLineId: membershipItemSalesOrderLineId,
                        divisionItemId: divisionItemId,
                        divisionItemSalesOrderLineId: divisionItemSalesOrderLineId,
                        salesOrderId: salesOrder !== null ? salesOrder['Id'] : null,
                        isDepartmentalMembershipJoin: component.get("v.isDepartmentalMembershipJoin"),
                        onlyShowVerifyMyProfilePage: false
                    });

                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        this.toggleSpinner(component);
                        if (state === "SUCCESS") {
                            var result = response.getReturnValue();
                            if (!result['Exception']) {
                                if (result['Show Error Message']) {
                                    if (component.get("v.isDepartmentalMembershipJoin")) {
                                        this.showToast(component, "You can no longer purchase this for your Department, since your department already has an active subscription.", "warning", "Warning!");
                                        return;
                                    } else {
                                        this.showToast(component, "You can no longer purchase this, since you already have an active subscription.", "warning", "Warning!");
                                        return;
                                    }
                                }
                                component.set("v.currentContact", result['Contact']);
                                component.set("v.salesOrder", result['Sales Order']);
                                component.set("v.currentPage", 'Marketing');
                            } else {
                                if (result['Exception'] === 'UniqueEmail') {
                                    this.showToast(component, $A.get("$Label.c.FS_Join_Process_Duplicate_Emails_Alert_Message"), "warning", "Warning!");
                                    return;
                                } else {
                                    this.showToast(component, "Encountered an error, please contact administrator.", "warning", "Warning!");
                                    return;
                                }
                            }
                        } else {
                            alert(state);
                        }
                    });
                    $A.enqueueAction(action);
                }
            }
        }
    },

    toggleSpinner: function(component) {
        var spinner = component.find("loadingSpinner");
        $A.util.toggleClass(spinner, "slds-hide");
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