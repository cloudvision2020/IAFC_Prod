public without sharing class FS_JoinProcess_Checkout_Cart_Controller {
    @AuraEnabled
    public static Map<String, Object> updateSalesOrder(List<OrderApi__Item__c> addOnsSelected, Contact contact,
        Boolean isFederalMilitary, Map<Id, Id> itemIdToSalesOrderLineId, Id salesOrderId) {
        Map<String, Object> result = new Map<String, Object>();
        try {    

            system.debug('addOnsSelected = '+ addOnsSelected);
            system.debug('itemIdToSalesOrderLineId = '+ itemIdToSalesOrderLineId);
            system.debug('salesOrderId = '+ salesOrderId);
            
            List<OrderApi__Sales_Order_Line__c> newSalesOrderLines = new List<OrderApi__Sales_Order_Line__c>();
            List<Id> salesOrderLineNeedToDelete = new List<Id>();
            Boolean divisionOptOut = true;
            Set<Id> itemIdsInSalesOrder = itemIdToSalesOrderLineId.keySet();

            Set<Id> itemIdsInSalesOrderIds = new Set<Id>();
            Set<Id> itemIdsInSalesOrderIdsdelete = new Set<Id>();
            
            List<OrderApi__Sales_Order_Line__c> lstSOLine = [Select Id, OrderApi__Item__c, OrderApi__Subscription_Plan__c,
                                                            OrderApi__Item__r.OrderApi__Item_Class__c, OrderApi__Item__r.OrderApi__Item_Class__r.Name,
                                                            OrderApi__Sales_Order_Line__c, OrderApi__Subscription__c
                                                            from OrderApi__Sales_Order_Line__c where OrderApi__Sales_Order__c=:salesOrderId 
                                                            and ( OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections'
                                                            OR OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Divisions')];
            
            String  parentSOL = null;
            String  parentSub = null;
            if(lstSOLine.size() > 0){
                List<OrderApi__Sales_Order_Line__c> lstSOLineDelete = new List<OrderApi__Sales_Order_Line__c>();
                for(OrderApi__Sales_Order_Line__c sol : lstSOLine){
                    if(sol.OrderApi__Item__r.OrderApi__Item_Class__r.Name != 'Divisions'){
                        lstSOLineDelete.add(sol);
                    }
                    if(sol.OrderApi__Item__r.OrderApi__Item_Class__r.Name == 'Divisions' && sol.OrderApi__Sales_Order_Line__c != null){
                        if(sol.OrderApi__Sales_Order_Line__c != null){
                            parentSOL = sol.OrderApi__Sales_Order_Line__c;
                        }
                        if(sol.OrderApi__Subscription__c != null){
                            parentSub = sol.OrderApi__Subscription__c;
                        }
                    }
                }
                delete lstSOLineDelete;
            }

            FDService.OrderService orderService = FDService.OrderService.getInstance();
            List<FDService.SalesOrderLine> lines = new List<FDService.SalesOrderLine>();

            for (OrderApi__Item__c addon : addOnsSelected) {
                if(addon.OrderApi__Item_Class__r.Name != 'Divisions' && addon.OrderApi__Item_Class__r.Name == 'Sections'){
                    if(salesOrderId != null && addon.id != null){
                        FDService.SalesOrderLine salesOrderLine = FDService.SalesOrderLine.getInstance();
                        salesOrderLine.salesOrder = salesOrderId;
                        salesOrderLine.item =  addon.id;
                        if(parentSub != null){
                            salesOrderLine.subscription = parentSub;
                            salesOrderLine.IsRenewal = true;
                        }
                        lines.add(salesOrderLine);
                    }
                    
                }
                
                if (addon.OrderApi__Item_Class__r.Name == 'Divisions' && contact.Division__c != null && isFederalMilitary) {
                    divisionOptOut = false;
                }
            }

            if (isFederalMilitary) {
                contact.Division_Opt_Out__c = divisionOptOut;
                update contact;
            }

            if(!lines.isEmpty()) {
                lines = orderService.addItemsToOrder(lines);
            }
            
            List<OrderApi__Sales_Order_Line__c> lstSOLineUpdate = [Select Id
                                                            from OrderApi__Sales_Order_Line__c 
                                                            where OrderApi__Sales_Order__c=:salesOrderId 
                                                            and ( OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections') and
                                                            OrderApi__Sales_Order_Line__c =: null];

            if(lstSOLineUpdate.size() > 0){
                for(OrderApi__Sales_Order_Line__c sol : lstSOLineUpdate){
                    if(parentSOL != null){
                        sol.OrderApi__Sales_Order_Line__c = parentSOL;
                    }
                }
                Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order_Line__c', true);
                update lstSOLineUpdate;
                Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order_Line__c', false);
            }

            //Trav - setting correct price for multi year sections
            /*Integer SubscriptionPlanYears = 1;
            List<OrderApi__Sales_Order_Line__c> SubscriptionLines = [SELECT Id, OrderApi__Subscription_Plan__r.Name, OrderApi__Subscription_Plan__r.Id, OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c 
                                                              FROM OrderApi__Sales_Order_Line__c 
                                                              WHERE OrderApi__Is_Subscription__c = true and OrderApi__Sales_Order__c = :salesOrderId Limit 1];
            if(SubscriptionLines.size() > 0){
                if(SubscriptionLines[0].OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c != null){
                    SubscriptionPlanYears = (SubscriptionLines[0].OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c / 12).intValue();
                }
                
                if(SubscriptionPlanYears > 1){
                    List<OrderApi__Sales_Order_Line__c> sectionLines = [SELECT Id, OrderApi__Sale_Price__c, OrderApi__Price_Override__c 
                                                                        FROM OrderApi__Sales_Order_Line__c 
                                                                        WHERE OrderApi__Sales_Order__c = :salesOrderId 
                                                                            and OrderApi__Price_Override__c = false
                                                                            and OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections'];
                    for(OrderApi__Sales_Order_Line__c sectionline: sectionLines){
                        //sectionline.OrderApi__Sale_Price__c = sectionline.OrderApi__Sale_Price__c * SubscriptionPlanYears;
                        sectionline.OrderApi__Price_Override__c = true;
                        sectionline.OrderApi__Quantity__c = SubscriptionPlanYears;
                        sectionline.OrderApi__Overall_Total__c = sectionline.OrderApi__Sale_Price__c * SubscriptionPlanYears;
                        sectionline.OrderApi__Balance_Due__c = sectionline.OrderApi__Overall_Total__c;
                    }
                    update sectionLines;
                }
            }*/
            

            List<OrderApi__Sales_Order__c> lstSOL = [SELECT Id, OrderApi__Total__c, OrderApi__Overall_Total__c FROM OrderApi__Sales_Order__c WHERE Id = :salesOrderId];

            for(OrderApi__Sales_Order__c sol : lstSOl){
                sol.OrderApi__Overall_Total__c = sol.OrderApi__Total__c;
                sol.OrderApi__Status__c='Closed';
            }
            update lstSOL;

            String paymentURL = [SELECT Id, Long_URL__c FROM OrderApi__Sales_Order__c WHERE Id = :salesOrderId].Long_URL__c;
            result.put('PaymentURL', paymentURL);
            result.put('SalesOrder', [SELECT Id, (SELECT Id, OrderApi__Total__c, OrderApi__Item__c, OrderApi__Item__r.Name, OrderApi__Item__r.OrderApi__Price__c, OrderApi__Item__r.OrderApi__Description__c, OrderApi__Item__r.OrderApi__Item_Class__r.Name, OrderApi__Item__r.OrderApi__Image_Path__c, OrderApi__Price_Rule__r.Name,OrderApi__Item_Class__r.Name, OrderApi__Subscription_Plan__c, OrderApi__Subscription_Plan__r.Name FROM OrderApi__Sales_Order_Lines__r) FROM OrderApi__Sales_Order__c WHERE Id = :salesOrderId][0]);
            return result;
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            result.put('Error', 'Update Sales Order Failed.');
            return result;
        }
    }
}