/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : FieldMappingService
 * Author          : <YourName>
 * Created Date    : Mar 12, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Mar 12, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Mar 12, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
public without sharing class FieldMappingService {
    public static Map<String, String> getMappings(String sourceObj, String targetObj) {
      Map<String, String> mappings = new Map<String, String>();

        for (Field_Mapping__mdt row : [
            SELECT Source_Field_API__c,
                   Source_Object__c,
                   Target_Field_API__c,
                   Target_Object__c,
                   Active__c
            FROM Field_Mapping__mdt
            WHERE Source_Object__c = :sourceObj
              AND Target_Object__c = :targetObj
              AND Active__c = true
        ]) {
            if (String.isNotBlank(row.Source_Field_API__c) &&
                String.isNotBlank(row.Target_Field_API__c)) {
                mappings.put(
                    row.Source_Field_API__c.trim(),
                    row.Target_Field_API__c.trim()
                );
            }
        }

        return mappings;
    }
}