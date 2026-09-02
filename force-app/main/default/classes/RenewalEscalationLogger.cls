/**
 * RenewalEscalationLogger
 * 
 * Invocable Apex class that creates Renewal_Escalation_Log__c records from escalation requests.
 * Accepts a list of escalation request objects and persists them as custom object records.
 * Designed to be called from scheduled Flows for renewal escalation workflows.
 */
public class RenewalEscalationLogger {

    /**
     * EscalationRequest
     * 
     * Inner class to represent an escalation request with required fields.
     * Used as the input parameter type for the invocable method.
     */
    public class EscalationRequest {
        @InvocableVariable(required=true, label='Opportunity ID')
        public String opportunityId;

        @InvocableVariable(required=true, label='Escalated To User ID')
        public String escalatedToUserId;

        @InvocableVariable(required=true, label='Escalation Date')
        public Date escalationDate;

        @InvocableVariable(required=false, label='Notes')
        public String notes;
    }

    /**
     * createEscalationLogs
     * 
     * Invocable method that processes a list of escalation requests and creates
     * Renewal_Escalation_Log__c records. Handles bulk inserts with partial success
     * enabled to capture all valid records even if some fail validation.
     * 
     * @param requests List of EscalationRequest objects containing escalation details
     */
    @InvocableMethod(label='Create Renewal Escalation Logs' description='Creates Renewal_Escalation_Log__c records from escalation requests')
    public static void createEscalationLogs(List<EscalationRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        List<Renewal_Escalation_Log__c> logsToCreate = new List<Renewal_Escalation_Log__c>();

        // Convert EscalationRequest objects to Renewal_Escalation_Log__c records
        for (EscalationRequest request : requests) {
            if (String.isBlank(request.opportunityId) || 
                String.isBlank(request.escalatedToUserId) || 
                request.escalationDate == null) {
                continue; // Skip invalid requests
            }

            Renewal_Escalation_Log__c log = new Renewal_Escalation_Log__c(
                Renewal_Escalation_Log_Opportunity__c = request.opportunityId,
                Renewal_Escalation_Log_EscalatedTo__c = request.escalatedToUserId,
                Renewal_Escalation_Log_EscalationDate__c = request.escalationDate,
                Renewal_Escalation_Log_Notes__c = request.notes
            );
            logsToCreate.add(log);
        }

        // Insert with partial success enabled to handle bulk operations safely
        if (!logsToCreate.isEmpty()) {
            Database.insert(logsToCreate, false, AccessLevel.USER_MODE);
        }
    }
}