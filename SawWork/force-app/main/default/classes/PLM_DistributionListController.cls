/**
	PLM_DistributionListController
	@author: sveerapp@akamai.com
	@description: This controller supports visualforce page PLM_DistributionList.page This controller has action methods to add, remove users from distribution list
	and  show available product lines and active users

*/
public  class PLM_DistributionListController {

    private String[] selectedProductLines = new String[]{};
    private String[] selectedUsersList = new String[]{};
    private List<PLM_Product_Launch_RASCI_Wrapper> rasciWrapperList;




    public PageReference addUsersToDistributionList() {

        List<Product_Launch_RASCI_List__c> plmNotificationList = new List<Product_Launch_RASCI_List__c>();

        Product_Launch_RASCI_List__c temp  = null;

        for(String productLineId: selectedProductLines){
            for(String userId : selectedUsersList){

                temp = new Product_Launch_RASCI_List__c();
                temp.User__c = userId;
                temp.Product_Line__c = productLineId;
                plmNotificationList.add(temp);
            }

        }

        insert plmNotificationList;
        return null;

    }


    public PageReference removeUsers() {

        List<Product_Launch_RASCI_List__c> plmNotificationDeleteList = new List<Product_Launch_RASCI_List__c>();

        for(PLM_Product_Launch_RASCI_Wrapper rasci: rasciWrapperList){
            if(rasci.isSelected){
                    plmNotificationDeleteList.add(rasci.rascidistributionRecord);
            }

        }

        delete plmNotificationDeleteList;
        return null;

    }


    public List<SelectOption> getUserList() {
        List<SelectOption> options = new List<SelectOption>();

        List<User> userList = [Select u.Id, u.Name From User u  where u.User_Profile_Name__c  in ('Engineering', 'Product Operations', 'Product Management', 'CMG') and  u.IsActive = true order by u.Name ];

        for(User usr: userList){
            options.add(new SelectOption(usr.Id ,usr.Name));
        }

        return options;
    }


    public List<SelectOption> getProductLines() {
        List<SelectOption> options = new List<SelectOption>();


        List<Product_Line__c> plcList =  [Select p.Id, p.Name From Product_Line__c p];

        for(Product_Line__c plc: plcList){
                    options.add(new SelectOption(plc.Id,plc.Name));
        }

        return options;
    }


    public List<PLM_Product_Launch_RASCI_Wrapper> getDistributionList(){

        rasciWrapperList = new List<PLM_Product_Launch_RASCI_Wrapper>();
        PLM_Product_Launch_RASCI_Wrapper rasciWrapper = new PLM_Product_Launch_RASCI_Wrapper();


        List<Product_Launch_RASCI_List__c>  plrList = [Select p.User__r.Name ,  p.Product_Line__r.Name From Product_Launch_RASCI_List__c p order by p.Product_Line__r.Name];

        for(Product_Launch_RASCI_List__c plc: plrList){
            rasciWrapper = new PLM_Product_Launch_RASCI_Wrapper();
            rasciWrapper.rascidistributionRecord = plc;
            rasciWrapperList.add(rasciWrapper);

        }

        return rasciWrapperList;

    }




    public String[] getSelectedProductLines() {
        return selectedProductLines;
    }

    public void setSelectedProductLines(String[] selectedProductLines) {
        this.selectedProductLines = selectedProductLines;
    }

    public String[] getSelectedUsersList() {
        return selectedUsersList;
    }

    public void setSelectedUsersList(String[] selectedUsersList) {
        this.selectedUsersList = selectedUsersList;
    }

    public List<PLM_Product_Launch_RASCI_Wrapper> getRasciWrapperList(){
    	return rasciWrapperList;
    }

	public void setRasciWrapperList(List<PLM_Product_Launch_RASCI_Wrapper> rasciWrapperList){
		this.rasciWrapperList = rasciWrapperList;
	}


}