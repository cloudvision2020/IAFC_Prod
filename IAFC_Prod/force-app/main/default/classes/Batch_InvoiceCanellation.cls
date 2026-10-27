public class Batch_InvoiceCanellation implements Database.Batchable<sObject> {
    public Date actualDueDate180;
    public Date actualDueDate30;
    //public String userId = '0053m00000CU6a5AAD';
    public String closeStatus = 'Closed';
    
    public Batch_InvoiceCanellation(){
       actualDueDate180 = Date.today().addDays(Integer.valueOf(Label.Invoice_Cancellation));
        actualDueDate30 = Date.today().addDays(Integer.valueOf(Label.Invoice_Cancellation_30));
    }
    
    public Database.QueryLocator start(Database.BatchableContext context){
        String query = 'SELECT Id, OrderApi__Status__c, OrderApi__Is_Closed__c, OrderApi__Is_Posted__c, Renewal_Items__c, CreatedDate FROM OrderApi__Sales_Order__c ' +
                       'WHERE OrderApi__Is_Closed__c = true AND OrderApi__Is_Posted__c = false AND OrderApi__Status__c = :closeStatus ' +
                       'AND ((CreatedDate < :actualDueDate180 AND Renewal_Items__c >= 1) OR (CreatedDate < :actualDueDate30 AND Renewal_Items__c = 0))';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext context, List<OrderApi__Sales_Order__c> scope){
       Batch_InvoiceCanellationHelper.cancelInvoice(scope);
    }
    
    public void finish(Database.BatchableContext context){
        
    }

}