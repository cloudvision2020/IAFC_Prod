public class EmailNotificationFinal {
 public string ContactId{get;set;}
    public list<OrderApi__Sales_Order_Line__c> salesOrderLine{get;set;}
    public  Decimal totalValue{get; set;}
    public  String ordername{get; set;}
    
    public EmailNotificationFinal(){
        salesOrderLine = new list<OrderApi__Sales_Order_Line__c>(); 
        totalValue = 0;
        
    }
    public list<OrderApi__Sales_Order_Line__c> returnSalesOrderLI{
      
       get{
            List<OrderApi__Subscription__c> subscription = [Select Id, name from OrderApi__Subscription__c
                                                     where OrderApi__Contact__c =: ContactId
                                                     AND OrderApi__Status__c = 'Active' Order by CreatedDate DESC Limit 1 ];
            
            List<OrderApi__Sales_Order__c> salesOrder = [Select Id, name from OrderApi__Sales_Order__c
                                                  where OrderApi__Contact__c =: ContactId 
                                                  AND OrderApi__Contact__r.Has_Group_Membership__c = False
                                                  AND (OrderApi__Status__c = 'open' OR 
                                                  (OrderApi__Status__c = 'closed' AND OrderApi__Posting_Status__c = 'pending'))
                                                  Order by LastModifiedDate DESC Limit 1];
            if(!salesOrder.isEmpty()){
                salesOrderLine = [Select Id,OrderApi__Item__c,OrderApi__Item__r.Name,OrderApi__Sales_Order__r.OrderApi__Total__c, OrderApi__Sales_Order__r.Name, OrderApi__Sales_Order__r.OrderApi__Encrypted_Id__c,
                             OrderApi__Quantity__c,OrderApi__Line_Description__c,OrderApi__List_Price__c,OrderApi__Sale_Price__c,OrderApi__Total__c
                             FROM OrderApi__Sales_Order_Line__c where OrderApi__Sales_Order__c =: salesOrder[0].Id];
             }
            
            
            return salesOrderLine;
           
        }
        set; 
    }
    
    public decimal returntotalvalue{
       
        get{  
                
             List<OrderApi__Subscription__c> subscription = [Select Id, name from OrderApi__Subscription__c
                                                     where OrderApi__Contact__c =: ContactId
                                                     AND OrderApi__Status__c = 'Active' Order by CreatedDate DESC Limit 1 ];
                
             List<OrderApi__Sales_Order__c> salesOrder = [Select Id, name from OrderApi__Sales_Order__c
                                              where OrderApi__Contact__c =: ContactId
                                              AND (OrderApi__Status__c = 'open' OR 
                                              (OrderApi__Status__c = 'closed' AND OrderApi__Posting_Status__c = 'pending'))
                                              Order by LastModifiedDate DESC Limit 1];
            
            if(!salesOrder.isEmpty()){
                salesOrderLine = [SELECT Id,OrderApi__Item__c,OrderApi__Item__r.Name,OrderApi__Sales_Order__r.OrderApi__Total__c,
                              OrderApi__Quantity__c,OrderApi__Line_Description__c,OrderApi__List_Price__c,OrderApi__Sale_Price__c,OrderApi__Total__c,
                              OrderApi__Sales_Order__r.Name, OrderApi__Sales_Order__r.OrderApi__Encrypted_Id__c
                              FROM OrderApi__Sales_Order_Line__c
                              WHERE OrderApi__Sales_Order__c =: salesOrder[0].Id];
            
                if(!salesOrderLine.isEmpty()){
                    totalValue = salesOrderLine[0].OrderApi__Sales_Order__r.OrderApi__Total__c;
                    system.debug('Total Value:- '+totalValue);
                }
             }
       
            return totalValue;
        
        }
        set;
         
    }    
    public string ordernme{
        get{
            if(!salesOrderLine.isEmpty()){
                ordernme = salesOrderLine[0].OrderApi__Sales_Order__r.Name;
                    system.debug('Total Value:- '+ ordername);
            }
            return ordernme;        
        } set; 
    }
    
    public list<OrderApi__Subscription__c> returnSubscription{
      
       get{
            List<OrderApi__Subscription__c> subscription = [Select Id,OrderAPI__Paid_Through_Date__c, name from OrderApi__Subscription__c
                                                     where OrderApi__Contact__c =: ContactId
                                                     AND OrderApi__Status__c = 'Active' Order by CreatedDate DESC Limit 1 ];
            
            return subscription;
           
        }
        set; 
    }
    
}