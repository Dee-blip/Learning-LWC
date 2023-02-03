public class IRCaseActExpMLController {

    @AuraEnabled
    public static Map<String, List<Merge_Contract_Manual_List__c>> getManualLists(Id caseId){

        List<Merge_Contract_Manual_List__c> amlList;
		    List<Merge_Contract_Manual_List__c> emlList;
        Map<String, List<Merge_Contract_Manual_List__c>> manualListMap = new Map<String, List<Merge_Contract_Manual_List__c>>();
        List<Case> IRCaseList =[Select IR_Original_Contract_Id__c from Case where Id =:caseId];

        IF (IRCaseList !=null){
            Integer manList_Extn_Days = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IRCA_ManList_Extn_Days'));
			amlList = [Select Id, Manual_List_Id__c ,Reason_Code__c ,Review_Frequency__c ,Review_Date__c ,Priority__c , Description__c , Owner__c ,
		              	End_Date__c , Accrual_Flag__c , Sub_Reason_Code__c from Merge_Contract_Manual_List__c
                   		Where Original_Contract_Id__c =: IRCaseList[0].IR_Original_Contract_Id__c
                       	AND ((Review_Frequency__c ='Monthly' and (End_Date__c = null OR End_Date__c >=: System.Date.today().addDays(-(manList_Extn_Days)))) OR
                             (Review_Frequency__c ='One Time' and (Review_Date__c = null OR Review_Date__c >=: System.Date.today().addDays(-(manList_Extn_Days)))))
              			order by End_Date__c DESC NULLS FIRST];

            manualListMap.put('active', amlList);

            emlList = [Select Id, Manual_List_Id__c ,Reason_Code__c ,Review_Frequency__c ,Review_Date__c ,Priority__c , Description__c , Owner__c ,
              			End_Date__c , Accrual_Flag__c , Sub_Reason_Code__c from Merge_Contract_Manual_List__c
                       	Where Original_Contract_Id__c =: IRCaseList[0].IR_Original_Contract_Id__c
        				AND ((Review_Frequency__c ='Monthly' and (End_Date__c <: System.Date.today().addDays(-(manList_Extn_Days)))) OR
                             (Review_Frequency__c ='One Time' and (Review_Date__c <: System.Date.today().addDays(-(manList_Extn_Days)))))
              			order by End_Date__c DESC NULLS LAST];

            manualListMap.put('expired', emlList);
        }
        return manualListMap;
    }
}