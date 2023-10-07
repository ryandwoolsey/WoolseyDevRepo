public class LocationIdentifierHandler {
    public static void handleBeforeInsert(List<Location_Identifier__c> newList) {
        for(Location_Identifier__c loc : newList){
            if(!String.isBlank(loc.Zip_Code__c)){
                loc.State__c = 'California';
            }
        }

    }
}