public without sharing class FS_JoinProcess_Marketing_AddOn_Controlle {
    @AuraEnabled
    public static Map<String, Object> initialization(Id accountId, OrderApi__Sales_Order__c salesOrder) {
        if(salesOrder == null){
            return null;
        }
        //Trav - Added to properly show multi year section pricing
        Integer SubscriptionPlanYears = 1; 
        String subId = null;
        List<OrderApi__Sales_Order_Line__c> SubscriptionLines = [Select Id, OrderApi__Subscription_Plan__c, 
                                                                    OrderApi__Subscription_Plan__r.Name, OrderApi__Price_Rule__r.Name,
                                                                 	OrderApi__Sales_Order__r.OrderApi__Encrypted_Id__c,
                                                                    OrderApi__Subscription_Plan__r.Id, OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c 
                                                                    from OrderApi__Sales_Order_Line__c where 
                                                                    OrderApi__Is_Subscription__c = true and 
                                                                    OrderApi__Sales_Order__c = :salesOrder.Id Limit 1];
       
        if(SubscriptionLines.size() > 0 && SubscriptionLines[0].OrderApi__Subscription_Plan__c != null && SubscriptionLines[0].OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c != null){
            SubscriptionPlanYears = (SubscriptionLines[0].OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c / 12).intValue();
        }
        
        Map<Id, OrderApi__Item__c> addOns = new Map<Id, OrderApi__Item__c>([SELECT Id, Name, OrderApi__Description__c, OrderApi__Price__c, OrderApi__Item_Class__r.Name FROM OrderApi__Item__c WHERE OrderApi__Item_Class__r.Name = 'Sections' AND OrderApi__Is_Active__c = TRUE]);
        Set<Id> existingAddOnIds = new Set<Id>();
        List<OrderApi__Sales_Order_Line__c> tempSalesOrderLines = new List<OrderApi__Sales_Order_Line__c>();
        List<OrderApi__Sales_Order_Line__c> lstSOL = [Select Id, OrderApi__Subscription_Plan__c, OrderApi__Subscription__c,
                                                    OrderApi__Subscription_Plan__r.Name, OrderApi__Total__c,OrderApi__Item__c,OrderApi__Price_Rule__r.Name,
                                                    OrderApi__Sales_Order__r.OrderApi__Encrypted_Id__c,
                                                    OrderApi__Subscription_Plan__r.Id, OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c 
                                                    from OrderApi__Sales_Order_Line__c where 
                                                    OrderApi__Sales_Order__c = :salesOrder.Id ];
                                                    
        for (OrderApi__Sales_Order_Line__c tempSalesOrderLine : lstSOL) {
            if(tempSalesOrderLine.OrderApi__Subscription__c != null){
                subId = tempSalesOrderLine.OrderApi__Subscription__c;
            }
            if(addOns.containskey(tempSalesOrderLine.OrderApi__Item__c)){
                addOns.get(tempSalesOrderLine.OrderApi__Item__c).OrderApi__Price__c = tempSalesOrderLine.OrderApi__Total__c;
                existingAddOnIds.add(tempSalesOrderLine.OrderApi__Item__c);
            }
        }
        FDService.OrderService orderService = FDService.OrderService.getInstance();
        List<FDService.SalesOrderLine> lines = new List<FDService.SalesOrderLine>();

        for (OrderApi__Item__c tempItem : addOns.values()) {
            if (!existingAddOnIds.contains(tempItem.Id)) {
                FDService.SalesOrderLine salesOrderLine = FDService.SalesOrderLine.getInstance();
                salesOrderLine.salesOrder = salesOrder.Id;
                salesOrderLine.item =  tempItem.id;
                if(subId != null){
                    salesOrderLine.subscription = subId;
                    salesOrderLine.IsRenewal = true;
                }
                lines.add(salesOrderLine);
                /*tempSalesOrderLines.add(
                        new OrderApi__Sales_Order_Line__c(
                                OrderApi__Sales_Order__c = salesOrder.Id,
                                OrderApi__Item__c = tempItem.Id,
                                OrderApi__Price_Override__c = SubscriptionPlanYears > 1,
                                OrderApi__Sale_Price__c = SubscriptionPlanYears > 1 ? tempItem.OrderApi__Price__c * SubscriptionPlanYears : tempItem.OrderApi__Price__c
                        )
                );*/
            }
        }
        
        Savepoint savepoint = Database.setSavepoint();
        //insert tempSalesOrderLines;
        if(!lines.isEmpty()) {
            lines = orderService.addItemsToOrder(lines);
        }

        Set<Id> tempSalesOrderLineIds = new Set<Id>();
        for (FDService.SalesOrderLine tempSalesOrderLine : lines) {
            tempSalesOrderLineIds.add(tempSalesOrderLine.Id);
        }
        List<OrderApi__Sales_Order_Line__c> updatedSalesOrderLines = [SELECT Id, OrderApi__Item__c, OrderApi__Price_Rule__r.Name, OrderApi__Total__c FROM OrderApi__Sales_Order_Line__c WHERE Id IN :tempSalesOrderLineIds];
        for (OrderApi__Sales_Order_Line__c tempSalesOrderLine : updatedSalesOrderLines) {
            addOns.get(tempSalesOrderLine.OrderApi__Item__c).OrderApi__Price__c = tempSalesOrderLine.OrderApi__Total__c;
        }
        Database.rollback(savepoint);

        return new Map<String, Object>{
            	'encryptedId' => [Select Id, OrderApi__Encrypted_Id__c from OrderApi__Sales_Order__c where Id =: salesOrder.Id].OrderApi__Encrypted_Id__c,
                'AddOns' => addOns.values(),
                'isFederalMilitary' => [SELECT Id, Department_Type__c FROM Account WHERE Id = :accountId].Department_Type__c == 'Federal/Military'
        };
    }
}