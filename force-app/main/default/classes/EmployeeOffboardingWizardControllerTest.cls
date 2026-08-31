@IsTest
private class EmployeeOffboardingWizardControllerTest {

    @TestSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Employee',
            Email = 'test.employee@example.com',
            Username = 'test.employee' + System.currentTimeMillis() + '@example.com',
            Alias = 'tstemp',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert testUser;
    }

    @IsTest
    static void testResignationOffboarding() {
        User u = [SELECT Id FROM User WHERE LastName = 'Employee' LIMIT 1];

        EmployeeOffboardingWizardController.Request req = new EmployeeOffboardingWizardController.Request();
        req.userId = u.Id;
        req.offboardingType = 'Resignation';


        EmployeeOffboardingWizardController.processOffboarding(
            new List<EmployeeOffboardingWizardController.Request>{ req }
        );


        User updated = [SELECT IsActive, Offboarding_Status__c FROM User WHERE Id = :u.Id];
        Assert.areEqual(false, updated.IsActive, 'User should be deactivated');
        Assert.areEqual('Resignation_In_Progress', updated.Offboarding_Status__c, 'Status should be Resignation_In_Progress');
    }

    @IsTest
    static void testTerminationOffboarding() {
        User u = [SELECT Id FROM User WHERE LastName = 'Employee' LIMIT 1];

        EmployeeOffboardingWizardController.Request req = new EmployeeOffboardingWizardController.Request();
        req.userId = u.Id;
        req.offboardingType = 'Termination';


        EmployeeOffboardingWizardController.processOffboarding(
            new List<EmployeeOffboardingWizardController.Request>{ req }
        );


        User updated = [SELECT IsActive, Offboarding_Status__c FROM User WHERE Id = :u.Id];
        Assert.areEqual(false, updated.IsActive, 'User should be deactivated');
        Assert.areEqual('Termination_In_Progress', updated.Offboarding_Status__c, 'Status should be Termination_In_Progress');
    }

    @IsTest
    static void testEmptyRequestList() {

        EmployeeOffboardingWizardController.processOffboarding(
            new List<EmployeeOffboardingWizardController.Request>()
        );

        Assert.isTrue(true, 'Empty request list should not throw an exception');
    }

    @IsTest
    static void testNullRequestList() {

        EmployeeOffboardingWizardController.processOffboarding(null);

        Assert.isTrue(true, 'Null request list should not throw an exception');
    }
}
