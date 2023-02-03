public class PartnerCommunityExceptionData {
    public String name = '';
    public String message = '';
    public Integer status;
    public String error = '';
    public Boolean dismissible = true;
 
    public PartnerCommunityExceptionData(String name, String message, Integer status, String error, Boolean dismissible) {
        this.name = name;
        this.message = message;
        this.status = status;
        this.error = error;
        this.dismissible = dismissible;
    }

    public PartnerCommunityExceptionData() {
        this.message = 'Some Error occured. Please contact your system administrator.'; 
    }
}