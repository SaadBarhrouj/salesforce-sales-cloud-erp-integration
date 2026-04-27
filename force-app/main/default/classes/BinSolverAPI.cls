/**
 * @description Service class to handle BinSolver API Callouts (3D Bin Packing)
 */
public inherited sharing class BinSolverAPI {

    // ========== CONSTANTES ==========
    private static final String NAMED_CREDENTIAL = 'callout:BinSolver_API';
    private static final String DISPLAY_URL = 'https://api.binsolver.com';
    private static final String API_ENDPOINT = '/pack';
    private static final String SERVICE_NAME = 'BinSolver';
    private static final String HTTP_METHOD = 'POST';
    private static final Integer HTTP_TIMEOUT_MS = 60000;
    private static final Integer MAX_RETRIES = 3;

    // ========== REQUEST WRAPPERS ==========
    /**
     * @description Racine de la requête de packing
     */
    public class PackingRequest {
        public String objective;
        public Boolean allowUnplaced;
        public List<BinRequest> bins;
        public List<ItemRequest> items;

        public PackingRequest() {
            this.allowUnplaced = true;
            this.bins = new List<BinRequest>();
            this.items = new List<ItemRequest>();
        }
    }

    /**
     * @description Structure d'un contenant (Bin/Box)
     */
    public class BinRequest {
        public String id;
        public Decimal w;
        public Decimal h;
        public Decimal d;
        public Decimal maxWeight;
        public Integer quantity;

        public BinRequest() {
            this.quantity = 1;
        }
    }

    /**
     * @description Structure d'un objet à emballer (Item)
     */
    public class ItemRequest {
        public String id;
        public Decimal w;
        public Decimal h;
        public Decimal d;
        public Decimal wg;
        public Integer vr;
    }

    // ========== RESPONSE WRAPPER ==========
    /**
     * @description Objet retourné au Queueable/Caller
     */
    public class PackingResult {
        public Boolean isSuccess { get; set; }
        public String responseBody { get; set; }
        public IntegrationLoggerService.LogCalloutRequest logRequest { get; set; }

        public PackingResult() {
            this.isSuccess = false;
        }
    }

    // ========== PUBLIC METHOD ==========
    /**
     * @description Executes the API call with retry management and log preparation
     * @param request Structured PackingRequest object
     * @param relatedRecordId ID of the related record (for logging)
     * @return PackingResult containing success, body and log
     */
    public static PackingResult callPackingApi(PackingRequest request, Id relatedRecordId) {
        PackingResult result = new PackingResult();
        IntegrationLoggerService.LogCalloutRequest logReq = initializeLogRequest(relatedRecordId);

        // Clean serialization
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
                    System.debug(LoggingLevel.WARN, 'BinSolver Attempt ' + attempt + ' failed with status ' + res.getStatusCode());
                }
            } catch (Exception e) {
                logReq.errorCode = (e instanceof CalloutException) ? 'CALLOUT_EXCEPTION' : 'APEX_EXCEPTION';
                logReq.responseBody = e.getMessage() + ' | Stack: ' + e.getStackTraceString();
                System.debug(LoggingLevel.ERROR, 'BinSolver Attempt ' + attempt + ' Exception: ' + e.getMessage());
            }
        }

        result.logRequest = logReq;
        return result;
    }

    // ========== PRIVATE HELPER METHODS ==========

    /**
     * @description Initializes the log with basic metadata
     * @param relatedRecordId ID of the related record
     * @return Initialized LogCalloutRequest object
     */
    private static IntegrationLoggerService.LogCalloutRequest initializeLogRequest(Id relatedRecordId) {
        IntegrationLoggerService.LogCalloutRequest logReq = new IntegrationLoggerService.LogCalloutRequest();
        logReq.serviceName = SERVICE_NAME;
        logReq.actionType = 'Calculate';
        logReq.relatedRecordId = relatedRecordId;
        logReq.method = HTTP_METHOD;
        logReq.endpoint = DISPLAY_URL + API_ENDPOINT;
        return logReq;
    }

    /**
     * @description Builds the HttpRequest object
     * @param requestBody The JSON request body as string
     * @return Configured HttpRequest object
     */
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