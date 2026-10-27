/**
* @File Name : SalesOrderLineReconciliationService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 27, 2025 |   | Initial Version
**/

public without sharing class SalesOrderLineReconciliationService {

    public static void reconcile(List<OrderApi__Sales_Order__c> salesOrders) {
        if (salesOrders == null || salesOrders.isEmpty()) return;

        // Index SOs
        Set<Id> soIds = new Set<Id>();

        for (OrderApi__Sales_Order__c so : salesOrders) soIds.add(so.Id);

        // 1) Pull existing SOLs for scope (used for both subscription inference and dedupe)
        Map<Id, List<OrderApi__Sales_Order_Line__c>> soIdToSols = new Map<Id, List<OrderApi__Sales_Order_Line__c>>();
        Set<Id> subscriptionIds = new Set<Id>();

        String parentSOL;
        for (OrderApi__Sales_Order_Line__c sol : [
            SELECT Id,
                   OrderApi__Sales_Order__c,
                   OrderApi__Subscription__c,       // Subscription lives on SOL
                   OrderApi__Item__c,
                   OrderApi__Quantity__c
            FROM OrderApi__Sales_Order_Line__c
            WHERE OrderApi__Sales_Order__c IN :soIds
        ]) {
            List<OrderApi__Sales_Order_Line__c> bucket = soIdToSols.get(sol.OrderApi__Sales_Order__c);
            if (bucket == null) {
                bucket = new List<OrderApi__Sales_Order_Line__c>();
                soIdToSols.put(sol.OrderApi__Sales_Order__c, bucket);
            }
            bucket.add(sol);
            if (sol.OrderApi__Subscription__c != null) {
                parentSOL = sol.id;
                subscriptionIds.add(sol.OrderApi__Subscription__c);
            }
        }

        // Partition SOs: can we infer a subscription from existing SOLs?
        Set<Id> resolvableSoIds = new Set<Id>();
        Set<Id> unknownSoIds    = new Set<Id>();
        for (OrderApi__Sales_Order__c so : salesOrders) {
            List<OrderApi__Sales_Order_Line__c> sols = soIdToSols.get(so.Id);
            Boolean hasSub = false;
            if (sols != null) {
                for (OrderApi__Sales_Order_Line__c s : sols) {
                    if (s.OrderApi__Subscription__c != null) { hasSub = true; break; }
                }
            }
            if (hasSub) resolvableSoIds.add(so.Id);
            else        unknownSoIds.add(so.Id);
        }

        if (subscriptionIds.isEmpty()) {
            // Nothing we can reconcile
            // ReconcileLog.logInfo('No subscriptions inferred from SOLs. Skipping reconciliation for this chunk.');
            return;
        }

		Set<Id> termIds = new Set<Id>();
        // 2) Build latest term per subscription
        Map<Id, OrderApi__Renewal__c> latestTermBySub = new Map<Id, OrderApi__Renewal__c>();
        for (OrderApi__Renewal__c term : [
            SELECT Id, OrderApi__Subscription__c
            FROM OrderApi__Renewal__c
            WHERE OrderApi__Subscription__c IN :subscriptionIds ORDER BY CreatedDate DESC limit 1
        ]) {
           latestTermBySub.put(term.OrderApi__Subscription__c, term);
		   termIds.add(term.Id);
        }


        // 3) Pull Subscription Lines (latest terms only)
        Map<Id, List<OrderApi__Subscription_Line__c>> termIdToSubLines = new Map<Id, List<OrderApi__Subscription_Line__c>>();
        for (OrderApi__Subscription_Line__c sl : [
            SELECT Id, OrderApi__Term__c,
                   OrderApi__Item__c,
                   OrderApi__Quantity__c,
				   OrderApi__Sales_Order_Line__c
            FROM OrderApi__Subscription_Line__c
            WHERE OrderApi__Term__c IN :termIds
        ]) {
            List<OrderApi__Subscription_Line__c> bucket = termIdToSubLines.get(sl.OrderApi__Term__c);
            if (bucket == null) {
                bucket = new List<OrderApi__Subscription_Line__c>();
                termIdToSubLines.put(sl.OrderApi__Term__c, bucket);
            }
            bucket.add(sl);
        }

        // 4) Compare & backfill per (SO, Subscription)
        List<OrderApi__Sales_Order_Line__c> toInsert = new List<OrderApi__Sales_Order_Line__c>();

        FDService.OrderService service = FDService.OrderService.getInstance();

        List<FDService.SalesOrderLine> lineItemsToInsertParent = new List<FDService.SalesOrderLine>();

        for (Id soId : resolvableSoIds) {
            List<OrderApi__Sales_Order_Line__c> existingSols = soIdToSols.get(soId);
            if (existingSols == null) continue;

            // Group existing SOLs by Subscription
            Map<Id, List<OrderApi__Sales_Order_Line__c>> subIdToExisting = new Map<Id, List<OrderApi__Sales_Order_Line__c>>();
            for (OrderApi__Sales_Order_Line__c sol : existingSols) {
                if (sol.OrderApi__Subscription__c == null) continue;
                List<OrderApi__Sales_Order_Line__c> listy = subIdToExisting.get(sol.OrderApi__Subscription__c);
                if (listy == null) {
                    listy = new List<OrderApi__Sales_Order_Line__c>();
                    subIdToExisting.put(sol.OrderApi__Subscription__c, listy);
                }
                listy.add(sol);
            }

            for (Id subId : subIdToExisting.keySet()) {
                OrderApi__Renewal__c latest = latestTermBySub.get(subId);

                if (latest == null) continue;

                List<OrderApi__Subscription_Line__c> subLines = termIdToSubLines.get(latest.Id);
                if (subLines == null || subLines.isEmpty()) continue;

                // Index existing SOLs by your idempotency key
                Map<String, OrderApi__Sales_Order_Line__c> existingByKey = new Map<String, OrderApi__Sales_Order_Line__c>();
                for (OrderApi__Sales_Order_Line__c sol : subIdToExisting.get(subId)) {
                    existingByKey.put(sol.OrderApi__Item__c, sol);
                }

                

                for (OrderApi__Subscription_Line__c sLine : subLines) {
                    String key = sLine.OrderApi__Item__c;
                    if (!existingByKey.containsKey(key)) {

                        FDService.SalesOrderLine newLineItem = FDService.SalesOrderLine.getInstance();
                        newLineItem.salesOrder = soId;
                        newLineItem.item = sLine.OrderApi__Item__c;
                        //newLineItem.Quantity = sLine.OrderApi__Quantity__c;
                        newLineItem.Subscription = subId;
                        newLineItem.salesorderline = parentSOL;
                        newLineItem.isRenewal = true;
                        lineItemsToInsertParent.add(newLineItem);

                        /*OrderApi__Sales_Order_Line__c newSol = new OrderApi__Sales_Order_Line__c();
                        newSol.OrderApi__Sales_Order__c  = soId;
                        newSol.OrderApi__Subscription__c = subId; // maintain link to same subscription
                        newSol.OrderApi__Item__c         = sLine.OrderApi__Item__c;
                        newSol.OrderApi__Quantity__c     = sLine.OrderApi__Quantity__c;
                        newSol.OrderApi__Sales_Order_Line__c = parentSOL;
                        // TODO: If your org requires PricebookEntry or other fields on SOL, map them here
                        // newSol.OrderApi__Price__c = ...;
                        // newSol.OrderApi__GL_Code__c = ...;

                        toInsert.add(newSol);*/
                    }
                }
            }
        }


        if (!lineItemsToInsertParent.isEmpty()) {
            lineItemsToInsertParent = FDService.OrderService.getInstance().addItemsToOrder(lineItemsToInsertParent);
        }

        List<OrderApi__Sales_Order__c> solUpdate = [Select Id, OrderApi__Overall_Total__c, OrderApi__Total__c	 from OrderApi__Sales_Order__c where Id=:soIds];
        for(OrderApi__Sales_Order__c so : solUpdate){
            so.OrderApi__Overall_Total__c = so.OrderApi__Total__c;
        }   

        update solUpdate;
        if (!toInsert.isEmpty()) {
            Database.SaveResult[] sr = Database.insert(toInsert, /* allOrNone */ false);
            // Optional: log failures
            // for (Database.SaveResult r : sr) if (!r.isSuccess()) ReconcileLog.logError('Insert SOL failed: ' + r.getErrors()[0].getMessage());
        }

        // Optional: handle unknown SOs (no SOL → cannot infer subscription)
        // if (!unknownSoIds.isEmpty()) ReconcileLog.logInfo('Unknown SOs (no SOLs to infer subscription): ' + unknownSoIds.size());
    }

}