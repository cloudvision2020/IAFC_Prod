// Inserting Receipt Line item from Sales order Line item and creating transactions and transaction line item
global class CreateReceiptLineBatch implements Database.Batchable<sObject>,schedulable{
    
    global void execute(SchedulableContext sc) {
        CreateReceiptLineBatch a = new CreateReceiptLineBatch();
        Database.executeBatch(a);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query ='Select id,OrderApi__Sales_Order__c,No_of_Receipt_Lines__c from OrderApi__Receipt__c where No_of_Receipt_Lines__c =0 AND OrderApi__Is_Posted__c = false AND (CreatedDate = Today OR CreatedDate = Yesterday)'; 
        return Database.getQueryLocator(query);        
    }
    
    global void execute(Database.BatchableContext BC, List<OrderApi__Receipt__c> scope){
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> ReceiptIds = new Set<ID>();
        Map<Id,Id> mapOfSOIdandRecId = new Map<Id,Id>();
       
        for(OrderApi__Receipt__c R: scope){
            if(R.No_of_Receipt_Lines__c == 0 && R.OrderApi__Sales_Order__c != NULL ){
                salesOrderIds.add(R.OrderApi__Sales_Order__c);     
                mapOfSOIdandRecId.put(R.OrderApi__Sales_Order__c,R.Id);
            }
        }
        //Get Sales Order Line Item
        If(!salesOrderIds.IsEmpty()){
            List<OrderApi__Sales_Order_Line__c> SOLlist = [select id,OrderApi__Item__c,OrderApi__Sale_Price__c,OrderApi__Sales_Order__c,OrderApi__Activation_Date__c,OrderApi__End_Date__c,
                                                           OrderApi__GL_Account__c, OrderApi__Business_Group__c,OrderApi__Subscription__c,OrderApi__Price_Rule__c,OrderApi__Price_Override__c,
                                                           OrderApi__Subscription_Plan__c
                                                           from OrderApi__Sales_Order_Line__c 
                                                           where OrderApi__Sales_Order__c IN :mapOfSOIdandRecId.keySet()];//mariyam
            List<OrderApi__Receipt_Line__c> RecLine = new List<OrderApi__Receipt_Line__c>();            
            for(OrderApi__Sales_Order_Line__c SolRec :SOLlist){
                
                OrderApi__Receipt_Line__c RL = new OrderApi__Receipt_Line__c();
                RL.OrderApi__Receipt__c = mapOfSOIdandRecId.get(SolRec.OrderApi__Sales_Order__c);
                RL.OrderApi__Item__c = SolRec.OrderApi__Item__c;
                RL.OrderApi__Sale_Price__c = SolRec.OrderApi__Sale_Price__c ;
                //RL.OrderApi__Sales_Order_Line__c = SolRec.id;
                //RL.OrderApi__Sales_Order__c = SolRec.OrderApi__Sales_Order__c;
                RL.OrderApi__Activation_Date__c = SolRec.OrderApi__Activation_Date__c;
                //RL.OrderApi__End_Date__c = SolRec.OrderApi__End_Date__c;
                RL.OrderApi__GL_Account__c = SolRec.OrderApi__GL_Account__c;
                RL.OrderApi__Business_Group__c = SolRec.OrderApi__Business_Group__c;
                RL.OrderApi__Subscription_Plan__c = SolRec.OrderApi__Subscription_Plan__c;
                RL.OrderApi__Subscription__c = SolRec.OrderApi__Subscription__c;
                RL.OrderApi__Price_Override__c = SolRec.OrderApi__Price_Override__c;
                RL.OrderApi__Price_Rule__c = SolRec.OrderApi__Price_Rule__c;
                RecLine.add(RL);
            }
            insert RecLine;
            List<OrderApi__Receipt__c> listOfOrderReceipt = [select id,OrderApi__Is_Posted__c,OrderApi__Posted_Date__c,OrderApi__Date__c
                                                             from OrderApi__Receipt__c where OrderApi__Sales_Order__c IN :mapOfSOIdandRecId.keySet() ];
            for(OrderApi__Receipt__c reciptItem :listOfOrderReceipt){
                reciptItem.OrderApi__Is_Posted__c = true;
                if(reciptItem.OrderApi__Posted_Date__c == NULL){
                    reciptItem.OrderApi__Posted_Date__c = reciptItem.OrderApi__Date__c;                    
                }
                
            }
            update listOfOrderReceipt;
        }
        
    }   
    global void finish(Database.BatchableContext BC)    {
        //CreateReceiptLineBatch batch = new CreateReceiptLineBatch();
        //String sch = '0 0 0,4,8,12,16,20 * * ?'; //'0 */3 * * *';
        //String jobIDNew = system.schedule('Batch_Scheduled_to_Update_Receipt_and_create_RL1234', sch, batch);
               
    }
}