//business logic for locate existing opportunity and locate account flow
global without sharing class SF1_LocateAccAndExistingOppService {
  public static String updateOpportunityAfterLinkedToDR(Opportunity currentOppty, Id pid) {
    if (currentOppty != null)
    {
      currentOppty.Existing_Opportunity__c = pid;
      currentOppty.Validation_Override__c = true;
      currentOppty.Deal_Reg_Opportunity_Status__c = 'Existing Opportunity';
      // SFDC-9133 - Rebate will be calcualted when the DR gets approved, hence commenting from here.
      // if (currentOppty.Deal_Reg_Account_Status__c == 'Existing Account')
      // {
      //   currentOppty = populateRebateDiscountPercentageAndStatus(currentOppty,'ExistingAccountExistingOppty');
      // }

      // if (currentOppty.Deal_Reg_Account_Status__c == 'Existing Customer')
      // {
      //   currentOppty = populateRebateDiscountPercentageAndStatus(currentOppty,'ExistingCustomerExistingOppty');
      // }
      
      
 
      try
      {
        update currentOppty;
      }
      catch (Exception e)
      {return e.getMessage();
      }
 
    }
 
    return 'success';
 
 
  }
 
  public static String updateOpportunityAfterAcceptAsNew(Opportunity currentOppty)
  {
    currentOppty.Deal_Reg_Opportunity_Status__c = 'New Opportunity';
    currentOppty.Existing_Opportunity__c = null;
 
    // SFDC-9133 - Rebate will be calcualted when the DR gets approved, hence commenting from here.
    // if (currentOppty.Deal_Reg_Account_Status__c == 'Existing Customer')
    // {
    //   currentOppty = populateRebateDiscountPercentageAndStatus(currentOppty,'ExistingCustomerNewOppty');
    // }
    // else if (currentOppty.Deal_Reg_Account_Status__c == 'Existing Account')
    // {
    //   currentOppty = populateRebateDiscountPercentageAndStatus(currentOppty,'ExistingAccountNewOpportunity');
    // }
 
    try
    {
      update currentOppty;
    }
    catch(Exception e){ return e.getMessage();}
    return 'success';
  }
 
  public static String updateOpportunityAfterLocateAccount(Id pid, Account selectedAccount, Opportunity Optty) {
    Optty.AccountId = pid;
    Optty.Validation_Override__c = true;
    Optty.Deal_Reg_Account_Status__c = selectedAccount.Customer_or_Account__c;
    String Success = 'Success';
 
    /*if(Optty.Partner_Owner__c!=null)
          {
            Id ownerId= Optty.Partner_Owner__c;
            Contact owner=[Select Id,Active_Partner__c from Contact where Id=:OwnerId];
            System.debug('Owner------->'+owner);
            if(owner.Active_Partner__c==false)
             {
               owner.Active_Partner__c=true;
               update owner;
             }
           }*/
 
    // SFDC-9133 - Rebate will be calcualted when the DR gets approved, hence commenting from here.
    // if (Optty.Deal_Reg_Opportunity_Status__c == 'New Opportunity') {
    //   if (selectedAccount.Customer_or_Account__c == 'Existing Customer') {
    //     Optty = populateRebateDiscountPercentageAndStatus(Optty,'ExistingCustomerNewOppty');
    //   }

    //   if (selectedAccount.Customer_or_Account__c == 'Existing Account') {
    //     Optty = populateRebateDiscountPercentageAndStatus(Optty,'ExistingAccountNewOpportunity');
    //   }
    // }

    // if (Optty.Deal_Reg_Opportunity_Status__c == 'Existing Opportunity') {
    //   if (selectedAccount.Customer_or_Account__c == 'Existing Customer') {
    //     Optty = populateRebateDiscountPercentageAndStatus(Optty,'ExistingCustomerExistingOppty');
    //   }

    //   if (selectedAccount.Customer_or_Account__c == 'Existing Account') {
    //     Optty = populateRebateDiscountPercentageAndStatus(Optty,'ExistingAccountExistingOppty');
    //   }

    // }
    
 
    try {
 
      update Optty;
    }
 
    Catch(Exception e) { System.debug('Exception @@ on Optty Update ' + e.getMessage()); return e.getMessage();
    }
 
    OpportunityTeamMember otm = null;
    OpportunityShare oppshare = null;
    for (OpportunityTeamMember otmmem : [select id, UserId from OpportunityTeamMember where OpportunityId = :Optty.id and TeamMemberRole = 'Partner'])
      otm = otmmem;
    if (otm != null) {
      otm.OpportunityAccessLevel = 'Edit';
      try { 
        update otm;
      }
      Catch(Exception e) { return e.getMessage();
 
      }
    }
    /*oppshare=SF1_OpportunityService.opptyUpdateShareTable(Optty.id,otm.UserId,'Edit');
     if(oppshare!=null)
     { System.debug('Oppshare Update Started');
 
        update oppshare;
 
        System.debug('Oppshare Update Done');
      }*/
 
 
    return Success;
  }
 
  global static String updateOpportunityAfterCreateAccount(Opportunity Optty, String AccountName, String AccountDomain, String PrimaryStreet, String PrimaryCity, String PrimaryState, String zip, String PrimaryCountry, String vertical, String subVertical)
  {
     list<account> acctList =new list<account>();
     list<SObject> acctList1 =new list<SObject>();
    Boolean DuplicateFlag =false;
    String error ='Error :';
    

    Account newAccount = new Account();
    newAccount.Name = AccountName;
    newAccount.Website = AccountDomain;
    newAccount.BillingCountry = PrimaryCountry;
    newAccount.BillingStreet = PrimaryStreet;
    newAccount.BillingCity = PrimaryCity;
    newAccount.BillingState = PrimaryState;
    newAccount.BillingPostalCode = Zip;
    newAccount.Vertical__c = vertical;
    newAccount.Sub_Vertical__c = subVertical;
    Account_Reassignment_Rule__c currentUserRule = null;
    String Success = 'Success';
    String reassign='User does not have any associated Account re-assignment rule';
 
    for (Account_Reassignment_Rule__c  tempRule : [Select a.Associated_User__c, a.Associated_User_RSM__c From Account_Reassignment_Rule__c a where a.Associated_User__c = :UserInfo.getUserID()])
      currentUserRule = tempRule;
 
    if (CurrentUserRule != null)
    {
      System.debug('RAJESH ASHOK----->RULE FOUND');
      try {
      
        //insert newAccount;

        Database.DMLOptions dml = new Database.DMLOptions();
        //if(allowDuplicate)
            dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.insert(newAccount, dml);
            if (!sr.isSuccess()) { 
                
                for(Database.Error err : sr.getErrors()) { error += err.getMessage();  }
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
                return Error;
            }
      }
 
      Catch(Exception e) { System.debug('Exception @@@@  ' + e.getMessage()); return e.getMessage();
 
      }
 
 
      Optty.AccountId = newAccount.id;
      Optty.Validation_Override__c = true;
      Optty.Deal_Reg_Account_Status__c = 'New Account';
      Optty.Deal_Reg_Opportunity_Status__c = 'New Opportunity';
      Optty.Existing_Opportunity__c = null;
      // Optty=populateRebateDiscountPercentageAndStatus(Optty,'NewAccountNewOppty');
      /*if(Optty.Partner_Owner__c!=null)
      {
        Id ownerId= Optty.Partner_Owner__c;
        Contact owner=[Select Id,Active_Partner__c from Contact where Id=:OwnerId];
        System.debug('Owner------->'+owner);
        if(owner.Active_Partner__c==false)
         {
           owner.Active_Partner__c=true;
           update owner;
         }
       }*/
 
 
      try {
        update Optty;
      }
      Catch(Exception e) { System.debug('Caught Exception on update Optty Update@@@@  ' + e.getMessage()); return e.getMessage();
 
      }
 
      OpportunityTeamMember otm = null;
      OpportunityShare oppshare = null;
      for (OpportunityTeamMember otmmem : [select id, UserId from OpportunityTeamMember where OpportunityId = :Optty.id and TeamMemberRole = 'Partner'])
        otm = otmmem;
      if (otm != null) {
        otm.OpportunityAccessLevel = 'Edit';
 
        try {
          update otm;
        }
        Catch(Exception e) {System.debug('Caught Exception on update Optty Update@@@@  ' + e.getMessage()); return e.getMessage();
 
        }
      }
      /*oppshare=SF1_OpportunityService.opptyUpdateShareTable(Optty.id,otm.UserId,'Edit');
      if(oppshare!=null)
      { System.debug('Oppshare Update Started');
 
      update oppshare;
 
      System.debug('Oppshare Update Done');
      }*/
 
 
      return Success;
 
    }
 
    else
      return reassign;
  }
 
  //SFDC-1469
  // SFDC-9133 - Rebate will be calcualted when the DR gets approved, hence commenting from here.
    // public static Opportunity populateRebateDiscountPercentageAndStatus(Opportunity oppty,String metadataInfo)
    //  {
    //     if (!oppty.Partner_Involved__r.No_Rebate_Required__c) {
    //       oppty.Rebate__c =  GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Deal_Reg_Rebate_Percentage__c;
    //       oppty.Discount_Percentage__c =  Integer.valueOf(GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Discount__c);
    //       oppty.Discount_Status__c = GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Discount_Status__c;
    //     }
    //     return oppty;
    //  }
}