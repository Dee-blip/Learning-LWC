public without sharing class CurrentSalesChannelCollection{

    //List<CurrentSalesChannelWrapper> cscList = new List<CurrentSalesChannelWrapper>();
    Map<String, CurrentSalesChannelWrapper> cscExternalIdToWrapperObject = new Map<String, CurrentSalesChannelWrapper>();

    public CurrentSalesChannelCollection(List<Current_Sales_Channel__c> channelRecords)
    {
        for(Current_Sales_Channel__c csc : channelRecords)
        {
            CurrentSalesChannelWrapper summary = new CurrentSalesChannelWrapper(csc);
            //cscList.add(summary);
            System.Debug(LoggingLevel.Error, 'AGH_D adding to existing collection'+summary);
            cscExternalIdToWrapperObject.put(summary.key, summary);
        }
    }

    public void add(CurrentSalesChannelWrapper cscWrapper)
    {
        cscWrapper.setUpdateNeeded();
        //this.cscList.add(cscWrapper);
        this.cscExternalIdToWrapperObject.put(cscWrapper.key, cscWrapper);

    }
    
    public Boolean contains(CurrentSalesChannelWrapper cscWrapper)
    {
            System.Debug(LoggingLevel.Error, 'AGH_D checking if exists'+cscWrapper.key);
        return cscExternalIdToWrapperObject.containsKey(cscWrapper.key);
    }

    public CurrentSalesChannelWrapper getExisting(CurrentSalesChannelWrapper cscWrapper)
    {
        
        return cscExternalIdToWrapperObject.get(cscWrapper.key);
    }

    public void modifyExistingSummaryWith(CurrentSalesChannelWrapper newSummary)
    {
        System.Debug(LoggingLevel.Error, 'AGH_D modifyng existing inside method');
        newSummary.setUpdateNeeded();
        
        cscExternalIdToWrapperObject.put(newSummary.key, newSummary);
    }
    
    

    public List<Current_Sales_Channel__c> getRecordsToBeUpserted()
    {
        List<Current_Sales_Channel__c> recordsToBeUpserted=new List<Current_Sales_Channel__c>();
        for(CurrentSalesChannelWrapper cscWrapper : cscExternalIdToWrapperObject.values())
        {
            
            if(cscWrapper.needsUpdate)
            {
                System.Debug(LoggingLevel.Error, 'Inside needs to be updated records '+cscWrapper.getCSCRecord());
 
                recordsToBeUpserted.add(cscWrapper.getCSCRecord());
            }
        }
        return recordsToBeUpserted;
    }
}