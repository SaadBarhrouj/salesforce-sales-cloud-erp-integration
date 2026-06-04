/**
 * @description Service class to handle OpenRouteService API Callouts
 * 🌟 Secured with Named/External Credentials and Standard JSON Parsing
 */
public inherited sharing class RouteCalculationService {
    
    // ========== CONSTANTES ==========
    private static final String NAMED_CREDENTIAL = 'callout:OpenRouteService_API';
    private static final String API_ENDPOINT = '/v2/directions/driving-car';
    private static final String SERVICE_NAME = 'OpenRouteService';
    private static final String HTTP_METHOD = 'POST';
    private static final Integer HTTP_TIMEOUT_MS = 10000;
    private static final Integer MAX_RETRIES = 3;

    // Response parsing constants (Mis à jour pour le JSON Standard)
    private static final String ROUTES_KEY = 'routes';
    private static final String SUMMARY_KEY = 'summary';
    private static final String DISTANCE_KEY = 'distance';
    private static final String DURATION_KEY = 'duration';
    
    // Conversion constants
    private static final Decimal METERS_TO_KM = 0.001;
    private static final Decimal SECONDS_TO_MINUTES = 60;

    // ========== WRAPPER CLASS ==========
    /**
     * @description Wrapper class to return both data and log request to the Queueable
     */
    public class RouteResult {
        /**
         * @description Indicates whether the route calculation succeeded.
         */
        public Boolean isSuccess { get; set; }
        /**
         * @description Driving distance between the two locations, in kilometers.
         */
        public Decimal distanceKm { get; set; }
        /**
         * @description Driving duration between the two locations, in minutes.
         */
        public Integer durationMinutes { get; set; }
        /**
         * @description Log request capturing the callout details.
         */
        public IntegrationLoggerService.LogCalloutRequest logRequest { get; set; }

        /**
         * @description Initializes a RouteResult with default values.
         */
        public RouteResult() {
            this.isSuccess = false;
        }
    }

    // ========== PUBLIC METHODS ==========
    /**
     * @description Calls OpenRouteService to get driving distance and duration between two locations
     * @param origin Origin location with coordinates
     * @param destination Destination location with coordinates
     * @param relatedRecordId Record ID for logging purposes
     * @return RouteResult containing distance, duration, success status, and logs
     */
    public static RouteResult callOpenRouteService(Schema.Location origin, Schema.Location destination, Id relatedRecordId) {
        RouteResult result = new RouteResult();
        IntegrationLoggerService.LogCalloutRequest logReq = initializeLogRequest(relatedRecordId);
        
        Integer attempt = 0;
        Boolean isCompleted = false;

        while (attempt < MAX_RETRIES && !isCompleted) {
            attempt++;
            try {
                // Step 1: Build the endpoint (Auth is handled silently by Named Credential)
                String endpoint = buildEndpoint();
                logReq.endpoint = endpoint.replace(NAMED_CREDENTIAL, 'https://api.openrouteservice.org');

                // Step 2: Create and configure HTTP request WITH BODY
                HttpRequest req = buildHttpRequest(endpoint, origin, destination);

                // Step 3: Log request payload for audit trail
                logReq.requestPayload = req.getBody();
                logReq.requestTimestamp = Datetime.now();

                // Step 4: Execute the callout
                HttpResponse res = new Http().send(req);

                // Step 5: Log response metadata
                logReq.responseTimestamp = Datetime.now();
                logReq.statusCode = res.getStatusCode();
                logReq.responseBody = res.getBody();
                logReq.retryCount = attempt - 1;

                // Step 6: Parse response based on status
                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    result = parseSuccessResponse(res, result);
                    isCompleted = true;
                } else {
                    logReq.errorCode = 'HTTP_ERROR_' + res.getStatusCode();
                    System.debug(LoggingLevel.WARN, 'OpenRouteService Attempt ' + attempt + ' failed with status ' + res.getStatusCode());
                }

            } catch (Exception e) {
                logReq.errorCode = (e instanceof CalloutException) ? 'CALLOUT_EXCEPTION' : 'APEX_EXCEPTION';
                logReq.responseBody = e.getMessage() + ' | Stack: ' + e.getStackTraceString();
                System.debug(LoggingLevel.ERROR, 'OpenRouteService Attempt ' + attempt + ' Exception: ' + e.getMessage());
            }
        }

        result.logRequest = logReq;
        return result;
    }

    // ========== PRIVATE HELPER METHODS ==========
    
    /**
     * @description Initialize logging request with metadata
     * @param relatedRecordId ID of the related record for logging
     * @return Initialized LogCalloutRequest object
     */
    private static IntegrationLoggerService.LogCalloutRequest initializeLogRequest(Id relatedRecordId) {
        IntegrationLoggerService.LogCalloutRequest logReq = new IntegrationLoggerService.LogCalloutRequest();
        logReq.serviceName = SERVICE_NAME;
        logReq.actionType = 'Calculate';
        logReq.relatedRecordId = relatedRecordId;
        logReq.requestTimestamp = Datetime.now();
        logReq.method = HTTP_METHOD;
        return logReq;
    }
    
    /**
     * @description Build the API endpoint URL (No coordinates in URL for POST)
     * Coordinates are sent in the request body as JSON
     * @return Full endpoint URL with named credential
     */
    private static String buildEndpoint() {
        return NAMED_CREDENTIAL + API_ENDPOINT;
    }
    
    /**
     * @description Create and configure HTTP request with JSON body
     * Named Credential automatically injects authentication headers
     * @param endpoint The API endpoint URL with named credential
     * @param origin Origin location with coordinates
     * @param destination Destination location with coordinates
     * @return Configured HttpRequest object with body
     */
    private static HttpRequest buildHttpRequest(String endpoint, Schema.Location origin, Schema.Location destination) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(HTTP_METHOD);
        req.setTimeout(HTTP_TIMEOUT_MS);
        req.setHeader('Content-Type', 'application/json; charset=utf-8');
        Map<String, Object> requestBody = new Map<String, Object>{
            'coordinates' => new List<List<Double>>{
                new List<Double>{origin.Longitude, origin.Latitude},
                new List<Double>{destination.Longitude, destination.Latitude}
            }
        };
        req.setBody(JSON.serialize(requestBody));

        return req;
    }
    
    /**
     * @description Parse successful API response (HTTP 200) based on standard JSON format
     * @param res The HTTP response from the API
     * @param result The RouteResult object to populate
     * @return Updated RouteResult with distance and duration values
     */
    private static RouteResult parseSuccessResponse(HttpResponse res, RouteResult result) {
        try {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            // 1. Search for the "routes" list (Standard JSON format)
            List<Object> routes = (List<Object>) jsonResponse.get(ROUTES_KEY);
            
            if (routes != null && !routes.isEmpty()) {
                
                // 2. Take the first route from the array
                Map<String, Object> firstRoute = (Map<String, Object>) routes[0];
                
                // 3. Go directly to "summary"
                Map<String, Object> summary = (Map<String, Object>) firstRoute.get(SUMMARY_KEY);
                
                // 4. Get the distance (in meters) and duration (in seconds)
                Decimal distanceMeters = (Decimal) summary.get(DISTANCE_KEY);
                Decimal durationSeconds = (Decimal) summary.get(DURATION_KEY);

                result.distanceKm = (distanceMeters * METERS_TO_KM).setScale(2);
                result.durationMinutes = (Integer)Math.round(durationSeconds / SECONDS_TO_MINUTES);
                result.isSuccess = true;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'JSON parsing error: ' + e.getMessage());
        }
        
        return result;
    }
}