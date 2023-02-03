public class IR_CaseSearchController {
	@AuraEnabled
    public static List<Case> fetchCases(String pageSize, String pageNumber, String whereClause) {
        Integer psize = Integer.valueOf(pageSize);
        Integer pnumber = Integer.valueOf(pageNumber)-1;
        System.debug('>> whereClause: '+whereClause);
        String query = 'select Id, CaseNumber,Account.Name,IR_Parent_Account_Name__c,IR_Original_Contract_Id__r.Name,';
        query += ' IR_Reporting_Region__c,IR_Invoice_Number__c,IR_Manual_Contract__c,IR_Invoice_Date__c,Description,Owner.Name,Status from Case';
        query += ' where id!=null and (RecordType.Name=\'Invoice Review Read Only\' or RecordType.Name=\'Invoice Review Case\') ';
        if (whereClause != '')
            query += whereClause;
        query += ' order by IR_Invoice_Date__c DESC NULLS LAST LIMIT ' + Integer.valueOf(psize) + ' OFFSET ' + (psize*pnumber);

        System.debug('>> query : '+query);
        List<Case> caseList = Database.query(query);
        System.debug('>> result : '+caseList);
        return caseList; 
    }

	@AuraEnabled
    public static List<String> getPicklistValues(String objectApiName,String fieldApiName){
        List<String> lstPickvals=new List<String>();
        lstPickvals.add('');
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);//From the Object Api name retrieving the SObject
        Sobject objectName = targetType.newSObject();
        Schema.sObjectType sobjectType = objectName.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> fieldMap = sobjectDescribe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> picklistValues = fieldMap.get(fieldApiName).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : picklistValues) { //for all values in the picklist list
        	lstPickvals.add(a.getValue());//add the value  to our final list
        }
        return lstPickvals;
	}
}