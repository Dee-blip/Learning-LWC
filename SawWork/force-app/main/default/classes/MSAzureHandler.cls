/*=====================================================================================================+
    Class name          :   AkamaiPartnerIntegration_TestClass 
    Authors             :   Aditya,Akhila,Jay & Kunal
    Created             :   27-Jan-16
    Purpose             :   Handler class for MS functionality
+=====================================================================================================*/
public class MSAzureHandler implements IPartnerProcessor{ 

    public static Boolean varActivityCreationRecCheck = false;
    public List<SObject> lSObjectToInsert = new List<SObject>();
    public Map<String,String> mAzureCasePrimaryConEmail = new Map<String,String>();
    public Map<String,Case> mAzureCaseAndAkamCaseId = new Map<String,Case>();
    public List<String> lPrimaryLiveId = new List<String>();
    public List<Case> lCasesInCollaborationMode = new List<Case>();
    public List<String> lAzureTicketsActivityOnly = new List<String>();
    public Map<String,String> mInboundReqIdAzureTicket = new Map<String,String>();
    public List<String> lAzureProductId = new List<String>();
    //Map of Configuration setting stored in Custom Metadata Type.
    public Map<String,String> mCustomMetadata = new Map<String,String>();
    List<Object> lCaseDetails;
    List<Object> lAdditionalContacts;
    Map<String,String> mAzureTicketAndActivities = new Map<String,String>();
    Map<String,String> mCaseUpdateActivity = new Map<String,String>();
    Map<String,Inbound_Request_Queue__c> mCaseIdAndInboundReqId = new Map<String,Inbound_Request_Queue__c>();
    Integer azureMessageId;
    String azureTicketRefNumber;
    Map<String, List<Partner_Customer_Contact__c>> mAdditionalContactsToInsert = new Map<String, List<Partner_Customer_Contact__c>>();
    Map<String,Partner_Customer_Contact__c> mAlternateContactInfo = new Map<String,Partner_Customer_Contact__c>();
    Map<String,String> mAzureTicketAndPreferredDetails = new Map<String,String>();
    String suggestedRecepients; //To store all the Primary & Alternate contacts
    Map<String,List<Object>> mAkamCaseIdPartnerContact = new Map<String,List<Object>>();
    Map<Id,Case> mCaseIdAndDetail = new Map<Id,Case>();
    public static Boolean varRecCheck = false;
    List<Outbound_Request_Queue__c> lOutboundReqToInsert = new List<Outbound_Request_Queue__c>();
    Map<String,String> mAkamCaseIdAndMSTicket = new Map<String,String>();
    Map<String,String> mERIdAndMSTicket = new Map<String,String>();
    Map<String,String> mActivityIdAndMSActivityId = new Map<String,String>();
    List<Partner_Customer_Contact__c> lPartnerCustomerContact = new List<Partner_Customer_Contact__c>();
    List<String> lInsertedCaseIds = new List<String>();
    Map<String,Contact> mPrimaryContactDetail = new Map<String,Contact>();
    List<String> lAccountIdsForCaseCreation = new List<String>();
    Map<String,Map<String,String>> mAccountCaseProduct = new Map<String,Map<String,String>>();
    Map<String,Case_Exchange_Inbound_Partner_Product__c> mAzureProductMapping = new Map<String,Case_Exchange_Inbound_Partner_Product__c>();
    public static Map<String,String> mMSToAkamSev = new Map<String,String>();
    public static Map<String,String> mAkamToMSSev = new Map<String,String>();
    public static boolean varActivateMSAzureCode;
    
    static{   
        varActivateMSAzureCode = true;
        for(Parter_Configuration_Data__mdt varCustomMetadata: [SELECT MasterLabel, Salesforce_Id__c 
                                                               FROM Parter_Configuration_Data__mdt]){
            if(varCustomMetadata.MasterLabel == 'MS Azure Code Enabled'
               && !varCustomMetadata.Salesforce_Id__c.equalsIgnoreCase('true')){
                varActivateMSAzureCode = false;
            }
                                                                   
            if(varCustomMetadata.MasterLabel == 'MS To Akamai Mapping'){
                for(String varSeverityMapping : varCustomMetadata.Salesforce_Id__c.split(',')){
                    mMSToAkamSev.put(varSeverityMapping.split(':')[0].trim(), varSeverityMapping.split(':')[1].trim());                    
                }  
            }
                                                                   
            if(varCustomMetadata.MasterLabel == 'Akamai To MS Mapping'){
                for(String varSeverityMapping : varCustomMetadata.Salesforce_Id__c.split(',')){
                    mAkamToMSSev.put(varSeverityMapping.split(':')[0].trim(), varSeverityMapping.split(':')[1].trim());                    
                }  
            }
        }
    }

    public MSAzureHandler(){
        //Getting all the configuration settings from Custome Metadata Type.
        List<Parter_Configuration_Data__mdt> lCustomSettingData = [SELECT MasterLabel, Salesforce_Id__c FROM Parter_Configuration_Data__mdt];
        for(Parter_Configuration_Data__mdt varCustomMetadat :lCustomSettingData){
            mCustomMetadata.put(varCustomMetadat.MasterLabel, varCustomMetadat.Salesforce_Id__c);           
        }
    }

    /*
     * Method for processing Inbound recs whenever the rec is inserted
     * when we do GetTicket.
     * This method is implemented from IPartnerProcessor Interface.
     */
    public void inboundRequestInsertProcessor(List<SObject> lSobject, Boolean isBefore){
        try{
            if(!isBefore){
                //Parsing the JSON input for creating Case.
                for(SObject varSObject :lSobject){
                    if(varSObject instanceOf Inbound_Request_Queue__c){
                        parseIncomingJSON((Inbound_Request_Queue__c) varSObject,((Inbound_Request_Queue__c) varSObject).Request_Data__c);
                    }
                }
                //Insert Case and Partner Customer Contacts.
                if(!lSObjectToInsert.isEmpty()){
                    insertProcessedRecords();
                }
                //Insert Activities if present in the Payload
                if(!lAzureTicketsActivityOnly.isEmpty()){
                    createActivitiesForCaseUpdate(mCaseUpdateActivity);
                }
            }
        }
        
        catch(Exception e){
            List<SObject> lInboundReqFailed = new List<SObject>();
            for(SObject varSobject: lSobject){
                Inbound_Request_Queue__c varRecToUpdate = (Inbound_Request_Queue__c) varSObject;
                Inbound_Request_Queue__c varInboundReqQueue = new Inbound_Request_Queue__c();
                varInboundReqQueue.Id = varRecToUpdate.Id;
                varInboundReqQueue.Processing_Status__c = 'Processing Error';
                varInboundReqQueue.Receipt_Status__c = 'Not Sent';
                varInboundReqQueue.Response_Data__c = '{"TicketReference":"'+ '", "MessageId":"' + varRecToUpdate.Partner_Request_Id__c +'", "ProcessingStatus":"Failure"}';
                varInboundReqQueue.Processing_Error_Reason__c = e.getMessage();
                lInboundReqFailed.add(varInboundReqQueue);
            }
            
            update lInboundReqFailed;
        }
        
    }
    /*
     * Method for processing Inbound recs whenever the rec is updated
     * in case we post a receipt.
     * This method is implemented from IPartnerProcessor interface
     */
    public void inboundRequestUpdateProcessor(List<SObject> lSobject, Boolean isBefore, List<SObject> lSobjectOld){
        System.debug('## Receipt Inbound Processor ' + lSobject + ' ### ' + isBefore + ' #### ' + lSobjectOld);
        Set<String> sAkamCaseIds = new Set<String>();
        Set<String> sAkamCaseIdsForERUpdate = new Set<String>();
        List<String> lAkamCaseIdAllCases = new List<String>();
        Map<String,Case> mCasesToUpdate = new Map<String, Case>();
        List<Case> lCasesToUpdate = new List<Case>();
        if(isBefore && !lSobject.isEmpty()){
            Integer i = 0;
            for(SObject varSObject :lSobject){
                if(varSObject instanceOf Inbound_Request_Queue__c){
                    Inbound_Request_Queue__c varInboundReq = (Inbound_Request_Queue__c) varSObject;
                    if(varInboundReq.Receipt_Status__c != ((Inbound_Request_Queue__c) lSobjectOld[i]).Receipt_Status__c
                       && varInboundReq.Receipt_Status__c == 'Success Receipt Sent'){
                        Map<String, Object> mReceiptPayload = (Map<String, Object>) JSON.deserializeUntyped(varInboundReq.Response_Data__c);
                        if(((String) mReceiptPayload.get('TicketReference')).startsWithIgnoreCase('F-CS-')){
                            sAkamCaseIds.add((String) mReceiptPayload.get('TicketReference'));
                            lAkamCaseIdAllCases.add((String) mReceiptPayload.get('TicketReference'));
                        }
                    }
                    
                    else if(varInboundReq.Receipt_Status__c != ((Inbound_Request_Queue__c) lSobjectOld[i]).Receipt_Status__c
                       && varInboundReq.Receipt_Status__c != 'Success Receipt Sent'){
                        Map<String, Object> mReceiptPayload = (Map<String, Object>) JSON.deserializeUntyped(varInboundReq.Response_Data__c);
                        if(((String) mReceiptPayload.get('TicketReference')).startsWithIgnoreCase('F-CS-')){
                            sAkamCaseIdsForERUpdate.add((String) mReceiptPayload.get('TicketReference'));
                            lAkamCaseIdAllCases.add((String) mReceiptPayload.get('TicketReference'));
                        }
                    }
                }
                i++;
            }
        //System.debug('## Inbound Processor ' + lAkamCaseIds);
        if(!sAkamCaseIds.isEmpty()){
            for(Case varCase :[SELECT Id,Partner_Joint_Troubleshooting_Status__c,
                               Eligible_for_Partner_Case_Exchange__c, AKAM_Case_ID__c,
                               (SELECT Id, Request_Status__c 
                                FROM Engagement_Requests__r 
                                WHERE RecordTypeId =:mCustomMetadata.get('MS Inbound ER Record Type Id')
                                AND Request_Status__c = 'Open')
                               FROM Case 
                               WHERE AKAM_Case_ID__c IN :lAkamCaseIdAllCases]){
                mCasesToUpdate.put(varCase.AKAM_Case_ID__c, varCase);
            }
        }
        setEligibilityFlagAndJointTrobleshootingStaus(sAkamCaseIds,mCasesToUpdate);
        }
    }
    
    /*
     * Method for processing Outbound recs whenever the rec is Inserted
     * when we create a ER, Outbound Activity, Update Case Status, Case Severity.
     * This method is implemented from IPartnerProcessor interface
     */
    public void outboundRequestInsertProcessor(List<SObject> lSobject, Boolean isBefore){
        
    }
    
    /*
     * Method for processing Outbound recs whenever the rec is Updated
     * when we receive receipt from MS. GetReceipt
     * This method is implemented from IPartnerProcessor interface
     */
    public void outboundRequestUpdateProcessor(List<SObject> lSobject, Boolean isBefore, List<SObject> lSobjectOld){
        //Set of Case Ids for Failure Receipt Received
        Set<String> sCaseIdsForAzureFailure = new Set<String>();
        //Set of Task Ids for Failure Receipt Received
        Set<String> sTaskIdsForAzureFailure = new Set<String>();
        //Set of ER Ids for Failure Receipt Received
        Set<String> sERIdsForAzureFailure = new Set<String>();
        Integer i = 0;
        for(SObject varSObject :lSobject){
            //Parse the Receipt Payload when Success Receipt is received and update MS Id on Case,ER or Task.
            if(varSObject instanceOf Outbound_Request_Queue__c
                && ((Outbound_Request_Queue__c) varSObject).Receipt_Status__c == 'Success Receipt Received'
                && ((Outbound_Request_Queue__c) varSObject).Receipt_Payload__c != null
                && ((Outbound_Request_Queue__c) varSObject).Receipt_Payload__c != ((Outbound_Request_Queue__c) lSobjectOld[i]).Receipt_Payload__c){
                parseReceiptPayload(((Outbound_Request_Queue__c) varSObject).Receipt_Payload__c,
                                    ((Outbound_Request_Queue__c) varSObject).Event_Object_Id__c,
                                    ((Outbound_Request_Queue__c) varSObject).Event_Type__c,
                                    isBefore);
            }
            
            //Add the Ids to the Failure sets when Failure Receipt is received.
            else if(varSObject instanceOf Outbound_Request_Queue__c
                    && (((Outbound_Request_Queue__c) varSObject).Receipt_Status__c == 'Failure Receipt Received'
                        || ((Outbound_Request_Queue__c) varSObject).Receipt_Status__c == 'Timed Out')
                    && ((Outbound_Request_Queue__c) varSObject).Receipt_Status__c != ((Outbound_Request_Queue__c) lSobjectOld[i]).Receipt_Status__c){
                if(((Outbound_Request_Queue__c) varSObject).Event_Type__c == 'Activity Creation'
                    || ((Outbound_Request_Queue__c) varSObject).Event_Type__c == 'Activity Update'){
                    sTaskIdsForAzureFailure.add(((Outbound_Request_Queue__c) varSObject).Event_Object_Id__c);
                }
                else if(((Outbound_Request_Queue__c) varSObject).Event_Type__c == 'Case Escalation'
                        || ((Outbound_Request_Queue__c) varSObject).Event_Type__c == 'Case Update'
                        || ((Outbound_Request_Queue__c) varSObject).Event_Type__c == 'Close Collaboration'){
                    sCaseIdsForAzureFailure.add(((Outbound_Request_Queue__c) varSObject).Case__c);
                    if(((Outbound_Request_Queue__c) varSObject).Event_Type__c == 'Case Escalation'){
                       sERIdsForAzureFailure.add(((Outbound_Request_Queue__c) varSObject).Event_Object_Id__c);
                    }
                }

            }
            i++;
        }        

        if(!mAkamCaseIdAndMSTicket.isEmpty() || !sCaseIdsForAzureFailure.isEmpty()){
            updateCaseWhenReceiptReceived(mAkamCaseIdAndMSTicket,sCaseIdsForAzureFailure);
        }
        if(!mERIdAndMSTicket.isEmpty()){
            updateERWithTicketNum(mERIdAndMSTicket);
        }
        
        if(!mActivityIdAndMSActivityId.isEmpty() || !sTaskIdsForAzureFailure.isEmpty()){
            updateTaskWhenReceiptReceived(mActivityIdAndMSActivityId,sTaskIdsForAzureFailure);
        }
        
        if(!sERIdsForAzureFailure.isEmpty()){
            setERReceiptStatusFailed(sERIdsForAzureFailure);
        }
    }
    
    private void setERReceiptStatusFailed(Set<String> sERIdsForAzureFailure){
        List<Engagement_Request__c> lEngagementRequestForFailure = new List<Engagement_Request__c>();
        for(String varERId : sERIdsForAzureFailure){
            Engagement_Request__c varER = new Engagement_Request__c();
            varER.Id = varERId;
            varER.Partner_Receipt_Status__c = 'Failure Receipt Received';
            varER.Request_Status__c = 'Closed';
            lEngagementRequestForFailure.add(varER);
        }
        
        if(!lEngagementRequestForFailure.isEmpty()){
            update lEngagementRequestForFailure;
        }
    }
    
    /*
     * Method for setting 'Partner Joint Troble Shooting' and 'Eligible for Partner Case Exchange' to true.
     * Triggerd when we receive success receipt in 'Inbound Request Queue'.
     */ 
    private void setEligibilityFlagAndJointTrobleshootingStaus(Set<String> sAkamCaseIds, Map<String,Case> mCasesToUpdate){
        List<Case> lCasesToUpdateFlagAndJointStatus = new List<Case>();
        if(!sAkamCaseIds.isEmpty()){
            for(String varAkamCaseId :sAkamCaseIds){
                if(mCasesToUpdate.containsKey(varAkamCaseId)
                   && !(mCasesToUpdate.get(varAkamCaseId).Engagement_Requests__r).isEmpty()){
                    Case varCase = mCasesToUpdate.get(varAkamCaseId);
                    varCase.Partner_Joint_Troubleshooting_Status__c = 'Open';
                    varCase.Eligible_for_Partner_Case_Exchange__c = true;
                    varCase.Validation_Override__c = true;   
                    lCasesToUpdateFlagAndJointStatus.add(varCase);
                }
            }
        }
        System.debug('## Inbound Processor ' + lCasesToUpdateFlagAndJointStatus);
        update lCasesToUpdateFlagAndJointStatus;
    }
    
    private void parseIncomingJSON(Inbound_Request_Queue__c inboundReqObject, String jsonString){
        Map<String, Object> mGenericPayload;
        Map<String, Object> mTicketInformation;
        mGenericPayload = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        mTicketInformation = (Map<String, Object>) mGenericPayload.get('Ticket');
        lCaseDetails = (List<Object>) mTicketInformation.get('TicketDetails');
        lAdditionalContacts = (List<Object>) mTicketInformation.get('Contacts');
        Integer messageType = (Integer)mTicketInformation.get('MessageType');
        azureMessageId = (Integer)mGenericPayload.get('MessageId');
        azureTicketRefNumber = (String)((Map<String, Object>) mTicketInformation.get('Sender')).get('TicketReference');
        String jsonStringForActivities = JSON.serialize(mTicketInformation.get('CCNotes'));
        mAzureTicketAndActivities.put(azureTicketRefNumber, jsonStringForActivities);
        SObject objectToInsert;
        mInboundReqIdAzureTicket.put(inboundReqObject.Id,azureTicketRefNumber);
        if(messageType==2){
            createAdditionalContacts(azureTicketRefNumber,lAdditionalContacts);
            objectToInsert = createCase();
            lSObjectToInsert.add(objectToInsert);
        }
        
        else if(messageType==3){
            String akamCaseId = (String)((Map<String, Object>) mTicketInformation.get('Receiver')).get('TicketReference');
            mCaseUpdateActivity.put(akamCaseId, jsonStringForActivities);
            mCaseIdAndInboundReqId.put(akamCaseId, inboundReqObject);
            lAzureTicketsActivityOnly.add(azureTicketRefNumber);
            //createActivity(mAzureTicketAndActivities);
        }
        
    }
    
    /*
     * Method for mapping Case fields from the payload that is coming from MS.
     * Different method is present to map Case Product using the Support Topic Id
     * that is coming in the payload.
     */ 
    public Case createCase(){
        Boolean isAutoEscalation = false;
        Case instanceCase = new Case();
        for(Object varCaseFieldInfo :lCaseDetails){
            Map<String, Object> mTempCaseInfo = (Map<String, Object>) varCaseFieldInfo;
            if((String) mTempCaseInfo.get('Name') == 'Title'){
                instanceCase.Subject = (String) mTempCaseInfo.get('Value');
            }
            
            else if((String) mTempCaseInfo.get('Name') == 'Severity'){
                System.debug('## Severity Check ' + mMSToAkamSev + ' $$$ ' +(String) mTempCaseInfo.get('Value'));
                instanceCase.Severity__c = mMSToAkamSev.get(((String) mTempCaseInfo.get('Value')).trim());
            }
            
            else if((String) mTempCaseInfo.get('Name') == 'Problem Description'){
                instanceCase.Description = (String) mTempCaseInfo.get('Value');
            }
            /*
            else if((String) mTempCaseInfo.get('Name') == 'SolveCallingCountry'){
                //instanceCase.Microsoft_Azure_Calling_Country_Code__c  = (String) mTempCaseInfo.get('Value');
            }
            
            else if((String) mTempCaseInfo.get('Name') == 'Problem Product'){
                //instanceCase.Partner_Product__c  = (String) mTempCaseInfo.get('Value');
            }*/
            
            else if((String) mTempCaseInfo.get('Name') == 'Suporttopic'){
                System.debug('## SupportTopic ' + (String) mTempCaseInfo.get('Value') + '  ## ' + mTempCaseInfo);
                instanceCase.Microsoft_Azure_Support_Topic__c = (String) mTempCaseInfo.get('Value');
                lAzureProductId.add(instanceCase.Microsoft_Azure_Support_Topic__c);
                //instanceCase.RecordTypeId = getCaseRecordType(instanceCase.Microsoft_Azure_Support_Topic__c );
            }
            
            else if((String) mTempCaseInfo.get('Name') == 'Eligibility Key Value'){
                instanceCase.Partner_Subscription_ID__c  = (String) mTempCaseInfo.get('Value');
            }
            
            else if((String) mTempCaseInfo.get('Name') == 'IsAutoEscalation'){
                isAutoEscalation = (String) mTempCaseInfo.get('Value')=='True'?true:false;
            }
            
            else if((String) mTempCaseInfo.get('Name') == 'HostName'){
                instanceCase.MS_Azure_Host_Name__c = (String) mTempCaseInfo.get('Value');
            }
        }
        instanceCase.Partner_Ticket_Number__c  = azureTicketRefNumber;
        instanceCase.Partner_Account__c = mCustomMetadata.get('MS Default Account Id');
        instanceCase.Do_Not_Show_in_Portal__c = false;
        instanceCase.Service_Category__c = '';
        instanceCase.Validation_Override__c = true;        
        mAzureCaseAndAkamCaseId.put(azureTicketRefNumber, new Case());
        if(!isAutoEscalation){
            instanceCase.Partner_Joint_Troubleshooting_Status__c = 'Open';
            instanceCase.Eligible_for_Partner_Case_Exchange__c = true;
            lCasesInCollaborationMode.add(instanceCase);
        }
        else{
            instanceCase.Partner_Joint_Troubleshooting_Status__c = 'Closed';
        }
        return instanceCase;
    }
    /*
     * Method for creating recs in 'Partner Customer Contact' Object.
     * This data comes in payload from MS. One Primary Contact always comes.
     * This info is being stored so that we can send it back to MS.
     * This method also adds Suggested Recepients which are being used Answer Customer functionality.
     */        
    private void createAdditionalContacts(String azureTicketRefNumber, List<Object> lAdditionalContacts){
        suggestedRecepients = '';
        for(Object varPartnerContactInfo :lAdditionalContacts){
            Partner_Customer_Contact__c varPartnerContact = new Partner_Customer_Contact__c();
            Map<String, Object> mPartnerContactInfo = (Map<String, Object>) varPartnerContactInfo;
            System.debug('@@@ ' + mPartnerContactInfo);
            varPartnerContact.First_Name__c = (String) mPartnerContactInfo.get('FirstName');
            varPartnerContact.Last_Name__c  = (String) mPartnerContactInfo.get('LastName');
            varPartnerContact.Contact_Email__c  = (String) mPartnerContactInfo.get('Email');
            suggestedRecepients = suggestedRecepients + ';' + (String) mPartnerContactInfo.get('Email');
            varPartnerContact.Contact_Phone__c  = (String) mPartnerContactInfo.get('PhoneNumber');
            varPartnerContact.Akam_Partner_Customer_Contact_Id__c = (String) mPartnerContactInfo.get('LiveID');
            varPartnerContact.Is_Primary__c = (Boolean) mPartnerContactInfo.get('IsPrimary');
            varPartnerContact.Is_Email_Enabled__c = (Boolean) mPartnerContactInfo.get('IsEmailEnabled');
            varPartnerContact.Preferred_Email__c = (String) mPartnerContactInfo.get('PreferredEmail');
            varPartnerContact.Preferred_Phone_Number__c = (String) mPartnerContactInfo.get('PreferredPhoneNumber');
            varPartnerContact.Type__c = (String) mPartnerContactInfo.get('Type');
            if((Boolean)mPartnerContactInfo.get('IsPrimary')){
                mAzureCasePrimaryConEmail.put(azureTicketRefNumber,((String) mPartnerContactInfo.get('LiveID')).toupperCase());
                mAlternateContactInfo.put(azureTicketRefNumber, varPartnerContact);
                lPrimaryLiveId.add((String) mPartnerContactInfo.get('LiveID'));
                String preferredDetails;
                if(varPartnerContact.Preferred_Email__c != null){
                    preferredDetails = 'Preferred Email: ' + varPartnerContact.Preferred_Email__c + '\n';
                }
                system.debug('## preferredDetails ## ' + preferredDetails);

                if(varPartnerContact.Preferred_Phone_Number__c != null){
                    preferredDetails = preferredDetails + 'Preferred Phone: ' + varPartnerContact.Preferred_Phone_Number__c;
                }
                system.debug('## preferredDetails ## ' + preferredDetails);
                mAzureTicketAndPreferredDetails.put(azureTicketRefNumber, preferredDetails);
                system.debug('## preferredDetails ## ' + mAzureTicketAndPreferredDetails);
            }
            if(!mAdditionalContactsToInsert.containsKey(azureTicketRefNumber)){
                mAdditionalContactsToInsert.put(azureTicketRefNumber, new List<Partner_Customer_Contact__c>());
            }
            mAdditionalContactsToInsert.get(azureTicketRefNumber).add(varPartnerContact);
        }
        
    }
    
    /*
     * Contains method for inserting 'Cases' (Separate method being called insertCases()).
     * Method for mapping the contact if it is present in Akamai (getContactAndAccountId).
     * Method for creating 'Partner Customer Contact' (lPartnerCustomerContact) once the Case is created.
     * Method for inserting ERs for Joint Trouble Shooting scenario (createERForCollaboration).
     * Method for Updating Inbound Request Queue once the Case is created successfully(updateInboundRequestQueue).
     * Method for creating Activity in case we receive cc note in the payload when MS escalte the Case 
     * to Akamai. This is a future method. (createActivity)
     */
    private void insertProcessedRecords(){
        Map<string, Schema.RecordTypeInfo> mCaseRecordType = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        getCaseRecordType(lAzureProductId);
        List<Case> lCasesActivityOnly = new List<Case>();
        if(!lAzureTicketsActivityOnly.isEmpty()){
            lCasesActivityOnly = [SELECT Id, Akam_Case_Id__c ,Partner_Ticket_Number__c
                                  FROM Case WHERE Partner_Ticket_Number__c IN :lAzureTicketsActivityOnly];
        }
        System.debug('## Contact ## ' + lPrimaryLiveId);
        getContactAndAccountId(lPrimaryLiveId);
        insertCases();
        System.debug('## Contact ## ' + mPrimaryContactDetail + ' ' + mAzureCasePrimaryConEmail);
        System.debug('%%% Part ' + mAdditionalContactsToInsert + ' '+lAdditionalContacts);
        for(SObject varSobject : lSObjectToInsert){
            Case varCase = (Case) varSobject;
            lInsertedCaseIds.add(varCase.Id);
            if(mAzureCaseAndAkamCaseId.containsKey(varCase.Partner_Ticket_Number__c)){
                mAzureCaseAndAkamCaseId.put(varCase.Partner_Ticket_Number__c,varCase);
            }
            
            for(Partner_Customer_Contact__c varPartnerContact : mAdditionalContactsToInsert.get(varCase.Partner_Ticket_Number__c)){
                System.debug('### In The Loop ' +  mAdditionalContactsToInsert.get(varCase.Partner_Ticket_Number__c));
                //if(!mPrimaryContactDetail.containsKey(varPartnerContact.Contact_Email__c)){
                    varPartnerContact.Case__c = varCase.Id;
                    lPartnerCustomerContact.add(varPartnerContact);
                //}
            }
        }
        System.debug('%%% Part ' + lPartnerCustomerContact);
        insert lPartnerCustomerContact;
        createERForCollaboration(lCasesInCollaborationMode,mAzureCaseAndAkamCaseId);
        updateInboundRequestQueue(mInboundReqIdAzureTicket);
        createActivity(mAzureTicketAndActivities);
    }
    
    /*
     * Method for inserting Cases.
     * Setting the Assignment Rule header as true. Mapping the Contact Id and Account Id.
     * Mapping the value for Case Product from Inbound Case Product mapping table (getContactAndAccountId).
     * 
     */ 
    private void insertCases(){
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        Map<string, Schema.RecordTypeInfo> mCaseRecordType = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        for(SObject varSobject : lSObjectToInsert){
            Case varCase = (Case) varSobject;
            varCase.setOptions(dmo);
            varCase.Akam_Case_Id__c = '';
            varCase.Validation_Override__c = true;
            varCase.Origin = 'Partner System';
            System.debug('## Contact ## ' + mPrimaryContactDetail.containsKey(mAzureCasePrimaryConEmail.get(varCase.Partner_Ticket_Number__c)));
            varCase.Suggested_Recipients__c = suggestedRecepients.substring(1); //setting suggested recipients field
            if(mPrimaryContactDetail.containsKey(mAzureCasePrimaryConEmail.get(varCase.Partner_Ticket_Number__c))){
                varCase.ContactId = mPrimaryContactDetail.get(mAzureCasePrimaryConEmail.get(varCase.Partner_Ticket_Number__c)).Id;
                varCase.AccountId = mPrimaryContactDetail.get(mAzureCasePrimaryConEmail.get(varCase.Partner_Ticket_Number__c)).AccountId;
            }
            else{
                varCase.AccountId = mCustomMetadata.get('MS Default Account Id');
                varCase.Alternate_Contact_Name__c = mAlternateContactInfo.get(varCase.Partner_Ticket_Number__c).First_Name__c
                                                    + ' ' + mAlternateContactInfo.get(varCase.Partner_Ticket_Number__c).Last_Name__c;
                varCase.Alternate_Contact_Phone__c = mAlternateContactInfo.get(varCase.Partner_Ticket_Number__c).Contact_Phone__c;
                varCase.Alternate_Contact_Email__c = mAlternateContactInfo.get(varCase.Partner_Ticket_Number__c).Contact_Email__c ;
                varCase.AlternateContactEmailManagedSecurity__c = mAlternateContactInfo.get(varCase.Partner_Ticket_Number__c).Contact_Email__c ;
            }
            System.debug('### 171 ' + mAccountCaseProduct + ' DD ' + mAzureProductMapping + ' ^^ ' + varCase);
            String productName;
            if( mAzureProductMapping.containsKey(varCase.Microsoft_Azure_Support_Topic__c) &&
                mCaseRecordType.containsKey(mAzureProductMapping.get(varCase.Microsoft_Azure_Support_Topic__c).Akamai_Case_Record_Type_Name__c)){
                varCase.RecordTypeId = mCaseRecordType.get(mAzureProductMapping.get(varCase.Microsoft_Azure_Support_Topic__c).Akamai_Case_Record_Type_Name__c).getRecordTypeId();
                productName = mAzureProductMapping.get(varCase.Microsoft_Azure_Support_Topic__c).Akamai_Case_Product__c;    
            }
            
            if(mAccountCaseProduct.containsKey(varCase.AccountId) &&
               mAccountCaseProduct.get(varCase.AccountId).containsKey(productName)){
                varCase.Case_Product__c = mAccountCaseProduct.get(varCase.AccountId).get(productName);
            }
            if(mAzureProductMapping.containsKey(varCase.Microsoft_Azure_Support_Topic__c)){
                varCase.Partner_Product__c  = mAzureProductMapping.get(varCase.Microsoft_Azure_Support_Topic__c).Id;
                varCase.Description = 'Problem Value: ' + mAzureProductMapping.get(varCase.Microsoft_Azure_Support_Topic__c).Akamai_Problem__c + '\n' + varCase.Description;
            }
            if(!mAzureTicketAndPreferredDetails.isEmpty()
                && mAzureTicketAndPreferredDetails.get(varCase.Partner_Ticket_Number__c) != NULL){
                varCase.Description += '\n' + mAzureTicketAndPreferredDetails.get(varCase.Partner_Ticket_Number__c);
            }

        }
        insert lSObjectToInsert;
    }
    /*
     * Method for getting the Record Type from 'Case Exchange Inbound Partner Product'
     * using support topic that is coming from MS payload.
     */ 
    private void getCaseRecordType(List<String> lAzureProductId){
        
        for(Case_Exchange_Inbound_Partner_Product__c varAzureCaseProduct : [SELECT Id, Akamai_Case_Product__c, Akamai_Problem__c,
                                                                            Akamai_Case_Record_Type_Name__c, Partner_Product_Id__c  
                                                                            FROM Case_Exchange_Inbound_Partner_Product__c 
                                                                            WHERE Partner_Product_Id__c IN :lAzureProductId]){
            mAzureProductMapping.put(varAzureCaseProduct.Partner_Product_Id__c, varAzureCaseProduct);   
        }
        
    }
    
    /*
     * Method for mapping the Account based on Primary Contact email Id and 
     * for mapping Case Product based on Support Topic Id.
     */ 
    private void getContactAndAccountId(List<String> lAzurePrimaryContactPortalId){
        for(Contact varContact: [SELECT Id, AccountId, Email 
                                 FROM Contact 
                                 WHERE 
                                 Login__c IN :lAzurePrimaryContactPortalId 
                                 AND Active_Portal_Login__c = true]){
            mPrimaryContactDetail.put((varContact.Email).toUpperCase(), varContact);
            lAccountIdsForCaseCreation.add(varContact.AccountId);
                                     
        }
        lAccountIdsForCaseCreation.add(mCustomMetadata.get('MS Default Account Id'));
        for(EB_AccountProductMap__c  varCaseProduct :[SELECT Name, EB_Account__c, EB_Product__c,Id 
                                                      FROM EB_AccountProductMap__c 
                                                      WHERE EB_Account__c IN :lAccountIdsForCaseCreation
                                                      AND EB_MarkedForDeletion__c = false]){
            if(!mAccountCaseProduct.containsKey(varCaseProduct.EB_Account__c)){
                mAccountCaseProduct.put(varCaseProduct.EB_Account__c, new Map<String,String>());
            }
            mAccountCaseProduct.get(varCaseProduct.EB_Account__c).put(varCaseProduct.Name,varCaseProduct.Id);
        }
    }
    
    public void getProductId(List<String> lAccountIdsForCaseCreation){
        
    }
    
    /*
     * Method for creating Inbound ER when Auto Escalation is false in the payload.
     */ 
    private void createERForCollaboration(List<Case> lCasesInCollaborationMode,Map<String,Case> mLinkAzureAndAkamaiCase){
        List<Engagement_Request__c> lERsToInsert = new List<Engagement_Request__c>();
        for(Case varCase :lCasesInCollaborationMode){
            Engagement_Request__c varER = new Engagement_Request__c ();
            varER.RecordTypeId = mCustomMetadata.get('MS Inbound ER Record Type Id');
            varER.AKAM_Created_By__c = 'Microsoft Azure Support';
            varER.Partner_Ticket__c = varCase.Partner_Ticket_Number__c;
            //varER.Partner_Subscription_ID__c  = varCase.Partner_Subscription_ID__c;
            varER.Request_Status__c = 'Open';
            //varER.Severity__c ='TODO';
            varER.Description__c = varCase.Description;
            varER.Case__c = mLinkAzureAndAkamaiCase.get(varCase.Partner_Ticket_Number__c).Id;
            varER.Subject__c = varCase.Subject;
            //varER.Originating_Partner_Account__c = 'MSAzure';
            lERsToInsert.add(varER);
        }
        insert lERsToInsert;
    }
    
    /*
     * Updates the the Inbound Request Queue Record with the Akam Case Id
     * when Case is inserted successfully.
     */ 
    private void updateInboundRequestQueue(Map<String,String> mInboundReqIdAzureTicket){
        Map<String,String> mLinkInboundReqAndCase = new Map<String,String>();
        Map<String, String> mCaseDetails = new Map<String,String>();
        List<Inbound_Request_Queue__c> lInboundReqIds = new List<Inbound_Request_Queue__c>();
        
        List<Inbound_Request_Queue__c> lInboundReq = new List<Inbound_Request_Queue__c>();
        for(Case varCase :[SELECT Id,AKAM_Case_ID__c,Partner_Ticket_Number__c FROM Case WHERE Id IN :lInsertedCaseIds]){
            mCaseDetails.put(varCase.Partner_Ticket_Number__c,varCase.AKAM_Case_ID__c);
        }
        for(Inbound_Request_Queue__c varInboundReqQueue : [SELECT Id, Processing_Status__c,Response_Data__c, 
                                                           Receipt_Status__c, Partner_Request_Id__c  
                                                           FROM Inbound_Request_Queue__c 
                                                           WHERE Id IN :mInboundReqIdAzureTicket.keySet()]){
            String statusOfRequest = mCaseDetails.containsKey(mInboundReqIdAzureTicket.get(varInboundReqQueue.Id))?'Success':'Failure';
            varInboundReqQueue.Processing_Status__c = 'Processed';
            varInboundReqQueue.Receipt_Status__c = 'Not Sent';
            varInboundReqQueue.Response_Data__c = '{"TicketReference":"'+ mCaseDetails.get(mInboundReqIdAzureTicket.get(varInboundReqQueue.Id)) + '", "MessageId":"' + varInboundReqQueue.Partner_Request_Id__c +'", "ProcessingStatus":"' + statusOfRequest +'"}';
            lInboundReq.add(varInboundReqQueue);
        }
        update lInboundReq;
    }
    
    /*
     * Method for creating Activity rec when CC Notes are present in the payload at the 
     * time of Escalation. This is a future method because we are inserting Case in the 
     * same transaction.
     */ 
    @future
    public static void createActivity(Map<String,String> mAzureTicketAndActivities){
        Map<String,String> mCustomMetadataFuture = new Map<String,String>();
        for(Parter_Configuration_Data__mdt varCustomMetadat :[SELECT MasterLabel, Salesforce_Id__c FROM Parter_Configuration_Data__mdt]){
            mCustomMetadataFuture.put(varCustomMetadat.MasterLabel, varCustomMetadat.Salesforce_Id__c);           
        }
        List<Task> lActivitiesToInsert = new List<Task>();
        Map<String,Case> mCaseDetails = new Map<String,Case>();
        List<Case> lCasesToAddActivities = [SELECT Id,Partner_Ticket_Number__c,RecordTypeId FROM Case 
                                            WHERE Partner_Ticket_Number__c IN :mAzureTicketAndActivities.keySet()];
        for(Case varCase : lCasesToAddActivities){
            mCaseDetails.put(varCase.Partner_Ticket_Number__c,varCase);
        }
        for(String varAzureId : mAzureTicketAndActivities.keySet()){
            List<Object> lCCNotes = (List<Object>) JSON.deserializeUntyped(mAzureTicketAndActivities.get(varAzureId));
            //List<Object> lCCNotes = (List<Object>) mapOfCCNotes.get('CCNotes');
            for(object varCCNote :lCCNotes){
                Map<String, Object> mOfCCNotes = (Map<String, Object>) varCCNote;
                Task varTask = new Task();
                if(((String) mOfCCNotes.get('Content')).length()>200)
                    varTask.Subject = 'Microsoft Azure Ticket #: ' + varAzureId + ' ' + ((String) mOfCCNotes.get('Content')).substring(0,199);
                else{
                    varTask.Subject = 'Microsoft Azure Ticket #: ' + varAzureId + ' ' + (String) mOfCCNotes.get('Content');
                }
                //varTask.Subject = (String) mOfCCNotes.get('Content');
                if(((String) mOfCCNotes.get('Content')).length()>31940)
                    varTask.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' + ((String) mOfCCNotes.get('Content')).substring(0,31939);
                else{
                    varTask.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' +  + (String) mOfCCNotes.get('Content');
                }
                //varTask.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' + (String) mOfCCNotes.get('Content');
                varTask.Status = 'Completed';
                varTask.Internal_Only__c = (Integer) mOfCCNotes.get('SharingLevel') == 1 ? true:false;
                varTask.Visibility__c = (Integer) mOfCCNotes.get('SharingLevel') == 1 ? 'Partner Only':'Customer';
                varTask.Partner_Activity_Id__c = (String) mOfCCNotes.get('Id');
                //varTask.Microsoft_Azure_Activity_Type__c = String.valueOf(mOfCCNotes.get('Type'));
                varTask.WhatId = mCaseDetails.get(varAzureId).Id;
                varTask.Type__c = 'Inbound Partner Activity';
                if(mCaseDetails.containsKey(varAzureId) 
                   && mCaseDetails.get(varAzureId).RecordTypeId== mCustomMetadataFuture.get('MS Managed Security Record Types')){
                    varTask.RecordTypeId = mCustomMetadataFuture.get('MS Managed Security Task Record Types');
                }
                else{
                    varTask.RecordTypeId = mCustomMetadataFuture.get('MS Technical Task Record Types');
                }
                lActivitiesToInsert.add(varTask);
            }
        }
        insert lActivitiesToInsert;
    }
    
    /*
     * Method for creating Activites when we receive only CC Note from MS and the Case is 
     * in Joint Troubleshooting state.
     */ 
    public void createActivitiesForCaseUpdate(Map<String,String> mActivityPayloadFormat){
        Map<String,String> mCustomMetadataFuture = new Map<String,String>();
        List<Case> lAzureCasesForCloseCollab = new List<Case>();
        List<String> lCaseIdsForActivityUpdate = new List<String>();
        Map<String,String> mMSActAndIdCaseId = new Map<String,String>();
        List<Task> lTaskToUpdate = new List<Task>();
        for(Parter_Configuration_Data__mdt varCustomMetadat :[SELECT MasterLabel, Salesforce_Id__c FROM Parter_Configuration_Data__mdt]){
            mCustomMetadataFuture.put(varCustomMetadat.MasterLabel, varCustomMetadat.Salesforce_Id__c);           
        }
        List<Task> lActivitiesToInsert = new List<Task>();
        Map<String,Case> mCaseDetails = new Map<String,Case>();
        List<Case> lCasesToAddActivities = [SELECT Id,Partner_Ticket_Number__c,RecordTypeId,
                                            Akam_Case_Id__c, Escalation_Partner_Ticket__c 
                                            FROM Case 
                                            WHERE Akam_Case_Id__c IN :mActivityPayloadFormat.keySet()];
        for(Case varCase : lCasesToAddActivities){
            mCaseDetails.put(varCase.Akam_Case_Id__c,varCase);
            List<Object> lCCNotes = (List<Object>) JSON.deserializeUntyped(mActivityPayloadFormat.get(varCase.Akam_Case_Id__c));
            for(object varCCNote :lCCNotes){
                Map<String, Object> mOfCCNotes = (Map<String, Object>) varCCNote;
                System.debug('###@@@@ Act Update ' + mOfCCNotes);
                if(((String) mOfCCNotes.get('Id') != '' || (String) mOfCCNotes.get('Id') != null)
                   && (Integer) mOfCCNotes.get('Type') == 1)
                mMSActAndIdCaseId.put((String) mOfCCNotes.get('Id'), varCase.Id);
            }
        }
        System.debug('### Act Update Map again ' + mMSActAndIdCaseId);
        Map<String,Task> mMSActIdAndActForUpdate = new Map<String,Task>();
        if(!mMSActAndIdCaseId.isEmpty()){
            for(Task varTask :[SELECT Id, Description,Partner_Activity_Id__c,
                               WhatID
                               FROM Task WHERE 
                               WhatId IN :mMSActAndIdCaseId.values()
                               AND Partner_Activity_Id__c IN :mMSActAndIdCaseId.keySet()]){
                mMSActIdAndActForUpdate.put(varTask.Partner_Activity_Id__c, varTask);
            }
        }
        
        for(String varAzureId : mActivityPayloadFormat.keySet()){
            List<Object> lCCNotes = (List<Object>) JSON.deserializeUntyped(mActivityPayloadFormat.get(varAzureId));
            String msTicketNumber = mCaseDetails.get(varAzureId).Escalation_Partner_Ticket__c == null? mCaseDetails.get(varAzureId).Partner_Ticket_Number__c:mCaseDetails.get(varAzureId).Escalation_Partner_Ticket__c;
            for(object varCCNote :lCCNotes){
                Map<String, Object> mOfCCNotes = (Map<String, Object>) varCCNote;
                if((Integer) mOfCCNotes.get('Type') == 2
                    || ((Integer) mOfCCNotes.get('Type') == 1 
                        && !mMSActIdAndActForUpdate.containsKey((String) mOfCCNotes.get('Id')))
                    || (Integer) mOfCCNotes.get('Type') == 3){
                    Task varTask = new Task();
                    if(((String) mOfCCNotes.get('Content')).length()>200)
                        varTask.Subject = 'Microsoft Azure Ticket #: ' + msTicketNumber + ' ' + ((String) mOfCCNotes.get('Content')).substring(0,199);
                    else{
                        varTask.Subject = 'Microsoft Azure Ticket #: ' + msTicketNumber + ' ' +(String) mOfCCNotes.get('Content');
                    } 
                    if(((String) mOfCCNotes.get('Content')).length()>31940)
                        varTask.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' + ((String) mOfCCNotes.get('Content')).substring(0,31939);
                    else{
                        varTask.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' +  + (String) mOfCCNotes.get('Content');
                    }    
                    //varTask.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' + (String) mOfCCNotes.get('Content');
                    varTask.Status = 'Completed';
                    varTask.Internal_Only__c = (Integer) mOfCCNotes.get('SharingLevel') == 1 ? true:false;
                    varTask.Visibility__c = (Integer) mOfCCNotes.get('SharingLevel') == 1 ? 'Partner Only':'Customer';
                    varTask.Partner_Activity_Id__c = (String) mOfCCNotes.get('Id');
                    //varTask.Microsoft_Azure_Activity_Type__c = String.valueOf(mOfCCNotes.get('Type'));
                    varTask.WhatId = mCaseDetails.get(varAzureId).Id;
                    varTask.Type__c = 'Inbound Partner Activity';
                    varTask.Task_Validation_Override__c = true;
                    if(mCaseDetails.containsKey(varAzureId) 
                       && mCaseDetails.get(varAzureId).RecordTypeId== mCustomMetadataFuture.get('MS Managed Security Record Types')){
                        varTask.RecordTypeId = mCustomMetadataFuture.get('MS Managed Security Task Record Types');
                    }
                    else{
                        varTask.RecordTypeId = mCustomMetadataFuture.get('MS Technical Task Record Types');
                    }
                    lActivitiesToInsert.add(varTask);
                }
                System.debug('### Task Id for Update map '+ mMSActAndIdCaseId);
                for(String varMSTaskId :mMSActIdAndActForUpdate.keySet()){
                    System.debug('### Task Id for Update ' + mMSActAndIdCaseId.get(varMSTaskId));
                    System.debug('### Task Id for Update map '+ mMSActAndIdCaseId);
                    Task varTaskToupdate = new Task();
                    varTaskToupdate.Id = (mMSActIdAndActForUpdate.get(varMSTaskId)).Id;
                    if(((String) mOfCCNotes.get('Content')).length()>31940)
                        varTaskToupdate.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' + ((String) mOfCCNotes.get('Content')).substring(0,31939);
                    else{
                        varTaskToupdate.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' +  + (String) mOfCCNotes.get('Content');
                    }
                    //varTaskToUpdate.Description = 'Note From: ' + (String) mOfCCNotes.get('NoteFrom') + '\n' + (String) mOfCCNotes.get('Content');
                    varTaskToupdate.Task_Validation_Override__c = true;
                    varTaskToupdate.WhatId = (mMSActIdAndActForUpdate.get(varMSTaskId)).WhatId;
                    lActivitiesToInsert.add(varTaskToUpdate);
                }
                
                if((Integer) mOfCCNotes.get('Type')==3){
                    Case varCase = new Case();
                    varCase.Id = mCaseDetails.get(varAzureId).Id;
                    lAzureCasesForCloseCollab.add(varCase);
                }
            }
        }
        if(!lActivitiesToInsert.isEmpty()){
            upsert lActivitiesToInsert;
            List<String> lTaskIds = new List<String>();
            List<String> lWhatIds = new List<String>();
            Map<String,String> mWhatIdAkamActivityId = new Map<String,String>();
            Map<String,String> mAkamCaseIdAndAkamActivityId = new Map<String,String>();
            for(Task varTaskForId : lActivitiesToInsert){
                lTaskIds.add(varTaskForId.Id);
                lWhatIds.add(varTaskForId.WhatId);
            }

            for(Case varCaseWithAkamCaseId : [SELECT Id, Akam_Case_Id__c 
                                              FROM Case WHERE Id IN :lWhatIds]){
                mWhatIdAkamActivityId.put(varCaseWithAkamCaseId.Id, varCaseWithAkamCaseId.Akam_Case_Id__c);
            }
            List<Inbound_Request_Queue__c> lInboundReqForUpdate = new List<Inbound_Request_Queue__c>();
            for(Task varTaskWithAkamId : [SELECT Id,AKAM_Activity_ID__c,WhatId
                                          FROM Task 
                                          WHERE Id IN :lTaskIds]){
                mAkamCaseIdAndAkamActivityId.put(mWhatIdAkamActivityId.get(varTaskWithAkamId.WhatId), varTaskWithAkamId.AKAM_Activity_ID__c);
                Inbound_Request_Queue__c varInboundReqQueue = new Inbound_Request_Queue__c();
                varInboundReqQueue.Id = (mCaseIdAndInboundReqId.get(mWhatIdAkamActivityId.get(varTaskWithAkamId.WhatId))).Id;
                varInboundReqQueue.Processing_Status__c = 'Processed';
                varInboundReqQueue.Receipt_Status__c = 'Not Sent';
                varInboundReqQueue.Response_Data__c = '{"TicketReference":"'+ varTaskWithAkamId.AKAM_Activity_ID__c + '", "MessageId":"' + (mCaseIdAndInboundReqId.get(mWhatIdAkamActivityId.get(varTaskWithAkamId.WhatId))).Partner_Request_Id__c +'", "ProcessingStatus":" Success' +'"}';
                lInboundReqForUpdate.add(varInboundReqQueue);
            }
            update lInboundReqForUpdate;
            updateCaseAndEROnCloseCollaboration(lAzureCasesForCloseCollab,true);
        }
    }
    
    /*
     * Method from creating payload when we have Case in Joint Troubleshooting state.
     */ 
    
    public void createPayloadForPostTicket(List<SObject> lSObject){
        List<String> lCaseIds = new List<String>();
        List<Case> lCaseDetail = new List<Case>();
        List<String> lSupportTopicToSend = new List<String>();
        Map<Id,Partner_Customer_Contact__c> mCaseIdAndPartnerCon = new Map<Id,Partner_Customer_Contact__c>();
        List<Object> lPartnerContactsToSend = new List<Object>();
        Document varDocument = [SELECT Body FROM Document WHERE DeveloperName = 'Azure_Post_Ticket_Payload'];
        String payloadFormat = varDocument.Body.toString();
        Map<String, Object> mPayloadFormat = (Map<String, Object>) JSON.deserializeUntyped(payloadFormat);
        List<Object> lContactPayloadFormat = (List<Object>) mPayloadFormat.get('Contacts');
        List<Object> lCCNotesPayloadFormat = (List<Object>) mPayloadFormat.get('CCNotes');
        Map<String, Object> mPayloadFormatForSender = (Map<String, Object>) mPayloadFormat.get('Sender');
        
        Map<String,Engagement_Request__c> mCaseIdAndER = new Map<String,Engagement_Request__c>();
        Map<String, String> mFinalPayloadToInsertJSON = new Map<String, String>();
        List<Object> lCaseDetails = (List<Object>) mPayloadFormat.get('TicketDetails');
        //List<Object> lCCNotesDetails = (List<Object>) mPayloadFormat.get('CCNotes');
        List<Outbound_Request_Queue__c> lOutboundReqToInsert = new List<Outbound_Request_Queue__c>();
        Map<String,String> mCaseIdAndGUID = new Map<String,String>();
        Map<String,Case_Exchange_Outbound_Partner_Product__c> mSupportTopicAndMSId = new Map<String,Case_Exchange_Outbound_Partner_Product__c>();
        List<Engagement_Request__c> lERToEscalate = new List<Engagement_Request__c>();
        for(SObject varSObject :lSObject){
            if(varSObject instanceOf Engagement_Request__c){
                lERToEscalate.add((Engagement_Request__c) varSObject);
                lCaseIds.add(((Engagement_Request__c) varSObject).Case__c);
                mCaseIdAndER.put(((Engagement_Request__c) varSObject).Case__c, (Engagement_Request__c) varSObject);
                mCaseIdAndGUID.put(((Engagement_Request__c) varSObject).Case__c, getGUID());
                lSupportTopicToSend.add(((Engagement_Request__c) varSObject).Support_Topic_Concatenated__c);
            }
        }
        if(lCaseIds.size()>0){
            checkOpenER(lCaseIds,mCaseIdAndER);
            setAdditionalContactsPayload(lCaseIds);
            mSupportTopicAndMSId = getSupportTopicToSend(lSupportTopicToSend);
        }
        for(String varCaseId :mCaseIdAndER.keySet()){
            Outbound_Request_Queue__c varOutboundRecToInsert = new Outbound_Request_Queue__c();
            mPayloadFormatForSender.put('TicketReference',mCaseIdAndDetail.get(varCaseId).Akam_Case_Id__c);
            mPayloadFormatForSender.put('ConversationRoleId', '12');
            mPayloadFormat.put('TrackingReference', mCaseIdAndGUID.get(varCaseId));
            //lCCNotesPayloadFormat.clear();
            //mPayloadFormat.put('CCNotes', lCCNotesPayloadFormat);
            mPayloadFormat.put('MessageType', 'New');
            lContactPayloadFormat.clear();
            if(mAkamCaseIdPartnerContact.containsKey(varCaseId)){
                lContactPayloadFormat.addAll((List<Object>)mAkamCaseIdPartnerContact.get(varCaseId));
            }
            System.debug('### lContactPayloadFormat ' + lContactPayloadFormat);
            System.debug('### lCaseDetails ' + lCaseDetails);
            for(Object varCaseFieldInfo :lCaseDetails){
                Map<String, Object> mTempCaseInfo = (Map<String, Object>) varCaseFieldInfo;
                if((String) mTempCaseInfo.get('Name') == 'Title'){
                    mTempCaseInfo.put('Value', mCaseIdAndER.get(varCaseId).Subject__c);
                }
                if((String) mTempCaseInfo.get('Name') == 'Severity'){
                    mTempCaseInfo.put('Value', mAkamToMSSev.get(mCaseIdAndER.get(varCaseId).Severity__c.trim()));
                }
                if((String) mTempCaseInfo.get('Name') == 'Status'){
                    mTempCaseInfo.put('Value', mCaseIdAndER.get(varCaseId).Request_Status__c);
                }
                if((String) mTempCaseInfo.get('Name') == 'Problem Product'){
                    if(mSupportTopicAndMSId.containsKey(mCaseIdAndER.get(varCaseId).Support_Topic_Concatenated__c)){
                        mTempCaseInfo.put('Value', mSupportTopicAndMSId.get(mCaseIdAndER.get(varCaseId).Support_Topic_Concatenated__c).Partner_Product_Id__c );
                    }
                    else{
                        mTempCaseInfo.put('Value', 'Value Not Found');
                    }

                }
                if((String) mTempCaseInfo.get('Name') == 'Suporttopic'){
                    
                    if(mSupportTopicAndMSId.containsKey(mCaseIdAndER.get(varCaseId).Support_Topic_Concatenated__c)){
                        mTempCaseInfo.put('Value', mSupportTopicAndMSId.get(mCaseIdAndER.get(varCaseId).Support_Topic_Concatenated__c).Support_Topic_Id__c );
                    }
                    else{
                        mTempCaseInfo.put('Value', 'Value Not Found');
                    }
                }
                if((String) mTempCaseInfo.get('Name') == 'Problem Description'){
                    mTempCaseInfo.put('Value', mCaseIdAndDetail.get(varCaseId).Description);
                }
                if((String) mTempCaseInfo.get('Name') == 'Customer CC List'){
                    mTempCaseInfo.put('Value', mCaseIdAndER.get(varCaseId).Additional_CC_List__c);
                }
                if((String) mTempCaseInfo.get('Name') == 'Eligibility Key Value'){
                    mTempCaseInfo.put('Value', mCaseIdAndER.get(varCaseId).Partner_Subscription_ID__c);
                }
                if((String) mTempCaseInfo.get('Name') == 'IsAutoEscalation'){
                    mTempCaseInfo.put('Value', 'False');
                }
                if((String) mTempCaseInfo.get('Name') == 'HostName'){
                    mTempCaseInfo.put('Value', mCaseIdAndDetail.get(varCaseId).MS_Azure_Host_Name__c);
                }
                if((String) mTempCaseInfo.get('Name') == 'MSCaseNumber'){
                    String azureTicketNumber = mCaseIdAndDetail.get(varCaseId).Escalation_Partner_Ticket__c == null? mCaseIdAndDetail.get(varCaseId).Partner_Ticket_Number__c : mCaseIdAndDetail.get(varCaseId).Escalation_Partner_Ticket__c;
                    mTempCaseInfo.put('Value', azureTicketNumber);
                }
                

            }
            System.debug('### lCaseDetails ' + lCaseDetails);
            System.debug('@#@#@#@ ccNote ' + lCCNotesPayloadFormat);
            for(Object varCCNotesDetails :lCCNotesPayloadFormat){
                System.debug('@#@#@#@ varCCNotesDetails ' + varCCNotesDetails);
                Map<String, Object> mTempCCNotesInfo = (Map<String, Object>) varCCNotesDetails;
                System.debug('@#@#@#@ mTempCCNotesInfo ' + mTempCCNotesInfo);
                mTempCCNotesInfo.put('Id','');
                mTempCCNotesInfo.put('Content', mCaseIdAndER.get(varCaseId).Description__c);
                mTempCCNotesInfo.put('PartnerCookie', mCaseIdAndDetail.get(varCaseId).Akam_Case_Id__c);
                mTempCCNotesInfo.put('SharingLevel', '2');
                mTempCCNotesInfo.put('Type', '1');
                mTempCCNotesInfo.put('NoteFrom', UserInfo.getName());
                mTempCCNotesInfo.put('OriginatingSystemDateTime', mCaseIdAndER.get(varCaseId).CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                
            }
            
            System.debug('@#@#@#@ ccNote ' + lCCNotesPayloadFormat);
            
            varOutboundRecToInsert.Request_Data__c  = JSON.serializePretty(mPayloadFormat);
            varOutboundRecToInsert.Request_Status__c = 'New';
            varOutboundRecToInsert.Tracking_Reference__c = mCaseIdAndGUID.get(varCaseId);
            varOutboundRecToInsert.Originating_Partner_Account__c = 'MSAzure';
            varOutboundRecToInsert.Event_Object_Id__c = mCaseIdAndER.get(varCaseId).Id;
            varOutboundRecToInsert.Event_Type__c = 'Case Escalation';
            varOutboundRecToInsert.Case__c = varCaseId;
            lOutboundReqToInsert.add(varOutboundRecToInsert);
        }
        insert lOutboundReqToInsert;
        
        /*for(String varCaseId :lCaseIds){
            Case varCase = new Case();
            varCase.Id = varCaseId;
            varCase.Eligible_for_Partner_Case_Exchange__c = false;
        }*/
    }
    
    /*
     * Method for stopping the User from creating multiple partner ERs in Open state.
     */ 
    private void checkOpenER(List<String> lCaseIds, Map<String,Engagement_Request__c> mCaseIdAndER){
        Map<String,Set<String>> mCaseIdWithOpenER = new Map<String,Set<String>>();
        List<Engagement_Request__c> lEngagementRequest = [SELECT Id,Case__c FROM Engagement_Request__c 
                                                          WHERE Case__c IN :lCaseIds AND Request_Status__c = 'Open'
                                                          AND (RecordType.Name = 'Escalation From Microsoft Azure' OR RecordType.Name = 'Escalation to Microsoft Azure')];
        if(!lEngagementRequest.isEmpty()){
            for(Engagement_Request__c varER :lEngagementRequest){
                if(!mCaseIdWithOpenER.containsKey(varER.Case__c)){
                    mCaseIdWithOpenER.put(varER.Case__c,new Set<String>());
                }
                mCaseIdWithOpenER.get(varER.Case__c).add(varER.Id);
            }
            System.debug('### ER Dupe ' + mCaseIdWithOpenER + ' ## ' + Trigger.New + '### ' +lEngagementRequest);
            for(SObject varSobject :Trigger.New){
                Engagement_Request__c varER = (Engagement_Request__c) varSobject;
                if(varSobject instanceOf Engagement_Request__c){
                    if(mCaseIdWithOpenER.containsKey(varER.Case__c) 
                       && mCaseIdWithOpenER.get(varER.Case__c).size()>1){
                        varER.addError('You can only have one open escalation with Microsoft at a time.');
                    }
                }
            }
        }
    }
    
    /*
     * This method adds additional contacts to the payload
     * that we are sending back to MS from 'Partner Customer Contact' Object.
     * This data comes in payload from MS. One Primary Contact always comes.
     */
    private void setAdditionalContactsPayload(List<String> lCaseIds){
        
            mCaseIdAndDetail = new Map<Id, Case> ([SELECT Id, Akam_Case_Id__c,Partner_Ticket_Number__c,
                                                   Escalation_Partner_Ticket__c,MS_Azure_Host_Name__c,
                                                   Description
                                                   FROM Case 
                                                   WHERE Id IN :lCaseIds]);
            for(Partner_Customer_Contact__c varPartnerCon : [SELECT Id,First_Name__c,Last_Name__c,Case__c,Type__c, 
                                                             Contact_Company__c,Contact_Email__c,Contact_Phone__c,
                                                             Is_Email_Enabled__c,Is_Primary__c,Preferred_Phone_Number__c,
                                                              Akam_Partner_Customer_Contact_Id__c 
                                                             FROM Partner_Customer_Contact__c
                                                             WHERE Case__c IN :lCaseIds]){
                Map<String, Object> mOfContactsPayload = new Map<String, Object>();
                mOfContactsPayload.put('Type',varPartnerCon.Type__c);
                mOfContactsPayload.put('Email',varPartnerCon.Contact_Email__c);
                mOfContactsPayload.put('FirstName',varPartnerCon.First_Name__c);
                mOfContactsPayload.put('LastName',varPartnerCon.Last_Name__c);
                mOfContactsPayload.put('PhoneNumber',varPartnerCon.Contact_Phone__c);
                mOfContactsPayload.put('IsPrimary',varPartnerCon.Is_Primary__c);
                mOfContactsPayload.put('IsEmailEnabled',varPartnerCon.Is_Email_Enabled__c);
                mOfContactsPayload.put('LiveId',varPartnerCon.Akam_Partner_Customer_Contact_Id__c);
                
                if(! mAkamCaseIdPartnerContact.containsKey(varPartnerCon.Case__c)){
                    mAkamCaseIdPartnerContact.put(varPartnerCon.Case__c, new List<Object>());
                }
                mAkamCaseIdPartnerContact.get(varPartnerCon.Case__c).add(mOfContactsPayload);
            
            
        }
        
    }
    
    /*
     * This method generates GUID that we send to MS.
     */ 
    private static String getGUID(){
        Blob aesKey = Crypto.GenerateAESKey(128);
        String aesKeyHex = EncodingUtil.ConvertTohex(aesKey);
        String guid = aesKeyHex.SubString(0,8)+ '-' + aesKeyHex.SubString(8,12) +
                      '-' + aesKeyHex.SubString(12,16) + '-' + aesKeyHex.SubString(16,20) + 
                      '-' + aesKeyHex.substring(20);
        return guid;
    }
    
    /*
     * Method for parsing receipt that comes from MS.
     * Stamps the MS Ticket Number on ER or MS Activity Id on Activity.
     */ 
    private void parseReceiptPayload(String receiptPayload,String eventObjectId,
                                     String eventType, Boolean isBefore){
        System.debug('#@#@ Receipt Processor ' + eventType + ' $$ ' + mActivityIdAndMSActivityId + ' %% ');
        for(Object varReceiptPayload :(List<Object>) JSON.deserializeUntyped(receiptPayload)){
            Map<String, Object> mReceiptPaylaod = (Map<String, Object>) varReceiptPayload;
            if((Integer) mReceiptPaylaod.get('Status') == 6 
                && eventType == 'Case Escalation'){
                Map<String,Object> mTicketSenderDetails = (Map<String, Object>) mReceiptPaylaod.get('TicketSender');
                Map<String,Object> mTicketReceiverDetails = (Map<String, Object>) mReceiptPaylaod.get('TicketReceiver');
                mAkamCaseIdAndMSTicket.put((String) mTicketSenderDetails.get('TicketReference'), 
                                           (String) mTicketReceiverDetails.get('TicketReference'));
                mERIdAndMSTicket.put(eventObjectId, 
                                     (String) mTicketReceiverDetails.get('TicketReference'));
            }
            if((Integer) mReceiptPaylaod.get('Status') == 6 
                && (eventType == 'Activity Creation'
                    || eventType == 'Activity Update')){
                List<Object> lCCNoteReceipts = (List<Object>) mReceiptPaylaod.get('CCNoteReceipts');
                Map<String,Object> mCCNoteReceiptsDetails = (Map<String,Object>) lCCNoteReceipts[0];
                if((Integer) mCCNoteReceiptsDetails.get('Status')==2){
                    mActivityIdAndMSActivityId.put(eventObjectId, (String) mCCNoteReceiptsDetails.get('Id'));
                    System.debug('#@#@ Receipt Processor ' + eventType + ' $$ ' + mActivityIdAndMSActivityId + ' %% ' + mCCNoteReceiptsDetails);
                }
            }
        }
    }
    
    private void updateCaseWhenReceiptReceived(Map<String,String> mAkamCaseIdAndMSTicket, Set<String> sCaseIdsForAzureFailure){
        List<Case> lCasesToUpdate = new List<Case>();
        for(Case varCase :[SELECT Id,Akam_Case_Id__c,Partner_Ticket_Number__c,
                           Escalation_Partner_Ticket__c  
                           FROM Case 
                           WHERE Akam_Case_Id__c IN :mAkamCaseIdAndMSTicket.keySet()]){
            varCase.Escalation_Partner_Ticket__c = mAkamCaseIdAndMSTicket.get(varCase.AKAM_Case_ID__c);
            varCase.Eligible_for_Partner_Case_Exchange__c = true;
            varCase.Validation_Override__c = true;
            varCase.Partner_Joint_Troubleshooting_Status__c = 'Open';                   
            lCasesToUpdate.add(varCase);
        }
        
        for(String varCaseId :sCaseIdsForAzureFailure){
            Case varCase = new Case();
            varCase.Id = varCaseId;
            varCase.Eligible_for_Partner_Case_Exchange__c = false;
            varCase.Validation_Override__c = true;
            lCasesToUpdate.add(varCase);
        }

        update lCasesToUpdate;
    }
    
    private void updateERWithTicketNum(Map<String,String> mERIdAndMSTicket){
        List<Engagement_Request__c> lERToUpdate = new List<Engagement_Request__c>();
        for(Engagement_Request__c varER :[SELECT Id,Partner_Ticket__c
                                          FROM Engagement_Request__c
                                          WHERE Id IN :mERIdAndMSTicket.keySet()]){
            varER.Partner_Ticket__c = mERIdAndMSTicket.get(varER.Id);
            varER.Partner_Receipt_Status__c = 'Success Receipt Received';
            lERToUpdate.add(varER);
        }
        
        update lERToUpdate;
    }
    
    private Map<String,Case_Exchange_Outbound_Partner_Product__c> getSupportTopicToSend(List<String> lSupportTopicToSend){
        Map<String,Case_Exchange_Outbound_Partner_Product__c> mSupportTopicAndMSId = new Map<String, Case_Exchange_Outbound_Partner_Product__c>();
        for(Case_Exchange_Outbound_Partner_Product__c varCaseExePartner :[SELECT Id,Support_Topic_Id__c,Partner_Product_Id__c, 
                                                                          Support_Topic_Concatenated__c 
                                                                          FROM Case_Exchange_Outbound_Partner_Product__c
                                                                          WHERE Support_Topic_Concatenated__c IN :lSupportTopicToSend]){
            mSupportTopicAndMSId.put(varCaseExePartner.Support_Topic_Concatenated__c,varCaseExePartner);
        }
        return mSupportTopicAndMSId;
    }
    
    
    
    private void updateCaseOnInboundQueueUpdate(List<String> lAkamCaseIds){
        
    }
    
    
    
    
    
    
    private void updateTaskWhenReceiptReceived(Map<String,String> mActivityIdAndMSActivityId, Set<String> sTaskIdsForAzureFailure){
        List<Task> lTaskToUpdate = new List<Task>();
        for(String varTaskId : mActivityIdAndMSActivityId.keySet()){
            Task varTask = new Task();
            varTask.Id = varTaskId;
            varTask.Partner_Activity_Id__c = mActivityIdAndMSActivityId.get(varTaskId);
            //varTask.Eligible_for_Partner_Exchange__c = true;
            varTask.Partner_Receipt_Status__c = 'Success Receipt Received';
            lTaskToUpdate.add(varTask);
        }

        for(String varTaskId :sTaskIdsForAzureFailure){
            Task varTask = new Task();
            varTask.Id = varTaskId;
            varTask.Partner_Receipt_Status__c = 'Failure Receipt Received';
            lTaskToUpdate.add(varTask);
        }
        System.debug('###$$$$ Task For Update ###$$$$ '+ lTaskToUpdate);
        update lTaskToUpdate;

    }
    
    /*
     * Method for creating payload the we send to MS when we create Activity(Partner or Customer)
     */ 
    public void creatPayloadForActivityUpdate(List<Task> lTask, Map<Id,Task> mOldTask){
        System.debug('## Into Payload Creation ## ' + lTask + ' $#$# ' + mOldTask);
        List<Outbound_Request_Queue__c> lOutboundRequestToInsert = new List<Outbound_Request_Queue__c>();
        Document varDocument = [SELECT Body FROM Document WHERE DeveloperName = 'Put_Ticket_Activity_Payload'];
        String activityPayloadFormat = varDocument.Body.toString();
        Map<String, Object> mActivityPayloadFormat = (Map<String, Object>) JSON.deserializeUntyped(activityPayloadFormat);
        Map<String, Object> mSenderPayload = (Map<String, Object>) mActivityPayloadFormat.get('Sender');
        List<Object> lCCNotes = (List<Object>) mActivityPayloadFormat.get('CCNotes');
        Map<String,Object> mCCNoteFormat = new Map<String,Object>();
        Set<String> sTaskRTId = new Set<String> {mCustomMetadata.get('MS Technical Task Record Types'),mCustomMetadata.get('MS Managed Security Task Record Types')};
        String trackingReference = getGUID();
        List<Task> lTaskForOutboundQueue = new List<Task>();
        List<String> lCaseIds = new List<String>();

        for(Task varTask :lTask){
            System.debug('## Into Payload Creation ## ' + sTaskRTId.contains(varTask.RecordTypeId));
            if(sTaskRTId.contains(varTask.RecordTypeId)
                && (varTask.Visibility__c == 'Customer' 
                    || varTask.Visibility__c == 'Partner Only')
                && (mOldTask == null
                    || varTask.Visibility__c != mOldTask.get(varTask.Id).Visibility__c
                    || varTask.Description != mOldTask.get(varTask.Id).Description
                    || varTask.Subject != mOldTask.get(varTask.Id).Subject
                    || varTask.Status != mOldTask.get(varTask.Id).Status)
                && varTask.Type__c != 'Inbound Partner Activity'
                && varTask.Status == 'Completed'
                && varTask.Type__c != 'Email'){               
                    
                    lTaskForOutboundQueue.add(varTask);
                    lCaseIds.add(varTask.WhatId);
     
            }
        }

        Map<String,Case> mCaseIdAndCase = new Map<String,Case> ([SELECT Id, Akam_Case_Id__c,Partner_Ticket_Number__c,
                                                                 Escalation_Partner_Ticket__c, Partner_Joint_Troubleshooting_Status__c,
                                                                 Eligible_for_Partner_Case_Exchange__c
                                                                 FROM Case
                                                                 WHERE Id IN :lCaseIds]);
        System.debug('## Into Payload Creation ## ' + lTaskForOutboundQueue + ' %$%$%$ ' + sTaskRTId);

        for(SObject varSObject :lTaskForOutboundQueue){
            Task varTask = (Task) varSObject;
            if(!varActivityCreationRecCheck 
               && mCaseIdAndCase.get(varTask.WhatId).Eligible_for_Partner_Case_Exchange__c
               && mCaseIdAndCase.get(varTask.WhatId).Partner_Joint_Troubleshooting_Status__c=='Open'){
                mActivityPayloadFormat.put('RequestDateTime',varTask.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                mActivityPayloadFormat.put('SystemTransactionId', getGUID());
                mActivityPayloadFormat.put('TrackingReference', trackingReference);
                lCCNotes.clear();
                mCCNoteFormat.put('Id',varTask.Partner_Activity_Id__c==null?'':varTask.Partner_Activity_Id__c);
                String descriptionForContent = 'Subject: ' + varTask.Subject;
                if(varTask.Description != null){
                    descriptionForContent = descriptionForContent + ' \n Description: ' + varTask.Description;
                }   
                if(descriptionForContent.length()>31970){
                    descriptionForContent = descriptionForContent.substring(0, 31969);
                }   
                mCCNoteFormat.put('Content','AKAM_CASE ' + mCaseIdAndCase.get(varTask.WhatId).Akam_Case_Id__c + ': ' + descriptionForContent);
                mCCNoteFormat.put('Type', '1');
                mCCNoteFormat.put('PartnerCookie',varTask.AKAM_Activity_ID__c);
                mCCNoteFormat.put('SharingLevel', varTask.Visibility__c=='Customer'?'2':'1');
                mCCNoteFormat.put('NoteFrom', UserInfo.getUserName());
                lCCNotes.add(mCCNoteFormat);
                mActivityPayloadFormat.put('CCNotes',lCCNotes);
                mSenderPayload.put('TicketReference', mCaseIdAndCase.get(varTask.WhatId).Akam_Case_Id__c);
                Outbound_Request_Queue__c varOutboundRecToInsert = new Outbound_Request_Queue__c();        
                varOutboundRecToInsert.Request_Data__c  = JSON.serializePretty(mActivityPayloadFormat);
                varOutboundRecToInsert.Request_Status__c = 'New';
                varOutboundRecToInsert.Tracking_Reference__c = trackingReference;
                varOutboundRecToInsert.Originating_Partner_Account__c = 'MSAzure';
                varOutboundRecToInsert.Event_Object_Id__c = varTask.Id;
                varOutboundRecToInsert.Event_Type__c = varTask.Partner_Activity_Id__c == null?'Activity Creation':'Activity Update';
                varOutboundRecToInsert.Case__c = varTask.WhatId;
                lOutboundRequestToInsert.add(varOutboundRecToInsert);
            }
        }
        if(!lOutboundRequestToInsert.isEmpty()){
            insert lOutboundRequestToInsert;
            varActivityCreationRecCheck = true;
        }
    }
    /*
     * Method for creating payload that we send to MS on Case Updates (System Updates i.e Severity Changes
     * and Regular Updates which are activity creation)
     */ 
    public void createPayloadForCaseUpdates(List<Case> lCasesForSystemUpdates, Map<Id,Case> oldMap){
        System.debug('### payloadFormat ' + lCasesForSystemUpdates + ' ' + oldMap);
        List<Case> lAzureCasesForStatusUpdates = new List<Case>();
        List<Case> lAzureCasesForCloseCollab = new List<Case>();
        List<Case> lAzureCasesForSevChange = new List<Case>();
        for(Case varCase :lCasesForSystemUpdates){
            if(varCase.Partner_Account__c == mCustomMetadata.get('MS Default Account Id') 
                && varCase.Partner_Joint_Troubleshooting_Status__c == 'Open'
                && varCase.Eligible_for_Partner_Case_Exchange__c
                && (varCase.RecordTypeId == mCustomMetadata.get('MS Managed Security Record Types') 
                    || varCase.RecordTypeId == mCustomMetadata.get('MS Technical Record Types'))){
                if(varCase.Status != oldMap.get(varCase.Id).Status){
                    //lAzureCasesForStatusUpdates.add(varCase);
                    if(varCase.Status.contains('Close')){
                        lAzureCasesForCloseCollab.add(varCase);
                    }                    
                }

                if(varCase.Severity__c != oldMap.get(varCase.Id).Severity__c){
                    lAzureCasesForSevChange.add(varCase);
                }
            }
        }
        System.debug('# The List For Updates ' + lAzureCasesForStatusUpdates + ' ### ' + lAzureCasesForCloseCollab + ' ### ' + lAzureCasesForSevChange);
        if(!lAzureCasesForCloseCollab.isEmpty() || !lAzureCasesForSevChange.isEmpty()){
            Document varDocument = [SELECT Body FROM Document WHERE DeveloperName = 'Put_Ticket_Activity_Payload'];
            String systemUpdatePayloadFormat = varDocument.Body.toString();
            Map<String, Object> mSystemUpdatePayloadFormat = (Map<String, Object>) JSON.deserializeUntyped(systemUpdatePayloadFormat);
            Map<String, Object> mSenderPayload = (Map<String, Object>) msystemUpdatePayloadFormat.get('Sender');
            List<Object> lCCNotes = (List<Object>) msystemUpdatePayloadFormat.get('CCNotes');
            Map<String,Object> mCCNoteFormat = new Map<String,Object>();

            if(!lAzureCasesForSevChange.isEmpty() && !varRecCheck){
                createOutboundRecForSevChange(lAzureCasesForSevChange,systemUpdatePayloadFormat);
            }

            /*if(!lAzureCasesForStatusUpdates.isEmpty() && !varRecCheck){
                createOutboundRecForStatusChange(lAzureCasesForStatusUpdates,systemUpdatePayloadFormat);
            }*/

            if(!lAzureCasesForCloseCollab.isEmpty() && !varRecCheck){
                //createOutboundRecForStatusChange(lAzureCasesForCloseCollab,systemUpdatePayloadFormat);
                createOutboundRecForCloseCollab(lAzureCasesForCloseCollab,systemUpdatePayloadFormat);
                updateCaseAndEROnCloseCollaboration(lAzureCasesForCloseCollab,false);
            }

            if(! lOutboundReqToInsert.isEmpty() && !varRecCheck){
                insert lOutboundReqToInsert;
                varRecCheck = true;
            }
        }
    }
    /*
     * Method for creating rec in Outbound Queue when the ER Severity is changed.
     */
    private void createOutboundRecForSevChange(List<Case> lAzureCasesForSevChange,String systemUpdatePayloadFormat){
        Map<String, Object> mSystemUpdatePayloadFormat = (Map<String, Object>) JSON.deserializeUntyped(systemUpdatePayloadFormat);
        Map<String, Object> mSenderPayload = (Map<String, Object>) msystemUpdatePayloadFormat.get('Sender');
        List<Object> lCCNotes = (List<Object>) msystemUpdatePayloadFormat.get('CCNotes');
        Map<String,Object> mCCNoteFormat = new Map<String,Object>();

        for(Case varCase :lAzureCasesForSevChange){
            String trackingReference = getGUID();
            mSenderPayload.put('TicketReference', varCase.Akam_Case_Id__c);
            mSenderPayload.put('Id', '17');
            mSystemUpdatePayloadFormat.put('RequestDateTime',System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            mSystemUpdatePayloadFormat.put('SystemTransactionId', getGUID());
            mSystemUpdatePayloadFormat.put('TrackingReference', trackingReference);
            lCCNotes.clear();
            mCCNoteFormat.put('Id','');
            mCCNoteFormat.put('Content', 'AKAM_CASE ' + varCase.Akam_Case_Id__c + ': Severity Changed to ' + varCase.Severity__c);
            mCCNoteFormat.put('Type', '2');
            mCCNoteFormat.put('PartnerCookie',varCase.Akam_Case_Id__c);
            mCCNoteFormat.put('SharingLevel', '1');
            mCCNoteFormat.put('NoteFrom', UserInfo.getName());
            lCCNotes.add(mCCNoteFormat);
            mSystemUpdatePayloadFormat.put('CCNotes',lCCNotes);
            Outbound_Request_Queue__c varOutboundRecToInsert = new Outbound_Request_Queue__c();
            varOutboundRecToInsert.Request_Data__c  = JSON.serializePretty(msystemUpdatePayloadFormat);
            varOutboundRecToInsert.Request_Status__c = 'New';
            varOutboundRecToInsert.Tracking_Reference__c = trackingReference;
            varOutboundRecToInsert.Originating_Partner_Account__c = 'MSAzure';
            varOutboundRecToInsert.Event_Object_Id__c = varCase.Id;
            varOutboundRecToInsert.Event_Type__c = 'Case Update';
            varOutboundRecToInsert.Case__c = varCase.Id;
            lOutboundReqToInsert.add(varOutboundRecToInsert);
        }
    }
    
    /*
     * Method for creating rec in Outbound Queue when the ER status is changed to Close.
     * This will happen automatically when the Case is Closed.
     */
    private void createOutboundRecForCloseCollab(List<Case> lAzureCasesForCloseCollab,String systemUpdatePayloadFormat){
        Map<String, Object> mSystemUpdatePayloadFormat = (Map<String, Object>) JSON.deserializeUntyped(systemUpdatePayloadFormat);
        Map<String, Object> mSenderPayload = (Map<String, Object>) msystemUpdatePayloadFormat.get('Sender');
        List<Object> lCCNotes = (List<Object>) msystemUpdatePayloadFormat.get('CCNotes');
        Map<String,Object> mCCNoteFormat = new Map<String,Object>();

        for(Case varCase :lAzureCasesForCloseCollab){
            String trackingReference = getGUID();
            mSenderPayload.put('TicketReference', varCase.Akam_Case_Id__c);
            mSenderPayload.put('Id', '17');
            mSystemUpdatePayloadFormat.put('RequestDateTime',System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            mSystemUpdatePayloadFormat.put('SystemTransactionId', getGUID());
            mSystemUpdatePayloadFormat.put('TrackingReference', trackingReference);
            lCCNotes.clear();
            mCCNoteFormat.put('Id','');
            mCCNoteFormat.put('Content', 'AKAM_CASE ' + varCase.Akam_Case_Id__c + ': Closing the Collaboration');
            mCCNoteFormat.put('Type', '3');
            mCCNoteFormat.put('PartnerCookie',varCase.Akam_Case_Id__c);
            mCCNoteFormat.put('SharingLevel', '1');
            mCCNoteFormat.put('NoteFrom', UserInfo.getName());
            lCCNotes.add(mCCNoteFormat);
            mSystemUpdatePayloadFormat.put('CCNotes',lCCNotes);
            Outbound_Request_Queue__c varOutboundRecToInsert = new Outbound_Request_Queue__c();
            varOutboundRecToInsert.Request_Data__c  = JSON.serializePretty(msystemUpdatePayloadFormat);
            varOutboundRecToInsert.Request_Status__c = 'New';
            varOutboundRecToInsert.Tracking_Reference__c = trackingReference;
            varOutboundRecToInsert.Originating_Partner_Account__c = 'MSAzure';
            varOutboundRecToInsert.Event_Object_Id__c = varCase.Id;
            varOutboundRecToInsert.Event_Type__c = 'Case Update';
            varOutboundRecToInsert.Case__c = varCase.Id;
            lOutboundReqToInsert.add(varOutboundRecToInsert);
            varCase.Partner_Joint_Troubleshooting_Status__c = 'Closed';
            varCase.Eligible_for_Partner_Case_Exchange__c = false;
            varCase.Validation_Override__c = true;
        }
    }
    /*
     * This method updates the ER and Case to Close when the status of the Case is changed to Close.
     */ 
    private void updateCaseAndEROnCloseCollaboration(List<Case> lAzureCasesForCloseCollab, Boolean isInbound){
        List<String> lERRTIds = new List<String>{mCustomMetadata.get('MS Inbound ER Record Type Id'),mCustomMetadata.get('MS Outbound ER Record Type Id')};
        List<String> lCaseIds = new List<String>();
        List<Case> lCaseToCloseCollabStatus = new List<Case>();
        List<Engagement_Request__c> lERToUpdate = new List<Engagement_Request__c>();
        for(Case varCase :lAzureCasesForCloseCollab){
            lCaseIds.add(varCase.Id);
            if(isInbound){
                varCase.Eligible_for_Partner_Case_Exchange__c = false;
                varCase.Partner_Joint_Troubleshooting_Status__c = 'Closed';
                varCase.Validation_Override__c = true;
                lCaseToCloseCollabStatus.add(varCase);
            }
        }

        for(Engagement_Request__c varER : [SELECT Id, Request_Status__c
                                           FROM Engagement_Request__c 
                                           WHERE Case__c IN :lCaseIds AND Request_Status__c = 'Open'
                                           AND RecordTypeId IN :lERRTIds]){
            varER.Request_Status__c = 'Closed';
            lERToUpdate.add(varER);
        }

        update lERToUpdate;
        if(!lCaseToCloseCollabStatus.isEmpty()){
            update lCaseToCloseCollabStatus;
        }
    }
    /*
     * Method for creating Outbound Request recs when the Status of the Case is changed.
     * We are sending the update to MS only when the status is changing to Close.
     */ 
    /*private void createOutboundRecForStatusChange(List<Case> lAzureCasesForStatusUpdates,String systemUpdatePayloadFormat){
        Map<String, Object> mSystemUpdatePayloadFormat = (Map<String, Object>) JSON.deserializeUntyped(systemUpdatePayloadFormat);
        Map<String, Object> mSenderPayload = (Map<String, Object>) msystemUpdatePayloadFormat.get('Sender');
        List<Object> lCCNotes = (List<Object>) msystemUpdatePayloadFormat.get('CCNotes');
        Map<String,Object> mCCNoteFormat = new Map<String,Object>();

        for(Case varCase :lAzureCasesForStatusUpdates){
            String trackingReference = getGUID();
            mSenderPayload.put('TicketReference', varCase.Akam_Case_Id__c);
            mSenderPayload.put('Id', '17');
            mSystemUpdatePayloadFormat.put('RequestDateTime',System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            mSystemUpdatePayloadFormat.put('SystemTransactionId', getGUID());
            mSystemUpdatePayloadFormat.put('TrackingReference', trackingReference);
            lCCNotes.clear();
            mCCNoteFormat.put('Id','');
            mCCNoteFormat.put('Content', 'AKAM_CASE ' + varCase.Akam_Case_Id__c + ': Status Changed to ' + varCase.Status);
            mCCNoteFormat.put('Type', '2');
            mCCNoteFormat.put('PartnerCookie',varCase.Akam_Case_Id__c);
            mCCNoteFormat.put('SharingLevel', '1');
            mCCNoteFormat.put('NoteFrom', UserInfo.getName());
            lCCNotes.add(mCCNoteFormat);
            mSystemUpdatePayloadFormat.put('CCNotes',lCCNotes);
            Outbound_Request_Queue__c varOutboundRecToInsert = new Outbound_Request_Queue__c();            
            varOutboundRecToInsert.Request_Data__c  = JSON.serializePretty(msystemUpdatePayloadFormat);
            varOutboundRecToInsert.Request_Status__c = 'New';
            varOutboundRecToInsert.Tracking_Reference__c = trackingReference;
            varOutboundRecToInsert.Originating_Partner_Account__c = 'MSAzure';
            varOutboundRecToInsert.Event_Object_Id__c = varCase.Id;
            varOutboundRecToInsert.Event_Type__c = 'Case Update';
            varOutboundRecToInsert.Case__c = varCase.Id;
            lOutboundReqToInsert.add(varOutboundRecToInsert);
        }
    }*/
    
    public void validateAdditionalEmailAddress(List<Engagement_Request__c> lAzureERsForEmailValidation){
        for(Engagement_Request__c varER :lAzureERsForEmailValidation){
            if(varER.Additional_CC_List__c != null && varER.Additional_CC_List__c != ''){
                for(String varEmailToValidate : varER.Additional_CC_List__c.replaceAll(',',';').split(';')){
                    String validEmailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
                    Pattern validEmailPattern = Pattern.compile(validEmailRegex);
                    Matcher emailMatcher = validEmailPattern.matcher(varEmailToValidate.trim());
                    if(! emailMatcher.matches()){
                       varER.addError('Please enter valid email address(es) in Additional CC List, separated by comma or semicolon if needed.');
                    }
                }
            }
        }
    }
}