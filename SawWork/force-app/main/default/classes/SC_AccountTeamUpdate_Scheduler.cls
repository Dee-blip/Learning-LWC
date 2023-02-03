/*-------------------------------------------------------------------------------------------------------------
 * Class Name           : SC_AccountTeamUpdate_Scheduler
 * Developer Name       : Vamsee Surya
 * Date                 : 17th July,2019
 * JIRA                 : ESESP-2306
 * Description          : Scheduler class to pick the AccountTeamMembers to give edit access on the case. 
 * Test Class           : SC_Case_Trgr_EmlServc_Class_TC2
 -------------------------------------------------------------------------------------------------------------*/ 
global class SC_AccountTeamUpdate_Scheduler implements Schedulable{
    
    global void execute(SchedulableContext sc){
        String profileName = 'GSS Professional Services - Restricted Country';
        List<AccountTeamMember> accountTeamList = new List<AccountTeamMember>();
        for(AccountTeamMember eachAccountTeam : [SELECT Id, CaseAccessLevel FROM AccountTeamMember WHERE User.Isactive = True AND
                                                 User.profile.name = :profileName AND CaseAccessLevel != 'Edit']){
            eachAccountTeam.CaseAccessLevel = 'Edit';
            accountTeamList.add(eachAccountTeam);                          
        }
        if(accountTeamList.size() > 0){
            Try{
                Update accountTeamList;
            }
            Catch(Exception Ex){
                String ErrorMessage =   'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Exception in SC_Utility.accountTeamMemberUpdate\n' + 'Error Message: '+Ex.getMessage() +'\n' + 'Line Number: '+Ex.getLineNumber();
                SC_Utility.sendExceptionEmail('Error in AccountTeamMember Update', ErrorMessage);
                
            }
        }
    }

}