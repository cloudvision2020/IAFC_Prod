trigger CommunityGroupMemberTrigger on PagesApi__Community_Group_Member__c (before insert, before update, after insert, after update) {
    if(Trigger.isInsert){
        if(Trigger.isBefore) {
            CommunityGroupMemberTriggerHandler.beforeInsert(Trigger.New);
        }else{
            CommunityGroupMemberTriggerHandler.afterInsert(Trigger.New, Trigger.NewMap);
        }
    }else if(Trigger.isUpdate){
        if(Trigger.isBefore){
            CommunityGroupMemberTriggerHandler.beforeUpdate(Trigger.New, Trigger.NewMap, Trigger.OldMap);
        }else{
            CommunityGroupMemberTriggerHandler.afterUpdate(Trigger.New, Trigger.NewMap, Trigger.OldMap);
        }
    }
}