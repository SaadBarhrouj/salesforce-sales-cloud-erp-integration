@isTest
private class BinPackingAPITest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"response":{"bins_packed":[{"bin_data":{"id":"TRUCK_A","used_weight":1200}}]}}');
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public Integer calls = 0;
        public HttpResponse respond(HttpRequest req) {
            calls++;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('server error');
            return res;
        }
    }

    private class RetryThenSucceedMock implements HttpCalloutMock {
        public Integer calls = 0;
        public HttpResponse respond(HttpRequest req) {
            calls++;
            HttpResponse res = new HttpResponse();
            if (calls == 1) { throw new CalloutException('transient'); }
            res.setStatusCode(200);
            res.setBody('{"response":{"bins_packed":[{"bin_data":{"id":"TRUCK_A"}}]}}');
            return res;
        }
    }

    private static BinPackingAPI.PackingRequest sampleRequest() {
        BinPackingAPI.PackingRequest r = new BinPackingAPI.PackingRequest();
        r.params.optimization_mode = 'bins_number';
        BinPackingAPI.BinRequest b = new BinPackingAPI.BinRequest();
        b.id = 'TRUCK_A'; b.w = 240; b.h = 240; b.d = 1360; b.max_wg = 24000; b.q = 5;
        r.bins.add(b);
        BinPackingAPI.ItemRequest it = new BinPackingAPI.ItemRequest();
        it.id = 'ITEM1'; it.w = 120; it.h = 80; it.d = 100; it.wg = 50; it.q = 3; it.vr = 1;
        r.items.add(it);
        return r;
    }

    @isTest
    static void callPackingApi_success_returnsBodyAndLogsPlaceholderNotSecret() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        BinPackingAPI.PackingResult result = BinPackingAPI.callPackingApi(sampleRequest(), null);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'A 2xx response should be a success');
        Assert.isTrue(result.responseBody.contains('bins_packed'), 'Response body should be captured');
        Assert.areEqual('BinPacking', result.logRequest.serviceName, 'Service name should be vendor-neutral');
        Assert.isTrue(result.logRequest.requestPayload.contains('{!$Credential.BinPacking3D_Auth.APIKey}'),
            'Logged payload must contain the merge placeholder, never a resolved key');
    }

    @isTest
    static void callPackingApi_httpError_retriesAndFails() {
        ErrorMock mock = new ErrorMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        BinPackingAPI.PackingResult result = BinPackingAPI.callPackingApi(sampleRequest(), null);
        Test.stopTest();

        Assert.isFalse(result.isSuccess, 'A 500 should not be a success');
        Assert.areEqual(3, mock.calls, 'Should retry up to MAX_RETRIES times');
        Assert.areEqual('HTTP_ERROR_500', result.logRequest.errorCode, 'Error code should reflect the HTTP status');
    }

    @isTest
    static void callPackingApi_transientException_thenSucceeds() {
        Test.setMock(HttpCalloutMock.class, new RetryThenSucceedMock());
        Test.startTest();
        BinPackingAPI.PackingResult result = BinPackingAPI.callPackingApi(sampleRequest(), null);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Should succeed on the retry after a transient CalloutException');
    }
}
