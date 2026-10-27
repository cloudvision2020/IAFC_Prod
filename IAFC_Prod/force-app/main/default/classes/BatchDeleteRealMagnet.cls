public class BatchDeleteRealMagnet implements Database.Batchable<sObject> {
    private Integer retentionDays;
    
    public BatchDeleteRealMagnet(Integer retentionDays) {
        this.retentionDays = retentionDays;
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        Date thresholdDate = Date.today().addDays(-retentionDays);
        
        return Database.getQueryLocator([
            SELECT Id FROM Real_Magnet__Activity_History__c WHERE CreatedDate < :thresholdDate 
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Real_Magnet__Activity_History__c> scope) {
        delete scope;
    }
    
    public void finish(Database.BatchableContext context) {
    }
}