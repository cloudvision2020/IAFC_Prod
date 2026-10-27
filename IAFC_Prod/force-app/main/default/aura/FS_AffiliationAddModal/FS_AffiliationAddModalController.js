/**
 * Created by dwu on 2019-01-22.
 */
({
    closeModal : function(component, event, helper) {
        component.set("v.showModal", false);
    },

    getSearchResults : function(component, event, helper) {
        if(component.get("v.searchValue") == '' || component.get("v.searchValue").length < 3) {
            component.set("v.accounts", null);
            component.set("v.showResults", false);
            return;
        }

        var timerId = component.get("v.timerId");
        if(!$A.util.isUndefinedOrNull(timerId)) {
            window.clearTimeout(timerId);
        }

        timerId = window.setTimeout(
            $A.getCallback(function() {
                helper.search(component, helper);
                component.set("v.timerId", null);
                window.clearTimeout(timerId);
            })

            , 400);

        component.set("v.timerId", timerId);
    },

    itemSelectedTriggerConfirm : function(component, event, helper) {
        if (component.get("v.isJoinProcessPage")) {
            var relatedAccountIds = component.get("v.relatedAccountIds");
            var accountIdSelected = event.currentTarget.getAttribute("data-recordId");

            if (relatedAccountIds.includes(accountIdSelected)) {
                component.set("v.isJoinProcessPageAndExistingAffiliation", true);
                component.set("v.confirmModalContent", "Are you sure you wish to change the primary organization to this account: " + event.currentTarget.getAttribute("data-recordName"));
            } else {
                component.set("v.confirmModalContent", "Are you sure you wish to add this account as an affiliation and make this as the primary organization: " + event.currentTarget.getAttribute("data-recordName"));
            }

            component.set("v.currentModalType", "itemSelectedJoinProcess");
            component.set("v.showConfirmModal", true);
            component.set("v.accountRecordId", event.currentTarget.getAttribute("data-recordId"));
        } else {
            component.set("v.currentModalType", "itemSelectedAffiliations");
            component.set("v.confirmModalContent", "Are you sure you wish to add this account as an affiliation: " + event.currentTarget.getAttribute("data-recordName"));
            component.set("v.showConfirmModal", true);
            component.set("v.accountRecordId", event.currentTarget.getAttribute("data-recordId"));
        }
    },

    createNewAccount : function(component, event, helper) {
        component.set("v.accounts", null);
        component.set("v.showResults", false);
        component.set("v.showModal", false);
        component.set("v.showNewAccountModal", true);
    },

    noOrganizationSelectedTriggerConfirm : function (component, event, helper) {
        if (component.get("v.noOrganization")) {
            component.set("v.currentModalType", "noOrgSelected");
            component.set("v.confirmModalContent", "Are you sure you have no related organization?");
            component.set("v.showConfirmModal", true);
        }
    },

    closeConfirmModel : function(component, event, helper) {
        if (component.get("v.currentModalType") === "noOrgSelected") {
            component.set("v.noOrganization", false);
        }
        component.set("v.currentModalType", "");
        component.set("v.isJoinProcessPageAndExistingAffiliation", false);
        component.set("v.showConfirmModal", false);
    },

    saveConfirmModel : function(component, event, helper) {
        if (component.get("v.currentModalType") === "noOrgSelected") {
            helper.noOrganizationSelected(component);
        } else if (component.get("v.currentModalType") === "itemSelectedAffiliations") {
            helper.itemSelectedAffiliations(component);
        } else if (component.get("v.currentModalType") === "itemSelectedJoinProcess") {
            helper.itemSelectedJoinProcess(component);
        }
        component.set("v.showConfirmModal", false);
        component.set("v.isJoinProcessPageAndExistingAffiliation", false);
    },

})