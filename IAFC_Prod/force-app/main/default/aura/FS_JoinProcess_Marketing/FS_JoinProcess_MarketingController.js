({
    init: function(component, event, helper) {
        helper.init(component, helper);
    },

    next: function(component, event, helper) {
        helper.nextStep(component, '');
    },

    back: function(component, event, helper) {
        component.set("v.currentPage", 'VerifyProfile');
    }
})