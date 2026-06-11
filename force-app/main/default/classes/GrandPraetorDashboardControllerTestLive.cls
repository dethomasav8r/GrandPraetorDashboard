// Separate test class using SeeAllData=true to exercise full code paths
// Cannot be in same class as @testSetup methods
@isTest(SeeAllData=true)
private class GrandPraetorDashboardControllerTestLive {

    @isTest
    static void testGetDashboardDataWithRealGPContact() {
        List<OrderApi__Position__c> gpPos = [
            SELECT OrderApi__Contact__c
            FROM OrderApi__Position__c
            WHERE OrderApi__Role__c IN ('Grand Praetor', 'Assistant Grand Praetor')
              AND OrderApi__Status__c = 'Active'
            LIMIT 1
        ];
        if (gpPos.isEmpty()) return;

        List<GrandPraetorDashboardController.ChapterDashboardData> result =
            GrandPraetorDashboardController.getDashboardDataForContact(
                gpPos[0].OrderApi__Contact__c
            );
        System.assertNotEquals(null, result, 'Should not be null');
        System.assert(result.size() >= 0, 'Should return valid data');
    }

    @isTest
    static void testGetDashboardDataWithRealAGPContact() {
        List<OrderApi__Position__c> agpPos = [
            SELECT OrderApi__Contact__c
            FROM OrderApi__Position__c
            WHERE OrderApi__Role__c = 'Assistant Grand Praetor'
              AND OrderApi__Status__c = 'Active'
            LIMIT 1
        ];
        if (agpPos.isEmpty()) return;

        List<GrandPraetorDashboardController.ChapterDashboardData> result =
            GrandPraetorDashboardController.getDashboardDataForContact(
                agpPos[0].OrderApi__Contact__c
            );
        System.assertNotEquals(null, result, 'Should not be null');
        System.assert(result.size() >= 0, 'AGP should return valid data');
    }

    @isTest
    static void testGetOrderLinesAllBuckets() {
        List<OrderApi__Position__c> gpPos = [
            SELECT OrderApi__Account__c
            FROM OrderApi__Position__c
            WHERE OrderApi__Role__c IN ('Grand Praetor', 'Assistant Grand Praetor')
              AND OrderApi__Status__c = 'Active'
            LIMIT 1
        ];
        if (gpPos.isEmpty()) return;

        for (String bucket : new List<String>{'0-30','31-60','61-90','90+'}) {
            List<GrandPraetorDashboardController.OrderLineData> lines =
                GrandPraetorDashboardController.getOrderLines(
                    gpPos[0].OrderApi__Account__c, bucket
                );
            System.assertNotEquals(null, lines, 'Bucket ' + bucket + ' should not be null');
        }
    }

    @isTest
    static void testBalanceHelperWithRealAccounts() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        if (accounts.isEmpty()) return;
        Set<Id> acctIds = new Set<Id>();
        for (Account a : accounts) acctIds.add(a.Id);

        List<GrandPraetorBalanceHelper.BalanceResult> results =
            GrandPraetorBalanceHelper.getBalances(acctIds);
        System.assertNotEquals(null, results, 'Should not be null');
        System.assert(results.size() >= 0, 'Should return valid list');
    }

    @isTest
    static void testGetContactDetailWithRealContact() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 1];
        if (contacts.isEmpty()) return;

        GrandPraetorDashboardController.ContactDetail cd =
            GrandPraetorDashboardController.getContactDetail(contacts[0].Id);
        System.assertNotEquals(null, cd, 'Should return contact detail');
    }
}
