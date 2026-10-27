public without sharing class CommunityGroupMemberTriggerHandler {
    
    public static void beforeInsert(List<PagesApi__Community_Group_Member__c> newList) {}
    
    public static void afterInsert(List<PagesApi__Community_Group_Member__c> newList, Map<ID,PagesApi__Community_Group_Member__c> newMap) {
        updateBadges(newList,null,null);
    }
    
    public static void beforeUpdate(List<PagesApi__Community_Group_Member__c> newList, Map<Id,PagesApi__Community_Group_Member__c> newMap, Map<Id,PagesApi__Community_Group_Member__c> oldMap) {}
    
    public static void afterUpdate(List<PagesApi__Community_Group_Member__c> newList, Map<Id,PagesApi__Community_Group_Member__c> newMap, Map<Id,PagesApi__Community_Group_Member__c> oldMap) {
        updateBadges(newList,newMap,oldMap);
    }
    
    public static void updateBadges(List<PagesApi__Community_Group_Member__c> newList, Map<Id,PagesApi__Community_Group_Member__c> newMap, Map<Id,PagesApi__Community_Group_Member__c> oldMap) {
        // Set to collect all Contact IDs that need processing
        Map<Id,String> contactIdsToProcess = new Map<Id,String>();
        
        // Add Contact IDs from Trigger.new (insert, update, undelete)
        for(PagesApi__Community_Group_Member__c GroupMember : newList){
            if(String.isNotBlank(GroupMember.PagesApi__Contact__c) && (oldMap == null || (oldMap != null && GroupMember.PagesApi__Status__c != oldMap.get(GroupMember.Id).PagesApi__Status__c))){
                contactIdsToProcess.put(GroupMember.PagesApi__Contact__c,GroupMember.PagesApi__Contact__r.Membership_Type__c);
            }
        }
        // Only proceed if there are Contact IDs to process
        if(contactIdsToProcess.size() > 0){
            // Query all related Community Group Members
            List<PagesApi__Community_Group_Member__c> relatedGroupMembers = [SELECT Id, Name, PagesApi__Contact__c, Community_Group_Display_Name__c,PagesApi__Status__c FROM PagesApi__Community_Group_Member__c WHERE PagesApi__Contact__c IN: contactIdsToProcess.keySet() AND PagesApi__Contact__r.IAFC_Member__c = true AND PagesApi__Contact__r.Membership_Type__c != ''];
            // Map to hold Account IDs and their corresponding Contact Names
            Map<Id, List<String>> contactToGMBadges = new Map<Id, List<String>>();
            // Only proceed if there are Community Group Member IDs to process
            if(!relatedGroupMembers.isEmpty()){
                // Populate the map with Contact names
                for(PagesApi__Community_Group_Member__c GroupMember : relatedGroupMembers){
                    if(GroupMember.PagesApi__Status__c == 'Active'){
                        if (!contactToGMBadges.containsKey(GroupMember.PagesApi__Contact__c)){
                            contactToGMBadges.put(GroupMember.PagesApi__Contact__c, new List<String>());
                        }
                        contactToGMBadges.get(GroupMember.PagesApi__Contact__c).add(GroupMember.Community_Group_Display_Name__c);
                    }
                }
                // List to hold accounts to update
                List<Contact> ContactsToUpdate = new List<Contact>();
                
                // Create Account updates
                for(Id ContactId : contactIdsToProcess.keySet()){
                    System.debug('Testmmnmnm '+contactIdsToProcess.get(ContactId));
                    Contact con = new Contact(Id = ContactId);
                    if(contactToGMBadges != null && contactToGMBadges.containsKey(ContactId)){
                        con.Tag__c = contactIdsToProcess.get(ContactId)+', '+String.join(contactToGMBadges.get(ContactId), ', ');
                    }else{
                        con.Tag__c = contactIdsToProcess.get(ContactId);
                    }
                    ContactsToUpdate.add(con);
                }                
                // Perform the update DML operation if there are accounts to update
                if(!ContactsToUpdate.isEmpty()){
                    update ContactsToUpdate;
                }
            }
        }
    }
}