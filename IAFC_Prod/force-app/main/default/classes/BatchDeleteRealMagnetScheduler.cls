public class BatchDeleteRealMagnetScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        Integer retentionDays = Integer.valueOf(Label.Real_Magnet_Days);
        BatchDeleteRealMagnet batchJob = new BatchDeleteRealMagnet(retentionDays);
        Database.executeBatch(batchJob);
        
    }
}