@IsTest
public class Batch_InvoiceCanellationTest {
    
    @IsTest
    public static void testBatchInvoiceCancellation() {
        OrderApi__Sales_Order__c order1 = new OrderApi__Sales_Order__c();
        order1.OrderApi__Is_Posted__c = false;
        order1.OrderApi__Is_Closed__c = true;
        order1.OrderApi__Status__c = 'Closed';
        order1.OrderApi__Due_Date__c = Date.today().addDays(-100);
        insert order1;
        
        
        Test.startTest();
        Database.executeBatch(new Batch_InvoiceCanellation(), 50);
        Datetime now = System.now().addMinutes(1);
        String cronExp = now.second() + ' ' + now.minute() +' ' + now.hour() + ' * * ?';
        String jobID = System.schedule('Batch_InvoiceCanellationScheduler' + System.currentTimeMillis(), cronExp, new Batch_InvoiceCanellationScheduler());
        
        
        Test.stopTest();
        
        
        List<OrderApi__Sales_Order__c> updatedSalesOrders = [
            SELECT Id, OrderApi__Status__c
            FROM OrderApi__Sales_Order__c
            WHERE OrderApi__Status__c = 'Cancelled'
        ];
        
      //  System.assertEquals(1, updatedSalesOrders.size(), 'All eligible sales orders should be cancelled');
        
        
        
    }
    
}