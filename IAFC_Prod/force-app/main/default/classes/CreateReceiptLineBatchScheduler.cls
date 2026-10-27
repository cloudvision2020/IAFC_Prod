public class CreateReceiptLineBatchScheduler {
    /*global void execute(SchedulableContext sc) {
        ID lv_BatchProcessdId = Database.executeBatch(new CreateReceiptLineBatch());
    }*/
    public static void meth(){
        CreateReceiptLineBatch batch = new CreateReceiptLineBatch();
         String sch = '0 0 0/3 * * ?'; //'0 */3 * * *';
       String jobIDNew = system.schedule('Batch_Scheduled_to_Update_Receipt_and_create_RL1', sch, batch);
    }   
}