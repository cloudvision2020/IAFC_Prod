({
    init: function(component, event, helper) {
        helper.init(component);
    },

    selectAddOn: function(component, event, helper) {
        helper.selectAndUnSelectAddOn(component, event);
    },

    back: function(component, event, helper) {
        component.set("v.salesOrder", component.get("v.salesOrder"));
        if (component.get("v.hasOnlyOneSubscriptionOption") || component.get("v.showCartDirectly")) {
            component.set("v.showCartDirectly", false);
            component.set("v.currentPage", 'VerifyProfile');
        } else {
            component.set("v.currentPage", 'Marketing');
        }

    },

    hideModal: function(component, event, helper) {
        console.log(component.get("v.addOnsSelected"));
        component.set("v.showModal", false);
    },

    payNow: function(component, event, helper) {
        window.location.href = component.get("v.paymentURL");
    },

    printInvoice: function(component, event, helper) {
        window.open('/apex/LTE__ViewDocument?recordId=' + component.get("v.encryptedId"));
       // window.open('/apex/FSP_APP__PageRenderer?template_id=' + component.get("v.pageTemplateId") + '&object_id=' + component.get("v.salesOrder")["Id"]);
       // if (component.get("v.checkoutPagePrintInvoiceButtonBehavior") === "Redirect" && component.get("v.checkoutPagePrintInvoiceButtonRedirectLink") !== "") {
        //    setTimeout(function(){ window.location.href = component.get("v.checkoutPagePrintInvoiceButtonRedirectLink"); }, 500);
       // }
    }
})