/* 
/*********************************************************************************************************************
 * JIRA             : ESESP-5250
 * Author           : Sujay Surendranath
 * Created Date     : 03-23-2022
 * Purpose          : To Hanle Delivery Team Membership Aggregate on percentage Assigned of resource utilization
 
 
/************************************************************************************************************************
*/ 


public without sharing class PS_DTMTriggerClass {
    
    
    public static void beforeInsertUpdate(Boolean isInsert, Delivery_Team_Membership__c[] oldPODs, Delivery_Team_Membership__c[] newPODs, Map<Id, Delivery_Team_Membership__c> oldMap, Map<Id, Delivery_Team_Membership__c> newMap)
    {
        
        Map<String, Decimal> resourceToNewPercentage    = new Map<String, Decimal>();
        Map<String, Decimal> resourceToAggPercentage    = new Map<String, Decimal>();
        List<AggregateResult> resourceAggregate         = new List<AggregateResult>();
        Set<Id> lstDTM                                  = new Set<Id>();
        
        
        for(Delivery_Team_Membership__c eDTM : newPODs)
        {   
            if(!isInsert)
            {
                lstDTM.add(eDTM.Id);
            } 
            if(eDTM.Resource__c  != NULL && eDTM.From_Date__c != NULL && eDTM.To_Date__c != NUll)
            {
                if(!resourceToNewPercentage.containsKey(eDTM.Key__c))
                {
                   resourceToNewPercentage.put(eDTM.Key__c, eDTM.Assigned__c); 
                }
                else
                {
                    Decimal existingPercent = resourceToNewPercentage.get(eDTM.Key__c);
                    resourceToNewPercentage.put(eDTM.Key__c, existingPercent + eDTM.Assigned__c );
                }
            }
            
        }
        
        System.debug('resourceToNewPercentage :: ' + resourceToNewPercentage);
        
        for( AggregateResult eAggr : [SELECT Key__c, sum(Assigned__c ) assinedVolume FROM Delivery_Team_Membership__c WHERE Key__c In :resourceToNewPercentage.keySet() AND Delivery_Team__r.POD_Association__r.Active__c = true AND  Id NOT in: lstDTM Group by Key__c])
        {
            string key      = (string) eAggr.get('Key__c');
            Decimal value   = (Decimal) eAggr.get('assinedVolume');
            
            System.debug('eAggr :: ' + eAggr);
            System.debug('key :: '   + key);
            System.debug('value :: ' + value);
            
            if(!resourceToAggPercentage.containsKey( key ) )
            {
                resourceToAggPercentage.put(key, value);
            }
        } 
            
        System.debug('resourceToAggPercentage :: ' + resourceToAggPercentage);
        
        for(Delivery_Team_Membership__c eDTM : newPODs)
        {
            Decimal AggPercnt = resourceToAggPercentage.get(eDTM.key__c) != null ? resourceToAggPercentage.get(eDTM.key__c) : 0.0;
            Decimal NewPercnt = resourceToNewPercentage.get(eDTM.key__c) != null ? resourceToNewPercentage.get(eDTM.key__c) : 0.0;
            Decimal Sum = AggPercnt + NewPercnt ;
            
            System.debug('AggPercnt :: '+ AggPercnt);
            System.debug('NewPercnt :: '+ NewPercnt);
            
            if(Sum > 100.00)
            {
                eDTM.addError('Alert, the % Assigned for this user exceeds 100%. Please check their membership records. ' + sum );
            }
            
        }  
    }
}