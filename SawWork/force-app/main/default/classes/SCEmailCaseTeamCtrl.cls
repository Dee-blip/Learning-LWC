public with sharing class SCEmailCaseTeamCtrl {
    private Case objCaseFromPage;
    private List<CaseTeamMember> lCaseTeamMembers= new List<CaseTeamMember>();
    private Set<Id> sContactCaseTeamMember = new Set<Id>();
    public string stringAllEmailAddress{get;set;}
    
    public SCEmailCaseTeamCtrl(ApexPages.StandardController controller) {
        objCaseFromPage = (Case) controller.getRecord();
        stringAllEmailAddress = '';
        lCaseTeamMembers = [SELECT Id, Member.Email, MemberId FROM CaseTeamMember Where ParentId = : objCaseFromPage.Id];
        for(CaseTeamMember objCaseTeamMember :lCaseTeamMembers){
            if(objCaseTeamMember.Member.Email != '' && objCaseTeamMember.Member.Email!=null){
                stringAllEmailAddress += objCaseTeamMember.Member.Email + ',';
            }
            if(String.valueOf(objCaseTeamMember.MemberId).startsWith('003')){
                sContactCaseTeamMember.add(objCaseTeamMember.MemberId);
            }    
        }
        
        for(Contact objContact : [select email from contact where id IN :sContactCaseTeamMember]){
            stringAllEmailAddress += objContact.Email + ',';
        }
        
        if(stringAllEmailAddress != ''){
            stringAllEmailAddress = stringAllEmailAddress.trim().substring(0,stringAllEmailAddress.length()-1);
        }


    }
    
    public string allCaseTeamMembers(){
        lCaseTeamMembers = [SELECT Id, Member.Email FROM CaseTeamMember Where ParentId = : objCaseFromPage.Id];
        for(CaseTeamMember objCaseTeamMember :lCaseTeamMembers){
            if(objCaseTeamMember.Member.Email != '' && objCaseTeamMember.Member.Email!=null)
                stringAllEmailAddress += objCaseTeamMember.Member.Email + ',';
        }
        if(stringAllEmailAddress != ''){
            stringAllEmailAddress = stringAllEmailAddress.trim().substring(0,stringAllEmailAddress.length()-1);
        }
            return stringAllEmailAddress;

    }
    

}