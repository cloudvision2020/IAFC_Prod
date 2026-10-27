// Batch_UpdateSolActivationAndProration.cls
// Updates SOL Activation/End dates and prorates Sales Price.
// Usage (Apex): Database.executeBatch(new Batch_UpdateSolActivationAndProration(new Set<Id>{soId1, soId2}), 100);
// Usage (Flow): call the invocable method below with a list of Sales Order Ids.

public without sharing class Batch_UpdateSolActivationAndProration
    implements Database.Batchable<SObject>, Database.Stateful
{
    // Optional: restrict to specific Sales Orders
    private final Set<Id> salesOrderIds;

    // Constants
    private static final Date TARGET_END_DATE = Date.newInstance(2026, 12, 31);
    // Constants
    private static final Date TARGET_START_DATE = Date.newInstance(2026, 01, 01);


    // START: return the Sales Orders we care about
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String soql =
        'SELECT Id, Name, CreatedDate, ' +
        '       OrderApi__Account__c, OrderApi__Contact__c ' +
        'FROM OrderApi__Sales_Order__c ' + Label.Is_Date_Fix;
        


        return Database.getQueryLocator(soql);
    }

    // EXECUTE: load SOLs + Subscriptions, compute dates & proration, update
    public void execute(Database.BatchableContext bc, List<OrderApi__Sales_Order__c> scope) {
        if (scope.isEmpty()) return;

        Set<Id> soIds = new Set<Id>();
        for (OrderApi__Sales_Order__c so : scope) soIds.add(so.Id);

        // Pull SOLs with pricing, quantity, dates, and related Subscription end date
        List<OrderApi__Sales_Order_Line__c> sols = [
            SELECT Id,
                   OrderApi__Sales_Order__c,
                   OrderApi__Subscription__c,
                   OrderApi__Activation_Date__c,
                   OrderApi__End_Date__c,
                   OrderApi__Quantity__c,
                   OrderApi__Item__c,
                   OrderApi__List_Price__c,
                   OrderApi__Sale_Price__c,      // optional, if you prefer this as base
                   OrderApi__Subscription__r.OrderApi__Term_End_Date__c
            FROM OrderApi__Sales_Order_Line__c
            WHERE OrderApi__Sales_Order__c IN :soIds
        ];

        system.debug('>>>> '+sols.size() );
        List<OrderApi__Sales_Order_Line__c> toUpdate = new List<OrderApi__Sales_Order_Line__c>();

        for (OrderApi__Sales_Order_Line__c sol : sols) {
            if(sol.OrderApi__Item__c != Label.Metropolitan_Fire_Chiefs ){
                system.debug('>>>> '+sol.OrderApi__Subscription__c );
                Date subEnd = (sol.OrderApi__Subscription__c == null)
                    ? null
                    : sol.OrderApi__Subscription__r.OrderApi__Term_End_Date__c;

                if (subEnd == null) {
                    // No subscription end date to base on; skip safely.
                    continue;
                }

                Date activation = subEnd.addDays(1);
                Date endDate = TARGET_END_DATE;

                OrderApi__Sales_Order_Line__c upd = new OrderApi__Sales_Order_Line__c(
                    Id = sol.Id,
                    //OrderApi__Auto_Calculate_Activation_Date__c = false,
                    OrderApi__Activation_Date__c = activation,
                    OrderApi__End_Date__c = endDate,
                    OrderApi__Price_Override__c = false
                );
                toUpdate.add(upd);
            }
            
        }
        update toUpdate;

        List<OrderApi__Sales_Order__c> solUpdate = [Select Id, OrderApi__Overall_Total__c, OrderApi__Total__c	 from OrderApi__Sales_Order__c where Id=:soIds];
        for(OrderApi__Sales_Order__c so : solUpdate){
            so.OrderApi__Overall_Total__c = so.OrderApi__Total__c;
        }  
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: summary log, email, or Platform Event
    }

}