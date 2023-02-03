/***
    DocuSign_Status_ai_au
    @version 1.0
    @author Ali KM <mohkhan@akamai.com>
    @Description : This trigger is called on 'after insert' and 'after update' events on DocuSign_Status__c object.
                   It takes care of the following :
                   - Setting the Associated Opportunities StageName to '6-Commit' if DocuSign_Status__c.isCustomerEnvelope__c is true & 
                    e-Sign process is completed - DocuSign_Status__c.dsfs__Envelope_Status__c == 'Completed'
    
    @History
    --Developer           --Date            --Change
    Ali KM                31/05/2011        CR 1132858 E-Sign: Flipping to SS-6 once signing process is complete shold work only 
                                            if Customer Signee is part of the envelope
                                                -> Created this Trigger
    Ali KM                08/04/2012        CR 1477954 Forecasting: Need to update QA env for forecasting
                                                -> Changing the StageName picklist 6-Commit to 6-Signed. 
                                                -> Also replacing where possible StageName 6-Signed with Probability = 90%. 
                                                   This way there is no dependency on StageName and instead relying on equivalent Probability% value.
    Ali KM                12/11/2012        CR 1895176 - Systems Allows Oppty to be moved to SS-6 even after the expiration of Valid Until Date  
                                                -> Send email for Completed E-Sign Request having expired ValidUntilDate. Email goes to Oppty Owner & SA Owner.
    Pranav Moktali        07/08/2013        CR 2327331 - DocuSign object can be related to either agreement or an Order Approval object.
                                                -> Flip the Agreement stage to 'Other Party Signatures' on creation of DocuSign Status   
                                                -> Update the Agreement status to 'Fully Signed' on completion.
    Lisha Murthy          Mar/2014          CR 2568369 - Change Business Terms (Amend agreement) - usability    
    Ali KM                21/Dec/2015       QTOO-2273 - Triggering STP flow in-case customEnvelope & signature process is completed.
    Ali KM                12/Jan/2016       QTOO-2740 - Copying over DocuSignStatus.Completed to Agreement.                         
*/
Trigger DocuSign_Status_ai_au on dsfs__DocuSign_Status__c (after insert, after update) 
{
    // runs only on updates
    if (!Trigger.isInsert)
    {
        Set<Id> dssOAIdList = new Set<Id>();
        List<Id> dssAptAgIdList = new List<Id>();  
        Map<Id, Id> opptyId_OAID = new Map<Id,Id>();
        Set<Id> opptyIdList = new Set<Id>();
        Set<Id> opptyIdListWithDosignStatusNotComplete = new Set<Id>();
        
        List<Opportunity> opptyToUpdateList = new List<Opportunity>();
        List<dsfs__DocuSign_Status__c> DocuSignStatusList = new List<dsfs__DocuSign_Status__c>();
        Map<Id, Opportunity> opptyMapSS6 = new Map<Id, Opportunity>();
        Set<Id> stpEnabledAgmntSet = new Set<Id>();

        Map<Id, Id> agmntToDSIdMap = new Map<Id, Id>();


        //Map<Id,Map<dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_Recipient__c>> OrderApproval = new Map<Id,Map<dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_Recipient__c>>();

        for (dsfs__DocuSign_Status__c dss : Trigger.new)
        {
            // run only when Envelope Status = Completed & Status is changing.
            if (dss.dsfs__Envelope_Status__c != null && dss.dsfs__Envelope_Status__c == 'Completed'
                && dss.dsfs__Envelope_Status__c != Trigger.oldMap.get(dss.Id).dsfs__Envelope_Status__c)
                {
                    if (dss.Order_Approval__c!=null){
                        dssOAIdList.add(dss.Order_Approval__c);
                        opptyId_OAID.put(dss.Order_Approval__c,dss.Associated_OpportunityID__c);
                    }
                    //if (dss.Apttus_Agreement__c!=null)
                    //{
                    //    dssAptAgIdList.add(dss.Apttus_Agreement__c);
                    //    agmntToDSIdMap.put(dss.Apttus_Agreement__c, dss.Id);
                    //}
                }
        }
        System.debug('Order Approval list:'+dssOAIdList);
        System.debug('opportunity Map:'+opptyId_OAID);
        //System.debug(LoggingLevel.ERROR, 'ECHO - OALIST '+dssOAIdList);
        List<dsfs__DocuSign_Status__c> docusignCompleted = new List<dsfs__DocuSign_Status__c>();
        if (dssOAIdList.size()>0 || dssAptAgIdList.size()>0)
        {
            if (!DocuSignStatusTriggerClass.emailAlertOFExpiredESignCompeletedFirsRunFlag)
                return;
            if(dssOAIdList.size()>0){
                
                DocuSignStatusList = [Select id,dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_ID__c,  Associated_OpportunityID__c, Order_Approval__c from dsfs__DocuSign_Status__c where Order_Approval__c In :dssOAIdList];
                if(DocuSignStatusList != null){
                    for(dsfs__DocuSign_Status__c DSL : DocuSignStatusList){
                        if(DSL.dsfs__Envelope_Status__c == 'Completed'){
                            docusignCompleted.add(DSL);
                        }
                        else if(dssOAIdList.contains(DSL.Order_Approval__c))
                            dssOAIdList.remove(DSL.Order_Approval__c);
                        
                    }
                }
            }
            System.debug('DocuSignStatusList'+DocuSignStatusList);
            System.debug('dssOAIdList:'+dssOAIdList);
            System.debug('Completed List:'+docusignCompleted);
            if(dssOAIdList.size()>0)
            {
                Map<Id,List<String>> OA_DocusignEnvelope = new Map<Id,List<String>>();
                //Map<Id,List<Id>> OA_DocusignEnvelope = new Map<Id,List<Id>>();
                List<String> docuSignEnv = new List<String>();
                for(dsfs__DocuSign_Status__c DSL: docusignCompleted){
                    if(dssOAIdList.contains(DSL.Order_Approval__c)){
                        if(OA_DocusignEnvelope.containsKey(DSL.Order_Approval__c)){
                            list<String> l = OA_DocusignEnvelope.get(DSL.Order_Approval__c);
                            l.add(DSL.dsfs__DocuSign_Envelope_ID__c);
                            OA_DocusignEnvelope.put(DSL.Order_Approval__c, l);
                        }
                        else{
                            OA_DocusignEnvelope.put(DSL.Order_Approval__c, new List<String>{DSL.dsfs__DocuSign_Envelope_ID__c});
                        }
                        docuSignEnv.add(DSL.dsfs__DocuSign_Envelope_ID__c);
                    }
                }
                System.debug('OA_DocusignEnvelope:'+OA_DocusignEnvelope);
                System.debug('docuSignEnv:'+docuSignEnv);

                List<dsfs__DocuSign_Envelope__c> DocusignEnvelope = new List<dsfs__DocuSign_Envelope__c>();
                DocusignEnvelope = [select dsfs__DocuSign_Envelope_ID__c, (select dsfs__DocuSign_Recipient_Role__c from dsfs__DocuSign_Envelope_Recipient__r) from dsfs__DocuSign_Envelope__c where dsfs__DocuSign_Envelope_ID__c IN :docuSignEnv];

                Map<String, List<String>> envelopeId_RecipientRole = new Map<String, List<String>>();

                for(dsfs__DocuSign_Envelope__c DSE : DocusignEnvelope){
                    if(envelopeId_RecipientRole.containsKey(DSE.dsfs__DocuSign_Envelope_ID__c)){
                        List<String> s = envelopeId_RecipientRole.get(DSE.dsfs__DocuSign_Envelope_ID__c);
                        for(dsfs__DocuSign_Envelope_Recipient__c EnvelopeRec : DSE.dsfs__DocuSign_Envelope_Recipient__r){
                            s.add(EnvelopeRec.dsfs__DocuSign_Recipient_Role__c);
                        }
                        envelopeId_RecipientRole.put((DSE.dsfs__DocuSign_Envelope_ID__c).toLowerCase(), s);
                    }else{
                        List<String> s1 = new List<String>();
                        for(dsfs__DocuSign_Envelope_Recipient__c EnvelopeRec : DSE.dsfs__DocuSign_Envelope_Recipient__r){
                            s1.add(EnvelopeRec.dsfs__DocuSign_Recipient_Role__c);
                        }
                        envelopeId_RecipientRole.put((DSE.dsfs__DocuSign_Envelope_ID__c).toLowerCase(), s1);
                    }
                }

                System.debug('envelopeId_RecipientRole:'+envelopeId_RecipientRole);

                //OA_DocusignEnvelope:{a0I5B000000DG3dUAG=(3F0833B8-9CC2-4481-8E40-38232644E854, 08AA1B2F-1EA0-4AE6-89EE-59F41E39EC48)}
                //envelopeId_RecipientRole:{08aa1b2f-1ea0-4ae6-89ee-59f41e39ec48=(Customer Signatory 1), 3f0833b8-9cc2-4481-8e40-38232644e854=(Akamai RSM 1)}


                Map<id, List<String>> OA_RecipientRole = new Map<id, List<String>>();

                for(Id OAid: OA_DocusignEnvelope.keySet()){
                    List<String> EnvelopeIdList = OA_DocusignEnvelope.get(OAid);
                    for(String Envelopeid : EnvelopeIdList){
                        if(!envelopeId_RecipientRole.isEmpty())
                            {
                                List<String> role = envelopeId_RecipientRole.get(Envelopeid.toLowerCase());
                                if(OA_RecipientRole.containsKey(OAid)){
                                    List<String> s2 = OA_RecipientRole.get(OAid);
                                    s2.addAll(role);
                                    OA_RecipientRole.put(OAid, s2);
                                }
                                else
                                {
                                    OA_RecipientRole.put(OAid, role);
                                }
                        }
                    }
                }
                System.debug('OA_RecipientRole'+OA_RecipientRole);

                for(Id OAid : OA_RecipientRole.keySet()){
                    Set<String> RoleName = new Set<String>(OA_RecipientRole.get(OAid));
                    if(!((RoleName.contains('Customer Signatory 1') || RoleName.contains('Customer Signatory 2') || RoleName.contains('Customer Signatory 3')) && ( RoleName.contains('Akamai RSM 1') || RoleName.contains('Akamai RSM 2') || RoleName.contains('Akamai RSM 3')))){
                        dssOAIdList.remove(OAid);
                    }
                }
                
                System.debug('dssOAIdList'+dssOAIdList);
                if(dssOAIdList.size() > 0){
                    for(Id OrderApprovalId : dssOAIdList){
                        opptyIdList.add(opptyId_OAID.get(OrderApprovalId));
                    }
                }
            }
/*
            if(dssAptAgIdList.size()>0){
                // Fetch DocuSignStatus associated with Apttus Agreement
                for (Apttus__APTS_Agreement__c ag : [Select Id,Apttus__Status_Category__c,DocusignPoYesSelected__c,PO_Required__c,DocusignPoNoSelected__c,Apttus__Status__c, Apttus__Related_Opportunity__c, AKAM_Agreement_ID__c from Apttus__APTS_Agreement__c where Id IN : dssAptAgIdList])
                {
                    if (ag.Apttus__Related_Opportunity__c != null)
                        opptyIdList.add(ag.Apttus__Related_Opportunity__c);
                    aptAgList.add(ag);
                }
            }*/


           /* if(aptAgList.size()>0){

                     for(Apttus__APTS_Agreement__c ag : aptAgList){
                        
                            if(ag.Apttus__Status_Category__c != 'In Signatures' || ag.Apttus__Status__c != 'Fully Signed')
                            {
                               
                                 if(ag.DocusignPoYesSelected__c )
                                      ag.PO_Required__c='Y';
                                 else if(ag.DocusignPoNoSelected__c)
                                      ag.PO_Required__c='N';
                                 else 
                                      ag.PO_Required__c='U';
                            }
                        }

                        update aptAgList;
            }*/



            System.debug(LoggingLevel.ERROR, 'ECHO - opptyIdList2: '+opptyIdList);
            if (opptyIdList.size()>0)
            {
                //List<Opportunity> opptyToUpdateList = new List<Opportunity>();
                //String strOFExpiredEmailTemplateId = GsmUtilClass.GetCustomSettingValue('OFExpiredAlert#EmailTemplateId2');
                //String strCRMAdminOrgWideId= GsmUtilClass.GetCustomSettingValue('OrgWideId#CRMADMINS');
                //String strCCEmailIds= GsmUtilClass.GetCustomSettingValue('OFExpiredAlert#2CCEmailIds');

                String strOFExpiredEmailTemplateId = GsmUtilClass.getGSMSettingValue('OFExpiredAlert_EmailTemplateId2');
                String strCRMAdminOrgWideId = GsmUtilClass.getGSMSettingValue('OrgWideId_CRMADMINS');
                String strCCEmailIds = GsmUtilClass.getGSMSettingValue('OFExpiredAlert_2CCEmailIds');

                Messaging.SingleEmailMessage[] sendOFExpiredAlertEmailList = new List<Messaging.SingleEmailMessage>();
                Integer emailIdcounter = 0;
                Id toEmail;
                String ccEmail;
                
                for (Opportunity oppty : [Select Id, Name, Owner.isActive, OwnerId, /*SA_Owner__r.isActive, SA_Owner__c,*/   
                    Validation_Override__c, DocuSign_Envelope_Status__c, DD_CCG_Expiration_Date__c, StageName, /*SA_Owner__r.Email,*/(Select id, Valid_Until_Date__c,Ownerid,Owner.isactive,Owner.Email from Related_Cases__r where RecordType.Name = 'Order Approval-Order Management' limit 1)
                        from Opportunity where Id IN : opptyIdList])
                         {
                            System.debug(LoggingLevel.ERROR, 'Expiration Date:::'+oppty.DD_CCG_Expiration_Date__c);
                            System.debug('Expiration Date:::'+ oppty.DD_CCG_Expiration_Date__c);
                            if (oppty.StageName != '6. Signed' && oppty.StageName != 'Closed Won' && oppty.StageName != 'Closed Lost' 
                                && oppty.StageName != 'Closed Duplicate' && oppty.StageName != 'Closed Contract Ended' && oppty.StageName != 'Closed Admin'
                                && (oppty.Related_Cases__r.size() > 0 && oppty.Related_Cases__r[0].Valid_Until_Date__c !=null &&  oppty.Related_Cases__r[0].Valid_Until_Date__c >=Date.today()))//SFDC-3539
                                {
                                    oppty.StageName = '6. Signed';//SFDC-3539
                                    oppty.Validation_Override__c = true;
                                    opptyMapSS6.put(oppty.Id, oppty);
                                    opptyToUpdateList.add(oppty);
                                }  
                            else if (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('pendingESignWithExpiredOFAlert') && oppty.StageName != '6. Signed' && oppty.StageName != 'Closed Won' && 
                                oppty.StageName != 'Closed Lost' && oppty.Related_Cases__r.size() > 0 && oppty.Related_Cases__r[0].Valid_Until_Date__c != null && oppty.Related_Cases__r[0].Valid_Until_Date__c < Date.today())//SFDC-3539
                                {
                                    // process before sending Email...
                                    toEmail=null;
                                    ccEmail='';
                                    //System.assertEquals(oppty.DocuSign_Envelope_Status__c,'Completed');
                                    
                                    if (!oppty.Owner.isActive)
                                        continue;
                                        
                                    toEmail=oppty.OwnerId;
                                    emailIdcounter++;
                                    //string var= String.valueOf(oppty.Related_Cases__r[0].Ownerid);
                                    
                                    if(oppty.Related_Cases__r[0].Ownerid !=null && String.valueOf(oppty.Related_Cases__r[0].Ownerid).Startswith('005') && oppty.Related_Cases__r[0].Owner.isActive)
                                    {
                                        ccEmail=oppty.Related_Cases__r[0].Owner.Email;
                                        emailIdcounter++;
                                    }
                                    
                                    if (strCCEmailIds!=null && strCCEmailIds.trim().contains('@'))
                                    {
                                        if (ccEmail=='')
                                            ccEmail = strCCEmailIds;
                                        else
                                            ccEmail += ',' + strCCEmailIds;
                                            
                                    }
                                    sendOFExpiredAlertEmailList.add(GsmUtilClass.createSingleEmail(oppty.Id,toEmail,ccEmail,strOFExpiredEmailTemplateId,strCRMAdminOrgWideId));
                                    
                                } 
                        }
                //if (opptyToUpdateList.size()>0)
                    //update opptyToUpdateList;
                if (sendOFExpiredAlertEmailList.size()>0)
                {
                    // send email
                    Messaging.reserveSingleEmailCapacity(emailIdcounter);
                    //Messaging.SendEmailResult[] sendEmailResultList = new List<Messaging.SendEmailResult>();
                    Messaging.SendEmailResult[]  sendEmailResultList = Messaging.sendEmail(sendOFExpiredAlertEmailList, false);
                }
            }

            // Ali KM - 18/Dec/15
            /*
            if (aptAgList.size()>0 && opptyMapSS6.size()>0)
            {
                for(Apttus__APTS_Agreement__c ag : aptAgList)
                {
                    ag.e_Signatures__c = true;
                     if(ag.DocusignPoYesSelected__c )
                                      ag.PO_Required__c='Y';
                     else if(ag.DocusignPoNoSelected__c)
                                      ag.PO_Required__c='N';
                     else 
                                      ag.PO_Required__c='U';

                    if(ag.Apttus__Related_Opportunity__c!=null && opptyMapSS6.get(ag.Apttus__Related_Opportunity__c)!=null && Q2O_EvaluateSTPAgreement.evaluateSTPCriteria(ag.Id))
                    {
                        stpEnabledAgmntSet.add(ag.Id);
                        OpportunityTriggerClass.stpEnabledOpptyIdSet.add(ag.Apttus__Related_Opportunity__c);
                    }
                }
                update aptAgList;
            }*/

            if (opptyToUpdateList.size()>0)
                update opptyToUpdateList;

            /*
            if(dssAptAgIdList.size()>0){
                //Update the Agreement status to fully signed.
                List<Apttus__APTS_Agreement__c> aptAgUpdateList = new List<Apttus__APTS_Agreement__c>();
                
                
                for(Apttus__APTS_Agreement__c ag : aptAgList)
                {
                    if(ag.Apttus__Status_Category__c != 'In Signatures' || ag.Apttus__Status__c != 'Fully Signed')
                    {
                        ag.Apttus__Status__c = 'Fully Signed';
                         
                        Id dsId = agmntToDSIdMap.get(ag.Id);
                        if (dsId!=null)
                        {
                            dateTime dt = Trigger.newMap.get(dsId).dsfs__Completed_Date_Time__c;
                            if (dt==null) // default this to now incase Completed Date is blank on status record.
                                dt = DateTime.now();
                            ag.Apttus__Company_Signed_Date__c = date.newinstance(dt.year(), dt.month(), dt.day());     
                        }
                    }*/

                    // Moved eligibility code 
                  /*  if (stpEnabledAgmntSet.contains(ag.Id))
                    {
                        ag.isSTP__c = true;
                    }
                    else
                        ag.isSTP__c = false;*/
                /*    aptAgUpdateList.add(ag);
                }
                if(aptAgUpdateList.size()>0){
                    Database.update(aptAgUpdateList, false);
                }   

            }*/
            DocuSignStatusTriggerClass.emailAlertOFExpiredESignCompeletedFirsRunFlag=false;
        }
    }
    
    // runs only on Insert
    /*
    if (Trigger.isInsert)
    {
        List<Id> dssAptAgIdList = new List<Id>();
        List<Apttus__APTS_Agreement__c> aptAgUpdateList = new List<Apttus__APTS_Agreement__c>();
        
        for (dsfs__DocuSign_Status__c dss : Trigger.new)
            dssAptAgIdList.add(dss.Apttus_Agreement__c);
        
        if(dssAptAgIdList.size()>0)
        {
            for(Apttus__APTS_Agreement__c ag : [Select Id,Apttus__Status_Category__c, Apttus__Status__c, Apttus__Related_Opportunity__c 
                from Apttus__APTS_Agreement__c where Id IN : dssAptAgIdList
                and Apttus__Status_Category__c != 'Request'
                and Apttus__Status__c != 'Request'
                //CR 2579070 - Stage flip is not happening for MSA's for eSignatuers
                //and Purpose__c != 'Change Business Terms'
                ])
            {
                if(ag.Apttus__Status_Category__c != 'In Signatures' || ag.Apttus__Status__c != 'In Signatures')
                {   
                    ag.Apttus__Status_Category__c = 'In Signatures';
                    ag.Apttus__Status__c = 'In Signatures';
                    aptAgUpdateList.add(ag);
                }
            }
            if(aptAgUpdateList.size()>0)
                update aptAgUpdateList;
        }
    }*/
}