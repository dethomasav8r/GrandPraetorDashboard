public without sharing class GrandPraetorBalanceHelper {

    public class BalanceResult {
        public Id accountId;
        public Decimal totalBalance;
        public Decimal due0to30;
        public Decimal due31to60;
        public Decimal due61to90;
        public Decimal due90Plus;
        public Integer maxAge;

        public BalanceResult(Id acctId) {
            this.accountId    = acctId;
            this.totalBalance = 0;
            this.due0to30     = 0;
            this.due31to60    = 0;
            this.due61to90    = 0;
            this.due90Plus    = 0;
            this.maxAge       = 0;
        }
    }

    public static List<BalanceResult> getBalances(Set<Id> chapterIds) {
        Map<Id, BalanceResult> resultMap = new Map<Id, BalanceResult>();
        try {
            List<OrderApi__Sales_Order__c> orders = [
                SELECT Id, OrderApi__Account__c,
                       OrderApi__Balance_Due__c, Posted_Age__c
                FROM OrderApi__Sales_Order__c
                WHERE OrderApi__Account__c IN :chapterIds
                  AND OrderApi__Balance_Due__c > 0
                  AND OrderApi__Is_Posted__c = true
                  AND OrderApi__Is_Voided__c = false
                  AND OrderApi__Entity__c = 'Account'
                LIMIT 10000
            ];
            for (OrderApi__Sales_Order__c so : orders) {
                Id acctId   = so.OrderApi__Account__c;
                Decimal bal = so.OrderApi__Balance_Due__c != null ? so.OrderApi__Balance_Due__c : 0;
                Integer age = so.Posted_Age__c != null ? Integer.valueOf(so.Posted_Age__c) : 0;

                if (!resultMap.containsKey(acctId)) {
                    resultMap.put(acctId, new BalanceResult(acctId));
                }
                BalanceResult br = resultMap.get(acctId);
                br.totalBalance += bal;
                if (age > br.maxAge) br.maxAge = age;

                if      (age <= 30) br.due0to30  += bal;
                else if (age <= 60) br.due31to60 += bal;
                else if (age <= 90) br.due61to90 += bal;
                else                br.due90Plus  += bal;
            }
        } catch(Exception e) {
            // return empty on error
        }
        return resultMap.values();
    }
}
