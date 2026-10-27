/**
 * Created by dwu on 2019-01-23.
 */
({

    countryStateMap: {

    },

    countryOptions: [

    ],

    getCountryStateOptions: function(component, event, helper) {
        var action = component.get("c.getJSONCountriesAndStates");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                this.countryOptions = result['countriesInfo'];
                this.countryStateMap = result['statesInfo'];
                component.set("v.billingCountryOptions", this.countryOptions);
                component.set("v.billingStateOptions", this.countryStateMap[component.get("v.accountRecord.BillingCountryCode")]);
            }
        });
        $A.enqueueAction(action);
    },

    getPopulationPicklistValues: function(component, event , helper) {
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
    }


})