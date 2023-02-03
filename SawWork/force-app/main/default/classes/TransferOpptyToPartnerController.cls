global class TransferOpptyToPartnerController {
    public Opportunity opp {get;set;} 
    public Boolean HasError {get;set;} 
    public list<OpportunityTeamMember> userlist {get;set;}
    public string pid{get;set;}
    private PageReference pRef;
    public TransferOpptyToPartnerController(ApexPages.StandardController controller) {
        this.opp = (opportunity)controller.getRecord();
        HasError=false;
        opp=[select id,Partner_Involved__c,Partner_Involved__r.ParentId,Partner_Involved__r.isCustomer__c, Partner_Involved__r.isParentCustomer__c, 
            Account.isCustomer__c, Account.isParentCustomer__c,
            Customer_Company_Name__c, Account.Name,
            End_Customer_Street_Address__c, Account.BillingStreet, 
            End_Customer_City__c, Account.BillingCity,
            End_Customer_State__c, Account.BillingState, 
            End_Customer_Zip_Code__c, Account.BillingPostalCode,
            End_Customer_Country__c, Account.BillingCountry, 
            Customer_Contact_First_Name__c, Associated_Lead__r.Associated_Contact__r.FirstName, 
            End_Customer_Contact_Last_Name__c, Associated_Lead__r.Associated_Contact__r.LastName, 
            End_Customer_Website__c, Account.Website, 
            OwnerId, Registration_Status__c, Deal_Reg_Account_Status__c, Validation_Override__c from Opportunity where id=:opp.id][0];
        if(opp.Partner_Involved__c==null)
        {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Partner Involved Cannot be Null'));HasError=true;
        }
        else if(opp.Registration_Status__c!='Akamai Provided')
        {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The registration status should be Akamai Provided. Currently the registration status is '+opp.Registration_Status__c+' .'));HasError=true;
        }
        else
            init();
    }
    public void init()
    {
        userlist = new list<OpportunityTeamMember>();
        for(OpportunityTeamMember ctm:[select User.Name, User.Email, UserId, User.UserRole.Name, User.UserRoleId from OpportunityTeamMember where OpportunityId=:opp.id and TeamMemberRole='Partner'])
            userlist.add(ctm);
        //show all users and let them select the user 
        if(userlist.size()==0)
        {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No partner users found. Click <a href="/apex/PRMAddPartnerToSalesTeam?id='+opp.id+'">here</a> to add partner users.'));
           HasError=true;
        }
        
       
    }
    public pageReference setvalue()
    {
        pid=ApexPages.currentPage().getParameters().get('pid');
        return null;
    }

    global PageReference transferToPartner() 
    {
        calculatePriceList();
         User usr=[select id,contactid from User where id=:pid];
        return new PageReference('/_ui/core/email/author/EmailAuthor?rtype=003&p2_lkid='+usr.contactid+'&p3_lkid='+opp.id+'&retURL=/'+opp.id+'&template_id='+GsmUtilClass.getGSMSettingValue('TransferOpptyToPartner_template'));
    }

    private void calculatePriceList()
    {
        if(opp.Account.isCustomer__c==true || opp.Account.isParentCustomer__c==true)
        {
            opp.Deal_Reg_Account_Status__c ='Existing Customer';
        }
        else
        {
            opp.Deal_Reg_Account_Status__c ='Existing Account';
        }
        opp.Customer_Company_Name__c = opp.Account.Name;
        opp.End_Customer_Street_Address__c = opp.Account.BillingStreet;
        opp.End_Customer_City__c = opp.Account.BillingCity;
        opp.End_Customer_State__c = opp.Account.BillingState;
        opp.End_Customer_Zip_Code__c = opp.Account.BillingPostalCode;
        opp.End_Customer_Country__c = opp.Account.BillingCountry;
        opp.End_Customer_Website__c = opp.Account.Website;
        if(opp.Associated_Lead__c!=null)
        {
            opp.End_Customer_Contact_Last_Name__c = opp.Associated_Lead__r.Associated_Contact__r.LastName;
            opp.Customer_Contact_First_Name__c = opp.Associated_Lead__r.Associated_Contact__r.FirstName;
        }
        opp.Validation_Override__c = true;
        try
        {
            update opp;
        }
        catch(Exception exc)
        {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error while updating the Pricelist on the Opportunity.'+exc.getMessage()));
        }

    }

    public PageReference cancel() {
      PageReference rPage = new PageReference('/'+opp.id);
      rPage.setRedirect(true);
      return rPage;
    }

    public PageReference redirectToAddPartnerPage() {
      PageReference rPage = new PageReference('/apex/PRMAddPartnerToSalesTeam?id='+opp.id);
      rPage.setRedirect(true);
      return rPage;
    }
}