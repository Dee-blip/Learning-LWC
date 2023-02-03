/* History:
 * =========================
 * @author  Hitesh CHawda,  1st June 2017  
 SFDC - 1641 
 */ 
 global class CampaignCleanup_LeadToOpptyBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{
    global final string query;
    global DMLResults results;
    integer recordLimit ;
    //Do not consider MAPI check , add Closed Oppty filter
    global CampaignCleanup_LeadToOpptyBatchClass()
     {
         query ='select Id,Campaign_Cleanup_Comment__c,Campaign_Cleanup_Date__c,Associated_Lead__r.CreatedDate,Associated_Lead__r.Latest_Campaign_AKAM_ID__c,Associated_Lead__r.Id,Account.Name,Associated_Lead__r.Product_Line__c,CampaignId,Campaign.Name,Associated_Lead__r.Associated_Contact__r.Id from Opportunity where (Associated_Lead__r.Latest_Campaign_AKAM_ID__c = \'\' OR CampaignId = \'\') and Associated_Lead__r.AKAM_Created_By__c = \'MAPI\' and ( NOT StageName like \'%Closed%\')';    
     }

    global Database.QueryLocator start(Database.BatchableContext BC){ 
         results= new DMLResults(); 
         results.storeObjectState();
         
         return Database.getQueryLocator(query); 
     }
     
         //Scope size is configured in metadata
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Opportunity> opptyList = (List<Opportunity>)scope;
        List<Opportunity> opptyUpdateList = new List<Opportunity>();
        List<CampaignMember> cmpMemberList = new List<CampaignMember>();
        List<Lead> leadList = new List<Lead>();

        System.Debug(LoggingLevel.Error, 'Scope in CampaignCleanup_LeadToOpptyBatchClass '+opptyList);

        
        Set<String> campaignAkamIds = new Set<String>();
        Map<String,Campaign> campaignAkamToId = new Map<String,Campaign>();
        Map<Id,Id> leadIdToCampaignId = new Map<Id,Id>();
        Map<Id,Id> leadToOpptyIdMap = new Map<id,Id>();
        Map<Id,Map<Id,DateTime>> leadIdToContactIdToDateMap = new Map<Id,Map<Id,DateTime>>();
        Map<Id,String> opptyIdToCampAkamIdMap = new Map<Id,String>();
        Set<Id> contactIdSet = new Set<Id>();
        Map<Id,Opportunity> idToRecordMap = new Map<Id,Opportunity>();
        
        for(Opportunity oppty : opptyList)
        {
            system.debug(LoggingLevel.Error,'List of Opportunities '+oppty.Associated_Lead__r.Latest_Campaign_AKAM_ID__c +' '+oppty.CampaignId);

            leadToOpptyIdMap.put(oppty.Associated_Lead__r.Id,oppty.Id);
            idToRecordMap.put(oppty.Id,oppty);
            //Getting either lead or opportunity or both do not have campaign associated

             if(oppty.Associated_Lead__r.Latest_Campaign_AKAM_ID__c != null && oppty.CampaignId == null)
                {
                    system.debug(LoggingLevel.Error,'First if');
                    campaignAkamIds.add(oppty.Associated_Lead__r.Latest_Campaign_AKAM_ID__c);
                    opptyUpdateList.add(oppty);
                    opptyIdToCampAkamIdMap.put(oppty.Id,oppty.Associated_Lead__r.Latest_Campaign_AKAM_ID__c);
                }
             else if(oppty.Associated_Lead__r.Latest_Campaign_AKAM_ID__c == null && oppty.CampaignId != null)
                {
                    system.debug(LoggingLevel.Error,'Else if ');
                    leadIdToCampaignId.put(oppty.Associated_Lead__r.Id,oppty.CampaignId);
                }
                
                else if(oppty.Associated_Lead__r.Latest_Campaign_AKAM_ID__c == null && oppty.CampaignId == null)
                {

                    Map<Id,DateTime> tempMap = new Map<Id,DateTime>();
                    tempMap.put(oppty.Associated_Lead__r.Associated_Contact__r.Id,oppty.Associated_Lead__r.CreatedDate);
                    //Map of lead to contact to leads created date
                    leadIdToContactIdToDateMap.put(oppty.Associated_Lead__r.Id ,tempMap);
                    contactIdSet.add(oppty.Associated_Lead__r.Associated_Contact__r.Id);

                    system.debug(LoggingLevel.Error,'Inside Oppty Lead Empty  Fix '+leadIdToContactIdToDateMap +' '+contactIdSet);

                }

        }
        
        
        //Map of contact id to all associated campaigns
        Map<Id,List<CampaignMember>> contactIdToCMListMap = new Map<Id,List<CampaignMember>>();

        if(!leadIdToContactIdToDateMap.isEmpty())
        {
            
            for(CampaignMember cpMem : [Select Id,CreatedDate,Name,CampaignId,ContactId,Campaign.AKAM_Campaign_ID__c From CampaignMember Where ContactId IN :contactIdSet])
            {
                system.debug(LoggingLevel.Error,'Inside Oppty Lead Empty  Fix '+cpMem);

                List<CampaignMember> tempListCm = new List<CampaignMember>();
                tempListCm.add(cpMem);
                if(!contactIdToCMListMap.isEmpty())
                {
                    if(contactIdToCMListMap.containsKey(cpMem.ContactId))
                    {
                        List<CampaignMember> tempListCAM = contactIdToCMListMap.get(cpMem.ContactId);
                        tempListCAM.add(cpMem);
                        contactIdToCMListMap.put(cpMem.ContactId,tempListCAM);
                    }
                    else
                    {
                        List<CampaignMember> tempListCAM = new List<CampaignMember>();
                        tempListCAM.add(cpMem);
                        contactIdToCMListMap.put(cpMem.ContactId,tempListCAM);                    }
                    }
                else
                {
                    List<CampaignMember> tempListCAM = new List<CampaignMember>();
                    tempListCAM.add(cpMem);
                    contactIdToCMListMap.put(cpMem.ContactId,tempListCAM);
                }
            }

        system.debug(LoggingLevel.Error,'Contact id to Campaign Member List Map '+contactIdToCMListMap);

        }



       // Map<Id,Id> leadIdToCampaignIdMap = new map<Id,Id>();
        for(Id leadId : leadIdToContactIdToDateMap.keySet())
        {
            system.debug(LoggingLevel.Error,'Each Lead Id '+leadId);
            for(Id contactId : leadIdToContactIdToDateMap.get(leadId).keySet())
            {
                DateTime leadCreatedDate = leadIdToContactIdToDateMap.get(leadId).get(contactId);
                system.debug(LoggingLevel.Error,'Each Contact  '+contactId +'Date '+leadCreatedDate);


                if(contactIdToCMListMap.containsKey(contactId))
                {
                    List<CampaignMember> campMemlist = contactIdToCMListMap.get(contactId);
                    system.debug(LoggingLevel.Error,' Campaign Member List for associated Contact  '+campMemlist);
                    Map<CampaignMember,Decimal> cmIdToHoursMap = new Map<CampaignMember,Decimal>();
                    Map<Id,CampaignMember> contactToCMId = new Map<Id,CampaignMember>();

                    for(CampaignMember cm : campMemlist)
                    {
                        system.debug(LoggingLevel.Error,'CM CreatedDate  '+cm.CreatedDate +'Get time  '+cm.CreatedDate.getTime() +'Lead Created Date Get Time '+leadCreatedDate.getTime());

                        //Get the differene between Campaign Members cretaed Date and Lead Created Date in milliseconds 
                        Decimal noOfHours = cm.CreatedDate.getTime() > leadCreatedDate.getTime() ? (cm.CreatedDate.getTime() -  leadCreatedDate.getTime()) :( leadCreatedDate.getTime() - cm.CreatedDate.getTime() );
                        //Convert MilliSeconds to Hours differnce with decimals 
                        noOfHours =  ((noOfHours/1000)/60)/60;  
                        system.debug(LoggingLevel.Error,'No of Hours  '+noOfHours);
                        
                        Decimal noOfHourConf = Integer.valueOf(GSMSettings.getValue('CampaignCleanup_Hours'));

                        if( noOfHours < noOfHourConf)
                        {
                            cmIdToHoursMap.put(cm,noOfHours);

                            if(contactToCMId.containsKey(contactId))
                                {
                                    Decimal hrs = cmIdToHoursMap.get(contactToCMId.get(contactId));
                                            system.debug(LoggingLevel.Error,'Hours comparision  '+hrs +'Map '+cmIdToHoursMap);

                                    if( hrs > noOfHours)
                                    {
                                        contactToCMId.put(contactId,cm);
                                    }
                                }
                            else 
                            {
                                contactToCMId.put(contactId,cm);
                            }

                             system.debug(LoggingLevel.Error,'Map '+contactToCMId);

                        }
                    }

                            /*leadIdToCampaignId.put(leadId,cm.CampaignId);
                            campaignAkamIds.add(cm.Campaign.AKAM_Campaign_ID__c);
                            Id opptyId = leadToOpptyIdMap.get(leadId);
                            opptyIdToCampAkamIdMap.put(opptyId,cm.Campaign.AKAM_Campaign_ID__c);
                            opptyUpdateList.add(idToRecordMap.get(opptyId));*/
                            
                                if(contactToCMId.containsKey(contactId))
                            
                                {
                                    leadIdToCampaignId.put(leadId,contactToCMId.get(contactId).CampaignId);
                                    campaignAkamIds.add(contactToCMId.get(contactId).Campaign.AKAM_Campaign_ID__c);
                                    Id opptyId = leadToOpptyIdMap.get(leadId);
                                    opptyIdToCampAkamIdMap.put(opptyId,contactToCMId.get(contactId).Campaign.AKAM_Campaign_ID__c);
                                    opptyUpdateList.add(idToRecordMap.get(opptyId));
                                }


                        }
                    }

                }

         

        if(!leadIdToCampaignId.isEmpty())
        {
             system.debug(LoggingLevel.Error,'Inside Lead Fix - Map  '+leadIdToCampaignId);

            for(Id leadId : leadIdToCampaignId.keySet())
            {
                CampaignMember cmpgnMember = new CampaignMember();
                cmpgnMember.LeadId = leadId;
                cmpgnMember.CampaignId = leadIdToCampaignId.get(leadId);
                cmpgnMember.Status = 'Member';
                cmpMemberList.add(cmpgnMember);
            }

            for(Lead ld : [Select Id,Campaign_Cleanup_Comment__c,Campaign_Cleanup_Date__c From Lead Where Id IN :leadIdToCampaignId.keySet() ])
                {
                    ld.Campaign_Cleanup_Comment__c = GsmUtilClass.getGSMSettingValue('LeadCleanupComment');
                    ld.Campaign_Cleanup_Date__c = Date.Today();
                    ld.Validation_Override__c = true;
                    leadList.add(ld);
                }


        }

        if(campaignAkamIds.size() > 0)
        {
            system.debug(LoggingLevel.Error,'Inside Oppty Fix List of Ids '+campaignAkamIds);

            for(Campaign cmpRec : [Select Id,AKAM_Campaign_ID__c,Name From Campaign Where AKAM_Campaign_ID__c IN :campaignAkamIds ])
            {
                campaignAkamToId.put(cmpRec.AKAM_Campaign_ID__c,cmpRec);
            }
            system.debug(LoggingLevel.Error,'Campaign Records '+campaignAkamToId);
            for(Opportunity opptyRec : opptyUpdateList)
            {
                system.debug(LoggingLevel.Error,'Campaign Records Oppty '+opptyIdToCampAkamIdMap +'Oppty Rec Id '+opptyRec.Id);

                opptyRec.CampaignId = campaignAkamToId.get(opptyIdToCampAkamIdMap.get(opptyRec.Id)).Id;
                //Formulate the Oppty Name 
                String oppName;
                String accName = opptyRec.Account.Name;
                String leadName = opptyRec.Associated_Lead__r.Product_Line__c;
                String campaignName  = campaignAkamToId.get(opptyIdToCampAkamIdMap.get(opptyRec.Id)).Name;
                Integer len;
                
                    oppName = accName+' - Auto-converted - '+campaignName+' - '+leadName;
                    system.debug(LoggingLevel.Error,'Campaign Records details '+campaignName +'opp Name '+oppName);

                    len = oppName.length();

                    if(len > 120 && campaignName.length() > (len-120)) //If the name is greater than 120 characters, truncate the Campaign Name accordingly
                    {
                        String campaignNameTrimmed= campaignName.substring(0,campaignName.length()-(len-120));
                        // What is the possibility of account name being equal to campaign name?
                        oppName = oppName.replace(campaignName, campaignNameTrimmed);

                    }
                    else if(len > 120 && accName.length() > (len-120))//Account Name is less than extra number of characters to be trimmed, then trim the account name
                    {
                        String accNameTrimmed= accName.substring(0,accName.length()-(len-120));
                        oppName = oppName.replace(accName,accNameTrimmed);
                    }
                

                if(oppName.length()>120)
                    oppName=oppName.substring(0,119);

                opptyRec.Name = oppName;
                opptyRec.Campaign_Cleanup_Comment__c = GsmUtilClass.getGSMSettingValue('OpportunityCleanupComment');
                opptyRec.Campaign_Cleanup_Date__c = Date.Today();
                opptyRec.Validation_Override__c = true;


            }
         }



        
        system.debug(LoggingLevel.Error,'Final Campaign Memebr List to be Inserted '+cmpMemberList);
        system.debug(LoggingLevel.Error,'Final Opportunity List to be Updated '+opptyUpdateList);
        system.debug(LoggingLevel.Error,'Final Lead List to be Updated '+leadList);


        if(opptyUpdateList.size() > 0)
            results.add(Database.update(opptyUpdateList,false),opptyUpdateList);
        
        if(cmpMemberList.size() > 0)
            results.add(Database.insert(cmpMemberList,false),cmpMemberList);

        if(leadList.size() > 0)
            results.add(Database.update(leadList,false),leadList);
    } 
 

    


global void finish(Database.BatchableContext BC)
    {
         results.withClassName('CampaignCleanup_LeadToOpptyBatchClass').insertRecordsInErrorLog();

    }



    
    
}