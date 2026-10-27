/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : HeaderMenuController
 * Author          : <YourName>
 * Created Date    : Feb 20, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Feb 20, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 20, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public without sharing class HeaderMenuController {

    public class MenuItemDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String url;
        public MenuItemDTO(String l, String u){ label = l; url = u; }
    }

    public class MenuDTO {
        @AuraEnabled public String developerName;
        @AuraEnabled public String label;
        @AuraEnabled public String url;
        @AuraEnabled public List<MenuItemDTO> items = new List<MenuItemDTO>();
    }

    @AuraEnabled(cacheable=true)
    public static List<MenuDTO> getHeaderMenus() {

        // 1) Parent menus
        List<Header_menu__mdt> menus = [
            SELECT DeveloperName, MasterLabel, URL__c
            FROM Header_menu__mdt
            ORDER BY MasterLabel
        ];

        Map<String, MenuDTO> byDevName = new Map<String, MenuDTO>();
        for (Header_menu__mdt m : menus) {
            MenuDTO dto = new MenuDTO();
            dto.developerName = m.DeveloperName;
            dto.label = m.MasterLabel;
            dto.url = m.URL__c;
            byDevName.put(m.DeveloperName, dto);
        }

        // 2) Child items (link to parent via Header_menu__c relationship field)
        List<Header_menu_items__mdt> items = [
            SELECT MasterLabel, URL__c, Header_menu__r.DeveloperName
            FROM Header_menu_items__mdt
            WHERE Header_menu__c != null
            ORDER BY MasterLabel
        ];

        for (Header_menu_items__mdt it : items) {
            String parentDevName = it.Header_menu__r != null ? it.Header_menu__r.DeveloperName : null;
            if (String.isBlank(parentDevName) || !byDevName.containsKey(parentDevName)) continue;

            byDevName.get(parentDevName).items.add(
                new MenuItemDTO(it.MasterLabel, it.URL__c)
            );
        }

        return new List<MenuDTO>(byDevName.values());
    }
}