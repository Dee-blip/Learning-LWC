/**
 * @Author		:		Sujay
 * @Date		:		12-Aug-2018
 * @Desc		:		Controller for Filtered/unFiltered Lookup Lightning Component
 * */
public class InvWB_Lookup {

    /**
     * Returns JSON of list of ResultWrapper to Components
     * @objectName - Name of SObject
     * @fld_API_Text - API name of field to display to user while searching
     * @fld_API_Val - API name of field to be returned by Lookup COmponent
     * @lim   - Total number of record to be returned
     * @fld_API_Search - API name of field to be searched
     * @searchText - text to be searched
     * */
    @AuraEnabled 
    public static String searchDB(String objectName, String fld_API_Text, String fld_API_Val, 
                                  Integer lim, String fld_API_Search,String searchText, String addSearchFilter, String fieldFilter, String iwSecAcc, String recordtyp){
        
		String query;
		if(objectName.containsIgnoreCase('pse__Region__c') && addSearchFilter != NULL){
              searchText='\'%' + String.escapeSingleQuotes(searchText.trim()) + '% ' +addSearchFilter +'\'';  
           	  query = 'SELECT '+ fld_API_Text +' ,'+ fld_API_Val +
						' FROM '+ objectName +
						' WHERE '+ fld_API_Search +' LIKE '+ searchText + 
						' AND ' + fieldFilter + '= false'  +
                  		//' AND (NOT ' + fld_API_Search + ' LIKE ' + '\'%'+' _Old' +'%' + '\')' +
                        ' AND (NOT ' + fld_API_Search + ' LIKE ' + '\'%'+' _Old' + '\')' +
                        ' AND (NOT ' + fld_API_Search + ' LIKE ' + '\'%'+' _Old' +' (%' + '\')' +
						' LIMIT '+ lim;
		}
		else if(objectName.containsIgnoreCase('User')){
            PSA_Common_Setting__mdt pc = [SELECT Value_Long__c FROM PSA_Common_Setting__mdt WHERE Name__c = 'IW URMap'];
            searchText='\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'';
            String profiles =pc.Value_Long__c;
			query = 'SELECT '+fld_API_Text+' ,'+fld_API_Val+
					' FROM '+objectName+
					' WHERE '+fld_API_Search+' LIKE '+searchText+ 
                	' AND isActive = true' + 
                	//' AND Profile.Name IN ' + profiles +
					' LIMIT '+lim;                   
		System.debug('query ::::::::::::::::::: '+ query);
		}
        else if(ObjectName.containsIgnoreCase('pse__Proj__c') && recordtyp != '' && iwSecAcc != ''){

            searchText='\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'';

            query = 'SELECT '+fld_API_Text+' ,'+fld_API_Val+
                    ' FROM '+ objectName +
                    ' WHERE '+fld_API_Search+' LIKE '+searchText+ 
                    ' AND RecordType.Name = '+ '\'' + recordtyp +'\'' + 
                    ' AND pse__Account__c = ' + '\'' +  iwSecAcc + '\'' +
                    ' LIMIT '+lim;
                                          
        }
		else if(ObjectName.containsIgnoreCase('Opportunity') && iwSecAcc != NULL){
            searchText='\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'';

            query = 'SELECT '+fld_API_Text+' ,'+fld_API_Val+
                    ' FROM '+ objectName +
                    ' WHERE '+fld_API_Search+' LIKE '+searchText+ 
                    ' AND AccountId = ' + '\'' +  iwSecAcc + '\'' +
                	' ORDER BY CloseDate DESC' + 
                    ' LIMIT '+lim;                              
		}
		else{
			searchText='\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'';

            query = 'SELECT '+fld_API_Text+' ,'+fld_API_Val+
					' FROM '+objectName+
					' WHERE '+fld_API_Search+' LIKE '+searchText+ 
					' LIMIT '+lim;
                                          
		}
                                      
        System.debug('Lookup Query : ' + query);
        List<sObject> sobjList = Database.query(query);
        List<ResultWrapper> lstRet = new List<ResultWrapper>();
        
        for(SObject s : sobjList){
            ResultWrapper obj = new ResultWrapper();
            obj.objName = objectName;
            obj.val = String.valueOf(s.get(fld_API_Val));
            if(!fld_API_Text.contains('.')){
                obj.text = String.valueOf(s.get(fld_API_Text)) ;
            }
            else{
                String[] txt = fld_API_Text.split('\\.');
				Map<String, Object> mapVal = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(s));
                obj.text = String.valueOf(((Map<String, Object>)mapVal.get(txt[0])).get(txt[1]));
            }
            
            lstRet.add(obj);
        } 
         System.debug('returned Json : ' + JSON.serialize(lstRet));
         return JSON.serialize(lstRet) ;
    }
    
    public class ResultWrapper{
        public String objName {get;set;}
        public String text{get;set;}
        public String val{get;set;}
    }

}