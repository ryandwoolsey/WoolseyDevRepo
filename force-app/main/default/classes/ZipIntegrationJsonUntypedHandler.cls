/**
 * The ZipIntegrationJsonUntypedHandler class is responsible for handling JSON data retrieved from an external service
 * and mapping it to Location_Identifier__c records. It leverages the deserializeUntyped method to cast the data to key-value objects.
 */
public class ZipIntegrationJsonUntypedHandler {

    /**
     * Handles the JSON response and maps it to Location_Identifier__c records.
     * @param jstr The JSON string containing data from the external service.
     * @param recZipMap A map containing Location IDs as keys and ZIP codes as values.
     * @return A list of Location_Identifier__c records populated with data from the JSON response.
     */
    public static List<Location_Identifier__c> handleJsonString(
        String jstr,
        Map<String, String> recZipMap
    ) {
        system.debug('here is reczipmap ' + recZipMap);
        system.debug('here is jstr ' + jstr);
        List<Location_Identifier__c> locationList = new List<Location_Identifier__c>();
        Map<String, Object> fullJson = (Map<String, Object>) JSON.deserializeUntyped(
            jstr
        );
        Map<String, Object> results = new Map<String, Object>();
        if (fullJson.get('results') == null) {
            system.debug('empty');
        }
        if (fullJson.containsKey('results')) {
            system.debug('contains results');
            try {
                results = (Map<String, Object>) fullJson.get('results');
            } catch (exception e) {
                return new List<Location_Identifier__c>();
            }
        } else {
            system.debug('throw exception');
            throw new throwException(
                'Json malformed - does not fit data model'
            );
        }
        for (string locId : recZipMap.keySet()) {
            String zipCode = recZipMap.get(locId);
            Object result;
            if (results.containsKey(zipCode)) {
                result = results.get(zipCode);
            } else {
                continue;
            }
            system.debug(result);
            List<Object> rlist = (List<Object>) result;
            locationList.add(assignLocationIdVariables(rlist, locId));
        }
        return locationList;
    }
    /**
     * Assigns the returned field values for Location_Identifier__c variables based on JSON data.
     * @param rlist A list of JSON objects representing location data.
     * @param locId The Location ID associated with the data.
     * @return A Location_Identifier__c record populated with data from the JSON objects.
     */
    public static Location_Identifier__c assignLocationIdVariables(
        List<Object> rlist,
        String locId
    ) {
        Location_Identifier__c locIdVar = new Location_Identifier__c();
        for (Object r : rlist) {
            if (locId != 'LWCNew') {
                locIdVar.Id = locId;
            }
            system.debug(r);
            Map<String, Object> data = (Map<String, Object>) r;
            if (data.get('country_code') != 'US') {
                continue;
            }
            locIdVar.Zip_Code__c = (string) data.get('postal_code');
            locIdVar.City__c = (string) data.get('city');
            locIdVar.State__c = (string) data.get('state');
            locIdVar.Country__c = (string) data.get('country_code');
        }
        return locIdVar;
    }
    public class throwException extends Exception {
    }
}
