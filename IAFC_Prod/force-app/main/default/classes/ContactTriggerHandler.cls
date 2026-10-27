public without sharing class ContactTriggerHandler{
    
    public static void beforeInsert(List<Contact> newList) {
        //updateAddress(newList,null,null);
    }
    
    public static void afterInsert(List<Contact> newList, Map<ID,Contact> newMap) {}
    
    public static void beforeUpdate(List<Contact> newList, Map<Id,Contact> newMap, Map<Id,Contact> oldMap) {
        //updateAddress(newList,newMap,oldMap);
        updateBadges(newList,newMap,oldMap);
    }
    
    public static void afterUpdate(List<Contact> newList, Map<Id,Contact> newMap, Map<Id,Contact> oldMap) {}
    
    public static void updateBadges(List<Contact> newList, Map<Id,Contact> newMap, Map<Id,Contact> oldMap) {
        // Set to collect all Contact IDs that need processing
        Map<Id,Contact> contactIdsToProcess = new Map<Id,Contact>();
        
        // Collect Account IDs from the Accounts being inserted/updated
        for(Contact con : newList){
            if(con.IAFC_Member__c && String.isNotBlank(con.Membership_Type__c)){
                contactIdsToProcess.put(con.Id,con);
            }
        }
        // Only proceed if there are Contact IDs to process
        if(contactIdsToProcess.size() > 0){
            // Query all related Contacts
            List<PagesApi__Community_Group_Member__c> relatedGroupMember = [SELECT Id, Name, PagesApi__Contact__c, Community_Group_Display_Name__c,PagesApi__Status__c FROM PagesApi__Community_Group_Member__c WHERE PagesApi__Contact__c IN: contactIdsToProcess.keySet()];
            // Map to hold Account IDs and their corresponding Contact Names
            Map<Id, List<String>> ContactToGMBadges = new Map<Id, List<String>>();
            // Only proceed if there are Community Group Member IDs to process
            if(!relatedGroupMember.isEmpty()){
                // Populate the map with Contact names
                for(PagesApi__Community_Group_Member__c groupMember : relatedGroupMember){
                    if(groupMember.PagesApi__Status__c == 'Active'){
                        if(!ContactToGMBadges.containsKey(groupMember.PagesApi__Contact__c)){
                            ContactToGMBadges.put(groupMember.PagesApi__Contact__c, new List<String>());
                        }
                        ContactToGMBadges.get(groupMember.PagesApi__Contact__c).add(groupMember.Community_Group_Display_Name__c);
                    }
                }                
                // Contact's Badges update
                for(Contact con : newList){
                    if(contactToGMBadges != null && contactToGMBadges.containsKey(con.Id)){
                        con.Tag__c = con.Membership_Type__c+', '+String.join(contactToGMBadges.get(con.Id), ', ');
                    }else{
                        con.Tag__c = con.Membership_Type__c;
                    }
                }
            }
        }    
    }
    
    public static void updateAddress(List<Contact> newList, Map<Id,Contact> newMap, Map<Id,Contact> oldMap){
        /*// Set to collect all Account IDs that need processing
        Set<Id> accountIds = new Set<Id>();
        
        // Collect Account IDs from the Contacts being inserted/updated
        for(Contact con : newList){
            if (String.isNotBlank(con.AccountId)){
                accountIds.add(con.AccountId);
            }
        }        
        // Only proceed if there are Account IDs to process
        if(!accountIds.isEmpty()){
            // Query Accounts based on the collected Account IDs
            Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE Id IN: accountIds]);
            // Update Contact Mailing Address fields with Account Billing Address fields
            for(Contact con : newList){
                //Update Contact Mailing Address
                if(con.AccountId != null && accountMap.containsKey(con.AccountId)){
                    Account acc = accountMap.get(con.AccountId);
                    con.MailingStreet = acc.BillingStreet;
                    con.MailingCity = acc.BillingCity;
                    con.MailingState = acc.BillingState;
                    con.MailingPostalCode = acc.BillingPostalCode;
                    con.MailingCountry = acc.BillingCountry;
                }
            }
        }*/
    }
}