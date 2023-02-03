global class PartnerMarketingActivityBatchClass extends GenericBatchClass
{
    //global DMLResults results;

    global PartnerMarketingActivityBatchClass() {

        super();

		operationType = 'Update';
		className = 'PartnerMarketingActivityBatchClass';
        //errorAddressCustomSetting = 'LastNAPLoginBatchClass#EmailId';
        query = 'select Partner__c,Reach_Performance__c,Id,Validation_Override__c,Activity_Spend__c,Leads_Performance__c,Closed_Deals_Performance__c,Monthly_Bookings_Performance__c'+
                ',Deal_Registrations_Performance__c from Partner_Marketing_Activity__c '+
                'where isDeleted=false and (Activity_Status__c=\'Approved\'  or Activity_Status__c=\'In Progress\' or Activity_Status__c=\'Excluded\')';
    }
    
    global override void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Partner_Marketing_Activity__c> pmaList= (List<Partner_Marketing_Activity__c>)scope;
        Set<Id> partnerAccountIds = new Set<Id>();
        List<Id> pmaIds = new List<Id>();

        for(Partner_Marketing_Activity__c pma : pmaList)
        {
            partnerAccountIds.add(pma.Partner__c);
            pmaIds.add(pma.id);
        }
        /*
           -	Activity Spend: Sum of Approved Amount of PMA.Fund Request.Fund Claim
           -	Performance Leads: Do we need to count only the Converted Leads or All?
           -	Performance Deal Registration: Do we need to count only the Open or Approved Deal Reg or All?
           -	Performance Closed Deals: We should count the number of opportunities with the Partner Involved = PMA.Partner Account. 

         */
        Map<Id, Integer> pmaToActivitySpend = new Map<Id, Integer>();
        Map<Id, Integer> pmaToLeadCount= new Map<Id, Integer>();
        //Map<Id, Integer> pmaToAllOpptys = new Map<Id, Integer>();   
        Map<Id, Integer> pmaToClosedOpptys= new Map<Id, Integer>();
        Map<Id, Decimal> pmaToClosedOpptysMRRSum = new Map<Id, Decimal>();

        for(AggregateResult fc: [select Fund_Request__r.Partner_Marketing_Activity__c pma
                                        ,sum(Approved_Amount__c) approvedSum 
                                        from SFDC_MDF_Claim__c 
                                        where Fund_Request__r.Partner_Marketing_Activity__c in :pmaList 
                                        group by Fund_Request__r.Partner_Marketing_Activity__c])
        {
            pmaToActivitySpend.put((Id)fc.get('pma'), Integer.valueOf(fc.get('approvedSum')));
        }

        for(AggregateResult l :[select count(id) numberOfLeads
                                       ,Primary_Campaign__r.Partner_Marketing_Activity__c pma 
                                       from lead 
                                       where Primary_Campaign__c in 
                                       (select id from campaign where Partner_Marketing_Activity__c in :pmaList) 
                                       group by Primary_Campaign__r.Partner_Marketing_Activity__c])
        {
            pmaToLeadCount.put((Id)l.get('pma'), Integer.valueOf(l.get('numberOfLeads')));
        }

        for(AggregateResult agg: [select Partner_Marketing_Activity__c
                                         ,count(id) numberOfOpptys
                                         ,SUM(Dollar_MRR__c) totalMRR
                                         ,IsClosed 
                                         ,IsWon
                                         from opportunity 
                                         where Partner_Marketing_Activity__c in :pmaIds 
                                         group by isclosed,IsWon,Partner_Marketing_Activity__c])
        {
            //Id partnerAccountId =(Id)agg.get('Partner_Involved__c');
            Id pmaId = (Id)agg.get('Partner_Marketing_Activity__c');
            //Integer oldAllOpptyCount = pmaToAllOpptys.containsKey(pmaId) ? pmaToAllOpptys.get(pmaId) : 0;
            Integer oldClosedOpptyCount = pmaToClosedOpptys.containsKey(pmaId) ? pmaToClosedOpptys.get(pmaId) : 0;
            Decimal oldTotalSumOfMRR = pmaToClosedOpptysMRRSum.containsKey(pmaId) ? pmaToClosedOpptysMRRSum.get(pmaId) : 0.00;

            if((Boolean)agg.get('IsClosed') && (Boolean)agg.get('IsWon'))
            {
                pmaToClosedOpptys.put(pmaId, oldClosedOpptyCount + Integer.valueOf(agg.get('numberOfOpptys')));
                pmaToClosedOpptysMRRSum.put(pmaId, oldTotalSumOfMRR + (Decimal)agg.get('totalMRR'));
            }
            //pmaToAllOpptys.put(pmaId, oldAllOpptyCount + Integer.valueOf(agg.get('numberOfOpptys')));
        }

        Map<Id,Set<Id>> pmaToOpptyMap = new Map<Id,Set<Id>>();
        for (Opportunity opp: [Select id,Registration_Status__c,Partner_Marketing_Activity__c From Opportunity 
                                where Partner_Marketing_Activity__c in :pmaIds
                                and Registration_Status__c = 'Approved']) {
            Set<Id> dealIds;

            if (pmaToOpptyMap.containsKey(opp.Partner_Marketing_Activity__c)) {
                dealIds = pmaToOpptyMap.get(opp.Partner_Marketing_Activity__c);
            } else {
                dealIds = new Set<Id>();
            }
            dealIds.add(opp.id);
            pmaToOpptyMap.put(opp.Partner_Marketing_Activity__c,dealIds);
        }

        for(Integer i=pmaList.size()-1;i>=0;i--)
        {
            Partner_Marketing_Activity__c pma =pmaList[i];
            if(pmaToActivitySpend.containsKey(pma.id) && pma.Activity_Spend__c != pmaToActivitySpend.get(pma.id))
            {
                pma.Validation_Override__c=true;
                pma.Activity_Spend__c=pmaToActivitySpend.get(pma.Id);
            }

            if(pmaToOpptyMap.containsKey(pma.id) && pma.Deal_Registrations_Performance__c != pmaToOpptyMap.get(pma.id).size())
            {
                pma.Validation_Override__c=true;
                pma.Deal_Registrations_Performance__c = pmaToOpptyMap.get(pma.id).size();
            }

            if(pmaToClosedOpptys.containsKey(pma.Id) && pma.Closed_Deals_Performance__c != pmaToClosedOpptys.get(pma.Id))
            {
                pma.Validation_Override__c=true;
                pma.Closed_Deals_Performance__c = pmaToClosedOpptys.get(pma.Id);
            }

            if(pmaToClosedOpptysMRRSum.containsKey(pma.Id) && pma.Monthly_Bookings_Performance__c != pmaToClosedOpptysMRRSum.get(pma.Id))
            {
                pma.Validation_Override__c=true;
                pma.Monthly_Bookings_Performance__c = pmaToClosedOpptysMRRSum.get(pma.Id);
            }

            if(pmaToLeadCount.containsKey(pma.Id) && pma.Leads_Performance__c != pmaToLeadCount.get(pma.Id))
            {
                pma.Validation_Override__c=true;
                pma.Leads_Performance__c=pmaToLeadCount.get(pma.Id);
            }

            if(!pma.Validation_Override__c)
                pmaList.remove(i);

        }
        
        if(pmaList.size()>0)
                super.execute(BC, pmaList);

    }

    global override void finish(Database.BatchableContext BC)
    {
        super.finish(BC);
    }
 }