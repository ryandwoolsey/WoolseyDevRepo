/**
 * The ZipIntegrationLocationIdentifierHandler class is responsible for handling Location_Identifier__c records
 * after updates and inserts, and triggering the Zip Code Integration process using the Queuable interface.
 */
public class ZipIntegrationLocationIdentifierHandler {
    /**
     * the handleAfterUpdate method handles Location_Identifier__c records after they are updated.
     * If ZIP codes have changed, enqueues a job to process the updates.
     * @param newMap Trigger.newMap.
     * @param oldMap Trigger.oldMap.
     */
    public static void handleAfterUpdate(
        Map<Id, Location_Identifier__c> newMap,
        Map<Id, Location_Identifier__c> oldMap
    ) {
        Map<String, String> locIdsZipCodes = new Map<String, String>();

        for (Location_Identifier__c li : newMap.values()) {
            Location_Identifier__c liOld = oldMap.get(li.Id);
            if (
                li.Zip_Code__c != liOld.Zip_Code__c &&
                !String.isBlank(li.Zip_Code__c)
            ) {
                locIdsZipCodes.put(li.Id, li.Zip_Code__c);
            }
        }
        if (!locIdsZipCodes.isEmpty()) {
            ZipIntegrationHttpHandler job = new ZipIntegrationHttpHandler(
                locIdsZipCodes
            );
            Id jobId = System.enqueueJob(job);
        }
    }

    /**
     * The handleAfterInsert method handles Location_Identifier__c records after they are inserted.
     * Enqueues jobs to process ZIP code integration for newly inserted records. Will only enqueue if record is not inserted by zipIntegrationLWC_EnterZip LWC component.
     * @param newList Trigger.new.
     */
    public static void handleAfterInsert(List<Location_Identifier__c> newList) {
        map<String, String> locIdsZipCodes = new Map<String, String>();

        for (Location_Identifier__c li : newList) {
            if (!String.isBlank(li.Zip_Code__c) && !li.LWCHandled__c) {
                locIdsZipCodes.put(li.Id, li.Zip_Code__c);
            }
        }

        if (!locIdsZipCodes.isEmpty() && locIdsZipCodes.size()<=100) {
            ZipIntegrationHttpHandler job = new ZipIntegrationHttpHandler(
                locIdsZipCodes
            );
            Id jobId = System.enqueueJob(job);
        }
        if(locIdsZipCodes.size()>100){
            List<Map<String,String>> listLocIdsZipCodes = handleBulkJobs(locIdsZipCodes);
            for(Integer i = 0; i < listLocIdsZipCodes.size(); i++){
                ZipIntegrationHttpHandler bulkJob = new ZipIntegrationHttpHandler(
                listLocIdsZipCodes[i]
            );
            System.enqueueJob(bulkJob);
            }
        }
    }

    /**
     * Splits a large set of Location IDs and ZIP codes into smaller batches for processing.
     * Reason for this is the ZipCodeStack database only allows a maximum of 100 zip codes to be retrieved in any given call.
     * Triggers are batched in 200 records, so will split in half and enqueue 2 jobs per Trigger batch run.
     * @param locIdsZipCodes A map of Location IDs and ZIP codes to be processed.
     * @return A list of maps, each containing a batch of Location IDs and ZIP codes. Should only ever be 2 maps.
     */
    public static List<Map<String, String>> handleBulkJobs(
        Map<String, String> locIdsZipCodes
    ) {
        List<Map<String, String>> listZipMaps = new List<Map<String, String>>();

        Map<String, String> locIdsToIterate = locIdsZipCodes;
        Decimal d = (Decimal) locIdsZipCodes.size();
        for (
            integer i = 0;
            i < (d / 100).Round(RoundingMode.CEILING);
            i++
        ) {
            Integer recordCount = 0;
            Map<String, String> newZipMap = new Map<String, String>();
            for (String locId : locIdsToIterate.keySet()) {
                if (recordCount < 100) {
                    newZipMap.put(locId, locIdsToIterate.get(locId));
                    recordCount++;
                } else {
                    break;
                }
            }
            if (!newZipMap.isEmpty()) {
                listZipMaps.add(newZipMap);
                locIdsToIterate.keySet().removeAll(newZipMap.keySet());
            }
        }
        return listZipMaps;
    }
}
