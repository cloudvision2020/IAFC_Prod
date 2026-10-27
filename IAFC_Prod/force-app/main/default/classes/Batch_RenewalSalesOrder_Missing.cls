/**
* @File Name : Batch_RenewalSalesOrder_Missing.cls
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

public without sharing class Batch_RenewalSalesOrder_Missing
    implements Database.Batchable<SObject>, Database.Stateful {


    public Database.QueryLocator start(Database.BatchableContext bc) {
        String soql =
        'SELECT Id, Name, CreatedDate, ' +
        '       OrderApi__Account__c, OrderApi__Contact__c ' +
        'FROM OrderApi__Sales_Order__c ' +
        'WHERE Is_Data_Fix__c = true';


        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<OrderApi__Sales_Order__c> scope) {
        SalesOrderLineReconciliationService.reconcile(scope);
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: send a summary, write an Integration_Log__c, or fire a Platform Event
        // ReconcileLog.logInfo('SOL Reconciliation batch finished.');
    }
}