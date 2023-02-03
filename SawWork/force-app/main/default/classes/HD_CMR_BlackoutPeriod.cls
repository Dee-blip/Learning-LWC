/* 
* File Name: HD_CMR_BlackoutPeriod
* Description : Helpdesk Change Managment System - Service Outages -(Blackout, Enhamnced Review and Conditional Blackout Period) functionalities)
* @author : 
* Modification Log ===============================================================
* Date              Author          Modification
* Aug 08th, 2020    Aneesh Budnar   PRTORES-1810 - Code scanner fixes
*/
public class HD_CMR_BlackoutPeriod {
    
    public static List<BMCServiceDesk__Projected_Service_Outage__c> serviceOutages = null;
    List<BMCServiceDesk__Projected_Service_Outage__c> soutageMatched = new List<BMCServiceDesk__Projected_Service_Outage__c>(); 
    public static  List<BMCServiceDesk__Change_Request__c>  changes = null;
    
    public static List<BMCServiceDesk__Change_Request__c> timeMatchedChanges = new List<BMCServiceDesk__Change_Request__c>();
    public static List<BMCServiceDesk__Projected_Service_Outage__c> timeMatchedSO =  new List<BMCServiceDesk__Projected_Service_Outage__c> ();
    public static List<BMCServiceDesk__Projected_Service_Outage__c> chMatchedSO =  new List<BMCServiceDesk__Projected_Service_Outage__c> ();
    
    public static List<BMCServiceDesk__Change_Request__c> matchedChanges = new List<BMCServiceDesk__Change_Request__c> ();
    public static List<BMCServiceDesk__Change_Request__c> greyoutChanges = new List<BMCServiceDesk__Change_Request__c> ();
    public static List<BMCServiceDesk__Change_Request__c> semiBlackoutChanges = new List<BMCServiceDesk__Change_Request__c> ();
    
    
public  class selectOption
{
    @auraEnabled
    public  String option;
    
     @auraEnabled
    public  String value;
    
    @auraEnabled
    public  Boolean selected;
    
    public selectOption(String opt, String val, Boolean selected){
        this.option = opt;
        this.value = val;
        this.selected = selected;
    }
}
    
    
    @auraEnabled
    public static List<BMCServiceDesk__Change_Request__c> getSOMatchingCMRList(String recordId){
        BMCServiceDesk__Projected_Service_Outage__c so = [SELECT BMCServiceDesk__End_Date__c,BMCServiceDesk__Start_Date__c,Service_Outage_Type__c,	Services_Affected__c,Affected_Services_Picklist__c,
                                                          Sub_Services_Affected__c, Outage_Condition__c FROM BMCServiceDesk__Projected_Service_Outage__c
                                                          WHERE Id = :recordId limit 1
                                                         ];
        
        return matchingCMRList(so.BMCServiceDesk__Start_Date__c, so.BMCServiceDesk__End_Date__c, so.Affected_Services_Picklist__c, so.Sub_Services_Affected__c, so.Outage_Condition__c);
        
    }
    
    
    @auraEnabled
    public static List<BMCServiceDesk__Change_Request__c> getMatchingCMRList(DateTime startdate, DateTime enddate, String services, String subservices, String condition){
        return matchingCMRList(startdate, enddate, services, subservices, condition);
    }
    
    
    public static List<BMCServiceDesk__Change_Request__c> matchingCMRList(DateTime startdate, DateTime enddate, String services, String subservices, String condition){
        List<BMCServiceDesk__Change_Request__c> cmrList =  new  List<BMCServiceDesk__Change_Request__c>();
        List<BMCServiceDesk__Change_Request__c> scmrList;
        if(startdate == null || enddate == null ){
            return cmrList;
        }
        
        String soqlQuery = ' SELECT ID, Name , Service_Element_Impacted__c, Change_Priority__c,HD_Sub_services_Impacted__c,HD_Service_Impacted__c,BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c,PCI_in_scope_service_asset_affecting__c,';
        soqlQuery += ' Change_Summary__c, HD_Change_Status__c, Owner.Name,BMCServiceDesk__Change_Category__c, HD_Owner_Name__c,HD_Change_Impact__c,HD_Facility_Location__c,Customer_Impacted__c,CR_Risk__c,HD_Sponsor_Name__c, SOX_in_scope_service_asset_affecting__c ';
        soqlQuery += ' FROM BMCServiceDesk__Change_Request__c WHERE (BMCServiceDesk__Scheduled_Start_Date__c <= :enddate AND  BMCServiceDesk__Scheduled_END_Date__c >= :startdate ) ';
      
        List<String> arr_services =  new List<String>();
        
        if(services != null && services != ''){
            arr_services =  services.split(';');
            String sstr = ' HD_Service_Impacted__c in :arr_services' ; 
            soqlQuery += ' AND ('+sstr+') ';
        }
        
        System.debug('  BLACKSOQL '+soqlQuery);
        cmrList =  database.query(soqlQuery);
        scmrList = cmrList;
        
        if(subservices != null && subservices != ''){
            scmrList =  new  List<BMCServiceDesk__Change_Request__c>();
            List<String> arr_subservices =  subservices.split(',');
            Boolean is_match = false;
            for(BMCServiceDesk__Change_Request__c chn: cmrList){
                
                for(String str: chn.HD_Sub_Services_Impacted__c.split(';')){
                    
                    for(String st: arr_subservices){
                        if( st == str){
                            is_match = true;
                            break;
                        }
                    }
                    if(is_match == true){
                        scmrList.add(chn);
                        is_match = false;
                        break;
                    }
                }
                
            }
            
           } 
            List<BMCServiceDesk__Change_Request__c> retCMRList = new  List<BMCServiceDesk__Change_Request__c>();
            if(condition != null && condition.trim() != ''){
                integer i = 0;
                Boolean match = false;
                for(SObject cmr: scmrList){
                    
                    match =  evaluateOutageCondition(cmr,condition);
                    if(match == true){
                        retCMRList.add(scmrList[i]);
                    }
                    i += 1;
                }
            }else{
                retCMRList = scmrList;
            }
            
            return  retCMRList ;           
        
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<BMCServiceDesk__Projected_Service_Outage__c> matchingServiceOutage(BMCServiceDesk__Change_Request__c currentCMR) {
        List<BMCServiceDesk__Projected_Service_Outage__c> cmrMatchedSO =  new List<BMCServiceDesk__Projected_Service_Outage__c> ();
		Boolean  servicematched = true;
        for(BMCServiceDesk__Projected_Service_Outage__c sout : [SELECT Name,BMCServiceDesk__End_Date__c,BMCServiceDesk__Start_Date__c,Service_Outage_Type__c,	Services_Affected__c,Affected_Services_Picklist__c,
                                                                    Sub_Services_Affected__c, Outage_Condition__c, BMCServiceDesk__Blackout__c  FROM BMCServiceDesk__Projected_Service_Outage__c
                                                                    WHERE BMCServiceDesk__Inactive__c != true and ( BMCServiceDesk__End_Date__c >= :currentCMR.BMCServiceDesk__Scheduled_Start_Date__c and BMCServiceDesk__Start_Date__c <= :currentCMR.BMCServiceDesk__Scheduled_End_Date__c)
                                                                   ]) {
                if(sout.BMCServiceDesk__Blackout__c  == true) {
                    cmrMatchedSO.add(sout);
                    continue;
                }

                if( (sout.Sub_Services_Affected__c == null || sout.Sub_Services_Affected__c.trim() == '') && sout.Affected_Services_Picklist__c != null && sout.Affected_Services_Picklist__c.trim() != '' && sout.Affected_Services_Picklist__c.split(';').contains(currentCMR.HD_Service_Impacted__c)){
                    cmrMatchedSO.add(sout);
                    continue;
                }
               
                if(sout.Sub_Services_Affected__c != null && sout.Sub_Services_Affected__c.trim() != '') {
                    List<String> subServices =  sout.Sub_Services_Affected__c.split(',');
                    List<String> changesubServices  = currentCMR.HD_Sub_services_Impacted__c.split(';');
                    servicematched = true;
                    if(sout.Affected_Services_Picklist__c != null && sout.Affected_Services_Picklist__c.trim() != '') {
                        if(sout.Affected_Services_Picklist__c.split(';').contains(currentCMR.HD_Service_Impacted__c)) {
                            servicematched = true;
                        }else {
                            servicematched = false;
                        }
                   }
                   if(servicematched == true) {
                        for(String str : subServices){
                            if (changesubServices.contains(str)) {
                                cmrMatchedSO.add(sout);
                                continue;
                            }
                        }
                    }   
                }
               
                SObject sch = currentCMR;
                if(sout.Outage_Condition__c != null && sout.Outage_Condition__c.trim() != '' && evaluateOutageCondition(sch, sout.Outage_Condition__c) ) {
                    cmrMatchedSO.add(sout);
                    continue;
                }
               
                if( (sout.Outage_Condition__c == null || sout.Outage_Condition__c.trim() == '') && ( sout.Sub_Services_Affected__c == null || sout.Sub_Services_Affected__c.trim() == '') && ( sout.Affected_Services_Picklist__c == null || sout.Affected_Services_Picklist__c.trim() == '' )) {
                    cmrMatchedSO.add(sout);
                    continue;
                }
            }
        return cmrMatchedSO;                                                          
    }
    
    public static void matchCMRWithServiceOutage(List<BMCServiceDesk__Change_Request__c> changes, List<BMCServiceDesk__Change_Request__c> oldChanges )
    {
        DateTime dtenow  = DateTime.now();
        DateTime soStart = changes[0].BMCServiceDesk__Scheduled_Start_Date__c;
        DateTime soEnd   = changes[0].BMCServiceDesk__Scheduled_End_Date__c;
        List<Id> secondLevelApprovers = new List<Id>();
        
        for(BMCServiceDesk__Change_Request__c ch : changes){
            if (ch.BMCServiceDesk__Scheduled_Start_Date__c <= soStart){
                soStart = ch.BMCServiceDesk__Scheduled_Start_Date__c;
            }
            
            if(ch.BMCServiceDesk__Scheduled_End_Date__c >= soEnd){
                soEnd = ch.BMCServiceDesk__Scheduled_End_Date__c;
            }
            
            if(ch.Second_Level_Approver__c != null) {
                secondLevelApprovers.add(ch.Second_Level_Approver__c);
            }
        }
        
        System.debug(' IN MATCH '+soStart+' - '+soEnd);
        if(serviceOutages == null){
            serviceOutages = [SELECT Name,BMCServiceDesk__End_Date__c,BMCServiceDesk__Start_Date__c,Service_Outage_Type__c,	Services_Affected__c,Affected_Services_Picklist__c,
                              Sub_Services_Affected__c, Outage_Condition__c, BMCServiceDesk__Blackout__c  FROM BMCServiceDesk__Projected_Service_Outage__c
                              WHERE BMCServiceDesk__Inactive__c != true and ( BMCServiceDesk__End_Date__c >= :soStart and BMCServiceDesk__Start_Date__c <= :soEnd)
                             ];
            
        }
        System.debug(' CMR SO '+serviceOutages.size()); 
        /*Profile communityProfile = [SELECT Id, Name FROM Profile WHERE Name = 'SFCommunityCustomers' LIMIT 1];
        Set<Id> userIds = new Map<Id, User>([SELECT ID, Name FROM USER 
                                             where (title like '%CIO%' or manager.title like '%CIO%' or title like 'Director%' or title like '%Vice President%') 
                                             and isActive = true AND ProfileId != :communityProfile.Id]).keySet(); */
        Map<Id, User> approvers = new Map<Id, User>([SELECT Id, Name, Title, Manager.Title FROM User WHERE Id IN :secondLevelApprovers]);
        
        Id userid = userInfo.getUserId();
        User currentUser = [Select Id,Name, BMCServiceDesk__Schedule_CR_and_Blackouts_During_Overlap__c	 FROM User  where id = :userid ];
        List<String> condition_list =  new List<String>();
        for( BMCServiceDesk__Projected_Service_Outage__c so : serviceOutages){
            
            if(so.Outage_Condition__c != ''){
                condition_list.add( so.Outage_Condition__c );
            }
            
        }
        
        System.debug(' Changes  - '+changes);        
       
        Integer i = 0;
        List<BMCServiceDesk__Change_Request__c> blckoutChanges = new List<BMCServiceDesk__Change_Request__c>();
        List<BMCServiceDesk__Projected_Service_Outage__c> blackoutSO = new  List<BMCServiceDesk__Projected_Service_Outage__c>();
        integer  idx = -1;
        Boolean  servicematched = true;
        for (BMCServiceDesk__Change_Request__c ch : changes){
            idx += 1;
            for( BMCServiceDesk__Projected_Service_Outage__c sout : serviceOutages ){
                
                System.debug('CMR CHECK '+ch.BMCServiceDesk__Scheduled_End_Date__c+' - '+ch.BMCServiceDesk__Scheduled_Start_Date__c+' SO '+sout.Name);
                //System.debug(' APPROVAL STATUS - '+ch.CR_Approval_Status__c+'  -- '+oldChanges[idx].CR_Approval_Status__c);
                 if ( oldChanges != null && !oldChanges.isEmpty() && ( ( ch.CR_Approval_Status__c == 'Recalled' && oldChanges[idx].CR_Approval_Status__c !=  'Recalled' )|| 
                    ( ch.CR_Approval_Status__c == 'Rejected' && oldChanges[idx].CR_Approval_Status__c != 'Rejected')) ) 
                 {
                         continue;
                 }

                 if(oldChanges != null && !oldChanges.isEmpty() && ( oldChanges[idx].CR_Approval_Status__c == 'AUTHORIZED' && ch.CR_Approval_Status__c == 'AUTHORIZED' )){
                    continue;
                 }

                if((ch.BMCServiceDesk__Scheduled_End_Date__c <= sout.BMCServiceDesk__Start_Date__c  ) || ch.BMCServiceDesk__Scheduled_Start_Date__c >=  sout.BMCServiceDesk__End_Date__c )
                {
                    continue;
                } 
                else{

                     System.debug('CMR CHMATCHED '+ch.BMCServiceDesk__Scheduled_End_Date__c+' - '+ch.BMCServiceDesk__Scheduled_Start_Date__c+' SO '+sout.Name);
         
                    if(sout.BMCServiceDesk__Blackout__c  == true){
                         matchedChanges.add(ch);
                         chMatchedSO.add(sout);
              
                    }

                    if( (sout.Sub_Services_Affected__c == null || sout.Sub_Services_Affected__c.trim() == '') && sout.Affected_Services_Picklist__c != null && sout.Affected_Services_Picklist__c.trim() != '' && sout.Affected_Services_Picklist__c.split(';').contains(ch.HD_Service_Impacted__c)){
                        matchedChanges.add(ch);
                        chMatchedSO.add(sout);
                    }
                    
                    if(sout.Sub_Services_Affected__c != null && sout.Sub_Services_Affected__c.trim() != ''){
                        List<String> sub_services =  sout.Sub_Services_Affected__c.split(',');
                        List<String> Changesub_services  = ch.HD_Sub_services_Impacted__c.split(';');
                        servicematched = true;
                        if(sout.Affected_Services_Picklist__c != null && sout.Affected_Services_Picklist__c.trim() != ''){
                           if(sout.Affected_Services_Picklist__c.split(';').contains(ch.HD_Service_Impacted__c)){
                             servicematched = true;
                           }else{
                            servicematched = false;
                           }

                        }
                        if(servicematched == true){
                            for(String str : sub_services){
                                if (Changesub_services.contains(str)){
                                    matchedChanges.add(ch);
                                    chMatchedSO.add(sout);
                                }
                            }
                        }
                        
                    }
                    
                    SObject sch = ch;
                    if(sout.Outage_Condition__c != null && sout.Outage_Condition__c.trim() != '' && evaluateOutageCondition(sch, sout.Outage_Condition__c) ){
                        matchedChanges.add(ch);
                        chMatchedSO.add(sout);
                    }
                    
                   System.debug(' Service Outages HERE - '+sout.Outage_Condition__c+' -- '+sout.Sub_Services_Affected__c+' -- '+sout.Affected_Services_Picklist__c );
                    if( (sout.Outage_Condition__c == null || sout.Outage_Condition__c.trim() == '') && ( sout.Sub_Services_Affected__c == null || sout.Sub_Services_Affected__c.trim() == '') && ( sout.Affected_Services_Picklist__c == null || sout.Affected_Services_Picklist__c.trim() == '' )){
                        System.debug(' Matched  -- '+ch.Name);
                        matchedChanges.add(ch);
                        chMatchedSO.add(sout);
                    }
                    
                }
            }//Service Outage For loop
        }
        i = 0;
        BMCServiceDesk__Change_Request__c changeMatch =  new BMCServiceDesk__Change_Request__c();
        String outagetype = '';
        if( matchedChanges.size() > 0){
            for(i =0 ;i < matchedChanges.size(); i++ ){
                changeMatch = matchedChanges[i];
                System.debug('CMR SOMATCHED '+chMatchedSO[i].Name+' CH '+changeMatch.Change_Summary__c);
                
               
                if( chMatchedSO[i] == null || chMatchedSO[i].Service_Outage_Type__c == null || chMatchedSO[i].Service_Outage_Type__c.trim() == ''){
                    outagetype = '';
                   }else{
                            outagetype = chMatchedSO[i].Service_Outage_Type__c.deleteWhitespace().toLowerCase();
                        }
                
                System.debug('CMR Outage Type -- '+outagetype);
  
                if(chMatchedSO[i].BMCServiceDesk__Blackout__c == true){
                     changeMatch.CR_Approval_Type__c = 'Blackout Period';
                }
                else if(outagetype == 'enhancedreviewperiod' ){
                     changeMatch.CR_Approval_Type__c = 'Enhanced Review Period';
                }
                else if (outagetype == 'conditionalblackoutperiod' ){
                    if(currentUser.BMCServiceDesk__Schedule_CR_and_Blackouts_During_Overlap__c != true ){
                      changeMatch.addError(' Change Request falls under conditional blackout period, change scheduled date time or contact CAB Manager');
                    }
                    changeMatch.CR_Approval_Type__c = 'Conditional Blackout Period';
                    System.debug(' With Error COnd');
                }
                
                    
                if (changeMatch.CR_Approval_Type__c != '' ){
                       if( changeMatch.Second_Level_Approver__c == null ) {
                        changeMatch.addError(' Change Request falls under '+changeMatch.CR_Approval_Type__c+', Please add second level approver who is Direct reports of CIO or a Director');
/*                    }else if ( !userIds.contains(changeMatch.Second_Level_Approver__c) ){*/
                       }else if (changeMatch.Second_Level_Approver__c != null && (!approvers.get(changeMatch.Second_Level_Approver__c).Title.contains('CIO') &&
                                !approvers.get(changeMatch.Second_Level_Approver__c).Manager.Title.contains('CIO') &&
                                !approvers.get(changeMatch.Second_Level_Approver__c).Title.contains('Director') &&
                                !approvers.get(changeMatch.Second_Level_Approver__c).Title.contains('Vice President'))){
                        changeMatch.addError(' Change Request falls under '+changeMatch.CR_Approval_Type__c+', second level approver selected must be Direct reports of CIO or a Director');
                    }
                }
                
                    
                    
            }
            
        }//matched changes
        
        
        //remove approval tag if matching CMR becomes unmatching with service outages
        for(BMCServiceDesk__Change_Request__c ch : changes){
            if(!matchedChanges.contains(ch) && ch.CR_Approval_Type__c != '' ){
                ch.CR_Approval_Type__c = '';
            }
        }
        
        
        
    }//matchCMRWithServiceOutage       
    
    
    public static Boolean evaluateOutageCondition(SObject ch,String condn){
        
        boolean retval = true;
        if(condn == '' || condn == null){
            return true;
        }
        
        System.debug('ABC CONDN INC -'+ch.Id+' CONDN '+condn);
        
        List<String>  out_conditions =  condn.split('&');
        List<String> condn_el;
        String ch_fldval;
        String cnd_opt;
        Boolean  last_eval = null ;
        String   last_operator ;
        for(String cnd : out_conditions){
            if(cnd == 'OR' || cnd == 'AND'){
                last_operator = cnd ;
                continue;    
            }
            
            condn_el =  cnd.split('#');
            
            boolean condn_eval = false;
            if(ch.get(condn_el[0]) == null){
                ch_fldval = ' ';
            }else{
                ch_fldval =  String.valueOf(ch.get(condn_el[0]));
            }
            System.debug(' FLD VAL '+condn_el[0]+' val '+ch_fldval+'  INC '+ch.Id);
            
            if (condn_el[1] == '='){
                if (ch_fldval == condn_el[2]){
                    condn_eval = true;
                }
            }
            if (condn_el[1] == '!='){
                if (ch_fldval != condn_el[2]){
                    condn_eval = true;
                }
                
            }
            if( condn_el[1] == '~' && ch_fldval.contains(condn_el[2]) ){
                condn_eval = true;
            }
            
            if( condn_el[1] == '!~' && !ch_fldval.contains(condn_el[2]) ){
                condn_eval = true;
            }
            
            if (last_operator == 'AND'){
                last_eval = last_eval && condn_eval;
            }else if (last_operator == 'OR'){
                last_eval = last_eval || condn_eval;
            }
            
            if (last_eval == null){
                last_eval = condn_eval;
            }
            
        }
        System.debug('ABC CONDN LAST EVAL - '+ch.id+' - '+last_eval);
        return last_eval;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<BMCServiceDesk__Projected_Service_Outage__c> getServiceOutages(){
        return [select Id,Name,  BMCServiceDesk__Description__c,BMCServiceDesk__End_Date__c,BMCServiceDesk__Start_Date__c,Service_Outage_Type__c,	Services_Affected__c,Affected_Services_Picklist__c,BMCServiceDesk__Inactive__c,
                Sub_Services_Affected__c,BMCServiceDesk__Blackout__c, Outage_Condition__c, Owner.Name FROM BMCServiceDesk__Projected_Service_Outage__c
                Order BY BMCServiceDesk__Start_Date__c DESC  LIMIT 500];
    }
    
    @auraEnabled
    public static BMCServiceDesk__Projected_Service_Outage__c getSO(String recId){
        return [select Id,Name,  BMCServiceDesk__Description__c,BMCServiceDesk__End_Date__c,BMCServiceDesk__Start_Date__c,Service_Outage_Type__c,	Services_Affected__c,Affected_Services_Picklist__c,BMCServiceDesk__Inactive__c,
                Sub_Services_Affected__c,BMCServiceDesk__Blackout__c, Outage_Condition__c, Owner.Name FROM BMCServiceDesk__Projected_Service_Outage__c WHERE ID = :recId][0];
    }
    
    @auraEnabled
    public static BMCServiceDesk__Projected_Service_Outage__c saveSO(String pso){
        
        BMCServiceDesk__Projected_Service_Outage__c serout = (BMCServiceDesk__Projected_Service_Outage__c)JSON.deserialize(pso, BMCServiceDesk__Projected_Service_Outage__c.class);
        System.debug('SR OUTAGE 1'+serout.BMCServiceDesk__Start_Date__c);
     
        insert serout;
        return serout;
    }
    
    @auraEnabled
    public static String deleteSO(String recId){
        BMCServiceDesk__Projected_Service_Outage__c  rec =  [select Id,Name FROM BMCServiceDesk__Projected_Service_Outage__c WHERE ID = :recId];
        String str = rec.Name;
        delete rec;
        return str;  
    }
    
    @auraEnabled
    public static BMCServiceDesk__Projected_Service_Outage__c toggleActiveSO(String recId, Boolean val){
        BMCServiceDesk__Projected_Service_Outage__c  rec =  [select Id,Name,BMCServiceDesk__Inactive__c FROM BMCServiceDesk__Projected_Service_Outage__c WHERE ID = :recId];
        rec.BMCServiceDesk__Inactive__c = val;
        update rec;
        return rec;  
    }
    
    @auraEnabled
    public static String notifyOwner(Id recId){
        BMCServiceDesk__Change_Request__c chr = [SELECT Id,Name,OwnerId, Owner.isActive,Owner.Name,Owner.EMail,HD_Owner_Name__c,HD_Sponsor_Name__c,BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c, HD_Change_Status__c, BMCServiceDesk__Change_Category__c,Change_Summary__c FROM BMCServiceDesk__Change_Request__c WHERE Id = :recId];
        LIST<String> toemails =  new LIST<String>();
        if( chr.Owner.IsActive == true ){
            toemails.add(chr.Owner.EMail);
        }

        List<EmailTemplate> ets = new List<EmailTemplate>();
        ets = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Notify_ServiceOutage_match' Limit 1];
        if( ets.size() < 1 ){
            return 'No Email Template';
        }
        
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(ets[0].Id, chr.OwnerId, chr.Id );

        String emailSubject = email.getSubject();
        String emailTextBody = email.getPlainTextBody();
        
        email.setTargetObjectId(chr.OwnerId);
        email.setSubject(emailSubject);
        email.setPlainTextBody(emailTextBody);
        email.saveAsActivity = false;
        try{
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        allmsg.add(email);
           
        Messaging.sendEmail(allmsg,false);
            System.debug('Mail Sent '+allmsg);
        return 'Email has been sent to '+toemails;
        }catch (Exception e){ 
          System.debug('Mail Error '+e.getMessage());
            return 'error';
        }
        
        
    }
    
    @auraEnabled
    public static List<selectOption> getOptionlist(){
        
       List<SelectOption> options = new List<SelectOption>();
           
       Schema.DescribeFieldResult fieldResult =
       BMCServiceDesk__Projected_Service_Outage__c.Affected_Services_Picklist__c.getDescribe();
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
       for( Schema.PicklistEntry f : ple)
       {
          options.add(new SelectOption(f.getLabel(), f.getValue(),false));
       }      
      return options;
    }
}