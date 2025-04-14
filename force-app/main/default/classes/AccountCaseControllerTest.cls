/**
@author AlexandreKuzo
 */
@isTest
private class AccountCaseControllerTest {

    @TestSetup
    static void setup() {
        Account testAccount = TestDataFactory.createTestAccount();
        List<Case> testCases = new List<Case>{
            new Case(AccountId = testAccount.Id, Subject = 'Test 1', Status = 'New', Priority = 'Medium'),
            new Case(AccountId = testAccount.Id, Subject = 'Test 2', Status = 'New', Priority = 'High')
        };
        insert testCases;
    }

    @IsTest
    static void testFindCasesBySubject() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String searchTerm = 'Test';
        Test.startTest();
        List<Case> results = AccountCasesController.findCasesBySubject(testAccount.Id, searchTerm);
        Test.stopTest();
        Assert.areEqual(2, results.size(), 'Should return one or more case.');
    }

    @IsTest
    static void testFindCasesBySubjectWithNoAccountId() {
        try {
            AccountCasesController.findCasesBySubject(null, 'Test');
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            String expectedErrorMessage = 'The account ID is required.';
            System.assertEquals(expectedErrorMessage, e.getMessage(), 'Incorrect error message was thrown.');
        }
    }
}