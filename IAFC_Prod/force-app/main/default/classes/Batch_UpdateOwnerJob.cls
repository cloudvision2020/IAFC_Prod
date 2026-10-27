/**
*   Class Name - UpdateOwnerBatchJob.
*   Description - Update the Owner id based on the parameter passed.
*   Created Date - 7th May 2024.
*   Author - Drashti LLC.
**/
global class Batch_UpdateOwnerJob implements Database.Batchable<sObject> {
   
    private static final String MY_OWNER_ID = Label.Helix_User;
    
    private String objectType;
    
    global Batch_UpdateOwnerJob(String objType) {
        this.objectType = objType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //return Database.getQueryLocator('SELECT Id, OwnerId FROM objectType WHERE CreatedDate = TODAY');
        String query = 'SELECT Id, OwnerId FROM ' + objectType + ' WHERE CreatedDate = TODAY';
        System.debug('Executing query: ' + query);
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        system.debug('Scope' +scope);
        List<sObject> recordsToUpdate = new List<sObject>();
        for(sObject obj : scope) {
            system.debug('Scope' +scope);
            obj.put('OwnerId', MY_OWNER_ID);
            recordsToUpdate.add(obj);
        }
        if(!recordsToUpdate.isEmpty()) {
            Framework.Dispatcher.disableTriggerInContext.put(objectType, true);
            update recordsToUpdate;
            Framework.Dispatcher.disableTriggerInContext.put(objectType, false);
            
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}