/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : BatchDeleteSystemLogScheduler
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

public class BatchDeleteSystemLogScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        Integer retentionDays = Integer.valueOf(Label.System_Log_Days);
        BatchDeleteSystemLog batchJob = new BatchDeleteSystemLog(retentionDays);
        Database.executeBatch(batchJob);
    }
}