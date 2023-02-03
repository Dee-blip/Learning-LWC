/**
 * PRM search oppty controller
 * This is a controller for Searching existing opptys.
 * This page is invoked by clicking the button 'Locate Existing Opportunity' on the submitted deal reg page layout
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 Anand Hegde      21 Jan 2014 Created Class
 Rahul Gaira      2 Feb 2015  Changed the Rebate % calculation
 Sonali Tandon    22 Dec 2016 SFDC- 1337 : Changed rebate % calculation, added logic for discount % and status
 **/
global class PRMSearchOpportunityController
{

    public list<Opportunity> listOfExistingOpptys{ get; set; }
    public Opportunity currentOppty{get; set;}
    private string oppId= '' ;
    private PageReference pRef;

    public  PRMSearchOpportunityController()
        {
            oppId = ApexPages.currentPage().getParameters().get('opptyid');
            if(oppId== '' || oppId == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Opportunity ID specified'));
            }
            else
            {
                oppId = String.escapeSingleQuotes(oppId.escapeHtml4());// SFDC-5952 Added escapeHtml4() and escape
                //SFDC-1337 - Added Deal_Reg_Account_Status__c to query
                for(Opportunity opp : [select Id, Partner_Involved__r.No_Rebate_Required__c, Deal_Reg_Account_Status__c,Existing_Opportunity__c, AccountId, Deal_Reg_Account_Discount__c, Deal_Reg_Opportunity_Discount__c from Opportunity where Id=:oppId])
                    currentOppty = opp;

                if(currentOppty!=null)
                {
                    search();
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Opportunity ID. No Opportunity exists with that Id'));
                }


            }
        }

    public void search()
        {
            listOfExistingOpptys= new list<Opportunity>();
            for(Opportunity opp : [select Id, Owner__r.Name, Owner__r.Id, StageName, Name, Existing_Opportunity__c, Validation_Override__c, Account.Name, End_Customer_Website__c, Services_Hostname__c, Deal_Age__c, Partner_Involved__c, Partner_Involved__r.Name, Dollar_MRR__c, Partner_Involved__r.Id, Deal_Reg_Account_Discount__c, Deal_Reg_Opportunity_Discount__c, CloseDate from Opportunity where AccountId=:currentOppty.AccountId and Id!=:currentOppty.Id order by CloseDate DESC])
                {
                    if(!opp.StageName.contains('Closed') && !opp.StageName.contains('Signed')){
                        listOfExistingOpptys.add(opp);
                    }
                }

            if(listOfExistingOpptys.size()<1)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No opportunities exist for this account yet.'));
            }
        }

    public PageReference addOppty()
        {
            ID pid = ApexPages.currentPage().getParameters().get('pid');
            pid = !String.isEmpty(pid) ? ID.valueOf(String.escapeSingleQuotes( String.valueOf(pid).escapeHtml4())): pid;// SFDC-5952 Added escapeHtml4() and escape
            if(currentOppty!=null)
            {
                currentOppty.Existing_Opportunity__c=pid;
                currentOppty.Validation_Override__c=true;
                currentOppty.Deal_Reg_Opportunity_Status__c = 'Existing Opportunity';

                
                // Start - SFDC -1337 , SFDC-1469
                if(currentOppty.Deal_Reg_Account_Status__c == 'Existing Account')
                populateRebateDiscountPercentageAndStatus(currentOppty,'ExistingAccountExistingOppty');

                if(currentOppty.Deal_Reg_Account_Status__c == 'Existing Customer')
                    populateRebateDiscountPercentageAndStatus(currentOppty,'ExistingCustomerExistingOppty');
                // End - SFDC-1337 SFDC-1469
                

                try
                {
                    update currentOppty;
                }
                catch(Exception e)
                {
                    pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                }

                PageReference rPage = new PageReference('/'+oppId);
                rPage.setRedirect(true);
                return rPage;
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Opportunity ID'));
                return null;
            }
        }

    public PageReference cancel()
        {
            PageReference rPage = new PageReference('/'+oppId );
            rPage.setRedirect(true);
            return rPage;
        }

    public PageReference createNew()
        {
            currentOppty.Deal_Reg_Opportunity_Status__c = 'New Opportunity';
            currentOppty.Existing_Opportunity__c = null;

            // Start -SFDC -1337, SFDC-1469
            if(currentOppty.Deal_Reg_Account_Status__c == 'Existing Customer')
                populateRebateDiscountPercentageAndStatus(currentOppty,'ExistingCustomerNewOppty');

            else if(currentOppty.Deal_Reg_Account_Status__c == 'Existing Account')
                populateRebateDiscountPercentageAndStatus(currentOppty,'ExistingAccountNewOpportunity');

            // End - SFDC-1337,1469

            try
            {
                update currentOppty;
            }
            catch(Exception e)
            {
                pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
            }
            PageReference rPage = new PageReference('/'+oppId);
            rPage.setRedirect(true);
            return rPage;
        }

    //SFDC-1469
    public static void populateRebateDiscountPercentageAndStatus(Opportunity oppty,String metadataInfo)
        {
            if (!oppty.Partner_Involved__r.No_Rebate_Required__c) {
                oppty.Rebate__c =  GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Deal_Reg_Rebate_Percentage__c;
                oppty.Discount_Percentage__c =  Integer.valueOf(GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Discount__c);
                oppty.Discount_Status__c = GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Discount_Status__c;
            }
        }



}