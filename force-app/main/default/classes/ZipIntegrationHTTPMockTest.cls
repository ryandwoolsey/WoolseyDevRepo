/**
 * The ZipIntegrationHTTPMockTest class is a test class used for mocking HTTP callouts.
 * It implements the HttpCalloutMock interface to simulate HTTP responses for testing.\
 * Allows for each Test Method to build independent responses to be added to interface for testing needs.
 */
@isTest
global class ZipIntegrationHTTPMockTest implements HttpCalloutMock {

    HttpResponse[] responses = new HttpResponse[0];

    public void addResponse (HttpResponse res){
        responses.add(res);
    }

    public HttpResponse respond(httpRequest req) {
        return responses.remove(0);
    }
}