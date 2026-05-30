@isTest
private class GrandPraetorDashboardControllerTest {

    @isTest
    static void testGetDashboardDataNoContact() {
        // Running as internal user with no Contact — should return empty list
        List<GrandPraetorDashboardController.ChapterDashboardData> result =
            GrandPraetorDashboardController.getDashboardData();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for user with no contact');
    }

    @isTest
    static void testGetDashboardDataNoBadge() {
        // Create a contact with no GP badge — should return empty list
        Contact c = new Contact(LastName = 'TestGP', Email = 'testgp@example.com');
        insert c;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            LastName       = 'TestGP',
            Email          = 'testgp@example.com',
            Username       = 'testgp_nodashboard@example.com.sandbox',
            Alias          = 'tgp',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey   = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId      = p.Id,
            ContactId      = c.Id
        );

        System.runAs(u) {
            List<GrandPraetorDashboardController.ChapterDashboardData> result =
                GrandPraetorDashboardController.getDashboardData();
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(0, result.size(), 'Should return empty list — no GP badge');
        }
    }
}
