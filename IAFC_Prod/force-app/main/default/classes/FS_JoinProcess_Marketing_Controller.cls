public without sharing class FS_JoinProcess_Marketing_Controller {
    @AuraEnabled
    public static List<OrderApi__Item__c> getMembershipItems(String contactTitle, Boolean isDepartmentalMembershipJoin) {
        List<OrderApi__Item__c> items = new List<OrderApi__Item__c>();
        for (OrderApi__Item__c tempItem : [SELECT Id, Name, FS_Item_Functional_Titles__c, OrderApi__Image_Path__c, OrderApi__Item_Class__r.Name, (SELECT Id,
                OrderApi__Subscription_Plan__r.Name, OrderApi__Subscription_Plan__r.Id FROM
                OrderApi__Subscription_Plan_Items__r ORDER BY OrderApi__Subscription_Plan__r.Name ASC) FROM OrderApi__Item__c WHERE OrderApi__Is_Active__c = TRUE]) {
            if (isDepartmentalMembershipJoin) {
                if ('Departmental Membership'.equalsIgnoreCase(tempItem.OrderApi__Item_Class__r.Name)
                    && tempItem.OrderApi__Subscription_Plan_Items__r.size() > 0) {
                    items.add(tempItem);
                }
            } else {
                if (tempItem.FS_Item_Functional_Titles__c != null && tempItem.FS_Item_Functional_Titles__c.split(';').contains(contactTitle)
                        && tempItem.OrderApi__Subscription_Plan_Items__r.size() > 0) {
                    items.add(tempItem);
                }
            }
        }
        return items;
    }

    @AuraEnabled
    public static OrderApi__Sales_Order__c createOrUpdateSalesOrder(Contact contact, Id itemId, Id planId,
            Id salesOrderId, Boolean isDepartmentalMembershipJoin, Boolean needToUpdate) {
                
        //try {
            //if (needToUpdate) {
                Boolean isNew = salesOrderId == null;
                if (isNew) {
                    OrderApi__Sales_Order__c newSalesOrder = new OrderApi__Sales_Order__c(
                            OrderApi__Contact__c = contact.Id,
                            OrderApi__Posting_Entity__c = 'Receipt',
                            OrderApi__Schedule_Type__c = 'Simple Receipt'
                    );
                    //  Vishnu: Added to set Entity to Account
                    if (isDepartmentalMembershipJoin) {
                        newSalesOrder.OrderApi__Entity__c = 'Account';
                    }
                    insert newSalesOrder;
                    salesOrderId = newSalesOrder.Id;
                }

                                /*List<OrderApi__Sales_Order_Line__c> newSalesOrderLines = new List<OrderApi__Sales_Order_Line__c>();
                List<OrderApi__Subscription_Plan__c> items = [Select Id, Name from OrderApi__Subscription_Plan__c where Id=:planId];
                system.debug('>>>> '+items);
                Integer quan = 1;
                /*if(items.size() > 0){
                    if(items[0].Name == '2 Year Calendar Membership'){
                        quan = 2;
                    }else if(items[0].Name == '3 Year Calendar Membership'){
                        quan = 3;
                    }else if(items[0].Name == '1 Year Calendar Membership'){
                        quan = 1;
                    }
                }
                */
                String subId;
                if (!isNew) {
                    List<OrderApi__Sales_Order_Line__c> salesOrderLinesNeedToDelete = new List<OrderApi__Sales_Order_Line__c>();
                    for (OrderApi__Sales_Order_Line__c tempSalesOrderLine : [   SELECT Id, OrderApi__Item__r.FS_Item_Functional_Titles__c,
                                                                                OrderApi__Subscription__c,
                                                                                OrderApi__Subscription_Plan__c,
                                                                                OrderApi__Subscription_Plan__r.Name
                                                                                FROM OrderApi__Sales_Order_Line__c
                                                                                WHERE OrderApi__Sales_Order__c = :salesOrderId 
                                                                                AND OrderApi__Subscription_Plan__c != NULL 
                                                                                AND OrderApi__Item__r.FS_Item_Functional_Titles__c != NULL]) {
                        if (tempSalesOrderLine.OrderApi__Item__r.FS_Item_Functional_Titles__c.split(';').contains(contact.Functional_Title__c)) {
                            system.debug('contact.Functional_Title__c '+contact.Functional_Title__c);
                            salesOrderLinesNeedToDelete.add(tempSalesOrderLine);
                        }
                        if(tempSalesOrderLine.OrderApi__Subscription_Plan__r.Name == '1 Year Calendar Membership'
                            || tempSalesOrderLine.OrderApi__Subscription_Plan__r.Name == '2 Year Calendar Membership'
                            || tempSalesOrderLine.OrderApi__Subscription_Plan__r.Name == '3 Year Calendar Membership'){
                            subId = tempSalesOrderLine.OrderApi__Subscription__c;
                        }
                    }
                    if (!salesOrderLinesNeedToDelete.isEmpty()) {
                      // delete salesOrderLinesNeedToDelete;
                    }
                }

                system.debug('isNew= ' + isNew);
                system.debug('itemId= '+itemId);

                if (isNew) {
                    FDService.OrderService orderService = FDService.OrderService.getInstance();
                    List<FDService.SalesOrderLine> lines = new List<FDService.SalesOrderLine>();

                    FDService.SalesOrderLine salesOrderLine = FDService.SalesOrderLine.getInstance();
                    salesOrderLine.salesOrder = salesOrderId;
                    salesOrderLine.item =  itemId;
                    salesOrderLine.subscriptionPlan=planId;

                    if(subId != null){
                        salesOrderLine.isRenewal = true;
                        salesOrderLine.subscription = subId;
                    }else{
                        List<OrderApi__Sales_Order__c> lstSOl = [Select Id, Temp_Sub_Id__c from OrderApi__Sales_Order__c where Id=:salesOrderId
                                                                and Temp_Sub_Id__c != null];
                        if(lstSOl.size() > 0){
                            salesOrderLine.isRenewal = true;
                            salesOrderLine.subscription = lstSOl[0].Temp_Sub_Id__c;
                        }
                    }
                    lines.add(salesOrderLine);
                    //  Vishnu: Added to avoid charging New Membership Fees for Departmental Join
                    if (contact.New_Mem_Fee__c ){//&& !isDepartmentalMembershipJoin) {
                        FDService.SalesOrderLine salesOrderLineNewMember = FDService.SalesOrderLine.getInstance();
                        salesOrderLineNewMember.salesOrder = salesOrderId;
                        salesOrderLineNewMember.item =  [SELECT Id FROM OrderApi__Item__c WHERE Name = 'New Member Fee' AND OrderApi__Is_Active__c = TRUE].Id;
                        lines.add(salesOrderLineNewMember);
                    }

                    if(!lines.isEmpty()) {
                        lines = orderService.addItemsToOrder(lines);
                    }
                }else{
                    List<OrderApi__Sales_Order_Line__c> lstSOlines = [Select Id from OrderApi__Sales_Order_Line__c where OrderApi__Item__c=:itemId and OrderApi__Sales_Order__c =:salesOrderId ];
                    
                    List<OrderApi__Sales_Order_Line__c> lstSOlDivision = [Select Id, OrderApi__Price_Rule__r.Name, OrderApi__Item_Class__r.Name, 
                                                            OrderAPI__Contact__r.Division__c from OrderApi__Sales_Order_Line__c 
                                                            where OrderApi__Sales_Order__c =:salesOrderId and OrderApi__Item_Class__r.Name =:'Divisions'];
                    
                    Boolean isDivisioChanged = false;
                    if(lstSOlDivision.size() > 0){
                        if(!lstSOlDivision[0].OrderApi__Price_Rule__r.Name.contains(lstSOlDivision[0].OrderAPI__Contact__r.Division__c)){
                            isDivisioChanged = true;
                        }
                    }

                    system.debug('lstSOlines>> '+ lstSOlines);
                    system.debug('lstSOlDivision>> '+ lstSOlDivision);

                    if(lstSOlines.size() == 0 || isDivisioChanged){
                        
                        List<OrderApi__Sales_Order_Line__c>  lstSOLineDelete = [Select Id, OrderApi__Item__c from OrderApi__Sales_Order_Line__c 
                                                                        where 
                                                                         OrderApi__Item__r.Name != 'New Member Fee' 
                                                                        and OrderApi__Sales_Order__c =:salesOrderId 
                                                                        and OrderApi__Sales_Order_Line__c =: null];
                        system.debug('lstSOLine>> '+ lstSOLineDelete);
                        system.debug('itemId>> '+ itemId);
                        /*if(lstSOLineDelete.size() > 0){

                            OrderApi__Sales_Order_Line__c[] salesOrderLines = (OrderApi__Sales_Order_Line__c[]) new Framework.Selector(OrderApi__Sales_Order_Line__c.SObjectType).selectById(new Set<Id>{salesOrderId}, Framework.SchemaService.getDescribe(OrderApi__Sales_Order_Line__c.OrderApi__Sales_Order__c).getName());
                            List<OrderApi__Sales_Order_Line__c> solsNeedToBeUpdated = new List<OrderApi__Sales_Order_Line__c>();
                            FDService.SalesOrderLine[] SOLs;
                            for (OrderApi__Sales_Order_Line__c sol : salesOrderLines) {
                                if (sol.OrderApi__Sales_Order_Line__c == null) {  
                                    sol.OrderApi__Item__c = itemId;
                                    solsNeedToBeUpdated.add(sol);
                                }
                                
                            }
                            if(solsNeedToBeUpdated  != NULL &&  solsNeedToBeUpdated.size() > 0) {
                                SOLs = FDService.SalesOrderLine.getInstance(solsNeedToBeUpdated);
                            }
                            if(SOLs != NULL && SOLs.size() > 0) {
                                FDService.OrderService.getInstance().updateItemsInOrder(SOLs);
                            }

                            FDService.OrderService orderService = FDService.OrderService.getInstance();
                            List<FDService.SalesOrderLine> lines = new List<FDService.SalesOrderLine>();

                            FDService.SalesOrderLine salesOrderLine = FDService.SalesOrderLine.getInstance(lstSOLine[0]);
                            salesOrderLine.item =  itemId;

                            FDService.OrderService.getInstance().updateItemInOrder(salesOrderLine);
                        }*/
                       

                        //if(lstSOLine.size() > 0){
                           FDService.OrderService orderService = FDService.OrderService.getInstance();
                            List<FDService.SalesOrderLine> lines = new List<FDService.SalesOrderLine>();

                            FDService.SalesOrderLine salesOrderLine = FDService.SalesOrderLine.getInstance();

                            salesOrderLine.item =  itemId;
                            salesOrderLine.salesOrder = salesOrderId;
                            salesOrderLine.subscriptionPlan=planId;
                            if(subId != null){
                                salesOrderLine.isRenewal = true;
                                salesOrderLine.subscription = subId;
                            }else{
                                List<OrderApi__Sales_Order__c> lstSOl = [Select Id, Temp_Sub_Id__c from OrderApi__Sales_Order__c where Id=:salesOrderId
                                                                        and Temp_Sub_Id__c != null];
                                if(lstSOl.size() > 0 ){
                                    salesOrderLine.isRenewal = true;
                                    salesOrderLine.subscription = lstSOl[0].Temp_Sub_Id__c;
                                }
                            }
                        
                            lines.add(salesOrderLine);
                            if(!lines.isEmpty()) {
                                lines = orderService.addItemsToOrder(lines);
                            }
                        //}

                           List<OrderApi__Sales_Order_Line__c>  lstSOLine = [Select Id from OrderApi__Sales_Order_Line__c 
                                                                        where OrderApi__Sales_Order_Line__c != null
                                                                        and OrderApi__Item__r.Name != 'New Member Fee' 
                                                                        and OrderApi__Sales_Order__c =:salesOrderId 
                                                                        and OrderApi__Item_Class__r.Name =: 'Sections'];
                            if(lstSOLine.size() > 0){
                                for(OrderApi__Sales_Order_Line__c sol : lstSOLine){
                                    sol.OrderApi__Sales_Order_Line__c = lines[0].Id;
                                }

                                update lstSOLine;
                            }
                            delete lstSOLineDelete;
                    }
                }

                
                /*//Trav - Added to properly show multi year section pricing
                Integer SubscriptionPlanYears = 1;
                List<OrderApi__Subscription_Plan__c> SubscriptionPlan = [Select Id, OrderApi__Initial_Term_Months__c from OrderApi__Subscription_Plan__c where Id = :planId];
                if(SubscriptionPlan.size() > 0){
                    //SubscriptionPlanYears = (SubscriptionPlan[0].OrderApi__Initial_Term_Months__c / 12).intValue();
                    List<OrderApi__Sales_Order_Line__c> priceResetLines = [SELECT Id FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Sales_Order__c = :salesOrderId and (OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections' OR OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Divisions')];
                    for(OrderApi__Sales_Order_Line__c priceResetLine: priceResetLines){ 
                        priceResetLine.OrderApi__Price_Override__c = false;
                    }
                    update priceResetLines; //Allow pricing rules to go into effect again
                    
                    //now the prices are normalized, if they are multi yeard override them
                    //if(SubscriptionPlanYears > 1){
                        priceResetLines = [SELECT Id, OrderApi__Sale_Price__c, OrderApi__Price_Override__c,OrderApi__Quantity__c, OrderApi__Overall_Total__c FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Sales_Order__c = :salesOrderId and (OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections' OR OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Divisions')];
                        for(OrderApi__Sales_Order_Line__c priceResetLine: priceResetLines){ 
                            priceResetLine.OrderApi__Price_Override__c = true;
                            //priceResetLine.OrderApi__Sale_Price__c = priceResetLine.OrderApi__Sale_Price__c * SubscriptionPlanYears;
                            priceResetLine.OrderApi__Quantity__c = quan;
                            priceResetLine.OrderApi__Overall_Total__c = priceResetLine.OrderApi__Sale_Price__c * priceResetLine.OrderApi__Quantity__c;
					        priceResetLine.OrderApi__Balance_Due__c = priceResetLine.OrderApi__Overall_Total__c;
                        }
                        update priceResetLines;
                    //}
                }*/
            //}

            
            
            /*List<OrderApi__Sales_Order__c> lstSOL = [SELECT Id, OrderApi__Total__c, OrderApi__Overall_Total__c, (SELECT Id, OrderApi__Total__c, OrderApi__Item__c, OrderApi__Item__r.Name, OrderApi__Item__r.OrderApi__Price__c, OrderApi__Item__r.OrderApi__Description__c, OrderApi__Item__r.OrderApi__Item_Class__r.Name, OrderApi__Item__r.OrderApi__Image_Path__c, OrderApi__Price_Rule__r.Name, OrderApi__Item_Class__r.Name, OrderApi__Subscription_Plan__c, OrderApi__Subscription_Plan__r.Name FROM OrderApi__Sales_Order_Lines__r) FROM OrderApi__Sales_Order__c WHERE Id = :salesOrderId];

            for(OrderApi__Sales_Order__c sol : lstSOl){
                sol.OrderApi__Overall_Total__c = sol.OrderApi__Total__c;
            }
            Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', true);
            update lstSOL;
            Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', false);*/
            return [SELECT Id, OrderApi__Total__c, OrderApi__Overall_Total__c, (SELECT Id, OrderApi__Total__c, OrderApi__Item__c, OrderApi__Item__r.Name, OrderApi__Item__r.OrderApi__Price__c, OrderApi__Item__r.OrderApi__Description__c, OrderApi__Item__r.OrderApi__Item_Class__r.Name, OrderApi__Item__r.OrderApi__Image_Path__c, OrderApi__Price_Rule__r.Name, OrderApi__Item_Class__r.Name, OrderApi__Subscription_Plan__c, OrderApi__Subscription_Plan__r.Name FROM OrderApi__Sales_Order_Lines__r) FROM OrderApi__Sales_Order__c WHERE Id = :salesOrderId];
        /*} catch (Exception e) {
            System.debug(e);
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            return null;
        }*/
    }

    @AuraEnabled
    public static String getAccountPopulationServed(String accountId) {
        Account objAcc = [SELECT Id, Population_Served_Size__c FROM Account WHERE Id=:accountId];
        return objAcc.Population_Served_Size__c;
    }   //  end of getAccountPopulationServed
}