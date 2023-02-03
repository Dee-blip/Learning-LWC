public class TrackGovLimits implements callable {

    public  string TrackGovLimits()
    {
        String returnStatus = 'Count of newly created components: ';
        List<String> listOfObj = GsmUtilClass.getGSMSettingValue('List_of_Objects_to_track_New_CMP').split(',');

        List<NewCMP_Audit_Object__c> cmpToSyncList = new List<NewCMP_Audit_Object__c>();
        Promise callOutVar1;
        callOutVar1 = new Promise();
        for(String objName : listOfObj)
            callOutVar1.then(new TrackGovLimitsChainClass(objName));
        callOutVar1.then(new TrackGovLimitsDMLChain());
        callOutVar1.error(new PromiseErrorDebugger());
        callOutVar1.execute(cmpToSyncList);

        List<sObject_Limit__c> limitsToSyncList = new List<sObject_Limit__c>();
        Promise callOutVar2;
        callOutVar2 = new Promise();
        for(String objName : listOfObj)
            callOutVar2.then(new TracksObjectLimitStatus(objName));
        callOutVar2.then(new sObjectLimitsDMLChain());
        callOutVar2.error(new PromiseErrorDebugger());
        callOutVar2.execute(limitsToSyncList);
        
        returnStatus = returnStatus + Integer.valueOf(cmpToSyncList.size());
        return returnStatus;
    } 
    // Dispatch actual methods
   public  Object call(String action, Map<String, Object> args) {
    switch on action {
      when 'TrackGovLimits' {
        return this.TrackGovLimits();
      }
      when else {
       throw new ExtensionMalformedCallException('Method not implemented');
      }
    }
  }

  public class ExtensionMalformedCallException extends Exception {}
}