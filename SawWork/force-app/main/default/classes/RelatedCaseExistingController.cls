public without sharing class RelatedCaseExistingController {
    
    @AuraEnabled
    public static ParentData getOnLoadCaseNumber(String caseId){
        String caseIdWithAKAMId;
        if(caseId != null){
            Case cs = [Select Id, CaseNumber, Akam_Case_Id__c from Case where Id = :caseId LIMIT 1];
            if(cs != null){
                ParentData ps = new ParentData(null,null);
                if(cs.CaseNumber != null){
                	ps.caseNumber = cs.CaseNumber;
            	}
                if(cs.Akam_Case_Id__c != null){
                	ps.akamId = cs.Akam_Case_Id__c;
            	}
                return ps;
            }
        }
        return null;
    }
    
    @AuraEnabled
    public static List<SearchWrapper> getCaseRecords(String idsToSearchStr, String caseId){
        
        system.debug('strIds ='+idsToSearchStr);
        /*List<String> idsToSearch = strIds != null?strIds.split(';|\\,|\\ |\\\n|\\\r\n'):new List<String>();
        System.debug('idsToSearch :: '+idsToSearch);*/
        List<SearchWrapper> searchWrapRecs = new List<SearchWrapper>();
        String parentOfCaseId ;
        String caseNumberOfParent;
        String akamIdOfParent;
        List<String> idsToSearch;
        if(idsToSearchStr != null){
        	idsToSearch = (List<String>)JSON.deserialize(idsToSearchStr, List<String>.class);
        }
        system.debug('idsToSearch ='+idsToSearch);
        if(idsToSearch != null && !idsToSearch.isEmpty()){
            List<Case> csLst = new List<Case>([SELECT Id,Account.Name, CaseNumber, Subject, Akam_Case_Id__c, Akam_Created_Date__c, ParentId, Status, AccountId, RecordTypeId, RecordType.Name, Parent.CaseNumber,Owner.Name 
                           FROM Case 
                           WHERE 
                           CaseNumber IN :idsToSearch
                           OR
                           Akam_Case_Id__c IN :idsToSearch
                           OR
                           Id = :caseId
                          ]);
            //added below extra for loop to get the Parent of the current case without extra soql
            for(Case cs : csLst){
                if(cs.Id == caseId){
                    parentOfCaseId = cs.ParentId;
                    caseNumberOfParent = cs.CaseNumber;
                    akamIdOfParent = cs.Akam_Case_Id__c;
                }
            }
            for(Case cs : csLst){
                if(cs.Id != caseId || (cs.Id == caseId && (idsToSearch.contains(caseNumberOfParent) || idsToSearch.contains(akamIdOfParent)))){
                	searchWrapRecs.add(new SearchWrapper(cs,caseId,parentOfCaseId));
                }
            }
        }
        System.debug('searchWrapRecs ::'+searchWrapRecs);
        return searchWrapRecs;
    }
    
    /** Method to update the selected child case with parent ID **/
    @AuraEnabled
    public static ErrorMessageWrapper updateParentCase(String csLst, String parentCaseId){
        List<Case> lCaseToUpdate = new List<Case>();
        String casesWithCircularDependancy = '';
        String successMsg ='';
        ErrorMessageWrapper returnVal = new ErrorMessageWrapper(null,null);
        integer i = 0;
        
        System.debug('csLst ::'+csLst+' &&&&&&& parentCaseId ::'+parentCaseId);
        system.debug((List<Case>)JSON.deserialize(csLst, List<Case>.class));
        if(csLst != null){
        	List<Case> selectedCases = (List<Case>)JSON.deserialize(csLst, List<Case>.class);
            for(Case cs : selectedCases){
                cs.ParentId = parentCaseId;
                lCaseToUpdate.add(cs);
            }
            System.debug('lCaseToUpdate ::'+lCaseToUpdate);
            
            if(!lCaseToUpdate.isEmpty()){
            	Database.SaveResult[] lException = Database.update(lCaseToUpdate, false);
                System.debug('lException :: '+lException);
                String errorMsg = '';
                for (Database.SaveResult sr : lException) {
                    if (!sr.isSuccess()) {
                        for(Database.Error errorMessage : sr.getErrors()){
                        	casesWithCircularDependancy += lCaseToUpdate[i].Akam_Case_Id__c + ',';
                            errorMsg += lCaseToUpdate[i].Akam_Case_Id__c + ':'+errorMessage.getMessage()+';';
                        }
                    }
                    else{
                        successMsg += lCaseToUpdate[i].Akam_Case_Id__c + ',';
                    }
                    i++;
                }
                
                if(casesWithCircularDependancy != ''){
                    casesWithCircularDependancy = casesWithCircularDependancy.substringBeforeLast(',');
                    returnVal.errorMsg = errorMsg;
            	}
                if(successMsg != ''){
                    successMsg = successMsg.substringBeforeLast(',');
                    returnVal.successMsg = 'Following records were updated successfully '+successMsg;
            	}
            }//End of if(!lCaseToUpdate.isEmpty()){
        }//End of if(csLst != null){
        return returnVal;
    }
    
    @AuraEnabled
    public static string createTitleForColumn(Case objCase, String caseId, String parentId){
        System.debug('### ' + objCase.Id + ' ' + parentId + ' ' + caseId);
        if(objCase.Id == parentId || objCase.Id == caseId){
            return 'This case is parented by a case that is also its child';
        }
        
        if(objCase.ParentId != null){
            return 'This case already has a parent';
        }
        
        if(objCase.Status.containsIgnoreCase('close')){
            return 'This case is already closed';
        }
        else{
            return 'Please select this Case to update';
        }
    }
    
    //Wrapper Class
    public class SearchWrapper{
        @AuraEnabled
        public Case caseToDisplayWrapper{get;set;}
        @AuraEnabled
        public string title{get;set;}
        
        public SearchWrapper(Case cs, String caseId, String parentId){
            caseToDisplayWrapper = cs;
            title = createTitleForColumn(cs,caseId,parentId);
        }
    }
    
    public class ErrorMessageWrapper{
        @AuraEnabled
        public String errorMsg{get;set;}
        
        @AuraEnabled
        public String successMsg{get;set;}
        
        public ErrorMessageWrapper(String msg, String smsg){
            errorMsg = msg;
            successMsg = smsg;
        }
    }
    
    public class ParentData{
        
        @AuraEnabled
        public String caseNumber{get;set;}
        @AuraEnabled
        public String akamId{get;set;}
        
        public ParentData(String cNum, String akamId){
            caseNumber = cNum;
            akamId = akamId;
        }
    }

}