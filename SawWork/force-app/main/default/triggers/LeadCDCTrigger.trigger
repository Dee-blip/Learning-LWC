trigger LeadCDCTrigger on LeadChangeEvent (after insert) {
    EventBus.ChangeEventHeader header;
    Set<String> convertedAkamaiLeadIds = new Set<String>();
    Boolean isLeadConversionAsynModeSet = MarketingIT_Custom_Settings__c.getValues('LeadAsyncConversionFlagStatus') != null?Boolean.valueOf(MarketingIT_Custom_Settings__c.getValues('LeadAsyncConversionFlagStatus').Flag_Status__c):true;
    //Check if Async mode is set, only then process events
    if(isLeadConversionAsynModeSet){
        //Iterate through each change event on lead object
        for(LeadChangeEvent leadEvent : Trigger.new){
            EventBus.ChangeEventHeader header = leadEvent.ChangeEventHeader;
            if(header.changetype == 'UPDATE'){
                //check for manual lead conversion event;
                if(header.changedFields.contains('Status') && header.changedFields.contains('RecordTypeId') && leadEvent.get('Status') == 'Converted' && leadEvent.get('RecordTypeId') == GSMSettings.getValue('ConvertedLeadRecordTypeId') && (leadEvent.get('Auto_Convert_Source__c') == null || leadEvent.get('Auto_Convert_Source__c') == '')){
                    convertedAkamaiLeadIds.addAll(header.recordIds);
                }
            }
        }
        if(!convertedAkamaiLeadIds.isEmpty()){
            System.debug(logginglevel.DEBUG,'Calling MARIT_LeadCDCEventHandler');
            MARIT_LeadCDCEventHandler.marketoLeadConversion(convertedAkamaiLeadIds);
            System.debug(logginglevel.DEBUG,'Finished Execution of MARIT_LeadCDCEventHandler');
        }
    }
}