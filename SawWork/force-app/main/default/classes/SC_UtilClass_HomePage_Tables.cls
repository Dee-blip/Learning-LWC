/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  27-Jul-2015    Akhila    CR  2948861 - Base class to store common fields of Home Page Tables
+=====================================================================================================*/
public virtual class SC_UtilClass_HomePage_Tables {

    public String AkamId{get;set;}
    public String SFDCId{get;set;}
    public String AccountName{get;set;}
    public String AccountId{get;set;}
    public String Subject{get;set;}
    public String SupportLevel{get;set;}
    public String Severity{get;set;}
    public String SLA{get;set;}
    public String ObjectType{get;set;}
    
    //For Case
    public SC_UtilClass_HomePage_Tables(Case c,CaseMilestone CaseMile)
    {
        AkamId = c.AKAM_Case_ID__c;
        SFDCId = c.Id;
        AccountName = c.Account.Name==null?'':c.Account.Name;
        AccountId = c.AccountId==null?'':c.AccountId;
        Subject = c.Subject==null?'':c.Subject;
        SupportLevel = c.Support_Level__c==null?'':c.Support_Level__c;
        Severity = c.Severity__c==null?'':c.Severity__c;
        
        if(CaseMile == null)
        {
            SLA='z';
        }
        else if(CaseMile != null && CaseMile.IsCompleted)
        {
            SLA='y';
        }
        else if(CaseMile != null)
        {
            SLA = String.valueOf(CaseMile.TargetResponseInMins - (DateTime.Now().getTime() - CaseMile.StartDate.getTime())/60000);
        }
        ObjectType = 'case';
    }
    
    //For Engagement Request
    public SC_UtilClass_HomePage_Tables(Engagement_Request__c e,CaseMilestone CaseMile)
    {
        AkamId = e.Name;
        SFDCId = e.Id;
        AccountName = e.Case__r.Account.Name==null?'':e.Case__r.Account.Name;
        AccountId = e.Case__r.AccountId==null?'':e.Case__r.AccountId;
        Subject = e.Description__c==null?'':e.Description__c;
        SupportLevel = e.Case__r.Support_Level__c==null?'':e.Case__r.Support_Level__c;
        Severity = e.ER_Severity__c==null?'':e.ER_Severity__c;
        
        if(CaseMile == null)
        {
            SLA='z';
        }
        else if(CaseMile != null && CaseMile.IsCompleted)
        {
            SLA='y';
        }
        else if(CaseMile != null)
        {
            SLA = String.valueOf(CaseMile.TargetResponseInMins - (DateTime.Now().getTime() - CaseMile.StartDate.getTime())/60000);
        }        
        ObjectType = 'er';
    }
            
}