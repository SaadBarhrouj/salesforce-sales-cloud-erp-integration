public inherited sharing class BinSolverAPI {
    
    private static final String ENDPOINT = 'callout:BinSolver_API/pack';
    private static final String SERVICE_NAME = 'BinSolver';
    private static final String METHOD = 'POST';
    private static final String ACTION_TYPE = 'Calculate';
    private static final Integer REQUEST_TIMEOUT_MS = 120000; // 2 minutes
    private static final Integer MAX_RETRIES = 3;

    /**
     * @description Calls BinSolver API with packing request and automatic retry logic
     */
    public static String packItems(
        String objective,
        List<Map<String, Object>> items,
        List<Map<String, Object>> bins,
        Id relatedRecordId
    ) {
        if (String.isBlank(objective) || items == null || items.isEmpty() || bins == null || bins.isEmpty()) {
            throw new IllegalArgumentException('objective, items, and bins are required and cannot be empty');
        }

        Map<String, Object> payload = new Map<String, Object>{
            'allowUnplaced' => true,
            'objective' => objective,
            'items' => items,
            'bins' => bins
        };

        String requestBody = JSON.serialize(payload, true);
        Integer retryCount = 0;
        String responseBody = null;
        Integer statusCode = null;
        String errorCode = null;
        Datetime requestTimestamp = System.now();
        Datetime responseTimestamp;
        
        List<IntegrationLoggerService.LogCalloutRequest> logRequests = new List<IntegrationLoggerService.LogCalloutRequest>();

        try {
            for (Integer attempt = 1; attempt <= MAX_RETRIES; attempt++) {
                try {
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(ENDPOINT);
                    req.setMethod(METHOD);
                    req.setHeader('Content-Type', 'application/json');
                    req.setTimeout(REQUEST_TIMEOUT_MS);
                    req.setBody(requestBody);

                    Http http = new Http();
                    HttpResponse res = http.send(req);
                    responseTimestamp = System.now();
                    statusCode = res.getStatusCode();
                    responseBody = res.getBody();

                    if (statusCode >= 200 && statusCode < 300) {
                        logRequests.add(buildLogRequest(requestBody, responseBody, statusCode, requestTimestamp, responseTimestamp, relatedRecordId, null, retryCount));
                        IntegrationLoggerService.logCallouts(logRequests);
                        return responseBody;
                    } else {
                        errorCode = 'HTTP_ERROR_' + statusCode;
                        if (attempt < MAX_RETRIES) {
                            retryCount++;
                            continue;
                        }
                    }
                } catch (Exception e) {
                    errorCode = (e instanceof CalloutException) ? 'CALLOUT_EXCEPTION' : 'SYSTEM_EXCEPTION';
                    responseBody = e.getMessage();
                    
                    if (attempt < MAX_RETRIES) {
                        retryCount++;
                        continue;
                    }
                }
            }

            responseTimestamp = System.now();
            logRequests.add(buildLogRequest(requestBody, responseBody, statusCode, requestTimestamp, responseTimestamp, relatedRecordId, errorCode, retryCount));
            IntegrationLoggerService.logCallouts(logRequests);
            throw new CalloutException('BinSolver API failed after ' + MAX_RETRIES + ' attempts: ' + responseBody);
        } catch (Exception e) {
            if (!(e instanceof CalloutException)) {
                logRequests.add(buildLogRequest(requestBody, e.getMessage(), null, requestTimestamp, System.now(), relatedRecordId, 'SYSTEM_ERROR', retryCount));
                try {
                    IntegrationLoggerService.logCallouts(logRequests);
                } catch (Exception logError) {
                    System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + logError.getMessage());
                }
            }
            throw e;
        }
    }

    /**
     * @description Builds a LogCalloutRequest object
     */
    private static IntegrationLoggerService.LogCalloutRequest buildLogRequest(
        String requestPayload,
        String responseBody,
        Integer statusCode,
        Datetime requestTimestamp,
        Datetime responseTimestamp,
        Id relatedRecordId,
        String errorCode,
        Integer retryCount
    ) {
        IntegrationLoggerService.LogCalloutRequest logRequest = new IntegrationLoggerService.LogCalloutRequest();
        logRequest.serviceName = SERVICE_NAME;
        logRequest.endpoint = ENDPOINT;
        logRequest.method = METHOD;
        logRequest.requestPayload = requestPayload;
        logRequest.responseBody = responseBody;
        logRequest.statusCode = statusCode;
        logRequest.requestTimestamp = requestTimestamp;
        logRequest.responseTimestamp = responseTimestamp;
        logRequest.relatedRecordId = relatedRecordId;
        logRequest.actionType = ACTION_TYPE;
        logRequest.errorCode = errorCode;
        logRequest.retryCount = retryCount;
        return logRequest;
    }
}