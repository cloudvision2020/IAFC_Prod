@isTest
public class IAFC_Mock_MultiRequest implements HttpCalloutMock {
	Map<String, HttpCalloutMock> requests;

	public IAFC_Mock_MultiRequest(Map<String, HttpCalloutMock> requests) {
		this.requests = requests;
	}

	public HTTPResponse respond(HTTPRequest req) {
		HttpCalloutMock mock = requests.get(req.getEndpoint());
		if (mock != null) {
			return mock.respond(req);
		} else {
    			throw new CalloutException('HTTP callout not supported for test methods');
		}
	}

	public void addRequestMock(String url, HttpCalloutMock mock) {
		requests.put(url, mock);
	}
}