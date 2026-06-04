/**
 * Service for logging integration callouts to Integration_Call_Log__c records.
 */
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
    /**
     * Wrapper holding the data required to log a single integration callout.
     */
    public class LogCalloutRequest {
        /**
         * Name of the external service being called.
         */
        public String  serviceName        { get; set; }
        /**
         * Endpoint URL of the callout.
         */
        public String  endpoint           { get; set; }
        /**
         * HTTP method used for the callout.
         */
        public String  method             { get; set; }
        /**
         * Raw request payload sent to the service.
         */
        public String  requestPayload     { get; set; }
        /**
         * Raw response body returned by the service.
         */
        public String  responseBody       { get; set; }
        /**
         * HTTP status code returned by the service.
         */
        public Integer statusCode         { get; set; }
        /**
         * Timestamp when the request was sent.
         */
        public Datetime requestTimestamp  { get; set; }
        /**
         * Timestamp when the response was received.
         */
        public Datetime responseTimestamp { get; set; }
        /**
         * Id of the Salesforce record related to this callout.
         */
        public Id      relatedRecordId    { get; set; }
        /**
         * Type of action performed by the callout.
         */
        public String  actionType         { get; set; }
        /**
         * Error code returned by the service, if any.
         */
        public String  errorCode          { get; set; }
        /**
         * Number of retry attempts for the callout.
         */
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
     * @param request The LogCalloutRequest to convert into a log record
     * @return The populated Integration_Call_Log__c record
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
     * @param statusCode The HTTP status code to resolve
     * @return The corresponding Status__c picklist value
     */
    private static String resolveStatus(Integer statusCode) {
        if (statusCode == null) {
            return 'Timeout';
        }
        if (statusCode >= 200 && statusCode < 300) {
            return 'Success';
        }
        if (statusCode == 408 || statusCode == 504) {
            return 'Timeout';
        }
        return 'Failed';
    }

    /**
     * @description Validates and normalizes action type against allowed values
     * @param actionType The raw action type to validate
     * @return The normalized action type, or 'Fetch' if invalid
     */
    private static String validateActionType(String actionType) {
        if (String.isBlank(actionType)) {
            return 'Fetch';
        }
        String normalized = actionType.toLowerCase();
        return VALID_ACTION_TYPES.containsKey(normalized) ? VALID_ACTION_TYPES.get(normalized) : 'Fetch';
    }

    /**
     * @description Truncates a string to the given max length
     * @param input The string to truncate
     * @param maxLength The maximum allowed length
     * @return The truncated string, or null if input is null
     */
    private static String truncateString(String input, Integer maxLength) {
        if (input == null) {
            return null;
        }
        if (input.length() <= maxLength) {
            return input;
        }
        System.debug(LoggingLevel.WARN, 'Truncating string from ' + input.length() + ' to ' + maxLength);
        return input.substring(0, maxLength);
    }
}