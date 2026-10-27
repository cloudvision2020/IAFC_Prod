/**
 * Created by Jason Cookman on 6/3/19.
 */
@IsTest
public with sharing class FS_PrintInvoiceButtonControllerTest {

    @IsTest
    public static void testShowButtonAndClick() {
       /* OrderApi__Business_Group__c businessGroup = new OrderApi__Business_Group__c(Name='International Society of Automation');
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
                OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Active__c=true);
        insert item1;

        OrderApi__Item__c item2 = new OrderApi__Item__c(Name='New Member Fee', OrderApi__Item_Class__c=itemClass.Id,
                OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Active__c=true);
        insert item2;

        OrderApi__Item__c item3 = new OrderApi__Item__c(Name='Eastern Division Dues', OrderApi__Item_Class__c=itemClass2.Id,
                OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Active__c=true);
        insert item3;

        OrderApi__Subscription_Plan__c subscriptionPlan = new OrderApi__Subscription_Plan__c(Name='1 Year', OrderApi__Initial_Term_Months__c=12);
        insert subscriptionPlan;

        OrderApi__Item_Subscription_Plan__c itemSubscriptionPlan = new OrderApi__Item_Subscription_Plan__c(OrderApi__Item__c=item.Id, OrderApi__Subscription_Plan__c=subscriptionPlan.Id);
        insert itemSubscriptionPlan;

        Account account = new Account(Name='Test Account Name', Population_Served_Size__c='Less than 10,000');
        insert account;

        Contact contact = new Contact(LastName='test', AccountId=account.Id, MailingStateCode='MD', MailingCountryCode='US');
        insert contact;

//        Profile p = [SELECT Id FROM Profile WHERE Name='Fonteva Customer Community Login User'];
//
//        User user = new User(Alias='standt', Email='test@example.com',
//                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
//                LocaleSidKey='en_US', ProfileId=p.Id,
//                TimeZoneSidKey='America/Los_Angeles', UserName='test@example.com', ContactId=contact.Id);
//        insert user;

        Contact contact1 = new Contact(LastName='test1', AccountId=account.Id, MailingStateCode='MD',
                MailingCountryCode='US', Functional_Title__c='4 Crossed Bugle Chief Officer');
        insert contact1;

        OrderApi__Sales_Order__c salesOrder = new OrderApi__Sales_Order__c(OrderApi__Contact__c=contact1.Id);
        insert salesOrder;
        OrderApi__Sales_Order_Line__c salesOrderLine = new OrderApi__Sales_Order_Line__c(OrderApi__Item__c=item.Id, OrderApi__Sales_Order__c=salesOrder.Id);
        insert salesOrderLine;
        OrderApi__Sales_Order_Line__c salesOrderLine1 = new OrderApi__Sales_Order_Line__c(OrderApi__Item__c=item1.Id, OrderApi__Sales_Order__c=salesOrder.Id);
        insert salesOrderLine1;
//        User user1 = new User(Alias='standt', Email='test@example.com',
//                EmailEncodingKey='UTF-8', LastName='Testing1Class', LanguageLocaleKey='en_US',
//                LocaleSidKey='en_US', ProfileId=p.Id,
//                TimeZoneSidKey='America/Los_Angeles', UserName='test1@example.com', ContactId=contact1.Id);
//        insert user1;

    */

        FS_PrintInvoiceButtonController invoiceController = new FS_PrintInvoiceButtonController();
        //System.assert(invoiceController.showButton(null) == true);
        //System.assert(invoiceController.onClick(salesOrder).contains(salesOrder.Id));
    } 
    
}