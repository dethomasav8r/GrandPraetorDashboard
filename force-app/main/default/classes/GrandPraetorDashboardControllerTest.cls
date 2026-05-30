@isTest
private class GrandPraetorDashboardControllerTest {
    @isTest
    static void testGetDashboardDataNoContact() {
        // Running as system user with no contact — should return empty list
        List<GrandPraetorDashboardController.ChapterDashboardData> result =
            GrandPraetorDashboardController.getDashboardData();
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}
