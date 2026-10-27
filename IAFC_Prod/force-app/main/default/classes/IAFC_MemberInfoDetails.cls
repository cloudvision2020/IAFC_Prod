public class IAFC_MemberInfoDetails {
@AuraEnabled(cacheable=true)
    public static Contact getUserDetails(String recId) {
        Contact currentContact = new Contact();
        try {
        	User currentUser = [Select Id , ContactId from User where Id =:recId];
        	currentContact = [Select Id, Original_Join_Date__c, Membership_Expiration__c, Division__c, Sections__c from Contact where Id = :currentUser.ContactId];
        } 
        catch(Exception ex){
            return new Contact();
        }
        return currentContact;
    }
}