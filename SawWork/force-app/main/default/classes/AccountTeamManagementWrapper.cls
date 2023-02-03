/**
 * utility class for AccountTeamManagement.cls
 * wraps the account teams so that updation or 
 * deletion can be performed on them
 *
 * History:
 * =========================
 * Developer        Date            Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N   7/OCT/2010      Created this Class
**/
public class AccountTeamManagementWrapper {

    public Boolean checked{ get; set;}
    public AccountTeamMember a { get; set;}
    public String BUOpt{get;set;}
    public String AccAccessLevel {get; set;}
    public String OppAccessLevel {get;set;}
    // display drop down menu of Account Team Role picklist
    private List<string> ple ;
    public List<SelectOption> getBUOptions() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(a.TeamMemberRole,a.TeamMemberRole));
        for(String p : ple)
        {
        if(a.TeamMemberRole!=p)
        options.add(new SelectOption(p, p));        
        }
        return options;
    }
    // Update Access share to be made viewable in UI
    private string UpdateAccessLevel(string accmem)
    {
        string AccShr = 'None';
        if (accmem == 'None')
            AccShr='Private';
        else if (accmem == 'Edit')
            AccShr='Read/Write';
        else if (accmem == 'All')
            AccShr='Owner';
        else
            AccShr='Read Only';
        return AccShr;
    }

    // Pass accountTeamMember and Account share
    public AccountTeamManagementWrapper(AccountTeamMember acc, AccountShare accountsh,List<String> pickval){
        a = acc;
        checked=false;
        AccAccessLevel=UpdateAccessLevel(accountsh.AccountAccessLevel);
        OppAccessLevel=UpdateAccessLevel(accountsh.OpportunityAccessLevel);
        if(acc.TeamMemberRole==null)
        a.TeamMemberRole='--None--';
        ple=pickval;
    }
    // Pass only Account Team Member , make account access and opportunity Access as null
    public AccountTeamManagementWrapper(AccountTeamMember acc,List<String> pickval){
        a = acc;
        checked=false;
        AccAccessLevel='-';
        OppAccessLevel='-';
        if(acc.TeamMemberRole==null)
        a.TeamMemberRole='--None--';
        ple=pickval;
    }
}