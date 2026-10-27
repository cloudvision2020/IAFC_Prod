public class SentReceipt {
    public string ReceId{get;set;}
    public string OReceiptId{get;set;}
    public list<OrderApi__Receipt_Line__c> receiptLine{get;set;}
    public  Decimal totalValue{get; set;}
    
    
    public list <OrderApi__Receipt__c> Receipt{
        get{
            Receipt= [select id from  OrderApi__Receipt__c where id =:OReceiptId AND OrderApi__Contact__r.Has_Group_Membership__c = False Limit 1];
            return receipt;
        }
        set;
    }
    
    public list<OrderApi__Receipt_Line__c> returnReceiptLI{
        
        get{
            receiptLine = new List<OrderApi__Receipt_Line__c>();
            List<OrderApi__Subscription__c> subscription = [Select Id, name from OrderApi__Subscription__c
                                                      where OrderApi__Contact__c =: ReceId AND OrderApi__Contact__r.Has_Group_Membership__c = False
                                                      AND OrderApi__Status__c = 'Active' Order by CreatedDate DESC Limit 1 ];
            
            List<OrderApi__Sales_Order__c> salesOrder = [Select Id, name from OrderApi__Sales_Order__c
                                                   where OrderApi__Contact__c =: ReceId 
                                                                  Order by CreatedDate DESC Limit 1];
          if(!salesOrder.isEmpty()){ 
            List<OrderApi__Receipt__c> Receipt = [Select Id, name from OrderApi__Receipt__c
                                            where OrderApi__Contact__c =: ReceId 
                                            AND OrderApi__Contact__r.Has_Group_Membership__c = False AND OrderApi__Sales_Order__c =: salesOrder[0].Id Limit 1];
            
            receiptLine = [Select Id,OrderApi__Item__c,OrderApi__Item__r.Name,OrderApi__Receipt__r.OrderApi__Total__c,OrderApi__Total__c,
                           OrderApi__Quantity__c,OrderApi__Line_Description__c,OrderApi__List_Price__c,OrderApi__Sale_Price__c
                           FROM OrderApi__Receipt_Line__c where OrderApi__Receipt__c =: OReceiptId ];
            }
            return receiptLine;
            
        }
        set;
    }
    
    public decimal returntotalval{
        get{  
            receiptLine = new List<OrderApi__Receipt_Line__c>();

            List<OrderApi__Subscription__c> subscription = [Select Id, name from OrderApi__Subscription__c
                                                      where OrderApi__Contact__c =: ReceId AND OrderApi__Contact__r.Has_Group_Membership__c = False
                                                      AND OrderApi__Status__c = 'Active' Order by CreatedDate DESC Limit 1 ];
            
            List<OrderApi__Sales_Order__c> salesOrder = [Select Id, name from OrderApi__Sales_Order__c
                                                   where OrderApi__Contact__c =: ReceId 
                                                   AND OrderApi__Contact__r.Has_Group_Membership__c = False
                                                   AND (OrderApi__Status__c = 'Closed' AND OrderApi__Posting_Status__c = 'Posted')
                                                   Order by LastModifiedDate DESC Limit 1];
             if(!salesOrder.isEmpty()){
                 List<OrderApi__Receipt__c> Receipt = [Select Id, name,OrderApi__Total__c from OrderApi__Receipt__c
                                            where OrderApi__Contact__c =: ReceId 
                                            AND OrderApi__Contact__r.Has_Group_Membership__c = False AND OrderApi__Sales_Order__c =: salesOrder[0].Id Limit 1];
            
            
                 receiptLine = [Select Id,OrderApi__Item__c,OrderApi__Item__r.Name,OrderApi__Receipt__r.OrderApi__Total__c,
                           OrderApi__Quantity__c,OrderApi__Line_Description__c,OrderApi__Receipt__c,OrderApi__List_Price__c,OrderApi__Sale_Price__c,OrderApi__Total__c
                           FROM OrderApi__Receipt_Line__c where OrderApi__Receipt__c =: OReceiptId];
            }
            if(!receiptLine.isEmpty()){
                totalValue = receiptLine[0].OrderApi__Receipt__r.OrderApi__Total__c;
            }
            return totalValue;
            
        }
        
        
        set;
        
    }    
    
}