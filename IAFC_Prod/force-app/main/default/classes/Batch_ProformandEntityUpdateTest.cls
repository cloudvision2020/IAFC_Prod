@isTest
private class Batch_ProformandEntityUpdateTest {
    
    @isTest
    static void batchProcess(){
        
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
        
        OrderApi__Sales_Order__c salesOrder1 = new OrderApi__Sales_Order__c();
        salesOrder1.OrderApi__Contact__c = con.Id;
        salesOrder1.OrderApi__Account__c = acc.Id;
        salesOrder1.OrderApi__Entity__c = 'Account';
        insert salesOrder1;
        
        OrderApi__Subscription__c sub = new OrderApi__Subscription__c();
        sub.OrderApi__Item__c = item.Id;
        insert sub;
        
        OrderApi__Sales_Order_Line__c salesOrderLine2 = new OrderApi__Sales_Order_Line__c();
        salesOrderLine2.OrderApi__Sales_Order__c = salesOrder1.Id;
        salesOrderLine2.OrderApi__Account__c = acc.id;
        salesOrderLine2.OrderApi__Subscription__c = sub.Id;
        salesOrderLine2.OrderApi__Is_Renewal__c =true;
        insert salesOrderLine2;
        
        salesOrder1.OrderApi__Posting_Status__c = 'Pending';
        salesOrder1.OrderApi__Status__c = 'Closed';
        
        update salesOrder1;
        
        Test.startTest();
        Batch_ProformandEntityUpdateScheduler batchScheduler = new Batch_ProformandEntityUpdateScheduler();
        batchScheduler.execute(null); 
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testBatchProcessing() {
        
        Account acc = new Account();
        acc.Name='test acc';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'test12';
        insert con;
        
        OrderApi__Sales_Order__c salesOrder = new OrderApi__Sales_Order__c();
        salesOrder.OrderApi__Contact__c = con.Id;
        salesOrder.OrderApi__Account__c = acc.Id;
        salesOrder.OrderApi__Entity__c = 'Account';
        insert salesOrder;
        
        OrderApi__Sales_Order_Line__c salesOrderLine = new OrderApi__Sales_Order_Line__c();
        salesOrderLine.OrderApi__Sales_Order__c = salesOrder.Id;
        salesOrderLine.OrderApi__Account__c = acc.id;
        insert salesOrderLine;
        
        salesOrder.OrderApi__Posting_Status__c = 'Pending';
        salesOrder.OrderApi__Status__c = 'Closed';
        
        update salesOrder;
        
        Test.startTest();
        Batch_ProformandEntityUpdateScheduler batchScheduler = new Batch_ProformandEntityUpdateScheduler();
        batchScheduler.execute(null); 
        Test.stopTest();
        
        OrderApi__Sales_Order__c updatedSalesOrder = [SELECT Id, OrderApi__Entity__c, OrderApi__Is_Proforma__c FROM OrderApi__Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
      
        System.assertEquals('Account', updatedSalesOrder.OrderApi__Entity__c, 'Entity should be updated to Account');
    }
}