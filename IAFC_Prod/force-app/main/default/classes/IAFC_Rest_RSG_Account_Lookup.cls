@RestResource(urlMapping='/customer/rsgaccounts/*')
global class IAFC_Rest_RSG_Account_Lookup {
    
    @HttpGet
    global static list<RSG_Account__c> rsgAccountLookup(){
        RestResponse res = RestContext.response;
        List<string> AccountIds = new List<string>();
        ID contactid;

        //make sure it's a valid ID
        if(!(RestContext.request.params.get('id') instanceOf  Id)){
            
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Invalid ID');
            return null;
        }
        Id id = RestContext.request.params.get('id'); 
        

        //If it's a user ID get the contact id with it
        if(id.getsobjecttype() == Schema.User.SObjectType){
            Map<Id,User> UserLookup = new Map<Id,User>([Select Id,ContactId from User where Id = :id]);
            contactid = UserLookup.get(id).ContactId;
        }

        //get all qualifying accounts
        List<AccountContactRelation> r = new List<AccountContactRelation>([Select AccountId from AccountContactRelation where ContactId = :id and IsActive = true and Internal_Account_Only__c = false]);
        for(AccountContactRelation x:r){
            AccountIds.add(x.AccountId);
        }

        //get their RSG accounts if they have them
        List<RSG_Account__c> rsg = [Select Id, Mailing_City__c, Mailing_State_Code__c, Description__c,Department_Type__c, Description_Other__c,Public_Education__c, Account__c, Account_Name__c 
         from RSG_Account__c where Account__c in :AccountIds];
        

        return rsg;
    }
}