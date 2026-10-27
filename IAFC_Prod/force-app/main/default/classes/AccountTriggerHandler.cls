public without sharing class AccountTriggerHandler{
    
    public static void beforeInsert(List<Account> newList) {}
    
    public static void afterInsert(List<Account> newList, Map<ID,Account> newMap) {
        //updateAddress(newList,newMap,null);
    }
    
    public static void beforeUpdate(List<Account> newList, Map<Id,Account> newMap, Map<Id,Account> oldMap) {}
    
    public static void afterUpdate(List<Account> newList, Map<Id,Account> newMap, Map<Id,Account> oldMap) {
        //updateAddress(newList,newMap,oldMap);
    }
    
    public static void updateAddress(List<Account> newList, Map<Id,Account> newMap, Map<Id,Account> oldMap) {
        /*// List to hold contacts that need to be updated
        list<Contact> contactsToUpdate = new list<Contact>();
        // Set to collect all Account IDs that need processing
        Set<Id> accountIds = new Set<Id>();
        
        // Populate the set with Account IDs
        for(Account acc : newList){
            if(oldMap == null || (oldMap != null && (acc.BillingStreet != oldMap.get(acc.Id).BillingStreet || acc.BillingCity != oldMap.get(acc.Id).BillingCity || acc.BillingState != oldMap.get(acc.Id).BillingState || acc.BillingPostalCode != oldMap.get(acc.Id).BillingPostalCode || acc.BillingCountry != oldMap.get(acc.Id).BillingCountry))){
                accountIds.add(acc.Id);   
            }
        }
        // Only proceed if there are Account IDs to process
        if(!accountIds.isEmpty()){
            // Query all related Contacts
            for(Contact con : [SELECT Id,AccountId FROM Contact WHERE AccountId IN: accountIds]){
                // Update each Contact's with the Account's value
                Account acc = newMap.get(con.AccountId);
                con.MailingStreet = acc.BillingStreet;
                con.MailingCity = acc.BillingCity;
                con.MailingState = acc.BillingState;
                con.MailingPostalCode = acc.BillingPostalCode;
                con.MailingCountry = acc.BillingCountry;
                contactsToUpdate.add(con);
            }
            // Perform the update DML operation if there are contacts to update
            if(!contactsToUpdate.isEmpty()){
                update contactsToUpdate;
            }
        }  */      
    }
}