// Runs without sharing to access Sales Order records
// regardless of portal user visibility
public without sharing class GrandPraetorBalanceHelper {

    public class BalanceResult {
        public Id accountId;
        public Decimal totalBalance;
        public Integer maxAge;
        public BalanceResult(Id acctId, Decimal bal, Integer age) {
            this.accountId    = acctId;
            this.totalBalance = bal;
            this.maxAge       = age;
        }
    }

    public static List<BalanceResult> getBalances(Set<Id> chapterIds) {
        List<BalanceResult> results = new List<BalanceResult>();
        try {
            List<AggregateResult> aggResults = [
                SELECT OrderApi__Account__c acctId,
                       SUM(OrderApi__Balance_Due__c) totalBal,
                       MAX(Posted_Age__c) maxAge
                FROM OrderApi__Sales_Order__c
                WHERE OrderApi__Account__c IN :chapterIds
                  AND OrderApi__Balance_Due__c > 0
                  AND OrderApi__Is_Posted__c = true
                  AND OrderApi__Is_Voided__c = false
                GROUP BY OrderApi__Account__c
            ];
            for (AggregateResult ar : aggResults) {
                Id acctId   = (Id) ar.get('acctId');
                Decimal bal = ar.get('totalBal') != null ? (Decimal) ar.get('totalBal') : 0;
                Integer age = ar.get('maxAge')   != null ? Integer.valueOf((Decimal) ar.get('maxAge')) : 0;
                results.add(new BalanceResult(acctId, bal, age));
            }
        } catch(Exception e) {
            // return empty on error
        }
        return results;
    }
}
