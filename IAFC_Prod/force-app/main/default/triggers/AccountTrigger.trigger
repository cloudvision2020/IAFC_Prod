trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    if(Trigger.isInsert){
        if(Trigger.isBefore) {
            AccountTriggerHandler.beforeInsert(Trigger.New);
        }else{
            AccountTriggerHandler.afterInsert(Trigger.New, Trigger.NewMap);
        }
    }else if(Trigger.isUpdate){
        if(Trigger.isBefore){
            AccountTriggerHandler.beforeUpdate(Trigger.New, Trigger.NewMap, Trigger.OldMap);
        }else{
            AccountTriggerHandler.afterUpdate(Trigger.New, Trigger.NewMap, Trigger.OldMap);
        }
    }
}