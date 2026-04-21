public inherited sharing class IntegrationLoggerService {

    /**
     * ==================== CONSTANTS ====================
     */
    private static final Integer MAX_PAYLOAD_LENGTH = 131000;

    private static final Map<String, String> VALID_ACTION_TYPES = new Map<String, String>{
        'calculate' => 'Calculate',
        'fetch'     => 'Fetch',
        'sync'      => 'Sync'
    };

    /**
     * ==================== INNER CLASS ====================
     */
    public class LogCalloutRequest {
        public String  serviceName        { get; set; }
        public String  endpoint           { get; set; }
        public String  method             { get; set; }
        public String  requestPayload     { get; set; }
        public String  responseBody       { get; set; }
        public Integer statusCode         { get; set; }
        public Datetime requestTimestamp  { get; set; }
        public Datetime responseTimestamp { get; set; }
        public Id      relatedRecordId    { get; set; }
        public String  actionType         { get; set; }
        public String  errorCode          { get; set; }
        public Integer retryCount         { get; set; }
    }

    /**
     * ==================== PUBLIC METHODS ====================
     */

    /**
     * @description Logs a list of integration callouts in a single DML
     * @param requests List of LogCalloutRequest to log
     */
    public static void logCallouts(List<LogCalloutRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'No log requests to process');
            return;
        }

        List<Integration_Call_Log__c> logRecords = new List<Integration_Call_Log__c>();

        for (LogCalloutRequest request : requests) {
            if (request == null) {
                System.debug(LoggingLevel.WARN, 'Null LogCalloutRequest encountered, skipping');
                continue;
            }
            logRecords.add(buildLogRecord(request));
        }

        if (logRecords.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'No valid log records to insert');
            return;
        }

        try {
            insert as system logRecords;
            System.debug(LoggingLevel.INFO, 'Successfully inserted ' + logRecords.size() + ' Integration_Call_Log__c records');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to insert Integration_Call_Log__c records: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
        }
    }

    /**
     * ==================== PRIVATE METHODS ====================
     */

    /**
     * @description Builds a single Integration_Call_Log__c record from a LogCalloutRequest
     */
    private static Integration_Call_Log__c buildLogRecord(LogCalloutRequest request) {
        Integration_Call_Log__c logRecord = new Integration_Call_Log__c();

        // Service & Endpoint
        logRecord.Service_Name__c = request.serviceName;
        logRecord.Endpoint__c     = request.endpoint;
        logRecord.Method__c       = request.method;
        logRecord.Direction__c    = 'Outbound';

        // Request & Response
        logRecord.Request_Payload__c = truncateString(request.requestPayload, MAX_PAYLOAD_LENGTH);
        logRecord.Response_Body__c   = truncateString(request.responseBody,   MAX_PAYLOAD_LENGTH);

        // Timestamps
        logRecord.Request_Timestamp__c  = request.requestTimestamp;
        logRecord.Response_Timestamp__c = request.responseTimestamp;

        // Status & Error
        logRecord.Status_Code__c = request.statusCode != null ? String.valueOf(request.statusCode) : null;
        logRecord.Status__c      = resolveStatus(request.statusCode);
        logRecord.Error_Code__c  = request.errorCode;

        // Related Object
        if (request.relatedRecordId != null) {
            logRecord.Related_Record_Id__c = (String) request.relatedRecordId;
            try {
                logRecord.Related_Object__c = request.relatedRecordId.getSObjectType().getDescribe().getName();
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Unable to determine object type for ID: ' + request.relatedRecordId);
            }
        }

        // Action & Retry
        logRecord.Action_Type_c__c = validateActionType(request.actionType);
        logRecord.Retry_Count__c   = request.retryCount != null ? request.retryCount : 0;

        return logRecord;
    }

    /**
     * @description Resolves HTTP status code to Status__c picklist value
     */
    private static String resolveStatus(Integer statusCode) {
        if (statusCode == null)                        return 'Timeout';
        if (statusCode >= 200 && statusCode < 300)     return 'Success';
        if (statusCode == 408 || statusCode == 504)    return 'Timeout';
        return 'Failed';
    }

    /**
     * @description Validates and normalizes action type against allowed values
     */
    private static String validateActionType(String actionType) {
        if (String.isBlank(actionType)) return 'Fetch';
        String normalized = actionType.toLowerCase();
        return VALID_ACTION_TYPES.containsKey(normalized) ? VALID_ACTION_TYPES.get(normalized) : 'Fetch';
    }

    /**
     * @description Truncates a string to the given max length
     */
    private static String truncateString(String input, Integer maxLength) {
        if (input == null)                  return null;
        if (input.length() <= maxLength)    return input;
        System.debug(LoggingLevel.WARN, 'Truncating string from ' + input.length() + ' to ' + maxLength);
        return input.substring(0, maxLength);
    }
}