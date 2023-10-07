trigger LocationIdentifierTrigger on Location_Identifier__c (before insert, after insert) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            LocationIdentifierHandler.handleBeforeInsert(Trigger.new);
        }
    }
}