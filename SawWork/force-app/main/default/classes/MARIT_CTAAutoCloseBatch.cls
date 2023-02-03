/* History:
 * =========================
 * @author  Himanshu Verma,  20th October 2020 
 */
global class MARIT_CTAAutoCloseBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Datetime lastDateToFetchC2A;
    global integer lastC2aTobeConsideredDate;
    global List<String> leadStatusToBeConsidered;
    global Id akamaiLeadRecordTypeId;
    //global DMLResults results;
    global string query;
    global String successStr;
    global String errStr;
    
    global MARIT_CTAAutoCloseBatch() 
	{
        Integer batchSize = MarketingUtilClass.getInt('CTAAutoCloseBatchSize');
        akamaiLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        lastC2aTobeConsideredDate = integer.valueof(MarketingUtilClass.getMarketingSettingsValue('CTADateLimitForAutoClose'));
        lastDateToFetchC2A = DateTime.Now().AddDays(lastC2aTobeConsideredDate);
        leadStatusToBeConsidered = MarketingUtilClass.getMarketingSettingsValue('CTAStatusForAutoClose').split(',');
        query = 'SELECT Id, Status, FirstName, LastName, Email, Lead_Qualification_Status__c FROM Lead '; 
        if (!Test.isRunningTest()) {
            query+='WHERE RecordTypeId =:akamaiLeadRecordTypeId and (Parent_Lead__c != null OR Associated_Contact__c != null) and Status in :leadStatusToBeConsidered and LastModifiedDate < :lastDateToFetchC2A';
            query+=' Order by LastModifiedDate asc limit '+ batchSize;
        } else {
            query+='WHERE RecordTypeId =:akamaiLeadRecordTypeId limit 1';
        }
        
        System.debug('query Auto close : ' + query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> leadList) {
       
        List<Lead> CTAUpdatedList =  new List<Lead>();
        System.debug('Lead Count : ' + leadList.size());
        // leadList consists of all CTAs which have LastModifiedDate older than 21 days (3 weeks) of job run
		for (Lead eachLead : leadList) {
            System.debug('Each lead : ' + eachLead);
            eachLead.Lead_Qualification_Status__c = 'Turnback Auto Close for Nurture';
            CTAUpdatedList.add(eachLead);
        }
        
        if (!CTAUpdatedList.isEmpty()) {
            List<Lead> c2aLeadList = new List<Lead>();
            c2aLeadList.addAll(CTAUpdatedList);
            Database.SaveResult[] srList = Database.update(c2aLeadList, false);
            
            //update c2aLeadList;
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted Lead ID: ' + sr.getId());
                    successStr +=  sr.getId();
                }
                else {
                    // Operation failed, so get all errors  
                    errStr += sr.getId();
                    for(Database.Error err : sr.getErrors()) {
                       
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Lead fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}