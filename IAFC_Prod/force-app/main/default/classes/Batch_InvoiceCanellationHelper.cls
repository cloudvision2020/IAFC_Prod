public class Batch_InvoiceCanellationHelper {
  
    public static void cancelInvoice (List<OrderApi__Sales_Order__c> soList){
        List<OrderApi__Sales_Order__c> updatedSoList = new List<OrderApi__Sales_Order__c>();
        
        for(OrderApi__Sales_Order__c updateSO: soList){
            updateSO.OrderApi__Status__c = 'Cancelled';
            updatedSoList.add(updateSO);
            } 
        
        Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', true);
        update updatedSoList;
        Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', false);
  	}
}