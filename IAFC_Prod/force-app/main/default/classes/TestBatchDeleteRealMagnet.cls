@IsTest
public class TestBatchDeleteRealMagnet {
    @IsTest
    static void testBatchDeleteRealMagnet() {
        Integer retentionDays = 10;
        Date thresholdDate = Date.today().addDays(-retentionDays - 1);
        
        List<Real_Magnet__Activity_History__c> testRecords = new List<Real_Magnet__Activity_History__c>();
        for (Integer i = 0; i < 20; i++) { 
            Real_Magnet__Activity_History__c record = new Real_Magnet__Activity_History__c();
            if (i < 10) {
                record.Real_Magnet__Activity_Date__c = Date.today().addDays(-(i + 1)); 
            } 
            else {
                record.Real_Magnet__Activity_Date__c = Date.today().addDays(-(i + retentionDays +2));
            }
            testRecords.add(record);
        }
        
        insert testRecords;
        
        Test.startTest();
        // Database.executebatch( new batchdeleterealmagnet(-10));
        BatchDeleteRealMagnetScheduler scheduler = new BatchDeleteRealMagnetScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        Integer remainingRecords = [SELECT count() FROM Real_Magnet__Activity_History__c WHERE Real_Magnet__Activity_Date__c >= :thresholdDate];
        System.assertEquals(10, remainingRecords, 'Only records outside the retention period should remain after batch execution.');
    }
}