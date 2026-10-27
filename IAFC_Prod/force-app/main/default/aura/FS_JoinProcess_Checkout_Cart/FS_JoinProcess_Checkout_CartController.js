({
    collapse: function(component, event, helper) {
        helper.collapseHelper(component,event,'addOnList');
    },

    remove: function(component, event, helper) {
        helper.removeHelper(component, event);
    },

    checkout: function(component, event, helper) {
        helper.checkoutHelper(component);
    },
})