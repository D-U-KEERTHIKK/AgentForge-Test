public with sharing class EmployeeOffboardingWizardController {

    public class Request {
        @InvocableVariable(label='Employee User Id' required=true)
        public Id userId;

        @InvocableVariable(label='Offboarding Type' required=true)
        public String offboardingType;
    }

    @InvocableMethod(
        label='Process Employee Offboarding'
        description='Deactivates a User and updates Offboarding_Status__c via a future method to avoid MIXED_DML exceptions'
    )
    public static void processOffboarding(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return;
        Request req = requests[0];
        executeOffboarding(String.valueOf(req.userId), req.offboardingType);
    }

    @future
    public static void executeOffboarding(String userId, String offboardingType) {
        try {
            User u = [SELECT Id, IsActive, Offboarding_Status__c FROM User WHERE Id = :userId LIMIT 1];
            u.IsActive = false;
            u.Offboarding_Status__c = (offboardingType == 'Resignation')
                ? 'Resignation_In_Progress'
                : 'Termination_In_Progress';
            update u;
        } catch (QueryException e) {
            throw new AuraHandledException('User not found:' + e.getMessage());
        } catch (DmlException e) {
            throw new AuraHandledException('Offboarding update failed:' + e.getMessage());
        }
    }
}
