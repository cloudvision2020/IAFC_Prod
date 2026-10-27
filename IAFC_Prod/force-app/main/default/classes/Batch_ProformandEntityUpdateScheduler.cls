global class Batch_ProformandEntityUpdateScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        Batch_ProformandEntityUpdate batchInstance = new Batch_ProformandEntityUpdate();
        Database.executeBatch(batchInstance, 1);
    }
}