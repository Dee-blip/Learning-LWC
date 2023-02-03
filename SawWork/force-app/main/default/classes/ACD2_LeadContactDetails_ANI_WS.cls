/****************************************************************************
 * Developer    : Sharath Prasanna
 * Enhancement  : Marketing API ACD
 * Date         : 16th Jan 2020
 * Test Class   : ACD2_Webservices_Test
 ---------------------------------------------------
    Input Parameters : CallGUID (string), ANI
    
    Use Cases:
    ----------
    1. ANI -> Marketo Lead and/or Contact found  - 1 CTA record found and the C2A owner is a User-> return true and the C2A owner
    (/services/apexrest/ACD2_LeadContactDetails_ANI_WS?ANI=+919164798007)
    
    2. ANI -> Marketo Lead and/or Contact found  - 1 CTA record found and the C2A owner is a Queue-> return true and Account Projected SDR
    (/services/apexrest/ACD2_LeadContactDetails_ANI_WS?ANI=+918455845510)

    3. ANI -> Marketo Lead and/or Contact found  - Multiple CTA records found and the C2A owner is a User-> Select the latest modified CTA -> return true and the C2A owner
    (/services/apexrest/ACD2_LeadContactDetails_ANI_WS?ANI=+918088990867)

    4. ANI -> Marketo Lead and/or Contact found  - Multiple CTA records found and the C2A owner is a Queue-> Select the latest modified CTA -> return true and Account Projected SDR
    (/services/apexrest/ACD2_LeadContactDetails_ANI_WS?ANI=+916666666666)
    
    5. ANI -> Marketo Lead and/or Contact found  - No CTA record found -> Select the latest modified Lead/Contact -> return true and Account Projected SDR
    (/services/apexrest/ACD2_LeadContactDetails_ANI_WS?ANI=+1800560900)

    6. ANI -> No Marketo Lead and/or Contact found -> return false
    (/services/apexrest/ACD2_LeadContactDetails_ANI_WS?ANI=+9191647980079000)

 
 */ 
@RestResource(urlMapping='/ACD2_LeadContactDetails_ANI_WS/*')
global class ACD2_LeadContactDetails_ANI_WS
{
    // Wrapper structure to be returned to Cisco
    global class MarketingResponseWrapper
    {
        String isContactFound;// true if found: false otherwise
        String isC2AFound; //true or false
        String AkAM_Contact_Id; //null if responseCode 0 and String otherwise
        
        //String agentId; //String if responseCode 2 and null otherwise        
        
        String SDR_AgentID; // Account SDR Agent when CTA is not found
        String Projected_AgentID; // CTA Owner 

        global MarketingResponseWrapper()
        {
            isContactFound = 'false';
            isC2AFound = 'false';            
        }
    }

    @HttpGet
    global static MarketingResponseWrapper getListOutput() 
    {
        Datetime requestReceivedTime = DateTime.now();
        RestRequest req = RestContext.request;

        String originalInparam = req.params.get('ANI');
        String inparam = originalInparam;
        String callGUID = req.params.get('CallGUID');
        
        MarketingResponseWrapper marketingResponseWrapperObject = new MarketingResponseWrapper();
        if(!String.isBlank(inparam))
        {
            try
            {
                inparam = inparam.trim();
                inparam = ACD2_UtilClass.prepareANI(inparam);
                
                List<list<SObject>> searchList = new List<list<SObject>>();
                                
                searchList = [FIND :inparam in PHONE FIELDS RETURNING CONTACT (Id, Akam_Contact_Id__c,Account.Projected_SDR__r.Alias,Account.Projected_SDR__r.isActive, lastmodifieddate order by lastmodifieddate desc ),                                                                     
                             LEAD (Id, AKAM_Lead_ID__c,lastmodifieddate, Associated_Account__r.Projected_SDR__r.Alias, Associated_Account__r.Projected_SDR__r.isActive where RecordType.Name = 'Marketo Lead' order by lastmodifieddate desc )];
                
                List<Contact> contactList = new List<Contact>();
                contactList = ((List<Contact>)searchList[0]);
                
                List<Lead> leadList = new List<Lead>();
                leadList = ((List<Lead>)searchList[1]);
        
                if(!contactList.isEmpty() || !leadList.isEmpty())
                {
                    String recordType = 'Akamai Lead';
                    Set<String> status = new Set<String>();
                    status.add('New');
                    status.add('In Process');
                    String parentId;
                    
                    marketingResponseWrapperObject.isContactFound = 'true';
                    
                    String query = 'Select Id, OwnerId, Owner.Alias, Owner.isActive, Associated_Account__r.Projected_SDR__r.Alias,Associated_Account__r.Projected_SDR__r.isActive, Associated_Contact__r.lastmodifieddate,Associated_Contact__r.Akam_Contact_Id__c, ';
                    
                    query += 'Parent_Lead__r.lastmodifieddate, Parent_Lead__r.AKAM_Lead_ID__c  from Lead where RecordType.Name = :recordType and Status in :status and ';
                        
                    query += ' (Associated_Contact__c in :contactList or Parent_Lead__c in :leadList) ';
                                    
                    query += ' order by lastmodifieddate desc limit 1';
            
                    system.debug('query+ ' + query);    
                    List<Lead> callToAction = Database.query(query);
                    
                    String selectedRec;
                    String ownerSalesforceId;
                    String ownerAlias;
                    
                    if(callToAction != null && !callToAction.isEmpty())
                    {
                        
                        datetime contactDate = callToAction.get(0).Associated_Contact__r.lastmodifieddate;
                        datetime leadDate = callToAction.get(0).Parent_Lead__r.lastmodifieddate;
                        selectedRec = contactDate == null? 'Lead': 
                                                (leadDate == null? 'Contact' : 
                                                    (contactDate >= contactDate ? 'Contact' :
                                                     'Lead'));
                        marketingResponseWrapperObject.AkAM_Contact_Id = selectedRec == 'Lead'?callToAction.get(0).Parent_Lead__r.AKAM_Lead_ID__c : callToAction.get(0).Associated_Contact__r.Akam_Contact_Id__c;
                        ownerSalesforceId = callToAction[0].OwnerId;
                        
                        marketingResponseWrapperObject.isC2AFound = 'true';
                        if(ownerSalesforceId != null && ownerSalesforceId.startsWith('005') )
                        {
                            marketingResponseWrapperObject.SDR_AgentID = callToAction[0].Owner.isActive? callToAction[0].Owner.alias: null;
                        }
                        marketingResponseWrapperObject.Projected_AgentID  = callToAction[0].Associated_Account__r.Projected_SDR__r.isActive? callToAction[0].Associated_Account__r.Projected_SDR__r.Alias : null;
                    }
                    else
                    {
                        selectedRec = contactList.size() == 0? 'Lead': 
                                                (leadList.size() == 0? 'Contact' : 
                                                    (contactList[0].lastmodifieddate >= leadList[0].lastmodifieddate ? 'Contact' :
                                                     'Lead'));
                        marketingResponseWrapperObject.AkAM_Contact_Id = selectedRec == 'Lead' ? leadList[0].AKAM_Lead_ID__c: contactList[0].Akam_Contact_Id__c;
                        Boolean isActiveOwner = selectedRec == 'Lead' ? leadList[0].Associated_Account__r.Projected_SDR__r.isActive: contactList[0].Account.Projected_SDR__r.isActive;
                        
                        if(isActiveOwner)
                        {
                            ownerAlias = selectedRec == 'Lead' ? leadList[0].Associated_Account__r.Projected_SDR__r.Alias: contactList[0].Account.Projected_SDR__r.Alias;
                            marketingResponseWrapperObject.Projected_AgentID = ownerAlias;
                            
                        }
                    }
                }
            }
            catch(Exception e)
            {
                ACD2_UtilClass.createLog(callGUID,'ACD2_LeadContactDetails_ANI_WS', 'ANI: '+originalInparam ,' Error Message: ' +e.getMessage()+ ' StackTrace: ' + e.getStackTraceString(),'Exception',requestReceivedTime );
                ACD2_UtilClass.sendErrorMail(inparam, e.getMessage(),e.getStackTraceString(),'ACD 2.0 Exception in ACD2_LeadContactDetails_ANI_WS');
                return marketingResponseWrapperObject;
            }
        
        }

        ACD2_UtilClass.createLog(callGUID,'ACD2_LeadContactDetails_ANI_WS', 'ANI: '+originalInparam ,JSON.serialize(marketingResponseWrapperObject),'Valid',requestReceivedTime);
        return marketingResponseWrapperObject;
    }
    
}