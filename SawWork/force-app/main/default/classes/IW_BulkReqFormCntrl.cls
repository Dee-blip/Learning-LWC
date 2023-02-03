public class IW_BulkReqFormCntrl {
    
    @AuraEnabled
    //method returns the hour count of available slot of account's Region current Quarter for bulk
    public static String getRgionAccountSlots(String watcherList, Decimal LOE, String Justification, String iwClassification){

        System.debug(' check watchers list : ' + watcherList);
        
        System.debug('justification ::: '+  Justification + ' classftn :  ' + iwClassification);
        JSONParser parser = JSON.createParser(watcherList);
        watcherWrapperCls[] watchersList = new list<watcherWrapperCls>();
        watcherWrapperCls eachWatcher;
        string watchersId='';
        List<Investment_Workbox__c> invalidRequests = new List<Investment_Workbox__c>();
        while (parser.nextToken() != null) {
            
            // Start at the array of invoices.
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                
                while (parser.nextToken() != null) {
                    
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        
                        eachWatcher = (watcherWrapperCls)parser.readValueAs(watcherWrapperCls.class);
                        watchersList.add(eachWatcher);
                        system.debug('--Inside watcherList Parser Method---'+watchersList);
                    }
                    
                } // End of Each Obj
            }
        } // End of Main Loop
        
        list<Id> watchersIdList = new List<Id>();
        String WatchersEmail = '';
        for(watcherWrapperCls eachItem :watchersList){
            watchersId += eachItem.Id + ',';
            watchersIdList.add(eachItem.Id);
        }
        System.debug('Account Ids ::::::::::::::: ' + watchersIdList);
        
        String returnStr ='';
		Decimal QSlot = 0.0;
        Decimal totalSlot = 0.0;
        Map<Id,Decimal> accIdToSlot = new Map<Id,Decimal>();
        System.debug('accId :: ' + watchersIdList); 
        Integer currentQuarter = (Integer) Math.ceil( Date.today().Month() / 3.0);
        Map<Id, Account> lstAccounts = new Map<Id, Account>([SELECT TERR_HIER_2__c, Name 
                          									FROM Account 
                          									WHERE Id =: watchersIdList ]);
        
        String currentYear = String.valueOf(Date.Today().Year());
        List<String> regionOfAccount = new List<String>();
        for(Account acc : lstAccounts.values()){
            regionOfAccount.add(acc.TERR_HIER_2__c + ' ' +'(Region)');
        }
        System.debug('currentQuarter :: '+ currentQuarter + 'currentYear :: '+ currentYear);
        List<Inv_Workbox_Region_Quarter_Mapping__c> listRQMap;
        //Adding psa_Old_Filter for querying active Regions
        try{
            listRQMap = [SELECT Id, Region__c, Region__r.Name, Region1__c, Quarter_1__c, Quarter_2__c, Quarter_3__c, Quarter_4__c, year__c,
                         Allocated_for_Quarter_1__c,Allocated_for_Quarter_2__c,Allocated_for_Quarter_3__c,Allocated_for_Quarter_4__c,
                         Planned_Hours__c , Product_Platform_Hours__c , UnPlanned_Hours__c, Remaining_Planned_Hours__c, Remaining_Unplanned_Hours__c,
                         Remaining_Product_Platform_Hours__c
                         FROM Inv_Workbox_Region_Quarter_Mapping__c
                         WHERE Region__r.Name =: regionOfAccount 
                         AND Region__r.psa_Old__c = false
                         AND year__c =: currentYear
                         AND RecordType.Name = 'Global Services'];
            System.debug('rqMap size:: '+ listRQMap.size() );
        }
        catch(Exception e){
            system.debug('Exception :: ' +e.getMessage());
            returnStr = 'failure';
            return returnStr;
        }
        
        Map<String, Decimal> regToSlot = new Map<String, Decimal>(); 
        
        for(Inv_Workbox_Region_Quarter_Mapping__c rq : listRQMap){
            //Changes for fetching values from new fields on IW Admin
            System.debug('qa qa rq : ' + rq.Id );
            QSlot = 0.0;
			totalSlot = 0.0;
			switch on iwClassification {
                when 'Planned Investment' {QSlot = rq.Remaining_Planned_Hours__c; totalSlot= rq.Planned_Hours__c;}
                when 'Unplanned Investment' {QSlot = rq.Remaining_Unplanned_Hours__c;totalSlot= rq.UnPlanned_Hours__c;}
                when else {QSlot = rq.Remaining_Product_Platform_Hours__c;totalSlot= rq.Product_Platform_Hours__c;}
            }//end of switch
            
            if(!regToSlot.containsKey(rq.Region1__c)){
                if(QSlot != NULL){
                   regToSlot.put(rq.Region1__c, QSlot); 
                }else{
                    regToSlot.put(rq.Region1__c, 0);
                }
                
            }
            System.debug('regToSlot ::::::: ' + regToSlot);
        }
        
		returnStr = 'success';
        String returnAccount = '';
        System.debug('returnStr ::::::::' + returnStr);
        for(Id acId : watchersIdList){
            //System.debug('accIdToSlot :::: assignig them ' + accIdToSlot );
            /*if(!accIdToSlot.containsKey(acId)){
               System.debug('inside if accIdToSlot :::: assignig them ' + accIdToSlot );
               accIdToSlot.put(acId, regToSlot.get(lstAccounts.get(acId).Division__c)); 
            }*/
            System.debug('inside Account Ids looop :::::::::: LOE :: '+ LOE + ' regToSlot.get(lstAccounts.get(acId).TERR_HIER_2__c) ::: '+regToSlot.get(lstAccounts.get(acId).TERR_HIER_2__c));
            if(!(LOE <= regToSlot.get(lstAccounts.get(acId).TERR_HIER_2__c))){
                invalidRequests.add(new Investment_Workbox__c(Account__c = acId, LOE_Hours__c =  LOE, Justification__c = Justification));
                System.debug('checking Slots for accounts' + regToSlot + lstAccounts );
                returnAccount += lstAccounts.get(acId).Name + ', ';
                System.debug('returnAccount ::::::::: '+ returnAccount);
            }
            System.debug('returnStr :::::::::' + returnAccount );  
        }
        
        if(returnAccount != '' ){
            returnAccount = returnAccount.removeEnd(', ');
            IW_getRequestWatchers.notifyLowSlot(JSON.serialize(invalidRequests),0.0, 'bulk', JSON.serialize(regToSlot),JSON.serialize(lstAccounts));
            returnStr = returnAccount;
            
        }
        System.debug('returnStr beforce return  ::: '+ returnStr);
        return returnStr; 
        

    }
     
    /*
    @AuraEnabled
    public static String insertWorkRequests(string watcherList, String workType, String requestor, String timeToAction, String justification, Integer loeHrs, Integer loeMin, String others, String status, boolean productSelected, String products){
        
        System.debug('inside insertWorkRequests method ::::::::::::::::::::::::::::::::: ');
        JSONParser parser = JSON.createParser(watcherList);
        watcherWrapperCls[] watchersList = new list<watcherWrapperCls>();
        watcherWrapperCls eachWatcher;
        string watchersId='';
        while (parser.nextToken() != null) {
            
            // Start at the array of invoices.
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                
                while (parser.nextToken() != null) {
                    
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        
                        eachWatcher = (watcherWrapperCls)parser.readValueAs(watcherWrapperCls.class);
                        watchersList.add(eachWatcher);
                        system.debug('--Inside watcherList Parser Method---'+watchersList);
                    }
                    
                } // End of Each Obj
            }
        } // End of Main Loop
        System.debug('Accounts ::: :::::::::::::::::::::::::::::::: ' + watchersList);
        String str = '';
        List<Id> watchersIdList = new List<Id>();
        String WatchersEmail = '';
        List<Investment_Workbox__c> allWorkRequests = new List<Investment_Workbox__c>();
        for(watcherWrapperCls eachItem :watchersList){
            watchersId += eachItem.Id + ',';
            watchersIdList.add(eachItem.Id);
        }
        for(Id accId : watchersIdList){
            System.debug('inside forLoop creating Object for Investment Work request :::::::::: ' + accId);
            Investment_Workbox__c inv = new Investment_Workbox__c();
            inv.Account__c = accId;
            inv.Requestor__c = requestor;
            inv.Work_Type__c = workType;
            inv.Time_To_Action__c = timeToAction;
            inv.Justification__c = justification;
            inv.LOE_Hours__c = loeHrs;
			inv.LOE_Minutes__c = loeMin;
            inv.Others__c = others;
            inv.Status__c = status;
            inv.isProductSelected__c = productSelected;
            inv.Products__c = products;
            allWorkRequests.add(inv);
        }
        
        try{
            System.debug(' allWorkRequests inserting now ::::::: ' + allWorkRequests);
            insert allWorkRequests; 
			str = 'Success';
        }
        catch(Exception ex){
            str = 'Failure';
            PSA_AutoCreateProjectUtil.sendErrorMails('Error:IW insert of Bulk request failed class : IW_BulkReqFormCntrl' ,ex.getMessage());
        }
        
        return str;
    }
    */
	
    
    public class watcherWrapperCls{ 
        public String Id;
        Public String Name;
        watcherWrapperCls(){}   
    }

    @AuraEnabled
    public static String getProductValues(){

        return JSON.serialize( Investment_Workbox__c.IW_Classification__c.getDescribe().getPicklistValues() ) ;

    }
    
}