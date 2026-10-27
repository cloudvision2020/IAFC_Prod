@isTest
private class SubscriptionLineItemJoinActionTest {

    @TestSetup
    static void setupData() {
        Id itemClassId = 'a111N0000068cZfQAI';

        Contact activeContact = new Contact(
            LastName = 'ActiveMember',
            Membership_Type__c = 'Full'
        );
        Contact formerContact = new Contact(
            LastName = 'FormerMember',
            Membership_Type__c = 'Former'
        );
        insert new List<Contact>{ activeContact, formerContact };

        OrderApi__Item__c item = new OrderApi__Item__c(
            Name = 'Section A',
            OrderApi__Item_Class__c = itemClassId
        );
        insert item;

        // Parent Subscription (required by Subscription Line)
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        OrderApi__Subscription__c subscription = new OrderApi__Subscription__c(
            OrderApi__Account__c = acct.Id
        );
        insert subscription;

        OrderApi__Subscription_Line__c subLine = new OrderApi__Subscription_Line__c(
            Contact__c = activeContact.Id,
            OrderApi__Item__c = item.Id,
            OrderApi__Item_Class__c = itemClassId,
            OrderApi__Subscription__c = subscription.Id
        );
        insert subLine;
    }
    @isTest
    static void testActiveContactGetsSections() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'ActiveMember' LIMIT 1];

        SubscriptionLineItemJoinAction.Request req = new SubscriptionLineItemJoinAction.Request();
        req.contactId = c.Id;

        Test.startTest();
        List<SubscriptionLineItemJoinAction.Result> results =
            SubscriptionLineItemJoinAction.updateContactActiveSections(
                new List<SubscriptionLineItemJoinAction.Request>{ req });
        Test.stopTest();

        Contact updated = [SELECT Active_Sections__c FROM Contact WHERE Id = :c.Id];
        
    }

    @isTest
    static void testFormerContactBlanked() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'FormerMember' LIMIT 1];

        SubscriptionLineItemJoinAction.Request req = new SubscriptionLineItemJoinAction.Request();
        req.contactId = c.Id;

        Test.startTest();
        List<SubscriptionLineItemJoinAction.Result> results =
            SubscriptionLineItemJoinAction.updateContactActiveSections(
                new List<SubscriptionLineItemJoinAction.Request>{ req });
        Test.stopTest();
    }

    @isTest
    static void testMixedContacts() {
        Contact active = [SELECT Id FROM Contact WHERE LastName = 'ActiveMember' LIMIT 1];
        Contact former = [SELECT Id FROM Contact WHERE LastName = 'FormerMember' LIMIT 1];

        SubscriptionLineItemJoinAction.Request r1 = new SubscriptionLineItemJoinAction.Request();
        r1.contactId = active.Id;
        SubscriptionLineItemJoinAction.Request r2 = new SubscriptionLineItemJoinAction.Request();
        r2.contactId = former.Id;

        Test.startTest();
        List<SubscriptionLineItemJoinAction.Result> results =
            SubscriptionLineItemJoinAction.updateContactActiveSections(
                new List<SubscriptionLineItemJoinAction.Request>{ r1, r2 });
        Test.stopTest();
    }

    @isTest
    static void testEmptyRequest() {
        Test.startTest();
        List<SubscriptionLineItemJoinAction.Result> emptyResults =
            SubscriptionLineItemJoinAction.updateContactActiveSections(
                new List<SubscriptionLineItemJoinAction.Request>());
        List<SubscriptionLineItemJoinAction.Result> nullResults =
            SubscriptionLineItemJoinAction.updateContactActiveSections(null);
        Test.stopTest();
    }

    @isTest
    static void testNullContactIdInRequest() {
        SubscriptionLineItemJoinAction.Request req = new SubscriptionLineItemJoinAction.Request();
        req.contactId = null;

        Test.startTest();
        List<SubscriptionLineItemJoinAction.Result> results =
            SubscriptionLineItemJoinAction.updateContactActiveSections(
                new List<SubscriptionLineItemJoinAction.Request>{ req });
        Test.stopTest();
    }
}