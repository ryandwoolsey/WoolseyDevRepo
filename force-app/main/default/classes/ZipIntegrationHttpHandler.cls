/**
 * The ZipIntegrationHttpHandler class is responsible for handling HTTP requests to an external ZIP code service.
 * After handling the response, it will update the Location_Identifier__c records contained in the trigger or LWC invocation.
 */
public class ZipIntegrationHttpHandler implements Queueable, Database.AllowsCallouts {
    public Map<String, String> recZipMap;

    /**
     * Constructor for queuable class. Instantiated and invoked from Trigger Handler..
     * @param idMapVar A map containing Location_Identifier__c record IDs as keys and ZIP codes as values.
     */

    public ZipIntegrationHttpHandler(Map<String, String> idMapVar) {
        this.recZipMap = idMapVar;
    }

    /**
     * The Execute method processes the ZIP codes and updates records based on the response from the ZIP code service.
     * @param context The QueueableContext for the current execution.
     */

    public void execute(QueueableContext context) {
        String paramString;
        Map<String, String> recZipMapToProcess = recZipMap;
        Map<Boolean, String> jsonResponse;
        for (String zip : recZipMapToProcess.values()) {
            if (String.isBlank(paramString)) {
                paramString = zip;
            } else {
                paramString += ',' + zip;
            }
        }
        if (!String.isBlank(paramString)) {
            jsonResponse = processPayload(paramString);
        }

        system.debug(jsonResponse);
        for (boolean b : jsonResponse.keySet()) {
            if (b) {
                try {
                    update ZipIntegrationJsonUntypedHandler.handleJsonString(
                        jsonResponse.get(true),
                        recZipMap
                    );
                } catch (exception e) {
                    System.debug(e.getMessage() + 'An error has occurred');
                }
            } else {
                System.debug(
                    'Data retrieval failed: ' + jsonResponse.get(false)
                );
            }
        }
    }

    /**
     * Builds and sends HTTP request and handles response from ZipCodeStack.com, a free Zip Code database accessible through REST API.
     * @param zipCodes A comma-separated string of ZIP codes to query.
     * @return A map with a Boolean indicating success (true) or failure (false), and a String containing the JSON response.
     */
    public static Map<Boolean, String> processPayload(String zipCodes) {
        Map<Boolean, String> verification = new Map<Boolean, String>();
        String endpoint =
            'https://api.zipcodestack.com/v1/search?codes=' + zipCodes;
        HttpRequest req = new HttpRequest();
        String apikey = (string) ZipCodeAPIKey__mdt.getInstance('apikey')
            .apikey__c;
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('apikey', apikey);
        req.setTimeout(2000);
        Http http = new Http();
        system.debug('endpoint : ' + endpoint);
        HTTPResponse response = http.send(req);
        system.debug('Status code: ' + response.getStatusCode());
        if (response.getStatusCode() == 200) {
            system.debug(response.getBody());
            verification.put(true, response.getBody());
            return verification;
        } else {
            String exceptionThrown =
                response.getStatus() +
                ', Status Code : ' +
                response.getStatusCode();
            verification.put(false, exceptionThrown);
            return verification;
        }
    }
}
