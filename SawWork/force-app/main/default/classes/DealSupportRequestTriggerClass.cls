/*Created By: Vivek Baidya
* Created Date: 18-May-2018
* Description: Trigger class for DealSupportRequest Trigger. 
*/
public class DealSupportRequestTriggerClass {
    public static boolean updateSEManagerOnDSRFirstRunFlag=true;
    public static boolean validationOverrideFirstRunFlag=true;
    public static boolean sendDSREmailFirstRunFlag=true;
    public static boolean sendEmailToChangedPrimarySEFlag=true;
    
    public static void createAndUpdateDSRTracking(List<Deal_Support_Request__c> dsrTriggerNew,Map<Id,Deal_Support_Request__c> dsrTriggerOldMap,Boolean isUpdate){
        List<string> statusToStampEndDate = GsmUtilClass.getGSMSettingValue('DSR_StatusToStampEndDateOnTracking').split(',');
        List<DSR_Tracking__c> trackingListToInsertOrUpdate = new List<DSR_Tracking__c>();
        Map<Id,List<DSR_Tracking__c>> dsrToTrackingMap = new Map<Id,List<DSR_Tracking__c>>();
        
        /* Preparing a map of DSR and its associated DSR Tracking records. */
        if(isUpdate){
            for(DSR_Tracking__c dsrTrack : [select Status__c,End__c,Deal_Support_Request__c from DSR_Tracking__c where Deal_Support_Request__c IN : dsrTriggerNew ORDER BY LastModifiedDate DESC]){
                if(dsrToTrackingMap.containsKey(dsrTrack.Deal_Support_Request__c)){
                    List<DSR_Tracking__c> trackList = dsrToTrackingMap.get(dsrTrack.Deal_Support_Request__c);
                    trackList.add(dsrTrack);
                    dsrToTrackingMap.put(dsrTrack.Deal_Support_Request__c,trackList);
                }else{
                    List<DSR_Tracking__c> trackList = new List<DSR_Tracking__c>();
                    trackList.add(dsrTrack);
                    dsrToTrackingMap.put(dsrTrack.Deal_Support_Request__c,trackList);
                }
            }
        }
        
        /* Looping over the DSR which needs DSR Tracking to be created/updated */
        for(Deal_Support_Request__c dsr : dsrTriggerNew){
            DSR_Tracking__c track = new DSR_Tracking__c();
            track.Deal_Support_Request__c = dsr.Id;
            track.Start__c = system.now();
            track.Status__c = dsr.POC_Status__c;
            if(isUpdate && statusToStampEndDate.contains(dsr.POC_Status__c))
                track.End__c = system.now();
            trackingListToInsertOrUpdate.add(track);
            
            if(isUpdate && !dsrToTrackingMap.isEmpty()){
                for(DSR_Tracking__c dsrT : dsrToTrackingMap.get(dsr.Id)){
                    if(dsrT.Status__c == dsrTriggerOldMap.get(dsr.Id).POC_Status__c){
                        dsrT.End__c = system.now();
                        trackingListToInsertOrUpdate.add(dsrT);
                        break;
                    }
                }
            }
        }
        
        /* Upserting DSR Tracking records */
        DMLResults insertResults = new DMLResults();
        if(trackingListToInsertOrUpdate.size() > 0){
            insertResults.add(Database.upsert(trackingListToInsertOrUpdate,false),trackingListToInsertOrUpdate);
            insertResults.withClassName('DealSupportRequestTriggerClass').insertRecordsInErrorLog();
        }
    }

    public static void addAccountToDSR(Map<Deal_Support_Request__c, Id> DSR_OppId){

        Map<Id, Id> OppId_AccId = new Map<Id, Id>();
        for(Opportunity opp : [Select id, AccountId from Opportunity where id in :DSR_OppId.values()]){
            OppId_AccId.put(opp.id, opp.AccountId);
        }
 
        for(Deal_Support_Request__c dsr : DSR_OppId.keySet()){
                dsr.Account__c = OppId_AccId.get(dsr.Opportunity__c);
        }
    }
    
    // SFDC-7055 : Populate primary SE when new request is created
    public static void populatePrimarySE(List<Deal_Support_Request__c> dsrList){

        String ownerNotAssignedUserId = GsmUtilClass.getGSMSettingValue('Owner_Not_Assigned_User_Id');
        Map<Id, List<Deal_Support_Request__c>> accountIdToDsrList = new Map<Id, List<Deal_Support_Request__c>>();
    
        for(Deal_Support_Request__c dsr : dsrList){
            System.debug('Request type:'+dsr.Request_Type__c);
                if(accountIdToDsrList.containsKey(dsr.Account__c)){
                    accountIdToDsrList.get(dsr.Account__c).add(dsr);
                }else{
                    accountIdToDsrList.put(dsr.Account__c, new List<Deal_Support_Request__c>{dsr});
                }
        }
        
        //Map<Id, Id> accountIdtoAtmUserId = new Map<Id, Id>();
        Map<Id, Account> accIdToAccount = new  Map<Id, Account>();
        Set<String> grazt = new Set<String>();
        if(accountIdToDsrList.size() > 0){

            for(Account acc : [Select id, GRAZT__c from Account where Id IN :accountIdToDsrList.keyset()]){
                accIdToAccount.put(acc.id, acc); 
                grazt.add(acc.GRAZT__c);
            }


            Map<String, String> DSRToQueueDetails = new Map<String, String>();

            for(DSR_Routing__c DsrRouting : [Select id, Request_RequestSub_Product__c, Queue__c, Queue_DL__c from DSR_Routing__c where Territory_Mapping_Id__r.GRAZT__c IN :grazt and (NOT Territory_Mapping_Id__r.name LIKE 'OLD_%')]){
                DSRToQueueDetails.put(DsrRouting.Request_RequestSub_Product__c, DsrRouting.Queue__c+':'+DsrRouting.Queue_DL__c);
            }


            /*
            System.debug('GRAZT:'+grazt);
            Map<String, String> graztToQueueValue = new  Map<String, String>();
            Map<String, String> graztToVSEQueueValue = new  Map<String, String>();
            Map<String, String> graztToESAQueueValue = new  Map<String, String>();
            Map<String, String> graztToWPAQueueValue = new  Map<String, String>();
            Map<String, String> graztToESAProlexicQueueValue = new  Map<String, String>();
            for(Territory_Mapping__c territoryMapping : [Select id, Name, GRAZT__c, Queue__c, Queue_DL__c,VSE_Queue__c,VSE_Queue_DL__c,ESA_Queue__c,ESA_Queue_DL__c, WPA_Queue__c, WPA_Queue_DL__c, ESA_Prolexic_Queue__c, ESA_Prolexic_Queue_DL__c from Territory_Mapping__c where GRAZT__c IN :grazt]){
                if(!territoryMapping.Name.startswith('OLD_') && territoryMapping.Queue__c != null && territoryMapping.Queue_DL__c != null)
                        graztToQueueValue.put(territoryMapping.GRAZT__c, territoryMapping.Queue__c+':'+territoryMapping.Queue_DL__c);
                if(!territoryMapping.Name.startswith('OLD_') && territoryMapping.VSE_Queue__c != null && territoryMapping.VSE_Queue_DL__c != null)
                        graztToVSEQueueValue.put(territoryMapping.GRAZT__c, territoryMapping.VSE_Queue__c+':'+territoryMapping.VSE_Queue_DL__c);
                if(!territoryMapping.Name.startswith('OLD_') && territoryMapping.ESA_Queue__c != null && territoryMapping.ESA_Queue_DL__c != null)
                        graztToESAQueueValue.put(territoryMapping.GRAZT__c, territoryMapping.ESA_Queue__c+':'+territoryMapping.ESA_Queue_DL__c);
                if(!territoryMapping.Name.startswith('OLD_') && territoryMapping.WPA_Queue__c != null && territoryMapping.WPA_Queue_DL__c != null)
                        graztToWPAQueueValue.put(territoryMapping.GRAZT__c, territoryMapping.WPA_Queue__c+':'+territoryMapping.WPA_Queue_DL__c);
                if(!territoryMapping.Name.startswith('OLD_') && territoryMapping.ESA_Prolexic_Queue__c != null && territoryMapping.ESA_Prolexic_Queue_DL__c != null)
                        graztToESAProlexicQueueValue.put(territoryMapping.GRAZT__c, territoryMapping.ESA_Prolexic_Queue__c+':'+territoryMapping.ESA_Prolexic_Queue_DL__c);
            }*/


            //get the queue DL based on the geo <T01>
            Map<String,String> mapGeoQueueDL = new Map<String,String>();    
            List<String> QueueNames = GsmUtilClass.getGSMSettingValue('CHIME_ProductApproval_Queues')?.split(',');  
            for( Group gp : [SELECT id, Name,Email FROM Group WHERE type='QUEUE' AND Name IN:QueueNames]){
                if(gp.name.contains('APJ')){    
                    mapGeoQueueDL.put('APJ',gp.Email);  
                }else if( gp.name.contains('EMEA')){    
                    mapGeoQueueDL.put('EMEA',gp.Email); 
                }   
                else if( gp.name.contains('America')){  
                    mapGeoQueueDL.put('North America',gp.Email);    
                    mapGeoQueueDL.put('LTAM',gp.Email); 
                }   
            }
            System.debug('DSRToQueueDetails:'+DSRToQueueDetails);
            System.debug('accountIdToDsrList:'+accountIdToDsrList);
            for(Id accId : accountIdToDsrList.keyset()){
                for(Deal_Support_Request__c dsr : accountIdToDsrList.get(accId)){
                    String key = dsr.Request_Type__c + ':' + dsr.Request_Sub_Type__c + ':' + dsr.Product__c;
                    System.debug('Key:'+key);
                    if(DSRToQueueDetails.containsKey(key)){
                        dsr.SE__c = ownerNotAssignedUserId;
                        dsr.Queue__c = DSRToQueueDetails.get(key).split(':')[0];
                        dsr.Queue_DL__c = DSRToQueueDetails.get(key).split(':')[1];
                    }
                    else if(dsr.Request_Sub_Type__c == 'Gating Review'|| dsr.Request_Sub_Type__c =='Integration Review'){
                        dsr.Queue_DL__c = (mapGeoQueueDL?.get(dsr.Account_Geography__c) !=null)?mapGeoQueueDL?.get(dsr.Account_Geography__c): '';
                    }
                    else{
                        dsr.addError('You cannot create a request for this region.');
                    }
                }
            }


            //Assigning primary SE to a User/Queue based on the DGRAT.
            /*for(Id accId : accountIdToDsrList.keyset()){
                for(Deal_Support_Request__c dsr : accountIdToDsrList.get(accId)){
                    if(dsr.Request_Type__c  == 'Solution Engineer'){
                        if(accIdToAccount.get(accId) != null && graztToQueueValue.containsKey(accIdToAccount.get(accId).GRAZT__c)){ 
                            
                            dsr.SE__c = ownerNotAssignedUserId;
                            dsr.Queue__c = graztToQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[0];
                            dsr.Queue_DL__c = graztToQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[1];
                           
                        }
                        else{
                            dsr.addError('You cannot create a Solution Engineer request for this region.');
                        }
                    }
                    //update DSR with Queue DL for sending reminder emails <T01>
                    else if(dsr.Request_Sub_Type__c == 'Gating Review'|| dsr.Request_Sub_Type__c =='Integration Review'){   
                        dsr.Queue_DL__c = (mapGeoQueueDL?.get(dsr.Account_Geography__c) !=null)?mapGeoQueueDL?.get(dsr.Account_Geography__c): '';               
                    }
                    else if(dsr.Request_Type__c  == 'VSE'){
                        if(accIdToAccount.get(accId) != null && graztToVSEQueueValue.containsKey(accIdToAccount.get(accId).GRAZT__c)){ 
                            
                            dsr.SE__c = ownerNotAssignedUserId;
                            dsr.Queue__c = graztToVSEQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[0];
                            dsr.Queue_DL__c = graztToVSEQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[1];
                           
                        }
                        else{
                            dsr.addError('You cannot create a VSE request for this region.');
                        }
                    }
                    else if(dsr.Request_Type__c  == 'Enterprise Security Architects - Fraud'){
                        if(accIdToAccount.get(accId) != null && graztToESAQueueValue.containsKey(accIdToAccount.get(accId).GRAZT__c)){ 
                            
                            dsr.SE__c = ownerNotAssignedUserId;
                            dsr.Queue__c = graztToESAQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[0];
                            dsr.Queue_DL__c = graztToESAQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[1];
                           
                        }
                        else{
                            dsr.addError('You cannot create a ESA request for this region.');
                        }
                    }
                    else if(dsr.Request_Type__c  == 'Web Performance Architect'){
                        if(accIdToAccount.get(accId) != null && graztToWPAQueueValue.containsKey(accIdToAccount.get(accId).GRAZT__c)){ 
                            
                            dsr.SE__c = ownerNotAssignedUserId;
                            dsr.Queue__c = graztToWPAQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[0];
                            dsr.Queue_DL__c = graztToWPAQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[1];
                           
                        }
                        else{
                            dsr.addError('You cannot create a WPA request for this region.');
                        }
                    }
                    else if(dsr.Request_Type__c  == 'Enterprise Security Architect - Prolexic'){
                        if(accIdToAccount.get(accId) != null && graztToESAProlexicQueueValue.containsKey(accIdToAccount.get(accId).GRAZT__c)){ 
                            
                            dsr.SE__c = ownerNotAssignedUserId;
                            dsr.Queue__c = graztToESAProlexicQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[0];
                            dsr.Queue_DL__c = graztToESAProlexicQueueValue.get(accIdToAccount.get(accId).GRAZT__c).split(':')[1];
                           
                        }
                        else{
                            dsr.addError('You cannot create a Enterprise Security Architect - Prolexic request for this region.');
                        }
                    }
                    else{
                        dsr.addError('You cannot create a request for this region.');
                    }
                }
            }*/
        }
    }
    
    /*
    // SFDC-7055 : Reset primary SE when new request-type is changed
    public static void actionRequestTypeChange(List<Deal_Support_Request__c> dsrList){

        String mediaQueueUserId = GsmUtilClass.getGSMSettingValue('DSR_PreSales_MediaTCQueueUser');
        String webQueueUserId = GsmUtilClass.getGSMSettingValue('DSR_PreSales_WebVSEQueueUser');
        for(Deal_Support_Request__c dsr : dsrList){
            if(dsr.Request_Type__c  == 'Web VSE'){
                dsr.SE__c = webQueueUserId;
                dsr.POC_Status__c = 'New';
                dsr.Validation_Override__c = true;
            }
            else if(dsr.Request_Type__c  == 'Media Technical Consultant'){
                dsr.SE__c = mediaQueueUserId;
                dsr.POC_Status__c = 'New';
                dsr.Validation_Override__c = true;
            }
        }
    }*/
    
    
    
    // SFDC-7055 : Perform various Status change tasks
    public static void populatePrimarySEOnStatusChange(List<Deal_Support_Request__c> dsrList){
        
        List<Deal_Support_Request__c> completedDsrList = new List<Deal_Support_Request__c>();
        List<String> completedDsrIdList = new List<String>();
        
        for(Deal_Support_Request__c dsr : dsrList){
            
            // SFDC-7055 : Validate if status = 'Completed', report must be attached
            if(dsr.POC_Status__c == 'Completed' && dsr.Request_Type__c == 'VSE'){
                completedDsrList.add(dsr);
                completedDsrIdList.add(dsr.id);
            }
            /* SFDC-7055 : Status to 'In Progress' ; change Primary SE to logged-in User
            else if(dsr.POC_Status__c == 'In Progress' && dsr.SE__c != UserInfo.getUserId() && dsr.Request_Sub_Type__c != 'Gating Review' && dsr.Request_Sub_Type__c !='Integration Review')	
                {
               dsr.SE__c = UserInfo.getUserId();
            }*/
        }
        
        Map<String,ContentDocumentLink> dsrToAttachments = new Map<String,ContentDocumentLink>();
        if(completedDsrIdList.size()>0){
            for( ContentDocumentLink cdl : [SELECT ContentDocumentId,LinkedEntityId
                                                    FROM ContentDocumentLink 
                                                WHERE LinkedEntityId in :completedDsrIdList]){
                   dsrToAttachments.put(cdl.LinkedEntityId,cdl);
            }
            for(Deal_Support_Request__c dsr : completedDsrList ){
                if(dsrToAttachments.get(dsr.id) == null && !dsr.Validation_Override__c && validationOverrideFirstRunFlag){
                    
                    dsr.addError('Please attach the relevant report in order to complete this request');              
                }
            }
        }  
        validationOverrideFirstRunFlag = false;       
    }


    public static void changeStatustoInProgress(List<Deal_Support_Request__c> dsrList){
        for(Deal_Support_Request__c dsr : dsrList){
            dsr.POC_Status__c = 'In Progress';
        }
    }

    @future
    public static void updateSEManagerOnDSR(List<Id> managerChangedUsers){
        if(!updateSEManagerOnDSRFirstRunFlag)
            return;
        Map<Id,User> userIdToUserRecord = new Map<Id,User>();
        for(User u : [SELECT Id, ManagerId, Manager.ManagerId FROM User WHERE ID IN : managerChangedUsers]){
            userIdToUserRecord.put(u.Id,u);
        }
        List<Deal_Support_Request__c> dsrToUpdate = new List<Deal_Support_Request__c>();
        for(Deal_Support_Request__c dsr : [SELECT Id, SE__c, SE_Manager__c, SE_Manager_s_Manager__c FROM Deal_Support_Request__c WHERE Request_Type__c = 'POC' AND POC_Status__c = 'Planned' AND (SE__c IN : managerChangedUsers OR SE_Manager__c IN : managerChangedUsers)]){
            if(userIdToUserRecord.containsKey(dsr.SE__c)){
                dsr.SE_Manager__c = userIdToUserRecord.get(dsr.SE__c).ManagerId;
                dsr.SE_Manager_s_Manager__c = userIdToUserRecord.get(dsr.SE__c).Manager.ManagerId;
            }
            if(userIdToUserRecord.containsKey(dsr.SE_Manager__c)){
                dsr.SE_Manager_s_Manager__c = userIdToUserRecord.get(dsr.SE_Manager__c).ManagerId;
            }
            dsrToUpdate.add(dsr);
        }
        if(dsrToUpdate.size() > 0)
            GsmUtilClass.doDatabaseUpdate(dsrToUpdate,'AccountPlanTriggerClass','updateSEManagerOnDSR');
        updateSEManagerOnDSRFirstRunFlag = false;
    }

    public static void insertOTM(List<Deal_Support_Request__c> dsrList){

        List<OpportunityTeamMember> otmToUpsert = new List<OpportunityTeamMember>();

        for(Deal_Support_Request__c dsr : dsrList){
            OpportunityTeamMember otm = new OpportunityTeamMember();
            otm.OpportunityId = dsr.Opportunity__c;
            otm.TeamMemberRole = 'Pre-Sales Specialist';
            otm.UserId = dsr.SE__c;
            otm.OpportunityAccessLevel = 'Read';
            otmToUpsert.add(otm);
        }

        if(otmToUpsert.size() > 0){
            GsmUtilClass.doDatabaseUpsert(otmToUpsert,'DealSupportRequestTriggerClass','Upsert OTM', true);
        }
    }

    public static void sendEmail(List<Deal_Support_Request__c> dsrList){

        if(!sendDSREmailFirstRunFlag){
            return;
        }

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<String, EmailTemplate> statusToEmailTemplateMap = new Map<String, EmailTemplate>();

        List<String> emailTemplateDevNames = GsmUtilClass.getGSMSettingValue('Email_Templates_For_DSR').split(',');
        List<String> stages = GsmUtilClass.getGSMSettingValue('DSR_Stages_For_Sending_Emails').split(',');
        Id dummyContactId = Id.valueOf(GsmUtilClass.getGSMSettingValue('Dummy_Contact_ID'));

        for(EmailTemplate em : [select Id, Name, DeveloperName, Subject, HtmlValue, Body from EmailTemplate where DeveloperName IN :emailTemplateDevNames]){
            for(String stage : stages){
                if(em.Name.contains(stage)){
                    statusToEmailTemplateMap.put(stage, em);
                }
            }
        }
        System.debug('statusToEmailTemplateMap:'+statusToEmailTemplateMap);
        System.debug('dsrList:'+dsrList);
        for(Deal_Support_Request__c dsr : dsrList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(statusToEmailTemplateMap.get(dsr.POC_Status__c).Id);
            mail.setTargetObjectId(dummyContactId);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setWhatId(dsr.id);
            if('New,In Progress'.contains(dsr.POC_Status__c)){
                mail.setToAddresses(new List<String>{dsr.Queue_DL__c});
            }
            else{
                mail.setToAddresses(new List<Id>{dsr.SE__c});
            }
            mail.setCcAddresses(new List<Id>{dsr.ownerId});
            mail.setSaveAsActivity(false);
            emailList.add(mail);
        }
        System.debug('emailList:'+emailList);
        if(emailList.size() > 0){
            Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList, false);
            System.debug('result**'+r);
        }
        
        sendDSREmailFirstRunFlag = false;
    }

    public static void sendEmailToChangedPrimarySE( Map<Id, Deal_Support_Request__c> dsrOldMap, List<Deal_Support_Request__c> dsrNewMapList){

        if(!sendEmailToChangedPrimarySEFlag){
            return;
        }

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        Id dummyContactId = Id.valueOf(GsmUtilClass.getGSMSettingValue('Dummy_Contact_ID'));
        EmailTemplate template = [select Id, Name, DeveloperName, Subject, HtmlValue, Body from EmailTemplate where DeveloperName = 'DSR_SE_Changed_For_ETG_and_STG' limit 1];

        for(Deal_Support_Request__c dsr : dsrNewMapList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(template.id);
            mail.setTargetObjectId(dummyContactId);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setWhatId(dsr.id);
            mail.setToAddresses(new List<Id>{dsr.SE__c});
            mail.setCcAddresses(new List<Id>{dsrOldMap.get(dsr.id).SE__c});
            mail.setSaveAsActivity(false);
            emailList.add(mail);
        }

        if(emailList.size() > 0){
            Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList, false);
            System.debug('result**'+r);
        }

        sendEmailToChangedPrimarySEFlag = false;
    }

    public static void updateChimeApprovalStatus(List<Deal_Support_Request__c> lstDSRs){

        Map<Id,CHIME__c> mapUpdateChime = new Map<Id,CHIME__c>();
        Set<Id> chimeIds = new Set<Id> ();
        Map<Id,String> mapChimeProducts = new Map<Id,String> ();

        for(Deal_Support_Request__c dsr : lstDSRs){
            if(dsr.Approval_Status__c != null){
                chimeIds.add(dsr.CHIME__c);
                CHIME__c chime = new CHIME__c(Id= dsr.CHIME__c);
                chime.Product_Approval_Status__c = dsr.Request_Sub_Type__c+' ' +dsr.Approval_Status__c;
                if(!mapUpdateChime.containsKey(dsr.CHIME__c)){
                    mapUpdateChime.put(dsr.CHIME__c,chime);
                }
            }
        }


        for(Chime_Product_Association__c cpa : [SELECT Id,CHIME__c,CHIME_Product__r.Name,CHIME_Product__r.Product_Name__c, Required_answer_on_product__c
                    FROM Chime_Product_Association__c 
                    WHERE CHIME__c IN :chimeIds AND CHIME_Product__r.Approval_Required__c =true] ){
            
            if( mapChimeProducts.containskey( cpa.CHIME__c)){
                mapChimeProducts.put(cpa.CHIME__c, mapChimeProducts.get(cpa.CHIME__c)+';'+cpa.CHIME_Product__r.Product_Name__c);
            }
            else{
                mapChimeProducts.put(cpa.CHIME__c,cpa.CHIME_Product__r.Product_Name__c);
            }
        }


        if(mapUpdateChime?.values()?.size()>0){

            for( CHIME__c chime :mapUpdateChime.values() ){
                if( chime.Product_Approval_Status__c.contains('Approval Pending') && mapChimeProducts?.get(chime.Id)!=null){
                    chime.Prolexic_Products__c = mapChimeProducts?.get(chime.Id);
                }
            }
            update mapUpdateChime.values();
        }
    }


    //Update approval comments on DSR NOtes <T01>
    public static void ProcessApprovalComments  (Map<Id,Deal_Support_Request__c> mapDSRs) 
    {

        if (!mapDSRs.isEmpty())  
        {
            // Get the most recent approval process instance for the object.
            // If there are some approvals to be reviewed for approval, then
            // get the most recent process instance for each object.
            List<Id> processInstanceIds = new List<Id>{};
            
            for (Deal_Support_Request__c dsr : [SELECT (SELECT ID
                                                    FROM ProcessInstances
                                                    ORDER BY CreatedDate DESC
                                                    LIMIT 1)
                                            FROM Deal_Support_Request__c
                                            WHERE ID IN :mapDSRs.keySet()])
            {
                processInstanceIds.add(dsr.ProcessInstances[0].Id);
            }
            
            // Now that we have the most recent process instances, we can check
            // the most recent process steps for comments.  
            for (ProcessInstance pi : [SELECT TargetObjectId,
                                        (SELECT Id, StepStatus, Comments 
                                            FROM Steps
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1 )
                                    FROM ProcessInstance
                                    WHERE Id IN :processInstanceIds
                                    ORDER BY CreatedDate DESC])   
            {                   
                if (pi.Steps != null &&  pi.Steps.size()>0){
            
                    if(pi.Steps[0].Comments == null || 
                            pi.Steps[0].Comments.trim().length() == 0)
                        {
                            if(mapDSRs.get(pi.TargetObjectId).Approval_Status__c == 'Rejected'){
                                mapDSRs.get(pi.TargetObjectId).addError(
                            'Operation Cancelled: Please provide a rejection reason!');
                            }
                            else if(mapDSRs.get(pi.TargetObjectId).Approval_Status__c == 'Approved'){
                                mapDSRs.get(pi.TargetObjectId).SE__c = UserInfo.getUserId(); 
                            }
                        }else if(pi.Steps[0].StepStatus != 'Started'){
                                mapDSRs.get(pi.TargetObjectId).Notes__c += '\n'+System.now()+ ' '+mapDSRs.get(pi.TargetObjectId).Approval_Status__c+' Comments : '+ pi.Steps[0].Comments;
                                if(mapDSRs.get(pi.TargetObjectId).Approval_Status__c == 'Approved'){
                                    mapDSRs.get(pi.TargetObjectId).SE__c = UserInfo.getUserId(); 
                                }
                        }
                }  
            }
        }
    }

    //Update approval comments on DSR NOtes for  resubmitted comments <T01>
    @future
    public static void ProcessApprovalCommentsFuture  (Set<Id> setDSRs) 
    {
        Map<Id,Deal_Support_Request__c> mapDSRs = new Map<Id,Deal_Support_Request__c>();
        List<Deal_Support_Request__c> lstUpdateDSRs = new List<Deal_Support_Request__c>();

        if (!setDSRs.isEmpty())  
        {
            // Get the most recent approval process instance for the object.
            // If there are some approvals to be reviewed for approval, then
            // get the most recent process instance for each object.
            List<Id> processInstanceIds = new List<Id>{};
            
            for (Deal_Support_Request__c dsr : [SELECT Id, Approval_Status__c, Notes__c,(SELECT ID
                                                    FROM ProcessInstances
                                                    ORDER BY CreatedDate DESC
                                                    LIMIT 1)
                                            FROM Deal_Support_Request__c
                                            WHERE ID IN :setDSRs])
            {
                processInstanceIds.add(dsr.ProcessInstances[0].Id);
                mapDSRs.put(dsr.Id,dsr);
            }
            
            // Now that we have the most recent process instances, we can check
            // the most recent process steps for comments.  
            for (ProcessInstance pi : [SELECT TargetObjectId,
                                        (SELECT Id, StepStatus, Comments 
                                            FROM Steps
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1 )
                                    FROM ProcessInstance
                                    WHERE Id IN :processInstanceIds
                                    ORDER BY CreatedDate DESC])   
            {   

                if (pi.Steps != null &&  pi.Steps.size()>0 &&
                    pi.Steps[0].StepStatus=='Started' && 
                    pi.Steps[0].Comments != null && pi.Steps[0].Comments.trim().length() > 0)
                {            

                    Deal_Support_Request__c updateDSR = new Deal_Support_Request__c(Id= pi.TargetObjectId);
                    updateDSR.Notes__c = mapDSRs.get(pi.TargetObjectId).Notes__c + '\n'+System.now()+ ' Submitted Comments : '+ pi.Steps[0].Comments;
                    lstUpdateDSRs.add(updateDSR);
                }  


            }

            if(lstUpdateDSRs.size()>0){
                update lstUpdateDSRs;
            }
        }
    }
}