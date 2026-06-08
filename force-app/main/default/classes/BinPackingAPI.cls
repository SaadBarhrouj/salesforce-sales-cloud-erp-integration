/**
 * @description Technical client for the 3DBinPacking.com packIntoMany API.
 * Vendor-neutral name; speaks the provider's JSON schema and injects credentials
 * via Named Credential body merge fields. Supports retries and audit logging.
 */
public inherited sharing class BinPackingAPI {

    // ========== CONSTANTS ==========
    private static final String NAMED_CREDENTIAL = 'callout:BinPacking3D_API';
    private static final String DISPLAY_URL      = 'https://global-api.3dbinpacking.com';
    private static final String API_ENDPOINT     = '/packer/packIntoMany';
    private static final String SERVICE_NAME     = 'BinPacking';
    private static final String HTTP_METHOD      = 'POST';
    private static final Integer HTTP_TIMEOUT_MS = 60000;
    private static final Integer MAX_RETRIES     = 3;

    // Resolved by the platform at callout time (Named Credential allowMergeFieldsInBody=true).
    // The literal placeholders — never the secrets — are what gets serialized and logged.
    private static final String USERNAME_MERGE = '{!$Credential.BinPacking3D_Auth.Username}';
    private static final String APIKEY_MERGE   = '{!$Credential.BinPacking3D_Auth.APIKey}';

    // ========== REQUEST DTOs ==========
    public class PackingRequest {
        public String username;
        public String api_key;
        public List<BinRequest> bins;
        public List<ItemRequest> items;
        public Params params;

        public PackingRequest() {
            this.username = USERNAME_MERGE;
            this.api_key  = APIKEY_MERGE;
            this.bins     = new List<BinRequest>();
            this.items    = new List<ItemRequest>();
            this.params   = new Params();
        }
    }

    public class Params {
        public String optimization_mode; // 'bins_number' | 'bins_utilization'
        public Integer images_complete;
        public String images_format;

        public Params() {
            this.images_complete = 1;
            this.images_format   = 'svg';
        }
    }

    public class BinRequest {
        public String id;       // Truck_Code__c
        public Decimal w;
        public Decimal h;
        public Decimal d;
        public Decimal max_wg;  // Maximum weight capacity
        public Integer q;       // Available quantity of this bin type
    }

    public class ItemRequest {
        public String id;
        public Decimal w;
        public Decimal h;
        public Decimal d;
        public Decimal wg;      // Unit weight
        public Integer q;       // Quantity
        public Integer vr;      // Vertical rotation allowed (1 = yes)
    }

    // ========== RESPONSE WRAPPER ==========
    public class PackingResult {
        public Boolean isSuccess { get; set; }
        public String responseBody { get; set; }
        public IntegrationLoggerService.LogCalloutRequest logRequest { get; set; }
        public PackingResult() { this.isSuccess = false; }
    }

    // ========== PUBLIC METHODS ==========
    public static PackingResult callPackingApi(PackingRequest request, Id relatedRecordId) {
        PackingResult result = new PackingResult();
        IntegrationLoggerService.LogCalloutRequest logReq = initializeLogRequest(relatedRecordId);

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
