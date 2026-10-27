@isTest
public class FS_ContactPerformaRuleTest {
    @TestSetup
    private static void install() {
        Framework.Installer.install();
        PagesApi.PackageScripts.install();
        OrderApi.PackageScripts.install();
        EventApi.PackageScripts.install();

        Framework.RoutingRule[] rules = new List<Framework.RoutingRule>();
        Framework.RoutingRule ContactPerformaRoutingRule = new Framework.RoutingRule();
        ContactPerformaRoutingRule.apexClass = FS_ContactPerformaRoutingRule.class.getName();
        ContactPerformaRoutingRule.namespace = '';
        ContactPerformaRoutingRule.isEnabled = true;
        ContactPerformaRoutingRule.sObjectName = 'Contact';
        ContactPerformaRoutingRule.executionOrder = 30;
        rules.add(ContactPerformaRoutingRule);
        Framework.Config.push(rules);
    }
	@IsTest
    private static void testContactTgr2(){
        //Insert Account
        Account a = FS_TestUtils.createAccount('TestAccount1');
        insert a;

        //Insert Contact
        Contact con = FS_TestUtils.createContact('TestContact1','fscontest@example.com');
        con.AccountId = a.Id;
        con.Functional_Title__c = '2-3 Crossed Bugle Chief Officer';
        insert con;

        OrderApi__Business_Group__c oBus = FS_TestUtils.createBusinessGroup('International Association of Fire Chiefs');
        insert oBus;

        //Insert GL Account
        OrderApi__GL_Account__c oglAccount = new OrderApi__GL_Account__c();
        oglAccount.GL_Code__c = '21200-00000';
        oglAccount.Name= 'Division Dues - Eastern';
        oglAccount.OrderApi__Business_Group__c = oBus.Id;
        oglAccount.OrderApi__Type__c = 'Income';
        insert oglAccount;

        //Insert Item Class
        OrderApi__Item_Class__c oItemClass = FS_TestUtils.createItemClass('Divisions');
        oItemClass.Name = 'Divisions';
        insert oItemClass;

        //Insert Item
        OrderApi__Item__c oItem = FS_TestUtils.createItem('Eastern Division Dues', oItemClass.Id);
        oItem.FS_Item_Functional_Titles__c = 'Fire Chief';
        oItem.OrderApi__Business_Group__c  = oBus.Id;
        oItem.OrderApi__Income_Account__c = oglAccount.Id;
        oItem.OrderApi__Adjustment_Account__c = oglAccount.Id;
        oItem.OrderApi__Refund_Account__c = oglAccount.Id;
        insert oItem;

        //Insert Subscription Plan
        OrderApi__Subscription_Plan__c oSPlan = FS_TestUtils.createSubsPlan('Test Sub plan');
        oSPlan.OrderApi__Type__c = 'Termed';
        oSPlan.OrderApi__Initial_Term_Months__c = 12;
        oSPlan.OrderApi__Is_Active__c = true;
        insert oSplan;

        //Insert Subsription
        OrderApi__Subscription__c oSubs = new  OrderApi__Subscription__c();
        oSubs.OrderApi__Item__c = oItem.Id;
        oSubs.OrderApi__Account__c = a.Id;
        oSubs.OrderApi__Contact__c = con.Id;
        oSubs.OrderApi__Subscription_Plan__c = oSplan.Id;
        oSubs.OrderApi__Current_Term_End_Date__c = System.TODAY()+30;
        oSubs.OrderApi__Current_Term_Start_Date__c =   System.TODAY()-5;
        oSubs.OrderApi__Status__c = 'Active';
        oSubs.OrderApi__Is_Active__c = true;
        oSubs.OrderApi__Business_Group__c = oBus.Id;
        insert oSubs;

        //Insert Sales Order
        OrderApi__Sales_Order__c oSO = FS_TestUtils.createSalesOrder(con.Id, a.Id, 'Receipt', 'Open');
        oSO.OrderApi__Business_Group__c = oBus.Id;
        insert oSO;

        //Insert Sales Order Line
        OrderApi__Sales_Order_Line__c oSOline = FS_TestUtils.createSalesOrderLine(oItem.Id, oSO.ID, con.Id, a.Id);
        oSOline.OrderApi__Is_Renewal__c = true;
        oSOline.OrderApi__Subscription__c = oSubs.Id;
        insert oSOline;
        
        con.Functional_Title__c = '2-3 Crossed Bugle Chief Officer';
        con.MailingState='Alabama';
        update con;

        oSO.OrderApi__Status__c = 'Closed';
        oSO.OrderApi__Posting_Status__c = 'Pending';
        update oSO;

        Test.startTest();
        con.Functional_Title__c = 'Fire Chief';
        con.MailingState='Alabama';
        update con;
        database.executeBatch(new FS_ContactPerformaBatch());
        Test.stopTest();
        List<OrderApi__Sales_Order__c> oSalesOrder = [SELECT Id,FS_Proforma_Sync__c  FROM OrderApi__Sales_Order__c WHERE Id =:oSO.Id];
        if(!oSalesOrder.isEmpty()) system.assert(oSalesOrder[0].FS_Proforma_Sync__c, 'Sales Order Performa Not sync');
    }
}