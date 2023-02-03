global without sharing class SF1_LocateAccountController{
    private static final String getAlphaChars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
 /** Begin Rajesh Kumar SFDC-5781 **/
 public static List<String> severErroDetail = System.Label.Account_Sub_Reseller_server_war_err_info.split('#');
 /** End Rajesh Kumar SFDC-5781 **/
    @AuraEnabled
    public static Opportunity getOpportunity(Id opptyId){
        Opportunity currentOppty = SF1_OpportunityService.getOpportunity(opptyId);
        return currentOppty;
    }

    @AuraEnabled
   public static List<Account> accSearch(String AccountName,String AccountDomain,String AccountCountry,String AccountState,Integer offset)
   { Integer oset=Integer.valueof(offset);
     List<Account> Accs = new list<Account>();
     Accs= SF1_AccountService.SearchExistingAccounts(AccountName,AccountDomain,AccountCountry,AccountState,oset);
     return Accs;
   }


   @AuraEnabled
   global static String AddAccount(Id pid, Id oid) {

   Account selectedAccount = SF1_AccountService.getAccount(pid);
   Opportunity Optty= SF1_OpportunityService.getOpportunity(oid);
   String retval;
    if(Optty!=null)
      {
         retval=SF1_LocateAccAndExistingOppService.updateOpportunityAfterLocateAccount(pid,selectedAccount,Optty);
      }
System.debug('Inside AddAccount----->'+retval);
if(retval!=null)
return retval;

else
return null;
}

@AuraEnabled
    public Static list<sobject> DupAccountCheck(Id pid,String AccountName,String AccountDomain, String PrimaryStreet, String PrimaryCity, String PrimaryState, String zip, String PrimaryCountry)
    {
        Account newAccount = new Account();
        newAccount.Name = AccountName;
        newAccount.Website = AccountDomain;
        newAccount.BillingCountry = PrimaryCountry;
        newAccount.BillingStreet = PrimaryStreet;
        newAccount.BillingCity = PrimaryCity;
        newAccount.BillingState = PrimaryState;
        newAccount.BillingPostalCode = Zip;
        string Accinfo ='Akam' ;
        list<account> acctList =new list<account>();
        list<sobject> dupAccList =new list<sobject>();
        
        acctList.add(newAccount);
        try{
        //Find Duplicate Accounts
        Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(acctList);
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        string Akamid='AKAM Account Id::'+ matchRecord.getRecord().get('AKAM_Account_ID__c');
                                if(!Accinfo.contains(Akamid)){
                                    Accinfo +='Account Name::'+matchRecord.getRecord().get('Name') + 'AKAM Account Id::'+ matchRecord.getRecord().get('AKAM_Account_ID__c')+'\n';
                                 
                        dupAccList.add(matchRecord.getRecord());
                        system.debug('acctList1'+dupAccList);
                    }
                    }
                }
            }
        } 
       }catch(Exception e){
        system.debug('Error::'+e.getMessage());
        throw new AuraHandledException(e.getMessage()); 
    } 
    return dupAccList;
        
        }

@AuraEnabled
public static String AddAccnt(Id pid,String AccountName,String AccountDomain, String PrimaryStreet, String PrimaryCity, String PrimaryState, String zip, String PrimaryCountry, String Vertical, String subVertical)
{
    Opportunity Optty= SF1_OpportunityService.getOpportunity(pid);
    String retval;
	system.debug('subVertical:'+subVertical);
    if(Optty!=null)
      {
         retval=SF1_LocateAccAndExistingOppService.updateOpportunityAfterCreateAccount(Optty,AccountName,AccountDomain,PrimaryStreet,PrimaryCity,PrimaryState,zip,PrimaryCountry, Vertical, subVertical);
      }
      System.debug('Inside AddAccnt------>'+retval);
if(retval!=null)
return retval;

else
return null;
}

/** Begin Rajesh Kumar SFDC-5781 **/ // below method return current user theme
@AuraEnabled
public static boolean getuserTheme() {
    List < String > classicThemeList = GsmUtilClass.getGSMSettingValue('SF_Classic_Theme').split(',');
    boolean isClassic = false;

    for (String themeName: classicThemeList) {
        if (UserInfo.getUiThemeDisplayed() == themeName) {
            isClassic = true;
            break;
        }
    }
    return isClassic;
}

// below method returns subresellers name verifies if it is in sub-reseller partner list based on client side search would be disabled .
@AuraEnabled
public static returnWrapper getIntialsubresellerdetail(String opptyId) {
     returnWrapper returnList = new returnWrapper();
     returnList.isPartnertechdata = false;
     List < String > subresPartlis = null;
     if (String.isBlank(opptyId))
        throw new AuraHandledException(severErroDetail[0]);
    try {

       subresPartlis =  GsmUtilClass.getGSMSettingValue('Sub_reseller_partner_list').split(';');
       List < Opportunity > opp = [Select id, Name, Sub_Reseller__c, Partner_Involved__c, Partner_Involved__r.name from Opportunity where Id =: opptyId Limit 1];
        for (String srprtner: subresPartlis) {
            if (opp[0].Partner_Involved__c == srprtner) {
                returnList.isPartnertechdata = true;
                break;
            }
        }
        returnList.subreSellerName = opp.size() > 0 ? String.valueOf(opp[0].Sub_Reseller__c) : null;
        returnList.opptyName = opp.size() > 0 ? String.valueOf(opp[0].Name) : null;
    } catch (Exception ex) { throw new AuraHandledException(severErroDetail[1] + ' ' + ex.getMessage() + '.' + '\n' + severErroDetail[2] + ' ' + ex.getStackTraceString() + '.' + '\n' + severErroDetail[3]);
    }
    return returnList;
}
@AuraEnabled
public static returnWrapper getSubreseller(Integer recordLimit, Integer recordOffset, String opptyId, String resellerName) {
    returnWrapper returnList = new returnWrapper();
    Integer intLimit = Integer.valueof(recordLimit);
    Integer intOffset = Integer.valueof(recordOffset);
    List < String > accPartnertype = null;
    List < String > subresPartlis = null;
    String subrespartinList = null;
    String accpartinList  = null;
    String query = null;
    String queryTotalrows = null;
    resellerName = '%' + resellerName + '%';
    if (String.isBlank(opptyId))
        throw new AuraHandledException(severErroDetail[0]);
    try {
    accPartnertype = GsmUtilClass.getGSMSettingValue('Account_Partner_Type').split(';');
    subresPartlis = GsmUtilClass.getGSMSettingValue('Sub_reseller_partner_list').split(';');
    subrespartinList = generateInlist(new Set < String > (subresPartlis));
    accpartinList = generateInlist(new Set < String > (accPartnertype));
    query = 'Select Id,Name,Website,BillingCountry,BillingState,Owner.Name,Account_Status__c from Account where isPartner = true and name like :resellerName and partner_type__c in' + accpartinList + ' and Id not in '+subrespartinList + 'order by name LIMIT :intLimit Offset :intOffset';
    queryTotalrows = 'Select Id from Account where isPartner = true and name like :resellerName and partner_type__c in ' + accpartinList + ' and Id not in '+subrespartinList ;
    returnList.accList = Database.query(query);
    returnList.opptyList = [Select id, Sub_Reseller__c, Partner_Involved__c, Partner_Involved__r.name from Opportunity where Id =: opptyId Limit 1];
    returnList.totalRows = Database.query(queryTotalrows).size();
    } catch (Exception exc) { throw new AuraHandledException(severErroDetail[1] + ' ' + exc.getMessage() + '.' + '\n' + severErroDetail[2] + ' ' + exc.getStackTraceString() + '.' + '\n' + severErroDetail[3]);
    }
    return returnList;
}
@AuraEnabled
public static void updateSubreseller(String linkedAccountId, String OpportunityId) {
    if (String.isBlank(OpportunityId))
        throw new AuraHandledException(severErroDetail[0]);
    Opportunity opp = new Opportunity(Id = OpportunityId);
    opp.Sub_Reseller_Account__c = linkedAccountId;
    opp.Validation_Override__c = true;
    try {
        update opp;
    } catch (DmlException ex) { throw new AuraHandledException(severErroDetail[1] + ' ' + ex.getMessage() + '.' + '\n' + severErroDetail[2] + ' ' + ex.getStackTraceString() + '.' + '\n' + severErroDetail[3]);

    }
}
//SFDC-5913 check user has Account create access or not
@AuraEnabled
public static Boolean AccountCreateAccess(){
  Boolean flag;
  String accessProfileIds = GSMSettings.getVerbose('AccountCreationProfileIds');
  String accessProfileId1 = GSMSettings.getVerbose('AccountCreationProfileId1');
  String accessProfileId2 = GSMSettings.getVerbose('AccountCreationProfileId2');
   if(accessProfileIds.contains(userinfo.getProfileId()) || accessProfileId1.contains(userinfo.getProfileId()) || accessProfileId2.contains(userinfo.getProfileId()) ){
      flag = true;
    }
      else{
        flag = false;
      }
      return flag;               
  }

 public class returnWrapper {
    @AuraEnabled public List < Account > accList {get;set;}
    @AuraEnabled public String userTheme {get;set;}
    @AuraEnabled public List<Opportunity> opptyList { get;set;}
    @AuraEnabled public Integer accListcount { get;set; }
    @AuraEnabled public Integer totalRows {get;set;}
    @AuraEnabled public String subreSellerName {get;set;}
    @AuraEnabled public Boolean isClassic { get; set; }
    @AuraEnabled public Boolean isPartnertechdata { get; set;}
    @AuraEnabled public String opptyName { get;set;}

 }
 public static String generateInlist(Set < String > keySet) {
     String newSetStr = '';
     for (String str: keySet)
         newSetStr += '\'' + str + '\',';

     newSetStr = newSetStr.lastIndexOf(',') > 0 ? '(' + newSetStr.substring(0, newSetStr.lastIndexOf(',')) + ')' : newSetStr;
     return newSetStr;

 }
/** End Rajesh Kumar SFDC-5781 **/
    
	@AuraEnabled 
	public static customPicklistWrapper getCustomDependablePicklist(String strObjectName, string strparentField, string strchildField) {
        Map<String,List<String>> pickListMap = new Map<String,List<String>>();
        customPicklistWrapper pw = new customPicklistWrapper();
        pw.pickListMap = pickListMap;
        
        if (Schema.getGlobalDescribe().get(strObjectName) == null || String.isBlank(strparentField) || String.isBlank(strChildField)){
            return pw;
        }
    
        Schema.sObjectType objType = Schema.getGlobalDescribe().get(strObjectName).newSObject().getSObjectType();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(strparentField) || !objFieldMap.containsKey(strchildField)){
            return pw;     
        }
        
        List<customPicklistEntryWrapper> depEntriesList = (List<customPicklistEntryWrapper>)JSON.deserialize(JSON.serialize(objFieldMap.get(strChildField).getDescribe().getPicklistValues()), List<customPicklistEntryWrapper>.class);
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : objFieldMap.get(strparentField).getDescribe().getPicklistValues()) {
            pickListMap.put(ple.getLabel(), new List<String>());
            controllingValues.add(ple.getLabel());
        }
        
        for (customPicklistEntryWrapper plew : depEntriesList) {
            String validForBits = alphaBaseToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    pickListMap.get(controllingValues.get(i)).add(plew.label);
                }
            }
        }
        
        pw.pickListMap = pickListMap;
        pw.parentFieldLabel = objFieldMap.get(strparentField).getDescribe().getLabel();
        pw.childFieldLabel = objFieldMap.get(strchildField).getDescribe().getLabel();
        return pw;
	}


    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    public static String alphaBaseToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = getAlphaChars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }

    public class customPicklistWrapper{
        @AuraEnabled
        public Map<String, List<String>> pickListMap;
        @AuraEnabled
        public String parentFieldLabel;
        @AuraEnabled
        public String childFieldLabel;      
    }
    
    public class customPicklistEntryWrapper{
        public String active;
        public String defaultValue;
        public String label;
        public String value;
        public String validFor;
        
    }
}