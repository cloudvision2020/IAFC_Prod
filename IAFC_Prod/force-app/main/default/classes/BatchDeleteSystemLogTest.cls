/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : BatchDeleteSystemLogTest
 * Author          : <YourName>
 * Created Date    : Aug 17, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Aug 17, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 17, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
private class BatchDeleteSystemLogTest {

    @testSetup
    static void setupData() {
        List<Framework__System_Log__c> logs = new List<Framework__System_Log__c>();
        for (Integer i = 0; i < 200; i++) {
            logs.add(new Framework__System_Log__c());
        }
        insert logs;
    }

    @isTest
    static void testBatchDeletesOldRecords() {
        // Force all records' CreatedDate to be older than the retention window
        List<Framework__System_Log__c> logs = [SELECT Id FROM Framework__System_Log__c];
        Test.setCreatedDate(logs[0].Id, Date.today().addDays(-90)); // older than 60 days

        // Set every record old so the whole scope qualifies for deletion
        for (Framework__System_Log__c log : logs) {
            Test.setCreatedDate(log.Id, Date.today().addDays(-90));
        }

        Test.startTest();
        BatchDeleteSystemLog batchJob = new BatchDeleteSystemLog(60);
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        System.assertEquals(0,
            [SELECT COUNT() FROM Framework__System_Log__c],
            'All records older than retention should be deleted');
    }

    @isTest
    static void testBatchKeepsRecentRecords() {
        // Records created "today" in @testSetup are recent — should NOT be deleted
        Test.startTest();
        Database.executeBatch(new BatchDeleteSystemLog(60), 200);
        Test.stopTest();

        System.assertEquals(200,
            [SELECT COUNT() FROM Framework__System_Log__c],
            'Recent records within retention should be kept');
    }

    @isTest
    static void testScheduler() {
        Test.startTest();
        String cron = '0 0 2 1 * ? 2050';
        String jobId = System.schedule('Test System Log Delete', cron,
            new BatchDeleteSystemLogScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cron, ct.CronExpression, 'Scheduler should be registered');
    }
}