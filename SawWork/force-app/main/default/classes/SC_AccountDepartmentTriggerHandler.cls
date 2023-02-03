/*
 * JIRA: ESESP-5249
 * Developer: Bhavesh Kumar
 * Date: July 5 2021
 * 
 * Developer                        Date                            Changes
 * Bhavesh                          5 July 2021                Controller class for trigger - AccountDepartmentTrigger..
*/
public class SC_AccountDepartmentTriggerHandler {
    public static Boolean isInsertCalled = false;
    public static Boolean isTriggerActive = false;
    public static String duplicateRecordMsg = '';
    public static String noAccessErrMsg = '';
    public static List<String> accRolesList = new List<String>();
    static{
        for(Account_Department_Trigger_Metadata__mdt  mdt : [Select DeveloperName , Value__c FROM Account_Department_Trigger_Metadata__mdt ] ){
            if(mdt.DeveloperName  == 'Roles')
                accRolesList.addAll(mdt.Value__c.split(','));
            else if(mdt.DeveloperName  == 'Duplicate_Error_Message')
                duplicateRecordMsg = mdt.Value__c;
            else if(mdt.DeveloperName  =='Edit_Access_Error_Message')
                noAccessErrMsg = mdt.Value__c;
            else if(mdt.DeveloperName  == 'TriggerActivate' && mdt.Value__c == 'True')
                isTriggerActive = true;
             
        }
    }
    public static void beforeInsert(List<Account_Department__c> newList){
        List<Id> accIdList = new List<Id>();
        List<Id> userIdList = new List<Id>();
        for( Account_Department__c ad : newList ){
            accIdList.add(ad.Account_Name__c);
        }
        checkDuplicateDepartmentOnAccount(newList, accIdList);
        
    }
    public static void beforeUpdate( List<Account_Department__c> newList, Map<Id,Account_Department__c> oldMap ){
        List<Id> accIdList = new List<Id>();
        List<Id> userIdList = new List<Id>();
        for( Account_Department__c ad : newList ){
            
            if( oldMap.get(ad.Id).Name != ad.Name ){
                accIdList.add(ad.Account_Name__c);
            }
        }
        if(accIdList.size()>0)
        checkDuplicateDepartmentOnAccount(newList, accIdList);
        
    }
    
    public static void afterInsert(List<Account_Department__c> newList){
        List<Id> accIdList = new List<Id>();
        List<Id> userIdList = new List<Id>();
        for( Account_Department__c ad : newList ){
            accIdList.add(ad.Account_Name__c);
            userIdList.add(ad.createdbyId);
        }
        checkCreateEditAccess(newList, accIdList, userIdList, true);
        isInsertCalled = true;
        
    }
    public static void afterUpdate( List<Account_Department__c> newList, Map<Id,Account_Department__c> oldMap ){
        List<Id> accIdList = new List<Id>();
        List<Id> userIdList = new List<Id>();
        for( Account_Department__c ad : newList ){
            accIdList.add(ad.Account_Name__c);
            userIdList.add(ad.LastModifiedById);
        }
        checkCreateEditAccess(newList, accIdList, userIdList, false);
        
    }
    
    public static void checkDuplicateDepartmentOnAccount(List<Account_Department__c> newList, List<Id> accIdList){
        Map<Id, List<Account_Department__c>> accIdWithDepartmentListMap = new Map<Id, List<Account_Department__c>>();
        List<Account_Department__c> departmentList;
        for(Account_Department__c ad : [Select Id, Account_Name__c, Name FROM Account_Department__c Where Account_Name__c in: accIdList ]){
            departmentList = new List<Account_Department__c>();
            if( accIdWithDepartmentListMap.containsKey(ad.Account_Name__c)){
                departmentList = accIdWithDepartmentListMap.get(ad.Account_Name__c);
            } 
            departmentList.add(ad);
            accIdWithDepartmentListMap.put(ad.Account_Name__c,departmentList);
        }
        
        for(Account_Department__c ad: newList){
            
            if(accIdWithDepartmentListMap.containsKey(ad.Account_Name__c )){ 
                for( Account_Department__c dep : accIdWithDepartmentListMap.get(ad.Account_Name__c)){
                    if( dep.id != ad.Id && (ad.Name.deleteWhitespace().toLowerCase() == dep.Name.deleteWhitespace().toLowerCase()
                      || ad.Name.toLowerCase() == dep.Name.toLowerCase())){
                        ad.addError(''+duplicateRecordMsg); 
                    }
                }
                
            }
        }
    }
    
    
    public static void checkCreateEditAccess(List<Account_Department__c> newList, List<Id> accIdList, List<Id> userIdList, Boolean isInsert){
        Set<String> accIdUserIdSet = new Set<String>();
        for( AccountTeamMember atr : [Select Id, AccountId, UserId From AccountTeamMember 
                                      where AccountId in: accIdList 
                                      and UserId in: userIdList
                                      and TeamMemberRole in: accRolesList]){
        	accIdUserIdSet.add(''+atr.AccountId+atr.UserId);             
        }
        for(Account_Department__c ad: newList){
            if((!ad.Admin_Govern__c && isInsert && !accIdUserIdSet.contains(''+ad.Account_Name__c+ad.CreatedById))
               ||
               (!ad.Admin_Govern__c && isInsertCalled == False && !isInsert && !accIdUserIdSet.contains(''+ad.Account_Name__c+ad.LastModifiedById))){
                ad.adderror(''+noAccessErrMsg);
            } 
            
        }
                
	}
}