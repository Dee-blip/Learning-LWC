public class SC_SOCC_RUNBOOK_Print_PDF {

    //Determines what kind of rendering to use for the page request
    public static Map<String,String> handlerFieldsMap{get;set;}
    public static String lightningBaseURL{get;set;}
    public static String communityBaseURL{get;set;}
    public List<SHMapPrintPDFWrapper> shMapList {get; set;}
    
    public class SHMapPrintPDFWrapper 
    {
        @AuraEnabled public SC_SOCC_Situation_to_Handler_Mapping__c SHMap{get;set;}
        @AuraEnabled public Handler__c Handler{get;set;}
        @AuraEnabled public Integer EscConLength{get;set;}
        @AuraEnabled public Integer EscConViaEmailLength{get;set;}
        @AuraEnabled public List<SC_SOCC_Escalation_Contact__c> EscalationContact{get;set;}
        @AuraEnabled public List<SC_SOCC_Escalation_via_Case_Email__c> EscalationContactViaEmail{get;set;}
        @AuraEnabled public String SituationNameList {get;set;}
        @AuraEnabled public Map<SC_SOCC_Escalation_Contact__c, List<SC_SOCC_Availability__c>> availabilityMap {get;set;}
        @AuraEnabled public Map<SC_SOCC_Escalation_Contact__c, Map<String,String>> availabilityColorMap {get;set;}//ESESP-5132
    }
    
    public SC_SOCC_RUNBOOK_Print_PDF(ApexPages.StandardController stdController){
        String PDId = Apexpages.currentPage().getParameters().get('id');
        String active = Apexpages.currentPage().getParameters().get('activeSections');
        system.debug('PDId : '+PDId);
        system.debug('active : '+active);
        List<Id> shMapIdList = (List<Id>)active.split(',');

        shMapList = new List<SHMapPrintPDFWrapper>();
        shMapList.addAll(SC_SOCC_RUNBOOK_Print_PDF.getSituationToHandlerMappingsHandler(PDId,shMapIdList));
        SC_SOCC_RUNBOOK_Print_PDF.getHandlerFieldMappings();
    }
    public SC_SOCC_RUNBOOK_Print_PDF() {
        List<SC_Utility__mdt> scUtilityList = [SELECT Id, DeveloperName, Active__c, Value_Text__c FROM SC_Utility__mdt WHERE Active__c = TRUE AND DeveloperName in ('Lightning_Base_URL','Community_Runbook_URL')];
        for(SC_Utility__mdt scUtil: scUtilityList){
            if(scUtil.DeveloperName == 'Lightning_Base_URL'){
                lightningBaseURL = scUtil.Value_Text__c;
            }
            else if(scUtil.DeveloperName == 'Community_Runbook_URL'){
                communityBaseURL = scUtil.Value_Text__c;
            }
        }
    }
    @AuraEnabled
    public static void getHandlerFieldMappings()
    {
        handlerFieldsMap = new Map<String,String>();
        for(Handler_Type__c eachType : [select id,name, Fields_To_Show__c from  Handler_Type__c]){
            handlerFieldsMap.put(eachType.name,eachType.Fields_To_Show__c);
        }
    }
    public static List<SHMapPrintPDFWrapper> getSituationToHandlerMappingsHandler(Id pdId, List<Id> shMapIdList)
    {
        List<SC_SOCC_Situation_to_Handler_Mapping__c> shmapList = [Select Id,Situation__r.Name, Handler__r.Name,Handler__c,CreatedBy.Name,CreatedDate, Policy_Domain__c from SC_SOCC_Situation_to_Handler_Mapping__c where Policy_Domain__c =: pdId and id in:(shMapIdList)];
        Map<Id,SC_SOCC_Situation_to_Handler_Mapping__c> handlerIdShMap = new Map<Id,SC_SOCC_Situation_to_Handler_Mapping__c>();
        Map<Id,List<String>> handlerSituationNameMap = new Map<Id,List<String>>();
        List<SC_SOCC_Escalation_Contact__c> escalationContactList = new List<SC_SOCC_Escalation_Contact__c>();
        List<SC_SOCC_Escalation_via_Case_Email__c > escalationContactViaEmailList = new List<SC_SOCC_Escalation_via_Case_Email__c >();
        Map<Id,Handler__c> esclationIdHandlerMap = new Map<Id,Handler__c>();
        Map<Id,Handler__c> handlerIdHandlerMap = new Map<Id,Handler__c>();
        Map<Id,List<SC_SOCC_Escalation_Contact__c>> esclationIdContListMap = new  Map<Id,List<SC_SOCC_Escalation_Contact__c>>();
        Map<Id,List<SC_SOCC_Escalation_via_Case_Email__c>> esclationIdContViaEmailListMap = new  Map<Id,List<SC_SOCC_Escalation_via_Case_Email__c>>();
        Set<Id> existingHandlerIdSet = new Set<Id>();
        Map<Id,Id> handlerescalationIdMap = new Map<Id,Id>();
        List<SHMapPrintPDFWrapper> SHMapPrintPDFWrapperList = new List<SHMapPrintPDFWrapper>();
        Set<Id> escConIdSet = new Set<Id>();
        Set<Id> sAvailableConId = new Set<Id>();
        Map<Id, SC_SOCC_Escalation_Contact__c> mConIdEscConRec = new Map<Id, SC_SOCC_Escalation_Contact__c>();
        Map<SC_SOCC_Escalation_Contact__c, List<SC_SOCC_Availability__c>> mConIdLAvailibilityRecs = new Map<SC_SOCC_Escalation_Contact__c, List<SC_SOCC_Availability__c>>();
        
        for(SC_SOCC_Situation_to_Handler_Mapping__c shmap:shmapList)
        {
            handlerIdShMap.put(shmap.Handler__c,shmap);
            
            if(handlerSituationNameMap.get(shmap.Handler__c) != null)
            {
                List<String> tempList = handlerSituationNameMap.get(shmap.Handler__c);
                tempList.add(shmap.Situation__r.Name);
                handlerSituationNameMap.put(shmap.Handler__c,tempList);
            }
            else{
                handlerSituationNameMap.put(shmap.Handler__c,new List<String>{shmap.Situation__r.Name});
                
            }
        }
        List<Handler__c> handlerList = [Select Id, Name,Escalation_List__c,Escalation_List__r.Name,Escalation_List__r.Instructions__c,Escalation_List__r.CreatedBy.Name,Handler_Type__r.Name,CreatedBy.Name,LastModifiedDate,Situation_Instruction__c,Ignore_Condition__c from Handler__c where id in:handlerIdShMap.keySet()];
        for(Handler__c varHandler:handlerList)
        {
            esclationIdHandlerMap.put(varHandler.Escalation_List__c, varHandler);
            handlerIdHandlerMap.put(varHandler.Id,varHandler);
            handlerescalationIdMap.put(varHandler.Id, varHandler.Escalation_List__c);
        }
        
        escalationContactList = [SELECT Id, Name, Order_Number__c,Escalation_List__c, Authorized_Contact__r.Contact_Name__r.Name,Authorized_Contact__r.Contact_Name__r.Email,
                                 Authorized_Contact__r.Contact_Name__r.Primary_Contact_Method__c,Authorized_Contact__r.Contact_Name__r.Secondary_Contact_Method__c,
                                 Authorized_Contact__r.Contact_Name__r.Phone, Authorized_Contact__r.Contact_Name__r.MobilePhone, Action_If_Unreachable__c,Authorized_Contact__r.Contact_Name__c,
                                 Escalation_List__r.Policy_Domain__c,Escalation_List__r.Id
                                                               FROM SC_SOCC_Escalation_Contact__c where Escalation_List__c in:esclationIdHandlerMap.keySet() ORDER BY Order_Number__c];
        for(SC_SOCC_Escalation_Contact__c escContact:escalationContactList)
        {
            mConIdEscConRec.put(escContact.Authorized_Contact__r.Contact_Name__c, escContact);
            escConIdSet.add(escContact.Authorized_Contact__r.Contact_Name__c);
            List<String> emailSplitList = new List<String>();
            
            if(escContact.Authorized_Contact__r.Contact_Name__r.Phone != null && (escContact.Authorized_Contact__r.Contact_Name__r.Phone).length() > 6){
                String phoneNumber = escContact.Authorized_Contact__r.Contact_Name__r.Phone;
                escContact.Authorized_Contact__r.Contact_Name__r.Phone = phoneNumber.substring(0,6)+ ' ' +phoneNumber.substring(6);
            }
            if(escContact.Authorized_Contact__r.Contact_Name__r.MobilePhone != null && (escContact.Authorized_Contact__r.Contact_Name__r.MobilePhone).length() > 6){
                String mobileNumber = escContact.Authorized_Contact__r.Contact_Name__r.MobilePhone;
                escContact.Authorized_Contact__r.Contact_Name__r.MobilePhone = mobileNumber.substring(0,6)+ ' ' +mobileNumber.substring(6);
            }
            
            if(escContact.Authorized_Contact__r.Contact_Name__r.Email != null)
                emailSplitList = escContact.Authorized_Contact__r.Contact_Name__r.Email.split('@');
            
            if(emailSplitList.size() > 0)
                escContact.Authorized_Contact__r.Contact_Name__r.Email = emailSplitList[0]+'@ '+emailSplitList[1];
            
            if(esclationIdContListMap.get(escContact.Escalation_List__c)!=null)
            {
                List<SC_SOCC_Escalation_Contact__c> tempList = esclationIdContListMap.get(escContact.Escalation_List__c);
                tempList.add(escContact);
                esclationIdContListMap.put(escContact.Escalation_List__c,tempList);
            }
            else
            {
                esclationIdContListMap.put(escContact.Escalation_List__c,new List<SC_SOCC_Escalation_Contact__c>{escContact});
            }
        }
        
        escalationContactViaEmailList = [SELECT Id, Name,Escalation_List__c, Authorized_Contact__r.Contact_Name__r.Name,Authorized_Contact__r.Contact_Name__r.Email,
                                         Authorized_Contact__r.Contact_Name__r.SMS_Notifications__c,Authorized_Contact__r.Policy_Domain__r.Account_Name__r.Name,
                                         Authorized_Contact__r.Policy_Domain__r.Service_Account__r.Name
                                                               FROM SC_SOCC_Escalation_via_Case_Email__c where Escalation_List__c in:esclationIdHandlerMap.keySet()];
        
        for(SC_SOCC_Escalation_via_Case_Email__c escContact:escalationContactViaEmailList)
        {
            if(esclationIdContViaEmailListMap.get(escContact.Escalation_List__c)!=null)
            {
                List<SC_SOCC_Escalation_via_Case_Email__c> tempList = esclationIdContViaEmailListMap.get(escContact.Escalation_List__c);
                tempList.add(escContact);
                esclationIdContViaEmailListMap.put(escContact.Escalation_List__c,tempList);
            }
            else
            {
                esclationIdContViaEmailListMap.put(escContact.Escalation_List__c,new List<SC_SOCC_Escalation_via_Case_Email__c>{escContact});
            }
        }
        
        for(SC_SOCC_Availability__c eachRec : [SELECT Id, Availability__c, Contact__c, Day_Of_Week__c, End_Time__c, Start_Time__c FROM SC_SOCC_Availability__c WHERE Contact__c in :escConIdSet ORDER BY Day_Of_Week__c]){
            
            if(!mConIdLAvailibilityRecs.containsKey(mConIdEscConRec.get(eachRec.Contact__c))){
                mConIdLAvailibilityRecs.put(mConIdEscConRec.get(eachRec.Contact__c),  new List<SC_SOCC_Availability__c>());
            }
            List<SC_SOCC_Availability__c> lAvailability = mConIdLAvailibilityRecs.get(mConIdEscConRec.get(eachRec.Contact__c));
            lAvailability.add(eachRec);
            mConIdLAvailibilityRecs.put(mConIdEscConRec.get(eachRec.Contact__c), lAvailability);
            
            /*if(!mConIdLAvailibilityRecs.containsKey(eachRec.Contact__c)){
                mConIdLAvailibilityRecs.put(eachRec.Contact__c,  new List<SC_SOCC_Availability__c>());
            }
            List<SC_SOCC_Availability__c> lAvailability = mConIdLAvailibilityRecs.get(eachRec.Contact__c);
            lAvailability.add(eachRec);
            mConIdLAvailibilityRecs.put(eachRec.Contact__c, lAvailability);*/
            
            Datetime currentDateTime = System.now();
            String currentDay = currentDateTime.format('EEEE');
            Long currentTimeInMS = currentDateTime.hourGmt()*60*60*1000 + currentDateTime.minuteGmt()*60*1000 + currentDateTime.secondGmt()*100 + currentDateTime.millisecondGmt();
            Long startTimeInMS = 0;
            Long endTimeInMS = 0;
            if(eachRec.Start_Time__c != null)
                startTimeInMS = eachRec.Start_Time__c.hour()*60*60*1000 + eachRec.Start_Time__c.minute()*60*1000 + eachRec.Start_Time__c.second()*100 + eachRec.Start_Time__c.millisecond();
            if(eachRec.End_Time__c != null)
                endTimeInMS = eachRec.End_Time__c.hour()*60*60*1000 + eachRec.End_Time__c.minute()*60*1000 + eachRec.End_Time__c.second()*100 + eachRec.End_Time__c.millisecond();
            
            if(eachRec.Day_Of_Week__c == currentDay && (eachRec.Availability__c == 'All Day' || (eachRec.Availability__c == 'Specific Time' && startTimeInMS < currentTimeInMS && currentTimeInMS < endTimeInMS)))
                sAvailableConId.add(eachRec.Contact__c);
        }
        
        for(SC_SOCC_Situation_to_Handler_Mapping__c shmap:shmapList)
        {
            System.debug('1.Number of Queries used in this apex code so far: 1' + Limits.getQueries());
            if(!existingHandlerIdSet.contains(shmap.Handler__c)){
                SHMapPrintPDFWrapper shMapPrintPDFWrap = new SHMapPrintPDFWrapper();
                shMapPrintPDFWrap.Handler = handlerIdHandlerMap.get(shmap.Handler__c) ;
                shMapPrintPDFWrap.EscConLength = 0;
                shMapPrintPDFWrap.EscConViaEmailLength = 0;
                shMapPrintPDFWrap.availabilityMap = new Map<SC_SOCC_Escalation_Contact__c, List<SC_SOCC_Availability__c>>();
                shMapPrintPDFWrap.availabilityColorMap = new Map<SC_SOCC_Escalation_Contact__c, Map<String,String>>();
                        
                shMapPrintPDFWrap.EscalationContact=esclationIdContListMap.get(handlerescalationIdMap.get(shmap.Handler__c));
                if((esclationIdContListMap.get(handlerescalationIdMap.get(shmap.Handler__c))) != null)
                    shMapPrintPDFWrap.EscConLength = (esclationIdContListMap.get(handlerescalationIdMap.get(shmap.Handler__c))).size();
                
                shMapPrintPDFWrap.EscalationContactViaEmail=esclationIdContViaEmailListMap.get(handlerescalationIdMap.get(shmap.Handler__c));
                if((esclationIdContViaEmailListMap.get(handlerescalationIdMap.get(shmap.Handler__c))) != null)
                    shMapPrintPDFWrap.EscConViaEmailLength = (esclationIdContViaEmailListMap.get(handlerescalationIdMap.get(shmap.Handler__c))).size();
                
                shMapPrintPDFWrap.SHMap = shmap;
                shMapPrintPDFWrap.SituationNameList = string.join(handlerSituationNameMap.get(shmap.Handler__c),',');
                /*if(mConIdLAvailibilityRecs.keySet().size() > 0){
                    shMapPrintPDFWrap.availabilityMap = mConIdLAvailibilityRecs;
                }*/
                if(shMapPrintPDFWrap.EscalationContact != null){
                    for(SC_SOCC_Escalation_Contact__c eachEscCon : shMapPrintPDFWrap.EscalationContact){
                        if(mConIdLAvailibilityRecs.containsKey(eachEscCon)){
                            shMapPrintPDFWrap.availabilityMap.put(eachEscCon,mConIdLAvailibilityRecs.get(eachEscCon));
                        }
                        else{
                            shMapPrintPDFWrap.availabilityMap.put(eachEscCon,new List<SC_SOCC_Availability__c>());
                        }
                        
                        //SC_SOCC_RUNBOOK_Print_PDF.createDayColorMap(eachEscCon); 
                        Map<String,String> colorMap = new Map<String,String>();
                        System.debug('1.Number of Queries used in this apex code so far: 2' + Limits.getQueries());
                        colorMap.putAll(SC_SOCC_RUNBOOK_Print_PDF.createDayColorMap(eachEscCon));//.values().replace('background-color:',''); 
                        shMapPrintPDFWrap.availabilityColorMap.put(eachEscCon,colorMap);
                    }
                }
                
                
                SHMapPrintPDFWrapperList.add(shMapPrintPDFWrap);
            }
            existingHandlerIdSet.add(shmap.Handler__c);
        }
        
        system.debug('SHMapPrintPDFWrapperList : '+SHMapPrintPDFWrapperList);
        return SHMapPrintPDFWrapperList;
    }
    

    public static Map<String,String> createDayColorMap(SC_SOCC_Escalation_Contact__c escContact){
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('1.Number of Queries used in this apex code so far: 3' + Limits.getQueries());
        
        //SC_SOCC_EscalationListCtrl.EscalationListWrapper escalationListWrapper = SC_SOCC_EscalationListCtrl.getEscalationContactRecords(String.valueOf(escContact.Escalation_List__r.Policy_Domain__c),String.valueOf(escContact.Escalation_List__r.id),false);
        List < SC_SOCC_EscalationListCtrl.AuthorizedContactWrapper > escAuthWrapperList = new List < SC_SOCC_EscalationListCtrl.AuthorizedContactWrapper >();
        //for(Id ss : escalationListWrapper.lAuthConId){
        //}
        escAuthWrapperList.addAll(SC_SOCC_EscalationListCtrl.getAuthorizedContactRecords(String.valueOf(escContact.Escalation_List__r.Policy_Domain__c),null));
        Map<String,String> dayColorMap = new Map<String,String>();
        
        for(SC_SOCC_EscalationListCtrl.AuthorizedContactWrapper escAuthWrapper : escAuthWrapperList){
            if(escAuthWrapper.authCon.Id == escContact.Authorized_Contact__r.Id){
                dayColorMap.putAll(escAuthWrapper.dayAndColor);
            }
        }
        return dayColorMap;   
    }
}