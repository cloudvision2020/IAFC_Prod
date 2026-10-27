public class Batch_InvoiceCanellationScheduler implements Schedulable {
    
    public void execute(SchedulableContext context){
        Batch_InvoiceCanellation batchInvoice = new Batch_InvoiceCanellation();
        
         Database.executeBatch(batchInvoice,1);
    }
    
}