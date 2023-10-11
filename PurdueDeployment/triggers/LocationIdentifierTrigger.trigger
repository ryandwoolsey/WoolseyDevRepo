trigger LocationIdentifierTrigger on Location_Identifier__c (before insert, after insert, after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            ZipIntegrationLocationIdentifierHandler.handleAfterInsert(Trigger.new);

        }
        if(Trigger.isUpdate){
            ZipIntegrationLocationIdentifierHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}