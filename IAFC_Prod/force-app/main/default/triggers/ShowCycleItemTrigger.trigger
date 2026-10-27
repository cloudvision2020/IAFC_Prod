trigger ShowCycleItemTrigger on s7e__Item__c (after insert, after update) {
    if(trigger.isAfter && (trigger.isUpdate || trigger.isInsert)){
        ItemTriggerHandler2.handleItem(trigger.newMap, trigger.oldMap);
    }
}