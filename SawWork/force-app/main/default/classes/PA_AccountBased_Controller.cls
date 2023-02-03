public class PA_AccountBased_Controller {

    public String acct_id {get; set;}
    public String Acct_name {get; set;}
    public String owner {get; set;}
    public Product_Approvals__c pac{get; set;} 
    public Approval_Workflow__c awc { get; set;}
    public CP_Chatter_Pulse__c cpc{get; set;}
    //public List<Approval_Workflow__c> option = [SELECT Id,Name FROM Approval_Workflow__c WHERE Account_Based_Approval__c=TRUE];
    public String[] SelectedApprovals = new String[]{};
    public ProductApprovalCS__c pa= ProductApprovalCS__c.getInstance('SIteShieldApprovalWF');
   

  //  public static Id definitionPhaseRecordTypeId =  Schema.SObjectType.Approval_Workflow__c.getRecordTypeInfosByName().get('SIteShieldApprovalWF').getRecordTypeId();
    public PA_AccountBased_Controller() {
    
        pac=new Product_Approvals__c();
        cpc=new CP_Chatter_Pulse__c();
        acct_id = System.currentPagereference().getParameters().get('acct_id');
        owner = System.currentPagereference().getParameters().get('owner');
        
        //List<Account> acctdetails = [SELECT Id, Name FROM Account WHERE Id = :acct_id];
        for(Account acctdetails:[SELECT Id, Name FROM Account WHERE Id = :acct_id])
        { 
        
        Acct_name=acctdetails.Name;
        
        }
        for(AccountTeamMember atm :[select AccountId, Id, TeamMemberRole, UserId FROM AccountTeamMember where AccountId = :acct_id and TeamMemberRole= 'Technical Sales - Primary' ])
        {
            cpc.Chatter_User__c=atm.UserId;
            //pac.User_Technical__c=atm.UserId;
        }
        init();
    }


     
  /*  public PA_AccountBased_Controller(ApexPages.StandardController controller) {
           
        pac=new Product_Approvals__c();  
         cpc=new CP_Chatter_Pulse__c();
        acct_id = System.currentPagereference().getParameters().get('acct_id');
        owner = System.currentPagereference().getParameters().get('owner');
        List<Account> acctdetails = [SELECT Id, Name FROM Account WHERE Id = :acct_id];
        Acct_name=acctdetails[0].Name;
        for(AccountTeamMember atm :[select AccountId, Id, TeamMemberRole, UserId FROM AccountTeamMember where AccountId = :acct_id and TeamMemberRole= 'Technical Sales - Primary' ])
        {
           cpc.Chatter_User__c=atm.UserId;
          // pac.User_Technical__c=atm.UserId;
        }
        init();
    } */
    
    public void init()
    {
    
        pac.Opportunity_Owner__c=owner;
        
        pac.Account__c=acct_id;
        
        pac.Creator__c=UserInfo.getUserId();
        
        Datetime cDT = System.now();          
      
    }


    public PageReference save() {
    for(Approval_Workflow__c approval : [SELECT Id, Name , Survey__c FROM Approval_Workflow__c WHERE Id= :pa.Value__c])
    {
     String PAname = approval.Name+ ' Approval for '+Acct_name;
       pac.Survey__c=approval.Survey__c;
       pac.Approval_Workflow__c =approval.Id;
       pac.Escalation_Status__c='NEW';
        if(PAname.length() > 79)
      {
         pac.name= PAname.substring(0, 79);
       }
       else
       {
       pac.name= PAname;
      }
       }
     
       
       if(cpc.Chatter_User__c!=null){
           pac.User_Technical__c=cpc.Chatter_User__c;
       } 
      else
        {
                  pac.User_Technical__c=owner; 
         }
         INSERT pac; 
         return new PageReference('/'+pac.Id);             
    }
    
     public PageReference save_survey() {  
     for(Approval_Workflow__c approval:[SELECT Id, Name , Survey__c FROM Approval_Workflow__c WHERE Id= :pa.Value__c])
     {
     String PAname = approval.Name+ ' Approval for '+Acct_name;//+cDt.day()+'-'+cDt.month()+'-'+cDt.year();
      pac.Survey__c=approval.Survey__c; 
      pac.Escalation_Status__c='NEW';   
       if(PAname.length() > 79)
      {
         pac.name= PAname.substring(0, 79);
       }
       else
       {
       pac.name= PAname;
      }
        pac.Approval_Workflow__c =approval.Id; 
     }
          pac.isUserTSP__c=TRUE; 
           if(cpc.Chatter_User__c!=null){
               pac.User_Technical__c=cpc.Chatter_User__c;
           } 
          else
            {
                  pac.User_Technical__c=owner; 
             }
          INSERT pac;
          return new PageReference('/apex/TakeSurvey?id='+pac.Survey__c+'&productApprovalId='+pac.Id);
     }
     
     public PageReference cancel() {
     
         return new PageReference('/'+acct_id);
         
     }

}