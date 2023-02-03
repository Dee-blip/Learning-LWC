/*=====================================================================================================+
Class name          :   SC_Case_LightningUtility 
Author              :   Supreeth,Sumukh,Himanshu
Created             :   10-Sep-18
Purpose             :   This is the main class for Case Record Type Selection and Dynamic Buttons on Lightning Page
1. PS_Lightning_RecordType.cmp - LC Component
2. SC_PS_PageLayout_Buttons.cmp - LC Component


Test Classes
SC_Case_Utility_Lighting_TC
SC_Elevation_TriggerHandler_Test
SC_BillingLightningUtility_Test


Last Modified       Developer           Purpose            
============= ========================  =======
10-SEP-18     Supreeth,Sumukh,Himanshu  Initial Development(Jira Ticket# ESESP-1529)
07-FEB-19     Sumukh SS                 Adding functionality for dynamic buttons for technical record type (ESESP-1973)
15-JUL-19     Sumukh SS                 Adding functionality for dynamic buttons for Managed Security Record Type(ESESP-2198)
7-08-2020     Sharath Prasanna          ESESP-3659: Changes for Billing Case migration: added bulk Clone method
20-02-2021    Aditi Singh               ESESP-3222 : Added to return the Parent case's AccountId to prepopulate in new Related Case from RL button
10-08-2021    Vandhana Krishnamurthy    ESESP-4359 Elevation on Account/Case
25-08-2021    Jay Rathod                ESESP-5716: Added method to get Tools url
9  May 2022	  Vandhana			 		ESESP-6457 ESESP-7167 : Clear SC IP Scrubbed checkbox on cloned Cases
+=====================================================================================================*/
public class SC_Case_LightningUtility {
    
    //Method - 1 : For cloning Case of all record types    
    @AuraEnabled
    public static string cloneCase(string CaseId)
    {   
        Map<String, Schema.SObjectField> objfieldMap = Case.sObjectType.getDescribe().fields.getMap();
        
        String strfieldName = '';
        
        for(Schema.SObjectField Field : objfieldMap.Values()) 
        {
            Schema.DescribeFieldResult fieldResult = Field.getDescribe();
            strfieldName += fieldResult.getName() + ',';
        }
        
        strfieldName = strfieldName.substring(0, strfieldName.length()-1);
        
        case selectedRecord = Database.query('select ' + strfieldName + ' from Case where id= :CaseId'); 
        case casenew = selectedRecord.clone(false,true,false,false);
        //Marking all relevant akam fields null
        casenew.AKAM_Case_ID__c = null;
        casenew.AKAM_Modified_Date__c=null;
        casenew.AKAM_Created_Date__c=null;
        casenew.AKAM_Created_By__c=null;
        casenew.AKAM_Modified_By__c=null;
        casenew.AKAM_Closed_Date__c=null;
        casenew.AKAM_Reopened_Date__c=null;
        insert casenew;
        string newid=casenew.Id;
        return newid;
    }
    //Method - 2 : For deleting cloned Case (cancel)
    
    @AuraEnabled
    public static void DeleteclonedCase(string DeleteCaseId)
    {   
        case deletedrec= [select id from case where id = :DeleteCaseId];
        delete deletedrec;
        
    }
    
    //Method - 3 : For checking if the recordtype of case to be cloned is ps    
    
    @AuraEnabled(cacheable=true)
    public static string is_ps_case(string RecCaseId)
    {   
        case recordtypename= [select RecordType_Name__c from case where id = :RecCaseId];
        string rectype=recordtypename.RecordType_Name__c;
        return rectype;
    }
    
    // Method - 4 : Logic for getting All Case Record Types and default Rec type  for Logged In User - Lightning 
    @AuraEnabled        
    public static List<String> fetchRecordTypeValues(){
        //Stores default Record type
        string Default_returnRecType;
        
        //Set of all Rec types
        Set<string> allRecTypes = new Set<string>();
        
        //List of all Rec types used to return to Lightning controller
        List<String> allRecTypes_List= new List<string>();
        
        // For getting default Rec type
        for(Schema.RecordTypeInfo eachRecType : Schema.SObjectType.Case.getRecordTypeInfosById().values()){
            if(eachRecType.isDefaultRecordTypeMapping()){
                Default_returnRecType = eachRecType.getName();
                break;
            }
        }
        
        //Adding default Rec type to Set in first position
        allRecTypes.add(Default_returnRecType);
        
        
        //Adding remaining Rec types to the set 
        for(RecordTypeInfo rt : case.SObjectType.getDescribe().getRecordTypeInfos()){
            
            if(rt.getName() != 'Master' && rt.isActive() == true && rt.isAvailable() == true )
                allRecTypes.add(rt.getName());
        }
        //converting set of Rec types into a list of Rec types
        allRecTypes_List.addAll(allRecTypes);
        
        return allRecTypes_List;
    }
    
    
    // Method - 5 : For Getting the Selected Record Type Id - Lightning 
    @AuraEnabled
    public static Id getRecTypeId(String recordTypeLabel){
        
        Id recid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId(); 
        return recid;
    } 
    
    // Method - 6 : Getting Case Details when User Clicks on Reopen Button - Lightning
    @AuraEnabled
    public static case getCaseReopenDetails(String parentCaseId)
    {
        Case reopendetails = [SELECT IsClosed,AKAM_Closed_Date__c,status FROM Case WHERE Id = :parentCaseId];
        
        return reopendetails;
    }
    
    // Method - 7 : Getting Case Details when User Clicks on Reopen Button - Lightning
    @AuraEnabled
    public static string updateCaseStatusReopen(String parentCaseId)
    {
        try{
            Case CaseToUpdate = new Case (Id=parentCaseId,
                                          Reopened__c =  true,
                                          Status = 'Reopened',
                                          AKAM_Closed_Date__c = null,
                                          AKAM_Reopened_Date__c = system.now() ,
                                          Is_IP_Scrubbed__c = false ,
                                          IP_Scrubbing_Failed_Objects__c = null,
                                          Validation_Override__c=true
                                         );            
            update CaseToUpdate;
            return 'Success';
        }
        catch(Exception e){
            string errMsg = e.getMessage();
            return errMsg;
        }
        
    }
    
    //Method - 8 : For getting recordtype details for lightning
    
    @AuraEnabled
    public Static List<RecordType> fetchRecordTypeDetails_LC() {
        
        // List to store all Final set of Record Type Details
        Set<RecordType> allRecordTypeDetails = new Set<RecordType>(); 
        
        List<RecordType> allRecordTypeDetails_List = new List<RecordType>(); 
        
        
        // Set to store all Unique Record Types Avalaibale for the Loggedin User
        set<Id> allAvalRecTypeIds = new set<Id>();
        
        // For getting default Rec type
        for(Schema.RecordTypeInfo eachRecType : Schema.SObjectType.Case.getRecordTypeInfosById().values()){
            if(eachRecType.isDefaultRecordTypeMapping()){
                allAvalRecTypeIds.add(eachRecType.getRecordTypeId());
                break;
            }
        }
        
        for(RecordType rt : [select Id,Name,Description from RecordType where SObjectType = 'Case' and Id IN :allAvalRecTypeIds]){
            allRecordTypeDetails.add(rt);
        }  
        
        
        for(RecordTypeInfo rt : Case.SObjectType.getDescribe().getRecordTypeInfos()){
            
            if(rt.getName() != 'Master' && rt.isActive() == true && rt.isAvailable() == true)
                allAvalRecTypeIds.add(rt.getRecordTypeId());
        } 
        
        
        for(RecordType rt : [select Id,Name,Description from RecordType where SObjectType = 'Case' and Id IN :allAvalRecTypeIds ORDER BY Name ]){
            
            allRecordTypeDetails.add(rt);
        }  
        
        allRecordTypeDetails_List.addAll(allRecordTypeDetails);
        
        return allRecordTypeDetails_List; 
    }
    
    @AuraEnabled 
    public static case getAkamAccountID(String RecordID)
    {
        case AKAMAccountID = [select AKAM_Account_ID__c from case where id=:RecordID limit 1];
        return AKAMAccountID;
    }
    
    @AuraEnabled 
    public static string closeInvalid(String RecCaseId, string Comments)
    { 
        //Changes by Sharath for Billing Migration: ESESP-3659. Setting Validation override for non-Billing cases
        try{
            case updaterecord = [Select Id, Comments__c,Status,RecordTypeId,RecordType.name,Validation_Override__c from case where id = :RecCaseId limit 1];
            if(updaterecord.RecordType.name != 'Billing')
            {
                updaterecord.Validation_Override__c =true;
            }
            updaterecord.Comments__c = Comments;
            updaterecord.Status = 'Closed';
            //ESESP-6265
            updaterecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Invalid_Case').getRecordTypeId();
            //case updaterecord = new case(id=RecCaseId,Comments__c =Comments,Status = 'Closed',RecordTypeId ='012G0000000z10rIAA',Validation_Override__c =true);
            update updaterecord;
            return 'true';
        }
        catch (exception e) {return SC_BillingLightningUtility.renderUserfriendlyError(e.getMessage());}
    }
    
    // Method for auto Closing a case (Javascript button functionality)    
    @AuraEnabled 
    public static string getcaseclosedetails(String RecCaseId)
    {
        string eMsgOne; 
        case CloseCaseDet = [select AutoClose__c ,Status ,Resolution_Sent__c , Solution_Summary__c , Origin , Sub_Type__c , Service_Category__c , Problem__c , Sub_Problem__c , Case_Product__c , Task_LOE__c , Solution_Status__c , Root_Cause__c , Root_Cause_Identified_Date__c , Resolved_Date__c  from case where id=:RecCaseId limit 1];
        
        if((CloseCaseDet.Sub_Type__c == 'Product Support') && (CloseCaseDet.Root_Cause__c==null || CloseCaseDet.Root_Cause_Identified_Date__c==null  || CloseCaseDet.Resolved_Date__c==null )){ 
            return 'Diagnosis, Diagnosis Date and Resolved Date should be populated'; 
        }
        
        
        if(CloseCaseDet.Solution_Summary__c==null ){eMsgOne='Solution Summary'; }
        if(CloseCaseDet.Origin==null ){if (eMsgOne==null) eMsgOne= 'Origin'; else eMsgOne = eMsgOne + ', Origin';} 
        if(CloseCaseDet.Resolved_Date__c==null ){if (eMsgOne==null) eMsgOne= 'Resolved Date'; else eMsgOne = eMsgOne + ', Resolved Date';} 
        if(CloseCaseDet.Sub_Type__c==null ){if (eMsgOne==null) eMsgOne= 'Sub Type'; else eMsgOne = eMsgOne + ', Sub Type';}
        if(CloseCaseDet.Service_Category__c==null ){if (eMsgOne==null) eMsgOne= 'Service Category'; else eMsgOne = eMsgOne + ', Service Category';} 
        if(CloseCaseDet.Problem__c==null ){if (eMsgOne==null) eMsgOne= 'Problem'; else eMsgOne = eMsgOne + ', Problem';} 
        if(CloseCaseDet.Sub_Problem__c==null ){if (eMsgOne==null) eMsgOne= 'Sub-Problem'; else eMsgOne = eMsgOne + ', Sub-Problem';}
        if(CloseCaseDet.Case_Product__c==null ){if (eMsgOne==null) eMsgOne= 'Case Product'; else eMsgOne = eMsgOne + ', Case Product';}
        if(CloseCaseDet.Task_LOE__c==null ){if (eMsgOne==null) eMsgOne= 'Task LOE'; else eMsgOne = eMsgOne + ', Task LOE';}
        
        if(CloseCaseDet.Status != 'Closed'){ 
            if(CloseCaseDet.AutoClose__c== false){ 
                if(CloseCaseDet.Resolution_Sent__c == true && (eMsgOne==null)){ 
                    try{ 
                        case updaterecord = new case(id=RecCaseId,AutoClose__c=true);
                        update updaterecord;
                        return 'Auto Close Updated Successfully.'; 
                        
                    }
                    catch(exception e){  return e.getMessage();}
                }
                else if(CloseCaseDet.Status == 'Mitigated / Solution Provided' && CloseCaseDet.Resolution_Sent__c == true){ 
                    if(eMsgOne!=null) 
                        return 'To Auto Close Case, Please fill : ' + eMsgOne; 
                }else if(CloseCaseDet.Status == 'Mitigated / Solution Provided' && CloseCaseDet.Resolution_Sent__c != true){ 
                    if(eMsgOne==null) 
                        return 'To Auto Close the Case, please set Resolution Sent as True'; 
                    else 
                        return 'To Auto Close Case, Please fill : ' + eMsgOne + '. Also please set Resolution Sent as True'; 
                }
                else if(CloseCaseDet.Status!= 'Mitigated / Solution Provided' && CloseCaseDet.Resolution_Sent__c == true){ 
                    if(eMsgOne==null) 
                        return 'To Auto Close the Case, please set Status as Mitigated / Solution Provided'; 
                    else 
                        return 'To Auto Close Case, Please fill : ' + eMsgOne + '. Also please set Status as Mitigated / Solution Provided'; 
                    
                }else{ 
                    if(eMsgOne==null) 
                        return 'To Auto Close the Case, please set Status as Mitigated / Solution Provided and Resolution Sent as True'; 
                    else 
                        return 'To Auto Close Case, Please fill : ' + eMsgOne + '. Also please set Resolution Sent as True and Status as Mitigated / Solution Provided'; 
                } 
            }
            else{ 
                try{ 
                    case updaterecord = new case(id=RecCaseId,AutoClose__c=true,Auto_Close_Date__c = null);
                    update updaterecord;
                    
                    return 'Auto Close Updated Successfully.'; 
                    
                }catch(exception e){  return e.getMessage(); } 
            } 
        }
        else
            return 'Cannot edit a closed case. Please re-open to perform edits';
        return 'null';
        
    }
    
    //Method to get list of case products for a account(Lightning comp: SC_CaseProductSelector)
    @AuraEnabled 
    public static string getCaseProductList(String caseId){
        String caseProductMapping = '[';
        Case caseRec = [Select Id, AccountId, Case_Product__c from case where Id =:caseId limit 1];
        if(caseRec.AccountId==null)
        {
            return 'null';
        }
        else
        {
        List<EB_AccountProductMap__c> caseProductList = [SELECT Name, Id FROM EB_AccountProductMap__c WHERE EB_MarkedForDeletion__c =false and EB_Account__c = :caseRec.AccountId];
        if(caseProductList.size() > 0){
            caseProductList.sort();
            for(EB_AccountProductMap__c c : caseProductList){
                if(c.id == caseRec.Case_Product__c)
                    caseProductMapping += '{"id": "' + c.Id + '", "label": "' + c.Name + '", "selected": true}, ';
                else
                    caseProductMapping += '{"id": "' + c.Id + '", "label": "' + c.Name + '"}, ';
            }  
            caseProductMapping = caseProductMapping.substring(0,caseProductMapping.length()-2);
            caseProductMapping += ']';
            
            return caseProductMapping;
        }
        else
            return 'null';
        }
    }
    
    //Method to save/update Case Product
    @AuraEnabled 
    public static string saveProduct(String caseId, String newProductId){
        Case c = [Select Id, Status, Case_Product__c, Validation_Override__c from case where id =: caseId limit 1];
        if(c.Status != 'Closed'){
            if(c.Case_Product__c != newProductId){
                c.Case_Product__c = newProductId;
                //c.Validation_Override__c = True;
                try{
                    update c;
                }catch(Exception e){ return e.getMessage(); }
            }
            return 'success';
        }
        else
            return 'Closed Case can not be updated!';
    }

    //ESESP-2278: Method to populate parameter for button Tools
    @AuraEnabled(Cacheable=false)
    public static String getToolUrl(String caseId){
        System.debug(caseId);
        if (String.isBlank(caseId)) {
            throw new AuraHandledException('CaseId is blank');
        }
        String toolURL = [SELECT Value__c FROM SC_Utility__mdt WHERE DeveloperName = 'AkaTec_Console_Tool_Link' LIMIT 1].Value__c;
        List<Case> cases = [SELECT Id,Owner.Name,OwnerId,AKAM_Case_ID__c,Owner.Type,Case_Product__r.Name,Problem__c,Sub_Problem__c,Service_Category__c ,Validation_Override__c FROM Case WHERE Id =:caseId LIMIT 1];
        if (cases.size() ==0) {
            throw new AuraHandledException('Case not found');
        }
        Case c = cases[0];
        if (c.Owner.Type != 'User' && !Test.isRunningTest()) {
            throw new AuraHandledException('Case must be assigned to a User in order to invoke this action.');
        }
        User owner = [SELECT Id,Manager__c,Team__c FROM User WHERE Id=:c.OwnerId];
        String managerName = owner.Manager__c != null ? owner.Manager__c : '';
        String product = c.Case_Product__c!=null && c.Case_Product__r.Name != null ? c.Case_Product__r.Name : '';
        String team = owner.Team__c != null ? owner.Team__c : '';
        String problem = c.Problem__c != null ? c.Problem__c : '';
        String serviceCategory = c.Service_Category__c != null ? c.Service_Category__c : '';
        String subProblem = c.Sub_Problem__c != null ? c.Sub_Problem__c : '';
        return toolURL+c.AKAM_Case_ID__c+'&owner='+c.Owner.Name+'&manager='+managerName+'&product='+product+'&team='+team+'&problem='+problem+'&servicecategory='+serviceCategory+'&subproblem='+subProblem;
    }
    
    //Method to get recordtypeId on the Case
    @AuraEnabled
    public static String getRecordTypeIdOfCase(String caseId){
        Case c = [Select Id, RecordTypeId from case where id=:caseId limit 1];
        return c.RecordTypeId;
    }

    //Method to get case Account ID on the Case
    @AuraEnabled
    public static String returnCaseAccountId(String caseId)
    {
        Case c = [Select AccountId FROM Case where id=:caseId limit 1];
        return c.AccountId;
    }
    
    // -------------------- Changes for SOCC Lightning Deployment (methods for Managed Security Page layout buttons) -------------------------------------------------------------
    
    
    //Creating new child case : Part of escalation Automation Functionality
    @AuraEnabled
    public static string CreateRelatedCase(String caseId, string ChoiceType, string fields)
    {
        Case c = [Select id,severity__c,ContactId,SuppliedEmail,Customer_Expectations__c,Origin,AccountId,subject,Service__c,Request_Type__c,Request_Sub_Type__c from case where id=:caseId limit 1];
        Case newCase = new Case();
        //Deserailizing the JSON fields passed by the Component - (Field API, Field Data)
        Map<String, object> jsonMap = (Map<String, object>)JSON.deserializeUntyped(fields);
        
        //Set the subject
        newCase.subject=c.subject;
        //Set the customer Expectations
        if(jsonMap.get('Customer_Expectations__c')!=null){
            newCase.Customer_Expectations__c=jsonMap.get('Customer_Expectations__c').toString();}
        //Set case description
        if(jsonMap.get('Description')!=null){
            newCase.Description = jsonMap.get('Description').toString();}
        //Set Service
        if(jsonMap.get('Service__c')!=null){
            newCase.Service__c = jsonMap.get('Service__c').toString();}
        //Set request type
        if(jsonMap.get('Request_Type__c')!=null){
            newCase.Request_Type__c = jsonMap.get('Request_Type__c').toString();}
        //Set request sub type
        if(jsonMap.get('Request_Sub_Type__c')!=null)
        {
            newCase.Request_Sub_Type__c = jsonMap.get('Request_Sub_Type__c').toString();
        }
        //Set Contact ID
        newCase.ContactId =c.ContactId;
        newCase.Case_Assignment_Using_Active_Rules__c=true;
        newCase.SuppliedEmail=c.SuppliedEmail;
        //Setting case origin
        newCase.Origin =c.Origin;
        if(jsonMap.get('Living_Summary_Next_Steps__c')!=null)
        {
            newCase.Living_Summary_Next_Steps__c=jsonMap.get('Living_Summary_Next_Steps__c').toString();
        }
        
        Map<string, String> Choice_RecordTypeName_Map = new Map<string, String>();
        Choice_RecordTypeName_Map.put('PS', 'Professional Services');
        Choice_RecordTypeName_Map.put('Akatec', 'Technical');
        Choice_RecordTypeName_Map.put('AMG','AMG');
        Choice_RecordTypeName_Map.put('NetOps','Managed Security');
        string rectype=Choice_RecordTypeName_Map.get(ChoiceType);
       newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(rectype).getRecordTypeId();

        newCase.validation_override__c = true;
        newCase.AccountId = c.AccountId;
        newCase.ParentId = caseId;
        newCase.Severity__c=c.severity__c; 
        
        try{
            insert newCase;  
            return newCase.Id;
        }
        catch (exception e) {return e.getMessage();}
    }
    
    // Method to return the parent case ID 
    @AuraEnabled
    public static Id getParentCaseId(String caseId){
        case c = [Select Id,ParentId from case where id=:caseId limit 1];
        return c.ParentId;
    }
    
    // Method to get report ID
    @AuraEnabled
    public static Id getReportId()
    {
        return [Select Id ,DeveloperName from Report where DeveloperName='SOCC_Cases_for_Account_6Ao' limit 1].Id;
    }
    
    // ----------This method can be removed!!!!(line  #190)
    @AuraEnabled
    public static String getAkamAccountIdSOCC(String CaseId)
    {
        return [Select Account.AKAM_Account_ID__c from Case where Id=:CaseId limit 1].Account.AKAM_Account_ID__c;
    }
    
    // Method for acknowledging customer response
    @AuraEnabled
    public static Boolean sendEmailSOCC(String CaseId)
    { 
        //To Avoid Bounce Emails
        Set<String> BounceNames = new Set<String>([Select Value_Text__c from SC_Utility__mdt where MasterLabel = 'Bounce From Name' limit 1].Value_Text__c.split(','));
        
        //To get from address dynamically
        List<String> SOCCFROMNames = new List<String>([Select Value_Text__c from SC_Utility__mdt where MasterLabel = 'SOCC From Name' limit 1].Value_Text__c.split(','));
        String Soccfromnamefinal = SOCCFROMNames[0];
        system.debug('Soccfromnamefinal'+Soccfromnamefinal);
        //Get all Incoming Email Message for the Case Id
        List<EmailMessage> EmailMessageUnderConsideration = [Select FromAddress,FromName,ToAddress,CCAddress,Subject from EmailMessage where Incoming=true and (NOT FromAddress  like '%akamai.com') and FromName not in:BounceNames  and ParentId =:CaseId  order by MessageDate Desc];
        
        if(EmailMessageUnderConsideration.size()>0)
        {
            //Set To Address
            List<String> ToAddress = new List<String>();
            ToAddress.add(EmailMessageUnderConsideration[0].FromAddress);
            
            //Set CC Address
            List<String> CCAddress = new List<String>();
            if(EmailMessageUnderConsideration[0].CCAddress!=null)
            {
                CCAddress = EmailMessageUnderConsideration[0].CCAddress.split(';');
            }
            
            //Set Subject
            String SubjectString = EmailMessageUnderConsideration[0].Subject;
            
            //Get orgwide email id
            Id OrgWideId = null;
            if(Soccfromnamefinal != null){
                OrgWideEmailAddress[] osObj = [select Id from OrgWideEmailAddress where Address=:Soccfromnamefinal limit 1];
                if (osObj.size() > 0){
                    OrgWideId = osObj[0].Id;
                }
            }
            //Id OrgWideId = [select id from OrgWideEmailAddress where Address=:Soccfromnamefinal limit 1].Id;//Commented by aditi to remove Null pointer error, resolved above
            
            //Get Loggedin users signature
            User currUser = [Select Id,Signature from User where Id=:userinfo.getuserId()];
            string userSignature;
            if(currUser.Signature!=null)
            {
                userSignature=currUser.Signature;
            }
            else
            {
                userSignature='';
            }
            
            
            //Set Body
            String Body = 'Hi '+EmailMessageUnderConsideration[0].FromName+',<br/><br/>';
            Body = Body+'Thanks for the update note. Akamai SOCC will review the details and will respond with an update.<br/>';
            Body = Body+'Please feel free to call us if this needs urgent attention or is of high priority. Akamai SOCC is available 24/7 <br/></br/>';
            Body = Body+'<br/>Regards,<br/>'+userSignature+'<br/>Security Operations Command Center<br/>Akamai Technologies<br/>';
            Body = Body+'<a class="external-link" title="http://www.akamai.com/threatresearch" href="http://www.akamai.com/threatresearch" target="_blank" rel="nofollow noopener">www.akamai.com/threatresearch</a> <br/>';
            Body = Body+'(+1) 617-444-4955<br/>(+1) 855-662-5662, Toll Free (US Only)<br/>(+65)  657-693-50, APJ<br/>(+48) 123-847-924, EMEA<br/>(+81) 345-207-530, Japan<br/>';
            Body = Body+'International Dialing Instructions:&nbsp;<a class="external-link" href="https://www.akamai.com/us/en/support/global-support-phone-numbers.jsp" target="_blank" rel="nofollow noopener">https://www.akamai.com/us/en/support/global-support-phone-numbers.jsp</a>';
            
            
            //Mail List
            List<Messaging.SingleEmailMessage> EmailList = new List<Messaging.SingleEmailMessage>();
            
            /*** Construct Email Message  ***/
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(ToAddress);
            mail.setCcAddresses(CCAddress);
            mail.setOrgWideEmailAddressId(OrgWideId);
            mail.setSubject(SubjectString);
            mail.setHtmlBody(Body);
            mail.setUseSignature(false);
            mail.setWhatId(CaseId);
            mail.setSaveAsActivity(true);
            EmailList.add(mail);
            
            
            if(EmailList.size()>0)
            {
                Messaging.sendEmail(EmailList);
            }
            
            return true;
            
            
        }
        
        else
        {
            return false;
        }
        
    }
    
    //ESESP-3659: Changes for Billing Case migration: changes by Sharath
    @AuraEnabled
    public static string cloneBillingCases(String caseId, String noOfClones)
    {
        Integer totalCount = Integer.valueOf(noOfClones);
        List<Case> caseCloneList = new List<Case>();
        String caseQuery = 'Select ';
        
        Map<String, Schema.Sobjectfield> CaseFieldMap = Case.sObjectType.getDescribe().fields.getMap();
        Schema.DescribeFieldResult caseField;
        system.debug('CaseFieldMap//'+CaseFieldMap);
        for(String caseFlds : CaseFieldMap.keySet())
        {
            caseField = CaseFieldMap.get(caseFlds).getDescribe();
            if(caseField.isUpdateable() && caseField.isAccessible()){
                caseQuery += caseFlds + ',';
            }
        }
        caseQuery = caseQuery.substring(0, caseQuery.length()-1);
        caseQuery += ' From Case Where Id = :caseId';

        Case originalCase = Database.query(caseQuery);
        Case newCase;
        
        for(Integer count = 0; count < totalCount; count++)
        {
            newCase = originalCase.clone(false,false);
            //newCase = new Case();

            //Marking all relevant akam fields null
            newCase.AKAM_Case_ID__c = null;
            newCase.AKAM_Modified_Date__c=null;
            newCase.AKAM_Created_Date__c=null;
            newCase.AKAM_Created_By__c=null;
            newCase.AKAM_Modified_By__c=null;
            newCase.AKAM_Closed_Date__c=null;
            newCase.AKAM_Reopened_Date__c=null;
            newCase.ClosedDate = null;
            newCase.EntitlementId = null;
            newCase.Resolved_Date__c = null;
            newCase.Reopened__c = false;
            newCase.Status = (newCase.Status == 'Closed' || newCase.Status == 'Reopened') ? 'Assigned' : newCase.Status;
            caseCloneList.add(newCase);  
        }
        
        try
        {
            if(!caseCloneList.isEmpty())
            {
                insert caseCloneList;
                system.debug('caseCloneList Inserted//'+caseCloneList.size());
                
            }
        }
        catch (exception e) 
        {
            return SC_BillingLightningUtility.renderUserfriendlyError(e.getMessage());
        }        
        return 'true';
    }      
    
    //Added by aditi - ESESP-3222: Added to return the Parent case's AccountId to prepopulate in new Related Case from RL button
    @AuraEnabled
    public static String queryParentAccountId(String idOftheCase){
        
        System.debug('idOftheCase :: '+idOftheCase);
        String accId = null;
        if(idOftheCase != null){
            Case[] cs = [Select Id,AccountId from case where Id=:idOftheCase limit 1];
            if (cs.size() > 0){
                accId = cs[0].AccountId;
            }
            //Case cs = [Select Id,AccountId from case where Id=:idOftheCase limit 1];//Commented by aditi to avoid null pointer error, resolved above
            System.debug('cs :: '+cs);
            //accId = cs.AccountId;
        }
        //System.assert(false);
        return accId;
    }

    // changes by Vandhana for ESESP-4359 Elevation on Account/Case
    @AuraEnabled
    public static void addExistingRecordToElevation(String objRecId,String objType,String elevationRecId)
    {
        if(String.isBlank(objRecId))
        {
            throw new AuraHandledException('Please select a record to add');   
        }
        
        String dbQuery = 'SELECT <fields> FROM <sObject> WHERE Id = \'' + objRecId + '\' LIMIT 1 FOR UPDATE';
        sObject recToUpdate;

        if(objType == 'case')
        {
            dbQuery = dbQuery.replace('<fields>','AKAM_Case_ID__c,IsClosed,Elevation__c').replace('<sObject>','Case');
            System.debug(dbQuery);
            recToUpdate = Database.query(dbQuery);
            if(recToUpdate.get('IsClosed') == true)
            {
                throw new AuraHandledException('You cannot associate a Closed Case, please reopen the Case for associating'); 
            }
            if(String.isNotBlank(String.valueOf(recToUpdate.get('Elevation__c'))) && String.valueOf(recToUpdate.get('Elevation__c')).contains(elevationRecId))
            {
                throw new AuraHandledException('This case is already added to the Elevation'); 
            }
            recToUpdate.put('Elevation__c',elevationRecId);
            try
            {
                update recToUpdate;
            }
            catch(Exception e)
            {
                throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));   
            }
        }
        else if(objType == 'escalation')
        {
            dbQuery = dbQuery.replace('<fields>','Elevation__c').replace('<sObject>','Engagement_Request__c');
            recToUpdate = Database.query(dbQuery);
            if(String.isNotBlank(String.valueOf(recToUpdate.get('Elevation__c'))) && String.valueOf(recToUpdate.get('Elevation__c')).contains(elevationRecId))
            {
                throw new AuraHandledException('This Escalation is already added to the Elevation'); 
            }
            recToUpdate.put('Elevation__c',elevationRecId);
            try
            {
                update recToUpdate;
            }
            catch(Exception e)
            {
                throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));   
            }
        }
        else if(objType == 'serviceincident' || objType == 'elevation')
        {
            String uniqueId = (objType == 'serviceincident') ? elevationRecId + objRecId : objRecId + elevationRecId;
            List<sObject> juncObj = [SELECT Elevation__c,Service_Incident__c,Unique_ID__c FROM Elevation_and_Service_Incident__c WHERE Unique_ID__c = :uniqueId LIMIT 1];
            if(!juncObj.isEmpty())
            {
                if(objType == 'serviceincident')
                {   throw new AuraHandledException('This Service Incident is already added to the Elevation');  }
                else 
                {   throw new AuraHandledException('This Elevation is already added to the Service Incident');  }
            }
            else
            {
                Elevation_and_Service_Incident__c elevNSI = new Elevation_and_Service_Incident__c();
                elevNSI.Elevation__c = (objType == 'serviceincident') ? elevationRecId : objRecId;
                elevNSI.Service_Incident__c = (objType == 'serviceincident') ? objRecId : elevationRecId;
                elevNSI.Unique_ID__c = (objType == 'serviceincident') ? elevationRecId + objRecId : objRecId + elevationRecId;
                try
                {
                    insert elevNSI;
                }
                catch(Exception e)
                {
                    throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));   
                }
            }
        }
    }

    @AuraEnabled
    public static String createElevation(String elevationParam, String caseId)
    {
        Map<String,Object> mapElevFieldVals = new Map<String,Object>();
        mapElevFieldVals = (Map<String, Object>) JSON.deserializeUntyped(elevationParam);
        System.debug(mapElevFieldVals);
        Case caseRec = new Case(Id = caseId);
        
        Elevation__c newElevRec = new Elevation__c(Status__c = 'Open');
        newElevRec.Account__c = String.valueOf(mapElevFieldVals.get('Account__c'));
        if(mapElevFieldVals.containsKey('Status__c') && String.isNotBlank(String.valueOf(mapElevFieldVals.get('Status__c'))))
        {   newElevRec.Status__c = String.valueOf(mapElevFieldVals.get('Status__c'));   }
        
        System.debug('TEMP : ' + String.valueOf(mapElevFieldVals.get('Customer_Temperature__c')));
        System.debug('TEMP : ' + mapElevFieldVals.get('Customer_Temperature__c'));
        
        if(mapElevFieldVals.containsKey('Customer_Temperature__c') && String.isNotBlank(String.valueOf(mapElevFieldVals.get('Customer_Temperature__c'))))
        {   
            newElevRec.Customer_Temperature__c = String.valueOf(mapElevFieldVals.get('Customer_Temperature__c'));   
        }
        //Added below by Aditi for  - ESESP-6831
        if(mapElevFieldVals.containsKey('Elevation_Visibility__c') && String.isNotBlank(String.valueOf(mapElevFieldVals.get('Elevation_Visibility__c'))))
        {   
            newElevRec.Elevation_Visibility__c = String.valueOf(mapElevFieldVals.get('Elevation_Visibility__c'));   
        }
        //Aditi changes end
        if(mapElevFieldVals.containsKey('Customer_Watch__c') && String.isNotBlank(String.valueOf(mapElevFieldVals.get('Customer_Watch__c'))))
        {   newElevRec.Customer_Watch__c = Boolean.valueOf(mapElevFieldVals.get('Customer_Watch__c'));   }
        if(mapElevFieldVals.containsKey('Reason_for_Elevation__c') && String.isNotBlank(String.valueOf(mapElevFieldVals.get('Reason_for_Elevation__c'))))
        {   newElevRec.Reason_for_Elevation__c = String.valueOf(mapElevFieldVals.get('Reason_for_Elevation__c'));   }
        if(mapElevFieldVals.containsKey('Latest_Summary__c') && String.isNotBlank(String.valueOf(mapElevFieldVals.get('Latest_Summary__c'))))
        {   newElevRec.Latest_Summary__c = String.valueOf(mapElevFieldVals.get('Latest_Summary__c'));   }
        if(mapElevFieldVals.containsKey('Exec_Summary__c') && String.isNotBlank(String.valueOf(mapElevFieldVals.get('Exec_Summary__c'))))
        {   newElevRec.Exec_Summary__c = String.valueOf(mapElevFieldVals.get('Exec_Summary__c'));   }
        
        System.debug(newElevRec);
        try
        {
            insert newElevRec;
            System.debug(newElevRec.Id);
            caseRec.Elevation__c = newElevRec.Id;
            caseRec.Validation_Override__c = true;
            update caseRec;
            return newElevRec.Id;
        }
        catch(Exception e)
        {
            throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));   
        }
    }
}