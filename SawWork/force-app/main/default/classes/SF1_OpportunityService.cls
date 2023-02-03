/**
@author: Shubham Richhariya
MOB-71 : Created Opportunity Service class : This class would contain queries related to opportunity object across salesforce1 functionality.

* History:
* =========================
* Developer        Date        Description

Shubham    27/March/17       Added this class for MOB-71.
Shubham    05/April/17       updated getExistingOpportunityList to introduce pagination in SF1 app
Shubham    29/May/17         updated the soql query creation in getExistingOpportunityList
**/

global without sharing class SF1_OpportunityService
{
    public static Opportunity getOpportunity(Id opptyId)
    {
        //SFDC-5573
        Opportunity currentOppty = [select Id,AccountId,Account.Name,
                                    Partner_Involved__r.No_Rebate_Required__c,
                                    ForecastCategoryName,
                                    Deal_Reg_Opportunity_Discount__c,
                                    Deal_Reg_Account_Discount__c,
                                    Customer_Company_Name__c,
                                    End_Customer_Website__c,
                                    End_Customer_Country__c,
                                    End_Customer_Zip_Code__c,
                                    End_Customer_Street_Address__c,
                                    End_Customer_State__c,
                                    End_Customer_City__c,
                                    Validation_Override__c,
                                    Deal_Reg_Account_Status__c,
                                    Rebate__c,
                                    Deal_Reg_Opportunity_Status__c,
                                    Discount_Percentage__c,
                                    Discount_Status__c,
                                    recordtype.DeveloperName,
                                    recordtype.name,Name,CurrencyIsoCode,CloseDate,MRR__c,stageName,
                                    Consolidation_Account__c,Opportunity_Category__c,
                                    Opportunity_Sub_Category__c,
                                    Loss_Cancellation_Description__c,
                                    Loss_Reason__c,Competitor__c, Strategic_MRR__c,
                                    Carrier_Application__c,Unacceptable_Terms_and_Conditions__c,
                                    Initial_Out_Clause_Description__c,
                                    Aggregation_Partner__c,Consolidation_Account__r.Name,Missing_Product_Feature__c,
                                    Opportunity_Revenue_Impact__c,Churn_No_Paper__c,EMRI_Utilization__c,EMRI_Comments__c,
                                    (select id,Product_Name__c,Average_Renewal_Commit_MRR__c,Projected_Monthly_commit_fees__c,
                                     NRR__c,unitprice,Average_Renewal_Usage_MRR__c,Projected_Avg_Rev_Non_Commit__c,
                                     Net_Non_Commit__c,EMRI__c,Opportunity.CurrencyISOCode from opportunitylineitems
                                     ORDER BY CreatedDate ASC)
                                    from Opportunity
                                    where Id=:opptyId];
        return currentOppty;
    }


    public static List<Opportunity> getExistingOpportunityList(Opportunity currentOppty,Integer pagesize , Integer offset,String orderBy)
    {
        Integer ps = Integer.valueof(pagesize);
        Integer off = Integer.valueof(offset);
        System.debug('orderBy :'+orderBy);
        List<Opportunity> opps = new List<Opportunity>();
        //test classes need to be updated

        al.SoqlBuilder soql = new al.SoqlBuilder()
            .selectx(new Set<Object>{'Id', 'Owner__r.Name', 'Owner__r.Id','MRR__c','AKAM_Created_Date__c',
                'CurrencyIsoCode','StageName', 'Name', 'Existing_Opportunity__c',
                'Validation_Override__c', 'Account.Name','End_Customer_Website__c',
                'Services_Hostname__c', 'Deal_Age__c', 'Partner_Involved__c',
                'Partner_Involved__r.Name', 'Dollar_MRR__c', 'Partner_Involved__r.Id',
                'Deal_Reg_Account_Discount__c','Deal_Reg_Opportunity_Discount__c'})
            .fromx('Opportunity');

        al.NestableCondition  andCond = new al.AndCondition();
        andCond.add(new al.FieldCondition('AccountId').equals(currentOppty.AccountId));
        andCond.add(new al.FieldCondition('Id').notEquals(currentOppty.Id));

        String query = soql.wherex(andCond).toSoql(new al.SoqlOptions().escapeSingleQuotes());

        //SFDC-6799
        query += ' AND (NOT StageName LIKE \'%Closed%\') AND (NOT StageName LIKE \'%Signed%\') ';

        if(orderBy!=null && orderBy!=''){
            query = query + ' ' +'order by '+ String.escapeSingleQuotes(orderBy);
        }
        else{
            query = query + ' ' +'order by Deal_Age__c';
        }
        query = query + ' ' + 'LIMIT ' +ps;
        query = query + ' ' + 'OFFSET ' +off;
        System.debug('query1 : '+query.substring(0, query.length()/2));
        System.debug('query2 : '+query.substring(query.length()/2, query.length()));

        for(Opportunity o : Database.query(query))
        {   //Remove this code?
            if(!o.StageName.contains('Closed') && !o.StageName.contains('Signed')){
                opps.add(o);
            }
        }

        return opps;
    }

    public static OpportunityLineItem getOpportunityLineItem(Id opptyLineItemId) {
        OpportunityLineItem oppLineObj = [select id,Product_Name__c,Average_Renewal_Commit_MRR__c,
                                          Projected_Monthly_commit_fees__c, Term__c,
                                          NRR__c,unitprice,Average_Renewal_Usage_MRR__c,Projected_Avg_Rev_Non_Commit__c,
                                          Net_Non_Commit__c,EMRI__c,Opportunity.CurrencyISOCode, Specialist_Projected_Monthly_Commit__c, Specialist_Touched__c,
                                          Specialist_Projected_Monthly_Usage__c, Specialist_Usage_Touched__c, Specialist_Forecast_Touched__c, Specialist_Forecast_Category__c,Specialist_Close_Date__c,Specialist_Close_Date_Touched__c from opportunitylineitem
                                          where Id = :opptyLineItemId];
        return oppLineObj;
    }

    /*MOB - 204  :Task App*/
    public static List<Opportunity> getOpportunitiesForCurrentOwner(Id ownerId)
        {
            List<Opportunity> opps = [SELECT Id, AccountId,Account.name, Name,Owner__r.Name,CurrencyIsoCode,Dollar_MRR__c, StageName, Description, OwnerId,(select id FROM Order_Approvals__r)
                                      FROM Opportunity where
                                      id in (select Associated_Opportunity__c FROM Order_Approval__c) AND
                                      OwnerId =  :ownerId AND
                                      StageName NOT IN('Closed Won', 'Closed Lost', 'Closed Duplicate', 'Closed Contract Ended', 'Closed - Unqualified AQL')
                                      order by createddate desc];
            return opps;
        }

    public static Order_Approval__c getOAForCurrentOpportunity(Id opptyId)
    {
        Order_Approval__c oa = [SELECT Id, Name, Associated_Opportunity__r.Name, Associated_Account__c,
                                Associated_Opportunity_Sales_Stage__c, Opportunity_Owner__c,
                                AKAM_OrderApproval_ID__c, Rebate__c, Discount__c, Discount_Status__c, Small_Deal__c
                                FROM Order_Approval__c where Associated_Opportunity__c  = :opptyId][0];
        return oa;
    }
}