public without sharing class AccountLicenseInfo{
    Integer liteLicenseCount;
    Integer nonLiteLicenseCount;
    Id accountId;

    public AccountLicenseInfo(Id accId, Integer lite, Integer nonLite)
    {
        this.accountId = accId;
        if(lite==null)
            this.liteLicenseCount=0;
        else
            this.liteLicenseCount = lite;

        if(nonLite==null)
            this.nonLiteLicenseCount=0;
        else
            this.nonLiteLicenseCount = nonLite;
    }

    public void incrementLiteLicense(){
        liteLicenseCount = liteLicenseCount+1;
    }

    public void incrementNonLiteLicense(){
        nonLiteLicenseCount = nonLiteLicenseCount+1;
    }

    public void decrementLiteLicense(){
        liteLicenseCount = liteLicenseCount-1;
    }

    public void decrementNonLiteLicense(){
        nonLiteLicenseCount = nonLiteLicenseCount -1;
    }

    public Account getAccount(){
        return new Account(Id=accountId, Current_licenses__c=nonLiteLicenseCount, Current_Lite_Licenses__c=liteLicenseCount);
    }

}