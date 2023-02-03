public without sharing class LeadConversionFacade
{
    public Map<Id, DecoratedLead> leadIdToDecoratedLead;

    public LeadConversionFacade(Lead ucLead)
    {
        this(new List<Lead>{ucLead});
    }


    public LeadConversionFacade(List<Lead> ucLeads)
    {
        leadIdToDecoratedLead = new Map<Id, DecoratedLead>();
        List<String> keyValues = new List<String>();
        List<String> subTerritories = new List<String>();

        for (Lead ithLead : ucLeads) {
            keyValues.add(ithLead.Product_Line__c);
            subTerritories.add(ithLead.Associated_Account__r.Anaplan_Sub_Territory__c);
        }

        SubTerritoryHelper StHelper = new SubTerritoryHelper(keyValues,subTerritories);
        Map<String,Id> anaplanSTtoSpecialsitUser = StHelper.getAnaplanSTtoSpecialsitUser();
        Map<String,Id> userTypeToSpecialsitUser = StHelper.getUserTypeToSpecialsitUser();
        Map<String,String> keyValueToUserType = StHelper.getKeyValueToUserType();
        Map<Id,Id> userIdTospecialistCompTeam = StHelper.getUserIdTospecialistCompTeam();
        Map<Id,String> userIdToEmail = StHelper.getUserIdToEmail();
        Map<String,String> keyValueToOpptyFieldName = StHelper.getKeyValueToOpptyFieldName();
        
        for (Lead ithLead : ucLeads) {
            DecoratedLead decLead = new DecoratedLead(ithLead);
            if (anaplanSTtoSpecialsitUser.containsKey(ithLead.Associated_Account__r.Anaplan_Sub_Territory__c) && (keyValueToUserType.containsKey(ithLead.Product_Line__c)) && (userTypeToSpecialsitUser.containsKey(keyValueToUserType.get(ithLead.Product_Line__c)))) {
                Id userId = userTypeToSpecialsitUser.get(keyValueToUserType.get(ithLead.Product_Line__c));
                decLead.setOppLeader(userId);
                decLead.setEnterpriseSalesRep(userIdTospecialistCompTeam.get(userId));
                decLead.setEnterpriseSalesRepEmail(userIdToEmail.get(userId));
                if (keyValueToOpptyFieldName.containsKey(ithLead.Product_Line__c)) {
                    decLead.setOpportunityFieldForSpecialist(keyValueToOpptyFieldName.get(ithLead.Product_Line__c));
                }
            }
            leadIdToDecoratedLead.put(ithLead.Id, decLead);
        }
    }



    private List<Opportunity> refreshOpptys(List<Opportunity> opps)
    {
        return [select id, AKAM_Opportunity_ID__c, Associated_Lead__c from Opportunity where Id in :opps];
    }

    public LeadConversionResult convert(Boolean isManual)
    {
        DMLResults res = new DMLResults();
        LeadConversionResult lcr = new LeadConversionResult();

        res.includeSuccess();

        List<Opportunity> opptys = new List<Opportunity>();

        for(DecoratedLead ithLead : leadIdToDecoratedLead.values())
        {
            opptys.add(ithLead.buildConvertedOpportunity(isManual));
        }


        System.DEbug(LoggingLevel.Error, 'AGH_D performing insert now'+opptys);
        res.dmlInsert(opptys);

        Integer ct =0;
        for(DmlResults.Result r : res.results)
        {
            lcr.addResult(r, opptys[ct].Associated_Lead__c, 'Insert', 'Opportunity');
            ct++;
        }

        // all failed
        if(res.dmlsAttempted==res.failureCount)
            return lcr;

        System.DEbug(LoggingLevel.Error, 'AGH_D performed insert '+res);

        res.clear();
        // this is to get the akam ids of the inserted opptys
        opptys = refreshOpptys(opptys);

        for(Opportunity opp : opptys)
        {
            leadIdToDecoratedLead.get(opp.Associated_Lead__c).updateConvertedOpportunityInfo(opp);
        }

        List<Lead> leadsToBeUpdated = new List<Lead>();
        //SFDC-4547
        Set<Id> uniqueContactIds = new Set<Id>();
        List<Contact> contactUpdateList = new List<Contact>();
        List<OpportunityContactRole> listOfOCR = new List<OpportunityContactRole>();
        List<Messaging.SingleEmailMessage> mailingList = new List<Messaging.SingleEmailMessage>();


        for(DecoratedLead ithLead : leadIdToDecoratedLead.values())
        {
            System.DEbug(LoggingLevel.Error, 'AGH_D entering lead loop'+ithLead);
            if(ithLead.conversionSucceeded)
            {
                leadsToBeUpdated.add(ithLead.getConvertedLead());
                //SFDC-4547
                Contact ithCon = ithLead.getContactWithPopulatedAssociatedOppty();
                if(ithCon!=null && !uniqueContactIds.contains(ithCon.Id))
                {
                    uniqueContactIds.add(ithCon.Id);
                    contactUpdateList.add(ithCon);
                }

                listOfOCR.add(ithLead.generateOpportunityContactRole());
                ithLead.generateOpptyLeaderMailingList(mailingList);
            }

        }

        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mailingList);

        System.DEbug(LoggingLevel.Error, 'AGH_D performing update of lead '+leadsToBeUpdated);

        if(leadsToBeUpdated.size()>0)
        {
            res.dmlUpdate(leadsToBeUpdated);
            ct =0;
            for(DmlResults.Result r : res.results)
            {
                lcr.addResult(r, leadsToBeUpdated[ct].Id, 'Update', 'Lead');
                ct++;
            }
            res.clear();
            res.dmlInsert(listOfOCR);
            ct =0;
            for(DmlResults.Result r : res.results)
            {
                lcr.addResult(r, leadsToBeUpdated[ct].Id, 'Insert', 'OpportunityContactRole');
                ct++;
            }
            if(contactUpdateList.size()>0)
            {
                res.clear();
                res.dmlUpdate(contactUpdateList);
                ct =0;
                for(DmlResults.Result r : res.results)
                {
                    lcr.addResult(r, contactUpdateList[ct].Id, 'Update', 'Contact');
                    ct++;
                }
            }

        }

        return lcr;
    }
    //MARIT-543
    public LeadConversionResult convertAsyncLead(Boolean isManual)
    {
        System.debug('In convertAsyncLead Class');
        DMLResults res = new DMLResults();
        LeadConversionResult lcr = new LeadConversionResult();

        res.includeSuccess();

        List<Opportunity> opptys = new List<Opportunity>();

        for(DecoratedLead ithLead : leadIdToDecoratedLead.values())
        {
            opptys.add(ithLead.buildOpportunityForAsyncLead(isManual));  //build all the Oppt fields required
        }


        System.DEbug(LoggingLevel.Error, 'AGH_D performing insert now'+opptys);
        res.dmlInsert(opptys); //insert Oppt

        Integer ct =0;
        for(DmlResults.Result r : res.results)
        {
            lcr.addResult(r, opptys[ct].Associated_Lead__c, 'Insert', 'Opportunity');
            ct++;
        }

        // all failed
        if(res.dmlsAttempted==res.failureCount)
            return lcr;

        System.DEbug(LoggingLevel.Error, 'AGH_D performed insert '+res);

        res.clear();
        opptys = refreshOpptys(opptys); //get the associated akam ids of the inserted oppt

        for(Opportunity opp : opptys)
        {
            leadIdToDecoratedLead.get(opp.Associated_Lead__c).updateConvertedOpportunityInfo(opp);
        }

        List<Lead> leadsToBeUpdated = new List<Lead>();
        List<Messaging.SingleEmailMessage> mailingList = new List<Messaging.SingleEmailMessage>();


        for(DecoratedLead ithLead : leadIdToDecoratedLead.values())
        {
            System.DEbug(LoggingLevel.Error, 'AGH_D entering lead loop'+ithLead);
            if(ithLead.conversionSucceeded)
            {
                leadsToBeUpdated.add(ithLead.getConvertedLead());  //convert akamai lead and update Oppt fields
                ithLead.generateOpptyLeaderMailingList(mailingList);
            }

        }


        System.Debug(LoggingLevel.Error, 'AGH_D performing update of lead '+leadsToBeUpdated);

        if(leadsToBeUpdated.size()>0)
        {
            res.dmlUpdate(leadsToBeUpdated);
            ct =0;
            for(DmlResults.Result r : res.results)
            {
                lcr.addResult(r, leadsToBeUpdated[ct].Id, 'Update', 'Lead');
                ct++;
            }
        }

        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mailingList);

        return lcr;
    }
}