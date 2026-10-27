trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    if(Trigger.isInsert){
        if(Trigger.isBefore) {
            ContactTriggerHandler.beforeInsert(Trigger.New);
        }else{
            ContactTriggerHandler.afterInsert(Trigger.New, Trigger.NewMap);
        }
    }else if(Trigger.isUpdate){
        if(Trigger.isBefore){
            ContactTriggerHandler.beforeUpdate(Trigger.New, Trigger.NewMap, Trigger.OldMap);
        }else{
            ContactTriggerHandler.afterUpdate(Trigger.New, Trigger.NewMap, Trigger.OldMap);
        }
    }
}