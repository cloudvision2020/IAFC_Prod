/**
 * Trigger for AccountContactRelation
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-11
 */

trigger FS_AccountContactRelationTrigger on AccountContactRelation (before insert, before update, before delete,
        after insert, after update, after delete) {
    String unknownAccountId = null;
    List<FS_Unknown_Account__mdt> matchingSetting = [SELECT FS_Account_Id__c FROM FS_Unknown_Account__mdt LIMIT 1];
    if (matchingSetting.size() > 0) {
        unknownAccountId = matchingSetting[0].FS_Account_Id__c;
    }

    if (Test.isRunningTest() || !String.isBlank(unknownAccountId)) {

        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                FS_AccountContactRelationTriggerService.beforeInsert(Trigger.new, unknownAccountId);
            } else if (Trigger.isUpdate) {
                FS_AccountContactRelationTriggerService.beforeUpdate(Trigger.new, Trigger.oldMap, unknownAccountId);
            }
        }

        if (Trigger.isAfter) {

            if (Trigger.isInsert) {
                FS_AccountContactRelationTriggerService.afterInsert(Trigger.new, unknownAccountId);
            } else if (Trigger.isUpdate) {
                FS_AccountContactRelationTriggerService.afterUpdate(Trigger.new, Trigger.oldMap, unknownAccountId);
            } else if (Trigger.isDelete) {
                FS_AccountContactRelationTriggerService.afterDelete(Trigger.old, unknownAccountId);
            }
        }
    }
}