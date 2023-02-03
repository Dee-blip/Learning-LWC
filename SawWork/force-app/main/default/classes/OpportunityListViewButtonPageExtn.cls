public with sharing class OpportunityListViewButtonPageExtn {
    public string accountId {get; set;}
    public string redirectUrl {get; set;}
    public OpportunityListViewButtonPageExtn(ApexPages.StandardSetController stdController){
        redirectUrl = '';
        accountId = ApexPages.currentPage().getParameters().get('id');
        if(accountId.length() > 15)
            accountId = accountId.substring(0, 15);
    }
    public OpportunityListViewButtonPageExtn(){
        
    }
    public PageReference getTrialOpportunities(){
        string reportId = GsmUtilClass.getGSMSettingValue('TrialOpportunityReportId');
        if(UserInfo.getUiThemeDisplayed() == 'Theme4d'){
            redirectURL = '/lightning/r/Report/'+reportId+'/view?fv0='+accountId;
        }else{
            redirectURL = '/'+reportId+'?pv0='+accountId;
        }
        return new PageReference(redirectURL);
    }
}