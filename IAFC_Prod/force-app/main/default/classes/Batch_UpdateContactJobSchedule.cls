/**
*   Class Name - Batch_UpdateContactJobSchedule.
*   Description - Update Contact created today with the Owner id as Helix User
*   Created Date - 7th May 2024.
*   Author - Drashti LLC.
**/
global class Batch_UpdateContactJobSchedule implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        Batch_UpdateOwnerJob contactBatch = new Batch_UpdateOwnerJob('Contact');
        Database.executeBatch(contactBatch);
    }
}