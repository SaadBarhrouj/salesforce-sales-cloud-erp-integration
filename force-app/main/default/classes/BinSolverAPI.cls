/**
 * @description Service class to handle technical communication with the BinSolver API.
 * This class uses structured DTOs (Data Transfer Objects) to match the OpenAPI 3.0.3 schema.
 * Supports automatic retries and integrates with IntegrationLoggerService for audit trails.
 */
public inherited sharing class BinSolverAPI {

    // ========== CONSTANTS ==========
    private static final String NAMED_CREDENTIAL = 'callout:BinSolver_API';
    private static final String DISPLAY_URL = 'https://api.binsolver.com';
    private static final String API_ENDPOINT = '/pack';
    private static final String SERVICE_NAME = 'BinSolver';
    private static final String HTTP_METHOD = 'POST';
    private static final Integer HTTP_TIMEOUT_MS = 60000; 
    private static final Integer MAX_RETRIES = 3;

    // ========== REQUEST WRAPPERS (DTOs) ==========
    
    /**
     * @description Root object for the /pack request.
     */
    public class PackingRequest {
        public String objective;      // Enum: fast, minBins, maxPlaced, minWaste, etc.
        public Boolean allowUnplaced; // Defaults to true.
        public List<BinRequest> bins;
        public List<ItemRequest> items;

        /**
         * @description Initializes a PackingRequest with default values.
         */
        public PackingRequest() {
            this.allowUnplaced = true;
            this.bins = new List<BinRequest>();
            this.items = new List<ItemRequest>();
        }
    }

    /**
     * @description Represents a container/truck template.
     */
    public class BinRequest {
        public String id;        // Identifier mapped to Truck_Code__c
        public Decimal w;         // Width (X)
        public Decimal h;         // Height (Y)
        public Decimal d;         // Depth (Z)
        public Decimal maxWeight; // Maximum weight capacity
        public Integer quantity;  // Available quantity of this bin type
    }

    /**
     * @description Represents an item to be packed.
     */
    public class ItemRequest {
        public String id;       // Item identifier (e.g., OLI ID)
        public Decimal w;        // Width (X)
        public Decimal h;        // Height (Y)
        public Decimal d;        // Depth (Z)
        public Decimal weight;   // Unit weight
        public Integer quantity; // Quantity of this item to pack
    }

    // ========== RESPONSE WRAPPERS ==========
    
    /**
     * @description Structured result returned to the business service.
     */
    public class PackingResult {
        /**
         * @description Indicates whether the packing API call succeeded.
         */
        public Boolean isSuccess { get; set; }
        /**
         * @description Raw JSON response body returned by the API for parsing.
         */
        public String responseBody { get; set; } // Raw JSON response for parsing
        /**
         * @description Log request capturing the callout details.
         */
        public IntegrationLoggerService.LogCalloutRequest logRequest { get; set; }

        /**
         * @description Initializes a PackingResult with default values.
         */
        public PackingResult() {
            this.isSuccess = false;
        }
    }

    // ========== PUBLIC METHODS ==========

    /**
     * @description Executes the Packing API call with retry logic.
     * @param request The structured PackingRequest object.
     * @param relatedRecordId Salesforce ID for log association.
     * @return PackingResult containing API data and prepared logs.
     */
    public static PackingResult callPackingApi(PackingRequest request, Id relatedRecordId) {
        PackingResult result = new PackingResult();
        IntegrationLoggerService.LogCalloutRequest logReq = initializeLogRequest(relatedRecordId);

        // Serialize request, suppressing nulls to comply with API strictness
        String requestBody = JSON.serialize(request, true);
        logReq.requestPayload = requestBody;

        Integer attempt = 0;
        Boolean isCompleted = false;

        while (attempt < MAX_RETRIES && !isCompleted) {
            attempt++;
            try {
                HttpRequest req = buildHttpRequest(requestBody);
                logReq.requestTimestamp = Datetime.now();

                HttpResponse res = new Http().send(req);

                logReq.responseTimestamp = Datetime.now();
                logReq.statusCode = res.getStatusCode();
                logReq.responseBody = res.getBody();
                logReq.retryCount = attempt - 1;

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    result.isSuccess = true;
                    result.responseBody = res.getBody();
                    isCompleted = true;
                } else {
                    logReq.errorCode = 'HTTP_ERROR_' + res.getStatusCode();
                }
            } catch (Exception e) {
                logReq.errorCode = (e instanceof CalloutException) ? 'CALLOUT_EXCEPTION' : 'APEX_EXCEPTION';
                logReq.responseBody = e.getMessage() + ' | ' + e.getStackTraceString();
            }
        }

        result.logRequest = logReq;
        return result;
    }

    // ========== PRIVATE HELPERS ==========

    private static IntegrationLoggerService.LogCalloutRequest initializeLogRequest(Id relatedRecordId) {
        IntegrationLoggerService.LogCalloutRequest logReq = new IntegrationLoggerService.LogCalloutRequest();
        logReq.serviceName = SERVICE_NAME;
        logReq.actionType = 'calculate';
        logReq.relatedRecordId = relatedRecordId;
        logReq.method = HTTP_METHOD;
        logReq.endpoint = DISPLAY_URL + API_ENDPOINT;
        return logReq;
    }

    private static HttpRequest buildHttpRequest(String requestBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + API_ENDPOINT);
        req.setMethod(HTTP_METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(HTTP_TIMEOUT_MS);
        req.setBody(requestBody);
        return req;
    }
}