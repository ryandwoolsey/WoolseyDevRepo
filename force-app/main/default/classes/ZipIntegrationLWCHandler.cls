/**
 * The ZipIntegrationLWCHandler class provides Aura-enabled methods for creating Location Identifiers from the
 * zipIntegrationLWC_EnterZip Lightning Web Component, and updating object records based on ZIP 
 * code information if the component happens to be rendered on a Record Page (Lead, Account, Contact).
 */
public class ZipIntegrationLWCHandler {

    /**
     * Creates Location Identifier records and updates object records, if the recordId field contains a Lead, Account, or Contact Id.
     * @param zipCode The ZIP code to process.
     * @param recordId The ID of the object record (Lead,Account,Contact) to update.
     * @return A string indicating the result of the operation ('unsuccessful' or the Location Identifier ID to be displayed to end user).
     */
    @AuraEnabled
    public static string createLocationIdentifiers(
        string zipCode,
        string recordId
    ) {
        string strToReturn = 'unsuccessful';

        Map<String, String> locMap = new Map<String, String>{
            'LWCNew' => zipCode
        };

        Map<Boolean, String> jsonResponse = ZipIntegrationHttpHandler.processPayload(
            zipCode
        );
        List<Location_Identifier__c> locList = new List<Location_Identifier__c>();

        for (boolean b : jsonResponse.keySet()) {
            if (b) {
                system.debug(loclist);
                system.debug(jsonResponse.get(true));
                system.debug(locMap);
                locList = ZipIntegrationJsonUntypedHandler.handleJsonString(
                    jsonResponse.get(true),
                    locMap
                );
                if (locList.isEmpty()) {
                    system.debug('did i get here');
                    throw new AuraHandledException(
                        'No zipcode data found. Please try again.'
                    );
                }
                String validation = validateRecord(locList);
                if (validation == 'Success') {
                    system.debug('loclist ' + json.serializePretty(locList));
                    try {
                        system.debug('first try block ');
                        insert locList;
                        for (Location_Identifier__c locString : locList) {
                            strToReturn = locString.Id;
                        }
                    } catch (DMLexception e) {
                        throw new AuraHandledException(
                            e.getMessage() + ' Insert failed. '
                        );
                    }
                } else {
                    throw new AuraHandledException(validation);
                }
            } else {
                System.debug(
                    'Data retrieval failed: ' + jsonResponse.get(false)
                );
            }
        }
        system.debug('Here is Object recordId: ' + recordId);
        if (!String.isBlank(recordId)) {
            try {
                updateObjectRecord(recordId, locList[0]);
                system.debug('updateObjectRecord Fired');
            } catch (exception e) {
                throw new AuraHandledException(
                    e.getMessage() + 'Record Update Failed'
                );
            }
        }
        return strToReturn;
    }
    /**
     * Validates Location Identifier records.
     * @param locList A list of Location Identifier records to validate.
     * @return A string indicating the validation result ('Success' or 'No Zip Codes Found').
     * This string informs the end user of the status of their operation. Displayed in Toast Message on LWC.
     */
    public static string validateRecord(List<Location_Identifier__c> locList) {
        String stringToReturn;
        for (Location_Identifier__c loc : locList) {
            system.debug('Zip Found' + json.serializePretty(loc));
            if (
                String.isBlank(loc.City__c) &&
                String.isBlank(loc.State__c) &&
                String.isBlank(loc.Country__c)
            ) {
                stringToReturn = 'No Zip Codes Found';
            } else {
                stringToReturn = 'Success';
            }
        }
        return stringToReturn;
    }

    /**
     * Updates the object record based on its ID and object type using a Switch Statement.
     * @param recordId The ID of the object record to update.
     * @param locIdent The Location Identifier record containing ZIP code data.
     */
    public static void updateObjectRecord(
        string recordId,
        Location_Identifier__c locIdent
    ) {
        Id recId = (Id) recordId;
        switch on recId.getSObjectType().getDescribe().getName() {
            when 'Lead' {
                Lead l = new Lead(
                    Id = recordId,
                    City = locIdent.City__c,
                    State = locIdent.State__c,
                    Country = locIdent.Country__c,
                    PostalCode = locIdent.Zip_Code__c
                );
                update l;
            }
            when 'Contact' {
                Contact c = new Contact(
                    Id = recordId,
                    MailingCity = locIdent.City__c,
                    MailingState = locIdent.State__c,
                    MailingCountry = locIdent.Country__c,
                    MailingPostalCode = locIdent.Zip_Code__c
                );
                update c;
            }
            when 'Account' {
                Account a = new Account(
                    Id = recordId,
                    BillingCity = locIdent.City__c,
                    BillingState = locIdent.State__c,
                    BillingCountry = locIdent.Country__c,
                    BillingPostalCode = locIdent.Zip_Code__c
                );
                update a;
            }
        }
    }
}
