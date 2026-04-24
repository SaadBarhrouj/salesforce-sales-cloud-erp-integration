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
    
    // Response parsing constants (Mis à jour pour le JSON Standard)
    private static final String ROUTES_KEY = 'routes';
    private static final String SUMMARY_KEY = 'summary';
    private static final String DISTANCE_KEY = 'distance';
    private static final String DURATION_KEY = 'duration';
    
    // Conversion constants
    private static final Decimal METERS_TO_KM = 0.001;
    private static final Integer SECONDS_TO_MINUTES = 60;
    
    // ========== WRAPPER CLASS ==========
    /**
     * @description Wrapper class to return both data and log request to the Queueable
     */
    public class RouteResult {
        public Boolean isSuccess { get; set; }
        public Decimal distanceKm { get; set; }
        public Integer durationMinutes { get; set; }
        public IntegrationLoggerService.LogCalloutRequest logRequest { get; set; }
        
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
        
        try {
            // Step 1: Build the endpoint (Auth is handled silently by Named Credential)
            String endpoint = buildEndpoint();
            logReq.endpoint = endpoint.replace(NAMED_CREDENTIAL, 'https://api.openrouteservice.org');
            
            // Step 2: Create and configure HTTP request WITH BODY
            HttpRequest req = buildHttpRequest(endpoint, origin, destination);
            
            // Step 3: Log request payload for audit trail
            logReq.requestPayload = req.getBody();
            
            // Step 4: Execute the callout
            HttpResponse res = new Http().send(req);
            
            // Step 5: Log response metadata
            logReq.responseTimestamp = Datetime.now();
            logReq.statusCode = res.getStatusCode();
            logReq.responseBody = res.getBody();
            
            // Step 5: Parse response based on status
            if (res.getStatusCode() == 200) {
                result = parseSuccessResponse(res, result);
            } else {
                handleErrorResponse(res, logReq);
            }
            
        } catch (Exception e) {
            handleException(e, logReq);
        }
        
        // Attach log to result
        result.logRequest = logReq;
        return result;
    }

    // ========== PRIVATE HELPER METHODS ==========
    
    /**
     * @description Initialize logging request with metadata
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
     */
    private static String buildEndpoint() {
        return NAMED_CREDENTIAL + API_ENDPOINT;
    }
    
    /**
     * @description Create and configure HTTP request with JSON body
     * Named Credential automatically injects authentication headers
     */
    private static HttpRequest buildHttpRequest(String endpoint, Schema.Location origin, Schema.Location destination) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(HTTP_METHOD);
        req.setTimeout(HTTP_TIMEOUT_MS);
        req.setHeader('Content-Type', 'application/json; charset=utf-8');
        String body = '{"coordinates":[[' + origin.Longitude + ',' + origin.Latitude + '],[' + destination.Longitude + ',' + destination.Latitude + ']]}';        
        req.setBody(body);
        
        return req;
    }
    
    /**
     * @description Parse successful API response (HTTP 200) based on standard JSON format
     */
    private static RouteResult parseSuccessResponse(HttpResponse res, RouteResult result) {
        try {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            // 1. On cherche la liste "routes" (Standard JSON format)
            List<Object> routes = (List<Object>) jsonResponse.get(ROUTES_KEY);
            
            if (routes != null && !routes.isEmpty()) {
                
                // 2. On prend la première route du tableau
                Map<String, Object> firstRoute = (Map<String, Object>) routes[0];
                
                // 3. On rentre directement dans "summary"
                Map<String, Object> summary = (Map<String, Object>) firstRoute.get(SUMMARY_KEY);
                
                // 4. On récupère la distance (en mètres) et la durée (en secondes)
                Decimal distanceMeters = (Decimal) summary.get(DISTANCE_KEY);
                Decimal durationSeconds = (Decimal) summary.get(DURATION_KEY);
                
                // Convert to km and minutes
                result.distanceKm = (distanceMeters * METERS_TO_KM).setScale(2);
                result.durationMinutes = Integer.valueOf(durationSeconds / SECONDS_TO_MINUTES);
                result.isSuccess = true;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'JSON parsing error: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Handle API error responses (non-200 status codes)
     */
    private static void handleErrorResponse(HttpResponse res, IntegrationLoggerService.LogCalloutRequest logReq) {
        logReq.errorCode = 'API_ERROR';
        System.debug(LoggingLevel.WARN, 'OpenRouteService API Error - Status: ' 
            + res.getStatusCode() + ' Body: ' + res.getBody());
    }
    
    /**
     * @description Handle Apex exceptions (timeouts, parsing errors, etc.)
     */
    private static void handleException(Exception e, IntegrationLoggerService.LogCalloutRequest logReq) {
        logReq.responseTimestamp = Datetime.now();
        logReq.statusCode = 500;
        logReq.errorCode = 'APEX_EXCEPTION';
        logReq.responseBody = e.getMessage() + ' | ' + e.getStackTraceString();
        
        System.debug(LoggingLevel.ERROR, 'Exception during OpenRouteService Callout: ' + e.getMessage());
    }
}