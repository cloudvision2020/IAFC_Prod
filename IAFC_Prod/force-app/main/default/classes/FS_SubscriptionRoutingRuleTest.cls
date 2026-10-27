/**
 * Test class for FS_SubscriptionRoutingRule and FS_SubscriptionRoutingRuleService
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-11
 */

@isTest
public class FS_SubscriptionRoutingRuleTest {
    @TestSetup
    private static void install() {
        Framework.Installer.install();
        PagesApi.PackageScripts.install();
        OrderApi.PackageScripts.install();
        EventApi.PackageScripts.install();

        Framework.RoutingRule[] rules = new List<Framework.RoutingRule>();
        Framework.RoutingRule subscriptionRoutingRule = new Framework.RoutingRule();
        subscriptionRoutingRule.apexClass = FS_SubscriptionRoutingRule.class.getName();
        subscriptionRoutingRule.namespace = 'OrderApi';
        subscriptionRoutingRule.isEnabled = true;
        subscriptionRoutingRule.sObjectName = SObjectType.OrderApi__Subscription__c.getName();
        subscriptionRoutingRule.executionOrder = 30;
        
        Framework.RoutingRule subscriptionRoutingRule1 = new Framework.RoutingRule();
        subscriptionRoutingRule1.apexClass = RenewalRoutingRule.class.getName();
        subscriptionRoutingRule1.namespace = ' ';
        subscriptionRoutingRule1.isEnabled = true;
        subscriptionRoutingRule1.sObjectName = SObjectType.OrderApi__Renewal__c.getName();
        subscriptionRoutingRule1.executionOrder = 99;
        
        rules.add(subscriptionRoutingRule);
        rules.add(subscriptionRoutingRule1);


        Framework.Config.push(rules);

        OrderApi__Business_Group__c businessGroup = new OrderApi__Business_Group__c(Name='International Society of Automation');
        insert businessGroup;

        Account acc = new Account(Name='Test');
        insert acc;

        Contact con = new Contact(LastName='Test1', AccountId=acc.Id);
        insert con;

        OrderApi__GL_Account__c glAccount = new OrderApi__GL_Account__c(Name='test', OrderApi__Business_Group__c=businessGroup.Id, GL_Code__c='40000-20200');
        insert glAccount;

        OrderApi__Item_Class__c itemClass = new OrderApi__Item_Class__c(Name='test',
                OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Subscription__c=true);
        insert itemClass;
        OrderApi__Item_Class__c itemClass1 = new OrderApi__Item_Class__c(Name='Sections',
                OrderApi__Is_Active__c=true, OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Is_Subscription__c=false);
        insert itemClass1;

        OrderApi__Subscription_Plan__c sp = new OrderApi__Subscription_Plan__c(Name='Test', OrderApi__Type__c='Termed',
                OrderApi__Is_Active__c=true, OrderApi__Initial_Term_Months__c=12);
        insert sp;

        PagesApi__Community_Group__c communityGroup = new PagesApi__Community_Group__c(Name='Test');
        insert communityGroup;

        OrderApi__Item__c item = new OrderApi__Item__c(Name='Basic Membership', OrderApi__Item_Class__c=itemClass.Id,
                OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Income_Account__c=glAccount.Id, OrderApi__Adjustment_Account__c=glAccount.Id,
                OrderApi__Refund_Account__c=glAccount.Id, OrderApi__Is_Subscription__c=true, OrderApi__Price__c=0
        );
        insert item;

        OrderApi__Item__c item1 = new OrderApi__Item__c(Name='test', OrderApi__Item_Class__c=itemClass1.Id,
                OrderApi__Business_Group__c=businessGroup.Id, OrderApi__Income_Account__c=glAccount.Id, OrderApi__Adjustment_Account__c=glAccount.Id,
                OrderApi__Refund_Account__c=glAccount.Id, OrderApi__Price__c=0, FS_Community_Group__c=communityGroup.Id
        );
        insert item1;

        OrderApi__Item_Subscription_Plan__c itemSubscriptionPlan = new OrderApi__Item_Subscription_Plan__c(OrderApi__Item__c=item.Id, OrderApi__Subscription_Plan__c=sp.Id, OrderApi__Is_Default__c=true);
        insert itemSubscriptionPlan;


        OrderApi__Sales_Order__c salesOrder = new OrderApi__Sales_Order__c(OrderApi__Contact__c=con.Id);
        insert salesOrder;

        OrderApi__Sales_Order_Line__c salesOrderLine = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=salesOrder.Id, OrderApi__Item__c=item.Id);
        insert salesOrderLine;

        OrderApi__Sales_Order_Line__c salesOrderLine1 = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=salesOrder.Id, OrderApi__Item__c=item1.Id);
        insert salesOrderLine1;

        salesOrder.OrderApi__Status__c = 'Closed';
        update salesOrder;
        salesOrder.OrderApi__Posting_Status__c = 'Posted';
        update salesOrder;
    }

    @isTest static void test() {
        Contact con = [SELECT Id FROM Contact WHERE Name = 'Test1' LIMIT 1];
        //populateOriginalJoinDate
        //System.assertEquals(Date.today(), [SELECT Original_Join_Date__c FROM Contact WHERE Id = :con.Id].Original_Join_Date__c);
        //checkNewMemFee
        System.assertEquals(false, [SELECT New_Mem_Fee__c FROM Contact WHERE Id = :con.Id].New_Mem_Fee__c);
        //populateMembershipExpiration
       //System.assertEquals(Date.today().addMonths(13).toStartofMonth().addDays(-1), [SELECT Membership_Expiration__c FROM Contact WHERE Id = :con.Id].Membership_Expiration__c);
        //populateMembershipType
        System.assertEquals('Basic', [SELECT Membership_Type__c FROM Contact WHERE Id = :con.Id].Membership_Type__c);
        //populateRejoinDate
        //System.assertEquals(Date.today(), [SELECT Rejoin_Date__c FROM Contact WHERE Id = :con.Id].Rejoin_Date__c);


        System.assert([SELECT Id FROM PagesApi__Community_Group_Member__c WHERE PagesApi__Contact__c = :con.Id].size() > 0);
        //System.assert([SELECT Id, (SELECT Id FROM Community_Group_Member_Histories__r) FROM PagesApi__Community_Group_Member__c WHERE PagesApi__Contact__c = :con.Id][0].Community_Group_Member_Histories__r.size() > 0);
    }

    @isTest static void test1() {
        Test.startTest();
        Contact con = [SELECT Id FROM Contact WHERE Name = 'Test1' LIMIT 1];
        OrderApi__Item__c item = [SELECT Id FROM OrderApi__Item__c WHERE Name = 'Basic Membership' LIMIT 1];
        OrderApi__Item__c item1 = [SELECT Id FROM OrderApi__Item__c WHERE Name = 'test' LIMIT 1];
        OrderApi__Sales_Order__c salesOrderRenew = new OrderApi__Sales_Order__c(OrderApi__Contact__c=con.Id);
        insert salesOrderRenew;

        OrderApi__Sales_Order_Line__c salesOrderLineRenew = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=salesOrderRenew.Id, OrderApi__Item__c=item.Id, OrderApi__Is_Renewal__c=true, OrderApi__Subscription__c=[SELECT Id FROM OrderApi__Subscription__c WHERE OrderApi__Contact__c = :con.Id LIMIT 1].Id);
        insert salesOrderLineRenew;

        OrderApi__Sales_Order_Line__c salesOrderLineRenew1 = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=salesOrderRenew.Id, OrderApi__Item__c=item1.Id);
        insert salesOrderLineRenew1;

        salesOrderRenew.OrderApi__Status__c = 'Closed';
        update salesOrderRenew;
        salesOrderRenew.OrderApi__Posting_Status__c = 'Posted';
        update salesOrderRenew;
        Test.stopTest();

        System.assert([SELECT Id FROM PagesApi__Community_Group_Member__c WHERE PagesApi__Contact__c = :con.Id].size() > 0);
        //System.assert([SELECT Id, (SELECT Id FROM Community_Group_Member_Histories__r) FROM PagesApi__Community_Group_Member__c WHERE PagesApi__Contact__c = :con.Id][0].Community_Group_Member_Histories__r.size() > 1);
    }

    @isTest static void test2() {
        Test.startTest();
        Contact con = [SELECT Id FROM Contact WHERE Name = 'Test1' LIMIT 1];
        OrderApi__GL_Account__c glAccount = [SELECT Id FROM OrderApi__GL_Account__c WHERE Name = 'test' LIMIT 1];
        OrderApi__Item__c itemNew = new OrderApi__Item__c(Name='Full Membership', OrderApi__Item_Class__c=[SELECT Id FROM OrderApi__Item_Class__c WHERE Name = 'test' LIMIT 1].Id,
                OrderApi__Business_Group__c=[SELECT Id FROM OrderApi__Business_Group__c WHERE Name = 'International Society of Automation' LIMIT 1].Id, OrderApi__Income_Account__c=glAccount.Id, OrderApi__Adjustment_Account__c=glAccount.Id,
                OrderApi__Refund_Account__c=glAccount.Id, OrderApi__Is_Subscription__c=true, OrderApi__Price__c=0
        );
        insert itemNew;
        OrderApi__Item_Subscription_Plan__c itemSubscriptionPlanNew = new OrderApi__Item_Subscription_Plan__c(OrderApi__Item__c=itemNew.Id, OrderApi__Subscription_Plan__c=[SELECT Id FROM OrderApi__Subscription_Plan__c WHERE Name = 'Test'].Id, OrderApi__Is_Default__c=true);
        insert itemSubscriptionPlanNew;

        OrderApi__Sales_Order__c salesOrderNew = new OrderApi__Sales_Order__c(OrderApi__Contact__c=con.Id);
        insert salesOrderNew;

        OrderApi__Sales_Order_Line__c salesOrderLineNew = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=salesOrderNew.Id, OrderApi__Item__c=itemNew.Id);
        insert salesOrderLineNew;

        salesOrderNew.OrderApi__Status__c = 'Closed';
        update salesOrderNew;
        salesOrderNew.OrderApi__Posting_Status__c = 'Posted';
        update salesOrderNew;
        Test.stopTest();
    }
    @isTest static void test3() {
        Test.startTest();
        List<OrderApi__Renewal__c> renewals = [Select id,OrderAPI__Is_Active__c from OrderApi__Renewal__c limit 1];
        renewals[0].OrderAPI__Is_Active__c = false; 
        update renewals;
        Test.stopTest();
    }
    @isTest static void test4() {
        Test.startTest();
        List<OrderApi__Subscription__c > subs = [Select id, OrderApi__Status__c, OrderAPI__Is_Active__c from OrderApi__Subscription__c limit 1];
        subs[0].OrderApi__Status__c = 'Suspended'; 
        update subs;
        Test.stopTest();
    }
}