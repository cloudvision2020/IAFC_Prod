/**
*   Class Name - Batch_UpdateAccountJobSchedule.
*   Description - Update Account created today with the Owner id as Helix User
*   Created Date - 7th May 2024.
*   Author - Drashti LLC.
**/
global class Batch_UpdateAccountJobSchedule implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        Batch_UpdateOwnerJob accountBatch = new Batch_UpdateOwnerJob('Account');
        Database.executeBatch(accountBatch);
    }
}