/**
 * Helper class for FS_SalesOrderItemRoutingRuleService
 * @author Vishnu Pilli from fusionSpan
 * @date 2019-02-15
 */

public with sharing class FS_SalesOrderItemRoutingRuleService {
	
	public static void afterInsert(List<OrderApi__Sales_Order_Line__c> records) {
        //processRecords(records, null, 'afterInsert');
        updateSalesOrder(records);
    }

    public static void afterUpdate(List<OrderApi__Sales_Order_Line__c> records, Map<Id, OrderApi__Sales_Order_Line__c> oldMap) {
        //processRecords(records, oldMap, 'afterUpdate');
        updateSalesOrderDepMemFlag(records, oldMap);
    }

    public static void afterDelete(List<OrderApi__Sales_Order_Line__c> records) {
        //processRecords(records, null, 'afterDelete');
        updateSalesOrderDepMemFlag(records, null);
    }


    public static void updateSalesOrder(List<OrderApi__Sales_Order_Line__c> records){
    	System.debug('##--Inside Service call: ' + records);
    	List<OrderApi__Item_Class__c> lstItemClass = [SELECT Id, Name FROM OrderApi__Item_Class__c WHERE Name='Departmental Membership'];

    	List<OrderApi__Sales_Order__c> lstSalesOrders = new List<OrderApi__Sales_Order__c>();
    	System.debug('##--Got Item Class: ' + lstItemClass);
    	//List<OrderApi__Sales_Order_Line__c> lstSalesOrderLines = new List<OrderApi__Sales_Order_Line__c>();
    	Set<Id> setSalesOrderIds = new Set<Id>();

    	for(OrderApi__Sales_Order_Line__c objSalesLine : records){
    		if(objSalesLine.OrderApi__Item_Class__c == lstItemClass[0].Id){
    			setSalesOrderIds.add(objSalesLine.OrderApi__Sales_Order__c);
    		}
    	}	//	end of for-each Sales Line

    	System.debug('##--Sales Order to be updated: ' + setSalesOrderIds);

    	for(OrderApi__Sales_Order__c objSalesOrder : [SELECT Id, Name, FS_Departmental_Membership__c 
    													FROM OrderApi__Sales_Order__c WHERE Id IN :setSalesOrderIds]){
    		if(! objSalesOrder.FS_Departmental_Membership__c){
    			objSalesOrder.FS_Departmental_Membership__c = true;
    			lstSalesOrders.add(objSalesOrder);
    		}
    	}	//	end of for-each Sales Order

    	System.debug('##--Fetched Sales Orders: ' + lstSalesOrders);

    	if(! lstSalesOrders.isEmpty()){
    		System.debug('##--Updating Sales Orders: ' + lstSalesOrders);
    		update lstSalesOrders;
    	}

    }	//	end of updateSalesOrder

    private static void updateSalesOrderDepMemFlag(List<OrderApi__Sales_Order_Line__c> records, Map<Id, OrderApi__Sales_Order_Line__c> oldMap){
		List<OrderApi__Item_Class__c> lstItemClass = [SELECT Id, Name FROM OrderApi__Item_Class__c WHERE Name='Departmental Membership'];
		Set<Id> setSalesOrderIds = new Set<Id>();
		List<OrderApi__Sales_Order__c> lstSalesOrders = new List<OrderApi__Sales_Order__c>();

		System.debug('##--Inside Update call: ' + lstItemClass);

		for(OrderApi__Sales_Order_Line__c objSalesLine : records){
			System.debug('##--Sales Line item: ' + objSalesLine);
			if(oldMap != null){
				if((objSalesLine.OrderApi__Item_Class__c == lstItemClass[0].Id || 
					oldMap.get(objSalesLine.Id).OrderApi__Item_Class__c == lstItemClass[0].Id) &&
					objSalesLine.OrderApi__Item_Class__c !=  oldMap.get(objSalesLine.Id).OrderApi__Item_Class__c){
					setSalesOrderIds.add(objSalesLine.OrderApi__Sales_Order__c);
				}
			} else{
				//	If the oldMap is null then it is a Delete
				if(objSalesLine.OrderApi__Item_Class__c == lstItemClass[0].Id){
					setSalesOrderIds.add(objSalesLine.OrderApi__Sales_Order__c);
				}
			}	//	end of outer if-else
		}	//	for each Sales Order Line

		System.debug('##--Sales Orders need to be updated: ' + setSalesOrderIds);

		// Fetch all the Sales Order records for the changed Line items
		for(OrderApi__Sales_Order__c objSalesOrder : [SELECT Id, Name, FS_Departmental_Membership__c,
															(SELECT Id, Name, OrderApi__Item_Class__c FROM OrderApi__Sales_Order_Lines__r) 
    													FROM OrderApi__Sales_Order__c WHERE Id IN :setSalesOrderIds]){
			if(isSalesOrderNeedsUpdate(objSalesOrder, lstItemClass[0].Id)){
				objSalesOrder.FS_Departmental_Membership__c=false;
				lstSalesOrders.add(objSalesOrder);
			}
		}	//	end of for-each Sales Order

		if(! lstSalesOrders.isEmpty()){
    		System.debug('##--Updating Sales Orders: ' + lstSalesOrders);
    		update lstSalesOrders;
    	}

    }	//	end of updateSalesOrderDepMemFlag


    private static boolean isSalesOrderNeedsUpdate(OrderApi__Sales_Order__c objSalesOrder, Id depMemItemClassId){
    	for(OrderApi__Sales_Order_Line__c objSalesLine : objSalesOrder.OrderApi__Sales_Order_Lines__r){
    		System.debug('##--Order Line for Sales Order: ' + objSalesLine);
    		if(objSalesLine.OrderApi__Item_Class__c == depMemItemClassId){
    			return false;
    		}
    	}	//	end of for-each Sales Line item for every Order
    	return true;
    }	//	end of isSalesOrderNeedsUpdate

}	//	end of FS_SalesOrderItemRoutingRuleService