@isTest
public class CommunityGroupMemberTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(LastName = 'Test Contact ' + i, Membership_Type__c = 'Associate'));
        }
        insert contacts;
        
        PagesApi__Community_Group__c cg = new PagesApi__Community_Group__c();
        cg.Name = 'Test';
        insert cg;

        // Create test Community Group Members
        List<PagesApi__Community_Group_Member__c> groupMembers = new List<PagesApi__Community_Group_Member__c>();
        for (Contact con : contacts) {
            groupMembers.add(new PagesApi__Community_Group_Member__c(PagesApi__Contact__c = con.Id, PagesApi__Status__c = 'Active', PagesApi__Community_Group__c = cg.Id));
        }
        insert groupMembers;
    }
    
    @isTest
    static void testCommunityGroupMemberTriggerHandler() {
        List<PagesApi__Community_Group_Member__c> groupMembers = [SELECT Id, PagesApi__Contact__c FROM PagesApi__Community_Group_Member__c];
        for (PagesApi__Community_Group_Member__c member : groupMembers) {
            member.PagesApi__Status__c = 'Inactive';
        }
        update groupMembers;
        
        List<Contact> contacts = [SELECT Tag__c FROM Contact];
        for (Contact con : contacts) {
            System.assertNotEquals(null, con.Tag__c);
        }
    }
}