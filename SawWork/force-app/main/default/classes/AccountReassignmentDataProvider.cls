public class AccountReassignmentDataProvider {
    private list<Account_Reassignment__c> newReassignmentList;
    private map<Id,Account_Reassignment__c> oldReassignmentMap;
    private set<Id> accountIdSet;
    private map<string,string> gsmSetting;
    private map<string,string> reassignConfigSetting;
    private set<Id> assignToRuleIdSet;
    private map<Id,Boolean> accOwnerStatusMap;
    private map<Id,Account> accIdToAccountMap;
    private set<Id> revenueAccountSet;
    private map<Id,Account_Reassignment_Rule__c> ruleIdToRuleMap;
    private set<Id> associatedUserIdSet;
    private set<string> reassignOpptyRecTypes;
    private list<string> accReassignReasonList; //SFDC-7770
    private map<Id,Id> accOwnerToRsmMap;
    private map<Id, Account_Reassignment_Rule__c> userIdToRuleMap;
    private map<string,set<Id>> salesOpsGroupMemberMap;
    private list<Account_Reassignment_Reason_Code__mdt> reasonCodeSetting;
    private map<Id,User> userIdToUserMap;
    private string currentUserId;
    private map<Id,list<Opportunity>> accountToOpenOpportunites;
    private map<Id,Account_Reassignment__c> accIdToReassignmentMap;
    private set<Id> assignToUserIdSet;
    private map<Id,string> associatedUserIdToRoleMap;
    
    public AccountReassignmentDataProvider(){
        newReassignmentList = new list<Account_Reassignment__c>();
        oldReassignmentMap = new map<Id,Account_Reassignment__c>();
        accountIdSet = new set<Id>();
        gsmSetting = new map<string,string>();
        reassignConfigSetting = new map<string,string>();
        assignToRuleIdSet = new set<Id>();
        accOwnerStatusMap = new map<Id,Boolean>();
        accIdToAccountMap = new map<Id,Account>();
        revenueAccountSet = new set<Id>();
        ruleIdToRuleMap = new map<Id,Account_Reassignment_Rule__c>();
        associatedUserIdSet = new set<Id>();
        reassignOpptyRecTypes = new set<string>();
        accReassignReasonList = new list<string>(); //SFDC-7770
        accOwnerToRsmMap = new map<Id,Id>();
        userIdToRuleMap = new map<Id,Account_Reassignment_Rule__c>();
        salesOpsGroupMemberMap = new map<string,set<Id>>();
        reasonCodeSetting = new list<Account_Reassignment_Reason_Code__mdt>();
        userIdToUserMap = new map<Id,User>();
        currentUserId = '';
        accountToOpenOpportunites = new map<Id,list<Opportunity>>();
        accIdToReassignmentMap = new map<Id,Account_Reassignment__c>();
        assignToUserIdSet = new set<Id>();
        associatedUserIdToRoleMap = new map<Id,string>();
    }
    
    public list<Account_Reassignment__c> getNewReassignmentList(){
        return this.newReassignmentList;
    }
    public void setNewReassignmentList(list<Account_Reassignment__c> newReassignmentList){
        this.newReassignmentList=newReassignmentList;
    }
    public map<Id,Account_Reassignment__c> getOldReassignmentMap(){
        return this.oldReassignmentMap;
    }
    public void setOldReassignmentMap(map<Id,Account_Reassignment__c> oldReassignmentMap){
        this.oldReassignmentMap=oldReassignmentMap;
    }
    public set<Id> getAccountIdSet(){
        return this.accountIdSet;
    }
    public void setAccountIdSet(set<Id> accountIdSet){
        this.accountIdSet=accountIdSet;
    }
    public map<string,string> getGsmSetting(){
        return this.gsmSetting;
    }
    public void setGsmSetting(map<string,string> gsmSetting){
        this.gsmSetting=gsmSetting;
    }
    public map<string,string> getReassignConfigSetting(){
        return this.reassignConfigSetting;
    }
    public void setReassignConfigSetting(map<string,string> reassignConfigSetting){
        this.reassignConfigSetting=reassignConfigSetting;
    }
    public set<Id> getAssignToRuleIdSet(){
        return this.assignToRuleIdSet;
    }
    public void setAssignToRuleIdSet(set<Id> assignToRuleIdSet){
        this.assignToRuleIdSet=assignToRuleIdSet;
    }
    public map<Id,Boolean> getAccOwnerStatusMap(){
        return this.accOwnerStatusMap;
    }
    public void setAccOwnerStatusMap(map<Id,Boolean> accOwnerStatusMap){
        this.accOwnerStatusMap=accOwnerStatusMap;
    }
    public map<Id,Account> getAccIdToAccountMap(){
        return this.accIdToAccountMap;
    }
    public void setAccIdToAccountMap(map<Id,Account> accIdToAccountMap){
        this.accIdToAccountMap=accIdToAccountMap;
    }
    public set<Id> getRevenueAccountSet(){
        return this.revenueAccountSet;
    }
    public void setRevenueAccountSet(set<Id> revenueAccountSet){
        this.revenueAccountSet=revenueAccountSet;
    }
    public map<Id,Account_Reassignment_Rule__c> getRuleIdToRuleMap(){
        return this.ruleIdToRuleMap;
    }
    public void setRuleIdToRuleMap(map<Id,Account_Reassignment_Rule__c> ruleIdToRuleMap){
        this.ruleIdToRuleMap=ruleIdToRuleMap;
    }
    public set<Id> getAssociatedUserIdSet(){
        return this.associatedUserIdSet;
    }
    public void setAssociatedUserIdSet(set<Id> associatedUserIdSet){
        this.associatedUserIdSet.addAll(associatedUserIdSet);
    }
    public set<string> getReassignOpptyRecTypes(){
        return this.reassignOpptyRecTypes;
    }
    public void setReassignOpptyRecTypes(set<string> reassignOpptyRecTypes){
        this.reassignOpptyRecTypes=reassignOpptyRecTypes;
    }

    //SFDC-7770
    public list<string> getaccReassignReasonList(){
        return this.accReassignReasonList;
    }
    public void setaccReassignReasonList(list<string> accReassignReasonList){
        this.accReassignReasonList=accReassignReasonList;
    }
    public map<Id,Id> getAccOwnerToRsmMap(){
        return this.accOwnerToRsmMap;
    }
    public void setAccOwnerToRsmMap(map<Id,Id> accOwnerToRsmMap){
        this.accOwnerToRsmMap=accOwnerToRsmMap;
    }
    public map<Id,Account_Reassignment_Rule__c> getUserIdToRuleMap(){
        return this.userIdToRuleMap;
    }
    public void setUserIdToRuleMap(map<Id,Account_Reassignment_Rule__c> userIdToRuleMap){
        this.userIdToRuleMap=userIdToRuleMap;
    }
    public map<string,set<Id>> getSalesOpsGroupMemberMap(){
        return this.salesOpsGroupMemberMap;
    }
    public void setSalesOpsGroupMemberMap(map<string,set<Id>> pSalesOpsGroupMemberMap){
        this.salesOpsGroupMemberMap.putAll(pSalesOpsGroupMemberMap);
    }
    public list<Account_Reassignment_Reason_Code__mdt> getReasonCodeSetting(){
        return this.reasonCodeSetting;
    }
    public void setReasonCodeSetting(list<Account_Reassignment_Reason_Code__mdt> reasonCodeSetting){
        this.reasonCodeSetting=reasonCodeSetting;
    }
    public map<Id,User> getUserIdToUserMap(){
        return this.userIdToUserMap;
    }
    public void setUserIdToUserMap(map<Id,User> userIdToUserMap){
        this.userIdToUserMap=userIdToUserMap;
    }
    public string getCurrentUserId(){
        return this.currentUserId;
    }
    public void setCurrentUserId(string currentUserId){
        this.currentUserId=currentUserId;
    }
    public map<Id,list<Opportunity>> getAccountToOpenOpportunites(){
        return this.accountToOpenOpportunites;
    }
    public void setAccountToOpenOpportunites(map<Id,list<Opportunity>> accountToOpenOpportunites){
        this.accountToOpenOpportunites=accountToOpenOpportunites;
    }
    public map<Id,Account_Reassignment__c> getAccIdToReassignmentMap(){
        return this.accIdToReassignmentMap;
    }
    public void setAccIdToReassignmentMap(map<Id,Account_Reassignment__c> accIdToReassignmentMap){
        this.accIdToReassignmentMap=accIdToReassignmentMap;
    }
    public set<Id> getAssignToUserIdSet(){
        return this.assignToUserIdSet;
    }
    public void setAssignToUserIdSet(set<Id> assignToUserIdSet){
        this.assignToUserIdSet=assignToUserIdSet;
    }
    public map<Id,string> getAssociatedUserIdToRoleMap(){
        return this.associatedUserIdToRoleMap;
    }
    public void setAssociatedUserIdToRoleMap(map<Id,string> associatedUserIdToRoleMap){
        this.associatedUserIdToRoleMap=associatedUserIdToRoleMap;
    }
}