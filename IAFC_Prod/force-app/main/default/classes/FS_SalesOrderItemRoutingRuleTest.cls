@isTest
private class FS_SalesOrderItemRoutingRuleTest {

	@TestSetup
    private static void install() {
        Framework.Installer.install();
        PagesApi.PackageScripts.install();
        OrderApi.PackageScripts.install();
        EventApi.PackageScripts.install();

        Framework.RoutingRule[] rules = new List<Framework.RoutingRule>();
        Framework.RoutingRule salesOrderRoutingRule = new Framework.RoutingRule();
        salesOrderRoutingRule.apexClass = FS_SalesOrderItemRoutingRule.class.getName();
        salesOrderRoutingRule.namespace = ' ';
        salesOrderRoutingRule.isEnabled = true;
        salesOrderRoutingRule.sObjectName = SObjectType.OrderApi__Sales_Order_Line__c.getName();
        salesOrderRoutingRule.executionOrder = 10;
        rules.add(salesOrderRoutingRule);

        Framework.Config.push(rules);



        OrderApi__Business_Group__c businessGroup = FS_TestUtils.createBusinessGroup('International Society of Automation');
        businessGroup.OrderApi__Type__c='Business Entity';
        insert businessGroup;

        OrderApi__GL_Account__c incomeAccount = new OrderApi__GL_Account__c();
        incomeAccount.Name='Income Account';
        incomeAccount.OrderApi__Business_Group__c=businessGroup.Id;
        incomeAccount.OrderApi__Report_Category__c='Income Statement';
        incomeAccount.OrderApi__Detail__c='Income';
        incomeAccount.OrderApi__Type__c='Income';
        incomeAccount.GL_Code__c = '25100-00000';
        insert incomeAccount;

        OrderApi__GL_Account__c adjustmentAccount = new OrderApi__GL_Account__c();
        adjustmentAccount.Name='Adjustment Account';
        adjustmentAccount.OrderApi__Business_Group__c=businessGroup.Id;
        adjustmentAccount.OrderApi__Report_Category__c='Income Statement';
        adjustmentAccount.OrderApi__Detail__c='Accounts Receivable (A/R)';
        adjustmentAccount.OrderApi__Type__c='Income';
        adjustmentAccount.GL_Code__c = '10106-00000';
        insert adjustmentAccount;

        OrderApi__Item_Class__c itemClass = FS_TestUtils.createItemClass('Departmental Membership');
        itemClass.OrderApi__Is_Active__c=true;
        itemClass.OrderApi__Business_Group__c=businessGroup.Id;
        insert itemClass;

        OrderApi__Item_Class__c itemClassSection = FS_TestUtils.createItemClass('Sections');
        itemClassSection.OrderApi__Is_Active__c=true;
        itemClassSection.OrderApi__Business_Group__c=businessGroup.Id;
        insert itemClassSection;

        OrderApi__Item__c item = FS_TestUtils.createItem('Departmental Membership', itemClass.Id);
        item.OrderApi__Business_Group__c=businessGroup.Id;
        item.FS_Item_Functional_Titles__c='Administrative Support';
        //item.OrderApi__Defer_Revenue__c=true;
        item.OrderApi__Is_Active__c=true;
        item.OrderApi__Income_Account__c=incomeAccount.Id;
        item.OrderApi__Adjustment_Account__c=adjustmentAccount.Id;
        item.OrderApi__Refund_Account__c=adjustmentAccount.Id;
        
        insert item;
        System.debug('##--Item: ' + Item);

        Account account = FS_TestUtils.createAccount('Test Account Name');
        insert account;

        Contact contact = FS_TestUtils.createContact('Test Contact', 'contact@test.com'); 
        contact.AccountId=account.Id;
        contact.Functional_Title__c='2-3 Crossed Bugle Chief Officer';
        contact.MailingCountryCode='US';
        contact.MailingStateCode='MD';
        insert contact;
        System.debug('##--Contact: ' + contact);


        // TODO: Create Sales Order that satisfies the batch condition
        OrderApi__Sales_Order__c objSalesOrder = FS_TestUtils.createSalesOrder(contact.Id, account.Id, 'Receipt', 'Open');
        objSalesOrder.OrderApi__Schedule_Type__c='Simple Receipt';
        //objSalesOrder.OrderApi__Posting_Status__c='Pending';
        objSalesOrder.OrderApi__Entity__c='Contact';
        insert objSalesOrder;
        
        

    }
	
	@isTest static void test_method_one() {

		List<OrderApi__Sales_Order__c> lstSalesOrders = [SELECT Id, Name FROM OrderApi__Sales_Order__c];
		List<OrderApi__Item_Class__c> lstItemClasses = [SELECT Id, Name FROM OrderApi__Item_Class__c];
		List<OrderApi__Item__c> lstItems = [SELECT Id, Name FROM OrderApi__Item__c];
		List<Contact> lstContacts = [SELECT Id, Name FROM Contact WHERE Name='Test Contact'];
		List<Account> lstAccounts = [SELECT Id, Name FROM Account WHERE Name ='Test Account Name'];
		List<OrderApi__GL_Account__c> lstIncomeAccounts = [SELECT Id, Name FROM OrderApi__GL_Account__c];

        OrderApi__Sales_Order_Line__c objSalesLine = FS_TestUtils.createSalesOrderLine(lstItems[0].Id, lstSalesOrders[0].Id, lstContacts[0].Id, lstAccounts[0].Id);
        objSalesLine.OrderApi__Contact__c = lstContacts[0].Id;
        objSalesLine.OrderApi__Item_Class__c=lstItemClasses[0].Id;
        insert objSalesLine;

        lstSalesOrders = [SELECT Id, Name, FS_Departmental_Membership__c FROM OrderApi__Sales_Order__c];

        System.assertEquals(true, lstSalesOrders[0].FS_Departmental_Membership__c);

        update objSalesLine;

        delete objSalesLine;

        lstSalesOrders = [SELECT Id, Name, FS_Departmental_Membership__c FROM OrderApi__Sales_Order__c];

        System.assertEquals(false, lstSalesOrders[0].FS_Departmental_Membership__c);
	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}