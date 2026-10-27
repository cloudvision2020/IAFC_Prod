@isTest(SeeAllData=true)
private class HeaderMenuControllerTest {

    @isTest
    static void testGetHeaderMenus() {

        Test.startTest();
        List<HeaderMenuController.MenuDTO> result =
            HeaderMenuController.getHeaderMenus();
        Test.stopTest();

        System.assertNotEquals(null, result);

        for (HeaderMenuController.MenuDTO menu : result) {
            System.assertNotEquals(null, menu.label);
            System.assertNotEquals(null, menu.developerName);

            if (menu.items != null) {
                for (HeaderMenuController.MenuItemDTO item : menu.items) {
                    System.assertNotEquals(null, item.label);
                    System.assertNotEquals(null, item.url);
                }
            }
        }
    }
}