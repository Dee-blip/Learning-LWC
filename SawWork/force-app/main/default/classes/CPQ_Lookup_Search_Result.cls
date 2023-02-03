/* CPQ_Lookup_Search_Result is a used in CPQ Product Search Controller  
* Test Class: CPQ_Test_Lookup_Search_Result
* @author  Mausam Singh
* @since   2021-09-23
*/
public virtual class CPQ_Lookup_Search_Result implements Comparable {
    protected Id id;
    protected String sObjectType;
    protected String icon;
    protected String title;
    protected String subtitle;
    
    
    
    public CPQ_Lookup_Search_Result(Id id, String sObjectType, String icon, String title, String subtitle) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
    }
    
    @AuraEnabled
    public Id getId() {
        return id;
    }
    
    @AuraEnabled
    public String getSObjectType() {
        return sObjectType;
    }
    
    @AuraEnabled
    public String getIcon() {
        return icon;
    }
    
    @AuraEnabled
    public String getTitle() {
        return title;
    }
    
    @AuraEnabled
    public String getSubtitle() {
        return subtitle;
    }
    
    /**
* Allow to sort search results based on title
*/
    public Integer compareTo(Object compareTo) {
        CPQ_Lookup_Search_Result other = (CPQ_Lookup_Search_Result) compareTo;
        if (this.getTitle() == null) {
            return (other.getTitle() == null) ? 0 : 1;
        }
        if (other.getTitle() == null) {
            return -1;
        }
        return this.getTitle().compareTo(other.getTitle());
    }
}