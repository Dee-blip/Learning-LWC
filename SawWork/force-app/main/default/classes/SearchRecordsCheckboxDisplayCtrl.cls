public class SearchRecordsCheckboxDisplayCtrl {
	@AuraEnabled
    public static List<String> getAllRecs(String queryString, String objectType,
                                              String fieldAPIName){
        List<SObject> lSObj = Database.query(queryString);
        List<String> lResults = new List<String>();
        for(SObject sObj :lSObj){
            lResults.add((String.valueOf(sObj.get(fieldAPIName))).trim());        	
        }
        /*List<String> lString = new List<String>{'Server','Kona','DDos','Prolexic','Site Accl','All','XYZ','ABC','BBC','Local','Hello','Why','Prod 1', 'Prod 2'};
            for(integer i=0; i<600 ; i++){
                lString.add('prod' + i);
            }  */
        System.debug('### ' + queryString);   
        System.debug('### ' + lResults);
        return lResults;
	}
    @AuraEnabled        
    public static List<String> getPickListValuesIntoList(String objectType, String selectedField){
        List<String> pickListValuesList = new List<String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
    	return pickListValuesList;
	}
    //method returns the hour count of available slot of account's Region current Quarter
    @AuraEnabled
    public Static Decimal getRgionAccountSlot(Id iwId, string requestParam) {
        
        Decimal QSlot = 0.0;
        Decimal totalSlot = 0.0;
        System.debug('accId :: ' + iwId);
        //19.5 Sujay : Adding Security__c check for Geo/Region slots and Showing Slot details based on quarter and year Submitted_Date__c
        // Invluded new fields introduced depending on IW classification
        Investment_Workbox__c iwDetails = [SELECT Region__c, Geo__c, Submitted_Date__c,Security__c , IW_Classification__c
                          FROM Investment_Workbox__c 
                          WHERE Id =: iwId Limit 1];
        //Integer currentQuarter = (Integer) Math.ceil( Date.today().Month() / 3.0);
        Integer currentQuarter = iwDetails.Submitted_Date__c != null ?(Integer) Math.ceil( iwDetails.Submitted_Date__c.Month() / 3.0) : (Integer) Math.ceil( Date.today().Month() / 3.0);
        System.debug('accId :: ' + iwDetails.Region__c);
        String regionOfAccount = iwDetails.Security__c ? iwDetails.Geo__c + ' ' +'(Geography)' : iwDetails.Region__c + ' ' +'(Region)';
        //String currentYear = String.valueOf(Date.Today().Year());
        String currentYear = iwDetails.Submitted_Date__c != null ? String.valueOf(iwDetails.Submitted_Date__c.Year()) : String.valueOf(Date.Today().Year());
        System.debug('currentQuarter :: '+ currentQuarter + 'currentYear :: '+ currentYear);
        Inv_Workbox_Region_Quarter_Mapping__c rqMap;
        
        //Adding filter for to pick active Regions
        try{
            rqMap = [SELECT Id, Region__c, Region1__c, Quarter_1__c, Quarter_2__c, Quarter_3__c, Quarter_4__c, year__c,
                     Allocated_for_Quarter_1__c,Allocated_for_Quarter_2__c,Allocated_for_Quarter_3__c,Allocated_for_Quarter_4__c ,
                     Planned_Hours__c , Product_Platform_Hours__c , UnPlanned_Hours__c , Remaining_Planned_Hours__c , 
                     Remaining_Product_Platform_Hours__c , Remaining_Unplanned_Hours__c
                     FROM Inv_Workbox_Region_Quarter_Mapping__c
                     WHERE Region__r.Name =: regionOfAccount
                     AND Region__r.psa_Old__c = FALSE
                     AND RecordType.Name = 'Global Services'
                     AND year__c =: currentYear LIMIT 1];
            System.debug('rqMap :: '+ rqMap.year__c + ' :: rqMap.Id :: ' + rqMap.Id );
        }
        catch(exception e){
            system.debug('Exception :: ' +e.getMessage());
            return QSlot.setScale(2);
        }
        
        switch on iwDetails.IW_Classification__c {
            when 'Planned Investment' {QSlot = rqMap.Remaining_Planned_Hours__c; totalSlot= rqMap.Planned_Hours__c;}
            when 'Unplanned Investment' {QSlot = rqMap.Remaining_Unplanned_Hours__c;totalSlot= rqMap.UnPlanned_Hours__c;}
            when else {QSlot = rqMap.Remaining_Product_Platform_Hours__c;totalSlot= rqMap.Product_Platform_Hours__c;}
        }//end of switch
        
        System.debug('QSlot :: ' + QSlot);
        if(QSlot > 0){
            if(requestParam == 'hours'){
                System.debug('requestParam :: '+ requestParam);
                return QSlot.setScale(2);
            }
            else{
                System.debug('QSlot :: '+ QSlot);
                System.debug('totalSlot :: '+ totalSlot);
                return ((QSlot*100)/totalSlot).setScale(2);
            }
            
        }
        return 0;
    }//end of method getRgionAccountSlot

}