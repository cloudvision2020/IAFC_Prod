/*
	@desc	service class for Routing Rule: FS_ContactPerformaRoutingRule
	Changes:-----------------
	27-Feb-2019 added filter oSOLine to filter Status closed + Posting status pending + posting Entity receipt
	NOTE: any changes made in this trigger should be updated in batch class: FS_ContactPerformaBatch
	-------------------------
*/
public class FS_ContactPerformaService {
    private static final String ITEM_CLASS_FUNCTIONAL_TITLE = 'Individual IAFC Dues';
    /*
    	@desc to perform update on Sales Order: FS_Proforma_Sync__c =  true
    */

    public static void updatePerforma(List<Contact> records, Map<Id, Contact> oldMap) {

        Map<Id, Contact> case1_div_contactMap = new Map<Id, Contact>();
        Map<Id, Contact> case2_func_contactMap = new Map<Id, Contact>();
        Map<Id, Contact> case3_OptOutDiv_contactMap = new Map<Id, Contact>();

        Map<Id, OrderApi__Sales_Order__c> salesOrdersToUpdateMap = new Map<Id, OrderApi__Sales_Order__c>();
        for (Contact oContact : records) {

            if (oldMap.get(oContact.Id) != null
                    && oContact.Division__c != oldMap.get(oContact.Id).Division__c) {
                case1_div_contactMap.put(oContact.Id, oContact);
            }

            if ((oContact.MailingState != null || oContact.MailingStateCode != null)
                    && (oContact.MailingState != oldMap.get(oContact.Id).MailingState
                            || oContact.MailingStateCode != oldMap.get(oContact.Id).MailingStateCode)) {
                case1_div_contactMap.put(oContact.Id, oContact);
            }

            if (oContact.Functional_Title__c != null && (oContact.Functional_Title__c != oldMap.get(oContact.Id).Functional_Title__c)) {
                case2_func_contactMap.put(oContact.Id, oContact);
            }

            if (oContact.Division_Opt_Out__c != oldMap.get(oContact.Id).Division_Opt_Out__c) {
                case3_OptOutDiv_contactMap.put(oContact.Id, oContact);
            }
        }

        System.debug('case1_div_contactMap');
        System.debug(case1_div_contactMap);
        System.debug('case2_func_contactMap');
        System.debug(case2_func_contactMap);
        System.debug('case3_OptOutDiv_contactMap');
        System.debug(case3_OptOutDiv_contactMap);

        for (OrderApi__Sales_Order_Line__c oSOLine : [
                SELECT Id, OrderApi__Is_Renewal__c,OrderApi__Sales_Order__c, OrderApi__Sales_Order__r.OrderApi__Posting_Status__c, OrderApi__Sales_Order__r.OrderApi__Status__c, OrderApi__Item__r.Name, OrderApi__Item__r.FS_Item_Functional_Titles__c, OrderApi__Contact__c, OrderApi__Contact__r.Division__c, OrderApi__Contact__r.Functional_Title__c, OrderApi__Item_Class__r.Name
                    FROM OrderApi__Sales_Order_Line__c
                    WHERE (
                            (OrderApi__Contact__c IN:case3_OptOutDiv_contactMap.keyset()
                            OR OrderApi__Contact__c IN:case1_div_contactMap.keyset()
                            OR OrderApi__Contact__c IN:case2_func_contactMap.keySet())
                        AND (OrderApi__Item_Class__r.Name != null
                            OR OrderApi__Contact__r.Functional_Title__c != null
                            OR OrderApi__Item__r.FS_Item_Functional_Titles__c != null
                            OR OrderApi__Is_Renewal__c = true )
                        AND OrderApi__Sales_Order__r.OrderApi__Status__c = 'Closed'
                        AND OrderApi__Sales_Order__r.OrderApi__Posting_Status__c = 'Pending'
                        AND OrderApi__Sales_Order__r.OrderApi__Posting_Entity__c = 'Receipt')
                    ORDER BY OrderApi__Sales_Order__c
        ]) {
            System.debug('oSOLine ' + oSOLine.Id + ' ' + oSOLine.OrderApi__Item_Class__r.Name + ' ' + oSOLine.OrderApi__Item__r.Name.startsWithIgnoreCase(oSOLine.OrderApi__Contact__r.Division__c) + ' ' + oSOLine.OrderApi__Item__r.Name + ' ' + oSOLine.OrderApi__Contact__r.Division__c);

            if (oSOLine.OrderApi__Contact__r.Division__c != null && oSOLine.OrderApi__Item_Class__r.Name == 'Divisions'
                    && (!oSOLine.OrderApi__Item__r.Name.startsWithIgnoreCase(oSOLine.OrderApi__Contact__r.Division__c))) {
                System.debug('INSIDE division:  ' + oSOLine.OrderApi__Sales_Order__c);
                salesOrdersToUpdateMap.put(oSOLine.OrderApi__Sales_Order__c, createSalesOrder(oSOLine.OrderApi__Sales_Order__c, true));

            } else if ((oSOLine.OrderApi__Item__r.FS_Item_Functional_Titles__c != null
                    && oSOLine.OrderApi__Contact__r.Functional_Title__c != null)
                    && (!oSOLine.OrderApi__Item__r.FS_Item_Functional_Titles__c.containsIgnoreCase(oSOLine.OrderApi__Contact__r.Functional_Title__c))
                    && oSOLine.OrderApi__Item_Class__r.Name.equalsIgnoreCase(ITEM_CLASS_FUNCTIONAL_TITLE)) { //case2_func_contactMap.get(oSOLine.OrderApi__Contact__c).Functional_Title__c
                System.debug('INSIDE functional:  ' + oSOLine.OrderApi__Sales_Order__c);
                salesOrdersToUpdateMap.put(oSOLine.OrderApi__Sales_Order__c, createSalesOrder(oSOLine.OrderApi__Sales_Order__c, true));

            } else if (!case3_OptOutDiv_contactMap.isEmpty() && oSOLine.OrderApi__Is_Renewal__c) {
                System.debug('INSIDE renewal:  ' + oSOLine.OrderApi__Sales_Order__c);
                salesOrdersToUpdateMap.put(oSOLine.OrderApi__Sales_Order__c, createSalesOrder(oSOLine.OrderApi__Sales_Order__c, true));
            } else {
                System.debug('INSIDE else:  ' + oSOLine.OrderApi__Sales_Order__c);
                if (!salesOrdersToUpdateMap.containsKey(oSOLine.OrderApi__Sales_Order__c)) {
                    salesOrdersToUpdateMap.put(oSOLine.OrderApi__Sales_Order__c, createSalesOrder(oSOLine.OrderApi__Sales_Order__c, false));
                }

            }
        }
        //Perform DML
        try {
            System.debug('oPerformaSyncOnSO.isEmpty()   ' + salesOrdersToUpdateMap.isEmpty());
            if (!salesOrdersToUpdateMap.isEmpty()) {
                update salesOrdersToUpdateMap.values();
            }
        } catch (DmlException oEx) {
            System.debug('FS_ContactPerformaRoutingRule FAILED to update : ' + oEx.getMessage());
        }

    }
    public static OrderApi__Sales_Order__c createSalesOrder(Id oSOId, boolean syncStatus) {
        OrderApi__Sales_Order__c oSO = new OrderApi__Sales_Order__c();
        oSO.Id = oSOId;
        oSO.FS_Proforma_Sync__c = syncStatus;
        return oSO;
    }
}