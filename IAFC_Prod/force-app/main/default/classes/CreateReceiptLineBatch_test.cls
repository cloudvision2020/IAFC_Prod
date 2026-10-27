@isTest
public class CreateReceiptLineBatch_test {
    @isTest
    public static void test(){
        Account acc = new Account(Name='testAcc');
        insert acc;
        
        Contact con = new Contact(LastName='testCon');
        insert con;
        
        OrderApi__Item__c item = new OrderApi__Item__c(Name='Full Membership');
        insert item;       
        
        OrderApi__Item__c item1 = new OrderApi__Item__c(Name='Southeastern Division Dues');
        insert item1;
        
        OrderApi__Sales_Order__c SalesOrder = new OrderApi__Sales_Order__c(OrderApi__Contact__c=con.id,OrderApi__Is_Posted__c = true);
        insert SalesOrder;
        
        OrderApi__Sales_Order_Line__c sOL = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=SalesOrder.id,OrderApi__Item__c=item.id,OrderApi__Contact__c=con.id,
                                                                             OrderApi__Sale_Price__c = 2.00 );
        insert sOL;
        
        OrderApi__Receipt__c Rec = new OrderApi__Receipt__c(OrderApi__Sales_Order__c=SalesOrder.id, OrderApi__Is_Posted__c = false);
        insert Rec;
        
        String CRON_EXP = '0 0 0/3 * * ?'; //'0 */3 * * *'; //'0 0 0,4,8,10,16,20 * * ?';
        Test.startTest();
        //String jobId = System.schedule('Insert Receipt Line', CRON_EXP, new CreateReceiptLineBatch());
		//CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		//System.assertEquals(CRON_EXP, ct.CronExpression);
		//System.assertEquals(0, ct.TimesTriggered);
        CreateReceiptLineBatch obj = new CreateReceiptLineBatch();
        String jobId = System.schedule('Insert_Receipt_Line', CRON_EXP, obj);
        obj.execute(null);
        //DataBase.executeBatch(obj);
        //CreateReceiptLineBatchScheduler = new CreateReceiptLineBatchScheduler();
        CreateReceiptLineBatchScheduler.meth();
        Test.stopTest();
    }
}