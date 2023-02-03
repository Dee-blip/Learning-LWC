/**
 * @description       : FFPSA-558
 * @author            : Sujay Sharath Suhas
 * date               : October 2018
 * @last modified on  : 10-25-2021
**/
public without sharing class InvWB_Handler {
    
    // 20.6 Converted class to without sharing as the parent class is with Sharing - we were unable to get email templates
    //To store first/second level approvers for LOE entry level
    Map< String, Map<String, List<String>> > approverLevel;
    Set<String> userDivisions;
    Map<String ,PSA_Common_Setting__mdt> loeCheckToApprovers;
    //List<String> allApprover;
    Map<String, List<String>> orphanApproverLevel;
    // List<String> SecIW4to40CostCenters;
    // List<String> SecIW40to80CostCenters;
    // List<String> SecIW80toCostCenters;
    Public User loggedInUserDetails;
    //Map<String, String> prodAcronymMap;
    Map<Id, String> accIdNameMap;
    
    public InvWB_Handler()
    {
        if(loggedInUserDetails == NULL)
        {
            loggedInUserDetails = [SELECT 
                                     Id, Name, Title , Cost_Center__c
                                    From User 
                   WHERE Id =: userInfo.getUserId()];
        }
    }
    
    //19.1 : Added by Sujay to Stamp the EndTime after 24 hours of IW Submitted date .
    public void stampEndTime(List<Investment_Workbox__c> allWRs){
        
        for(Investment_Workbox__c wr : allWRs){
            if(wr.Escalate_Time__c == NULL && wr.Status__c.equalsIgnoreCase('Awaiting Approval')){
                //Read Submitted date for every request and stamp hours accordingly.
                Datetime dt = wr.Submitted_Date__c;
                String dayOfWeek = dt.format('EEEE');
                System.debug('Day : ' + dayOfWeek);
                if(dayOfWeek.equalsIgnoreCase('Friday')){
                    wr.Escalate_Time__c = wr.Submitted_Date__c.addHours(96-12);
                }
                else if(dayOfWeek.equalsIgnoreCase('Saturday')){
                    wr.Escalate_Time__c = wr.Submitted_Date__c.addHours(72-12);
                }
                else if(dayOfWeek.equalsIgnoreCase('Sunday')){
                    wr.Escalate_Time__c = wr.Submitted_Date__c.addHours(48-12);
                }
                else{
                    //wr.Escalate_Time__c = wr.Submitted_Date__c.addMinutes(1);
                    wr.Escalate_Time__c = wr.Submitted_Date__c.addHours(24);
                }
            }
        }
        
    }
    
    
    //Add Default Watchers method
    public static void addDefaultWatchers(List<Investment_Workbox__c> WRs){
        Set<Id> reqIds = new Set<Id>();
        Set<String> watchers = new Set<String>();
        Set<String> watchersEmail = new Set<String>();
        List<String> wts = new List<String>();
        List<String> wEmls = new List<String>();
        
        for(Investment_Workbox__c iwb : WRs){
            reqIds.add(iwb.Requestor__c);
        }
        
        Map<Id, User> uSet = new Map<Id, User>([SELECT Id, ManagerId, Manager.Email, Email, Title
                                                FROM User
                                                WHERE (ID IN :reqIds
                                                       OR ID =: UserInfo.getUserId())
                                                AND Email != NULL 
                                                AND Manager.Email != NULL
                                                AND Title != NULL]);
        
        for(Investment_Workbox__c wRid : WRs){
            
            watchersEmail.clear();
            wEmls.clear();
            wts.clear();
            watchers.clear();
            
            watchers.add(userInfo.getUserId());
            if(uSet.containsKey(userInfo.getUserId())){
                watchersEmail.add(uSet.get(userInfo.getUserId()).Email);  
                //FFPSA-1184 : changes 
                //if(uSet.get(userInfo.getUserId()).ManagerId != NULL){
                //  watchers.add(uSet.get(userInfo.getUserId()).ManagerId ); 
                //  watchersEmail.add(uSet.get(userInfo.getUserId()).Manager.Email );
                //}   
            }
            System.debug('wRid.Requestor__c :: ' + wRid.Requestor__c);
            watchers.add(wRid.Requestor__c);
            if(uSet.containsKey(wRid.Requestor__c)){
                System.debug('uSet.get(wRid.Requestor__c).Email :: '+ uSet.get(wRid.Requestor__c).Email);
                watchersEmail.add(uSet.get(wRid.Requestor__c).Email);
                //FFPSA-1184 : changes 
                //if(uSet.get(wRid.Requestor__c).ManagerId != NULL){
                //  watchers.add(uSet.get(wRid.Requestor__c).ManagerId);
                //  watchersEmail.add(uSet.get(wRid.Requestor__c).Manager.Email);
                //}
            }
            wts.addAll(watchers);
            wEmls.addAll(watchersEmail);
            wRid.WatchersId__c = String.join(wts,',');
            wRid.Watchers_Email_Id__c = String.join(wEmls,',');
            //wRid.WatchersId__c = userInfo.getUserId() + ','+ uSet.get(userInfo.getUserId()).ManagerId + ','+ wRid.Requestor__c;
            //wRid.WatchersId__c += wRid.WatchersId__c.containsIgnoreCase(uSet.get(wRid.Requestor__c).ManagerId) ? '' : ','+uSet.get(wRid.Requestor__c).ManagerId;
            System.debug('wRIdToWatchers :: '+ wRid.WatchersId__c);
        }
        
    }
    
    
    //Method is to initialize the Custom meta data for LOE hours
    public void initializeCustomMetadata(){

        userDivisions = new Set<String>();
        approverLevel = new Map< String, Map<String, List<String>> >();
        //allApprover = new List<String>();
        loeCheckToApprovers = new Map<String, PSA_Common_Setting__mdt>();
        // SecIW4to40CostCenters = new List<String>();
        // SecIW40to80CostCenters = new List<String>();
        // SecIW80toCostCenters = new List<String>();
        //prodAcronymMap = new Map<String, String>();
        List<PSA_Common_Setting__mdt> iwSettings = [SELECT Id,Value__c, LOE_High_Limit__c,LOE_Low_Limts__c,MasterLabel,
                                                        FirstLevelApprovers__c, SecondLevelApprovers__c, Value_Long__c , Escalation_Approvers__c , Escalation_Secondary_Approvers__c
                                                    FROM PSA_Common_Setting__mdt
                                                    WHERE type__c = 'IW_Settings__mdt'];
        //Added changes to store title changes in map to be fetched dynalimally according to IW Type
        for(PSA_Common_Setting__mdt iws : iwSettings){
            //if(iws.LOE_Low_Limts__c == 4){
            if(iws.MasterLabel == 'IW LOE 4 To 40' || iws.MasterLabel == 'IW LOE 4 To 40PP'){
                System.debug('before ld 1');
                loadApproverLevel(iws, '4To40');
            }
            //Load approvers and cost center for SECUIRTY 4-40 IWs
            // else if(iws.MasterLabel == 'IW SEC LOE 4 To 40')
            // {
            //     loadApproverLevel(iws, '4To40Sec');
            //     SecIW4to40CostCenters.addAll( iws.Value__c.split(',') );
            // }
            //else if(iws.LOE_Low_Limts__c == 40){
            else if(iws.MasterLabel == 'IW LOE 40 To 80' || iws.MasterLabel == 'IW LOE 40 To 80PP' ){
                System.debug('before ld 2');
                loadApproverLevel(iws, '40To80');
            }
            //Load approvers and cost center for SECUIRTY 40-80 IWs
            // else if(iws.MasterLabel == 'IW SEC LOE 40 To 80'){
            //     loadApproverLevel(iws, '40To80Sec');
            //     SecIW40to80CostCenters.addAll(iws.Value__c.split(','));
            // }
            //else if(iws.LOE_Low_Limts__c == 80){
            else if(iws.MasterLabel == 'IW LOE > 80' || iws.MasterLabel == 'IW LOE > 80PP'){
                System.debug('before ld 3');
                loadApproverLevel(iws, '80');
            }
            //Lad approvers and cost center for SECUIRTY above 80
            // else if(iws.MasterLabel == 'IW SEC LOE > 80'){
            //     loadApproverLevel(iws, '80Sec');
            //     SecIW80toCostCenters.addAll(iws.Value__c.split(','));
            // }
            // else if(iws.MasterLabel == 'IW Milestone Name Map') {

            //     for (String str : iws.Value_Long__c.split(',') ) {
            //         prodAcronymMap.put(str.split(':')[0], str.split(':')[1]);
            //     }
            // }
        }

        String uDivisions = [select Value_Long__c from PSA_Common_Setting__mdt where type__c = 'IW_Divisions' limit 1].Value_Long__c;
        userDivisions.addAll(uDivisions.split(':'));
        
    }
    
    
    // set first/second level approver
    public void loadApproverLevel(PSA_Common_Setting__mdt iws, String limitType) {
        loeCheckToApprovers.put(limitType,iws);
        Map<String, List<String>> lApprover = new Map<String, List<String>>();
        if (iws.Value__c == 'PlannedUnPlanned') {
            System.debug('loadd apprvr : ' + limitType );
            loeCheckToApprovers.put(limitType+'PunP',iws);
            lApprover.put('flAppPunP', iws.FirstLevelApprovers__c.split(':'));
            lApprover.put('secAppPunP', iws.SecondLevelApprovers__c.split(':'));
            lApprover.put('flAppPunPEsc', iws.Escalation_Approvers__c.split(':'));
            lApprover.put('secAppPunPEsc', iws.Escalation_Secondary_Approvers__c.split(':'));
            approverLevel.put(limitType+'PunP',lApprover);
            System.debug('loadd apprvr : ' + lApprover );
        
        } else if (iws.Value__c == 'ProductPlatform') {
            System.debug('loadd apprvr 1 : ' + limitType );
            loeCheckToApprovers.put(limitType+'PP',iws);
            lApprover.put('flAppPP', iws.FirstLevelApprovers__c.split(':'));
            lApprover.put('secAppPP', iws.SecondLevelApprovers__c.split(':'));
            lApprover.put('flAppPPEsc', iws.Escalation_Approvers__c.split(':'));
            lApprover.put('secAppPPEsc', iws.Escalation_Secondary_Approvers__c.split(':'));
            approverLevel.put(limitType+'PP',lApprover);
            System.debug('loadd apprvr 1 : ' + lApprover );
        }
        
        //lApprover.put('flApp', iws.FirstLevelApprovers__c.split(':'));
        
        //allApprover.addAll(iws.FirstLevelApprovers__c.split(','));
        //lApprover.put('secApp', iws.SecondLevelApprovers__c.split(':'));
        //allApprover.addAll(iws.SecondLevelApprovers__c.split(','));
        
        //System.debug('limit type str : ' + limitType + ' aprrs undr that  ' + approverLevel.get(limitType) );
    }
    
    //set Orphan check box if there is no Approver for the WRs after insert
    @future
    public static void setOrphanQueue(List<Id> submittedWrs)
    {
        List<Investment_Workbox__c> allSubmittedWrs= [SELECT Id, Escalated__c,IW_Modify__c,Division__c,Geo__c,Region__c, LOE__c, LOE_Hours__c, LOE_Minutes__c,Orphan_Request__c , IW_Classification__c
                                                      FROM Investment_Workbox__c
                                                      WHERE Id IN: submittedWrs  ];
        Set<String> allRegion = new Set<String>();
        for(Investment_Workbox__c iw: allSubmittedWrs ){
            if(iw.Region__c != NULL ){
                allRegion.add(iw.Region__c + ' ' + '(Region)');
            }
        }
        if(allRegion != NULL && allRegion.size() > 0){
            InvWB_Handler ih = new InvWB_Handler();
            List<Investment_Workbox__c> orphanRecs = new List<Investment_Workbox__c>();
            Map<Id,Set<String>> setOrphan = ih.getWRIdToApproversList(allSubmittedWrs, allRegion, 'id');
            System.debug('james setOrphan :: ' + setOrphan);
            for(Investment_Workbox__c wr : allSubmittedWrs){
                //System.debug('James Orphan Queue Test : '+ setOrphan.containsKey(wr.Id) + ' :::::  (setOrphan.get(wr.Id).size() > 0)  ' + (setOrphan.get(wr.Id).size() > 0) );
                //if(setOrphan.containsKey(wr.Id) && ! (setOrphan.get(wr.Id).size() > 0) ){
                if(setOrphan.isEmpty() || (setOrphan.containsKey(wr.Id) && ! (setOrphan.get(wr.Id).size() > 0)) ){
                    System.debug('Setting up Orphan Queue checkbox');
                    wr.Orphan_Request__c = true;
                    wr.IW_Modify__c = true;
                    orphanRecs.add(wr);
                }
            }
            if(orphanRecs.size() > 0){
                update orphanRecs;
            }
        }
        
        
    }
    
    
    //set Orphan check box if there is no Approver for the WRs before update
    public void setOrphanQueue(List<Investment_Workbox__c> oQueue, Set<String> allRegions){
        
        System.debug('James :: in oQueue allRegions :: ' + allRegions);
        Map<Id,Set<String>> setOrphan = getWRIdToApproversList(oQueue, allRegions, 'id');
        System.debug('james setOrphan :: ' + setOrphan);
        for(Investment_Workbox__c wr : oQueue){
            System.debug('wr.Id ::: ' + wr.Id);
            System.debug('LOE_Hours__c' + wr.LOE_Hours__c);
            //19.5 Adding if setOrphan Empty(check) 
            if(setOrphan.isEmpty() || (setOrphan.containsKey(wr.Id) && ! (setOrphan.get(wr.Id).size() > 0)) ) {
                System.debug('Setting up Orphan Queue checkbox');
                wr.IW_Modify__c = true;
                wr.Orphan_Request__c = true;
            }
        }
    }
    
    
    //to check availabality of slots when submitted called from trigger
    public void checkIfSlotAvailableToSubmit(List<Investment_Workbox__c> submittedWRs)
    {
        //getRgionAccountSlot
        System.debug('in checkIfSlotAvailableToSubmit :::::::::::::::::::::: ');
        Set<Id> accIds = new Set<Id>();

        Decimal totalHrs = 0.0;
        for(Investment_Workbox__c iwb : submittedWRs)
        {  
            accIds.add(iwb.Account__c);   
        }

        System.debug('accIds :::::: '+ accIds);
        Map<Id, Map<String, Decimal> > accIdToQSlot = getRgionAccountSlots(accIds,  'hour');
        System.debug('accIdToQSlot :::::::::::::::::::::::::::: '+ accIdToQSlot);
        for(Investment_Workbox__c iwb : submittedWRs)
        {
            totalHrs = 0.0;
            System.debug('in for checking :::::::::::::::::::::: ');
            if(iwb.Status__c != NULL && (iwb.Status__c.equals('Awaiting Approval') || iwb.Status__c.equals('Escalated')))
            {
                totalHrs = iwb.LOE_Hours__c + (iwb.LOE_Minutes__c/60.0);
                //Decimal slots = getRgionAccountSlot(iwb.Account__c, 'hours');
                System.debug('slots available before submit :::::::::::::::::  '+ totalHrs );
                //20.6 geo to region interchange and do not through validations for security slots
                // Removed secuirty checks
                // if(iwb.Security__c && accIdToQSlot.containskey(iwb.Account__c) && accIdToQSlot.get(iwb.Account__c) != NULL && totalHrs > accIdToQSlot.get(iwb.Account__c).get(iwb.Geo__c+' (Geography)'))
                // {
                //     //iwb.addError('Slots are not available to Submit the Work Request');
                // }
                if(accIdToQSlot.containskey(iwb.Account__c) && accIdToQSlot.get(iwb.Account__c) != NULL && totalHrs > accIdToQSlot.get(iwb.Account__c).get(iwb.Region__c+' (Region)')) 
                {
                    iwb.addError('Slots are not available to Submit the Work Request.');
                }
            }
        }
    }
    
    
    //method returns the hour count of available slot of account's Region/Geo for current Quarter - called from IW comp
    public Decimal getRgionAccountSlot(Id accId, string requestParam, String regOrGeo, String iwClassification) {
        
        Decimal QSlot = 0.0;
        Decimal totalSlot = 0.0;
        System.debug('accId :: ' + accId);
        Account accObj = new Account();
        Integer currentQuarter = (Integer) Math.ceil( Date.today().Month() / 3.0);
        if(accId != NULL){
            accObj = [SELECT TERR_HIER_1__c, TERR_HIER_2__c
                      FROM Account
                      WHERE Id =: accId Limit 1];
        }
        String regionOfAccount = 'Region'.equalsIgnoreCase(regOrGeo) ? accObj.TERR_HIER_2__c + ' ' +'(Region)' :  accObj.TERR_HIER_1__c + ' ' +'(Geography)' ;
        String currentYear = String.valueOf(Date.Today().Year());
        System.debug('currentQuarter :: '+ currentQuarter + 'currentYear :: '+ currentYear + ' regionOfAccount:: ' + regionOfAccount);
        Inv_Workbox_Region_Quarter_Mapping__c rqMap;
        
        try{
            rqMap = [SELECT Id, Region__c, Region1__c, Quarter_1__c, Quarter_2__c, Quarter_3__c, Quarter_4__c, year__c, Product_Platform_Hours__c,
                     Allocated_for_Quarter_1__c,Allocated_for_Quarter_2__c,Allocated_for_Quarter_3__c,Allocated_for_Quarter_4__c , 
                     Planned_Hours__c , UnPlanned_Hours__c , Remaining_Planned_Hours__c , Remaining_Product_Platform_Hours__c , Remaining_Unplanned_Hours__c
                     FROM Inv_Workbox_Region_Quarter_Mapping__c
                     WHERE Region__r.Name =: regionOfAccount
                     AND Region__r.psa_Old__c = false
                     AND RecordType.Name = 'Global Services'
                     AND year__c =: currentYear LIMIT 1];
            System.debug('rqMap :: '+ rqMap.year__c + ' :: rqMap.Id :: ' + rqMap.Id );
        }
        catch(exception e){
            system.debug('Exception :: ' +e.getMessage());
            return QSlot;
        }
        
        switch on currentQuarter {
            when 1 {QSlot = rqMap.Quarter_1__c; totalSlot= rqMap.Allocated_for_Quarter_1__c;}
            when 2 {QSlot = rqMap.Quarter_2__c;totalSlot= rqMap.Allocated_for_Quarter_2__c;}
            when 3 {QSlot = rqMap.Quarter_3__c;totalSlot= rqMap.Allocated_for_Quarter_3__c;}
            when else {QSlot = rqMap.Quarter_4__c;totalSlot= rqMap.Allocated_for_Quarter_4__c;}
        }//end of switch

        System.debug('classification ::: ' + iwClassification );


        if(iwClassification == 'Planned Investment')
        {
            QSlot = rqMap.Remaining_Planned_Hours__c ;
            totalSlot = rqMap.Planned_Hours__c;
        } else if (iwClassification == 'Unplanned Investment') 
        {
            QSlot = rqMap.Remaining_Unplanned_Hours__c ;
            totalSlot = rqMap.UnPlanned_Hours__c;
        } else if ( iwClassification == 'Product/Platform Work')
        {
            QSlot = rqMap.Remaining_Product_Platform_Hours__c ;
            totalSlot = rqMap.Product_Platform_Hours__c;
        }


        
        System.debug('QSlot :: ' + QSlot);
        if(QSlot > 0){
            if(requestParam == 'hours'){
                System.debug('requestParam :: '+ requestParam);
                return QSlot;
            }
            else{
                System.debug('QSlot :: '+ QSlot);
                System.debug('totalSlot :: '+ totalSlot);
                return (QSlot*100)/totalSlot;
            }
            
        }
        else{
            return QSlot;
        }
        
    }//end of method getRgionAccountSlot
    
    
    //method returns the hour count of available slot of account's Region current Quarter for bulk
    public Map<Id, Map<String, Decimal> > getRgionAccountSlots(Set<Id> accIds, string requestParam){
        
        Decimal QSlot = 0.0;
        Decimal totalSlot = 0.0;
        Map<Id, Map<String, Decimal> > accIdToSlot = new Map<Id, Map<String, Decimal> >();
        System.debug('accId :: ' + accIds);
        Integer currentQuarter = (Integer) Math.ceil( Date.today().Month() / 3.0);
        Map<Id, Account> lstAccounts = new Map<Id, Account>([SELECT TERR_HIER_1__c, TERR_HIER_2__c
                                                             FROM Account
                                                             WHERE Id =: accIds ]);
        
        String currentYear = String.valueOf(Date.Today().Year());
        List<String> regionOfAccount = new List<String>();
        for(Account acc : lstAccounts.values()){
            regionOfAccount.add(acc.TERR_HIER_2__c + ' ' +'(Region)');
            regionOfAccount.add(acc.TERR_HIER_1__c + ' ' +'(Geography)');
        }
        System.debug('currentQuarter :: '+ currentQuarter + 'currentYear :: '+ currentYear);
        List<Inv_Workbox_Region_Quarter_Mapping__c> listRQMap;
        
        //Adding Filter for querying active Regions.
        try{
            listRQMap = [SELECT Id, Region__c, Region__r.Name, Region1__c, Quarter_1__c, Quarter_2__c, Quarter_3__c, Quarter_4__c, year__c,
                         Allocated_for_Quarter_1__c,Allocated_for_Quarter_2__c,Allocated_for_Quarter_3__c,Allocated_for_Quarter_4__c
                         FROM Inv_Workbox_Region_Quarter_Mapping__c
                         WHERE Region__r.Name =: regionOfAccount
                         AND year__c =: currentYear
                         AND Region__r.psa_Old__c = false
                         AND RecordType.Name = 'Global Services'];
            System.debug('rqMap :: '+ listRQMap );
        }
        catch(Exception e){
            system.debug('Exception :: ' +e.getMessage());
            return new Map<Id, Map<String, Decimal> >();
        }
        
        Map<String, Decimal> regToSlot = new Map<String, Decimal>();
        
        for(Inv_Workbox_Region_Quarter_Mapping__c rq : listRQMap){
            System.debug('listRQMap ::::::: + ' +  rq);
            QSlot = 0.0;
            totalSlot = 0.0;
            switch on currentQuarter {
                when 1 {QSlot = rq.Quarter_1__c; totalSlot= rq.Allocated_for_Quarter_1__c;}
                when 2 {QSlot = rq.Quarter_2__c;totalSlot= rq.Allocated_for_Quarter_2__c;}
                when 3 {QSlot = rq.Quarter_3__c;totalSlot= rq.Allocated_for_Quarter_3__c;}
                when else {QSlot = rq.Quarter_4__c;totalSlot= rq.Allocated_for_Quarter_4__c;}
            }//end of switch
            
            if(!regToSlot.containsKey(rq.Region__r.Name)){
                regToSlot.put(rq.Region__r.Name, QSlot);
            }
            System.debug('regToSlot ::::::: ' + regToSlot);
        }
        
        for(Id acId : accIds){
            System.debug('accIdToSlot :::: assignig them ' + accIdToSlot );
            if(acId != NULL && !accIdToSlot.containsKey(acId)){
                System.debug('inside if accIdToSlot :::: assignig them ' + accIdToSlot );
                System.debug('Testt Id ::: '+ acId);
                if(regToSlot.get(lstAccounts.get(acId).TERR_HIER_2__c + ' (Region)') == NULL){
                    Map<String, Decimal> regGeoMapToSlots = new Map<String, Decimal> ();
                    regGeoMapToSlots.put(lstAccounts.get(acId).TERR_HIER_2__c + ' (Region)', 0);
                    accIdToSlot.put(acId, regGeoMapToSlots);
                }
                else if(regToSlot.get(lstAccounts.get(acId).TERR_HIER_1__c + ' (Geography)') == NULL){
                    Map<String, Decimal> regGeoMapToSlots = new Map<String, Decimal> ();
                    regGeoMapToSlots.put(lstAccounts.get(acId).TERR_HIER_1__c + ' (Geography)', 0);
                    accIdToSlot.put(acId, regGeoMapToSlots);
                    
                }else{
                    Map<String, Decimal> regGeoMapToSlots = new Map<String, Decimal> ();
                    regGeoMapToSlots.put(lstAccounts.get(acId).TERR_HIER_2__c + ' (Region)', regToSlot.get(lstAccounts.get(acId).TERR_HIER_2__c + ' (Region)') );
                    regGeoMapToSlots.put(lstAccounts.get(acId).TERR_HIER_1__c + ' (Geography)', regToSlot.get(lstAccounts.get(acId).TERR_HIER_1__c + ' (Geography)') );
                    accIdToSlot.put(acId,regGeoMapToSlots) ; 
                }
            }
        }
        
        return accIdToSlot;
        
    }
    
    
    //method called from before insert/update of Investment Workrequest Trigger to deduct slot based on Account's Region of WorkRequest.
    public void deductSlotForApprovedWRs(List<Investment_Workbox__c> allApprovedWRs, Boolean isInsert) 
    {
        
        List<String> matchingRegions                                      = new List<String>();
        String errorMsg                                                   = '';
        List<Inv_Workbox_Region_Quarter_Mapping__c> allRqMapRecupdate     = new List<Inv_Workbox_Region_Quarter_Mapping__c>();
        Map<String, Inv_Workbox_Region_Quarter_Mapping__c> regionToRQMap  = new Map<String, Inv_Workbox_Region_Quarter_Mapping__c>();
        Decimal totalHourEntered;
        Integer currentQuarter;
        String iwClassification;
        //19.5 Sujay : FFPSA-726
        Set <String> iwYears = new Set <String>();
        //19.5 to store Region TO (Year TO Admin Record)
        Map<String, Map<String,Inv_Workbox_Region_Quarter_Mapping__c>> regionToYearAdminMap = new Map<String, Map<String,Inv_Workbox_Region_Quarter_Mapping__c>>();
        
        System.debug('Inside deductSlotForApprovedWRs::  ');
        for(Investment_Workbox__c wb : allApprovedWRs){
            if( wb.Account__c != NULL && wb.Region__c != NULL ){
                //19.5 adding iwYears set to fetch Admin records 
                iwYears.add(String.valueOf(wb.Submitted_Date__c.Year()));
                //String region = wb.Security__c ? wb.Geo__c + ' ' +'(Geography)' :  wb.Region__c + ' ' +'(Region)';
                String region =  wb.Region__c + ' ' +'(Region)';
                System.debug('region :: ' + region );
                matchingRegions.add(region);
            }
            System.debug('matchingRegions :: ' + matchingRegions);
        }
        
        if(matchingRegions.size() > 0){
            //String currentYear = String.valueOf(Date.Today().Year());
            //19.5 iwYears filter
            //Added changes to fetch values from new fields on IW Admin
            List<Inv_Workbox_Region_Quarter_Mapping__c> allRQMapRecords = [SELECT Id, Region__c, Region1__c, Quarter_1__c, Quarter_2__c, Quarter_3__c, Quarter_4__c, Year__c , 
                                                                                Planned_Hours__c , Product_Platform_Hours__c , UnPlanned_Hours__c , Remaining_Product_Platform_Hours__c,
                                                                                Remaining_Unplanned_Hours__c ,Remaining_Planned_Hours__c
                                                                           FROM Inv_Workbox_Region_Quarter_Mapping__c
                                                                           WHERE Region__r.Name IN: matchingRegions
                                                                           AND Region__r.psa_Old__c = false
                                                                           AND Year__c IN: iwYears
                                                                           AND RecordType.Name = 'Global Services' 
                                                                           for update];
            
            //iterate Admin records and store in Map of Region TO (Year TO Admin Record) - regionToYearAdminMap
            for(Inv_Workbox_Region_Quarter_Mapping__c rqMap : allRQMapRecords){
                if(!regionToYearAdminMap.containsKey(rqMap.Region1__c)){
                    regionToYearAdminMap.put(rqMap.Region1__c,new Map<String,Inv_Workbox_Region_Quarter_Mapping__c> () );
                }
                regionToYearAdminMap.get(rqMap.Region1__c).put(rqMap.Year__c, rqMap);
            }
            System.debug(' regionToYearAdminMap :: '+ regionToYearAdminMap);
        }
        
        for(Investment_Workbox__c newWB : allApprovedWRs) {
            
            currentQuarter = (Integer) Math.ceil( newWB.Submitted_Date__c.Month() / 3.0);
            iwClassification = newWB.IW_Classification__c ;
            //fetching year to the Submitted Request
            String submittedYear = String.valueOf(newWB.Submitted_Date__c.Year());
            System.debug('currentQuarter :: '+ currentQuarter);
            System.debug('request status :: ' + newWB.Status__c);
            //19.6 adding geo/region 
            if(newWB.Region__c != NULL && ( regionToYearAdminMap.containsKey(newWB.Region__c) || regionToYearAdminMap.containsKey(newWB.Geo__c) ) ){
                Decimal QSlot = 0.0;
                switch on iwClassification {
                    when 'Planned Investment' {QSlot = regionToYearAdminMap.get(newWB.Region__c).get(submittedYear).Remaining_Planned_Hours__c;}
                    when 'Unplanned Investment' {QSlot = regionToYearAdminMap.get(newWB.Region__c).get(submittedYear).Remaining_Unplanned_Hours__c;}
                    when else {QSlot = regionToYearAdminMap.get(newWB.Region__c).get(submittedYear).Remaining_Product_Platform_Hours__c;}
                }
                
                System.debug('Utilized in Quarter ' +currentQuarter + ' and QSlot used are =  '+ QSlot);
                
                //20.6 just bypass all the validations for security slots
                if(newWB.LOE_Hours__c != NULL && newWB.LOE_Minutes__c != NULL && ((newWB.LOE_Hours__c + newWB.LOE_Minutes__c/60.0) <= QSlot)) {
                    //Inv_Workbox_Region_Quarter_Mapping__c rqMapRecord = newWB.Security__c ?  regionToYearAdminMap.get(newWB.Geo__c).get(submittedYear) : regionToYearAdminMap.get(newWB.Region__c).get(submittedYear);
                    Inv_Workbox_Region_Quarter_Mapping__c rqMapRecord =  regionToYearAdminMap.get(newWB.Region__c).get(submittedYear);
                    // convert hours and mins to hours units
                    totalHourEntered = newWB.LOE_Hours__c + (newWB.LOE_Minutes__c/60.0);
                    switch on iwClassification {
                        when 'Planned Investment' {rqMapRecord.Remaining_Planned_Hours__c -= totalHourEntered.SetScale(2);}
                        when 'Unplanned Investment' {rqMapRecord.Remaining_Unplanned_Hours__c -= totalHourEntered.SetScale(2);}
                        when else {rqMapRecord.Remaining_Product_Platform_Hours__c -= totalHourEntered.SetScale(2);}
                    }
                    allRqMapRecupdate.add(rqMapRecord);
                    System.debug('rqMapRecord :: '+ rqMapRecord);
                }
                else{
                    //20.6 bypass all security requests validations.
                    // if(!newWB.Security__c)
                    // {
                        
                    // }

                    errorMsg = isInsert ? 'LOE cannot be greater than the Remaining Budget' : 'Slots are not available to Approve the Work Request for this Quarter';
                    newWB.addError(errorMsg);
                }
            }//end of if
            else{
                errorMsg = isInsert ? 'Work request can not be created as their is an invalid region / no region tagged to Work Request\'s Account' : 'Work request can not be Approved as their is an invalid region / no region tagged to Work Request\'s Account';
                newWB.addError(errorMsg);
            }
            
        }
        
        if(allRqMapRecupdate != NULL && allRqMapRecupdate.size() > 0){
            update allRqMapRecupdate;
        }
        
        
    }//end of method deductSlotForApprovedWRs
    
    
    //method called to add canceled hour back to region's Quarter on before update action
    public void addCanceledWRhoursToRegionSlot(List<Investment_Workbox__c> canceledWRs)
    {
        List<String> matchingRegions = new List<String>();
        Map<String, Inv_Workbox_Region_Quarter_Mapping__c> regionToRQMap  = new Map<String, Inv_Workbox_Region_Quarter_Mapping__c>();
        String errorMsg                                                   = '';
        List<Inv_Workbox_Region_Quarter_Mapping__c> allRqMapRecupdate     = new List<Inv_Workbox_Region_Quarter_Mapping__c>();
        Integer currentQuarter;
        //19.5 Sujay : FFPSA-726
        Set <String> iwYears = new Set <String>();
        //19.5 to store Region TO (Year TO Admin Record)
        Map<String, Map<String,Inv_Workbox_Region_Quarter_Mapping__c>> regionToYearAdminMap = new Map<String, Map<String,Inv_Workbox_Region_Quarter_Mapping__c>>();
        
        for(Investment_Workbox__c wb : canceledWRs){
            if( wb.Account__c != NULL && wb.Region__c != NULL ){
                //19.5 adding iwYears set to fetch Admin records 
                iwYears.add(String.valueOf(wb.Submitted_Date__c.Year()));
                //String region = wb.Security__c ?  wb.Geo__c + ' ' +'(Geography)' : wb.Region__c + ' ' +'(Region)';
                String region =  wb.Region__c + ' ' +'(Region)';
                System.debug('region :: ' + region );
                matchingRegions.add(region);
            }
            System.debug('matchingRegions :: ' + matchingRegions);
        }
        
        if(matchingRegions.size() > 0){
            //String currentYear = String.valueOf(Date.Today().Year());
            List<Inv_Workbox_Region_Quarter_Mapping__c> allRQMapRecords = [SELECT Id, Region__c, Region1__c, Quarter_1__c, Quarter_2__c, Quarter_3__c, Quarter_4__c, Year__c,
                                                                           Allocated_for_Quarter_1__c,Allocated_for_Quarter_2__c,Allocated_for_Quarter_3__c,Allocated_for_Quarter_4__c ,
                                                                           Remaining_Planned_Hours__c	, Remaining_Product_Platform_Hours__c , Remaining_Unplanned_Hours__c	
                                                                           FROM Inv_Workbox_Region_Quarter_Mapping__c
                                                                           WHERE Region__r.Name IN: matchingRegions
                                                                           AND Region__r.psa_Old__c = false
                                                                           AND RecordType.Name = 'Global Services'
                                                                           AND Year__c IN: iwYears for update];
            
            System.debug(' allRQMapRecords :: '+ allRQMapRecords);
            //19.5 Iterate Admin records and store in Map of Region TO (Year TO Admin Record) - regionToYearAdminMap
            for(Inv_Workbox_Region_Quarter_Mapping__c rqMap : allRQMapRecords){
                if(!regionToYearAdminMap.containsKey(rqMap.Region1__c)){
                    regionToYearAdminMap.put(rqMap.Region1__c,new Map<String,Inv_Workbox_Region_Quarter_Mapping__c> () );
                }
                regionToYearAdminMap.get(rqMap.Region1__c).put(rqMap.Year__c, rqMap);
            }
            System.debug(' regionToYearAdminMap :: '+ regionToYearAdminMap);
        }
        
        for(Investment_Workbox__c newWB : canceledWRs) {
            
            currentQuarter = (Integer) Math.ceil( newWB.Submitted_Date__c.Month() / 3.0);
            System.debug('currentQuarter :: '+ currentQuarter);
            //fetching year to the Submitted Request
            String submittedYear = String.valueOf(newWB.Submitted_Date__c.Year());
            System.debug('request status :: ' + newWB.Status__c);
            //Added changes for fectching from the new fields on IW Admin 
            if(newWB.Region__c != NULL && ( regionToYearAdminMap.containsKey(newWB.Region__c) || regionToYearAdminMap.containsKey(newWB.Geo__c) )){
                Decimal QSlot = 0.0;
                switch on newWB.IW_Classification__c {
                    when 'Planned Investment' {QSlot = regionToYearAdminMap.get(newWB.Region__c).get(submittedYear).Remaining_Planned_Hours__c;}
                    when 'Unplanned Investment' {QSlot = regionToYearAdminMap.get(newWB.Region__c).get(submittedYear).Remaining_Unplanned_Hours__c;}
                    when else {QSlot = regionToYearAdminMap.get(newWB.Region__c).get(submittedYear).Remaining_Product_Platform_Hours__c;}
                    
                }
                
                System.debug('Utilized in Quarter ' +currentQuarter + ' and QSlot used are =  '+ QSlot);
                
                if(newWB.LOE__c != NULL && newWB.LOE__c > 0)
                {
                    Inv_Workbox_Region_Quarter_Mapping__c rqMapRecord =  regionToYearAdminMap.get(newWB.Region__c).get(submittedYear);
                    // convert hours and mins to hours units
                    switch on newWB.IW_Classification__c {
                        when 'Planned Investment' {rqMapRecord.Remaining_Planned_Hours__c += newWB.LOE__c;}
                        when 'Unplanned Investment' {rqMapRecord.Remaining_Unplanned_Hours__c += newWB.LOE__c;}
                        when else {rqMapRecord.Remaining_Product_Platform_Hours__c += newWB.LOE__c;}
                    }
                    allRqMapRecupdate.add(rqMapRecord);
                    System.debug('rqMapRecord :: '+ rqMapRecord);
                }
                else{
                    errorMsg = 'LOE entered for the Work request is < zero to cancel the WR ';
                    newWB.addError(errorMsg);
                }
            }//end of if
            else{
                errorMsg = 'Work Request can not be Cancelled as their is an invalid region / no region tagged to Work Request\'s Account';
                newWB.addError(errorMsg);
            }
            
        }// end of for Investment_Workbox
        
        if(allRqMapRecupdate != NULL && allRqMapRecupdate.size() > 0){
            update allRqMapRecupdate;
        }
        
        
    }// end of addCanceledWRhoursToRegionSlot
    
    
    //method is being called after insert/update to notify users about the status of WRs
    public void sendEmailNotificationToUsersonStatus(List<Investment_Workbox__c> reqStatusChangedList){
        
        PSA_Common_Setting__mdt commonSetting = [SELECT Id,Value__c,MasterLabel,type__c
                                                 FROM PSA_Common_Setting__mdt
                                                 WHERE type__c = 'IW Send Email notification'];
        //User contct;
        Contact contct;
        String con = '';
        String conEmail = '';
        try{
            System.debug('usr info : ' + UserInfo.getUserId() );
            contct = [SELECT Id, Email FROM Contact WHERE pse__Salesforce_User__c =: UserInfo.getUserId() LIMIT 1];
            con = contct.Id;
            conEmail = contct.Email; 
        }
        catch(Exception e){
            System.debug('Exception While fetching the contact Id');
            con = '0031h00000EddxB';
            conEmail = 'services-engg@akamai.com';
        }
        
        
        String sendEmail = commonSetting.Value__c;
        if(sendEmail.equalsIgnoreCase('yes')){
            System.debug('inside email notify method');
            
            Map<String, String> statusToRequest     = new Map<String, String> ();
            Set<Id> allWRIds = new Set<Id>();
            Set<String> allRrgions = new Set<String>();
            Set<String> allGeos = new Set<String>();
            Set<String> allDivs = new Set<String>();

            Set<String> allAutoGeos = new Set<String>();
            Set<String> allAutoRegs = new Set<String>();
            Map<String, String> AutoApprovalTitleMap = new Map<String, String>();
            List<Inv_WorkBox_Region_Mapping__c> allUserRegion = new List<Inv_WorkBox_Region_Mapping__c> ();

            String fromAddress= '';
            String orgWideEmailId = '';
            List<String> watcherEmailIds = new List<String>();
            //store all wRs with watcher Ids
            Map<Id,List<String>> wRsIdToWatcherId = new Map<Id,List<String>>();
            
            //Query CMD and store in a Map
            for(PSA_Common_Setting__mdt temp: [SELECT Value__c, MasterLabel
                                               FROM PSA_Common_Setting__mdt
                                               WHERE type__c = 'IW_Templete_Holder__mdt']){
                                                   
                                                   if(temp.MasterLabel.contains('Awaiting Email')){
                                                       statusToRequest.put('Awaiting', temp.Value__c);
                                                   }
                                                   else if(temp.MasterLabel.contains('Approved')){
                                                       statusToRequest.put('Approved', temp.Value__c);
                                                   }
                                                   else if(temp.MasterLabel.contains('Rejected')){
                                                       statusToRequest.put('Rejected', temp.Value__c);
                                                   }
                                                   else if(temp.MasterLabel.contains('Escalated Email')){
                                                       statusToRequest.put('Escalated Email', temp.Value__c);
                                                   }
                                                   else if(temp.MasterLabel.contains('Escalated Approver')){
                                                       statusToRequest.put('Escalated Approver', temp.Value__c);
                                                   }
                                                   else if(temp.MasterLabel.contains('Cancelled')){
                                                       statusToRequest.put('Cancelled', temp.Value__c);
                                                   }
                                                   else if(temp.MasterLabel.contains('Awaiting Approver')){
                                                       statusToRequest.put('Awaiting Approver', temp.Value__c);
                                                   }
                                               }
            
            System.debug(' print templ ' + Json.serialize(statusToRequest));
            //IMP : add them to filter to fetch Approvers
            for(Investment_Workbox__c iwb : reqStatusChangedList){
                watcherEmailIds.clear();
                allWRIds.add(iwb.Id);
                allRrgions.add(iwb.Region__c + ' ' +'(Region)');
                allGeos.add(iwb.Geo__c + ' ' +'(Geography)');

                if(iwb.Watchers_Email_Id__c != NULL){
                    watcherEmailIds = iwb.Watchers_Email_Id__c.split(',');
                    if(! wRsIdToWatcherId.containsKey(iwb.Id)){
                        wRsIdToWatcherId.put(iwb.Id, watcherEmailIds);
                        System.debug('wRsIdToWatcherId  Emailssss :::::::::::::::::::::::::::::::: '+ wRsIdToWatcherId.get(iwb.Id));
                    }
                    else{
                        wRsIdToWatcherId.get(iwb.Id).addAll(watcherEmailIds);
                        System.debug('wRsIdToWatcherId  Emailssss:::::::::::::::::::::: '+ wRsIdToWatcherId.get(iwb.Id));
                    }
                }
                if(iwb.Status__c == 'Auto-Approved')
                {
                    allAutoRegs.add(iwb.Region__c + ' ' +'(Region)');
                    allAutoGeos.add(iwb.Geo__c + ' ' +'(Geography)');
                }

            }
            if(approverLevel == NULL || loeCheckToApprovers == NULL || userDivisions == NULL )
            {
                initializeCustomMetadata();
            }
            
            List<String> autoTitles = new List<String>();
            List<String> autoPunPTitles = new List<String>();
            List<String> autoPPTitles = new List<String>();


            for (PSA_Common_Setting__mdt appSetting : [SELECT Id,Value__c, Value_Long__c ,MasterLabel,type__c FROM PSA_Common_Setting__mdt WHERE type__c = 'IW Auto Approval Titles']) {

                AutoApprovalTitleMap.put(appSetting.Value__c , appSetting.Value_Long__c);
                autoTitles.addAll(appSetting.Value_Long__c.split(':') );
                if (appSetting.Value__c == 'PlannedUnPlanned' ) {
                    autoPunPTitles.addAll(appSetting.Value_Long__c.split(':'));
                } else {
                    autoPPTitles.addAll(appSetting.Value_Long__c.split(':'));
                }
            }

            if (allAutoRegs!= null && allAutoRegs!= null && allAutoRegs.size()>0 && allAutoGeos.size() > 0) {


                allUserRegion = [SELECT 
                                Id, User__r.Name, User__r.Title, User__r.Cost_Center__c , TERR_HIER_1_F__c,
                                TERR_HIER_2_F__c, User__c,User__r.Email,RecordType.Name,
                                TERR_HIER_1__r.Name, TERR_HIER_2__r.Name 
                             FROM 
                                Inv_WorkBox_Region_Mapping__c
                             WHERE 
                                User__r.isActive = TRUE
                             AND RecordType.Name = 'Investment Workbox'
                              AND User__r.Division != Null
                             AND User__r.Division IN : userDivisions
                             AND TERR_HIER_1__r.psa_Old__c = false
                             AND (TERR_HIER_2__r.Name IN :allAutoRegs OR TERR_HIER_2_F__c = '*')
                             AND (TERR_HIER_1__r.Name IN :allAutoGeos OR TERR_HIER_1_F__c = '*')
                             AND User__r.Title IN :autoTitles 
                             ];
            }

            System.debug(' oogs apprvs : ' + allUserRegion );

            Map<String , Map<String, String>> regiontoEmail = new Map<String , Map<String, String>>();

            for (Inv_WorkBox_Region_Mapping__c IWRMap : allUserRegion) {
                String geoReg = IWRMap.TERR_HIER_2_F__c+ ' (Region)' + ' ' + IWRMap.TERR_HIER_1_F__c + ' (Geography)' ;
                System.debug('reg or geo : ' + geoReg);
                List<String> emails = new List<String>();
                emails.add(IWRMap.User__r.Email);
                if(!regiontoEmail.containsKey(geoReg))
                {
                    if ( autoPunPTitles.contains(IWRMap.User__r.Title)) {
                        Map<String , String> typetoEmail = new Map<String, String>();
                        typetoEmail.put('PunP', IWRMap.User__r.Email);
                        regiontoEmail.put(geoReg, typetoEmail);
                    } else if( autoPPTitles.contains(IWRMap.User__r.Title) ){
                        Map<String , String> typetoEmail = new Map<String, String>();
                        typetoEmail.put('PP', IWRMap.User__r.Email);
                        regiontoEmail.put(geoReg, typetoEmail);
                    }
                    
                } else {

                    //regiontoEmail.put(geoReg, new Map<String, String>());

                    if ( autoPunPTitles.contains(IWRMap.User__r.Title)) {

                        if( !regiontoEmail.get(geoReg).containsKey('PunP') )
                        {
                            regiontoEmail.get(geoReg).put('PunP', IWRMap.User__r.Email);
                        } else {
                            String emailstr = regiontoEmail.get(geoReg).get('PunP');
                            emailstr = emailstr + ':' + IWRMap.User__r.Email ;
                            regiontoEmail.get(geoReg).put('PunP', emailstr);

                        }

                    } else if (autoPPTitles.contains(IWRMap.User__r.Title)){

                        if( !regiontoEmail.get(geoReg).containsKey('PP') )
                        {
                            regiontoEmail.get(geoReg).put('PP', IWRMap.User__r.Email);
                        } else {
                            String emailstr = regiontoEmail.get(geoReg).get('PP');
                            emailstr = emailstr + ':' + IWRMap.User__r.Email ;
                            regiontoEmail.get(geoReg).put('PP', emailstr);

                        }

                    }

                    
                }
            }

            System.debug(' regiontoEmail :: ' + regiontoEmail);
            
            boolean checkApprover = false;
            Map<Id,Set<String>> WRsToApprovers = new Map<Id,Set<String>>();
            //for setting targetObjectId dynamically for Approvers
            Map<Id, String> wrIdToApprContact = new Map<Id, String>();
            Map<String, String> contEmailToContId = new Map<String, String>();
            
            for(Investment_Workbox__c wr: reqStatusChangedList){
                if((wr.Status__c.equals('Awaiting Approval') || wr.Status__c.equals('Escalated')) && !wr.Orphan_Request__c){
                    System.debug('wr Approver : '+ wr.Approver_List__c);
                    checkApprover = true;
                }
            }
            
            if(checkApprover){
                //get All WRs Approvers
                WRsToApprovers = getWRIdToApproversList(reqStatusChangedList, allRrgions, 'id');
                System.debug('WRsToApprovers values :: '+  WRsToApprovers.values());
                
                for(Id wrId : WRsToApprovers.keySet()){
                    //System.debug('wrId :: '+ wrId + ' :::: WRsToApprovers.get(wrId) :::' + WRsToApprovers.get(wrId) + ' :::::: new List<String>(WRsToApprovers.get(wrId))[0] = '+  new List<String>(WRsToApprovers.get(wrId))[0]);
                    if(WRsToApprovers.containsKey(wrId) && WRsToApprovers.get(wrId).size() > 0 ){
                        String emailUser = (String) new List<String>(WRsToApprovers.get(wrId))[0];
                        System.debug('emailUser :::: ' + emailUser);
                        wrIdToApprContact.put(wrId, emailUser);
                        System.debug('wrIdToApprContact :::: '+ wrIdToApprContact);  
                    }
                }
                
                try{
                    System.debug('Querying Contacts for Approver Emails with wrIdToApprContact :: ' + wrIdToApprContact.values());
                    List<Contact> contApprovers = [SELECT Id,Email,pse__Salesforce_User__c
                                                   FROM Contact 
                                                   WHERE pse__Salesforce_User__c =: wrIdToApprContact.Values()];
                    System.debug('contApprovers :: '+ contApprovers);
                    for(Contact cont : contApprovers){
                        if(cont.pse__Salesforce_User__c != NULL ){
                            contEmailToContId.put(cont.pse__Salesforce_User__c, cont.Id);    
                        } 
                    }
                    System.debug('contEmailToContId :::: ' + contEmailToContId);
                }
                catch(Exception e){
                    System.debug('Exception While fetching the contact Id');
                    con = '0031h00000EddxB';
                    contEmailToContId.put(UserInfo.getUserId(), con);    
                }
            }
            
            
            try{
                PSA_Common_Setting__mdt cs= [SELECT Id, Name__c , Value_Long__c from PSA_Common_Setting__mdt WHERE Name__c = 'FromEmailAdress'];
                fromAddress = cs.Value_Long__c != NULL ? cs.Value_Long__c : 'services-engg@akamai.com';
            }
            catch(Exception e ){
                System.debug('Exception occured in fetching CMD :: ' + e.getMessage());
                fromAddress = 'services-engg@akamai.com';
            }
            
            //add try catch block and use custom metadata
            try{
                orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
            }
            catch(Exception e){
                System.debug('Exception occured while fetching OrWideEmailId in InvWB_Handler :: ' + e.getMessage());
            }
            
            //notify users on the staus og the work req
            List<Messaging.SingleEmailMessage> emailNotifyList = new List<Messaging.SingleEmailMessage>();
            List<Messaging.SingleEmailMessage> approverNotifyList = new List<Messaging.SingleEmailMessage>();
            
            for(Investment_Workbox__c iwb : reqStatusChangedList){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage approverMail;
                List<String> usrEmail = new List<String>();
                List<String> approverEmail = new List<String>();
                System.debug('reqStatusChangedList '+  iwb);
                //System.debug('reqStatusChangedList :::: from future call ? :: '+  System.isFuture());
                if(iwb.Status__c.equals('Saved')){
                    statusToRequest.get('Saved');
                }
                else if(iwb.Status__c.equals('Awaiting Approval')){
                    if(wRsIdToWatcherId.containsKey(iwb.Id)){
                        usrEmail.addAll(wRsIdToWatcherId.get(iwb.Id));
                        mail.setToAddresses(usrEmail);
                        mail.setWhatId(iwb.Id);
                        mail.setTemplateID(statusToRequest.get('Awaiting'));
                    }
                    if(WRsToApprovers.containsKey(iwb.Id)){
                        approverMail = new Messaging.SingleEmailMessage();
                        approverEmail.addAll(WRsToApprovers.get(iwb.Id));
                        System.debug('WRsToApprovers.get(iwb.Id) Approver check' + WRsToApprovers.get(iwb.Id));
                        approverMail.setToAddresses(approverEmail);
                        approverMail.setCcAddresses(new List<String>{conEmail});
                        approverMail.setWhatId(iwb.Id);
                        approverMail.setTemplateID(statusToRequest.get('Awaiting Approver'));
                    }
                }
                //else if(System.isFuture() && (iwb.Status__c.equals('Auto-Approved') || iwb.Status__c.equals('Approved') || iwb.Status__c.equals('Escalate Approved')) ) {
                else if(iwb.Status__c.equals('Auto-Approved') || iwb.Status__c.equals('Approved') || iwb.Status__c.equals('Escalate Approved') ) {
                    if(wRsIdToWatcherId.containsKey(iwb.Id)){
                        usrEmail.addAll(wRsIdToWatcherId.get(iwb.Id));
                    }
                    // getting title and storing user email for IW auto approval notifications
                    System.debug('auto reg checks 1: ' + regiontoEmail.containsKey( iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) );
                    System.debug('auto reg checks 2: ' + regiontoEmail.containsKey( '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) ); 
                    System.debug('auto reg checks 3: ' + regiontoEmail.containsKey( '* (Region)'+ ' ' + '* (Geography)' ) );

                    if (iwb.Status__c.equals('Auto-Approved') && (regiontoEmail.containsKey( iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) 
                                                                ||regiontoEmail.containsKey( '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) 
                                                                ||regiontoEmail.containsKey( '* (Region)'+ ' ' + '* (Geography)' ) )  ) {
                        
                        //usrEmail.addAll(regiontoEmail.get( iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ));
                        //usrEmail.addAll(regiontoEmail.get( '*'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) );
                        //usrEmail.addAll(regiontoEmail.get( '*'+ ' ' + '*' ));
                        System.debug('INNN :' + iwb.IW_Classification__c );
                        if (iwb.IW_Classification__c == 'Product/Platform Work') {
                            System.debug('PP work :');
                            if (regiontoEmail.containsKey( iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) &&  regiontoEmail.get(iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)').containsKey('PP')) {
                                usrEmail.addAll(regiontoEmail.get(iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)').get('PP').split(':') );
                            } 
                            if ( regiontoEmail.containsKey( '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) && regiontoEmail.get( '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ).containsKey('PP') )
                            {
                                usrEmail.addAll(regiontoEmail.get( '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ).get('PP').split(':') );
                            }  
                            if(regiontoEmail.containsKey( '* (Region)'+ ' ' + '* (Geography)' ) && regiontoEmail.get('* (Region)'+ ' ' + '* (Geography)' ).containsKey('PP') ) 
                            {
                                usrEmail.addAll(regiontoEmail.get('* (Region)'+ ' ' + '* (Geography)' ).get('PP').split(':') );
                            }   
                        }
                        else {
                            System.debug(' reg to email : ' + regiontoEmail );
                            System.debug(' not here ? ? ' + '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' );
                            if (regiontoEmail.containsKey( iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) &&  regiontoEmail.get(iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)').containsKey('PunP')) {
                                usrEmail.addAll(regiontoEmail.get(iwb.Region__c + ' ' +'(Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)').get('PunP').split(':') );
                            } 
                            if ( regiontoEmail.containsKey( '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ) && regiontoEmail.get( '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ).containsKey('PunP') )
                            {
                                System.debug('innns :' + usrEmail);
                                usrEmail.addAll(regiontoEmail.get( '* (Region)'+ ' ' + iwb.Geo__c + ' ' +'(Geography)' ).get('PunP').split(':') );
                                System.debug('innns :ltr' + usrEmail);
                            }if(regiontoEmail.containsKey( '* (Region)'+ ' ' + '* (Geography)' ) && regiontoEmail.get('* (Region)'+ ' ' + '* (Geography)' ).containsKey('PunP') ) 
                            {
                                usrEmail.addAll(regiontoEmail.get('* (Region)'+ ' ' + '* (Geography)' ).get('PunP').split(':') );
                            } 

                        }
                    }
                    System.debug('usr email :: ' + usrEmail );
                    mail.setToAddresses(usrEmail);
                    mail.setWhatId(iwb.Id);
                    mail.setTemplateID(statusToRequest.get('Approved'));
                }
                else if(iwb.Status__c.equals('Rejected') || iwb.Status__c.equals('Escalate Reject')){
                    if(wRsIdToWatcherId.containsKey(iwb.Id)){
                        usrEmail.addAll(wRsIdToWatcherId.get(iwb.Id));
                    }
                    mail.setToAddresses(usrEmail);
                    mail.setWhatId(iwb.Id);
                    mail.setTemplateID(statusToRequest.get('Rejected'));
                }
                else if(iwb.Status__c.equals('Escalated')){
                    //send diff emails
                    if(wRsIdToWatcherId.containsKey(iwb.Id)){
                        usrEmail.addAll(wRsIdToWatcherId.get(iwb.Id));
                        mail.setToAddresses(usrEmail);
                        mail.setWhatId(iwb.Id);
                        mail.setTemplateID(statusToRequest.get('Escalated Email'));
                    }
                    if(WRsToApprovers.containsKey(iwb.Id)){
                        approverMail = new Messaging.SingleEmailMessage();
                        approverEmail.addAll(WRsToApprovers.get(iwb.Id));
                        approverMail.setToAddresses(approverEmail);
                        approverMail.setCcAddresses(new List<String>{conEmail});
                        approverMail.setWhatId(iwb.Id);
                        approverMail.setTemplateID(statusToRequest.get('Escalated Approver'));
                    }
                    
                }
                else if(iwb.Status__c.equals('Cancelled')){
                    if(wRsIdToWatcherId.containsKey(iwb.Id)){
                        usrEmail.addAll(wRsIdToWatcherId.get(iwb.Id));
                    }
                    mail.setToAddresses(usrEmail);
                    mail.setWhatId(iwb.Id);
                    mail.setTemplateID(statusToRequest.get('Cancelled'));
                }
                //set this Id in QA and Prod Properly.
                mail.setTargetObjectId(con);
                System.debug(' con set :: ' + con);
                mail.setSaveAsActivity(false);
                mail.setOrgWideEmailAddressId(orgWideEmailId);
                emailNotifyList.add(mail);
                
                if(approverMail != NULL ){
                    String targetObjId = contEmailToContId.get(wrIdToApprContact.get(iwb.Id)) != NULL ? contEmailToContId.get(wrIdToApprContact.get(iwb.Id)) : con ;
                    System.debug('targetObjId :::::: ' + targetObjId);
                    approverMail.setTargetObjectId(targetObjId);
                    approverMail.setSaveAsActivity(false);
                    approverMail.setOrgWideEmailAddressId(orgWideEmailId);
                    approverNotifyList.add(approverMail);    
                }
                System.debug('approverMail :: '+ approverMail);
                System.debug('mail :: '+ mail);
                
            }//end of for loop
            System.debug('emailNotifyList :: ' + emailNotifyList);
            try{
                if(emailNotifyList != NULL && emailNotifyList.size() > 0){
                    Messaging.sendEmail(emailNotifyList,true);
                }
                if(approverNotifyList !=  NULL && approverNotifyList.size() > 0){
                    Messaging.sendEmail(approverNotifyList,true);
                }
            }
            catch(Exception e){
                String str = System.Url.getSalesforceBaseURL().toExternalForm();
                System.debug('Exception while sending email :: ' + e.getMessage());
                PSA_AutoCreateProjectUtil.sendErrorMails('Error:IW Send Email Notify (Class:InvWB_Handler), ', str +'\n' +e.getMessage() + '\n emailNotifyList : ' + emailNotifyList + '\n approverNotifyList :' + approverNotifyList);
            }
            
        }
        
    }
    
    
    public void stampApprovers(List<Investment_Workbox__c> submittedWRs){
        
        System.debug('submittedWRs ::: ' +  submittedWRs);
        Set<String> allRrgions = new Set<String>();
        Set<String> allGeos = new Set<String>();
        Set<String> allDivs = new Set<String>();
        
        for(Investment_Workbox__c iwb : submittedWRs){
            allRrgions.add(iwb.Region__c + ' ' +'(Region)');
            allGeos.add(iwb.Geo__c + ' ' +'(Geography)');

        }
        Map<Id,Set<String>> approverList = getWRIdToApproversList(submittedWRs, allRrgions, 'Id' );
        System.debug('submittedWRs ::: ' +  approverList);
        if(approverList.keySet() != NULL){
            List<String> approvers = new List<String>();
            for(Investment_Workbox__c iwb : submittedWRs){
                System.debug('submittedWRs ::: ' +  iwb);
                if(approverList.containsKey(iwb.Id) && !iwb.Orphan_Request__c ){
                    System.debug(' he is an Approver ::: ' +  iwb);
                    System.debug('approverList.containsKey(iwb.Id) :: '+  approverList.get(iwb.Id));
                    approvers.clear();
                    approvers.addAll(approverList.get(iwb.Id));
                    String allApprovers = string.join(approvers,',').left(255);
                    iwb.Approver_List__c = '';
                    iwb.All_Approvers__c = '';
                    System.debug(' iwb.Approver_List__c ' +  iwb.All_Approvers__c );
                    System.debug(' iwb.All_Approvers__c  ' +  iwb.All_Approvers__c );
                    iwb.Approver_List__c = allApprovers;
                    iwb.All_Approvers__c = string.join(approvers,',');
                    System.debug(' iwb.Approver_List__c ' +  iwb.All_Approvers__c );
                    System.debug(' iwb.All_Approvers__c  ' +  iwb.All_Approvers__c );
                    allApprovers = '';
                }
            }
        }
        
    }
    
    
    //take WRs and store List of Approvers w.r.t the WRs.
    //IMP :Add Geo and Div Filter to reduce the load on Query
    public Map<Id,Set<String>> getWRIdToApproversList(List<Investment_Workbox__c> invWRs, Set<String> allRegions, String emailORusrId){
        
        Set<String> allDivs = new Set<String>();
        Set<String> allGeos = new Set<String>();
        for(Investment_Workbox__c iwb : invWRs)
        {

            allGeos.add(iwb.Geo__c + ' '+ '(Geography)');

            System.debug('Geo ' + iwb.Geo__c);
            System.debug('Region :: ' + iwb.Region__c);
        }

        if(approverLevel == NULL || loeCheckToApprovers == NULL || userDivisions == NULL )
        {
            initializeCustomMetadata();
        }
        
        Map<Id, Set<String>> wRsToApproverList = new Map<Id,Set<String>>();
        System.debug('wRsToApproverList creating instance :: ' + wRsToApproverList);
        List<Inv_WorkBox_Region_Mapping__c> allUserRegion = new List<Inv_WorkBox_Region_Mapping__c> ();

        System.debug('all regions : ' + allRegions + ' all geos :: ' + allGeos + ' all devs :: ' + userDivisions );
        //19.4 Adding Recordtype Filters
        if(!Test.isRunningTest()) 
        {
            allUserRegion = [SELECT 
                                Id, User__r.Name, User__r.Title, User__r.Cost_Center__c , TERR_HIER_1_F__c,
                                TERR_HIER_2_F__c, User__c,User__r.Email,RecordType.Name,
                                TERR_HIER_1__r.Name, TERR_HIER_2__r.Name 
                             FROM 
                                Inv_WorkBox_Region_Mapping__c
                             WHERE 
                                User__r.isActive = TRUE
                             AND RecordType.Name = 'Investment Workbox'
                             AND User__r.Division != null
                             AND User__r.Division IN : userDivisions
                             AND TERR_HIER_1__r.psa_Old__c = false
                             AND (TERR_HIER_2__r.Name IN :allRegions OR TERR_HIER_2_F__c = '*')
                             AND (TERR_HIER_1__r.Name IN :allGeos OR TERR_HIER_1_F__c = '*')];
        }
        else
        {
            System.debug('TestClass Execution'  );
            allUserRegion = [SELECT Id, User__r.Name, User__r.Title, User__r.Cost_Center__c , TERR_HIER_1_F__c,
                             TERR_HIER_2_F__c, User__c,User__r.Email,RecordType.Name,
                             TERR_HIER_1__r.Name, TERR_HIER_2__r.Name
                             FROM Inv_WorkBox_Region_Mapping__c
                             WHERE 
                             RecordType.Name = 'Investment Workbox'
                            ];
            
        }
        //System.debug('allUserRegion :: '+ allUserRegion);
        System.debug('allUserRegionsize()  ::' + allUserRegion);
        System.debug('allUserRegionsize()  ::' + allUserRegion.size());
        
        Map<String, List<Inv_WorkBox_Region_Mapping__c>> regionTourMap = new Map<String, List<Inv_WorkBox_Region_Mapping__c>>();
        
        if(allUserRegion != NULL && allUserRegion.size() > 0)
        {
            for(Inv_WorkBox_Region_Mapping__c urMap : allUserRegion)
            {
                if(!regionTourMap.containsKey(urMap.TERR_HIER_2_F__c))
                {
                    regionTourMap.put(urMap.TERR_HIER_2_F__c, new List<Inv_WorkBox_Region_Mapping__c>{urMap});
                    //System.debug('regionTourMap first time :: ' +regionTourMap );
                    //System.debug('Region Inside If :: ' + urMap.TERR_HIER_2_F__c);
                }
                else
                {
                    regionTourMap.get(urMap.TERR_HIER_2_F__c).add(urMap);
                    //System.debug('regionTourMap second time :: '+ regionTourMap);
                }
            }
            
            System.debug('regionTourMap :: ' + regionTourMap);
            
            
            
            System.debug('approverLevel ::: ' + approverLevel);
            Set<String> uIds = new Set<String>();
            Set<String> usrEmail = new Set<String>();
            Decimal LOEHours = 0.0;
            
            
            for(Investment_Workbox__c iw : invWRs)
            {
                LOEHours = iw.LOE_Hours__c + iw.LOE_Minutes__c/60.0;
                //System.debug('check LOEHours :: '+ LOEHours);
                usrEmail = new Set<String>();
                uIds = new Set<String>();
                
                if(regionTourMap.containsKey(iw.Region__c) || regionTourMap.containsKey('*'))
                {
                    List<Inv_WorkBox_Region_Mapping__c> mergeAll = regionTourMap.containsKey(iw.Region__c) ? regionTourMap.get(iw.Region__c) : new List<Inv_WorkBox_Region_Mapping__c>();
                    //mergeAll = regionTourMap.containsKey('*') ? mergeAll.addAll(regionTourMap.get('*')) : mergeAll;
                    if(regionTourMap.containsKey('*'))
                    {
                        mergeAll.addAll(regionTourMap.get('*'));
                    }
                    //System.debug('mergeAll :: ' + mergeAll.size());
                    for(Inv_WorkBox_Region_Mapping__c urMap : mergeAll)
                    {
                        if(urMap.User__r.Title != NULL && urMap.User__r.Cost_Center__c != null)
                        {
                            System.debug('urMap' + urMap);
                            System.debug('IW' + iw);
                            if((urMap.TERR_HIER_2_F__c.equals(iw.Region__c) || urMap.TERR_HIER_2_F__c.equals('*')) && (urMap.TERR_HIER_1_F__c.equals(iw.Geo__c) || urMap.TERR_HIER_1_F__c.equals('*')) )
                            {
                                String clasiftn = (iw.IW_Classification__c == 'Product/Platform Work') ? 'PP' : 'PunP' ;
                                getUserIdnEmails(clasiftn,uIds,usrEmail, LOEHours, iw , urMap);
                            }
                        }
                        
                    }// end of loop urmap
                    
                }// end of regionTourMap check
                
                if(!wRsToApproverList.containsKey(iw.Id))
                {
                    if('email'.equalsIgnoreCase(emailORusrId) )
                    {
                        wRsToApproverList.put(iw.Id, usrEmail);
                    } else if('id'.equalsIgnoreCase(emailORusrId))
                    {
                        wRsToApproverList.put(iw.Id, uIds);
                    }
                    System.debug('James :: loading data :: '+iw.Id + ' ' +wRsToApproverList );
                }
                
            }// end of iw loop
            
        }// end of allUserRegion check
        
        System.debug('wRsToApproverList :: ' + wRsToApproverList);
        return wRsToApproverList;
        
    }
    
    // Genric  function to get list of users for particular type of Investment work since the routing for both IW type is similar
    public void getUserIdnEmails(String classificationStr,Set<String> uIds, Set<String> usrEmail, Decimal LOEHours,Investment_Workbox__c iw,Inv_WorkBox_Region_Mapping__c urMap )
    {

        if( LOEHours > loeCheckToApprovers.get('4To40'+classificationStr).LOE_Low_Limts__c && LOEHours <= loeCheckToApprovers.get('4To40'+classificationStr).LOE_High_Limit__c) 
        {
            System.debug('inside 4To40 LOE ::');
            if( (!iw.Escalated__c && ( approverLevel.get('4To40'+classificationStr).get('flApp'+classificationStr).contains(urMap.User__r.Title)  )   ) )
                {
                    uIds.add(urMap.User__c);
                    if( approverLevel.get('4To40'+classificationStr).get('flApp'+classificationStr).contains(urMap.User__r.Title) )
                    {
                        System.debug('IN 1');
                        System.debug('ckhs vlass : ' + approverLevel.get('4To40'+classificationStr).get('flApp'+classificationStr) + 'user :: ' +urMap.User__r.Title );
                        System.debug('user Name : ' + urMap.User__r.Name);
                        usrEmail.add(urMap.User__r.Email);
                    }
                } 
            else if( iw.Escalated__c &&   ( approverLevel.get('4To40'+classificationStr).get('flApp'+classificationStr+'Esc').contains(urMap.User__r.Title) )  )
            {
                uIds.add(urMap.User__c);
                if( approverLevel.get('4To40'+classificationStr).get('flApp'+classificationStr+'Esc').contains(urMap.User__r.Title) )
                {
                    System.debug('IN 2');
                    usrEmail.add(urMap.User__r.Email);
                }
            }
        }
        else if( LOEHours > loeCheckToApprovers.get('40To80'+classificationStr).LOE_Low_Limts__c && LOEHours <= loeCheckToApprovers.get('40To80'+classificationStr).LOE_High_Limit__c)  
        {
            System.debug('inside 40To80 LOE ::');
            if( (!iw.Escalated__c && ( approverLevel.get('40To80'+classificationStr).get('flApp'+classificationStr).contains(urMap.User__r.Title)  )   ) )
            {
                uIds.add(urMap.User__c);
                if( approverLevel.get('40To80'+classificationStr).get('flApp'+classificationStr).contains(urMap.User__r.Title) )
                {
                    System.debug('IN 3');
                    usrEmail.add(urMap.User__r.Email);
                }
            } 
            else if( iw.Escalated__c &&   ( approverLevel.get('40To80'+classificationStr).get('flApp'+classificationStr+'Esc').contains(urMap.User__r.Title)  )  )
            {
                uIds.add(urMap.User__c);
                if( approverLevel.get('40To80'+classificationStr).get('flApp'+classificationStr+'Esc').contains(urMap.User__r.Title) )
                {
                    System.debug('IN 4');
                    usrEmail.add(urMap.User__r.Email);
                }
            }
            
        }
        else if (LOEHours > loeCheckToApprovers.get('80'+classificationStr).LOE_Low_Limts__c)
        {
            System.debug('inside >80 LOE ::');
            if( (!iw.Escalated__c && ( approverLevel.get('80'+classificationStr).get('flApp'+classificationStr).contains(urMap.User__r.Title) )   ) )
            {
                uIds.add(urMap.User__c);
                if( approverLevel.get('80'+classificationStr).get('flApp'+classificationStr).contains(urMap.User__r.Title) )
                {
                    System.debug('IN 5');
                    usrEmail.add(urMap.User__r.Email);
                }
            } 
            else if( iw.Escalated__c &&   ( approverLevel.get('80'+classificationStr).get('flApp'+classificationStr+'Esc').contains(urMap.User__r.Title)  )  )
            {
                uIds.add(urMap.User__c);
                if( approverLevel.get('80'+classificationStr).get('flApp'+classificationStr+'Esc').contains(urMap.User__r.Title) )
                {
                    System.debug('IN 6');
                    usrEmail.add(urMap.User__r.Email);
                }
            }
        }

    }
    
    
    //if loggedIn User is Creator of the record returns list of buttons
    public List<String> loggedInuserIscreator(Investment_Workbox__c iw)
    {
        List<String> buttons = new List<String>();
        
        System.debug('CreatedById ====== loggedInUsr');
        buttons.add('eligible');
        if(iw.Status__c.equals('Saved')){
            buttons.add('Submit');
        }
        else if(iw.Status__c.equals('Awaiting Approval')){
            buttons.add('Cancel');
            // 19.10.2 - Adding Escalate button for the creator of the IW Req
            buttons.add('Escalate');
        }
        else if(iw.Status__c.equals('Escalated')){
            buttons.add('Cancel');
        }
        else if(iw.Status__c.equals('Approved') || iw.Status__c.equals('Escalate Approved') || iw.Status__c.equals('Auto Approved')){
            buttons.add('Cancel');
        }
        return buttons;
    }
    
    
    //routing logic that returs buttons for Orphan Queue
    public List<String> orphanRequestButtons(Investment_Workbox__c iw, String usrTitle)
    {
        //Map<Id,List<String>> wrIdToOrphanbuttons = new Map<Id,List<String>>();
        List<String> buttons = new List<String>();
        //wrIdToOrphanbuttons.put(iw.Id, buttons);
        
        //if Logged in user is an Approver from Orphan Queue.
        if(iw.Orphan_Request__c)
        {
            System.debug('loggedInUsr is an Approver for Orphan Queue');
            buttons.add('eligible');
            System.debug('initiliazing Buttons for non Orphan Approvers ::');
            if(approverLevel == NULL || loeCheckToApprovers == NULL)
            {
                initializeCustomMetadata();
            }
            String iwClasificatnStr = iw.IW_Classification__c == 'Product/Platform Work' ? 'PP' : 'PunP';
            
            if(iw.LOE__c > loeCheckToApprovers.get('4To40'+iwClasificatnStr).LOE_Low_Limts__c && iw.LOE__c <= loeCheckToApprovers.get('4To40'+iwClasificatnStr).LOE_High_Limit__c){
                   if(!iw.Escalated__c && ( approverLevel.get('4To40'+iwClasificatnStr).get('flApp'+iwClasificatnStr).contains(usrTitle) || approverLevel.get('40To80'+iwClasificatnStr).get('flApp'+iwClasificatnStr).contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('flApp'+iwClasificatnStr).contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('secApp'+iwClasificatnStr).contains(usrTitle) ) )
                   {
                       if(iw.Status__c.equals('Awaiting Approval')){
                           buttons.add('Approve');
                           buttons.add('Reject');
                           buttons.add('Escalate');
                           //buttons.add('Cancel');
                           System.debug('Buttons when not escalated in Orhan 40 -80 :: ' + buttons);
                       }
                       else if(iw.Status__c.equals('Auto-Approved') || iw.Status__c.equals('Approved')){
                           //buttons.add('Cancel');
                       }
                   }
                   else if(iw.Escalated__c && ( approverLevel.get('40To80'+iwClasificatnStr).get('secApp'+iwClasificatnStr+'Esc').contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('flApp'+iwClasificatnStr+'Esc').contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('secApp'+iwClasificatnStr+'Esc').contains(usrTitle) ) )  
                   {
                       if(iw.Status__c.equals('Escalated')){
                           buttons.add('Approve');
                           buttons.add('Reject');
                           //buttons.add('Cancel');
                           System.debug('Buttons when escalated in orphan:: ' + buttons);
                       }
                       else if(iw.Status__c.equals('Escalate Approved')){
                           //buttons.add('Cancel');
                       }
                   }
               }
            else if(iw.LOE__c > loeCheckToApprovers.get('40To80'+iwClasificatnStr).LOE_Low_Limts__c && iw.LOE__c <= loeCheckToApprovers.get('40To80'+iwClasificatnStr).LOE_High_Limit__c)
            {
                    if(!iw.Escalated__c && ( approverLevel.get('40To80'+iwClasificatnStr).get('flApp'+iwClasificatnStr).contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('flApp'+iwClasificatnStr).contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('secApp'+iwClasificatnStr).contains(usrTitle) ) )
                    {
                            if(iw.Status__c.equals('Awaiting Approval')){
                                buttons.add('Approve');
                                buttons.add('Reject');
                                buttons.add('Escalate');
                                //buttons.add('Cancel');
                                System.debug('Buttons when not escalated in Orhan 40 -80 :: ' + buttons);
                            }
                            else if(iw.Status__c.equals('Auto-Approved') || iw.Status__c.equals('Approved')){
                                //buttons.add('Cancel');
                            }
                        }else if(iw.Escalated__c && (  approverLevel.get('40To80'+iwClasificatnStr).get('secApp'+iwClasificatnStr+'Esc').contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('flApp'+iwClasificatnStr+'Esc').contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('secApp'+iwClasificatnStr+'Esc').contains(usrTitle) ) )  {
                            if(iw.Status__c.equals('Escalated')){
                                buttons.add('Approve');
                                buttons.add('Reject');
                                //buttons.add('Cancel');
                                System.debug('Buttons when escalated in orphan:: ' + buttons);
                            }
                            else if(iw.Status__c.equals('Escalate Approved')){
                                //buttons.add('Cancel');
                            }
                        }
                    }
            else if (iw.LOE__c > loeCheckToApprovers.get('80'+iwClasificatnStr).LOE_Low_Limts__c){
                //check for VP and SVP names again
                if(!iw.Escalated__c && ( approverLevel.get('80'+iwClasificatnStr).get('flApp'+iwClasificatnStr).contains(usrTitle) || approverLevel.get('80'+iwClasificatnStr).get('secApp'+iwClasificatnStr).contains(usrTitle) ) ){
                    if(iw.Status__c.equals('Awaiting Approval')){
                        buttons.add('Approve');
                        buttons.add('Reject');
                        buttons.add('Escalate');
                        //buttons.add('Cancel');
                        System.debug('Buttons when not escalated in Orhan 40 -80 :: ' + buttons);
                    }
                    else if(iw.Status__c.equals('Auto-Approved') || iw.Status__c.equals('Approved')){
                        //buttons.add('Cancel');
                    }
                }else if (iw.Escalated__c &&  approverLevel.get('80'+iwClasificatnStr+'Esc').get('secApp'+iwClasificatnStr+'Esc').contains(usrTitle) ) {
                    if(iw.Status__c.equals('Escalated')){
                        buttons.add('Approve');
                        buttons.add('Reject');
                        //buttons.add('Cancel');
                        System.debug('Buttons when escalated in orphan:: ' + buttons);
                    }
                    else if(iw.Status__c.equals('Escalate Approved')){
                        //buttons.add('Cancel');
                    }
                }
            }
            //wrIdToOrphanbuttons.put(iw.Id, buttons);
        }
        
        return buttons;
    }
    
    
    //Logged in user is one of the Approver return buttons.
    public List<String> loggedInUserApproverButtons(Investment_Workbox__c iw, String usrTitle , String usrCostCenter )
    {
        List<String> buttons = new List<String>();
        
        System.debug('loggedInUsr is an Approver for non Orphan Queue');
        System.debug('iw loe :' + iw.LOE__c + ' status :' + iw.status__c );
        buttons.add('eligible');
        System.debug('initiliazing Buttons for non Orphan Approvers ::');
        if(approverLevel == NULL || loeCheckToApprovers == NULL)
        {
            initializeCustomMetadata();
        }
        String iwClassftn = iw.IW_Classification__c == 'Product/Platform Work' ? 'PP' : 'PunP';
        // check if slots are security/discrete limits 4-40
        // Check the type of IW and Slot of IW and fetch dynamillay the title of users for the type of IW
        if( (iw.LOE__c > loeCheckToApprovers.get('4To40'+iwClassftn).LOE_Low_Limts__c && iw.LOE__c <= loeCheckToApprovers.get('4To40'+iwClassftn).LOE_High_Limit__c) )
        {
               if( (  ( approverLevel.get('4To40'+iwClassftn).get('flApp'+iwClassftn).contains(usrTitle) || approverLevel.get('4To40'+iwClassftn).get('secApp'+iwClassftn).contains(usrTitle)
                                        || approverLevel.get('4To40'+iwClassftn).get('flApp'+iwClassftn+'Esc').contains(usrTitle) || approverLevel.get('4To40'+iwClassftn).get('secApp'+iwClassftn+'Esc').contains(usrTitle)
                                        || approverLevel.get('40To80'+iwClassftn).get('flApp'+iwClassftn).contains(usrTitle) ||  approverLevel.get('40To80'+iwClassftn).get('secApp'+iwClassftn).contains(usrTitle)
                                        || approverLevel.get('40To80'+iwClassftn).get('flApp'+iwClassftn+'Esc').contains(usrTitle) ||  approverLevel.get('40To80'+iwClassftn).get('secApp'+iwClassftn+'Esc').contains(usrTitle)
                                        || approverLevel.get('80'+iwClassftn).get('flApp'+iwClassftn).contains(usrTitle) || approverLevel.get('80'+iwClassftn).get('secApp'+iwClassftn).contains(usrTitle)
                                        || approverLevel.get('80'+iwClassftn).get('flApp'+iwClassftn+'Esc').contains(usrTitle) || approverLevel.get('80'+iwClassftn).get('secApp'+iwClassftn+'Esc').contains(usrTitle)
                                        ) )  )
               {
                   if(iw.Status__c.equals('Awaiting Approval')|| iw.Status__c.equals('Escalated')){
                       buttons.add('Approve');
                       buttons.add('Reject');
                       buttons.add('Escalate');
                       //buttons.add('Cancel');
                       System.debug('Buttons when not escalated in Orhan 40 -80 :: ' + buttons);
                   }
                   else if(iw.Status__c.equals('Auto-Approved') || iw.Status__c.equals('Approved')){
                       //buttons.add('Cancel');
                   }
               }
            //    else if(iw.Escalated__c && ( ( approverLevel.get('4To40').get('flApp'+iwClassftn+'Esc').contains(usrTitle) || approverLevel.get('4To40').get('secApp'+iwClassftn+'Esc').contains(usrTitle) || approverLevel.get('80').get('flApp').contains(usrTitle) || approverLevel.get('80').get('secApp').contains(usrTitle) ))  )  
            //    {
            //        if(iw.Status__c.equals('Escalated')){
            //            buttons.add('Approve');
            //            buttons.add('Reject');
            //            //buttons.add('Cancel');
            //            System.debug('Buttons when escalated in orphan:: ' + buttons);
            //        }
            //        else if(iw.Status__c.equals('Escalate Approved')){
            //            //buttons.add('Cancel');
            //        }
            //    }
        }
        // check if slots are security/discrete limits 40-80
        else if((iw.LOE__c > loeCheckToApprovers.get('40To80').LOE_Low_Limts__c && iw.LOE__c <= loeCheckToApprovers.get('40To80').LOE_High_Limit__c))
        {
            System.debug('din reach here ? ' );
            
            System.debug('din reach here log cond? ' + (approverLevel.get('40To80'+iwClassftn).get('flApp'+iwClassftn).contains(usrTitle) ||  approverLevel.get('40To80'+iwClassftn).get('secApp'+iwClassftn).contains(usrTitle)
            || approverLevel.get('40To80'+iwClassftn).get('flApp'+iwClassftn+'Esc').contains(usrTitle) ||  approverLevel.get('40To80'+iwClassftn).get('secApp'+iwClassftn+'Esc').contains(usrTitle)
            || approverLevel.get('80'+iwClassftn).get('flApp'+iwClassftn).contains(usrTitle) || approverLevel.get('80'+iwClassftn).get('secApp'+iwClassftn).contains(usrTitle)
            || approverLevel.get('80'+iwClassftn).get('flApp'+iwClassftn+'Esc').contains(usrTitle) || approverLevel.get('80'+iwClassftn).get('secApp'+iwClassftn+'Esc').contains(usrTitle) )  );


                  if(approverLevel.get('40To80'+iwClassftn).get('flApp'+iwClassftn).contains(usrTitle) ||  approverLevel.get('40To80'+iwClassftn).get('secApp'+iwClassftn).contains(usrTitle)
                  || approverLevel.get('40To80'+iwClassftn).get('flApp'+iwClassftn+'Esc').contains(usrTitle) ||  approverLevel.get('40To80'+iwClassftn).get('secApp'+iwClassftn+'Esc').contains(usrTitle)
                  || approverLevel.get('80'+iwClassftn).get('flApp'+iwClassftn).contains(usrTitle) || approverLevel.get('80'+iwClassftn).get('secApp'+iwClassftn).contains(usrTitle)
                  || approverLevel.get('80'+iwClassftn).get('flApp'+iwClassftn+'Esc').contains(usrTitle) || approverLevel.get('80'+iwClassftn).get('secApp'+iwClassftn+'Esc').contains(usrTitle) )
                  {
                        if(iw.Status__c.equals('Awaiting Approval') || iw.Status__c.equals('Escalated')  ){
                            buttons.add('Approve');
                            buttons.add('Reject');
                            buttons.add('Escalate');
                            //buttons.add('Cancel');
                            System.debug('Buttons when not escalated in Orhan 40 -80 :: ' + buttons);
                        }
                        else if(iw.Status__c.equals('Auto-Approved') || iw.Status__c.equals('Approved')){
                            //buttons.add('Cancel');
                        }
                   }
                //   else if(iw.Escalated__c && (  (approverLevel.get('40To80').get('secApp').contains(usrTitle) ||  approverLevel.get('80').get('secApp').contains(usrTitle) ) ) )  
                //   {
                //         if(iw.Status__c.equals('Escalated')){
                //             buttons.add('Approve');
                //             buttons.add('Reject');
                //             //buttons.add('Cancel');
                //             System.debug('Buttons when escalated in orphan:: ' + buttons);
                //         }
                //         else if(iw.Status__c.equals('Escalate Approved')){
                //             //buttons.add('Cancel');
                //         }
                //    }
        }
        // check if slots are security/discrete limits > 80
        else if (iw.LOE__c > loeCheckToApprovers.get('80').LOE_Low_Limts__c )
        {
            //check for VP and SVP names again
            if(approverLevel.get('80'+iwClassftn).get('flApp'+iwClassftn).contains(usrTitle) || approverLevel.get('80'+iwClassftn).get('secApp'+iwClassftn).contains(usrTitle)
            || approverLevel.get('80'+iwClassftn).get('flApp'+iwClassftn+'Esc').contains(usrTitle) || approverLevel.get('80'+iwClassftn).get('secApp'+iwClassftn+'Esc').contains(usrTitle))
            {
                if(iw.Status__c.equals('Awaiting Approval')|| iw.Status__c.equals('Escalated')){
                    buttons.add('Approve');
                    buttons.add('Reject');
                    buttons.add('Escalate');
                    //buttons.add('Cancel');
                    System.debug('Buttons when not escalated in Orhan 40 -80 :: ' + buttons);
                }
                else if(iw.Status__c.equals('Auto-Approved') || iw.Status__c.equals('Approved')){
                    //buttons.add('Cancel');
                }
            }
            // else if (iw.Escalated__c && ( (approverLevel.get('80').get('secApp').contains(usrTitle) )  ) ) 
            // {
            //     if(iw.Status__c.equals('Escalated')){
            //         buttons.add('Approve');
            //         buttons.add('Reject');
            //         //buttons.add('Cancel');
            //         System.debug('Buttons when escalated in orphan:: ' + buttons);
            //     }
            //     else if(iw.Status__c.equals('Escalate Approved')){
            //         //buttons.add('Cancel');
            //     }
            // }
        }
        return buttons;
    }
    
    
    //this Method is called from trigger to validate if a person who is trying to make changes on IW can do it or not
    public Map<Id, Set<String>> accessToWR(List<Investment_Workbox__c> invWRs)
    {    
        //stores button access to each and every inidividual request.
        Map<Id, Set<String>> wrIdToButtons = new Map<Id, Set<String>>();
        
        User usrRec;
        String usrTitle = '';
        String usrCostCenter = '';
        //set all WrId to ApproverIds
        Map<Id,Set<String>> getAllApproversForWR = new Map<Id,Set<String>> ();
        //set all WrId to OrphanRequest access
        Map<Id,Set<String>> getAppApproverOrphan = new Map<Id,Set<String>> ();
        //to add butons available to user and the workrequest
        Set<String> allButtons = new Set<String>();
        //to store all wr regions
        Set<String> regions = new Set<String>();
        List<Investment_Workbox__c> requestWithApprovers = new List<Investment_Workbox__c>();
        List<Investment_Workbox__c> orphanRequests = new List<Investment_Workbox__c>();
        
        if(usrRec == NULL ){
            usrRec = loggedInUserDetails; 
            //usrTitle = setTitle(usrRec.Title);
            usrTitle = usrRec.Title;
            usrCostCenter = loggedInUserDetails.Cost_Center__c == null ? '0' : String.valueOf(loggedInUserDetails.Cost_Center__c);
        }
        
        for(Investment_Workbox__c workReq : invWRs){
            if(!workReq.Orphan_Request__c){
                regions.add(workReq.Region__c + ' ' +'(Region)');
                requestWithApprovers.add(workReq);
            }
            else{
                orphanRequests.add(workReq);
            }
        }
        
        //getAllApproversForWR = getWRIdToApproversList(requestWithApprovers, regions, 'Id');
        //to store all valid users against the IW req's DGR from GSS User Region based on their title and cost center
        getAllApproversForWR = getAllRegionApprovers(requestWithApprovers);
        for(Investment_Workbox__c workReq : invWRs){
            
            //if loggedIn User is Creator of the record
            if(workReq.CreatedById == UserInfo.getUserId() && workReq.Legacy_Data__c != 'Workbox'){
                allButtons.addAll(loggedInuserIscreator(workReq));
            }
            
            //loggedInUser is one of the Approver()
            if(!workReq.Orphan_Request__c && getAllApproversForWR.containsKey(workReq.Id) && getAllApproversForWR.get(workReq.Id).contains(UserInfo.getUserId())){
                allButtons.addAll(loggedInUserApproverButtons(workReq, usrTitle, usrCostCenter));
            }
            
            //if Logged in user is an Approver from Orphan Queue.
            if(workReq.Orphan_Request__c){
                allButtons.addAll(orphanRequestButtons(workReq, usrTitle));
                System.debug('allButtons: :: :: ::  :from Orphan request :::: ' + allButtons);
            }
            wrIdToButtons.put(workReq.Id, allButtons);
        }
        
        return wrIdToButtons;
    }
    
    /*//to set title for VPs, SVPs, EVPs
    public String setTitle(String uTitle){
        String usrTitle = uTitle;
        if(usrTitle.startsWith('Vice')){
            usrTitle = 'Vice President';
        }else if(usrTitle.containsIgnoreCase('Senior Vice President')){
            usrTitle = 'Senior Vice President';
        }else if(usrTitle.containsIgnoreCase('Executive Vice President')){
            usrTitle = 'Executive Vice President';
        }else{
            usrTitle = usrTitle;
        }
        return usrTitle;
    }*/
    
    
    //method to check if a logged In user has access to take actions on WR from the create/modify component.
    public List<String> getApproverListOfWR(Investment_Workbox__c iw, Id loggedInUsr){
        //boolean usr = false;
        User usrRec;
        String usrTitle = '';
        String usrCostCenter = '';
        Map<Id,Set<String>> getAllApproversForWR = new Map<Id,Set<String>> ();
        Map<Id,Set<String>> getAppApproverOrphan = new Map<Id,Set<String>> ();
        
        
        if(iw != NULL )
        {
            usrRec = loggedInUserDetails;
            //usrTitle = setTitle(usrRec.Title);
            usrTitle = usrRec.Title;
            usrCostCenter = loggedInUserDetails.Cost_Center__c == null ? '0' : String.valueOf(loggedInUserDetails.Cost_Center__c);
        }
        
        List<String> buttons = new List<String>();
        
        // if(iw.Product_BU__c.equalsIgnoreCase('Internal'))
        // {

        // }
        //to store all valid users against the IW req's DGR from GSS User Region based on their title and cost center
        getAllApproversForWR = getAllRegionApprovers(new List<Investment_Workbox__c>{iw});
        
        //loggedIn User is Creator of the record
        //&& iw.Legacy_Data__c != 'Workbox'
        if(iw.CreatedById == loggedInUsr && iw.Legacy_Data__c != 'Workbox'){
            buttons = loggedInuserIscreator(iw);
        }

        System.debug('all apps : ' + getAllApproversForWR);
        
        //Logged in user is one of the Approver.
        if(!iw.Orphan_Request__c && getAllApproversForWR.containsKey(iw.Id) && getAllApproversForWR.get(iw.Id).contains(loggedInUsr)){
            System.debug('loggedInUsr is an Approver for non Orphan Queue');
            buttons = loggedInUserApproverButtons(iw,usrTitle,usrCostCenter );
        }
        
        
        //if Logged in user is an Approver from Orphan Queue.
        if(iw.Orphan_Request__c){
            buttons = orphanRequestButtons(iw, usrTitle);
        }
        
        
        System.debug('All the button ' + buttons);
        return buttons;
        
    }
    
    
    //any user in GSS User Region with matching Account DGR can take actions on the IW Request.
    //This method is called to find the relevant approvers and tagged to IW DGR and then allow right set of person to take actions on the IW 
    public Map<Id, Set<String>> getAllRegionApprovers(List<Investment_Workbox__c> invWRs)
    {
        
        //String userTitle = setTitle(approver.User__r.Title);
        Set<String> allDivs = new Set<String>();
        Set<String> allGeos = new Set<String>();
        Set<String> allRegs = new Set<String>();
        Set<String> uIds;
        for(Investment_Workbox__c iwb : invWRs){
            allGeos.add(iwb.Geo__c + ' '+ '(Geography)');
            allRegs.add(iwb.Region__c + ' '+ '(Region)');
        }
        if(approverLevel == NULL || loeCheckToApprovers == NULL || userDivisions == NULL )
        {
            initializeCustomMetadata();
        }
        Map<Id, Set<String>> wRsToApproverList = new Map<Id,Set<String>>();
        
        List<Inv_WorkBox_Region_Mapping__c> allUserRegion = new List<Inv_WorkBox_Region_Mapping__c> ();
        if(!Test.isRunningTest()) {
            allUserRegion = [SELECT 
                             Id, User__r.Name, User__r.Title,User__c, TERR_HIER_2_F__c, TERR_HIER_1_F__c
                             FROM 
                             Inv_WorkBox_Region_Mapping__c
                             WHERE 
                             User__r.isActive = TRUE
                             AND RecordType.Name = 'Investment Workbox'
                             AND User__r.Division != null
                             AND User__r.Division IN : userDivisions
                             AND TERR_HIER_1__r.psa_Old__c = false
                             AND (TERR_HIER_2__r.Name IN :allRegs OR TERR_HIER_2_F__c = '*')
                             AND (TERR_HIER_1__r.Name IN :allGeos OR TERR_HIER_1_F__c = '*')
                             AND User__c =: UserInfo.getUserId()];
        }
        else{
            System.debug('TestClass Execution' + UserInfo.getUserId() );
            allUserRegion = [SELECT 
                             Id, User__r.Name, User__r.Title,User__c, TERR_HIER_2_F__c, TERR_HIER_1_F__c
                             FROM 
                             Inv_WorkBox_Region_Mapping__c
                             WHERE 
                             RecordType.Name = 'Investment Workbox'
                             AND User__c =: UserInfo.getUserId()
                            ];   
        }
        
        Map<String, List<Inv_WorkBox_Region_Mapping__c>> regionTourMap = new Map<String, List<Inv_WorkBox_Region_Mapping__c>>();
        
        if(allUserRegion != NULL && allUserRegion.size() > 0){
            
            for(Inv_WorkBox_Region_Mapping__c urMap : allUserRegion){
                if(!regionTourMap.containsKey(urMap.TERR_HIER_2_F__c)){
                    regionTourMap.put(urMap.TERR_HIER_2_F__c, new List<Inv_WorkBox_Region_Mapping__c>{urMap});
                }
                else{
                    regionTourMap.get(urMap.TERR_HIER_2_F__c).add(urMap);
                }
            }
            
            System.debug('regionTourMap :: ' + regionTourMap);
            
            if(approverLevel == NULL || loeCheckToApprovers == NULL){
                initializeCustomMetadata();
            }
            
            for(Investment_Workbox__c iw : invWRs){
                
                uIds = new Set<String>();

                String iwClassificatonStr = iw.IW_Classification__c == 'Product/Platform Work' ? 'PP' : 'PunP';
                
                if(regionTourMap.containsKey(iw.Region__c) || regionTourMap.containsKey('*')){
                    List<Inv_WorkBox_Region_Mapping__c> mergeAll = regionTourMap.containsKey(iw.Region__c) ? regionTourMap.get(iw.Region__c) : new List<Inv_WorkBox_Region_Mapping__c>();
                    if(regionTourMap.containsKey('*')){
                        mergeAll.addAll(regionTourMap.get('*'));
                    }
                    for(Inv_WorkBox_Region_Mapping__c urMap : mergeAll){
                        if(urMap.User__r.Title != NULL){
                            if( (urMap.TERR_HIER_2_F__c.equals(iw.Region__c) || urMap.TERR_HIER_2_F__c.equals('*')) && 
                               (urMap.TERR_HIER_1_F__c.equals(iw.Geo__c) || urMap.TERR_HIER_1_F__c.equals('*')) ){

                                System.debug('all 1 : ' + approverLevel.get('4To40'+iwClassificatonStr).get('flApp'+iwClassificatonStr) );
                                System.debug('all 2 : ' + approverLevel.get('40To80'+iwClassificatonStr).get('flApp'+iwClassificatonStr) );
                                System.debug('all 3 : ' + approverLevel.get('80'+iwClassificatonStr).get('flApp'+iwClassificatonStr) );
                                System.debug('all 4 : ' + approverLevel.get('80'+iwClassificatonStr).get('secApp'+iwClassificatonStr+'Esc') );
                                // getting list of approver from saved map of titles on IW Type
                                   
                                   if(approverLevel.get('4To40'+iwClassificatonStr).get('flApp'+iwClassificatonStr).contains(urMap.User__r.Title)
                                    || approverLevel.get('4To40'+iwClassificatonStr).get('secApp'+iwClassificatonStr).contains(urMap.User__r.Title)
                                    || approverLevel.get('4To40'+iwClassificatonStr).get('secApp'+iwClassificatonStr+'Esc').contains(urMap.User__r.Title) 
                                      || approverLevel.get('40To80'+iwClassificatonStr).get('flApp'+iwClassificatonStr).contains(urMap.User__r.Title) 
                                      || approverLevel.get('40To80'+iwClassificatonStr).get('secApp'+iwClassificatonStr).contains(urMap.User__r.Title)
                                      || approverLevel.get('40To80'+iwClassificatonStr).get('secApp'+iwClassificatonStr+'Esc').contains(urMap.User__r.Title) 
                                        ||  approverLevel.get('80'+iwClassificatonStr).get('flApp'+iwClassificatonStr).contains(urMap.User__r.Title) 
                                        ||  approverLevel.get('80'+iwClassificatonStr).get('secApp'+iwClassificatonStr).contains(urMap.User__r.Title) 
                                            ||  approverLevel.get('80'+iwClassificatonStr).get('secApp'+iwClassificatonStr+'Esc').contains(urMap.User__r.Title) )
                                   {
                                          if(wRsToApproverList.containsKey(iw.Id)){
                                              wRsToApproverList.get(iw.Id).add(urMap.User__c);    
                                          }
                                          else{
                                              wRsToApproverList.put(iw.Id, new Set<String>{urMap.User__c});    
                                          }
                                    }
                                   
                               }
                        }
                    }
                }
            }
        }
        
        
        return wRsToApproverList;
    }
    
    
    public void createProjectsHandlerFunction(List<Investment_Workbox__c > approvedInvestmentRequests)
    {
        String projectId = [select value__c from PSA_Common_Setting__mdt  where type__c = 'IW_Internal_Project_Name' limit 1].value__c;

        Map<String,String> nameToValue = new Map<String,String>();
        accIdNameMap = new Map<Id, String>();
        for (PSA_Common_Setting__mdt commonSettingRecord: [select Name__c,Value__c from PSA_Common_Setting__mdt where Name__c in ('PSA User Project Manager' ,'InternalPractice' ,'INVProjTemplateNameId','INVProjectName','INVProjSubType','INVProjType' )])
        {
            nameToValue.put(commonSettingRecord.Name__c,commonSettingRecord.Value__c);
        }
        
        //Map<Id,pse__proj__c> accountToProjects = new Map<Id,pse__proj__c>();
        Map<Id, Map<String,pse__proj__c>> accountToProjects = new Map<Id, Map<String,pse__proj__c>>();

        Map<Id,String> accountIdToCurrency = new Map<Id,String>();
        for(Investment_Workbox__c approvedInvestmentRequest :approvedInvestmentRequests)
        {
            accountToProjects.put(approvedInvestmentRequest.Account__c,null);
        }
        Map<Id,String> accountToArea = new Map<Id,String>();
        for(Account account: [select id,Name,CurrencyIsoCode, TERR_HIER_5__c, (select id, Name, IW_Product_BU__c from pse__Projects__r where pse__Project_Type__c = :nameToValue.get('INVProjType') and Project_Sub_Type__c = :nameToValue.get('INVProjSubType') and pse__Closed_for_Time_Entry__c = false and pse__Is_Active__c = true and pse__Stage__c = 'In Progress') from Account where id in :accountToProjects.keySet()])
        {
            accountToArea.put(account.id, account.TERR_HIER_5__c + ' (Territory)');
            accountIdToCurrency.put(account.id,account.CurrencyIsoCode);
            //if(account.pse__Projects__r != null && account.pse__Projects__r.size() == 1)
            
            // Saving exisiting map of projects created for the current IW account
            if(account.pse__Projects__r != null && account.pse__Projects__r.size() > 0) 
            {
                Map<String, pse__Proj__c> iwProductTypeToProject = new Map<String, pse__Proj__c>();
                for(pse__Proj__c proj : account.pse__Projects__r)
                {
                    if (proj.IW_Product_BU__c != null && proj.IW_Product_BU__c != '') {

                        // if(proj.IW_Product_BU__c.equalsIgnoreCase('Edge Technology Group'))
                        // {
                        //     iwProductTypeToProject.put('Edge Technology Group', proj);
                        // }
                        // else if(proj.IW_Product_BU__c.equalsIgnoreCase('Security Technology Group'))
                        // {
                        //     iwProductTypeToProject.put('Security Technology Group', proj);
                        // }
                        // else if(proj.IW_Product_BU__c.equalsIgnoreCase('Internal'))
                        // {
                        //     iwProductTypeToProject.put('Internal', proj);
                        // }
                        // added by Kushal FFPSA-2049
                        if(proj.IW_Product_BU__c.equalsIgnoreCase('IWProject')){
                            iwProductTypeToProject.put('IWProject',proj);
                        }
                        
                    }
                    
                }
                accountToProjects.put(account.Id,iwProductTypeToProject);
            }
            
            accIdNameMap.put(account.Id, account.Name );
        }
        Map<String, Id> regionNametoId = new Map<String, Id>();
        for(pse__Region__c region: [select id,name from pse__Region__c where name in :accountToArea.values()])
        {
            regionNametoId.put(region.name, region.id);
        }
        List<pse__Proj__c> projectsToInsert = new List<pse__Proj__c>();
        List<pse__Milestone__c> milestonesToInsert = new List<pse__Milestone__c>();
        pse__Milestone__c milestoneRecord;
        pse__Proj__c projectRecord;
        pse__Proj__c projectRecordPointer;

        system.debug('full accountToProjects :: ' + accountToProjects);
        //modified creation of projects depending on the Type of IW and Account of IW
        for(Investment_Workbox__c approvedInvestmentRequest :approvedInvestmentRequests)
        {
            //if(accountToProjects.get(approvedInvestmentRequest.Account__c) != null || approvedInvestmentRequest.Security__c)  
            if( (accountToProjects.get(approvedInvestmentRequest.Account__c) != null &&  accountToProjects.get(approvedInvestmentRequest.Account__c).get('IWProject') != null) )
            {
                System.debug('ch now approvedInvestmentRequest : '+ approvedInvestmentRequest);
                //milestoneRecord =  approvedInvestmentRequest.Security__c ? createMilestone(approvedInvestmentRequest,new pse__Proj__c( Id = approvedInvestmentRequest.Project__c)) : createMilestone(approvedInvestmentRequest,accountToProjects.get(approvedInvestmentRequest.Account__c));

                pse__Proj__c projectRef = accountToProjects.get(approvedInvestmentRequest.Account__c).get('IWProject');
                milestoneRecord =  createMilestone(approvedInvestmentRequest,projectRef);
                milestonesToInsert.add(milestoneRecord);
            }
            else
            {
                String currencyIsoCode = accountIdToCurrency.get(approvedInvestmentRequest.Account__c);
                Id regionId = regionNametoId.get(accountToArea.get(approvedInvestmentRequest.Account__c));
                projectRecord = createProject(approvedInvestmentRequest.Account__c,currencyIsoCode,regionId,nameToValue, 'IWProject');
                projectsToInsert.add(projectRecord);
                milestoneRecord = createMilestone(approvedInvestmentRequest,projectRecord);
                milestonesToInsert.add(milestoneRecord);
                
            }

        }
        if(!projectsToInsert.isEmpty())
        {
            insert projectsToInsert;
        }
        if(!milestonesToInsert.isEmpty())
        {
            insert milestonesToInsert;
            List<id> insertedMilestonesIds = new List<id>();
            for(pse__Milestone__c insertedMilestone : milestonesToInsert)
            {
                insertedMilestonesIds.add(insertedMilestone.id);
            }
            if(!insertedMilestonesIds.isEmpty())
            {
                updateInvestmentWorkWithLookups(insertedMilestonesIds);
            }
        }
        
    }
    
    
    @future
    public static void updateInvestmentWorkWithLookups (List<Id> milestoneIds)
    {
        Map<Id,List<Id>> workboxToMilestone = new Map<Id,List<Id>>();
        List<Investment_Workbox__c> requestsToUpdate = new List<Investment_Workbox__c>();
        for(pse__Milestone__c insertedMilestones: [select id,Investment_Work__c, pse__project__c from pse__Milestone__c where id in :milestoneIds])
        {
            workboxToMilestone.put(insertedMilestones.Investment_Work__c,new List<Id>());
            workboxToMilestone.get(insertedMilestones.Investment_Work__c).add(insertedMilestones.Id);
            workboxToMilestone.get(insertedMilestones.Investment_Work__c).add(insertedMilestones.pse__project__c);
        }
        if(!workboxToMilestone.isEmpty())
        {
            for(Investment_Workbox__c approvedInvestmentRequest : [select id,LOE_Hours__c, Loe_Minutes__c, Region__c,Geo__c,Watchers_Email_Id__c,Orphan_Request__c,Status__c,Project__c,Milestone__c,IW_Modify__c , Escalated__c , IW_Classification__c from Investment_Workbox__c where id in : workboxToMilestone.keyset()])
            {
                if(workboxToMilestone.get(approvedInvestmentRequest.Id).size() == 2)
                {
                    approvedInvestmentRequest.Project__c = workboxToMilestone.get(approvedInvestmentRequest.Id)[1];
                    approvedInvestmentRequest.Milestone__c = workboxToMilestone.get(approvedInvestmentRequest.Id)[0];
                    approvedInvestmentRequest.IW_Modify__c = true;
                    requestsToUpdate.add(approvedInvestmentRequest);
                    
                }
            }
            if(!requestsToUpdate.isEmpty())
            {
                update requestsToUpdate;
                //Email to notify 
                //System.debug('@@@requestsToUpdate: '+requestsToUpdate);
                InvWB_Handler ih = new InvWB_Handler();
                System.debug('requestsToUpdate : '+ requestsToUpdate);
                ih.sendEmailNotificationToUsersonStatus(requestsToUpdate);
            }
            
        }
        
    }
    
    
    public  pse__Proj__c createProject (Id accountId, String CurrencyIsoCode, Id regionId, Map<String, String> nameToValue, String productBU )
    {
        
        pse__Proj__c proj = new pse__Proj__c();
        
        //adding Product Type of IW 21.7.
        proj.Name = ' - ' + nameToValue.get('INVProjectName');
        proj.IW_Product_BU__c = productBU;
        proj.Project_Template__c = nameToValue.get('INVProjTemplateNameId');
        proj.CurrencyIsoCode = CurrencyIsoCode;
        proj.pse__Account__c = accountId;
        proj.Contract_Closed__c = 'Internal';
        proj.pse__Project_Type__c = nameToValue.get('INVProjType');
        proj.Project_Sub_Type__c = nameToValue.get('INVProjSubType');
        proj.pse__Project_Manager__c = nameToValue.get('PSA User Project Manager');
        proj.pse__End_Date__c = date.newinstance(2040, 12, 12);
        proj.pse__Start_Date__c = date.today();
        proj.pse__Region__c = regionId;
        proj.pse__Planned_Hours__c = 0;
        proj.Ongoing_Project_Recurring_Planned_Hour__c = 0;
        proj.Ongoing_Project_Recurring_Budget_Amt__c = 0;
        proj.pse__Is_Active__c  = true;
        proj.pse__Stage__c = 'In Progress';
        proj.External_Id__c = accountId + nameToValue.get('INVProjectName') + String.valueOf(system.now());
        proj.pse__Is_Billable__c = false;
        Id recordTypeId = Schema.SObjectType.pse__proj__c.getRecordTypeInfosByName().get('Internal Project').getRecordTypeId();
        proj.recordTypeId = recordTypeId;
        proj.pse__Practice__c = nameToValue.get('InternalPractice');
        
        return proj;
    }
    
    
    public  pse__Milestone__c createMilestone (Investment_Workbox__c approvedInvestmentRequest, pse__proj__c parentProject)
    {
        
        pse__proj__c projLookUp;
        pse__Milestone__c  milestone =  new pse__Milestone__c();
        //19.5 Adding Security check to avoid non billable milestone
        //if(parentProject.Id == null && !approvedInvestmentRequest.Security__c )
        if(parentProject.Id == null)
        {
            projLookUp = new pse__proj__c();
            projLookUp.External_Id__c = parentProject.External_Id__c;
            milestone.pse__project__r = projLookUp;
        }
        else
        {
            milestone.pse__Project__c = parentProject.Id;
        }

        // if(prodAcronymMap == null || prodAcronymMap.isEmpty())
        // {
        //     initializeCustomMetadata();
        // }

        System.debug('rech crt milestone : '+approvedInvestmentRequest );
        //Removed Secuirty checks for milestone creation 
        milestone.Start_Date__c =  Date.today();
        //Added by Sujay for FFPSA-907
        milestone.pse__Target_Date__c =  Date.today().addMonths(6);
        
        milestone.pse__Milestone_Amount__c = 0;
        milestone.pse__Planned_Hours__c = 0;
        String nameMilestone = '';
        // if(!approvedInvestmentRequest.Security__c )
        // {
        //     nameMilestone = approvedInvestmentRequest.Name + '::'+approvedInvestmentRequest.Work_Type__c+'-'+ approvedInvestmentRequest.Justification__c+'-' + approvedInvestmentRequest.Product_BU__c;
        // }
        // else 
        //{

        //     String productName = '';
        //     if(approvedInvestmentRequest.Products__c != null )
        //     {
        //         for (String product : approvedInvestmentRequest.Products__c.split(',')) {
        //             if ( prodAcronymMap.containsKey(product) ) {
        //                 productName = productName + prodAcronymMap.get(product) + ' ';
        //             } else if(product.containsWhitespace()) {
        //                 Integer count = 1;
        //                 for (string eachProdWord : product.split(' ') ) {
        //                     if (count < 4 ) {
        //                         productName = productName + eachProdWord.left(1).toUpperCase() ;
        //                         count++;
        //                     }
        //                 }
        //                 productName = productName + ' ';
        //             } else if( !product.containsWhitespace()) {
        //                 productName = productName + product.left(3).toUpperCase() + ' ';
        //             }   
        //         }
        //     }
        //     nameMilestone = (approvedInvestmentRequest.Name + '::' + (productName.left(11)).trim() + (productName == ''? '' : '_' ) + accIdNameMap.get(approvedInvestmentRequest.Account__c ) ).left(80) ;
        // }
        //21.7 removing distinguisher on Milestone creation.
        nameMilestone = approvedInvestmentRequest.Name + '::'+approvedInvestmentRequest.Work_Type__c+'-'+ approvedInvestmentRequest.Justification__c+'-' + approvedInvestmentRequest.Product_BU__c;
        milestone.Milestone_Type_List__c =  'Product & Platform';
        milestone.Name = nameMilestone.length() > 80 ?  nameMilestone.substring(0, 80) : nameMilestone ;
        milestone.Task_Milestone_Name__c = nameMilestone.left(40);
        milestone.pse__Planned_Hours__c = approvedInvestmentRequest.LOE__c;
        milestone.Investment_Work__c = approvedInvestmentRequest.Id;
        // added by Kushal FFPSA-2049
        milestone.IW_Product_BU__c = approvedInvestmentRequest.Product_BU__c;
        //milestone.Billable__c = approvedInvestmentRequest.Security__c ? true : false;
        milestone.Billable__c = false;
        Id recordTypeId = Schema.SObjectType.pse__Milestone__c.getRecordTypeInfosByName().get('Investment Work').getRecordTypeId();
        //Id billRecordTypeId = Schema.SObjectType.pse__Milestone__c.getRecordTypeInfosByName().get('Investment Work Billable').getRecordTypeId();
        //milestone.recordTypeId = approvedInvestmentRequest.Security__c ? billRecordTypeId : recordTypeId;
        milestone.recordTypeId = recordTypeId;
        // if (approvedInvestmentRequest.Security__c) {
        //     milestone.pse__Description__c = URL.getSalesforceBaseUrl().toExternalForm()+'/'+approvedInvestmentRequest.Id;
        // }
        return milestone;
    }
    
    
    public void checkInvestmentWorkForCancel(List<Investment_Workbox__c> cancelledRequests)
    {
        system.debug('HELLLLO in MILestone::::::::::::::::::');
        List<Id> milestonesToUpdate = new List<Id>();
        Set<Id> investmentRequestIds = new Set<Id>();
        List<Investment_Workbox__c> successfulCancels = new List<Investment_Workbox__c>();
        for(Investment_Workbox__c cancelledRequest: cancelledRequests)
        {
            
            investmentRequestIds.add(cancelledRequest.Id);
            // if(! cancelledRequest.Product_BU__c == 'Internal')
            // {
                
            // }
            
        }
        for (pse__Milestone__c milestone: [select id,pse__Closed_for_Time_Entry__c, pse__Status__c,Investment_Work__c,(select id from pse__Timecards__r where pse__Status__c != 'Saved' limit 1) from pse__Milestone__c where Investment_Work__c in :investmentRequestIds])
        {
            if(milestone.pse__Timecards__r == null || milestone.pse__Timecards__r.size() == 0)
            {
                milestonesToUpdate.add(milestone.Id);
                investmentRequestIds.remove(milestone.Investment_Work__c);
            }
        }
        for(Investment_Workbox__c cancelledRequest: cancelledRequests)
        {
            if(investmentRequestIds.contains(cancelledRequest.Id))
            {
                cancelledRequest.addError('This Investment Work Request cannot be Cancelled as Time has been Submitted against it');
            }
            else if(cancelledRequest.Approved_Date__c != null)
            {
                //cancelledRequest.Approved_Date__c = null;
                successfulCancels.add(cancelledRequest);
            }
        }
        
        if(!successfulCancels.isEmpty())
        {
            addCanceledWRhoursToRegionSlot(successfulCancels);
        }
        if(!milestonesToUpdate.isEmpty())
        {
            
            updateMilestoneFunction(milestonesToUpdate);
        }
    }
    
    
    @future
    public static void updateMilestoneFunction (List<Id> milestonesToUpdate)
    {
        System.debug('cancelling Milstones ' + milestonesToUpdate);
        List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();
        if(milestonesToUpdate!= null && !milestonesToUpdate.isEmpty())
        {
            
            for (pse__Milestone__c milestone: [select id,pse__Closed_for_Time_Entry__c, pse__Status__c,Investment_Work__c,(select id from pse__Timecards__r where pse__Status__c != 'Saved' limit 1) from pse__Milestone__c where Id in :milestonesToUpdate])
            {
                if(milestone.pse__Timecards__r == null || milestone.pse__Timecards__r.size() == 0)
                {
                    milestone.pse__Closed_for_Time_Entry__c = true;
                    milestone.PSA_Ignore_Saved_Timecards__c = true;
                    milestone.pse__Status__c  = 'Cancelled';
                    milestones.add(milestone);
                }
            }
            
            if(milestones != null && !milestones.isEmpty())
            {
                update milestones;
            }
            
        }
        
    }
    
}