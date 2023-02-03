/*
 * CR: FFPSA-558
 * Developer: Sujay Aditya Suhas
 * Date: October 2018
 * 
*/ 

public without sharing class IW_getRequestWatchers {

    @AuraEnabled
    public static String getIWDetails(String recordId){
    
        if(recordId != null && recordId != ''){
            Investment_Workbox__c iwReq = [SELECT Id, Project__r.Id , Security__c, Project__r.Name, Opportunity__r.Id, Opportunity__r.Name FROM Investment_Workbox__c WHERE Id =: recordId LIMIT 1];
            if(iwReq != null){
                return JSON.serialize(iwReq);
            }
        }
        return 'No Records';
        
    }
    
    @AuraEnabled
    public static list<User> getWatchers(id recordIWID){
        Set<Id> defaultWatcherListId = new Set<Id>();
        boolean addWatcherAccess = false;
        Investment_Workbox__c iWDetails = [Select WatchersId__c,All_Approvers__c,CreatedById from Investment_Workbox__c where id=:recordIWID];
        Set<Id> watchersIdList = new Set<Id>();
        list<User> uSet;
        if(iWDetails != null && iWDetails.All_Approvers__c != null){
           List<String> allApproverList = iWDetails.All_Approvers__c.split(',');
            if(allApproverList.contains(userinfo.getUserId()) || userinfo.getUserId() == iWDetails.CreatedById){
                addWatcherAccess = true; 
            }  
        }
        if(iWDetails != null && iWDetails.WatchersId__c != null){
            for(string eachWatchers : iWDetails.WatchersId__c.split(',')){
                watchersIdList.add(eachWatchers);
            }
            uSet = new list<User>([select id,name from user where ID IN :watchersIdList]);
        }
        
        return uSet;
        
    }
    
    @AuraEnabled
    public static boolean getWatchersAccess(id recordIWID){
        boolean addWatcherAccess = false;
        Id systemAdminProfId = [Select id from Profile where Name ='System Administrator' limit 1].Id;
        Investment_Workbox__c iWDetails = [Select WatchersId__c,All_Approvers__c,CreatedById,Orphan_Request__c,Region__c,Legacy_Data__c,Status__c,Escalated__c,LOE__c,Division__c,Geo__c,LOE_Hours__c,LOE_Minutes__c,Auto_Escalated__c, Security__c, IW_Classification__c from Investment_Workbox__c where id=:recordIWID];
        Set<Id> watchersIdList = new Set<Id>();
        system.debug('---allApprover--'+iWDetails.All_Approvers__c);
        List<String> allApproverList = new List<String>();
        if(iWDetails != null && iWDetails.All_Approvers__c != null){
            for(string eachString :iWDetails.All_Approvers__c.split(',')){
                allApproverList.add(eachString);
            }
            system.debug('---allApproverList--'+allApproverList);
            if(allApproverList.contains(userinfo.getUserId()) || userinfo.getUserId() == iWDetails.CreatedById || userInfo.getProfileId() == systemAdminProfId){
                addWatcherAccess = true; 
            }  
        }
        else if(iWDetails != null && (userinfo.getUserId() == iWDetails.CreatedById || userInfo.getProfileId() == systemAdminProfId)){
            addWatcherAccess = true; 
        }
        else{
            InvWB_Handler invHandler = new InvWB_Handler();
            List<String> btnStringValAccess = invHandler.getApproverListOfWR(iWDetails,userinfo.getUserId());
            if(btnStringValAccess.contains('eligible')){
                addWatcherAccess = true;
            }
            
        }
        
        return addWatcherAccess;
        
    }
    
    @AuraEnabled
    public static void saveWatchers(string watcherList,id recId ){
        
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
        
        list<Id> watchersIdList = new List<Id>();
        String WatchersEmail = '';
        for(watcherWrapperCls eachItem :watchersList){
            watchersId += eachItem.Id + ',';
            watchersIdList.add(eachItem.Id);
        }
        
        watchersId = watchersId.removeEnd(',');
        watchersId = watchersId.trim();
        for(User eachUser :[Select id,email from user where ID IN :watchersIdList]){
            WatchersEmail += eachUser.email+',';
        }
        WatchersEmail = WatchersEmail.removeEnd(',');
        WatchersEmail = WatchersEmail.trim();
        
        Investment_Workbox__c inv = new Investment_Workbox__c();
        inv.WatchersId__c = watchersId;
        inv.Watchers_Email_Id__c  = WatchersEmail;
        inv.Id = recId;
        try{
            inv.IW_Modify__c = true;
            update inv; 
        }
        catch(Exception ex){
            PSA_AutoCreateProjectUtil.sendErrorMails('Error:IW Adding Watchers(Class:IW_getRequestWatchers), Id: '+recId,ex.getMessage());
        }
        
    }
    
    public class watcherWrapperCls{ 
        public String Id;
        Public String Name;
        watcherWrapperCls(){}   
    }
    
    //19.1 FFPSA added by sujay to show Approver(s) component
    @AuraEnabled
    public static list<User> getApprovers(id recordIWID){
        Set<Id> defaultWatcherListId = new Set<Id>();
        boolean addWatcherAccess = false;
        Investment_Workbox__c iWDetails = [Select All_Approvers__c,CreatedById from Investment_Workbox__c where id=:recordIWID];
        //Set<Id> watchersIdList = new Set<Id>();
        Set<Id> approversIdList = new Set<Id>();
        list<User> uSet;
        /*if(iWDetails != null && iWDetails.All_Approvers__c != null){
           List<String> allApproverList = iWDetails.All_Approvers__c.split(',');
            if(allApproverList.contains(userinfo.getUserId()) || userinfo.getUserId() == iWDetails.CreatedById){
                addWatcherAccess = true; 
            }  
        }*/
        if(iWDetails != null && iWDetails.All_Approvers__c != null){
            for(string eachApprovers : iWDetails.All_Approvers__c.split(',')){
                approversIdList.add(eachApprovers);
            }
            uSet = new list<User>([select id,name from user where ID IN :approversIdList]);
        }
        
        return uSet;
        
    }
    
    
    @AuraEnabled
    public static string handleButtonEvent(string recordIWID, string buttonEvent,string LOEHrs,string LOEMins,String Account,String Comment, boolean internalProd, String iwClassification){
        string isSuccess = 'true';
        Decimal slotAvailable = 0.0;
        Investment_Workbox__c inv = new Investment_Workbox__c();
        System.debug('IN handleButtonEvent');
        if(recordIWID != null && recordIWID != ''){
            inv = [select id,Requestor__c,IW_Modify__c,CreatedBy.Name, Security__c, Account__r.Name, Justification__c, Region__c, CreatedById,Requestor__r.ManagerId,CreatedBy.ManagerId,Escalated__c,Status__c,Account__c,LOE__c,LOE_Hours__c,LOE_Minutes__c,Legacy_Data__c,Comments__c,Auto_Escalated__c , IW_Classification__c , Product_BU__c from Investment_Workbox__c where id = :recordIWID];
            if (internalProd != false && internalProd != true ) {
                if (inv.Product_BU__c != null && inv.Product_BU__c == 'Internal') {
                    internalProd = true;
                } else { internalProd = false; }
            }
            if (iwClassification == '' || iwClassification == null) {
                iwClassification = inv.IW_Classification__c ;
            }
            InvWB_Handler ib = new InvWB_Handler();
            //19.5/19.6 Adding Security/ Non Security Project check to identify number of slots available
            slotAvailable =  ib.getRgionAccountSlot(inv.Account__c, 'hours' , 'Region' , iwClassification );
        }
        if(buttonEvent == 'submit' || buttonEvent == 'save'){
            string buttonVal = '';
            // if Account == 'None' : Call is from edit page submit button, else call from button component
            if(Account != 'None'){
                system.debug('---On Submit with Account Id populated---'+userInfo.getUserId());
                system.debug('---On Submit with Account Id populated---'+inv.CreatedById);
                system.debug('---On Submit with Account Id populated---'+userInfo.getProfileId());
                
                Id systemAdminProfId = [Select id from Profile where Name ='System Administrator' limit 1].Id;
                if(inv.CreatedById == NULL || userInfo.getUserId() == inv.CreatedById || userInfo.getProfileId() == systemAdminProfId){
                    system.debug('---On Submit Inside Insert Check---' + inv.CreatedById  + ' classification ::' + iwClassification );
                    //19.5 To identify and get the avialble hours for region / geo
                    String accountSlotInfo = availableLoeBudget(Account, 'Region', iwClassification );
                    System.debug('accountSlotInfo :: '+ accountSlotInfo);
                    
                    system.debug('---method handleButtonEvent: return availableLoeBudget JSON String---'+accountSlotInfo);
                    if(accountSlotInfo != '' && accountSlotInfo != null){
                        Map<String, Object> mPayloadFormat = (Map<String, Object>) JSON.deserializeUntyped(accountSlotInfo);
                        integer totalLOEMinRequested = (Integer.valueOf(LOEHrs)*60)+ Integer.valueOf(LOEMins);
                        decimal slotHrsVal = (decimal) mPayloadFormat.get('slotHrs');  
                        slotAvailable = slotHrsVal;
                        integer slotMinVal = Integer.valueOf(slotHrsVal)*60;
                        //20.6 - byPass security check on IW.
                        if( totalLOEMinRequested > slotMinVal){
                            buttonVal = 'failure';
                        }
                        else{
                            buttonVal = 'success';
                        }
                    }
                    else{
                        buttonVal = 'failure';
                    }
                }
                else{
                    system.debug('---On Submit Inside No Permission---');
                    buttonVal = 'NoPermission';
                }
                
            }
            //call from button component
            else{
                system.debug('---On Submit Inside Account = None ---');
                buttonVal = getLoeBudget(inv.Account__c,String.valueOf(inv.LOE_Hours__c),String.valueOf(inv.LOE_Minutes__c),recordIWID); 
            }
            
            system.debug('---handleButtonEvent buttonVal---'+buttonVal);
            if(buttonVal != '' && buttonVal != 'failure' && buttonVal != 'NoPermission' && buttonEvent != 'save'){
                inv.Status__c = 'Awaiting Approval';
            }
            else if(buttonVal == 'NoPermission'){
                isSuccess = 'NoPermission';
            }
            else{
                isSuccess = 'false';
                System.debug('calling notifyLowSlot ');
                System.debug('inv :: ' + inv + 'slotAvailable :: ' + slotAvailable);
                if(inv.Id != NULL && Account == 'None'){
                    slotAvailable = slotAvailable != NULL ? slotAvailable : 0.0;
                    IW_getRequestWatchers.notifyLowSlot(JSON.serialize(inv),slotAvailable, 'single', 'test', 'test');    
                }
                
            }
        }
        else if(buttonEvent == 'approve'){
            if(inv != null && inv.Escalated__c){
                inv.Status__c = 'Escalate Approved';
            }
            else{
                inv.Status__c = 'Approved';
            }
        }
        else if(buttonEvent == 'reject'){
            if(inv != null && inv.Escalated__c){
                inv.Status__c = 'Escalate Reject';
            }
            else{
                inv.Status__c = 'Rejected';
            }
        }
        else if(buttonEvent == 'escalate'){
            inv.Status__c = 'Escalated';
            inv.Escalated__c = true;
        }
        else if(buttonEvent == 'cancel'){
            inv.Status__c = 'Cancelled';
        }
        
        //recordIWID == '' when submitted from edit page for insert.
        if(recordIWID != ''){
            inv.Id = recordIWID;
            inv.IW_Modify__c = true;
            if(Comment != '' && Comment != null){
                if(inv.Comments__c != null && inv.Comments__c != ''){
                    inv.Comments__c += +buttonEvent+' Comment:'+'\n'+Comment;
                }
                else{
                    inv.Comments__c = buttonEvent+' Comment:'+Comment;
                }
            }
            if(isSuccess != 'NoPermission' && isSuccess != 'false' && !((buttonEvent == 'submit' || buttonEvent == 'save') && Account != 'None'))
            {
                update inv; 
            }
        }
        
        return isSuccess;
    }
    
    @AuraEnabled
    public static string[] getButtonVisibility(Id recordIWID){
        Investment_Workbox__c inv = [select Id, Approver__c , Approver__r.Manager.Id ,WatchersId__c,Requestor__c,CreatedById,Requestor__r.ManagerId,CreatedBy.ManagerId,Orphan_Request__c,status__c,Division__c, Geo__c, Region__c, Area__c, Territory__c, LOE__c,LOE_Hours__c , LOE_Minutes__c, Escalated__c,Legacy_Data__c,Auto_Escalated__c, Security__c , IW_Classification__c from Investment_Workbox__c where id =:recordIWID];
        string submitCancelBtnViewer ='';       
        InvWB_Handler handler = new InvWB_Handler();
        string[] buttonVisibility = handler.getApproverListOfWR(inv,userInfo.getUserId());
        submitCancelBtnViewer = inv.CreatedById+','+inv.Requestor__c+','+inv.Requestor__r.ManagerId+','+inv.CreatedBy.ManagerId;
        Id systemAdminProfId = [Select id from Profile where Name ='System Administrator' limit 1].Id;
        system.debug('---method getButtonVisibility return buttons from getApproverListOfWR---'+buttonVisibility);
        if(inv.Status__c == 'Saved'){
            if(userInfo.getUserId() == inv.CreatedById || userInfo.getProfileId() == systemAdminProfId){
                buttonVisibility.add('Cancel');
                buttonVisibility.add('Edit');
                buttonVisibility.add('Submit');
            }      
        }
        else if(inv.Status__c == 'Awaiting Approval'){
            if(userInfo.getUserId() == inv.CreatedById || userInfo.getProfileId() == systemAdminProfId){
                buttonVisibility.add('Cancel');
                buttonVisibility.add('Edit');
            }
        }
        else if(inv.Status__c == 'Approved' || inv.Status__c == 'Auto-Approved'){
            buttonVisibility.add('statusAppr');
            if(userInfo.getUserId() == inv.CreatedById || userInfo.getProfileId() == systemAdminProfId || userInfo.getUserId() == inv.Approver__c || userInfo.getUserId() == inv.Approver__r.Manager.Id ){
                buttonVisibility.add('Cancel');
            }
            
        }
        else if(inv.Status__c == 'Rejected'){
            buttonVisibility.add('statusRej');
        }
        else if(inv.Status__c == 'Escalate Approved'){
            buttonVisibility.add('escAppr');
            if(userInfo.getUserId() == inv.CreatedById || userInfo.getProfileId() == systemAdminProfId || userInfo.getUserId() == inv.Approver__c || userInfo.getUserId() == inv.Approver__r.Manager.Id ){
                buttonVisibility.add('Cancel');
            }
        }
        else if(inv.Status__c == 'Escalate Reject'){
            buttonVisibility.add('escRej');
        }
        else if(inv.Status__c == 'Escalated'){
            buttonVisibility.add('statusEsc');
        }
        else if(inv.Status__c == 'Cancelled'){
            buttonVisibility.add('statusCanl');
        }
        
        system.debug('---method getButtonVisibility Final list of button ---'+buttonVisibility);
        return buttonVisibility;
    }
    
    @AuraEnabled
    public static string getLoeBudget(id accountId,string loeHrs,string loeMin,id requestId){
        string submitUser = '';
        string result ='';
        Investment_Workbox__c inv;
        if(requestId != null){
            inv = [select Id,Requestor__c,Security__c, CreatedById,Requestor__r.ManagerId,CreatedBy.ManagerId , IW_Classification__c from Investment_Workbox__c where id =:requestId];
            submitUser = inv.CreatedById+','+inv.Requestor__c+','+inv.Requestor__r.ManagerId+','+inv.CreatedBy.ManagerId;
        }
        Id systemAdminProfId = [Select id from Profile where Name ='System Administrator' limit 1].Id;
        if(submitUser.contains(userInfo.getUserId()) || userInfo.getProfileId() == systemAdminProfId){
            integer loeHours = Integer.valueOf(loeHrs);
            integer loeMinutes = Integer.valueOf(loeMin);
           
            InvWB_Handler ih = new InvWB_Handler();
            //pass the Account Id to get available slot hrs
            //19.5 Adding below line to diffenrtiate and fetch the Bug for Geo/Region
            //Decimal slot = ih.getRgionAccountSlot(accountId,'hours');
            Decimal slot = ih.getRgionAccountSlot(accountId, 'hours' , 'Region' , inv.IW_Classification__c );
            Integer slotMins = (slot != null && slot > 0) ? (slot*60).intValue() : 0;       
            Integer loeMins = loeMinutes;
            Integer totalLoeMin = Integer.valueOf((loeHours*60)) + Integer.valueOf(loeMinutes);
            //20.6
            if(!inv.Security__c && totalLoeMin > slotMins) {
                result = 'failure';
            }
            else{
                result = String.valueOf(slotMins);
            }
        }
        else{
            result = 'NoPermission';
        }
        system.debug('---getLoeBudget result--'+result);
        return result;
    }
    
    
    @AuraEnabled
    public static string availableLoeBudget(string accountInfo, String regORGeo, String classification){        
        Decimal slotHrs = 0.0;
        String accountInfoJSONString = '';
        system.debug('---inside method : availableLoeBudget- Param Account Id---'+accountInfo);
        if(accountInfo != null || accountInfo != ''){
            InvWB_Handler ih = new InvWB_Handler();
            //pass the Account Id to get available slot hrs
            Decimal slot = ih.getRgionAccountSlot(accountInfo,'hours', regOrGeo , classification);
            system.debug('---slot value returned from getRgionAccountSlot----'+slot);
            slotHrs = (slot != null || slot > 0.0) ? slot : 0.0;
            decimal slotHours = slotHrs.setScale(2,RoundingMode.HALF_UP);
            
            Account acc = [Select TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c,Owner.Name from Account where id = :accountInfo limit 1]; 
            
            Map<String, Object> responseDetailsJson = new Map<String, Object>();
            //JSONObject responseDetailsJson = new JSONObject();
            
            /*
            responseDetailsJson.put('Area', acc.Region__c);
            responseDetailsJson.put('Region',acc.Division__c);
            responseDetailsJson.put('Division',acc.Division_Formula__c);
            responseDetailsJson.put('Territory',acc.Area__c );
            responseDetailsJson.put('Geography',acc.Geography_Formula__c);
            responseDetailsJson.put('Owner',acc.Owner.Name);
            responseDetailsJson.put('slotHrs',slotHours);
            */
            
            responseDetailsJson.put('Geography',acc.TERR_HIER_1__c);
            responseDetailsJson.put('Region',acc.TERR_HIER_2__c);
            responseDetailsJson.put('Area', acc.TERR_HIER_3__c);
            responseDetailsJson.put('Zone',acc.TERR_HIER_4__c);
            responseDetailsJson.put('Territory',acc.TERR_HIER_5__c );            
            responseDetailsJson.put('Owner',acc.Owner.Name);
            responseDetailsJson.put('slotHrs',slotHours);
            accountInfoJSONString = JSON.Serialize(responseDetailsJson);
            
        }
        //return slotHrs.setScale(2,RoundingMode.HALF_UP);
        system.debug('--accountInfoJSONString JSON--'+accountInfoJSONString);
        return accountInfoJSONString;
    }

    @AuraEnabled
    public static void calculateValueforNotifyLowSlot(String LOEHrs,String LOEMins, String Account, String Justification, String iwClassification)
    {
        System.debug('like did reach :' + LOEHrs + ' mins :' + LOEMins + ' Accout :  ' + Account + ' claasif : ' + iwClassification );
        Decimal LOE = decimal.valueOf(LOEHrs) + (decimal.valueOf(LOEMins)/60);
        Map<String, String> watchersMap = new Map<String, String>();
        watchersMap.put('Name', [select Name from Account where Id =:Id.valueof(Account)].Name);
        watchersMap.put('Id', Account);
        List<Map<String, String>> watchersMapList = new List<Map<String, String>>();
        watchersMapList.add(watchersMap);
        String watcherList = JSON.serialize(watchersMapList);
        String success = IW_BulkReqFormCntrl.getRgionAccountSlots( watcherList, LOE, Justification, iwClassification);

    }
    
    @future
    public static void notifyLowSlot(String iwSerialized ,Decimal slotAvailable, String singleOrBulk, String regToSlot, String lstAccounts)
    {
        List<Investment_Workbox__c> requests = new List<Investment_Workbox__c>();
        Map<Id, Account> lstAccountss = new Map<Id, Account>();
        Map<String, Decimal> regToSlott = new Map<String, Decimal>(); 
        slotAvailable = slotAvailable != NULL ? slotAvailable : 0.0;
        System.debug('Checking serialized data : ' + iwSerialized);
        String usr = [SELECT Id, Name from User where Id =: Userinfo.getUserId()].Name;
        if(singleOrBulk.equalsIgnoreCase('single')){
            Investment_Workbox__c iws = (Investment_Workbox__c)JSON.deserialize(iwSerialized, Investment_Workbox__c.class);
            System.debug('iws >' + iws);
            requests = new List<Investment_Workbox__c>{iws};  
        }else if(singleOrBulk.equalsIgnoreCase('bulk')){
            requests = (List<Investment_Workbox__c>)JSON.deserialize(iwSerialized, List<Investment_Workbox__c>.class);
            lstAccountss = (Map<Id, Account>)JSON.deserialize(lstAccounts, Map<Id, Account>.class);
            regToSlott = (Map<String, Decimal>)JSON.deserialize(regToSlot, Map<String, Decimal>.class);
            System.debug('lstAccountss :: '+ lstAccountss);
            System.debug('lstAccountss :: '+ regToSlott);
            System.debug('requests :: ' + requests);
        }
        
        System.debug('reached mail sys');
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        String fromAddress;
        List<String> invAdminDL = new List<String>();
        invAdminDL.add([ select Value_Long__c from PSA_Common_Setting__mdt where type__c ='IW_Admin_Users__mdt' limit 1].Value_Long__c);

        try
        {
            PSA_Common_Setting__mdt cs= [SELECT Id, Name__c , Value_Long__c from PSA_Common_Setting__mdt WHERE Name__c = 'FromEmailAdress'];
            fromAddress = cs.Value_Long__c != NULL ? cs.Value_Long__c : 'services-engg@akamai.com';
        }
        catch(Exception e ){
            fromAddress = 'services-engg@akamai.com';
        }

        String orgWideEmailId;
        
        try
        {
            orgWideEmailId = [select Id  from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
        }
        catch(Exception e)
        {
            orgWideEmailId = null; 
        }

        for(Investment_Workbox__c wr: requests)
        {
            String AccountName = singleOrBulk.equalsIgnoreCase('single') ? wr.Account__r.Name : lstAccountss.get(wr.Account__c).Name ;
            // String RegionName = singleOrBulk.equalsIgnoreCase('single') ? wr.Region__c : lstAccountss.get(wr.Account__c).Division__c; 
            //slotAvailable = singleOrBulk.equalsIgnoreCase('single') ? slotAvailable : regToSlott.get(lstAccountss.get(wr.Account__c).Division__c);
            slotAvailable = singleOrBulk.equalsIgnoreCase('single') ? slotAvailable : regToSlott.get(lstAccountss.get(wr.Account__c).TERR_HIER_2__c);
            Decimal LOE = singleOrBulk.equalsIgnoreCase('single') ? wr.LOE_Hours__c + wr.LOE_Minutes__c/60 : wr.LOE_Hours__c;
            Messaging.SingleEmailMessage objEmail = new Messaging.Singleemailmessage();
            String htmlBody = '<html><body><p>Hello,</p></body></html>' ;
            htmlBody = htmlBody + '<p><b>' + usr + '</b> has attempted to submit an Investment Work request for <b>' + AccountName + '</b> for <b>' + LOE + ' Hrs </b>. The remaining budget mapped to that account is <b>' + slotAvailable + '</b>. Please confirm whether there is truly no budget remaining or whether hours can be moved around to accommodate the request and reach out to the user.</p>';            
            htmlBody = htmlBody + 'Thanks,</br>Investment Work</br>For any queries or feedback on Investment Work, please visit <a href="https://akamai.lightning.force.com/lightning/r/CollaborationGroup/0F90f000000TikDCAS/view">Investment Work Support</a> (Investment Work Chatter Feed) </br></body></html>';

            //objEmail.setToAddresses(new List<String>{'sujs@akamai.com','sujain@akamai.com'});
            objEmail.setToAddresses(invAdminDL);
            objEmail.setSubject('Investment Work || Insufficient Slot');
        
            objEmail.setReplyTo('noreply@akamai.com');

            objEmail.setHtmlBody(htmlBody);
            

            if (orgWideEmailId != null)
            {
              objEmail.setOrgWideEmailAddressId(orgWideEmailId);
            }
            
            objEmail.saveAsActivity = false ;
            mailsToBeSent.add(objEmail);
        }

        System.debug('displ mailsto send' + mailsToBeSent);

        try{
            if(!mailsToBeSent.isEmpty()){
                Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);    
            }
        }
        catch(Exception e){
            System.debug('Error in sending email :: '+ e.getMessage() );
        }
    }
    // Removed secuirty checks and fetching values for IW classification and validate Accounts
    // @AuraEnabled
    // public static string getSecurityProj(){

    //     PSA_Common_Setting__mdt securityProj = new PSA_Common_Setting__mdt( ); 
    //     securityProj = [select Value__c,Name__c  from PSA_Common_Setting__mdt where type__c = 'IW_Security_Proj' limit 1];
    //     ResultWrapper obj = new ResultWrapper();
    //     obj.objName = 'pse__Proj__c';
    //     obj.text= securityProj.Name__c;
    //     obj.val = securityProj.Value__c;
    //     return JSON.serialize(obj) ;

    // }

    @AuraEnabled
    public static String getProductValues(){

        //return JSON.serialize( Investment_Workbox__c.Product_BU__c.getDescribe().getPicklistValues() ) ;
        return JSON.serialize( Investment_Workbox__c.IW_Classification__c.getDescribe().getPicklistValues() ) ;

    }

    @AuraEnabled
    public static String getAccountIdInternal(String accountId){

        System.debug('accc 1:: ' + accountId );
        account acc = [select id , Vertical__c, Account_Status__c from account where id=:accountId];
        System.debug('accc :: ' + acc );
        if ( (acc.Account_Status__c == 'Akamai Internal - Inactive' || acc.Account_Status__c == 'Akamai Internal - Active') ) {
            return JSON.serialize('true') ;
        } else {
            return JSON.serialize('false') ;
        }

        

    }

    public class ResultWrapper{
        public String objName {get;set;}
        public String text{get;set;}
        public String val{get;set;}
    }

}