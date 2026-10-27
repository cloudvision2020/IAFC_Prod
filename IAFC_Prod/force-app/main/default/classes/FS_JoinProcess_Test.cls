@isTest
public class FS_JoinProcess_Test {
    @TestSetup
    private static void setup() {
        OrderApi__Business_Group__c businessGroup = new OrderApi__Business_Group__c(Name='International Society of Automation');
        insert businessGroup;
        
        OrderApi__Item_Class__c itemClass = new OrderApi__Item_Class__c(Name='Test',
                                                                        OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id);
        insert itemClass;
        OrderApi__Item_Class__c itemClass1 = new OrderApi__Item_Class__c(Name='Sections',
                                                                         OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id);
        insert itemClass1;
        OrderApi__Item_Class__c itemClass2 = new OrderApi__Item_Class__c(Name='Divisions',
                                                                         OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id);
        insert itemClass2;
        OrderApi__Item__c item = new OrderApi__Item__c(Name='Basic Membership', OrderApi__Item_Class__c=itemClass.Id,
                                                       OrderApi__Business_Group__c=businessGroup.Id, FS_Item_Functional_Titles__c='2-3 Crossed Bugle Chief Officer; 4 Crossed Bugle Chief Officer', OrderApi__Is_Active__c=true);
        insert item;
        OrderApi__Item__c item1 = new OrderApi__Item__c(Name='Test', OrderApi__Item_Class__c=itemClass1.Id,
                                                        OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Active__c=true, FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert item1;

        OrderApi__Item__c item4 = new OrderApi__Item__c(Name='Test222', OrderApi__Item_Class__c=itemClass1.Id,
                                                        OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Active__c=true, FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert item4;
        
        OrderApi__Item__c item2 = new OrderApi__Item__c(Name='New Member Fee', OrderApi__Item_Class__c=itemClass.Id,
                                                        OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Active__c=true, FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert item2;
        
        OrderApi__Item__c item3 = new OrderApi__Item__c(Name='Eastern Division Dues', OrderApi__Item_Class__c=itemClass2.Id,
                                                        OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Active__c=true, FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert item3;
        
        OrderApi__Subscription_Plan__c subscriptionPlan = new OrderApi__Subscription_Plan__c(Name='1 Year', OrderApi__Initial_Term_Months__c=12);
        insert subscriptionPlan;
        
        OrderApi__Item_Subscription_Plan__c itemSubscriptionPlan = new OrderApi__Item_Subscription_Plan__c(OrderApi__Item__c=item.Id, OrderApi__Subscription_Plan__c=subscriptionPlan.Id);
        insert itemSubscriptionPlan;
        
        Account account = new Account(Name='Test Account Name', Population_Served_Size__c='Less than 10,000');
        insert account;
        
        Contact contact = new Contact(LastName='test', AccountId=account.Id, MailingStateCode='MD', MailingCountryCode='US');
        insert contact;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Fonteva Customer Community Login User'];
        
        User user = new User(Alias='standt', Email='test@example.com',
                             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', ProfileId=p.Id,
                             TimeZoneSidKey='America/Los_Angeles', UserName='test@example.com', ContactId=contact.Id);
        insert user;
        
        Contact contact1 = new Contact(LastName='test1', AccountId=account.Id, MailingStateCode='MD',
                                       MailingCountryCode='US', Functional_Title__c='4 Crossed Bugle Chief Officer');
        insert contact1;
        
        OrderApi__Sales_Order__c salesOrder = new OrderApi__Sales_Order__c(OrderApi__Contact__c=contact1.Id);
        insert salesOrder;
        OrderApi__Sales_Order_Line__c salesOrderLine = new OrderApi__Sales_Order_Line__c(OrderApi__Item__c=item.Id, OrderApi__Sales_Order__c=salesOrder.Id, OrderApi__Subscription_Plan__c = subscriptionPlan.Id);
        insert salesOrderLine;
        OrderApi__Sales_Order_Line__c salesOrderLine1 = new OrderApi__Sales_Order_Line__c(OrderApi__Item__c=item1.Id, OrderApi__Sales_Order__c=salesOrder.Id , OrderApi__Subscription_Plan__c = subscriptionPlan.Id);
        insert salesOrderLine1;
        User user1 = new User(Alias='standt', Email='test@example.com',
                              EmailEncodingKey='UTF-8', LastName='Testing1Class', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId=p.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='test1@example.com', ContactId=contact1.Id);
        insert user1;
    }
    
    @isTest static void testFS_JoinProcess_VerifyProfile_Controller() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User adminUser = new User(Alias='admin', Email='admin@example.com',
                                  EmailEncodingKey='UTF-8', LastName='Admin', LanguageLocaleKey='en_US',
                                  LocaleSidKey='en_US', ProfileId=adminProfile.Id,
                                  TimeZoneSidKey='America/Los_Angeles', UserName='admin123@example.com');
        insert adminUser;
        
        
        Test.startTest();
        
        
        Map<String, Object> countriesAndStates = FS_JoinProcess_VerifyProfile_Controller.getJSONCountriesAndStates();
        System.assertEquals('US', ((List<Map<String, String>>) countriesAndStates.get('countriesInfo'))[0].get('value'));
        
        List<Map<String, String>> preferredEmailTypeOptions = FS_JoinProcess_VerifyProfile_Controller.getPreferredEmailTypeOptions();
        System.assertEquals(true, preferredEmailTypeOptions.size() > 0);
        
        List<Map<String, String>> preferredPhoneTypeOptions = FS_JoinProcess_VerifyProfile_Controller.getPreferredPhoneTypeOptions();
        System.assertEquals(true, preferredPhoneTypeOptions.size() > 0);
        
        List<Map<String, String>> jobFunctionOptions = FS_JoinProcess_VerifyProfile_Controller.getJobFunctionOptions();
        System.assertEquals(true, jobFunctionOptions.size() > 0);
        
        Map<String, Object> countriesAndStates2 = FS_JoinProcess_VerifyProfile_Controller.getJSONCountriesAndStates();
        System.assertEquals('US', ((List<Map<String, String>>) countriesAndStates.get('countriesInfo'))[0].get('value'));
        
        List<Map<String, String>> preferredEmailTypeOptions2 = FS_JoinProcess_VerifyProfile_Controller.getPreferredEmailTypeOptions();
        System.assertEquals(true, preferredEmailTypeOptions2.size() > 0);
        
        List<Map<String, String>> preferredPhoneTypeOptions2 = FS_JoinProcess_VerifyProfile_Controller.getPreferredPhoneTypeOptions();
        System.assertEquals(true, preferredPhoneTypeOptions2.size() > 0);
        
        List<Map<String, String>> jobFunctionOptions2 = FS_JoinProcess_VerifyProfile_Controller.getJobFunctionOptions();
        System.assertEquals(true, jobFunctionOptions2.size() > 0);
        System.debug([SELECT Id FROM User]);
        Contact testContact = (Contact) FS_JoinProcess_VerifyProfile_Controller.getContact([SELECT Id FROM User WHERE LastName='Testing1Class'][0].Id, null).get('Contact');
        OrderApi__Sales_Order__c salesOrder = (OrderApi__Sales_Order__c) FS_JoinProcess_VerifyProfile_Controller.getContact([SELECT Id FROM User WHERE LastName='Testing1Class'][0].Id, null).get('Sales Order');
        System.assertEquals('test1', testContact.LastName);
        FS_JoinProcess_VerifyProfile_Controller.updateContact(testContact, null, null, null, null, salesOrder.Id, false, false);
        
       
        Account testAccount2 = new Account(Name='New Account');
        Contact testContact11 = new Contact(LastName='1111');
        
        Map<String, String> picklistValues = FS_JoinProcess_VerifyProfile_Controller.getPopulationPicklistValues();
        
        //Map<String, Object> AccountInsert = FS_JoinProcess_VerifyProfile_Controller.insertAccount(testAccount2,testContact11);
    
        Test.stopTest();
   
    }
   @isTest static void testFS_JoinProcess_Marketing_Controller() {
        List<OrderApi__Item__c> membershipItems = FS_JoinProcess_Marketing_Controller.getMembershipItems('2-3 Crossed Bugle Chief Officer', false);
        System.assertEquals(1, membershipItems.size());
        Contact testContact = (Contact) FS_JoinProcess_VerifyProfile_Controller.getContact([SELECT Id FROM User WHERE LastName='Testing1Class'][0].Id, null).get('Contact');
        FS_JoinProcess_Marketing_Controller.createOrUpdateSalesOrder(testContact, [SELECT Id FROM OrderApi__Item__c][0].Id, [SELECT Id FROM OrderApi__Subscription_Plan__c][0].Id, [SELECT Id FROM OrderApi__Sales_Order__c][0].Id, false, true);
        FS_JoinProcess_Marketing_Controller.createOrUpdateSalesOrder(testContact, [SELECT Id FROM OrderApi__Item__c][0].Id, [SELECT Id FROM OrderApi__Subscription_Plan__c][0].Id, null, false, true);
        System.assertEquals('Less than 10,000', FS_JoinProcess_Marketing_Controller.getAccountPopulationServed([SELECT Id FROM Account WHERE Name = 'Test Account Name'][0].Id));
    }

    @isTest static void testFS_JoinProcess_Marketing_ControllerTest() {

        delete [Select id from OrderApi__Sales_Order_Line__c where OrderApi__Sales_Order__c=:[SELECT Id FROM OrderApi__Sales_Order__c][0].Id];
        OrderApi__Business_Group__c businessGroup = new OrderApi__Business_Group__c(Name='International Society of Automation');
        insert businessGroup;
        
        OrderApi__Item_Class__c itemClass = new OrderApi__Item_Class__c(Name='Testing',
                                                                        OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id);
        insert itemClass;

       
        OrderApi__Item__c item = new OrderApi__Item__c(Name='Testing', OrderApi__Item_Class__c=itemClass.Id,
                                                        OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Active__c=true, FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
         insert item;
        OrderApi__Sales_Order_Line__c salesOrderLine = new OrderApi__Sales_Order_Line__c(OrderApi__Item__c=item.Id, OrderApi__Sales_Order__c=[SELECT Id FROM OrderApi__Sales_Order__c][0].Id);
        insert salesOrderLine;

        List<OrderApi__Item__c> membershipItems = FS_JoinProcess_Marketing_Controller.getMembershipItems('2-3 Crossed Bugle Chief Officer', false);
        System.assertEquals(1, membershipItems.size());
        Contact testContact = (Contact) FS_JoinProcess_VerifyProfile_Controller.getContact([SELECT Id FROM User WHERE LastName='Testing1Class'][0].Id, null).get('Contact');

        FS_JoinProcess_Marketing_Controller.createOrUpdateSalesOrder(testContact, [SELECT Id FROM OrderApi__Item__c][0].Id, [SELECT Id FROM OrderApi__Subscription_Plan__c][0].Id, [SELECT Id FROM OrderApi__Sales_Order__c][0].Id, false, true);
       
        System.assertEquals('Less than 10,000', FS_JoinProcess_Marketing_Controller.getAccountPopulationServed([SELECT Id FROM Account WHERE Name = 'Test Account Name'][0].Id));
    }

@isTest static void testFS_JoinProcess_Marketing_AddOn_Controlle() {
    Id accountId = [SELECT Id FROM Account WHERE Name = 'Test Account Name'].Id;
    FS_JoinProcess_Marketing_AddOn_Controlle.initialization(accountId, [SELECT Id FROM OrderApi__Sales_Order__c][0]);
}

@isTest
    static void testFS_JoinProcess_Checkout_Cart_Controller() {
        List<Account> lstAcc = [Select Id from Account where Name=:'Test Account Name'];
        Account acc = new Account();
        acc = lstAcc[0];

        List<Contact> lstCon = [Select Id from Contact where AccountId=:lstAcc[0].Id];
        Contact testContact = new Contact();
        testContact = lstCon[0];


        //Contact testContact = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        //insert testContact;

        OrderApi__Sales_Order__c testSalesOrder = new OrderApi__Sales_Order__c(OrderApi__Contact__c=testContact.Id);
        insert testSalesOrder;

        OrderApi__Business_Group__c businessGroup = new OrderApi__Business_Group__c(Name='International Society of Automation');
        insert businessGroup;

        OrderApi__Item_Class__c itemClass = new OrderApi__Item_Class__c(Name='Test',
                                                                        OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id);
        insert itemClass;

        OrderApi__Item_Class__c itemClass1 = new OrderApi__Item_Class__c(Name='Sections',
                                                                        OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id);
        insert itemClass1;

        OrderApi__Item_Class__c itemClass2 = new OrderApi__Item_Class__c(Name='Divisions',
                                                                        OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id);
        insert itemClass2;

        OrderApi__Item__c testItem = new OrderApi__Item__c(Name = 'Test Item', OrderApi__Item_Class__c = itemClass.Id , FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert testItem;

        OrderApi__Item__c testItem1 = new OrderApi__Item__c(Name = 'Test Item 1', OrderApi__Item_Class__c = itemClass1.Id , FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert testItem1;

        OrderApi__Item__c testItem2 = new OrderApi__Item__c(Name = 'Test Item 2', OrderApi__Item_Class__c = itemClass2.Id , FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert testItem2;

        OrderApi__Item__c testItem3 = new OrderApi__Item__c(Name = 'Test Item 3', OrderApi__Item_Class__c = itemClass1.Id , FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert testItem3;

        OrderApi__Item__c testItem4 = new OrderApi__Item__c(Name = 'Test Item 4', OrderApi__Item_Class__c = itemClass1.Id , FS_Item_Functional_Titles__c = '2-3 Crossed Bugle Chief Officer');
        insert testItem4;

        List<OrderApi__Item__c> lstItem =[Select Id, OrderApi__Item__c, OrderApi__Item_Class__c, OrderApi__Item_Class__r.Name from 
                                            OrderApi__Item__c];
       
       
        Map<Id, Id> tempMap = new Map<Id, Id>();

        OrderApi__Subscription_Plan__c subscriptionPlan = new OrderApi__Subscription_Plan__c(
            Name = 'Test Subscription Plan',
            OrderApi__Initial_Term_Months__c = 24 
        );
        insert subscriptionPlan;

        OrderApi__Sales_Order_Line__c tempSalesOrderLine = new OrderApi__Sales_Order_Line__c(
            OrderApi__Item__c = testItem.Id,
            OrderApi__Sales_Order__c = testSalesOrder.Id,
            OrderApi__Subscription_Plan__c = subscriptionPlan.Id
        );
        insert tempSalesOrderLine;

        OrderApi__Sales_Order_Line__c tempSalesOrderLine1 = new OrderApi__Sales_Order_Line__c(
            OrderApi__Item__c = testItem1.Id,
            OrderApi__Sales_Order__c = testSalesOrder.Id,
            OrderApi__Sales_Order_Line__c = tempSalesOrderLine.Id,
            OrderApi__Subscription_Plan__c = subscriptionPlan.Id
        );
        insert tempSalesOrderLine1;

        OrderApi__Sales_Order_Line__c tempSalesOrderLine2 = new OrderApi__Sales_Order_Line__c(
            OrderApi__Item__c = testItem2.Id,
            OrderApi__Sales_Order__c = testSalesOrder.Id,
            OrderApi__Sales_Order_Line__c = tempSalesOrderLine.Id,
            OrderApi__Subscription_Plan__c = subscriptionPlan.Id
        );
        insert tempSalesOrderLine2;

        OrderApi__Sales_Order_Line__c tempSalesOrderLine3 = new OrderApi__Sales_Order_Line__c(
            OrderApi__Item__c = testItem3.Id,
            OrderApi__Sales_Order__c = testSalesOrder.Id,
            OrderApi__Subscription_Plan__c = subscriptionPlan.Id
        );
        insert tempSalesOrderLine3;

        tempMap.put(tempSalesOrderLine.OrderApi__Item__c, tempSalesOrderLine.Id);
        tempMap.put(tempSalesOrderLine1.OrderApi__Item__c, tempSalesOrderLine1.Id);
        tempMap.put(tempSalesOrderLine2.OrderApi__Item__c, tempSalesOrderLine2.Id);
        tempMap.put(tempSalesOrderLine3.OrderApi__Item__c, tempSalesOrderLine3.Id);

        

        OrderApi__Sales_Order_Line__c subscriptionLine = new OrderApi__Sales_Order_Line__c(
            OrderApi__Item__c = testItem.Id,
            OrderApi__Sales_Order__c = testSalesOrder.Id,
            OrderApi__Subscription_Plan__c = subscriptionPlan.Id,
            OrderApi__Is_Subscription__c = true
        );
        insert subscriptionLine;
       
        
        Map<String, Object> result = FS_JoinProcess_Checkout_Cart_Controller.updateSalesOrder(
            new List<OrderApi__Item__c>{},
            testContact,
            true,
            tempMap,
            testSalesOrder.Id
        );

        //System.assert(result.containsKey('PaymentURL'), 'PaymentURL should be present in the result');

        delete subscriptionPlan;
        delete subscriptionLine;

        OrderApi__Item__c newAddon = new OrderApi__Item__c(Name = 'New Test Item',OrderApi__Item_Class__c = itemClass1.Id );
        insert newAddon;



        Map<Id, Id> newItemIdToSalesOrderLineId = new Map<Id, Id>();
        newItemIdToSalesOrderLineId.put(newAddon.Id, null);

        Map<String, Object> newResult = FS_JoinProcess_Checkout_Cart_Controller.updateSalesOrder(
            lstItem,
            testContact,
            true,
            newItemIdToSalesOrderLineId,
            testSalesOrder.Id
        );

        //ystem.assert(newResult.containsKey('PaymentURL'), 'PaymentURL should be present in the newResult');
        //delete newAddon;
        //delete testSalesOrder;
       // delete testContact;
        //delete testItem;
}

}