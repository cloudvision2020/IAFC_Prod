/*@desc
*Case-1* If Division on the Contact object  is changed after proforma generation and
does not match the Division Item on the Sales Order Line THEN Proforma Sync is TRUE on sales order
*Case-2* If Functional Title on the Contact object is changed after proforma generation and 
the proforma Sales Order Line that includes the IAFC Individual Membership Item and 
does not correspond to the correct Functional Title THEN Proforma Sync is TRUE
*/
global class FS_ContactPerformaBatch implements Database.Batchable<sObject>{
    private static final String ITEM_CLASS_FUNCTIONAL_TITLE = 'Individual IAFC Dues';
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, OrderApi__Is_Renewal__c ,OrderApi__Sales_Order__c, OrderApi__Sales_Order__r.OrderApi__Posting_Status__c, OrderApi__Sales_Order__r.OrderApi__Status__c, OrderApi__Item__r.Name, OrderApi__Item__r.FS_Item_Functional_Titles__c, OrderApi__Contact__c, OrderApi__Contact__r.Division__c, OrderApi__Contact__r.Functional_Title__c, OrderApi__Item_Class__r.Name  FROM OrderApi__Sales_Order_Line__c  WHERE  (OrderApi__Item_Class__r.Name != null OR OrderApi__Contact__r.Functional_Title__c != null OR OrderApi__Item__r.FS_Item_Functional_Titles__c!= null  OR OrderApi__Is_Renewal__c = true  ) ORDER BY OrderApi__Sales_Order__c' ;
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<OrderApi__Sales_Order_Line__c  > scope){
        //Maintain two set of ids to update the records based on cases 
        Set<Id> divisionSOIdsSet = new Set<Id>();
        Set<Id> functionSOIdsSet = new Set<Id>();
        //Map to store SO to update performa sync 
        Map<Id, OrderApi__Sales_Order__c> oPerformaSyncOnSO = new Map<Id, OrderApi__Sales_Order__c>();
        
        for(OrderApi__Sales_Order_Line__c  oSOLine: scope ){            
            //System.debug('oSOLine '+ oSOLine.Id + ' '+ oSOLine.OrderApi__Item_Class__r.Name + ' '+ oSOLine.OrderApi__Item__r.Name.startsWithIgnoreCase(oSOLine.OrderApi__Contact__r.Division__c) + ' '+ oSOLine.OrderApi__Item__r.Name + ' '+ oSOLine.OrderApi__Contact__r.Division__c );
            if(oSOLine.OrderApi__Contact__r.Division__c!= null && oSOLine.OrderApi__Item_Class__r.Name == 'Divisions' && (!oSOLine.OrderApi__Item__r.Name.startsWithIgnoreCase(oSOLine.OrderApi__Contact__r.Division__c))){
                system.debug('INSIDE division:  ' + oSOLine.OrderApi__Sales_Order__c);
                oPerformaSyncOnSO.put(oSOLine.OrderApi__Sales_Order__c,createSalesOrder(oSOLine.OrderApi__Sales_Order__c, true) );
            }else if((oSOLine.OrderApi__Item__r.FS_Item_Functional_Titles__c != null && oSOLine.OrderApi__Contact__r.Functional_Title__c != null) && (!oSOLine.OrderApi__Item__r.FS_Item_Functional_Titles__c.containsIgnoreCase(oSOLine.OrderApi__Contact__r.Functional_Title__c) && oSOLine.OrderApi__Item_Class__r.Name.equalsIgnoreCase(ITEM_CLASS_FUNCTIONAL_TITLE))){ //case2_func_contactMap.get(oSOLine.OrderApi__Contact__c).Functional_Title__c 
                system.debug('INSIDE functional:  ' + oSOLine.OrderApi__Sales_Order__c);
                oPerformaSyncOnSO.put(oSOLine.OrderApi__Sales_Order__c,createSalesOrder(oSOLine.OrderApi__Sales_Order__c, true) );
            }
            /*else if(!case3_OptOutDiv_contactMap.isEmpty() && oSOLine.OrderApi__Is_Renewal__c){
                system.debug('INSIDE renewal:  ' + oSOLine.OrderApi__Sales_Order__c);
                oPerformaSyncOnSO.put(oSOLine.OrderApi__Sales_Order__c,createSalesOrder(oSOLine.OrderApi__Sales_Order__c, true) );
            }
			*/
            else{
                system.debug('INSIDE else:  ' + oSOLine.OrderApi__Sales_Order__c);
                if(!oPerformaSyncOnSO.containsKey(oSOLine.OrderApi__Sales_Order__c))  oPerformaSyncOnSO.put(oSOLine.OrderApi__Sales_Order__c,createSalesOrder(oSOLine.OrderApi__Sales_Order__c, false) );
        	}
        }
        //Perform after update on SO records
                
        //Perform DML 
        try{
            system.debug('oPerformaSyncOnSO.isEmpty()   ' + oPerformaSyncOnSO.isEmpty());
            if(!oPerformaSyncOnSO.isEmpty()) update oPerformaSyncOnSO.values();
        }catch(DMLException oEx){
            system.debug('FS_ContactPerformaRoutingRule FAILED to update : ' + oEx.getMessage());
        }        
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    public static OrderApi__Sales_Order__c createSalesOrder(Id oSOId, boolean syncStatus){
        OrderApi__Sales_Order__c oSO = new OrderApi__Sales_Order__c();
        oSO.Id = oSOId;
        oSO.FS_Proforma_Sync__c = syncStatus;
        return oSO;
    }
    
}