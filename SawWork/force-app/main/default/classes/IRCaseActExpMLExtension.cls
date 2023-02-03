/*  @Change History
    Developer | CR    | Date  |  Purpose
      Ankit   |3003392|27.4.15|Extension to get list view for active and expired CML on Case object. VFPage:IRCaseActExpManList
      Ankit   |3021023|18.5.15|Corrected query to show correct data for active and expired ML.
      Ankit   |3102071|23.7.15|Added 'IRCA_ManList_Extn_Days' custom setting for extending active manual lists.
*/ 
public class IRCaseActExpMLExtension {

public  List<Merge_Contract_Manual_List__c> amlList {get;set;}    
public  List<Merge_Contract_Manual_List__c> emlList {get;set;} 
public   Case  IRCase {get;set;}
public IRCaseActExpMLExtension(ApexPages.StandardController stdController) 
  {
  this.IRCase = (Case)stdController.getRecord();
    List<Case> IRCaseList ;

    IRCaseList = [Select IR_Original_Contract_Id__c from Case where Id =:IRCase.Id];
    //CR 3102071
    Integer manList_Extn_Days = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IRCA_ManList_Extn_Days'));
    
  IF (IRCaseList !=null) 
    {
      amlList = [Select Manual_List_Id__c ,Reason_Code__c ,Review_Frequency__c ,Review_Date__c ,Priority__c , Description__c , Owner__c , 
              End_Date__c , Accrual_Flag__c , Sub_Reason_Code__c from Merge_Contract_Manual_List__c Where Original_Contract_Id__c =: IRCaseList[0].IR_Original_Contract_Id__c 
              AND ((Review_Frequency__c ='Monthly' and (End_Date__c = null OR End_Date__c >=: System.Date.today().addDays(-(manList_Extn_Days)))) OR (Review_Frequency__c ='One Time' and (Review_Date__c = null OR Review_Date__c >=: System.Date.today().addDays(-(manList_Extn_Days))))) //CR 3021023 
              order by End_Date__c DESC NULLS FIRST]; //CR 3102071
        
        emlList = [Select Manual_List_Id__c ,Reason_Code__c ,Review_Frequency__c ,Review_Date__c ,Priority__c , Description__c , Owner__c , 
              End_Date__c , Accrual_Flag__c , Sub_Reason_Code__c from Merge_Contract_Manual_List__c Where Original_Contract_Id__c =: IRCaseList[0].IR_Original_Contract_Id__c 
              AND ((Review_Frequency__c ='Monthly' and (End_Date__c <: System.Date.today().addDays(-(manList_Extn_Days)))) OR (Review_Frequency__c ='One Time' and (Review_Date__c <: System.Date.today().addDays(-(manList_Extn_Days))))) //CR 3021023
              order by End_Date__c DESC NULLS LAST]; //CR 3102071
    }
  }
}