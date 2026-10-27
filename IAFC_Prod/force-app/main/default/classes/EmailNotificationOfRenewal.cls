public with sharing class EmailNotificationOfRenewal {
    public  string subscriptionId{get; set;}
    public  list<OrderApi__Sales_Order_Line__c> salesOrderLine{get; set;}
    public  Decimal totalValue{get; set;}
    
    public  list<OrderApi__Sales_Order_Line__c> returnSalesOrderLI{
        get{
            system.debug('Subscription Id:- '+subscriptionId);
        OrderApi__Renewal__c term = [SELECT Id,OrderApi__Sales_Order__c
                                     FROM OrderApi__Renewal__c 
                                     WHERE OrderApi__Subscription__c =:subscriptionId 
                                     AND OrderApi__Sales_Order__c != NULL
                                     AND OrderApi__Is_Active__c = TRUE
                                     ORDER BY CreatedDate DESC LIMIT 1];
            system.debug('Term :- '+term);
            system.debug('SalesOrder Id :- '+term.OrderApi__Sales_Order__c);
        salesOrderLine = [SELECT Id,OrderApi__Item__c,OrderApi__Item__r.Name,OrderApi__Sales_Order__r.OrderApi__Total__c,
                          OrderApi__Quantity__c,OrderApi__Line_Description__c,OrderApi__List_Price__c,OrderApi__Sale_Price__c,OrderApi__Total__c
                          FROM OrderApi__Sales_Order_Line__c
                          WHERE OrderApi__Sales_Order__c =: term.OrderApi__Sales_Order__c];
            
            system.debug('salesOrderLine :- '+salesOrderLine);
            return salesOrderLine;
        }
        set;
    }
    
    public decimal returntotalvalue{
            get{   
        OrderApi__Renewal__c term = [SELECT Id,OrderApi__Sales_Order__c
                                     FROM OrderApi__Renewal__c 
                                     WHERE OrderApi__Subscription__c =:subscriptionId
                                     AND OrderApi__Sales_Order__c != NULL
                                     AND OrderApi__Is_Active__c = TRUE
                                     ORDER BY CreatedDate DESC LIMIT 1];
                
        salesOrderLine = [SELECT Id,OrderApi__Item__c,OrderApi__Item__r.Name,OrderApi__Sales_Order__r.OrderApi__Total__c,
                          OrderApi__Quantity__c,OrderApi__Line_Description__c,OrderApi__List_Price__c,OrderApi__Sale_Price__c,OrderApi__Total__c
                          FROM OrderApi__Sales_Order_Line__c
                          WHERE OrderApi__Sales_Order__c =: term.OrderApi__Sales_Order__c];
            
        
        totalValue = salesOrderLine[0].OrderApi__Sales_Order__r.OrderApi__Total__c;
                system.debug('Total Value:- '+totalValue);
            return totalValue;
        }
        set;
    }
}