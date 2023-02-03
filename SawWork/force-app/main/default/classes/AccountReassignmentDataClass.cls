/**
   History
      
      --Developer       --Date         --Description
      Chandra Lohani                Created this Class
      Ali KM            08/04/2011     CR 1145503 Account Moves: Keep terminated users as the account.owner for their termination month
                                 -> Added logic to VFPage, DecideAction() & Reassign_ApprovedReassignments() methods.
                                    -> If Account Owner is InActive and its a Lead or Active Reassignment Account request.
                                       For Lead Accounts: 
                                          -> Reassign immediately if Account does not have any open Opptys OR has open Opptys with closed Date=current month
                                          -> Reassign Next Month if Account has open Opptys with Closed Date > current month
                                       For Active Accounts:
                                          -> Reassign Next Month.
      Ali KM            19/05/2012      CR 1533601 Contract Visibility: Enhancements.
                                       As part of Account Reassignment, also reassigning all Account Contact to new Account Owner.                                         
*/

public class AccountReassignmentDataClass { 
   
   // Static Variables and getters
   //private static Map<String, Account_Reassignment_Settings__c> customSettings = Account_Reassignment_Settings__c.getAll(); //SFDC-2304
   private static Map<String, String> accReassignMap = GsmUtilClass.getAccReassignmentKeyValue();
   //private static Account_Reassignment_Class_Settings__c accReassignmentClassCustomSettings = Account_Reassignment_Class_Settings__c.getInstance('v1.0'); //SFDC-2304
   
   public static String getCustomSettings(String settingsName)
   {
      return accReassignMap.get(settingsName); //SFDC-2304
   }
   /*public static Account_Reassignment_Class_Settings__c getAccReassignmentClassCustomSettings() //SFDC-2304
   {
      return accReassignmentClassCustomSettings;
   }*/
   // Instance Varibles
   private Boolean flag;
   //public static Boolean firstRunFlag = true;
   private Map<Id,Account_Reassignment_Rule__c> rulesMap;
  // Store all the Old Owners Ids in a set.
   private Map<Id,Id> accountOwnerMap;
   private Map<Id,String> userRoleMap;  
  // PDRA Bug fix variable
   private Set<Id> accOwnerIdsSet;
   private Map<Id,Id> ruleMap;
  // PDRA Cont 2 - Auto reassing to ONA if Owner does not have AccountReassignmentRule
   private Id ONARuleId;
   private List<Account> accounts;
   private List<Account_Reassignment__c> accReassignmentList;
   private Map<Id,Account_Reassignment__c> oldAccReassignmentMap;
   private Map<Id,Id> accountIdRuleIdMap;
   private String fromWhere;
   private Boolean isInsert;
   private Boolean isBefore;
   private Map<Id,Account_Reassignment__c> accountIdAccountReassignmentMap;
   private List<Opportunity> relatedOpportunities;
   private List<Contact> relatedContacts;
   private List<AccountTeamMember> oldAccountTeamMembers;
   private List<AccountTeamMember> newAccountTeamMembers;
   private List<Default_Account_Team_Members__c> newDefaultAccountTeamMembers;
   private Set<Id> teamMemberIds;
   private List<AccountShare> relatedAccountShares;
   private Map<Id,Boolean> accOwnerStatusMap;
   private List<String> reassignOpptyRecTypes;
   private Set<Id> revenueAccounts;
   private Map<Id,Account> relatedAccountMap;
   //private Map<Id,String> accOwnerProfileMap;
   private Map<String,Set<Id>> salesOpsGroupMemberMap;
   private Map<Id,User> userMap;//salesOpsUsersMap;
   private Set<Id> userIdSet; 
   private String accountIsIntRevenueAccountErrorMsg;
   
   // Error message
   private String accountIdNotPresentErrorMessage;
   // Constructor
   public AccountReassignmentDataClass()
   {
      flag=false;
      rulesMap = new Map<Id,Account_Reassignment_Rule__c>();
      accountOwnerMap = new Map<Id,Id>();
      userRoleMap = new Map<Id,String>();
      accOwnerIdsSet = new Set<Id>();
      ruleMap = new Map<Id,Id>();
      ONARuleId=null;
      accounts=null;
      accReassignmentList=null;
      oldAccReassignmentMap=null;
      accountIdRuleIdMap=new Map<Id,Id>();
      isInsert=null;
      isBefore=null;
      accountIdAccountReassignmentMap=new Map<Id,Account_Reassignment__c>();
      relatedOpportunities=new List<Opportunity>();
      relatedContacts=new List<Contact>();
      oldAccountTeamMembers=new List<AccountTeamMember>();
      newAccountTeamMembers=new List<AccountTeamMember>();
      newDefaultAccountTeamMembers=new List<Default_Account_Team_Members__c>();
      teamMemberIds=new Set<Id>();
      relatedAccountShares=new List<AccountShare>();
      accOwnerStatusMap = new Map<Id,Boolean>();
      //accountIdNotPresentErrorMessage=GSM_Custom_Settings__c.getInstance('AccReassign#MissingAccIdError').value__c; //SFDC-2304
      accountIdNotPresentErrorMessage=GsmUtilClass.getGSMSettingValue('AccReassign_MissingAccIdError'); //SFDC-2304
      accountIsIntRevenueAccountErrorMsg = GSMUtilClass.getGSMSettingValue('AccReassign_InternalRevAccount');
      reassignOpptyRecTypes = new List<Id>();
      revenueAccounts = new Set<Id>();
      relatedAccountMap = new Map<Id,Account>();
      //accOwnerProfileMap = new Map<Id,String>();
      salesOpsGroupMemberMap = new Map<String,Set<Id>>();
      userIdSet = new Set<Id>();
      userMap = new Map<Id,User>(); //salesOpsUsersMap
      //init
      initReassignOpptyRecTypes(); 
   }
   
   private void initReassignOpptyRecTypes()
   {
         reassignOpptyRecTypes.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId());
         reassignOpptyRecTypes.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId());
    }
    
   
   //getters and setters
   public void setAccOwnerStatusMap(Map<Id,Boolean> pAccOwnerStatusMap)
   {
      this.accOwnerStatusMap = pAccOwnerStatusMap;
   }
   
   public Map<Id,Boolean> getAccOwnerStatusMap()
   {
      return this.accOwnerStatusMap;
   }
   
   public Boolean isFlag()
   {
      return this.flag;
   }
   public void setFlag(Boolean flag)
   {
      this.flag=flag;
   }
   
   public Map<Id,Account_Reassignment_Rule__c> getRulesMap()
   {
      return this.rulesMap;
   }
   public void setRulesMap(Map<Id,Account_Reassignment_Rule__c> rulesMap)
   {
      this.rulesMap=rulesMap;
   }
   
   public Map<Id,Id> getAccountOwnerMap()
   {
      return this.accountOwnerMap;
   }
   public void setAccountOwnerMap(Map<Id,Id> accountOwnerMap)
   {
      this.accountOwnerMap=accountOwnerMap;
   }
   
   public Map<Id,String> getUserRoleMap()
   {
      return this.userRoleMap;
   }
   public void  setUserRoleMap(Map<Id,String> userRoleMap)
   {
      this.userRoleMap=userRoleMap;
   }
   
   public Set<Id> getAccOwnerIdsSet()
   {
      return this.accOwnerIdsSet;
   }
   public void setAccOwnerIdsSet(Set<Id> accOwnerIdSet)
   {
      this.accOwnerIdsSet=accOwnerIdSet;
   }
   
   public Map<Id,Id> getRuleMap()
   {
      return this.ruleMap;
   }
   public void setRuleMap(Map<Id,Id> ruleMap)
   {
      this.ruleMap=ruleMap;
   }
   
   public Id getONARuleId()
   {
      return this.ONARuleId;
   }
   public void setONARuleId(Id ONARuleId)
   {
      this.ONARuleId=ONARuleId;
   }
   
   public List<Account> getAccounts()
   {
      return this.accounts;
   }
   public void setAccounts(List<Account> accounts)
   {
      this.accounts=accounts;
   }
   
   public List<Account_Reassignment__c> getAccReassignmentList()
   {
      return this.accReassignmentList;
   }
   public void setAccReassignmentList(List<Account_Reassignment__c> accReassignmentList)
   {
      this.accReassignmentList=accReassignmentList;
   }
   
   public Map<Id,Account_Reassignment__c> getOldAccReassignmentMap()
   {
      return this.oldAccReassignmentMap;
   }
   public void setOldAccReassignmentMap(Map<Id,Account_Reassignment__c> oldAccReassignmentMap)
   {
      this.oldAccReassignmentMap=oldAccReassignmentMap;
   }
   public Map<Id,Id> getAccountIdRuleIdMap()
   {
      return this.accountIdRuleIdMap;
   }
   public void setAccountIdRuleIdMap(Map<Id,Id> accountIdRuleIdMap)
   {
      this.accountIdRuleIdMap=accountIdRuleIdMap;
   }
   
   public String getFromWhere()
   {
      return this.fromWhere;
   }
   public void setFromWhere(String fromWhere)
   {
      this.fromWhere=fromWhere;
   }
   
   public Boolean getIsInsert()
   {
      return this.isInsert;
   }
   public void setIsInsert(Boolean isInsert)
   {
      this.isInsert=isInsert;
   }
   
   public Boolean getIsBefore()
   {
      return this.isBefore;
   }
   public void setIsBefore(Boolean isBefore)
   {
      this.isBefore=isBefore;
   }
   
   public Map<Id,Account_Reassignment__c> getAccountIdAccountReassignmentMap()
   {
      return this.accountIdAccountReassignmentMap;
   }
   public void setAccountIdAccountReassignmentMap(Map<Id,Account_Reassignment__c> accountIdAccountReassignmentMap)
   {
      this.accountIdAccountReassignmentMap=accountIdAccountReassignmentMap;
   }
   
   public List<Opportunity> getRelatedOpportunities()
   {
      return this.relatedOpportunities;
   }
   public void setRelatedOpportunities(List<Opportunity> relatedOpportunities)
   {
      this.relatedOpportunities=relatedOpportunities;
   }
   
   public List<Contact> getRelatedContacts()
   {
      return this.relatedContacts;
   }
   public void setRelatedContacts(List<Contact> relatedContacts)
   {
      this.relatedContacts=relatedContacts;
   }
   
   public List<AccountTeamMember> getOldAccountTeamMembers()
   {
      return this.oldAccountTeamMembers;
   }
   public void setOldAccountTeamMembers(List<AccountTeamMember> oldAccountTeamMembers){
      this.oldAccountTeamMembers=oldAccountTeamMembers;
   }
   
   public List<AccountTeamMember> getNewAccountTeamMembers()
   {
      return this.newAccountTeamMembers;
   }
   public void setNewAccountTeamMembers(List<AccountTeamMember> newAccountTeamMembers){
      this.newAccountTeamMembers=newAccountTeamMembers;
   }
   
   public List<Default_Account_Team_Members__c> getNewDefaultAccountTeamMembers()
   {
      return this.newDefaultAccountTeamMembers;
   }
   public void setNewDefaultAccountTeamMembers(List<Default_Account_Team_Members__c> newDefaultAccountTeamMembers)
   {
      this.newDefaultAccountTeamMembers=newDefaultAccountTeamMembers;
   }
   
   public Set<Id> getTeamMemberIds()
   {
      return this.teamMemberIds;
   }
   public void setTeamMemberIds(Set<Id> teamMemberIds)
   {
      this.teamMemberIds=teamMemberIds;
   }
   
   public List<AccountShare> getRelatedAccountShares()
   {
      return this.relatedAccountShares;
   }
   public void setRelatedAccountShares(List<AccountShare> relatedAccountShares)
   {
      this.relatedAccountShares=relatedAccountShares;
   }
   
   public String getAccountIdNotPresentErrorMessage()
   {
      return this.accountIdNotPresentErrorMessage;
   }
   public void setAccountIdNotPresentErrorMessage(String accountIdNotPresentErrorMessage)
   {
      this.accountIdNotPresentErrorMessage=accountIdNotPresentErrorMessage;
   }
   public List<String> getReassignOpptyRecTypes()
    {
      return this.reassignOpptyRecTypes;
    }
    
   public void setRevenueAccounts(Set<Id> pRevenueAccounts)
   {
      this.revenueAccounts = pRevenueAccounts;
   }
   public Set<Id> getRevenueAccounts()
   {
      return this.revenueAccounts;
   }
   
   public void setRelatedAccountMap(Map<Id,Account> pRelatedAccountMap)
   {
      this.relatedAccountMap = pRelatedAccountMap;
   }
   public Map<Id,Account> getRelatedAccountMap()
   {
      return this.relatedAccountMap;
   }
   
   public void setUserIdSet(Set<Id> pUserIdSet)
   {
      this.userIdSet.addAll(pUserIdSet);
   }
   public Set<Id> getUserIdSet()
   {
      return this.userIdSet;
   }
   
   public void setSalesOpsGroupMemberMap(Map<String,Set<Id>> pSalesOpsGroupMemberMap)
   {
      this.salesOpsGroupMemberMap.putAll(pSalesOpsGroupMemberMap);
   }
   public Map<String,Set<Id>> getSalesOpsGroupMemberMap()
   {
      return this.salesOpsGroupMemberMap;
   }
   
   public void setUserMap(Map<Id,User> pUserMap) // setSalesOpsUsersMap
   {
      this.userMap.putAll(pUserMap);
   }
   public Map<Id,User> getUserMap()
   {
      return this.userMap;
   } 
      public String getAccountIsIntRevenueAccountErrorMsg()
   {
      return this.accountIsIntRevenueAccountErrorMsg;
   }
   
   public void setAccountIsIntRevenueAccountErrorMsg(String accountIsIntRevenueAccountErrorMsg)
   {        
      this.accountIsIntRevenueAccountErrorMsg=accountIsIntRevenueAccountErrorMsg;
   }        

}