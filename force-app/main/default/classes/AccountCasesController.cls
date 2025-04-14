public with sharing class AccountCasesController {
    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
    @AuraEnabled
    public static List<Case> findCasesBySubject(Id accountId, String subjectSearchTerm){
        if (accountId == null) {
            throw newMessageException('The account ID is required.');
        }

        List<Case> cases = [
            SELECT Id, Subject, Status, Priority
            FROM Case
            WHERE AccountId = :accountId
            AND Subject LIKE :('%' + subjectSearchTerm + '%')
            LIMIT 10
        ];

        return cases;
    }

}