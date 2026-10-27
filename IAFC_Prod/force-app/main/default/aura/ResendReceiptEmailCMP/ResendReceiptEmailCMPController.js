({
    doInit: function(component, event, helper){
        component.set("v.isEmailOpen", true);
    },
   
  closeModel: function(component, event, helper) {
      // Set isModalOpen attribute to false  
      component.set("v.isEmailOpen", false);
   },
  
   submitDetails: function(component, event, helper) {
       var action = component.get('c.ResendEmail'); 
        action.setParams({
            ReceiptId : component.get('v.recordId'),
            Email : component.get('v.Email')
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                component.set("v.isEmailOpen", false);
               component.set("v.isMailSent", true);
                
            }
        });
        $A.enqueueAction(action);
    }
      
   
    
})