global class Batch_ProformandEntityUpdate implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String orderStatus = 'Closed';
        String postingStatus = 'Pending';
        String query = ' SELECT Id, (SELECT Id, OrderApi__Account__c, '+ 
                        ' OrderApi__Account__r.Has_Group_Membership__c, OrderApi__Contact__r.Has_Group_Membership__c FROM OrderApi__Sales_Order_Lines__r '+ 
                        ' WHERE OrderApi__Is_Renewal__c = true  and OrderApi__Subscription__c != null LIMIT 1 ) '+ 
                        ' FROM OrderApi__Sales_Order__c WHERE CreatedDate = TODAY and OrderApi__Status__c =: orderStatus and OrderApi__Posting_Status__c =:postingStatus';

        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<OrderApi__Sales_Order__c> scope) {
        List<OrderApi__Sales_Order__c> lstOrderUpdate = new List<OrderApi__Sales_Order__c>();
        for(OrderApi__Sales_Order__c order : scope) {
            if(order.OrderApi__Sales_Order_Lines__r.size() > 0) {
                OrderApi__Sales_Order_Line__c lineItem = order.OrderApi__Sales_Order_Lines__r[0];
                OrderApi__Sales_Order__c sol = new OrderApi__Sales_Order__c();
                if(lineItem.OrderApi__Account__r.Has_Group_Membership__c && lineItem.OrderApi__Contact__r.Has_Group_Membership__c) {
                    sol.OrderApi__Entity__c = 'Account';
                }
                sol.OrderApi__Is_Proforma__c = true;
                sol.Id = order.Id;
                lstOrderUpdate.add(sol);
            }
        }
        update lstOrderUpdate;
    }
    
    global void finish(Database.BatchableContext BC) {
    }
    
}