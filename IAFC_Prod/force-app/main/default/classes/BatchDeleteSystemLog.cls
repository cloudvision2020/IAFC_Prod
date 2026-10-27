/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : BatchDeleteSystemLog
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
public class BatchDeleteSystemLog implements Database.Batchable<sObject> {
    private Integer retentionDays;

    public BatchDeleteSystemLog(Integer retentionDays) {
        this.retentionDays = retentionDays;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        Date thresholdDate = Date.today().addDays(-retentionDays);

        return Database.getQueryLocator([
            SELECT Id FROM Framework__System_Log__c WHERE CreatedDate < :thresholdDate
        ]);
    }

    public void execute(Database.BatchableContext context, List<Framework__System_Log__c> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext context) {
    }
}